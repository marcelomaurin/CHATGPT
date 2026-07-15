unit main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Math, Types, Forms, Controls, Graphics, Dialogs, ExtCtrls, StdCtrls,
  aibase, aigraphvisualizer, aigraphmap;

type
  TNodeLayout = record
    Node: TAIGraphNode;
    Bounds: TRect;
    Center: TPoint;
  end;
  PNodeLayout = ^TNodeLayout;

  { TfrmMain }

  TfrmMain = class(TForm)
    AIGraphMap1: TAIGraphMap;
    AIGraphVisualizer1: TAIGraphVisualizer;
    pnlTop: TPanel;
    pnlGraph: TPanel;
    lblTitle: TLabel;
    lblStatus: TLabel;
    btnRun: TButton;
    btnClearLog: TButton;
    pbGraph: TPaintBox;
    memoLog: TMemo;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btnRunClick(Sender: TObject);
    procedure btnClearLogClick(Sender: TObject);
    procedure pbGraphPaint(Sender: TObject);
  private
    procedure AddLog(const AMsg: string);
    procedure BuildDemoData;
    procedure RefreshGraph;
    procedure RenderGraph(ACanvas: TCanvas);
    procedure SortGraphNodes(AList: TList);
    function NodeFillColor(ANode: TAIGraphNode): TColor;
    procedure DrawArrow(ACanvas: TCanvas; const X1, Y1, X2, Y2: Integer;
      AColor: TColor; AWidth: Integer);
  public

  end;

var
  frmMain: TfrmMain;

implementation

{$R *.lfm}

{ TfrmMain }

procedure TfrmMain.FormCreate(Sender: TObject);
begin
  DoubleBuffered := True;
  AddLog('Graph Visualizer Demo (aigraphvisualizer) initialized.');
  BuildDemoData;
  RefreshGraph;
end;

procedure TfrmMain.FormDestroy(Sender: TObject);
begin
  // Handled by LCL Owner auto-free.
end;

procedure TfrmMain.btnRunClick(Sender: TObject);
begin
  lblStatus.Caption := 'Status: Processing...';
  AddLog('--- Starting Execution ---');
  try
    AIGraphVisualizer1.GraphMap := AIGraphMap1;
    AIGraphVisualizer1.MinWeight := 0.1;
    AIGraphVisualizer1.TopN := 50;
    AddLog('Graph Visualizer Properties:');
    AddLog('  MinWeight: 0.1');
    AddLog('  TopN: 50');
    AddLog('Building demo graph data...');
    BuildDemoData;
    RefreshGraph;
    lblStatus.Caption := 'Status: Completed Successfully';
  except
    on E: Exception do
    begin
      AddLog('Critical Error: ' + E.Message);
      lblStatus.Caption := 'Status: Execution Error';
    end;
  end;
  AddLog('--- Execution Finished ---');
end;

procedure TfrmMain.btnClearLogClick(Sender: TObject);
begin
  memoLog.Clear;
end;

procedure TfrmMain.pbGraphPaint(Sender: TObject);
begin
  RenderGraph(pbGraph.Canvas);
end;

procedure TfrmMain.AddLog(const AMsg: string);
begin
  memoLog.Lines.Add(AMsg);
end;

procedure TfrmMain.BuildDemoData;
var
  Item: TAITrainingItem;
begin
  AIGraphMap1.Training.Clear;

  Item := AIGraphMap1.Training.Add;
  Item.InputText := 'login senha acesso bloqueado';
  Item.OutputCategory := 'Suporte';
  Item.Weight := 1.0;

  Item := AIGraphMap1.Training.Add;
  Item.InputText := 'senha expirada usuario nao consegue entrar';
  Item.OutputCategory := 'Suporte';
  Item.Weight := 1.1;

  Item := AIGraphMap1.Training.Add;
  Item.InputText := 'boleto pago nota fiscal faturamento';
  Item.OutputCategory := 'Financeiro';
  Item.Weight := 1.0;

  Item := AIGraphMap1.Training.Add;
  Item.InputText := 'fatura vencida pagamento pendente';
  Item.OutputCategory := 'Financeiro';
  Item.Weight := 1.2;

  Item := AIGraphMap1.Training.Add;
  Item.InputText := 'pedido atrasado entrega rastreio';
  Item.OutputCategory := 'Logistica';
  Item.Weight := 1.0;

  Item := AIGraphMap1.Training.Add;
  Item.InputText := 'estoque baixo reposicao urgente';
  Item.OutputCategory := 'Logistica';
  Item.Weight := 1.2;

  AIGraphVisualizer1.GraphMap := AIGraphMap1;
  AIGraphVisualizer1.MinWeight := 0.1;
  AIGraphVisualizer1.TopN := 50;

  AIGraphMap1.Train;

  AddLog(AIGraphMap1.LastResult);

  try
    AIGraphVisualizer1.ExportToMermaid('graph_visual.mmd');
    if AIGraphVisualizer1.LastSuccess then
      AddLog('Graph Layout written to graph_visual.mmd')
    else
      AddLog('Visual Generation failed: ' + AIGraphVisualizer1.LastError);
  except
    on E: Exception do AddLog('Exception: ' + E.Message);
  end;
end;

procedure TfrmMain.RefreshGraph;
begin
  if Assigned(pbGraph) then
    pbGraph.Invalidate;
end;

procedure TfrmMain.SortGraphNodes(AList: TList);
var
  I, J: Integer;
  A, B: TAIGraphNode;
begin
  for I := 0 to AList.Count - 2 do
    for J := I + 1 to AList.Count - 1 do
    begin
      A := TAIGraphNode(AList[I]);
      B := TAIGraphNode(AList[J]);
      if (B.Weight > A.Weight) or ((B.Weight = A.Weight) and (B.Text < A.Text)) then
      begin
        AList[I] := B;
        AList[J] := A;
      end;
    end;
end;

function TfrmMain.NodeFillColor(ANode: TAIGraphNode): TColor;
begin
  if ANode.NodeType = ntCategory then
    Result := $00C7D9FF
  else
    Result := $00FFF1D6;
end;

procedure TfrmMain.DrawArrow(ACanvas: TCanvas; const X1, Y1, X2, Y2: Integer;
  AColor: TColor; AWidth: Integer);
var
  Angle: Double;
  HeadSize: Double;
  P1, P2, P3: TPoint;
begin
  ACanvas.Pen.Color := AColor;
  ACanvas.Pen.Width := AWidth;
  ACanvas.Line(X1, Y1, X2, Y2);

  Angle := ArcTan2(Y2 - Y1, X2 - X1);
  HeadSize := 8 + AWidth;

  P1 := Point(X2, Y2);
  P2 := Point(
    Round(X2 - Cos(Angle - Pi / 6) * HeadSize),
    Round(Y2 - Sin(Angle - Pi / 6) * HeadSize)
  );
  P3 := Point(
    Round(X2 - Cos(Angle + Pi / 6) * HeadSize),
    Round(Y2 - Sin(Angle + Pi / 6) * HeadSize)
  );

  ACanvas.Brush.Style := bsSolid;
  ACanvas.Brush.Color := AColor;
  ACanvas.Polygon([P1, P2, P3]);
end;

procedure TfrmMain.RenderGraph(ACanvas: TCanvas);
var
  W, H: Integer;
  TokenNodes, CategoryNodes: TList;
  Layouts: array of TNodeLayout;
  I, MaxId: Integer;
  Node: TAIGraphNode;
  Edge: TAIGraphEdge;
  NodeWidth, NodeHeight: Integer;
  LeftX, RightX, TopY, BottomY, YPos: Integer;
  TokenCount, CategoryCount: Integer;
  EdgeWeight, MaxWeight: Double;
  SrcLayout, DstLayout: PNodeLayout;
  SrcPoint, DstPoint: TPoint;
  BoxText: string;
  LabelRect: TRect;
  NodeRect: TRect;
  MidX, MidY: Integer;

  function FindLayout(AId: Integer): PNodeLayout;
  var
    K: Integer;
  begin
    Result := nil;
    for K := Low(Layouts) to High(Layouts) do
      if Assigned(Layouts[K].Node) and (Layouts[K].Node.Id = AId) then
        Exit(@Layouts[K]);
  end;

  function BorderPoint(const Center, Target: TPoint; const ARect: TRect): TPoint;
  var
    Dx, Dy, ScaleX, ScaleY, Scale: Double;
  begin
    Dx := Target.X - Center.X;
    Dy := Target.Y - Center.Y;
    if (Abs(Dx) < 0.01) and (Abs(Dy) < 0.01) then
      Exit(Center);

    ScaleX := (ARect.Right - ARect.Left) / 2 / Max(Abs(Dx), 0.01);
    ScaleY := (ARect.Bottom - ARect.Top) / 2 / Max(Abs(Dy), 0.01);
    if ScaleX < ScaleY then
      Scale := ScaleX
    else
      Scale := ScaleY;

    Result.X := Round(Center.X + Dx * Scale);
    Result.Y := Round(Center.Y + Dy * Scale);
  end;

  procedure DrawNode(const L: TNodeLayout);
  var
    R: TRect;
    WeightText: string;
    C: TColor;
  begin
    R := L.Bounds;
    C := NodeFillColor(L.Node);
    ACanvas.Brush.Color := C;
    ACanvas.Pen.Color := clGray;
    ACanvas.Pen.Width := 1;
    ACanvas.RoundRect(R.Left, R.Top, R.Right, R.Bottom, 16, 16);

    ACanvas.Font.Style := [fsBold];
    ACanvas.Font.Color := clBlack;
    BoxText := L.Node.Text;
    WeightText := Format('w=%.2f', [L.Node.Weight]);
    LabelRect := R;
    InflateRect(LabelRect, -10, -8);
    ACanvas.TextRect(LabelRect, LabelRect.Left, LabelRect.Top + 4, BoxText);
    ACanvas.Font.Style := [];
    ACanvas.Font.Color := clGrayText;
    ACanvas.TextRect(LabelRect, LabelRect.Left, LabelRect.Top + 22, WeightText);
  end;

begin
  W := pbGraph.ClientWidth;
  H := pbGraph.ClientHeight;

  ACanvas.Brush.Color := $00FAFAF8;
  ACanvas.FillRect(Rect(0, 0, W, H));

  if (AIGraphMap1 = nil) or (AIGraphMap1.NodeCount = 0) then
  begin
    ACanvas.Font.Color := clGrayText;
    ACanvas.TextOut(24, 24, 'Build a demo graph to see the links here.');
    Exit;
  end;

  TokenNodes := TList.Create;
  CategoryNodes := TList.Create;
  try
    for I := 0 to AIGraphMap1.Nodes.Count - 1 do
    begin
      Node := TAIGraphNode(AIGraphMap1.Nodes[I]);
      if Node.NodeType = ntCategory then
        CategoryNodes.Add(Node)
      else
        TokenNodes.Add(Node);
    end;

    SortGraphNodes(TokenNodes);
    SortGraphNodes(CategoryNodes);

    TokenCount := TokenNodes.Count;
    CategoryCount := CategoryNodes.Count;

    MaxId := 0;
    Layouts := nil;
    for I := 0 to AIGraphMap1.Nodes.Count - 1 do
      if TAIGraphNode(AIGraphMap1.Nodes[I]).Id > MaxId then
        MaxId := TAIGraphNode(AIGraphMap1.Nodes[I]).Id;
    SetLength(Layouts, MaxId + 1);

    ACanvas.Font.Name := 'Segoe UI';
    ACanvas.Font.Size := 10;

    NodeHeight := 52;
    NodeWidth := 180;
    LeftX := 110;
    RightX := W - 110;
    TopY := 70;
    BottomY := H - 60;

    if TokenCount = 1 then
      YPos := (TopY + BottomY) div 2
    else
      YPos := TopY;

    for I := 0 to TokenCount - 1 do
    begin
      Node := TAIGraphNode(TokenNodes[I]);
      if TokenCount = 1 then
        YPos := (TopY + BottomY) div 2
      else
        YPos := TopY + Round((BottomY - TopY) * (I / (TokenCount - 1)));

      NodeRect := Rect(
        LeftX - (NodeWidth div 2),
        YPos - (NodeHeight div 2),
        LeftX + (NodeWidth div 2),
        YPos + (NodeHeight div 2)
      );

      Layouts[Node.Id].Node := Node;
      Layouts[Node.Id].Bounds := NodeRect;
      Layouts[Node.Id].Center := Point(LeftX, YPos);
    end;

    if CategoryCount = 1 then
      YPos := (TopY + BottomY) div 2
    else
      YPos := TopY;

    for I := 0 to CategoryCount - 1 do
    begin
      Node := TAIGraphNode(CategoryNodes[I]);
      if CategoryCount = 1 then
        YPos := (TopY + BottomY) div 2
      else
        YPos := TopY + Round((BottomY - TopY) * (I / (CategoryCount - 1)));

      NodeRect := Rect(
        RightX - (NodeWidth div 2),
        YPos - (NodeHeight div 2),
        RightX + (NodeWidth div 2),
        YPos + (NodeHeight div 2)
      );

      Layouts[Node.Id].Node := Node;
      Layouts[Node.Id].Bounds := NodeRect;
      Layouts[Node.Id].Center := Point(RightX, YPos);
    end;

    MaxWeight := 0;
    for I := 0 to AIGraphMap1.Edges.Count - 1 do
    begin
      Edge := TAIGraphEdge(AIGraphMap1.Edges[I]);
      if Edge.Weight > MaxWeight then
        MaxWeight := Edge.Weight;
    end;
    if MaxWeight <= 0 then
      MaxWeight := 1;

    // Draw links first so the nodes stay on top.
    for I := 0 to AIGraphMap1.Edges.Count - 1 do
    begin
      Edge := TAIGraphEdge(AIGraphMap1.Edges[I]);
      SrcLayout := FindLayout(Edge.FromNodeId);
      DstLayout := FindLayout(Edge.ToNodeId);
      if (SrcLayout = nil) or (DstLayout = nil) then
        Continue;

      if SrcLayout^.Node.NodeType = ntCategory then
        EdgeWeight := 0.0
      else
        EdgeWeight := Edge.Weight;

      if EdgeWeight >= MaxWeight * 0.75 then
        ACanvas.Pen.Color := $006B3D1A
      else if SrcLayout^.Node.NodeType = ntCategory then
        ACanvas.Pen.Color := $00994C00
      else
        ACanvas.Pen.Color := $00808080;

      if Edge.Weight > 0 then
        ACanvas.Pen.Width := Max(1, Min(4, Round((Edge.Weight / MaxWeight) * 4)));

      SrcPoint := BorderPoint(SrcLayout^.Center, DstLayout^.Center, SrcLayout^.Bounds);
      DstPoint := BorderPoint(DstLayout^.Center, SrcLayout^.Center, DstLayout^.Bounds);
      DrawArrow(ACanvas, SrcPoint.X, SrcPoint.Y, DstPoint.X, DstPoint.Y, ACanvas.Pen.Color, ACanvas.Pen.Width);

      MidX := (SrcPoint.X + DstPoint.X) div 2;
      MidY := (SrcPoint.Y + DstPoint.Y) div 2;
      ACanvas.Font.Color := clGrayText;
      ACanvas.Font.Size := 8;
      ACanvas.Brush.Style := bsClear;
      ACanvas.TextOut(MidX + 4, MidY + 4, Format('%.2f', [Edge.Weight]));
    end;

    for I := 0 to High(Layouts) do
      if Assigned(Layouts[I].Node) then
        DrawNode(Layouts[I]);

    // Legend
    ACanvas.Brush.Style := bsClear;
    ACanvas.Font.Color := clBlack;
    ACanvas.Font.Style := [fsBold];
    ACanvas.TextOut(24, 18, 'Graph links');
    ACanvas.Font.Style := [];
    ACanvas.Font.Color := clGrayText;
    ACanvas.TextOut(24, 36, Format('Nodes: %d   Edges: %d', [AIGraphMap1.NodeCount, AIGraphMap1.EdgeCount]));
  finally
    CategoryNodes.Free;
    TokenNodes.Free;
  end;
end;

end.
