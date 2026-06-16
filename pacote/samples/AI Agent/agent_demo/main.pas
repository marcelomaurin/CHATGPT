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

    { Left Sub-components (Jarvis Config Parameters) }
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

    { Center Sub-components (Jarvis Chat Terminal) }
    gbChatConsole: TGroupBox;
    memChatConsole: TMemo;
    pnlCommandInput: TPanel;
    edtCommandInput: TEdit;
    btnSendCommand: TButton;
    
    pnlScenarioButtons: TPanel;
    btnLoadReactorScenario: TButton;
    btnLoadSecurityScenario: TButton;

    { Right Sub-components (Outcome Analysis Dashboard) }
    gbResultAction: TGroupBox;
    pnlSelectedAction: TPanel;
    gbSelectedParams: TGroupBox;
    lbSelectedParams: TListBox;
    gbRationale: TGroupBox;
    memRationale: TMemo;
    gbResourceExecution: TGroupBox;
    memResourceExecution: TMemo;

    { Non-visual IA components }
    FChatGPT: TCHATGPT;
    FAIAgent: TAIAgent;
    FAIAgentOptions: TAIAgentOptions;
    FAIAgentAction: TAIAgentAction;
    FAIAgentResource: TAIAgentResource;
    FAIAgentOutput: TAIAgentOutput;

    procedure CreateLayout;
    procedure LoadReactorScenario;
    procedure LoadSecurityScenario;
    procedure AddConsoleLine(const AText: string);
    
    { Action handlers }
    procedure cbProviderChange(Sender: TObject);
    procedure btnSendCommandClick(Sender: TObject);
    procedure edtCommandInputKeyPress(Sender: TObject; var Key: char);
    procedure btnLoadReactorScenarioClick(Sender: TObject);
    procedure btnLoadSecurityScenarioClick(Sender: TObject);
    
    { Callback events }
    procedure OnAgentActionTriggered(Sender: TObject; const AActionName: string; AParams: TStrings);
    procedure OnAgentExecuteAction(Sender: TObject; const AActionName: string; AParams: TStrings);
    procedure OnAgentOutputExecuted(Sender: TObject; const AActionName: string; const AResourceName: string; const ALog: string; ASuccess: Boolean);
  public

  end;

var
  frmAgentDemo: TfrmAgentDemo;

implementation

{$R *.lfm}

{ TfrmAgentDemo }

procedure TfrmAgentDemo.FormCreate(Sender: TObject);
begin
  Caption := '🖥️ J.A.R.V.I.S. - Sistema de Controle de Recursos e Agente Autônomo';
  Width := 1200;
  Height := 750;
  Position := poScreenCenter;
  Color := $0F172A; // Deep dark slate background (Jarvis theme)

  { Instantiate IA Components }
  FChatGPT := TCHATGPT.Create(Self);
  FAIAgent := TAIAgent.Create(Self);
  FAIAgentOptions := TAIAgentOptions.Create(Self);
  FAIAgentAction := TAIAgentAction.Create(Self);
  FAIAgentResource := TAIAgentResource.Create(Self);
  FAIAgentOutput := TAIAgentOutput.Create(Self);

  { Wire IA components together }
  FAIAgent.ChatGPT := FChatGPT;
  FAIAgent.Options := FAIAgentOptions;
  FAIAgent.Action := FAIAgentAction;
  FAIAgentOptions.Action := FAIAgentAction;
  
  { Wire Resource Output system }
  FAIAgentOutput.Action := FAIAgentAction;
  FAIAgentOutput.Resource := FAIAgentResource;

  { Wire events }
  FAIAgent.OnActionTriggered := @OnAgentActionTriggered;
  FAIAgentAction.OnExecuteAction := @OnAgentExecuteAction;
  FAIAgentOutput.OnOutputExecuted := @OnAgentOutputExecuted;

  { Design layout }
  CreateLayout;

  { Populate Mock Resources }
  
  // 1. Email Resource
  with FAIAgentResource.Resources.Add do
  begin
    Name := 'Stark_Email_System';
    ResourceType := artEmail;
    Sender := 'jarvis@starkindustries.com';
    Recipient := 'senhor.tony@stark.com';
    Subject := 'J.A.R.V.I.S. Diagnostic Alert';
  end;

  // 2. File Resource (writes a real log in local disk)
  with FAIAgentResource.Resources.Add do
  begin
    Name := 'Stark_File_Writer';
    ResourceType := artFile;
    FilePath := 'jarvis_system.log';
  end;

  // 3. WhatsApp Resource
  with FAIAgentResource.Resources.Add do
  begin
    Name := 'Stark_WhatsApp_Alert';
    ResourceType := artWhatsApp;
    Recipient := '+5516999999999';
  end;

  // 4. Web API Resource
  with FAIAgentResource.Resources.Add do
  begin
    Name := 'Stark_Mainframe_API';
    ResourceType := artWebAPI;
    APIUrl := 'http://localhost:8080/stark/mainframe';
  end;

  { Configure Action Mappings }
  
  // SEND_EMAIL -> Email system
  with FAIAgentOutput.Mappings.Add do
  begin
    ActionName := 'SEND_EMAIL';
    ResourceName := 'Stark_Email_System';
  end;

  // WRITE_LOG_FILE -> File system
  with FAIAgentOutput.Mappings.Add do
  begin
    ActionName := 'WRITE_LOG_FILE';
    ResourceName := 'Stark_File_Writer';
  end;

  // SEND_WHATSAPP_MSG -> WhatsApp alerts
  with FAIAgentOutput.Mappings.Add do
  begin
    ActionName := 'SEND_WHATSAPP_MSG';
    ResourceName := 'Stark_WhatsApp_Alert';
  end;

  // EXECUTE_WEB_API -> Mainframe API calls
  with FAIAgentOutput.Mappings.Add do
  begin
    ActionName := 'EXECUTE_WEB_API';
    ResourceName := 'Stark_Mainframe_API';
  end;

  { Setup ComboBox selections }
  cbProvider.ItemIndex := 0; // OpenAI
  cbProviderChange(nil);

  { Load default Jarvis Scenario }
  LoadReactorScenario;

  { Pre-fill console welcome message }
  memChatConsole.Clear;
  AddConsoleLine('================================================================================');
  AddConsoleLine('               🔴 J.A.R.V.I.S. INTELIGÊNCIA ARTIFICIAL ATIVA 🔴');
  AddConsoleLine('================================================================================');
  AddConsoleLine('Jarvis: Todos os sistemas estão online, Senhor.');
  AddConsoleLine('Jarvis: Reatores em 100%, conexões seguras restabelecidas.');
  AddConsoleLine('Jarvis: Digite suas ordens no terminal e eu cuidarei dos parâmetros físicos.');
  AddConsoleLine('================================================================================');
  AddConsoleLine('');
end;

procedure TfrmAgentDemo.FormDestroy(Sender: TObject);
begin
  { Self automatically frees owned sub-components }
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
  pnlHeader.Color := $1E293B; // Slate-800
  pnlHeader.BevelOuter := bvNone;
  pnlHeader.BorderWidth := 10;

  with TLabel.Create(Self) do
  begin
    Parent := pnlHeader;
    Align := alClient;
    Alignment := taCenter;
    Layout := tlCenter;
    Caption := '🖥️ J.A.R.V.I.S. - Sistema de Agente Autônomo e Controle de Recursos';
    Font.Color := $38BDF8; // Neon Light Blue
    Font.Size := 13;
    Font.Style := [fsBold];
  end;

  { 2. Provider Config Panel }
  pnlConfig := TPanel.Create(Self);
  pnlConfig.Parent := Self;
  pnlConfig.Align := alTop;
  pnlConfig.Height := 75;
  pnlConfig.Color := $1E293B; // Slate-800
  pnlConfig.BevelOuter := bvNone;
  pnlConfig.BorderWidth := 8;

  // Provider ComboBox
  lblProvider := TLabel.Create(Self);
  lblProvider.Parent := pnlConfig;
  lblProvider.Left := 15;
  lblProvider.Top := 10;
  lblProvider.Caption := 'Provedor IA:';
  lblProvider.Font.Color := $00FFFF; // Neon Cyan
  lblProvider.Font.Style := [fsBold];

  cbProvider := TComboBox.Create(Self);
  cbProvider.Parent := pnlConfig;
  cbProvider.Left := 15;
  cbProvider.Top := 28;
  cbProvider.Width := 140;
  cbProvider.Style := csDropDownList;
  cbProvider.Color := $334155; // Slate-700
  cbProvider.Font.Color := clWhite;
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
  lblModel.Font.Color := $00FFFF;
  lblModel.Font.Style := [fsBold];

  cbModel := TComboBox.Create(Self);
  cbModel.Parent := pnlConfig;
  cbModel.Left := 170;
  cbModel.Top := 28;
  cbModel.Width := 170;
  cbModel.Style := csDropDownList;
  cbModel.Color := $334155;
  cbModel.Font.Color := clWhite;

  // Custom Model Edit
  lblCustomModel := TLabel.Create(Self);
  lblCustomModel.Parent := pnlConfig;
  lblCustomModel.Left := 355;
  lblCustomModel.Top := 10;
  lblCustomModel.Caption := 'Modelo Customizado:';
  lblCustomModel.Font.Color := $00FFFF;
  lblCustomModel.Font.Style := [fsBold];

  edtCustomModel := TEdit.Create(Self);
  edtCustomModel.Parent := pnlConfig;
  edtCustomModel.Left := 355;
  edtCustomModel.Top := 28;
  edtCustomModel.Width := 150;
  edtCustomModel.Color := $334155;
  edtCustomModel.Font.Color := clWhite;

  // Local URL IP
  lblLocalIP := TLabel.Create(Self);
  lblLocalIP.Parent := pnlConfig;
  lblLocalIP.Left := 520;
  lblLocalIP.Top := 10;
  lblLocalIP.Caption := 'URL Local / IP:';
  lblLocalIP.Font.Color := $00FFFF;
  lblLocalIP.Font.Style := [fsBold];

  edtLocalIP := TEdit.Create(Self);
  edtLocalIP.Parent := pnlConfig;
  edtLocalIP.Left := 520;
  edtLocalIP.Top := 28;
  edtLocalIP.Width := 180;
  edtLocalIP.Color := $334155;
  edtLocalIP.Font.Color := clWhite;
  edtLocalIP.Text := 'http://localhost:11434';

  // API Token Key
  lblToken := TLabel.Create(Self);
  lblToken.Parent := pnlConfig;
  lblToken.Left := 715;
  lblToken.Top := 10;
  lblToken.Caption := 'Chave API / Token:';
  lblToken.Font.Color := $00FFFF;
  lblToken.Font.Style := [fsBold];

  edtToken := TEdit.Create(Self);
  edtToken.Parent := pnlConfig;
  edtToken.Left := 715;
  edtToken.Top := 28;
  edtToken.Width := 250;
  edtToken.Color := $334155;
  edtToken.Font.Color := clWhite;
  edtToken.PasswordChar := '*';

  { 3. Main Workspace Area (Client Panel) }
  pnlClient := TPanel.Create(Self);
  pnlClient.Parent := Self;
  pnlClient.Align := alClient;
  pnlClient.BevelOuter := bvNone;

  { Left Panel: Settings Hidden or Folded for sleek look }
  pnlLeft := TPanel.Create(Self);
  pnlLeft.Parent := pnlClient;
  pnlLeft.Align := alLeft;
  pnlLeft.Width := 340;
  pnlLeft.BevelOuter := bvNone;
  pnlLeft.Color := $111827; // Deep Dark Grey-Blue
  pnlLeft.BorderWidth := 8;

  // System Prompt Group
  gbSystemPrompt := TGroupBox.Create(Self);
  gbSystemPrompt.Parent := pnlLeft;
  gbSystemPrompt.Align := alTop;
  gbSystemPrompt.Height := 105;
  gbSystemPrompt.Caption := ' Diretriz J.A.R.V.I.S. (SystemPrompt) ';
  gbSystemPrompt.Font.Color := $38BDF8;
  gbSystemPrompt.Font.Style := [fsBold];
  
  memSystemPrompt := TMemo.Create(Self);
  memSystemPrompt.Parent := gbSystemPrompt;
  memSystemPrompt.Align := alClient;
  memSystemPrompt.Color := $030712;
  memSystemPrompt.Font.Color := clWhite;
  memSystemPrompt.ScrollBars := ssAutoVertical;

  pnlSep := TPanel.Create(Self);
  pnlSep.Parent := pnlLeft;
  pnlSep.Align := alTop;
  pnlSep.Height := 6;
  pnlSep.BevelOuter := bvNone;

  // Questions Group
  gbQuestions := TGroupBox.Create(Self);
  gbQuestions.Parent := pnlLeft;
  gbQuestions.Align := alTop;
  gbQuestions.Height := 115;
  gbQuestions.Caption := ' Análise Cronológica (Options.Questions) ';
  gbQuestions.Font.Color := $38BDF8;
  gbQuestions.Font.Style := [fsBold];

  memQuestions := TMemo.Create(Self);
  memQuestions.Parent := gbQuestions;
  memQuestions.Align := alClient;
  memQuestions.Color := $030712;
  memQuestions.Font.Color := clWhite;
  memQuestions.ScrollBars := ssAutoVertical;

  pnlSep := TPanel.Create(Self);
  pnlSep.Parent := pnlLeft;
  pnlSep.Align := alTop;
  pnlSep.Height := 6;
  pnlSep.BevelOuter := bvNone;

  // Context Group
  gbContext := TGroupBox.Create(Self);
  gbContext.Parent := pnlLeft;
  gbContext.Align := alTop;
  gbContext.Height := 80;
  gbContext.Caption := ' Contexto de Stark (Options.Context) ';
  gbContext.Font.Color := $38BDF8;
  gbContext.Font.Style := [fsBold];

  memContext := TMemo.Create(Self);
  memContext.Parent := gbContext;
  memContext.Align := alClient;
  memContext.Color := $030712;
  memContext.Font.Color := clWhite;
  memContext.ScrollBars := ssAutoVertical;

  pnlSep := TPanel.Create(Self);
  pnlSep.Parent := pnlLeft;
  pnlSep.Align := alTop;
  pnlSep.Height := 6;
  pnlSep.BevelOuter := bvNone;

  // Allowed Actions Group
  gbAllowedActions := TGroupBox.Create(Self);
  gbAllowedActions.Parent := pnlLeft;
  gbAllowedActions.Align := alTop;
  gbAllowedActions.Height := 110;
  gbAllowedActions.Caption := ' Ações do Mainframe (AllowedActions) ';
  gbAllowedActions.Font.Color := $38BDF8;
  gbAllowedActions.Font.Style := [fsBold];

  memAllowedActions := TMemo.Create(Self);
  memAllowedActions.Parent := gbAllowedActions;
  memAllowedActions.Align := alClient;
  memAllowedActions.Color := $030712;
  memAllowedActions.Font.Color := clWhite;
  memAllowedActions.ScrollBars := ssAutoVertical;

  pnlSep := TPanel.Create(Self);
  pnlSep.Parent := pnlLeft;
  pnlSep.Align := alTop;
  pnlSep.Height := 6;
  pnlSep.BevelOuter := bvNone;

  // Parameter Definitions Group
  gbParameterDefs := TGroupBox.Create(Self);
  gbParameterDefs.Parent := pnlLeft;
  gbParameterDefs.Align := alClient;
  gbParameterDefs.Caption := ' Dicionário de Parâmetros ';
  gbParameterDefs.Font.Color := $38BDF8;
  gbParameterDefs.Font.Style := [fsBold];

  memParameterDefs := TMemo.Create(Self);
  memParameterDefs.Parent := gbParameterDefs;
  memParameterDefs.Align := alClient;
  memParameterDefs.Color := $030712;
  memParameterDefs.Font.Color := clWhite;
  memParameterDefs.ScrollBars := ssAutoVertical;

  // Splitter Left
  splitterLeft := TSplitter.Create(Self);
  splitterLeft.Parent := pnlClient;
  splitterLeft.Align := alLeft;
  splitterLeft.Color := $1F2937;

  { Right Panel: Decision Results & Real Logs }
  pnlRight := TPanel.Create(Self);
  pnlRight.Parent := pnlClient;
  pnlRight.Align := alRight;
  pnlRight.Width := 380;
  pnlRight.BevelOuter := bvNone;
  pnlRight.Color := $111827;
  pnlRight.BorderWidth := 8;

  // Result Action Group
  gbResultAction := TGroupBox.Create(Self);
  gbResultAction.Parent := pnlRight;
  gbResultAction.Align := alTop;
  gbResultAction.Height := 200;
  gbResultAction.Caption := ' ⚡ Decisão Estruturada do Jarvis ';
  gbResultAction.Font.Color := $38BDF8;
  gbResultAction.Font.Style := [fsBold];
  gbResultAction.BorderWidth := 5;

  pnlSelectedAction := TPanel.Create(Self);
  pnlSelectedAction.Parent := gbResultAction;
  pnlSelectedAction.Align := alTop;
  pnlSelectedAction.Height := 45;
  pnlSelectedAction.Color := $1E293B;
  pnlSelectedAction.Font.Color := $00FFFF; // Neon Cyan
  pnlSelectedAction.Font.Size := 11;
  pnlSelectedAction.Font.Style := [fsBold];
  pnlSelectedAction.Alignment := taCenter;
  pnlSelectedAction.Caption := 'SISTEMA EM ESPERA';
  pnlSelectedAction.BevelOuter := bvNone;

  gbSelectedParams := TGroupBox.Create(Self);
  gbSelectedParams.Parent := gbResultAction;
  gbSelectedParams.Align := alClient;
  gbSelectedParams.Caption := ' Parâmetros Mapeados pela IA ';
  gbSelectedParams.Font.Color := clWhite;
  gbSelectedParams.Font.Style := [fsBold];

  lbSelectedParams := TListBox.Create(Self);
  lbSelectedParams.Parent := gbSelectedParams;
  lbSelectedParams.Align := alClient;
  lbSelectedParams.Color := $030712;
  lbSelectedParams.Font.Color := $34D399; // Matrix green
  lbSelectedParams.Font.Name := 'Consolas';

  pnlSep := TPanel.Create(Self);
  pnlSep.Parent := pnlRight;
  pnlSep.Align := alBottom;
  pnlSep.Height := 8;
  pnlSep.BevelOuter := bvNone;

  // Physical world resource output logs
  gbResourceExecution := TGroupBox.Create(Self);
  gbResourceExecution.Parent := pnlRight;
  gbResourceExecution.Align := alBottom;
  gbResourceExecution.Height := 170;
  gbResourceExecution.Caption := ' 🌐 Log do Atuador do Mundo Físico ';
  gbResourceExecution.Font.Color := $38BDF8;
  gbResourceExecution.Font.Style := [fsBold];

  memResourceExecution := TMemo.Create(Self);
  memResourceExecution.Parent := gbResourceExecution;
  memResourceExecution.Align := alClient;
  memResourceExecution.ReadOnly := True;
  memResourceExecution.Color := $020617;
  memResourceExecution.Font.Color := $38BDF8; // Cyan logs
  memResourceExecution.Font.Name := 'Consolas';
  memResourceExecution.ScrollBars := ssAutoVertical;

  // Rationale Group
  gbRationale := TGroupBox.Create(Self);
  gbRationale.Parent := pnlRight;
  gbRationale.Align := alClient;
  gbRationale.Caption := ' 🧠 Raciocínio (Rationale) ';
  gbRationale.Font.Color := $38BDF8;
  gbRationale.Font.Style := [fsBold];

  memRationale := TMemo.Create(Self);
  memRationale.Parent := gbRationale;
  memRationale.Align := alClient;
  memRationale.ReadOnly := True;
  memRationale.Color := $020617;
  memRationale.Font.Color := $FBBF24; // Amber yellow
  memRationale.ScrollBars := ssAutoVertical;

  // Splitter Right
  splitterRight := TSplitter.Create(Self);
  splitterRight.Parent := pnlClient;
  splitterRight.Align := alRight;
  splitterRight.Color := $1F2937;

  { Center Panel: Jarvis Terminal Chat Console }
  pnlCenter := TPanel.Create(Self);
  pnlCenter.Parent := pnlClient;
  pnlCenter.Align := alClient;
  pnlCenter.BevelOuter := bvNone;
  pnlCenter.BorderWidth := 8;

  // Chat Console Group
  gbChatConsole := TGroupBox.Create(Self);
  gbChatConsole.Parent := pnlCenter;
  gbChatConsole.Align := alClient;
  gbChatConsole.Caption := ' 🖥️ Console de Diálogo Interativo - J.A.R.V.I.S. Terminal ';
  gbChatConsole.Font.Color := $38BDF8;
  gbChatConsole.Font.Style := [fsBold];

  memChatConsole := TMemo.Create(Self);
  memChatConsole.Parent := gbChatConsole;
  memChatConsole.Align := alClient;
  memChatConsole.ReadOnly := True;
  memChatConsole.Color := $020617; // Cyber black console
  memChatConsole.Font.Color := $34D399; // Neon emerald-400
  memChatConsole.Font.Name := 'Consolas';
  memChatConsole.Font.Size := 10;
  memChatConsole.ScrollBars := ssAutoVertical;

  pnlSep := TPanel.Create(Self);
  pnlSep.Parent := pnlCenter;
  pnlSep.Align := alBottom;
  pnlSep.Height := 8;
  pnlSep.BevelOuter := bvNone;

  // Command Input Panel
  pnlCommandInput := TPanel.Create(Self);
  pnlCommandInput.Parent := pnlCenter;
  pnlCommandInput.Align := alBottom;
  pnlCommandInput.Height := 50;
  pnlCommandInput.Color := $1E293B; // Slate-800
  pnlCommandInput.BevelOuter := bvNone;
  pnlCommandInput.BorderWidth := 8;

  btnSendCommand := TButton.Create(Self);
  btnSendCommand.Parent := pnlCommandInput;
  btnSendCommand.Align := alRight;
  btnSendCommand.Width := 130;
  btnSendCommand.Caption := '⚡ ENVIAR ORDEM';
  btnSendCommand.Font.Style := [fsBold];
  btnSendCommand.OnClick := @btnSendCommandClick;

  edtCommandInput := TEdit.Create(Self);
  edtCommandInput.Parent := pnlCommandInput;
  edtCommandInput.Align := alClient;
  edtCommandInput.Color := $0F172A; // Dark input
  edtCommandInput.Font.Color := clWhite;
  edtCommandInput.Font.Size := 11;
  edtCommandInput.OnKeyPress := @edtCommandInputKeyPress;

  pnlSep := TPanel.Create(Self);
  pnlSep.Parent := pnlCenter;
  pnlSep.Align := alBottom;
  pnlSep.Height := 8;
  pnlSep.BevelOuter := bvNone;

  // Scenario buttons panel
  pnlScenarioButtons := TPanel.Create(Self);
  pnlScenarioButtons.Parent := pnlCenter;
  pnlScenarioButtons.Align := alBottom;
  pnlScenarioButtons.Height := 40;
  pnlScenarioButtons.Color := $111827;
  pnlScenarioButtons.BevelOuter := bvNone;

  btnLoadReactorScenario := TButton.Create(Self);
  btnLoadReactorScenario.Parent := pnlScenarioButtons;
  btnLoadReactorScenario.Align := alLeft;
  btnLoadReactorScenario.Width := 200;
  btnLoadReactorScenario.Caption := '🔴 Reator Arc (Tony Stark)';
  btnLoadReactorScenario.OnClick := @btnLoadReactorScenarioClick;

  btnLoadSecurityScenario := TButton.Create(Self);
  btnLoadSecurityScenario.Parent := pnlScenarioButtons;
  btnLoadSecurityScenario.Align := alLeft;
  btnLoadSecurityScenario.Width := 200;
  btnLoadSecurityScenario.Caption := '🛡️ Protocolo de Segurança';
  btnLoadSecurityScenario.OnClick := @btnLoadSecurityScenarioClick;
end;

procedure TfrmAgentDemo.AddConsoleLine(const AText: string);
begin
  memChatConsole.Lines.Add(AText);
  
  // Auto-scroll memo to bottom
  memChatConsole.SelStart := Length(memChatConsole.Text);
end;

procedure TfrmAgentDemo.LoadReactorScenario;
begin
  memSystemPrompt.Text := 'Você é o J.A.R.V.I.S., assistente autônomo do reator de Tony Stark. Analise ordens do Senhor e dispare ações.';
  
  memQuestions.Clear;
  memQuestions.Lines.Add('1. Extraia o canal de notificação física correto (e-mail, arquivo local ou whatsapp).');
  memQuestions.Lines.Add('2. Se o usuário mandar gravar log ou arquivo, use WRITE_LOG_FILE.');
  memQuestions.Lines.Add('3. Se for reator crítico, marque urgency=alta.');

  memContext.Text := 'Sistemas do Reator Arc Stark carregados. Monitoramento de potência.';

  memAllowedActions.Clear;
  memAllowedActions.Lines.Add('SEND_EMAIL');
  memAllowedActions.Lines.Add('WRITE_LOG_FILE');
  memAllowedActions.Lines.Add('SEND_WHATSAPP_MSG');
  memAllowedActions.Lines.Add('EXECUTE_WEB_API');

  memParameterDefs.Clear;
  memParameterDefs.Lines.Add('recipient: string (email de Tony ou número telefone)');
  memParameterDefs.Lines.Add('file_path: string (nome do arquivo log)');
  memParameterDefs.Lines.Add('subject: string (assunto do email)');
  memParameterDefs.Lines.Add('urgency: string (alta, media, baixa)');
  memParameterDefs.Lines.Add('reason: string (justificativa analítica rápida)');

  edtCommandInput.Text := 'Jarvis, grave um log de segurança no arquivo reator_stark.log reportando oscilação térmica de 48%!';
end;

procedure TfrmAgentDemo.LoadSecurityScenario;
begin
  memSystemPrompt.Text := 'Você é o J.A.R.V.I.S., assistente cibernético responsável pelas barreiras de segurança física e redes das Indústrias Stark.';
  
  memQuestions.Clear;
  memQuestions.Lines.Add('1. Identifique intrusões de redes ou acessos físicos.');
  memQuestions.Lines.Add('2. Para tentativas de força bruta na rede principal, envie alerta via Web API para mainframe.');
  memQuestions.Lines.Add('3. Configure urgência alta caso haja invasão de perímetro.');

  memContext.Text := 'Firewall Stark e monitoramento de câmeras de Ribeirão Preto online.';

  memAllowedActions.Clear;
  memAllowedActions.Lines.Add('SEND_EMAIL');
  memAllowedActions.Lines.Add('SEND_WHATSAPP_MSG');
  memAllowedActions.Lines.Add('EXECUTE_WEB_API');

  memParameterDefs.Clear;
  memParameterDefs.Lines.Add('recipient: string (email de Tony ou telefone)');
  memParameterDefs.Lines.Add('api_url: string (url do endpoint de bloqueio)');
  memParameterDefs.Lines.Add('urgency: string (alta, media, baixa)');
  memParameterDefs.Lines.Add('reason: string (diagnóstico do incidente)');

  edtCommandInput.Text := 'Jarvis, envie um e-mail para pepper.potts@stark.com com o assunto "Invasão no Laboratório" informando urgência máxima!';
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

procedure TfrmAgentDemo.btnSendCommandClick(Sender: TObject);
var
  Prov: TAIProvider;
  ModelIdx: Integer;
  VModel: TVersionChat;
  Cmd: string;
  OK: Boolean;
begin
  Cmd := Trim(edtCommandInput.Text);
  if Cmd = '' then Exit;

  Screen.Cursor := crHourGlass;
  pnlSelectedAction.Color := $1E293B;
  pnlSelectedAction.Font.Color := $00FFFF;
  pnlSelectedAction.Caption := 'JARVIS RACIOCINANDO...';
  lbSelectedParams.Clear;
  memRationale.Clear;
  memResourceExecution.Clear;
  
  AddConsoleLine('Senhor: ' + Cmd);
  AddConsoleLine('Jarvis: Acessando redes neurais e decodificando ordens físicas...');
  
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
    FAIAgentOptions.Questions.Assign(memQuestions.Lines);
    FAIAgentOptions.Context := memContext.Text;
    FAIAgentAction.AllowedActions.Assign(memAllowedActions.Lines);
    FAIAgentAction.ParameterDefinitions.Assign(memParameterDefs.Lines);

    { 3. Execute Decision }
    OK := FAIAgent.Execute(Cmd);

    if OK then
    begin
      pnlSelectedAction.Color := $065F46; // Dark neon green
      pnlSelectedAction.Font.Color := $34D399; // Neon emerald
      pnlSelectedAction.Caption := 'ORDE DE EXECUÇÃO: ' + FAIAgentAction.SelectedAction;
      
      memRationale.Text := FAIAgent.LastRationale;
      
      // Update parameter display list
      lbSelectedParams.Items.Assign(FAIAgentAction.SelectedParameters);
      
      // Append chatbot dialogues inside our conversational UI
      AddConsoleLine('Jarvis: Compreendi sua ordem, Senhor.');
      AddConsoleLine('Jarvis: Ação estruturada resolvida: ' + FAIAgentAction.SelectedAction);
      AddConsoleLine('Jarvis: ' + FAIAgent.LastRationale);
    end
    else
    begin
      pnlSelectedAction.Color := $991B1B; // Deep dark red
      pnlSelectedAction.Font.Color := $FCA5A5;
      pnlSelectedAction.Caption := 'JARVIS ENCONTROU FALHAS';
      
      memRationale.Text := 'Diagnóstico de erro:' + sLineBreak + FAIAgent.LastError;
      
      AddConsoleLine('Jarvis [FALHA]: Não pude decodificar os comandos físicos.');
      AddConsoleLine('Jarvis [DIAGNÓSTICO]: ' + FAIAgent.LastError);
    end;

    edtCommandInput.Text := ''; // Clear input for next order
  finally
    Screen.Cursor := crDefault;
  end;
end;

procedure TfrmAgentDemo.edtCommandInputKeyPress(Sender: TObject; var Key: char);
begin
  if Key = #13 then // Enter key
  begin
    Key := #0; // Prevent beep
    btnSendCommandClick(nil);
  end;
end;

procedure TfrmAgentDemo.btnLoadReactorScenarioClick(Sender: TObject);
begin
  LoadReactorScenario;
  AddConsoleLine('Jarvis: Cenário "Reator Arc de Tony Stark" ativado. Sistemas de monitoramento e escrita de arquivos reator_stark.log prontos.');
end;

procedure TfrmAgentDemo.btnLoadSecurityScenarioClick(Sender: TObject);
begin
  LoadSecurityScenario;
  AddConsoleLine('Jarvis: Cenário "Protocolo de Segurança Stark" ativado. Defesas contra força bruta de rede e bloqueios IP Mainframe prontos.');
end;

procedure TfrmAgentDemo.OnAgentActionTriggered(Sender: TObject; const AActionName: string; AParams: TStrings);
begin
end;

procedure TfrmAgentDemo.OnAgentExecuteAction(Sender: TObject; const AActionName: string; AParams: TStrings);
begin
end;

procedure TfrmAgentDemo.OnAgentOutputExecuted(Sender: TObject; const AActionName: string; const AResourceName: string; const ALog: string; ASuccess: Boolean);
var
  StatusStr: string;
begin
  if ASuccess then
    StatusStr := 'SUCESSO'
  else
    StatusStr := 'FALHA';

  memResourceExecution.Clear;
  memResourceExecution.Lines.Add('=== PROCESSAMENTO DE REDE FÍSICA ===');
  memResourceExecution.Lines.Add('Decisão: ' + AActionName);
  memResourceExecution.Lines.Add('Atuador Mapeado: ' + AResourceName);
  memResourceExecution.Lines.Add('Resultado: ' + StatusStr);
  memResourceExecution.Lines.Add('');
  memResourceExecution.Lines.Add('--- REGISTRO FÍSICO DO ATUADOR ---');
  memResourceExecution.Lines.Add(ALog);
  
  // Append actuator logging directly inside the chat timeline
  AddConsoleLine('Jarvis [EXECUÇÃO FÍSICA]: Atuador "' + AResourceName + '" disparado. Status: ' + StatusStr);
  AddConsoleLine('--------------------------------------------------------------------------------');
  AddConsoleLine('');
end;

end.
