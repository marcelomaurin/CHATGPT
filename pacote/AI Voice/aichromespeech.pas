unit aichromespeech;
{$mode objfpc}{$H+}
interface
uses Classes, SysUtils, Sockets;
type
  TAIChromeSpeechEvent = procedure(Sender: TObject; const AText: string) of object;
  TAIChromeSpeechWorker = class;
  { Poll must be called on the application's main thread. No microphone is
    opened by this component: Chrome asks permission after a user gesture. }
  TAIChromeSpeech = class(TComponent)
  private
    FWorker: TAIChromeSpeechWorker;
    FLanguage, FBrowserExecutable: string;
    FVoiceThreshold: Double;
    FSilenceMs,FMinSpeechMs: Integer;
    FOnText, FOnState: TAIChromeSpeechEvent;
    function GetURL: string;
    function GetActive: Boolean;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure Start;
    procedure Stop;
    procedure SetPaused(AValue: Boolean);
    procedure Poll;
    procedure OpenBrowser;
    property URL: string read GetURL;
    property Active: Boolean read GetActive;
  published
    property VoiceThreshold: Double read FVoiceThreshold write FVoiceThreshold;
    property SilenceTimeoutMs: Integer read FSilenceMs write FSilenceMs;
    property MinSpeechMs: Integer read FMinSpeechMs write FMinSpeechMs;
    property Language: string read FLanguage write FLanguage;
    property BrowserExecutable: string read FBrowserExecutable write FBrowserExecutable;
    property OnText: TAIChromeSpeechEvent read FOnText write FOnText;
    property OnState: TAIChromeSpeechEvent read FOnState write FOnState;
  end;
  TAIChromeSpeechWorker = class(TThread)
  private
    FSocket: LongInt;
    FLock: TRTLCriticalSection;
    FQueue: TStringList;
    FPort: Word;
    FVoiceThreshold: Double;
    FSilenceMs,FMinSpeechMs: Integer;
    FToken, FLanguage: string;
    FPaused: Boolean;
    FEpoch: Integer;
    FLastHeartbeat: QWord;
    FReportedLost: Boolean;
    procedure Serve(Client: LongInt);
    function Handle(const Method, Path, Host, Origin, Body: string;
      out Code: Integer; out ContentType: string): string;
    procedure Queue(const Kind, Text: string);
  protected
    procedure Execute; override;
  public
    constructor Create(const ALanguage: string);
    destructor Destroy; override;
    procedure Pause(AValue: Boolean);
    function Drain: TStringList;
    function SessionURL: string;
  end;
procedure Register;
implementation
uses LResources, Process, Math, fpjson, jsonparser,
  {$IFDEF MSWINDOWS}WinSock2{$ELSE}BaseUnix{$ENDIF};
const
  ChromeSpeechHTML = {$I aichromespeech_page.inc};

procedure Register;
begin RegisterComponents('AI Voice', [TAIChromeSpeech]); end;

function Readable(S: LongInt; TimeoutMs: Integer): Boolean;
var F: TFDSet; T: TTimeVal;
begin
  {$IFDEF MSWINDOWS}WinSock2.FD_ZERO(F); WinSock2.FD_SET(S,F);
  {$ELSE}fpFD_ZERO(F); fpFD_SET(S,F);{$ENDIF}
  T.tv_sec:=TimeoutMs div 1000; T.tv_usec:=(TimeoutMs mod 1000)*1000;
  {$IFDEF MSWINDOWS}Result:=WinSock2.select(0,@F,nil,nil,@T)>0;
  {$ELSE}Result:=fpSelect(S+1,@F,nil,nil,@T)>0;{$ENDIF}
end;

constructor TAIChromeSpeechWorker.Create(const ALanguage: string);
var A: TInetSockAddr; L: TSockLen; G: TGUID;
begin
  inherited Create(True); FreeOnTerminate:=False;
  FSocket:=-1; InitCriticalSection(FLock); FQueue:=TStringList.Create;
  FLanguage:=ALanguage; if (FLanguage='') or (FLanguage='pt') then FLanguage:='pt-BR';
  CreateGUID(G); FToken:=StringReplace(StringReplace(GUIDToString(G),'{','',[]),'}','',[]);
  FEpoch:=1; FLastHeartbeat:=GetTickCount64;
  FSocket:=fpSocket(AF_INET,SOCK_STREAM,0);
  if FSocket<0 then raise Exception.Create('Nao foi possivel abrir a ponte do Chrome.');
  FillChar(A,SizeOf(A),0); A.sin_family:=AF_INET;
  A.sin_addr:=StrToNetAddr('127.0.0.1'); A.sin_port:=0;
  if (fpBind(FSocket,@A,SizeOf(A))<>0) or (fpListen(FSocket,4)<>0) then
    raise Exception.Create('Nao foi possivel iniciar a ponte local do Chrome.');
  L:=SizeOf(A);
  if fpGetSockName(FSocket,@A,@L)<>0 then raise Exception.Create('Porta local indisponivel.');
  FPort:=ntohs(A.sin_port);
end;

destructor TAIChromeSpeechWorker.Destroy;
begin
  Terminate;
  { Also safe when construction failed while the thread was suspended. }
  if Suspended then Start;
  WaitFor;
  if FSocket>=0 then CloseSocket(FSocket);
  FQueue.Free; DoneCriticalSection(FLock); inherited Destroy;
end;

function TAIChromeSpeechWorker.SessionURL: string;
begin Result:='http://127.0.0.1:'+IntToStr(FPort)+'/'+FToken+'/'; end;

procedure TAIChromeSpeechWorker.Queue(const Kind, Text: string);
begin
  { Caller holds FLock. Bounded queue; never log microphone contents. }
  if FQueue.Count<16 then FQueue.Add(Kind+Text);
end;

procedure TAIChromeSpeechWorker.Pause(AValue: Boolean);
begin
  EnterCriticalSection(FLock);
  try
    if FPaused=AValue then Exit;
    FPaused:=AValue; Inc(FEpoch); FQueue.Clear;
  finally LeaveCriticalSection(FLock); end;
end;

function TAIChromeSpeechWorker.Drain: TStringList;
begin
  Result:=TStringList.Create;
  EnterCriticalSection(FLock);
  try
    if not FReportedLost and (GetTickCount64-FLastHeartbeat>8000) then
    begin Queue('S','Chrome desconectado. Reabra a escuta pelo botao do microfone.'); FReportedLost:=True; end;
    Result.Assign(FQueue); FQueue.Clear;
  finally LeaveCriticalSection(FLock); end;
end;

function TAIChromeSpeechWorker.Handle(const Method, Path, Host, Origin, Body: string;
  out Code: Integer; out ContentType: string): string;
var Prefix, ExpectedOrigin, Text, Kind: string; UTF8Body: UTF8String; J, V: TJSONData; O: TJSONObject;
begin
  Code:=403; ContentType:='text/plain; charset=utf-8'; Result:='Forbidden';
  Prefix:='/'+FToken+'/'; ExpectedOrigin:='http://127.0.0.1:'+IntToStr(FPort);
  if Host<>'127.0.0.1:'+IntToStr(FPort) then Exit;
  if Copy(Path,1,Length(Prefix))<>Prefix then Exit;
  if (Origin<>'') and (Origin<>ExpectedOrigin) then Exit;
  if (Method='GET') and (Path=Prefix) then
  begin Code:=200; ContentType:='text/html; charset=utf-8'; Exit(ChromeSpeechHTML); end;
  EnterCriticalSection(FLock);
  try
    if (Method='GET') and (Path=Prefix+'state') then
    begin
      FLastHeartbeat:=GetTickCount64;
      if FReportedLost then begin Queue('S','Chrome reconectado.'); FReportedLost:=False; end;
      O:=TJSONObject.Create;
      try
        O.Add('voiceThreshold',FVoiceThreshold); O.Add('silenceMs',FSilenceMs); O.Add('minSpeechMs',FMinSpeechMs);
        O.Add('enabled',not FPaused); O.Add('epoch',FEpoch); O.Add('language',FLanguage);
        Result:=O.AsJSON;
      finally O.Free; end;
      Code:=200; ContentType:='application/json; charset=utf-8'; Exit;
    end;
    if (Method<>'POST') or (Path<>Prefix+'event') then
    begin Code:=404; Result:='Not found'; Exit; end;
    { Browser POSTs must carry Origin: no cross-site or unauthenticated IPC. }
    if Origin<>ExpectedOrigin then Exit;
    Code:=400; Result:='Invalid event';
    SetString(UTF8Body,PChar(Body),Length(Body));
    try J:=GetJSON(UTF8Body); except Exit; end;
    try
      if not (J is TJSONObject) then Exit;
      O:=TJSONObject(J); V:=O.Find('epoch');
      if (V=nil) or (V.JSONType<>jtNumber) then Exit;
      if (V.AsInteger<>FEpoch) or FPaused then
      begin Code:=409; Result:='Paused or stale session'; Exit; end;
      V:=O.Find('kind'); if (V=nil) or (V.JSONType<>jtString) then Exit;
      Kind:=V.AsString;
      V:=O.Find('text'); if (V=nil) or (V.JSONType<>jtString) then Exit;
      SetString(Text,PAnsiChar(V.AsString),Length(V.AsString)); Text:=Trim(Text);
      if (Text='') or (Length(Text)>4096) or (Pos(#0,Text)>0) then Exit;
      if Kind='text' then Queue('T',Text)
      else if Kind='state' then Queue('S',Text) else Exit;
      Code:=200; Result:='OK';
    finally J.Free; end;
  finally LeaveCriticalSection(FLock); end;
end;

procedure TAIChromeSpeechWorker.Serve(Client: LongInt);
var Data, Body, Header, Line, Method, Path, Host, Origin, CT, Reply: string;
  Buf: array[0..2047] of Char; N,P,Q, HeaderEnd, Len, Code, Sent: Integer;
  Deadline: QWord; Headers: TStringList; HasLength: Boolean;
begin
  Data:=''; HeaderEnd:=0; Len:=0; Deadline:=GetTickCount64+2000;
  while not Terminated and (GetTickCount64<Deadline) do
  begin
    if not Readable(Client,50) then Continue;
    N:=fpRecv(Client,@Buf,SizeOf(Buf),0); if N<=0 then Exit;
    SetString(Line,PChar(@Buf),N); Data:=Data+Line;
    if Length(Data)>16384 then Exit;
    HeaderEnd:=Pos(#13#10#13#10,Data);
    if HeaderEnd>0 then Break;
  end;
  if Terminated or (HeaderEnd=0) then Exit;
  Header:=Copy(Data,1,HeaderEnd-1); Headers:=TStringList.Create;
  try
    Headers.Text:=Header; if Headers.Count=0 then Exit;
    Line:=Headers[0]; P:=Pos(' ',Line); if P=0 then Exit;
    Method:=Copy(Line,1,P-1); Delete(Line,1,P);
    P:=Pos(' ',Line); if P=0 then Exit; Path:=Copy(Line,1,P-1);
    Host:=''; Origin:=''; HasLength:=False;
    for N:=1 to Headers.Count-1 do
    begin
      Line:=Headers[N]; P:=Pos(':',Line); if P=0 then Exit;
      Header:=LowerCase(Copy(Line,1,P-1)); Line:=Trim(Copy(Line,P+1,MaxInt));
      if Header='transfer-encoding' then Exit;
      if Header='host' then begin if Host<>'' then Exit; Host:=Line; end;
      if Header='origin' then begin if Origin<>'' then Exit; Origin:=Line; end;
      if Header='content-length' then
      begin
        if HasLength then Exit; HasLength:=True;
        if not TryStrToInt(Line,Len) or (Len<0) or (Len>8192) then Exit;
      end;
    end;
    Body:=Copy(Data,HeaderEnd+4,MaxInt);
    while (Length(Body)<Len) and not Terminated and (GetTickCount64<Deadline) do
    begin
      if not Readable(Client,50) then Continue;
      N:=fpRecv(Client,@Buf,SizeOf(Buf),0); if N<=0 then Exit;
      SetString(Line,PChar(@Buf),N); Body:=Body+Line;
      if Length(Body)>8192 then Exit;
    end;
    if Terminated or (Length(Body)<>Len) then Exit;
    Reply:=Handle(Method,Path,Host,Origin,Body,Code,CT);
    Data:='HTTP/1.1 '+IntToStr(Code)+' Response'+#13#10+
      'Content-Type: '+CT+#13#10+'Content-Length: '+IntToStr(Length(Reply))+#13#10+
      'Cache-Control: no-store'+#13#10+'Referrer-Policy: no-referrer'+#13#10+
      'X-Content-Type-Options: nosniff'+#13#10+'X-Frame-Options: DENY'+#13#10+
      'Content-Security-Policy: default-src ''none''; script-src ''unsafe-inline''; style-src ''unsafe-inline''; connect-src ''self''; frame-ancestors ''none'''+#13#10+
      'Connection: close'+#13#10#13#10+Reply;
    Sent:=0;
    while (Sent<Length(Data)) and not Terminated do
    begin Q:=fpSend(Client,@Data[Sent+1],Length(Data)-Sent,0); if Q<=0 then Break; Inc(Sent,Q); end;
  finally Headers.Free; end;
end;

procedure TAIChromeSpeechWorker.Execute;
var Client: LongInt;
begin
  while not Terminated do
  begin
    if (FSocket<0) or not Readable(FSocket,50) then Continue;
    Client:=fpAccept(FSocket,nil,nil); if Client<0 then Continue;
    try
      try Serve(Client); except { Invalid local requests cannot stop the listener. } end;
    finally CloseSocket(Client); end;
  end;
end;

constructor TAIChromeSpeech.Create(AOwner: TComponent);
begin inherited Create(AOwner); FLanguage:='pt-BR';FVoiceThreshold:=0.015;FSilenceMs:=900;FMinSpeechMs:=250;end;
destructor TAIChromeSpeech.Destroy;
begin Stop; inherited Destroy; end;
function TAIChromeSpeech.GetActive: Boolean;
begin Result:=FWorker<>nil; end;
function TAIChromeSpeech.GetURL: string;
begin Result:=''; if FWorker<>nil then Result:=FWorker.SessionURL; end;
procedure TAIChromeSpeech.Start;
begin
  if FWorker<>nil then Exit;
  FWorker:=TAIChromeSpeechWorker.Create(FLanguage);
  FWorker.FVoiceThreshold:=EnsureRange(FVoiceThreshold,0.001,0.5);
  FWorker.FSilenceMs:=EnsureRange(FSilenceMs,200,5000);
  FWorker.FMinSpeechMs:=EnsureRange(FMinSpeechMs,100,3000);
  FWorker.Start;
end;
procedure TAIChromeSpeech.Stop;
begin FreeAndNil(FWorker); end;
procedure TAIChromeSpeech.SetPaused(AValue: Boolean);
begin if FWorker<>nil then FWorker.Pause(AValue); end;
procedure TAIChromeSpeech.Poll;
var Events: TStringList; I: Integer; S: string;
begin
  if FWorker=nil then Exit;
  Events:=FWorker.Drain;
  try
    for I:=0 to Events.Count-1 do
    begin
      { An earlier callback can pause/stop the recognizer. Dispatch one text
        per polling cycle so queued speech cannot trigger a second request. }
      S:=Events[I];
      if (S[1]='T') and Assigned(FOnText) then
      begin FOnText(Self,Copy(S,2,MaxInt)); Break; end;
      if (S[1]='S') and Assigned(FOnState) then FOnState(Self,Copy(S,2,MaxInt));
    end;
  finally Events.Free; end;
end;
procedure TAIChromeSpeech.OpenBrowser;
var P: TProcess; Exe, Candidate: string; Roots: array[0..2] of string; I: Integer;
begin
  if not Active then raise Exception.Create('Inicie a ponte antes de abrir o Chrome.');
  Exe:=FBrowserExecutable;
  if Exe='' then
  begin
    Roots[0]:=GetEnvironmentVariable('ProgramFiles');
    Roots[1]:=GetEnvironmentVariable('ProgramFiles(x86)');
    Roots[2]:=GetEnvironmentVariable('LOCALAPPDATA');
    for I:=0 to High(Roots) do
    begin
      Candidate:=IncludeTrailingPathDelimiter(Roots[I])+'Google\Chrome\Application\chrome.exe';
      if (Roots[I]<>'') and FileExists(Candidate) then begin Exe:=Candidate; Break; end;
    end;
  end;
  if (Exe='') or not FileExists(Exe) then
    raise Exception.Create('Google Chrome nao encontrado. Instale o Chrome ou configure BrowserExecutable.');
  P:=TProcess.Create(nil);
  try
    P.Executable:=Exe; P.Parameters.Add('--new-window'); P.Parameters.Add(URL);
    P.Options:=[poNoConsole]; P.Execute;
  finally P.Free; end;
end;
initialization
  {$I aichromespeech_icon.lrs}

end.
