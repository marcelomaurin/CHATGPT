"""Validate OpenAI transcription against a local HTTP fixture, with no real key/audio."""
from pathlib import Path
from http.server import BaseHTTPRequestHandler,ThreadingHTTPServer
from threading import Thread
import subprocess,tempfile,sys,json,os,wave

def main():
    requests=[]
    class Handler(BaseHTTPRequestHandler):
        def log_message(self,*args):pass
        def do_POST(self):
            body=self.rfile.read(int(self.headers['Content-Length']))
            requests.append((self.path,self.headers.get('Authorization'),body))
            status=401 if self.path=='/unauthorized' else 200
            self.send_response(status);self.send_header('Content-Type','application/json');self.end_headers()
            self.wfile.write(b'{broken' if self.path=='/malformed' else json.dumps(
                {'text':''} if self.path=='/empty' else {'text':'Olá, professor!'}).encode())
    server=ThreadingHTTPServer(('127.0.0.1',0),Handler)
    thread=Thread(target=server.serve_forever,daemon=True);thread.start()
    env=dict(os.environ,OPENAI_API_KEY='')
    try:
        with tempfile.TemporaryDirectory() as tmp:
            wav=Path(tmp)/'fixture.wav'
            with wave.open(str(wav),'wb') as out:
                out.setparams((1,2,16000,0,'NONE','not compressed'));out.writeframes(b'\0'*1600)
            for path,mode in [('/transcribe','fallback'),('/transcribe','explicit'),
                              ('/unauthorized','error'),('/empty','error'),('/malformed','error'),
                              ('/transcribe','missing'),('/transcribe','chrome')]:
                process=subprocess.run([sys.argv[1],f'http://127.0.0.1:{server.server_port}{path}',str(wav),mode],
                    env=env,capture_output=True,timeout=15)
                assert process.returncode==0,(path,mode,process.stdout,process.stderr)
            assert len(requests)==5,requests
            assert requests[0][1]=='Bearer fixture-chat-token'
            assert requests[1][1]=='Bearer fixture-stt-token'
            for _,_,body in requests:
                assert b'name="language"\r\n\r\npt\r\n' in body
                assert b'name="model"\r\n\r\nwhisper-1\r\n' in body
                assert b'RIFF' in body and b'WAVE' in body
        print('PASS: OpenAI ChatGPT token fallback, explicit override, multipart WAV/model/language, HTTP 401, empty/malformed JSON, missing credentials, Chrome never uploads WAV')
    finally:server.shutdown();server.server_close()
if __name__=='__main__':main()
