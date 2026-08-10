unit aixlsxwriter;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Math, Zipper;

type
  TAIXLSXCellType = (ctString, ctNumber, ctBoolean, ctDateTime);

  TAIXLSXCell = record
    CellType: TAIXLSXCellType;
    StringVal: string;
    NumberVal: Double;
    BoolVal: Boolean;
    DateTimeVal: TDateTime;
  end;
  PAIXLSXCell = ^TAIXLSXCell;

  { TAIXLSXWriter }

  TAIXLSXWriter = class
  private
    FCells: TStringList; // Key: "Row,Col" (0-indexed)
    FMaxRow: Integer;
    FMaxCol: Integer;
    FHeaderRow: Integer;

    function XMLEncode(const AText: string): string;
    function ColumnToExcelName(ACol: Integer): string;
    function BuildContentTypesXML: string;
    function BuildRelsXML: string;
    function BuildWorkbookRelsXML: string;
    function BuildWorkbookXML: string;
    function BuildStylesXML: string;
    function BuildSharedStringsXML(out ASharedStrings: TStringList): string;
    function BuildSheetXML(ASharedStrings: TStringList): string;
    function GetCellRecord(ARow, ACol: Integer; out ACell: TAIXLSXCell): Boolean;
    procedure SetCellRecord(ARow, ACol: Integer; const ACell: TAIXLSXCell);
  public
    constructor Create;
    destructor Destroy; override;

    procedure Clear;
    procedure SetString(ARow, ACol: Integer; const AValue: string);
    procedure SetNumber(ARow, ACol: Integer; AValue: Double);
    procedure SetBoolean(ARow, ACol: Integer; AValue: Boolean);
    procedure SetDateTime(ARow, ACol: Integer; AValue: TDateTime);
    function SaveToFile(const AFileName: string): Boolean;

    property HeaderRow: Integer read FHeaderRow write FHeaderRow;
    property MaxRow: Integer read FMaxRow;
    property MaxCol: Integer read FMaxCol;
  end;

implementation

constructor TAIXLSXWriter.Create;
begin
  FCells := TStringList.Create;
  FHeaderRow := 0;
  Clear;
end;

destructor TAIXLSXWriter.Destroy;
begin
  Clear;
  FCells.Free;
  inherited Destroy;
end;

procedure TAIXLSXWriter.Clear;
var
  I: Integer;
  PCell: PAIXLSXCell;
begin
  for I := 0 to FCells.Count - 1 do
  begin
    PCell := PAIXLSXCell(FCells.Objects[I]);
    if PCell <> nil then
      Dispose(PCell);
  end;
  FCells.Clear;
  FMaxRow := -1;
  FMaxCol := -1;
end;

function TAIXLSXWriter.ColumnToExcelName(ACol: Integer): string;
var
  Remainder: Integer;
begin
  Result := '';
  Inc(ACol);
  while ACol > 0 do
  begin
    Remainder := (ACol - 1) mod 26;
    Result := Char(Ord('A') + Remainder) + Result;
    ACol := (ACol - 1) div 26;
  end;
end;

function TAIXLSXWriter.XMLEncode(const AText: string): string;
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
      '''': Result := Result + '&apos;';
    else
      Result := Result + Ch;
    end;
  end;
end;

function TAIXLSXWriter.GetCellRecord(ARow, ACol: Integer; out ACell: TAIXLSXCell): Boolean;
var
  Key: string;
  Idx: Integer;
  PCell: PAIXLSXCell;
begin
  Result := False;
  Key := IntToStr(ARow) + ',' + IntToStr(ACol);
  Idx := FCells.IndexOf(Key);
  if Idx >= 0 then
  begin
    PCell := PAIXLSXCell(FCells.Objects[Idx]);
    if PCell <> nil then
    begin
      ACell := PCell^;
      Result := True;
    end;
  end;
end;

procedure TAIXLSXWriter.SetCellRecord(ARow, ACol: Integer; const ACell: TAIXLSXCell);
var
  Key: string;
  Idx: Integer;
  PCell: PAIXLSXCell;
begin
  if (ARow < 0) or (ACol < 0) then Exit;

  PCell := nil;
  Key := IntToStr(ARow) + ',' + IntToStr(ACol);
  Idx := FCells.IndexOf(Key);
  if Idx >= 0 then
  begin
    PCell := PAIXLSXCell(FCells.Objects[Idx]);
  end;

  if PCell = nil then
  begin
    New(PCell);
    FCells.AddObject(Key, TObject(PCell));
  end;

  PCell^ := ACell;
  if ARow > FMaxRow then FMaxRow := ARow;
  if ACol > FMaxCol then FMaxCol := ACol;
end;

procedure TAIXLSXWriter.SetString(ARow, ACol: Integer; const AValue: string);
var
  Cell: TAIXLSXCell;
begin
  Cell.CellType := ctString;
  Cell.StringVal := AValue;
  SetCellRecord(ARow, ACol, Cell);
end;

procedure TAIXLSXWriter.SetNumber(ARow, ACol: Integer; AValue: Double);
var
  Cell: TAIXLSXCell;
begin
  Cell.CellType := ctNumber;
  Cell.NumberVal := AValue;
  SetCellRecord(ARow, ACol, Cell);
end;

procedure TAIXLSXWriter.SetBoolean(ARow, ACol: Integer; AValue: Boolean);
var
  Cell: TAIXLSXCell;
begin
  Cell.CellType := ctBoolean;
  Cell.BoolVal := AValue;
  SetCellRecord(ARow, ACol, Cell);
end;

procedure TAIXLSXWriter.SetDateTime(ARow, ACol: Integer; AValue: TDateTime);
var
  Cell: TAIXLSXCell;
begin
  Cell.CellType := ctDateTime;
  Cell.DateTimeVal := AValue;
  SetCellRecord(ARow, ACol, Cell);
end;

function TAIXLSXWriter.BuildContentTypesXML: string;
begin
  Result :=
    '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>' + #13#10 +
    '<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">' + #13#10 +
    '  <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>' + #13#10 +
    '  <Default Extension="xml" ContentType="application/xml"/>' + #13#10 +
    '  <Override PartName="/xl/workbook.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/>' + #13#10 +
    '  <Override PartName="/xl/worksheets/sheet1.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/>' + #13#10 +
    '  <Override PartName="/xl/sharedStrings.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sharedStrings+xml"/>' + #13#10 +
    '  <Override PartName="/xl/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.styles+xml"/>' + #13#10 +
    '</Types>';
end;

function TAIXLSXWriter.BuildRelsXML: string;
begin
  Result :=
    '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>' + #13#10 +
    '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">' + #13#10 +
    '  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="xl/workbook.xml"/>' + #13#10 +
    '</Relationships>';
end;

function TAIXLSXWriter.BuildWorkbookRelsXML: string;
begin
  Result :=
    '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>' + #13#10 +
    '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">' + #13#10 +
    '  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet1.xml"/>' + #13#10 +
    '  <Relationship Id="rId2" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/sharedStrings" Target="sharedStrings.xml"/>' + #13#10 +
    '  <Relationship Id="rId3" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles.xml"/>' + #13#10 +
    '</Relationships>';
end;

function TAIXLSXWriter.BuildWorkbookXML: string;
begin
  Result :=
    '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>' + #13#10 +
    '<workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">' + #13#10 +
    '  <sheets>' + #13#10 +
    '    <sheet name="Sheet1" sheetId="1" r:id="rId1"/>' + #13#10 +
    '  </sheets>' + #13#10 +
    '</workbook>';
end;

function TAIXLSXWriter.BuildStylesXML: string;
begin
  Result :=
    '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>' + #13#10 +
    '<styleSheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">' + #13#10 +
    '  <fonts count="2">' + #13#10 +
    '    <font><sz val="11"/><name val="Calibri"/></font>' + #13#10 +
    '    <font><b/><sz val="11"/><name val="Calibri"/></font>' + #13#10 +
    '  </fonts>' + #13#10 +
    '  <fills count="2">' + #13#10 +
    '    <fill><patternFill patternType="none"/></fill>' + #13#10 +
    '    <fill><patternFill patternType="gray125"/></fill>' + #13#10 +
    '  </fills>' + #13#10 +
    '  <borders count="1">' + #13#10 +
    '    <border><left/><right/><top/><bottom/></border>' + #13#10 +
    '  </borders>' + #13#10 +
    '  <cellStyleXfs count="1">' + #13#10 +
    '    <xf numFmtId="0" fontId="0" fillId="0" borderId="0"/>' + #13#10 +
    '  </cellStyleXfs>' + #13#10 +
    '  <cellXfs count="2">' + #13#10 +
    '    <xf numFmtId="0" fontId="0" fillId="0" borderId="0" xfId="0"/>' + #13#10 +
    '    <xf numFmtId="0" fontId="1" fillId="0" borderId="0" xfId="0"/>' + #13#10 +
    '  </cellXfs>' + #13#10 +
    '</styleSheet>';
end;

function TAIXLSXWriter.BuildSharedStringsXML(out ASharedStrings: TStringList): string;
var
  R, C: Integer;
  Cell: TAIXLSXCell;
  I: Integer;
begin
  ASharedStrings := TStringList.Create;
  for R := 0 to FMaxRow do
  begin
    for C := 0 to FMaxCol do
    begin
      if GetCellRecord(R, C, Cell) then
      begin
        if Cell.CellType = ctString then
        begin
          if ASharedStrings.IndexOf(Cell.StringVal) < 0 then
            ASharedStrings.Add(Cell.StringVal);
        end;
      end;
    end;
  end;

  Result :=
    '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>' + #13#10 +
    Format('<sst xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" count="%d" uniqueCount="%d">' + #13#10,
      [ASharedStrings.Count, ASharedStrings.Count]);

  for I := 0 to ASharedStrings.Count - 1 do
    Result := Result + Format('  <si><t>%s</t></si>' + #13#10, [XMLEncode(ASharedStrings[I])]);

  Result := Result + '</sst>';
end;

function TAIXLSXWriter.BuildSheetXML(ASharedStrings: TStringList): string;
var
  R, C, StyleIdx: Integer;
  CellRef: string;
  Cell: TAIXLSXCell;
  StrIdx: Integer;
  FmtSettings: TFormatSettings;
begin
  FmtSettings.DecimalSeparator := '.';

  Result :=
    '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>' + #13#10 +
    '<worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">' + #13#10 +
    '  <sheetData>' + #13#10;

  for R := 0 to FMaxRow do
  begin
    Result := Result + Format('    <row r="%d">' + #13#10, [R + 1]);
    for C := 0 to FMaxCol do
    begin
      if GetCellRecord(R, C, Cell) then
      begin
        CellRef := ColumnToExcelName(C) + IntToStr(R + 1);
        if R = FHeaderRow then
          StyleIdx := 1
        else
          StyleIdx := 0;

        case Cell.CellType of
          ctString:
            begin
              StrIdx := ASharedStrings.IndexOf(Cell.StringVal);
              Result := Result + Format('      <c r="%s" t="s" s="%d"><v>%d</v></c>' + #13#10, [CellRef, StyleIdx, StrIdx]);
            end;
          ctNumber:
            begin
              Result := Result + Format('      <c r="%s" s="%d"><v>%s</v></c>' + #13#10, [CellRef, StyleIdx, FloatToStr(Cell.NumberVal, FmtSettings)]);
            end;
          ctBoolean:
            begin
              Result := Result + Format('      <c r="%s" t="b" s="%d"><v>%d</v></c>' + #13#10, [CellRef, StyleIdx, Ord(Cell.BoolVal)]);
            end;
          ctDateTime:
            begin
              // Excel date serial number offset (25569 = 1899-12-30 to 1970-01-01)
              Result := Result + Format('      <c r="%s" s="%d"><v>%s</v></c>' + #13#10, [CellRef, StyleIdx, FloatToStr(Cell.DateTimeVal + 2415018.5 - 2415018.5, FmtSettings)]);
            end;
        end;
      end;
    end;
    Result := Result + '    </row>' + #13#10;
  end;

  Result := Result +
    '  </sheetData>' + #13#10 +
    '</worksheet>';
end;

function TAIXLSXWriter.SaveToFile(const AFileName: string): Boolean;
var
  Zip: TZipper;
  SharedStringsList: TStringList;
  ContentTypesStream, RelsStream, WorkbookRelsStream, WorkbookStream, StylesStream, SharedStringsStream, SheetStream: TStringStream;
begin
  Result := False;
  if Trim(AFileName) = '' then Exit;
  if FMaxRow < 0 then FMaxRow := 0;
  if FMaxCol < 0 then FMaxCol := 0;

  Zip := TZipper.Create;
  SharedStringsList := nil;
  ContentTypesStream := TStringStream.Create(BuildContentTypesXML);
  RelsStream := TStringStream.Create(BuildRelsXML);
  WorkbookRelsStream := TStringStream.Create(BuildWorkbookRelsXML);
  WorkbookStream := TStringStream.Create(BuildWorkbookXML);
  StylesStream := TStringStream.Create(BuildStylesXML);
  SharedStringsStream := TStringStream.Create(BuildSharedStringsXML(SharedStringsList));
  SheetStream := TStringStream.Create(BuildSheetXML(SharedStringsList));

  try
    try
      Zip.FileName := AFileName;
      Zip.Entries.AddFileEntry(ContentTypesStream, '[Content_Types].xml');
      Zip.Entries.AddFileEntry(RelsStream, '_rels/.rels');
      Zip.Entries.AddFileEntry(WorkbookRelsStream, 'xl/_rels/workbook.xml.rels');
      Zip.Entries.AddFileEntry(WorkbookStream, 'xl/workbook.xml');
      Zip.Entries.AddFileEntry(StylesStream, 'xl/styles.xml');
      Zip.Entries.AddFileEntry(SharedStringsStream, 'xl/sharedStrings.xml');
      Zip.Entries.AddFileEntry(SheetStream, 'xl/worksheets/sheet1.xml');
      Zip.ZipAllFiles;
      Result := True;
    except
      on E: Exception do
        Result := False;
    end;
  finally
    SheetStream.Free;
    SharedStringsStream.Free;
    if SharedStringsList <> nil then SharedStringsList.Free;
    StylesStream.Free;
    WorkbookStream.Free;
    WorkbookRelsStream.Free;
    RelsStream.Free;
    ContentTypesStream.Free;
    Zip.Free;
  end;
end;

end.
