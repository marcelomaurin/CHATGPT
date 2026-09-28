unit aicontinuouslistener;

{$mode objfpc}{$H+}

interface
uses Classes, SysUtils, Math, aiaudio;
type
  TAIListenerState=(lsIdle,lsListening,lsSpeech,lsSilence,lsPaused,lsError);
  TAISpeechReadyEvent=procedure(Sender:TObject;const AFileName:string) of object;
  TAIListenerStateEvent=procedure(Sender:TObject;AState:TAIListenerState) of object;
  TAIContinuousListener=class(TComponent)
  private
    FAudioInput:TAIAudioInput; FOwnsAudioInput,FEnabled,FPaused:Boolean;
    FVoiceThreshold:Double; FSilenceTimeoutMs,FMinSpeechMs,FMaxSpeechMs,FPreRollMs:Integer;
    FEchoSuppressionEnabled:Boolean; FSelfAudioCorrelationThreshold:Double;
    FOutputDirectory,FCurrentFile,FLastError:string; FState:TAIListenerState;
    FSpeechStartedAt,FLastVoiceAt:QWord;
    FOnSpeechReady:TAISpeechReadyEvent; FOnStateChange:TAIListenerStateEvent; FOnError:TNotifyEvent;
    procedure SetState(AState:TAIListenerState); procedure Fail(const S:string);
    function NewSegmentFile:string; function NowMs:QWord;
    procedure AudioLevel(Sender:TObject;ALevel:Double);
  public
    constructor Create(AOwner:TComponent);override; destructor Destroy;override;
    procedure Start; procedure Stop; procedure Pause; procedure Resume;
    procedure FeedSamples(const ASamples:array of SmallInt;ASampleRate:Integer);
    procedure NotifyLevel(ALevel:Double); procedure FinishUtterance;
    property State:TAIListenerState read FState; property CurrentFile:string read FCurrentFile;
    property LastError:string read FLastError;
  published
    property AudioInput:TAIAudioInput read FAudioInput write FAudioInput;
    property Enabled:Boolean read FEnabled;
    property VoiceThreshold:Double read FVoiceThreshold write FVoiceThreshold;
    property SilenceTimeoutMs:Integer read FSilenceTimeoutMs write FSilenceTimeoutMs default 900;
    property MinSpeechMs:Integer read FMinSpeechMs write FMinSpeechMs default 250;
    property MaxSpeechMs:Integer read FMaxSpeechMs write FMaxSpeechMs default 30000;
    property PreRollMs:Integer read FPreRollMs write FPreRollMs default 250;
    property EchoSuppressionEnabled:Boolean read FEchoSuppressionEnabled write FEchoSuppressionEnabled default True;
    property SelfAudioCorrelationThreshold:Double read FSelfAudioCorrelationThreshold write FSelfAudioCorrelationThreshold;
    property OutputDirectory:string read FOutputDirectory write FOutputDirectory;
    property OnSpeechReady:TAISpeechReadyEvent read FOnSpeechReady write FOnSpeechReady;
    property OnStateChange:TAIListenerStateEvent read FOnStateChange write FOnStateChange;
    property OnError:TNotifyEvent read FOnError write FOnError;
  end;
procedure Register;
implementation
procedure Register;begin RegisterComponents('AI Communication',[TAIContinuousListener]);end;
constructor TAIContinuousListener.Create(AOwner:TComponent);
begin inherited Create(AOwner); FVoiceThreshold:=0.025; FSilenceTimeoutMs:=900; FMinSpeechMs:=250; FMaxSpeechMs:=30000; FPreRollMs:=250; FEchoSuppressionEnabled:=True; FSelfAudioCorrelationThreshold:=0.85; FOutputDirectory:=IncludeTrailingPathDelimiter(GetTempDir(False))+'chatgpt-audio'; FState:=lsIdle;end;
destructor TAIContinuousListener.Destroy;begin Stop;if FOwnsAudioInput then FreeAndNil(FAudioInput);inherited Destroy;end;
function TAIContinuousListener.NowMs:QWord;begin Result:=GetTickCount64;end;
procedure TAIContinuousListener.SetState(AState:TAIListenerState);begin if FState=AState then Exit;FState:=AState;if Assigned(FOnStateChange) then FOnStateChange(Self,FState);end;
procedure TAIContinuousListener.Fail(const S:string);begin FLastError:=S;SetState(lsError);if Assigned(FOnError) then FOnError(Self);end;
function TAIContinuousListener.NewSegmentFile:string;begin ForceDirectories(FOutputDirectory);Result:=IncludeTrailingPathDelimiter(FOutputDirectory)+'speech-'+FormatDateTime('yyyymmdd-hhnnss-zzz',Now)+'.wav';end;
procedure TAIContinuousListener.AudioLevel(Sender:TObject;ALevel:Double);begin NotifyLevel(ALevel);end;
procedure TAIContinuousListener.Start;
begin
 if FEnabled then Exit;FLastError:='';
 if not Assigned(FAudioInput) then begin FAudioInput:=TAIAudioInput.Create(nil);FOwnsAudioInput:=True;end;
 FAudioInput.OnAudioLevel:=@AudioLevel; FCurrentFile:=NewSegmentFile;
 if not FAudioInput.StartRecord(FCurrentFile) then begin Fail(FAudioInput.LastError);Exit;end;
 FEnabled:=True;FPaused:=False;FSpeechStartedAt:=0;FLastVoiceAt:=0;SetState(lsListening);
end;
procedure TAIContinuousListener.Stop;begin if Assigned(FAudioInput) then begin FAudioInput.OnAudioLevel:=nil;if FAudioInput.Recording then FAudioInput.StopRecord;end;FEnabled:=False;FPaused:=False;SetState(lsIdle);end;
procedure TAIContinuousListener.Pause;begin if not FEnabled or FPaused then Exit;if FAudioInput.Recording then FAudioInput.StopRecord;FPaused:=True;SetState(lsPaused);end;
procedure TAIContinuousListener.Resume;begin if not FEnabled or not FPaused then Exit;FCurrentFile:=NewSegmentFile;if not FAudioInput.StartRecord(FCurrentFile) then begin Fail(FAudioInput.LastError);Exit;end;FPaused:=False;FSpeechStartedAt:=0;FLastVoiceAt:=0;SetState(lsListening);end;
procedure TAIContinuousListener.FeedSamples(const ASamples:array of SmallInt;ASampleRate:Integer);
var I:Integer;S,R:Double;begin if Length(ASamples)=0 then Exit;S:=0;for I:=Low(ASamples) to High(ASamples) do S:=S+Sqr(ASamples[I]/32768.0);R:=Sqrt(S/Length(ASamples));NotifyLevel(R);end;
procedure TAIContinuousListener.NotifyLevel(ALevel:Double);
var T:QWord;begin if not FEnabled or FPaused then Exit;T:=NowMs;if ALevel>=FVoiceThreshold then begin FLastVoiceAt:=T;if FSpeechStartedAt=0 then FSpeechStartedAt:=T;SetState(lsSpeech);end else if FSpeechStartedAt<>0 then begin SetState(lsSilence);if (T-FLastVoiceAt>=QWord(Max(0,FSilenceTimeoutMs))) and (T-FSpeechStartedAt>=QWord(Max(0,FMinSpeechMs))) then FinishUtterance;end;if (FSpeechStartedAt<>0) and (FMaxSpeechMs>0) and (T-FSpeechStartedAt>=QWord(FMaxSpeechMs)) then FinishUtterance;end;
procedure TAIContinuousListener.FinishUtterance;
var F,E:string;begin if not FEnabled or FPaused or (FSpeechStartedAt=0) then Exit;F:=FCurrentFile;if FAudioInput.Recording then FAudioInput.StopRecord;if FAudioInput.ValidateWavFile(F,E) then begin if Assigned(FOnSpeechReady) then FOnSpeechReady(Self,F);end else Fail(E);if not FEnabled then Exit;FCurrentFile:=NewSegmentFile;if not FAudioInput.StartRecord(FCurrentFile) then begin Fail(FAudioInput.LastError);Exit;end;FSpeechStartedAt:=0;FLastVoiceAt:=0;SetState(lsListening);end;
end.
