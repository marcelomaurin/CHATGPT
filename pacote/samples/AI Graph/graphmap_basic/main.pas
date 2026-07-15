unit main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Math, Types, Forms, Controls, Graphics, Dialogs, ExtCtrls,
  StdCtrls, ComCtrls, aidependencygraph;

type
  TNodeLayout = record
    Node: TAIDependencyNode;
    Bounds: TRect;
    Center: TPoint;
  end;
  PNodeLayout = ^TNodeLayout;

  { TfrmGraphMapBasic }

  TfrmGraphMapBasic = class(TForm)
    AIDependencyGraph1: TAIDependencyGraph;
    btnAddNode: TButton;
    btnAddRelation: TButton;
    btnClear: TButton;
    btnLoadSample: TButton;
    btnSaveMermaid: TButton;
    cbFromNode: TComboBox;
    cbToNode: TComboBox;
    edNodeDescription: TEdit;
    lblFromNode: TLabel;
    lblGraph: TLabel;
    lblMessage: TLabel;
    lblNodeAutoId: TLabel;
    lblNodeDescription: TLabel;
    lblStatus: TLabel;
    lblToNode: TLabel;
    pbGraph: TPaintBox;
    pcMain: TPageControl;
    pnlGraph: TPanel;
    pnlNode: TPanel;
    pnlRelation: TPanel;
    pnlTop: TPanel;
    sdGraph: TSaveDialog;
    tsNodes: TTabSheet;
    tsRelations: TTabSheet;
    procedure btnAddNodeClick(Sender: TObject);
    procedure btnAddRelationClick(Sender: TObject);
    procedure btnClearClick(Sender: TObject);
    procedure btnLoadSampleClick(Sender: TObject);
    procedure btnSaveMermaidClick(Sender: TObject);
    procedure edNodeDescriptionChange(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure pbGraphPaint(Sender: TObject);
  private
    procedure AddSampleGraph;
    function DefaultEvidence: TAIDependencyEvidence;
    function EdgeColor(const AEdge: TAIDependencyEdge): TColor;
    procedure DrawArrow(ACanvas: TCanvas; const X1, Y1, X2, Y2: Integer;
      AColor: TColor; AWidth: Integer; ADashed: Boolean);
    function MakeNodeId(const ADescription: string): string;
    function MakeUniqueNodeId(const ADescription: string): string;
    function NodeColor(AIndex: Integer): TColor;
    function NodeDisplayText(ANode: TAIDependencyNode): string;
    function SelectedNodeId(ACombo: TComboBox): string;
    procedure RefreshGraph;
    procedure RefreshNodeCombos(const ASelectFromId, ASelectToId: string);
    procedure RenderGraph(ACanvas: TCanvas);
    procedure SetMessage(const AMsg: string);
    procedure UpdateStatus;
    procedure UpdateNodeIdPreview;
  public

  end;

var
  frmGraphMapBasic: TfrmGraphMapBasic;

implementation

{$R *.lfm}

const
  DEFAULT_SOURCE = 'graphmap_basic/main.pas';
  EDGE_KIND = 'related_to';

{ TfrmGraphMapBasic }

procedure TfrmGraphMapBasic.FormCreate(Sender: TObject);
begin
  DoubleBuffered := True;
  pcMain.ActivePage := tsNodes;

  edNodeDescription.Text := 'Customer';

  AIDependencyGraph1.Clear;
  AddSampleGraph;
  UpdateNodeIdPreview;
  UpdateStatus;
  SetMessage('Create a node in the Nodes tab, then connect two nodes in the Relationships tab.');
end;

procedure TfrmGraphMapBasic.edNodeDescriptionChange(Sender: TObject);
begin
  UpdateNodeIdPreview;
end;

procedure TfrmGraphMapBasic.btnAddNodeClick(Sender: TObject);
var
  NodeDesc, NodeId, OldFromId: string;
begin
  NodeDesc := Trim(edNodeDescription.Text);
  if NodeDesc = '' then
  begin
    SetMessage('Enter a description for the node.');
    Exit;
  end;

  NodeId := MakeUniqueNodeId(NodeDesc);
  if NodeId = '' then
  begin
    SetMessage('Could not generate the node id.');
    Exit;
  end;

  OldFromId := SelectedNodeId(cbFromNode);

  AIDependencyGraph1.AddNode(NodeId, AIDG_NODE_SAMPLE, NodeDesc, '', DefaultEvidence);
  RefreshNodeCombos(OldFromId, NodeId);
  UpdateNodeIdPreview;
  RefreshGraph;
  UpdateStatus;
  SetMessage('Node added: ' + NodeDesc);
end;

procedure TfrmGraphMapBasic.btnAddRelationClick(Sender: TObject);
var
  FromId, ToId: string;
begin
  FromId := SelectedNodeId(cbFromNode);
  ToId := SelectedNodeId(cbToNode);

  if (FromId = '') or (ToId = '') then
  begin
    SetMessage('Select both nodes to create the relation.');
    Exit;
  end;

  if SameText(FromId, ToId) then
  begin
    SetMessage('Choose two different nodes.');
    Exit;
  end;

  AIDependencyGraph1.AddEdge(FromId, ToId, EDGE_KIND, DefaultEvidence);
  RefreshGraph;
  UpdateStatus;
  SetMessage('Relation created between the two nodes.');
end;

procedure TfrmGraphMapBasic.btnLoadSampleClick(Sender: TObject);
begin
  AddSampleGraph;
  UpdateNodeIdPreview;
  RefreshGraph;
  UpdateStatus;
  SetMessage('Sample loaded.');
end;

procedure TfrmGraphMapBasic.btnSaveMermaidClick(Sender: TObject);
begin
  sdGraph.FileName := 'graphmap_basic.mmd';
  if not sdGraph.Execute then
    Exit;

  if AIDependencyGraph1.SaveToMermaid(sdGraph.FileName) then
    SetMessage('Mermaid saved to ' + sdGraph.FileName)
  else
    SetMessage('Could not save Mermaid.');
end;

procedure TfrmGraphMapBasic.btnClearClick(Sender: TObject);
begin
  AIDependencyGraph1.Clear;
  RefreshNodeCombos('', '');
  RefreshGraph;
  UpdateStatus;
  UpdateNodeIdPreview;
  SetMessage('Graph cleared.');
end;

procedure TfrmGraphMapBasic.pbGraphPaint(Sender: TObject);
begin
  RenderGraph(pbGraph.Canvas);
end;

procedure TfrmGraphMapBasic.AddSampleGraph;
begin
  AIDependencyGraph1.Clear;

  AIDependencyGraph1.AddNode('sample:customer', AIDG_NODE_SAMPLE, 'Customer', '', DefaultEvidence);
  AIDependencyGraph1.AddNode('sample:order', AIDG_NODE_SAMPLE, 'Order', '', DefaultEvidence);
  AIDependencyGraph1.AddNode('sample:payment', AIDG_NODE_SAMPLE, 'Payment', '', DefaultEvidence);
  AIDependencyGraph1.AddNode('sample:delivery', AIDG_NODE_SAMPLE, 'Delivery', '', DefaultEvidence);

  AIDependencyGraph1.AddEdge('sample:customer', 'sample:order', EDGE_KIND, DefaultEvidence);
  AIDependencyGraph1.AddEdge('sample:order', 'sample:payment', EDGE_KIND, DefaultEvidence);
  AIDependencyGraph1.AddEdge('sample:order', 'sample:delivery', EDGE_KIND, DefaultEvidence);

  RefreshNodeCombos('sample:customer', 'sample:order');
end;

function TfrmGraphMapBasic.DefaultEvidence: TAIDependencyEvidence;
begin
  Result := MakeAIDependencyEvidence(DEFAULT_SOURCE, 1, 'graphmap_basic');
end;

function TfrmGraphMapBasic.EdgeColor(const AEdge: TAIDependencyEdge): TColor;
begin
  if SameText(AEdge.Kind, AIDG_KIND_INFERRED) then
    Exit(RGBToColor(126, 87, 194));
  Result := RGBToColor(75, 85, 99);
end;

procedure TfrmGraphMapBasic.DrawArrow(ACanvas: TCanvas; const X1, Y1, X2, Y2: Integer;
  AColor: TColor; AWidth: Integer; ADashed: Boolean);
var
  Angle: Double;
  HeadSize: Double;
  P1, P2, P3: TPoint;
begin
  ACanvas.Pen.Color := AColor;
  ACanvas.Pen.Width := AWidth;
  if ADashed then
    ACanvas.Pen.Style := psDash
  else
    ACanvas.Pen.Style := psSolid;
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
  ACanvas.Pen.Style := psSolid;
end;

function TfrmGraphMapBasic.MakeNodeId(const ADescription: string): string;
begin
  if Trim(ADescription) = '' then
    Exit('');
  Result := MakeAIDependencyNodeId(AIDG_NODE_SAMPLE, Trim(ADescription));
end;

function TfrmGraphMapBasic.MakeUniqueNodeId(const ADescription: string): string;
var
  BaseId, Candidate: string;
  Counter: Integer;
begin
  BaseId := MakeNodeId(ADescription);
  if BaseId = '' then
    Exit('');

  Candidate := BaseId;
  Counter := 2;
  while Assigned(AIDependencyGraph1.FindNode(Candidate)) do
  begin
    Candidate := BaseId + '-' + IntToStr(Counter);
    Inc(Counter);
  end;
  Result := Candidate;
end;

function TfrmGraphMapBasic.NodeColor(AIndex: Integer): TColor;
begin
  case AIndex mod 6 of
    0: Result := RGBToColor(198, 228, 255);
    1: Result := RGBToColor(208, 245, 226);
    2: Result := RGBToColor(255, 232, 194);
    3: Result := RGBToColor(240, 219, 255);
    4: Result := RGBToColor(255, 221, 214);
  else
    Result := RGBToColor(233, 236, 239);
  end;
end;

function TfrmGraphMapBasic.NodeDisplayText(ANode: TAIDependencyNode): string;
begin
  Result := ANode.Name + '  [' + ANode.Id + ']';
end;

function TfrmGraphMapBasic.SelectedNodeId(ACombo: TComboBox): string;
begin
  Result := '';
  if (ACombo.ItemIndex < 0) or (ACombo.ItemIndex >= ACombo.Items.Count) then
    Exit;
  if Assigned(ACombo.Items.Objects[ACombo.ItemIndex]) then
    Result := TAIDependencyNode(ACombo.Items.Objects[ACombo.ItemIndex]).Id;
end;

procedure TfrmGraphMapBasic.RefreshGraph;
begin
  pbGraph.Invalidate;
end;

procedure TfrmGraphMapBasic.RefreshNodeCombos(const ASelectFromId, ASelectToId: string);

  procedure FillCombo(ACombo: TComboBox; const ASelectedId: string);
  var
    I, SelectedIndex: Integer;
    Node: TAIDependencyNode;
  begin
    SelectedIndex := -1;
    ACombo.Items.BeginUpdate;
    try
      ACombo.Clear;
      for I := 0 to AIDependencyGraph1.Nodes.Count - 1 do
      begin
        Node := AIDependencyGraph1.Nodes[I];
        ACombo.Items.AddObject(NodeDisplayText(Node), Node);
        if SameText(Node.Id, ASelectedId) then
          SelectedIndex := I;
      end;
      if SelectedIndex >= 0 then
        ACombo.ItemIndex := SelectedIndex
      else if ACombo.Items.Count > 0 then
        ACombo.ItemIndex := 0
      else
        ACombo.ItemIndex := -1;
    finally
      ACombo.Items.EndUpdate;
    end;
  end;

begin
  FillCombo(cbFromNode, ASelectFromId);
  FillCombo(cbToNode, ASelectToId);
end;

procedure TfrmGraphMapBasic.RenderGraph(ACanvas: TCanvas);
var
  W, H: Integer;
  AllEdges: TList;
  Layouts: array of TNodeLayout;
  I, Count, RadiusX, RadiusY: Integer;
  Node: TAIDependencyNode;
  Edge: TAIDependencyEdge;
  SrcLayout, DstLayout: PNodeLayout;
  SrcPoint, DstPoint: TPoint;
  NodeWidth, NodeHeight: Integer;
  CenterX, CenterY, AngleDeg: Double;
  BoxText: string;

  function LayoutById(const AId: string): PNodeLayout;
  var
    L: Integer;
  begin
    Result := nil;
    for L := Low(Layouts) to High(Layouts) do
      if Assigned(Layouts[L].Node) and SameText(Layouts[L].Node.Id, AId) then
        Exit(@Layouts[L]);
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

  procedure DrawNode(const L: TNodeLayout; const AIndex: Integer);
  var
    R, TextRect: TRect;
  begin
    R := L.Bounds;
    ACanvas.Brush.Color := NodeColor(AIndex);
    ACanvas.Pen.Color := RGBToColor(107, 114, 128);
    ACanvas.Pen.Width := 1;
    ACanvas.RoundRect(R.Left, R.Top, R.Right, R.Bottom, 14, 14);

    ACanvas.Font.Name := 'Segoe UI';
    ACanvas.Font.Color := clBlack;
    ACanvas.Font.Size := 10;
    ACanvas.Font.Style := [fsBold];
    TextRect := R;
    InflateRect(TextRect, -10, -8);
    BoxText := L.Node.Name;
    ACanvas.TextRect(TextRect, TextRect.Left, TextRect.Top + 4, BoxText);

    ACanvas.Font.Size := 8;
    ACanvas.Font.Style := [];
    ACanvas.Font.Color := clGrayText;
    ACanvas.TextRect(TextRect, TextRect.Left, TextRect.Top + 22, L.Node.Id);
  end;

begin
  W := pbGraph.ClientWidth;
  H := pbGraph.ClientHeight;

  ACanvas.Brush.Color := RGBToColor(250, 250, 247);
  ACanvas.FillRect(Rect(0, 0, W, H));

  if AIDependencyGraph1.NodeCount = 0 then
  begin
    ACanvas.Font.Color := clGrayText;
    ACanvas.Font.Size := 11;
    ACanvas.TextOut(24, 24, 'Add nodes and relationships to see the graph here.');
    Exit;
  end;

  Count := AIDependencyGraph1.Nodes.Count;
  Layouts := nil;
  SetLength(Layouts, Count);

  NodeWidth := 150;
  NodeHeight := 54;
  CenterX := W / 2;
  CenterY := H / 2;
  RadiusX := Max(90, (W div 2) - 110);
  RadiusY := Max(70, (H div 2) - 80);

  for I := 0 to Count - 1 do
  begin
    Node := AIDependencyGraph1.Nodes[I];
    if Count = 1 then
    begin
      Layouts[I].Center := Point(Round(CenterX), Round(CenterY));
    end
    else
    begin
      AngleDeg := (2 * Pi * I / Count) - (Pi / 2);
      Layouts[I].Center := Point(
        Round(CenterX + Cos(AngleDeg) * RadiusX),
        Round(CenterY + Sin(AngleDeg) * RadiusY)
      );
    end;

    Layouts[I].Node := Node;
    Layouts[I].Bounds := Rect(
      Layouts[I].Center.X - (NodeWidth div 2),
      Layouts[I].Center.Y - (NodeHeight div 2),
      Layouts[I].Center.X + (NodeWidth div 2),
      Layouts[I].Center.Y + (NodeHeight div 2)
    );
  end;

  AllEdges := TList.Create;
  try
    for I := 0 to AIDependencyGraph1.Edges.Count - 1 do
      AllEdges.Add(AIDependencyGraph1.Edges[I]);
    for I := 0 to AIDependencyGraph1.InferredEdges.Count - 1 do
      AllEdges.Add(AIDependencyGraph1.InferredEdges[I]);

    ACanvas.Font.Name := 'Segoe UI';
    ACanvas.Brush.Style := bsClear;

    for I := 0 to AllEdges.Count - 1 do
    begin
      Edge := TAIDependencyEdge(AllEdges[I]);
      SrcLayout := LayoutById(Edge.FromId);
      DstLayout := LayoutById(Edge.ToId);
      if (SrcLayout = nil) or (DstLayout = nil) then
        Continue;

      SrcPoint := BorderPoint(SrcLayout^.Center, DstLayout^.Center, SrcLayout^.Bounds);
      DstPoint := BorderPoint(DstLayout^.Center, SrcLayout^.Center, DstLayout^.Bounds);
      DrawArrow(ACanvas, SrcPoint.X, SrcPoint.Y, DstPoint.X, DstPoint.Y,
        EdgeColor(Edge), 2, SameText(Edge.Kind, AIDG_KIND_INFERRED));
    end;

    for I := 0 to High(Layouts) do
      DrawNode(Layouts[I], I);

    ACanvas.Font.Color := clGrayText;
    ACanvas.Font.Size := 10;
  ACanvas.TextOut(20, 16, Format('Nodes: %d  |  Links: %d',
      [AIDependencyGraph1.NodeCount, AIDependencyGraph1.EdgeCount + AIDependencyGraph1.InferredEdges.Count]));
  finally
    AllEdges.Free;
  end;
end;

procedure TfrmGraphMapBasic.SetMessage(const AMsg: string);
begin
  lblMessage.Caption := AMsg;
end;

procedure TfrmGraphMapBasic.UpdateStatus;
begin
  lblStatus.Caption := Format('Nodes: %d  |  Relations: %d',
    [AIDependencyGraph1.NodeCount, AIDependencyGraph1.EdgeCount + AIDependencyGraph1.InferredEdges.Count]);
end;

procedure TfrmGraphMapBasic.UpdateNodeIdPreview;
var
  NodeId: string;
begin
  NodeId := MakeNodeId(edNodeDescription.Text);
  if NodeId = '' then
    lblNodeAutoId.Caption := 'Generated ID: -'
  else
    lblNodeAutoId.Caption := 'Generated ID: ' + NodeId;
end;

end.
