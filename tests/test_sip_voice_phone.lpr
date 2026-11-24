program test_sip_voice_phone;
{$mode objfpc}{$H+}
uses {$IFDEF UNIX}cthreads,{$ENDIF}
  Classes, SysUtils, Math, aisip_types, aisip_client;

type
  TPhone = class
    Client: TAISIPClient;
    Registered, Connected: Boolean;
    LastStatus, Frames: Integer;
    procedure Registration(Sender: TObject; Status, Expires: Integer; const Reason: string);
    procedure State(Sender: TObject; CallID: TAISIPCallID; Value: TAISIPCallState;
      Status: Integer; const Reason: string);
    procedure Audio(Sender: TObject; CallID: TAISIPCallID;
      const Samples: TAISIPAudioSamples; Rate: Integer);
    procedure Pump(Milliseconds: Integer);
    procedure Run;
  end;

procedure Require(Value: Boolean; const Message: string);
begin if not Value then raise Exception.Create(Message); end;

procedure TPhone.Registration(Sender: TObject; Status, Expires: Integer; const Reason: string);
begin if (Status = 200) and (Expires > 0) then Registered := True; end;

procedure TPhone.State(Sender: TObject; CallID: TAISIPCallID; Value: TAISIPCallState;
  Status: Integer; const Reason: string);
begin
  LastStatus := Status;
  if Value = scConnected then Connected := True;
  if Value = scDisconnected then Connected := False;
end;

procedure TPhone.Audio(Sender: TObject; CallID: TAISIPCallID;
  const Samples: TAISIPAudioSamples; Rate: Integer);
var I: Integer;
begin
  for I := 0 to High(Samples) do if Abs(Integer(Samples[I])) > 500 then
  begin Inc(Frames); Break; end;
end;

procedure TPhone.Pump(Milliseconds: Integer);
var UntilTime: QWord;
begin
  UntilTime := GetTickCount64+QWord(Milliseconds);
  repeat Require(Client.Poll(5), Client.LastError); Sleep(1);
  until GetTickCount64 >= UntilTime;
end;

procedure TPhone.Run;
var CallID: TAISIPCallID; I, J: Integer; Samples: TAISIPAudioSamples;
begin
  Client := TAISIPClient.Create(nil);
  try
    Client.RuntimeLibrary := ExpandFileName(ParamStr(1)); Client.ServerURI := ParamStr(2);
    Client.UserName := '1001'; Client.Password := 'fixture-password'; Client.Realm := 'maurin.local';
    Client.BindAddress := '127.0.0.1'; Client.PublicAddress := '127.0.0.1';
    Client.SIPPort := 0; Client.RTPPort := 48000+(GetProcessID mod 1000)*8;
    Client.OnRegistrationState := @Registration; Client.OnCallStateChanged := @State;
    Client.OnAudio := @Audio;
    Require(Client.Start, Client.LastError); Require(Client.RegisterAccount, Client.LastError);
    Pump(700); Require(Registered, 'External daemon did not authenticate phone');
    Require(Client.Call('9999', CallID), Client.LastError); Pump(500);
    Require(not Connected and (LastStatus = 403), 'Daemon allowed an unauthorized destination');
    Require(Client.Call('8000', CallID), Client.LastError); Pump(1000);
    Require(Connected, 'External daemon did not answer AI extension');
    SetLength(Samples, 160);
    for J := 0 to 19 do
    begin
      for I := 0 to High(Samples) do Samples[I] := Round(7000*Sin((J*160+I)*2*Pi*440/8000));
      Require(Client.WriteAudio(CallID, Samples) = 160, Client.LastError); Pump(20);
    end;
    Pump(2500); Require(Frames >= 15, 'No response audio from Casa daemon');
    Require(Client.Hangup(CallID), Client.LastError); Pump(300);
    Require(not Connected, 'Casa daemon did not finish call');
    WriteLn('PASS: separate Casa daemon, configured accounts, destination authorization, voice pipeline and RTP response');
  finally Client.Free; end;
end;

var Phone: TPhone;
begin
  Require(ParamCount = 2, 'Usage: test_sip_voice_phone bridge.so sip:127.0.0.1:port');
  Phone := TPhone.Create; try Phone.Run; finally Phone.Free; end;
end.
