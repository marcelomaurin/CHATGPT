unit airemotesignaling;
{$mode objfpc}{$H+}
interface
uses Classes, SysUtils, fpjson;
type
  EAIRemoteAPI = class(Exception)
  public
    Status: Integer;
    Code: string;
    constructor CreateAPI(AStatus:Integer; const ACode, AMessage:string);
  end;
  { Synchronous client: call from a worker, never the visual thread. Not thread-safe. }
  TAIRemoteSignalingClient = class
  private
    FBaseURL,FToken:string;
    FAllowLocalHTTP:Boolean;
    function Request(const Method,Route:string; Body:TJSONObject):TJSONObject;
  public
    property BaseURL:string read FBaseURL write FBaseURL;
    property DeviceToken:string read FToken write FToken;
    property AllowLocalHTTP:Boolean read FAllowLocalHTTP write FAllowLocalHTTP;
    function RegisterDevice(const RegistrationId,Secret,Name,Platform,Version:string):TJSONObject;
    function Heartbeat:TJSONObject;
    function Incoming:TJSONObject;
    function RequestSession(const Key:string; Control:Boolean):TJSONObject;
    function Decide(const Id:string; Accept,Control:Boolean):TJSONObject;
    function CloseSession(const Id,Reason:string):TJSONObject;
    function GetSession(const Id:string):TJSONObject;
    function Health:TJSONObject;
    function AnnounceEndpoint(Port:Integer; const Transport:string='tcp'; const LocalIP:string=''):TJSONObject;
    function GetPeerEndpoint(const Id:string):TJSONObject;
    function SendDiagnosticLog(const Category, Message, LogContent: string; const SessionId: string = ''; const Level: string = 'error'): TJSONObject;
  end;
function AIRemoteValidKey(const Key:string):Boolean;
implementation
uses jsonparser, airemoteidentity
{$IFDEF WINDOWS}, Windows{$ENDIF};
{$IFDEF WINDOWS}
type HINTERNET=Pointer;
function WinHttpOpen(Agent:PWideChar; AccessType:DWORD; ProxyName,ProxyBypass:PWideChar; Flags:DWORD):HINTERNET;
  stdcall; external 'winhttp.dll';
function WinHttpConnect(Session:HINTERNET; Server:PWideChar; Port:Word; Reserved:DWORD):HINTERNET;
  stdcall; external 'winhttp.dll';
function WinHttpOpenRequest(Connect:HINTERNET; Verb,ObjectName,Version,Referrer:PWideChar;
  AcceptTypes:Pointer; Flags:DWORD):HINTERNET; stdcall; external 'winhttp.dll';
function WinHttpSetTimeouts(Session:HINTERNET; Resolve,Connect,Send,Receive:Integer):BOOL;
  stdcall; external 'winhttp.dll';
function WinHttpSetOption(Handle:HINTERNET; Option:DWORD; Buffer:Pointer; BufferLength:DWORD):BOOL;
  stdcall; external 'winhttp.dll';
function WinHttpSendRequest(Request:HINTERNET; Headers:PWideChar; HeadersLength:DWORD; Optional:Pointer;
  OptionalLength,TotalLength:DWORD; Context:PtrUInt):BOOL; stdcall; external 'winhttp.dll';
function WinHttpReceiveResponse(Request:HINTERNET; Reserved:Pointer):BOOL; stdcall; external 'winhttp.dll';
function WinHttpQueryHeaders(Request:HINTERNET; InfoLevel:DWORD; Name:PWideChar;
  Buffer:Pointer; var BufferLength:DWORD; Index:Pointer):BOOL; stdcall; external 'winhttp.dll';
function WinHttpReadData(Request:HINTERNET; Buffer:Pointer; BytesToRead:DWORD; var BytesRead:DWORD):BOOL;
  stdcall; external 'winhttp.dll';
function WinHttpCloseHandle(Handle:HINTERNET):BOOL; stdcall; external 'winhttp.dll';

function HTTP(const URL,Method,Token,Body,Idempotency:string; AllowLocal:Boolean; out Status:Integer):string;
var Rest,Host,Resource,Authority:string; Port:Word; P,I,N:Integer; Secure:Boolean;
    Session,Connection,Req:HINTERNET; WAgent,WHost,WMethod,WResource,WHeaders:UnicodeString;
    Flags,Policy,Size,Code,ReadCount:DWORD; Buffer:array[0..8191] of Byte; Data:Pointer;
begin
  Secure:=Copy(URL,1,8)='https://';
  if Secure then Rest:=Copy(URL,9,MaxInt)
  else if Copy(URL,1,7)='http://' then Rest:=Copy(URL,8,MaxInt)
  else raise Exception.Create('HTTPS URL required');
  P:=Pos('/',Rest);
  if P=0 then raise Exception.Create('API path required');
  Authority:=Copy(Rest,1,P-1); Resource:=Copy(Rest,P,MaxInt);
  Host:=Authority; if Secure then Port:=443 else Port:=80;
  P:=Pos(':',Authority);
  if P>0 then begin
    Host:=Copy(Authority,1,P-1);
    N:=StrToIntDef(Copy(Authority,P+1,MaxInt),0);
    if (N<1) or (N>65535) then raise Exception.Create('Invalid port');
    Port:=N;
  end;
  if Host='' then raise Exception.Create('Invalid host');
  for I:=1 to Length(Host) do if not (Host[I] in ['a'..'z','A'..'Z','0'..'9','-','.']) then
    raise Exception.Create('Invalid host');
  if not Secure and not (AllowLocal and ((Host='127.0.0.1') or (Host='localhost'))) then
    raise Exception.Create('HTTPS URL required');
  if (Pos(#13,URL)>0) or (Pos(#10,URL)>0) or (Pos('#',URL)>0) or (Pos('?',URL)>0) then
    raise Exception.Create('Invalid API URL');
  WAgent:='AIRemoteSignaling/0.2.0'; WHost:=UTF8Decode(Host);
  WMethod:=UTF8Decode(Method); WResource:=UTF8Decode(Resource);
  Session:=WinHttpOpen(PWideChar(WAgent),0,nil,nil,0);
  if Session=nil then raise Exception.Create('WinHTTP unavailable');
  try
    if not WinHttpSetTimeouts(Session,5000,5000,8000,8000) then raise Exception.Create('Cannot set network timeouts');
    Connection:=WinHttpConnect(Session,PWideChar(WHost),Port,0);
    if Connection=nil then raise Exception.Create('Connection failed');
    try
      Flags:=0; if Secure then Flags:=$00800000;
      Req:=WinHttpOpenRequest(Connection,PWideChar(WMethod),PWideChar(WResource),nil,nil,nil,Flags);
      if Req=nil then raise Exception.Create('Request creation failed');
      try
        Policy:=0; // WINHTTP_OPTION_REDIRECT_POLICY_NEVER. Certificate verification stays enabled.
        if not WinHttpSetOption(Req,88,@Policy,SizeOf(Policy)) then raise Exception.Create('Cannot disable redirects');
        WHeaders:='Accept: application/json'+#13#10+'Content-Type: application/json'+#13#10;
        if Token<>'' then WHeaders:=WHeaders+UTF8Decode('Authorization: Bearer '+Token)+#13#10;
        if Idempotency<>'' then WHeaders:=WHeaders+UTF8Decode('Idempotency-Key: '+Idempotency)+#13#10;
        Data:=nil; if Body<>'' then Data:=PChar(Body);
        if not WinHttpSendRequest(Req,PWideChar(WHeaders),Length(WHeaders),Data,Length(Body),Length(Body),0) then
          raise Exception.Create('HTTPS request failed; verify network and certificate');
        if not WinHttpReceiveResponse(Req,nil) then raise Exception.Create('No API response');
        Size:=SizeOf(Code);
        if not WinHttpQueryHeaders(Req,19 or $20000000,nil,@Code,Size,nil) then raise Exception.Create('Invalid HTTP response');
        Status:=Code; Result:='';
        repeat
          if not WinHttpReadData(Req,@Buffer[0],SizeOf(Buffer),ReadCount) then raise Exception.Create('Response interrupted');
          if Length(Result)+ReadCount>1048576 then raise Exception.Create('API response too large');
          I:=Length(Result); SetLength(Result,I+ReadCount);
          if ReadCount>0 then Move(Buffer[0],Result[I+1],ReadCount);
        until ReadCount=0;
      finally WinHttpCloseHandle(Req); end;
    finally WinHttpCloseHandle(Connection); end;
  finally WinHttpCloseHandle(Session); end;
end;
{$ENDIF}
constructor EAIRemoteAPI.CreateAPI(AStatus:Integer; const ACode,AMessage:string);
begin inherited Create(AMessage); Status:=AStatus; Code:=ACode; end;
function AIRemoteValidKey(const Key:string):Boolean;
var I:Integer;
begin
  Result:=Length(Key)=10;
  if Result then for I:=1 to 10 do if not (Key[I] in ['0'..'9']) then Exit(False);
end;
procedure CheckSessionId(const Id:string);
var I:Integer;
begin
  if Length(Id)<>36 then raise Exception.Create('Invalid session identifier');
  for I:=1 to Length(Id) do if not (Id[I] in ['a'..'f','0'..'9','-']) then
    raise Exception.Create('Invalid session identifier');
end;
function Permissions(Control:Boolean):TJSONArray;
begin
  Result:=TJSONArray.Create; Result.Add('screen.view');
  if Control then begin Result.Add('input.mouse'); Result.Add('input.keyboard'); end;
end;
function TAIRemoteSignalingClient.Request(const Method,Route:string; Body:TJSONObject):TJSONObject;
var Raw,Payload,Key,URL:string; Status:Integer; J,E:TJSONData; I:Integer;
begin
  if FBaseURL='' then raise Exception.Create('API URL not configured');
  if FToken<>'' then begin
    if Length(FToken)<>64 then raise Exception.Create('Invalid device token');
    for I:=1 to Length(FToken) do if not(FToken[I] in ['a'..'f','0'..'9']) then raise Exception.Create('Invalid device token');
  end;
  Payload:=''; if Body<>nil then Payload:=Body.AsJSON;
  Key:=''; if Method<>'GET' then Key:=AIRemoteUUID;
  URL:=ExcludeTrailingPathDelimiter(FBaseURL)+Route;
  {$IFDEF WINDOWS}
  Raw:=HTTP(URL,Method,FToken,Payload,Key,FAllowLocalHTTP,Status);
  {$ELSE}
  raise Exception.Create('HTTPS backend not implemented on this platform');
  {$ENDIF}
  if (Status<200) or (Status>=300) then begin
    J:=nil;
    try
      try
        J:=GetJSON(Raw);
        if J is TJSONObject then begin
          E:=TJSONObject(J).Find('error');
          if E is TJSONObject then
            raise EAIRemoteAPI.CreateAPI(Status,TJSONObject(E).Get('code','API_ERROR'),
              TJSONObject(E).Get('message','API request failed'));
        end;
      finally
        if J<>nil then J.Free;
      end;
    except
      on E: EAIRemoteAPI do raise;
      on Exception do ;
    end;
    raise EAIRemoteAPI.CreateAPI(Status,'HTTP_'+IntToStr(Status),
      'Servidor retornou código HTTP '+IntToStr(Status)+'. Os arquivos da API ainda não estão ativos na pasta.');
  end;
  J:=GetJSON(Raw);
  try
    if not (J is TJSONObject) then raise Exception.Create('Invalid API envelope');
    E:=TJSONObject(J).Find('data');
    if not (E is TJSONObject) then raise Exception.Create('Invalid API data');
    Result:=TJSONObject(E.Clone);
  finally J.Free; end;
end;
function TAIRemoteSignalingClient.RegisterDevice(const RegistrationId,Secret,Name,Platform,Version:string):TJSONObject;
var B:TJSONObject;
begin
  B:=TJSONObject.Create(['registration_id',RegistrationId,'registration_secret',Secret,
    'display_name',Name,'platform',Platform,'app_version',Version]);
  try Result:=Request('POST','/devices',B); finally B.Free; end;
end;
function TAIRemoteSignalingClient.Heartbeat:TJSONObject;
var B:TJSONObject;
begin B:=TJSONObject.Create; try Result:=Request('POST','/devices/heartbeat',B); finally B.Free; end; end;
function TAIRemoteSignalingClient.Incoming:TJSONObject;
begin Result:=Request('GET','/sessions/incoming',nil); end;
function TAIRemoteSignalingClient.RequestSession(const Key:string; Control:Boolean):TJSONObject;
var B:TJSONObject;
begin
  if not AIRemoteValidKey(Key) then raise Exception.Create('Key must contain exactly 10 digits');
  B:=TJSONObject.Create(['target_key',Key]); B.Add('requested_permissions',Permissions(Control));
  try Result:=Request('POST','/sessions',B); finally B.Free; end;
end;
function TAIRemoteSignalingClient.Decide(const Id:string; Accept,Control:Boolean):TJSONObject;
var B:TJSONObject; Decision:string;
begin
  CheckSessionId(Id); if Accept then Decision:='accept' else Decision:='reject';
  B:=TJSONObject.Create(['decision',Decision]);
  if Accept then B.Add('granted_permissions',Permissions(Control));
  try Result:=Request('POST','/sessions/'+Id+'/decision',B); finally B.Free; end;
end;
function TAIRemoteSignalingClient.CloseSession(const Id,Reason:string):TJSONObject;
var B:TJSONObject;
begin
  CheckSessionId(Id); B:=TJSONObject.Create(['reason',Reason]);
  try Result:=Request('POST','/sessions/'+Id+'/close',B); finally B.Free; end;
end;
function TAIRemoteSignalingClient.GetSession(const Id:string):TJSONObject;
begin CheckSessionId(Id); Result:=Request('GET','/sessions/'+Id,nil); end;
function TAIRemoteSignalingClient.Health:TJSONObject;
begin Result:=Request('GET','/health',nil); end;
function TAIRemoteSignalingClient.AnnounceEndpoint(Port:Integer; const Transport,LocalIP:string):TJSONObject;
var B:TJSONObject;
begin
  if LocalIP<>'' then begin
    B:=TJSONObject.Create(['port',Port,'transport',Transport,'local_ip',LocalIP]);
    try
      Result:=Request('POST','/devices/endpoint',B);
      Exit;
    except
    end;
    B.Free;
  end;
  B:=TJSONObject.Create(['port',Port,'transport',Transport]);
  try Result:=Request('POST','/devices/endpoint',B); finally B.Free; end;
end;
function TAIRemoteSignalingClient.GetPeerEndpoint(const Id:string):TJSONObject;
begin CheckSessionId(Id); Result:=Request('GET','/sessions/'+Id+'/peer',nil); end;
function TAIRemoteSignalingClient.SendDiagnosticLog(const Category, Message, LogContent, SessionId, Level: string): TJSONObject;
var B: TJSONObject;
begin
  B := TJSONObject.Create([
    'category', Category,
    'message', Message,
    'log_content', LogContent,
    'app_version', '0.5.0',
    'level', Level
  ]);
  if SessionId <> '' then B.Add('session_id', SessionId);
  try Result := Request('POST', '/diagnostics/logs', B); finally B.Free; end;
end;
end.
