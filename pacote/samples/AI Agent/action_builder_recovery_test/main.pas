unit main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, StdCtrls,
  ComCtrls, IniFiles, chatgpt, aiagent_actionbuilder, aiagent_memorymap;

type

  { TfrmActionBuilderRecoveryTest }

  TfrmActionBuilderRecoveryTest = class(TForm)
  private
    { UI Controls - Top Config Panel }
    FTopPanel: TPanel;
    FLblTitle: TLabel;

    FLblProvider: TLabel;
    FCbProvider: TComboBox;
    FLblModel: TLabel;
    FCbModel: TComboBox;
    FLblCustomModel: TLabel;
    FEdtCustomModel: TEdit;
    FLblLocalIP: TLabel;
    FEdtLocalIP: TEdit;
    FLblToken: TLabel;
    FEdtToken: TEdit;

    FChkAutoRecover: TCheckBox;
    FBtnSaveConfig: TButton;

    { UI Controls - Left Panel }
    FLeftPanel: TPanel;
    FLblScenarios: TLabel;
    FBtnScenario1: TButton;
    FBtnScenario2: TButton;
    FBtnScenario3: TButton;
    FBtnRunRecovery: TButton;
    FBtnRunStrict: TButton;
    FBtnRunAll: TButton;
    FBtnClear: TButton;

    { UI Controls - Center Workspace Panel }
    FCenterPanel: TPanel;
    FPageControl: TPageControl;
    FTabInput: TTabSheet;
    FTabOutput: TTabSheet;
    FTabDetails: TTabSheet;
    FTabLog: TTabSheet;

    FMemInput: TMemo;
    FMemOutput: TMemo;
    FMemDetails: TMemo;
    FMemLog: TMemo;

    { UI Controls - Bottom Status Bar }
    FBottomPanel: TPanel;
    FStatusLabel: TLabel;

    { Non-visual AI components }
    FChatGPT: TChatGPT;
    FMemoryMap: TAIAgentMemoryMap;
    FActionBuilder: TAIActionBuilderAgent;

    procedure BuildUI;
    procedure AddLog(const AMsg: string);
    procedure SetStatus(const AStatus: string; const AColor: TColor);

    { AppData Persistence Pattern }
    function ConfigFileName: string;
    procedure LoadConfig;
    procedure SaveConfig;

    { Provider & Model Selection }
    procedure CbProviderChange(Sender: TObject);
    function ConfigureChatGPTFromUI: Boolean;

    { Scenario & Execution Handlers }
    procedure BtnScenario1Click(Sender: TObject);
    procedure BtnScenario2Click(Sender: TObject);
    procedure BtnScenario3Click(Sender: TObject);
    procedure BtnRunRecoveryClick(Sender: TObject);
    procedure BtnRunStrictClick(Sender: TObject);
    procedure BtnRunAllClick(Sender: TObject);
    procedure BtnSaveConfigClick(Sender: TObject);
    procedure BtnClearClick(Sender: TObject);
    procedure FormCloseHandler(Sender: TObject; var CloseAction: TCloseAction);
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  end;

var
  frmActionBuilderRecoveryTest: TfrmActionBuilderRecoveryTest;

implementation

constructor TfrmActionBuilderRecoveryTest.Create(AOwner: TComponent);
begin
  inherited CreateNew(AOwner, 0);
  Caption := 'AI Agent - Action Builder Recovery Test Demo';
  Width := 1150;
  Height := 750;
  Position := poScreenCenter;
  OnClose := @FormCloseHandler;

  FChatGPT := TChatGPT.Create(Self);
  FMemoryMap := TAIAgentMemoryMap.Create(Self);
  FActionBuilder := TAIActionBuilderAgent.Create(Self);
  FActionBuilder.ChatGPT := FChatGPT;
  FActionBuilder.MemoryMap := FMemoryMap;

  BuildUI;

  // Carrega configurações persistidas de AppData
  LoadConfig;

  // Carrega cenário inicial padrão
  BtnScenario1Click(nil);

  SetStatus('Pronto. Configurações carregadas de AppData.', clDefault);
  AddLog('Aplicação inicializada com sucesso.');
  AddLog('Arquivo de configuração: ' + ConfigFileName);
end;

destructor TfrmActionBuilderRecoveryTest.Destroy;
begin
  inherited Destroy;
end;

procedure TfrmActionBuilderRecoveryTest.FormCloseHandler(Sender: TObject; var CloseAction: TCloseAction);
begin
  SaveConfig;
end;

function TfrmActionBuilderRecoveryTest.ConfigFileName: string;
var
  BaseDir: string;
begin
  {$IFDEF WINDOWS}
  BaseDir := GetEnvironmentVariable('APPDATA');
  if BaseDir = '' then
    BaseDir := GetAppConfigDir(False);
  BaseDir := IncludeTrailingPathDelimiter(BaseDir) +
    'Maurinsoft' + DirectorySeparator + 'ActionBuilderRecoveryTest';
  {$ELSE}
  BaseDir := IncludeTrailingPathDelimiter(GetUserDir) + '.config' +
    DirectorySeparator + 'maurinsoft' + DirectorySeparator +
    'action_builder_recovery_test';
  {$ENDIF}
  Result := IncludeTrailingPathDelimiter(BaseDir) + 'settings.ini';
end;

procedure TfrmActionBuilderRecoveryTest.LoadConfig;
var
  Ini: TIniFile;
  FileName, SavedProvider, SavedModel: string;
  Idx: Integer;
begin
  FileName := ConfigFileName;

  if FileExists(FileName) then
  begin
    Ini := TIniFile.Create(FileName);
    try
      SavedProvider := Ini.ReadString('LLM', 'Provider', 'OpenAI');
      Idx := FCbProvider.Items.IndexOf(SavedProvider);
      if Idx >= 0 then
      begin
        FCbProvider.ItemIndex := Idx;
        CbProviderChange(nil);
      end;

      SavedModel := Ini.ReadString('LLM', 'Model', '');
      Idx := FCbModel.Items.IndexOf(SavedModel);
      if Idx >= 0 then
        FCbModel.ItemIndex := Idx;

      FEdtCustomModel.Text := Ini.ReadString('LLM', 'CustomModel', '');
      FEdtLocalIP.Text := Ini.ReadString('LLM', 'LocalIP', 'http://localhost:11434');
      FEdtToken.Text := Ini.ReadString('LLM', 'Token', '');
      FChkAutoRecover.Checked := Ini.ReadBool('Agent', 'AutoRecoverInvalidInput', True);
    finally
      Ini.Free;
    end;
  end
  else
  begin
    // Provedor padrão
    FCbProvider.ItemIndex := 0;
    CbProviderChange(nil);
  end;

  // Fallback para variáveis de ambiente se token estiver vazio
  if Trim(FEdtToken.Text) = '' then
  begin
    FEdtToken.Text := GetEnvironmentVariable('OPENAI_API_KEY');
    if Trim(FEdtToken.Text) = '' then
      FEdtToken.Text := GetEnvironmentVariable('CHATGPT_TOKEN');
  end;
end;

procedure TfrmActionBuilderRecoveryTest.SaveConfig;
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
    Ini.WriteString('LLM', 'Provider', FCbProvider.Text);
    Ini.WriteString('LLM', 'Model', FCbModel.Text);
    Ini.WriteString('LLM', 'CustomModel', FEdtCustomModel.Text);
    Ini.WriteString('LLM', 'LocalIP', FEdtLocalIP.Text);
    Ini.WriteString('LLM', 'Token', FEdtToken.Text);
    Ini.WriteBool('Agent', 'AutoRecoverInvalidInput', FChkAutoRecover.Checked);
    Ini.UpdateFile;
  finally
    Ini.Free;
  end;
  AddLog('Configurações salvas em AppData com sucesso.');
end;

procedure TfrmActionBuilderRecoveryTest.BuildUI;
begin
  // 1. Top Panel (Configurações do Modelo, Provedor, URL e API Token)
  FTopPanel := TPanel.Create(Self);
  FTopPanel.Parent := Self;
  FTopPanel.Align := alTop;
  FTopPanel.Height := 95;
  FTopPanel.BevelOuter := bvNone;
  FTopPanel.Color := clBtnFace;

  FLblTitle := TLabel.Create(Self);
  FLblTitle.Parent := FTopPanel;
  FLblTitle.Left := 14;
  FLblTitle.Top := 8;
  FLblTitle.Caption := 'TAIActionBuilderAgent: Configuração do Modelo LLM e Recuperação';
  FLblTitle.Font.Style := [fsBold];
  FLblTitle.Font.Size := 11;

  // Provedor IA
  FLblProvider := TLabel.Create(Self);
  FLblProvider.Parent := FTopPanel;
  FLblProvider.Left := 14;
  FLblProvider.Top := 34;
  FLblProvider.Caption := 'Provedor:';
  FLblProvider.Font.Style := [fsBold];

  FCbProvider := TComboBox.Create(Self);
  FCbProvider.Parent := FTopPanel;
  FCbProvider.Left := 14;
  FCbProvider.Top := 52;
  FCbProvider.Width := 130;
  FCbProvider.Style := csDropDownList;
  FCbProvider.Items.Add('OpenAI');
  FCbProvider.Items.Add('OpenRouter');
  FCbProvider.Items.Add('Cerebras');
  FCbProvider.Items.Add('Local (Ollama)');
  FCbProvider.Items.Add('Google Gemini');
  FCbProvider.Items.Add('Anthropic Claude');
  FCbProvider.Items.Add('DeepSeek');
  FCbProvider.OnChange := @CbProviderChange;

  // Modelo Sugerido
  FLblModel := TLabel.Create(Self);
  FLblModel.Parent := FTopPanel;
  FLblModel.Left := 152;
  FLblModel.Top := 34;
  FLblModel.Caption := 'Modelo:';
  FLblModel.Font.Style := [fsBold];

  FCbModel := TComboBox.Create(Self);
  FCbModel.Parent := FTopPanel;
  FCbModel.Left := 152;
  FCbModel.Top := 52;
  FCbModel.Width := 160;
  FCbModel.Style := csDropDownList;

  // Modelo Customizado
  FLblCustomModel := TLabel.Create(Self);
  FLblCustomModel.Parent := FTopPanel;
  FLblCustomModel.Left := 320;
  FLblCustomModel.Top := 34;
  FLblCustomModel.Caption := 'Modelo Custom:';
  FLblCustomModel.Font.Style := [fsBold];

  FEdtCustomModel := TEdit.Create(Self);
  FEdtCustomModel.Parent := FTopPanel;
  FEdtCustomModel.Left := 320;
  FEdtCustomModel.Top := 52;
  FEdtCustomModel.Width := 120;

  // URL / Local IP
  FLblLocalIP := TLabel.Create(Self);
  FLblLocalIP.Parent := FTopPanel;
  FLblLocalIP.Left := 448;
  FLblLocalIP.Top := 34;
  FLblLocalIP.Caption := 'URL Local / IP:';
  FLblLocalIP.Font.Style := [fsBold];

  FEdtLocalIP := TEdit.Create(Self);
  FEdtLocalIP.Parent := FTopPanel;
  FEdtLocalIP.Left := 448;
  FEdtLocalIP.Top := 52;
  FEdtLocalIP.Width := 150;
  FEdtLocalIP.Text := 'http://localhost:11434';

  // API Token
  FLblToken := TLabel.Create(Self);
  FLblToken.Parent := FTopPanel;
  FLblToken.Left := 606;
  FLblToken.Top := 34;
  FLblToken.Caption := 'Chave API / Token:';
  FLblToken.Font.Style := [fsBold];

  FEdtToken := TEdit.Create(Self);
  FEdtToken.Parent := FTopPanel;
  FEdtToken.Left := 606;
  FEdtToken.Top := 52;
  FEdtToken.Width := 200;
  FEdtToken.PasswordChar := '*';

  // Checkbox AutoRecover
  FChkAutoRecover := TCheckBox.Create(Self);
  FChkAutoRecover.Parent := FTopPanel;
  FChkAutoRecover.Left := 818;
  FChkAutoRecover.Top := 54;
  FChkAutoRecover.Caption := 'AutoRecover';
  FChkAutoRecover.Checked := True;

  // Botão Salvar em AppData
  FBtnSaveConfig := TButton.Create(Self);
  FBtnSaveConfig.Parent := FTopPanel;
  FBtnSaveConfig.Left := 930;
  FBtnSaveConfig.Top := 50;
  FBtnSaveConfig.Width := 170;
  FBtnSaveConfig.Height := 28;
  FBtnSaveConfig.Caption := 'Salvar em AppData';
  FBtnSaveConfig.OnClick := @BtnSaveConfigClick;

  // 2. Left Panel (Cenários e Ações)
  FLeftPanel := TPanel.Create(Self);
  FLeftPanel.Parent := Self;
  FLeftPanel.Align := alLeft;
  FLeftPanel.Width := 240;
  FLeftPanel.BevelOuter := bvNone;

  FLblScenarios := TLabel.Create(Self);
  FLblScenarios.Parent := FLeftPanel;
  FLblScenarios.Left := 12;
  FLblScenarios.Top := 12;
  FLblScenarios.Caption := 'Cenários de Teste:';
  FLblScenarios.Font.Style := [fsBold];

  FBtnScenario1 := TButton.Create(Self);
  FBtnScenario1.Parent := FLeftPanel;
  FBtnScenario1.SetBounds(12, 36, 216, 32);
  FBtnScenario1.Caption := '1. Input Textual Confuso';
  FBtnScenario1.OnClick := @BtnScenario1Click;

  FBtnScenario2 := TButton.Create(Self);
  FBtnScenario2.Parent := FLeftPanel;
  FBtnScenario2.SetBounds(12, 74, 216, 32);
  FBtnScenario2.Caption := '2. Saída Inválida (Validação)';
  FBtnScenario2.OnClick := @BtnScenario2Click;

  FBtnScenario3 := TButton.Create(Self);
  FBtnScenario3.Parent := FLeftPanel;
  FBtnScenario3.SetBounds(12, 112, 216, 32);
  FBtnScenario3.Caption := '3. Teste Livre';
  FBtnScenario3.OnClick := @BtnScenario3Click;

  FBtnRunRecovery := TButton.Create(Self);
  FBtnRunRecovery.Parent := FLeftPanel;
  FBtnRunRecovery.SetBounds(12, 166, 216, 38);
  FBtnRunRecovery.Caption := 'Executar com Recuperação';
  FBtnRunRecovery.Font.Style := [fsBold];
  FBtnRunRecovery.OnClick := @BtnRunRecoveryClick;

  FBtnRunStrict := TButton.Create(Self);
  FBtnRunStrict.Parent := FLeftPanel;
  FBtnRunStrict.SetBounds(12, 210, 216, 32);
  FBtnRunStrict.Caption := 'Executar Estrito (Sem AutoRecover)';
  FBtnRunStrict.OnClick := @BtnRunStrictClick;

  FBtnRunAll := TButton.Create(Self);
  FBtnRunAll.Parent := FLeftPanel;
  FBtnRunAll.SetBounds(12, 248, 216, 32);
  FBtnRunAll.Caption := 'Executar Bateria Completa';
  FBtnRunAll.OnClick := @BtnRunAllClick;

  FBtnClear := TButton.Create(Self);
  FBtnClear.Parent := FLeftPanel;
  FBtnClear.SetBounds(12, 286, 216, 30);
  FBtnClear.Caption := 'Limpar Logs e Resultados';
  FBtnClear.OnClick := @BtnClearClick;

  // 3. Bottom Panel (Status)
  FBottomPanel := TPanel.Create(Self);
  FBottomPanel.Parent := Self;
  FBottomPanel.Align := alBottom;
  FBottomPanel.Height := 32;
  FBottomPanel.BevelOuter := bvLowered;

  FStatusLabel := TLabel.Create(Self);
  FStatusLabel.Parent := FBottomPanel;
  FStatusLabel.Left := 12;
  FStatusLabel.Top := 8;
  FStatusLabel.Caption := 'Status: Pronto';

  // 4. Center Panel (PageControl e Memos)
  FCenterPanel := TPanel.Create(Self);
  FCenterPanel.Parent := Self;
  FCenterPanel.Align := alClient;
  FCenterPanel.BevelOuter := bvNone;

  FPageControl := TPageControl.Create(Self);
  FPageControl.Parent := FCenterPanel;
  FPageControl.Align := alClient;

  FTabInput := TTabSheet.Create(Self);
  FTabInput.PageControl := FPageControl;
  FTabInput.Caption := 'Input do Usuário';

  FMemInput := TMemo.Create(Self);
  FMemInput.Parent := FTabInput;
  FMemInput.Align := alClient;
  FMemInput.ScrollBars := ssAutoBoth;
  FMemInput.Font.Name := 'Consolas';
  FMemInput.Font.Size := 10;

  FTabOutput := TTabSheet.Create(Self);
  FTabOutput.PageControl := FPageControl;
  FTabOutput.Caption := 'Output / Ações Geradas';

  FMemOutput := TMemo.Create(Self);
  FMemOutput.Parent := FTabOutput;
  FMemOutput.Align := alClient;
  FMemOutput.ScrollBars := ssAutoBoth;
  FMemOutput.Font.Name := 'Consolas';
  FMemOutput.Font.Size := 10;

  FTabDetails := TTabSheet.Create(Self);
  FTabDetails.PageControl := FPageControl;
  FTabDetails.Caption := 'Detalhes de Recuperação';

  FMemDetails := TMemo.Create(Self);
  FMemDetails.Parent := FTabDetails;
  FMemDetails.Align := alClient;
  FMemDetails.ScrollBars := ssAutoBoth;
  FMemDetails.Font.Name := 'Consolas';
  FMemDetails.Font.Size := 10;

  FTabLog := TTabSheet.Create(Self);
  FTabLog.PageControl := FPageControl;
  FTabLog.Caption := 'Log de Execução';

  FMemLog := TMemo.Create(Self);
  FMemLog.Parent := FTabLog;
  FMemLog.Align := alClient;
  FMemLog.ScrollBars := ssAutoBoth;
  FMemLog.Font.Name := 'Consolas';
  FMemLog.Font.Size := 10;
end;

procedure TfrmActionBuilderRecoveryTest.AddLog(const AMsg: string);
begin
  FMemLog.Lines.Add(FormatDateTime('hh:nn:ss.zzz', Now) + ' - ' + AMsg);
end;

procedure TfrmActionBuilderRecoveryTest.SetStatus(const AStatus: string; const AColor: TColor);
begin
  FStatusLabel.Caption := 'Status: ' + AStatus;
  FStatusLabel.Font.Color := AColor;
end;

procedure TfrmActionBuilderRecoveryTest.CbProviderChange(Sender: TObject);
var
  Prov: TAIProvider;
begin
  FCbModel.Clear;
  Prov := TAIProvider(FCbProvider.ItemIndex);

  case Prov of
    AIP_OPENAI:
      begin
        FCbModel.Items.Add('gpt-4o');
        FCbModel.Items.Add('gpt-4o-mini');
        FCbModel.Items.Add('o3-mini');
        FCbModel.Items.Add('gpt-3.5-turbo');
        FCbModel.ItemIndex := 1;
        FLblToken.Enabled := True;
        FEdtToken.Enabled := True;
        FLblLocalIP.Enabled := False;
        FEdtLocalIP.Enabled := False;
      end;
    AIP_OPENROUTER:
      begin
        FCbModel.Items.Add('meta-llama/llama-3-8b-instruct:free');
        FCbModel.Items.Add('google/gemma-2-9b-it:free');
        FCbModel.Items.Add('deepseek/deepseek-r1:free');
        FCbModel.Items.Add('meta-llama/llama-3.2-3b-instruct:free');
        FCbModel.ItemIndex := 0;
        FLblToken.Enabled := True;
        FEdtToken.Enabled := True;
        FLblLocalIP.Enabled := False;
        FEdtLocalIP.Enabled := False;
      end;
    AIP_CEREBRAS:
      begin
        FCbModel.Items.Add('qwen-3-235b');
        FCbModel.Items.Add('llama3.1-8b');
        FCbModel.Items.Add('llama3.1-70b');
        FCbModel.ItemIndex := 0;
        FLblToken.Enabled := True;
        FEdtToken.Enabled := True;
        FLblLocalIP.Enabled := False;
        FEdtLocalIP.Enabled := False;
      end;
    AIP_LOCAL:
      begin
        FCbModel.Items.Add('llama3.2:3b');
        FCbModel.Items.Add('qwen2.5:1.5b');
        FCbModel.Items.Add('deepseek-r1:1.5b');
        FCbModel.Items.Add('deepseek-r1:8b');
        FCbModel.ItemIndex := 0;
        FLblToken.Enabled := False;
        FEdtToken.Enabled := False;
        FLblLocalIP.Enabled := True;
        FEdtLocalIP.Enabled := True;
      end;
    AIP_GEMINI:
      begin
        FCbModel.Items.Add('gemini-2.5-flash');
        FCbModel.Items.Add('gemini-2.5-pro');
        FCbModel.Items.Add('gemini-2.0-flash');
        FCbModel.Items.Add('gemini-1.5-flash');
        FCbModel.ItemIndex := 0;
        FLblToken.Enabled := True;
        FEdtToken.Enabled := True;
        FLblLocalIP.Enabled := False;
        FEdtLocalIP.Enabled := False;
      end;
    AIP_CLAUDE:
      begin
        FCbModel.Items.Add('claude-3-5-sonnet-20241022');
        FCbModel.Items.Add('claude-3-5-haiku-20241022');
        FCbModel.Items.Add('claude-3-opus-20240229');
        FCbModel.ItemIndex := 0;
        FLblToken.Enabled := True;
        FEdtToken.Enabled := True;
        FLblLocalIP.Enabled := False;
        FEdtLocalIP.Enabled := False;
      end;
    AIP_DEEPSEEK:
      begin
        FCbModel.Items.Add('deepseek-chat');
        FCbModel.Items.Add('deepseek-reasoner');
        FCbModel.ItemIndex := 0;
        FLblToken.Enabled := True;
        FEdtToken.Enabled := True;
        FLblLocalIP.Enabled := False;
        FEdtLocalIP.Enabled := False;
      end;
  else
    FCbModel.Items.Add('gpt-4o-mini');
    FCbModel.ItemIndex := 0;
  end;
end;

function TfrmActionBuilderRecoveryTest.ConfigureChatGPTFromUI: Boolean;
var
  Prov: TAIProvider;
  ModelIdx: Integer;
  VModel: TVersionChat;
begin
  Result := False;

  if Trim(FCbProvider.Text) = '' then
  begin
    ShowMessage('Selecione o provedor.');
    Exit;
  end;

  Prov := TAIProvider(FCbProvider.ItemIndex);

  if (Prov in [AIP_OPENAI, AIP_OPENROUTER, AIP_CEREBRAS, AIP_GEMINI, AIP_CLAUDE, AIP_DEEPSEEK]) and
     (Trim(FEdtToken.Text) = '') then
  begin
    AddLog('Aviso: Chave API / Token não preenchida para o provedor ' + FCbProvider.Text + '. O teste poderá falhar ou requerer token.');
  end;

  if (Prov = AIP_LOCAL) and (Trim(FEdtLocalIP.Text) = '') then
  begin
    ShowMessage('Por favor, informe a URL Local / IP para o servidor local (ex: http://localhost:11434).');
    Exit;
  end;

  FChatGPT.Provider := Prov;
  FChatGPT.Token := Trim(FEdtToken.Text);
  FChatGPT.LocalIP := Trim(FEdtLocalIP.Text);
  FChatGPT.CustomModel := Trim(FEdtCustomModel.Text);

  ModelIdx := FCbModel.ItemIndex;
  case Prov of
    AIP_OPENAI:
      begin
        if ModelIdx = 0 then VModel := VCT_GPT4o
        else if ModelIdx = 1 then VModel := VCT_GPT4O_MINI
        else if ModelIdx = 2 then VModel := VCT_GPTo3_mini
        else VModel := VCT_GPT35TURBO;
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
        else if ModelIdx = 2 then VModel := VCT_GEMINI_20_FLASH
        else VModel := VCT_GEMINI_15_FLASH;
      end;
    AIP_CLAUDE:
      begin
        if ModelIdx = 0 then VModel := VCT_CLAUDE_35_SONNET
        else if ModelIdx = 1 then VModel := VCT_CLAUDE_35_HAIKU
        else VModel := VCT_CLAUDE_3_OPUS;
      end;
    AIP_DEEPSEEK:
      begin
        if ModelIdx = 0 then VModel := VCT_DEEPSEEK_CHAT
        else VModel := VCT_DEEPSEEK_REASONER;
      end;
  else
    VModel := VCT_GPT4O_MINI;
  end;

  FChatGPT.TipoChat := VModel;
  FActionBuilder.AutoRecoverInvalidInput := FChkAutoRecover.Checked;

  Result := True;
end;

procedure TfrmActionBuilderRecoveryTest.BtnScenario1Click(Sender: TObject);
begin
  FMemInput.Lines.Text :=
    'O processamento gerou um curriculo. Preciso criar o texto e preparar um email para ' +
    'contato@empresa.com com assunto "Envio de Curriculo" contendo o anexo.';
  FPageControl.ActivePage := FTabInput;
  SetStatus('Cenário 1 carregado (Input textual confuso para estruturação de ações).', clDefault);
end;

procedure TfrmActionBuilderRecoveryTest.BtnScenario2Click(Sender: TObject);
begin
  FMemInput.Lines.Text :=
    '{"analysis": "Entendi a tarefa", "result": "Criar documento e email"}';
  FPageControl.ActivePage := FTabInput;
  SetStatus('Cenário 2 carregado (JSON sem actions para teste de validação e recuperação).', clDefault);
end;

procedure TfrmActionBuilderRecoveryTest.BtnScenario3Click(Sender: TObject);
begin
  FMemInput.Lines.Text :=
    'Por favor, leia o arquivo relatorio.txt, filtre as linhas que contém ERRO e envie um alerta via Telegram.';
  FPageControl.ActivePage := FTabInput;
  SetStatus('Cenário 3 carregado (Teste livre).', clDefault);
end;

procedure TfrmActionBuilderRecoveryTest.BtnRunRecoveryClick(Sender: TObject);
var
  InputText, OutputText: string;
  Ok: Boolean;
begin
  if not ConfigureChatGPTFromUI then Exit;

  InputText := Trim(FMemInput.Lines.Text);
  if InputText = '' then
  begin
    ShowMessage('Informe um texto de entrada no memo de input.');
    Exit;
  end;

  SetStatus('Executando com recuperação...', clNavy);
  AddLog('Iniciando BuildActionsWithRecovery com provedor ' + FCbProvider.Text + ' (Modelo: ' + FCbModel.Text + ')...');
  FMemOutput.Clear;
  FMemDetails.Clear;

  Screen.Cursor := crHourGlass;
  try
    Ok := FActionBuilder.BuildActionsWithRecovery(InputText, OutputText);
  finally
    Screen.Cursor := crDefault;
  end;

  FMemOutput.Lines.Text := OutputText;

  FMemDetails.Lines.Add('=== Detalhes da Execução com Recuperação ===');
  FMemDetails.Lines.Add('Provedor: ' + FCbProvider.Text);
  FMemDetails.Lines.Add('Modelo: ' + FCbModel.Text);
  FMemDetails.Lines.Add('AutoRecoverInvalidInput: ' + BoolToStr(FActionBuilder.AutoRecoverInvalidInput, True));
  FMemDetails.Lines.Add('LastValidationError: ' + FActionBuilder.LastValidationError);
  FMemDetails.Lines.Add('');
  FMemDetails.Lines.Add('--- LastRawOutput ---');
  FMemDetails.Lines.Add(FActionBuilder.LastRawOutput);
  FMemDetails.Lines.Add('');
  FMemDetails.Lines.Add('--- LastRecoveredOutput ---');
  FMemDetails.Lines.Add(FActionBuilder.LastRecoveredOutput);

  if Ok then
  begin
    SetStatus('Sucesso na construção das ações!', clGreen);
    AddLog('Sucesso na execução.');
    FPageControl.ActivePage := FTabOutput;
  end
  else
  begin
    SetStatus('Falha: ' + FActionBuilder.LastError, clRed);
    AddLog('Erro: ' + FActionBuilder.LastError);
    FPageControl.ActivePage := FTabDetails;
  end;
end;

procedure TfrmActionBuilderRecoveryTest.BtnRunStrictClick(Sender: TObject);
var
  InputText, OutputText: string;
  Ok: Boolean;
begin
  if not ConfigureChatGPTFromUI then Exit;

  InputText := Trim(FMemInput.Lines.Text);
  if InputText = '' then
  begin
    ShowMessage('Informe um texto de entrada no memo de input.');
    Exit;
  end;

  SetStatus('Executando em modo estrito (sem recuperação)...', clNavy);
  AddLog('Iniciando BuildActionsStrict com provedor ' + FCbProvider.Text + '...');
  FMemOutput.Clear;
  FMemDetails.Clear;

  Screen.Cursor := crHourGlass;
  try
    Ok := FActionBuilder.BuildActionsStrict(InputText, OutputText);
  finally
    Screen.Cursor := crDefault;
  end;

  FMemOutput.Lines.Text := OutputText;

  FMemDetails.Lines.Add('=== Modo Estrito (Sem Recuperação) ===');
  FMemDetails.Lines.Add('Provedor: ' + FCbProvider.Text);
  FMemDetails.Lines.Add('Modelo: ' + FCbModel.Text);
  FMemDetails.Lines.Add('LastValidationError: ' + FActionBuilder.LastValidationError);
  FMemDetails.Lines.Add('');
  FMemDetails.Lines.Add('--- LastRawOutput ---');
  FMemDetails.Lines.Add(FActionBuilder.LastRawOutput);

  if Ok then
  begin
    SetStatus('Sucesso no modo estrito!', clGreen);
    AddLog('Sucesso no modo estrito.');
    FPageControl.ActivePage := FTabOutput;
  end
  else
  begin
    SetStatus('Falha esperada no modo estrito: ' + FActionBuilder.LastError, clMaroon);
    AddLog('Falha em modo estrito: ' + FActionBuilder.LastError);
    FPageControl.ActivePage := FTabDetails;
  end;
end;

procedure TfrmActionBuilderRecoveryTest.BtnRunAllClick(Sender: TObject);
var
  OutText: string;
begin
  if not ConfigureChatGPTFromUI then Exit;

  AddLog('==================================================');
  AddLog('Iniciando Bateria de Testes Automatizados...');

  // Teste 1
  AddLog('Teste 1: Input textual confuso');
  BtnScenario1Click(nil);
  if (FChatGPT.Provider = AIP_LOCAL) or (FChatGPT.Token <> '') then
  begin
    if FActionBuilder.BuildActionsWithRecovery(FMemInput.Lines.Text, OutText) then
      AddLog('  [PASS] Teste 1: Ações geradas com sucesso.')
    else
      AddLog('  [FAIL] Teste 1: ' + FActionBuilder.LastError);
  end
  else
    AddLog('  [SKIP] Teste 1: Sem token de API configurado.');

  // Teste 2
  AddLog('Teste 2: Validação de saída vazia/inválida');
  if not FActionBuilder.BuildActions('', OutText) then
    AddLog('  [PASS] Teste 2: Rejeitou input vazio corretamente: ' + FActionBuilder.LastError)
  else
    AddLog('  [FAIL] Teste 2: Deveria ter rejeitado input vazio.');

  AddLog('Bateria de testes finalizada.');
  AddLog('==================================================');
  SetStatus('Bateria de testes concluída. Veja a aba Log.', clGreen);
  FPageControl.ActivePage := FTabLog;
end;

procedure TfrmActionBuilderRecoveryTest.BtnSaveConfigClick(Sender: TObject);
begin
  SaveConfig;
  ShowMessage('Configurações salvas com sucesso em AppData:' + sLineBreak + ConfigFileName);
end;

procedure TfrmActionBuilderRecoveryTest.BtnClearClick(Sender: TObject);
begin
  FMemOutput.Clear;
  FMemDetails.Clear;
  FMemLog.Clear;
  SetStatus('Resultados e logs limpos.', clDefault);
  AddLog('Logs limpos.');
end;

end.
