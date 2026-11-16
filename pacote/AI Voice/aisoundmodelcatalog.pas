unit aisoundmodelcatalog;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils;

type
  TAISoundModelInfo = record
    IsLegacy: Boolean;
    Provider: string;
    InternalName: string;
    FriendlyName: string;
    DefaultEndpoint: string;
    DefaultVoice: string;
    DefaultSampleRate: Integer;
    RequiresAPIKey: Boolean;
    SupportsVoiceCloning: Boolean;
    SupportsSFX: Boolean;
    SupportsMusic: Boolean;
    RunsOnCPUWithoutGPU: Boolean;
    IsLocalServer: Boolean;
  end;

function AISoundModelCount: Integer;
function GetAISoundModelInfo(AIndex: Integer; out AInfo: TAISoundModelInfo): Boolean;
function FindAISoundModel(const AProvider, AModel: string;
  out AInfo: TAISoundModelInfo): Boolean;
procedure GetAISoundProviders(AList: TStrings);
procedure GetAISoundModelsForProvider(const AProvider: string; AList: TStrings;
  AIncludeLegacy: Boolean = False);
function GetAISoundDefaultModel(const AProvider: string): string;

implementation

procedure SetSndInfo(out AInfo: TAISoundModelInfo; const AProvider, AInternal,
  AFriendly, AEndpoint, AVoice: string; ASampleRate: Integer;
  AReqKey, AClone, ASfx, AMusic, ACpuOk, ALocal: Boolean);
begin
  AInfo.IsLegacy := False;
  AInfo.Provider := AProvider;
  AInfo.InternalName := AInternal;
  AInfo.FriendlyName := AFriendly;
  AInfo.DefaultEndpoint := AEndpoint;
  AInfo.DefaultVoice := AVoice;
  AInfo.DefaultSampleRate := ASampleRate;
  AInfo.RequiresAPIKey := AReqKey;
  AInfo.SupportsVoiceCloning := AClone;
  AInfo.SupportsSFX := ASfx;
  AInfo.SupportsMusic := AMusic;
  AInfo.RunsOnCPUWithoutGPU := ACpuOk;
  AInfo.IsLocalServer := ALocal;
end;

function AISoundModelCount: Integer;
begin
  Result := 30;
end;

function GetAISoundModelInfo(AIndex: Integer; out AInfo: TAISoundModelInfo): Boolean;
const
  OpenAISndEp    = 'https://api.openai.com/v1/audio/speech';
  ElevenEp       = 'https://api.elevenlabs.io/v1/text-to-speech/';
  GeminiTtsEp    = 'https://texttospeech.googleapis.com/v1/text:synthesize';
  KokoroEp       = 'http://127.0.0.1:8880/v1/audio/speech';
  PiperEp        = 'http://127.0.0.1:5000/';
  OpenedAIEp     = 'http://127.0.0.1:8000/v1/audio/speech';
  XttsEp         = 'http://127.0.0.1:8020/tts_to_audio/';
  AllTalkEp      = 'http://127.0.0.1:7851/api/tts-generate';
  OpenVoiceEp    = 'http://127.0.0.1:8030/synthesize';
  F5ServerEp     = 'http://127.0.0.1:7860/api/predict';
  ChatterboxEp   = 'http://127.0.0.1:8080/v1/tts';
  AudioCraftEp   = 'http://127.0.0.1:8040/generate';
  ParakeetEp     = 'http://127.0.0.1:8090/v1/audio/speech';
begin
  Result := True;
  case AIndex of
    // OpenAI Audio
    0: SetSndInfo(AInfo, 'OpenAI', 'gpt-4o-mini-tts', 'GPT-4o Mini TTS (OpenAI)', OpenAISndEp, 'alloy', 24000, True, False, False, False, False, False);
    1: SetSndInfo(AInfo, 'OpenAI', 'tts-1', 'TTS-1 Standard (OpenAI)', OpenAISndEp, 'nova', 24000, True, False, False, False, False, False);
    2: SetSndInfo(AInfo, 'OpenAI', 'tts-1-hd', 'TTS-1 HD (OpenAI)', OpenAISndEp, 'onyx', 24000, True, False, False, False, False, False);

    // ElevenLabs (Voz, Clonagem & SFX)
    3: SetSndInfo(AInfo, 'ElevenLabs', 'eleven_multilingual_v2', 'Eleven Multilingual v2 (Clone + PT)', ElevenEp, 'EXAVITQu4vr4xnSDxMaL', 44100, True, True, False, False, False, False);
    4: SetSndInfo(AInfo, 'ElevenLabs', 'eleven_turbo_v2_5', 'Eleven Turbo v2.5', ElevenEp, 'EXAVITQu4vr4xnSDxMaL', 44100, True, True, False, False, False, False);
    5: SetSndInfo(AInfo, 'ElevenLabs', 'sound-generation', 'ElevenLabs Sound Effects (SFX)', 'https://api.elevenlabs.io/v1/sound-generation', '', 44100, True, False, True, True, False, False);

    // Google Cloud / Gemini TTS
    6: SetSndInfo(AInfo, 'GeminiTTS', 'gemini-2.5-flash-preview-tts', 'Gemini 2.5 Flash TTS', GeminiTtsEp, 'pt-BR-Neural2-A', 24000, True, False, False, False, False, False);

    // Kokoro-FastAPI (Servidor Aberto, roda muito rapido em CPU sem GPU!)
    7: SetSndInfo(AInfo, 'Kokoro-FastAPI', 'kokoro', 'Kokoro-82M (Servidor Aberto CPU/GPU)', KokoroEp, 'pf_dora', 24000, False, False, False, False, True, True);

    // Piper HTTP (Servidor Aberto ONNX C++, ultra-leve em CPU sem GPU!)
    8: SetSndInfo(AInfo, 'Piper-HTTP', 'pt_BR-faber-medium', 'Piper PT-BR Faber (CPU sem GPU)', PiperEp, 'pt_BR-faber-medium', 22050, False, False, False, False, True, True);
    9: SetSndInfo(AInfo, 'Piper-HTTP', 'pt_BR-edresson-low', 'Piper PT-BR Edresson Low (CPU leve)', PiperEp, 'pt_BR-edresson-low', 16000, False, False, False, False, True, True);
    10: SetSndInfo(AInfo, 'Piper-HTTP', 'en_US-lessac-medium', 'Piper EN-US Lessac (CPU sem GPU)', PiperEp, 'en_US-lessac-medium', 22050, False, False, False, False, True, True);

    // OpenedAI-Speech (Drop-in OpenAI local com Piper + XTTS-v2 Cloning em CPU!)
    11: SetSndInfo(AInfo, 'OpenedAI-Speech', 'tts-1', 'OpenedAI-Speech Piper (CPU sem GPU)', OpenedAIEp, 'alloy', 22050, False, False, False, False, True, True);
    12: SetSndInfo(AInfo, 'OpenedAI-Speech', 'xtts_v2', 'OpenedAI-Speech XTTS-v2 (Clonagem CPU/GPU)', OpenedAIEp, 'alloy', 24000, False, True, False, False, True, True);

    // Coqui XTTS-v2 Server (Servidor Aberto de Clonagem de Voz, CPU ou GPU)
    13: SetSndInfo(AInfo, 'Coqui-XTTS', 'xtts_v2', 'Coqui XTTS-v2 (Clonagem Zero-Shot CPU/GPU)', XttsEp, 'default', 24000, False, True, False, False, True, True);
    14: SetSndInfo(AInfo, 'Coqui-XTTS', 'your_tts', 'Coqui YourTTS (Clonagem Leve CPU)', XttsEp, 'default', 16000, False, True, False, False, True, True);

    // AllTalk TTS (Servidor Unificado Local XTTS/Piper/Parler/F5)
    15: SetSndInfo(AInfo, 'AllTalk-TTS', 'xtts_v2', 'AllTalk XTTS-v2 (Clonagem Local)', AllTalkEp, 'female_01.wav', 24000, False, True, False, False, True, True);
    16: SetSndInfo(AInfo, 'AllTalk-TTS', 'piper', 'AllTalk Piper (CPU rapido)', AllTalkEp, 'pt_BR-faber-medium', 22050, False, False, False, False, True, True);
    17: SetSndInfo(AInfo, 'AllTalk-TTS', 'f5_tts', 'AllTalk F5-TTS (Clonagem)', AllTalkEp, 'female_01.wav', 24000, False, True, False, False, True, True);

    // OpenVoice v2 (MyShell - Clonagem instantanea de timbre em CPU)
    18: SetSndInfo(AInfo, 'OpenVoice-v2', 'openvoice_v2', 'MyShell OpenVoice v2 (Clonagem CPU/GPU)', OpenVoiceEp, 'PT', 24000, False, True, False, False, True, True);

    // F5-TTS Server
    19: SetSndInfo(AInfo, 'F5-TTS-Server', 'F5-TTS', 'F5-TTS Server (Clonagem Zero-Shot)', F5ServerEp, 'default', 24000, False, True, False, False, True, True);
    20: SetSndInfo(AInfo, 'F5-TTS-Server', 'E2-TTS', 'E2-TTS Server (Clonagem)', F5ServerEp, 'default', 24000, False, True, False, False, True, True);

    // Chatterbox / Fish-Speech (Servidor Aberto Expressivo + Clonagem)
    21: SetSndInfo(AInfo, 'Chatterbox', 'chatterbox', 'Resemble Chatterbox (Clonagem Local)', ChatterboxEp, 'default', 24000, False, True, False, False, True, True);
    22: SetSndInfo(AInfo, 'Chatterbox', 'fish-speech-1.5', 'Fish-Speech 1.5 (Clonagem Rapida)', ChatterboxEp, 'default', 44100, False, True, False, False, True, True);

    // AudioCraft / Bark (Efeitos Sonoros SFX & Musica em servidor aberto)
    23: SetSndInfo(AInfo, 'AudioCraft-Bark', 'facebook/audiogen-medium', 'Meta AudioGen (SFX Aberto)', AudioCraftEp, '', 16000, False, False, True, False, True, True);
    24: SetSndInfo(AInfo, 'AudioCraft-Bark', 'facebook/musicgen-small', 'Meta MusicGen Small (Trilha CPU/GPU)', AudioCraftEp, '', 32000, False, False, False, True, True, True);
    25: SetSndInfo(AInfo, 'AudioCraft-Bark', 'suno/bark-small', 'Suno Bark Small (Voz + Efeitos CPU)', AudioCraftEp, 'v2/pt_speaker_0', 24000, False, False, True, False, True, True);

    // Runtime Python Local sem GPU (aisound_cpu_worker.py)
    26: SetSndInfo(AInfo, 'Local-CPU-Runtime', 'piper-kokoro-cpu', 'Runtime Python CPU (Parakeet/Piper/SFX procedural)', 'local://aisound_cpu_worker.py', 'pt_BR', 22050, False, True, True, True, True, True);

    // Fallback Nativo do Sistema (SAPI / eSpeak)
    27: SetSndInfo(AInfo, 'System-OS', 'system-sapi-espeak', 'Voz Nativa SO (Windows SAPI / eSpeak CPU)', 'system://tts', 'default', 22050, False, False, False, False, True, True);

    // Parakeet TTS (Modelo Texto para Voz preparado no Runtime + servidor HTTP local)
    28: SetSndInfo(AInfo, 'Parakeet', 'parakeet', 'Parakeet TTS (Texto para Voz Runtime CPU/ONNX)', 'local://parakeet', 'pt_BR', 24000, False, False, False, False, True, True);
    29: SetSndInfo(AInfo, 'Parakeet', 'parakeet-server', 'Parakeet HTTP Server (Local CPU/GPU)', ParakeetEp, 'pt_BR', 24000, False, False, False, False, True, True);
  else
    Result := False;
  end;
end;

function FindAISoundModel(const AProvider, AModel: string;
  out AInfo: TAISoundModelInfo): Boolean;
var
  I: Integer;
begin
  for I := 0 to AISoundModelCount - 1 do
    if GetAISoundModelInfo(I, AInfo) and
       ((AProvider = '') or SameText(AInfo.Provider, AProvider)) and
       (SameText(AInfo.InternalName, AModel) or SameText(AInfo.FriendlyName, AModel)) then
      Exit(True);
  Result := False;
end;

procedure GetAISoundProviders(AList: TStrings);
var
  I: Integer;
  Info: TAISoundModelInfo;
begin
  if AList = nil then Exit;
  AList.Clear;
  for I := 0 to AISoundModelCount - 1 do
    if GetAISoundModelInfo(I, Info) and (AList.IndexOf(Info.Provider) < 0) then
      AList.Add(Info.Provider);
end;

procedure GetAISoundModelsForProvider(const AProvider: string; AList: TStrings;
  AIncludeLegacy: Boolean);
var
  I: Integer;
  Info: TAISoundModelInfo;
begin
  if AList = nil then Exit;
  AList.Clear;
  for I := 0 to AISoundModelCount - 1 do
    if GetAISoundModelInfo(I, Info) and SameText(Info.Provider, AProvider) and
       (AIncludeLegacy or not Info.IsLegacy) then
      AList.Add(Info.InternalName);
end;

function GetAISoundDefaultModel(const AProvider: string): string;
var
  I: Integer;
  Info: TAISoundModelInfo;
begin
  Result := '';
  for I := 0 to AISoundModelCount - 1 do
    if GetAISoundModelInfo(I, Info) and SameText(Info.Provider, AProvider) and
       not Info.IsLegacy then
      Exit(Info.InternalName);
end;

end.
