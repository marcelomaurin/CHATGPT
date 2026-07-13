unit aigraphstructuraladapter;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, aibase, aigraphmap, aigraphvisualizer, aidependencygraph;

type
  { TAIGraphStructuralAdapter }

  TAIGraphStructuralAdapter = class(TAIBaseComponent)
  private
    FDependencyGraph: TAIDependencyGraph;
    FGraphMap: TAIGraphMap;
    procedure SetDependencyGraph(AValue: TAIDependencyGraph);
    procedure ConfigureGraphMap;
    function NodeLabel(const ANode: TAIDependencyNode): string;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    procedure Refresh;
    procedure AttachToVisualizer(AViz: TAIGraphVisualizer);

    property GraphMap: TAIGraphMap read FGraphMap;
  published
    property DependencyGraph: TAIDependencyGraph read FDependencyGraph write SetDependencyGraph;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('AI Graph', [TAIGraphStructuralAdapter]);
end;

constructor TAIGraphStructuralAdapter.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FDependencyGraph := nil;
  FGraphMap := TAIGraphMap.Create(Self);
  ConfigureGraphMap;
  FPrompt := 'Component TAIGraphStructuralAdapter projects TAIDependencyGraph into a TAIGraphMap so the existing TAIGraphVisualizer can export DOT and Mermaid without being modified.';
  ClearError;
end;

destructor TAIGraphStructuralAdapter.Destroy;
begin
  FGraphMap.Free;
  inherited Destroy;
end;

procedure TAIGraphStructuralAdapter.ConfigureGraphMap;
begin
  if not Assigned(FGraphMap) then
    Exit;

  FGraphMap.LowerCaseTokens := False;
  FGraphMap.RemoveAccents := False;
  FGraphMap.RemoveStopWords := False;
  FGraphMap.MinTokenLength := 1;
  FGraphMap.TokenDelimiterChars := ' ';
  FGraphMap.UniqueTokensPerText := True;
  FGraphMap.UseTokenSequenceEdges := False;
  FGraphMap.UseTokenCategoryEdges := True;
  FGraphMap.AutoClearBeforeTrain := False;
  FGraphMap.UseGraphDepthSearch := False;
end;

function TAIGraphStructuralAdapter.NodeLabel(const ANode: TAIDependencyNode): string;
begin
  Result := ANode.Id;
end;

procedure TAIGraphStructuralAdapter.SetDependencyGraph(AValue: TAIDependencyGraph);
begin
  if FDependencyGraph = AValue then
    Exit;
  FDependencyGraph := AValue;
  Refresh;
end;

procedure TAIGraphStructuralAdapter.Refresh;
var
  I: Integer;
  Edge: TAIDependencyEdge;
  SrcNode, DstNode: TAIDependencyNode;
  Item: TAITrainingItem;
begin
  ClearError;
  if not Assigned(FGraphMap) then
    Exit;

  FGraphMap.ClearGraph;
  FGraphMap.Training.Clear;

  if not Assigned(FDependencyGraph) then
  begin
    SetError('DependencyGraph is not assigned.');
    Exit;
  end;

  if FDependencyGraph.NodeCount = 0 then
  begin
    SetError('DependencyGraph is empty.');
    Exit;
  end;

  ConfigureGraphMap;

  for I := 0 to FDependencyGraph.Edges.Count - 1 do
  begin
    Edge := FDependencyGraph.Edges[I];
    SrcNode := FDependencyGraph.FindNode(Edge.FromId);
    DstNode := FDependencyGraph.FindNode(Edge.ToId);
    if (not Assigned(SrcNode)) or (not Assigned(DstNode)) then
      Continue;

    Item := FGraphMap.Training.Add;
    Item.InputText := NodeLabel(SrcNode);
    Item.OutputCategory := NodeLabel(DstNode);
    Item.Weight := 1.0;
  end;

  FGraphMap.Train;
  FLastResult := Format('Structural projection built. Nodes: %d, Edges: %d', [
    FGraphMap.NodeCount, FGraphMap.EdgeCount
  ]);
  FLastSuccess := True;
end;

procedure TAIGraphStructuralAdapter.AttachToVisualizer(AViz: TAIGraphVisualizer);
begin
  if not Assigned(AViz) then
    Exit;
  if not Assigned(FGraphMap) then
    Exit;
  AViz.GraphMap := FGraphMap;
end;

end.
