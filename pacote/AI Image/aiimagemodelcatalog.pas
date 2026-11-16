unit aiimagemodelcatalog;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils;

type
  TAIImageModelInfo = record
    IsLegacy: Boolean;
    Provider: string;
    InternalName: string;
    FriendlyName: string;
    DefaultEndpoint: string;
    DefaultWidth: Integer;
    DefaultHeight: Integer;
    RequiresAPIKey: Boolean;
    RunsOnCPUWithoutGPU: Boolean;
    IsLocalServer: Boolean;
    SupportsNegativePrompt: Boolean;
    SupportsImg2Img: Boolean;
  end;

function AIImageModelCount: Integer;
function GetAIImageModelInfo(AIndex: Integer; out AInfo: TAIImageModelInfo): Boolean;
function FindAIImageModel(const AProvider, AModel: string;
  out AInfo: TAIImageModelInfo): Boolean;
procedure GetAIImageProviders(AList: TStrings);
procedure GetAIImageModelsForProvider(const AProvider: string; AList: TStrings;
  AIncludeLegacy: Boolean = False);
function GetAIImageDefaultModel(const AProvider: string): string;

implementation

procedure SetImgInfo(out AInfo: TAIImageModelInfo; const AProvider, AInternal,
  AFriendly, AEndpoint: string; W, H: Integer;
  AReqKey, ACpuOk, ALocal, ANeg, AImg2Img: Boolean);
begin
  AInfo.IsLegacy := False;
  AInfo.Provider := AProvider;
  AInfo.InternalName := AInternal;
  AInfo.FriendlyName := AFriendly;
  AInfo.DefaultEndpoint := AEndpoint;
  AInfo.DefaultWidth := W;
  AInfo.DefaultHeight := H;
  AInfo.RequiresAPIKey := AReqKey;
  AInfo.RunsOnCPUWithoutGPU := ACpuOk;
  AInfo.IsLocalServer := ALocal;
  AInfo.SupportsNegativePrompt := ANeg;
  AInfo.SupportsImg2Img := AImg2Img;
end;

function AIImageModelCount: Integer;
begin
  Result := 21;
end;

function GetAIImageModelInfo(AIndex: Integer; out AInfo: TAIImageModelInfo): Boolean;
const
  OpenAIImgEp = 'https://api.openai.com/v1/images/generations';
  GeminiImgEp = 'https://generativelanguage.googleapis.com/v1beta/models/';
  StabilityEp = 'https://api.stability.ai/v2beta/stable-image/generate/sd3';
  BflEp       = 'https://api.bfl.ml/v1/flux-pro-1.1';
  ComfyEp     = 'http://127.0.0.1:8188/prompt';
  A1111Ep     = 'http://127.0.0.1:7860/sdapi/v1/txt2img';
  HFEp        = 'https://api-inference.huggingface.co/models/';
  CompatEp    = 'http://127.0.0.1:8080/v1/images/generations';
begin
  Result := True;
  case AIndex of
    // OpenAI
    0: SetImgInfo(AInfo, 'OpenAI', 'gpt-image-1', 'GPT Image 1 (OpenAI)', OpenAIImgEp, 1024, 1024, True, False, False, False, True);
    1: SetImgInfo(AInfo, 'OpenAI', 'dall-e-3', 'DALL-E 3 (OpenAI)', OpenAIImgEp, 1024, 1024, True, False, False, False, False);
    2: SetImgInfo(AInfo, 'OpenAI', 'dall-e-2', 'DALL-E 2 (OpenAI)', OpenAIImgEp, 1024, 1024, True, False, False, False, True);

    // Google Gemini / Imagen
    3: SetImgInfo(AInfo, 'Gemini', 'imagen-3.0-generate-002', 'Imagen 3.0 (Google)', GeminiImgEp, 1024, 1024, True, False, False, True, False);
    4: SetImgInfo(AInfo, 'Gemini', 'gemini-2.0-flash-exp-image-generation', 'Gemini 2.0 Flash Image', GeminiImgEp, 1024, 1024, True, False, False, False, True);

    // Stability AI
    5: SetImgInfo(AInfo, 'Stability', 'sd3.5-large', 'Stable Diffusion 3.5 Large', StabilityEp, 1024, 1024, True, False, False, True, True);
    6: SetImgInfo(AInfo, 'Stability', 'sd3.5-medium', 'Stable Diffusion 3.5 Medium', StabilityEp, 1024, 1024, True, False, False, True, True);
    7: SetImgInfo(AInfo, 'Stability', 'stable-image-ultra', 'Stable Image Ultra', StabilityEp, 1024, 1024, True, False, False, True, False);

    // Black Forest Labs (Flux)
    8: SetImgInfo(AInfo, 'BlackForestLabs', 'flux-pro-1.1', 'FLUX 1.1 Pro (BFL)', BflEp, 1024, 1024, True, False, False, False, False);
    9: SetImgInfo(AInfo, 'BlackForestLabs', 'flux-dev', 'FLUX.1 Dev (BFL)', BflEp, 1024, 1024, True, False, False, False, False);
    10: SetImgInfo(AInfo, 'BlackForestLabs', 'flux-schnell', 'FLUX.1 Schnell (BFL)', BflEp, 1024, 1024, True, False, False, False, False);

    // ComfyUI (Servidor local aberto, CPU ou GPU)
    11: SetImgInfo(AInfo, 'ComfyUI', 'sdxl_turbo_1.0_fp16.safetensors', 'SDXL Turbo (ComfyUI Local/CPU)', ComfyEp, 512, 512, False, True, True, True, True);
    12: SetImgInfo(AInfo, 'ComfyUI', 'v1-5-pruned-emaonly.safetensors', 'SD 1.5 (ComfyUI CPU-friendly)', ComfyEp, 512, 512, False, True, True, True, True);
    13: SetImgInfo(AInfo, 'ComfyUI', 'flux1-schnell-fp8.safetensors', 'FLUX.1 Schnell (ComfyUI)', ComfyEp, 1024, 1024, False, False, True, True, True);

    // Automatic1111 / Forge WebUI (Servidor local aberto, CPU ou GPU)
    14: SetImgInfo(AInfo, 'Automatic1111', 'sd_xl_turbo_1.0', 'SDXL Turbo (A1111/Forge CPU)', A1111Ep, 512, 512, False, True, True, True, True);
    15: SetImgInfo(AInfo, 'Automatic1111', 'v1-5-pruned-emaonly', 'SD 1.5 (A1111/Forge CPU)', A1111Ep, 512, 512, False, True, True, True, True);
    16: SetImgInfo(AInfo, 'Automatic1111', 'sd_xl_base_1.0', 'SDXL Base 1.0 (A1111/Forge)', A1111Ep, 1024, 1024, False, True, True, True, True);

    // HuggingFace Inference API
    17: SetImgInfo(AInfo, 'HuggingFace', 'black-forest-labs/FLUX.1-schnell', 'FLUX.1 Schnell (HuggingFace)', HFEp, 1024, 1024, True, False, False, False, False);
    18: SetImgInfo(AInfo, 'HuggingFace', 'stabilityai/stable-diffusion-xl-base-1.0', 'SDXL 1.0 (HuggingFace)', HFEp, 1024, 1024, True, False, False, True, False);

    // OpenAI-compatible (LocalAI / sd.cpp server CPU)
    19: SetImgInfo(AInfo, 'OpenAI-compatible', 'stablediffusion', 'StableDiffusion.cpp / LocalAI (CPU)', CompatEp, 512, 512, False, True, True, True, False);
    20: SetImgInfo(AInfo, 'OpenAI-compatible', 'custom-image-model', 'Custom Image Server', CompatEp, 1024, 1024, False, True, True, True, False);
  else
    Result := False;
  end;
end;

function FindAIImageModel(const AProvider, AModel: string;
  out AInfo: TAIImageModelInfo): Boolean;
var
  I: Integer;
begin
  for I := 0 to AIImageModelCount - 1 do
    if GetAIImageModelInfo(I, AInfo) and
       ((AProvider = '') or SameText(AInfo.Provider, AProvider)) and
       (SameText(AInfo.InternalName, AModel) or SameText(AInfo.FriendlyName, AModel)) then
      Exit(True);
  Result := False;
end;

procedure GetAIImageProviders(AList: TStrings);
var
  I: Integer;
  Info: TAIImageModelInfo;
begin
  if AList = nil then Exit;
  AList.Clear;
  for I := 0 to AIImageModelCount - 1 do
    if GetAIImageModelInfo(I, Info) and (AList.IndexOf(Info.Provider) < 0) then
      AList.Add(Info.Provider);
end;

procedure GetAIImageModelsForProvider(const AProvider: string; AList: TStrings;
  AIncludeLegacy: Boolean);
var
  I: Integer;
  Info: TAIImageModelInfo;
begin
  if AList = nil then Exit;
  AList.Clear;
  for I := 0 to AIImageModelCount - 1 do
    if GetAIImageModelInfo(I, Info) and SameText(Info.Provider, AProvider) and
       (AIncludeLegacy or not Info.IsLegacy) then
      AList.Add(Info.InternalName);
end;

function GetAIImageDefaultModel(const AProvider: string): string;
var
  I: Integer;
  Info: TAIImageModelInfo;
begin
  Result := '';
  for I := 0 to AIImageModelCount - 1 do
    if GetAIImageModelInfo(I, Info) and SameText(Info.Provider, AProvider) and
       not Info.IsLegacy then
      Exit(Info.InternalName);
end;

end.
