unit airoutegraph;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Contnrs, Math, aibase, airoutegraph_types, airoutegraph_utils;

type
  { TAIRouteGraph }

  TAIRouteGraph = class(TAIBaseComponent)
  private
    FNodes: TAIRouteNodeArray;
    FEdges: TAIRouteEdgeArray;
    FLoaded: Boolean;
    FSourceFile: string;
    FNodeCount: Integer;
    FEdgeCount: Integer;
    FSpatialCellSize: Double;
    FMaximumSnapDistanceMeters: Double;
    FExternalNodeIndex: TStringList;
    FSpatialIndex: TStringList;
    function GetNode(AIndex: Integer): TAIRouteNode;
    function GetEdge(AIndex: Integer): TAIRouteEdge;
    function CellKey(const ALatitude, ALongitude: Double): string;
    procedure SortEdgesByOrigin;
    procedure AddIndexEntry(const AKey: string; const AIndex: Integer);
    procedure AppendTextToStream(AStream: TStream; const AText: string);
    function ReadTextFromStream(AStream: TStream): string;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    procedure Clear;

    function AddNode(
      const AExternalId: Int64;
      const ALatitude, ALongitude: Double
    ): Integer;

    function AddEdge(
      const AExternalId: Int64;
      const AFromNodeIndex, AToNodeIndex: Integer;
      const ADistanceMeters, ATravelTimeSeconds: Double
    ): Integer;

    function FindNodeIndexByExternalId(const AExternalId: Int64): Integer;
    procedure UpdateEdgeMetadata(
      const AEdgeIndex: Integer;
      const ARoadName, ARoadReference: string;
      const AHighwayType: TAIRoadType;
      const AOneWay, AToll: Boolean;
      const AEstimatedSpeedKmH: Double
    );

    procedure SetEdgeGeometry(const AEdgeIndex: Integer; const APoints: TAIGeoPointArray);

    procedure BuildAdjacencyIndex;
    procedure BuildSpatialIndex;

    function FindNearestNode(
      const ALatitude, ALongitude: Double;
      out ANodeIndex: Integer
    ): Boolean;

    procedure SaveToBinary(const AFileName: string);
    procedure LoadFromBinary(const AFileName: string);

    function GetEdgeGeometry(const AEdgeIndex: Integer): TAIGeoPointArray;

    property Nodes[AIndex: Integer]: TAIRouteNode read GetNode;
    property Edges[AIndex: Integer]: TAIRouteEdge read GetEdge;
    property NodeCount: Integer read FNodeCount;
    property EdgeCount: Integer read FEdgeCount;
  published
    property SourceFile: string read FSourceFile write FSourceFile;
    property Loaded: Boolean read FLoaded;
    property SpatialCellSize: Double read FSpatialCellSize write FSpatialCellSize;
    property MaximumSnapDistanceMeters: Double read FMaximumSnapDistanceMeters write FMaximumSnapDistanceMeters;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('AI Graph', [TAIRouteGraph]);
end;

{ TAIRouteGraph }

constructor TAIRouteGraph.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FCategory := ccOther;
  FPrompt := 'Component TAIRouteGraph stores road nodes, directed edges, adjacency indexes, and spatial lookup for route calculation.';
  FSpatialCellSize := 0.05;
  FMaximumSnapDistanceMeters := 50000;
  FExternalNodeIndex := TStringList.Create;
  FExternalNodeIndex.Sorted := True;
  FExternalNodeIndex.Duplicates := dupIgnore;
  FSpatialIndex := TStringList.Create;
  FSpatialIndex.Sorted := False;
  FSpatialIndex.Duplicates := dupIgnore;
  Clear;
end;

destructor TAIRouteGraph.Destroy;
begin
  FSpatialIndex.Free;
  FExternalNodeIndex.Free;
  inherited Destroy;
end;

procedure TAIRouteGraph.Clear;
begin
  SetLength(FNodes, 0);
  SetLength(FEdges, 0);
  FNodeCount := 0;
  FEdgeCount := 0;
  FLoaded := False;
  FExternalNodeIndex.Clear;
  FSpatialIndex.Clear;
end;

function TAIRouteGraph.GetNode(AIndex: Integer): TAIRouteNode;
begin
  if (AIndex < 0) or (AIndex >= FNodeCount) then
    raise Exception.CreateFmt('Node index out of range: %d', [AIndex]);
  Result := FNodes[AIndex];
end;

function TAIRouteGraph.GetEdge(AIndex: Integer): TAIRouteEdge;
begin
  if (AIndex < 0) or (AIndex >= FEdgeCount) then
    raise Exception.CreateFmt('Edge index out of range: %d', [AIndex]);
  Result := FEdges[AIndex];
end;

function TAIRouteGraph.FindNodeIndexByExternalId(const AExternalId: Int64): Integer;
var
  Idx: Integer;
begin
  Result := -1;
  if FExternalNodeIndex.Count = 0 then
    Exit;
  if FExternalNodeIndex.Find(IntToStr(AExternalId), Idx) then
    Result := PtrInt(FExternalNodeIndex.Objects[Idx]);
end;

function TAIRouteGraph.AddNode(
  const AExternalId: Int64; const ALatitude, ALongitude: Double
): Integer;
begin
  Result := FindNodeIndexByExternalId(AExternalId);
  if Result >= 0 then
    Exit;

  Result := FNodeCount;
  SetLength(FNodes, FNodeCount + 1);
  FNodes[Result].ExternalId := AExternalId;
  FNodes[Result].Latitude := ALatitude;
  FNodes[Result].Longitude := ALongitude;
  FNodes[Result].FirstOutgoingEdge := -1;
  FNodes[Result].OutgoingEdgeCount := 0;
  Inc(FNodeCount);
  AddIndexEntry(IntToStr(AExternalId), Result);
end;

function TAIRouteGraph.AddEdge(
  const AExternalId: Int64; const AFromNodeIndex, AToNodeIndex: Integer;
  const ADistanceMeters, ATravelTimeSeconds: Double
): Integer;
begin
  Result := FEdgeCount;
  SetLength(FEdges, FEdgeCount + 1);
  FEdges[Result].ExternalId := AExternalId;
  FEdges[Result].FromNodeIndex := AFromNodeIndex;
  FEdges[Result].ToNodeIndex := AToNodeIndex;
  FEdges[Result].DistanceMeters := ADistanceMeters;
  FEdges[Result].TravelTimeSeconds := ATravelTimeSeconds;
  FEdges[Result].EstimatedSpeedKmH := 0;
  FEdges[Result].RoadName := '';
  FEdges[Result].RoadReference := '';
  FEdges[Result].HighwayType := rtUnknown;
  FEdges[Result].OneWay := True;
  FEdges[Result].Toll := False;
  FEdges[Result].GeometryStart := 0;
  FEdges[Result].GeometryCount := 0;
  SetLength(FEdges[Result].Geometry, 0);
  Inc(FEdgeCount);
  FLoaded := True;
end;

procedure TAIRouteGraph.UpdateEdgeMetadata(
  const AEdgeIndex: Integer; const ARoadName, ARoadReference: string;
  const AHighwayType: TAIRoadType; const AOneWay, AToll: Boolean;
  const AEstimatedSpeedKmH: Double);
begin
  if (AEdgeIndex < 0) or (AEdgeIndex >= FEdgeCount) then
    Exit;
  FEdges[AEdgeIndex].RoadName := ARoadName;
  FEdges[AEdgeIndex].RoadReference := ARoadReference;
  FEdges[AEdgeIndex].HighwayType := AHighwayType;
  FEdges[AEdgeIndex].OneWay := AOneWay;
  FEdges[AEdgeIndex].Toll := AToll;
  FEdges[AEdgeIndex].EstimatedSpeedKmH := AEstimatedSpeedKmH;
end;

procedure TAIRouteGraph.SetEdgeGeometry(const AEdgeIndex: Integer; const APoints: TAIGeoPointArray);
var
  I: Integer;
begin
  if (AEdgeIndex < 0) or (AEdgeIndex >= FEdgeCount) then
    Exit;
  SetLength(FEdges[AEdgeIndex].Geometry, Length(APoints));
  for I := 0 to High(APoints) do
    FEdges[AEdgeIndex].Geometry[I] := APoints[I];
  FEdges[AEdgeIndex].GeometryStart := 0;
  FEdges[AEdgeIndex].GeometryCount := Length(APoints);
end;

procedure TAIRouteGraph.SortEdgesByOrigin;
var
  I, J: Integer;
  Tmp: TAIRouteEdge;
begin
  for I := 0 to FEdgeCount - 2 do
    for J := I + 1 to FEdgeCount - 1 do
      if (FEdges[J].FromNodeIndex < FEdges[I].FromNodeIndex) or
        ((FEdges[J].FromNodeIndex = FEdges[I].FromNodeIndex) and
        (FEdges[J].ToNodeIndex < FEdges[I].ToNodeIndex)) then
      begin
        Tmp := FEdges[I];
        FEdges[I] := FEdges[J];
        FEdges[J] := Tmp;
      end;
end;

procedure TAIRouteGraph.BuildAdjacencyIndex;
var
  I, CurrentNode, StartIndex: Integer;
begin
  if FNodeCount = 0 then
    Exit;

  SortEdgesByOrigin;
  for I := 0 to FNodeCount - 1 do
  begin
    FNodes[I].FirstOutgoingEdge := -1;
    FNodes[I].OutgoingEdgeCount := 0;
  end;

  CurrentNode := -1;
  StartIndex := 0;
  for I := 0 to FEdgeCount - 1 do
  begin
    if FEdges[I].FromNodeIndex <> CurrentNode then
    begin
      if CurrentNode >= 0 then
      begin
        FNodes[CurrentNode].FirstOutgoingEdge := StartIndex;
        FNodes[CurrentNode].OutgoingEdgeCount := I - StartIndex;
      end;
      CurrentNode := FEdges[I].FromNodeIndex;
      StartIndex := I;
    end;
  end;
  if CurrentNode >= 0 then
  begin
    FNodes[CurrentNode].FirstOutgoingEdge := StartIndex;
    FNodes[CurrentNode].OutgoingEdgeCount := FEdgeCount - StartIndex;
  end;
end;

procedure TAIRouteGraph.AddIndexEntry(const AKey: string; const AIndex: Integer);
begin
  FExternalNodeIndex.AddObject(AKey, TObject(PtrInt(AIndex)));
end;

function TAIRouteGraph.CellKey(const ALatitude, ALongitude: Double): string;
var
  LatCell, LonCell: Int64;
begin
  if FSpatialCellSize <= 0 then
    Exit('0|0');
  LatCell := Trunc(ALatitude / FSpatialCellSize);
  LonCell := Trunc(ALongitude / FSpatialCellSize);
  Result := IntToStr(LatCell) + '|' + IntToStr(LonCell);
end;

procedure TAIRouteGraph.BuildSpatialIndex;
var
  I: Integer;
  Idx: Integer;
  Key: string;
begin
  FSpatialIndex.Clear;
  for I := 0 to FNodeCount - 1 do
  begin
    Key := CellKey(FNodes[I].Latitude, FNodes[I].Longitude);
    Idx := FSpatialIndex.IndexOfName(Key);
    if Idx < 0 then
      FSpatialIndex.Add(Key + '=' + IntToStr(I))
    else
    begin
      if FSpatialIndex.ValueFromIndex[Idx] = '' then
        FSpatialIndex.ValueFromIndex[Idx] := IntToStr(I)
      else
        FSpatialIndex.ValueFromIndex[Idx] := FSpatialIndex.ValueFromIndex[Idx] + ',' + IntToStr(I);
    end;
  end;
end;

function TAIRouteGraph.FindNearestNode(
  const ALatitude, ALongitude: Double; out ANodeIndex: Integer): Boolean;
var
  BestDistance, Dist: Double;
  I: Integer;
  Key: string;
  CellList, CandidateList: TStringList;
  LatCell, LonCell, DLat, DLon, Radius, R: Integer;
  CandidateIndex: Integer;
begin
  Result := False;
  ANodeIndex := -1;
  if FNodeCount = 0 then
    Exit;

  BestDistance := MaxDouble;
  CandidateList := TStringList.Create;
  try
    Key := CellKey(ALatitude, ALongitude);
    if FSpatialIndex.IndexOfName(Key) >= 0 then
      CandidateList.CommaText := FSpatialIndex.Values[Key];

    if CandidateList.Count = 0 then
    begin
      LatCell := Trunc(ALatitude / FSpatialCellSize);
      LonCell := Trunc(ALongitude / FSpatialCellSize);
      for Radius := 1 to 6 do
      begin
        CandidateList.Clear;
        for DLat := -Radius to Radius do
          for DLon := -Radius to Radius do
          begin
            if (Abs(DLat) <> Radius) and (Abs(DLon) <> Radius) then
              Continue;
            Key := IntToStr(LatCell + DLat) + '|' + IntToStr(LonCell + DLon);
            if FSpatialIndex.IndexOfName(Key) >= 0 then
              CandidateList.CommaText := CandidateList.CommaText + ',' + FSpatialIndex.Values[Key];
          end;
        if CandidateList.Count > 0 then
          Break;
      end;
    end;

    if CandidateList.Count = 0 then
    begin
      for I := 0 to FNodeCount - 1 do
      begin
        Dist := HaversineDistanceMeters(ALatitude, ALongitude, FNodes[I].Latitude, FNodes[I].Longitude);
        if Dist < BestDistance then
        begin
          BestDistance := Dist;
          ANodeIndex := I;
        end;
      end;
    end
    else
    begin
      for I := 0 to CandidateList.Count - 1 do
      begin
        CandidateIndex := StrToIntDef(CandidateList[I], -1);
        if (CandidateIndex < 0) or (CandidateIndex >= FNodeCount) then
          Continue;
        Dist := HaversineDistanceMeters(ALatitude, ALongitude,
          FNodes[CandidateIndex].Latitude, FNodes[CandidateIndex].Longitude);
        if Dist < BestDistance then
        begin
          BestDistance := Dist;
          ANodeIndex := CandidateIndex;
        end;
      end;
    end;

    Result := (ANodeIndex >= 0) and (BestDistance <= FMaximumSnapDistanceMeters);
  finally
    CandidateList.Free;
  end;
end;

procedure TAIRouteGraph.AppendTextToStream(AStream: TStream; const AText: string);
var
  B: UTF8String;
  L: Integer;
begin
  B := UTF8Encode(AText);
  L := Length(B);
  AStream.WriteBuffer(L, SizeOf(L));
  if L > 0 then
    AStream.WriteBuffer(B[1], L);
end;

function TAIRouteGraph.ReadTextFromStream(AStream: TStream): string;
var
  L: Integer;
  B: UTF8String;
begin
  Result := '';
  AStream.ReadBuffer(L, SizeOf(L));
  if L <= 0 then
    Exit;
  SetLength(B, L);
  AStream.ReadBuffer(B[1], L);
  Result := UTF8Decode(B);
end;

procedure TAIRouteGraph.SaveToBinary(const AFileName: string);
var
  FS: TFileStream;
  I, G: Integer;
  S: string;
begin
  FS := TFileStream.Create(AFileName, fmCreate);
  try
    S := 'AIRouteGraph1';
    AppendTextToStream(FS, S);
    FS.WriteBuffer(FNodeCount, SizeOf(FNodeCount));
    FS.WriteBuffer(FEdgeCount, SizeOf(FEdgeCount));
    for I := 0 to FNodeCount - 1 do
      FS.WriteBuffer(FNodes[I], SizeOf(TAIRouteNode));
    for I := 0 to FEdgeCount - 1 do
    begin
      FS.WriteBuffer(FEdges[I].ExternalId, SizeOf(FEdges[I].ExternalId));
      FS.WriteBuffer(FEdges[I].FromNodeIndex, SizeOf(FEdges[I].FromNodeIndex));
      FS.WriteBuffer(FEdges[I].ToNodeIndex, SizeOf(FEdges[I].ToNodeIndex));
      FS.WriteBuffer(FEdges[I].DistanceMeters, SizeOf(FEdges[I].DistanceMeters));
      FS.WriteBuffer(FEdges[I].EstimatedSpeedKmH, SizeOf(FEdges[I].EstimatedSpeedKmH));
      FS.WriteBuffer(FEdges[I].TravelTimeSeconds, SizeOf(FEdges[I].TravelTimeSeconds));
      FS.WriteBuffer(FEdges[I].HighwayType, SizeOf(FEdges[I].HighwayType));
      FS.WriteBuffer(FEdges[I].OneWay, SizeOf(FEdges[I].OneWay));
      FS.WriteBuffer(FEdges[I].Toll, SizeOf(FEdges[I].Toll));
      AppendTextToStream(FS, FEdges[I].RoadName);
      AppendTextToStream(FS, FEdges[I].RoadReference);
      FS.WriteBuffer(FEdges[I].GeometryCount, SizeOf(FEdges[I].GeometryCount));
      for G := 0 to High(FEdges[I].Geometry) do
        FS.WriteBuffer(FEdges[I].Geometry[G], SizeOf(TAIGeoPoint));
    end;
    AppendTextToStream(FS, FSourceFile);
    FS.WriteBuffer(FLoaded, SizeOf(FLoaded));
  finally
    FS.Free;
  end;
end;

procedure TAIRouteGraph.LoadFromBinary(const AFileName: string);
var
  FS: TFileStream;
  I, G: Integer;
  Signature: string;
begin
  Clear;
  FS := TFileStream.Create(AFileName, fmOpenRead or fmShareDenyWrite);
  try
    Signature := ReadTextFromStream(FS);
    if Signature <> 'AIRouteGraph1' then
      raise Exception.Create('Invalid route graph cache.');
    FS.ReadBuffer(FNodeCount, SizeOf(FNodeCount));
    FS.ReadBuffer(FEdgeCount, SizeOf(FEdgeCount));
    SetLength(FNodes, FNodeCount);
    SetLength(FEdges, FEdgeCount);
    for I := 0 to FNodeCount - 1 do
    begin
      FS.ReadBuffer(FNodes[I], SizeOf(TAIRouteNode));
      AddIndexEntry(IntToStr(FNodes[I].ExternalId), I);
    end;
    for I := 0 to FEdgeCount - 1 do
    begin
      FS.ReadBuffer(FEdges[I].ExternalId, SizeOf(FEdges[I].ExternalId));
      FS.ReadBuffer(FEdges[I].FromNodeIndex, SizeOf(FEdges[I].FromNodeIndex));
      FS.ReadBuffer(FEdges[I].ToNodeIndex, SizeOf(FEdges[I].ToNodeIndex));
      FS.ReadBuffer(FEdges[I].DistanceMeters, SizeOf(FEdges[I].DistanceMeters));
      FS.ReadBuffer(FEdges[I].EstimatedSpeedKmH, SizeOf(FEdges[I].EstimatedSpeedKmH));
      FS.ReadBuffer(FEdges[I].TravelTimeSeconds, SizeOf(FEdges[I].TravelTimeSeconds));
      FS.ReadBuffer(FEdges[I].HighwayType, SizeOf(FEdges[I].HighwayType));
      FS.ReadBuffer(FEdges[I].OneWay, SizeOf(FEdges[I].OneWay));
      FS.ReadBuffer(FEdges[I].Toll, SizeOf(FEdges[I].Toll));
      FEdges[I].RoadName := ReadTextFromStream(FS);
      FEdges[I].RoadReference := ReadTextFromStream(FS);
      FS.ReadBuffer(FEdges[I].GeometryCount, SizeOf(FEdges[I].GeometryCount));
      SetLength(FEdges[I].Geometry, FEdges[I].GeometryCount);
      for G := 0 to FEdges[I].GeometryCount - 1 do
        FS.ReadBuffer(FEdges[I].Geometry[G], SizeOf(TAIGeoPoint));
    end;
    FSourceFile := ReadTextFromStream(FS);
    FS.ReadBuffer(FLoaded, SizeOf(FLoaded));
  finally
    FS.Free;
  end;
  BuildAdjacencyIndex;
  BuildSpatialIndex;
end;

function TAIRouteGraph.GetEdgeGeometry(const AEdgeIndex: Integer): TAIGeoPointArray;
begin
  if (AEdgeIndex < 0) or (AEdgeIndex >= FEdgeCount) then
    Exit(nil);
  Result := FEdges[AEdgeIndex].Geometry;
end;

initialization
  RegisterClass(TAIRouteGraph);
finalization
  UnRegisterClass(TAIRouteGraph);

end.
