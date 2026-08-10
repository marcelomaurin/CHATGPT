unit aidocxwriter;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Zipper;

type
  { TAIDOCXElement }
  TAIDOCXElementType = (etHeading, etParagraph, etTable);

  TAIDOCXElement = record
    ElementType: TAIDOCXElementType;
    Text: string;
    Level: Integer;
    Headers: array of string;
    Rows: array of string;
    Cols: Integer;
  end;

  { TAIDOCXWriter }

  TAIDOCXWriter = class
  private
    FTitle: string;
    FAuthor: string;
    FElements: array of TAIDOCXElement;
    function XMLEncode(const AText: string): string;
    function BuildContentTypesXML: string;
    function BuildRelsXML: string;
    function BuildWordRelsXML: string;
    function BuildCoreXML: string;
    function BuildStylesXML: string;
    function BuildDocumentXML: string;
  public
    constructor Create;
    destructor Destroy; override;

    procedure Clear;
    procedure AddHeading(const AText: string; ALevel: Integer = 1);
    procedure AddParagraph(const AText: string);
    procedure AddTable(const AHeaders: array of string; const ARows: array of string; ACols: Integer);
    function SaveToFile(const AFileName: string): Boolean;

    property Title: string read FTitle write FTitle;
    property Author: string read FAuthor write FAuthor;
  end;

implementation

constructor TAIDOCXWriter.Create;
begin
  FTitle := 'Document';
  FAuthor := 'Antigravity AI Suite';
  Clear;
end;

destructor TAIDOCXWriter.Destroy;
begin
  Clear;
  inherited Destroy;
end;

procedure TAIDOCXWriter.Clear;
begin
  SetLength(FElements, 0);
end;

function TAIDOCXWriter.XMLEncode(const AText: string): string;
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

procedure TAIDOCXWriter.AddHeading(const AText: string; ALevel: Integer);
var
  Idx: Integer;
  L: Integer;
begin
  L := ALevel;
  if L < 1 then L := 1;
  if L > 6 then L := 6;

  Idx := Length(FElements);
  SetLength(FElements, Idx + 1);
  FElements[Idx].ElementType := etHeading;
  FElements[Idx].Text := AText;
  FElements[Idx].Level := L;
end;

procedure TAIDOCXWriter.AddParagraph(const AText: string);
var
  Idx: Integer;
begin
  Idx := Length(FElements);
  SetLength(FElements, Idx + 1);
  FElements[Idx].ElementType := etParagraph;
  FElements[Idx].Text := AText;
  FElements[Idx].Level := 0;
end;

procedure TAIDOCXWriter.AddTable(const AHeaders: array of string; const ARows: array of string; ACols: Integer);
var
  Idx, I: Integer;
begin
  if ACols <= 0 then Exit;

  Idx := Length(FElements);
  SetLength(FElements, Idx + 1);
  FElements[Idx].ElementType := etTable;
  FElements[Idx].Cols := ACols;

  SetLength(FElements[Idx].Headers, Length(AHeaders));
  for I := 0 to High(AHeaders) do
    FElements[Idx].Headers[I] := AHeaders[I];

  SetLength(FElements[Idx].Rows, Length(ARows));
  for I := 0 to High(ARows) do
    FElements[Idx].Rows[I] := ARows[I];
end;

function TAIDOCXWriter.BuildContentTypesXML: string;
begin
  Result :=
    '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>' + #13#10 +
    '<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">' + #13#10 +
    '  <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>' + #13#10 +
    '  <Default Extension="xml" ContentType="application/xml"/>' + #13#10 +
    '  <Override PartName="/word/document.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/>' + #13#10 +
    '  <Override PartName="/word/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.styles+xml"/>' + #13#10 +
    '  <Override PartName="/docProps/core.xml" ContentType="application/vnd.openxmlformats-package.core-properties+xml"/>' + #13#10 +
    '</Types>';
end;

function TAIDOCXWriter.BuildRelsXML: string;
begin
  Result :=
    '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>' + #13#10 +
    '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">' + #13#10 +
    '  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="word/document.xml"/>' + #13#10 +
    '  <Relationship Id="rId2" Type="http://schemas.openxmlformats.org/package/2006/relationships/metadata/core-properties" Target="docProps/core.xml"/>' + #13#10 +
    '</Relationships>';
end;

function TAIDOCXWriter.BuildWordRelsXML: string;
begin
  Result :=
    '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>' + #13#10 +
    '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">' + #13#10 +
    '  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles.xml"/>' + #13#10 +
    '</Relationships>';
end;

function TAIDOCXWriter.BuildCoreXML: string;
begin
  Result :=
    '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>' + #13#10 +
    '<cp:coreProperties xmlns:cp="http://schemas.openxmlformats.org/package/2006/metadata/core-properties" ' +
    'xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:dcterms="http://purl.org/dc/terms/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">' + #13#10 +
    '  <dc:title>' + XMLEncode(FTitle) + '</dc:title>' + #13#10 +
    '  <dc:creator>' + XMLEncode(FAuthor) + '</dc:creator>' + #13#10 +
    '</cp:coreProperties>';
end;

function TAIDOCXWriter.BuildStylesXML: string;
var
  I: Integer;
begin
  Result :=
    '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>' + #13#10 +
    '<w:styles xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">' + #13#10;
  for I := 1 to 6 do
  begin
    Result := Result +
      Format('  <w:style w:type="paragraph" w:styleId="Heading%d">' + #13#10 +
             '    <w:name w:val="heading %d"/>' + #13#10 +
             '    <w:rPr><w:b/><w:sz w:val="%d"/></w:rPr>' + #13#10 +
             '  </w:style>' + #13#10, [I, I, 48 - (I * 4)]);
  end;
  Result := Result + '</w:styles>';
end;

function TAIDOCXWriter.BuildDocumentXML: string;
var
  I, R, C, RowsCount: Integer;
  El: TAIDOCXElement;
  CellVal: string;
begin
  Result :=
    '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>' + #13#10 +
    '<w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">' + #13#10 +
    '  <w:body>' + #13#10;

  for I := 0 to High(FElements) do
  begin
    El := FElements[I];
    case El.ElementType of
      etHeading:
        begin
          Result := Result +
            Format('    <w:p><w:pPr><w:pStyle w:val="Heading%d"/></w:pPr><w:r><w:t>%s</w:t></w:r></w:p>' + #13#10,
              [El.Level, XMLEncode(El.Text)]);
        end;

      etParagraph:
        begin
          Result := Result +
            Format('    <w:p><w:r><w:t>%s</w:t></w:r></w:p>' + #13#10,
              [XMLEncode(El.Text)]);
        end;

      etTable:
        begin
          Result := Result + '    <w:tbl>' + #13#10;
          // Table Headers
          if Length(El.Headers) > 0 then
          begin
            Result := Result + '      <w:tr>' + #13#10;
            for C := 0 to El.Cols - 1 do
            begin
              if C <= High(El.Headers) then
                CellVal := El.Headers[C]
              else
                CellVal := '';
              Result := Result + Format('        <w:tc><w:p><w:r><w:b/><w:t>%s</w:t></w:r></w:p></w:tc>' + #13#10, [XMLEncode(CellVal)]);
            end;
            Result := Result + '      </w:tr>' + #13#10;
          end;

          // Table Rows
          if (El.Cols > 0) and (Length(El.Rows) > 0) then
          begin
            RowsCount := (Length(El.Rows) + El.Cols - 1) div El.Cols;
            for R := 0 to RowsCount - 1 do
            begin
              Result := Result + '      <w:tr>' + #13#10;
              for C := 0 to El.Cols - 1 do
              begin
                if (R * El.Cols + C) <= High(El.Rows) then
                  CellVal := El.Rows[R * El.Cols + C]
                else
                  CellVal := '';
                Result := Result + Format('        <w:tc><w:p><w:r><w:t>%s</w:t></w:r></w:p></w:tc>' + #13#10, [XMLEncode(CellVal)]);
              end;
              Result := Result + '      </w:tr>' + #13#10;
            end;
          end;
          Result := Result + '    </w:tbl>' + #13#10;
        end;
    end;
  end;

  Result := Result +
    '  </w:body>' + #13#10 +
    '</w:document>';
end;

function TAIDOCXWriter.SaveToFile(const AFileName: string): Boolean;
var
  Zip: TZipper;
  ContentTypesStream, RelsStream, WordRelsStream, CoreStream, StylesStream, DocStream: TStringStream;
begin
  Result := False;
  if Trim(AFileName) = '' then Exit;

  Zip := TZipper.Create;
  ContentTypesStream := TStringStream.Create(BuildContentTypesXML);
  RelsStream := TStringStream.Create(BuildRelsXML);
  WordRelsStream := TStringStream.Create(BuildWordRelsXML);
  CoreStream := TStringStream.Create(BuildCoreXML);
  StylesStream := TStringStream.Create(BuildStylesXML);
  DocStream := TStringStream.Create(BuildDocumentXML);

  try
    try
      Zip.FileName := AFileName;
      Zip.Entries.AddFileEntry(ContentTypesStream, '[Content_Types].xml');
      Zip.Entries.AddFileEntry(RelsStream, '_rels/.rels');
      Zip.Entries.AddFileEntry(WordRelsStream, 'word/_rels/document.xml.rels');
      Zip.Entries.AddFileEntry(CoreStream, 'docProps/core.xml');
      Zip.Entries.AddFileEntry(StylesStream, 'word/styles.xml');
      Zip.Entries.AddFileEntry(DocStream, 'word/document.xml');
      Zip.ZipAllFiles;
      Result := True;
    except
      on E: Exception do
        Result := False;
    end;
  finally
    DocStream.Free;
    StylesStream.Free;
    CoreStream.Free;
    WordRelsStream.Free;
    RelsStream.Free;
    ContentTypesStream.Free;
    Zip.Free;
  end;
end;

end.
