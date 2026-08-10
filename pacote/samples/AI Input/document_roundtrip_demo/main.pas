unit main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, ExtCtrls,
  aioutput_docs, aidocxinput, aiexcelinput, aipdfinput;

type

  { TfrmRoundtripDemo }

  TfrmRoundtripDemo = class(TForm)
    pnlTop: TPanel;
    lblTitle: TLabel;
    btnCreateDOCX: TButton;
    btnReadDOCX: TButton;
    btnCreateXLSX: TButton;
    btnReadXLSX: TButton;
    btnCreatePDF: TButton;
    btnReadPDF: TButton;
    memoLog: TMemo;
    procedure FormCreate(Sender: TObject);
    procedure btnCreateDOCXClick(Sender: TObject);
    procedure btnReadDOCXClick(Sender: TObject);
    procedure btnCreateXLSXClick(Sender: TObject);
    procedure btnReadXLSXClick(Sender: TObject);
    procedure btnCreatePDFClick(Sender: TObject);
    procedure btnReadPDFClick(Sender: TObject);
  private
    procedure AddLog(const AMsg: string);
  public

  end;

var
  frmRoundtripDemo: TfrmRoundtripDemo;

implementation

{$R *.lfm}

{ TfrmRoundtripDemo }

procedure TfrmRoundtripDemo.FormCreate(Sender: TObject);
begin
  Caption := 'Document Round-Trip Demo';
  SetBounds(100, 100, 780, 550);
end;

procedure TfrmRoundtripDemo.AddLog(const AMsg: string);
begin
  memoLog.Lines.Add('[' + FormatDateTime('hh:nn:ss', Now) + '] ' + AMsg);
end;

procedure TfrmRoundtripDemo.btnCreateDOCXClick(Sender: TObject);
var
  WordOut: TAIWordOutput;
begin
  WordOut := TAIWordOutput.Create(Self);
  try
    WordOut.FileName := 'roundtrip_doc.docx';
    WordOut.OutputFormat := wofDOCX;
    WordOut.Title := 'Relatório de Teste DOCX';
    WordOut.AddHeading('Relatório Empresarial', 1);
    WordOut.AddParagraph('Este é um parágrafo de teste gerado nativamente em formato DOCX.');
    WordOut.AddTable(['Item', 'Quantidade', 'Valor'], ['Servidor', '2', 'R$ 15.000', 'Licença', '5', 'R$ 2.500'], 3);

    if WordOut.SaveWord then
      AddLog('DOCX criado com sucesso: roundtrip_doc.docx')
    else
      AddLog('Erro ao criar DOCX: ' + WordOut.LastError);
  finally
    WordOut.Free;
  end;
end;

procedure TfrmRoundtripDemo.btnReadDOCXClick(Sender: TObject);
var
  DOCXIn: TAIDOCXInput;
begin
  DOCXIn := TAIDOCXInput.Create(Self);
  try
    if DOCXIn.LoadFromFile('roundtrip_doc.docx') then
    begin
      AddLog('--- Conteúdo Lido do DOCX ---');
      AddLog(DOCXIn.Text);
    end
    else
      AddLog('Erro ao ler DOCX: ' + DOCXIn.LastError);
  finally
    DOCXIn.Free;
  end;
end;

procedure TfrmRoundtripDemo.btnCreateXLSXClick(Sender: TObject);
var
  XLSOut: TAIExcelOutput;
begin
  XLSOut := TAIExcelOutput.Create(Self);
  try
    XLSOut.FileName := 'roundtrip_sheet.xlsx';
    XLSOut.OutputFormat := eofXLSX;
    XLSOut.SetCell(0, 0, 'Produto');
    XLSOut.SetCell(0, 1, 'Preço');
    XLSOut.SetCell(1, 0, 'Notebook AI');
    XLSOut.SetCell(1, 1, '7500.00');

    if XLSOut.SaveExcel then
      AddLog('XLSX criado com sucesso: roundtrip_sheet.xlsx')
    else
      AddLog('Erro ao criar XLSX: ' + XLSOut.LastError);
  finally
    XLSOut.Free;
  end;
end;

procedure TfrmRoundtripDemo.btnReadXLSXClick(Sender: TObject);
var
  XLSIn: TAIExcelInput;
begin
  XLSIn := TAIExcelInput.Create(Self);
  try
    if XLSIn.LoadFromFile('roundtrip_sheet.xlsx') then
    begin
      AddLog('--- Conteúdo Lido do XLSX ---');
      AddLog(XLSIn.ToText);
    end
    else
      AddLog('Erro ao ler XLSX: ' + XLSIn.LastError);
  finally
    XLSIn.Free;
  end;
end;

procedure TfrmRoundtripDemo.btnCreatePDFClick(Sender: TObject);
var
  PDFOut: TAIPDFOutput;
begin
  PDFOut := TAIPDFOutput.Create(Self);
  try
    PDFOut.FileName := 'roundtrip_doc.pdf';
    PDFOut.Title := 'Documento PDF Nativo';
    PDFOut.StartDocument;
    PDFOut.AddHeading('Relatório PDF Nativo', 1);
    PDFOut.AddParagraph('Este parágrafo foi gerado utilizando o gerador nativo fppdf com suporte a margens e paginação.');

    if PDFOut.SavePDF then
      AddLog('PDF criado com sucesso: roundtrip_doc.pdf')
    else
      AddLog('Erro ao criar PDF: ' + PDFOut.LastError);
  finally
    PDFOut.Free;
  end;
end;

procedure TfrmRoundtripDemo.btnReadPDFClick(Sender: TObject);
var
  PDFIn: TAIPDFInput;
begin
  PDFIn := TAIPDFInput.Create(Self);
  try
    if PDFIn.LoadFromFile('roundtrip_doc.pdf') then
    begin
      AddLog('--- Conteúdo Lido do PDF ---');
      AddLog(PDFIn.FullText);
    end
    else
      AddLog('Erro ao ler PDF: ' + PDFIn.LastError);
  finally
    PDFIn.Free;
  end;
end;

end.
