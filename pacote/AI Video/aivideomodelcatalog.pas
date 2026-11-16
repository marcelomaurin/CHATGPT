unit aivideomodelcatalog;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils;

type
  TAIVideoModelInfo = record
    IsLegacy: Boolean;
    Provider: string;
    InternalName: string;
    FriendlyName: string;
    DefaultEndpoint: string;
    DefaultWidth: Integer;
    DefaultHeight: Integer;
    DefaultFPS: Integer;
    MaxDurationSec: Integer;
    RequiresAPIKey: Boolean;
    SupportsImageToVideo: Boolean;
    RunsOnCPUWithoutGPU: Boolean;
    IsLocalServer: Boolean;
  end;

function AIVideoModelCount: Integer;
function GetAIVideoModelInfo(AIndex: Integer; out AInfo: TAIVideoModelInfo): Boolean;
function FindAIVideoModel(const AProvider, AModel: string;
  out AInfo: TAIVideoModelInfo): Boolean;
procedure GetAIVideoProviders(AList: TStrings);
procedure GetAIVideoModelsForProvider(const AProvider: string; AList: TStrings;
  AIncludeLegacy: Boolean = False);
function GetAIVideoDefaultModel(const AProvider: string): string;

implementation

procedure SetVidInfo(out AInfo: TAIVideoModelInfo; const AProvider, AInternal,
  AFriendly, AEndpoint: string; W, H, FPS, MaxSec: Integer;
  AReqKey, AImg2Vid, ACpuOk, ALocal: Boolean);
begin
  AInfo.IsLegacy := False;
  AInfo.Provider := AProvider;
  AInfo.InternalName := AInternal;
  AInfo.FriendlyName := AFriendly;
  AInfo.DefaultEndpoint := AEndpoint;
  AInfo.DefaultWidth := W;
  AInfo.DefaultHeight := H;
  AInfo.DefaultFPS := FPS;
  AInfo.MaxDurationSec := MaxSec;
  AInfo.RequiresAPIKey := AReqKey;
  AInfo.SupportsImageToVideo := AImg2Vid;
  AInfo.RunsOnCPUWithoutGPU := ACpuOk;
  AInfo.IsLocalServer := ALocal;
end;

function AIVideoModelCount: Integer;
begin
  Result := 17;
end;

function GetAIVideoModelInfo(AIndex: Integer; out AInfo: TAIVideoModelInfo): Boolean;
const
  SoraEp    = 'https://api.openai.com/v1/videos';
  VeoEp     = 'https://generativelanguage.googleapis.com/v1beta/models/';
  RunwayEp  = 'https://api.dev.runwayml.com/v1/image_to_video';
  KlingEp   = 'https://api.klingai.com/v1/videos/text2video';
  LumaEp    = 'https://api.lumalabs.ai/dream-machine/v1/generations';
  ComfyEp   = 'http://127.0.0.1:8188/prompt';
  CompatEp  = 'http://127.0.0.1:8080/v1/videos';
begin
  Result := True;
  case AIndex of
    // OpenAI Sora
    0: SetVidInfo(AInfo, 'OpenAI-Sora', 'sora-2', 'Sora 2 (OpenAI)', SoraEp, 1280, 720, 24, 20, True, True, False, False);
    1: SetVidInfo(AInfo, 'OpenAI-Sora', 'sora-2-pro', 'Sora 2 Pro (OpenAI)', SoraEp, 1920, 1080, 24, 20, True, True, False, False);

    // Google Veo
    2: SetVidInfo(AInfo, 'Google-Veo', 'veo-3.0-generate-preview', 'Veo 3.0 (Google)', VeoEp, 1280, 720, 24, 8, True, True, False, False);
    3: SetVidInfo(AInfo, 'Google-Veo', 'veo-2.0-generate-001', 'Veo 2.0 (Google)', VeoEp, 1280, 720, 24, 8, True, True, False, False);

    // Runway
    4: SetVidInfo(AInfo, 'Runway', 'gen4_turbo', 'Runway Gen-4 Turbo', RunwayEp, 1280, 720, 24, 10, True, True, False, False);
    5: SetVidInfo(AInfo, 'Runway', 'gen3a_turbo', 'Runway Gen-3 Alpha Turbo', RunwayEp, 1280, 768, 24, 10, True, True, False, False);

    // Kling AI
    6: SetVidInfo(AInfo, 'Kling', 'kling-v2-master', 'Kling v2 Master', KlingEp, 1280, 720, 24, 10, True, True, False, False);
    7: SetVidInfo(AInfo, 'Kling', 'kling-v1-6', 'Kling v1.6', KlingEp, 1280, 720, 24, 10, True, True, False, False);

    // Luma Dream Machine
    8: SetVidInfo(AInfo, 'Luma', 'ray-2', 'Luma Ray 2', LumaEp, 1280, 720, 24, 9, True, True, False, False);
    9: SetVidInfo(AInfo, 'Luma', 'ray-flash-2', 'Luma Ray Flash 2', LumaEp, 1280, 720, 24, 9, True, True, False, False);

    // ComfyUI Video (Servidor aberto local)
    10: SetVidInfo(AInfo, 'ComfyUI-Video', 'wan2.1_t2v_1.3B_fp16.safetensors', 'Wan 2.1 1.3B (ComfyUI Local)', ComfyEp, 832, 480, 16, 5, False, True, False, True);
    11: SetVidInfo(AInfo, 'ComfyUI-Video', 'ltx-video-2b-v0.9.5.safetensors', 'LTX-Video 2B (ComfyUI Rapido)', ComfyEp, 768, 512, 24, 5, False, True, False, True);
    12: SetVidInfo(AInfo, 'ComfyUI-Video', 'animatediff_v3', 'AnimateDiff v3 (ComfyUI CPU/GPU)', ComfyEp, 512, 512, 16, 4, False, True, True, True);
    13: SetVidInfo(AInfo, 'ComfyUI-Video', 'hunyuanvideo_t2v', 'HunyuanVideo (ComfyUI)', ComfyEp, 1280, 720, 24, 5, False, False, False, True);

    // Local FFmpeg CPU Runtime (sem GPU!)
    14: SetVidInfo(AInfo, 'FFmpeg-CPU', 'ffmpeg-kenburns-cpu', 'FFmpeg Ken Burns / Movimento CPU (sem GPU)', 'local://ffmpeg', 1280, 720, 24, 120, False, True, True, True);
    15: SetVidInfo(AInfo, 'FFmpeg-CPU', 'ffmpeg-storyboard-cpu', 'FFmpeg Card + Audio CPU (sem GPU)', 'local://ffmpeg', 1280, 720, 24, 120, False, True, True, True);

    // OpenAI-compatible Video
    16: SetVidInfo(AInfo, 'OpenAI-compatible', 'custom-video-model', 'Servidor Video Compativel', CompatEp, 1280, 720, 24, 15, False, True, True, True);
  else
    Result := False;
  end;
end;

function FindAIVideoModel(const AProvider, AModel: string;
  out AInfo: TAIVideoModelInfo): Boolean;
var
  I: Integer;
begin
  for I := 0 to AIVideoModelCount - 1 do
    if GetAIVideoModelInfo(I, AInfo) and
       ((AProvider = '') or SameText(AInfo.Provider, AProvider)) and
       (SameText(AInfo.InternalName, AModel) or SameText(AInfo.FriendlyName, AModel)) then
      Exit(True);
  Result := False;
end;

procedure GetAIVideoProviders(AList: TStrings);
var
  I: Integer;
  Info: TAIVideoModelInfo;
begin
  if AList = nil then Exit;
  AList.Clear;
  for I := 0 to AIVideoModelCount - 1 do
    if GetAIVideoModelInfo(I, Info) and (AList.IndexOf(Info.Provider) < 0) then
      AList.Add(Info.Provider);
end;

procedure GetAIVideoModelsForProvider(const AProvider: string; AList: TStrings;
  AIncludeLegacy: Boolean);
var
  I: Integer;
  Info: TAIVideoModelInfo;
begin
  if AList = nil then Exit;
  AList.Clear;
  for I := 0 to AIVideoModelCount - 1 do
    if GetAIVideoModelInfo(I, Info) and SameText(Info.Provider, AProvider) and
       (AIncludeLegacy or not Info.IsLegacy) then
      AList.Add(Info.InternalName);
end;

function GetAIVideoDefaultModel(const AProvider: string): string;
var
  I: Integer;
  Info: TAIVideoModelInfo;
begin
  Result := '';
  for I := 0 to AIVideoModelCount - 1 do
    if GetAIVideoModelInfo(I, Info) and SameText(Info.Provider, AProvider) and
       not Info.IsLegacy then
      Exit(Info.InternalName);
end;

end.
