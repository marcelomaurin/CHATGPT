unit aivoiceassistant;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, aibase, aispeechrecognizer, chatgpt, aivoiceclone,
  LResources;

type
  TAIVoiceAssistantState = (vasIdle, vasListening, vasRecognizing,
    vasThinking, vasSpeaking, vasCancelled, vasError);
  TAIVoiceAssistantTextEvent = procedure(Sender: TObject; const AText: string) of object;
  TAIVoiceAssistantStageEvent = procedure(Sender: TObject;
    AState: TAIVoiceAssistantState) of object;

  TAIVoiceAssistant = class(TAIBaseComponent)
  private
    FRecognizer: TAISpeechRecognizer;
    FChatGPT: TCHATGPT;
    FVoiceClone: TAIVoiceClone;
    FState: TAIVoiceAssistantState;
    FLastRecognizedText: string;
    FLastResponse: string;
    FLastAudioFile: string;
    FOnRecognized: TAIVoiceAssistantTextEvent;
    FOnResponse: TAIVoiceAssistantTextEvent;
    FOnAudioReady: TAIVoiceAssistantTextEvent;
    FOnStage: TAIVoiceAssistantStageEvent;
    procedure SetRecognizer(AValue: TAISpeechRecognizer);
    procedure SetChatGPT(AValue: TCHATGPT);
    procedure SetVoiceClone(AValue: TAIVoiceClone);
    procedure SetState(AValue: TAIVoiceAssistantState);
    function EnsureComponents(ANeedRecognizer: Boolean): Boolean;
  protected
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
  public
    constructor Create(AOwner: TComponent); override;
    function StartListening(const AOutputWavFile: string = ''): Boolean;
    function StopListeningAndRespond: Boolean;
    function ProcessAudioFile(const AFileName: string): Boolean;
    function ProcessText(const AText: string): Boolean;
    procedure Cancel;
  published
    property Recognizer: TAISpeechRecognizer read FRecognizer write SetRecognizer;
    property ChatGPT: TCHATGPT read FChatGPT write SetChatGPT;
    property VoiceClone: TAIVoiceClone read FVoiceClone write SetVoiceClone;
    property State: TAIVoiceAssistantState read FState;
    property LastRecognizedText: string read FLastRecognizedText;
    property LastResponse: string read FLastResponse;
    property LastAudioFile: string read FLastAudioFile;
    property OnRecognized: TAIVoiceAssistantTextEvent read FOnRecognized write FOnRecognized;
    property OnResponse: TAIVoiceAssistantTextEvent read FOnResponse write FOnResponse;
    property OnAudioReady: TAIVoiceAssistantTextEvent read FOnAudioReady write FOnAudioReady;
    property OnStage: TAIVoiceAssistantStageEvent read FOnStage write FOnStage;
  end;

procedure Register;

implementation

procedure Register;
begin RegisterComponents('AI Voice', [TAIVoiceAssistant]); end;

constructor TAIVoiceAssistant.Create(AOwner: TComponent);
begin inherited Create(AOwner); FCategory := ccAction; FState := vasIdle; end;

procedure TAIVoiceAssistant.SetRecognizer(AValue: TAISpeechRecognizer);
begin
  if FRecognizer = AValue then Exit;
  if Assigned(FRecognizer) then FRecognizer.RemoveFreeNotification(Self);
  FRecognizer := AValue;
  if Assigned(FRecognizer) then FRecognizer.FreeNotification(Self);
end;

procedure TAIVoiceAssistant.SetChatGPT(AValue: TCHATGPT);
begin
  if FChatGPT = AValue then Exit;
  if Assigned(FChatGPT) then FChatGPT.RemoveFreeNotification(Self);
  FChatGPT := AValue;
  if Assigned(FChatGPT) then FChatGPT.FreeNotification(Self);
end;

procedure TAIVoiceAssistant.SetVoiceClone(AValue: TAIVoiceClone);
begin
  if FVoiceClone = AValue then Exit;
  if Assigned(FVoiceClone) then FVoiceClone.RemoveFreeNotification(Self);
  FVoiceClone := AValue;
  if Assigned(FVoiceClone) then FVoiceClone.FreeNotification(Self);
end;

procedure TAIVoiceAssistant.Notification(AComponent: TComponent;
  Operation: TOperation);
begin
  inherited Notification(AComponent, Operation);
  if Operation = opRemove then
  begin
    if AComponent = FRecognizer then FRecognizer := nil;
    if AComponent = FChatGPT then FChatGPT := nil;
    if AComponent = FVoiceClone then FVoiceClone := nil;
  end;
end;

procedure TAIVoiceAssistant.SetState(AValue: TAIVoiceAssistantState);
begin FState := AValue; if Assigned(FOnStage) then FOnStage(Self, FState); end;

function TAIVoiceAssistant.EnsureComponents(ANeedRecognizer: Boolean): Boolean;
begin
  Result := False;
  if ANeedRecognizer and not Assigned(FRecognizer) then begin SetError('SpeechRecognizer nao associado.'); SetState(vasError); Exit; end;
  if not Assigned(FChatGPT) then begin SetError('TCHATGPT nao associado.'); SetState(vasError); Exit; end;
  if not Assigned(FVoiceClone) then begin SetError('TAIVoiceClone nao associado.'); SetState(vasError); Exit; end;
  Result := True;
end;

function TAIVoiceAssistant.StartListening(const AOutputWavFile: string): Boolean;
begin
  ClearError;
  if not EnsureComponents(True) then Exit(False);
  Result := FRecognizer.StartListening(AOutputWavFile);
  if Result then SetState(vasListening)
  else begin SetError(FRecognizer.LastError); SetState(vasError); end;
end;

function TAIVoiceAssistant.StopListeningAndRespond: Boolean;
begin
  Result := False;
  if not EnsureComponents(True) then Exit;
  SetState(vasRecognizing);
  if not FRecognizer.StopListening then
  begin SetError(FRecognizer.LastError); SetState(vasError); Exit; end;
  FLastRecognizedText := FRecognizer.LastText;
  if Assigned(FOnRecognized) then FOnRecognized(Self, FLastRecognizedText);
  Result := ProcessText(FLastRecognizedText);
end;

function TAIVoiceAssistant.ProcessAudioFile(const AFileName: string): Boolean;
begin
  Result := False;
  ClearError;
  if not EnsureComponents(True) then Exit;
  SetState(vasRecognizing);
  if not FRecognizer.TranscribeFile(AFileName) then
  begin SetError(FRecognizer.LastError); SetState(vasError); Exit; end;
  FLastRecognizedText := FRecognizer.LastText;
  if Assigned(FOnRecognized) then FOnRecognized(Self, FLastRecognizedText);
  Result := ProcessText(FLastRecognizedText);
end;

function TAIVoiceAssistant.ProcessText(const AText: string): Boolean;
begin
  Result := False;
  ClearError;
  if not EnsureComponents(False) then Exit;
  if Trim(AText) = '' then begin SetError('Texto de entrada vazio.'); SetState(vasError); Exit; end;
  SetState(vasThinking);
  if not FChatGPT.SendQuestion(AText) then
  begin SetError(FChatGPT.LastError); SetState(vasError); Exit; end;
  FLastResponse := UTF8Encode(FChatGPT.Response);
  if Assigned(FOnResponse) then FOnResponse(Self, FLastResponse);
  SetState(vasSpeaking);
  if not FVoiceClone.Synthesize(FLastResponse) then
  begin SetError(FVoiceClone.LastError); SetState(vasError); Exit; end;
  FLastAudioFile := FVoiceClone.LastOutputFile;
  if not FileExists(FLastAudioFile) then
  begin SetError('Sintese nao produziu arquivo de audio valido.'); SetState(vasError); Exit; end;
  FLastResult := FLastAudioFile;
  FLastSuccess := True;
  SetState(vasIdle);
  if Assigned(FOnAudioReady) then FOnAudioReady(Self, FLastAudioFile);
  Result := True;
end;

procedure TAIVoiceAssistant.Cancel;
begin
  if Assigned(FRecognizer) then FRecognizer.Cancel;
  if Assigned(FChatGPT) then FChatGPT.Cancel;
  if Assigned(FVoiceClone) then FVoiceClone.Cancel;
  SetState(vasCancelled);
end;

end.
