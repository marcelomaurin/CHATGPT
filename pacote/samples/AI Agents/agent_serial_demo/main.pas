unit main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, TypInfo, Forms, Controls, Graphics, Dialogs, ExtCtrls,
  StdCtrls, ComCtrls, Spin, chatgpt, aiserial, ailistserialdevices,
  aiagentserial, aiagent_memorymap, aiagent_flowevents;

type
  { TfrmMain }

  TfrmMain = class(TForm)
    AIAgentMemoryMap1: TAIAgentMemoryMap;
    AIAgentSerial1: TAIAgentSerial;
    AIListSerialDevices1: TAIListSerialDevices;
    AISerialModem1: TAISerialModem;
    btnIniciar: TButton;
    btnRefreshPorts: TButton;
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
    pnlLLM: TGroupBox;
    pnlPrompt: TPanel;
    pnlSerial: TGroupBox;
    pnlStart: TPanel;
    spinMaxTokens: TSpinEdit;
    tabChat: TTabSheet;
    tabConfig: TTabSheet;
    procedure AgentBeforeAction(Sender: TObject; AKind: TAgentActionKind;
      const AParam: string; var AAllow: Boolean);
    procedure AgentLog(Sender: TObject; const AMessage: string);
    procedure btnIniciarClick(Sender: TObject);
    procedure btnRefreshPortsClick(Sender: TObject);
    procedure btnTestLLMClick(Sender: TObject);
    procedure editPromptKeyPress(Sender: TObject; var Key: char);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormCreate(Sender: TObject);
    procedure SerialRX(Sender: TObject; const AData: string);
  private
    procedure ApplyLLMConfig;
    procedure RefreshPorts;
    procedure SubmitPrompt;
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

  cbBaud.ItemIndex := cbBaud.Items.IndexOf('9600');
  tabChat.TabVisible := False;
  pgMain.ActivePage := tabConfig;
  RefreshPorts;
end;

procedure TfrmMain.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
  AISerialModem1.ClosePort;
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
  AIAgentMemoryMap1.StartFlow('Sessão de controle serial via agente',
    'Agent Serial Demo', 'user', 'desktop');
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

  tabChat.TabVisible := True;
  pgMain.ActivePage := tabChat;
  lblStartStatus.Caption := 'Sessão iniciada';
  memoHistory.Clear;
  memoHistory.Lines.Add('=== Sessão iniciada ===');
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
  memoHistory.Lines.Add('  [RX] ' + AData);
end;

end.
