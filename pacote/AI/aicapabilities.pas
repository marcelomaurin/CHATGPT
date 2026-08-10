unit aicapabilities;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, aillmproviders;

type
  TAICapability = (
    aicChat,
    aicStreaming,
    aicTools,
    aicJSON,
    aicVision,
    aicEmbeddings,
    aicSTT,
    aicTTS,
    aicVideo,
    aicTraining,
    aicLocal,
    aicTemperature
  );
  TAICapabilities = set of TAICapability;

  { TAICapabilityRegistry }

  TAICapabilityRegistry = class(TComponent)
  private
    FOverrides: TStringList;
    function ProviderKey(AKind: TAILLMProviderKind): string;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    function DefaultCapabilities(AKind: TAILLMProviderKind): TAICapabilities;
    function CapabilitiesOf(AKind: TAILLMProviderKind): TAICapabilities;
    function Supports(AKind: TAILLMProviderKind; ACapability: TAICapability): Boolean;
    procedure SetCapabilities(AKind: TAILLMProviderKind; const ACapabilities: TAICapabilities);
    procedure ClearOverride(AKind: TAILLMProviderKind);
    function CapabilitiesAsText(AKind: TAILLMProviderKind): string;
  end;

function AICapabilityName(ACapability: TAICapability): string;

implementation

function AICapabilityName(ACapability: TAICapability): string;
begin
  case ACapability of
    aicChat: Result := 'chat';
    aicStreaming: Result := 'streaming';
    aicTools: Result := 'tools';
    aicJSON: Result := 'json';
    aicVision: Result := 'vision';
    aicEmbeddings: Result := 'embeddings';
    aicSTT: Result := 'stt';
    aicTTS: Result := 'tts';
    aicVideo: Result := 'video';
    aicTraining: Result := 'training';
    aicLocal: Result := 'local';
    aicTemperature: Result := 'temperature';
  else
    Result := 'unknown';
  end;
end;

constructor TAICapabilityRegistry.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FOverrides := TStringList.Create;
  FOverrides.CaseSensitive := False;
  FOverrides.NameValueSeparator := '=';
end;

destructor TAICapabilityRegistry.Destroy;
begin
  FOverrides.Free;
  inherited Destroy;
end;

function TAICapabilityRegistry.ProviderKey(AKind: TAILLMProviderKind): string;
begin
  Result := IntToStr(Ord(AKind));
end;

function TAICapabilityRegistry.DefaultCapabilities(
  AKind: TAILLMProviderKind): TAICapabilities;
begin
  Result := [aicChat, aicJSON];

  case AKind of
    llmOpenAI,
    llmOpenAICompatible,
    llmLlamaCpp,
    llmNeuralAPI,
    llmDeepSeek,
    llmOpenRouter,
    llmCerebras,
    llmOllama:
      Include(Result, aicStreaming);
  end;

  case AKind of
    llmOpenAI,
    llmOpenAICompatible,
    llmGemini,
    llmClaude,
    llmDeepSeek,
    llmOpenRouter:
      Include(Result, aicTools);
  end;

  case AKind of
    llmOpenAI,
    llmGemini,
    llmClaude,
    llmOpenRouter:
      Include(Result, aicVision);
  end;

  case AKind of
    llmOpenAI,
    llmOpenAICompatible,
    llmLlamaCpp,
    llmNeuralAPI,
    llmOllama,
    llmOpenRouter:
      Include(Result, aicEmbeddings);
  end;

  case AKind of
    llmLlamaCpp,
    llmNeuralAPI,
    llmOllama:
      Include(Result, aicLocal);
  end;

  if AKind <> llmGemini then
    Include(Result, aicTemperature);
end;

function TAICapabilityRegistry.CapabilitiesOf(
  AKind: TAILLMProviderKind): TAICapabilities;
var
  S: string;
  I, N: Integer;
  C: TAICapability;
begin
  Result := DefaultCapabilities(AKind);
  S := FOverrides.Values[ProviderKey(AKind)];
  if S = '' then
    Exit;

  Result := [];
  for I := 1 to Length(S) do
    if S[I] = '1' then
    begin
      N := I - 1;
      if N <= Ord(High(TAICapability)) then
      begin
        C := TAICapability(N);
        Include(Result, C);
      end;
    end;
end;

function TAICapabilityRegistry.Supports(AKind: TAILLMProviderKind;
  ACapability: TAICapability): Boolean;
begin
  Result := ACapability in CapabilitiesOf(AKind);
end;

procedure TAICapabilityRegistry.SetCapabilities(AKind: TAILLMProviderKind;
  const ACapabilities: TAICapabilities);
var
  C: TAICapability;
  S: string;
begin
  S := '';
  for C := Low(TAICapability) to High(TAICapability) do
    if C in ACapabilities then
      S := S + '1'
    else
      S := S + '0';
  FOverrides.Values[ProviderKey(AKind)] := S;
end;

procedure TAICapabilityRegistry.ClearOverride(AKind: TAILLMProviderKind);
var
  I: Integer;
begin
  I := FOverrides.IndexOfName(ProviderKey(AKind));
  if I >= 0 then
    FOverrides.Delete(I);
end;

function TAICapabilityRegistry.CapabilitiesAsText(
  AKind: TAILLMProviderKind): string;
var
  C: TAICapability;
  Caps: TAICapabilities;
begin
  Result := '';
  Caps := CapabilitiesOf(AKind);
  for C := Low(TAICapability) to High(TAICapability) do
    if C in Caps then
    begin
      if Result <> '' then
        Result := Result + ',';
      Result := Result + AICapabilityName(C);
    end;
end;

end.
