unit aioutput_docs;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Math,
  // Native FPC PDF generator library
  fpPDF;

type
  { TAIPDFOutput }

  TAIPDFOutput = class(TComponent)
  private
    FPrompt: string;
    FFileName: string;
    FTitle: string;
    FAuthor: string;
    FSubject: string;
    FPDFDoc: TPDFDocument;
    FPage: TPDFPage;
    FFontIndex: Integer;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    
    procedure StartDocument;
    procedure AddPage;
    procedure AddText(const AText: string; X, Y: Single; FontSize: Single = 12.0);
    function SavePDF: Boolean;
  published
    property Prompt: string read FPrompt write FPrompt;
    property FileName: string read FFileName write FFileName;
    property Title: string read FTitle write FTitle;
    property Author: string read FAuthor write FAuthor;
    property Subject: string read FSubject write FSubject;
  end;

  { TAIWordOutput }

  TAIWordOutput = class(TComponent)
  private
    FPrompt: string;
    FFileName: string;
    FTitle: string;
    FContent: TStringList;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    
    procedure AddHeading(const AText: string; ALevel: Integer = 1);
    procedure AddParagraph(const AText: string);
    procedure AddTable(const AHeaders: array of string; const ARows: array of string; ACols: Integer);
    function SaveWord: Boolean;
  published
    property Prompt: string read FPrompt write FPrompt;
    property FileName: string read FFileName write FFileName;
    property Title: string read FTitle write FTitle;
  end;

  { TAIExcelOutput }

  TAIExcelOutput = class(TComponent)
  private
    FPrompt: string;
    FFileName: string;
    FCells: TStringList;
    FMaxRow: Integer;
    FMaxCol: Integer;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    
    procedure SetCell(ARow, ACol: Integer; const AValue: string);
    function SaveExcel: Boolean;
  published
    property Prompt: string read FPrompt write FPrompt;
    property FileName: string read FFileName write FFileName;
  end;

  { TAITXTOutput }

  TAITXTOutput = class(TComponent)
  private
    FPrompt: string;
    FFileName: string;
    FLines: TStringList;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    
    procedure AddLine(const ALine: string);
    procedure AddHeader(const AText: string);
    procedure Clear;
    function SaveText: Boolean;
  published
    property Prompt: string read FPrompt write FPrompt;
    property FileName: string read FFileName write FFileName;
  end;

  { TAIOutputDocs }

  TAIOutputDocs = class(TComponent)
  private
    FPrompt: string;
    FFileNamePDF: string;
    FFileNameWord: string;
    FFileNameExcel: string;
    FFileNameTXT: string;
    FTitle: string;
    FAuthor: string;
    FSubject: string;
    
    FParagraphs: TStringList;
    FTableHeaders: TStringList;
    FTableRows: TStringList;
    FTableCols: Integer;
    FCells: TStringList;
    FMaxRow: Integer;
    FMaxCol: Integer;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    
    procedure Clear;
    procedure AddHeading(const AText: string; ALevel: Integer = 1);
    procedure AddParagraph(const AText: string);
    procedure AddTable(const AHeaders: array of string; const ARows: array of string; ACols: Integer);
    procedure SetCell(ARow, ACol: Integer; const AValue: string);
    
    function SaveToPDF: Boolean;
    function SaveToWord: Boolean;
    function SaveToExcel: Boolean;
    function SaveToTXT: Boolean;
    function SaveAll(const ABaseFileName: string = ''): Boolean;
  published
    property Prompt: string read FPrompt write FPrompt;
    property FileNamePDF: string read FFileNamePDF write FFileNamePDF;
    property FileNameWord: string read FFileNameWord write FFileNameWord;
    property FileNameExcel: string read FFileNameExcel write FFileNameExcel;
    property FileNameTXT: string read FFileNameTXT write FFileNameTXT;
    property Title: string read FTitle write FTitle;
    property Author: string read FAuthor write FAuthor;
    property Subject: string read FSubject write FSubject;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('IA Output', [
    TAIPDFOutput,
    TAIWordOutput,
    TAIExcelOutput,
    TAITXTOutput,
    TAIOutputDocs
  ]);
end;

{ TAIPDFOutput }

constructor TAIPDFOutput.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FPrompt := 'Component TAIPDFOutput generates standard PDF documents natively using fppdf. Properties: FileName: string, Title: string, Author: string, Subject: string. Methods: StartDocument, AddPage, AddText(const AText: string; X, Y: Single; FontSize: Single = 12.0), SavePDF: Boolean. AI Agent: Use this to create high-quality reports or printable documents.';
  FFileName := 'documento_ia.pdf';
  FTitle := 'Relatório de IA';
  FAuthor := 'Antigravity AI Suite';
  FSubject := 'Resultados de Modelos de IA';
  FPDFDoc := nil;
  FPage := nil;
  FFontIndex := -1;
end;

destructor TAIPDFOutput.Destroy;
begin
  if Assigned(FPDFDoc) then
    FPDFDoc.Free;
  inherited Destroy;
end;

procedure TAIPDFOutput.StartDocument;
begin
  if Assigned(FPDFDoc) then
    FPDFDoc.Free;
    
  FPDFDoc := TPDFDocument.Create(nil);
  FPDFDoc.StartDocument;
  
  FPDFDoc.Infos.Title := FTitle;
  FPDFDoc.Infos.Author := FAuthor;
  
  // Add standard Helvetica font to document catalog
  FFontIndex := FPDFDoc.AddFont('Helvetica');
end;

procedure TAIPDFOutput.AddPage;
begin
  if not Assigned(FPDFDoc) then
    StartDocument;
    
  FPage := FPDFDoc.Pages.AddPage;
  FPage.PaperType := ptA4;
  FPage.Orientation := ppoPortrait;
end;

procedure TAIPDFOutput.AddText(const AText: string; X, Y: Single; FontSize: Single);
begin
  if not Assigned(FPage) then
    AddPage;
    
  FPage.SetFont(FFontIndex, Round(FontSize));
  FPage.SetColor(clBlack, False);
  // Y-axis is from bottom up in PDF specification, correct for standard top-down
  FPage.WriteText(X, 842.0 - Y, AText);
end;

function TAIPDFOutput.SavePDF: Boolean;
begin
  Result := False;
  if not Assigned(FPDFDoc) then
    Exit;
    
  try
    FPDFDoc.SaveToFile(FFileName);
    Result := True;
  except
    Result := False;
  end;
end;

{ TAIWordOutput }

constructor TAIWordOutput.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FPrompt := 'Component TAIWordOutput creates Microsoft Word compatible documents (.docx/HTML) natively. Properties: FileName: string, Title: string. Methods: AddHeading(const AText: string; ALevel: Integer = 1), AddParagraph(const AText: string), AddTable(const AHeaders: array of string; const ARows: array of string; ACols: Integer), SaveWord: Boolean. AI Agent: Use this to generate formatted text documents or reports.';
  FFileName := 'documento_ia.docx';
  FTitle := 'Relatório de IA';
  FContent := TStringList.Create;
end;

destructor TAIWordOutput.Destroy;
begin
  FContent.Free;
  inherited Destroy;
end;

procedure TAIWordOutput.AddHeading(const AText: string; ALevel: Integer);
var
  HSize: Integer;
begin
  HSize := Max(10, 24 - (ALevel * 4));
  FContent.Add(Format('<h%d style="font-family: sans-serif; color: #1a237e; font-size: %dpx;">%s</h%d>', [ALevel, HSize, AText, ALevel]));
end;

procedure TAIWordOutput.AddParagraph(const AText: string);
begin
  FContent.Add(Format('<p style="font-family: sans-serif; font-size: 11pt; line-height: 1.5; color: #333;">%s</p>', [AText]));
end;

procedure TAIWordOutput.AddTable(const AHeaders: array of string; const ARows: array of string; ACols: Integer);
var
  I, J: Integer;
  TableStr: string;
begin
  TableStr := '<table border="1" cellpadding="6" cellspacing="0" style="border-collapse: collapse; font-family: sans-serif; font-size: 10pt; width: 100%; border: 1px solid #ccc;">';
  
  // Headers
  if Length(AHeaders) > 0 then
  begin
    TableStr := TableStr + '<tr style="background-color: #f5f5f5; font-weight: bold; color: #1a237e;">';
    for I := 0 to High(AHeaders) do
      TableStr := TableStr + '<th>' + AHeaders[I] + '</th>';
    TableStr := TableStr + '</tr>';
  end;
  
  // Rows
  if ACols > 0 then
  begin
    for I := 0 to (Length(ARows) div ACols) - 1 do
    begin
      TableStr := TableStr + '<tr>';
      for J := 0 to ACols - 1 do
      begin
        TableStr := TableStr + '<td>' + ARows[I * ACols + J] + '</td>';
      end;
      TableStr := TableStr + '</tr>';
    end;
  end;
  
  TableStr := TableStr + '</table>';
  FContent.Add(TableStr);
end;

function TAIWordOutput.SaveWord: Boolean;
var
  DocBody: TStringList;
begin
  Result := False;
  DocBody := TStringList.Create;
  try
    DocBody.Add('<!--[if gte mso 9]>');
    DocBody.Add('<xml>');
    DocBody.Add(' <w:WordDocument>');
    DocBody.Add('  <w:View>Print</w:View>');
    DocBody.Add(' </w:WordDocument>');
    DocBody.Add('</xml>');
    DocBody.Add('<![endif]-->');
    DocBody.Add('<html>');
    DocBody.Add('<head><title>' + FTitle + '</title></head>');
    DocBody.Add('<body style="padding: 40px;">');
    DocBody.AddStrings(FContent);
    DocBody.Add('</body>');
    DocBody.Add('</html>');
    
    DocBody.SaveToFile(FFileName);
    Result := True;
  finally
    DocBody.Free;
  end;
end;

{ TAIExcelOutput }

constructor TAIExcelOutput.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FPrompt := 'Component TAIExcelOutput generates Excel compatible spreadsheets (.xlsx/HTML) natively. Properties: FileName: string. Methods: SetCell(ARow, ACol: Integer; const AValue: string), SaveExcel: Boolean. AI Agent: Use this to output structured tabular data, reports, or telemetry logs.';
  FFileName := 'dados_ia.xlsx';
  FCells := TStringList.Create;
  FMaxRow := 0;
  FMaxCol := 0;
end;

destructor TAIExcelOutput.Destroy;
begin
  FCells.Free;
  inherited Destroy;
end;

procedure TAIExcelOutput.SetCell(ARow, ACol: Integer; const AValue: string);
begin
  FCells.Values[IntToStr(ARow) + ',' + IntToStr(ACol)] := AValue;
  if ARow > FMaxRow then FMaxRow := ARow;
  if ACol > FMaxCol then FMaxCol := ACol;
end;

function TAIExcelOutput.SaveExcel: Boolean;
var
  Doc: TStringList;
  R, C: Integer;
  Val: string;
begin
  Result := False;
  Doc := TStringList.Create;
  try
    Doc.Add('<html>');
    Doc.Add('<head>');
    Doc.Add(' <meta http-equiv="content-type" content="text/html; charset=utf-8">');
    Doc.Add(' <style>');
    Doc.Add('  table { border-collapse: collapse; }');
    Doc.Add('  td { border: 1px solid #ccc; font-family: sans-serif; font-size: 10pt; padding: 4px; }');
    Doc.Add('  .header { background-color: #e3f2fd; font-weight: bold; color: #0d47a1; text-align: center; }');
    Doc.Add(' </style>');
    Doc.Add('</head>');
    Doc.Add('<body>');
    Doc.Add(' <table>');
    
    for R := 0 to FMaxRow do
    begin
      Doc.Add('  <tr>');
      for C := 0 to FMaxCol do
      begin
        Val := FCells.Values[IntToStr(R) + ',' + IntToStr(C)];
        if R = 0 then
          Doc.Add('   <td class="header">' + Val + '</td>')
        else
          Doc.Add('   <td>' + Val + '</td>');
      end;
      Doc.Add('  </tr>');
    end;
    
    Doc.Add(' </table>');
    Doc.Add('</body>');
    Doc.Add('</html>');
    
    Doc.SaveToFile(FFileName);
    Result := True;
  finally
    Doc.Free;
  end;
end;

{ TAITXTOutput }

constructor TAITXTOutput.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FPrompt := 'Component TAITXTOutput generates plain ASCII text files natively. Properties: FileName: string. Methods: AddLine(const ALine: string), AddHeader(const AText: string), Clear, SaveText: Boolean. AI Agent: Use this to output raw text summaries, logs, or flat files.';
  FFileName := 'relatorio_ia.txt';
  FLines := TStringList.Create;
end;

destructor TAITXTOutput.Destroy;
begin
  FLines.Free;
  inherited Destroy;
end;

procedure TAITXTOutput.AddLine(const ALine: string);
begin
  FLines.Add(ALine);
end;

procedure TAITXTOutput.AddHeader(const AText: string);
begin
  FLines.Add('================================================================================');
  FLines.Add('  ' + UpperCase(AText));
  FLines.Add('================================================================================');
end;

procedure TAITXTOutput.Clear;
begin
  FLines.Clear;
end;

function TAITXTOutput.SaveText: Boolean;
begin
  try
    FLines.SaveToFile(FFileName);
    Result := True;
  except
    Result := False;
  end;
end;

{ TAIOutputDocs }

constructor TAIOutputDocs.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FPrompt := 'Component TAIOutputDocs is a unified document output suite combining PDF, Word, Excel, and TXT outputs. Properties: FileNamePDF: string, FileNameWord: string, FileNameExcel: string, FileNameTXT: string, Title: string, Author: string, Subject: string. Methods: Clear, AddHeading(const AText: string; ALevel: Integer = 1), AddParagraph(const AText: string), AddTable(const AHeaders: array of string; const ARows: array of string; ACols: Integer), SetCell(ARow, ACol: Integer; const AValue: string), SaveToPDF: Boolean, SaveToWord: Boolean, SaveToExcel: Boolean, SaveToTXT: Boolean, SaveAll(const ABaseFileName: string = ""): Boolean. AI Agent: Use this unified component to output reports in all four major document types at once.';
  FFileNamePDF := 'documento_ia.pdf';
  FFileNameWord := 'documento_ia.docx';
  FFileNameExcel := 'dados_ia.xlsx';
  FFileNameTXT := 'relatorio_ia.txt';
  FTitle := 'Relatório de IA Unificado';
  FAuthor := 'Antigravity AI Suite';
  FSubject := 'Resultados de Modelos de IA';
  
  FParagraphs := TStringList.Create;
  FTableHeaders := TStringList.Create;
  FTableRows := TStringList.Create;
  FTableCols := 0;
  FCells := TStringList.Create;
  FMaxRow := 0;
  FMaxCol := 0;
end;

destructor TAIOutputDocs.Destroy;
begin
  FParagraphs.Free;
  FTableHeaders.Free;
  FTableRows.Free;
  FCells.Free;
  inherited Destroy;
end;

procedure TAIOutputDocs.Clear;
begin
  FParagraphs.Clear;
  FTableHeaders.Clear;
  FTableRows.Clear;
  FTableCols := 0;
  FCells.Clear;
  FMaxRow := 0;
  FMaxCol := 0;
end;

procedure TAIOutputDocs.AddHeading(const AText: string; ALevel: Integer);
begin
  FParagraphs.Add('=== ' + AText + ' ===');
end;

procedure TAIOutputDocs.AddParagraph(const AText: string);
begin
  FParagraphs.Add(AText);
end;

procedure TAIOutputDocs.AddTable(const AHeaders: array of string; const ARows: array of string; ACols: Integer);
var
  I: Integer;
begin
  FTableHeaders.Clear;
  for I := 0 to High(AHeaders) do
    FTableHeaders.Add(AHeaders[I]);
    
  FTableRows.Clear;
  for I := 0 to High(ARows) do
    FTableRows.Add(ARows[I]);
    
  FTableCols := ACols;
end;

procedure TAIOutputDocs.SetCell(ARow, ACol: Integer; const AValue: string);
begin
  FCells.Values[IntToStr(ARow) + ',' + IntToStr(ACol)] := AValue;
  if ARow > FMaxRow then FMaxRow := ARow;
  if ACol > FMaxCol then FMaxCol := ACol;
end;

function TAIOutputDocs.SaveToPDF: Boolean;
var
  PDF: TAIPDFOutput;
  I: Integer;
  Y: Single;
begin
  PDF := TAIPDFOutput.Create(nil);
  try
    PDF.FileName := FFileNamePDF;
    PDF.Title := FTitle;
    PDF.Author := FAuthor;
    PDF.Subject := FSubject;
    PDF.StartDocument;
    PDF.AddPage;
    
    // Draw header banner
    PDF.AddText(FTitle, 40, 50, 18);
    PDF.AddText('Autor: ' + FAuthor, 40, 75, 10);
    PDF.AddText('--------------------------------------------------------------------------------', 40, 95, 10);
    
    Y := 120;
    for I := 0 to FParagraphs.Count - 1 do
    begin
      PDF.AddText(FParagraphs[I], 40, Y, 11);
      Y := Y + 25;
      if Y > 780 then
      begin
        PDF.AddPage;
        Y := 50;
      end;
    end;
    
    Result := PDF.SavePDF;
  finally
    PDF.Free;
  end;
end;

function TAIOutputDocs.SaveToWord: Boolean;
var
  Word: TAIWordOutput;
  I: Integer;
  HeadersArr: array of string;
  RowsArr: array of string;
begin
  Word := TAIWordOutput.Create(nil);
  try
    Word.FileName := FFileNameWord;
    Word.Title := FTitle;
    
    Word.AddHeading(FTitle, 1);
    Word.AddParagraph('Autor: ' + FAuthor);
    
    for I := 0 to FParagraphs.Count - 1 do
      Word.AddParagraph(FParagraphs[I]);
      
    if (FTableCols > 0) and (FTableRows.Count > 0) then
    begin
      SetLength(HeadersArr, FTableHeaders.Count);
      for I := 0 to FTableHeaders.Count - 1 do
        HeadersArr[I] := FTableHeaders[I];
        
      SetLength(RowsArr, FTableRows.Count);
      for I := 0 to FTableRows.Count - 1 do
        RowsArr[I] := FTableRows[I];
        
      Word.AddTable(HeadersArr, RowsArr, FTableCols);
    end;
    
    Result := Word.SaveWord;
  finally
    Word.Free;
  end;
end;

function TAIOutputDocs.SaveToExcel: Boolean;
var
  Excel: TAIExcelOutput;
  I: Integer;
begin
  Excel := TAIExcelOutput.Create(nil);
  try
    Excel.FileName := FFileNameExcel;
    
    if FCells.Count > 0 then
    begin
      Excel.FCells.Assign(FCells);
      Excel.FMaxRow := FMaxRow;
      Excel.FMaxCol := FMaxCol;
    end
    else
    begin
      // Fallback spreadsheet population
      Excel.SetCell(0, 0, 'Relatório');
      Excel.SetCell(0, 1, FTitle);
      Excel.SetCell(1, 0, 'Autor');
      Excel.SetCell(1, 1, FAuthor);
      for I := 0 to FParagraphs.Count - 1 do
      begin
        Excel.SetCell(3 + I, 0, 'Parágrafo ' + IntToStr(I + 1));
        Excel.SetCell(3 + I, 1, FParagraphs[I]);
      end;
    end;
    
    Result := Excel.SaveExcel;
  finally
    Excel.Free;
  end;
end;

function TAIOutputDocs.SaveToTXT: Boolean;
var
  TXT: TAITXTOutput;
  I: Integer;
begin
  TXT := TAITXTOutput.Create(nil);
  try
    TXT.FileName := FFileNameTXT;
    TXT.AddHeader(FTitle);
    TXT.AddLine('Autor: ' + FAuthor);
    TXT.AddLine('Assunto: ' + FSubject);
    TXT.AddLine('');
    
    for I := 0 to FParagraphs.Count - 1 do
      TXT.AddLine(FParagraphs[I]);
      
    Result := TXT.SaveText;
  finally
    TXT.Free;
  end;
end;

function TAIOutputDocs.SaveAll(const ABaseFileName: string): Boolean;
var
  Base: string;
begin
  if ABaseFileName <> '' then
  begin
    Base := ChangeFileExt(ABaseFileName, '');
    FFileNamePDF := Base + '.pdf';
    FFileNameWord := Base + '.docx';
    FFileNameExcel := Base + '.xlsx';
    FFileNameTXT := Base + '.txt';
  end;
  
  Result := SaveToPDF and SaveToWord and SaveToExcel and SaveToTXT;
end;

end.
