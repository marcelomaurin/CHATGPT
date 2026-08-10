unit aidocxinput;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Zipper, DOM, XMLRead, aibase, aidocumentreader;

type
  { TAIDOCXInput }

  TAIDOCXInput = class(TAIBaseComponent)
  private
    FFileName: string;
    FText: string;
    FIncludeTables: Boolean;
    FMetadata: TAIDocumentMetadata;
    procedure ParseCoreProps(const AXmlStream: TStream);
    procedure ParseDocumentXML(const AXmlStream: TStream);
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    procedure Clear;
    function LoadFromFile(const AFileName: string): Boolean;
    function Load: Boolean;

    property Text: string read FText;
    property Metadata: TAIDocumentMetadata read FMetadata;
  published
    property FileName: string read FFileName write FFileName;
    property IncludeTables: Boolean read FIncludeTables write FIncludeTables default True;
  end;

implementation

constructor TAIDOCXInput.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FPrompt := 'Component TAIDOCXInput reads native OpenXML .docx files using Zipper and DOM XML parsing. Properties: FileName: string, IncludeTables: Boolean. Methods: LoadFromFile, Load, Clear.';
  FFileName := '';
  FText := '';
  FIncludeTables := True;
  InitDocumentMetadata(FMetadata);
  Clear;
end;

destructor TAIDOCXInput.Destroy;
begin
  Clear;
  inherited Destroy;
end;

procedure TAIDOCXInput.Clear;
begin
  FText := '';
  InitDocumentMetadata(FMetadata);
  ClearError;
end;

procedure TAIDOCXInput.ParseCoreProps(const AXmlStream: TStream);
var
  Doc: TXMLDocument;
  Node: TDOMNode;
begin
  try
    AXmlStream.Position := 0;
    ReadXMLFile(Doc, AXmlStream);
    try
      if Assigned(Doc) then
      begin
        Node := Doc.DocumentElement.FindNode('dc:title');
        if Assigned(Node) then FMetadata.Title := Node.TextContent;

        Node := Doc.DocumentElement.FindNode('dc:creator');
        if Assigned(Node) then FMetadata.Author := Node.TextContent;

        Node := Doc.DocumentElement.FindNode('dc:subject');
        if Assigned(Node) then FMetadata.Subject := Node.TextContent;
      end;
    finally
      Doc.Free;
    end;
  except
    // Optional metadata parsing error silently ignored
  end;
end;

procedure TAIDOCXInput.ParseDocumentXML(const AXmlStream: TStream);
var
  Doc: TXMLDocument;

  procedure ProcessNode(ANode: TDOMNode; var AOutputText: string);
  var
    Child: TDOMNode;
    NodeName: string;
  begin
    if ANode = nil then Exit;
    NodeName := ANode.NodeName;

    if (NodeName = 'w:p') then
    begin
      Child := ANode.FirstChild;
      while Assigned(Child) do
      begin
        ProcessNode(Child, AOutputText);
        Child := Child.NextSibling;
      end;
      AOutputText := AOutputText + #13#10;
    end
    else if (NodeName = 'w:t') then
    begin
      AOutputText := AOutputText + ANode.TextContent;
    end
    else if FIncludeTables and (NodeName = 'w:tc') then
    begin
      Child := ANode.FirstChild;
      while Assigned(Child) do
      begin
        ProcessNode(Child, AOutputText);
        Child := Child.NextSibling;
      end;
      AOutputText := AOutputText + ' | ';
    end
    else
    begin
      Child := ANode.FirstChild;
      while Assigned(Child) do
      begin
        ProcessNode(Child, AOutputText);
        Child := Child.NextSibling;
      end;
    end;
  end;

begin
  AXmlStream.Position := 0;
  ReadXMLFile(Doc, AXmlStream);
  try
    if Assigned(Doc) then
    begin
      ProcessNode(Doc.DocumentElement, FText);
    end;
  finally
    Doc.Free;
  end;
end;

type
  TUnZipStreamHandler = class
  public
    DocStream: TMemoryStream;
    CoreStream: TMemoryStream;
    procedure CreateStream(Sender: TObject; var AStream: TStream; AItem: TFullZipFileEntry);
    procedure DoneStream(Sender: TObject; var AStream: TStream; AItem: TFullZipFileEntry);
  end;

procedure TUnZipStreamHandler.CreateStream(Sender: TObject; var AStream: TStream; AItem: TFullZipFileEntry);
begin
  if AItem.ArchiveFileName = 'word/document.xml' then
    AStream := DocStream
  else if AItem.ArchiveFileName = 'docProps/core.xml' then
    AStream := CoreStream
  else
    AStream := nil;
end;

procedure TUnZipStreamHandler.DoneStream(Sender: TObject; var AStream: TStream; AItem: TFullZipFileEntry);
begin
  // Keep memory streams open for processing
end;

function TAIDOCXInput.LoadFromFile(const AFileName: string): Boolean;
var
  UnZipper: TUnZipper;
  DocStream, CoreStream: TMemoryStream;
  Handler: TUnZipStreamHandler;
  EntriesList: TStringList;
begin
  FFileName := AFileName;
  Result := False;
  Clear;

  if Trim(FFileName) = '' then
  begin
    SetError('Nome de arquivo DOCX não especificado.');
    Exit;
  end;

  if not FileExists(FFileName) then
  begin
    SetError('Arquivo DOCX não encontrado: ' + FFileName);
    Exit;
  end;

  FMetadata.FileName := FFileName;
  FMetadata.Extension := LowerCase(ExtractFileExt(FFileName));

  UnZipper := TUnZipper.Create;
  DocStream := TMemoryStream.Create;
  CoreStream := TMemoryStream.Create;
  Handler := TUnZipStreamHandler.Create;
  EntriesList := TStringList.Create;
  try
    try
      Handler.DocStream := DocStream;
      Handler.CoreStream := CoreStream;

      EntriesList.Add('word/document.xml');
      EntriesList.Add('docProps/core.xml');

      UnZipper.FileName := FFileName;
      UnZipper.OnCreateStream := @Handler.CreateStream;
      UnZipper.OnDoneStream := @Handler.DoneStream;
      UnZipper.UnZipFiles(EntriesList);

      if CoreStream.Size > 0 then
        ParseCoreProps(CoreStream);

      if DocStream.Size > 0 then
      begin
        ParseDocumentXML(DocStream);
        FLastResult := 'DOCX Loaded successfully: ' + FFileName;
        FLastSuccess := True;
        Result := True;
      end
      else
        SetError('Arquivo word/document.xml não encontrado no pacote DOCX.');
    except
      on E: Exception do
        SetError('Erro ao abrir ZIP/XML do DOCX: ' + E.Message);
    end;
  finally
    EntriesList.Free;
    Handler.Free;
    CoreStream.Free;
    DocStream.Free;
    UnZipper.Free;
  end;
end;

function TAIDOCXInput.Load: Boolean;
begin
  Result := LoadFromFile(FFileName);
end;

end.
