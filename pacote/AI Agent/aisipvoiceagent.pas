unit aisipvoiceagent;

{$mode objfpc}{$H+}

interface

uses Classes, SysUtils, SyncObjs, fpjson, aibase, aisip_types, aisip_base;

type
  { Implementations are called on worker threads. They must use request-local
    state; configure them before Start and keep them alive until Stop returns. }
  TAISIPVoiceBackend = class(TComponent)
  public
    function Transcribe(const WAV: RawByteString): string; virtual; abstract;
    function Reply(const SessionID, Text, HistoryJSON: string): string; virtual; abstract;
    function Synthesize(const Text: string): TAISIPAudioSamples; virtual; abstract;
  end;

  TAISIPVoiceTextEvent = procedure(Sender: TObject; CallID: TAISIPCallID;
    const Text: string) of object;
  TAISIPVoiceSessionEvent = procedure(Sender: TObject; CallID: TAISIPCallID) of object;

  TAISIPVoiceAgent = class(TAIBaseComponent)
  private
    FSIP: TAISIPBase;
    FBackend: TAISIPVoiceBackend;
    FActive, FAutoAnswer: Boolean;
    FMaxCalls, FSilenceMs, FMinSpeechMs, FMaxUtteranceMs, FEnergyThreshold: Integer;
    FSequence: QWord;
    FCalls, FWorkers: TList;
    FOldIncoming: TAISIPIncomingCallEvent;
    FOldState: TAISIPCallStateEvent;
    FOldAudio: TAISIPAudioEvent;
    FOnTranscript, FOnResponse, FOnError: TAISIPVoiceTextEvent;
    FOnSessionStarted, FOnSessionEnded: TAISIPVoiceSessionEvent;
    FOnAudioReady: TAISIPAudioEvent;
    procedure SetSIP(Value: TAISIPBase);
    procedure SetBackend(Value: TAISIPVoiceBackend);
    procedure SetActive(Value: Boolean);
    function FindCall(CallID: TAISIPCallID): TObject;
    procedure Incoming(Sender: TObject; CallID: TAISIPCallID; const Caller, Target: string);
    procedure StateChanged(Sender: TObject; CallID: TAISIPCallID;
      State: TAISIPCallState; StatusCode: Integer; const Reason: string);
    procedure AudioReceived(Sender: TObject; CallID: TAISIPCallID;
      const Samples: TAISIPAudioSamples; SampleRate: Integer);
    procedure Submit(Call: TObject);
    procedure Error(CallID: TAISIPCallID; const Message: string);
  protected
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure Start;
    procedure Stop;
    function Poll(TimeoutMs: Integer = 10): Boolean;
    { Also usable with an external PCM transport, without a SIP runtime. }
    function BeginCall(CallID: TAISIPCallID): Boolean;
    procedure EndCall(CallID: TAISIPCallID);
    procedure ReceiveAudio(CallID: TAISIPCallID;
      const Samples: TAISIPAudioSamples; SampleRate: Integer = 8000);
    procedure Process;
    function SessionCount: Integer;
  published
    property SIP: TAISIPBase read FSIP write SetSIP;
    property Backend: TAISIPVoiceBackend read FBackend write SetBackend;
    property Active: Boolean read FActive write SetActive default False;
    property AutoAnswer: Boolean read FAutoAnswer write FAutoAnswer default True;
    property MaxCalls: Integer read FMaxCalls write FMaxCalls default 4;
    property SilenceMs: Integer read FSilenceMs write FSilenceMs default 700;
    property MinSpeechMs: Integer read FMinSpeechMs write FMinSpeechMs default 200;
    property MaxUtteranceMs: Integer read FMaxUtteranceMs write FMaxUtteranceMs default 15000;
    property EnergyThreshold: Integer read FEnergyThreshold write FEnergyThreshold default 500;
    property OnTranscript: TAISIPVoiceTextEvent read FOnTranscript write FOnTranscript;
    property OnResponse: TAISIPVoiceTextEvent read FOnResponse write FOnResponse;
    property OnError: TAISIPVoiceTextEvent read FOnError write FOnError;
    property OnSessionStarted: TAISIPVoiceSessionEvent read FOnSessionStarted write FOnSessionStarted;
    property OnSessionEnded: TAISIPVoiceSessionEvent read FOnSessionEnded write FOnSessionEnded;
    property OnAudioReady: TAISIPAudioEvent read FOnAudioReady write FOnAudioReady;
  end;

implementation

uses aisipvoiceaudio;

type
  TVoiceSession = class
    ID: TAISIPCallID;
    Serial: QWord;
    Key: string;
    Connected, Busy: Boolean;
    Input: TMemoryStream;
    PreRoll, Output: TAISIPAudioSamples;
    Silence, VoiceSamples, OutputOffset: Integer;
    NextFrame, PlaybackUntil: QWord;
    History: TJSONArray;
    constructor Create;
    destructor Destroy; override;
    procedure ResetInput;
  end;

  TVoiceWorker = class(TThread)
  private
    FBackend: TAISIPVoiceBackend;
    FWAV: RawByteString;
    FSessionID, FHistory: string;
  protected
    procedure Execute; override;
  public
    Done: TEvent;
    CallID: TAISIPCallID;
    Serial: QWord;
    Transcript, Response, Failure: string;
    Audio: TAISIPAudioSamples;
    constructor Create(ABackend: TAISIPVoiceBackend; Session: TVoiceSession);
    destructor Destroy; override;
  end;

constructor TVoiceSession.Create;
begin inherited Create; Input := TMemoryStream.Create; History := TJSONArray.Create; end;

destructor TVoiceSession.Destroy;
begin Input.Free; History.Free; inherited Destroy; end;

procedure TVoiceSession.ResetInput;
begin Input.Clear; PreRoll := nil; Silence := 0; VoiceSamples := 0; end;

constructor TVoiceWorker.Create(ABackend: TAISIPVoiceBackend; Session: TVoiceSession);
var Samples: TAISIPAudioSamples;
begin
  inherited Create(True); FreeOnTerminate := False;
  Done := TEvent.Create(nil, True, False, '');
  FBackend := ABackend; CallID := Session.ID; Serial := Session.Serial;
  FSessionID := Session.Key; FHistory := Session.History.AsJSON;
  SetLength(Samples, Session.Input.Size div 2);
  if Length(Samples) > 0 then Move(Session.Input.Memory^, Samples[0], Length(Samples)*2);
  FWAV := SIPVoiceWAV(Samples);
end;

destructor TVoiceWorker.Destroy;
begin inherited Destroy; Done.Free; end;

procedure TVoiceWorker.Execute;
begin
  try
    try
      if Terminated then Exit;
      Transcript := Trim(FBackend.Transcribe(FWAV)); FWAV := '';
      if Terminated then Exit;
      if not SIPVoiceRealTranscript(Transcript) then
        raise Exception.Create('STT returned empty or demonstration text');
      Response := Trim(FBackend.Reply(FSessionID, Transcript, FHistory));
      if Terminated then Exit;
      if (Response = '') or (Length(Response) > 16000) then
        raise Exception.Create('AI returned empty or oversized text');
      Audio := FBackend.Synthesize(Response);
      if (Length(Audio) = 0) or (Length(Audio) > 8000*120) then
        raise Exception.Create('TTS returned empty or oversized audio');
    except on E: Exception do Failure := E.Message; end;
  finally Done.SetEvent; end;
end;

constructor TAISIPVoiceAgent.Create(AOwner: TComponent);
begin
  inherited Create(AOwner); FCategory := ccAction;
  FCalls := TList.Create; FWorkers := TList.Create;
  FAutoAnswer := True; FMaxCalls := 4; FSilenceMs := 700;
  FMinSpeechMs := 200; FMaxUtteranceMs := 15000; FEnergyThreshold := 500;
end;

destructor TAISIPVoiceAgent.Destroy;
begin Stop; FCalls.Free; FWorkers.Free; inherited Destroy; end;

procedure TAISIPVoiceAgent.SetSIP(Value: TAISIPBase);
begin
  if Value = FSIP then Exit;
  if FActive then raise Exception.Create('Stop the voice agent before changing SIP');
  if FSIP <> nil then FSIP.RemoveFreeNotification(Self);
  FSIP := Value;
  if FSIP <> nil then FSIP.FreeNotification(Self);
end;

procedure TAISIPVoiceAgent.SetBackend(Value: TAISIPVoiceBackend);
begin
  if Value = FBackend then Exit;
  if FActive then raise Exception.Create('Stop the voice agent before changing Backend');
  if FBackend <> nil then FBackend.RemoveFreeNotification(Self);
  FBackend := Value;
  if FBackend <> nil then FBackend.FreeNotification(Self);
end;

procedure TAISIPVoiceAgent.Notification(AComponent: TComponent; Operation: TOperation);
begin
  if Operation = opRemove then
  begin
    if AComponent = FSIP then begin Stop; FSIP := nil; end;
    if AComponent = FBackend then begin Stop; FBackend := nil; end;
  end;
  inherited Notification(AComponent, Operation);
end;

procedure TAISIPVoiceAgent.SetActive(Value: Boolean);
begin if Value then Start else Stop; end;

procedure TAISIPVoiceAgent.Start;
begin
  if FActive then Exit;
  if FBackend = nil then raise Exception.Create('Voice Backend is required');
  if (FMaxCalls < 1) or (FMaxCalls > 16) or (FEnergyThreshold < 1) or
    (FEnergyThreshold > 32767) or (FMinSpeechMs < 20) or
    (FMaxUtteranceMs < FMinSpeechMs+200) or (FMaxUtteranceMs > 30000) or
    (FSilenceMs < 100) or (FSilenceMs > 5000) then
    raise Exception.Create('Invalid voice activity limits');
  if FSIP <> nil then
  begin
    FOldIncoming := FSIP.OnIncomingCall; FOldState := FSIP.OnCallStateChanged;
    FOldAudio := FSIP.OnAudio;
    FSIP.OnIncomingCall := @Incoming; FSIP.OnCallStateChanged := @StateChanged;
    FSIP.OnAudio := @AudioReceived;
  end;
  FActive := True; ClearError;
end;

procedure TAISIPVoiceAgent.Stop;
var I: Integer; W: TVoiceWorker;
begin
  if FActive and (FSIP <> nil) then
  begin
    FSIP.OnIncomingCall := FOldIncoming; FSIP.OnCallStateChanged := FOldState;
    FSIP.OnAudio := FOldAudio;
  end;
  FActive := False;
  for I := 0 to FWorkers.Count-1 do TVoiceWorker(FWorkers[I]).Terminate;
  for I := FCalls.Count-1 downto 0 do TObject(FCalls[I]).Free;
  FCalls.Clear;
  for I := FWorkers.Count-1 downto 0 do
  begin W := TVoiceWorker(FWorkers[I]); W.WaitFor; W.Free; end;
  FWorkers.Clear;
end;

function TAISIPVoiceAgent.FindCall(CallID: TAISIPCallID): TObject;
var I: Integer;
begin
  Result := nil;
  for I := 0 to FCalls.Count-1 do
    if TVoiceSession(FCalls[I]).ID = CallID then Exit(TObject(FCalls[I]));
end;

function TAISIPVoiceAgent.SessionCount: Integer;
begin Result := FCalls.Count; end;

function TAISIPVoiceAgent.BeginCall(CallID: TAISIPCallID): Boolean;
var S: TVoiceSession;
begin
  Result := False;
  if not FActive or (CallID = 0) then Exit;
  S := TVoiceSession(FindCall(CallID));
  if S <> nil then Exit(True);
  if (FCalls.Count >= FMaxCalls) or (FWorkers.Count >= FMaxCalls) then Exit;
  S := TVoiceSession.Create; S.ID := CallID; Inc(FSequence); S.Serial := FSequence;
  S.Key := Format('sip-%d-%d-%d-%d', [GetProcessID, GetTickCount64, FSequence, CallID]);
  S.Connected := True; FCalls.Add(S); Result := True;
  if Assigned(FOnSessionStarted) then FOnSessionStarted(Self, CallID);
end;

procedure TAISIPVoiceAgent.EndCall(CallID: TAISIPCallID);
var S: TVoiceSession; I: Integer;
begin
  S := TVoiceSession(FindCall(CallID));
  if S = nil then Exit;
  for I := 0 to FWorkers.Count-1 do
    if (TVoiceWorker(FWorkers[I]).CallID = CallID) and
      (TVoiceWorker(FWorkers[I]).Serial = S.Serial) then TVoiceWorker(FWorkers[I]).Terminate;
  FCalls.Remove(S); S.Free;
  if Assigned(FOnSessionEnded) then FOnSessionEnded(Self, CallID);
end;

procedure TAISIPVoiceAgent.Incoming(Sender: TObject; CallID: TAISIPCallID;
  const Caller, Target: string);
var S: TVoiceSession;
begin
  if not FAutoAnswer then Exit;
  if not BeginCall(CallID) then begin FSIP.Reject(CallID, 486); Exit; end;
  S := TVoiceSession(FindCall(CallID)); S.Connected := False;
  if not FSIP.Answer(CallID) then EndCall(CallID);
end;

procedure TAISIPVoiceAgent.StateChanged(Sender: TObject; CallID: TAISIPCallID;
  State: TAISIPCallState; StatusCode: Integer; const Reason: string);
begin
  if State = scDisconnected then EndCall(CallID)
  else if State = scConnected then
  begin
    if BeginCall(CallID) then TVoiceSession(FindCall(CallID)).Connected := True
    else FSIP.Hangup(CallID);
  end;
end;

procedure TAISIPVoiceAgent.AudioReceived(Sender: TObject; CallID: TAISIPCallID;
  const Samples: TAISIPAudioSamples; SampleRate: Integer);
begin ReceiveAudio(CallID, Samples, SampleRate); end;

procedure TAISIPVoiceAgent.Error(CallID: TAISIPCallID; const Message: string);
begin SetError(Message); if Assigned(FOnError) then FOnError(Self, CallID, Message); end;

procedure TAISIPVoiceAgent.Submit(Call: TObject);
var S: TVoiceSession; W: TVoiceWorker;
begin
  S := TVoiceSession(Call);
  if (S.VoiceSamples < FMinSpeechMs*8) or (FWorkers.Count >= FMaxCalls) then
  begin S.ResetInput; Exit; end;
  W := TVoiceWorker.Create(FBackend, S);
  FWorkers.Add(W); S.Busy := True; S.ResetInput; W.Start;
end;

procedure TAISIPVoiceAgent.ReceiveAudio(CallID: TAISIPCallID;
  const Samples: TAISIPAudioSamples; SampleRate: Integer);
var S: TVoiceSession; I, Count, Keep, Total, Available: Integer; Energy: Int64;
    Voiced: Boolean;
begin
  if not FActive or (Length(Samples) = 0) then Exit;
  S := TVoiceSession(FindCall(CallID));
  if (S = nil) or not S.Connected or S.Busy or
    (Length(S.Output) > 0) or (GetTickCount64 < S.PlaybackUntil) then Exit;
  if (SampleRate <> 8000) or (Length(Samples) > 8000) then
  begin Error(CallID, 'Voice input must be 8 kHz PCM, at most one second per frame'); Exit; end;
  Energy := 0;
  for I := 0 to High(Samples) do Inc(Energy, Abs(Integer(Samples[I])));
  Voiced := Energy div Length(Samples) >= FEnergyThreshold;
  if (S.Input.Size = 0) and not Voiced then
  begin
    Count := Length(Samples); if Count > 1600 then Count := 1600;
    Keep := Length(S.PreRoll); if Keep > 1600-Count then Keep := 1600-Count;
    Total := Length(S.PreRoll);
    if Keep > 0 then Move(S.PreRoll[Total-Keep], S.PreRoll[0], Keep*2);
    SetLength(S.PreRoll, Keep+Count);
    Move(Samples[Length(Samples)-Count], S.PreRoll[Keep], Count*2); Exit;
  end;
  if (S.Input.Size = 0) and (Length(S.PreRoll) > 0) then
    S.Input.WriteBuffer(S.PreRoll[0], Length(S.PreRoll)*2);
  S.PreRoll := nil;
  Count := Length(Samples); Available := FMaxUtteranceMs*8-S.Input.Size div 2;
  if Count > Available then Count := Available;
  if Count > 0 then S.Input.WriteBuffer(Samples[0], Count*2);
  if Voiced then begin Inc(S.VoiceSamples, Count); S.Silence := 0; end
  else Inc(S.Silence, Count);
  if (S.Silence >= FSilenceMs*8) or (S.Input.Size div 2 >= FMaxUtteranceMs*8) then Submit(S);
end;

procedure TAISIPVoiceAgent.Process;
var I, N, Written: Integer; W: TVoiceWorker; S: TVoiceSession;
    Chunk: TAISIPAudioSamples; Now: QWord;
begin
  if not FActive then Exit;
  for I := FWorkers.Count-1 downto 0 do
  begin
    if I >= FWorkers.Count then Continue;
    W := TVoiceWorker(FWorkers[I]);
    if W.Done.WaitFor(0) <> wrSignaled then Continue;
    W.WaitFor; FWorkers.Delete(I);
    try
      S := TVoiceSession(FindCall(W.CallID));
      if (S = nil) or (S.Serial <> W.Serial) or W.Terminated then Continue;
      S.Busy := False;
      if W.Failure <> '' then
      begin
        Error(W.CallID, W.Failure);
        if not FActive then Exit;
        Continue;
      end;
      S.Output := W.Audio; S.OutputOffset := 0; S.NextFrame := 0;
      S.History.Add(TJSONObject.Create(['role', 'user', 'content', W.Transcript]));
      S.History.Add(TJSONObject.Create(['role', 'assistant', 'content', W.Response]));
      while (S.History.Count > 24) or (Length(S.History.AsJSON) > 32000) do
        S.History.Delete(0);
      FLastResult := W.Response; ClearError;
      if not FActive then Exit;
      if Assigned(FOnTranscript) then FOnTranscript(Self, W.CallID, W.Transcript);
      if not FActive then Exit;
      S := TVoiceSession(FindCall(W.CallID));
      if (S <> nil) and (S.Serial = W.Serial) and Assigned(FOnResponse) then
        FOnResponse(Self, W.CallID, W.Response);
      if not FActive then Exit;
    finally W.Free; end;
  end;
  Now := GetTickCount64;
  for I := FCalls.Count-1 downto 0 do
  begin
    if I >= FCalls.Count then Continue;
    S := TVoiceSession(FCalls[I]);
    if not S.Connected or (Length(S.Output) = 0) or (Now < S.NextFrame) then Continue;
    N := Length(S.Output)-S.OutputOffset; if N > 160 then N := 160;
    SetLength(Chunk, N); Move(S.Output[S.OutputOffset], Chunk[0], N*2);
    Written := N;
    if FSIP <> nil then Written := FSIP.WriteAudio(S.ID, Chunk);
    if Written < 0 then Continue;
    Inc(S.OutputOffset, Written); S.NextFrame := Now+20;
    if S.OutputOffset >= Length(S.Output) then
    begin S.Output := nil; S.OutputOffset := 0; S.PlaybackUntil := Now+80; end;
    if Assigned(FOnAudioReady) then FOnAudioReady(Self, S.ID, Chunk, 8000);
    if not FActive then Exit;
  end;
end;

function TAISIPVoiceAgent.Poll(TimeoutMs: Integer): Boolean;
begin
  Result := FActive;
  if not Result then Exit;
  if FSIP <> nil then Result := FSIP.Poll(TimeoutMs);
  Process;
end;

end.
