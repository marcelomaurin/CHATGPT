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

  TAIActionCapability = (
    acFileRead,
    acFileWrite,
    acNetwork,
    acEmailSend,
    acIndustrialWrite,
    acProcessExec,
    acStateMutation
  );
  TAIActionCapabilities = set of TAIActionCapability;

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
    FAllowProcessExec: Boolean;
    FAllowAnyDomain: Boolean;
    FSafeBasePath: string;
    FAllowedDomains: TStrings;
    FAllowedPorts: TStrings;
    FAllowedActions: TStrings;
    FOnConfirmAction: TAIConfirmActionEvent;

    procedure SetAllowedDomains(AValue: TStrings);
    procedure SetAllowedPorts(AValue: TStrings);
    procedure SetAllowedActions(AValue: TStrings);
    function IsActionCapabilityAllowed(ACap: TAIActionCapability; out AError: string): Boolean;
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
    property SimulationMode: Boolean read FSimulationMode write FSimulationMode default False;

    property AllowFileWrite: Boolean read FAllowFileWrite write FAllowFileWrite default False;
    property AllowNetwork: Boolean read FAllowNetwork write FAllowNetwork default False;
    property AllowIndustrialWrite: Boolean read FAllowIndustrialWrite write FAllowIndustrialWrite default False;
    property AllowEmailSend: Boolean read FAllowEmailSend write FAllowEmailSend default False;
    property AllowProcessExec: Boolean read FAllowProcessExec write FAllowProcessExec default False;
    property AllowAnyDomain: Boolean read FAllowAnyDomain write FAllowAnyDomain default False;

    property SafeBasePath: string read FSafeBasePath write FSafeBasePath;
    property AllowedDomains: TStrings read FAllowedDomains write SetAllowedDomains;
    property AllowedPorts: TStrings read FAllowedPorts write SetAllowedPorts;
    property AllowedActions: TStrings read FAllowedActions write SetAllowedActions;
    property OnConfirmAction: TAIConfirmActionEvent read FOnConfirmAction write FOnConfirmAction;
  end;

procedure RegisterActionCapability(const AActionName: string; ACaps: TAIActionCapabilities);
function GetActionCapabilities(const AActionName: string; out ACaps: TAIActionCapabilities): Boolean;
procedure Register;

implementation

type
  TAIActionRegItem = record
    Name: string;
    Caps: TAIActionCapabilities;
  end;

var
  GActionRegistry: array of TAIActionRegItem;

procedure RegisterActionCapability(const AActionName: string; ACaps: TAIActionCapabilities);
var
  I, Idx: Integer;
begin
  Idx := -1;
  for I := 0 to High(GActionRegistry) do
  begin
    if CompareText(GActionRegistry[I].Name, AActionName) = 0 then
    begin
      Idx := I;
      Break;
    end;
  end;
  if Idx < 0 then
  begin
    Idx := Length(GActionRegistry);
    SetLength(GActionRegistry, Idx + 1);
    GActionRegistry[Idx].Name := UpperCase(AActionName);
  end;
  GActionRegistry[Idx].Caps := ACaps;
end;

function GetActionCapabilities(const AActionName: string; out ACaps: TAIActionCapabilities): Boolean;
var
  I: Integer;
  UpperName: string;
begin
  Result := False;
  ACaps := [];
  UpperName := UpperCase(AActionName);
  for I := 0 to High(GActionRegistry) do
  begin
    if GActionRegistry[I].Name = UpperName then
    begin
      ACaps := GActionRegistry[I].Caps;
      Result := True;
      Exit;
    end;
  end;
end;

procedure InitDefaultActionRegistry;
begin
  SetLength(GActionRegistry, 0);
  RegisterActionCapability('BROWSER_NAVIGATE', [acNetwork]);
  RegisterActionCapability('BROWSER_READ_PAGE', [acNetwork, acFileRead]);
  RegisterActionCapability('BROWSER_DOM_LIST', [acNetwork]);
  RegisterActionCapability('BROWSER_CAPTURE_TEXT', [acNetwork]);
  RegisterActionCapability('BROWSER_WAIT_SELECTOR', [acNetwork]);
  RegisterActionCapability('BROWSER_FOCUS', [acNetwork]);
  RegisterActionCapability('BROWSER_CLICK', [acNetwork, acStateMutation]);
  RegisterActionCapability('BROWSER_PRESS_ENTER', [acNetwork, acStateMutation]);
  RegisterActionCapability('BROWSER_SET_VALUE', [acNetwork, acStateMutation]);
  RegisterActionCapability('BROWSER_SUBMIT_FORM', [acNetwork, acStateMutation]);
  RegisterActionCapability('BROWSER_SCREENSHOT', [acNetwork, acFileWrite]);
  RegisterActionCapability('CREATE_TEXT_DOCUMENT', [acFileWrite]);
  RegisterActionCapability('READ_WORD_DOCUMENT', [acFileRead]);
  RegisterActionCapability('LIST_PDF_FILES', [acFileRead]);
  RegisterActionCapability('SEND_EMAIL', [acEmailSend, acNetwork]);
  RegisterActionCapability('REGISTER_RESULT', [acStateMutation]);
  RegisterActionCapability('SALVAR_RELATORIO', [acFileWrite]);
  RegisterActionCapability('CHAMAR_API', [acNetwork]);
end;

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
  FSimulationMode := False;
  FAllowFileWrite := False;
  FAllowNetwork := False;
  FAllowIndustrialWrite := False;
  FAllowEmailSend := False;
  FAllowProcessExec := False;
  FAllowAnyDomain := False;
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

function TAIAgentSafety.IsActionCapabilityAllowed(ACap: TAIActionCapability; out AError: string): Boolean;
begin
  Result := True;
  AError := '';
  case ACap of
    acFileRead:
      ; // Read operations are allowed by default unless constrained by path or specific rule
    acFileWrite:
      if not FAllowFileWrite then
      begin
        AError := 'Escrita de arquivos bloqueada (AllowFileWrite = False).';
        Exit(False);
      end;
    acNetwork:
      if not FAllowNetwork then
      begin
        AError := 'Acesso de rede bloqueado (AllowNetwork = False).';
        Exit(False);
      end;
    acEmailSend:
      if not FAllowEmailSend then
      begin
        AError := 'Envio de email bloqueado (AllowEmailSend = False).';
        Exit(False);
      end;
    acIndustrialWrite:
      if not FAllowIndustrialWrite then
      begin
        AError := 'Escrita industrial bloqueada (AllowIndustrialWrite = False).';
        Exit(False);
      end;
    acProcessExec:
      if not FAllowProcessExec then
      begin
        AError := 'Execucao de processos bloqueada (AllowProcessExec = False).';
        Exit(False);
      end;
    acStateMutation:
      if FReadOnlyMode and not FSimulationMode then
      begin
        AError := 'Mutacao de estado bloqueada no modo Somente Leitura (ReadOnlyMode).';
        Exit(False);
      end;
  end;
end;

function TAIAgentSafety.ValidateAction(const AActionName: string; AParams: TStrings; out AError: string): Boolean;
var
  Caps: TAIActionCapabilities;
  Cap: TAIActionCapability;
  I: Integer;
  ParamName, ParamVal, UpperName: string;
  Confirmed: Boolean;
begin
  Result := True;
  AError := '';
  if not FEnabled then Exit;

  if (FAllowedActions.Count > 0) and (FAllowedActions.IndexOf(AActionName) < 0) then
  begin
    AError := 'Acao "' + AActionName + '" nao esta na lista de acoes permitidas.';
    Exit(False);
  end;

  if not GetActionCapabilities(AActionName, Caps) then
  begin
    AError := 'Acao nao registrada no catalogo de seguranca (Fail-Closed): ' + AActionName;
    Exit(False);
  end;

  for Cap in Caps do
  begin
    if not IsActionCapabilityAllowed(Cap, AError) then
      Exit(False);
  end;

  if Assigned(AParams) then
  begin
    for I := 0 to AParams.Count - 1 do
    begin
      ParamName := UpperCase(AParams.Names[I]);
      ParamVal := AParams.ValueFromIndex[I];
      if ParamVal <> '' then
      begin
        if (Pos('FILE', ParamName) > 0) or (Pos('PATH', ParamName) > 0) or
           (Pos('ARQUIVO', ParamName) > 0) or (Pos('CAMINHO', ParamName) > 0) or
           (Pos('PASTA', ParamName) > 0) or (Pos('DESTINO', ParamName) > 0) or
           (Pos('SAIDA', ParamName) > 0) or (Pos('ENTRADA', ParamName) > 0) then
        begin
          if not ValidateFilePath(ParamVal, AError) then
            Exit(False);
        end;

        if (Pos('URL', ParamName) > 0) or (Pos('HOST', ParamName) > 0) or
           (Pos('API', ParamName) > 0) or (Pos('ENDERECO', ParamName) > 0) or
           (Pos('DESTINO', ParamName) > 0) or (Pos('://', ParamVal) > 0) then
        begin
          if not ValidateURL(ParamVal, AError) then
            Exit(False);
        end;
      end;
    end;
  end;

  if FRequireConfirmation then
  begin
    Confirmed := False;
    if Assigned(FOnConfirmAction) then
      FOnConfirmAction(Self, AActionName, AParams, Confirmed);
    if not Confirmed then
    begin
      AError := 'Acao "' + AActionName + '" rejeitada pelo usuario na confirmacao.';
      Exit(False);
    end;
  end;
end;

function TAIAgentSafety.ValidateFilePath(const AFileName: string; out AError: string): Boolean;
var
  NormalizedPath: string;
  SafePath: string;
  FullPath: string;
  I: Integer;
begin
  Result := True;
  AError := '';
  if not FEnabled then Exit;

  NormalizedPath := StringReplace(AFileName, '\', '/', [rfReplaceAll]);
  if (NormalizedPath = '..') or (Copy(NormalizedPath, 1, 3) = '../') or 
     (Pos('/../', NormalizedPath) > 0) or 
     ((Length(NormalizedPath) >= 3) and (Copy(NormalizedPath, Length(NormalizedPath) - 2, 3) = '/..')) then
  begin
    AError := 'Acesso a caminho contendo travessia de diretorio ("..") e negado: ' + AFileName;
    Exit(False);
  end;

  if FSafeBasePath <> '' then
  begin
    SafePath := IncludeTrailingPathDelimiter(ExpandFileName(FSafeBasePath));
    FullPath := ExpandFileName(AFileName);
    if (Length(FullPath) < Length(SafePath)) or
       (not SameFileName(Copy(IncludeTrailingPathDelimiter(FullPath), 1, Length(SafePath)), SafePath)) then
    begin
      AError := 'Acesso ao arquivo "' + AFileName + '" fora do diretorio seguro base ("' + FSafeBasePath + '") e negado.';
      Exit(False);
    end;
  end
  else
  begin
    if (Length(AFileName) > 0) and ((AFileName[1] = '/') or (Pos(':', AFileName) > 1)) then
    begin
      AError := 'Caminho absoluto desabilitado quando SafeBasePath nao esta configurado: ' + AFileName;
      Exit(False);
    end;
  end;
end;

function TAIAgentSafety.ValidateURL(const AURL: string; out AError: string): Boolean;
var
  LDomain: string;
  LPort: string;
  LProtocolPos: Integer;
  LSlashPos, LQuestionPos, LHashPos: Integer;
  LColonPos, LBracketPos: Integer;
  LTemp, LAuthority: string;
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
    LProtocol := LowerCase(Copy(LTemp, 1, LProtocolPos - 1));
    Delete(LTemp, 1, LProtocolPos + 2);
  end;

  if (LProtocol <> 'http') and (LProtocol <> 'https') then
  begin
    AError := 'Esquema de URL nao permitido: ' + LProtocol;
    Exit(False);
  end;

  LQuestionPos := Pos('?', LTemp);
  if LQuestionPos > 0 then LTemp := Copy(LTemp, 1, LQuestionPos - 1);
  LHashPos := Pos('#', LTemp);
  if LHashPos > 0 then LTemp := Copy(LTemp, 1, LHashPos - 1);

  LSlashPos := Pos('/', LTemp);
  if LSlashPos > 0 then
    LAuthority := Copy(LTemp, 1, LSlashPos - 1)
  else
    LAuthority := LTemp;

  if Pos('@', LAuthority) > 0 then
  begin
    AError := 'Credenciais na URL nao sao permitidas.';
    Exit(False);
  end;

  if (Length(LAuthority) > 0) and (LAuthority[1] = '[') then
  begin
    LBracketPos := Pos(']', LAuthority);
    if LBracketPos > 0 then
    begin
      LDomain := Copy(LAuthority, 1, LBracketPos);
      LTemp := Copy(LAuthority, LBracketPos + 1, MaxInt);
      if (Length(LTemp) > 0) and (LTemp[1] = ':') then
        LPort := Copy(LTemp, 2, MaxInt)
      else if LProtocol = 'https' then
        LPort := '443'
      else
        LPort := '80';
    end;
  end
  else
  begin
    LColonPos := Pos(':', LAuthority);
    if LColonPos > 0 then
    begin
      LDomain := Copy(LAuthority, 1, LColonPos - 1);
      LPort := Copy(LAuthority, LColonPos + 1, MaxInt);
    end
    else
    begin
      LDomain := LAuthority;
      if LProtocol = 'https' then
        LPort := '443'
      else
        LPort := '80';
    end;
  end;

  if not FAllowAnyDomain then
  begin
    if FAllowedDomains.Count = 0 then
    begin
      AError := 'Acesso a rede bloqueado (AllowedDomains esta vazia).';
      Exit(False);
    end;

    if FAllowedDomains.IndexOf(LDomain) < 0 then
    begin
      AError := 'Acesso ao dominio "' + LDomain + '" nao e permitido pelas regras de seguranca.';
      Exit(False);
    end;
  end;

  if (FAllowedPorts.Count > 0) and (FAllowedPorts.IndexOf(LPort) < 0) then
  begin
    AError := 'Conexao na porta "' + LPort + '" nao e permitida pelas regras de seguranca.';
    Exit(False);
  end;
end;

initialization
  InitDefaultActionRegistry;
  {$I aiagentsafety_icon.lrs}

end.
