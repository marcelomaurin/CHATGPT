unit aicontinuouslistener;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Math, aiaudio;

type
  TAIListenerState = (lsIdle, lsListening, lsSpeech, lsSilence, lsPaused, lsError);
  TAISpeechReadyEvent = procedure(Sender: TObject; const AFileName: string) of object;
  TAIListenerStateEvent = procedure(Sender: TObject; AState: TAIListenerState) of object;

  { TAIContinuousListener
    Orquestra a captura continua sobre TAIAudioInput. A analise de amostras pode
    ser alimentada por FeedSamples; assim o VAD permanece independente do backend
    de captura (MCI/ALSA) e pode receber audio ja filtrado. }
  TAIContinuousListener = class(TComponent)
  private
    FAudioInput: TAIAudioInput;
    FOwnsAudioInput: Boolean;
    FEnabled: Boolean;
    FPaused: Boolean;
    FVoiceThreshold: Double;
    FSilenceTimeoutMs: Integer;
    FMinSpeechMs: Integer;
    FMaxSpeechMs: Integer;
    FPreRollMs: Integer;
    FEchoSuppressionEnabled: Boolean;
    FSelfAudioCorrelationThreshold: Double;
    FOutputDirectory: string;
    FCurrentFile: string;
    FState: TAIListenerState;
    FSpeechStartedAt: QWord;
    FLastVoiceAt: QWord;
    FSegmentStartedAt: QWord;
    FOnSpeechReady: TAISpeechReadyEvent;
    FOnStateChange: TAIListenerStateEvent;
    FOnError: TNotifyEvent;
    FLastError: string;
    procedure SetState(AState: TAIListenerState);
    function NewSegmentFile: string;
    procedure Fail(const AMessage: string);
    function NowMs: QWord;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure Start;
    procedure Stop;
    procedure Pause;
    procedure Resume;
    procedure FeedSamples(const ASamples: array of SmallInt; ASampleRate: Integer);
    procedure NotifyLevel(ALevel: Double);
    procedure FinishUtterance;
    property State: TAIListenerState read FState;
    property CurrentFile: string read FCurrentFile;
    property LastError: string read FLastError;
  published
    property AudioInput: TAIAudioInput read FAudioInput write FAudioInput;
    property Enabled: Boolean read FEnabled;
    property VoiceThreshold: Double read FVoiceThreshold write FVoiceThreshold;
    property SilenceTimeoutMs: Integer read FSilenceTimeoutMs write FSilenceTimeoutMs default 900;
    property MinSpeechMs: Integer read FMinSpeechMs write FMinSpeechMs default 250;
    property MaxSpeechMs: Integer read FMaxSpeechMs write FMaxSpeechMs default 30000;
    property PreRollMs: Integer read FPreRollMs write FPreRollMs default 250;
    property EchoSuppressionEnabled: Boolean read FEchoSuppressionEnabled write FEchoSuppressionEnabled default True;
    property SelfAudioCorrelationThreshold: Double read FSelfAudioCorrelationThreshold write FSelfAudioCorrelationThreshold;
    property OutputDirectory: string read FOutputDirectory write FOutputDirectory;
    property OnSpeechReady: TAISpeechReadyEvent read FOnSpeechReady write FOnSpeechReady;
    property OnStateChange: TAIListenerStateEvent read FOnStateChange write FOnStateChange;
    property OnError: TNotifyEvent read FOnError write FOnError;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('AI Communication', [TAIContinuousListener]);
end;

constructor TAIContinuousListener.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FAudioInput := nil;
  FOwnsAudioInput := False;
  FVoiceThreshold := 0.025;
  FSilenceTimeoutMs := 900;
  FMinSpeechMs := 250;
  FMaxSpeechMs := 30000;
  FPreRollMs := 250;
  FEchoSuppressionEnabled := True;
  FSelfAudioCorrelationThreshold := 0.85;
  FOutputDirectory := IncludeTrailingPathDelimiter(GetTempDir(False)) + 'chatgpt-audio';
  FState := lsIdle;
end;

destructor TAIContinuousListener.Destroy;
begin
  Stop;
  if FOwnsAudioInput then FreeAndNil(FAudioInput);
  inherited Destroy;
end;

function TAIContinuousListener.NowMs: QWord;
begin
  Result := GetTickCount64;
end;

procedure TAIContinuousListener.SetState(AState: TAIListenerState);
begin
  if FState = AState then Exit;
  FState := AState;
  if Assigned(FOnStateChange) then FOnStateChange(Self, FState);
end;

procedure TAIContinuousListener.Fail(const AMessage: string);
begin
  FLastError := AMessage;
  SetState(lsError);
  if Assigned(FOnError) then FOnError(Self);
end;

function TAIContinuousListener.NewSegmentFile: string;
begin
  ForceDirectories(FOutputDirectory);
  Result := IncludeTrailingPathDelimiter(FOutputDirectory) +
    'speech-' + FormatDateTime('yyyymmdd-hhnnss-zzz', Now) + '.wav';
end;

procedure TAIContinuousListener.Start;
begin
  if FEnabled then Exit;
  FLastError := '';
  if not Assigned(FAudioInput) then
  begin
    FAudioInput := TAIAudioInput.Create(nil);
    FOwnsAudioInput := True;
  end;
  FCurrentFile := NewSegmentFile;
  if not FAudioInput.StartRecord(FCurrentFile) then
  begin
    Fail(FAudioInput.LastError);
    Exit;
  end;
  FEnabled := True;
  FPaused := False;
  FSegmentStartedAt := NowMs;
  FSpeechStartedAt := 0;
  FLastVoiceAt := 0;
  SetState(lsListening);
end;

procedure TAIContinuousListener.Stop;
begin
  if Assigned(FAudioInput) and FAudioInput.Recording then FAudioInput.StopRecord;
  FEnabled := False;
  FPaused := False;
  SetState(lsIdle);
end;

procedure TAIContinuousListener.Pause;
begin
  if not FEnabled or FPaused then Exit;
  if Assigned(FAudioInput) and FAudioInput.Recording then FAudioInput.StopRecord;
  FPaused := True;
  SetState(lsPaused);
end;

procedure TAIContinuousListener.Resume;
begin
  if not FEnabled or not FPaused then Exit;
  FCurrentFile := NewSegmentFile;
  if not FAudioInput.StartRecord(FCurrentFile) then
  begin
    Fail(FAudioInput.LastError);
    Exit;
  end;
  FPaused := False;
  FSegmentStartedAt := NowMs;
  FSpeechStartedAt := 0;
  FLastVoiceAt := 0;
  SetState(lsListening);
end;

procedure TAIContinuousListener.FeedSamples(const ASamples: array of SmallInt; ASampleRate: Integer);
var
  I: Integer;
  SumSquares, RMS: Double;
begin
  if Length(ASamples) = 0 then Exit;
  SumSquares := 0;
  for I := Low(ASamples) to High(ASamples) do
    SumSquares := SumSquares + Sqr(ASamples[I] / 32768.0);
  RMS := Sqrt(SumSquares / Length(ASamples));
  NotifyLevel(RMS);
end;

procedure TAIContinuousListener.NotifyLevel(ALevel: Double);
var T: QWord;
begin
  if not FEnabled or FPaused then Exit;
  T := NowMs;

  if ALevel >= FVoiceThreshold then
  begin
    FLastVoiceAt := T;
    if FSpeechStartedAt = 0 then FSpeechStartedAt := T;
    SetState(lsSpeech);
  end
  else if FSpeechStartedAt <> 0 then
  begin
    SetState(lsSilence);
    if (T - FLastVoiceAt >= QWord(Max(0, FSilenceTimeoutMs))) and
       (T - FSpeechStartedAt >= QWord(Max(0, FMinSpeechMs))) then
      FinishUtterance;
  end;

  if (FSpeechStartedAt <> 0) and (FMaxSpeechMs > 0) and
     (T - FSpeechStartedAt >= QWord(FMaxSpeechMs)) then
    FinishUtterance;
end;

procedure TAIContinuousListener.FinishUtterance;
var
  CompletedFile, Err: string;
begin
  if not FEnabled or FPaused or (FSpeechStartedAt = 0) then Exit;
  CompletedFile := FCurrentFile;
  if FAudioInput.Recording then FAudioInput.StopRecord;

  if FAudioInput.ValidateWavFile(CompletedFile, Err) then
  begin
    if Assigned(FOnSpeechReady) then FOnSpeechReady(Self, CompletedFile);
  end
  else
    Fail(Err);

  if not FEnabled then Exit;
  FCurrentFile := NewSegmentFile;
  if not FAudioInput.StartRecord(FCurrentFile) then
  begin
    Fail(FAudioInput.LastError);
    Exit;
  end;
  FSegmentStartedAt := NowMs;
  FSpeechStartedAt := 0;
  FLastVoiceAt := 0;
  SetState(lsListening);
end;

end.
