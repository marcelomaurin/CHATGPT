unit main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, ExtCtrls,
  ComCtrls, chatgpt, aigraphmap, airag;

type

  { TfrmRAGGraphDemo }

  TfrmRAGGraphDemo = class(TForm)
    pnlTop: TPanel;
    pnlBottom: TPanel;
    pnlLeft: TPanel;
    btnIndexar: TButton;
    btnPerguntar: TButton;
    btnClear: TButton;
    lblPergunta: TLabel;
    edtPergunta: TEdit;
    lblDocumentos: TLabel;
    memDocumento: TMemo;
    pcResults: TPageControl;
    tsResposta: TTabSheet;
    memResposta: TMemo;
    tsContexto: TTabSheet;
    memContexto: TMemo;
    tsFontes: TTabSheet;
    memFontes: TMemo;
    tsLogs: TTabSheet;
    memLogs: TMemo;
    CHATGPT1: TCHATGPT;
    AIGraphMapRAG: TAIGraphMap;
    AIRAG1: TAIRAG;

    procedure FormCreate(Sender: TObject);
    procedure btnIndexarClick(Sender: TObject);
    procedure btnPerguntarClick(Sender: TObject);
    procedure btnClearClick(Sender: TObject);
    procedure AIRAG1RAGLog(Sender: TObject; const AMessage: string);
  private
    procedure SetupRAGComponents;
  public

  end;

var
  frmRAGGraphDemo: TfrmRAGGraphDemo;

implementation

{$R *.lfm}

{ TfrmRAGGraphDemo }

procedure TfrmRAGGraphDemo.FormCreate(Sender: TObject);
begin
  SetupRAGComponents;
  memDocumento.Text :=
    'O equipamento de anestesia modelo A3 deve ser enviado para manutencao preventiva a cada 6 meses.' + sLineBreak +
    'Caso ocorra falha de pressao no sensor de O2, abra imediatamente uma Ordem de Servico tipo Emergencia.' + sLineBreak +
    'O prazo maximo para atendimento de chamados criticos e de 2 horas uteis pela equipe de Engenharia Clinica.';
  edtPergunta.Text := 'Qual o prazo para atendimento de chamados criticos?';
end;

procedure TfrmRAGGraphDemo.SetupRAGComponents;
begin
  // Configuração exclusiva do GraphMap para RAG
  AIGraphMapRAG.AutoClearBeforeTrain := True;
  AIGraphMapRAG.UseTokenCategoryEdges := True;
  AIGraphMapRAG.UseTokenSequenceEdges := False;
  AIGraphMapRAG.UseGraphDepthSearch := False;
  AIGraphMapRAG.MaxDepth := 0;
  AIGraphMapRAG.NormalizeScores := True;
  AIGraphMapRAG.RemoveAccents := True;
  AIGraphMapRAG.RemoveStopWords := True;
  AIGraphMapRAG.UniqueTokensPerText := True;

  // Associação do RAG com os componentes por propriedade
  AIRAG1.ChatGPT := CHATGPT1;
  AIRAG1.GraphMap := AIGraphMapRAG;

  AIRAG1.ChunkSize := 1200;
  AIRAG1.ChunkOverlap := 150;
  AIRAG1.TopK := 4;
  AIRAG1.MinimumScore := 0.0;

  AIRAG1.Instructions := 'Voce e um assistente especializado nos documentos fornecidos.';
  AIRAG1.NoAnswerText := 'Nao encontrei essa informacao na base de conhecimento.';
end;

procedure TfrmRAGGraphDemo.btnIndexarClick(Sender: TObject);
var
  Count: Integer;
begin
  memLogs.Lines.Add('=== Iniciando Indexacao ===');
  AIRAG1.Clear;

  Count := AIRAG1.AddText('manual_equipamento.txt', memDocumento.Text);
  memLogs.Lines.Add(Format('Chunks adicionados: %d', [Count]));

  if AIRAG1.BuildIndex then
  begin
    memLogs.Lines.Add('Indice RAG construido com sucesso!');
    memLogs.Lines.Add(Format('Nos no Grafo: %d | Arestas: %d', [AIGraphMapRAG.NodeCount, AIGraphMapRAG.EdgeCount]));
    ShowMessage('Base indexada com sucesso!');
  end
  else
  begin
    memLogs.Lines.Add('Erro ao construir indice: ' + AIRAG1.LastError);
    ShowMessage('Erro: ' + AIRAG1.LastError);
  end;
end;

procedure TfrmRAGGraphDemo.btnPerguntarClick(Sender: TObject);
begin
  if Trim(edtPergunta.Text) = '' then
  begin
    ShowMessage('Digite uma pergunta!');
    Exit;
  end;

  memLogs.Lines.Add('=== Realizando Pergunta ===');
  memLogs.Lines.Add('Pergunta: ' + edtPergunta.Text);

  if AIRAG1.Ask(edtPergunta.Text) then
  begin
    memResposta.Text := AIRAG1.LastAnswer;
    memContexto.Text := AIRAG1.LastContext;
    memFontes.Lines.Assign(AIRAG1.LastSources);
    pcResults.ActivePage := tsResposta;
    memLogs.Lines.Add('Resposta gerada com sucesso.');
  end
  else
  begin
    memResposta.Text := 'ERRO: ' + AIRAG1.LastError;
    memLogs.Lines.Add('Falha ao responder: ' + AIRAG1.LastError);
    ShowMessage('Erro ao consultar RAG: ' + AIRAG1.LastError);
  end;
end;

procedure TfrmRAGGraphDemo.btnClearClick(Sender: TObject);
begin
  AIRAG1.Clear;
  memResposta.Clear;
  memContexto.Clear;
  memFontes.Clear;
  memLogs.Clear;
  ShowMessage('Base e histórico limpos.');
end;

procedure TfrmRAGGraphDemo.AIRAG1RAGLog(Sender: TObject; const AMessage: string);
begin
  memLogs.Lines.Add('[RAG LOG] ' + AMessage);
end;

end.
