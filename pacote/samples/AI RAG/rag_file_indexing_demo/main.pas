unit main;

{$mode objfpc}{$H+}
{$M+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, ExtCtrls,
  ComCtrls, chatgpt, aigraphmap, airag;

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
  private
    FChatGPT: TCHATGPT;
    FGraphMap: TAIGraphMap;
    FAIRAG: TAIRAG;
    procedure SetupComponents;
    procedure AIRAGLog(Sender: TObject; const AMessage: string);
    function CarregarDocumentosDaPasta(const APasta: string): Integer;
  public

  end;

var
  frmRAGFileIndexingDemo: TfrmRAGFileIndexingDemo;

implementation

{$R *.lfm}

{ TfrmRAGFileIndexingDemo }

procedure TfrmRAGFileIndexingDemo.FormCreate(Sender: TObject);
var
  DocsDir: string;
begin
  SetupComponents;

  // Localiza pasta docs padrão
  DocsDir := ExtractFilePath(ParamStr(0)) + 'docs';
  if not DirectoryExists(DocsDir) then
    DocsDir := ExpandFileName(ExtractFilePath(ParamStr(0)) + '..\..\docs');
  if not DirectoryExists(DocsDir) then
    DocsDir := ExpandFileName('D:\projetos\maurinsoft\CHATGPT\pacote\samples\AI RAG\rag_file_indexing_demo\docs');

  edtDocsPath.Text := DocsDir;
  if DirectoryExists(DocsDir) then
    CarregarDocumentosDaPasta(DocsDir);
end;

procedure TfrmRAGFileIndexingDemo.FormDestroy(Sender: TObject);
begin
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

  edtPergunta.Text := 'Qual a época de florada do Ipê-Amarelo e quais são os doces tradicionais brasileiros?';
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

procedure TfrmRAGFileIndexingDemo.btnAdicionarArquivoClick(Sender: TObject);
var
  Count, I: Integer;
begin
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
