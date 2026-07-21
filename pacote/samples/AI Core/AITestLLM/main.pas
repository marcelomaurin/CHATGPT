unit main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, StdCtrls,
  ComCtrls, Grids, TypInfo, IniFiles, fpjson, jsonparser, chatgpt, aibase;

type

  { TfrmMain }

  TfrmMain = class(TForm)
    // PageControl e Abas
    pgcMain: TPageControl;
    tsConfig: TTabSheet;
    tsQuestions: TTabSheet;
    tsCRUD: TTabSheet;
    tsRun: TTabSheet;
    tsLog: TTabSheet;

    // Componentes Aba 1 (Config)
    lblTitle: TLabel;
    lblProvider: TLabel;
    cbProvider: TComboBox;
    lblModel: TLabel;
    cbModel: TComboBox;
    lblCustomModel: TLabel;
    edtCustomModel: TEdit;
    lblURL: TLabel;
    edtURL: TEdit;
    lblLocalIP: TLabel;
    edtLocalIP: TEdit;
    lblToken: TLabel;
    edtToken: TEdit;
    lblMaxTokens: TLabel;
    edtMaxTokens: TEdit;
    chkUseLLMValidation: TCheckBox;
    lblValidationPrompt: TLabel;
    memValidationPrompt: TMemo;
    btnSaveConfig: TButton;

    // Componentes Aba 2 (Questions)
    lblJSONFile: TLabel;
    edtJSONFile: TEdit;
    btnSelectJSON: TButton;
    gridTests: TStringGrid;
    btnReloadJSON: TButton;

    // Componentes Aba 3 (CRUD)
    lblDescricao: TLabel;
    edtDescricao: TEdit;
    lblDEV: TLabel;
    memDEV: TMemo;
    lblPROMPT: TLabel;
    memPROMPT: TMemo;
    lblResposta: TLabel;
    memResposta: TMemo;
    lblRespostasValidas: TLabel;
    edtRespostasValidas: TEdit;
    btnNew: TButton;
    btnAdd: TButton;
    btnUpdate: TButton;
    btnDelete: TButton;
    btnSaveJSON: TButton;

    // Componentes Aba 4 (Run)
    btnRunTests: TButton;
    btnStopTests: TButton;
    progressBar: TProgressBar;
    lblProgress: TLabel;
    gridResults: TStringGrid;
    pnlReport: TPanel;
    lblTotal: TLabel;
    lblAcertos: TLabel;
    lblErros: TLabel;
    lblAssertividade: TLabel;

    // Componentes Aba 5 (Log)
    memLog: TMemo;
    btnClearLog: TButton;

    // Componentes não visuais no formulário
    ChatGPT1: TCHATGPT;
    OpenDialog1: TOpenDialog;

    // Eventos
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure cbProviderChange(Sender: TObject);
    procedure chkUseLLMValidationChange(Sender: TObject);
    procedure btnSaveConfigClick(Sender: TObject);
    procedure btnSelectJSONClick(Sender: TObject);
    procedure btnReloadJSONClick(Sender: TObject);
    procedure gridTestsSelection(Sender: TObject; aCol, aRow: Integer);
    procedure btnNewClick(Sender: TObject);
    procedure btnAddClick(Sender: TObject);
    procedure btnUpdateClick(Sender: TObject);
    procedure btnDeleteClick(Sender: TObject);
    procedure btnSaveJSONClick(Sender: TObject);
    procedure btnRunTestsClick(Sender: TObject);
    procedure btnStopTestsClick(Sender: TObject);
    procedure btnClearLogClick(Sender: TObject);

  private
    FStopExecution: Boolean;
    procedure AddLog(const AMsg: string);
    procedure OnComponentLog(Sender: TObject; Level: TAILogLevel; const Message: string);
    function GetConfigFilename: string;
    procedure SaveConfig;
    procedure LoadConfig;
    procedure PopulateProviders;
    procedure PopulateModels(AProvider: TAIProvider);
    procedure LoadJSON(const AFileName: string);
    procedure SaveJSON(const AFileName: string);
    function CleanString(const S: string): string;

  public

  end;

var
  frmMain: TfrmMain;

implementation

{$R *.lfm}

{ Helpers de JSON para garantir compatibilidade entre versões do FPC }
function GetJSONString(AObj: TJSONObject; const AName: string): string;
var
  Data: TJSONData;
begin
  Result := '';
  if AObj = nil then Exit;
  Data := AObj.Find(AName);
  if Data <> nil then
  begin
    if Data.JSONType = jtString then
      Result := Data.AsString
    else
      Result := Data.Value;
  end;
end;

{ TfrmMain }

procedure TfrmMain.FormCreate(Sender: TObject);
begin
  AddLog('AITestLLM Inicializado.');
  FStopExecution := False;

  // Registrar manipulador de log do componente ChatGPT1
  ChatGPT1.OnLog := @OnComponentLog;

  // Configurar cabeçalhos das tabelas
  gridTests.Cells[0, 0] := 'Descrição (Resumo)';
  gridTests.Cells[1, 0] := 'DEV (System Prompt)';
  gridTests.Cells[2, 0] := 'PROMPT (Pergunta)';
  gridTests.Cells[3, 0] := 'Resposta Esperada';
  gridTests.Cells[4, 0] := 'Respostas Válidas';

  gridResults.Cells[0, 0] := 'Descrição';
  gridResults.Cells[1, 0] := 'Status';
  gridResults.Cells[2, 0] := 'Esperada';
  gridResults.Cells[3, 0] := 'Obtida';
  gridResults.Cells[4, 0] := 'Comparação';

  PopulateProviders;

  // Carregar Configurações do INI
  LoadConfig;
end;

procedure TfrmMain.FormDestroy(Sender: TObject);
begin
  // A destruição de componentes criados na LFM é gerenciada automaticamente pelo Lazarus
end;

procedure TfrmMain.AddLog(const AMsg: string);
begin
  memLog.Lines.Add(FormatDateTime('yyyy-mm-dd hh:nn:ss.zzz', Now) + ' - ' + AMsg);
  // Rolagem automática
  memLog.SelStart := Length(memLog.Lines.Text);
end;

procedure TfrmMain.OnComponentLog(Sender: TObject; Level: TAILogLevel; const Message: string);
var
  LevelStr: string;
begin
  case Level of
    llDebug: LevelStr := '[DEBUG]';
    llInfo: LevelStr := '[INFO]';
    llWarning: LevelStr := '[WARNING]';
    llError: LevelStr := '[ERROR]';
  end;
  AddLog('ChatGPT Lib: ' + LevelStr + ' ' + Message);
end;

function TfrmMain.GetConfigFilename: string;
begin
  // Salva no mesmo diretório do executável para facilitar a portabilidade
  Result := ExtractFilePath(ParamStr(0)) + 'config.ini';
end;

procedure TfrmMain.PopulateProviders;
var
  Prov: TAIProvider;
  S: string;
begin
  cbProvider.Items.Clear;
  for Prov := Low(TAIProvider) to High(TAIProvider) do
  begin
    case Prov of
      AIP_OPENAI: S := 'OpenAI';
      AIP_OPENROUTER: S := 'OpenRouter';
      AIP_CEREBRAS: S := 'Cerebras';
      AIP_LOCAL: S := 'Local / Ollama';
      AIP_GEMINI: S := 'Google Gemini';
      AIP_CLAUDE: S := 'Anthropic Claude';
    else
      S := GetEnumName(TypeInfo(TAIProvider), Ord(Prov));
    end;
    cbProvider.Items.AddObject(S, TObject(Pointer(Prov)));
  end;
end;

procedure TfrmMain.PopulateModels(AProvider: TAIProvider);
begin
  cbModel.Items.Clear;
  case AProvider of
    AIP_OPENAI:
    begin
      cbModel.Items.AddObject('gpt-4o', TObject(Pointer(VCT_GPT4o)));
      cbModel.Items.AddObject('gpt-4o-mini', TObject(Pointer(VCT_GPT4O_MINI)));
      cbModel.Items.AddObject('o3-mini', TObject(Pointer(VCT_GPTo3_mini)));
      cbModel.Items.AddObject('gpt-4', TObject(Pointer(VCT_GPT40)));
      cbModel.Items.AddObject('gpt-4-turbo', TObject(Pointer(VCT_GPT40_TURBO)));
      cbModel.Items.AddObject('o1', TObject(Pointer(VCT_GPTo1)));
      cbModel.Items.AddObject('o1-mini', TObject(Pointer(VCT_GPTo1_mini)));
      cbModel.Items.AddObject('o1-preview', TObject(Pointer(VCT_GPTo1_preview)));
      cbModel.Items.AddObject('gpt-3.5-turbo', TObject(Pointer(VCT_GPT35TURBO)));
      cbModel.Items.AddObject('[Customizado]', TObject(Pointer(VCT_CUSTOM)));
      cbModel.ItemIndex := 1; // gpt-4o-mini
    end;
    AIP_GEMINI:
    begin
      cbModel.Items.AddObject('gemini-2.5-flash', TObject(Pointer(VCT_GEMINI_25_FLASH)));
      cbModel.Items.AddObject('gemini-2.5-pro', TObject(Pointer(VCT_GEMINI_25_PRO)));
      cbModel.Items.AddObject('gemini-2.0-flash', TObject(Pointer(VCT_GEMINI_20_FLASH)));
      cbModel.Items.AddObject('[Customizado]', TObject(Pointer(VCT_CUSTOM)));
      cbModel.ItemIndex := 0; // gemini-2.5-flash
    end;
    AIP_CLAUDE:
    begin
      cbModel.Items.AddObject('claude-3-5-sonnet', TObject(Pointer(VCT_CLAUDE_35_SONNET)));
      cbModel.Items.AddObject('claude-3-5-haiku', TObject(Pointer(VCT_CLAUDE_35_HAIKU)));
      cbModel.Items.AddObject('claude-3-opus', TObject(Pointer(VCT_CLAUDE_3_OPUS)));
      cbModel.Items.AddObject('[Customizado]', TObject(Pointer(VCT_CUSTOM)));
      cbModel.ItemIndex := 0; // claude-3-5-sonnet
    end;
    AIP_OPENROUTER:
    begin
      cbModel.Items.AddObject('deepseek/deepseek-r1:free', TObject(Pointer(VCT_OPENROUTER_DEEPSEEK_R1_FREE)));
      cbModel.Items.AddObject('meta-llama/llama-3.2-3b-instruct:free', TObject(Pointer(VCT_OPENROUTER_LLAMA32_3B_FREE)));
      cbModel.Items.AddObject('meta-llama/llama-3-8b-instruct:free', TObject(Pointer(VCT_OPENROUTER_LLAMA3_8B_FREE)));
      cbModel.Items.AddObject('google/gemma-2-9b-it:free', TObject(Pointer(VCT_OPENROUTER_GEMMA2_9B_FREE)));
      cbModel.Items.AddObject('[Customizado]', TObject(Pointer(VCT_CUSTOM)));
      cbModel.ItemIndex := 0; // deepseek r1 free
    end;
    AIP_CEREBRAS:
    begin
      cbModel.Items.AddObject('qwen-3-235b-instruct', TObject(Pointer(VCT_CUSTOM)));
      cbModel.ItemIndex := 0;
    end;
    AIP_LOCAL:
    begin
      cbModel.Items.AddObject('deepseek-r1:1.5b', TObject(Pointer(VCT_DEEPSEEK_R1_1_5b)));
      cbModel.Items.AddObject('deepseek-r1:7b', TObject(Pointer(VCT_DEEPSEEK_R1_7b)));
      cbModel.Items.AddObject('deepseek-r1:8b', TObject(Pointer(VCT_DEEPSEEK_R1_8B)));
      cbModel.Items.AddObject('llama3.2:3b', TObject(Pointer(VCT_LLAMA32_3B)));
      cbModel.Items.AddObject('qwen2.5:1.5b', TObject(Pointer(VCT_QWEN25_15B)));
      cbModel.Items.AddObject('[Customizado]', TObject(Pointer(VCT_CUSTOM)));
      cbModel.ItemIndex := 0;
    end;
  end;
end;

procedure TfrmMain.cbProviderChange(Sender: TObject);
var
  Prov: TAIProvider;
begin
  if cbProvider.ItemIndex = -1 then Exit;
  Prov := TAIProvider(Pointer(cbProvider.Items.Objects[cbProvider.ItemIndex]));
  PopulateModels(Prov);
end;

procedure TfrmMain.chkUseLLMValidationChange(Sender: TObject);
begin
  memValidationPrompt.Enabled := chkUseLLMValidation.Checked;
end;

procedure TfrmMain.SaveConfig;
var
  Ini: TIniFile;
begin
  Ini := TIniFile.Create(GetConfigFilename);
  try
    Ini.WriteInteger('LLM', 'Provider', cbProvider.ItemIndex);
    Ini.WriteInteger('LLM', 'ModelIndex', cbModel.ItemIndex);
    Ini.WriteString('LLM', 'CustomModel', edtCustomModel.Text);
    Ini.WriteString('LLM', 'URL', edtURL.Text);
    Ini.WriteString('LLM', 'LocalIP', edtLocalIP.Text);
    Ini.WriteString('LLM', 'Token', edtToken.Text);
    Ini.WriteString('LLM', 'MaxTokens', edtMaxTokens.Text);
    Ini.WriteBool('Validation', 'UseLLMEval', chkUseLLMValidation.Checked);
    Ini.WriteString('Validation', 'Prompt', memValidationPrompt.Lines.Text);
    Ini.WriteString('Files', 'LastJSON', edtJSONFile.Text);
    AddLog('Configurações salvas em: ' + GetConfigFilename);
  finally
    Ini.Free;
  end;
end;

procedure TfrmMain.LoadConfig;
var
  Ini: TIniFile;
  ValPromptDefault: string;
  SavedJson: string;
begin
  if not FileExists(GetConfigFilename) then
  begin
    cbProvider.ItemIndex := 0;
    cbProviderChange(nil);
    Exit;
  end;

  Ini := TIniFile.Create(GetConfigFilename);
  try
    cbProvider.ItemIndex := Ini.ReadInteger('LLM', 'Provider', 0);
    cbProviderChange(nil); // popula os modelos da engine correspondente

    cbModel.ItemIndex := Ini.ReadInteger('LLM', 'ModelIndex', 0);
    edtCustomModel.Text := Ini.ReadString('LLM', 'CustomModel', '');
    edtURL.Text := Ini.ReadString('LLM', 'URL', '');
    edtLocalIP.Text := Ini.ReadString('LLM', 'LocalIP', 'http://localhost:11434');
    edtToken.Text := Ini.ReadString('LLM', 'Token', '');
    edtMaxTokens.Text := Ini.ReadString('LLM', 'MaxTokens', '4096');

    chkUseLLMValidation.Checked := Ini.ReadBool('Validation', 'UseLLMEval', False);
    chkUseLLMValidationChange(nil);

    ValPromptDefault := 'Você é um avaliador de correspondência de respostas. Responda apenas "SIM" ou "NAO".' + #13#10 +
                        'Sua função é analisar se a resposta obtida pela LLM atende semanticamente ao que era esperado pelo teste.';
    memValidationPrompt.Lines.Text := Ini.ReadString('Validation', 'Prompt', ValPromptDefault);

    SavedJson := Ini.ReadString('Files', 'LastJSON', '');
    if (SavedJson <> '') and FileExists(SavedJson) then
    begin
      edtJSONFile.Text := SavedJson;
      LoadJSON(SavedJson);
    end;

    AddLog('Configurações carregadas de: ' + GetConfigFilename);
  finally
    Ini.Free;
  end;
end;

procedure TfrmMain.btnSaveConfigClick(Sender: TObject);
begin
  SaveConfig;
  ShowMessage('Configurações salvas com sucesso.');
end;

procedure TfrmMain.btnSelectJSONClick(Sender: TObject);
begin
  if OpenDialog1.Execute then
  begin
    edtJSONFile.Text := OpenDialog1.FileName;
    LoadJSON(OpenDialog1.FileName);
    SaveConfig; // Salva o último JSON carregado
  end;
end;

procedure TfrmMain.btnReloadJSONClick(Sender: TObject);
begin
  if (edtJSONFile.Text <> '') and FileExists(edtJSONFile.Text) then
    LoadJSON(edtJSONFile.Text)
  else
    ShowMessage('Selecione um arquivo JSON válido primeiro.');
end;

procedure TfrmMain.LoadJSON(const AFileName: string);
var
  FileStream: TFileStream;
  Parser: TJSONParser;
  JSONData: TJSONData;
  JSONArray: TJSONArray;
  JSONObj: TJSONObject;
  I: Integer;
  RowIndex: Integer;
begin
  if not FileExists(AFileName) then Exit;

  gridTests.RowCount := 1; // Reseta as linhas mantendo o cabeçalho

  FileStream := TFileStream.Create(AFileName, fmOpenRead or fmShareDenyWrite);
  Parser := TJSONParser.Create(FileStream);
  try
    try
      JSONData := Parser.Parse;
      try
        if JSONData.JSONType = jtArray then
        begin
          JSONArray := TJSONArray(JSONData);
          gridTests.RowCount := JSONArray.Count + 1;
          for I := 0 to JSONArray.Count - 1 do
          begin
            RowIndex := I + 1;
            JSONObj := JSONArray.Objects[I];
            gridTests.Cells[0, RowIndex] := GetJSONString(JSONObj, 'Descricao');
            gridTests.Cells[1, RowIndex] := GetJSONString(JSONObj, 'DEV');
            gridTests.Cells[2, RowIndex] := GetJSONString(JSONObj, 'PROMPT');
            gridTests.Cells[3, RowIndex] := GetJSONString(JSONObj, 'Resposta');
            gridTests.Cells[4, RowIndex] := GetJSONString(JSONObj, 'RespostasValidas');
          end;
          AddLog('Carregados ' + IntToStr(JSONArray.Count) + ' testes do arquivo JSON.');
        end
        else
        begin
          AddLog('Erro: O arquivo JSON deve ter um Array na raiz.');
          ShowMessage('Formato inválido: O arquivo JSON precisa ser um Array na raiz.');
        end;
      finally
        JSONData.Free;
      end;
    except
      on E: Exception do
      begin
        AddLog('Erro de interpretador JSON: ' + E.Message);
        ShowMessage('Erro ao abrir arquivo JSON: ' + E.Message);
      end;
    end;
  finally
    Parser.Free;
    FileStream.Free;
  end;
end;

procedure TfrmMain.SaveJSON(const AFileName: string);
var
  JSONArray: TJSONArray;
  JSONObj: TJSONObject;
  I: Integer;
  FileStream: TFileStream;
  JSONString: string;
begin
  if Trim(AFileName) = '' then
  begin
    ShowMessage('Selecione ou crie um arquivo JSON primeiro.');
    Exit;
  end;

  JSONArray := TJSONArray.Create;
  try
    for I := 1 to gridTests.RowCount - 1 do
    begin
      // Ignora linhas totalmente vazias
      if (Trim(gridTests.Cells[0, I]) = '') and 
         (Trim(gridTests.Cells[2, I]) = '') then
        Continue;

      JSONObj := TJSONObject.Create;
      JSONObj.Add('Descricao', gridTests.Cells[0, I]);
      JSONObj.Add('DEV', gridTests.Cells[1, I]);
      JSONObj.Add('PROMPT', gridTests.Cells[2, I]);
      JSONObj.Add('Resposta', gridTests.Cells[3, I]);
      JSONObj.Add('RespostasValidas', gridTests.Cells[4, I]);
      JSONArray.Add(JSONObj);
    end;

    JSONString := JSONArray.FormatJSON;

    FileStream := TFileStream.Create(AFileName, fmCreate);
    try
      FileStream.WriteBuffer(Pointer(JSONString)^, Length(JSONString));
    finally
      FileStream.Free;
    end;

    AddLog('Gravados ' + IntToStr(JSONArray.Count) + ' registros no arquivo: ' + AFileName);
  finally
    JSONArray.Free;
  end;
end;

procedure TfrmMain.gridTestsSelection(Sender: TObject; aCol, aRow: Integer);
begin
  if (aRow > 0) and (aRow < gridTests.RowCount) then
  begin
    edtDescricao.Text := gridTests.Cells[0, aRow];
    memDEV.Text       := gridTests.Cells[1, aRow];
    memPROMPT.Text    := gridTests.Cells[2, aRow];
    memResposta.Text  := gridTests.Cells[3, aRow];
    edtRespostasValidas.Text := gridTests.Cells[4, aRow];
  end;
end;

procedure TfrmMain.btnNewClick(Sender: TObject);
begin
  edtDescricao.Clear;
  memDEV.Clear;
  memPROMPT.Clear;
  memResposta.Clear;
  edtRespostasValidas.Clear;
  edtDescricao.SetFocus;
end;

procedure TfrmMain.btnAddClick(Sender: TObject);
var
  NewRow: Integer;
begin
  gridTests.RowCount := gridTests.RowCount + 1;
  NewRow := gridTests.RowCount - 1;

  gridTests.Cells[0, NewRow] := edtDescricao.Text;
  gridTests.Cells[1, NewRow] := memDEV.Text;
  gridTests.Cells[2, NewRow] := memPROMPT.Text;
  gridTests.Cells[3, NewRow] := memResposta.Text;
  gridTests.Cells[4, NewRow] := edtRespostasValidas.Text;
 
  gridTests.Row := NewRow;
  AddLog('Registro adicionado na tabela.');
end;

procedure TfrmMain.btnUpdateClick(Sender: TObject);
var
  SelRow: Integer;
begin
  SelRow := gridTests.Row;
  if SelRow > 0 then
  begin
    gridTests.Cells[0, SelRow] := edtDescricao.Text;
    gridTests.Cells[1, SelRow] := memDEV.Text;
    gridTests.Cells[2, SelRow] := memPROMPT.Text;
    gridTests.Cells[3, SelRow] := memResposta.Text;
    gridTests.Cells[4, SelRow] := edtRespostasValidas.Text;
    AddLog('Registro alterado na linha: ' + IntToStr(SelRow));
  end
  else
    ShowMessage('Selecione uma linha da tabela de testes para alterar.');
end;

procedure TfrmMain.btnDeleteClick(Sender: TObject);
var
  SelRow: Integer;
begin
  SelRow := gridTests.Row;
  if SelRow > 0 then
  begin
    gridTests.DeleteRow(SelRow);
    AddLog('Registro deletado da linha: ' + IntToStr(SelRow));
    btnNewClick(nil);
  end
  else
    ShowMessage('Selecione uma linha da tabela de testes para deletar.');
end;

procedure TfrmMain.btnSaveJSONClick(Sender: TObject);
begin
  if edtJSONFile.Text = '' then
  begin
    // Caso não tenha arquivo, abre dialog de salvar
    with TSaveDialog.Create(nil) do
    try
      DefaultExt := '.json';
      Filter := 'Arquivos JSON (*.json)|*.json|Todos os Arquivos (*.*)|*.*';
      if Execute then
      begin
        edtJSONFile.Text := FileName;
        SaveJSON(FileName);
        SaveConfig;
      end;
    finally
      Free;
    end;
  end
  else
  begin
    SaveJSON(edtJSONFile.Text);
    ShowMessage('Tabela gravada no arquivo JSON.');
  end;
end;

function TfrmMain.CleanString(const S: string): string;
var
  I: Integer;
  C: Char;
begin
  Result := '';
  for I := 1 to Length(S) do
  begin
    C := S[I];
    if (C >= 'a') and (C <= 'z') then
      Result := Result + C
    else if (C >= 'A') and (C <= 'Z') then
      Result := Result + LowerCase(C)
    else if (C >= '0') and (C <= '9') then
      Result := Result + C;
  end;
end;

procedure TfrmMain.btnRunTestsClick(Sender: TObject);
var
  I: Integer;
  TotalTests: Integer;
  SuccessCount: Integer;
  FailureCount: Integer;
  Assertividade: Double;
  
  // Controle de Retentativas
  Attempts: Integer;
  DoneCall: Boolean;
  ErrorMsg: string;

  // Dados do Teste
  Desc, DevPrompt, PromptText, Expected: string;
  RespostasValidas: string;
  ValidList: TStringList;
  IsValidFormat: Boolean;
  J: Integer;
  ActualResponse: string;
  IsMatch: Boolean;
  ValResponse: string;

  // Credenciais
  SelectedProv: TAIProvider;
  SelectedModel: TVersionChat;
begin
  if gridTests.RowCount <= 1 then
  begin
    ShowMessage('Nenhum teste disponível. Carregue um JSON ou adicione registros.');
    Exit;
  end;

  if cbProvider.ItemIndex = -1 then
  begin
    ShowMessage('Selecione um Provedor de LLM na aba de Configuração.');
    Exit;
  end;

  // Preparar os botões e estado
  FStopExecution := False;
  btnRunTests.Enabled := False;
  btnStopTests.Enabled := True;
  
  TotalTests := gridTests.RowCount - 1;
  SuccessCount := 0;
  FailureCount := 0;

  progressBar.Max := TotalTests;
  progressBar.Position := 0;

  // Preparar grid de resultados
  gridResults.RowCount := gridTests.RowCount;
  for I := 1 to TotalTests do
  begin
    gridResults.Cells[0, I] := gridTests.Cells[0, I];
    gridResults.Cells[1, I] := 'Pendente';
    gridResults.Cells[2, I] := gridTests.Cells[3, I]; // Esperada
    gridResults.Cells[3, I] := '';
    gridResults.Cells[4, I] := '';
  end;

  SelectedProv := TAIProvider(Pointer(cbProvider.Items.Objects[cbProvider.ItemIndex]));
  SelectedModel := TVersionChat(Pointer(cbModel.Items.Objects[cbModel.ItemIndex]));

  AddLog('=== Iniciando Execução Bateria de Testes (' + IntToStr(TotalTests) + ') ===');

  for I := 1 to TotalTests do
  begin
    if FStopExecution then
    begin
      AddLog('Execução abortada pelo usuário.');
      Break;
    end;

    gridResults.Cells[1, I] := 'Rodando...';
    lblProgress.Caption := Format('Rodando teste %d de %d: %s', [I, TotalTests, gridTests.Cells[0, I]]);
    AddLog(Format('--- Teste %d/%d: %s ---', [I, TotalTests, gridTests.Cells[0, I]]));
    
    // Ler os campos do teste corrente
    Desc             := gridTests.Cells[0, I];
    DevPrompt        := gridTests.Cells[1, I];
    PromptText       := gridTests.Cells[2, I];
    Expected         := gridTests.Cells[3, I];
    RespostasValidas := gridTests.Cells[4, I];

    Attempts := 0;
    DoneCall := False;
    IsMatch := False;
    ActualResponse := '';
    ErrorMsg := '';

    // Loop de até 3 tentativas para erro de API/Comunicação ou retorno inválido
    while (Attempts < 3) and (not DoneCall) and (not FStopExecution) do
    begin
      Inc(Attempts);
      if Attempts > 1 then
      begin
        AddLog(Format('Tentativa %d de 3 para o teste: "%s"...', [Attempts, Desc]));
        // Breve pausa para restabelecer conexão ou liberar rate limits
        Sleep(800);
      end;

      // Configurar o componente ChatGPT1
      ChatGPT1.Provider := SelectedProv;
      ChatGPT1.TipoChat := SelectedModel;
      ChatGPT1.CustomModel := edtCustomModel.Text;
      ChatGPT1.URL := edtURL.Text;
      ChatGPT1.LocalIP := edtLocalIP.Text;
      ChatGPT1.TOKEN := edtToken.Text;
      ChatGPT1.MaxTokens := StrToIntDef(edtMaxTokens.Text, 4096);
      ChatGPT1.Dev := DevPrompt;

      AddLog('Enviando pergunta: ' + PromptText);
      
      // Chamar API
      if ChatGPT1.SendQuestion(PromptText) then
      begin
        ActualResponse := ChatGPT1.Response;
        
        // Verifica se a resposta não está vazia (resposta inválida/erro de modelo previsto)
        if Trim(ActualResponse) = '' then
        begin
          ErrorMsg := 'Resposta vazia retornada pela API';
          AddLog('Erro na tentativa: ' + ErrorMsg);
          Continue;
        end;

        // Verifica se a resposta está dentro do padrão de respostas válidas
        if Trim(RespostasValidas) <> '' then
        begin
          ValidList := TStringList.Create;
          try
            ValidList.Delimiter := ',';
            ValidList.StrictDelimiter := True;
            ValidList.DelimitedText := UpperCase(RespostasValidas);
            for J := 0 to ValidList.Count - 1 do
              ValidList[J] := Trim(ValidList[J]);
              
            IsValidFormat := False;
            for J := 0 to ValidList.Count - 1 do
            begin
              if Trim(UpperCase(ActualResponse)) = ValidList[J] then
              begin
                IsValidFormat := True;
                Break;
              end;
            end;
          finally
            ValidList.Free;
          end;

          if not IsValidFormat then
          begin
            ErrorMsg := 'Resposta fora do padrão (' + ActualResponse + ')';
            AddLog('Erro na tentativa: ' + ErrorMsg);
            Continue;
          end;
        end;

        AddLog('Obtido: ' + ActualResponse);
        
        // Validação da resposta
        if chkUseLLMValidation.Checked then
        begin
          AddLog('Realizando Validação Semântica...');
          
          // Salva DEV original para o prompt validador
          ChatGPT1.Dev := memValidationPrompt.Lines.Text;
          
          // Formula a pergunta de validação
          if ChatGPT1.SendQuestion(
            'A resposta fornecida bate semanticamente com a resposta esperada?' + #13#10 +
            'Resposta Esperada: "' + Expected + '"' + #13#10 +
            'Resposta Fornecida: "' + ActualResponse + '"' + #13#10 +
            'Responda APENAS "SIM" ou "NAO" (sem justificativas ou pontuação).'
          ) then
          begin
            ValResponse := UpperCase(Trim(ChatGPT1.Response));
            if ValResponse = '' then
            begin
              ErrorMsg := 'Resposta do validador semântico vazia';
              AddLog('Erro na tentativa: ' + ErrorMsg);
              Continue;
            end;

            AddLog('Validador respondeu: ' + ValResponse);
            IsMatch := Pos('SIM', ValResponse) > 0;
            DoneCall := True; // Tudo funcionou com sucesso (resposta e validação concluídas)
          end
          else
          begin
            ErrorMsg := 'Validador falhou: ' + ChatGPT1.LastError;
            AddLog('Erro na validação semântica: ' + ChatGPT1.LastError);
            // Falha na chamada da validação é considerada erro de API e provoca retentativa
          end;
        end
        else
        begin
          // Comparação de string simples (limpa espaços, pontuação básica e caixa)
          IsMatch := CleanString(ActualResponse) = CleanString(Expected);
          AddLog('Comparação direta. Limpa e igual: ' + BoolToStr(IsMatch, True));
          DoneCall := True; // Sucesso
        end;
      end
      else
      begin
        ErrorMsg := ChatGPT1.LastError;
        AddLog('Erro na requisição da API: ' + ErrorMsg);
      end;
      
      Application.ProcessMessages;
    end;

    if FStopExecution then
      Break;

    if DoneCall then
    begin
      if IsMatch then
      begin
        gridResults.Cells[1, I] := 'Sucesso';
        gridResults.Cells[3, I] := ActualResponse;
        gridResults.Cells[4, I] := 'Bateu';
        Inc(SuccessCount);
        AddLog('Resultado: ACERTO');
      end
      else
      begin
        gridResults.Cells[1, I] := 'Falha';
        gridResults.Cells[3, I] := ActualResponse;
        gridResults.Cells[4, I] := 'Divergiu';
        Inc(FailureCount);
        AddLog('Resultado: ERRO/DIVERGÊNCIA');
      end;
    end
    else
    begin
      // Erro persistente após 3 tentativas (não é erro de resposta divergente, é falha técnica)
      gridResults.Cells[1, I] := 'Erro API';
      gridResults.Cells[3, I] := ErrorMsg;
      gridResults.Cells[4, I] := 'Falha técnica (Excedeu 3 tentativas)';
      Inc(FailureCount);
      AddLog('Teste cancelado por erros técnicos persistentes nas 3 tentativas: ' + ErrorMsg);
    end;

    progressBar.Position := I;
    
    // Atualiza o painel de relatório parcial na tela
    lblTotal.Caption := 'Total de Testes: ' + IntToStr(TotalTests);
    lblAcertos.Caption := 'Total de Acertos: ' + IntToStr(SuccessCount);
    lblErros.Caption := 'Total de Erros: ' + IntToStr(FailureCount);
    if I > 0 then
      Assertividade := (SuccessCount / I) * 100
    else
      Assertividade := 0.0;
    lblAssertividade.Caption := Format('Assertividade: %2.2f%%', [Assertividade]);

    Application.ProcessMessages;
  end;

  // Finalização do andamento
  btnRunTests.Enabled := True;
  btnStopTests.Enabled := False;
  lblProgress.Caption := 'Execução finalizada.';
  
  AddLog('=== Execução Concluída ===');
  AddLog('Total executado: ' + IntToStr(SuccessCount + FailureCount));
  AddLog('Acertos: ' + IntToStr(SuccessCount));
  AddLog('Erros: ' + IntToStr(FailureCount));
  AddLog('Assertividade Final: ' + Format('%2.2f%%', [Assertividade]));
end;


procedure TfrmMain.btnStopTestsClick(Sender: TObject);
begin
  FStopExecution := True;
  btnStopTests.Enabled := False;
  AddLog('Sinal de parada enviado pelo usuário.');
end;

procedure TfrmMain.btnClearLogClick(Sender: TObject);
begin
  memLog.Clear;
end;

end.
