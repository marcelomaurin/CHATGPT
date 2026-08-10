unit aioutput_docs;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Math,
  // Native FPC PDF generator library
  fpPDF, aibase, LResources, aidocxwriter, aixlsxwriter;

type
  TAIWordOutputFormat = (
    wofHTMLCompatible,
    wofDOCX
  );

  TAIExcelOutputFormat = (
    eofHTMLCompatible,
    eofXLSX,
    eofCSV
  );

  { TAIPDFOutput }

  TAIPDFOutput = class(TAIBaseComponent)
  private
    FFileName: string;
    FTitle: string;
    FAuthor: string;
    FSubject: string;
    FAutoCreateDirectories: Boolean;
    FMarginLeft: Single;
    FMarginTop: Single;
    FMarginRight: Single;
    FMarginBottom: Single;

    FCursorX: Single;
    FCursorY: Single;

    FPDFDoc: TPDFDocument;
    FPage: TPDFPage;
    FFontIndex: Integer;
    
    function CurrentPageHeight: Single;
    function WrapText(const AText: string; AWidth: Single; AFontSize: Single): TStringList;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    
    procedure Clear;
    procedure StartDocument;
    procedure AddPage;
    procedure AddText(const AText: string; X, Y: Single; FontSize: Single = 12.0);
    procedure AddParagraph(const AText: string; FontSize: Single = 12.0);
    procedure AddHeading(const AText: string; ALevel: Integer = 1);
    function SavePDF: Boolean;
  published
    property FileName: string read FFileName write FFileName;
    property Title: string read FTitle write FTitle;
    property Author: string read FAuthor write FAuthor;
    property Subject: string read FSubject write FSubject;
    property AutoCreateDirectories: Boolean read FAutoCreateDirectories write FAutoCreateDirectories default True;
    property MarginLeft: Single read FMarginLeft write FMarginLeft;
    property MarginTop: Single read FMarginTop write FMarginTop;
    property MarginRight: Single read FMarginRight write FMarginRight;
    property MarginBottom: Single read FMarginBottom write FMarginBottom;
  end;

  { TAIWordOutput }

  TAIWordOutput = class(TAIBaseComponent)
  private
    FFileName: string;
    FTitle: string;
    FOutputFormat: TAIWordOutputFormat;
    FContent: TStringList;
    FDOCXWriter: TAIDOCXWriter;

    function HTMLEncode(const AText: string): string;
    function SaveHTMLCompatible: Boolean;
    function SaveDOCX: Boolean;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    
    procedure AddHeading(const AText: string; ALevel: Integer = 1);
    procedure AddParagraph(const AText: string);
    procedure AddTable(const AHeaders: array of string; const ARows: array of string; ACols: Integer);
    function SaveWord: Boolean;
  published
    property FileName: string read FFileName write FFileName;
    property Title: string read FTitle write FTitle;
    property OutputFormat: TAIWordOutputFormat read FOutputFormat write FOutputFormat default wofHTMLCompatible;
  end;

  { TAIExcelOutput }

  TAIExcelOutput = class(TAIBaseComponent)
  private
    FFileName: string;
    FOutputFormat: TAIExcelOutputFormat;
    FCells: TStringList;
    FMaxRow: Integer;
    FMaxCol: Integer;
    FXLSXWriter: TAIXLSXWriter;

    function HTMLEncode(const AText: string): string;
    function SaveHTMLCompatible: Boolean;
    function SaveXLSX: Boolean;
    function SaveCSV: Boolean;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    
    procedure Clear;
    procedure SetCell(ARow, ACol: Integer; const AValue: string);
    function GetCell(ARow, ACol: Integer): string;
    function SaveExcel: Boolean;
  published
    property FileName: string read FFileName write FFileName;
    property OutputFormat: TAIExcelOutputFormat read FOutputFormat write FOutputFormat default eofHTMLCompatible;
  end;

  { TAITXTOutput }

  TAITXTOutput = class(TAIBaseComponent)
  private
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
    property FileName: string read FFileName write FFileName;
  end;

  { TAIOutputDocs }

  TAIOutputDocs = class(TAIBaseComponent)
  private
    FFileNamePDF: string;
    FLegacyToken: string;
    FFileNameWord: string;
    FFileNameExcel: string;
    FFileNameTXT: string;
    FTitle: string;
    FAuthor: string;
    FSubject: string;
    
    FPDFOutput: TAIPDFOutput;
    FWordOutput: TAIWordOutput;
    FExcelOutput: TAIExcelOutput;
    FTXTOutput: TAITXTOutput;
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
    property FileNamePDF: string read FFileNamePDF write FFileNamePDF;
    // Legacy compatibility only. Not used for document generation.
    property Token: string read FLegacyToken write FLegacyToken;
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
  RegisterComponents('AI Documents', [
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
  FAutoCreateDirectories := True;
  FMarginLeft := 40;
  FMarginTop := 40;
  FMarginRight := 40;
  FMarginBottom := 40;
  FCursorX := 40;
  FCursorY := 40;
  FPDFDoc := nil;
  FPage := nil;
  FFontIndex := -1;
end;

destructor TAIPDFOutput.Destroy;
begin
  Clear;
  inherited Destroy;
end;

procedure TAIPDFOutput.Clear;
begin
  if Assigned(FPDFDoc) then
  begin
    FPDFDoc.Free;
    FPDFDoc := nil;
  end;
  FPage := nil;
  FFontIndex := -1;
  FCursorX := FMarginLeft;
  FCursorY := FMarginTop;
end;

function TAIPDFOutput.CurrentPageHeight: Single;
begin
  Result := 842.0; // A4 portrait height in points
end;

procedure TAIPDFOutput.StartDocument;
begin
  Clear;
  FPDFDoc := TPDFDocument.Create(nil);
  FPDFDoc.StartDocument;
  
  FPDFDoc.Infos.Title := FTitle;
  FPDFDoc.Infos.Author := FAuthor;
  
  FFontIndex := FPDFDoc.AddFont('Helvetica');
end;

procedure TAIPDFOutput.AddPage;
begin
  if not Assigned(FPDFDoc) then
    StartDocument;
    
  FPage := FPDFDoc.Pages.AddPage;
  FPage.PaperType := ptA4;
  FPage.Orientation := ppoPortrait;
  FCursorX := FMarginLeft;
  FCursorY := FMarginTop;
end;

procedure TAIPDFOutput.AddText(const AText: string; X, Y: Single; FontSize: Single);
begin
  if not Assigned(FPage) then
    AddPage;
    
  FPage.SetFont(FFontIndex, Round(FontSize));
  FPage.SetColor(clBlack, False);
  FPage.WriteText(X, CurrentPageHeight - Y, AText);
end;

function TAIPDFOutput.WrapText(const AText: string; AWidth: Single; AFontSize: Single): TStringList;
var
  Words: TStringList;
  I: Integer;
  CurrentLine: string;
  CharWidthEstimate: Single;
  MaxCharsPerLine: Integer;
begin
  Result := TStringList.Create;
  Words := TStringList.Create;
  try
    Words.Delimiter := ' ';
    Words.DelimitedText := AText;

    CharWidthEstimate := AFontSize * 0.55;
    if CharWidthEstimate < 1.0 then CharWidthEstimate := 1.0;
    MaxCharsPerLine := Max(1, Trunc(AWidth / CharWidthEstimate));

    CurrentLine := '';
    for I := 0 to Words.Count - 1 do
    begin
      if CurrentLine = '' then
        CurrentLine := Words[I]
      else if Length(CurrentLine) + 1 + Length(Words[I]) <= MaxCharsPerLine then
        CurrentLine := CurrentLine + ' ' + Words[I]
      else
      begin
        Result.Add(CurrentLine);
        CurrentLine := Words[I];
      end;
    end;
    if CurrentLine <> '' then
      Result.Add(CurrentLine);
  finally
    Words.Free;
  end;
end;

procedure TAIPDFOutput.AddParagraph(const AText: string; FontSize: Single);
var
  Lines: TStringList;
  I: Integer;
  LineHeight, UsableWidth: Single;
begin
  if not Assigned(FPage) then
    AddPage;

  LineHeight := FontSize * 1.4;
  UsableWidth := 595.0 - FMarginLeft - FMarginRight;
  Lines := WrapText(AText, UsableWidth, FontSize);
  try
    for I := 0 to Lines.Count - 1 do
    begin
      if FCursorY + LineHeight > CurrentPageHeight - FMarginBottom then
        AddPage;

      AddText(Lines[I], FMarginLeft, FCursorY, FontSize);
      FCursorY := FCursorY + LineHeight;
    end;
    FCursorY := FCursorY + (FontSize * 0.5); // Paragraph spacing
  finally
    Lines.Free;
  end;
end;

procedure TAIPDFOutput.AddHeading(const AText: string; ALevel: Integer);
var
  HSize: Single;
  L: Integer;
begin
  L := ALevel;
  if L < 1 then L := 1;
  if L > 6 then L := 6;

  HSize := Max(12.0, 24.0 - (L * 2.0));
  AddParagraph(AText, HSize);
end;

function TAIPDFOutput.SavePDF: Boolean;
var
  Dir: string;
begin
  Result := False;
  ClearError;
  try
    if Trim(FFileName) = '' then
    begin
      SetError('Nome do arquivo PDF não pode ser vazio.');
      Exit;
    end;

    if not Assigned(FPDFDoc) then
    begin
      SetError('Documento PDF não foi iniciado. Chame StartDocument antes de salvar.');
      Exit;
    end;
    
    if FAutoCreateDirectories then
    begin
      Dir := ExtractFileDir(ExpandFileName(FFileName));
      if (Dir <> '') and (not DirectoryExists(Dir)) then
        ForceDirectories(Dir);
    end;

    FPDFDoc.SaveToFile(FFileName);
    FLastResult := 'PDF Document Saved: ' + FFileName;
    FLastSuccess := True;
    Result := True;
  except
    on E: Exception do
    begin
      SetError('Erro ao salvar PDF: ' + E.Message);
      Result := False;
    end;
  end;
end;

{ TAIWordOutput }

constructor TAIWordOutput.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FPrompt := 'Component TAIWordOutput creates Microsoft Word compatible documents (.docx/HTML) natively. Properties: FileName: string, Title: string. Methods: AddHeading(const AText: string; ALevel: Integer = 1), AddParagraph(const AText: string), AddTable(const AHeaders: array of string; const ARows: array of string; ACols: Integer), SaveWord: Boolean. AI Agent: Use this to generate formatted text documents or reports.';
  FFileName := '';
  FTitle := 'Relatório de IA';
  FOutputFormat := wofHTMLCompatible;
  FContent := TStringList.Create;
  FDOCXWriter := TAIDOCXWriter.Create;
end;

destructor TAIWordOutput.Destroy;
begin
  FContent.Free;
  FDOCXWriter.Free;
  inherited Destroy;
end;

function TAIWordOutput.HTMLEncode(const AText: string): string;
var
  I: Integer;
  Ch: Char;
begin
  Result := '';
  for I := 1 to Length(AText) do
  begin
    Ch := AText[I];
    case Ch of
      '&': Result := Result + '&amp;';
      '<': Result := Result + '&lt;';
      '>': Result := Result + '&gt;';
      '"': Result := Result + '&quot;';
    else
      Result := Result + Ch;
    end;
  end;
end;

procedure TAIWordOutput.AddHeading(const AText: string; ALevel: Integer);
var
  HSize, L: Integer;
begin
  L := ALevel;
  if L < 1 then L := 1;
  if L > 6 then L := 6;

  HSize := Max(10, 24 - (L * 4));
  FContent.Add(Format('<h%d style="font-family: sans-serif; color: #1a237e; font-size: %dpx;">%s</h%d>', [L, HSize, HTMLEncode(AText), L]));
  FDOCXWriter.AddHeading(AText, L);
end;

procedure TAIWordOutput.AddParagraph(const AText: string);
begin
  FContent.Add(Format('<p style="font-family: sans-serif; font-size: 11pt; line-height: 1.5; color: #333;">%s</p>', [HTMLEncode(AText)]));
  FDOCXWriter.AddParagraph(AText);
end;

procedure TAIWordOutput.AddTable(const AHeaders: array of string; const ARows: array of string; ACols: Integer);
var
  I, J, RowCount: Integer;
  TableStr, CellText: string;
begin
  if ACols <= 0 then Exit;

  TableStr := '<table border="1" cellpadding="6" cellspacing="0" style="border-collapse: collapse; font-family: sans-serif; font-size: 10pt; width: 100%; border: 1px solid #ccc;">';
  
  // Headers
  TableStr := TableStr + '<tr style="background-color: #f5f5f5; font-weight: bold; color: #1a237e;">';
  for I := 0 to ACols - 1 do
  begin
    if I <= High(AHeaders) then
      CellText := HTMLEncode(AHeaders[I])
    else
      CellText := '';
    TableStr := TableStr + '<th>' + CellText + '</th>';
  end;
  TableStr := TableStr + '</tr>';
  
  // Rows
  if Length(ARows) > 0 then
  begin
    RowCount := (Length(ARows) + ACols - 1) div ACols;
    for I := 0 to RowCount - 1 do
    begin
      TableStr := TableStr + '<tr>';
      for J := 0 to ACols - 1 do
      begin
        if (I * ACols + J) <= High(ARows) then
          CellText := HTMLEncode(ARows[I * ACols + J])
        else
          CellText := '';
        TableStr := TableStr + '<td>' + CellText + '</td>';
      end;
      TableStr := TableStr + '</tr>';
    end;
  end;
  
  TableStr := TableStr + '</table>';
  FContent.Add(TableStr);
  FDOCXWriter.AddTable(AHeaders, ARows, ACols);
end;

function TAIWordOutput.SaveHTMLCompatible: Boolean;
var
  DocBody: TStringList;
  ActualFileName: string;
begin
  Result := False;
  ClearError;
  DocBody := TStringList.Create;
  try
    try
      ActualFileName := FFileName;
      if Trim(ActualFileName) = '' then
        ActualFileName := 'documento_ia.html';

      DocBody.Add('<!--[if gte mso 9]>');
      DocBody.Add('<xml>');
      DocBody.Add(' <w:WordDocument>');
      DocBody.Add('  <w:View>Print</w:View>');
      DocBody.Add(' </w:WordDocument>');
      DocBody.Add('</xml>');
      DocBody.Add('<![endif]-->');
      DocBody.Add('<html>');
      DocBody.Add('<head><title>' + HTMLEncode(FTitle) + '</title></head>');
      DocBody.Add('<body style="padding: 40px;">');
      DocBody.AddStrings(FContent);
      DocBody.Add('</body>');
      DocBody.Add('</html>');
      
      DocBody.SaveToFile(ActualFileName);
      FLastResult := 'Word HTML Document Saved: ' + ActualFileName;
      FLastSuccess := True;
      Result := True;
    except
      on E: Exception do
      begin
        SetError('Erro ao salvar arquivo Word HTML: ' + E.Message);
        Result := False;
      end;
    end;
  finally
    DocBody.Free;
  end;
end;

function TAIWordOutput.SaveDOCX: Boolean;
var
  ActualFileName: string;
begin
  Result := False;
  ClearError;
  ActualFileName := FFileName;
  if Trim(ActualFileName) = '' then
    ActualFileName := 'documento_ia.docx';

  FDOCXWriter.Title := FTitle;
  if FDOCXWriter.SaveToFile(ActualFileName) then
  begin
    FLastResult := 'Word DOCX Document Saved: ' + ActualFileName;
    FLastSuccess := True;
    Result := True;
  end
  else
    SetError('Erro ao gerar pacote DOCX nativo.');
end;

function TAIWordOutput.SaveWord: Boolean;
begin
  case FOutputFormat of
    wofHTMLCompatible: Result := SaveHTMLCompatible;
    wofDOCX: Result := SaveDOCX;
  else
    Result := SaveHTMLCompatible;
  end;
end;

{ TAIExcelOutput }

constructor TAIExcelOutput.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FPrompt := 'Component TAIExcelOutput generates Excel compatible spreadsheets (.xlsx/HTML) natively. Properties: FileName: string. Methods: SetCell(ARow, ACol: Integer; const AValue: string), SaveExcel: Boolean. AI Agent: Use this to output structured tabular data, reports, or telemetry logs.';
  FFileName := '';
  FOutputFormat := eofHTMLCompatible;
  FCells := TStringList.Create;
  FMaxRow := -1;
  FMaxCol := -1;
  FXLSXWriter := TAIXLSXWriter.Create;
end;

destructor TAIExcelOutput.Destroy;
begin
  FCells.Free;
  FXLSXWriter.Free;
  inherited Destroy;
end;

procedure TAIExcelOutput.Clear;
begin
  FCells.Clear;
  FMaxRow := -1;
  FMaxCol := -1;
  FXLSXWriter.Clear;
end;

function TAIExcelOutput.HTMLEncode(const AText: string): string;
var
  I: Integer;
  Ch: Char;
begin
  Result := '';
  for I := 1 to Length(AText) do
  begin
    Ch := AText[I];
    case Ch of
      '&': Result := Result + '&amp;';
      '<': Result := Result + '&lt;';
      '>': Result := Result + '&gt;';
      '"': Result := Result + '&quot;';
    else
      Result := Result + Ch;
    end;
  end;
end;

procedure TAIExcelOutput.SetCell(ARow, ACol: Integer; const AValue: string);
begin
  if (ARow < 0) or (ACol < 0) then
  begin
    SetError('Índice de célula inválido em SetCell.');
    Exit;
  end;
  FCells.Values[IntToStr(ARow) + ',' + IntToStr(ACol)] := AValue;
  if ARow > FMaxRow then FMaxRow := ARow;
  if ACol > FMaxCol then FMaxCol := ACol;

  FXLSXWriter.SetString(ARow, ACol, AValue);
end;

function TAIExcelOutput.GetCell(ARow, ACol: Integer): string;
begin
  if (ARow < 0) or (ACol < 0) then
  begin
    Result := '';
    Exit;
  end;
  Result := FCells.Values[IntToStr(ARow) + ',' + IntToStr(ACol)];
end;

function TAIExcelOutput.SaveHTMLCompatible: Boolean;
var
  Doc: TStringList;
  R, C: Integer;
  Val, ActualFileName: string;
begin
  Result := False;
  ClearError;
  ActualFileName := FFileName;
  if Trim(ActualFileName) = '' then
    ActualFileName := 'dados_ia.html';

  Doc := TStringList.Create;
  try
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
          Val := HTMLEncode(GetCell(R, C));
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
      
      Doc.SaveToFile(ActualFileName);
      FLastResult := 'Excel HTML Document Saved: ' + ActualFileName;
      FLastSuccess := True;
      Result := True;
    except
      on E: Exception do
      begin
        SetError('Erro ao salvar arquivo Excel HTML: ' + E.Message);
        Result := False;
      end;
    end;
  finally
    Doc.Free;
  end;
end;

function TAIExcelOutput.SaveXLSX: Boolean;
var
  ActualFileName: string;
begin
  Result := False;
  ClearError;
  ActualFileName := FFileName;
  if Trim(ActualFileName) = '' then
    ActualFileName := 'dados_ia.xlsx';

  if FXLSXWriter.SaveToFile(ActualFileName) then
  begin
    FLastResult := 'Excel XLSX Document Saved: ' + ActualFileName;
    FLastSuccess := True;
    Result := True;
  end
  else
    SetError('Erro ao gerar arquivo XLSX nativo.');
end;

function TAIExcelOutput.SaveCSV: Boolean;
var
  Doc: TStringList;
  R, C: Integer;
  RowStr, Val, ActualFileName: string;
begin
  Result := False;
  ClearError;
  ActualFileName := FFileName;
  if Trim(ActualFileName) = '' then
    ActualFileName := 'dados_ia.csv';

  Doc := TStringList.Create;
  try
    try
      for R := 0 to FMaxRow do
      begin
        RowStr := '';
        for C := 0 to FMaxCol do
        begin
          Val := GetCell(R, C);
          if (Pos(',', Val) > 0) or (Pos('"', Val) > 0) then
            Val := '"' + StringReplace(Val, '"', '""', [rfReplaceAll]) + '"';
          if C > 0 then RowStr := RowStr + ',';
          RowStr := RowStr + Val;
        end;
        Doc.Add(RowStr);
      end;

      Doc.SaveToFile(ActualFileName);
      FLastResult := 'Excel CSV Document Saved: ' + ActualFileName;
      FLastSuccess := True;
      Result := True;
    except
      on E: Exception do
      begin
        SetError('Erro ao salvar arquivo CSV: ' + E.Message);
        Result := False;
      end;
    end;
  finally
    Doc.Free;
  end;
end;

function TAIExcelOutput.SaveExcel: Boolean;
begin
  case FOutputFormat of
    eofHTMLCompatible: Result := SaveHTMLCompatible;
    eofXLSX: Result := SaveXLSX;
    eofCSV: Result := SaveCSV;
  else
    Result := SaveHTMLCompatible;
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
  Result := False;
  ClearError;
  try
    FLines.SaveToFile(FFileName);
    FLastResult := 'Text Document Saved: ' + FFileName;
    FLastSuccess := True;
    Result := True;
  except
    on E: Exception do
    begin
      SetError('Erro ao salvar arquivo texto: ' + E.Message);
      Result := False;
    end;
  end;
end;

{ TAIOutputDocs }

constructor TAIOutputDocs.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FPrompt := 'Component TAIOutputDocs is a unified document output suite combining PDF, Word, Excel, and TXT outputs. Properties: FileNamePDF: string, FileNameWord: string, FileNameExcel: string, FileNameTXT: string, Title: string, Author: string, Subject: string. Methods: Clear, AddHeading(const AText: string; ALevel: Integer = 1), AddParagraph(const AText: string), AddTable(const AHeaders: array of string; const ARows: array of string; ACols: Integer), SetCell(ARow, ACol: Integer; const AValue: string), SaveToPDF: Boolean, SaveToWord: Boolean, SaveToExcel: Boolean, SaveToTXT: Boolean, SaveAll(const ABaseFileName: string = ""): Boolean. AI Agent: Use this unified component to output reports in all four major document types at once.';
  FFileNamePDF := 'documento_ia.pdf';
  FLegacyToken := '';
  FFileNameWord := 'documento_ia.docx';
  FFileNameExcel := 'dados_ia.xlsx';
  FFileNameTXT := 'relatorio_ia.txt';
  FTitle := 'Relatório de IA Unificado';
  FAuthor := 'Antigravity AI Suite';
  FSubject := 'Resultados de Modelos de IA';

  FPDFOutput := TAIPDFOutput.Create(Self);
  FWordOutput := TAIWordOutput.Create(Self);
  FExcelOutput := TAIExcelOutput.Create(Self);
  FTXTOutput := TAITXTOutput.Create(Self);
end;

destructor TAIOutputDocs.Destroy;
begin
  inherited Destroy;
end;

procedure TAIOutputDocs.Clear;
begin
  FPDFOutput.Clear;
  FWordOutput.AddHeading('', 1); // Reset content
  FExcelOutput.Clear;
  FTXTOutput.Clear;
end;

procedure TAIOutputDocs.AddHeading(const AText: string; ALevel: Integer);
begin
  FPDFOutput.AddHeading(AText, ALevel);
  FWordOutput.AddHeading(AText, ALevel);
  FTXTOutput.AddHeader(AText);
end;

procedure TAIOutputDocs.AddParagraph(const AText: string);
begin
  FPDFOutput.AddParagraph(AText);
  FWordOutput.AddParagraph(AText);
  FTXTOutput.AddLine(AText);
end;

procedure TAIOutputDocs.AddTable(const AHeaders: array of string; const ARows: array of string; ACols: Integer);
var
  I: Integer;
  RowStr: string;
begin
  FWordOutput.AddTable(AHeaders, ARows, ACols);

  RowStr := '';
  for I := 0 to High(AHeaders) do
  begin
    if I > 0 then RowStr := RowStr + ' | ';
    RowStr := RowStr + AHeaders[I];
  end;
  FTXTOutput.AddLine(RowStr);

  for I := 0 to High(ARows) do
  begin
    if (I mod Max(1, ACols)) = 0 then
      RowStr := ARows[I]
    else
      RowStr := RowStr + ' | ' + ARows[I];

    if ((I + 1) mod Max(1, ACols) = 0) or (I = High(ARows)) then
      FTXTOutput.AddLine(RowStr);
  end;
end;

procedure TAIOutputDocs.SetCell(ARow, ACol: Integer; const AValue: string);
begin
  FExcelOutput.SetCell(ARow, ACol, AValue);
end;

function TAIOutputDocs.SaveToPDF: Boolean;
begin
  FPDFOutput.FileName := FFileNamePDF;
  FPDFOutput.Title := FTitle;
  FPDFOutput.Author := FAuthor;
  FPDFOutput.Subject := FSubject;
  Result := FPDFOutput.SavePDF;
  if Result then
  begin
    FLastResult := FPDFOutput.LastResult;
    FLastSuccess := True;
  end
  else
    SetError(FPDFOutput.LastError);
end;

function TAIOutputDocs.SaveToWord: Boolean;
begin
  FWordOutput.FileName := FFileNameWord;
  FWordOutput.Title := FTitle;
  Result := FWordOutput.SaveWord;
  if Result then
  begin
    FLastResult := FWordOutput.LastResult;
    FLastSuccess := True;
  end
  else
    SetError(FWordOutput.LastError);
end;

function TAIOutputDocs.SaveToExcel: Boolean;
begin
  FExcelOutput.FileName := FFileNameExcel;
  Result := FExcelOutput.SaveExcel;
  if Result then
  begin
    FLastResult := FExcelOutput.LastResult;
    FLastSuccess := True;
  end
  else
    SetError(FExcelOutput.LastError);
end;

function TAIOutputDocs.SaveToTXT: Boolean;
begin
  FTXTOutput.FileName := FFileNameTXT;
  Result := FTXTOutput.SaveText;
  if Result then
  begin
    FLastResult := FTXTOutput.LastResult;
    FLastSuccess := True;
  end
  else
    SetError(FTXTOutput.LastError);
end;

function TAIOutputDocs.SaveAll(const ABaseFileName: string): Boolean;
var
  Base: string;
begin
  Result := False;
  ClearError;
  try
    if ABaseFileName <> '' then
    begin
      Base := ChangeFileExt(ABaseFileName, '');
      FFileNamePDF := Base + '.pdf';
      FFileNameWord := Base + '.docx';
      FFileNameExcel := Base + '.xlsx';
      FFileNameTXT := Base + '.txt';
    end;
    
    Result := SaveToPDF and SaveToWord and SaveToExcel and SaveToTXT;
    if Result then
    begin
      FLastResult := 'All documents generated successfully.';
      FLastSuccess := True;
    end
    else
      SetError('Falha ao gerar um ou mais documentos no SaveAll.');
  except
    on E: Exception do
    begin
      SetError('SaveAll Error: ' + E.Message);
      Result := False;
    end;
  end;
end;

initialization
  {$I aioutput_docs_icon.lrs}

end.
