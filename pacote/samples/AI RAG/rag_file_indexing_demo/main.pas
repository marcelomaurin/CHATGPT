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
    tsLogs: TTabSheet;
    memLogs: TMemo;
    OpenDialog1: TOpenDialog;
    SaveDialog1: TSaveDialog;

    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btnAdicionarArquivoClick(Sender: TObject);
    procedure btnIndexarClick(Sender: TObject);
    procedure btnSalvarIndiceClick(Sender: TObject);
    procedure btnCarregarIndiceClick(Sender: TObject);
    procedure btnPerguntarClick(Sender: TObject);
    procedure btnClearClick(Sender: TObject);
  private
    FChatGPT: TCHATGPT;
    FGraphMap: TAIGraphMap;
    FAIRAG: TAIRAG;
    procedure SetupComponents;
    procedure AIRAGLog(Sender: TObject; const AMessage: string);
  public

  end;

var
  frmRAGFileIndexingDemo: TfrmRAGFileIndexingDemo;

implementation

{$R *.lfm}

{ TfrmRAGFileIndexingDemo }

procedure TfrmRAGFileIndexingDemo.FormCreate(Sender: TObject);
begin
  SetupComponents;
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
  FChatGPT.Prompt := 'Você é um assistente RAG especializado.';

  FGraphMap := TAIGraphMap.Create(Self);
  FGraphMap.AutoClearBeforeTrain := True;
  FGraphMap.UseTokenCategoryEdges := True;
  FGraphMap.UseTokenSequenceEdges := False;
  FGraphMap.NormalizeScores := True;
  FGraphMap.RemoveAccents := True;
  FGraphMap.RemoveStopWords := True;

  FAIRAG := TAIRAG.Create(Self);
  FAIRAG.ChatGPT := FChatGPT;
  FAIRAG.GraphMap := FGraphMap;
  FAIRAG.ChunkSize := 1200;
  FAIRAG.ChunkOverlap := 150;
  FAIRAG.TopK := 4;
  FAIRAG.OnRAGLog := @AIRAGLog;

  edtPergunta.Text := 'Quais são as instruções gerais dos documentos carregados?';
end;

procedure TfrmRAGFileIndexingDemo.AIRAGLog(Sender: TObject; const AMessage: string);
begin
  memLogs.Lines.Add('[RAG LOG] ' + AMessage);
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
  memLogs.Lines.Add('Iniciando construção de índice RAG...');
  if FAIRAG.BuildIndex then
  begin
    memLogs.Lines.Add('Índice RAG gerado com sucesso.');
    ShowMessage('Índice RAG construído!');
  end
  else
  begin
    memLogs.Lines.Add('Erro ao gerar índice: ' + FAIRAG.LastError);
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
      ShowMessage('Erro ao salvar índice: ' + FAIRAG.LastError);
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
      ShowMessage('Erro ao carregar índice: ' + FAIRAG.LastError);
  end;
end;

procedure TfrmRAGFileIndexingDemo.btnPerguntarClick(Sender: TObject);
begin
  if Trim(edtPergunta.Text) = '' then
  begin
    ShowMessage('Digite uma pergunta!');
    Exit;
  end;

  memLogs.Lines.Add('Consultando RAG...');
  if FAIRAG.Ask(edtPergunta.Text) then
  begin
    memResposta.Text := FAIRAG.LastAnswer;
    memContexto.Text := FAIRAG.LastContext;
    memFontes.Lines.Assign(FAIRAG.LastSources);
    pcResults.ActivePage := tsResposta;
    memLogs.Lines.Add('Resposta obtida com sucesso.');
  end
  else
  begin
    memResposta.Text := 'ERRO: ' + FAIRAG.LastError;
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
end;

end.
