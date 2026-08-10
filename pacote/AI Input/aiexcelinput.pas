unit aiexcelinput;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Zipper, DOM, XMLRead, aibase, aidocumentreader;

type
  { TAIExcelInput }

  TAIExcelInput = class(TAIBaseComponent)
  private
    FFileName: string;
    FSharedStrings: TStringList;
    FCells: TStringList; // Key: "Row,Col" (0-indexed)
    FRowCount: Integer;
    FColCount: Integer;
    FMetadata: TAIDocumentMetadata;

    function ColumnNameToIndex(const AName: string): Integer;
    procedure ParseCellRef(const ARef: string; out ARow, ACol: Integer);
    procedure ParseSharedStringsXML(const AXmlStream: TStream);
    procedure ParseSheetXML(const AXmlStream: TStream);
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    procedure Clear;
    function LoadFromFile(const AFileName: string): Boolean;
    function Load: Boolean;
    function GetCell(ARow, ACol: Integer): string;
    function ToText: string;

    property RowCount: Integer read FRowCount;
    property ColCount: Integer read FColCount;
    property Metadata: TAIDocumentMetadata read FMetadata;
  published
    property FileName: string read FFileName write FFileName;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('AI Documents', [TAIExcelInput]);
end;

constructor TAIExcelInput.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FPrompt := 'Component TAIExcelInput reads native OpenXML .xlsx spreadsheets using Zipper and DOM XML parsing. Properties: FileName: string. Methods: LoadFromFile, Load, GetCell(ARow, ACol), ToText, Clear.';
  FFileName := '';
  FSharedStrings := TStringList.Create;
  FCells := TStringList.Create;
  FRowCount := 0;
  FColCount := 0;
  InitDocumentMetadata(FMetadata);
  Clear;
end;

destructor TAIExcelInput.Destroy;
begin
  Clear;
  FCells.Free;
  FSharedStrings.Free;
  inherited Destroy;
end;

procedure TAIExcelInput.Clear;
begin
  FSharedStrings.Clear;
  FCells.Clear;
  FRowCount := 0;
  FColCount := 0;
  InitDocumentMetadata(FMetadata);
  ClearError;
end;

function TAIExcelInput.ColumnNameToIndex(const AName: string): Integer;
var
  I: Integer;
begin
  Result := 0;
  for I := 1 to Length(AName) do
    Result := Result * 26 + (Ord(UpCase(AName[I])) - Ord('A') + 1);
  Dec(Result);
end;

procedure TAIExcelInput.ParseCellRef(const ARef: string; out ARow, ACol: Integer);
var
  ColStr, RowStr: string;
  I: Integer;
begin
  ColStr := '';
  RowStr := '';
  for I := 1 to Length(ARef) do
  begin
    if ARef[I] in ['A'..'Z', 'a'..'z'] then
      ColStr := ColStr + ARef[I]
    else if ARef[I] in ['0'..'9'] then
      RowStr := RowStr + ARef[I];
  end;

  ACol := ColumnNameToIndex(ColStr);
  ARow := StrToIntDef(RowStr, 1) - 1;
end;

procedure TAIExcelInput.ParseSharedStringsXML(const AXmlStream: TStream);
var
  Doc: TXMLDocument;
  NodeList: TDOMNodeList;
  I: Integer;
  SiNode, TNode: TDOMNode;
begin
  FSharedStrings.Clear;
  try
    AXmlStream.Position := 0;
    ReadXMLFile(Doc, AXmlStream);
    try
      if Assigned(Doc) then
      begin
        NodeList := Doc.GetElementsByTagName('si');
        for I := 0 to NodeList.Length - 1 do
        begin
          SiNode := NodeList.Item[I];
          TNode := SiNode.FindNode('t');
          if Assigned(TNode) then
            FSharedStrings.Add(TNode.TextContent)
          else
            FSharedStrings.Add('');
        end;
      end;
    finally
      Doc.Free;
    end;
  except
  end;
end;

procedure TAIExcelInput.ParseSheetXML(const AXmlStream: TStream);
var
  Doc: TXMLDocument;
  CNodeList: TDOMNodeList;
  I, R, C, SharedIdx: Integer;
  CNode, VNode: TDOMNode;
  CellRef, CellType, CellVal: string;
  Element: TDOMElement;
begin
  try
    AXmlStream.Position := 0;
    ReadXMLFile(Doc, AXmlStream);
    try
      if Assigned(Doc) then
      begin
        CNodeList := Doc.GetElementsByTagName('c');
        for I := 0 to CNodeList.Length - 1 do
        begin
          CNode := CNodeList.Item[I];
          if CNode is TDOMElement then
          begin
            Element := TDOMElement(CNode);
            CellRef := Element.GetAttribute('r');
            CellType := Element.GetAttribute('t');

            ParseCellRef(CellRef, R, C);
            VNode := CNode.FindNode('v');
            CellVal := '';

            if Assigned(VNode) then
            begin
              if CellType = 's' then
              begin
                SharedIdx := StrToIntDef(VNode.TextContent, -1);
                if (SharedIdx >= 0) and (SharedIdx < FSharedStrings.Count) then
                  CellVal := FSharedStrings[SharedIdx];
              end
              else
                CellVal := VNode.TextContent;
            end;

            FCells.Values[IntToStr(R) + ',' + IntToStr(C)] := CellVal;

            if R + 1 > FRowCount then FRowCount := R + 1;
            if C + 1 > FColCount then FColCount := C + 1;
          end;
        end;
      end;
    finally
      Doc.Free;
    end;
  except
  end;
end;

function TAIExcelInput.GetCell(ARow, ACol: Integer): string;
begin
  if (ARow < 0) or (ACol < 0) then
    Result := ''
  else
    Result := FCells.Values[IntToStr(ARow) + ',' + IntToStr(ACol)];
end;

function TAIExcelInput.ToText: string;
var
  R, C: Integer;
  RowStr: string;
begin
  Result := '';
  for R := 0 to FRowCount - 1 do
  begin
    RowStr := '';
    for C := 0 to FColCount - 1 do
    begin
      if C > 0 then RowStr := RowStr + ' | ';
      RowStr := RowStr + GetCell(R, C);
    end;
    if Result <> '' then Result := Result + #13#10;
    Result := Result + RowStr;
  end;
end;

type
  TExcelUnZipStreamHandler = class
  public
    SheetStream: TMemoryStream;
    SharedStringsStream: TMemoryStream;
    procedure CreateStream(Sender: TObject; var AStream: TStream; AItem: TFullZipFileEntry);
    procedure DoneStream(Sender: TObject; var AStream: TStream; AItem: TFullZipFileEntry);
  end;

procedure TExcelUnZipStreamHandler.CreateStream(Sender: TObject; var AStream: TStream; AItem: TFullZipFileEntry);
begin
  if AItem.ArchiveFileName = 'xl/sharedStrings.xml' then
    AStream := SharedStringsStream
  else if AItem.ArchiveFileName = 'xl/worksheets/sheet1.xml' then
    AStream := SheetStream
  else
    AStream := nil;
end;

procedure TExcelUnZipStreamHandler.DoneStream(Sender: TObject; var AStream: TStream; AItem: TFullZipFileEntry);
begin
  // Keep memory streams open for processing
end;

function TAIExcelInput.LoadFromFile(const AFileName: string): Boolean;
var
  UnZipper: TUnZipper;
  SheetStream, SharedStringsStream: TMemoryStream;
  Handler: TExcelUnZipStreamHandler;
  EntriesList: TStringList;
begin
  FFileName := AFileName;
  Result := False;
  Clear;

  if Trim(FFileName) = '' then
  begin
    SetError('Nome de arquivo XLSX não especificado.');
    Exit;
  end;

  if not FileExists(FFileName) then
  begin
    SetError('Arquivo XLSX não encontrado: ' + FFileName);
    Exit;
  end;

  FMetadata.FileName := FFileName;
  FMetadata.Extension := LowerCase(ExtractFileExt(FFileName));
  FMetadata.SheetCount := 1;

  UnZipper := TUnZipper.Create;
  SheetStream := TMemoryStream.Create;
  SharedStringsStream := TMemoryStream.Create;
  Handler := TExcelUnZipStreamHandler.Create;
  EntriesList := TStringList.Create;
  try
    try
      Handler.SheetStream := SheetStream;
      Handler.SharedStringsStream := SharedStringsStream;

      EntriesList.Add('xl/sharedStrings.xml');
      EntriesList.Add('xl/worksheets/sheet1.xml');

      UnZipper.FileName := FFileName;
      UnZipper.OnCreateStream := @Handler.CreateStream;
      UnZipper.OnDoneStream := @Handler.DoneStream;
      UnZipper.UnZipFiles(EntriesList);

      if SharedStringsStream.Size > 0 then
        ParseSharedStringsXML(SharedStringsStream);

      if SheetStream.Size > 0 then
      begin
        ParseSheetXML(SheetStream);
        FLastResult := 'XLSX Loaded successfully: ' + FFileName;
        FLastSuccess := True;
        Result := True;
      end
      else
        SetError('Arquivo xl/worksheets/sheet1.xml não encontrado no pacote XLSX.');
    except
      on E: Exception do
        SetError('Erro ao abrir ZIP/XML do XLSX: ' + E.Message);
    end;
  finally
    EntriesList.Free;
    Handler.Free;
    SharedStringsStream.Free;
    SheetStream.Free;
    UnZipper.Free;
  end;
end;

function TAIExcelInput.Load: Boolean;
begin
  Result := LoadFromFile(FFileName);
end;

end.
