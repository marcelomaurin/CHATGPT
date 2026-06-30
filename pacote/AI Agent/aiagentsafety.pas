unit aiagentsafety;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, LResources;

type
  TAIConfirmActionEvent = procedure(
    Sender: TObject;
    const AActionName: string;
    AParams: TStrings;
    var AConfirmed: Boolean
  ) of object;

  { TAIAgentSafety }

  TAIAgentSafety = class(TComponent)
  private
    FEnabled: Boolean;
    FRequireConfirmation: Boolean;
    FReadOnlyMode: Boolean;
    FSimulationMode: Boolean;
    FAllowFileWrite: Boolean;
    FAllowNetwork: Boolean;
    FAllowIndustrialWrite: Boolean;
    FAllowEmailSend: Boolean;
    FSafeBasePath: string;
    FAllowedDomains: TStrings;
    FAllowedPorts: TStrings;
    FAllowedActions: TStrings;
    FOnConfirmAction: TAIConfirmActionEvent;

    procedure SetAllowedDomains(AValue: TStrings);
    procedure SetAllowedPorts(AValue: TStrings);
    procedure SetAllowedActions(AValue: TStrings);
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    function ValidateAction(const AActionName: string; AParams: TStrings; out AError: string): Boolean;
    function ValidateFilePath(const AFileName: string; out AError: string): Boolean;
    function ValidateURL(const AURL: string; out AError: string): Boolean;
  published
    property Enabled: Boolean read FEnabled write FEnabled default True;
    property RequireConfirmation: Boolean read FRequireConfirmation write FRequireConfirmation default True;
    property ReadOnlyMode: Boolean read FReadOnlyMode write FReadOnlyMode default True;
    property SimulationMode: Boolean read FSimulationMode write FSimulationMode default True;

    property AllowFileWrite: Boolean read FAllowFileWrite write FAllowFileWrite default False;
    property AllowNetwork: Boolean read FAllowNetwork write FAllowNetwork default False;
    property AllowIndustrialWrite: Boolean read FAllowIndustrialWrite write FAllowIndustrialWrite default False;
    property AllowEmailSend: Boolean read FAllowEmailSend write FAllowEmailSend default False;

    property SafeBasePath: string read FSafeBasePath write FSafeBasePath;
    property AllowedDomains: TStrings read FAllowedDomains write SetAllowedDomains;
    property AllowedPorts: TStrings read FAllowedPorts write SetAllowedPorts;
    property AllowedActions: TStrings read FAllowedActions write SetAllowedActions;
    property OnConfirmAction: TAIConfirmActionEvent read FOnConfirmAction write FOnConfirmAction;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('AI Agents', [TAIAgentSafety]);
end;

{ TAIAgentSafety }

constructor TAIAgentSafety.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FEnabled := True;
  FRequireConfirmation := True;
  FReadOnlyMode := True;
  FSimulationMode := True;
  FAllowFileWrite := False;
  FAllowNetwork := False;
  FAllowIndustrialWrite := False;
  FAllowEmailSend := False;
  FSafeBasePath := '';
  FAllowedDomains := TStringList.Create;
  FAllowedPorts := TStringList.Create;
  FAllowedActions := TStringList.Create;
end;

destructor TAIAgentSafety.Destroy;
begin
  FAllowedDomains.Free;
  FAllowedPorts.Free;
  FAllowedActions.Free;
  inherited Destroy;
end;

procedure TAIAgentSafety.SetAllowedDomains(AValue: TStrings);
begin
  FAllowedDomains.Assign(AValue);
end;

procedure TAIAgentSafety.SetAllowedPorts(AValue: TStrings);
begin
  FAllowedPorts.Assign(AValue);
end;

procedure TAIAgentSafety.SetAllowedActions(AValue: TStrings);
begin
  FAllowedActions.Assign(AValue);
end;

function TAIAgentSafety.ValidateAction(const AActionName: string; AParams: TStrings; out AError: string): Boolean;
var
  LActionUpper: string;
  LParamVal: string;
  I: Integer;
  Confirmed: Boolean;
begin
  Result := True;
  AError := '';
  if not FEnabled then Exit;

  LActionUpper := UpperCase(AActionName);

  // Check AllowedActions list if populated
  if (FAllowedActions.Count > 0) and (FAllowedActions.IndexOf(AActionName) < 0) then
  begin
    AError := 'Ação "' + AActionName + '" não está na lista de ações permitidas.';
    Exit(False);
  end;

  // File Write Check
  if (Pos('FILE', LActionUpper) > 0) or (Pos('SAVE', LActionUpper) > 0) or 
     (Pos('WRITE', LActionUpper) > 0) or (Pos('PDF', LActionUpper) > 0) or 
     (Pos('WORD', LActionUpper) > 0) or (Pos('EXCEL', LActionUpper) > 0) or 
     (Pos('TXT', LActionUpper) > 0) or (Pos('DOCS', LActionUpper) > 0) then
  begin
    if not FAllowFileWrite then
    begin
      AError := 'Escrita de arquivos bloqueada pelas regras de segurança (AllowFileWrite = False).';
      Exit(False);
    end;
  end;

  // Email / Messenger Send Check
  if (Pos('EMAIL', LActionUpper) > 0) or (Pos('MAIL', LActionUpper) > 0) or 
     (Pos('WHATSAPP', LActionUpper) > 0) or (Pos('SMS', LActionUpper) > 0) or 
     (Pos('MESSENGER', LActionUpper) > 0) then
  begin
    if not FAllowEmailSend then
    begin
      AError := 'Envio de mensagens/e-mails bloqueado pelas regras de segurança (AllowEmailSend = False).';
      Exit(False);
    end;
  end;

  // Industrial Write Check
  if (Pos('MODBUS', LActionUpper) > 0) or (Pos('CLP', LActionUpper) > 0) or 
     (Pos('INDUSTRIAL', LActionUpper) > 0) then
  begin
    if not FAllowIndustrialWrite then
    begin
      AError := 'Escrita industrial (CLP/Modbus) bloqueada pelas regras de segurança (AllowIndustrialWrite = False).';
      Exit(False);
    end;
  end;

  // Network Access Check
  if (Pos('MQTT', LActionUpper) > 0) or (Pos('SOCKET', LActionUpper) > 0) or 
     (Pos('TCP', LActionUpper) > 0) or (Pos('UDP', LActionUpper) > 0) or 
     (Pos('WEBAPI', LActionUpper) > 0) or (Pos('URL', LActionUpper) > 0) or
     (Pos('HTTP', LActionUpper) > 0) then
  begin
    if not FAllowNetwork then
    begin
      AError := 'Acesso de rede bloqueado pelas regras de segurança (AllowNetwork = False).';
      Exit(False);
    end;
  end;

  // ReadOnlyMode Check
  if FReadOnlyMode and not FSimulationMode then
  begin
    if (Pos('WRITE', LActionUpper) > 0) or (Pos('SAVE', LActionUpper) > 0) or 
       (Pos('SEND', LActionUpper) > 0) or (Pos('PUBLISH', LActionUpper) > 0) or 
       (Pos('POST', LActionUpper) > 0) or (Pos('DELETE', LActionUpper) > 0) or
       (Pos('MODBUS', LActionUpper) > 0) then
    begin
      AError := 'Operações de escrita/modificação bloqueadas no modo Somente Leitura (ReadOnlyMode).';
      Exit(False);
    end;
  end;

  // Validate parameters (filenames, URLs)
  if Assigned(AParams) then
  begin
    for I := 0 to AParams.Count - 1 do
    begin
      LParamVal := AParams.ValueFromIndex[I];
      if LParamVal <> '' then
      begin
        // Validate File Path if parameter looks like a path/filename
        if (Pos('FILE', UpperCase(AParams.Names[I])) > 0) or 
           (Pos('PATH', UpperCase(AParams.Names[I])) > 0) then
        begin
          if not ValidateFilePath(LParamVal, AError) then
            Exit(False);
        end;
        // Validate URL if parameter looks like URL/APIUrl/Host
        if (Pos('URL', UpperCase(AParams.Names[I])) > 0) or 
           (Pos('HOST', UpperCase(AParams.Names[I])) > 0) or
           (Pos('API', UpperCase(AParams.Names[I])) > 0) then
        begin
          if not ValidateURL(LParamVal, AError) then
            Exit(False);
        end;
      end;
    end;
  end;

  // Require Confirmation Check
  if FRequireConfirmation then
  begin
    Confirmed := False;
    if Assigned(FOnConfirmAction) then
      FOnConfirmAction(Self, AActionName, AParams, Confirmed);
    if not Confirmed then
    begin
      AError := 'Ação "' + AActionName + '" rejeitada pelo usuário na confirmação.';
      Exit(False);
    end;
  end;
end;

function TAIAgentSafety.ValidateFilePath(const AFileName: string; out AError: string): Boolean;
var
  FullPath: string;
  SafePath: string;
begin
  Result := True;
  AError := '';
  if not FEnabled then Exit;

  // Prevent directory traversal
  if Pos('..', AFileName) > 0 then
  begin
    AError := 'Acesso a caminho contendo travessia de diretório ("..") é negado.';
    Exit(False);
  end;

  if FSafeBasePath <> '' then
  begin
    SafePath := IncludeTrailingPathDelimiter(ExpandFileName(FSafeBasePath));
    FullPath := ExpandFileName(AFileName);
    if Pos(SafePath, FullPath) <> 1 then
    begin
      AError := 'Acesso ao arquivo "' + AFileName + '" fora do diretório seguro base ("' + FSafeBasePath + '") é negado.';
      Exit(False);
    end;
  end;
end;

function TAIAgentSafety.ValidateURL(const AURL: string; out AError: string): Boolean;
var
  LDomain: string;
  LPort: string;
  LProtocolPos: Integer;
  LSlashPos: Integer;
  LColonPos: Integer;
  LTemp: string;
  LProtocol: string;
begin
  Result := True;
  AError := '';
  if not FEnabled then Exit;

  LTemp := AURL;
  LProtocol := 'http';
  LProtocolPos := Pos('://', LTemp);
  if LProtocolPos > 0 then
  begin
    LProtocol := Copy(LTemp, 1, LProtocolPos - 1);
    Delete(LTemp, 1, LProtocolPos + 2);
  end;

  LSlashPos := Pos('/', LTemp);
  if LSlashPos > 0 then
    LTemp := Copy(LTemp, 1, LSlashPos - 1);

  LColonPos := Pos(':', LTemp);
  if LColonPos > 0 then
  begin
    LDomain := Copy(LTemp, 1, LColonPos - 1);
    LPort := Copy(LTemp, LColonPos + 1, MaxInt);
  end
  else
  begin
    LDomain := LTemp;
    if SameText(LProtocol, 'https') then
      LPort := '443'
    else
      LPort := '80';
  end;

  // Check AllowedDomains list
  if (FAllowedDomains.Count > 0) and (FAllowedDomains.IndexOf(LDomain) < 0) then
  begin
    AError := 'Acesso ao domínio "' + LDomain + '" não é permitido pelas regras de segurança.';
    Exit(False);
  end;

  // Check AllowedPorts list
  if (FAllowedPorts.Count > 0) and (FAllowedPorts.IndexOf(LPort) < 0) then
  begin
    AError := 'Conexão na porta "' + LPort + '" não é permitida pelas regras de segurança.';
    Exit(False);
  end;
end;

initialization
  {$I taiagentsafety_icon.lrs}

  {$I aiagentsafety_icon.lrs}

end.
