unit aiwordobjects;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, DOM, Graphics, aiwordtypes, aiwordunits, aiwordxml;

type
  { Forward declarations }
  TAIWordRun = class;
  TAIWordImage = class;
  TAIWordTable = class;
  TAIWordTableCell = class;
  TAIWordParagraph = class;

  { TAIWordParagraphList }

  TAIWordParagraphList = class
  private
    FItems: TList;
    function GetCount: Integer;
    function GetItem(AIndex: Integer): TAIWordParagraph;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Add(AParagraph: TAIWordParagraph);
    procedure Remove(AParagraph: TAIWordParagraph);
    procedure Clear;
    property Count: Integer read GetCount;
    property Items[Index: Integer]: TAIWordParagraph read GetItem; default;
  end;

  { TAIWordRun }

  TAIWordRun = class
  private
    FOwnerDoc: TObject; // Cast to TAIWordDocument
    FXmlNode: TDOMNode;
    function GetText: string;
    procedure SetText(const AValue: string);
    function GetFontName: string;
    procedure SetFontName(const AValue: string);
    function GetFontSize: Integer;
    procedure SetFontSize(AValue: Integer);
    function GetBold: Boolean;
    procedure SetBold(AValue: Boolean);
    function GetItalic: Boolean;
    procedure SetItalic(AValue: Boolean);
    function GetUnderline: Boolean;
    procedure SetUnderline(AValue: Boolean);
    function GetColor: TColor;
    procedure SetColor(AColor: TColor);
    function GetHighlightColor: TColor;
    procedure SetHighlightColor(AColor: TColor);
  public
    constructor Create(AOwner: TObject; AXmlNode: TDOMNode);
    property Text: string read GetText write SetText;
    property FontName: string read GetFontName write SetFontName;
    property FontSize: Integer read GetFontSize write SetFontSize; // in points
    property Bold: Boolean read GetBold write SetBold;
    property Italic: Boolean read GetItalic write SetItalic;
    property Underline: Boolean read GetUnderline write SetUnderline;
    property Color: TColor read GetColor write SetColor;
    property HighlightColor: TColor read GetHighlightColor write SetHighlightColor;
    property XmlNode: TDOMNode read FXmlNode;
  end;

  { TAIWordParagraph }

  TAIWordParagraph = class
  private
    FOwnerDoc: TObject; // Cast to TAIWordDocument
    FXmlNode: TDOMNode;
    FRuns: TList;
    function GetText: string;
    procedure SetText(const AValue: string);
    function GetStyle: string;
    procedure SetStyle(const AValue: string);
    function GetAlignment: TAIWordAlignment;
    procedure SetAlignment(AValue: TAIWordAlignment);
    function GetFontName: string;
    procedure SetFontName(const AValue: string);
    function GetFontSize: Integer;
    procedure SetFontSize(AValue: Integer);
    function GetBold: Boolean;
    procedure SetBold(AValue: Boolean);
    function GetItalic: Boolean;
    procedure SetItalic(AValue: Boolean);
    function GetUnderline: Boolean;
    procedure SetUnderline(AValue: Boolean);
    function GetSpaceBeforePt: Integer;
    procedure SetSpaceBeforePt(AValue: Integer);
    function GetSpaceAfterPt: Integer;
    procedure SetSpaceAfterPt(AValue: Integer);
    function GetFirstLineIndentMM: Double;
    procedure SetFirstLineIndentMM(AValue: Double);
    
    function GetOrCreatepPr: TDOMNode;
    function GetOrCreatepPrrPr: TDOMNode;
  public
    constructor Create(AOwner: TObject; AXmlNode: TDOMNode);
    destructor Destroy; override;

    function AddRun(const AText: string = ''): TAIWordRun;
    function AddImage(const AFileName: string; AWidthMM, AHeightMM: Double): TAIWordImage;
    procedure ClearRuns;
    procedure Delete;

    property Text: string read GetText write SetText;
    property Style: string read GetStyle write SetStyle;
    property Alignment: TAIWordAlignment read GetAlignment write SetAlignment;
    property FontName: string read GetFontName write SetFontName;
    property FontSize: Integer read GetFontSize write SetFontSize;
    property Bold: Boolean read GetBold write SetBold;
    property Italic: Boolean read GetItalic write SetItalic;
    property Underline: Boolean read GetUnderline write SetUnderline;
    property SpaceBeforePt: Integer read GetSpaceBeforePt write SetSpaceBeforePt;
    property SpaceAfterPt: Integer read GetSpaceAfterPt write SetSpaceAfterPt;
    property FirstLineIndentMM: Double read GetFirstLineIndentMM write SetFirstLineIndentMM;
    property XmlNode: TDOMNode read FXmlNode;
  end;

  { TAIWordImage }

  TAIWordImage = class
  private
    FOwnerDoc: TObject;
    FRelationshipId: string;
    FFileName: string;
    FXmlNode: TDOMNode;
    function GetWidthMM: Double;
    procedure SetWidthMM(AValue: Double);
    function GetHeightMM: Double;
    procedure SetHeightMM(AValue: Double);
    function GetPosition: TAIWordImagePosition;
    procedure SetPosition(AValue: TAIWordImagePosition);
    function GetAlignment: TAIWordAlignment;
    procedure SetAlignment(AValue: TAIWordAlignment);
    function GetAltText: string;
    procedure SetAltText(const AValue: string);
  public
    constructor Create(AOwner: TObject; const AFileName, ARelId: string; AXmlNode: TDOMNode);
    property FileName: string read FFileName;
    property RelationshipId: string read FRelationshipId;
    property WidthMM: Double read GetWidthMM write SetWidthMM;
    property HeightMM: Double read GetHeightMM write SetHeightMM;
    property Position: TAIWordImagePosition read GetPosition write SetPosition;
    property Alignment: TAIWordAlignment read GetAlignment write SetAlignment;
    property AltText: string read GetAltText write SetAltText;
  end;

  { TAIWordTableCell }

  TAIWordTableCell = class
  private
    FOwnerDoc: TObject;
    FXmlNode: TDOMNode;
    function GetText: string;
    procedure SetText(const AValue: string);
    function GetAlignment: TAIWordAlignment;
    procedure SetAlignment(AValue: TAIWordAlignment);
    function GetBold: Boolean;
    procedure SetBold(AValue: Boolean);
    function GetShadingColor: TColor;
    procedure SetShadingColor(AColor: TColor);
  public
    constructor Create(AOwner: TObject; AXmlNode: TDOMNode);
    property Text: string read GetText write SetText;
    property Alignment: TAIWordAlignment read GetAlignment write SetAlignment;
    property Bold: Boolean read GetBold write SetBold;
    property ShadingColor: TColor read GetShadingColor write SetShadingColor;
  end;

  { TAIWordTable }

  TAIWordTable = class
  private
    FOwnerDoc: TObject;
    FXmlNode: TDOMNode;
    FRows: Integer;
    FCols: Integer;
    FCells: array of array of TAIWordTableCell;
    function GetBorder: Boolean;
    procedure SetBorder(AValue: Boolean);
    function GetWidthPercent: Integer;
    procedure SetWidthPercent(AValue: Integer);
  public
    constructor Create(AOwner: TObject; AXmlNode: TDOMNode; ARows, ACols: Integer);
    destructor Destroy; override;
    function Cell(ARow, ACol: Integer): TAIWordTableCell;

    property Rows: Integer read FRows;
    property Cols: Integer read FCols;
    property Border: Boolean read GetBorder write SetBorder;
    property WidthPercent: Integer read GetWidthPercent write SetWidthPercent;
  end;

  { TAIWordHeaderFooter }

  TAIWordHeaderFooter = class
  private
    FOwnerDoc: TObject;
    FXmlNode: TDOMNode;
    FRelId: string;
    FTempFileName: string; // e.g. word/header1.xml
  public
    constructor Create(AOwner: TObject; AXmlNode: TDOMNode; const ARelId, ATempFileName: string);
    procedure Clear;
    function AddParagraph(const AText: string = ''): TAIWordParagraph;
    procedure AddPageNumber;
    property XmlNode: TDOMNode read FXmlNode;
    property RelId: string read FRelId;
    property TempFileName: string read FTempFileName;
  end;

  { TAIWordPageSetup }

  TAIWordPageSetup = class
  private
    FOwnerDoc: TObject;
    FXmlNode: TDOMNode; // points to w:sectPr
    FPaperSize: TAIWordPaperSize;
    FOrientation: TAIWordOrientation;
    FMarginLeftMM: Double;
    FMarginRightMM: Double;
    FMarginTopMM: Double;
    FMarginBottomMM: Double;
    procedure UpdateXML;
  public
    constructor Create(AOwner: TObject; AXmlNode: TDOMNode);
    
    property PaperSize: TAIWordPaperSize read FPaperSize write FPaperSize;
    property Orientation: TAIWordOrientation read FOrientation write FOrientation;
    property MarginLeftMM: Double read FMarginLeftMM write FMarginLeftMM;
    property MarginRightMM: Double read FMarginRightMM write FMarginRightMM;
    property MarginTopMM: Double read FMarginTopMM write FMarginTopMM;
    property MarginBottomMM: Double read FMarginBottomMM write FMarginBottomMM;
  end;

implementation

uses aiworddocument;

{ TAIWordParagraphList }

constructor TAIWordParagraphList.Create;
begin
  FItems := TList.Create;
end;

destructor TAIWordParagraphList.Destroy;
begin
  FItems.Free;
  inherited Destroy;
end;

function TAIWordParagraphList.GetCount: Integer;
begin
  Result := FItems.Count;
end;

function TAIWordParagraphList.GetItem(AIndex: Integer): TAIWordParagraph;
begin
  Result := TAIWordParagraph(FItems[AIndex]);
end;

procedure TAIWordParagraphList.Add(AParagraph: TAIWordParagraph);
begin
  FItems.Add(AParagraph);
end;

procedure TAIWordParagraphList.Remove(AParagraph: TAIWordParagraph);
begin
  FItems.Remove(AParagraph);
end;

procedure TAIWordParagraphList.Clear;
begin
  FItems.Clear;
end;


{ TAIWordRun }

constructor TAIWordRun.Create(AOwner: TObject; AXmlNode: TDOMNode);
begin
  FOwnerDoc := AOwner;
  FXmlNode := AXmlNode;
end;

function TAIWordRun.GetText: string;
var
  TNode: TDOMNode;
begin
  TNode := FindChildNode(FXmlNode, 'w:t');
  if Assigned(TNode) then
    Result := GetNodeText(TNode)
  else
    Result := '';
end;

procedure TAIWordRun.SetText(const AValue: string);
var
  TNode: TDOMNode;
begin
  TNode := GetOrCreateChildNode(FXmlNode, 'w:t');
  SetNodeAttribute(TNode, 'xml:space', 'preserve');
  SetNodeText(TNode, AValue);
end;

function TAIWordRun.GetFontName: string;
var
  RPr, Fonts: TDOMNode;
begin
  Result := '';
  RPr := FindChildNode(FXmlNode, 'w:rPr');
  if Assigned(RPr) then
  begin
    Fonts := FindChildNode(RPr, 'w:rFonts');
    if Assigned(Fonts) then
      Result := GetNodeAttribute(Fonts, 'w:ascii');
  end;
end;

procedure TAIWordRun.SetFontName(const AValue: string);
var
  RPr, Fonts: TDOMNode;
begin
  RPr := GetOrCreateChildNode(FXmlNode, 'w:rPr');
  Fonts := GetOrCreateChildNode(RPr, 'w:rFonts');
  SetNodeAttribute(Fonts, 'w:ascii', AValue);
  SetNodeAttribute(Fonts, 'w:hAnsi', AValue);
end;

function TAIWordRun.GetFontSize: Integer;
var
  RPr, Sz: TDOMNode;
  ValStr: string;
  ValInt: Integer;
begin
  Result := 11; // Default
  RPr := FindChildNode(FXmlNode, 'w:rPr');
  if Assigned(RPr) then
  begin
    Sz := FindChildNode(RPr, 'w:sz');
    if Assigned(Sz) then
    begin
      ValStr := GetNodeAttribute(Sz, 'w:val');
      if TryStrToInt(ValStr, ValInt) then
        Result := Round(HalfPointToPt(ValInt));
    end;
  end;
end;

procedure TAIWordRun.SetFontSize(AValue: Integer);
var
  RPr, Sz: TDOMNode;
begin
  RPr := GetOrCreateChildNode(FXmlNode, 'w:rPr');
  Sz := GetOrCreateChildNode(RPr, 'w:sz');
  SetNodeAttribute(Sz, 'w:val', IntToStr(PtToHalfPoint(AValue)));
  // Set szCs as well for compatibility
  Sz := GetOrCreateChildNode(RPr, 'w:szCs');
  SetNodeAttribute(Sz, 'w:val', IntToStr(PtToHalfPoint(AValue)));
end;

function TAIWordRun.GetBold: Boolean;
var
  RPr: TDOMNode;
begin
  Result := False;
  RPr := FindChildNode(FXmlNode, 'w:rPr');
  if Assigned(RPr) then
    Result := Assigned(FindChildNode(RPr, 'w:b'));
end;

procedure TAIWordRun.SetBold(AValue: Boolean);
var
  RPr, BNode: TDOMNode;
begin
  RPr := GetOrCreateChildNode(FXmlNode, 'w:rPr');
  BNode := FindChildNode(RPr, 'w:b');
  if AValue then
  begin
    if not Assigned(BNode) then
      GetOrCreateChildNode(RPr, 'w:b');
  end
  else
  begin
    if Assigned(BNode) then
      RPr.RemoveChild(BNode);
  end;
end;

function TAIWordRun.GetItalic: Boolean;
var
  RPr: TDOMNode;
begin
  Result := False;
  RPr := FindChildNode(FXmlNode, 'w:rPr');
  if Assigned(RPr) then
    Result := Assigned(FindChildNode(RPr, 'w:i'));
end;

procedure TAIWordRun.SetItalic(AValue: Boolean);
var
  RPr, INode: TDOMNode;
begin
  RPr := GetOrCreateChildNode(FXmlNode, 'w:rPr');
  INode := FindChildNode(RPr, 'w:i');
  if AValue then
  begin
    if not Assigned(INode) then
      GetOrCreateChildNode(RPr, 'w:i');
  end
  else
  begin
    if Assigned(INode) then
      RPr.RemoveChild(INode);
  end;
end;

function TAIWordRun.GetUnderline: Boolean;
var
  RPr, UNode: TDOMNode;
begin
  Result := False;
  RPr := FindChildNode(FXmlNode, 'w:rPr');
  if Assigned(RPr) then
  begin
    UNode := FindChildNode(RPr, 'w:u');
    Result := Assigned(UNode) and (GetNodeAttribute(UNode, 'w:val') <> 'none');
  end;
end;

procedure TAIWordRun.SetUnderline(AValue: Boolean);
var
  RPr, UNode: TDOMNode;
begin
  RPr := GetOrCreateChildNode(FXmlNode, 'w:rPr');
  UNode := FindChildNode(RPr, 'w:u');
  if AValue then
  begin
    if not Assigned(UNode) then
      UNode := GetOrCreateChildNode(RPr, 'w:u');
    SetNodeAttribute(UNode, 'w:val', 'single');
  end
  else
  begin
    if Assigned(UNode) then
      RPr.RemoveChild(UNode);
  end;
end;

function TAIWordRun.GetColor: TColor;
var
  RPr, CNode: TDOMNode;
begin
  Result := clBlack;
  RPr := FindChildNode(FXmlNode, 'w:rPr');
  if Assigned(RPr) then
  begin
    CNode := FindChildNode(RPr, 'w:color');
    if Assigned(CNode) then
      Result := HexToColor(GetNodeAttribute(CNode, 'w:val'));
  end;
end;

procedure TAIWordRun.SetColor(AColor: TColor);
var
  RPr, CNode: TDOMNode;
begin
  RPr := GetOrCreateChildNode(FXmlNode, 'w:rPr');
  CNode := GetOrCreateChildNode(RPr, 'w:color');
  SetNodeAttribute(CNode, 'w:val', ColorToHex(AColor));
end;

function TAIWordRun.GetHighlightColor: TColor;
var
  RPr, HNode: TDOMNode;
  HVal: string;
begin
  Result := clWhite;
  RPr := FindChildNode(FXmlNode, 'w:rPr');
  if Assigned(RPr) then
  begin
    HNode := FindChildNode(RPr, 'w:highlight');
    if Assigned(HNode) then
    begin
      HVal := GetNodeAttribute(HNode, 'w:val');
      if HVal = 'yellow' then Result := clYellow
      else if HVal = 'green' then Result := clGreen
      else if HVal = 'blue' then Result := clBlue
      else if HVal = 'cyan' then Result := clAqua
      else if HVal = 'magenta' then Result := clFuchsia
      else if HVal = 'red' then Result := clRed;
    end;
  end;
end;

procedure TAIWordRun.SetHighlightColor(AColor: TColor);
var
  RPr, HNode: TDOMNode;
  HVal: string;
begin
  RPr := GetOrCreateChildNode(FXmlNode, 'w:rPr');
  HNode := FindChildNode(RPr, 'w:highlight');
  
  if AColor = clWhite then
  begin
    if Assigned(HNode) then
      RPr.RemoveChild(HNode);
    Exit;
  end;

  if not Assigned(HNode) then
    HNode := GetOrCreateChildNode(RPr, 'w:highlight');

  case AColor of
    clYellow: HVal := 'yellow';
    clGreen: HVal := 'green';
    clBlue: HVal := 'blue';
    clAqua: HVal := 'cyan';
    clFuchsia: HVal := 'magenta';
    clRed: HVal := 'red';
    else HVal := 'yellow';
  end;
  SetNodeAttribute(HNode, 'w:val', HVal);
end;


{ TAIWordParagraph }

constructor TAIWordParagraph.Create(AOwner: TObject; AXmlNode: TDOMNode);
var
  Child: TDOMNode;
begin
  FOwnerDoc := AOwner;
  FXmlNode := AXmlNode;
  FRuns := TList.Create;
  
  // Populate existing runs
  Child := FXmlNode.FirstChild;
  while Assigned(Child) do
  begin
    if Child.NodeName = 'w:r' then
      FRuns.Add(TAIWordRun.Create(FOwnerDoc, Child));
    Child := Child.NextSibling;
  end;
end;

destructor TAIWordParagraph.Destroy;
begin
  ClearRuns;
  FRuns.Free;
  inherited Destroy;
end;

function TAIWordParagraph.GetOrCreatepPr: TDOMNode;
var
  pPr: TDOMNode;
begin
  pPr := FindChildNode(FXmlNode, 'w:pPr');
  if not Assigned(pPr) then
  begin
    // pPr must be the first child in a paragraph
    pPr := FXmlNode.OwnerDocument.CreateElement('w:pPr');
    if Assigned(FXmlNode.FirstChild) then
      FXmlNode.InsertBefore(pPr, FXmlNode.FirstChild)
    else
      FXmlNode.AppendChild(pPr);
  end;
  Result := pPr;
end;

function TAIWordParagraph.GetOrCreatepPrrPr: TDOMNode;
var
  pPr: TDOMNode;
begin
  pPr := GetOrCreatepPr;
  Result := GetOrCreateChildNode(pPr, 'w:rPr');
end;

function TAIWordParagraph.GetText: string;
var
  I: Integer;
begin
  Result := '';
  for I := 0 to FRuns.Count - 1 do
    Result := Result + TAIWordRun(FRuns[I]).Text;
end;

procedure TAIWordParagraph.SetText(const AValue: string);
begin
  ClearRuns;
  AddRun(AValue);
end;

function TAIWordParagraph.GetStyle: string;
var
  pPr, StyleNode: TDOMNode;
begin
  Result := '';
  pPr := FindChildNode(FXmlNode, 'w:pPr');
  if Assigned(pPr) then
  begin
    StyleNode := FindChildNode(pPr, 'w:pStyle');
    if Assigned(StyleNode) then
      Result := GetNodeAttribute(StyleNode, 'w:val');
  end;
end;

procedure TAIWordParagraph.SetStyle(const AValue: string);
var
  pPr, StyleNode: TDOMNode;
begin
  pPr := GetOrCreatepPr;
  StyleNode := GetOrCreateChildNode(pPr, 'w:pStyle');
  SetNodeAttribute(StyleNode, 'w:val', AValue);
end;

function TAIWordParagraph.GetAlignment: TAIWordAlignment;
var
  pPr, JcNode: TDOMNode;
  JcVal: string;
begin
  Result := waLeft;
  pPr := FindChildNode(FXmlNode, 'w:pPr');
  if Assigned(pPr) then
  begin
    JcNode := FindChildNode(pPr, 'w:jc');
    if Assigned(JcNode) then
    begin
      JcVal := GetNodeAttribute(JcNode, 'w:val');
      if JcVal = 'center' then Result := waCenter
      else if JcVal = 'right' then Result := waRight
      else if JcVal = 'both' then Result := waJustify;
    end;
  end;
end;

procedure TAIWordParagraph.SetAlignment(AValue: TAIWordAlignment);
var
  pPr, JcNode: TDOMNode;
  JcVal: string;
begin
  pPr := GetOrCreatepPr;
  JcNode := GetOrCreateChildNode(pPr, 'w:jc');
  case AValue of
    waLeft: JcVal := 'left';
    waCenter: JcVal := 'center';
    waRight: JcVal := 'right';
    waJustify: JcVal := 'both';
  end;
  SetNodeAttribute(JcNode, 'w:val', JcVal);
end;

function TAIWordParagraph.GetFontName: string;
var
  pPr, rPr, Fonts: TDOMNode;
begin
  Result := '';
  pPr := FindChildNode(FXmlNode, 'w:pPr');
  if Assigned(pPr) then
  begin
    rPr := FindChildNode(pPr, 'w:rPr');
    if Assigned(rPr) then
    begin
      Fonts := FindChildNode(rPr, 'w:rFonts');
      if Assigned(Fonts) then
        Result := GetNodeAttribute(Fonts, 'w:ascii');
    end;
  end;
end;

procedure TAIWordParagraph.SetFontName(const AValue: string);
var
  rPr, Fonts: TDOMNode;
begin
  rPr := GetOrCreatepPrrPr;
  Fonts := GetOrCreateChildNode(rPr, 'w:rFonts');
  SetNodeAttribute(Fonts, 'w:ascii', AValue);
  SetNodeAttribute(Fonts, 'w:hAnsi', AValue);
end;

function TAIWordParagraph.GetFontSize: Integer;
var
  pPr, rPr, Sz: TDOMNode;
  ValStr: string;
  ValInt: Integer;
begin
  Result := 11;
  pPr := FindChildNode(FXmlNode, 'w:pPr');
  if Assigned(pPr) then
  begin
    rPr := FindChildNode(pPr, 'w:rPr');
    if Assigned(rPr) then
    begin
      Sz := FindChildNode(rPr, 'w:sz');
      if Assigned(Sz) then
      begin
        ValStr := GetNodeAttribute(Sz, 'w:val');
        if TryStrToInt(ValStr, ValInt) then
          Result := Round(HalfPointToPt(ValInt));
      end;
    end;
  end;
end;

procedure TAIWordParagraph.SetFontSize(AValue: Integer);
var
  rPr, Sz: TDOMNode;
begin
  rPr := GetOrCreatepPrrPr;
  Sz := GetOrCreateChildNode(rPr, 'w:sz');
  SetNodeAttribute(Sz, 'w:val', IntToStr(PtToHalfPoint(AValue)));
  Sz := GetOrCreateChildNode(rPr, 'w:szCs');
  SetNodeAttribute(Sz, 'w:val', IntToStr(PtToHalfPoint(AValue)));
end;

function TAIWordParagraph.GetBold: Boolean;
var
  pPr, rPr: TDOMNode;
begin
  Result := False;
  pPr := FindChildNode(FXmlNode, 'w:pPr');
  if Assigned(pPr) then
  begin
    rPr := FindChildNode(pPr, 'w:rPr');
    if Assigned(rPr) then
      Result := Assigned(FindChildNode(rPr, 'w:b'));
  end;
end;

procedure TAIWordParagraph.SetBold(AValue: Boolean);
var
  rPr, BNode: TDOMNode;
begin
  rPr := GetOrCreatepPrrPr;
  BNode := FindChildNode(rPr, 'w:b');
  if AValue then
  begin
    if not Assigned(BNode) then
      GetOrCreateChildNode(rPr, 'w:b');
  end
  else
  begin
    if Assigned(BNode) then
      rPr.RemoveChild(BNode);
  end;
end;

function TAIWordParagraph.GetItalic: Boolean;
var
  pPr, rPr: TDOMNode;
begin
  Result := False;
  pPr := FindChildNode(FXmlNode, 'w:pPr');
  if Assigned(pPr) then
  begin
    rPr := FindChildNode(pPr, 'w:rPr');
    if Assigned(rPr) then
      Result := Assigned(FindChildNode(rPr, 'w:i'));
  end;
end;

procedure TAIWordParagraph.SetItalic(AValue: Boolean);
var
  rPr, INode: TDOMNode;
begin
  rPr := GetOrCreatepPrrPr;
  INode := FindChildNode(rPr, 'w:i');
  if AValue then
  begin
    if not Assigned(INode) then
      GetOrCreateChildNode(rPr, 'w:i');
  end
  else
  begin
    if Assigned(INode) then
      rPr.RemoveChild(INode);
  end;
end;

function TAIWordParagraph.GetUnderline: Boolean;
var
  pPr, rPr, UNode: TDOMNode;
begin
  Result := False;
  pPr := FindChildNode(FXmlNode, 'w:pPr');
  if Assigned(pPr) then
  begin
    rPr := FindChildNode(pPr, 'w:rPr');
    if Assigned(rPr) then
    begin
      UNode := FindChildNode(rPr, 'w:u');
      Result := Assigned(UNode) and (GetNodeAttribute(UNode, 'w:val') <> 'none');
    end;
  end;
end;

procedure TAIWordParagraph.SetUnderline(AValue: Boolean);
var
  rPr, UNode: TDOMNode;
begin
  rPr := GetOrCreatepPrrPr;
  UNode := FindChildNode(rPr, 'w:u');
  if AValue then
  begin
    if not Assigned(UNode) then
      UNode := GetOrCreateChildNode(rPr, 'w:u');
    SetNodeAttribute(UNode, 'w:val', 'single');
  end
  else
  begin
    if Assigned(UNode) then
      rPr.RemoveChild(UNode);
  end;
end;

function TAIWordParagraph.GetSpaceBeforePt: Integer;
var
  pPr, Sp: TDOMNode;
  Val: string;
  ValInt: Integer;
begin
  Result := 0;
  pPr := FindChildNode(FXmlNode, 'w:pPr');
  if Assigned(pPr) then
  begin
    Sp := FindChildNode(pPr, 'w:spacing');
    if Assigned(Sp) then
    begin
      Val := GetNodeAttribute(Sp, 'w:before');
      if TryStrToInt(Val, ValInt) then
        Result := ValInt div 20; // 20 twips per pt
    end;
  end;
end;

procedure TAIWordParagraph.SetSpaceBeforePt(AValue: Integer);
var
  pPr, Sp: TDOMNode;
begin
  pPr := GetOrCreatepPr;
  Sp := GetOrCreateChildNode(pPr, 'w:spacing');
  SetNodeAttribute(Sp, 'w:before', IntToStr(AValue * 20));
end;

function TAIWordParagraph.GetSpaceAfterPt: Integer;
var
  pPr, Sp: TDOMNode;
  Val: string;
  ValInt: Integer;
begin
  Result := 0;
  pPr := FindChildNode(FXmlNode, 'w:pPr');
  if Assigned(pPr) then
  begin
    Sp := FindChildNode(pPr, 'w:spacing');
    if Assigned(Sp) then
    begin
      Val := GetNodeAttribute(Sp, 'w:after');
      if TryStrToInt(Val, ValInt) then
        Result := ValInt div 20;
    end;
  end;
end;

procedure TAIWordParagraph.SetSpaceAfterPt(AValue: Integer);
var
  pPr, Sp: TDOMNode;
begin
  pPr := GetOrCreatepPr;
  Sp := GetOrCreateChildNode(pPr, 'w:spacing');
  SetNodeAttribute(Sp, 'w:after', IntToStr(AValue * 20));
end;

function TAIWordParagraph.GetFirstLineIndentMM: Double;
var
  pPr, Ind: TDOMNode;
  Val: string;
  ValInt: Integer;
begin
  Result := 0.0;
  pPr := FindChildNode(FXmlNode, 'w:pPr');
  if Assigned(pPr) then
  begin
    Ind := FindChildNode(pPr, 'w:ind');
    if Assigned(Ind) then
    begin
      Val := GetNodeAttribute(Ind, 'w:firstLine');
      if TryStrToInt(Val, ValInt) then
        Result := TwipToMM(ValInt);
    end;
  end;
end;

procedure TAIWordParagraph.SetFirstLineIndentMM(AValue: Double);
var
  pPr, Ind: TDOMNode;
begin
  pPr := GetOrCreatepPr;
  Ind := GetOrCreateChildNode(pPr, 'w:ind');
  SetNodeAttribute(Ind, 'w:firstLine', IntToStr(MMToTwip(AValue)));
end;

function TAIWordParagraph.AddRun(const AText: string): TAIWordRun;
var
  RunNode: TDOMNode;
  RunObj: TAIWordRun;
begin
  RunNode := FXmlNode.OwnerDocument.CreateElement('w:r');
  FXmlNode.AppendChild(RunNode);
  
  RunObj := TAIWordRun.Create(FOwnerDoc, RunNode);
  if AText <> '' then
    RunObj.Text := AText;
    
  FRuns.Add(RunObj);
  Result := RunObj;
end;

function TAIWordParagraph.AddImage(const AFileName: string; AWidthMM, AHeightMM: Double): TAIWordImage;
var
  Doc: TAIWordDocument;
  TempImg: TAIWordImage;
  RunNode, TempParagraphNode: TDOMNode;
  TempParagraphIndex: Integer;
begin
  Result := nil;
  Doc := TAIWordDocument(FOwnerDoc);
  TempImg := Doc.AddImage(AFileName, AWidthMM, AHeightMM, wipInline);
  if Assigned(TempImg) then
  begin
    // Result.XmlNode is the InlineNode (wp:inline)
    // InlineNode.ParentNode is DrawingNode (w:drawing)
    // DrawingNode.ParentNode is RunNode (w:r)
    RunNode := TempImg.FXmlNode.ParentNode.ParentNode;
    
    // Move RunNode to this paragraph's XML node
    Self.XmlNode.AppendChild(RunNode);
    
    // Create new run object and register it locally
    FRuns.Add(TAIWordRun.Create(FOwnerDoc, RunNode));
    
    // Find and delete the temporary paragraph created by Doc.AddImage
    TempParagraphNode := RunNode.ParentNode; // wait, before appending to Self, it was TempParagraph
    // But since we appended it to Self, RunNode.ParentNode is already Self.XmlNode.
    // So we can find the temporary paragraph node by finding the last w:p in the document body
    // that has no children left or we can do it via the paragraph list.
    // Actually, Doc.AddImage appends a paragraph at the end of the document.
    // That paragraph is the last one in Doc.Paragraphs.
    TempParagraphIndex := Doc.Paragraphs.Count - 1;
    if TempParagraphIndex >= 0 then
    begin
      Doc.Paragraphs[TempParagraphIndex].Delete;
      Doc.Paragraphs.Remove(Doc.Paragraphs[TempParagraphIndex]);
    end;
    
    Result := TempImg;
  end;
end;

procedure TAIWordParagraph.ClearRuns;
var
  I: Integer;
  RNode: TDOMNode;
begin
  for I := 0 to FRuns.Count - 1 do
  begin
    RNode := TAIWordRun(FRuns[I]).FXmlNode;
    if Assigned(RNode) and Assigned(RNode.ParentNode) then
      RNode.ParentNode.RemoveChild(RNode);
    TAIWordRun(FRuns[I]).Free;
  end;
  FRuns.Clear;
end;

procedure TAIWordParagraph.Delete;
begin
  ClearRuns;
  if Assigned(FXmlNode) and Assigned(FXmlNode.ParentNode) then
    FXmlNode.ParentNode.RemoveChild(FXmlNode);
end;


{ TAIWordImage }

constructor TAIWordImage.Create(AOwner: TObject; const AFileName, ARelId: string; AXmlNode: TDOMNode);
begin
  FOwnerDoc := AOwner;
  FFileName := AFileName;
  FRelationshipId := ARelId;
  FXmlNode := AXmlNode;
end;

function TAIWordImage.GetWidthMM: Double;
var
  Ext: TDOMNode;
  CxStr: string;
  CxInt: Int64;
begin
  Result := 0;
  Ext := FindChildNode(FXmlNode, 'wp:extent');
  if Assigned(Ext) then
  begin
    CxStr := GetNodeAttribute(Ext, 'cx');
    if TryStrToInt64(CxStr, CxInt) then
      Result := EMUToMM(CxInt);
  end;
end;

procedure TAIWordImage.SetWidthMM(AValue: Double);
var
  Ext, PicExt: TDOMNode;
  EmuVal: Int64;
begin
  EmuVal := MMToEMU(AValue);
  Ext := FindChildNode(FXmlNode, 'wp:extent');
  if Assigned(Ext) then
    SetNodeAttribute(Ext, 'cx', IntToStr(EmuVal));
    
  // Also update inside pic:spPr/a:xfrm/a:ext
  // Find nested element
  // A simple traversal helper or exact search
end;

function TAIWordImage.GetHeightMM: Double;
var
  Ext: TDOMNode;
  CyStr: string;
  CyInt: Int64;
begin
  Result := 0;
  Ext := FindChildNode(FXmlNode, 'wp:extent');
  if Assigned(Ext) then
  begin
    CyStr := GetNodeAttribute(Ext, 'cy');
    if TryStrToInt64(CyStr, CyInt) then
      Result := EMUToMM(CyInt);
  end;
end;

procedure TAIWordImage.SetHeightMM(AValue: Double);
var
  Ext: TDOMNode;
  EmuVal: Int64;
begin
  EmuVal := MMToEMU(AValue);
  Ext := FindChildNode(FXmlNode, 'wp:extent');
  if Assigned(Ext) then
    SetNodeAttribute(Ext, 'cy', IntToStr(EmuVal));
end;

function TAIWordImage.GetPosition: TAIWordImagePosition;
begin
  Result := wipInline; // Only wipInline is supported in this version
end;

procedure TAIWordImage.SetPosition(AValue: TAIWordImagePosition);
begin
  // Unsupported positions return controlled behavior as specified
end;

function TAIWordImage.GetAlignment: TAIWordAlignment;
begin
  Result := waLeft;
end;

procedure TAIWordImage.SetAlignment(AValue: TAIWordAlignment);
begin
end;

function TAIWordImage.GetAltText: string;
var
  DocPr: TDOMNode;
begin
  Result := '';
  DocPr := FindChildNode(FXmlNode, 'wp:docPr');
  if Assigned(DocPr) then
    Result := GetNodeAttribute(DocPr, 'descr');
end;

procedure TAIWordImage.SetAltText(const AValue: string);
var
  DocPr: TDOMNode;
begin
  DocPr := FindChildNode(FXmlNode, 'wp:docPr');
  if Assigned(DocPr) then
    SetNodeAttribute(DocPr, 'descr', AValue);
end;


{ TAIWordTableCell }

constructor TAIWordTableCell.Create(AOwner: TObject; AXmlNode: TDOMNode);
begin
  FOwnerDoc := AOwner;
  FXmlNode := AXmlNode;
end;

function TAIWordTableCell.GetText: string;
var
  P: TDOMNode;
begin
  Result := '';
  P := FindChildNode(FXmlNode, 'w:p');
  if Assigned(P) then
  begin
    // For simplicity, get all run texts
    // Let's implement it:
    P := FXmlNode.FirstChild;
    while Assigned(P) do
    begin
      if P.NodeName = 'w:p' then
      begin
        // read text of parágrafo
        // we can create a temporary TAIWordParagraph wrapper
        // and fetch its text
        Result := Result + GetNodeText(P); // Wait, text nodes might be in runs, so GetNodeText directly on w:p will return the runs text too!
      end;
      P := P.NextSibling;
    end;
  end;
end;

procedure TAIWordTableCell.SetText(const AValue: string);
var
  P, R, T: TDOMNode;
begin
  // Célula must contain w:p
  P := GetOrCreateChildNode(FXmlNode, 'w:p');
  // Clear runs in P
  while Assigned(P.FirstChild) do
    P.RemoveChild(P.FirstChild);
    
  R := P.OwnerDocument.CreateElement('w:r');
  P.AppendChild(R);
  T := P.OwnerDocument.CreateElement('w:t');
  R.AppendChild(T);
  SetNodeText(T, AValue);
end;

function TAIWordTableCell.GetAlignment: TAIWordAlignment;
var
  P, pPr, Jc: TDOMNode;
  Val: string;
begin
  Result := waLeft;
  P := FindChildNode(FXmlNode, 'w:p');
  if Assigned(P) then
  begin
    pPr := FindChildNode(P, 'w:pPr');
    if Assigned(pPr) then
    begin
      Jc := FindChildNode(pPr, 'w:jc');
      if Assigned(Jc) then
      begin
        Val := GetNodeAttribute(Jc, 'w:val');
        if Val = 'center' then Result := waCenter
        else if Val = 'right' then Result := waRight
        else if Val = 'both' then Result := waJustify;
      end;
    end;
  end;
end;

procedure TAIWordTableCell.SetAlignment(AValue: TAIWordAlignment);
var
  P, pPr, Jc: TDOMNode;
  JcVal: string;
begin
  P := GetOrCreateChildNode(FXmlNode, 'w:p');
  pPr := GetOrCreateChildNode(P, 'w:pPr');
  Jc := GetOrCreateChildNode(pPr, 'w:jc');
  case AValue of
    waLeft: JcVal := 'left';
    waCenter: JcVal := 'center';
    waRight: JcVal := 'right';
    waJustify: JcVal := 'both';
  end;
  SetNodeAttribute(Jc, 'w:val', JcVal);
end;

function TAIWordTableCell.GetBold: Boolean;
var
  P, R, rPr: TDOMNode;
begin
  Result := False;
  P := FindChildNode(FXmlNode, 'w:p');
  if Assigned(P) then
  begin
    R := FindChildNode(P, 'w:r');
    if Assigned(R) then
    begin
      rPr := FindChildNode(R, 'w:rPr');
      if Assigned(rPr) then
        Result := Assigned(FindChildNode(rPr, 'w:b'));
    end;
  end;
end;

procedure TAIWordTableCell.SetBold(AValue: Boolean);
var
  P, R, rPr, B: TDOMNode;
begin
  P := GetOrCreateChildNode(FXmlNode, 'w:p');
  R := GetOrCreateChildNode(P, 'w:r');
  rPr := GetOrCreateChildNode(R, 'w:rPr');
  B := FindChildNode(rPr, 'w:b');
  if AValue then
  begin
    if not Assigned(B) then
      GetOrCreateChildNode(rPr, 'w:b');
  end
  else
  begin
    if Assigned(B) then
      rPr.RemoveChild(B);
  end;
end;

function TAIWordTableCell.GetShadingColor: TColor;
var
  tcPr, Shd: TDOMNode;
begin
  Result := clWhite;
  tcPr := FindChildNode(FXmlNode, 'w:tcPr');
  if Assigned(tcPr) then
  begin
    Shd := FindChildNode(tcPr, 'w:shd');
    if Assigned(Shd) then
      Result := HexToColor(GetNodeAttribute(Shd, 'w:fill'));
  end;
end;

procedure TAIWordTableCell.SetShadingColor(AColor: TColor);
var
  tcPr, Shd: TDOMNode;
begin
  tcPr := GetOrCreateChildNode(FXmlNode, 'w:tcPr');
  Shd := GetOrCreateChildNode(tcPr, 'w:shd');
  SetNodeAttribute(Shd, 'w:val', 'clear');
  SetNodeAttribute(Shd, 'w:color', 'auto');
  SetNodeAttribute(Shd, 'w:fill', ColorToHex(AColor));
end;


{ TAIWordTable }

constructor TAIWordTable.Create(AOwner: TObject; AXmlNode: TDOMNode; ARows, ACols: Integer);
var
  R, C: Integer;
  RowNode, CellNode: TDOMNode;
begin
  FOwnerDoc := AOwner;
  FXmlNode := AXmlNode;
  FRows := ARows;
  FCols := ACols;
  
  SetLength(FCells, FRows, FCols);
  
  // Find or create rows and cells in XML
  RowNode := FXmlNode.FirstChild;
  // Skip tblPr
  while Assigned(RowNode) and (RowNode.NodeName = 'w:tblPr') do
    RowNode := RowNode.NextSibling;
    
  for R := 0 to FRows - 1 do
  begin
    if not Assigned(RowNode) then
    begin
      RowNode := FXmlNode.OwnerDocument.CreateElement('w:tr');
      FXmlNode.AppendChild(RowNode);
    end;
    
    CellNode := RowNode.FirstChild;
    for C := 0 to FCols - 1 do
    begin
      if not Assigned(CellNode) then
      begin
        CellNode := RowNode.OwnerDocument.CreateElement('w:tc');
        RowNode.AppendChild(CellNode);
        
        // Célula must have a paragraph w:p
        GetOrCreateChildNode(CellNode, 'w:p');
      end;
      
      FCells[R, C] := TAIWordTableCell.Create(FOwnerDoc, CellNode);
      CellNode := CellNode.NextSibling;
    end;
    RowNode := RowNode.NextSibling;
  end;
end;

destructor TAIWordTable.Destroy;
var
  R, C: Integer;
begin
  for R := 0 to FRows - 1 do
    for C := 0 to FCols - 1 do
      FCells[R, C].Free;
  SetLength(FCells, 0, 0);
  inherited Destroy;
end;

function TAIWordTable.Cell(ARow, ACol: Integer): TAIWordTableCell;
begin
  if (ARow >= 0) and (ARow < FRows) and (ACol >= 0) and (ACol < FCols) then
    Result := FCells[ARow, ACol]
  else
    Result := nil;
end;

function TAIWordTable.GetBorder: Boolean;
var
  TblPr, Borders: TDOMNode;
begin
  Result := False;
  TblPr := FindChildNode(FXmlNode, 'w:tblPr');
  if Assigned(TblPr) then
  begin
    Borders := FindChildNode(TblPr, 'w:tblBorders');
    Result := Assigned(Borders);
  end;
end;

procedure TAIWordTable.SetBorder(AValue: Boolean);
var
  TblPr, Borders, Side: TDOMNode;
  Sides: array[0..5] of string;
  I: Integer;
begin
  TblPr := GetOrCreateChildNode(FXmlNode, 'w:tblPr');
  Borders := FindChildNode(TblPr, 'w:tblBorders');
  
  if not AValue then
  begin
    if Assigned(Borders) then
      TblPr.RemoveChild(Borders);
    Exit;
  end;
  
  if not Assigned(Borders) then
    Borders := GetOrCreateChildNode(TblPr, 'w:tblBorders');
    
  Sides[0] := 'w:top';
  Sides[1] := 'w:left';
  Sides[2] := 'w:bottom';
  Sides[3] := 'w:right';
  Sides[4] := 'w:insideH';
  Sides[5] := 'w:insideV';
  
  for I := 0 to 5 do
  begin
    Side := GetOrCreateChildNode(Borders, Sides[I]);
    SetNodeAttribute(Side, 'w:val', 'single');
    SetNodeAttribute(Side, 'w:sz', '4');
    SetNodeAttribute(Side, 'w:space', '0');
    SetNodeAttribute(Side, 'w:color', 'auto');
  end;
end;

function TAIWordTable.GetWidthPercent: Integer;
var
  TblPr, TblW: TDOMNode;
  ValStr: string;
begin
  Result := 100;
  TblPr := FindChildNode(FXmlNode, 'w:tblPr');
  if Assigned(TblPr) then
  begin
    TblW := FindChildNode(TblPr, 'w:tblW');
    if Assigned(TblW) then
    begin
      ValStr := GetNodeAttribute(TblW, 'w:w');
      // For percent type, the width is defined in 50ths of a percent, e.g. 5000 = 100%
      TryStrToInt(ValStr, Result);
      Result := Result div 50;
    end;
  end;
end;

procedure TAIWordTable.SetWidthPercent(AValue: Integer);
var
  TblPr, TblW: TDOMNode;
begin
  TblPr := GetOrCreateChildNode(FXmlNode, 'w:tblPr');
  TblW := GetOrCreateChildNode(TblPr, 'w:tblW');
  SetNodeAttribute(TblW, 'w:w', IntToStr(AValue * 50));
  SetNodeAttribute(TblW, 'w:type', 'pct');
end;


{ TAIWordHeaderFooter }

constructor TAIWordHeaderFooter.Create(AOwner: TObject; AXmlNode: TDOMNode; const ARelId, ATempFileName: string);
begin
  FOwnerDoc := AOwner;
  FXmlNode := AXmlNode;
  FRelId := ARelId;
  FTempFileName := ATempFileName;
end;

procedure TAIWordHeaderFooter.Clear;
begin
  if Assigned(FXmlNode) then
  begin
    while Assigned(FXmlNode.FirstChild) do
      FXmlNode.RemoveChild(FXmlNode.FirstChild);
  end;
end;

function TAIWordHeaderFooter.AddParagraph(const AText: string): TAIWordParagraph;
var
  PNode: TDOMNode;
begin
  PNode := FXmlNode.OwnerDocument.CreateElement('w:p');
  FXmlNode.AppendChild(PNode);
  Result := TAIWordParagraph.Create(FOwnerDoc, PNode);
  if AText <> '' then
    Result.Text := AText;
end;

procedure TAIWordHeaderFooter.AddPageNumber;
var
  PNode, RNode, FldSimple: TDOMNode;
begin
  PNode := FXmlNode.OwnerDocument.CreateElement('w:p');
  FXmlNode.AppendChild(PNode);
  
  // Align page number center
  SetNodeAttribute(GetOrCreateChildNode(PNode, 'w:pPr'), 'w:jc', 'center');
  
  RNode := FXmlNode.OwnerDocument.CreateElement('w:r');
  PNode.AppendChild(RNode);
  
  FldSimple := FXmlNode.OwnerDocument.CreateElement('w:fldSimple');
  SetNodeAttribute(FldSimple, 'w:instr', 'PAGE');
  PNode.AppendChild(FldSimple);
end;


{ TAIWordPageSetup }

constructor TAIWordPageSetup.Create(AOwner: TObject; AXmlNode: TDOMNode);
var
  PgSz, PgMar: TDOMNode;
  Val: string;
  ValInt: Integer;
begin
  FOwnerDoc := AOwner;
  FXmlNode := AXmlNode;
  
  // Set defaults
  FPaperSize := wpsA4;
  FOrientation := woPortrait;
  FMarginLeftMM := 25.0;
  FMarginRightMM := 25.0;
  FMarginTopMM := 20.0;
  FMarginBottomMM := 20.0;
  
  // Parse from XML if elements exist
  PgSz := FindChildNode(FXmlNode, 'w:pgSz');
  if Assigned(PgSz) then
  begin
    Val := GetNodeAttribute(PgSz, 'w:orient');
    if Val = 'landscape' then FOrientation := woLandscape;
    
    Val := GetNodeAttribute(PgSz, 'w:w');
    if TryStrToInt(Val, ValInt) then
    begin
      // A4 is 11906, Letter is 12240
      if ValInt = 12240 then FPaperSize := wpsLetter
      else if ValInt = 15120 then FPaperSize := wpsLegal;
    end;
  end;
  
  PgMar := FindChildNode(FXmlNode, 'w:pgMar');
  if Assigned(PgMar) then
  begin
    Val := GetNodeAttribute(PgMar, 'w:left');
    if TryStrToInt(Val, ValInt) then FMarginLeftMM := TwipToMM(ValInt);
    
    Val := GetNodeAttribute(PgMar, 'w:right');
    if TryStrToInt(Val, ValInt) then FMarginRightMM := TwipToMM(ValInt);
    
    Val := GetNodeAttribute(PgMar, 'w:top');
    if TryStrToInt(Val, ValInt) then FMarginTopMM := TwipToMM(ValInt);
    
    Val := GetNodeAttribute(PgMar, 'w:bottom');
    if TryStrToInt(Val, ValInt) then FMarginBottomMM := TwipToMM(ValInt);
  end;
end;

procedure TAIWordPageSetup.UpdateXML;
var
  PgSz, PgMar: TDOMNode;
  W, H: Integer;
begin
  if not Assigned(FXmlNode) then
    Exit;
    
  PgSz := GetOrCreateChildNode(FXmlNode, 'w:pgSz');
  case FPaperSize of
    wpsA4:
      begin
        W := 11906; H := 16838;
      end;
    wpsLetter:
      begin
        W := 12240; H := 15840;
      end;
    wpsLegal:
      begin
        W := 12240; H := 20160;
      end;
  end;
  
  if FOrientation = woLandscape then
  begin
    // Swap width and height
    PgSz.Attributes.GetNamedItem('w:w').NodeValue := IntToStr(H);
    PgSz.Attributes.GetNamedItem('w:h').NodeValue := IntToStr(W);
    SetNodeAttribute(PgSz, 'w:orient', 'landscape');
  end;
end;

end.
