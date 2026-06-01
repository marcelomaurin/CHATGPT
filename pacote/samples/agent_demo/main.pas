unit main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, StdCtrls,
  ComCtrls, chatgpt, aiagent;

type

  { TfrmAgentDemo }

  TfrmAgentDemo = class(TForm)
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
  private
    { UI Controls - Top Panel Config }
    pnlHeader: TPanel;
    pnlConfig: TPanel;
    
    lblProvider: TLabel;
    cbProvider: TComboBox;
    lblModel: TLabel;
    cbModel: TComboBox;
    lblCustomModel: TLabel;
    edtCustomModel: TEdit;
    lblToken: TLabel;
    edtToken: TEdit;
    lblLocalIP: TLabel;
    edtLocalIP: TEdit;

    { Main Panels }
    pnlClient: TPanel;
    pnlLeft: TPanel;
    splitterLeft: TSplitter;
    pnlRight: TPanel;
    splitterRight: TSplitter;
    pnlCenter: TPanel;

    { Left Sub-components (Agent Directives) }
    gbSystemPrompt: TGroupBox;
    memSystemPrompt: TMemo;
    gbQuestions: TGroupBox;
    memQuestions: TMemo;
    gbContext: TGroupBox;
    memContext: TMemo;
    gbAllowedActions: TGroupBox;
    memAllowedActions: TMemo;
    gbParameterDefs: TGroupBox;
    memParameterDefs: TMemo;

    { Center Sub-components (Execution Panel) }
    gbInput: TGroupBox;
    memInputData: TMemo;
    pnlExecute: TPanel;
    btnExecute: TButton;
    btnLoadITScenario: TButton;
    btnLoadSupportScenario: TButton;
    gbLogs: TGroupBox;
    memLogs: TMemo;

    { Right Sub-components (Output & Decisons) }
    gbResultAction: TGroupBox;
    pnlSelectedAction: TPanel;
    gbSelectedParams: TGroupBox;
    lbSelectedParams: TListBox;
    gbRationale: TGroupBox;
    memRationale: TMemo;

    { Non-visual IA components }
    FChatGPT: TCHATGPT;
    FAIAgent: TAIAgent;
    FAIAgentOptions: TAIAgentOptions;
    FAIAgentAction: TAIAgentAction;

    procedure CreateLayout;
    procedure LoadITAlertScenario;
    procedure LoadSupportScenario;
    
    { Action handlers }
    procedure cbProviderChange(Sender: TObject);
    procedure btnExecuteClick(Sender: TObject);
    procedure btnLoadITScenarioClick(Sender: TObject);
    procedure btnLoadSupportScenarioClick(Sender: TObject);
    
    { Callback events }
    procedure OnAgentActionTriggered(Sender: TObject; const AActionName: string; AParams: TStrings);
    procedure OnAgentExecuteAction(Sender: TObject; const AActionName: string; AParams: TStrings);
  public

  end;

var
  frmAgentDemo: TfrmAgentDemo;

implementation

{$R *.lfm}

{ TfrmAgentDemo }

procedure TfrmAgentDemo.FormCreate(Sender: TObject);
begin
  Caption := 'IA Autonomous Agent & Decision Playground';
  Width := 1180;
  Height := 720;
  Position := poScreenCenter;
  Color := $F3F4F6; // Modern soft gray background

  { Instantiate IA Components }
  FChatGPT := TCHATGPT.Create(Self);
  FAIAgent := TAIAgent.Create(Self);
  FAIAgentOptions := TAIAgentOptions.Create(Self);
  FAIAgentAction := TAIAgentAction.Create(Self);

  { Wire IA components together }
  FAIAgent.ChatGPT := FChatGPT;
  FAIAgent.Options := FAIAgentOptions;
  FAIAgent.Action := FAIAgentAction;
  FAIAgentOptions.Action := FAIAgentAction;

  { Wire events }
  FAIAgent.OnActionTriggered := @OnAgentActionTriggered;
  FAIAgentAction.OnExecuteAction := @OnAgentExecuteAction;

  { Design layout }
  CreateLayout;

  { Setup ComboBox selections }
  cbProvider.ItemIndex := 0; // OpenAI
  cbProviderChange(nil);

  { Load default Scenario }
  LoadITAlertScenario;
end;

procedure TfrmAgentDemo.FormDestroy(Sender: TObject);
begin
  { Self automatically frees owned sub-components FChatGPT, FAIAgent, etc. }
end;

procedure TfrmAgentDemo.CreateLayout;
var
  pnlSep: TPanel;
begin
  { 1. Header Panel }
  pnlHeader := TPanel.Create(Self);
  pnlHeader.Parent := Self;
  pnlHeader.Align := alTop;
  pnlHeader.Height := 55;
  pnlHeader.Color := $1E3A8A; // Sleek Dark Navy Blue
  pnlHeader.BevelOuter := bvNone;
  pnlHeader.BorderWidth := 10;

  with TLabel.Create(Self) do
  begin
    Parent := pnlHeader;
    Align := alClient;
    Alignment := taCenter;
    Layout := tlCenter;
    Caption := '🤖 IA Autonomous Agent & Structured Decision Control Panel';
    Font.Color := clWhite;
    Font.Size := 13;
    Font.Style := [fsBold];
  end;

  { 2. Provider Config Panel }
  pnlConfig := TPanel.Create(Self);
  pnlConfig.Parent := Self;
  pnlConfig.Align := alTop;
  pnlConfig.Height := 75;
  pnlConfig.Color := clWhite;
  pnlConfig.BevelOuter := bvNone;
  pnlConfig.BorderWidth := 8;

  // Provider ComboBox
  lblProvider := TLabel.Create(Self);
  lblProvider.Parent := pnlConfig;
  lblProvider.Left := 15;
  lblProvider.Top := 10;
  lblProvider.Caption := 'Provedor IA:';
  lblProvider.Font.Style := [fsBold];

  cbProvider := TComboBox.Create(Self);
  cbProvider.Parent := pnlConfig;
  cbProvider.Left := 15;
  cbProvider.Top := 28;
  cbProvider.Width := 140;
  cbProvider.Style := csDropDownList;
  cbProvider.Items.Add('OpenAI');
  cbProvider.Items.Add('OpenRouter');
  cbProvider.Items.Add('Cerebras');
  cbProvider.Items.Add('Local (Ollama)');
  cbProvider.Items.Add('Google Gemini');
  cbProvider.Items.Add('Anthropic Claude');
  cbProvider.OnChange := @cbProviderChange;

  // Model ComboBox
  lblModel := TLabel.Create(Self);
  lblModel.Parent := pnlConfig;
  lblModel.Left := 170;
  lblModel.Top := 10;
  lblModel.Caption := 'Modelo Sugerido:';
  lblModel.Font.Style := [fsBold];

  cbModel := TComboBox.Create(Self);
  cbModel.Parent := pnlConfig;
  cbModel.Left := 170;
  cbModel.Top := 28;
  cbModel.Width := 170;
  cbModel.Style := csDropDownList;

  // Custom Model Edit
  lblCustomModel := TLabel.Create(Self);
  lblCustomModel.Parent := pnlConfig;
  lblCustomModel.Left := 355;
  lblCustomModel.Top := 10;
  lblCustomModel.Caption := 'Modelo Customizado:';
  lblCustomModel.Font.Style := [fsBold];

  edtCustomModel := TEdit.Create(Self);
  edtCustomModel.Parent := pnlConfig;
  edtCustomModel.Left := 355;
  edtCustomModel.Top := 28;
  edtCustomModel.Width := 150;
  edtCustomModel.Text := '';

  // Local URL IP
  lblLocalIP := TLabel.Create(Self);
  lblLocalIP.Parent := pnlConfig;
  lblLocalIP.Left := 520;
  lblLocalIP.Top := 10;
  lblLocalIP.Caption := 'URL Local / IP:';
  lblLocalIP.Font.Style := [fsBold];

  edtLocalIP := TEdit.Create(Self);
  edtLocalIP.Parent := pnlConfig;
  edtLocalIP.Left := 520;
  edtLocalIP.Top := 28;
  edtLocalIP.Width := 180;
  edtLocalIP.Text := 'http://localhost:11434';

  // API Token Key
  lblToken := TLabel.Create(Self);
  lblToken.Parent := pnlConfig;
  lblToken.Left := 715;
  lblToken.Top := 10;
  lblToken.Caption := 'Chave API / Token:';
  lblToken.Font.Style := [fsBold];

  edtToken := TEdit.Create(Self);
  edtToken.Parent := pnlConfig;
  edtToken.Left := 715;
  edtToken.Top := 28;
  edtToken.Width := 250;
  edtToken.PasswordChar := '*';

  { 3. Main Workspace Area (Client Panel) }
  pnlClient := TPanel.Create(Self);
  pnlClient.Parent := Self;
  pnlClient.Align := alClient;
  pnlClient.BevelOuter := bvNone;

  { Left Panel: Agent Directives (System Prompts, Questions, Allowed Actions, Params) }
  pnlLeft := TPanel.Create(Self);
  pnlLeft.Parent := pnlClient;
  pnlLeft.Align := alLeft;
  pnlLeft.Width := 380;
  pnlLeft.BevelOuter := bvNone;
  pnlLeft.Color := $F9FAFB;
  pnlLeft.BorderWidth := 10;

  // System Prompt Group
  gbSystemPrompt := TGroupBox.Create(Self);
  gbSystemPrompt.Parent := pnlLeft;
  gbSystemPrompt.Align := alTop;
  gbSystemPrompt.Height := 105;
  gbSystemPrompt.Caption := ' Prompt do Sistema (SystemPrompt) ';
  gbSystemPrompt.Font.Style := [fsBold];
  
  memSystemPrompt := TMemo.Create(Self);
  memSystemPrompt.Parent := gbSystemPrompt;
  memSystemPrompt.Align := alClient;
  memSystemPrompt.ScrollBars := ssAutoVertical;

  pnlSep := TPanel.Create(Self);
  pnlSep.Parent := pnlLeft;
  pnlSep.Align := alTop;
  pnlSep.Height := 8;
  pnlSep.BevelOuter := bvNone;

  // Questions Group
  gbQuestions := TGroupBox.Create(Self);
  gbQuestions.Parent := pnlLeft;
  gbQuestions.Align := alTop;
  gbQuestions.Height := 125;
  gbQuestions.Caption := ' Perguntas/Diretrizes (Options.Questions) ';
  gbQuestions.Font.Style := [fsBold];

  memQuestions := TMemo.Create(Self);
  memQuestions.Parent := gbQuestions;
  memQuestions.Align := alClient;
  memQuestions.ScrollBars := ssAutoVertical;

  pnlSep := TPanel.Create(Self);
  pnlSep.Parent := pnlLeft;
  pnlSep.Align := alTop;
  pnlSep.Height := 8;
  pnlSep.BevelOuter := bvNone;

  // Context Group
  gbContext := TGroupBox.Create(Self);
  gbContext.Parent := pnlLeft;
  gbContext.Align := alTop;
  gbContext.Height := 85;
  gbContext.Caption := ' Contexto Operacional (Options.Context) ';
  gbContext.Font.Style := [fsBold];

  memContext := TMemo.Create(Self);
  memContext.Parent := gbContext;
  memContext.Align := alClient;
  memContext.ScrollBars := ssAutoVertical;

  pnlSep := TPanel.Create(Self);
  pnlSep.Parent := pnlLeft;
  pnlSep.Align := alTop;
  pnlSep.Height := 8;
  pnlSep.BevelOuter := bvNone;

  // Allowed Actions Group
  gbAllowedActions := TGroupBox.Create(Self);
  gbAllowedActions.Parent := pnlLeft;
  gbAllowedActions.Align := alTop;
  gbAllowedActions.Height := 110;
  gbAllowedActions.Caption := ' Ações Permitidas (Action.AllowedActions) ';
  gbAllowedActions.Font.Style := [fsBold];

  memAllowedActions := TMemo.Create(Self);
  memAllowedActions.Parent := gbAllowedActions;
  memAllowedActions.Align := alClient;
  memAllowedActions.ScrollBars := ssAutoVertical;

  pnlSep := TPanel.Create(Self);
  pnlSep.Parent := pnlLeft;
  pnlSep.Align := alTop;
  pnlSep.Height := 8;
  pnlSep.BevelOuter := bvNone;

  // Parameter Definitions Group
  gbParameterDefs := TGroupBox.Create(Self);
  gbParameterDefs.Parent := pnlLeft;
  gbParameterDefs.Align := alClient;
  gbParameterDefs.Caption := ' Parâmetros Exigidos (Action.ParameterDefinitions) ';
  gbParameterDefs.Font.Style := [fsBold];

  memParameterDefs := TMemo.Create(Self);
  memParameterDefs.Parent := gbParameterDefs;
  memParameterDefs.Align := alClient;
  memParameterDefs.ScrollBars := ssAutoVertical;

  // Splitter Left
  splitterLeft := TSplitter.Create(Self);
  splitterLeft.Parent := pnlClient;
  splitterLeft.Align := alLeft;
  splitterLeft.Color := $E5E7EB;

  { Right Panel: Decision Results & Rationale }
  pnlRight := TPanel.Create(Self);
  pnlRight.Parent := pnlClient;
  pnlRight.Align := alRight;
  pnlRight.Width := 380;
  pnlRight.BevelOuter := bvNone;
  pnlRight.Color := $F9FAFB;
  pnlRight.BorderWidth := 10;

  // Result Action Group
  gbResultAction := TGroupBox.Create(Self);
  gbResultAction.Parent := pnlRight;
  gbResultAction.Align := alTop;
  gbResultAction.Height := 200;
  gbResultAction.Caption := ' ⚡ Decisão Escolhida pelo Agente ';
  gbResultAction.Font.Style := [fsBold];
  gbResultAction.BorderWidth := 5;

  pnlSelectedAction := TPanel.Create(Self);
  pnlSelectedAction.Parent := gbResultAction;
  pnlSelectedAction.Align := alTop;
  pnlSelectedAction.Height := 45;
  pnlSelectedAction.Color := $FEF3C7; // Light premium yellow
  pnlSelectedAction.Font.Color := $92400E; // Dark amber
  pnlSelectedAction.Font.Size := 11;
  pnlSelectedAction.Font.Style := [fsBold];
  pnlSelectedAction.Alignment := taCenter;
  pnlSelectedAction.Caption := 'AGUARDANDO PROCESSAMENTO...';
  pnlSelectedAction.BevelOuter := bvNone;

  gbSelectedParams := TGroupBox.Create(Self);
  gbSelectedParams.Parent := gbResultAction;
  gbSelectedParams.Align := alClient;
  gbSelectedParams.Caption := ' Parâmetros da Decisão ';
  gbSelectedParams.Font.Style := [fsBold];

  lbSelectedParams := TListBox.Create(Self);
  lbSelectedParams.Parent := gbSelectedParams;
  lbSelectedParams.Align := alClient;
  lbSelectedParams.Color := $F9FAFB;

  pnlSep := TPanel.Create(Self);
  pnlSep.Parent := pnlRight;
  pnlSep.Align := alTop;
  pnlSep.Height := 10;
  pnlSep.BevelOuter := bvNone;

  // Rationale Group
  gbRationale := TGroupBox.Create(Self);
  gbRationale.Parent := pnlRight;
  gbRationale.Align := alClient;
  gbRationale.Caption := ' 🧠 Raciocínio Analítico (Rationale) ';
  gbRationale.Font.Style := [fsBold];

  memRationale := TMemo.Create(Self);
  memRationale.Parent := gbRationale;
  memRationale.Align := alClient;
  memRationale.ReadOnly := True;
  memRationale.Color := $FFFDF5; // Gentle paper color
  memRationale.ScrollBars := ssAutoVertical;

  // Splitter Right
  splitterRight := TSplitter.Create(Self);
  splitterRight.Parent := pnlClient;
  splitterRight.Align := alRight;
  splitterRight.Color := $E5E7EB;

  { Center Panel: Input data & Log Memo }
  pnlCenter := TPanel.Create(Self);
  pnlCenter.Parent := pnlClient;
  pnlCenter.Align := alClient;
  pnlCenter.BevelOuter := bvNone;
  pnlCenter.BorderWidth := 10;

  // Input data group
  gbInput := TGroupBox.Create(Self);
  gbInput.Parent := pnlCenter;
  gbInput.Align := alTop;
  gbInput.Height := 240;
  gbInput.Caption := ' Dados de Entrada para Análise (InputData) ';
  gbInput.Font.Style := [fsBold];

  memInputData := TMemo.Create(Self);
  memInputData.Parent := gbInput;
  memInputData.Align := alClient;
  memInputData.ScrollBars := ssAutoVertical;

  // Execution buttons bar
  pnlExecute := TPanel.Create(Self);
  pnlExecute.Parent := pnlCenter;
  pnlExecute.Align := alTop;
  pnlExecute.Height := 48;
  pnlExecute.BevelOuter := bvNone;

  btnLoadITScenario := TButton.Create(Self);
  btnLoadITScenario.Parent := pnlExecute;
  btnLoadITScenario.Align := alLeft;
  btnLoadITScenario.Width := 125;
  btnLoadITScenario.Caption := '🔌 Alerta de Servidor';
  btnLoadITScenario.OnClick := @btnLoadITScenarioClick;

  btnLoadSupportScenario := TButton.Create(Self);
  btnLoadSupportScenario.Parent := pnlExecute;
  btnLoadSupportScenario.Align := alLeft;
  btnLoadSupportScenario.Width := 125;
  btnLoadSupportScenario.Caption := '📦 Ticket de Entrega';
  btnLoadSupportScenario.OnClick := @btnLoadSupportScenarioClick;

  btnExecute := TButton.Create(Self);
  btnExecute.Parent := pnlExecute;
  btnExecute.Align := alClient;
  btnExecute.Caption := '🤖 EXECUTAR DECISÃO DO AGENTE';
  btnExecute.Font.Style := [fsBold];
  btnExecute.OnClick := @btnExecuteClick;

  pnlSep := TPanel.Create(Self);
  pnlSep.Parent := pnlCenter;
  pnlSep.Align := alTop;
  pnlSep.Height := 8;
  pnlSep.BevelOuter := bvNone;

  // Logs group
  gbLogs := TGroupBox.Create(Self);
  gbLogs.Parent := pnlCenter;
  gbLogs.Align := alClient;
  gbLogs.Caption := ' 📜 Histórico de Comunicação / JSON Logs ';
  gbLogs.Font.Style := [fsBold];

  memLogs := TMemo.Create(Self);
  memLogs.Parent := gbLogs;
  memLogs.Align := alClient;
  memLogs.ReadOnly := True;
  memLogs.ScrollBars := ssAutoVertical;
  memLogs.Color := $F1F5F9;
  memLogs.Font.Name := 'Courier New';
  memLogs.Font.Size := 9;
end;

procedure TfrmAgentDemo.LoadITAlertScenario;
begin
  memSystemPrompt.Text := 'Você é um Agente Inteligente Autônomo de Segurança e Infraestrutura de TI para servidores críticos.';
  
  memQuestions.Clear;
  memQuestions.Lines.Add('1. Analise a temperatura reportada e configure a gravidade de emergência.');
  memQuestions.Lines.Add('2. Se a temperatura ultrapassar 40°C, dispare a ação TRIGGER_CRITICAL_COOLING_ALERT com gravidade alta.');
  memQuestions.Lines.Add('3. Caso seja falha comum, use NOTIFY_MAINTENANCE.');

  memContext.Text := 'Servidores principais em Ribeirão Preto, sala A, climatizados.';

  memAllowedActions.Clear;
  memAllowedActions.Lines.Add('TRIGGER_CRITICAL_COOLING_ALERT');
  memAllowedActions.Lines.Add('NOTIFY_MAINTENANCE');
  memAllowedActions.Lines.Add('REQUEST_MORE_INFO');

  memParameterDefs.Clear;
  memParameterDefs.Lines.Add('urgency: string (alta, media, baixa)');
  memParameterDefs.Lines.Add('reason: string (breve justificativa)');
  memParameterDefs.Lines.Add('target_department: string (suporte, infra, ti)');
  memParameterDefs.Lines.Add('notification_method: string (slack, email, pagerduty)');

  memInputData.Text := 'ALERT_EVENT: Sensor de temperatura na sala A reportou 48.2 graus Celsius às 19:40h! Ar condicionado falhou em inicializar automaticamente.';
end;

procedure TfrmAgentDemo.LoadSupportScenario;
begin
  memSystemPrompt.Text := 'Você é um Agente de Triagem de Tickets de Suporte e Reclamações de Clientes.';
  
  memQuestions.Clear;
  memQuestions.Lines.Add('1. Verifique se o pedido está em atraso crítico.');
  memQuestions.Lines.Add('2. Se o cliente solicitar cancelamento ou devolução, dispare DISPATCH_SUPPORT_TICKET com target_department=financeiro.');
  memQuestions.Lines.Add('3. Identifique o teor do problema e encaminhe adequadamente.');

  memContext.Text := 'Sistema de comércio eletrônico integrado via Correios/Transportadoras.';

  memAllowedActions.Clear;
  memAllowedActions.Lines.Add('DISPATCH_SUPPORT_TICKET');
  memAllowedActions.Lines.Add('REQUEST_MORE_INFO');

  memParameterDefs.Clear;
  memParameterDefs.Lines.Add('urgency: string (alta, media, baixa)');
  memParameterDefs.Lines.Add('reason: string (motivação detalhada)');
  memParameterDefs.Lines.Add('target_department: string (financeiro, suporte, logistica)');
  memParameterDefs.Lines.Add('notification_method: string (email, ticket_system)');

  memInputData.Text := 'Olá, comprei o smartphone no pedido #98342 com entrega prometida para 3 dias atrás. Ele ainda não foi postado e quero o reembolso imediatamente!';
end;

procedure TfrmAgentDemo.cbProviderChange(Sender: TObject);
begin
  cbModel.Clear;
  case TAIProvider(cbProvider.ItemIndex) of
    AIP_OPENAI:
      begin
        cbModel.Items.Add('gpt-4o');
        cbModel.Items.Add('gpt-4o-mini');
        cbModel.Items.Add('o3-mini');
        cbModel.ItemIndex := 0;
        lblToken.Enabled := True;
        edtToken.Enabled := True;
        lblLocalIP.Enabled := False;
        edtLocalIP.Enabled := False;
      end;
    AIP_OPENROUTER:
      begin
        cbModel.Items.Add('meta-llama/llama-3-8b-instruct:free');
        cbModel.Items.Add('google/gemma-2-9b-it:free');
        cbModel.Items.Add('deepseek/deepseek-r1:free');
        cbModel.ItemIndex := 0;
        lblToken.Enabled := True;
        edtToken.Enabled := True;
        lblLocalIP.Enabled := False;
        edtLocalIP.Enabled := False;
      end;
    AIP_CEREBRAS:
      begin
        cbModel.Items.Add('qwen-3-235b');
        cbModel.ItemIndex := 0;
        lblToken.Enabled := True;
        edtToken.Enabled := True;
        lblLocalIP.Enabled := False;
        edtLocalIP.Enabled := False;
      end;
    AIP_LOCAL:
      begin
        cbModel.Items.Add('llama3.2:3b');
        cbModel.Items.Add('qwen2.5:1.5b');
        cbModel.Items.Add('deepseek-r1:1.5b');
        cbModel.Items.Add('deepseek-r1:8b');
        cbModel.ItemIndex := 0;
        lblToken.Enabled := False;
        edtToken.Enabled := False;
        lblLocalIP.Enabled := True;
        edtLocalIP.Enabled := True;
      end;
    AIP_GEMINI:
      begin
        cbModel.Items.Add('gemini-2.5-flash');
        cbModel.Items.Add('gemini-2.5-pro');
        cbModel.Items.Add('gemini-2.0-flash');
        cbModel.ItemIndex := 0;
        lblToken.Enabled := True;
        edtToken.Enabled := True;
        lblLocalIP.Enabled := False;
        edtLocalIP.Enabled := False;
      end;
    AIP_CLAUDE:
      begin
        cbModel.Items.Add('claude-3-5-sonnet-20241022');
        cbModel.Items.Add('claude-3-5-haiku-20241022');
        cbModel.ItemIndex := 0;
        lblToken.Enabled := True;
        edtToken.Enabled := True;
        lblLocalIP.Enabled := False;
        edtLocalIP.Enabled := False;
      end;
  end;
end;

procedure TfrmAgentDemo.btnExecuteClick(Sender: TObject);
var
  Prov: TAIProvider;
  ModelIdx: Integer;
  VModel: TVersionChat;
  OK: Boolean;
begin
  Screen.Cursor := crHourGlass;
  pnlSelectedAction.Color := $FEF3C7;
  pnlSelectedAction.Font.Color := $92400E;
  pnlSelectedAction.Caption := 'EXECUTANDO DECISÃO DO AGENTE...';
  lbSelectedParams.Clear;
  memRationale.Clear;
  memLogs.Clear;
  
  try
    { 1. Configure TCHATGPT }
    Prov := TAIProvider(cbProvider.ItemIndex);
    FChatGPT.Provider := Prov;
    FChatGPT.TOKEN := edtToken.Text;
    FChatGPT.LocalIP := edtLocalIP.Text;
    FChatGPT.CustomModel := edtCustomModel.Text;

    ModelIdx := cbModel.ItemIndex;
    case Prov of
      AIP_OPENAI:
        begin
          if ModelIdx = 0 then VModel := VCT_GPT4o
          else if ModelIdx = 1 then VModel := VCT_GPT4O_MINI
          else VModel := VCT_GPTo3_mini;
        end;
      AIP_OPENROUTER:
        begin
          if ModelIdx = 0 then VModel := VCT_OPENROUTER_LLAMA3_8B_FREE
          else if ModelIdx = 1 then VModel := VCT_OPENROUTER_GEMMA2_9B_FREE
          else if ModelIdx = 2 then VModel := VCT_OPENROUTER_DEEPSEEK_R1_FREE
          else VModel := VCT_OPENROUTER_LLAMA32_3B_FREE;
        end;
      AIP_CEREBRAS:
        VModel := VCT_CUSTOM;
      AIP_LOCAL:
        begin
          if ModelIdx = 0 then VModel := VCT_LLAMA32_3B
          else if ModelIdx = 1 then VModel := VCT_QWEN25_15B
          else if ModelIdx = 2 then VModel := VCT_DEEPSEEK_R1_15B
          else VModel := VCT_DEEPSEEK_R1_8B;
        end;
      AIP_GEMINI:
        begin
          if ModelIdx = 0 then VModel := VCT_GEMINI_25_FLASH
          else if ModelIdx = 1 then VModel := VCT_GEMINI_25_PRO
          else VModel := VCT_GEMINI_20_FLASH;
        end;
      AIP_CLAUDE:
        begin
          if ModelIdx = 0 then VModel := VCT_CLAUDE_35_SONNET
          else if ModelIdx = 1 then VModel := VCT_CLAUDE_35_HAIKU
          else VModel := VCT_CLAUDE_3_OPUS;
        end;
    else
      VModel := VCT_GPT4o;
    end;
    FChatGPT.TipoChat := VModel;

    { 2. Configure Agent Parameters }
    FAIAgent.SystemPrompt := memSystemPrompt.Text;
    
    // Assign Questions
    FAIAgentOptions.Questions.Assign(memQuestions.Lines);
    FAIAgentOptions.Context := memContext.Text;
    
    // Assign Actions
    FAIAgentAction.AllowedActions.Assign(memAllowedActions.Lines);
    FAIAgentAction.ParameterDefinitions.Assign(memParameterDefs.Lines);

    { 3. Execute Decision }
    OK := FAIAgent.Execute(memInputData.Text);

    { 4. Show debug log }
    memLogs.Lines.Add('--- REQUISIÇÃO ---');
    memLogs.Lines.Add('Endpoint: ' + FChatGPT.LastURL);
    memLogs.Lines.Add('Modelo: ' + FChatGPT.TipoModelo);
    memLogs.Lines.Add('');
    memLogs.Lines.Add('--- JSON RESPOSTA BRUTA ---');
    memLogs.Lines.Add(FChatGPT.LastJSON);

    if OK then
    begin
      pnlSelectedAction.Color := $D1FAE5; // Soft green
      pnlSelectedAction.Font.Color := $065F46; // Dark green
      pnlSelectedAction.Caption := 'SUCESSO: ' + FAIAgentAction.SelectedAction;
      
      memRationale.Text := FAIAgent.LastRationale;
      
      // Update parameter display list
      lbSelectedParams.Items.Assign(FAIAgentAction.SelectedParameters);
    end
    else
    begin
      pnlSelectedAction.Color := $FEE2E2; // Soft red
      pnlSelectedAction.Font.Color := $991B1B; // Dark red
      pnlSelectedAction.Caption := 'FALHA NO AGENTE';
      
      memRationale.Text := 'OCORREU UM ERRO:' + sLineBreak + FAIAgent.LastError;
    end;

  finally
    Screen.Cursor := crDefault;
  end;
end;

procedure TfrmAgentDemo.btnLoadITScenarioClick(Sender: TObject);
begin
  LoadITAlertScenario;
  ShowMessage('Cenário de Alerta de Infraestrutura e Redes de Servidores Carregado!');
end;

procedure TfrmAgentDemo.btnLoadSupportScenarioClick(Sender: TObject);
begin
  LoadSupportScenario;
  ShowMessage('Cenário de Triagem de Tickets de Clientes Carregado!');
end;

procedure TfrmAgentDemo.OnAgentActionTriggered(Sender: TObject; const AActionName: string; AParams: TStrings);
begin
  { This triggers when decision is executed successfully }
  // We can write to system console or log
end;

procedure TfrmAgentDemo.OnAgentExecuteAction(Sender: TObject; const AActionName: string; AParams: TStrings);
begin
  { Handle physical world simulated action callbacks }
  ShowMessage(Format('🔔 EXECUÇÃO EXTERNA DISPARADA!' + sLineBreak + 
                     'Ação: %s' + sLineBreak + 
                     'Parâmetros carregados: %d', [AActionName, AParams.Count]));
end;

end.
