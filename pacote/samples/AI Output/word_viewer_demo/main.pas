unit main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, ExtCtrls,
  aiworddocument, aiwordviewer, aiwordtypes, aiwordobjects;

type
  { TfrmMain }

  TfrmMain = class(TForm)
    btnLoad: TButton;
    btnGenerate: TButton;
    btnZoomIn: TButton;
    btnZoomOut: TButton;
    btnFitWidth: TButton;
    btnFirst: TButton;
    btnPrev: TButton;
    btnNext: TButton;
    btnLast: TButton;
    btnClear: TButton;
    btnClearLog: TButton;
    memLog: TMemo;
    pnPreview: TPanel;
    pnlLeft: TPanel;
    OpenDialog1: TOpenDialog;
    WordDoc1: TAIWordDocument;
    WordViewer1: TAIWordViewer;
    procedure FormCreate(Sender: TObject);
    procedure btnLoadClick(Sender: TObject);
    procedure btnGenerateClick(Sender: TObject);
    procedure btnZoomInClick(Sender: TObject);
    procedure btnZoomOutClick(Sender: TObject);
    procedure btnFitWidthClick(Sender: TObject);
    procedure btnFirstClick(Sender: TObject);
    procedure btnPrevClick(Sender: TObject);
    procedure btnNextClick(Sender: TObject);
    procedure btnLastClick(Sender: TObject);
    procedure btnClearClick(Sender: TObject);
    procedure btnClearLogClick(Sender: TObject);
  private
    procedure AddLog(const Msg: string);
    procedure UpdatePageIndicator;
  public

  end;

var
  frmMain: TfrmMain;

implementation

{$R *.lfm}

{ TfrmMain }

procedure TfrmMain.FormCreate(Sender: TObject);
begin
  WordViewer1.AttachToPanel(pnPreview);
  WordViewer1.Zoom := 100;
  WordViewer1.ShowPageBorder := True;
  WordViewer1.ShowImages := True;
  WordViewer1.ShowTables := True;
  AddLog('Visualizador inicializado e anexado ao Painel.');
end;

procedure TfrmMain.AddLog(const Msg: string);
begin
  memLog.Lines.Add(FormatDateTime('hh:nn:ss', Now) + ' - ' + Msg);
end;

procedure TfrmMain.UpdatePageIndicator;
begin
  AddLog(Format('Página Atual: %d / %d', [WordViewer1.PageIndex + 1, WordViewer1.PageCount]));
end;

procedure TfrmMain.btnLoadClick(Sender: TObject);
begin
  OpenDialog1.InitialDir := ExtractFilePath(Application.ExeName);
  if OpenDialog1.Execute then
  begin
    if WordViewer1.LoadFromFile(OpenDialog1.FileName) then
    begin
      AddLog('Documento carregado e visualizado: ' + OpenDialog1.FileName);
      UpdatePageIndicator;
    end
    else
      AddLog('Erro ao carregar documento: ' + WordViewer1.LastError);
  end;
end;

procedure TfrmMain.btnGenerateClick(Sender: TObject);
var
  P: TAIWordParagraph;
  T: TAIWordTable;
  LogoPath: string;
begin
  AddLog('Gerando documento em memória para pré-visualização...');
  WordDoc1.NewDocument;

  WordDoc1.Title := 'Documento de Teste';
  WordDoc1.Author := 'Lazarus AI Suite';

  WordDoc1.Header.AddParagraph('Cabeçalho do documento');
  WordDoc1.Footer.AddParagraph('Rodapé do documento');
  WordDoc1.Footer.AddPageNumber;

  WordDoc1.AddTitle('Visualizador DOCX em TPanel');

  P := WordDoc1.AddParagraph('Este documento foi criado por objeto e renderizado no painel.');
  P.Alignment := waJustify;
  P.FontName := 'Arial';
  P.FontSize := 12;

  LogoPath := ExtractFilePath(Application.ExeName) + 'imagem' + PathDelim + 'logo.png';
  if not FileExists(LogoPath) then
    LogoPath := 'imagem/logo.png';

  if FileExists(LogoPath) then
    WordDoc1.AddImage(LogoPath, 50, 30, wipInline)
  else
    AddLog('Aviso: imagem/logo.png não encontrado para inclusão.');

  T := WordDoc1.AddTable(2, 2);
  T.Cell(0, 0).Text := 'Campo';
  T.Cell(0, 1).Text := 'Valor';
  T.Cell(1, 0).Text := 'Componente';
  T.Cell(1, 1).Text := 'TAIWordViewer';

  if WordViewer1.LoadFromDocument(WordDoc1) then
  begin
    AddLog('Documento em memória renderizado no painel.');
    UpdatePageIndicator;
  end
  else
    AddLog('Erro ao renderizar documento: ' + WordViewer1.LastError);
end;

procedure TfrmMain.btnZoomInClick(Sender: TObject);
begin
  WordViewer1.ZoomIn;
  AddLog(Format('Zoom: %d%%', [WordViewer1.Zoom]));
end;

procedure TfrmMain.btnZoomOutClick(Sender: TObject);
begin
  WordViewer1.ZoomOut;
  AddLog(Format('Zoom: %d%%', [WordViewer1.Zoom]));
end;

procedure TfrmMain.btnFitWidthClick(Sender: TObject);
begin
  WordViewer1.FitWidth;
  AddLog(Format('Largura Ajustada. Zoom: %d%%', [WordViewer1.Zoom]));
end;

procedure TfrmMain.btnFirstClick(Sender: TObject);
begin
  WordViewer1.FirstPage;
  UpdatePageIndicator;
end;

procedure TfrmMain.btnPrevClick(Sender: TObject);
begin
  WordViewer1.PreviousPage;
  UpdatePageIndicator;
end;

procedure TfrmMain.btnNextClick(Sender: TObject);
begin
  WordViewer1.NextPage;
  UpdatePageIndicator;
end;

procedure TfrmMain.btnLastClick(Sender: TObject);
begin
  WordViewer1.LastPage;
  UpdatePageIndicator;
end;

procedure TfrmMain.btnClearClick(Sender: TObject);
begin
  WordViewer1.Clear;
  AddLog('Visualizador limpo.');
end;

procedure TfrmMain.btnClearLogClick(Sender: TObject);
begin
  memLog.Clear;
end;

end.
