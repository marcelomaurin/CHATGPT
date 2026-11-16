unit aiunifiedvideo;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, aibase, aivideoproviders, aivideomodelcatalog;

type
  TAIUnifiedVideo = class(TAIBaseComponent)
  private
    FProviderKind: TAIVideoProviderKind;
    FEndpoint: string;
    FToken: string;
    FModel: string;
    FSourceImageFile: string;
    FAudioFile: string;
    FOutputFile: string;
    FFfmpegPath: string;
    FWidth: Integer;
    FHeight: Integer;
    FFPS: Integer;
    FDurationSec: Integer;
    FUseGPU: Boolean;
    FTimeout: Integer;
    FProvider: IAIVideoProvider;
  public
    constructor Create(AOwner: TComponent); override;
    function GenerateTextToVideo(const APrompt, AOutputFile: string): Boolean;
    function GenerateImageToVideo(const AImageFile, APrompt, AOutputFile: string): Boolean;
    procedure Cancel;
  published
    property ProviderKind: TAIVideoProviderKind read FProviderKind write FProviderKind default vidLocalFFmpegCPU;
    property Endpoint: string read FEndpoint write FEndpoint;
    property Token: string read FToken write FToken stored False;
    property Model: string read FModel write FModel;
    property SourceImageFile: string read FSourceImageFile write FSourceImageFile;
    property AudioFile: string read FAudioFile write FAudioFile;
    property OutputFile: string read FOutputFile write FOutputFile;
    property FfmpegPath: string read FFfmpegPath write FFfmpegPath;
    property Width: Integer read FWidth write FWidth default 1280;
    property Height: Integer read FHeight write FHeight default 720;
    property FPS: Integer read FFPS write FFPS default 24;
    property DurationSec: Integer read FDurationSec write FDurationSec default 5;
    property UseGPU: Boolean read FUseGPU write FUseGPU default False;
    property Timeout: Integer read FTimeout write FTimeout default 300000;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('AI Video', [TAIUnifiedVideo]);
end;

constructor TAIUnifiedVideo.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FCategory := ccModel;
  FProviderKind := vidLocalFFmpegCPU;
  FWidth := 1280;
  FHeight := 720;
  FFPS := 24;
  FDurationSec := 5;
  FUseGPU := False;
  FTimeout := 300000;
end;

function TAIUnifiedVideo.GenerateTextToVideo(const APrompt,
  AOutputFile: string): Boolean;
var
  Cfg: TAIVideoProviderConfig;
  OutPath: string;
begin
  Result := False;
  ClearError;
  FLastResult := '';

  OutPath := Trim(AOutputFile);
  if OutPath = '' then OutPath := Trim(FOutputFile);
  if OutPath = '' then
  begin
    SetError('OutputFile nao informado para geracao de video.');
    Exit;
  end;

  FProvider := TAIVideoProviderFactory.CreateProvider(FProviderKind);
  if FProvider = nil then
  begin
    SetError('Provedor de video nao encontrado.');
    Exit;
  end;

  InitAIVideoProviderConfig(Cfg);
  Cfg.Endpoint := FEndpoint;
  Cfg.Token := FToken;
  Cfg.Model := FModel;
  Cfg.Prompt := APrompt;
  Cfg.SourceImageFile := FSourceImageFile;
  Cfg.AudioFile := FAudioFile;
  Cfg.OutputFile := OutPath;
  Cfg.FfmpegPath := FFfmpegPath;
  Cfg.Width := FWidth;
  Cfg.Height := FHeight;
  Cfg.FPS := FFPS;
  Cfg.DurationSec := FDurationSec;
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

function TAIUnifiedVideo.GenerateImageToVideo(const AImageFile, APrompt,
  AOutputFile: string): Boolean;
begin
  FSourceImageFile := AImageFile;
  Result := GenerateTextToVideo(APrompt, AOutputFile);
end;

procedure TAIUnifiedVideo.Cancel;
begin
  if FProvider <> nil then
    FProvider.Cancel;
end;

end.
