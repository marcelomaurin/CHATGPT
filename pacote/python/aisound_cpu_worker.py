#!/usr/bin/env python3
"""
aisound_cpu_worker.py - Runtime local CPU-friendly para sintese de voz (TTS),
clonagem de voz e geracao de efeitos sonoros (SFX/musica) sem GPU obrigatoria.
Integravel com TAIUnifiedSound / TAIVoiceClone do projeto CHATGPT.
"""
import argparse
import json
import math
import os
import shutil
import struct
import subprocess
import sys
import wave


def write_pcm_wav(out_path: str, samples, sample_rate: int = 22050):
    os.makedirs(os.path.dirname(os.path.abspath(out_path)), exist_ok=True)
    with wave.open(out_path, "wb") as wf:
        wf.setnchannels(1)
        wf.setsampwidth(2)
        wf.setframerate(sample_rate)
        frames = bytearray()
        for s in samples:
            v = max(-1.0, min(1.0, float(s)))
            frames += struct.pack("<h", int(v * 32767.0))
        wf.writeframes(bytes(frames))


def synth_procedural_sfx(prompt: str, out_path: str, duration: float = 3.0):
    sr = 22050
    total = max(1, int(sr * max(0.5, duration)))
    p = (prompt or "").lower()
    samples = []
    # Deterministico conforme palavras-chave do prompt
    seed = sum(ord(c) for c in p) % 97
    if any(k in p for k in ["chuva", "vento", "mar", "ruido", "passos", "floresta", "ambiente"]):
        state = seed + 13
        for i in range(total):
            state = (1103515245 * state + 12345) & 0x7FFFFFFF
            noise = ((state / 0x7FFFFFFF) * 2.0 - 1.0)
            env = math.sin(math.pi * i / total)
            samples.append(noise * 0.28 * env)
    elif any(k in p for k in ["musica", "trilha", "acorde", "piano", "tema"]):
        freqs = [261.63, 329.63, 392.00, 523.25]
        for i in range(total):
            t = i / sr
            env = 0.25 * (1.0 - 0.5 * (i / total))
            val = sum(math.sin(2 * math.pi * f * t) for f in freqs) / len(freqs)
            samples.append(val * env)
    else:
        base_f = 220.0 + seed * 3.0
        for i in range(total):
            t = i / sr
            env = math.exp(-2.2 * t / max(0.5, duration))
            val = 0.55 * math.sin(2 * math.pi * base_f * t) + 0.25 * math.sin(2 * math.pi * base_f * 1.5 * t)
            samples.append(val * env)
    write_pcm_wav(out_path, samples, sr)
    return "procedural-sfx-cpu"


def default_parakeet_dir(runtime_dir: str = "") -> str:
    if runtime_dir:
        return os.path.join(os.path.abspath(runtime_dir), "models", "parakeet")
    env_dir = os.environ.get("CHATGPT_AI_RUNTIME", "").strip()
    if env_dir:
        return os.path.join(env_dir, "models", "parakeet")
    if os.name == "nt" and os.path.isdir(r"C:\CHATGPT-AI"):
        return os.path.join(r"C:\CHATGPT-AI", "models", "parakeet")
    script_dir = os.path.dirname(os.path.abspath(__file__))
    return os.path.abspath(os.path.join(script_dir, "..", "..", "runtime", "models", "parakeet"))


def prepare_parakeet_runtime(runtime_dir: str = "", do_install: bool = False) -> int:
    model_dir = default_parakeet_dir(runtime_dir)
    os.makedirs(model_dir, exist_ok=True)
    manifest = {
        "model": "parakeet",
        "task": "text-to-voice",
        "device": "cpu",
        "model_dir": model_dir,
        "onnx_ready": any(f.endswith(".onnx") for f in os.listdir(model_dir)),
    }
    manifest_path = os.path.join(model_dir, "parakeet_runtime.json")
    with open(manifest_path, "w", encoding="utf-8") as fp:
        json.dump(manifest, fp, indent=2, ensure_ascii=False)

    if do_install:
        req_file = os.path.abspath(
            os.path.join(os.path.dirname(__file__), "..", "..", "runtime", "requirements", "requirements-voice.txt")
        )
        if os.path.isfile(req_file):
            subprocess.run([sys.executable, "-m", "pip", "install", "--prefer-binary", "-r", req_file])

    print(json.dumps({"prepared": True, "manifest": manifest_path, "model": "parakeet"}, ensure_ascii=False))
    return 0


def run_health(runtime_dir: str = ""):
    import importlib.util
    parakeet_dir = default_parakeet_dir(runtime_dir)
    onnx_files = []
    if os.path.isdir(parakeet_dir):
        onnx_files = [f for f in os.listdir(parakeet_dir) if f.endswith(".onnx")]
    has_paddlespeech = bool(importlib.util.find_spec("paddlespeech"))
    has_parakeet_cli = bool(shutil.which("parakeet-tts") or shutil.which("parakeet") or shutil.which("paddlespeech"))
    has_onnxruntime = bool(importlib.util.find_spec("onnxruntime"))
    info = {
        "cpu_ready": True,
        "default_tts_model": "parakeet",
        "parakeet_ready": bool(has_paddlespeech or has_parakeet_cli or (has_onnxruntime and len(onnx_files) > 0)),
        "parakeet_prepared_dir": os.path.isdir(parakeet_dir),
        "parakeet_model_dir": parakeet_dir,
        "python": sys.version.split()[0],
        "backends": {
            "parakeet_cli": has_parakeet_cli,
            "paddlespeech": has_paddlespeech,
            "onnxruntime": has_onnxruntime,
            "parakeet_onnx_files": len(onnx_files),
            "piper_cli": bool(shutil.which("piper")),
            "espeak_ng": bool(shutil.which("espeak-ng") or shutil.which("espeak")),
            "kokoro_onnx": bool(importlib.util.find_spec("kokoro_onnx")),
            "coqui_tts": bool(importlib.util.find_spec("TTS")),
            "f5_tts": bool(importlib.util.find_spec("f5_tts")),
            "audiocraft": bool(importlib.util.find_spec("audiocraft")),
            "pyttsx3": bool(importlib.util.find_spec("pyttsx3")),
            "torch_installed": bool(importlib.util.find_spec("torch")),
        },
    }
    print(json.dumps(info, ensure_ascii=False))
    return 0


def run_parakeet_tts(args, out_path: str) -> str:
    device = "gpu" if args.gpu else "cpu"
    # 1) CLI dedicated parakeet-tts / parakeet / paddlespeech
    parakeet_bin = shutil.which("parakeet-tts") or shutil.which("parakeet")
    if parakeet_bin:
        cmd = [parakeet_bin, "--text", args.text, "--output", out_path]
        if args.language:
            cmd += ["--lang", args.language]
        proc = subprocess.run(cmd, capture_output=True)
        if proc.returncode == 0 and os.path.isfile(out_path) and os.path.getsize(out_path) > 44:
            return f"parakeet-cli-{device}"

    paddle_bin = shutil.which("paddlespeech")
    if paddle_bin:
        lang = "en" if (args.language or "").lower().startswith("en") else "mix"
        am = "fastspeech2_ljspeech" if lang == "en" else "fastspeech2_mix"
        proc = subprocess.run(
            [paddle_bin, "tts", "--am", am, "--lang", lang, "--input", args.text, "--output", out_path],
            capture_output=True,
        )
        if proc.returncode == 0 and os.path.isfile(out_path) and os.path.getsize(out_path) > 44:
            return f"parakeet-paddlespeech-cli-{device}"

    # 2) Python PaddleSpeech TTSExecutor (Parakeet lineage, CPU-ready)
    try:
        from paddlespeech.cli.tts.infer import TTSExecutor
        tts = TTSExecutor()
        lang = "en" if (args.language or "").lower().startswith("en") else "mix"
        am = "fastspeech2_ljspeech" if lang == "en" else "fastspeech2_mix"
        tts(text=args.text, output=out_path, am=am, lang=lang, device=device)
        if os.path.isfile(out_path) and os.path.getsize(out_path) > 44:
            return f"parakeet-paddlespeech-{device}"
    except Exception:
        pass

    return ""


def run_tts(args):
    out_path = os.path.abspath(args.output)
    os.makedirs(os.path.dirname(out_path), exist_ok=True)
    model_l = (args.model or "parakeet").strip().lower()

    # 0) Parakeet Text-to-Voice no Runtime (modelo padrao)
    if ("parakeet" in model_l) or (model_l == ""):
        backend = run_parakeet_tts(args, out_path)
        if backend:
            print(f"backend={backend}")
            return 0

    # 1) Piper CLI ONNX (CPU sem GPU)
    piper_bin = shutil.which("piper")
    if piper_bin and args.model and os.path.isfile(args.model):
        proc = subprocess.run(
            [piper_bin, "--model", args.model, "--output_file", out_path],
            input=args.text.encode("utf-8"),
            capture_output=True,
        )
        if proc.returncode == 0 and os.path.isfile(out_path):
            print("backend=piper-cpu")
            return 0

    # 2) pyttsx3 (Windows SAPI / Linux offline CPU)
    try:
        import pyttsx3
        eng = pyttsx3.init()
        eng.save_to_file(args.text, out_path)
        eng.runAndWait()
        if os.path.isfile(out_path) and os.path.getsize(out_path) > 44:
            print("backend=pyttsx3-cpu")
            return 0
    except Exception:
        pass

    # 3) espeak-ng CLI
    espeak_bin = shutil.which("espeak-ng") or shutil.which("espeak")
    if espeak_bin:
        proc = subprocess.run([espeak_bin, "-v", args.language or "pt", "-w", out_path, args.text])
        if proc.returncode == 0 and os.path.isfile(out_path):
            print("backend=espeak-cpu")
            return 0

    # 4) Fallback deterministico em CPU para nao quebrar o fluxo offline
    synth_procedural_sfx(args.text, out_path, duration=max(1.5, min(6.0, len(args.text) * 0.05)))
    print("backend=procedural-tts-fallback")
    return 0


def run_clone(args):
    out_path = os.path.abspath(args.output)
    os.makedirs(os.path.dirname(out_path), exist_ok=True)
    device = "cuda" if args.gpu else "cpu"
    if not args.ref_audio or not os.path.isfile(args.ref_audio):
        print("Erro: audio de referencia nao encontrado para clonagem.", file=sys.stderr)
        return 2

    # 1) Coqui XTTS-v2 Python API em CPU/GPU
    try:
        from TTS.api import TTS
        tts = TTS(model_name=args.model or "tts_models/multilingual/multi-dataset/xtts_v2").to(device)
        tts.tts_to_file(
            text=args.text,
            speaker_wav=args.ref_audio,
            language=args.language or "pt",
            file_path=out_path,
        )
        if os.path.isfile(out_path):
            print(f"backend=coqui-xtts-{device}")
            return 0
    except Exception:
        pass

    # 2) F5-TTS CLI se instalado
    f5_bin = shutil.which("f5-tts_infer-cli")
    if f5_bin:
        proc = subprocess.run(
            [f5_bin, "--ref_audio", args.ref_audio, "--gen_text", args.text, "--output_file", out_path],
            capture_output=True,
        )
        if proc.returncode == 0 and os.path.isfile(out_path):
            print(f"backend=f5-tts-{device}")
            return 0

    print("Nenhum motor de clonagem local (TTS/Coqui XTTS-v2 ou f5-tts_infer-cli) instalado neste runtime Python.", file=sys.stderr)
    return 3


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--health", action="store_true")
    ap.add_argument("--prepare-parakeet", action="store_true")
    ap.add_argument("--install-deps", action="store_true")
    ap.add_argument("--runtime-dir", default="")
    ap.add_argument("--mode", default="tts", choices=["tts", "clone", "sfx", "music"])
    ap.add_argument("--text", default="")
    ap.add_argument("--output", default="out.wav")
    ap.add_argument("--model", default="parakeet")
    ap.add_argument("--voice", default="")
    ap.add_argument("--language", default="pt")
    ap.add_argument("--ref_audio", default="")
    ap.add_argument("--duration", type=float, default=4.0)
    ap.add_argument("--cpu", action="store_true")
    ap.add_argument("--gpu", action="store_true")
    args = ap.parse_args()

    if args.prepare_parakeet:
        return prepare_parakeet_runtime(args.runtime_dir, args.install_deps)
    if args.health:
        return run_health(args.runtime_dir)
    if args.mode in ("sfx", "music"):
        backend = synth_procedural_sfx(args.text, args.output, args.duration)
        print(f"backend={backend}")
        return 0
    if args.mode == "clone":
        return run_clone(args)
    return run_tts(args)


if __name__ == "__main__":
    sys.exit(main())
