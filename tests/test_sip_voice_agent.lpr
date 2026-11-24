program test_sip_voice_agent;
{$mode objfpc}{$H+}
uses {$IFDEF UNIX}cthreads,{$ENDIF}
  Classes, SysUtils, Math, SyncObjs, fpjson, jsonparser,
  aisip_types, aisipvoiceaudio, aisipvoiceagent;

type
  TBackend = class(TAISIPVoiceBackend)
  public
    Lock: TCriticalSection;
    Entered, Release: TEvent;
    Hold: Boolean;
    Text: string;
    Transcriptions, Replies: Integer;
    Histories, Sessions: TStringList;
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    function Transcribe(const WAV: RawByteString): string; override;
    function Reply(const SessionID, UserText, HistoryJSON: string): string; override;
    function Synthesize(const UserText: string): TAISIPAudioSamples; override;
  end;
  TTest = class
    Agent: TAISIPVoiceAgent;
    Backend: TBackend;
    Frames, Answers, Errors: Integer;
    DisconnectOnTranscript: Boolean;
    procedure Audio(Sender: TObject; CallID: TAISIPCallID;
      const Samples: TAISIPAudioSamples; Rate: Integer);
    procedure Answer(Sender: TObject; CallID: TAISIPCallID; const Text: string);
    procedure Error(Sender: TObject; CallID: TAISIPCallID; const Text: string);
    procedure Transcript(Sender: TObject; CallID: TAISIPCallID; const Text: string);
    procedure Feed(CallID: TAISIPCallID; VoiceFrames, SilenceFrames: Integer);
    procedure Pump(Milliseconds: Integer);
    procedure Run;
  end;

procedure Require(Value: Boolean; const Message: string);
begin if not Value then raise Exception.Create(Message); end;

function Tone(Count: Integer): TAISIPAudioSamples;
var I: Integer;
begin
  Result := nil; SetLength(Result, Count);
  for I := 0 to Count-1 do Result[I] := Round(6000*Sin(I*2*Pi*440/8000));
end;

constructor TBackend.Create(AOwner: TComponent);
begin
  inherited Create(AOwner); Lock := TCriticalSection.Create;
  Entered := TEvent.Create(nil, True, False, ''); Release := TEvent.Create(nil, True, False, '');
  Histories := TStringList.Create; Sessions := TStringList.Create; Text := 'fixture utterance';
end;

destructor TBackend.Destroy;
begin Lock.Free; Entered.Free; Release.Free; Histories.Free; Sessions.Free; inherited Destroy; end;

function TBackend.Transcribe(const WAV: RawByteString): string;
begin
  Require(Length(SIPVoiceReadWAV(WAV)) > 0, 'Invalid input WAV');
  Lock.Enter; try Inc(Transcriptions); finally Lock.Leave; end;
  Entered.SetEvent;
  if Hold then Require(Release.WaitFor(2000) = wrSignaled, 'Test worker timed out');
  Result := Text;
end;

function TBackend.Reply(const SessionID, UserText, HistoryJSON: string): string;
begin
  Lock.Enter;
  try Inc(Replies); Histories.Add(HistoryJSON); Sessions.Add(SessionID);
  finally Lock.Leave; end;
  Result := 'fixture response';
end;

function TBackend.Synthesize(const UserText: string): TAISIPAudioSamples;
begin Result := Tone(320); end;

procedure TTest.Audio(Sender: TObject; CallID: TAISIPCallID;
  const Samples: TAISIPAudioSamples; Rate: Integer);
begin Require((Rate = 8000) and (Length(Samples) <= 160), 'Invalid output frame'); Inc(Frames); end;

procedure TTest.Answer(Sender: TObject; CallID: TAISIPCallID; const Text: string);
begin Inc(Answers); end;

procedure TTest.Error(Sender: TObject; CallID: TAISIPCallID; const Text: string);
begin Inc(Errors); end;

procedure TTest.Transcript(Sender: TObject; CallID: TAISIPCallID; const Text: string);
begin if DisconnectOnTranscript then Agent.EndCall(CallID); end;

procedure TTest.Feed(CallID: TAISIPCallID; VoiceFrames, SilenceFrames: Integer);
var I: Integer; Samples: TAISIPAudioSamples;
begin
  Samples := Tone(160);
  for I := 1 to VoiceFrames do Agent.ReceiveAudio(CallID, Samples);
  FillChar(Samples[0], Length(Samples)*2, 0);
  for I := 1 to SilenceFrames do Agent.ReceiveAudio(CallID, Samples);
end;

procedure TTest.Pump(Milliseconds: Integer);
var UntilTime: QWord;
begin
  UntilTime := GetTickCount64+QWord(Milliseconds);
  repeat Agent.Process; Sleep(1); until GetTickCount64 >= UntilTime;
end;

procedure TTest.Run;
var Samples, ReadBack: TAISIPAudioSamples; WAV: RawByteString;
    I, SavedAnswers, SavedFrames, SavedReplies: Integer; J: TJSONData;
begin
  Samples := Tone(1600); Samples[0] := -32768; Samples[1] := 32767;
  WAV := SIPVoiceWAV(Samples); ReadBack := SIPVoiceReadWAV(WAV);
  Require((Length(ReadBack) = 1600) and (ReadBack[0] = -32768) and
    (ReadBack[1] = 32767), 'Signed WAV round trip failed');
  Require(Length(SIPVoiceReadWAV(SIPVoiceWAV(Samples, 16000))) = 800, '16 to 8 kHz resampling failed');
  for I := 1 to 43 do
  begin
    try SIPVoiceReadWAV(Copy(WAV, 1, I)); Require(False, 'Truncated WAV accepted');
    except on E: Exception do Require(E.Message <> 'Truncated WAV accepted', E.Message); end;
  end;
  Backend := TBackend.Create(nil); Agent := TAISIPVoiceAgent.Create(nil);
  try
    Agent.Backend := Backend; Agent.SilenceMs := 100; Agent.MinSpeechMs := 40;
    Agent.MaxUtteranceMs := 1000; Agent.MaxCalls := 2;
    Agent.OnAudioReady := @Audio; Agent.OnResponse := @Answer;
    Agent.OnError := @Error; Agent.OnTranscript := @Transcript;
    Agent.Start; Require(Agent.BeginCall(1), 'First call failed');
    Require(Agent.BeginCall(2), 'Second call failed');
    Require(not Agent.BeginCall(3), 'Call limit was not enforced');
    Feed(1, 0, 20); Feed(1, 1, 5); Pump(50);
    Require(Backend.Transcriptions = 0, 'Silence or short noise triggered STT');
    Feed(1, 3, 5); Pump(200);
    Require((Answers = 1) and (Frames = 2), 'First turn did not produce paced audio');
    Feed(1, 3, 5); Pump(200);
    Require(Answers = 2, 'Second turn failed');
    J := GetJSON(Backend.Histories[1]);
    try Require((J is TJSONArray) and (J.Count = 2), 'Conversation context was lost'); finally J.Free; end;
    Feed(2, 3, 5); Pump(200);
    Require(Answers = 3, 'Independent call failed');
    Require((Backend.Histories[2] = '[]') and (Backend.Sessions[2] <> Backend.Sessions[0]),
      'Conversation history leaked between calls');
    Agent.ReceiveAudio(1, Tone(160), 16000);
    Require(Errors = 1, 'Invalid PCM rate was not rejected');
    Backend.Text := '[Áudio recebido e processado pelo Parakeet STT]';
    SavedReplies := Backend.Replies; Feed(1, 3, 5); Pump(100);
    Require((Errors = 2) and (Backend.Replies = SavedReplies), 'Demonstration STT text reached AI');
    Backend.Text := 'fixture utterance'; Backend.Hold := True; Backend.Entered.ResetEvent;
    SavedAnswers := Answers; SavedFrames := Frames;
    Feed(1, 3, 5);
    Require(Backend.Entered.WaitFor(1000) = wrSignaled, 'Worker did not begin');
    Agent.EndCall(1); Require(Agent.BeginCall(1), 'Reused call ID failed');
    Backend.Release.SetEvent; Pump(100); Backend.Hold := False;
    Require((Answers = SavedAnswers) and (Frames = SavedFrames) and
      (Backend.Replies = SavedReplies), 'A disconnected call continued processing');
    DisconnectOnTranscript := True; Feed(1, 3, 5); Pump(100);
    Require((Answers = SavedAnswers) and (Frames = SavedFrames) and
      (Agent.SessionCount = 1), 'Disconnect in transcript event still played an answer');
    DisconnectOnTranscript := False; Feed(2, 70, 0); Pump(200);
    Require(Answers = SavedAnswers+1, 'Maximum utterance duration was not enforced');
    Agent.Stop; Require(Agent.SessionCount = 0, 'Stop left sessions alive');
    WriteLn('PASS: PCM/WAV, resampling, silence, noise, segmentation, bounded calls, per-call context, demo rejection, cancellation, reused IDs and paced output');
  finally Agent.Free; Backend.Free; end;
end;

var Test: TTest;
begin Test := TTest.Create; try Test.Run; finally Test.Free; end; end.
