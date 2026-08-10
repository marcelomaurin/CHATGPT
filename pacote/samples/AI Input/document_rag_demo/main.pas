unit main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, ExtCtrls,
  aidocumentreader, aidocumentextractor, airag;

type

  { TfrmDocRAGDemo }

  TfrmDocRAGDemo = class(TForm)
    pnlTop: TPanel;
    lblTitle: TLabel;
    lblFile: TLabel;
    edtFileName: TEdit;
    btnBrowse: TButton;
    btnAddRAG: TButton;
    lblQuestion: TLabel;
    edtQuestion: TEdit;
    btnAsk: TButton;
    memoLog: TMemo;
    openDlg: TOpenDialog;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btnBrowseClick(Sender: TObject);
    procedure btnAddRAGClick(Sender: TObject);
    procedure btnAskClick(Sender: TObject);
  private
    FRAG: TAIRAG;
    procedure AddLog(const AMsg: string);
  public

  end;

var
  frmDocRAGDemo: TfrmDocRAGDemo;

implementation

{$R *.lfm}

{ TfrmDocRAGDemo }

procedure TfrmDocRAGDemo.FormCreate(Sender: TObject);
begin
  Caption := 'AI Document RAG Demo';
  SetBounds(100, 100, 800, 600);
  FRAG := TAIRAG.Create(Self);
  AddLog('TAIRAG com Extrator Automático de Documentos Inicializado.');
end;

procedure TfrmDocRAGDemo.FormDestroy(Sender: TObject);
begin
  // Managed by Owner
end;

procedure TfrmDocRAGDemo.AddLog(const AMsg: string);
begin
  memoLog.Lines.Add('[' + FormatDateTime('hh:nn:ss', Now) + '] ' + AMsg);
end;

procedure TfrmDocRAGDemo.btnBrowseClick(Sender: TObject);
begin
  if openDlg.Execute then
    edtFileName.Text := openDlg.FileName;
end;

procedure TfrmDocRAGDemo.btnAddRAGClick(Sender: TObject);
var
  ExtractedText, ErrorStr: string;
  Reg: TAIDocumentExtractorRegistry;
begin
  if Trim(edtFileName.Text) = '' then
  begin
    ShowMessage('Selecione um arquivo de documento (PDF, DOCX, XLSX ou TXT).');
    Exit;
  end;

  Reg := GlobalExtractorRegistry;
  AddLog('Extraindo texto do arquivo: ' + edtFileName.Text);
  if Reg.ExtractText(edtFileName.Text, ExtractedText, ErrorStr) then
  begin
    FRAG.AddText(ExtractFileName(edtFileName.Text), ExtractedText);
    AddLog('Texto indexado com sucesso no RAG (' + IntToStr(Length(ExtractedText)) + ' caracteres).');
  end
  else
    AddLog('Erro ao extrair arquivo: ' + ErrorStr);
end;

procedure TfrmDocRAGDemo.btnAskClick(Sender: TObject);
begin
  if Trim(edtQuestion.Text) = '' then
  begin
    ShowMessage('Digite uma pergunta.');
    Exit;
  end;

  AddLog('Pergunta: ' + edtQuestion.Text);
  if FRAG.BuildContext(edtQuestion.Text) then
  begin
    AddLog('--- Contexto RAG Recuperado ---');
    AddLog(FRAG.GetLastContext);
  end
  else
    AddLog('Nenhum contexto relevante encontrado para a pergunta.');
end;

end.
