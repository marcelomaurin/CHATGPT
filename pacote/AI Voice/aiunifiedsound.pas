unit aiunifiedsound;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, aibase, aivoiceclonetypes, aisoundproviders,
  aisoundmodelcatalog, aisoundruntime;

type
  TAIUnifiedSound = class(TAIBaseComponent)
  private
    FProviderKind: TAISoundProviderKind;
    FTaskKind: TAISoundTaskKind;
    FEndpoint: string;
    FToken: string;
    FModel: string;
    FVoice: string;
    FLanguage: string;
    FReferenceAudio: string;
    FOutputFile: string;
    FOutputFormat: string;
    FSpeed: Double;
    FDurationSec: Double;
    FUseGPU: Boolean;
    FPythonPath: string;
    FWorkerPath: string;
    FRequireConsent: Boolean;
    FConsentConfirmed: Boolean;
    FVoiceOwner: string;
    FTimeout: Integer;
    FProvider: IAISoundProvider;
  public
    constructor Create(AOwner: TComponent); override;
    function SynthesizeToFile(const AText, AOutputFile: string): Boolean;
    function CloneAndSynthesize(const AText, ARefAudioFile, AOutputFile: string): Boolean;
    function GenerateSFX(const APrompt, AOutputFile: string; ADurationSec: Double = 4.0): Boolean;
    function GenerateMusic(const APrompt, AOutputFile: string; ADurationSec: Double = 8.0): Boolean;
    procedure DiscoverLocalServers(AList: TStrings);
    procedure Cancel;
  published
    property ProviderKind: TAISoundProviderKind read FProviderKind write FProviderKind default sndKokoroFastAPI;
    property TaskKind: TAISoundTaskKind read FTaskKind write FTaskKind default stkSpeech;
    property Endpoint: string read FEndpoint write FEndpoint;
    property Token: string read FToken write FToken stored False;
    property Model: string read FModel write FModel;
    property Voice: string read FVoice write FVoice;
    property Language: string read FLanguage write FLanguage;
    property ReferenceAudio: string read FReferenceAudio write FReferenceAudio;
    property OutputFile: string read FOutputFile write FOutputFile;
    property OutputFormat: string read FOutputFormat write FOutputFormat;
    property Speed: Double read FSpeed write FSpeed;
    property DurationSec: Double read FDurationSec write FDurationSec;
    property UseGPU: Boolean read FUseGPU write FUseGPU default False;
    property PythonPath: string read FPythonPath write FPythonPath;
    property WorkerPath: string read FWorkerPath write FWorkerPath;
    property RequireConsent: Boolean read FRequireConsent write FRequireConsent default True;
    property ConsentConfirmed: Boolean read FConsentConfirmed write FConsentConfirmed default False;
    property VoiceOwner: string read FVoiceOwner write FVoiceOwner;
    property Timeout: Integer read FTimeout write FTimeout default 180000;
  end;

  { Adaptador IAIVoiceCloneEngine para ligar TAIVoiceClone aos servidores HTTP abertos ou Runtime CPU }
  TAIHttpVoiceCloneEngine = class(TAIBaseComponent, IAIVoiceCloneEngine)
  private
    FProviderKind: TAISoundProviderKind;
    FEndpoint: string;
    FToken: string;
    FModelPath: string;
    FUseGPU: Boolean;
    FPythonPath: string;
    FTimeoutMs: Integer;
    FActiveProvider: IAISoundProvider;
  public
    constructor Create(AOwner: TComponent); override;
    function CreateVoice(AProfile: TAIVoiceProfile; out AError: string): Boolean;
    function Synthesize(AProfile: TAIVoiceProfile; const AText,
      AOutputFile: string; out ARealOutputFile, AError: string): Boolean;
    procedure Cancel;
  published
    property ProviderKind: TAISoundProviderKind read FProviderKind write FProviderKind default sndCoquiXTTS;
    property Endpoint: string read FEndpoint write FEndpoint;
    property Token: string read FToken write FToken stored False;
    property ModelPath: string read FModelPath write FModelPath;
    property UseGPU: Boolean read FUseGPU write FUseGPU default False;
    property PythonPath: string read FPythonPath write FPythonPath;
    property TimeoutMs: Integer read FTimeoutMs write FTimeoutMs default 180000;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('AI Voice', [TAIUnifiedSound, TAIHttpVoiceCloneEngine]);
end;

{ TAIUnifiedSound }

constructor TAIUnifiedSound.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FCategory := ccOutput;
  FProviderKind := sndKokoroFastAPI;
  FTaskKind := stkSpeech;
  FLanguage := 'pt';
  FOutputFormat := 'wav';
  FSpeed := 1.0;
  FDurationSec := 4.0;
  FUseGPU := False;
  FRequireConsent := True;
  FConsentConfirmed := False;
  FTimeout := 180000;
end;

function TAIUnifiedSound.SynthesizeToFile(const AText,
  AOutputFile: string): Boolean;
var
  Cfg: TAISoundProviderConfig;
  OutPath: string;
begin
  Result := False;
  ClearError;
  FLastResult := '';

  OutPath := Trim(AOutputFile);
  if OutPath = '' then OutPath := Trim(FOutputFile);
  if OutPath = '' then
  begin
    SetError('OutputFile nao informado para geracao de audio.');
    Exit;
  end;

  if (FTaskKind = stkVoiceClone) and FRequireConsent and (not FConsentConfirmed) then
  begin
    SetError('Clonagem de voz bloqueada: consentimento explicito nao confirmado.');
    Exit;
  end;

  FProvider := TAISoundProviderFactory.CreateProvider(FProviderKind);
  if FProvider = nil then
  begin
    SetError('Provedor de som nao encontrado.');
    Exit;
  end;

  InitAISoundProviderConfig(Cfg);
  Cfg.TaskKind := FTaskKind;
  Cfg.Endpoint := FEndpoint;
  Cfg.Token := FToken;
  Cfg.Model := FModel;
  Cfg.Voice := FVoice;
  Cfg.Language := FLanguage;
  Cfg.TextOrPrompt := AText;
  Cfg.ReferenceAudio := FReferenceAudio;
  Cfg.OutputFile := OutPath;
  Cfg.OutputFormat := FOutputFormat;
  Cfg.Speed := FSpeed;
  Cfg.DurationSec := FDurationSec;
  Cfg.UseGPU := FUseGPU;
  Cfg.PythonPath := FPythonPath;
  Cfg.WorkerPath := FWorkerPath;
  Cfg.Timeout := FTimeout;

  if FProvider.Synthesize(Cfg, OutPath) then
  begin
    FLastResult := OutPath;
    FLastSuccess := True;
    Result := True;
  end
  else
    SetError(FProvider.GetLastError);
end;

function TAIUnifiedSound.CloneAndSynthesize(const AText, ARefAudioFile,
  AOutputFile: string): Boolean;
begin
  FTaskKind := stkVoiceClone;
  FReferenceAudio := ARefAudioFile;
  Result := SynthesizeToFile(AText, AOutputFile);
end;

function TAIUnifiedSound.GenerateSFX(const APrompt, AOutputFile: string;
  ADurationSec: Double): Boolean;
begin
  FTaskKind := stkSFX;
  FDurationSec := ADurationSec;
  Result := SynthesizeToFile(APrompt, AOutputFile);
end;

function TAIUnifiedSound.GenerateMusic(const APrompt, AOutputFile: string;
  ADurationSec: Double): Boolean;
begin
  FTaskKind := stkMusic;
  FDurationSec := ADurationSec;
  Result := SynthesizeToFile(APrompt, AOutputFile);
end;

procedure TAIUnifiedSound.DiscoverLocalServers(AList: TStrings);
begin
  DiscoverLocalSoundServers(AList);
end;

procedure TAIUnifiedSound.Cancel;
begin
  if FProvider <> nil then
    FProvider.Cancel;
end;

{ TAIHttpVoiceCloneEngine }

constructor TAIHttpVoiceCloneEngine.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FCategory := ccModel;
  FProviderKind := sndCoquiXTTS;
  FUseGPU := False;
  FTimeoutMs := 180000;
end;

function TAIHttpVoiceCloneEngine.CreateVoice(AProfile: TAIVoiceProfile;
  out AError: string): Boolean;
begin
  Result := False;
  AError := '';
  if AProfile = nil then
  begin
    AError := 'Perfil de voz nulo.';
    SetError(AError);
    Exit;
  end;
  if (Trim(AProfile.ReferenceAudio) = '') or (not FileExists(AProfile.ReferenceAudio)) then
  begin
    AError := 'Audio de referencia nao encontrado: ' + AProfile.ReferenceAudio;
    SetError(AError);
    Exit;
  end;
  ClearError;
  Result := True;
end;

function TAIHttpVoiceCloneEngine.Synthesize(AProfile: TAIVoiceProfile;
  const AText, AOutputFile: string; out ARealOutputFile,
  AError: string): Boolean;
var
  Cfg: TAISoundProviderConfig;
begin
  Result := False;
  ARealOutputFile := '';
  AError := '';
  if not CreateVoice(AProfile, AError) then Exit;

  FActiveProvider := TAISoundProviderFactory.CreateProvider(FProviderKind);
  InitAISoundProviderConfig(Cfg);
  Cfg.TaskKind := stkVoiceClone;
  Cfg.Endpoint := FEndpoint;
  Cfg.Token := FToken;
  Cfg.Model := AProfile.Model;
  if Cfg.Model = '' then Cfg.Model := FModelPath;
  Cfg.Voice := AProfile.ID;
  Cfg.Language := AProfile.Language;
  Cfg.TextOrPrompt := AText;
  Cfg.ReferenceAudio := AProfile.ReferenceAudio;
  Cfg.OutputFile := AOutputFile;
  Cfg.UseGPU := FUseGPU;
  Cfg.PythonPath := FPythonPath;
  Cfg.Timeout := FTimeoutMs;

  Result := FActiveProvider.Synthesize(Cfg, ARealOutputFile);
  if not Result then
  begin
    AError := FActiveProvider.GetLastError;
    SetError(AError);
  end;
end;

procedure TAIHttpVoiceCloneEngine.Cancel;
begin
  if FActiveProvider <> nil then
    FActiveProvider.Cancel;
end;

end.
