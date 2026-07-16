unit aiagentserial;

{$mode objfpc}{$H+}

{ If Serial.OnRXReceive is already assigned, the owner must forward received
  data to AppendRX. Otherwise TAIAgentSerial installs its internal handler. }

interface

uses
  Classes, SysUtils, fpjson, jsonparser, aibase, chatgpt, aiserial,
  ailistserialdevices, aiagent, LResources;

type
  TAgentActionKind = (aakNone, aakSetPort, aakSetBaud, aakConnect,
    aakDisconnect, aakSend, aakRead, aakListPorts, aakStatus);

  TAgentActionEvent = procedure(Sender: TObject; AKind: TAgentActionKind;
    const AParam: string; var AAllow: Boolean) of object;
  TAgentLogEvent = procedure(Sender: TObject; const AMessage: string) of object;

  TAISerialCommandDiscoveryState = (
    scdsIdle,
    scdsWaitingBegin,
    scdsReadingManual,
    scdsCompleted,
    scdsFailed
  );

  TAISerialCommandsEvent = procedure(Sender: TObject;
    ACommands: TStrings) of object;
  TAISerialCommandRejectedEvent = procedure(Sender: TObject;
    const ACommand: string; const AReason: string) of object;

  { TAIAgentSerial }

  TAIAgentSerial = class(TAIBaseComponent)
  private
    FSerial: TAISerialModem;
    FLLM: TCHATGPT;
    FSystemPrompt: string;
    FRequireConfirmation: Boolean;
    FMaxActionsPerPrompt: Integer;
    FOwnsSerialRXHandler: Boolean;
    FRXBuffer: TStringList;
    FCommandCatalog: TAIAgentAction;
    FAutoDiscoverCommands: Boolean;
    FDiscoveryCommand: string;
    FManualBeginMarker: string;
    FManualEndMarker: string;
    FCommandLinePrefix: string;
    FAllowUnknownDeviceCommands: Boolean;
    FClearCatalogOnDisconnect: Boolean;
    FDiscoveryState: TAISerialCommandDiscoveryState;
    FCommandsKnown: Boolean;
    FLastManual: TStringList;
    FRXLineBuffer: string;
    FOnBeforeAction: TAgentActionEvent;
    FOnAgentLog: TAgentLogEvent;
    FOnCommandsDiscovered: TAISerialCommandsEvent;
    FOnCommandRejected: TAISerialCommandRejectedEvent;
    FOnDiscoveryError: TAgentLogEvent;
    procedure SetSerial(AValue: TAISerialModem);
    procedure SetLLM(AValue: TCHATGPT);
    procedure SetCommandCatalog(AValue: TAIAgentAction);
    procedure SetMaxActionsPerPrompt(AValue: Integer);
    procedure SerialRX(Sender: TObject; const AData: string);
    procedure AgentLog(const AMessage: string);
    procedure DiscoveryError(const AMessage: string);
    procedure ProcessRXChunk(const AData: string);
    procedure ProcessRXLine(const ALine: string);
    procedure ParseManualCommandLine(const ALine: string);
    procedure FinishCommandDiscovery;
    function ExtractCommandName(const ACommandText: string): string;
    function GetLastManual: TStrings;
    function BuildPrompt(const AUserPrompt: string): string;
    function ExtractJSONObject(const AText: string): string;
    function ParseResponse(const AText: string; out ARoot: TJSONObject): Boolean;
    function ActionKindFromName(const AName: string): TAgentActionKind;
    function ActionName(AKind: TAgentActionKind): string;
    function RXContext: string;
  protected
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
    function SerialIsActive: Boolean; virtual;
    function SerialOpenPort: Boolean; virtual;
    procedure SerialClosePort; virtual;
    function SerialWriteText(const AText: string): Boolean; virtual;
    procedure SerialPoll; virtual;
    function SerialErrorText: string; virtual;
    function ExecuteAction(AKind: TAgentActionKind;
      const AParam: string): string; reintroduce;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    function Execute(const AUserPrompt: string): string;
    procedure AppendRX(const AData: string);
    procedure StartCommandDiscovery;
    procedure ClearCommandCatalog;
    function IsDeviceCommandAllowed(const ACommand: string): Boolean;
    function DeviceCommandsPrompt: string;
  published
    property Serial: TAISerialModem read FSerial write SetSerial;
    property LLM: TCHATGPT read FLLM write SetLLM;
    property CommandCatalog: TAIAgentAction read FCommandCatalog
      write SetCommandCatalog;
    property SystemPrompt: string read FSystemPrompt write FSystemPrompt;
    property RequireConfirmation: Boolean read FRequireConfirmation write FRequireConfirmation default True;
    property MaxActionsPerPrompt: Integer read FMaxActionsPerPrompt write SetMaxActionsPerPrompt default 5;
    property AutoDiscoverCommands: Boolean read FAutoDiscoverCommands
      write FAutoDiscoverCommands default True;
    property DiscoveryCommand: string read FDiscoveryCommand
      write FDiscoveryCommand;
    property ManualBeginMarker: string read FManualBeginMarker
      write FManualBeginMarker;
    property ManualEndMarker: string read FManualEndMarker
      write FManualEndMarker;
    property CommandLinePrefix: string read FCommandLinePrefix
      write FCommandLinePrefix;
    property AllowUnknownDeviceCommands: Boolean
      read FAllowUnknownDeviceCommands write FAllowUnknownDeviceCommands
      default False;
    property ClearCatalogOnDisconnect: Boolean
      read FClearCatalogOnDisconnect write FClearCatalogOnDisconnect
      default True;
    property CommandsKnown: Boolean read FCommandsKnown;
    property DiscoveryState: TAISerialCommandDiscoveryState
      read FDiscoveryState;
    property LastManual: TStrings read GetLastManual;
    property OnBeforeAction: TAgentActionEvent read FOnBeforeAction write FOnBeforeAction;
    property OnAgentLog: TAgentLogEvent read FOnAgentLog write FOnAgentLog;
    property OnCommandsDiscovered: TAISerialCommandsEvent
      read FOnCommandsDiscovered write FOnCommandsDiscovered;
    property OnCommandRejected: TAISerialCommandRejectedEvent
      read FOnCommandRejected write FOnCommandRejected;
    property OnDiscoveryError: TAgentLogEvent
      read FOnDiscoveryError write FOnDiscoveryError;
  end;

procedure Register;

const
  AGENT_PROTOCOL_PROMPT =
    'Voce e um agente que controla uma porta serial. Responda SOMENTE com JSON valido, sem markdown.' + LineEnding +
    'Formato: {"actions":[{"action":"<nome>","param":"<valor>"}],"reply":"<texto para o usuario>"}' + LineEnding +
    'Acoes disponiveis:' + LineEnding +
    ' - list_ports (param vazio): lista portas seriais disponiveis' + LineEnding +
    ' - set_port (param: nome da porta, ex COM3 ou /dev/ttyUSB0)' + LineEnding +
    ' - set_baud (param: numero, ex 9600 ou 115200)' + LineEnding +
    ' - connect (param vazio): abre a porta' + LineEnding +
    ' - disconnect (param vazio): fecha a porta' + LineEnding +
    ' - send (param: comando ou texto; comandos descobertos recebem fim de linha automaticamente)' + LineEnding +
    ' - read (param vazio): retorna dados recebidos acumulados' + LineEnding +
    ' - status (param vazio): retorna porta, baud e estado da conexao' + LineEnding +
    'Se nenhuma acao for necessaria, use "actions":[] e apenas "reply".';

implementation

procedure Register;
begin
  RegisterComponents('AI Agent', [TAIAgentSerial]);
end;

constructor TAIAgentSerial.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FPrompt := 'Agent that connects TCHATGPT to TAISerialModem using confirmed JSON actions, serial polling and RX context.';
  FSystemPrompt := '';
  FRequireConfirmation := True;
  FMaxActionsPerPrompt := 5;
  FOwnsSerialRXHandler := False;
  FRXBuffer := TStringList.Create;
  FCommandCatalog := nil;
  FAutoDiscoverCommands := True;
  FDiscoveryCommand := 'MAN';
  FManualBeginMarker := 'MAN-BEGIN';
  FManualEndMarker := 'MAN-END';
  FCommandLinePrefix := 'COMMAND ';
  FAllowUnknownDeviceCommands := False;
  FClearCatalogOnDisconnect := True;
  FDiscoveryState := scdsIdle;
  FCommandsKnown := False;
  FLastManual := TStringList.Create;
  FRXLineBuffer := '';
  FCategory := ccAction;
end;

destructor TAIAgentSerial.Destroy;
begin
  if (FSerial <> nil) and FOwnsSerialRXHandler then
    FSerial.OnRXReceive := nil;
  FLastManual.Free;
  FRXBuffer.Free;
  inherited Destroy;
end;

procedure TAIAgentSerial.SetSerial(AValue: TAISerialModem);
begin
  if FSerial = AValue then Exit;
  if FSerial <> nil then
  begin
    if FOwnsSerialRXHandler then
      FSerial.OnRXReceive := nil;
    FOwnsSerialRXHandler := False;
    FSerial.RemoveFreeNotification(Self);
  end;
  FSerial := AValue;
  if FSerial <> nil then
  begin
    FSerial.FreeNotification(Self);
    if not Assigned(FSerial.OnRXReceive) then
    begin
      FSerial.OnRXReceive := @SerialRX;
      FOwnsSerialRXHandler := True;
    end;
  end;
end;

procedure TAIAgentSerial.SetLLM(AValue: TCHATGPT);
begin
  if FLLM = AValue then Exit;
  if FLLM <> nil then FLLM.RemoveFreeNotification(Self);
  FLLM := AValue;
  if FLLM <> nil then FLLM.FreeNotification(Self);
end;

procedure TAIAgentSerial.SetCommandCatalog(AValue: TAIAgentAction);
begin
  if FCommandCatalog = AValue then Exit;
  if FCommandCatalog <> nil then
    FCommandCatalog.RemoveFreeNotification(Self);
  FCommandCatalog := AValue;
  if FCommandCatalog <> nil then
  begin
    FCommandCatalog.FreeNotification(Self);
    FCommandsKnown := FCommandCatalog.AllowedActions.Count > 0;
  end
  else
    FCommandsKnown := False;
end;

procedure TAIAgentSerial.SetMaxActionsPerPrompt(AValue: Integer);
begin
  if AValue < 1 then AValue := 1;
  FMaxActionsPerPrompt := AValue;
end;

procedure TAIAgentSerial.Notification(AComponent: TComponent; Operation: TOperation);
begin
  inherited Notification(AComponent, Operation);
  if Operation = opRemove then
  begin
    if AComponent = FSerial then
    begin
      FSerial := nil;
      FOwnsSerialRXHandler := False;
    end;
    if AComponent = FLLM then FLLM := nil;
    if AComponent = FCommandCatalog then
    begin
      FCommandCatalog := nil;
      FCommandsKnown := False;
    end;
  end;
end;

procedure TAIAgentSerial.SerialRX(Sender: TObject; const AData: string);
begin
  AppendRX(AData);
end;

procedure TAIAgentSerial.AppendRX(const AData: string);
begin
  FRXBuffer.Add(FormatDateTime('yyyy-mm-dd hh:nn:ss.zzz', Now) + ' ' + AData);
  while FRXBuffer.Count > 200 do FRXBuffer.Delete(0);
  ProcessRXChunk(AData);
end;

procedure TAIAgentSerial.AgentLog(const AMessage: string);
begin
  if Assigned(FOnAgentLog) then FOnAgentLog(Self, AMessage);
end;

procedure TAIAgentSerial.DiscoveryError(const AMessage: string);
begin
  FDiscoveryState := scdsFailed;
  FCommandsKnown := False;
  AgentLog('[discovery] error=' + AMessage);
  if Assigned(FOnDiscoveryError) then
    FOnDiscoveryError(Self, AMessage);
end;

function TAIAgentSerial.GetLastManual: TStrings;
begin
  Result := FLastManual;
end;

procedure TAIAgentSerial.ProcessRXChunk(const AData: string);
var
  LFPos: SizeInt;
  Line: string;
begin
  FRXLineBuffer := FRXLineBuffer + AData;
  repeat
    LFPos := Pos(#10, FRXLineBuffer);
    if LFPos = 0 then Break;
    Line := Copy(FRXLineBuffer, 1, LFPos - 1);
    Delete(FRXLineBuffer, 1, LFPos);
    if (Line <> '') and (Line[Length(Line)] = #13) then
      Delete(Line, Length(Line), 1);
    ProcessRXLine(Line);
  until False;
end;

procedure TAIAgentSerial.ProcessRXLine(const ALine: string);
var
  Line: string;
begin
  Line := Trim(ALine);

  { Accept an unsolicited manual as well. This makes the parser deterministic
    and testable even when the device sends MAN in response to an external
    terminal or after reconnecting. }
  if (FDiscoveryState in [scdsIdle, scdsCompleted, scdsFailed]) and
    SameText(Line, Trim(FManualBeginMarker)) then
  begin
    if FCommandCatalog <> nil then
    begin
      FCommandCatalog.AllowedActions.Clear;
      FCommandCatalog.ParameterDefinitions.Clear;
    end;
    FCommandsKnown := False;
    FLastManual.Clear;
    FDiscoveryState := scdsReadingManual;
    FLastManual.Add(Line);
    Exit;
  end;

  case FDiscoveryState of
    scdsWaitingBegin:
      if SameText(Line, Trim(FManualBeginMarker)) then
      begin
        FDiscoveryState := scdsReadingManual;
        FLastManual.Clear;
        FLastManual.Add(Line);
        AgentLog('[discovery] manual begin received');
      end;

    scdsReadingManual:
      begin
        FLastManual.Add(Line);
        if SameText(Line, Trim(FManualEndMarker)) then
          FinishCommandDiscovery
        else if (Length(Line) >= Length(FCommandLinePrefix)) and
          SameText(Copy(Line, 1, Length(FCommandLinePrefix)),
            FCommandLinePrefix) then
          ParseManualCommandLine(Line);
      end;
  end;
end;

procedure TAIAgentSerial.ParseManualCommandLine(const ALine: string);
var
  CommandText, CommandName, Description, Definition: string;
  ColonPos, I: Integer;
begin
  if FCommandCatalog = nil then Exit;
  if not SameText(Copy(ALine, 1, Length(FCommandLinePrefix)),
    FCommandLinePrefix) then Exit;

  CommandText := Trim(Copy(ALine, Length(FCommandLinePrefix) + 1,
    MaxInt));
  ColonPos := Pos(':', CommandText);
  if ColonPos <= 1 then Exit;

  CommandName := Trim(Copy(CommandText, 1, ColonPos - 1));
  Description := Trim(Copy(CommandText, ColonPos + 1, MaxInt));
  if CommandName = '' then Exit;

  for I := 0 to FCommandCatalog.AllowedActions.Count - 1 do
    if SameText(FCommandCatalog.AllowedActions[I], CommandName) then Exit;

  FCommandCatalog.AllowedActions.Add(CommandName);
  Definition := CommandName + ':';
  if Description <> '' then Definition := Definition + ' ' + Description;
  FCommandCatalog.ParameterDefinitions.Add(Definition);
end;

procedure TAIAgentSerial.FinishCommandDiscovery;
var
  Count: Integer;
begin
  if FCommandCatalog <> nil then
    Count := FCommandCatalog.AllowedActions.Count
  else
    Count := 0;

  FCommandsKnown := Count > 0;
  if not FCommandsKnown then
  begin
    DiscoveryError('manual ended without valid COMMAND lines');
    Exit;
  end;

  FDiscoveryState := scdsCompleted;
  AgentLog(Format('[discovery] completed commands=%d', [Count]));
  if Assigned(FOnCommandsDiscovered) then
    FOnCommandsDiscovered(Self, FCommandCatalog.AllowedActions);
end;

function TAIAgentSerial.ExtractCommandName(
  const ACommandText: string): string;
var
  S: string;
  I: Integer;
begin
  S := Trim(ACommandText);
  I := 1;
  while (I <= Length(S)) and not (S[I] in [' ', #9, #10, #13]) do
    Inc(I);
  Result := UpperCase(Copy(S, 1, I - 1));
end;

procedure TAIAgentSerial.StartCommandDiscovery;
var
  Data: string;
begin
  if FDiscoveryState in [scdsWaitingBegin, scdsReadingManual] then Exit;
  if FSerial = nil then
  begin
    DiscoveryError('Serial is not assigned');
    Exit;
  end;
  if not SerialIsActive then
  begin
    DiscoveryError('serial port is not connected');
    Exit;
  end;
  if FCommandCatalog = nil then
  begin
    DiscoveryError('CommandCatalog is not assigned');
    Exit;
  end;

  ClearCommandCatalog;
  FDiscoveryState := scdsWaitingBegin;
  Data := FDiscoveryCommand + LineEnding;
  if not SerialWriteText(Data) then
  begin
    DiscoveryError('failed to send discovery command: ' + SerialErrorText);
    Exit;
  end;
  AgentLog('[discovery] command sent: ' + FDiscoveryCommand);
end;

procedure TAIAgentSerial.ClearCommandCatalog;
begin
  if FCommandCatalog <> nil then
  begin
    FCommandCatalog.AllowedActions.Clear;
    FCommandCatalog.ParameterDefinitions.Clear;
  end;
  FCommandsKnown := False;
  FDiscoveryState := scdsIdle;
  FLastManual.Clear;
  FRXLineBuffer := '';
end;

function TAIAgentSerial.IsDeviceCommandAllowed(
  const ACommand: string): Boolean;
var
  CommandName, DiscoveryName: string;
  I: Integer;
begin
  CommandName := ExtractCommandName(ACommand);
  DiscoveryName := ExtractCommandName(FDiscoveryCommand);
  if (CommandName <> '') and SameText(CommandName, DiscoveryName) then
    Exit(True);
  if FAllowUnknownDeviceCommands then Exit(True);
  if (FCommandCatalog = nil) or not FCommandsKnown then Exit(False);
  for I := 0 to FCommandCatalog.AllowedActions.Count - 1 do
    if SameText(FCommandCatalog.AllowedActions[I], CommandName) then
      Exit(True);
  Result := False;
end;

function TAIAgentSerial.DeviceCommandsPrompt: string;
var
  I: Integer;
begin
  Result := '=== COMANDOS DESCOBERTOS NO EQUIPAMENTO ===' + LineEnding;
  if (FCommandCatalog = nil) or
    (FCommandCatalog.AllowedActions.Count = 0) then
  begin
    Result := Result + LineEnding +
      'Os comandos do equipamento ainda nao foram descobertos.' + LineEnding +
      'Use a acao send com o comando ' + FDiscoveryCommand +
      ' e depois leia a resposta.' + LineEnding +
      'Nao invente comandos.' + LineEnding;
    Exit;
  end;

  Result := Result + LineEnding;
  if FCommandCatalog.ParameterDefinitions.Count > 0 then
    for I := 0 to FCommandCatalog.ParameterDefinitions.Count - 1 do
      Result := Result + '- ' +
        FCommandCatalog.ParameterDefinitions[I] + LineEnding
  else
    for I := 0 to FCommandCatalog.AllowedActions.Count - 1 do
      Result := Result + '- ' + FCommandCatalog.AllowedActions[I] +
        LineEnding;
  Result := Result + 'Use somente os comandos listados.' + LineEnding +
    'Nao invente comandos que nao estejam no catalogo.' + LineEnding;
end;

function TAIAgentSerial.SerialIsActive: Boolean;
begin
  Result := (FSerial <> nil) and FSerial.Active;
end;

function TAIAgentSerial.SerialOpenPort: Boolean;
begin
  Result := (FSerial <> nil) and FSerial.OpenPort;
end;

procedure TAIAgentSerial.SerialClosePort;
begin
  if FSerial <> nil then FSerial.ClosePort;
end;

function TAIAgentSerial.SerialWriteText(const AText: string): Boolean;
begin
  Result := (FSerial <> nil) and FSerial.WriteText(AText);
end;

procedure TAIAgentSerial.SerialPoll;
begin
  if FSerial <> nil then FSerial.Poll;
end;

function TAIAgentSerial.SerialErrorText: string;
begin
  if FSerial <> nil then Result := FSerial.LastError else Result := 'Serial is not assigned';
end;

function TAIAgentSerial.RXContext: string;
var
  I: Integer;
begin
  Result := '';
  for I := FRXBuffer.Count - 1 downto 0 do
  begin
    if Length(FRXBuffer[I]) + Length(Result) + Length(LineEnding) > 2048 then Break;
    Result := FRXBuffer[I] + LineEnding + Result;
  end;
end;

function TAIAgentSerial.BuildPrompt(const AUserPrompt: string): string;
var
  State: string;
begin
  if FSerial.Active then State := 'S' else State := 'N';
  Result := AGENT_PROTOCOL_PROMPT + LineEnding + LineEnding;
  if FSystemPrompt <> '' then Result := Result + FSystemPrompt + LineEnding;
  Result := Result + Format('ESTADO: porta=%s baud=%d conectado=%s',
    [FSerial.DeviceName, FSerial.BaudRate, State]) + LineEnding + LineEnding +
    DeviceCommandsPrompt + LineEnding +
    'RX RECENTE:' + LineEnding + RXContext +
    'PROMPT DO USUARIO:' + LineEnding + AUserPrompt;
end;

function TAIAgentSerial.ExtractJSONObject(const AText: string): string;
var
  I, StartPos, Depth: Integer;
  InString, Escaped: Boolean;
begin
  Result := '';
  StartPos := 0; Depth := 0; InString := False; Escaped := False;
  for I := 1 to Length(AText) do
  begin
    if InString then
    begin
      if Escaped then Escaped := False
      else if AText[I] = '\' then Escaped := True
      else if AText[I] = '"' then InString := False;
      Continue;
    end;
    if AText[I] = '"' then InString := True
    else if AText[I] = '{' then
    begin
      if Depth = 0 then StartPos := I;
      Inc(Depth);
    end
    else if (AText[I] = '}') and (Depth > 0) then
    begin
      Dec(Depth);
      if (Depth = 0) and (StartPos > 0) then Exit(Copy(AText, StartPos, I - StartPos + 1));
    end;
  end;
end;

function TAIAgentSerial.ParseResponse(const AText: string; out ARoot: TJSONObject): Boolean;
var
  Data: TJSONData;
  S: string;
begin
  Result := False; ARoot := nil; S := AText;
  try
    try
      Data := GetJSON(S);
    except
      S := ExtractJSONObject(AText);
      if S = '' then Exit;
      Data := GetJSON(S);
    end;
    if Data.JSONType <> jtObject then begin Data.Free; Exit; end;
    ARoot := TJSONObject(Data); Result := True;
  except
    Result := False;
  end;
end;

function TAIAgentSerial.ActionKindFromName(const AName: string): TAgentActionKind;
begin
  if SameText(AName, 'set_port') then Result := aakSetPort
  else if SameText(AName, 'set_baud') then Result := aakSetBaud
  else if SameText(AName, 'connect') then Result := aakConnect
  else if SameText(AName, 'disconnect') then Result := aakDisconnect
  else if SameText(AName, 'send') then Result := aakSend
  else if SameText(AName, 'read') then Result := aakRead
  else if SameText(AName, 'list_ports') then Result := aakListPorts
  else if SameText(AName, 'status') then Result := aakStatus
  else Result := aakNone;
end;

function TAIAgentSerial.ActionName(AKind: TAgentActionKind): string;
const Names: array[TAgentActionKind] of string = ('none','set_port','set_baud',
  'connect','disconnect','send','read','list_ports','status');
begin Result := Names[AKind]; end;

function TAIAgentSerial.ExecuteAction(AKind: TAgentActionKind; const AParam: string): string;
var
  Allow: Boolean;
  Baud: Integer;
  Data, CommandName, Reason: string;
  KnownCommand: Boolean;
  I: Integer;
  Lister: TAIListSerialDevices;
  Names: TStringList;
begin
  Data := '';
  if AKind = aakSend then
  begin
    Data := StringReplace(AParam, '\n', #10, [rfReplaceAll]);
    Data := StringReplace(Data, '\r', #13, [rfReplaceAll]);
    CommandName := ExtractCommandName(Data);
    KnownCommand := SameText(CommandName,
      ExtractCommandName(FDiscoveryCommand));
    if not KnownCommand and (FCommandCatalog <> nil) then
      for I := 0 to FCommandCatalog.AllowedActions.Count - 1 do
        if SameText(FCommandCatalog.AllowedActions[I], CommandName) then
        begin
          KnownCommand := True;
          Break;
        end;

    if not KnownCommand then
    begin
      Reason := 'device command not present in discovered command catalog';
      if FAllowUnknownDeviceCommands then
        AgentLog('[agent] warning=unknown device command allowed command=' +
          CommandName)
      else
      begin
        if Assigned(FOnCommandRejected) then
          FOnCommandRejected(Self, CommandName, Reason);
        AgentLog('[agent] rejected command=' + CommandName +
          ' reason=' + Reason);
        Exit('error: ' + Reason);
      end;
    end;

    { Commands discovered through MAN are line-oriented.  Always terminate a
      known device command so that firmware parsers do not leave it waiting in
      their input buffer when the LLM supplies only the documented syntax. }
    if KnownCommand and (Data <> '') and
      not (Data[Length(Data)] in [#10, #13]) then
      Data := Data + LineEnding;
  end;

  Allow := not FRequireConfirmation;
  if FRequireConfirmation then
  begin
    Allow := False;
    if Assigned(FOnBeforeAction) then FOnBeforeAction(Self, AKind, AParam, Allow);
  end;
  if not Allow then Exit('action denied by user');

  case AKind of
    aakListPorts:
      begin
        Lister := TAIListSerialDevices.Create(nil); Names := TStringList.Create;
        try Lister.ProbeOpenable := False; Lister.Refresh; Lister.GetDeviceNames(Names);
          Result := StringReplace(Trim(Names.Text), LineEnding, ', ', [rfReplaceAll]);
          if Result = '' then Result := '(no ports)';
        finally Names.Free; Lister.Free; end;
      end;
    aakSetPort:
      if FSerial.Active then Result := 'error: disconnect before changing port'
      else begin FSerial.DeviceName := AParam; Result := 'port set to ' + AParam; end;
    aakSetBaud:
      begin
        Baud := StrToIntDef(Trim(AParam), 0);
        if Baud <= 0 then Result := 'error: invalid baud'
        else if FSerial.Active then Result := 'error: disconnect before changing baud'
        else begin FSerial.BaudRate := Baud; Result := 'baud set to ' + IntToStr(Baud); end;
      end;
    aakConnect:
      if SerialOpenPort then
      begin
        Result := 'connected';
        if FAutoDiscoverCommands then StartCommandDiscovery;
      end
      else Result := 'error: ' + SerialErrorText;
    aakDisconnect:
      begin
        SerialClosePort;
        if FClearCatalogOnDisconnect then ClearCommandCatalog;
        Result := 'disconnected';
      end;
    aakSend:
      begin
        if SerialWriteText(Data) then Result := 'sent ' + IntToStr(Length(Data)) + ' bytes'
        else Result := 'error: ' + SerialErrorText;
      end;
    aakRead:
      begin SerialPoll; Result := Trim(FRXBuffer.Text);
        if Result = '' then Result := '(no data)'; FRXBuffer.Clear; end;
    aakStatus:
      begin Result := Format('%s @%d, ', [FSerial.DeviceName, FSerial.BaudRate]);
        if FSerial.Active then Result := Result + 'connected' else Result := Result + 'disconnected'; end;
    else Result := 'error: unknown action';
  end;
end;

function TAIAgentSerial.Execute(const AUserPrompt: string): string;
var
  Raw, Reply, Results, Param, ActionText: string;
  Root, FeedbackRoot: TJSONObject;
  Actions: TJSONArray;
  Obj: TJSONObject;
  I, Limit: Integer;
  Kind: TAgentActionKind;
  ActionResult: string;
begin
  Result := '';
  ClearError;
  if FSerial = nil then Exit('agent error: Serial is not assigned');
  if FLLM = nil then Exit('agent error: LLM is not assigned');
  try
    if not FLLM.SendQuestion(BuildPrompt(AUserPrompt)) then
      raise Exception.Create('LLM error: ' + FLLM.LastError);
    Raw := UTF8Encode(FLLM.Response);
    if not ParseResponse(Raw, Root) then
    begin AgentLog('[agent] warning=invalid JSON response'); Exit(Raw); end;
    try
      Reply := Root.Get('reply', ''); Results := '';
      Actions := Root.Arrays['actions'];
      if Actions <> nil then
      begin
        Limit := Actions.Count; if Limit > FMaxActionsPerPrompt then Limit := FMaxActionsPerPrompt;
        for I := 0 to Limit - 1 do
        begin
          if Actions.Items[I].JSONType <> jtObject then Continue;
          Obj := TJSONObject(Actions.Items[I]); ActionText := Obj.Get('action', ''); Param := Obj.Get('param', '');
          Kind := ActionKindFromName(ActionText); ActionResult := ExecuteAction(Kind, Param);
          AgentLog(Format('[agent] action=%s param=%s result=%s', [ActionText, Param, ActionResult]));
          Results := Results + ActionText + ': ' + ActionResult + LineEnding;
        end;
      end;
    finally Root.Free; end;

    if Results <> '' then
    begin
      Raw := BuildPrompt(AUserPrompt) + LineEnding + 'RESULTADOS DAS ACOES:' + LineEnding + Results +
        'Responda em JSON valido com actions vazias e apenas o campo reply final.';
      if FLLM.SendQuestion(Raw) then
      begin
        Raw := UTF8Encode(FLLM.Response);
        if ParseResponse(Raw, FeedbackRoot) then
        try Reply := FeedbackRoot.Get('reply', Reply); finally FeedbackRoot.Free; end
        else begin AgentLog('[agent] warning=invalid feedback JSON'); Reply := Raw; end;
      end;
    end;
    Result := Reply; FLastResult := Result; FLastSuccess := True;
  except
    on E: Exception do begin SetError(E.Message); AgentLog('[agent] error=' + E.Message);
      Result := 'agent error: ' + E.Message; end;
  end;
end;

initialization
  {$I taiagentserial_icon.lrs}

end.
