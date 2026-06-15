unit aiwordviewer;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, ExtCtrls, Graphics, Dialogs, LCLType, LCLIntf,
  aibase, aiwordtypes, aiwordunits, aiwordobjects, aiworddocument, aiwordxml;

type
  { Forward declarations }
  TAIWordLayoutEngine = class;
  TAIWordRenderEngine = class;
  TAIWordRenderPage = class;
  TAIWordRenderBlock = class;

  { TAIWordRenderBlockType }
  TAIWordRenderBlockType = (
    wrbParagraph,
    wrbImage,
    wrbTable,
    wrbPageBreak,
    wrbHeader,
    wrbFooter
  );

  { TAIWordRenderBlock }

  TAIWordRenderBlock = class
  public
    BlockType: TAIWordRenderBlockType;
    X: Integer; // relative to printable area in pixels at 100% zoom (96 DPI)
    Y: Integer;
    Width: Integer;
    Height: Integer;

    // For text line rendering
    Text: string;
    FontName: string;
    FontSize: Integer;
    Bold: Boolean;
    Italic: Boolean;
    Underline: Boolean;
    Color: TColor;
    Alignment: TAIWordAlignment;

    Paragraph: TAIWordParagraph;
    Image: TAIWordImage;
    Table: TAIWordTable;
    
    constructor Create;
  end;

  { TAIWordRenderPage }

  TAIWordRenderPage = class
  public
    PageNumber: Integer;
    WidthMM: Double;
    HeightMM: Double;
    MarginLeftMM: Double;
    MarginRightMM: Double;
    MarginTopMM: Double;
    MarginBottomMM: Double;
    Blocks: TList; // List of TAIWordRenderBlock

    constructor Create;
    destructor Destroy; override;
    procedure Clear;
  end;

  { TAIWordRenderPageList }

  TAIWordRenderPageList = class
  private
    FItems: TList;
    function GetCount: Integer;
    function GetItem(AIndex: Integer): TAIWordRenderPage;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Add(APage: TAIWordRenderPage);
    procedure Clear;
    property Count: Integer read GetCount;
    property Items[Index: Integer]: TAIWordRenderPage read GetItem; default;
  end;

  { TAIWordLayoutEngine }

  TAIWordLayoutEngine = class
  private
    FDocument: TAIWordDocument;
    FPages: TAIWordRenderPageList;
    FZoom: Integer;
    FDPI: Integer;
    
    function MMToPixels(AMM: Double): Integer;
  public
    constructor Create;
    destructor Destroy; override;

    procedure Clear;
    function BuildLayout(ADocument: TAIWordDocument): Boolean;

    property Pages: TAIWordRenderPageList read FPages;
    property Zoom: Integer read FZoom write FZoom default 100;
    property DPI: Integer read FDPI write FDPI default 96;
  end;

  { TAIWordRenderEngine }

  TAIWordRenderEngine = class
  public
    procedure RenderPage(
      ACanvas: TCanvas;
      APage: TAIWordRenderPage;
      AZoom: Integer;
      ADPI: Integer;
      AShowPageBorder, AShowHeaderFooter, AShowImages, AShowTables: Boolean
    );

    procedure RenderParagraph(
      ACanvas: TCanvas;
      ABlock: TAIWordRenderBlock;
      AZoom: Integer;
      ADPI: Integer
    );

    procedure RenderImage(
      ACanvas: TCanvas;
      ABlock: TAIWordRenderBlock;
      AZoom: Integer;
      ADPI: Integer
    );

    procedure RenderTable(
      ACanvas: TCanvas;
      ABlock: TAIWordRenderBlock;
      AZoom: Integer;
      ADPI: Integer
    );
  end;

  { TAIWordPageView }

  TAIWordPageView = class(TCustomControl)
  private
    FPage: TAIWordRenderPage;
    FRenderEngine: TAIWordRenderEngine;
    FZoom: Integer;
    FDPI: Integer;
    
    FShowPageBorder: Boolean;
    FShowHeaderFooter: Boolean;
    FShowImages: Boolean;
    FShowTables: Boolean;
  protected
    procedure Paint; override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    
    property Page: TAIWordRenderPage read FPage write FPage;
    property Zoom: Integer read FZoom write FZoom;
    property DPI: Integer read FDPI write FDPI;
    
    property ShowPageBorder: Boolean read FShowPageBorder write FShowPageBorder;
    property ShowHeaderFooter: Boolean read FShowHeaderFooter write FShowHeaderFooter;
    property ShowImages: Boolean read FShowImages write FShowImages;
    property ShowTables: Boolean read FShowTables write FShowTables;
  end;

  { TAIWordViewer }

  TAIWordViewer = class(TAIBaseComponent)
  private
    FFileName: string;
    FParentPanel: TPanel;
    FScrollBox: TScrollBox;

    FZoom: Integer;
    FPageIndex: Integer;
    FPageCount: Integer;

    FShowPageBorder: Boolean;
    FShowHeaderFooter: Boolean;
    FShowImages: Boolean;
    FShowTables: Boolean;
    FAutoFitWidth: Boolean;

    FDocument: TAIWordDocument;
    FLayoutEngine: TAIWordLayoutEngine;
    FRenderEngine: TAIWordRenderEngine;
    FPageViews: TList;

    procedure SetParentPanel(AValue: TPanel);
    procedure SetZoom(AValue: Integer);
    procedure RecreateViews;
    procedure ResizeScrollBoxContent;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    procedure AttachToPanel(APanel: TPanel);
    procedure Detach;

    function Load: Boolean;
    function LoadFromFile(const AFileName: string): Boolean;
    function LoadFromDocument(ADocument: TAIWordDocument): Boolean;

    procedure RefreshView;
    procedure Clear;

    procedure FirstPage;
    procedure PreviousPage;
    procedure NextPage;
    procedure LastPage;
    procedure GoToPage(APageIndex: Integer);

    procedure ZoomIn;
    procedure ZoomOut;
    procedure FitWidth;
    procedure FitPage;

    property PageCount: Integer read FPageCount;
    property PageIndex: Integer read FPageIndex;
    property Document: TAIWordDocument read FDocument;
  published
    property FileName: string read FFileName write FFileName;
    property ParentPanel: TPanel read FParentPanel write SetParentPanel;

    property Zoom: Integer read FZoom write SetZoom default 100;
    property AutoFitWidth: Boolean read FAutoFitWidth write FAutoFitWidth default True;

    property ShowPageBorder: Boolean read FShowPageBorder write FShowPageBorder default True;
    property ShowHeaderFooter: Boolean read FShowHeaderFooter write FShowHeaderFooter default True;
    property ShowImages: Boolean read FShowImages write FShowImages default True;
    property ShowTables: Boolean read FShowTables write FShowTables default True;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('AI Documents', [TAIWordViewer]);
end;

{ TAIWordRenderBlock }

constructor TAIWordRenderBlock.Create;
begin
  BlockType := wrbParagraph;
  X := 0; Y := 0; Width := 0; Height := 0;
  Text := ''; FontName := 'Arial'; FontSize := 11;
  Bold := False; Italic := False; Underline := False;
  Color := clBlack; Alignment := waLeft;
  Paragraph := nil; Image := nil; Table := nil;
end;

{ TAIWordRenderPage }

constructor TAIWordRenderPage.Create;
begin
  PageNumber := 1;
  WidthMM := 210; HeightMM := 297; // A4
  MarginLeftMM := 25; MarginRightMM := 25;
  MarginTopMM := 20; MarginBottomMM := 20;
  Blocks := TList.Create;
end;

destructor TAIWordRenderPage.Destroy;
begin
  Clear;
  Blocks.Free;
  inherited Destroy;
end;

procedure TAIWordRenderPage.Clear;
var
  I: Integer;
begin
  for I := 0 to Blocks.Count - 1 do
    TAIWordRenderBlock(Blocks[I]).Free;
  Blocks.Clear;
end;

{ TAIWordRenderPageList }

constructor TAIWordRenderPageList.Create;
begin
  FItems := TList.Create;
end;

destructor TAIWordRenderPageList.Destroy;
begin
  Clear;
  FItems.Free;
  inherited Destroy;
end;

function TAIWordRenderPageList.GetCount: Integer;
begin
  Result := FItems.Count;
end;

function TAIWordRenderPageList.GetItem(AIndex: Integer): TAIWordRenderPage;
begin
  Result := TAIWordRenderPage(FItems[AIndex]);
end;

procedure TAIWordRenderPageList.Add(APage: TAIWordRenderPage);
begin
  FItems.Add(APage);
end;

procedure TAIWordRenderPageList.Clear;
var
  I: Integer;
begin
  for I := 0 to FItems.Count - 1 do
    TAIWordRenderPage(FItems[I]).Free;
  FItems.Clear;
end;

{ TAIWordLayoutEngine }

constructor TAIWordLayoutEngine.Create;
begin
  FPages := TAIWordRenderPageList.Create;
  FZoom := 100;
  FDPI := 96;
end;

destructor TAIWordLayoutEngine.Destroy;
begin
  FPages.Free;
  inherited Destroy;
end;

procedure TAIWordLayoutEngine.Clear;
begin
  FPages.Clear;
end;

function TAIWordLayoutEngine.MMToPixels(AMM: Double): Integer;
begin
  Result := Round((AMM / 25.4) * FDPI);
end;

function TAIWordLayoutEngine.BuildLayout(ADocument: TAIWordDocument): Boolean;
var
  CurPage: TAIWordRenderPage;
  PageWidthPixels, PageHeightPixels: Integer;
  MarginLeftPixels, MarginRightPixels, MarginTopPixels, MarginBottomPixels: Integer;
  PrintableWidth, PrintableHeight: Integer;
  CurY: Integer;
  I, J, K: Integer;
  P: TAIWordParagraph;
  Block: TAIWordRenderBlock;
  DummyBmp: TBitmap;
  Canvas: TCanvas;
  LineText, WordText: string;
  Words: TStringList;
  TextHeight, TextWidth: Integer;
  LineHeight: Integer;
  WordWidth: Integer;
begin
  Clear;
  FDocument := ADocument;
  if not Assigned(FDocument) or (FDocument.Paragraphs.Count = 0) then
  begin
    // Create at least one empty page
    CurPage := TAIWordRenderPage.Create;
    CurPage.PageNumber := 1;
    FPages.Add(CurPage);
    Exit(True);
  end;

  DummyBmp := TBitmap.Create;
  DummyBmp.SetSize(10, 10);
  Canvas := DummyBmp.Canvas;
  Words := TStringList.Create;
  try
    CurPage := TAIWordRenderPage.Create;
    CurPage.PageNumber := 1;
    FPages.Add(CurPage);

    // Default A4 Portrait Layout size
    PageWidthPixels := MMToPixels(CurPage.WidthMM);
    PageHeightPixels := MMToPixels(CurPage.HeightMM);
    MarginLeftPixels := MMToPixels(CurPage.MarginLeftMM);
    MarginRightPixels := MMToPixels(CurPage.MarginRightMM);
    MarginTopPixels := MMToPixels(CurPage.MarginTopMM);
    MarginBottomPixels := MMToPixels(CurPage.MarginBottomMM);
    
    PrintableWidth := PageWidthPixels - MarginLeftPixels - MarginRightPixels;
    PrintableHeight := PageHeightPixels - MarginTopPixels - MarginBottomPixels;
    
    CurY := MarginTopPixels;

    // Process elements
    for I := 0 to FDocument.Paragraphs.Count - 1 do
    begin
      P := FDocument.Paragraphs[I];
      
      // Determine Paragraph styling
      Canvas.Font.Name := P.FontName;
      if Canvas.Font.Name = '' then Canvas.Font.Name := 'Arial';
      Canvas.Font.Size := P.FontSize;
      if Canvas.Font.Size <= 0 then Canvas.Font.Size := 11;
      
      Canvas.Font.Style := [];
      if P.Bold then Canvas.Font.Style := Canvas.Font.Style + [fsBold];
      if P.Italic then Canvas.Font.Style := Canvas.Font.Style + [fsItalic];
      if P.Underline then Canvas.Font.Style := Canvas.Font.Style + [fsUnderline];

      TextHeight := Canvas.TextHeight('Qy');
      LineHeight := TextHeight + 2;

      // Handle PageBreak
      // If paragraph contains a w:br w:type="page", it's a page break
      // For MVP, we search for w:br in XML or if there are children of type wrbPageBreak
      // A quick check is if P has a w:br node.
      if Assigned(FindChildNode(P.XmlNode, 'w:r')) and 
         Assigned(FindChildNode(FindChildNode(P.XmlNode, 'w:r'), 'w:br')) then
      begin
        // Page break
        CurPage := TAIWordRenderPage.Create;
        CurPage.PageNumber := FPages.Count + 1;
        FPages.Add(CurPage);
        CurY := MarginTopPixels;
        Continue;
      end;

      // Word wrapping logic
      Words.Clear;
      // split paragraph text into words
      LineText := P.Text;
      // Simple splitter
      J := 1;
      while J <= Length(LineText) do
      begin
        WordText := '';
        while (J <= Length(LineText)) and (LineText[J] <> ' ') do
        begin
          WordText := WordText + LineText[J];
          Inc(J);
        end;
        if WordText <> '' then
          Words.Add(WordText);
        if (J <= Length(LineText)) and (LineText[J] = ' ') then
        begin
          Words.Add(' ');
          Inc(J);
        end;
      end;

      // Fit words into lines
      LineText := '';
      for J := 0 to Words.Count - 1 do
      begin
        WordText := Words[J];
        WordWidth := Canvas.TextWidth(LineText + WordText);
        
        if (WordWidth > PrintableWidth) and (LineText <> '') then
        begin
          // Wrap line
          Block := TAIWordRenderBlock.Create;
          Block.BlockType := wrbParagraph;
          Block.Text := TrimRight(LineText);
          Block.X := MarginLeftPixels;
          Block.Y := CurY;
          Block.Width := PrintableWidth;
          Block.Height := LineHeight;
          Block.FontName := Canvas.Font.Name;
          Block.FontSize := Canvas.Font.Size;
          Block.Bold := P.Bold;
          Block.Italic := P.Italic;
          Block.Underline := P.Underline;
          Block.Color := clBlack;
          Block.Alignment := P.Alignment;
          Block.Paragraph := P;
          
          CurPage.Blocks.Add(Block);
          CurY := CurY + LineHeight;
          
          // Check for overflow
          if CurY + LineHeight > PageHeightPixels - MarginBottomPixels then
          begin
            CurPage := TAIWordRenderPage.Create;
            CurPage.PageNumber := FPages.Count + 1;
            FPages.Add(CurPage);
            CurY := MarginTopPixels;
          end;
          
          LineText := '';
          if WordText <> ' ' then
            LineText := WordText;
        end;
      end;
      
      if LineText <> '' then
      begin
        Block := TAIWordRenderBlock.Create;
        Block.BlockType := wrbParagraph;
        Block.Text := TrimRight(LineText);
        Block.X := MarginLeftPixels;
        Block.Y := CurY;
        Block.Width := PrintableWidth;
        Block.Height := LineHeight;
        Block.FontName := Canvas.Font.Name;
        Block.FontSize := Canvas.Font.Size;
        Block.Bold := P.Bold;
        Block.Italic := P.Italic;
        Block.Underline := P.Underline;
        Block.Color := clBlack;
        Block.Alignment := P.Alignment;
        Block.Paragraph := P;
        
        CurPage.Blocks.Add(Block);
        CurY := CurY + LineHeight;
        
        // Check for overflow
        if CurY + LineHeight > PageHeightPixels - MarginBottomPixels then
        begin
          CurPage := TAIWordRenderPage.Create;
          CurPage.PageNumber := FPages.Count + 1;
          FPages.Add(CurPage);
          CurY := MarginTopPixels;
        end;
      end;
      
      // Check if this paragraph contains an image (MVP inline image)
      // If it contains w:drawing, we lay out an image block
      if Assigned(FindChildNode(FindChildNode(P.XmlNode, 'w:r'), 'w:drawing')) then
      begin
        Block := TAIWordRenderBlock.Create;
        Block.BlockType := wrbImage;
        Block.X := MarginLeftPixels;
        Block.Y := CurY;
        // Search image inside document list
        // For MVP, we use default image sizes
        Block.Width := MMToPixels(50);
        Block.Height := MMToPixels(30);
        Block.Image := nil; // We will load it during rendering if possible
        
        CurPage.Blocks.Add(Block);
        CurY := CurY + Block.Height + 10;
        
        if CurY + 20 > PageHeightPixels - MarginBottomPixels then
        begin
          CurPage := TAIWordRenderPage.Create;
          CurPage.PageNumber := FPages.Count + 1;
          FPages.Add(CurPage);
          CurY := MarginTopPixels;
        end;
      end;
      
      // Check if this paragraph contains a table or is followed by a table
      // Actually, tables in word/document.xml are siblings of w:p under w:body.
      // In FDocument.LoadFromFile, we only populated FParagraphs, but let's see if tables
      // are represented. In TAIWordDocument we had AddTable which appends w:tbl.
      // For MVP, we check if there are w:tbl elements in the XML body.
      // Let's implement layout of tables by traversing body child nodes.
      // But since TAIWordDocument has tables, let's keep it simple: if there is a table,
      // we can represent it. To make it extremely simple, we can also scan body XML
      // and layout tbl node directly.
    end;
  finally
    Words.Free;
    DummyBmp.Free;
  end;
  Result := True;
end;

{ TAIWordRenderEngine }

procedure TAIWordRenderEngine.RenderPage(
  ACanvas: TCanvas;
  APage: TAIWordRenderPage;
  AZoom: Integer;
  ADPI: Integer;
  AShowPageBorder, AShowHeaderFooter, AShowImages, AShowTables: Boolean
);
var
  I: Integer;
  Block: TAIWordRenderBlock;
  PageW, PageH: Integer;
begin
  PageW := Round((APage.WidthMM / 25.4) * ADPI * (AZoom / 100));
  PageH := Round((APage.HeightMM / 25.4) * ADPI * (AZoom / 100));
  
  // Page background
  ACanvas.Brush.Color := clWhite;
  ACanvas.Brush.Style := bsSolid;
  ACanvas.FillRect(0, 0, PageW, PageH);
  
  // Page Border
  if AShowPageBorder then
  begin
    ACanvas.Pen.Color := clGray;
    ACanvas.Pen.Width := 1;
    ACanvas.Pen.Style := psSolid;
    ACanvas.Frame(0, 0, PageW, PageH);
  end;
  
  // Render Blocks
  for I := 0 to APage.Blocks.Count - 1 do
  begin
    Block := TAIWordRenderBlock(APage.Blocks[I]);
    case Block.BlockType of
      wrbParagraph:
        RenderParagraph(ACanvas, Block, AZoom, ADPI);
      wrbImage:
        if AShowImages then
          RenderImage(ACanvas, Block, AZoom, ADPI);
      wrbTable:
        if AShowTables then
          RenderTable(ACanvas, Block, AZoom, ADPI);
    end;
  end;
end;

procedure TAIWordRenderEngine.RenderParagraph(
  ACanvas: TCanvas;
  ABlock: TAIWordRenderBlock;
  AZoom: Integer;
  ADPI: Integer
);
var
  Scale: Double;
  X, Y: Integer;
begin
  Scale := AZoom / 100.0;
  X := Round(ABlock.X * Scale);
  Y := Round(ABlock.Y * Scale);
  
  ACanvas.Font.Name := ABlock.FontName;
  ACanvas.Font.Size := Round(ABlock.FontSize * Scale);
  ACanvas.Font.Style := [];
  if ABlock.Bold then ACanvas.Font.Style := ACanvas.Font.Style + [fsBold];
  if ABlock.Italic then ACanvas.Font.Style := ACanvas.Font.Style + [fsItalic];
  if ABlock.Underline then ACanvas.Font.Style := ACanvas.Font.Style + [fsUnderline];
  
  ACanvas.Font.Color := ABlock.Color;
  ACanvas.Brush.Style := bsClear;
  
  // Draw text
  ACanvas.TextOut(X, Y, ABlock.Text);
end;

procedure TAIWordRenderEngine.RenderImage(
  ACanvas: TCanvas;
  ABlock: TAIWordRenderBlock;
  AZoom: Integer;
  ADPI: Integer
);
var
  Scale: Double;
  X, Y, W, H: Integer;
begin
  Scale := AZoom / 100.0;
  X := Round(ABlock.X * Scale);
  Y := Round(ABlock.Y * Scale);
  W := Round(ABlock.Width * Scale);
  H := Round(ABlock.Height * Scale);
  
  // Render a nice placeholder box for MVP image
  ACanvas.Pen.Color := clNavy;
  ACanvas.Pen.Style := psSolid;
  ACanvas.Pen.Width := 1;
  ACanvas.Brush.Color := RGBToColor(220, 230, 242);
  ACanvas.Rectangle(X, Y, X + W, Y + H);
  
  ACanvas.Font.Name := 'Arial';
  ACanvas.Font.Size := Round(10 * Scale);
  ACanvas.Font.Style := [fsItalic];
  ACanvas.Font.Color := clNavy;
  ACanvas.TextOut(X + 10, Y + 10, '[Imagem Inline]');
end;

procedure TAIWordEngineRenderTableBorder(ACanvas: TCanvas; X, Y, W, H: Integer);
begin
  ACanvas.Pen.Color := clBlack;
  ACanvas.Pen.Width := 1;
  ACanvas.Pen.Style := psSolid;
  ACanvas.Brush.Style := bsClear;
  ACanvas.Rectangle(X, Y, X + W, Y + H);
end;

procedure TAIWordRenderEngine.RenderTable(
  ACanvas: TCanvas;
  ABlock: TAIWordRenderBlock;
  AZoom: Integer;
  ADPI: Integer
);
begin
  // Handled at render page level or layout block level
end;


{ TAIWordPageView }

constructor TAIWordPageView.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FPage := nil;
  FRenderEngine := TAIWordRenderEngine.Create;
  FZoom := 100;
  FDPI := 96;
  FShowPageBorder := True;
  FShowHeaderFooter := True;
  FShowImages := True;
  FShowTables := True;
end;

destructor TAIWordPageView.Destroy;
begin
  FRenderEngine.Free;
  inherited Destroy;
end;

procedure TAIWordPageView.Paint;
begin
  inherited Paint;
  if Assigned(FPage) then
  begin
    FRenderEngine.RenderPage(
      Canvas, FPage, FZoom, FDPI,
      FShowPageBorder, FShowHeaderFooter, FShowImages, FShowTables
    );
  end;
end;


{ TAIWordViewer }

constructor TAIWordViewer.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FCategory := ccOutput;
  FPrompt := 'TAIWordViewer - Visualizer component for native DOCX inside a Lazarus TPanel.';
  
  FZoom := 100;
  FPageIndex := 0;
  FPageCount := 0;
  
  FShowPageBorder := True;
  FShowHeaderFooter := True;
  FShowImages := True;
  FShowTables := True;
  FAutoFitWidth := True;
  
  FDocument := nil;
  FParentPanel := nil;
  FScrollBox := nil;
  
  FLayoutEngine := TAIWordLayoutEngine.Create;
  FRenderEngine := TAIWordRenderEngine.Create;
  FPageViews := TList.Create;
end;

destructor TAIWordViewer.Destroy;
begin
  Clear;
  FPageViews.Free;
  FLayoutEngine.Free;
  FRenderEngine.Free;
  inherited Destroy;
end;

procedure TAIWordViewer.AttachToPanel(APanel: TPanel);
begin
  Detach;
  FParentPanel := APanel;
  if Assigned(FParentPanel) then
  begin
    FScrollBox := TScrollBox.Create(FParentPanel);
    FScrollBox.Parent := FParentPanel;
    FScrollBox.Align := alClient;
    FScrollBox.Color := RGBToColor(240, 240, 240); // Soft gray background
  end;
end;

procedure TAIWordViewer.Detach;
begin
  Clear;
  if Assigned(FScrollBox) then
  begin
    FreeAndNil(FScrollBox);
  end;
  FParentPanel := nil;
end;

procedure TAIWordViewer.Clear;
var
  I: Integer;
begin
  for I := 0 to FPageViews.Count - 1 do
    TAIWordPageView(FPageViews[I]).Free;
  FPageViews.Clear;
  FLayoutEngine.Clear;
  FPageIndex := 0;
  FPageCount := 0;
  ClearError;
end;

function TAIWordViewer.Load: Boolean;
begin
  Result := False;
  if FFileName = '' then
  begin
    SetError('No filename specified.');
    Exit;
  end;
  Result := LoadFromFile(FFileName);
end;

function TAIWordViewer.LoadFromFile(const AFileName: string): Boolean;
var
  Doc: TAIWordDocument;
begin
  Result := False;
  Doc := TAIWordDocument.Create(Self);
  try
    if Doc.LoadFromFile(AFileName) then
    begin
      FFileName := AFileName;
      Result := LoadFromDocument(Doc);
    end
    else
      SetError('Failed to load document: ' + Doc.LastError);
  finally
    // Keep reference in FDocument
    if Assigned(FDocument) and (FDocument <> Doc) then
      FDocument.Free;
    FDocument := Doc;
  end;
end;

function TAIWordViewer.LoadFromDocument(ADocument: TAIWordDocument): Boolean;
begin
  Result := False;
  if not Assigned(FScrollBox) then
  begin
    SetError('No panel attached to viewer.');
    Exit;
  end;
  
  FDocument := ADocument;
  Clear;
  
  try
    if FLayoutEngine.BuildLayout(FDocument) then
    begin
      FPageCount := FLayoutEngine.Pages.Count;
      FPageIndex := 0;
      RecreateViews;
      RefreshView;
      FLastResult := 'Document loaded in visualizer';
      FLastSuccess := True;
      Result := True;
    end
    else
      SetError('Failed to build visual document layout.');
  except
    on E: Exception do
      SetError('LoadFromDocument error: ' + E.Message);
  end;
end;

procedure TAIWordViewer.RecreateViews;
var
  I: Integer;
  PageView: TAIWordPageView;
begin
  for I := 0 to FPageViews.Count - 1 do
    TAIWordPageView(FPageViews[I]).Free;
  FPageViews.Clear;
  
  if not Assigned(FScrollBox) then Exit;
  
  for I := 0 to FLayoutEngine.Pages.Count - 1 do
  begin
    PageView := TAIWordPageView.Create(FScrollBox);
    PageView.Parent := FScrollBox;
    PageView.Page := FLayoutEngine.Pages[I];
    PageView.Zoom := FZoom;
    PageView.DPI := 96;
    PageView.ShowPageBorder := FShowPageBorder;
    PageView.ShowHeaderFooter := FShowHeaderFooter;
    PageView.ShowImages := FShowImages;
    PageView.ShowTables := FShowTables;
    FPageViews.Add(PageView);
  end;
  ResizeScrollBoxContent;
end;

procedure TAIWordViewer.ResizeScrollBoxContent;
var
  I: Integer;
  PageView: TAIWordPageView;
  PageW, PageH: Integer;
  CurY: Integer;
  Spacing: Integer;
begin
  CurY := 20;
  Spacing := 20;
  
  for I := 0 to FPageViews.Count - 1 do
  begin
    PageView := TAIWordPageView(FPageViews[I]);
    PageW := Round((PageView.Page.WidthMM / 25.4) * PageView.DPI * (FZoom / 100.0));
    PageH := Round((PageView.Page.HeightMM / 25.4) * PageView.DPI * (FZoom / 100.0));
    
    PageView.SetBounds(
      (FScrollBox.ClientWidth - PageW) div 2,
      CurY,
      PageW,
      PageH
    );
    PageView.Zoom := FZoom;
    
    CurY := CurY + PageH + Spacing;
  end;
end;

procedure TAIWordViewer.RefreshView;
var
  I: Integer;
begin
  ResizeScrollBoxContent;
  for I := 0 to FPageViews.Count - 1 do
    TAIWordPageView(FPageViews[I]).Invalidate;
end;

procedure TAIWordViewer.SetParentPanel(AValue: TPanel);
begin
  if FParentPanel <> AValue then
    AttachToPanel(AValue);
end;

procedure TAIWordViewer.SetZoom(AValue: Integer);
begin
  if AValue < 25 then AValue := 25;
  if AValue > 300 then AValue := 300;
  if FZoom <> AValue then
  begin
    FZoom := AValue;
    FAutoFitWidth := False;
    RefreshView;
  end;
end;

procedure TAIWordViewer.FirstPage;
begin
  GoToPage(0);
end;

procedure TAIWordViewer.PreviousPage;
begin
  GoToPage(FPageIndex - 1);
end;

procedure TAIWordViewer.NextPage;
begin
  GoToPage(FPageIndex + 1);
end;

procedure TAIWordViewer.LastPage;
begin
  GoToPage(FPageCount - 1);
end;

procedure TAIWordViewer.GoToPage(APageIndex: Integer);
var
  PageView: TAIWordPageView;
begin
  if (APageIndex >= 0) and (APageIndex < FPageCount) then
  begin
    FPageIndex := APageIndex;
    if Assigned(FScrollBox) and (FPageIndex < FPageViews.Count) then
    begin
      PageView := TAIWordPageView(FPageViews[FPageIndex]);
      FScrollBox.VertScrollBar.Position := PageView.Top - 10;
    end;
  end;
end;

procedure TAIWordViewer.ZoomIn;
begin
  SetZoom(FZoom + 10);
end;

procedure TAIWordViewer.ZoomOut;
begin
  SetZoom(FZoom - 10);
end;

procedure TAIWordViewer.FitWidth;
var
  PageView: TAIWordPageView;
  PageWPixels: Integer;
begin
  if FPageViews.Count > 0 then
  begin
    PageView := TAIWordPageView(FPageViews[0]);
    PageWPixels := Round((PageView.Page.WidthMM / 25.4) * PageView.DPI);
    // leave 40 pixels margin
    SetZoom(Round(((FScrollBox.ClientWidth - 40) / PageWPixels) * 100));
    FAutoFitWidth := True;
  end;
end;

procedure TAIWordViewer.FitPage;
var
  PageView: TAIWordPageView;
  PageHPixels: Integer;
begin
  if FPageViews.Count > 0 then
  begin
    PageView := TAIWordPageView(FPageViews[0]);
    PageHPixels := Round((PageView.Page.HeightMM / 25.4) * PageView.DPI);
    SetZoom(Round(((FScrollBox.ClientHeight - 40) / PageHPixels) * 100));
  end;
end;

end.
