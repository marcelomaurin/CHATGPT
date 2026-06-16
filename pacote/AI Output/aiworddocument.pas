unit aiworddocument;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, DOM, Graphics, aibase, LResources, FileUtil,
  aiwordtypes, aiwordunits, aiwordpackage, aiwordxml, aiwordrelationships, aiwordobjects;

type
  { TAIWordDocument }

  TAIWordDocument = class(TAIBaseComponent)
  private
    FFileName: string;
    FTitle: string;
    FAuthor: string;
    FSubject: string;
    FPreserveUnsupportedXml: Boolean;

    FPackage: TAIWordPackage;
    FParagraphs: TAIWordParagraphList;
    FHeader: TAIWordHeaderFooter;
    FFooter: TAIWordHeaderFooter;
    FPageSetup: TAIWordPageSetup;
    FDocXml: TXMLDocument;
    FDocRels: TAIWordRelationships;

    // Variables for templating
    FVariables: TStrings;

    procedure LoadCoreProps;
    procedure SaveCoreProps;
    procedure LoadDocumentXML;
    procedure SaveDocumentXML;
    procedure LoadRelationships;
    procedure EnsureDefaultHeaderFooter;
    function GenerateNewImageId: Integer;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    procedure NewDocument;
    function LoadFromFile(const AFileName: string): Boolean;
    function SaveToFile(const AFileName: string = ''): Boolean;

    // Insert methods
    function AddTitle(const AText: string): TAIWordParagraph;
    function AddHeading(const AText: string; ALevel: Integer = 1): TAIWordParagraph;
    function AddParagraph(const AText: string = ''): TAIWordParagraph;
    procedure AddPageBreak;

    function AddImage(
      const AFileName: string;
      AWidthMM: Double = 0;
      AHeightMM: Double = 0;
      APosition: TAIWordImagePosition = wipInline
    ): TAIWordImage;

    function AddTable(ARows, ACols: Integer): TAIWordTable;

    // Search and Replace
    function FindParagraph(const AText: string): TAIWordParagraph;
    function FindParagraphs(const AText: string): TAIWordParagraphList;
    function ReplaceText(const ASearch, AReplace: string): Integer;

    // Template Mode
    procedure SetVariable(const AName, AValue: string);
    function ApplyVariables: Integer;

    procedure Clear;

    property Paragraphs: TAIWordParagraphList read FParagraphs;
    property Header: TAIWordHeaderFooter read FHeader;
    property Footer: TAIWordHeaderFooter read FFooter;
    property PageSetup: TAIWordPageSetup read FPageSetup;
  published
    property FileName: string read FFileName write FFileName;
    property Title: string read FTitle write FTitle;
    property Author: string read FAuthor write FAuthor;
    property Subject: string read FSubject write FSubject;
    property PreserveUnsupportedXml: Boolean
      read FPreserveUnsupportedXml
      write FPreserveUnsupportedXml
      default True;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('AI Documents', [TAIWordDocument]);
end;

constructor TAIWordDocument.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FCategory := ccOutput;
  FPrompt := 'TAIWordDocument - Component for creating, loading, editing and saving Microsoft Word DOCX files natively in Lazarus using OpenXML.';
  FPreserveUnsupportedXml := True;
  
  FPackage := TAIWordPackage.Create;
  FParagraphs := TAIWordParagraphList.Create;
  FDocRels := TAIWordRelationships.Create;
  FVariables := TStringList.Create;
  
  FHeader := nil;
  FFooter := nil;
  FPageSetup := nil;
  FDocXml := nil;
end;

destructor TAIWordDocument.Destroy;
begin
  Clear;
  FVariables.Free;
  FDocRels.Free;
  FParagraphs.Free;
  FPackage.Free;
  inherited Destroy;
end;

procedure TAIWordDocument.Clear;
begin
  if Assigned(FHeader) then FreeAndNil(FHeader);
  if Assigned(FFooter) then FreeAndNil(FFooter);
  if Assigned(FPageSetup) then FreeAndNil(FPageSetup);
  FParagraphs.Clear;
  if Assigned(FDocXml) then FreeAndNil(FDocXml);
  FDocRels.Clear;
  FVariables.Clear;
  ClearError;
end;

procedure TAIWordDocument.NewDocument;
begin
  Clear;
  try
    if FPackage.NewPackage then
    begin
      LoadRelationships;
      LoadDocumentXML;
      LoadCoreProps;
      FLastResult := 'New document initialized';
      FLastSuccess := True;
    end
    else
      SetError('Failed to initialize a new DOCX package.');
  except
    on E: Exception do
      SetError('NewDocument error: ' + E.Message);
  end;
end;

function TAIWordDocument.LoadFromFile(const AFileName: string): Boolean;
begin
  Clear;
  try
    if FPackage.LoadPackage(AFileName) then
    begin
      FFileName := AFileName;
      LoadRelationships;
      LoadDocumentXML;
      LoadCoreProps;
      FLastResult := 'Loaded ' + AFileName;
      FLastSuccess := True;
      Result := True;
    end
    else
    begin
      SetError('Failed to load file: ' + AFileName);
      Result := False;
    end;
  except
    on E: Exception do
    begin
      SetError('LoadFromFile error: ' + E.Message);
      Result := False;
    end;
  end;
end;

function TAIWordDocument.SaveToFile(const AFileName: string): Boolean;
var
  TargetFile: string;
begin
  ClearError;
  if AFileName <> '' then
    TargetFile := AFileName
  else
    TargetFile := FFileName;
    
  if TargetFile = '' then
  begin
    SetError('No filename specified for save operation.');
    Exit(False);
  end;
  
  try
    SaveCoreProps;
    SaveDocumentXML;
    
    // Save relationships
    FDocRels.SaveToFile;
    
    // Save headers and footers XML
    if Assigned(FHeader) and (FHeader.TempFileName <> '') then
      SaveXML(TXMLDocument(FHeader.XmlNode), FPackage.TempDir + PathDelim + FHeader.TempFileName);
    if Assigned(FFooter) and (FFooter.TempFileName <> '') then
      SaveXML(TXMLDocument(FFooter.XmlNode), FPackage.TempDir + PathDelim + FFooter.TempFileName);
      
    if FPackage.SavePackage(TargetFile) then
    begin
      FFileName := TargetFile;
      FLastResult := 'Saved to ' + TargetFile;
      FLastSuccess := True;
      Result := True;
    end
    else
    begin
      SetError('Failed to repack and save DOCX file to: ' + TargetFile);
      Result := False;
    end;
  except
    on E: Exception do
    begin
      SetError('SaveToFile error: ' + E.Message);
      Result := False;
    end;
  end;
end;

procedure TAIWordDocument.LoadCoreProps;
var
  CorePath: string;
  CoreDoc: TXMLDocument;
  Root, Child: TDOMNode;
begin
  CorePath := FPackage.TempDir + PathDelim + 'docProps' + PathDelim + 'core.xml';
  if not FileExists(CorePath) then Exit;
  
  try
    CoreDoc := LoadXML(CorePath);
    if Assigned(CoreDoc) then
    begin
      Root := FindChildNode(CoreDoc, 'cp:coreProperties');
      if Assigned(Root) then
      begin
        Child := FindChildNode(Root, 'dc:title');
        if Assigned(Child) then FTitle := GetNodeText(Child);
        Child := FindChildNode(Root, 'dc:creator');
        if Assigned(Child) then FAuthor := GetNodeText(Child);
        Child := FindChildNode(Root, 'dc:subject');
        if Assigned(Child) then FSubject := GetNodeText(Child);
      end;
      CoreDoc.Free;
    end;
  except
    // Non-fatal, fallback to empty
  end;
end;

procedure TAIWordDocument.SaveCoreProps;
var
  CorePath: string;
  CoreDoc: TXMLDocument;
  Root, Child: TDOMNode;
begin
  CorePath := FPackage.TempDir + PathDelim + 'docProps' + PathDelim + 'core.xml';
  try
    CoreDoc := TXMLDocument.Create;
    Root := CoreDoc.CreateElement('cp:coreProperties');
    SetNodeAttribute(Root, 'xmlns:cp', 'http://schemas.openxmlformats.org/package/2006/metadata/core-properties');
    SetNodeAttribute(Root, 'xmlns:dc', 'http://purl.org/dc/elements/1.1/');
    SetNodeAttribute(Root, 'xmlns:dcterms', 'http://purl.org/dc/terms/');
    SetNodeAttribute(Root, 'xmlns:xsi', 'http://www.w3.org/2001/XMLSchema-instance');
    CoreDoc.AppendChild(Root);
    
    Child := CoreDoc.CreateElement('dc:title');
    SetNodeText(Child, FTitle);
    Root.AppendChild(Child);
    
    Child := CoreDoc.CreateElement('dc:creator');
    SetNodeText(Child, FAuthor);
    Root.AppendChild(Child);
    
    if FSubject <> '' then
    begin
      Child := CoreDoc.CreateElement('dc:subject');
      SetNodeText(Child, FSubject);
      Root.AppendChild(Child);
    end;
    
    SaveXML(CoreDoc, CorePath);
    CoreDoc.Free;
  except
    // Ignore error in non-essential properties
  end;
end;

procedure TAIWordDocument.LoadDocumentXML;
var
  DocPath: string;
  Body, Child: TDOMNode;
  SectPr: TDOMNode;
  HRef, FRef: TDOMNode;
  RelId, HFName: string;
  HFDoc: TXMLDocument;
begin
  DocPath := FPackage.TempDir + PathDelim + 'word' + PathDelim + 'document.xml';
  FDocXml := LoadXML(DocPath);
  if not Assigned(FDocXml) then
    Exit;
    
  Body := FindChildNode(FindChildNode(FDocXml, 'w:document'), 'w:body');
  if not Assigned(Body) then
    Exit;
    
  // Load paragraphs
  Child := Body.FirstChild;
  while Assigned(Child) do
  begin
    if Child.NodeName = 'w:p' then
      FParagraphs.Add(TAIWordParagraph.Create(Self, Child));
    Child := Child.NextSibling;
  end;
  
  // Page setup & Sections
  SectPr := FindChildNode(Body, 'w:sectPr');
  if Assigned(SectPr) then
    FPageSetup := TAIWordPageSetup.Create(Self, SectPr);
    
  // Load Headers / Footers
  if Assigned(SectPr) then
  begin
    HRef := FindChildNode(SectPr, 'w:headerReference');
    if Assigned(HRef) then
    begin
      RelId := GetNodeAttribute(HRef, 'r:id');
      HFName := FDocRels.FindTargetById(RelId);
      if HFName <> '' then
      begin
        HFDoc := LoadXML(FPackage.TempDir + PathDelim + 'word' + PathDelim + HFName);
        if Assigned(HFDoc) then
          FHeader := TAIWordHeaderFooter.Create(Self, FindChildNode(HFDoc, 'w:hdr'), RelId, 'word' + PathDelim + HFName);
      end;
    end;
    
    FRef := FindChildNode(SectPr, 'w:footerReference');
    if Assigned(FRef) then
    begin
      RelId := GetNodeAttribute(FRef, 'r:id');
      HFName := FDocRels.FindTargetById(RelId);
      if HFName <> '' then
      begin
        HFDoc := LoadXML(FPackage.TempDir + PathDelim + 'word' + PathDelim + HFName);
        if Assigned(HFDoc) then
          FFooter := TAIWordHeaderFooter.Create(Self, FindChildNode(HFDoc, 'w:ftr'), RelId, 'word' + PathDelim + HFName);
      end;
    end;
  end;
end;

procedure TAIWordDocument.SaveDocumentXML;
var
  DocPath: string;
begin
  DocPath := FPackage.TempDir + PathDelim + 'word' + PathDelim + 'document.xml';
  SaveXML(FDocXml, DocPath);
end;

procedure TAIWordDocument.LoadRelationships;
var
  RelsPath: string;
begin
  RelsPath := FPackage.TempDir + PathDelim + 'word' + PathDelim + '_rels' + PathDelim + 'document.xml.rels';
  FDocRels.LoadFromFile(RelsPath);
end;

procedure TAIWordDocument.EnsureDefaultHeaderFooter;
var
  Body, SectPr, HRef, FRef: TDOMNode;
  HFDoc: TXMLDocument;
  HRelId, FRelId: string;
  List: TStringList;
begin
  Body := FindChildNode(FindChildNode(FDocXml, 'w:document'), 'w:body');
  if not Assigned(Body) then Exit;
  
  SectPr := GetOrCreateChildNode(Body, 'w:sectPr');
  
  if not Assigned(FHeader) then
  begin
    // Create word/header1.xml in package
    List := TStringList.Create;
    try
      List.Text := '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>' + #13#10 +
                   '<w:hdr xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">' + #13#10 +
                   '</w:hdr>';
      List.SaveToFile(FPackage.TempDir + PathDelim + 'word' + PathDelim + 'header1.xml', TEncoding.UTF8);
    finally
      List.Free;
    end;
    
    HRelId := FDocRels.AddRelationship(
      'http://schemas.openxmlformats.org/officeDocument/2006/relationships/header',
      'header1.xml'
    );
    
    HFDoc := LoadXML(FPackage.TempDir + PathDelim + 'word' + PathDelim + 'header1.xml');
    FHeader := TAIWordHeaderFooter.Create(Self, FindChildNode(HFDoc, 'w:hdr'), HRelId, 'word' + PathDelim + 'header1.xml');
    
    HRef := FDocXml.CreateElement('w:headerReference');
    SetNodeAttribute(HRef, 'w:type', 'default');
    SetNodeAttribute(HRef, 'r:id', HRelId);
    SectPr.AppendChild(HRef);
  end;
  
  if not Assigned(FFooter) then
  begin
    // Create word/footer1.xml in package
    List := TStringList.Create;
    try
      List.Text := '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>' + #13#10 +
                   '<w:ftr xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">' + #13#10 +
                   '</w:ftr>';
      List.SaveToFile(FPackage.TempDir + PathDelim + 'word' + PathDelim + 'footer1.xml', TEncoding.UTF8);
    finally
      List.Free;
    end;
    
    FRelId := FDocRels.AddRelationship(
      'http://schemas.openxmlformats.org/officeDocument/2006/relationships/footer',
      'footer1.xml'
    );
    
    HFDoc := LoadXML(FPackage.TempDir + PathDelim + 'word' + PathDelim + 'footer1.xml');
    FFooter := TAIWordHeaderFooter.Create(Self, FindChildNode(HFDoc, 'w:ftr'), FRelId, 'word' + PathDelim + 'footer1.xml');
    
    FRef := FDocXml.CreateElement('w:footerReference');
    SetNodeAttribute(FRef, 'w:type', 'default');
    SetNodeAttribute(FRef, 'r:id', FRelId);
    SectPr.AppendChild(FRef);
  end;
end;

function TAIWordDocument.AddParagraph(const AText: string): TAIWordParagraph;
var
  Body, SectPr, PNode: TDOMNode;
begin
  Body := FindChildNode(FindChildNode(FDocXml, 'w:document'), 'w:body');
  PNode := FDocXml.CreateElement('w:p');
  
  // Insert before w:sectPr
  SectPr := FindChildNode(Body, 'w:sectPr');
  if Assigned(SectPr) then
    Body.InsertBefore(PNode, SectPr)
  else
    Body.AppendChild(PNode);
    
  Result := TAIWordParagraph.Create(Self, PNode);
  if AText <> '' then
    Result.Text := AText;
    
  FParagraphs.Add(Result);
end;

function TAIWordDocument.AddTitle(const AText: string): TAIWordParagraph;
begin
  Result := AddParagraph(AText);
  Result.Style := 'Title';
  Result.FontSize := 26;
  Result.Bold := True;
  Result.SpaceAfterPt := 12;
end;

function TAIWordDocument.AddHeading(const AText: string; ALevel: Integer): TAIWordParagraph;
begin
  Result := AddParagraph(AText);
  Result.Style := 'Heading' + IntToStr(ALevel);
  Result.FontSize := 20 - (ALevel * 2);
  Result.Bold := True;
  Result.SpaceBeforePt := 12;
  Result.SpaceAfterPt := 6;
end;

procedure TAIWordDocument.AddPageBreak;
var
  P: TAIWordParagraph;
  Run: TAIWordRun;
  BrNode: TDOMNode;
begin
  P := AddParagraph;
  Run := P.AddRun;
  BrNode := FDocXml.CreateElement('w:br');
  SetNodeAttribute(BrNode, 'w:type', 'page');
  Run.XmlNode.AppendChild(BrNode);
end;

function TAIWordDocument.GenerateNewImageId: Integer;
var
  SR: TSearchRec;
  MaxVal, Val: Integer;
  FName: string;
begin
  MaxVal := 0;
  if FindFirst(FPackage.TempDir + PathDelim + 'word' + PathDelim + 'media' + PathDelim + 'image*', faAnyFile, SR) = 0 then
  begin
    repeat
      FName := ChangeFileExt(SR.Name, '');
      if (Length(FName) > 5) and (Copy(FName, 1, 5) = 'image') then
      begin
        if TryStrToInt(Copy(FName, 6, Length(FName) - 5), Val) then
        begin
          if Val > MaxVal then
            MaxVal := Val;
        end;
      end;
    until FindNext(SR) <> 0;
    FindClose(SR);
  end;
  Result := MaxVal + 1;
end;

function TAIWordDocument.AddImage(
  const AFileName: string;
  AWidthMM: Double;
  AHeightMM: Double;
  APosition: TAIWordImagePosition
): TAIWordImage;
var
  ImgNum: Integer;
  DestExt, DestName, DestPath: string;
  RelId: string;
  P: TAIWordParagraph;
  RunNode, DrawingNode, InlineNode, ExtNode, DocPrNode, GraphicNode, GraphicDataNode, PicNode, NvPicPrNode, CNvPrNode, BlipFillNode, BlipNode, StretchNode, FillRectNode, SpPrNode, XfrmNode, OffNode, Ext2Node, PrstGeomNode: TDOMNode;
  EmuW, EmuH: Int64;
begin
  Result := nil;
  if not FileExists(AFileName) then
  begin
    SetError('Image file not found: ' + AFileName);
    Exit;
  end;
  
  if APosition <> wipInline then
  begin
    SetError('Only wipInline image positioning is supported in this version.');
    Exit;
  end;

  try
    ImgNum := GenerateNewImageId;
    DestExt := ExtractFileExt(AFileName);
    DestName := 'image' + IntToStr(ImgNum) + DestExt;
    DestPath := FPackage.TempDir + PathDelim + 'word' + PathDelim + 'media' + PathDelim + DestName;
    
    // Copy the image into package media folder
    CopyFile(AFileName, DestPath);
    
    // Add relationship
    RelId := FDocRels.AddRelationship(
      'http://schemas.openxmlformats.org/officeDocument/2006/relationships/image',
      'media/' + DestName
    );
    
    // Default size if 0
    if AWidthMM <= 0 then AWidthMM := 50.0;
    if AHeightMM <= 0 then AHeightMM := 30.0;
    EmuW := MMToEMU(AWidthMM);
    EmuH := MMToEMU(AHeightMM);
    
    // Add image to new paragraph
    P := AddParagraph;
    RunNode := FDocXml.CreateElement('w:r');
    P.XmlNode.AppendChild(RunNode);
    
    DrawingNode := FDocXml.CreateElement('w:drawing');
    RunNode.AppendChild(DrawingNode);
    
    InlineNode := FDocXml.CreateElement('wp:inline');
    SetNodeAttribute(InlineNode, 'distT', '0');
    SetNodeAttribute(InlineNode, 'distB', '0');
    SetNodeAttribute(InlineNode, 'distL', '0');
    SetNodeAttribute(InlineNode, 'distR', '0');
    DrawingNode.AppendChild(InlineNode);
    
    ExtNode := FDocXml.CreateElement('wp:extent');
    SetNodeAttribute(ExtNode, 'cx', IntToStr(EmuW));
    SetNodeAttribute(ExtNode, 'cy', IntToStr(EmuH));
    InlineNode.AppendChild(ExtNode);
    
    DocPrNode := FDocXml.CreateElement('wp:docPr');
    SetNodeAttribute(DocPrNode, 'id', IntToStr(ImgNum));
    SetNodeAttribute(DocPrNode, 'name', DestName);
    SetNodeAttribute(DocPrNode, 'descr', '');
    InlineNode.AppendChild(DocPrNode);
    
    GraphicNode := FDocXml.CreateElement('a:graphic');
    SetNodeAttribute(GraphicNode, 'xmlns:a', 'http://schemas.openxmlformats.org/drawingml/2006/main');
    InlineNode.AppendChild(GraphicNode);
    
    GraphicDataNode := FDocXml.CreateElement('a:graphicData');
    SetNodeAttribute(GraphicDataNode, 'uri', 'http://schemas.openxmlformats.org/drawingml/2006/picture');
    GraphicNode.AppendChild(GraphicDataNode);
    
    PicNode := FDocXml.CreateElement('pic:pic');
    SetNodeAttribute(PicNode, 'xmlns:pic', 'http://schemas.openxmlformats.org/drawingml/2006/picture');
    GraphicDataNode.AppendChild(PicNode);
    
    NvPicPrNode := FDocXml.CreateElement('pic:nvPicPr');
    PicNode.AppendChild(NvPicPrNode);
    
    CNvPrNode := FDocXml.CreateElement('pic:cNvPr');
    SetNodeAttribute(CNvPrNode, 'id', IntToStr(ImgNum));
    SetNodeAttribute(CNvPrNode, 'name', DestName);
    NvPicPrNode.AppendChild(CNvPrNode);
    
    NvPicPrNode.AppendChild(FDocXml.CreateElement('pic:cNvPicPr'));
    
    BlipFillNode := FDocXml.CreateElement('pic:blipFill');
    PicNode.AppendChild(BlipFillNode);
    
    BlipNode := FDocXml.CreateElement('a:blip');
    SetNodeAttribute(BlipNode, 'r:embed', RelId);
    SetNodeAttribute(BlipNode, 'xmlns:r', 'http://schemas.openxmlformats.org/officeDocument/2006/relationships');
    BlipFillNode.AppendChild(BlipNode);
    
    StretchNode := FDocXml.CreateElement('a:stretch');
    BlipFillNode.AppendChild(StretchNode);
    StretchNode.AppendChild(FDocXml.CreateElement('a:fillRect'));
    
    SpPrNode := FDocXml.CreateElement('pic:spPr');
    PicNode.AppendChild(SpPrNode);
    
    XfrmNode := FDocXml.CreateElement('a:xfrm');
    SpPrNode.AppendChild(XfrmNode);
    
    OffNode := FDocXml.CreateElement('a:off');
    SetNodeAttribute(OffNode, 'x', '0');
    SetNodeAttribute(OffNode, 'y', '0');
    XfrmNode.AppendChild(OffNode);
    
    Ext2Node := FDocXml.CreateElement('a:ext');
    SetNodeAttribute(Ext2Node, 'cx', IntToStr(EmuW));
    SetNodeAttribute(Ext2Node, 'cy', IntToStr(EmuH));
    XfrmNode.AppendChild(Ext2Node);
    
    PrstGeomNode := FDocXml.CreateElement('a:prstGeom');
    SetNodeAttribute(PrstGeomNode, 'prst', 'rect');
    SpPrNode.AppendChild(PrstGeomNode);
    PrstGeomNode.AppendChild(FDocXml.CreateElement('a:avLst'));
    
    Result := TAIWordImage.Create(Self, DestName, RelId, InlineNode);
    FLastResult := 'Image added successfully';
    FLastSuccess := True;
  except
    on E: Exception do
      SetError('AddImage error: ' + E.Message);
  end;
end;

function TAIWordDocument.AddTable(ARows, ACols: Integer): TAIWordTable;
var
  Body, SectPr, TblNode: TDOMNode;
begin
  Body := FindChildNode(FindChildNode(FDocXml, 'w:document'), 'w:body');
  TblNode := FDocXml.CreateElement('w:tbl');
  
  // Insert before w:sectPr
  SectPr := FindChildNode(Body, 'w:sectPr');
  if Assigned(SectPr) then
    Body.InsertBefore(TblNode, SectPr)
  else
    Body.AppendChild(TblNode);
    
  Result := TAIWordTable.Create(Self, TblNode, ARows, ACols);
  Result.Border := True;
end;

function TAIWordDocument.FindParagraph(const AText: string): TAIWordParagraph;
var
  I: Integer;
begin
  Result := nil;
  for I := 0 to FParagraphs.Count - 1 do
  begin
    if Pos(AText, FParagraphs[I].Text) > 0 then
    begin
      Result := FParagraphs[I];
      Exit;
    end;
  end;
end;

function TAIWordDocument.FindParagraphs(const AText: string): TAIWordParagraphList;
var
  I: Integer;
begin
  Result := TAIWordParagraphList.Create;
  for I := 0 to FParagraphs.Count - 1 do
  begin
    if Pos(AText, FParagraphs[I].Text) > 0 then
      Result.Add(FParagraphs[I]);
  end;
end;

function TAIWordDocument.ReplaceText(const ASearch, AReplace: string): Integer;
var
  I: Integer;
  PText: string;
begin
  Result := 0;
  for I := 0 to FParagraphs.Count - 1 do
  begin
    PText := FParagraphs[I].Text;
    if Pos(ASearch, PText) > 0 then
    begin
      PText := StringReplace(PText, ASearch, AReplace, [rfReplaceAll]);
      FParagraphs[I].Text := PText;
      Inc(Result);
    end;
  end;
end;

procedure TAIWordDocument.SetVariable(const AName, AValue: string);
begin
  FVariables.Values[AName] := AValue;
end;

function TAIWordDocument.ApplyVariables: Integer;
var
  I: Integer;
  VarName, VarPattern: string;
begin
  Result := 0;
  for I := 0 to FVariables.Count - 1 do
  begin
    VarName := FVariables.Names[I];
    VarPattern := '{{' + VarName + '}}';
    Inc(Result, ReplaceText(VarPattern, FVariables.ValueFromIndex[I]));
  end;
end;

end.
