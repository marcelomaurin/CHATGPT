program test_sip_loopback;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}cthreads,{$ENDIF}
  Classes, SysUtils, Math, aisip_types, aisip_client, aisip_server;

type
  TTest = class
    Server: TAISIPServer;
    A, B, Bad: TAISIPClient;
    Registered, AuthOK, AuthDenied, Routed, States, AudioA, AudioB, Digits: Integer;
    ACall, BCall: TAISIPCallID;
    ConnectedA, ConnectedB, EndedA, EndedB, RejectNext, DenyRegistration: Boolean;
    LastBadStatus, LastAStatus, LastRegA: Integer;
    procedure Credentials(Sender: TObject; const UserName, Realm, Remote: string;
      var Secret: string; var Kind: TAISIPCredentialKind; var Found: Boolean);
    procedure Allow(Sender: TObject; const UserName, Target, Remote: string; var Accept: Boolean);
    procedure RegisterPermission(Sender: TObject; const UserName, Target, Remote: string; var Accept: Boolean);
    procedure Auth(Sender: TObject; const UserName, Remote: string; Accepted: Boolean; Status: Integer);
    procedure Route(Sender: TObject; CallID: TAISIPCallID; const Caller, Target: string;
      var Destination: string; var Action: TAISIPRouteAction);
    procedure RegState(Sender: TObject; Status, Expires: Integer; const Reason: string);
    procedure Incoming(Sender: TObject; CallID: TAISIPCallID; const Caller, Target: string);
    procedure State(Sender: TObject; CallID: TAISIPCallID; Value: TAISIPCallState; Status: Integer; const Reason: string);
    procedure Audio(Sender: TObject; CallID: TAISIPCallID; const Samples: TAISIPAudioSamples; Rate: Integer);
    procedure DTMF(Sender: TObject; CallID: TAISIPCallID; const Digit: string; Duration: Integer);
    procedure Pump(Milliseconds: Integer);
    procedure Run;
  end;

procedure Require(Condition: Boolean; const Message: string);
begin
  if not Condition then raise Exception.Create(Message);
end;

procedure TTest.Credentials(Sender: TObject; const UserName, Realm, Remote: string;
  var Secret: string; var Kind: TAISIPCredentialKind; var Found: Boolean);
begin
  Found := (Realm = 'maurin.local') and ((UserName = '1001') or (UserName = '1002') or (UserName = '1003'));
  Secret := 'loopback-only-test'; Kind := skPassword;
end;

procedure TTest.Allow(Sender: TObject; const UserName, Target, Remote: string; var Accept: Boolean);
begin Accept := True; end;

procedure TTest.RegisterPermission(Sender: TObject; const UserName, Target, Remote: string; var Accept: Boolean);
begin Accept := not DenyRegistration; end;

procedure TTest.Auth(Sender: TObject; const UserName, Remote: string; Accepted: Boolean; Status: Integer);
begin if Accepted then Inc(AuthOK) else Inc(AuthDenied); end;

procedure TTest.Route(Sender: TObject; CallID: TAISIPCallID; const Caller, Target: string;
  var Destination: string; var Action: TAISIPRouteAction);
begin
  Inc(Routed); Destination := Target;
  if Target = '1002' then Action := srRoute else Action := srDeny;
end;

procedure TTest.RegState(Sender: TObject; Status, Expires: Integer; const Reason: string);
begin
  WriteLn('registration ', TAISIPClient(Sender).UserName, ' ', Status, ' expires=', Expires, ' ', Reason);
  if Sender = Bad then LastBadStatus := Status
  else if (Status = 200) and (Expires > 0) then Inc(Registered);
  if Sender = A then LastRegA := Status;
end;

procedure TTest.Incoming(Sender: TObject; CallID: TAISIPCallID; const Caller, Target: string);
begin
  Require(Sender = B, 'Unexpected incoming call'); BCall := CallID;
  if RejectNext then Require(B.Reject(CallID), B.LastError)
  else Require(B.Answer(CallID), B.LastError);
end;

procedure TTest.State(Sender: TObject; CallID: TAISIPCallID; Value: TAISIPCallState;
  Status: Integer; const Reason: string);
begin
  Inc(States);
  WriteLn('state ', TAISIPClient(Sender).UserName, ' call=', CallID, ' state=', Ord(Value), ' code=', Status);
  if Sender = A then begin
    LastAStatus := Status;
    if Value = scConnected then ConnectedA := True;
    if Value = scDisconnected then EndedA := True;
  end;
  if Sender = B then begin
    if Value = scConnected then ConnectedB := True;
    if Value = scDisconnected then EndedB := True;
  end;
end;

procedure TTest.Audio(Sender: TObject; CallID: TAISIPCallID;
  const Samples: TAISIPAudioSamples; Rate: Integer);
var I: Integer;
begin
  Require(Rate = 8000, 'Unexpected PCM sample rate');
  for I := 0 to High(Samples) do if Abs(Integer(Samples[I])) > 1000 then begin
    if Sender = A then Inc(AudioA);
    if Sender = B then Inc(AudioB);
    Break;
  end;
end;

procedure TTest.DTMF(Sender: TObject; CallID: TAISIPCallID; const Digit: string; Duration: Integer);
begin if (Sender = B) and (Digit = '5') then Inc(Digits); end;

procedure TTest.Pump(Milliseconds: Integer);
var Deadline: QWord;
begin
  Deadline := GetTickCount64 + QWord(Milliseconds);
  repeat Require(Server.Poll(5), Server.LastError); Sleep(1);
  until GetTickCount64 >= Deadline;
end;

procedure TTest.Run;
var Clients: array[0..2] of TAISIPClient; I, J: Integer;
    Samples: TAISIPAudioSamples; BasePort: Integer; URI: string;
begin
  Server := TAISIPServer.Create(nil); A := TAISIPClient.Create(nil);
  B := TAISIPClient.Create(nil); Bad := TAISIPClient.Create(nil);
  try
    Server.RuntimeLibrary := ExpandFileName(ParamStr(1));
    BasePort := 20000 + (GetProcessID mod 1000) * 8;
    Server.SIPPort := BasePort; Server.RTPPort := BasePort + 2000;
    Server.BindAddress := '127.0.0.1'; Server.PublicAddress := '127.0.0.1';
    Server.OnAuthenticate := @Credentials;
    Server.OnAuthorizeRegistration := @RegisterPermission;
    Server.OnAuthorizeCall := @Allow; Server.OnRouteCall := @Route;
    Server.OnAuthenticationResult := @Auth;
    Require(Server.Start, Server.LastError);
    URI := 'sip:127.0.0.1:' + IntToStr(Server.LocalPort);
    Clients[0] := A; Clients[1] := B; Clients[2] := Bad;
    for I := 0 to 2 do begin
      Clients[I].RuntimeLibrary := Server.RuntimeLibrary;
      Clients[I].ServerURI := URI; Clients[I].UserName := IntToStr(1001 + I);
      Clients[I].Password := 'loopback-only-test';
      Clients[I].BindAddress := '127.0.0.1'; Clients[I].PublicAddress := '127.0.0.1';
      Clients[I].SIPPort := BasePort + 1 + I; Clients[I].RTPPort := BasePort + 2100 + I*100;
      Clients[I].OnRegistrationState := @RegState;
      Clients[I].OnIncomingCall := @Incoming; Clients[I].OnCallStateChanged := @State;
      Clients[I].OnAudio := @Audio; Clients[I].OnDTMF := @DTMF;
    end;
    Bad.Password := 'incorrect';
    for I := 0 to 2 do begin
      Require(Clients[I].Start, Clients[I].LastError);
      Require(Clients[I].RegisterAccount, Clients[I].LastError);
    end;
    Pump(1000);
    Require(Registered = 2, 'Expected two authenticated registrations');
    Require((LastBadStatus = 403) and (AuthDenied > 0), 'Wrong password was not rejected');
    Require(A.Call('1002', ACall), A.LastError); Pump(1800);
    Require(ConnectedA and ConnectedB and (Routed = 1), 'Call was not bridged');
    SetLength(Samples, 160);
    for J := 0 to 99 do begin
      for I := 0 to High(Samples) do Samples[I] := Round(7000 * Sin((J*160+I) * 2 * Pi * 440 / 8000));
      Require(A.WriteAudio(ACall, Samples) = 160, A.LastError);
      Require(B.WriteAudio(BCall, Samples) = 160, B.LastError);
      Pump(20);
    end;
    Require((AudioA > 10) and (AudioB > 10), 'No non-silent bidirectional RTP audio');
    Require(A.SendDTMF(ACall, '5'), A.LastError); Pump(800);
    Require(Digits > 0, 'DTMF was not relayed');
    Require(A.Hangup(ACall), A.LastError);
    for I := 0 to 100 do begin Pump(20); if EndedA and EndedB then Break; end;
    Require(EndedA and EndedB, 'Hangup was not propagated');
    EndedA := False; RejectNext := True;
    Require(A.Call('1002', ACall), A.LastError); Pump(800);
    Require(EndedA and (LastAStatus = 486), 'Busy rejection was not propagated');
    EndedA := False;
    Require(A.Call('9999', ACall), A.LastError); Pump(800);
    Require(EndedA and (LastAStatus = 403), 'Routing default deny failed');
    Require(A.UnregisterAccount, A.LastError); Pump(400);
    DenyRegistration := True;
    Require(A.RegisterAccount, A.LastError); Pump(500);
    Require(LastRegA = 403, 'Registration authorization event was not enforced');
    WriteLn('PASS: SIP Digest, wrong-password rejection, event authorization, routing, bidirectional RTP/PCM, DTMF, busy, deny, hangup and unregistration');
  finally
    Bad.Free; B.Free; A.Free; Server.Free;
  end;
end;

var Test: TTest;
begin
  Require(ParamCount = 1, 'Usage: test_sip_loopback /absolute/path/libchatgpt_sip_bridge.so');
  Test := TTest.Create;
  try Test.Run; finally Test.Free; end;
end.
