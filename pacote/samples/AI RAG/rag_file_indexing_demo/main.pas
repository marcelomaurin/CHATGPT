unit main;

{$mode objfpc}{$H+}
{$M+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, ExtCtrls,
  ComCtrls, IniFiles, chatgpt, aigraphmap, airag;

type

  { TfrmRAGFileIndexingDemo }

  TfrmRAGFileIndexingDemo = class(TForm)
    pnlTop: TPanel;
    pnlLeft: TPanel;
    btnAdicionarArquivo: TButton;
    btnIndexar: TButton;
    btnSalvarIndice: TButton;
    btnCarregarIndice: TButton;
    btnPerguntar: TButton;
    btnClear: TButton;
    lblPergunta: TLabel;
    edtPergunta: TEdit;
    lblArquivos: TLabel;
    lstArquivos: TListBox;
    pcResults: TPageControl;
    tsResposta: TTabSheet;
    memResposta: TMemo;
    tsContexto: TTabSheet;
    memContexto: TMemo;
    tsFontes: TTabSheet;
    memFontes: TMemo;
    tsConfigIA: TTabSheet;
    pnlConfigIABox: TPanel;
    lblProvider: TLabel;
    cmbProvider: TComboBox;
    lblApiKey: TLabel;
    edtApiKey: TEdit;
    lblModel: TLabel;
    cmbModel: TComboBox;
    lblChunkSize: TLabel;
    edtChunkSize: TEdit;
    lblChunkOverlap: TLabel;
    edtChunkOverlap: TEdit;
    lblTopK: TLabel;
    edtTopK: TEdit;
    lblMinScore: TLabel;
    edtMinScore: TEdit;
    lblInstructions: TLabel;
    memInstructions: TMemo;
    btnSalvarConfigIA: TButton;
    tsConfiguracao: TTabSheet;
    pnlConfigTop: TPanel;
    lblDocsPath: TLabel;
    edtDocsPath: TEdit;
    btnSelecionarPasta: TButton;
    btnVarrerPasta: TButton;
    chkRecursive: TCheckBox;
    lblExtensions: TLabel;
    edtExtensions: TEdit;
    memDocsInfo: TMemo;
    tsLogs: TTabSheet;
    memLogs: TMemo;
    OpenDialog1: TOpenDialog;
    SaveDialog1: TSaveDialog;
    SelectDirectoryDialog1: TSelectDirectoryDialog;

    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btnAdicionarArquivoClick(Sender: TObject);
    procedure btnIndexarClick(Sender: TObject);
    procedure btnSalvarIndiceClick(Sender: TObject);
    procedure btnCarregarIndiceClick(Sender: TObject);
    procedure btnPerguntarClick(Sender: TObject);
    procedure btnClearClick(Sender: TObject);
    procedure btnSelecionarPastaClick(Sender: TObject);
    procedure btnVarrerPastaClick(Sender: TObject);
    procedure btnSalvarConfigIAClick(Sender: TObject);
    procedure cmbProviderChange(Sender: TObject);
  private
    FChatGPT: TCHATGPT;
    FGraphMap: TAIGraphMap;
    FAIRAG: TAIRAG;
    procedure SetupComponents;
    procedure AIRAGLog(Sender: TObject; const AMessage: string);
    function CarregarDocumentosDaPasta(const APasta: string): Integer;
    function GetConfigFilePath: string;
    procedure CarregarConfiguracoesAppData;
    procedure SalvarConfiguracoesAppData;
    procedure AplicarConfiguracoesIA;
    procedure AtualizarModelosDoProvedor;
  public

  end;

var
  frmRAGFileIndexingDemo: TfrmRAGFileIndexingDemo;

implementation

{$R *.lfm}

{ TfrmRAGFileIndexingDemo }

function TfrmRAGFileIndexingDemo.GetConfigFilePath: string;
var
  ConfigDir: string;
begin
  ConfigDir := GetAppConfigDir(False);
  if not DirectoryExists(ConfigDir) then
    ForceDirectories(ConfigDir);
  Result := IncludeTrailingPathDelimiter(ConfigDir) + 'rag_config.ini';
end;

procedure TfrmRAGFileIndexingDemo.AtualizarModelosDoProvedor;
var
  SelectedProvider: TAIProvider;
  CurrentModel: string;
begin
  CurrentModel := cmbModel.Text;
  SelectedProvider := GetAIProviderFromIndex(cmbProvider.ItemIndex);

  cmbModel.Items.Clear;
  GetAIModelListForProvider(SelectedProvider, cmbModel.Items);

  if cmbModel.Items.Count > 0 then
  begin
    if cmbModel.Items.IndexOf(CurrentModel) >= 0 then
      cmbModel.Text := CurrentModel
    else
      cmbModel.ItemIndex := 0;
  end;
end;

procedure TfrmRAGFileIndexingDemo.cmbProviderChange(Sender: TObject);
begin
  AtualizarModelosDoProvedor;
end;

procedure TfrmRAGFileIndexingDemo.CarregarConfiguracoesAppData;
var
  Ini: TIniFile;
  ConfigFile, DocsDir, ProviderStr: string;
  ProviderIdx: Integer;
begin
  ConfigFile := GetConfigFilePath;
  Ini := TIniFile.Create(ConfigFile);
  try
    DocsDir := ExtractFilePath(ParamStr(0)) + 'docs';
    if not DirectoryExists(DocsDir) then
      DocsDir := ExpandFileName(ExtractFilePath(ParamStr(0)) + '..\..\docs');
    if not DirectoryExists(DocsDir) then
      DocsDir := ExpandFileName('D:\projetos\maurinsoft\CHATGPT\pacote\samples\AI RAG\rag_file_indexing_demo\docs');

    // Carrega Provedores
    GetAIProviderList(cmbProvider.Items);
    ProviderIdx := Ini.ReadInteger('IA', 'ProviderIndex', 0);
    if (ProviderIdx >= 0) and (ProviderIdx < cmbProvider.Items.Count) then
      cmbProvider.ItemIndex := ProviderIdx
    else
      cmbProvider.ItemIndex := 0;

    AtualizarModelosDoProvedor;

    edtApiKey.Text := Ini.ReadString('IA', 'ApiKey', GetEnvironmentVariable('OPENAI_API_KEY'));
    cmbModel.Text := Ini.ReadString('IA', 'Model', cmbModel.Text);
    edtChunkSize.Text := Ini.ReadString('RAG', 'ChunkSize', '1200');
    edtChunkOverlap.Text := Ini.ReadString('RAG', 'ChunkOverlap', '150');
    edtTopK.Text := Ini.ReadString('RAG', 'TopK', '4');
    edtMinScore.Text := Ini.ReadString('RAG', 'MinScore', '0.0');
    memInstructions.Text := Ini.ReadString('IA', 'Instructions', 'Voce e um assistente especializado nos documentos fornecidos.');

    edtDocsPath.Text := Ini.ReadString('Pasta', 'DocsPath', DocsDir);
    edtExtensions.Text := Ini.ReadString('Pasta', 'Extensions', '.txt;.md;.pas;.json;.csv');
    chkRecursive.Checked := Ini.ReadBool('Pasta', 'Recursive', True);

    memLogs.Lines.Add('Configurações carregadas de AppData: ' + ConfigFile);
  finally
    Ini.Free;
  end;
end;

procedure TfrmRAGFileIndexingDemo.SalvarConfiguracoesAppData;
var
  Ini: TIniFile;
  ConfigFile: string;
begin
  ConfigFile := GetConfigFilePath;
  Ini := TIniFile.Create(ConfigFile);
  try
    Ini.WriteInteger('IA', 'ProviderIndex', cmbProvider.ItemIndex);
    Ini.WriteString('IA', 'ProviderName', cmbProvider.Text);
    Ini.WriteString('IA', 'ApiKey', edtApiKey.Text);
    Ini.WriteString('IA', 'Model', cmbModel.Text);
    Ini.WriteString('RAG', 'ChunkSize', edtChunkSize.Text);
    Ini.WriteString('RAG', 'ChunkOverlap', edtChunkOverlap.Text);
    Ini.WriteString('RAG', 'TopK', edtTopK.Text);
    Ini.WriteString('RAG', 'MinScore', edtMinScore.Text);
    Ini.WriteString('IA', 'Instructions', memInstructions.Text);

    Ini.WriteString('Pasta', 'DocsPath', edtDocsPath.Text);
    Ini.WriteString('Pasta', 'Extensions', edtExtensions.Text);
    Ini.WriteBool('Pasta', 'Recursive', chkRecursive.Checked);

    memLogs.Lines.Add('Configurações salvas com sucesso em AppData: ' + ConfigFile);
  finally
    Ini.Free;
  end;
end;

procedure TfrmRAGFileIndexingDemo.AplicarConfiguracoesIA;
var
  SelProvider: TAIProvider;
begin
  if Assigned(FChatGPT) then
  begin
    SelProvider := GetAIProviderFromIndex(cmbProvider.ItemIndex);
    FChatGPT.Provider := SelProvider;

    if Trim(edtApiKey.Text) <> '' then
      FChatGPT.TOKEN := edtApiKey.Text;

    if Trim(cmbModel.Text) <> '' then
    begin
      FChatGPT.TipoChat := VCT_CUSTOM;
      FChatGPT.CustomModel := cmbModel.Text;
    end;
  end;

  if Assigned(FAIRAG) then
  begin
    FAIRAG.ChunkSize := StrToIntDef(edtChunkSize.Text, 1200);
    FAIRAG.ChunkOverlap := StrToIntDef(edtChunkOverlap.Text, 150);
    FAIRAG.TopK := StrToIntDef(edtTopK.Text, 4);
    FAIRAG.MinimumScore := StrToFloatDef(StringReplace(edtMinScore.Text, ',', '.', [rfReplaceAll]), 0.0);
    if Trim(memInstructions.Text) <> '' then
      FAIRAG.Instructions := memInstructions.Text;
  end;
end;

procedure TfrmRAGFileIndexingDemo.FormCreate(Sender: TObject);
begin
  SetupComponents;
  CarregarConfiguracoesAppData;
  AplicarConfiguracoesIA;

  if DirectoryExists(edtDocsPath.Text) then
    CarregarDocumentosDaPasta(edtDocsPath.Text);
end;

procedure TfrmRAGFileIndexingDemo.FormDestroy(Sender: TObject);
begin
  SalvarConfiguracoesAppData;
  FAIRAG.Free;
  FGraphMap.Free;
  FChatGPT.Free;
end;

procedure TfrmRAGFileIndexingDemo.SetupComponents;
begin
  FChatGPT := TCHATGPT.Create(Self);
  FChatGPT.Prompt := 'Você é um assistente RAG especializado em botânica e culinária brasileira.';

  FGraphMap := TAIGraphMap.Create(Self);
  FGraphMap.AutoClearBeforeTrain := True;
  FGraphMap.UseTokenCategoryEdges := True;
  FGraphMap.UseTokenSequenceEdges := False;
  FGraphMap.NormalizeScores := True;
  FGraphMap.RemoveAccents := False; // Preserva UTF-8
  FGraphMap.RemoveStopWords := True;

  FAIRAG := TAIRAG.Create(Self);
  FAIRAG.ChatGPT := FChatGPT;
  FAIRAG.GraphMap := FGraphMap;
  FAIRAG.ChunkSize := 1200;
  FAIRAG.ChunkOverlap := 150;
  FAIRAG.TopK := 4;
  FAIRAG.OnRAGLog := @AIRAGLog;

  edtPergunta.Text := 'Em janeiro qual planta florece?';
end;

procedure TfrmRAGFileIndexingDemo.AIRAGLog(Sender: TObject; const AMessage: string);
begin
  memLogs.Lines.Add('[RAG LOG] ' + AMessage);
end;

function TfrmRAGFileIndexingDemo.CarregarDocumentosDaPasta(const APasta: string): Integer;
var
  TotalFiles: Integer;
  SearchRec: TSearchRec;
begin
  Result := 0;
  if not DirectoryExists(APasta) then
  begin
    memLogs.Lines.Add('[ERRO GUI] Diretório de documentos não encontrado: ' + APasta);
    ShowMessage('Diretório não encontrado: ' + APasta);
    Exit(0);
  end;

  AplicarConfiguracoesIA;
  FAIRAG.Clear;
  lstArquivos.Clear;
  memDocsInfo.Lines.Clear;
  memDocsInfo.Lines.Add('Diretório de Varredura RAG: ' + APasta);
  memDocsInfo.Lines.Add('Extensões Filtradas: ' + edtExtensions.Text);
  memDocsInfo.Lines.Add('Varredura Recursiva: ' + BoolToStr(chkRecursive.Checked, True));
  memDocsInfo.Lines.Add('========================================');

  TotalFiles := FAIRAG.AddFolder(APasta, chkRecursive.Checked, edtExtensions.Text);

  // Exibe lista de arquivos encontrados na pasta
  if FindFirst(IncludeTrailingPathDelimiter(APasta) + '*.*', faAnyFile, SearchRec) = 0 then
  begin
    try
      repeat
        if (SearchRec.Attr and faDirectory) = 0 then
        begin
          if (SearchRec.Name <> '.') and (SearchRec.Name <> '..') then
            lstArquivos.Items.Add(SearchRec.Name);
        end;
      until FindNext(SearchRec) <> 0;
    finally
      FindClose(SearchRec);
    end;
  end;

  memDocsInfo.Lines.Add('========================================');
  memDocsInfo.Lines.Add(Format('Total de Arquivos Processados: %d', [TotalFiles]));
  memDocsInfo.Lines.Add(Format('Total de Chunks no Treinamento do Grafo: %d', [FGraphMap.Training.Count]));

  if TotalFiles = 0 then
    memLogs.Lines.Add('[AVISO GUI] Nenhum arquivo correspondente às extensões foi encontrado em ' + APasta)
  else
    memLogs.Lines.Add(Format('Varredura concluída em %s: %d arquivos (%d chunks no grafo).', [APasta, TotalFiles, FGraphMap.Training.Count]));

  Result := TotalFiles;
end;

procedure TfrmRAGFileIndexingDemo.btnSelecionarPastaClick(Sender: TObject);
begin
  SelectDirectoryDialog1.InitialDir := edtDocsPath.Text;
  if SelectDirectoryDialog1.Execute then
  begin
    edtDocsPath.Text := SelectDirectoryDialog1.FileName;
    CarregarDocumentosDaPasta(SelectDirectoryDialog1.FileName);
    SalvarConfiguracoesAppData;
  end;
end;

procedure TfrmRAGFileIndexingDemo.btnVarrerPastaClick(Sender: TObject);
var
  FilesCount: Integer;
begin
  FilesCount := CarregarDocumentosDaPasta(edtDocsPath.Text);
  if FilesCount > 0 then
    btnIndexarClick(Sender)
  else
  begin
    memLogs.Lines.Add('[ERRO VARREDURA] Nenhum arquivo válido foi encontrado na pasta ' + edtDocsPath.Text);
    ShowMessage('Nenhum arquivo correspondente às extensões (' + edtExtensions.Text + ') foi encontrado na pasta.');
  end;
end;

procedure TfrmRAGFileIndexingDemo.btnSalvarConfigIAClick(Sender: TObject);
begin
  AplicarConfiguracoesIA;
  SalvarConfiguracoesAppData;
  ShowMessage('Configurações da IA salvas com sucesso em AppData!');
end;

procedure TfrmRAGFileIndexingDemo.btnAdicionarArquivoClick(Sender: TObject);
var
  Count, I: Integer;
begin
  AplicarConfiguracoesIA;
  OpenDialog1.Filter := 'Arquivos de Texto (*.txt;*.md)|*.txt;*.md|Todos os Arquivos (*.*)|*.*';
  if OpenDialog1.Execute then
  begin
    for I := 0 to OpenDialog1.Files.Count - 1 do
    begin
      Count := FAIRAG.AddFile(OpenDialog1.Files[I]);
      lstArquivos.Items.Add(ExtractFileName(OpenDialog1.Files[I]) + Format(' (%d chunks)', [Count]));
      memLogs.Lines.Add(Format('Arquivo adicionado: %s (%d chunks)', [ExtractFileName(OpenDialog1.Files[I]), Count]));
    end;
  end;
end;

procedure TfrmRAGFileIndexingDemo.btnIndexarClick(Sender: TObject);
begin
  if FGraphMap.Training.Count = 0 then
  begin
    memLogs.Lines.Add('[ERRO GUI] Tentativa de indexação com 0 chunks no treinamento.');
    ShowMessage('Nenhum documento ou texto foi adicionado. Varra uma pasta ou adicione um arquivo primeiro.');
    Exit;
  end;

  AplicarConfiguracoesIA;
  memLogs.Lines.Add('Iniciando construção de índice RAG...');
  if FAIRAG.BuildIndex then
  begin
    memLogs.Lines.Add('Índice RAG gerado com sucesso.');
    ShowMessage('Índice RAG construído com sucesso!');
  end
  else
  begin
    memLogs.Lines.Add('[ERRO GUILOG] Erro ao gerar índice RAG: ' + FAIRAG.LastError);
    ShowMessage('Erro: ' + FAIRAG.LastError);
  end;
end;

procedure TfrmRAGFileIndexingDemo.btnSalvarIndiceClick(Sender: TObject);
var
  GraphFile, TrainingFile: string;
begin
  SaveDialog1.Title := 'Salvar Grafo do Índice';
  SaveDialog1.Filter := 'Arquivo de Grafo (*.bin)|*.bin';
  if SaveDialog1.Execute then
  begin
    GraphFile := SaveDialog1.FileName;
    TrainingFile := ChangeFileExt(GraphFile, '.json');
    if FAIRAG.SaveIndex(GraphFile, TrainingFile) then
    begin
      memLogs.Lines.Add('Índice RAG salvo: ' + GraphFile);
      ShowMessage('Índice RAG salvo em disco!');
    end
    else
    begin
      memLogs.Lines.Add('[ERRO GUI] Erro ao salvar índice: ' + FAIRAG.LastError);
      ShowMessage('Erro ao salvar índice: ' + FAIRAG.LastError);
    end;
  end;
end;

procedure TfrmRAGFileIndexingDemo.btnCarregarIndiceClick(Sender: TObject);
var
  GraphFile, TrainingFile: string;
begin
  OpenDialog1.Title := 'Carregar Grafo do Índice';
  OpenDialog1.Filter := 'Arquivo de Grafo (*.bin)|*.bin';
  if OpenDialog1.Execute then
  begin
    GraphFile := OpenDialog1.FileName;
    TrainingFile := ChangeFileExt(GraphFile, '.json');
    if FAIRAG.LoadIndex(GraphFile, TrainingFile) then
    begin
      memLogs.Lines.Add('Índice RAG carregado: ' + GraphFile);
      ShowMessage('Índice RAG carregado com sucesso!');
    end
    else
    begin
      memLogs.Lines.Add('[ERRO GUI] Erro ao carregar índice: ' + FAIRAG.LastError);
      ShowMessage('Erro ao carregar índice: ' + FAIRAG.LastError);
    end;
  end;
end;

procedure TfrmRAGFileIndexingDemo.btnPerguntarClick(Sender: TObject);
begin
  if Trim(edtPergunta.Text) = '' then
  begin
    ShowMessage('Digite uma pergunta!');
    Exit;
  end;

  if FGraphMap.Training.Count = 0 then
  begin
    memLogs.Lines.Add('[ERRO CONSULTA] Tentativa de pergunta sem documentos indexados.');
    ShowMessage('Nenhum documento foi adicionado para busca RAG. Adicione arquivos ou varra uma pasta primeiro.');
    Exit;
  end;

  AplicarConfiguracoesIA;
  memLogs.Lines.Add('Consultando RAG...');
  if FAIRAG.Ask(edtPergunta.Text) then
  begin
    memResposta.Text := FAIRAG.LastAnswer;
    memContexto.Text := FAIRAG.LastContext;
    memFontes.Lines.Assign(FAIRAG.LastSources);
    pcResults.ActivePage := tsResposta;
    memLogs.Lines.Add('Consulta concluída.');
  end
  else
  begin
    memResposta.Text := 'ERRO: ' + FAIRAG.LastError;
    memLogs.Lines.Add('[ERRO CONSULTA] ' + FAIRAG.LastError);
    ShowMessage('Erro RAG: ' + FAIRAG.LastError);
  end;
end;

procedure TfrmRAGFileIndexingDemo.btnClearClick(Sender: TObject);
begin
  FAIRAG.Clear;
  lstArquivos.Clear;
  memResposta.Clear;
  memContexto.Clear;
  memFontes.Clear;
  memLogs.Clear;
  memLogs.Lines.Add('Estado do RAG limpo.');
end;

end.
