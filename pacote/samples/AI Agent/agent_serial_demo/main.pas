unit main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, IniFiles, TypInfo, Forms, Controls, Graphics, Dialogs, ExtCtrls,
  StdCtrls, ComCtrls, Spin, Grids, Clipbrd, chatgpt, aiserial,
  ailistserialdevices, aiagent, aiagentserial, aiagent_memorymap,
  aiagent_flowevents;

type
  TLEDState = (ledsUnknown, ledsOff, ledsOn);

  { TfrmMain }

  TfrmMain = class(TForm)
    AIAgentMemoryMap1: TAIAgentMemoryMap;
    AIAgentDeviceCommands1: TAIAgentAction;
    AIAgentSerial1: TAIAgentSerial;
    AIListSerialDevices1: TAIListSerialDevices;
    AISerialModem1: TAISerialModem;
    btnIniciar: TButton;
    btnClearCatalog: TButton;
    btnCopyCommands: TButton;
    btnDiscoverCommands: TButton;
    btnNewConversation: TButton;
    btnRefreshPorts: TButton;
    btnSaveSetup: TButton;
    btnTestLLM: TButton;
    cbBaud: TComboBox;
    cbPort: TComboBox;
    cbProvider: TComboBox;
    cbTipoChat: TComboBox;
    CHATGPT1: TCHATGPT;
    editCustomModel: TEdit;
    editDev: TEdit;
    editLocalIP: TEdit;
    editORSite: TEdit;
    editORTitle: TEdit;
    editPrompt: TEdit;
    editToken: TEdit;
    editURL: TEdit;
    lblAgentStatus: TLabel;
    lblBaud: TLabel;
    lblCustomModel: TLabel;
    lblDev: TLabel;
    lblLLMStatus: TLabel;
    lblCatalogStatus: TLabel;
    lblLEDState: TLabel;
    lblLocalIP: TLabel;
    lblMaxTokens: TLabel;
    lblORSite: TLabel;
    lblORTitle: TLabel;
    lblPort: TLabel;
    lblProvider: TLabel;
    lblSerialInfo: TLabel;
    lblStartStatus: TLabel;
    lblTipoChat: TLabel;
    lblToken: TLabel;
    lblURL: TLabel;
    memoHistory: TMemo;
    pgMain: TPageControl;
    gridCommands: TStringGrid;
    pnlCommandsTop: TPanel;
    pnlLLM: TGroupBox;
    pnlPrompt: TPanel;
    pnlSerial: TGroupBox;
    pnlStart: TPanel;
    spinMaxTokens: TSpinEdit;
    tabChat: TTabSheet;
    tabCommands: TTabSheet;
    tabConfig: TTabSheet;
    tmrSerialPoll: TTimer;
    procedure AgentCommandRejected(Sender: TObject; const ACommand,
      AReason: string);
    procedure AgentCommandsDiscovered(Sender: TObject; ACommands: TStrings);
    procedure AgentDiscoveryError(Sender: TObject; const AMessage: string);
    procedure AgentBeforeAction(Sender: TObject; AKind: TAgentActionKind;
      const AParam: string; var AAllow: Boolean);
    procedure AgentLog(Sender: TObject; const AMessage: string);
    procedure btnIniciarClick(Sender: TObject);
    procedure btnClearCatalogClick(Sender: TObject);
    procedure btnCopyCommandsClick(Sender: TObject);
    procedure btnDiscoverCommandsClick(Sender: TObject);
    procedure btnNewConversationClick(Sender: TObject);
    procedure btnRefreshPortsClick(Sender: TObject);
    procedure btnSaveSetupClick(Sender: TObject);
    procedure btnTestLLMClick(Sender: TObject);
    procedure cbBaudChange(Sender: TObject);
    procedure cbPortChange(Sender: TObject);
    procedure editPromptKeyPress(Sender: TObject; var Key: char);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormCreate(Sender: TObject);
    procedure SerialRX(Sender: TObject; const AData: string);
    procedure tmrSerialPollTimer(Sender: TObject);
  private
    FHasMemoryFlow: Boolean;
    FLEDState: TLEDState;
    FLEDLineBuffer: string;
    procedure ApplyLLMConfig;
    procedure ApplySerialConfig;
    function ConfigFileName: string;
    function HistoryFileName: string;
    procedure LoadConfig;
    procedure LoadHistory;
    procedure RestoreHistory;
    procedure SaveConfig(AIncludeToken: Boolean = False);
    procedure SaveHistory;
    procedure RefreshPorts;
    procedure SubmitPrompt;
    procedure ProcessLEDStateChunk(const AData: string);
    procedure ProcessLEDStateLine(const ALine: string);
    procedure UpdateCatalogGrid;
    procedure UpdateDiscoveryStatus;
    function CatalogCommandDescription(const ACommand: string): string;
    function ActionName(AKind: TAgentActionKind): string;
  end;

var
  frmMain: TfrmMain;

implementation

{$R *.lfm}

procedure TfrmMain.FormCreate(Sender: TObject);
var
  I: Integer;
  TypeData: PTypeData;
begin
  cbProvider.Items.Clear;
  TypeData := GetTypeData(TypeInfo(TAIProvider));
  for I := TypeData^.MinValue to TypeData^.MaxValue do
    cbProvider.Items.Add(GetEnumName(TypeInfo(TAIProvider), I));
  cbProvider.ItemIndex := Ord(AIP_OPENAI);

  cbTipoChat.Items.Clear;
  TypeData := GetTypeData(TypeInfo(TVersionChat));
  for I := TypeData^.MinValue to TypeData^.MaxValue do
    cbTipoChat.Items.Add(GetEnumName(TypeInfo(TVersionChat), I));
  cbTipoChat.ItemIndex := Ord(VCT_GPT4o);

  cbBaud.ItemIndex := cbBaud.Items.IndexOf('115200');
  tabChat.TabVisible := False;
  pgMain.ActivePage := tabConfig;
  RefreshPorts;
  LoadConfig;
  ApplySerialConfig;
  LoadHistory;
  FLEDState := ledsUnknown;
  FLEDLineBuffer := '';
  gridCommands.ColCount := 4;
  gridCommands.FixedRows := 1;
  gridCommands.RowCount := 1;
  gridCommands.Cells[0, 0] := 'Comando';
  gridCommands.Cells[1, 0] := 'Descrição';
  gridCommands.Cells[2, 0] := 'Origem';
  gridCommands.Cells[3, 0] := 'Ativo';
  UpdateCatalogGrid;
  UpdateDiscoveryStatus;
end;

procedure TfrmMain.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
  tmrSerialPoll.Enabled := False;
  SaveConfig;
  SaveHistory;
  AISerialModem1.ClosePort;
end;

function TfrmMain.ConfigFileName: string;
var
  BaseDir: string;
begin
  {$IFDEF WINDOWS}
  BaseDir := GetEnvironmentVariable('APPDATA');
  if BaseDir = '' then
    BaseDir := GetAppConfigDir(False);
  BaseDir := IncludeTrailingPathDelimiter(BaseDir) +
    'Maurinsoft' + DirectorySeparator + 'AgentSerialDemo';
  {$ELSE}
  BaseDir := IncludeTrailingPathDelimiter(GetUserDir) + '.config' +
    DirectorySeparator + 'maurinsoft' + DirectorySeparator +
    'agent_serial_demo';
  {$ENDIF}
  Result := IncludeTrailingPathDelimiter(BaseDir) + 'settings.ini';
end;

function TfrmMain.HistoryFileName: string;
begin
  Result := IncludeTrailingPathDelimiter(ExtractFileDir(ConfigFileName)) +
    'conversation-history.json';
end;

procedure TfrmMain.LoadConfig;
var
  Ini: TIniFile;
  FileName, SavedValue: string;
  Idx: Integer;
begin
  FileName := ConfigFileName;
  if not FileExists(FileName) then Exit;

  Ini := TIniFile.Create(FileName);
  try
    SavedValue := Ini.ReadString('LLM', 'Provider', cbProvider.Text);
    Idx := cbProvider.Items.IndexOf(SavedValue);
    if Idx >= 0 then cbProvider.ItemIndex := Idx;

    SavedValue := Ini.ReadString('LLM', 'ChatType', cbTipoChat.Text);
    Idx := cbTipoChat.Items.IndexOf(SavedValue);
    if Idx >= 0 then cbTipoChat.ItemIndex := Idx;

    editCustomModel.Text := Ini.ReadString('LLM', 'CustomModel', '');
    editToken.Text := Ini.ReadString('LLM', 'Token', '');
    editURL.Text := Ini.ReadString('LLM', 'URL', '');
    editLocalIP.Text := Ini.ReadString('LLM', 'LocalIP', editLocalIP.Text);
    spinMaxTokens.Value := Ini.ReadInteger('LLM', 'MaxTokens', spinMaxTokens.Value);
    editDev.Text := Ini.ReadString('LLM', 'DevInstructions', editDev.Text);
    editORTitle.Text := Ini.ReadString('OpenRouter', 'Title', '');
    editORSite.Text := Ini.ReadString('OpenRouter', 'Site', '');

    SavedValue := Ini.ReadString('Serial', 'Port', '');
    Idx := cbPort.Items.IndexOf(SavedValue);
    if Idx >= 0 then cbPort.ItemIndex := Idx;

    SavedValue := Ini.ReadString('Serial', 'Baud', '');
    Idx := cbBaud.Items.IndexOf(SavedValue);
    if Idx >= 0 then cbBaud.ItemIndex := Idx;
  finally
    Ini.Free;
  end;
end;

procedure TfrmMain.LoadHistory;
var
  FileName: string;
begin
  FHasMemoryFlow := False;
  FileName := HistoryFileName;
  if not FileExists(FileName) then Exit;

  AIAgentMemoryMap1.LoadFromFile(FileName);
  if AIAgentMemoryMap1.LastError = '' then
  begin
    FHasMemoryFlow := True;
    RestoreHistory;
  end;
end;

procedure TfrmMain.RestoreHistory;
var
  I: Integer;
  Item: TAIAgentMemoryMapItem;
begin
  memoHistory.Clear;
  memoHistory.Lines.Add('=== Histórico persistente da conversa ===');
  for I := 0 to AIAgentMemoryMap1.Items.Count - 1 do
  begin
    Item := AIAgentMemoryMap1.Items[I];
    if SameText(Item.NomeAgente, 'AgenteSerial') then
    begin
      if Trim(Item.PedidoRecebido) <> '' then
        memoHistory.Lines.Add('Você> ' + Item.PedidoRecebido);
      if Trim(Item.SaidaGerada) <> '' then
        memoHistory.Lines.Add('Agente> ' + Item.SaidaGerada);
    end;
  end;
end;

procedure TfrmMain.SaveConfig(AIncludeToken: Boolean);
var
  Ini: TIniFile;
  FileName, ConfigDir: string;
begin
  FileName := ConfigFileName;
  ConfigDir := ExtractFileDir(FileName);
  if not DirectoryExists(ConfigDir) then
    ForceDirectories(ConfigDir);

  Ini := TIniFile.Create(FileName);
  try
    Ini.WriteString('LLM', 'Provider', cbProvider.Text);
    Ini.WriteString('LLM', 'ChatType', cbTipoChat.Text);
    Ini.WriteString('LLM', 'CustomModel', editCustomModel.Text);
    if AIncludeToken then
      Ini.WriteString('LLM', 'Token', editToken.Text);
    Ini.WriteString('LLM', 'URL', editURL.Text);
    Ini.WriteString('LLM', 'LocalIP', editLocalIP.Text);
    Ini.WriteInteger('LLM', 'MaxTokens', spinMaxTokens.Value);
    Ini.WriteString('LLM', 'DevInstructions', editDev.Text);
    Ini.WriteString('OpenRouter', 'Title', editORTitle.Text);
    Ini.WriteString('OpenRouter', 'Site', editORSite.Text);
    Ini.WriteString('Serial', 'Port', cbPort.Text);
    Ini.WriteString('Serial', 'Baud', cbBaud.Text);
    Ini.UpdateFile;
  finally
    Ini.Free;
  end;
end;

procedure TfrmMain.SaveHistory;
var
  FileName, HistoryDir: string;
begin
  if not FHasMemoryFlow then Exit;
  FileName := HistoryFileName;
  HistoryDir := ExtractFileDir(FileName);
  if not DirectoryExists(HistoryDir) then
    ForceDirectories(HistoryDir);
  AIAgentMemoryMap1.SaveToFile(FileName);
end;

procedure TfrmMain.ApplyLLMConfig;
begin
  CHATGPT1.Provider := TAIProvider(cbProvider.ItemIndex);
  CHATGPT1.TipoChat := TVersionChat(cbTipoChat.ItemIndex);
  CHATGPT1.TOKEN := editToken.Text;
  CHATGPT1.CustomModel := editCustomModel.Text;
  CHATGPT1.URL := editURL.Text;
  CHATGPT1.LocalIP := editLocalIP.Text;
  CHATGPT1.MaxTokens := spinMaxTokens.Value;
  CHATGPT1.Dev := editDev.Text;
  CHATGPT1.OpenRouterTitle := editORTitle.Text;
  CHATGPT1.OpenRouterSite := editORSite.Text;
end;

procedure TfrmMain.ApplySerialConfig;
var
  NewPort: string;
  NewBaud: Integer;
  ConfigChanged: Boolean;
begin
  NewPort := Trim(cbPort.Text);
  NewBaud := StrToIntDef(Trim(cbBaud.Text), 0);
  ConfigChanged := ((NewPort <> '') and
    (not SameText(AISerialModem1.DeviceName, NewPort))) or
    ((NewBaud > 0) and (AISerialModem1.BaudRate <> NewBaud));

  if AISerialModem1.Active and ConfigChanged then
  begin
    AISerialModem1.ClosePort;
    if AIAgentSerial1.ClearCatalogOnDisconnect then
      AIAgentSerial1.ClearCommandCatalog;
  end;

  if NewPort <> '' then
    AISerialModem1.DeviceName := NewPort;
  if NewBaud > 0 then
    AISerialModem1.BaudRate := NewBaud;

  lblSerialInfo.Caption := Format(
    'Configurado: %s @ %d. A conexão será feita pelo agente.',
    [AISerialModem1.DeviceName, AISerialModem1.BaudRate]);
end;

procedure TfrmMain.RefreshPorts;
begin
  AIListSerialDevices1.ProbeOpenable := False;
  AIListSerialDevices1.Refresh;
  AIListSerialDevices1.GetDeviceNames(cbPort.Items);
  if cbPort.Items.Count > 0 then
    cbPort.ItemIndex := 0;
end;

procedure TfrmMain.btnRefreshPortsClick(Sender: TObject);
begin
  RefreshPorts;
  ApplySerialConfig;
end;

function TfrmMain.CatalogCommandDescription(const ACommand: string): string;
var
  I: Integer;
  Definition, Prefix: string;
begin
  Result := '';
  Prefix := ACommand + ':';
  for I := 0 to AIAgentDeviceCommands1.ParameterDefinitions.Count - 1 do
  begin
    Definition := AIAgentDeviceCommands1.ParameterDefinitions[I];
    if SameText(Copy(Definition, 1, Length(Prefix)), Prefix) then
      Exit(Trim(Copy(Definition, Length(Prefix) + 1, MaxInt)));
  end;
end;

procedure TfrmMain.UpdateCatalogGrid;
var
  I, Row: Integer;
  CommandName: string;
begin
  gridCommands.RowCount := AIAgentDeviceCommands1.AllowedActions.Count + 1;
  if gridCommands.RowCount < 2 then gridCommands.RowCount := 2;
  for Row := 1 to gridCommands.RowCount - 1 do
    for I := 0 to gridCommands.ColCount - 1 do
      gridCommands.Cells[I, Row] := '';

  for I := 0 to AIAgentDeviceCommands1.AllowedActions.Count - 1 do
  begin
    Row := I + 1;
    CommandName := AIAgentDeviceCommands1.AllowedActions[I];
    gridCommands.Cells[0, Row] := CommandName;
    gridCommands.Cells[1, Row] := CatalogCommandDescription(CommandName);
    gridCommands.Cells[2, Row] := 'serial-manual';
    gridCommands.Cells[3, Row] := 'Sim';
  end;
end;

procedure TfrmMain.UpdateDiscoveryStatus;
var
  StatusText: string;
begin
  case AIAgentSerial1.DiscoveryState of
    scdsIdle: StatusText := 'Não carregado';
    scdsWaitingBegin: StatusText := 'Aguardando MAN-BEGIN';
    scdsReadingManual: StatusText := 'Recebendo manual';
    scdsCompleted: StatusText := 'Carregado';
    scdsFailed: StatusText := 'Falha';
  end;
  if lblCatalogStatus.Caption <> 'Catálogo: ' + StatusText then
    lblCatalogStatus.Caption := 'Catálogo: ' + StatusText;
end;

procedure TfrmMain.btnDiscoverCommandsClick(Sender: TObject);
begin
  if not AISerialModem1.Active then
  begin
    MessageDlg('Conecte a porta serial antes de redescobrir os comandos.',
      mtWarning, [mbOK], 0);
    Exit;
  end;
  AIAgentSerial1.StartCommandDiscovery;
  UpdateCatalogGrid;
  UpdateDiscoveryStatus;
end;

procedure TfrmMain.btnClearCatalogClick(Sender: TObject);
begin
  AIAgentSerial1.ClearCommandCatalog;
  UpdateCatalogGrid;
  UpdateDiscoveryStatus;
end;

procedure TfrmMain.btnCopyCommandsClick(Sender: TObject);
begin
  if AIAgentDeviceCommands1.ParameterDefinitions.Count > 0 then
    Clipboard.AsText := AIAgentDeviceCommands1.ParameterDefinitions.Text
  else
    Clipboard.AsText := AIAgentDeviceCommands1.AllowedActions.Text;
end;

procedure TfrmMain.AgentCommandsDiscovered(Sender: TObject;
  ACommands: TStrings);
var
  I: Integer;
  Step: TAIAgentMemoryMapItem;
  CommandName, Description: string;
begin
  if not FHasMemoryFlow then
  begin
    AIAgentMemoryMap1.StartFlow('Sessão de controle serial via agente',
      'Agent Serial Demo', 'user', 'desktop');
    FHasMemoryFlow := True;
  end;

  Step := AIAgentMemoryMap1.BeginAgentStep('SerialCommandDiscovery',
    tamCustom, 'Descoberta automática de comandos via MAN');
  for I := 0 to ACommands.Count - 1 do
  begin
    CommandName := ACommands[I];
    Description := CatalogCommandDescription(CommandName);
    AIAgentMemoryMap1.AddQuestion(Step, 'comando_disponivel', CommandName,
      Description, 'serial-manual', 1.0);
  end;
  AIAgentMemoryMap1.EndAgentStep(Step, 'Manual serial analisado',
    'Comandos extraídos deterministicamente',
    'Atualizar catálogo de comandos',
    AIAgentDeviceCommands1.AllowedActions.Text,
    'Catálogo disponível para o agente serial');
  SaveHistory;
  UpdateCatalogGrid;
  UpdateDiscoveryStatus;
end;

procedure TfrmMain.AgentCommandRejected(Sender: TObject;
  const ACommand, AReason: string);
begin
  memoHistory.Lines.Add(Format('  [bloqueado] %s: %s',
    [ACommand, AReason]));
end;

procedure TfrmMain.AgentDiscoveryError(Sender: TObject;
  const AMessage: string);
begin
  memoHistory.Lines.Add('  [descoberta] ERRO: ' + AMessage);
  UpdateDiscoveryStatus;
end;

procedure TfrmMain.btnSaveSetupClick(Sender: TObject);
begin
  ApplyLLMConfig;
  ApplySerialConfig;
  SaveConfig(True);
  lblStartStatus.Caption := 'Setup salvo em: ' + ConfigFileName;
end;

procedure TfrmMain.cbPortChange(Sender: TObject);
begin
  ApplySerialConfig;
end;

procedure TfrmMain.cbBaudChange(Sender: TObject);
begin
  ApplySerialConfig;
end;

procedure TfrmMain.btnNewConversationClick(Sender: TObject);
begin
  if MessageDlg('Apagar o histórico atual e iniciar uma nova conversa?',
    mtConfirmation, [mbYes, mbNo], 0) <> mrYes then Exit;

  AISerialModem1.ClosePort;
  if AIAgentSerial1.ClearCatalogOnDisconnect then
    AIAgentSerial1.ClearCommandCatalog;
  AIAgentMemoryMap1.StartFlow('Sessão de controle serial via agente',
    'Agent Serial Demo', 'user', 'desktop');
  FHasMemoryFlow := True;
  RestoreHistory;
  SaveHistory;
  lblStartStatus.Caption := 'Nova conversa criada';
end;

procedure TfrmMain.btnTestLLMClick(Sender: TObject);
begin
  ApplyLLMConfig;
  Screen.Cursor := crHourGlass;
  try
    try
      if CHATGPT1.SendQuestion('Responda apenas: OK') then
        lblLLMStatus.Caption := 'Conexão OK — ' + CHATGPT1.ProviderName +
          ' / ' + CHATGPT1.TipoModelo
      else
        lblLLMStatus.Caption := 'FALHA: ' + CHATGPT1.LastError;
    except
      on E: Exception do
        lblLLMStatus.Caption := 'FALHA: ' + E.Message;
    end;
  finally
    Screen.Cursor := crDefault;
  end;
end;

procedure TfrmMain.btnIniciarClick(Sender: TObject);
var
  Step: TAIAgentMemoryMapItem;
begin
  if (TAIProvider(cbProvider.ItemIndex) <> AIP_LOCAL) and
    (Trim(editToken.Text) = '') then
  begin
    MessageDlg('Informe o token do provedor.', mtWarning, [mbOK], 0);
    Exit;
  end;
  if cbPort.Text = '' then
  begin
    MessageDlg('Selecione uma porta serial.', mtWarning, [mbOK], 0);
    Exit;
  end;

  ApplyLLMConfig;
  ApplySerialConfig;
  SaveConfig;
  if not FHasMemoryFlow then
  begin
    AIAgentMemoryMap1.StartFlow('Sessão de controle serial via agente',
      'Agent Serial Demo', 'user', 'desktop');
    FHasMemoryFlow := True;
  end;
  RestoreHistory;
  Step := AIAgentMemoryMap1.BeginAgentStep('Configuração', tamCustom,
    'Configuração inicial da sessão');
  AIAgentMemoryMap1.AddQuestion(Step, 'porta_serial', cbPort.Text,
    'Porta selecionada pelo usuário', 'user', 1.0);
  AIAgentMemoryMap1.AddQuestion(Step, 'baud_rate', cbBaud.Text,
    'Baud rate selecionado pelo usuário', 'user', 1.0);
  AIAgentMemoryMap1.AddQuestion(Step, 'provider_llm', cbProvider.Text,
    'Provedor de IA', 'user', 1.0);
  AIAgentMemoryMap1.AddQuestion(Step, 'modelo', CHATGPT1.TipoModelo,
    'Modelo em uso', 'system', 1.0);
  AIAgentMemoryMap1.AddQuestion(Step, 'protocolo_hardware',
    'Para descobrir os comandos suportados pelo equipamento, envie MAN pela ' +
    'serial. O equipamento responde com o manual. Sempre que não souber como ' +
    'operar o dispositivo, envie MAN primeiro e leia a resposta.',
    'Convenção de descoberta de hardware', 'system', 1.0);
  AIAgentMemoryMap1.EndAgentStep(Step, 'Configuração validada',
    'Parâmetros registrados para uso da LLM', 'Iniciar sessão',
    'Configuração registrada', 'Usar porta, baud e protocolo MAN');
  SaveHistory;

  tabChat.TabVisible := True;
  pgMain.ActivePage := tabChat;
  lblStartStatus.Caption := 'Sessão iniciada';
  memoHistory.Lines.Add('=== Sessão iniciada/retomada ===');
  memoHistory.Lines.Add(Format('Porta: %s @ %s | Provider: %s',
    [cbPort.Text, cbBaud.Text, cbProvider.Text]));
  memoHistory.Lines.Add('Dica: o hardware documenta seus comandos via MAN.');
  memoHistory.Lines.Add('Digite sua solicitação abaixo e pressione Enter.');
  editPrompt.SetFocus;
end;

procedure TfrmMain.editPromptKeyPress(Sender: TObject; var Key: char);
begin
  if Key = #13 then
  begin
    Key := #0;
    SubmitPrompt;
  end;
end;

procedure TfrmMain.SubmitPrompt;
var
  Ask, Ctx, Reply: string;
  Step: TAIAgentMemoryMapItem;
begin
  Ask := Trim(editPrompt.Text);
  if Ask = '' then Exit;
  editPrompt.Clear;
  memoHistory.Lines.Add('Você> ' + Ask);
  lblAgentStatus.Caption := 'processando...';
  editPrompt.Enabled := False;
  Application.ProcessMessages;
  Step := nil;
  try
    Ctx := AIAgentMemoryMap1.BuildContextForAgent('AgenteSerial', tamCustom, 10);
    Step := AIAgentMemoryMap1.BeginAgentStep('AgenteSerial', tamCustom, Ask, Ctx);
    AIAgentSerial1.SystemPrompt := Ctx;
    Reply := AIAgentSerial1.Execute(Ask);
    AIAgentMemoryMap1.AddQuestion(Step, Ask, Reply,
      'Resposta do agente serial', 'LLM', 0);
    AIAgentMemoryMap1.EndAgentStep(Step, 'Prompt analisado',
      'Resposta gerada com memória da sessão', 'Executar agente serial', Reply,
      Reply);
    memoHistory.Lines.Add('Agente> ' + Reply);
  except
    on E: Exception do
    begin
      if Step <> nil then
        AIAgentMemoryMap1.EndAgentStep(Step, 'Erro', E.Message,
          'Abortar execução', 'ERRO: ' + E.Message, E.Message);
      memoHistory.Lines.Add('ERRO> ' + E.Message);
    end;
  end;
  SaveHistory;
  lblAgentStatus.Caption := 'pronto';
  editPrompt.Enabled := True;
  editPrompt.SetFocus;
end;

function TfrmMain.ActionName(AKind: TAgentActionKind): string;
const
  Names: array[TAgentActionKind] of string = ('none', 'set_port', 'set_baud',
    'connect', 'disconnect', 'send', 'read', 'list_ports', 'status');
begin
  Result := Names[AKind];
end;

procedure TfrmMain.AgentBeforeAction(Sender: TObject; AKind: TAgentActionKind;
  const AParam: string; var AAllow: Boolean);
begin
  AAllow := MessageDlg('O agente quer executar: ' + ActionName(AKind) + ' ' +
    AParam + '. Permitir?', mtConfirmation, [mbYes, mbNo], 0) = mrYes;
end;

procedure TfrmMain.AgentLog(Sender: TObject; const AMessage: string);
begin
  memoHistory.Lines.Add('  [ação] ' + AMessage);
end;

procedure TfrmMain.SerialRX(Sender: TObject; const AData: string);
begin
  AIAgentSerial1.AppendRX(AData);
  ProcessLEDStateChunk(AData);
  memoHistory.Lines.Add('  [RX] ' + AData);
end;

procedure TfrmMain.ProcessLEDStateChunk(const AData: string);
var
  LFPos: SizeInt;
  Line: string;
begin
  FLEDLineBuffer := FLEDLineBuffer + AData;
  repeat
    LFPos := Pos(#10, FLEDLineBuffer);
    if LFPos = 0 then Break;
    Line := Copy(FLEDLineBuffer, 1, LFPos - 1);
    Delete(FLEDLineBuffer, 1, LFPos);
    if (Line <> '') and (Line[Length(Line)] = #13) then
      Delete(Line, Length(Line), 1);
    ProcessLEDStateLine(Trim(Line));
  until False;
end;

procedure TfrmMain.ProcessLEDStateLine(const ALine: string);
begin
  if SameText(ALine, 'STATE LED=ON') then
    FLEDState := ledsOn
  else if SameText(ALine, 'STATE LED=OFF') then
    FLEDState := ledsOff
  else
    Exit;

  case FLEDState of
    ledsOn: lblLEDState.Caption := 'LED: ligado';
    ledsOff: lblLEDState.Caption := 'LED: desligado';
    else lblLEDState.Caption := 'LED: desconhecido';
  end;
end;

procedure TfrmMain.tmrSerialPollTimer(Sender: TObject);
begin
  if AISerialModem1.Active then AISerialModem1.Poll;
  UpdateDiscoveryStatus;
end;

end.
