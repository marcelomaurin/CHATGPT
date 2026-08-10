unit aiunifiedllm;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, aibase, aillmproviders, aicapabilities, aimodelrouter;

type
  { TAIUnifiedLLM }

  TAIUnifiedLLM = class(TAIBaseComponent)
  private
    FProviderKind: TAILLMProviderKind;
    FEndpoint: string;
    FToken: string;
    FModel: string;
    FSystemPrompt: string;
    FTimeout: Integer;
    FMaxTokens: Integer;
    FTemperature: Double;
    FStream: Boolean;
    FAutoRoute: Boolean;
    FPreferLocal: Boolean;
    FRequiredCapabilities: TAICapabilities;
    FRouter: TAIModelRouter;
    FOnStreamData: TAILLMStreamDataEvent;
    FProvider: IAILLMProvider;
    procedure ApplyRouter;
  protected
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
  public
    constructor Create(AOwner: TComponent); override;
    procedure Cancel;
    function Ask(const AUserPrompt: string): Boolean;
    function AskText(const AUserPrompt: string): string;
    function ProviderCapabilities: TAICapabilities;
    function Supports(ACapability: TAICapability): Boolean;
    property RequiredCapabilities: TAICapabilities read FRequiredCapabilities write FRequiredCapabilities;
  published
    property ProviderKind: TAILLMProviderKind read FProviderKind write FProviderKind default llmOpenAICompatible;
    property Endpoint: string read FEndpoint write FEndpoint;
    property Token: string read FToken write FToken;
    property Model: string read FModel write FModel;
    property SystemPrompt: string read FSystemPrompt write FSystemPrompt;
    property Timeout: Integer read FTimeout write FTimeout default 120000;
    property MaxTokens: Integer read FMaxTokens write FMaxTokens default 1000;
    property Temperature: Double read FTemperature write FTemperature;
    property Stream: Boolean read FStream write FStream default False;
    property AutoRoute: Boolean read FAutoRoute write FAutoRoute default False;
    property PreferLocal: Boolean read FPreferLocal write FPreferLocal default True;
    property Router: TAIModelRouter read FRouter write FRouter;
    property OnStreamData: TAILLMStreamDataEvent read FOnStreamData write FOnStreamData;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('AI Core', [TAIUnifiedLLM]);
end;

constructor TAIUnifiedLLM.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FCategory := ccModel;
  FProviderKind := llmOpenAICompatible;
  FTimeout := 120000;
  FMaxTokens := 1000;
  FTemperature := 0.7;
  FStream := False;
  FAutoRoute := False;
  FPreferLocal := True;
  FRequiredCapabilities := [aicChat];
end;

procedure TAIUnifiedLLM.Notification(AComponent: TComponent;
  Operation: TOperation);
begin
  inherited Notification(AComponent, Operation);
  if (Operation = opRemove) and (AComponent = FRouter) then
    FRouter := nil;
end;

procedure TAIUnifiedLLM.ApplyRouter;
var
  R: TAIModelRoute;
begin
  if not FAutoRoute then Exit;
  if FRouter = nil then
    raise Exception.Create('AutoRoute ativo sem TAIModelRouter configurado.');

  FRouter.PreferLocal := FPreferLocal;
  R := FRouter.Select(FRequiredCapabilities);
  if R = nil then
    raise Exception.Create(FRouter.LastError);

  FProviderKind := R.ProviderKind;
  FModel := R.Model;
  FEndpoint := R.Endpoint;
  FToken := R.Token;
end;

function TAIUnifiedLLM.Ask(const AUserPrompt: string): Boolean;
var
  Cfg: TAILLMProviderConfig;
  Answer: string;
begin
  ClearError;
  FLastResult := '';
  Result := False;

  try
    ApplyRouter;
    FProvider := TAILLMProviderFactory.CreateProvider(FProviderKind);
    if FProvider = nil then
      raise Exception.Create('Nao foi possivel criar provider LLM.');

    InitAILLMProviderConfig(Cfg);
    Cfg.Endpoint := FEndpoint;
    Cfg.Token := FToken;
    Cfg.Model := FModel;
    Cfg.SystemPrompt := FSystemPrompt;
    Cfg.UserPrompt := AUserPrompt;
    Cfg.Timeout := FTimeout;
    Cfg.MaxTokens := FMaxTokens;
    Cfg.Temperature := FTemperature;
    Cfg.Stream := FStream;

    Result := FProvider.Send(Cfg, FOnStreamData, Answer);
    if Result then
    begin
      FLastResult := Answer;
      FLastSuccess := True;
    end
    else
      SetError(FProvider.GetLastError);
  except
    on E: Exception do
      SetError(E.Message);
  end;
end;

function TAIUnifiedLLM.AskText(const AUserPrompt: string): string;
begin
  if Ask(AUserPrompt) then
    Result := FLastResult
  else
    Result := '';
end;

procedure TAIUnifiedLLM.Cancel;
begin
  if FProvider <> nil then
    FProvider.Cancel;
end;

function TAIUnifiedLLM.ProviderCapabilities: TAICapabilities;
var
  Registry: TAICapabilityRegistry;
begin
  Registry := TAICapabilityRegistry.Create(nil);
  try
    Result := Registry.CapabilitiesOf(FProviderKind);
  finally
    Registry.Free;
  end;
end;

function TAIUnifiedLLM.Supports(ACapability: TAICapability): Boolean;
begin
  Result := ACapability in ProviderCapabilities;
end;

end.
