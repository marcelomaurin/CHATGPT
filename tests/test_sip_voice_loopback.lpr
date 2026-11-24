program test_sip_voice_loopback;
{$mode objfpc}{$H+}
uses {$IFDEF UNIX}cthreads,{$ENDIF}
  Classes, SysUtils, Math, aisip_types, aisip_server, aisip_client,
  aisipvoiceagent, aisipvoicehttp;

type
  TTest = class
    Server: TAISIPServer;
    Client: TAISIPClient;
    Agent: TAISIPVoiceAgent;
    Backend: TAISIPVoiceHTTPBackend;
    Registered, Connected: Boolean;
    Received, Responses, Transcripts: Integer;
    procedure Credential(Sender: TObject; const UserName, Realm, Remote: string;
      var Secret: string; var Kind: TAISIPCredentialKind; var Found: Boolean);
    procedure Allow(Sender: TObject; const UserName, Target, Remote: string; var Accept: Boolean);
    procedure Route(Sender: TObject; CallID: TAISIPCallID; const Caller, Target: string;
      var Destination: string; var Action: TAISIPRouteAction);
    procedure Reg(Sender: TObject; Status, Expires: Integer; const Reason: string);
    procedure State(Sender: TObject; CallID: TAISIPCallID; Value: TAISIPCallState;
      Status: Integer; const Reason: string);
    procedure Audio(Sender: TObject; CallID: TAISIPCallID;
      const Samples: TAISIPAudioSamples; Rate: Integer);
    procedure Response(Sender: TObject; CallID: TAISIPCallID; const Text: string);
    procedure Transcript(Sender: TObject; CallID: TAISIPCallID; const Text: string);
    procedure Error(Sender: TObject; CallID: TAISIPCallID; const Text: string);
    procedure Pump(Milliseconds: Integer);
    procedure Run;
  end;

procedure Require(Value: Boolean; const Message: string);
begin if not Value then raise Exception.Create(Message); end;

procedure TTest.Credential(Sender: TObject; const UserName, Realm, Remote: string;
  var Secret: string; var Kind: TAISIPCredentialKind; var Found: Boolean);
begin Found := UserName = '1001'; Secret := 'fixture-password'; Kind := skPassword; end;

procedure TTest.Allow(Sender: TObject; const UserName, Target, Remote: string; var Accept: Boolean);
begin Accept := UserName = '1001'; end;

procedure TTest.Route(Sender: TObject; CallID: TAISIPCallID; const Caller, Target: string;
  var Destination: string; var Action: TAISIPRouteAction);
begin Action := srDeny; if Target = '8000' then Action := srAnswerLocally; end;

procedure TTest.Reg(Sender: TObject; Status, Expires: Integer; const Reason: string);
begin if (Status = 200) and (Expires > 0) then Registered := True; end;

procedure TTest.State(Sender: TObject; CallID: TAISIPCallID; Value: TAISIPCallState;
  Status: Integer; const Reason: string);
begin
  if Value = scConnected then Connected := True;
  if Value = scDisconnected then Connected := False;
end;

procedure TTest.Audio(Sender: TObject; CallID: TAISIPCallID;
  const Samples: TAISIPAudioSamples; Rate: Integer);
var I: Integer;
begin
  for I := 0 to High(Samples) do if Abs(Integer(Samples[I])) > 500 then
  begin Inc(Received); Break; end;
end;

procedure TTest.Response(Sender: TObject; CallID: TAISIPCallID; const Text: string);
begin Require(Text = 'fixture response', 'Wrong AI response'); Inc(Responses); end;

procedure TTest.Transcript(Sender: TObject; CallID: TAISIPCallID; const Text: string);
begin Require(Text = 'fixture utterance', 'Wrong transcript'); Inc(Transcripts); end;

procedure TTest.Error(Sender: TObject; CallID: TAISIPCallID; const Text: string);
begin raise Exception.Create(Text); end;

procedure TTest.Pump(Milliseconds: Integer);
var Deadline: QWord;
begin
  Deadline := GetTickCount64+QWord(Milliseconds);
  repeat Require(Agent.Poll(5), Server.LastError); Sleep(1);
  until GetTickCount64 >= Deadline;
end;

procedure TTest.Run;
var BasePort, I, J: Integer; CallID: TAISIPCallID; Samples: TAISIPAudioSamples;
begin
  Server := TAISIPServer.Create(nil); Client := TAISIPClient.Create(nil);
  Backend := TAISIPVoiceHTTPBackend.Create(nil); Agent := TAISIPVoiceAgent.Create(nil);
  try
    Server.RuntimeLibrary := ExpandFileName(ParamStr(1));
    BasePort := 22000+(GetProcessID mod 1000)*8;
    Server.SIPPort := BasePort; Server.RTPPort := BasePort+3000;
    Server.BindAddress := '127.0.0.1'; Server.PublicAddress := '127.0.0.1';
    Server.OnAuthenticate := @Credential; Server.OnAuthorizeCall := @Allow;
    Server.OnAuthorizeRegistration := @Allow; Server.OnRouteCall := @Route;
    Backend.STTURL := ParamStr(2)+'/stt'; Backend.ReplyURL := ParamStr(2)+'/ai';
    Backend.TTSURL := ParamStr(2)+'/tts'; Backend.AudioBaseURL := ParamStr(2)+'/audio/';
    Backend.ReplyToken := 'fixture-token'; Backend.TimeoutMs := 2000;
    Agent.SIP := Server; Agent.Backend := Backend; Agent.SilenceMs := 100;
    Agent.MinSpeechMs := 80; Agent.OnResponse := @Response;
    Agent.OnTranscript := @Transcript; Agent.OnError := @Error; Agent.Start;
    Require(Server.Start, Server.LastError);
    Client.RuntimeLibrary := Server.RuntimeLibrary; Client.UserName := '1001';
    Client.Password := 'fixture-password'; Client.BindAddress := '127.0.0.1';
    Client.PublicAddress := '127.0.0.1'; Client.ServerURI := 'sip:127.0.0.1:'+IntToStr(BasePort);
    Client.SIPPort := BasePort+1; Client.RTPPort := BasePort+3100;
    Client.OnRegistrationState := @Reg; Client.OnCallStateChanged := @State; Client.OnAudio := @Audio;
    Require(Client.Start, Client.LastError); Require(Client.RegisterAccount, Client.LastError);
    Pump(500); Require(Registered, 'SIP authentication failed');
    Require(Client.Call('8000', CallID), Client.LastError); Pump(1000);
    Require(Connected and (Agent.SessionCount = 1), 'AI did not answer SIP call');
    SetLength(Samples, 160);
    for J := 0 to 19 do
    begin
      for I := 0 to High(Samples) do Samples[I] := Round(7000*Sin((J*160+I)*2*Pi*440/8000));
      Require(Client.WriteAudio(CallID, Samples) = 160, Client.LastError); Pump(20);
    end;
    Pump(2000);
    Require((Transcripts = 1) and (Responses = 1) and (Received >= 15),
      'RTP -> STT -> AI -> TTS -> RTP round trip failed');
    Require(Client.Hangup(CallID), Client.LastError); Pump(400);
    Require(not Connected and (Agent.SessionCount = 0), 'SIP disconnect left a voice session');
    WriteLn('PASS: authenticated SIP call, real bidirectional RTP, asynchronous HTTP voice pipeline and disconnect (synthetic ASR/AI/TTS fixtures)');
  finally Agent.Free; Client.Free; Server.Free; Backend.Free; end;
end;

var Test: TTest;
begin
  Require(ParamCount = 2, 'Usage: test_sip_voice_loopback bridge.so http://127.0.0.1:port');
  Test := TTest.Create; try Test.Run; finally Test.Free; end;
end.
