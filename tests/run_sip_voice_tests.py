#!/usr/bin/env python3
"""Run voice-agent tests; optional real SIP/RTP with explicit synthetic HTTP fixtures.

These tests do not claim to validate speech recognition quality, an installed LLM,
a synthesizer model, or physical telephones.
"""
import argparse
import io
import json
import math
import os
from pathlib import Path
import shutil
import struct
import subprocess
import tempfile
import threading
import time
import wave
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

ROOT = Path(__file__).resolve().parents[1]


def test_daemon(executable, bridge, daemon, build, http_base):
    users = build / 'sip-users.ini'
    users.write_text('[1001]\npassword=fixture-password\n')
    port = 31000 + os.getpid() % 1000 * 8
    env = dict(os.environ, CASA_SIP_USERS_FILE=str(users), CASA_SIP_LIBRARY=str(bridge.resolve()),
               CASA_SIP_BIND='127.0.0.1', CASA_SIP_PUBLIC_ADDRESS='127.0.0.1',
               CASA_SIP_PORT=str(port), CASA_SIP_RTP_PORT=str(port+3000), CASA_SIP_REALM='maurin.local',
               CASA_SIP_AI_TOKEN='fixture-token', CASA_SIP_AI_FORMAT='casa',
               CASA_SIP_STT_URL=http_base+'/stt', CASA_SIP_AI_URL=http_base+'/ai',
               CASA_SIP_TTS_URL=http_base+'/tts', CASA_SIP_AUDIO_BASE_URL=http_base+'/audio/',
               CASA_SIP_SILENCE_MS='100', CASA_SIP_MIN_SPEECH_MS='80')
    subprocess.run([str(daemon), '--check-config'], env=env, check=True, timeout=5)
    users.write_text('[1001]\npassword=CHANGE_ME_PHONE\n')
    invalid = subprocess.run([str(daemon), '--check-config'], env=env, capture_output=True, timeout=5)
    assert invalid.returncode != 0, 'Default password was accepted'
    users.write_text('[1001]\npassword=fixture-password\n')
    logfile = build / 'daemon.log'
    with logfile.open('w') as log:
        process = subprocess.Popen([str(daemon)], env=env, stdout=log, stderr=subprocess.STDOUT)
        try:
            deadline = time.monotonic()+5
            while 'listening on SIP' not in logfile.read_text():
                if process.poll() is not None or time.monotonic() >= deadline:
                    raise RuntimeError('Casa daemon did not start: '+logfile.read_text())
                time.sleep(0.02)
            subprocess.run([str(executable), str(bridge.resolve()), f'sip:127.0.0.1:{port}'],
                           check=True, timeout=20)
        finally:
            process.terminate()
            process.wait(timeout=5)
        assert process.returncode == 0, logfile.read_text()
    assert 'response ready' in logfile.read_text() and 'Stopped' in logfile.read_text()


def fixture_audio():
    buffer = io.BytesIO()
    with wave.open(buffer, 'wb') as audio:
        audio.setparams((1, 2, 16000, 0, 'NONE', 'not compressed'))
        audio.writeframes(b''.join(struct.pack('<h', round(6000 * math.sin(i * 2 * math.pi * 660 / 16000)))
                                   for i in range(8000)))
    return buffer.getvalue()


class Fixtures(BaseHTTPRequestHandler):
    """Test doubles only. Never imported by production code."""
    requests_seen = []
    errors = []
    lock = threading.Lock()
    audio = fixture_audio()

    def log_message(self, *args):
        pass

    def respond(self, body, code=200, content_type='application/json'):
        if isinstance(body, dict):
            body = json.dumps(body, ensure_ascii=False).encode()
        self.send_response(code)
        self.send_header('Content-Type', content_type)
        self.send_header('Content-Length', str(len(body)))
        self.end_headers()
        try:
            self.wfile.write(body)
        except (BrokenPipeError, ConnectionResetError):
            pass

    def do_GET(self):
        with self.lock:
            self.requests_seen.append(('GET', self.path))
        if self.path == '/audio/fixture.wav':
            self.respond(self.audio, content_type='audio/wav')
        else:
            self.respond({'error': 'not found'}, 404)

    def do_POST(self):
        try:
            raw = self.rfile.read(int(self.headers.get('Content-Length', 0)))
            with self.lock:
                self.requests_seen.append(('POST', self.path))
            if self.path in ('/stt', '/stt-stub', '/slow'):
                with wave.open(io.BytesIO(raw)) as wav:
                    assert wav.getframerate() == 8000 and wav.getnchannels() == 1
                if self.path == '/slow':
                    time.sleep(0.3)
                text = '[Áudio recebido e processado pelo Parakeet STT]' if self.path == '/stt-stub' else 'fixture utterance'
                self.respond({'ok': True, 'texto': text})
            elif self.path in ('/ai', '/chat'):
                assert self.headers.get('Authorization') == 'Bearer fixture-token'
                data = json.loads(raw)
                if self.path == '/ai':
                    assert data['comando'] == 'fixture utterance'
                    assert data['session_id'] and isinstance(data['historico_mensagens'], list)
                    self.respond({'status': 'sucesso', 'resposta': 'fixture response'})
                else:
                    assert data['model'] == 'fixture-model' and data['stream'] is False
                    assert data['messages'][-1]['content'] == 'fixture utterance'
                    self.respond({'choices': [{'message': {'content': 'fixture response'}}]})
            elif self.path in ('/tts', '/tts-direct', '/tts-unsafe'):
                data = json.loads(raw)
                assert data['reproduzir'] is False
                if self.path == '/tts-direct':
                    self.respond(self.audio, content_type='audio/wav')
                else:
                    name = 'fixture.wav' if self.path == '/tts' else '%2e%2e.wav'
                    self.respond({'status': 'ok', 'audio_url': '/casa/api/audio/' + name})
            elif self.path == '/redirect':
                self.send_response(302)
                self.send_header('Location', '/must-not-be-followed')
                self.send_header('Content-Length', '0')
                self.end_headers()
            else:
                self.respond({'error': 'unavailable'}, 503)
        except Exception as exc:
            with self.lock:
                self.errors.append(repr(exc))
            self.respond({'error': 'fixture assertion failed'}, 500)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--fpc', default=shutil.which('fpc'))
    parser.add_argument('--unit-path', action='append', default=[])
    parser.add_argument('--no-config', action='store_true', help='Use FPC -n with extracted toolchains')
    parser.add_argument('--bridge', type=Path, help='Enable the actual SIP/RTP integration test')
    parser.add_argument('--daemon', type=Path, help='Also test the compiled Casa SIP daemon as a separate process')
    args = parser.parse_args()
    if not args.fpc:
        parser.error('Free Pascal is required; pass --fpc')
    tests = ['test_sip_voice_agent', 'test_sip_voice_http']
    if args.bridge:
        if not args.bridge.is_file():
            parser.error('SIP bridge does not exist')
        tests.append('test_sip_voice_loopback')
    if args.daemon:
        if not args.bridge or not args.daemon.is_file():
            parser.error('--daemon requires an existing executable and --bridge')
        args.daemon = args.daemon.resolve()
        tests.append('test_sip_voice_phone')
    server = ThreadingHTTPServer(('127.0.0.1', 0), Fixtures)
    thread = threading.Thread(target=server.serve_forever, daemon=True)
    thread.start()
    try:
        with tempfile.TemporaryDirectory(prefix='sip-voice-test-') as temp:
            build = Path(temp)
            for test in tests:
                command = [args.fpc, '-B', '-Cr', '-Co', '-gl', '-gh', f'-FU{build}', f'-FE{build}']
                if args.no_config:
                    command.append('-n')
                for directory in [ROOT / 'pacote/AI', ROOT / 'pacote/AI Agent',
                                  ROOT / 'pacote/AI Communication/AISIP', *args.unit_path]:
                    command.append(f'-Fu{directory}')
                subprocess.run(command + [str(ROOT / 'tests' / (test + '.lpr'))], check=True, timeout=90)
                executable = build / (test + ('.exe' if os.name == 'nt' else ''))
                http_base = f'http://127.0.0.1:{server.server_port}'
                if test == 'test_sip_voice_phone':
                    test_daemon(executable, args.bridge, args.daemon, build, http_base)
                    continue
                parameters = []
                if test.endswith('_loopback'):
                    parameters.append(str(args.bridge.resolve()))
                if test != 'test_sip_voice_agent':
                    parameters.append(http_base)
                subprocess.run([str(executable), *parameters], check=True, timeout=30)
        assert not Fixtures.errors, Fixtures.errors
        assert not any(path == '/must-not-be-followed' for _, path in Fixtures.requests_seen)
        print(f'PASS: {len(tests)} suites; {len(Fixtures.requests_seen)} local HTTP fixture requests')
    finally:
        server.shutdown()
        server.server_close()
        thread.join(timeout=2)


if __name__ == '__main__':
    main()
