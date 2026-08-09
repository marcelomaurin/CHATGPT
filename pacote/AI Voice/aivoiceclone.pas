unit aivoiceclone;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, TypInfo, aibase, aivoiceclonetypes, LResources;

type
  TAIVoiceClone = class(TAIBaseComponent)
  private
    FProfile: TAIVoiceProfile;
    FEngine: TComponent;
    FOutputFile: string;
    FUseGPU: Boolean;
    FModelPath: string;
    FRequireConsent: Boolean;
    FLastOutputFile: string;
    FState: TAIVoiceCloneState;
    FOnStart: TNotifyEvent;
    FOnProgress: TAIVoiceCloneProgressEvent;
    FOnError: TAIVoiceCloneErrorEvent;
    FOnFinish: TAIVoiceCloneFinishEvent;
    procedure SetProfile(AValue: TAIVoiceProfile);
    procedure SetEngine(AValue: TComponent);
    function GetReferenceAudio: string;
    procedure SetReferenceAudio(const AValue: string);
    function GetVoiceID: string;
    procedure SetVoiceID(const AValue: string);
    function GetLanguage: string;
    procedure SetLanguage(const AValue: string);
    function GetConsentConfirmed: Boolean;
    procedure SetConsentConfirmed(AValue: Boolean);
    function GetVoiceOwner: string;
    procedure SetVoiceOwner(const AValue: string);
    function GetBusy: Boolean;
    function ValidateConsent: Boolean;
    procedure Fail(const AMessage: string);
  protected
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    function CreateVoice: Boolean;
    function Synthesize(const AText: string): Boolean;
    procedure Cancel;
  published
    property Profile: TAIVoiceProfile read FProfile write SetProfile;
    property Engine: TComponent read FEngine write SetEngine;
    property ReferenceAudio: string read GetReferenceAudio write SetReferenceAudio;
    property VoiceID: string read GetVoiceID write SetVoiceID;
    property OutputFile: string read FOutputFile write FOutputFile;
    property Language: string read GetLanguage write SetLanguage;
    property UseGPU: Boolean read FUseGPU write FUseGPU default False;
    property ModelPath: string read FModelPath write FModelPath;
    property RequireConsent: Boolean read FRequireConsent write FRequireConsent default True;
    property ConsentConfirmed: Boolean read GetConsentConfirmed write SetConsentConfirmed default False;
    property VoiceOwner: string read GetVoiceOwner write SetVoiceOwner;
    property LastOutputFile: string read FLastOutputFile;
    property State: TAIVoiceCloneState read FState;
    property Busy: Boolean read GetBusy;
    property OnStart: TNotifyEvent read FOnStart write FOnStart;
    property OnProgress: TAIVoiceCloneProgressEvent read FOnProgress write FOnProgress;
    property OnError: TAIVoiceCloneErrorEvent read FOnError write FOnError;
    property OnFinish: TAIVoiceCloneFinishEvent read FOnFinish write FOnFinish;
  end;

procedure Register;

implementation

procedure Register;
begin RegisterComponents('AI Voice', [TAIVoiceClone]); end;

constructor TAIVoiceClone.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FCategory := ccOutput;
  FProfile := TAIVoiceProfile.Create;
  FOutputFile := 'output' + DirectorySeparator + 'voice_clone.wav';
  FRequireConsent := True;
  FUseGPU := False;
  FState := vcsIdle;
end;

destructor TAIVoiceClone.Destroy;
begin FProfile.Free; inherited Destroy; end;

procedure TAIVoiceClone.SetProfile(AValue: TAIVoiceProfile);
begin if Assigned(AValue) then FProfile.Assign(AValue); end;

procedure TAIVoiceClone.SetEngine(AValue: TComponent);
begin
  if FEngine = AValue then Exit;
  if Assigned(FEngine) then FEngine.RemoveFreeNotification(Self);
  FEngine := AValue;
  if Assigned(FEngine) then FEngine.FreeNotification(Self);
end;

procedure TAIVoiceClone.Notification(AComponent: TComponent; Operation: TOperation);
begin
  inherited Notification(AComponent, Operation);
  if (Operation = opRemove) and (AComponent = FEngine) then FEngine := nil;
end;

function TAIVoiceClone.GetReferenceAudio: string;
begin Result := FProfile.ReferenceAudio; end;
procedure TAIVoiceClone.SetReferenceAudio(const AValue: string);
begin FProfile.ReferenceAudio := AValue; end;
function TAIVoiceClone.GetVoiceID: string;
begin Result := FProfile.ID; end;
procedure TAIVoiceClone.SetVoiceID(const AValue: string);
begin FProfile.ID := AValue; end;
function TAIVoiceClone.GetLanguage: string;
begin Result := FProfile.Language; end;
procedure TAIVoiceClone.SetLanguage(const AValue: string);
begin FProfile.Language := AValue; end;
function TAIVoiceClone.GetConsentConfirmed: Boolean;
begin Result := FProfile.ConsentConfirmed; end;
procedure TAIVoiceClone.SetConsentConfirmed(AValue: Boolean);
begin FProfile.ConsentConfirmed := AValue; end;
function TAIVoiceClone.GetVoiceOwner: string;
begin Result := FProfile.VoiceOwner; end;
procedure TAIVoiceClone.SetVoiceOwner(const AValue: string);
begin FProfile.VoiceOwner := AValue; end;
function TAIVoiceClone.GetBusy: Boolean;
begin Result := FState in [vcsPreparing, vcsSynthesizing, vcsCancelling]; end;

procedure TAIVoiceClone.Fail(const AMessage: string);
begin
  FState := vcsError;
  SetError(AMessage);
  if Assigned(FOnError) then FOnError(Self, AMessage);
end;

function TAIVoiceClone.ValidateConsent: Boolean;
begin
  Result := (not FRequireConsent) or FProfile.ConsentConfirmed;
  if not Result then Fail('Clonagem de voz bloqueada: consentimento explicito nao confirmado.');
  if Result and FRequireConsent and (Trim(FProfile.VoiceOwner) = '') then
  begin Result := False; Fail('VoiceOwner deve identificar o titular/autorizado.'); end;
end;

function TAIVoiceClone.CreateVoice: Boolean;
var CloneEngine: IAIVoiceCloneEngine; Err: string;
begin
  Result := False; ClearError; FLastOutputFile := '';
  if not ValidateConsent then Exit;
  if not Assigned(FEngine) or not Supports(FEngine, IAIVoiceCloneEngine,
    CloneEngine) then begin Fail('Engine de clonagem nao associado ou incompativel.'); Exit; end;
  FProfile.Model := FModelPath;
  if IsPublishedProp(FEngine, 'UseGPU') then SetOrdProp(FEngine, 'UseGPU', Ord(FUseGPU));
  if IsPublishedProp(FEngine, 'ModelPath') then SetStrProp(FEngine, 'ModelPath', FModelPath);
  FState := vcsPreparing;
  if Assigned(FOnStart) then FOnStart(Self);
  if Assigned(FOnProgress) then FOnProgress(Self, 10, 'Validando perfil e referencia');
  Result := CloneEngine.CreateVoice(FProfile, Err);
  if Result then
  begin FState := vcsCompleted; FLastSuccess := True; if Assigned(FOnProgress) then FOnProgress(Self, 100, 'Perfil preparado'); end
  else Fail(Err);
  if Assigned(FOnFinish) then FOnFinish(Self, Result, '');
end;

function TAIVoiceClone.Synthesize(const AText: string): Boolean;
var CloneEngine: IAIVoiceCloneEngine; Err, RealOutput: string;
begin
  Result := False; ClearError; FLastOutputFile := '';
  if not ValidateConsent then Exit;
  if Trim(AText) = '' then begin Fail('Texto para sintese esta vazio.'); Exit; end;
  if Trim(FOutputFile) = '' then begin Fail('OutputFile esta vazio.'); Exit; end;
  if not Assigned(FEngine) or not Supports(FEngine, IAIVoiceCloneEngine,
    CloneEngine) then begin Fail('Engine de clonagem nao associado ou incompativel.'); Exit; end;
  FProfile.Model := FModelPath;
  if IsPublishedProp(FEngine, 'UseGPU') then SetOrdProp(FEngine, 'UseGPU', Ord(FUseGPU));
  if IsPublishedProp(FEngine, 'ModelPath') then SetStrProp(FEngine, 'ModelPath', FModelPath);
  FState := vcsSynthesizing;
  if Assigned(FOnStart) then FOnStart(Self);
  if Assigned(FOnProgress) then FOnProgress(Self, 10, 'Iniciando sintese');
  Result := CloneEngine.Synthesize(FProfile, AText, FOutputFile, RealOutput, Err);
  if Result and FileExists(RealOutput) then
  begin
    FLastOutputFile := ExpandFileName(RealOutput);
    FLastResult := FLastOutputFile;
    FLastSuccess := True;
    FState := vcsCompleted;
    if Assigned(FOnProgress) then FOnProgress(Self, 100, 'WAV gerado e validado');
  end
  else
  begin
    if Result then Err := 'Engine declarou sucesso sem arquivo de saida valido.';
    Result := False;
    Fail(Err);
  end;
  if Assigned(FOnFinish) then FOnFinish(Self, Result, FLastOutputFile);
end;

procedure TAIVoiceClone.Cancel;
var CloneEngine: IAIVoiceCloneEngine;
begin
  FState := vcsCancelling;
  if Assigned(FEngine) and Supports(FEngine, IAIVoiceCloneEngine,
    CloneEngine) then CloneEngine.Cancel;
  FState := vcsIdle;
end;

end.
