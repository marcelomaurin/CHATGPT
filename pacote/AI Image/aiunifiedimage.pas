unit aiunifiedimage;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, aibase, aiimageproviders, aiimagemodelcatalog;

type
  TAIUnifiedImage = class(TAIBaseComponent)
  private
    FProviderKind: TAIImageProviderKind;
    FEndpoint: string;
    FToken: string;
    FModel: string;
    FNegativePrompt: string;
    FWidth: Integer;
    FHeight: Integer;
    FSteps: Integer;
    FSeed: Int64;
    FQuality: string;
    FStyle: string;
    FOutputFile: string;
    FUseGPU: Boolean;
    FTimeout: Integer;
    FProvider: IAIImageProvider;
  public
    constructor Create(AOwner: TComponent); override;
    function Generate(const APrompt: string; const AOutputFile: string = ''): Boolean;
    function GenerateToFile(const APrompt, AOutputFile: string): Boolean;
    procedure Cancel;
  published
    property ProviderKind: TAIImageProviderKind read FProviderKind write FProviderKind default imgOpenAICompatible;
    property Endpoint: string read FEndpoint write FEndpoint;
    property Token: string read FToken write FToken stored False;
    property Model: string read FModel write FModel;
    property NegativePrompt: string read FNegativePrompt write FNegativePrompt;
    property Width: Integer read FWidth write FWidth default 1024;
    property Height: Integer read FHeight write FHeight default 1024;
    property Steps: Integer read FSteps write FSteps default 20;
    property Seed: Int64 read FSeed write FSeed default -1;
    property Quality: string read FQuality write FQuality;
    property Style: string read FStyle write FStyle;
    property OutputFile: string read FOutputFile write FOutputFile;
    property UseGPU: Boolean read FUseGPU write FUseGPU default False;
    property Timeout: Integer read FTimeout write FTimeout default 180000;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('AI Image', [TAIUnifiedImage]);
end;

constructor TAIUnifiedImage.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FCategory := ccModel;
  FProviderKind := imgOpenAICompatible;
  FWidth := 1024;
  FHeight := 1024;
  FSteps := 20;
  FSeed := -1;
  FQuality := 'standard';
  FUseGPU := False;
  FTimeout := 180000;
end;

function TAIUnifiedImage.Generate(const APrompt: string;
  const AOutputFile: string): Boolean;
var
  Cfg: TAIImageProviderConfig;
  OutPath: string;
begin
  Result := False;
  ClearError;
  FLastResult := '';

  OutPath := Trim(AOutputFile);
  if OutPath = '' then OutPath := Trim(FOutputFile);
  if OutPath = '' then
  begin
    SetError('OutputFile nao informado para geracao de imagem.');
    Exit;
  end;

  FProvider := TAIImageProviderFactory.CreateProvider(FProviderKind);
  if FProvider = nil then
  begin
    SetError('Provedor de imagem nao encontrado.');
    Exit;
  end;

  InitAIImageProviderConfig(Cfg);
  Cfg.Endpoint := FEndpoint;
  Cfg.Token := FToken;
  Cfg.Model := FModel;
  Cfg.Prompt := APrompt;
  Cfg.NegativePrompt := FNegativePrompt;
  Cfg.Width := FWidth;
  Cfg.Height := FHeight;
  Cfg.Steps := FSteps;
  Cfg.Seed := FSeed;
  Cfg.Quality := FQuality;
  Cfg.Style := FStyle;
  Cfg.OutputFile := OutPath;
  Cfg.UseGPU := FUseGPU;
  Cfg.Timeout := FTimeout;

  if FProvider.Generate(Cfg, OutPath) then
  begin
    FLastResult := OutPath;
    FLastSuccess := True;
    Result := True;
  end
  else
    SetError(FProvider.GetLastError);
end;

function TAIUnifiedImage.GenerateToFile(const APrompt,
  AOutputFile: string): Boolean;
begin
  Result := Generate(APrompt, AOutputFile);
end;

procedure TAIUnifiedImage.Cancel;
begin
  if FProvider <> nil then
    FProvider.Cancel;
end;

end.
