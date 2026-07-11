unit aiagentserial;

{$mode objfpc}{$H+}

{ If Serial.OnRXReceive is already assigned, the owner must forward received
  data to AppendRX. Otherwise TAIAgentSerial installs its internal handler. }

interface

uses
  Classes, SysUtils, fpjson, jsonparser, aibase, chatgpt, aiserial,
  ailistserialdevices, LResources;

type
  TAgentActionKind = (aakNone, aakSetPort, aakSetBaud, aakConnect,
    aakDisconnect, aakSend, aakRead, aakListPorts, aakStatus);

  TAgentActionEvent = procedure(Sender: TObject; AKind: TAgentActionKind;
    const AParam: string; var AAllow: Boolean) of object;
  TAgentLogEvent = procedure(Sender: TObject; const AMessage: string) of object;

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
    FOnBeforeAction: TAgentActionEvent;
    FOnAgentLog: TAgentLogEvent;
    procedure SetSerial(AValue: TAISerialModem);
    procedure SetLLM(AValue: TCHATGPT);
    procedure SetMaxActionsPerPrompt(AValue: Integer);
    procedure SerialRX(Sender: TObject; const AData: string);
    procedure AgentLog(const AMessage: string);
    function BuildPrompt(const AUserPrompt: string): string;
    function ExtractJSONObject(const AText: string): string;
    function ParseResponse(const AText: string; out ARoot: TJSONObject): Boolean;
    function ActionKindFromName(const AName: string): TAgentActionKind;
    function ActionName(AKind: TAgentActionKind): string;
    function ExecuteAction(AKind: TAgentActionKind; const AParam: string): string; reintroduce;
    function RXContext: string;
  protected
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    function Execute(const AUserPrompt: string): string;
    procedure AppendRX(const AData: string);
  published
    property Serial: TAISerialModem read FSerial write SetSerial;
    property LLM: TCHATGPT read FLLM write SetLLM;
    property SystemPrompt: string read FSystemPrompt write FSystemPrompt;
    property RequireConfirmation: Boolean read FRequireConfirmation write FRequireConfirmation default True;
    property MaxActionsPerPrompt: Integer read FMaxActionsPerPrompt write SetMaxActionsPerPrompt default 5;
    property OnBeforeAction: TAgentActionEvent read FOnBeforeAction write FOnBeforeAction;
    property OnAgentLog: TAgentLogEvent read FOnAgentLog write FOnAgentLog;
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
    ' - send (param: texto a enviar; use \n para nova linha)' + LineEnding +
    ' - read (param vazio): retorna dados recebidos acumulados' + LineEnding +
    ' - status (param vazio): retorna porta, baud e estado da conexao' + LineEnding +
    'Se nenhuma acao for necessaria, use "actions":[] e apenas "reply".';

implementation

procedure Register;
begin
  RegisterComponents('AI AGENTS', [TAIAgentSerial]);
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
  FCategory := ccAction;
end;

destructor TAIAgentSerial.Destroy;
begin
  if (FSerial <> nil) and FOwnsSerialRXHandler then
    FSerial.OnRXReceive := nil;
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
end;

procedure TAIAgentSerial.AgentLog(const AMessage: string);
begin
  if Assigned(FOnAgentLog) then FOnAgentLog(Self, AMessage);
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
    [FSerial.DeviceName, FSerial.BaudRate, State]) + LineEnding +
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
  Data: string;
  Lister: TAIListSerialDevices;
  Names: TStringList;
begin
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
      if FSerial.OpenPort then Result := 'connected' else Result := 'error: ' + FSerial.LastError;
    aakDisconnect: begin FSerial.ClosePort; Result := 'disconnected'; end;
    aakSend:
      begin
        Data := StringReplace(AParam, '\n', #10, [rfReplaceAll]);
        Data := StringReplace(Data, '\r', #13, [rfReplaceAll]);
        if FSerial.WriteText(Data) then Result := 'sent ' + IntToStr(Length(Data)) + ' bytes'
        else Result := 'error: ' + FSerial.LastError;
      end;
    aakRead:
      begin FSerial.Poll; Result := Trim(FRXBuffer.Text);
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
