unit airoutecalculator;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Math, Contnrs, airoutegraph_types, airoutegraph,
  airoutespeedprofile, airoutegraph_utils, aibase;

type
  TAIRouteAlgorithm = (raDijkstra, raAStar);
  TAIRouteCostMode = (rcmFastest, rcmShortest);

  { TAIRouteCalculator }

  TAIRouteCalculator = class(TAIBaseComponent)
  private
    FRouteGraph: TAIRouteGraph;
    FSpeedProfile: TAIRouteSpeedProfile;
    FAlgorithm: TAIRouteAlgorithm;
    FCostMode: TAIRouteCostMode;
    FLastRoute: TAIRouteResult;
    FCancelled: Boolean;
    function HeuristicCost(const ANodeIndex, ADestinationNodeIndex: Integer): Double;
    function EdgeCost(const AEdge: TAIRouteEdge): Double;
    function MaxSpeedForHeuristic: Double;
    procedure AddGeometrySegment(const AEdge: TAIRouteEdge; APoints: TList);
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    function CalculateRoute(
      const AOriginNodeIndex: Integer;
      const ADestinationNodeIndex: Integer
    ): Boolean;

    function CalculateRouteByCoordinates(
      const AOriginLatitude, AOriginLongitude: Double;
      const ADestinationLatitude, ADestinationLongitude: Double
    ): Boolean;

    procedure Cancel;
    property LastRoute: TAIRouteResult read FLastRoute;
  published
    property RouteGraph: TAIRouteGraph read FRouteGraph write FRouteGraph;
    property SpeedProfile: TAIRouteSpeedProfile read FSpeedProfile write FSpeedProfile;
    property Algorithm: TAIRouteAlgorithm read FAlgorithm write FAlgorithm default raAStar;
    property CostMode: TAIRouteCostMode read FCostMode write FCostMode default rcmFastest;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('AI Graph', [TAIRouteCalculator]);
end;

{ TAIRouteCalculator }

constructor TAIRouteCalculator.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FCategory := ccOther;
  FPrompt := 'Component TAIRouteCalculator computes shortest or fastest route over a directed road graph.';
  FAlgorithm := raAStar;
  FCostMode := rcmFastest;
  FLastRoute := TAIRouteResult.Create;
  FCancelled := False;
end;

destructor TAIRouteCalculator.Destroy;
begin
  FLastRoute.Free;
  inherited Destroy;
end;

procedure TAIRouteCalculator.Cancel;
begin
  FCancelled := True;
end;

function TAIRouteCalculator.MaxSpeedForHeuristic: Double;
begin
  if Assigned(FSpeedProfile) then
    Result := Max(FSpeedProfile.MotorwaySpeed, Max(FSpeedProfile.TrunkSpeed,
      Max(FSpeedProfile.PrimarySpeed, Max(FSpeedProfile.SecondarySpeed,
      Max(FSpeedProfile.TertiarySpeed, Max(FSpeedProfile.UnclassifiedSpeed,
      Max(FSpeedProfile.ResidentialSpeed, Max(FSpeedProfile.ServiceSpeed,
      FSpeedProfile.TrackSpeed))))))))
  else
    Result := 120;
  Result := Max(1, Result);
end;

function TAIRouteCalculator.HeuristicCost(const ANodeIndex, ADestinationNodeIndex: Integer): Double;
var
  Dist: Double;
  Speed: Double;
begin
  if (FAlgorithm <> raAStar) or not Assigned(FRouteGraph) then
    Exit(0);

  Dist := HaversineDistanceMeters(
    FRouteGraph.Nodes[ANodeIndex].Latitude,
    FRouteGraph.Nodes[ANodeIndex].Longitude,
    FRouteGraph.Nodes[ADestinationNodeIndex].Latitude,
    FRouteGraph.Nodes[ADestinationNodeIndex].Longitude
  );

  if FCostMode = rcmFastest then
  begin
    Speed := MaxSpeedForHeuristic;
    Result := Dist / (Speed * 1000 / 3600);
  end
  else
    Result := Dist;
end;

function TAIRouteCalculator.EdgeCost(const AEdge: TAIRouteEdge): Double;
begin
  if FCostMode = rcmShortest then
    Result := AEdge.DistanceMeters
  else
    Result := AEdge.TravelTimeSeconds;
end;

procedure TAIRouteCalculator.AddGeometrySegment(const AEdge: TAIRouteEdge; APoints: TList);
var
  I: Integer;
  Geo: ^TAIGeoPoint;
begin
  if Length(AEdge.Geometry) > 0 then
  begin
    for I := High(AEdge.Geometry) downto 0 do
    begin
      New(Geo);
      Geo^ := AEdge.Geometry[I];
      APoints.Insert(0, Geo);
    end;
    Exit;
  end;

  New(Geo);
  Geo^.Latitude := FRouteGraph.Nodes[AEdge.ToNodeIndex].Latitude;
  Geo^.Longitude := FRouteGraph.Nodes[AEdge.ToNodeIndex].Longitude;
  APoints.Insert(0, Geo);

  New(Geo);
  Geo^.Latitude := FRouteGraph.Nodes[AEdge.FromNodeIndex].Latitude;
  Geo^.Longitude := FRouteGraph.Nodes[AEdge.FromNodeIndex].Longitude;
  APoints.Insert(0, Geo);
end;

function TAIRouteCalculator.CalculateRoute(
  const AOriginNodeIndex, ADestinationNodeIndex: Integer
): Boolean;
var
  NodeCount, I, CurrentNode, BestNode, EdgeIndex, Neighbor: Integer;
  Distances, Scores: array of Double;
  Visited: array of Boolean;
  PrevNode, PrevEdge: array of Integer;
  BestScore, Alt: Double;
  StartTime: QWord;
  RouteEdges: TList;
  GeometryPoints: TList;
  Edge: TAIRouteEdge;
  PointGeo: ^TAIGeoPoint;
  NodeGeo: TAIGeoPoint;
  TotalDistance, TotalTime: Double;
begin
  FCancelled := False;
  FLastRoute.Clear;
  Result := False;

  if not Assigned(FRouteGraph) then
  begin
    FLastRoute.ErrorMessage := 'Route graph is not assigned.';
    Exit;
  end;
  if (AOriginNodeIndex < 0) or (ADestinationNodeIndex < 0) then
  begin
    FLastRoute.ErrorMessage := 'Invalid origin or destination node.';
    Exit;
  end;
  if AOriginNodeIndex = ADestinationNodeIndex then
  begin
    FLastRoute.ErrorMessage := 'Origin and destination are the same.';
    Exit;
  end;

  NodeCount := FRouteGraph.NodeCount;
  if NodeCount = 0 then
  begin
    FLastRoute.ErrorMessage := 'Route graph is empty.';
    Exit;
  end;

  SetLength(Distances, NodeCount);
  SetLength(Scores, NodeCount);
  SetLength(Visited, NodeCount);
  SetLength(PrevNode, NodeCount);
  SetLength(PrevEdge, NodeCount);
  for I := 0 to NodeCount - 1 do
  begin
    Distances[I] := MaxDouble;
    Scores[I] := MaxDouble;
    Visited[I] := False;
    PrevNode[I] := -1;
    PrevEdge[I] := -1;
  end;

  StartTime := GetTickCount64;
  Distances[AOriginNodeIndex] := 0;
  Scores[AOriginNodeIndex] := HeuristicCost(AOriginNodeIndex, ADestinationNodeIndex);

  while True do
  begin
    BestNode := -1;
    BestScore := MaxDouble;
    for I := 0 to NodeCount - 1 do
    begin
      if Visited[I] then
        Continue;
      if Scores[I] < BestScore then
      begin
        BestScore := Scores[I];
        BestNode := I;
      end;
    end;

    if (BestNode < 0) or (BestScore = MaxDouble) then
      Break;
    if FCancelled then
    begin
      FLastRoute.ErrorMessage := 'Route calculation canceled.';
      Exit;
    end;

    CurrentNode := BestNode;
    Visited[CurrentNode] := True;
    if CurrentNode = ADestinationNodeIndex then
      Break;

    if FRouteGraph.Nodes[CurrentNode].FirstOutgoingEdge < 0 then
      Continue;

    for EdgeIndex := FRouteGraph.Nodes[CurrentNode].FirstOutgoingEdge to
      FRouteGraph.Nodes[CurrentNode].FirstOutgoingEdge + FRouteGraph.Nodes[CurrentNode].OutgoingEdgeCount - 1 do
    begin
      Edge := FRouteGraph.Edges[EdgeIndex];
      Neighbor := Edge.ToNodeIndex;
      if (Neighbor < 0) or (Neighbor >= NodeCount) then
        Continue;

      Alt := Distances[CurrentNode] + EdgeCost(Edge);
      if Alt < Distances[Neighbor] then
      begin
        Distances[Neighbor] := Alt;
        Scores[Neighbor] := Alt + HeuristicCost(Neighbor, ADestinationNodeIndex);
        PrevNode[Neighbor] := CurrentNode;
        PrevEdge[Neighbor] := EdgeIndex;
      end;
    end;
  end;

  if PrevNode[ADestinationNodeIndex] < 0 then
  begin
    FLastRoute.ErrorMessage := 'No route found between origin and destination.';
    Exit;
  end;

  RouteEdges := TList.Create;
  GeometryPoints := TList.Create;
  try
    CurrentNode := ADestinationNodeIndex;
    TotalDistance := 0;
    TotalTime := 0;
    while CurrentNode <> AOriginNodeIndex do
    begin
      EdgeIndex := PrevEdge[CurrentNode];
      if EdgeIndex < 0 then
        Break;
      RouteEdges.Add(TObject(PtrInt(EdgeIndex)));
      Edge := FRouteGraph.Edges[EdgeIndex];
      TotalDistance += Edge.DistanceMeters;
      TotalTime += Edge.TravelTimeSeconds;
      AddGeometrySegment(Edge, GeometryPoints);
      CurrentNode := PrevNode[CurrentNode];
    end;

    SetLength(FLastRoute.EdgeIndexes, RouteEdges.Count);
    for I := 0 to RouteEdges.Count - 1 do
      FLastRoute.EdgeIndexes[I] := PtrInt(RouteEdges[RouteEdges.Count - 1 - I]);

    SetLength(FLastRoute.Geometry, GeometryPoints.Count);
    for I := 0 to GeometryPoints.Count - 1 do
    begin
      PointGeo := GeometryPoints[I];
      FLastRoute.Geometry[I] := PointGeo^;
      Dispose(PointGeo);
    end;

    FLastRoute.Found := True;
    FLastRoute.OriginNodeIndex := AOriginNodeIndex;
    FLastRoute.DestinationNodeIndex := ADestinationNodeIndex;
    FLastRoute.TotalDistanceMeters := TotalDistance;
    FLastRoute.TotalTravelTimeSeconds := TotalTime;
    FLastRoute.CalculationTimeMilliseconds := GetTickCount64 - StartTime;
    Result := True;
  finally
    GeometryPoints.Free;
    RouteEdges.Free;
  end;
end;

function TAIRouteCalculator.CalculateRouteByCoordinates(
  const AOriginLatitude, AOriginLongitude: Double;
  const ADestinationLatitude, ADestinationLongitude: Double
): Boolean;
var
  OriginIndex, DestinationIndex: Integer;
begin
  Result := False;
  if not Assigned(FRouteGraph) then
    Exit;
  if not FRouteGraph.FindNearestNode(AOriginLatitude, AOriginLongitude, OriginIndex) then
  begin
    FLastRoute.ErrorMessage := 'Origin node not found near the selected city.';
    Exit;
  end;
  if not FRouteGraph.FindNearestNode(ADestinationLatitude, ADestinationLongitude, DestinationIndex) then
  begin
    FLastRoute.ErrorMessage := 'Destination node not found near the selected city.';
    Exit;
  end;
  Result := CalculateRoute(OriginIndex, DestinationIndex);
end;

initialization
  RegisterClass(TAIRouteCalculator);
finalization
  UnRegisterClass(TAIRouteCalculator);

end.
