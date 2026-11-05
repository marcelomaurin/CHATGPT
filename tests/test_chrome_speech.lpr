program chrome_speech_tests;
{$mode objfpc}{$H+}
uses Classes, SysUtils, Math, fphttpclient, fpjson, jsonparser, Sockets, aichromespeech;
type
  TReceiver=class
    Count: Integer;
    Text: string;
    procedure Received(Sender: TObject; const AText: string);
  end;
var Bridge: TAIChromeSpeech; Receiver: TReceiver; Client: TFPHTTPClient;
  Root,Origin,Reply: string; J:TJSONData; Epoch,OldEpoch:Integer;
  S:LongInt; A:TInetSockAddr; Started:QWord; Raw:string; Buf:array[0..1023] of Char; N:Integer;
procedure Check(B:Boolean;const Message:string);
begin if not B then raise Exception.Create(Message); end;
procedure TReceiver.Received(Sender:TObject;const AText:string);
begin
  Check(GetCurrentThreadID=MainThreadID,'Callback must run on caller/main thread');
  Inc(Count); Text:=AText;
end;
function Request(const Method,URL,Body,RequestOrigin,RequestHost:string):string;
var Req,Resp:TStringStream;
begin
  Req:=TStringStream.Create(Body); Resp:=TStringStream.Create('');
  try
    Client.RequestHeaders.Clear;
    if RequestOrigin<>'' then Client.AddHeader('Origin',RequestOrigin);
    if RequestHost<>'' then Client.AddHeader('Host',RequestHost);
    Client.AddHeader('Content-Type','application/json'); Client.RequestBody:=Req;
    Client.HTTPMethod(Method,URL,Resp,[200,400,403,404,409]); Result:=Resp.DataString;
  finally Client.RequestBody:=nil; Resp.Free; Req.Free; end;
end;
function StateEpoch:Integer;
begin
  J:=GetJSON(Request('GET',Root+'state','','',''));
  try
    Result:=TJSONObject(J).Get('epoch',0);
    Check(TJSONObject(J).Get('language','')='pt-BR','Portuguese locale normalization failed');
  finally J.Free;end;
end;
procedure Post(const Text:string; AGeneration:Integer; const From:string);
var O:TJSONObject; U:UTF8String;
begin
  SetString(U,PChar(Text),Length(Text));
  O:=TJSONObject.Create(['kind','text','epoch',AGeneration]); O.Add('text',U);
  try Reply:=Request('POST',Root+'event',O.AsJSON,From,'');finally O.Free;end;
end;
begin
  DefaultSystemCodePage:=CP_UTF8;
  SetMultiByteConversionCodePage(CP_UTF8);
  Bridge:=TAIChromeSpeech.Create(nil);Receiver:=TReceiver.Create;Client:=TFPHTTPClient.Create(nil);
  try
    Client.ConnectTimeout:=2000; Client.IOTimeout:=3000;
    Bridge.Language:='pt';Bridge.OnText:=@Receiver.Received;Bridge.Start;
    Root:=Bridge.URL;Origin:=Copy(Root,1,Pos('/',Copy(Root,8,MaxInt))+6);
    // Origin is URL without slash/path.
    Origin:=Copy(Root,1,Pos('/',Copy(Root,8,MaxInt))+6);
    Reply:=Request('GET',Root,'','','');
    Check(Pos('webkitSpeechRecognition',Reply)>0,'Embedded browser page missing');
    Check(Pos('Iniciar escuta',Reply)>0,'Explicit microphone consent action missing');
    Epoch:=StateEpoch;
    Post('Olá, professor!',Epoch,Origin);Check(Client.ResponseStatusCode=200,'Valid result rejected: '+Origin);
    Check(Receiver.Count=0,'HTTP thread delivered UI callback');Bridge.Poll;
    Check((Receiver.Count=1) and (Receiver.Text='Olá, professor!'),'UTF-8 text not delivered');
    Post('intruder',Epoch,'https://external.example');Check(Client.ResponseStatusCode=403,'Cross-origin accepted');
    Post('intruder',Epoch,'');Check(Client.ResponseStatusCode=403,'Missing Origin accepted');
    FillChar(A,SizeOf(A),0);A.sin_family:=AF_INET;A.sin_addr:=StrToNetAddr('127.0.0.1');
    A.sin_port:=htons(StrToInt(Copy(Origin,18,MaxInt)));
    S:=fpSocket(AF_INET,SOCK_STREAM,0);
    try
      Check(fpConnect(S,@A,SizeOf(A))=0,'Raw client failed');
      Raw:='GET '+Copy(Root,Length(Origin)+1,MaxInt)+'state HTTP/1.1'+#13#10+'Host: attacker.example'+#13#10#13#10;
      Check(fpSend(S,@Raw[1],Length(Raw),0)>0,'Raw send failed');
      N:=fpRecv(S,@Buf,SizeOf(Buf),0);SetString(Raw,PChar(@Buf),Max(0,N));
      Check(Pos('403',Raw)>0,'Foreign Host accepted');
    finally CloseSocket(S);end;
    Reply:=Request('GET',Origin+'/wrong-session/state','','','');Check(Client.ResponseStatusCode=403,'Wrong session accepted');
    Reply:=Request('POST',Root+'event','{invalid',Origin,'');Check(Client.ResponseStatusCode=400,'Invalid JSON accepted');
    Post(StringOfChar('x',4097),Epoch,Origin);Check(Client.ResponseStatusCode=400,'Oversized transcript accepted');
    Post('queued before pause',Epoch,Origin);Bridge.SetPaused(True);Bridge.Poll;
    Check(Receiver.Count=1,'Pause did not clear pending text');
    Post('while speaking',Epoch,Origin);Check(Client.ResponseStatusCode=409,'Paused result accepted');
    OldEpoch:=Epoch;Bridge.SetPaused(False);Epoch:=StateEpoch;
    Check(Epoch<>OldEpoch,'Pause/resume did not invalidate generation');
    Post('stale recording',OldEpoch,Origin);Check(Client.ResponseStatusCode=409,'Stale recording accepted');
    Post('segunda pergunta',Epoch,Origin);Bridge.Poll;Check(Receiver.Count=2,'Resume failed');
    // Shutdown must not wait for a silent browser connection.
    FillChar(A,SizeOf(A),0);A.sin_family:=AF_INET;A.sin_addr:=StrToNetAddr('127.0.0.1');
    A.sin_port:=htons(StrToInt(Copy(Origin,18,MaxInt)));
    S:=fpSocket(AF_INET,SOCK_STREAM,0);
    try
      Check(fpConnect(S,@A,SizeOf(A))=0,'Silent client connection failed');Sleep(80);
      Started:=GetTickCount64;Bridge.Stop;
      Check(GetTickCount64-Started<750,'Shutdown blocked on silent connection');
    finally CloseSocket(S);end;
    Check(not Bridge.Active,'Bridge still active');
    Bridge.Start;Check(Bridge.URL<>Root,'Restart reused session token');Bridge.Stop;
    WriteLn('PASS: Chrome HTTP bridge, UTF-8, main-thread callbacks, origin/host/session checks, invalid JSON, length limit, pause, stale results, resume, shutdown, restart');
  finally Client.Free;Bridge.Free;Receiver.Free;end;
end.
