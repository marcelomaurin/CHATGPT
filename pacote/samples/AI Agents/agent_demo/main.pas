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

    { Left Sub-components (Agent Config Parameters) }
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

    { Center Sub-components (User Input) }
    gbUserInput: TGroupBox;
    memUserInput: TMemo;
    pnlCommandInput: TPanel;
    btnExecute: TButton;

    { Right Sub-components (Results & Errors) }
    gbResult: TGroupBox;
    memResult: TMemo;
    gbError: TGroupBox;
    memError: TMemo;

    { Non-visual IA components }
    FChatGPT: TCHATGPT;
    FAIAgent: TAIAgent;
    FAIAgentOptions: TAIAgentOptions;
    FAIAgentAction: TAIAgentAction;

    procedure CreateLayout;
    procedure LoadMinimalScenario;
    
    { Action handlers }
    procedure cbProviderChange(Sender: TObject);
    procedure btnExecuteClick(Sender: TObject);
    
    { Callback events }
    procedure OnAgentExecuteAction(Sender: TObject; const AActionName: string; AParams: TStrings);
    procedure ShowAgentResult;
    function ConfigureChatGPTFromUI: Boolean;
  public

  end;

var
  frmAgentDemo: TfrmAgentDemo;

implementation

{$R *.lfm}

{ TfrmAgentDemo }

procedure TfrmAgentDemo.FormCreate(Sender: TObject);
begin
  Caption := 'AI Agent Minimal Demo';
  Width := 1200;
  Height := 750;
  Position := poScreenCenter;

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
  FAIAgentAction.OnExecuteAction := @OnAgentExecuteAction;

  { Design layout }
  CreateLayout;

  { Setup ComboBox selections }
  cbProvider.ItemIndex := 0; // OpenAI
  cbProviderChange(nil);

  { Load default Scenario }
  LoadMinimalScenario;
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
  pnlHeader.BevelOuter := bvNone;
  pnlHeader.BorderWidth := 10;

  with TLabel.Create(Self) do
  begin
    Parent := pnlHeader;
    Align := alClient;
    Alignment := taCenter;
    Layout := tlCenter;
    Caption := 'AI Agent Minimal Demo';
    Font.Size := 13;
    Font.Style := [fsBold];
  end;

  { 2. Provider Config Panel }
  pnlConfig := TPanel.Create(Self);
  pnlConfig.Parent := Self;
  pnlConfig.Align := alTop;
  pnlConfig.Height := 75;
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

  { Left Panel }
  pnlLeft := TPanel.Create(Self);
  pnlLeft.Parent := pnlClient;
  pnlLeft.Align := alLeft;
  pnlLeft.Width := 340;
  pnlLeft.BevelOuter := bvNone;
  pnlLeft.BorderWidth := 8;

  // System Prompt Group
  gbSystemPrompt := TGroupBox.Create(Self);
  gbSystemPrompt.Parent := pnlLeft;
  gbSystemPrompt.Align := alTop;
  gbSystemPrompt.Height := 105;
  gbSystemPrompt.Caption := ' Diretriz do Agente (SystemPrompt) ';
  gbSystemPrompt.Font.Style := [fsBold];
  
  memSystemPrompt := TMemo.Create(Self);
  memSystemPrompt.Parent := gbSystemPrompt;
  memSystemPrompt.Align := alClient;
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
  gbQuestions.Caption := ' Perguntas/Questões (Options.Questions) ';
  gbQuestions.Font.Style := [fsBold];

  memQuestions := TMemo.Create(Self);
  memQuestions.Parent := gbQuestions;
  memQuestions.Align := alClient;
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
  gbContext.Caption := ' Contexto (Options.Context) ';
  gbContext.Font.Style := [fsBold];

  memContext := TMemo.Create(Self);
  memContext.Parent := gbContext;
  memContext.Align := alClient;
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
  gbAllowedActions.Caption := ' Ações Permitidas (AllowedActions) ';
  gbAllowedActions.Font.Style := [fsBold];

  memAllowedActions := TMemo.Create(Self);
  memAllowedActions.Parent := gbAllowedActions;
  memAllowedActions.Align := alClient;
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
  gbParameterDefs.Caption := ' Definição de Parâmetros ';
  gbParameterDefs.Font.Style := [fsBold];

  memParameterDefs := TMemo.Create(Self);
  memParameterDefs.Parent := gbParameterDefs;
  memParameterDefs.Align := alClient;
  memParameterDefs.ScrollBars := ssAutoVertical;

  // Splitter Left
  splitterLeft := TSplitter.Create(Self);
  splitterLeft.Parent := pnlClient;
  splitterLeft.Align := alLeft;

  { Right Panel }
  pnlRight := TPanel.Create(Self);
  pnlRight.Parent := pnlClient;
  pnlRight.Align := alRight;
  pnlRight.Width := 400;
  pnlRight.BevelOuter := bvNone;
  pnlRight.BorderWidth := 8;

  // Result Group
  gbResult := TGroupBox.Create(Self);
  gbResult.Parent := pnlRight;
  gbResult.Align := alClient;
  gbResult.Caption := ' Resultado ';
  gbResult.Font.Style := [fsBold];

  memResult := TMemo.Create(Self);
  memResult.Parent := gbResult;
  memResult.Align := alClient;
  memResult.ReadOnly := True;
  memResult.Font.Name := 'Consolas';
  memResult.ScrollBars := ssAutoVertical;

  pnlSep := TPanel.Create(Self);
  pnlSep.Parent := pnlRight;
  pnlSep.Align := alBottom;
  pnlSep.Height := 8;
  pnlSep.BevelOuter := bvNone;

  // Error Group
  gbError := TGroupBox.Create(Self);
  gbError.Parent := pnlRight;
  gbError.Align := alBottom;
  gbError.Height := 200;
  gbError.Caption := ' Erro ';
  gbError.Font.Color := clRed;
  gbError.Font.Style := [fsBold];

  memError := TMemo.Create(Self);
  memError.Parent := gbError;
  memError.Align := alClient;
  memError.ReadOnly := True;
  memError.Font.Color := clRed;
  memError.Font.Name := 'Consolas';
  memError.ScrollBars := ssAutoVertical;

  // Splitter Right
  splitterRight := TSplitter.Create(Self);
  splitterRight.Parent := pnlClient;
  splitterRight.Align := alRight;

  { Center Panel }
  pnlCenter := TPanel.Create(Self);
  pnlCenter.Parent := pnlClient;
  pnlCenter.Align := alClient;
  pnlCenter.BevelOuter := bvNone;
  pnlCenter.BorderWidth := 8;

  // User Input Group
  gbUserInput := TGroupBox.Create(Self);
  gbUserInput.Parent := pnlCenter;
  gbUserInput.Align := alClient;
  gbUserInput.Caption := ' Entrada do Usuário ';
  gbUserInput.Font.Style := [fsBold];

  memUserInput := TMemo.Create(Self);
  memUserInput.Parent := gbUserInput;
  memUserInput.Align := alClient;
  memUserInput.Font.Size := 11;
  memUserInput.ScrollBars := ssAutoVertical;

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
  pnlCommandInput.BevelOuter := bvNone;
  pnlCommandInput.BorderWidth := 8;

  btnExecute := TButton.Create(Self);
  btnExecute.Parent := pnlCommandInput;
  btnExecute.Align := alClient;
  btnExecute.Caption := 'Executar Agente';
  btnExecute.Font.Style := [fsBold];
  btnExecute.OnClick := @btnExecuteClick;
end;

procedure TfrmAgentDemo.LoadMinimalScenario;
begin
  memSystemPrompt.Text :=
    'Você é um agente de decisão simples. ' +
    'Analise a entrada do usuário e escolha apenas uma ação entre as ações permitidas. ' +
    'Não execute tarefas externas. ' +
    'Retorne somente a decisão, os parâmetros e uma justificativa breve.';

  memQuestions.Clear;
  memQuestions.Lines.Add('Identifique a intenção principal do usuário.');
  memQuestions.Lines.Add('Escolha apenas uma ação permitida.');
  memQuestions.Lines.Add('Explique brevemente a decisão.');

  memContext.Text :=
    'Este é um sample didático. Nenhuma ação externa será executada.';

  memAllowedActions.Clear;
  memAllowedActions.Lines.Add('CREATE_TASK');
  memAllowedActions.Lines.Add('ASK_MORE_INFO');
  memAllowedActions.Lines.Add('IGNORE');

  memParameterDefs.Clear;
  memParameterDefs.Lines.Add('priority: baixa, media ou alta');
  memParameterDefs.Lines.Add('category: trabalho, estudo, pessoal ou outro');
  memParameterDefs.Lines.Add('summary: resumo curto da solicitação');

  memUserInput.Text :=
    'Preciso revisar o relatório antes da reunião de amanhã.';
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

function TfrmAgentDemo.ConfigureChatGPTFromUI: Boolean;
var
  Prov: TAIProvider;
  ModelIdx: Integer;
  VModel: TVersionChat;
begin
  Result := False;

  if Trim(cbProvider.Text) = '' then
  begin
    ShowMessage('Selecione o provedor.');
    Exit;
  end;

  if Trim(cbModel.Text) = '' then
  begin
    ShowMessage('Selecione ou informe o modelo.');
    Exit;
  end;

  Prov := TAIProvider(cbProvider.ItemIndex);
  
  if (Prov in [AIP_OPENAI, AIP_OPENROUTER, AIP_CEREBRAS, AIP_GEMINI, AIP_CLAUDE]) and (Trim(edtToken.Text) = '') then
  begin
    ShowMessage('Por favor, informe a Chave API / Token para o provedor selecionado.');
    Exit;
  end;
  
  if (Prov = AIP_LOCAL) and (Trim(edtLocalIP.Text) = '') then
  begin
    ShowMessage('Por favor, informe a URL Local / IP para o Ollama.');
    Exit;
  end;

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
  
  Result := True;
end;

procedure TfrmAgentDemo.btnExecuteClick(Sender: TObject);
var
  Cmd: string;
  OK: Boolean;
begin
  Cmd := Trim(memUserInput.Text);

  if Cmd = '' then
  begin
    ShowMessage('Informe uma entrada para o agente analisar.');
    Exit;
  end;

  memResult.Clear;
  memError.Clear;

  if not ConfigureChatGPTFromUI then
    Exit;

  Screen.Cursor := crHourGlass;
  try
    FAIAgent.SystemPrompt := memSystemPrompt.Text;
    FAIAgentOptions.Questions.Assign(memQuestions.Lines);
    FAIAgentOptions.Context := memContext.Text;
    FAIAgentAction.AllowedActions.Assign(memAllowedActions.Lines);
    FAIAgentAction.ParameterDefinitions.Assign(memParameterDefs.Lines);

    OK := FAIAgent.Execute(Cmd);

    if OK then
      ShowAgentResult
    else
      memError.Text := FAIAgent.LastError;
  finally
    Screen.Cursor := crDefault;
  end;
end;

procedure TfrmAgentDemo.OnAgentExecuteAction(
  Sender: TObject;
  const AActionName: string;
  AParams: TStrings
);
begin
  memResult.Lines.Add('Evento OnExecuteAction disparado.');
  memResult.Lines.Add('Ação recebida: ' + AActionName);
  memResult.Lines.Add('');
end;

procedure TfrmAgentDemo.ShowAgentResult;
begin
  memResult.Lines.Add('Ação escolhida: ' + FAIAgentAction.SelectedAction);
  memResult.Lines.Add('');

  memResult.Lines.Add('Parâmetros:');
  memResult.Lines.Add(FAIAgentAction.SelectedParameters.Text);
  memResult.Lines.Add('');

  memResult.Lines.Add('Justificativa:');
  memResult.Lines.Add(FAIAgent.LastRationale);
end;

end.
