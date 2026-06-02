unit aiemail;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, sockets,
  {$IFDEF WIN32}
  winsock2,
  {$ELSE}
    {$IFDEF WIN64}
    winsock2,
    {$ELSE}
    netdb,
    {$ENDIF}
  {$ENDIF}
  Math;

type
  { TAIEmailClient }

  TAIEmailClient = class(TComponent)
  private
    FHostSMTP: string;
    FPortSMTP: Integer;
    FHostPOP3: string;
    FPortPOP3: Integer;
    FUsername: string;
    FPassword: string;
    
    function ExecuteSMTPCommand(Sock: TSocket; const ACmd: string; const AExpectedCode: string): Boolean;
    function ReadPOP3Response(Sock: TSocket; out AResponse: string): Boolean;
    function ResolveHost(const AHost: string; var AAddr): Boolean;
  public
    constructor Create(AOwner: TComponent); override;
    
    function SendEmail(const ATo, ASubject, ABody: string): Boolean;
    function FetchEmails(out AEmails: TStrings): Boolean;
  published
    property HostSMTP: string read FHostSMTP write FHostSMTP;
    property PortSMTP: Integer read FPortSMTP write FPortSMTP default 25;
    property HostPOP3: string read FHostPOP3 write FHostPOP3;
    property PortPOP3: Integer read FPortPOP3 write FPortPOP3 default 110;
    property Username: string read FUsername write FUsername;
    property Password: string read FPassword write FPassword;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('IA Input', [TAIEmailClient]);
end;

{ TAIEmailClient }

constructor TAIEmailClient.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FHostSMTP := 'localhost';
  FPortSMTP := 25;
  FHostPOP3 := 'localhost';
  FPortPOP3 := 110;
  FUsername := '';
  FPassword := '';
end;

function TAIEmailClient.ResolveHost(const AHost: string; var AAddr): Boolean;
var
  AddrVal: Cardinal;
  {$IFDEF WIN32}
  HostEnt: PHostEnt;
  {$ELSE}
    {$IFDEF WIN64}
    HostEnt: PHostEnt;
    {$ELSE}
    HostEnt: THostEntry;
    {$ENDIF}
  {$ENDIF}
begin
  Result := False;
  AddrVal := 0;
  Move(StrToNetAddr(AHost), AddrVal, 4);
  if AddrVal <> 0 then
  begin
    Move(AddrVal, AAddr, 4);
    Exit(True);
  end;
    
  {$IFDEF WIN32}
  HostEnt := gethostbyname(PChar(AHost));
  if HostEnt <> nil then
  begin
    Move(HostEnt^.h_addr_list^^, AAddr, 4);
    Result := True;
  end;
  {$ELSE}
    {$IFDEF WIN64}
    HostEnt := gethostbyname(PChar(AHost));
    if HostEnt <> nil then
    begin
      Move(HostEnt^.h_addr_list^^, AAddr, 4);
      Result := True;
    end;
    {$ELSE}
    if netdb.ResolveHostByName(AHost, HostEnt) then
    begin
      Move(HostEnt.Addr, AAddr, SizeOf(TInAddr));
      Result := True;
    end;
    {$ENDIF}
  {$ENDIF}
end;

function TAIEmailClient.ExecuteSMTPCommand(Sock: TSocket; const ACmd: string; const AExpectedCode: string): Boolean;
var
  Buffer: array[0..1023] of Char;
  BytesReceived: Integer;
  Response: string;
begin
  Result := False;
  if ACmd <> '' then
  begin
    if fpsend(Sock, Pointer(ACmd), Length(ACmd), 0) <= 0 then
      Exit;
  end;
  
  FillChar(Buffer, SizeOf(Buffer), 0);
  BytesReceived := fprecv(Sock, @Buffer[0], SizeOf(Buffer) - 1, 0);
  if BytesReceived <= 0 then
    Exit;
    
  Response := StrPas(Buffer);
  Result := (Pos(AExpectedCode, Response) = 1) or (Pos(AExpectedCode, Response) > 0);
end;

function TAIEmailClient.ReadPOP3Response(Sock: TSocket; out AResponse: string): Boolean;
var
  Buffer: array[0..1023] of Char;
  BytesReceived: Integer;
begin
  Result := False;
  AResponse := '';
  FillChar(Buffer, SizeOf(Buffer), 0);
  BytesReceived := fprecv(Sock, @Buffer[0], SizeOf(Buffer) - 1, 0);
  if BytesReceived <= 0 then
    Exit;
    
  AResponse := StrPas(Buffer);
  Result := (Pos('+OK', AResponse) = 1);
end;

function TAIEmailClient.SendEmail(const ATo, ASubject, ABody: string): Boolean;
var
  Sock: TSocket;
  Addr: TInetSockAddr;
  Msg: string;
begin
  Result := False;
  
  Sock := fpSocket(AF_INET, SOCK_STREAM, 0);
  if Sock = TSocket(-1) then
    Exit;
    
  Addr.sin_family := AF_INET;
  Addr.sin_port := htons(FPortSMTP);
  
  if not ResolveHost(FHostSMTP, Addr.sin_addr) then
  begin
    sockets.CloseSocket(Sock);
    Exit;
  end;
  
  if fpConnect(Sock, @Addr, SizeOf(Addr)) < 0 then
  begin
    sockets.CloseSocket(Sock);
    Exit;
  end;
  
  try
    // Initial welcome response
    if not ExecuteSMTPCommand(Sock, '', '220') then Exit;
    
    // HELO/EHLO
    if not ExecuteSMTPCommand(Sock, 'EHLO AI_Client'#13#10, '250') then
    begin
      // Fallback to HELO
      if not ExecuteSMTPCommand(Sock, 'HELO AI_Client'#13#10, '250') then Exit;
    end;
    
    // MAIL FROM
    Msg := 'MAIL FROM:<' + FUsername + '>'#13#10;
    if not ExecuteSMTPCommand(Sock, Msg, '250') then Exit;
    
    // RCPT TO
    Msg := 'RCPT TO:<' + ATo + '>'#13#10;
    if not ExecuteSMTPCommand(Sock, Msg, '250') then Exit;
    
    // DATA
    if not ExecuteSMTPCommand(Sock, 'DATA'#13#10, '354') then Exit;
    
    // Send email raw content
    Msg := 'From: ' + FUsername + #13#10 +
           'To: ' + ATo + #13#10 +
           'Subject: ' + ASubject + #13#10 +
           'Content-Type: text/plain; charset=UTF-8' + #13#10 +
           #13#10 +
           ABody + #13#10 +
           '.'#13#10;
    if not ExecuteSMTPCommand(Sock, Msg, '250') then Exit;
    
    // QUIT
    ExecuteSMTPCommand(Sock, 'QUIT'#13#10, '221');
    Result := True;
  finally
    sockets.CloseSocket(Sock);
  end;
end;

function TAIEmailClient.FetchEmails(out AEmails: TStrings): Boolean;
var
  Sock: TSocket;
  Addr: TInetSockAddr;
  Response: string;
  Cmd: string;
  EmailCount: Integer;
  I: Integer;
  SubjectPos, HeaderEndPos: Integer;
  EmailBody: string;
begin
  Result := False;
  AEmails := TStringList.Create;
  
  Sock := fpSocket(AF_INET, SOCK_STREAM, 0);
  if Sock = TSocket(-1) then
    Exit;
    
  Addr.sin_family := AF_INET;
  Addr.sin_port := htons(FPortPOP3);
  
  if not ResolveHost(FHostPOP3, Addr.sin_addr) then
  begin
    sockets.CloseSocket(Sock);
    Exit;
  end;
  
  if fpConnect(Sock, @Addr, SizeOf(Addr)) < 0 then
  begin
    sockets.CloseSocket(Sock);
    Exit;
  end;
  
  try
    // Greeting
    if not ReadPOP3Response(Sock, Response) then Exit;
    
    // USER
    Cmd := 'USER ' + FUsername + #13#10;
    if fpsend(Sock, Pointer(Cmd), Length(Cmd), 0) <= 0 then Exit;
    if not ReadPOP3Response(Sock, Response) then Exit;
    
    // PASS
    Cmd := 'PASS ' + FPassword + #13#10;
    if fpsend(Sock, Pointer(Cmd), Length(Cmd), 0) <= 0 then Exit;
    if not ReadPOP3Response(Sock, Response) then Exit;
    
    // STAT
    Cmd := 'STAT'#13#10;
    if fpsend(Sock, Pointer(Cmd), Length(Cmd), 0) <= 0 then Exit;
    if not ReadPOP3Response(Sock, Response) then Exit;
    
    // Parse count of emails
    EmailCount := 0;
    if Length(Response) > 4 then
      EmailCount := StrToIntDef(Copy(Response, 5, Pos(' ', Response, 5) - 5), 0);
      
    if EmailCount > 5 then
      EmailCount := 5;
      
    for I := 1 to EmailCount do
    begin
      Cmd := 'RETR ' + IntToStr(I) + #13#10;
      if fpsend(Sock, Pointer(Cmd), Length(Cmd), 0) <= 0 then Break;
      if ReadPOP3Response(Sock, EmailBody) then
      begin
        // Simple extraction of subject header
        SubjectPos := Pos('Subject:', EmailBody);
        if SubjectPos > 0 then
        begin
          HeaderEndPos := Pos(#13#10, EmailBody, SubjectPos);
          if HeaderEndPos > 0 then
            AEmails.Add('Email ' + IntToStr(I) + ': ' + Copy(EmailBody, SubjectPos, HeaderEndPos - SubjectPos))
          else
            AEmails.Add('Email ' + IntToStr(I) + ': Header subject found');
        end
        else
          AEmails.Add('Email ' + IntToStr(I) + ': (No Subject)');
      end;
    end;
    
    // QUIT
    Cmd := 'QUIT'#13#10;
    fpsend(Sock, Pointer(Cmd), Length(Cmd), 0);
    Result := True;
  finally
    sockets.CloseSocket(Sock);
  end;
end;

end.
