unit aicommonserviceagents;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, StrUtils, fphttpclient, opensslsockets, DB, SQLDB,
  LResources, aibase, aiprocessrunner, aiemail;

type
  TAIServiceAgent = class(TAIBaseComponent)
  private
    FAccessToken: string;
    FBaseURL: string;
    FAllowRead: Boolean;
    FAllowWrite: Boolean;
    FTimeoutMs: Integer;
    FLastStatusCode: Integer;
  protected
    function EnsureRead: Boolean;
    function EnsureWrite: Boolean;
    function Request(const AMethod, AURL, ABody, AContentType,
      AHeaderName, AHeaderValue: string): Boolean;
    function JoinURL(const APath: string): string;
    function URLEncode(const S: string): string;
    function JSONEscape(const S: string): string;
  public
    constructor Create(AOwner: TComponent); override;
    property LastStatusCode: Integer read FLastStatusCode;
  published
    property AccessToken: string read FAccessToken write FAccessToken;
    property BaseURL: string read FBaseURL write FBaseURL;
    property AllowRead: Boolean read FAllowRead write FAllowRead default True;
    property AllowWrite: Boolean read FAllowWrite write FAllowWrite default False;
    property TimeoutMs: Integer read FTimeoutMs write FTimeoutMs default 30000;
  end;

  TAIGitLabAgent = class(TAIServiceAgent)
  private
    FProjectID: string;
  public
    constructor Create(AOwner: TComponent); override;
    function GetProject: Boolean;
    function ListIssues: Boolean;
    function CreateIssue(const ATitle, ADescription: string): Boolean;
    function ListPipelines: Boolean;
  published
    property ProjectID: string read FProjectID write FProjectID;
  end;

  TAITelegramAgent = class(TAIServiceAgent)
  private
    FBotToken: string;
    FChatID: string;
    function BotURL(const AMethod: string): string;
  public
    constructor Create(AOwner: TComponent); override;
    function GetMe: Boolean;
    function GetUpdates(AOffset: Int64 = 0): Boolean;
    function SendMessage(const AText: string): Boolean;
  published
    property BotToken: string read FBotToken write FBotToken;
    property ChatID: string read FChatID write FChatID;
  end;

  TAIEmailAgent = class(TAIServiceAgent)
  private
    FClient: TAIEmailClient;
    FHostSMTP: string;
    FPortSMTP: Integer;
    FHostPOP3: string;
    FPortPOP3: Integer;
    FUsername: string;
    FPassword: string;
    procedure ApplySettings;
  public
    constructor Create(AOwner: TComponent); override;
    function SendEmail(const ATo, ASubject, ABody: string): Boolean;
    function FetchEmails: Boolean;
  published
    property HostSMTP: string read FHostSMTP write FHostSMTP;
    property PortSMTP: Integer read FPortSMTP write FPortSMTP default 25;
    property HostPOP3: string read FHostPOP3 write FHostPOP3;
    property PortPOP3: Integer read FPortPOP3 write FPortPOP3 default 110;
    property Username: string read FUsername write FUsername;
    property Password: string read FPassword write FPassword;
  end;

  TAIRSSAgent = class(TAIServiceAgent)
  private
    FFeedURL: string;
    function ExtractTitles(const AXML: string): string;
  public
    constructor Create(AOwner: TComponent); override;
    function Fetch: Boolean;
    function FetchTitles: Boolean;
  published
    property FeedURL: string read FFeedURL write FFeedURL;
  end;

  TAIWebAgent = class(TAIServiceAgent)
  public
    constructor Create(AOwner: TComponent); override;
    function Get(const AURL: string): Boolean;
    function PostJSON(const AURL, AJSON: string): Boolean;
    function DownloadFile(const AURL, AFileName: string): Boolean;
  end;

  TAISSHAgent = class(TAIServiceAgent)
  private
    FRunner: TAIProcessRunner;
    FSSHPath: string;
    FHost: string;
    FUserName: string;
    FPort: Integer;
    FIdentityFile: string;
    function GetStdOutText: string;
    function GetStdErrText: string;
    function GetExitCode: Integer;
  public
    constructor Create(AOwner: TComponent); override;
    function ExecuteCommand(const ACommand: string): Boolean;
    procedure Stop;
    property StdOutText: string read GetStdOutText;
    property StdErrText: string read GetStdErrText;
    property ExitCode: Integer read GetExitCode;
  published
    property SSHPath: string read FSSHPath write FSSHPath;
    property Host: string read FHost write FHost;
    property UserName: string read FUserName write FUserName;
    property Port: Integer read FPort write FPort default 22;
    property IdentityFile: string read FIdentityFile write FIdentityFile;
  end;

  TAIDatabaseAgent = class(TAIServiceAgent)
  private
    FConnection: TSQLConnection;
    procedure SetConnection(AValue: TSQLConnection);
    function IsReadOnlySQL(const ASQL: string): Boolean;
  protected
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
  public
    function ExecuteReadOnly(const ASQL: string): Boolean;
    function ExecuteNonQuery(const ASQL: string): Boolean;
  published
    property Connection: TSQLConnection read FConnection write SetConnection;
  end;

  TAIWhatsAppAgent = class(TAIServiceAgent)
  private
    FAPIVersion: string;
    FPhoneNumberID: string;
    function MessagesURL: string;
  public
    constructor Create(AOwner: TComponent); override;
    function GetPhoneNumberInfo: Boolean;
    function SendText(const AToPhone, AText: string): Boolean;
    function MarkAsRead(const AMessageID: string): Boolean;
  published
    property APIVersion: string read FAPIVersion write FAPIVersion;
    property PhoneNumberID: string read FPhoneNumberID write FPhoneNumberID;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('AI Services', [TAIGitLabAgent, TAITelegramAgent,
    TAIEmailAgent, TAIRSSAgent, TAIWebAgent, TAISSHAgent,
    TAIDatabaseAgent, TAIWhatsAppAgent]);
end;

{ TAIServiceAgent }

constructor TAIServiceAgent.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FCategory := ccAction;
  FAllowRead := True;
  FAllowWrite := False;
  FTimeoutMs := 30000;
  FLastStatusCode := 0;
end;

function TAIServiceAgent.EnsureRead: Boolean;
begin
  Result := FAllowRead;
  if not Result then SetError('AllowRead=False. Leitura bloqueada.');
end;

function TAIServiceAgent.EnsureWrite: Boolean;
begin
  Result := FAllowWrite;
  if not Result then SetError('AllowWrite=False. Escrita bloqueada.');
end;

function TAIServiceAgent.JoinURL(const APath: string): string;
begin
  if APath = '' then Exit(FBaseURL);
  if AnsiEndsStr('/', FBaseURL) and AnsiStartsStr('/', APath) then
    Result := FBaseURL + Copy(APath, 2, MaxInt)
  else if (not AnsiEndsStr('/', FBaseURL)) and (not AnsiStartsStr('/', APath)) then
    Result := FBaseURL + '/' + APath
  else
    Result := FBaseURL + APath;
end;

function TAIServiceAgent.URLEncode(const S: string): string;
const
  Hex: array[0..15] of Char = '0123456789ABCDEF';
var
  I: Integer;
  C: Byte;
begin
  Result := '';
  for I := 1 to Length(S) do
  begin
    C := Ord(S[I]);
    if ((C >= Ord('a')) and (C <= Ord('z'))) or
       ((C >= Ord('A')) and (C <= Ord('Z'))) or
       ((C >= Ord('0')) and (C <= Ord('9'))) or (S[I] in ['-', '_', '.', '~']) then
      Result := Result + S[I]
    else
      Result := Result + '%' + Hex[C shr 4] + Hex[C and $0F];
  end;
end;

function TAIServiceAgent.JSONEscape(const S: string): string;
var
  I: Integer;
begin
  Result := '';
  for I := 1 to Length(S) do
    case S[I] of
      '"': Result := Result + '\"';
      '\': Result := Result + '\\';
      #8: Result := Result + '\b';
      #9: Result := Result + '\t';
      #10: Result := Result + '\n';
      #12: Result := Result + '\f';
      #13: Result := Result + '\r';
    else
      Result := Result + S[I];
    end;
end;

function TAIServiceAgent.Request(const AMethod, AURL, ABody, AContentType,
  AHeaderName, AHeaderValue: string): Boolean;
var
  Client: TFPHTTPClient;
  RequestStream, ResponseStream: TStringStream;
  URL: string;
begin
  ClearError;
  Result := False;
  FLastStatusCode := 0;
  URL := AURL;
  if URL = '' then
  begin
    SetError('URL nao configurada.');
    Exit;
  end;
  Client := TFPHTTPClient.Create(nil);
  RequestStream := nil;
  ResponseStream := TStringStream.Create('');
  try
    Client.ConnectTimeout := FTimeoutMs;
    Client.IOTimeout := FTimeoutMs;
    Client.AllowRedirect := True;
    if AContentType <> '' then Client.AddHeader('Content-Type', AContentType);
    Client.AddHeader('Accept', 'application/json, application/xml, text/xml, text/plain, */*');
    if (AHeaderName <> '') and (AHeaderValue <> '') then
      Client.AddHeader(AHeaderName, AHeaderValue);
    if ABody <> '' then
    begin
      RequestStream := TStringStream.Create(ABody);
      Client.RequestBody := RequestStream;
    end;
    try
      Client.HTTPMethod(UpperCase(AMethod), URL, ResponseStream, [200, 201, 202, 204]);
      FLastStatusCode := Client.ResponseStatusCode;
      FLastResult := ResponseStream.DataString;
      FLastSuccess := True;
      Result := True;
    except
      on E: Exception do
      begin
        FLastStatusCode := Client.ResponseStatusCode;
        FLastResult := ResponseStream.DataString;
        SetError(E.Message);
      end;
    end;
  finally
    RequestStream.Free;
    ResponseStream.Free;
    Client.Free;
  end;
end;

{ TAIGitLabAgent }

constructor TAIGitLabAgent.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  BaseURL := 'https://gitlab.com/api/v4';
end;

function TAIGitLabAgent.GetProject: Boolean;
begin
  if not EnsureRead then Exit(False);
  Result := Request('GET', JoinURL('/projects/' + URLEncode(FProjectID)), '', '',
    'PRIVATE-TOKEN', AccessToken);
end;

function TAIGitLabAgent.ListIssues: Boolean;
begin
  if not EnsureRead then Exit(False);
  Result := Request('GET', JoinURL('/projects/' + URLEncode(FProjectID) + '/issues'), '', '',
    'PRIVATE-TOKEN', AccessToken);
end;

function TAIGitLabAgent.CreateIssue(const ATitle, ADescription: string): Boolean;
var
  Body: string;
begin
  if not EnsureWrite then Exit(False);
  Body := '{"title":"' + JSONEscape(ATitle) + '","description":"' +
    JSONEscape(ADescription) + '"}';
  Result := Request('POST', JoinURL('/projects/' + URLEncode(FProjectID) + '/issues'),
    Body, 'application/json', 'PRIVATE-TOKEN', AccessToken);
end;

function TAIGitLabAgent.ListPipelines: Boolean;
begin
  if not EnsureRead then Exit(False);
  Result := Request('GET', JoinURL('/projects/' + URLEncode(FProjectID) + '/pipelines'), '', '',
    'PRIVATE-TOKEN', AccessToken);
end;

{ TAITelegramAgent }

constructor TAITelegramAgent.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  BaseURL := 'https://api.telegram.org';
end;

function TAITelegramAgent.BotURL(const AMethod: string): string;
begin
  Result := JoinURL('/bot' + FBotToken + '/' + AMethod);
end;

function TAITelegramAgent.GetMe: Boolean;
begin
  if not EnsureRead then Exit(False);
  Result := Request('GET', BotURL('getMe'), '', '', '', '');
end;

function TAITelegramAgent.GetUpdates(AOffset: Int64): Boolean;
var
  URL: string;
begin
  if not EnsureRead then Exit(False);
  URL := BotURL('getUpdates');
  if AOffset <> 0 then URL := URL + '?offset=' + IntToStr(AOffset);
  Result := Request('GET', URL, '', '', '', '');
end;

function TAITelegramAgent.SendMessage(const AText: string): Boolean;
var
  Body: string;
begin
  if not EnsureWrite then Exit(False);
  Body := '{"chat_id":"' + JSONEscape(FChatID) + '","text":"' + JSONEscape(AText) + '"}';
  Result := Request('POST', BotURL('sendMessage'), Body, 'application/json', '', '');
end;

{ TAIEmailAgent }

constructor TAIEmailAgent.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FPortSMTP := 25;
  FPortPOP3 := 110;
  FClient := TAIEmailClient.Create(Self);
end;

procedure TAIEmailAgent.ApplySettings;
begin
  FClient.HostSMTP := FHostSMTP;
  FClient.PortSMTP := FPortSMTP;
  FClient.HostPOP3 := FHostPOP3;
  FClient.PortPOP3 := FPortPOP3;
  FClient.Username := FUsername;
  FClient.Password := FPassword;
end;

function TAIEmailAgent.SendEmail(const ATo, ASubject, ABody: string): Boolean;
begin
  ClearError;
  if not EnsureWrite then Exit(False);
  ApplySettings;
  Result := FClient.SendEmail(ATo, ASubject, ABody);
  FLastSuccess := Result;
  if Result then FLastResult := 'E-mail enviado para ' + ATo
  else SetError('Falha ao enviar e-mail.');
end;

function TAIEmailAgent.FetchEmails: Boolean;
var
  Emails: TStrings;
begin
  ClearError;
  if not EnsureRead then Exit(False);
  ApplySettings;
  Emails := nil;
  Result := FClient.FetchEmails(Emails);
  try
    if Result and Assigned(Emails) then
    begin
      FLastResult := Emails.Text;
      FLastSuccess := True;
    end
    else if not Result then
      SetError('Falha ao buscar e-mails.');
  finally
    Emails.Free;
  end;
end;

{ TAIRSSAgent }

constructor TAIRSSAgent.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
end;

function TAIRSSAgent.Fetch: Boolean;
begin
  if not EnsureRead then Exit(False);
  Result := Request('GET', FFeedURL, '', '', '', '');
end;

function TAIRSSAgent.ExtractTitles(const AXML: string): string;
var
  P, P1, P2: SizeInt;
  S, Segment, Title: string;
begin
  Result := '';
  S := AXML;
  P := 1;
  while P <= Length(S) do
  begin
    P1 := PosEx('<item', S, P);
    if P1 = 0 then Break;
    P1 := PosEx('>', S, P1);
    if P1 = 0 then Break;
    P2 := PosEx('</item>', S, P1 + 1);
    if P2 = 0 then Break;
    Segment := Copy(S, P1 + 1, P2 - P1 - 1);
    P1 := Pos('<title>', Segment);
    if P1 > 0 then
    begin
      P1 := P1 + Length('<title>');
      P2 := PosEx('</title>', Segment, P1);
      if P2 > 0 then
      begin
        Title := Trim(Copy(Segment, P1, P2 - P1));
        Result := Result + Title + LineEnding;
      end;
    end;
    P := P2 + Length('</item>');
  end;
  if Result = '' then
  begin
    P := 1;
    while P <= Length(S) do
    begin
      P1 := PosEx('<entry', S, P);
      if P1 = 0 then Break;
      P1 := PosEx('>', S, P1);
      if P1 = 0 then Break;
      P2 := PosEx('</entry>', S, P1 + 1);
      if P2 = 0 then Break;
      Segment := Copy(S, P1 + 1, P2 - P1 - 1);
      P1 := Pos('<title', Segment);
      if P1 > 0 then
      begin
        P1 := PosEx('>', Segment, P1) + 1;
        if P1 > 1 then
        begin
          P2 := PosEx('</title>', Segment, P1);
          if P2 > 0 then
            Result := Result + Trim(Copy(Segment, P1, P2 - P1)) + LineEnding;
        end;
      end;
      P := P2 + Length('</entry>');
    end;
  end;
end;

function TAIRSSAgent.FetchTitles: Boolean;
var
  XML: string;
begin
  Result := Fetch;
  if not Result then Exit;
  XML := FLastResult;
  FLastResult := ExtractTitles(XML);
  Result := Trim(FLastResult) <> '';
  FLastSuccess := Result;
  if not Result then SetError('Nenhum titulo RSS/Atom encontrado.');
end;

{ TAIWebAgent }

constructor TAIWebAgent.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
end;

function TAIWebAgent.Get(const AURL: string): Boolean;
begin
  if not EnsureRead then Exit(False);
  Result := Request('GET', AURL, '', '', '', '');
end;

function TAIWebAgent.PostJSON(const AURL, AJSON: string): Boolean;
begin
  if not EnsureWrite then Exit(False);
  Result := Request('POST', AURL, AJSON, 'application/json', '', '');
end;

function TAIWebAgent.DownloadFile(const AURL, AFileName: string): Boolean;
var
  Client: TFPHTTPClient;
  Stream: TFileStream;
begin
  ClearError;
  if not EnsureRead then Exit(False);
  if not EnsureWrite then Exit(False);
  Result := False;
  Client := TFPHTTPClient.Create(nil);
  Stream := nil;
  try
    Client.ConnectTimeout := TimeoutMs;
    Client.IOTimeout := TimeoutMs;
    Stream := TFileStream.Create(AFileName, fmCreate);
    try
      Client.Get(AURL, Stream);
      FLastResult := ExpandFileName(AFileName);
      FLastSuccess := True;
      Result := True;
    except
      on E: Exception do SetError(E.Message);
    end;
  finally
    Stream.Free;
    Client.Free;
  end;
end;

{ TAISSHAgent }

constructor TAISSHAgent.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FSSHPath := 'ssh';
  FPort := 22;
  FRunner := TAIProcessRunner.Create(Self);
end;

function TAISSHAgent.GetStdOutText: string;
begin
  Result := FRunner.StdOutText;
end;

function TAISSHAgent.GetStdErrText: string;
begin
  Result := FRunner.StdErrText;
end;

function TAISSHAgent.GetExitCode: Integer;
begin
  Result := FRunner.LastExitCode;
end;

function TAISSHAgent.ExecuteCommand(const ACommand: string): Boolean;
var
  Params: array of string;
  Target: string;
  N: Integer;
begin
  ClearError;
  if not EnsureWrite then Exit(False);
  if Trim(FHost) = '' then
  begin
    SetError('Host nao configurado.');
    Exit(False);
  end;
  Target := FHost;
  if Trim(FUserName) <> '' then Target := FUserName + '@' + FHost;
  SetLength(Params, 0);
  N := 0;
  SetLength(Params, N + 2); Params[N] := '-o'; Params[N + 1] := 'BatchMode=yes'; Inc(N, 2);
  SetLength(Params, N + 2); Params[N] := '-p'; Params[N + 1] := IntToStr(FPort); Inc(N, 2);
  if Trim(FIdentityFile) <> '' then
  begin
    SetLength(Params, N + 2); Params[N] := '-i'; Params[N + 1] := FIdentityFile; Inc(N, 2);
  end;
  SetLength(Params, N + 2); Params[N] := Target; Params[N + 1] := ACommand;
  FRunner.Executable := FSSHPath;
  FRunner.TimeoutMs := TimeoutMs;
  Result := FRunner.Execute(Params);
  FLastSuccess := Result;
  FLastResult := FRunner.StdOutText;
  if not Result then SetError(FRunner.LastError);
end;

procedure TAISSHAgent.Stop;
begin
  FRunner.Stop;
end;

{ TAIDatabaseAgent }

procedure TAIDatabaseAgent.SetConnection(AValue: TSQLConnection);
begin
  if FConnection = AValue then Exit;
  if Assigned(FConnection) then FConnection.RemoveFreeNotification(Self);
  FConnection := AValue;
  if Assigned(FConnection) then FConnection.FreeNotification(Self);
end;

procedure TAIDatabaseAgent.Notification(AComponent: TComponent; Operation: TOperation);
begin
  inherited Notification(AComponent, Operation);
  if (Operation = opRemove) and (AComponent = FConnection) then FConnection := nil;
end;

function TAIDatabaseAgent.IsReadOnlySQL(const ASQL: string): Boolean;
var
  S: string;
begin
  S := UpperCase(Trim(ASQL));
  Result := AnsiStartsStr('SELECT', S) or AnsiStartsStr('WITH', S) or
    AnsiStartsStr('EXPLAIN', S) or AnsiStartsStr('SHOW', S);
end;

function TAIDatabaseAgent.ExecuteReadOnly(const ASQL: string): Boolean;
var
  Q: TSQLQuery;
  I: Integer;
  Row: string;
begin
  ClearError;
  if not EnsureRead then Exit(False);
  if not IsReadOnlySQL(ASQL) then
  begin
    SetError('SQL nao permitido em ExecuteReadOnly.');
    Exit(False);
  end;
  if FConnection = nil then
  begin
    SetError('Connection nao configurada.');
    Exit(False);
  end;
  Q := TSQLQuery.Create(nil);
  try
    Q.DataBase := FConnection;
    Q.SQL.Text := ASQL;
    try
      Q.Open;
      FLastResult := '';
      while not Q.EOF do
      begin
        Row := '';
        for I := 0 to Q.Fields.Count - 1 do
        begin
          if I > 0 then Row := Row + #9;
          Row := Row + Q.Fields[I].FieldName + '=' + Q.Fields[I].AsString;
        end;
        FLastResult := FLastResult + Row + LineEnding;
        Q.Next;
      end;
      FLastSuccess := True;
      Result := True;
    except
      on E: Exception do begin SetError(E.Message); Result := False; end;
    end;
  finally
    Q.Free;
  end;
end;

function TAIDatabaseAgent.ExecuteNonQuery(const ASQL: string): Boolean;
var
  Q: TSQLQuery;
  T: TSQLTransaction;
  OwnTransaction: Boolean;
begin
  ClearError;
  if not EnsureWrite then Exit(False);
  if FConnection = nil then
  begin
    SetError('Connection nao configurada.');
    Exit(False);
  end;
  Q := TSQLQuery.Create(nil);
  T := nil;
  OwnTransaction := FConnection.Transaction = nil;
  try
    if OwnTransaction then
    begin
      T := TSQLTransaction.Create(nil);
      T.DataBase := FConnection;
      FConnection.Transaction := T;
    end;
    Q.DataBase := FConnection;
    Q.Transaction := FConnection.Transaction;
    Q.SQL.Text := ASQL;
    try
      if not FConnection.Transaction.Active then FConnection.Transaction.StartTransaction;
      Q.ExecSQL;
      FConnection.Transaction.Commit;
      FLastResult := 'SQL executado. RowsAffected=' + IntToStr(Q.RowsAffected);
      FLastSuccess := True;
      Result := True;
    except
      on E: Exception do
      begin
        if Assigned(FConnection.Transaction) and FConnection.Transaction.Active then
          FConnection.Transaction.Rollback;
        SetError(E.Message);
        Result := False;
      end;
    end;
  finally
    Q.Free;
    if OwnTransaction then
    begin
      FConnection.Transaction := nil;
      T.Free;
    end;
  end;
end;

{ TAIWhatsAppAgent }

constructor TAIWhatsAppAgent.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  BaseURL := 'https://graph.facebook.com';
  FAPIVersion := 'v23.0';
end;

function TAIWhatsAppAgent.MessagesURL: string;
begin
  Result := JoinURL('/' + FAPIVersion + '/' + FPhoneNumberID + '/messages');
end;

function TAIWhatsAppAgent.GetPhoneNumberInfo: Boolean;
begin
  if not EnsureRead then Exit(False);
  Result := Request('GET', JoinURL('/' + FAPIVersion + '/' + FPhoneNumberID), '', '',
    'Authorization', 'Bearer ' + AccessToken);
end;

function TAIWhatsAppAgent.SendText(const AToPhone, AText: string): Boolean;
var
  Body: string;
begin
  if not EnsureWrite then Exit(False);
  Body := '{"messaging_product":"whatsapp","recipient_type":"individual",' +
    '"to":"' + JSONEscape(AToPhone) + '","type":"text","text":{"preview_url":false,' +
    '"body":"' + JSONEscape(AText) + '"}}';
  Result := Request('POST', MessagesURL, Body, 'application/json',
    'Authorization', 'Bearer ' + AccessToken);
end;

function TAIWhatsAppAgent.MarkAsRead(const AMessageID: string): Boolean;
var
  Body: string;
begin
  if not EnsureWrite then Exit(False);
  Body := '{"messaging_product":"whatsapp","status":"read","message_id":"' +
    JSONEscape(AMessageID) + '"}';
  Result := Request('POST', MessagesURL, Body, 'application/json',
    'Authorization', 'Bearer ' + AccessToken);
end;

end.
