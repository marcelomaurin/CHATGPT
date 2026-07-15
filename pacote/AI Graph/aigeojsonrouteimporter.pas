unit aigeojsonrouteimporter;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Math, fpjson, jsonparser, jsonscanner, aibase, airoutegraph_types,
  airoutegraph, airoutegraph_utils, airoutespeedprofile;

type
  { TAIGeoJSONRouteImporter }

  TAIGeoJSONRouteImporter = class(TAIBaseComponent)
  private
    FRouteGraph: TAIRouteGraph;
    FNodesFileName: string;
    FEdgesFileName: string;
    FAutoBuildIndexes: Boolean;
    FOnProgress: TAIImportProgressEvent;
    function LoadJSONFile(const AFileName: string): TJSONData;
    procedure Report(const AMessage: string; const APercent: Integer);
    function ParsePoint(const AFeature: TJSONObject; out APoint: TAIGeoPoint): Boolean;
    function ParseLineString(const AFeature: TJSONObject; out APoints: TAIGeoPointArray): Boolean;
    function JsonText(const AObj: TJSONObject; const AName, ADefault: string): string;
    function JsonInt64(const AObj: TJSONObject; const AName: string; const ADefault: Int64): Int64;
    function JsonFloat(const AObj: TJSONObject; const AName: string; const ADefault: Double): Double;
  public
    constructor Create(AOwner: TComponent); override;

    function Import: Boolean;
    function ImportNodes: Boolean;
    function ImportEdges: Boolean;
  published
    property RouteGraph: TAIRouteGraph read FRouteGraph write FRouteGraph;
    property NodesFileName: string read FNodesFileName write FNodesFileName;
    property EdgesFileName: string read FEdgesFileName write FEdgesFileName;
    property AutoBuildIndexes: Boolean read FAutoBuildIndexes write FAutoBuildIndexes default True;
    property OnProgress: TAIImportProgressEvent read FOnProgress write FOnProgress;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('AI Graph', [TAIGeoJSONRouteImporter]);
end;

{ TAIGeoJSONRouteImporter }

constructor TAIGeoJSONRouteImporter.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FCategory := ccOther;
  FPrompt := 'Component TAIGeoJSONRouteImporter loads road nodes, edges, and cities from GeoJSON files.';
  FAutoBuildIndexes := True;
end;

procedure TAIGeoJSONRouteImporter.Report(const AMessage: string; const APercent: Integer);
begin
  if Assigned(FOnProgress) then
    FOnProgress(Self, AMessage, APercent);
end;

function TAIGeoJSONRouteImporter.LoadJSONFile(const AFileName: string): TJSONData;
var
  FS: TFileStream;
  Parser: TJSONParser;
begin
  if not FileExists(AFileName) then
    raise Exception.Create('File not found: ' + AFileName);

  FS := TFileStream.Create(AFileName, fmOpenRead or fmShareDenyWrite);
  try
    Parser := TJSONParser.Create(FS, [joUTF8, joBOMCheck]);
    try
      Result := Parser.Parse;
    finally
      Parser.Free;
    end;
  finally
    FS.Free;
  end;
end;

function TAIGeoJSONRouteImporter.ParsePoint(const AFeature: TJSONObject; out APoint: TAIGeoPoint): Boolean;
var
  Geometry: TJSONObject;
  Coordinates: TJSONArray;
begin
  Result := False;
  Geometry := AFeature.Find('geometry') as TJSONObject;
  if not Assigned(Geometry) then
    Exit;
  if NormalizeRouteText(Geometry.Get('type', '')) <> 'point' then
    Exit;
  Coordinates := Geometry.Arrays['coordinates'];
  if (Coordinates = nil) or (Coordinates.Count < 2) then
    Exit;
  APoint.Longitude := Coordinates[0].AsFloat;
  APoint.Latitude := Coordinates[1].AsFloat;
  Result := True;
end;

function TAIGeoJSONRouteImporter.ParseLineString(const AFeature: TJSONObject; out APoints: TAIGeoPointArray): Boolean;
var
  Geometry: TJSONObject;
  Coordinates: TJSONArray;
  I: Integer;
  Pair: TJSONArray;
begin
  Result := False;
  Geometry := AFeature.Find('geometry') as TJSONObject;
  if not Assigned(Geometry) then
    Exit;
  if NormalizeRouteText(Geometry.Get('type', '')) <> 'linestring' then
    Exit;
  Coordinates := Geometry.Arrays['coordinates'];
  if (Coordinates = nil) or (Coordinates.Count < 2) then
    Exit;
  SetLength(APoints, Coordinates.Count);
  for I := 0 to Coordinates.Count - 1 do
  begin
    Pair := Coordinates.Items[I] as TJSONArray;
    if (Pair = nil) or (Pair.Count < 2) then
      Continue;
    APoints[I].Longitude := Pair[0].AsFloat;
    APoints[I].Latitude := Pair[1].AsFloat;
  end;
  Result := True;
end;

function TAIGeoJSONRouteImporter.JsonText(const AObj: TJSONObject; const AName,
  ADefault: string): string;
var
  Data: TJSONData;
begin
  Result := ADefault;
  if not Assigned(AObj) then
    Exit;
  Data := AObj.Find(AName);
  if not Assigned(Data) then
    Exit;
  Result := Trim(Data.AsString);
  if Result = '' then
    Result := ADefault;
end;

function TAIGeoJSONRouteImporter.JsonInt64(const AObj: TJSONObject; const AName: string;
  const ADefault: Int64): Int64;
var
  S: string;
begin
  Result := ADefault;
  S := JsonText(AObj, AName, '');
  if S = '' then
    Exit;
  if not TryStrToInt64(S, Result) then
    Result := ADefault;
end;

function TAIGeoJSONRouteImporter.JsonFloat(const AObj: TJSONObject; const AName: string;
  const ADefault: Double): Double;
var
  S: string;
  FS: TFormatSettings;
begin
  Result := ADefault;
  S := JsonText(AObj, AName, '');
  if S = '' then
    Exit;
  FS := DefaultFormatSettings;
  if not TryStrToFloat(S, Result, FS) then
  begin
    FS.DecimalSeparator := '.';
    if not TryStrToFloat(S, Result, FS) then
      Result := ADefault;
  end;
end;

function TAIGeoJSONRouteImporter.ImportNodes: Boolean;
var
  Data: TJSONData;
  Root, Feature, Props: TJSONObject;
  Features: TJSONArray;
  I: Integer;
  Point: TAIGeoPoint;
  ExternalId: Int64;
  IdText: string;
  LoadedCount: Integer;
begin
  Result := False;
  if not Assigned(FRouteGraph) then
  begin
    SetError('RouteGraph is not assigned.');
    Exit;
  end;

  Data := LoadJSONFile(FNodesFileName);
  try
    if not (Data is TJSONObject) then
      raise Exception.Create('Nodes GeoJSON root must be a JSON object.');
    Root := TJSONObject(Data);
    Features := Root.Arrays['features'];
    if not Assigned(Features) then
      raise Exception.Create('Nodes GeoJSON must contain a features array.');

    FRouteGraph.Clear;
    LoadedCount := 0;
    Report('Loading route nodes...', 0);
    for I := 0 to Features.Count - 1 do
    begin
      Feature := Features[I] as TJSONObject;
      if not ParsePoint(Feature, Point) then
        Continue;
      Props := Feature.Find('properties') as TJSONObject;
      ExternalId := I + 1;
      if Assigned(Props) then
        ExternalId := JsonInt64(Props, 'id', ExternalId);
      FRouteGraph.AddNode(ExternalId, Point.Latitude, Point.Longitude);
      Inc(LoadedCount);
    end;
    Result := FRouteGraph.NodeCount > 0;
    if Result then
      Report(Format('Loaded %d road nodes.', [FRouteGraph.NodeCount]), 50)
    else
      SetError(Format('No road nodes were imported from %s.', [FNodesFileName]));
  finally
    Data.Free;
  end;
end;

function TAIGeoJSONRouteImporter.ImportEdges: Boolean;
var
  Data: TJSONData;
  Root, Feature, Props: TJSONObject;
  Features: TJSONArray;
  I: Integer;
  Points: TAIGeoPointArray;
  FromId, ToId, ExternalId: Int64;
  FromIndex, ToIndex, EdgeIndex: Integer;
  SwapIndex: Integer;
  Dist, Speed, TimeSec, MaxSpeed: Double;
  Highway, OneWayText: string;
  RoadType: TAIRoadType;
  RoadName, RoadRef: string;
  OneWay, Toll: Boolean;
  LoadedCount, ReverseCount, SkippedCount: Integer;
begin
  Result := False;
  if not Assigned(FRouteGraph) then
  begin
    SetError('RouteGraph is not assigned.');
    Exit;
  end;
  if FRouteGraph.NodeCount = 0 then
  begin
    SetError('Road nodes must be loaded before edges.');
    Exit;
  end;

  Data := LoadJSONFile(FEdgesFileName);
  try
    if not (Data is TJSONObject) then
      raise Exception.Create('Edges GeoJSON root must be a JSON object.');
    Root := TJSONObject(Data);
    Features := Root.Arrays['features'];
    if not Assigned(Features) then
      raise Exception.Create('Edges GeoJSON must contain a features array.');

    LoadedCount := 0;
    ReverseCount := 0;
    SkippedCount := 0;
    Report('Loading road edges...', 50);
    for I := 0 to Features.Count - 1 do
    begin
      try
        Feature := Features[I] as TJSONObject;
        if not ParseLineString(Feature, Points) then
        begin
          Inc(SkippedCount);
          Continue;
        end;

        Props := Feature.Find('properties') as TJSONObject;
        if not Assigned(Props) then
        begin
          Inc(SkippedCount);
          Continue;
        end;

        ExternalId := JsonInt64(Props, 'id', I + 1);
        FromId := JsonInt64(Props, 'u', -1);
        ToId := JsonInt64(Props, 'v', -1);
        if (FromId < 0) or (ToId < 0) then
        begin
          Inc(SkippedCount);
          Continue;
        end;

        FromIndex := FRouteGraph.FindNodeIndexByExternalId(FromId);
        ToIndex := FRouteGraph.FindNodeIndexByExternalId(ToId);
        if (FromIndex < 0) or (ToIndex < 0) then
        begin
          Inc(SkippedCount);
          Continue;
        end;

        Highway := JsonText(Props, 'highway', '');
        RoadType := RoadTypeFromText(Highway);
        RoadName := JsonText(Props, 'name', '');
        RoadRef := JsonText(Props, 'ref', '');
        OneWayText := LowerCase(JsonText(Props, 'oneway', 'yes'));
        OneWay := not ((OneWayText = 'no') or (OneWayText = 'false'));
        if OneWayText = '-1' then
        begin
          OneWay := True;
          SwapIndex := FromIndex;
          FromIndex := ToIndex;
          ToIndex := SwapIndex;
        end;
        Toll := LowerCase(JsonText(Props, 'toll', 'false')) = 'true';

        Dist := JsonFloat(Props, 'length_m', 0.0);
        if Dist <= 0 then
          Dist := CalculateLineStringDistance(Points);
        MaxSpeed := ParseMaxSpeedKmH(JsonText(Props, 'maxspeed', ''), 0);
        Speed := DefaultSpeedForRoadType(RoadType);
        if MaxSpeed > 0 then
          Speed := MaxSpeed;
        Speed := Max(1, Speed * 0.85);
        TimeSec := Dist / (Speed * 1000 / 3600);

        EdgeIndex := FRouteGraph.AddEdge(ExternalId, FromIndex, ToIndex, Dist, TimeSec);
        FRouteGraph.UpdateEdgeMetadata(EdgeIndex, RoadName, RoadRef, RoadType, OneWay, Toll, Speed);
        FRouteGraph.SetEdgeGeometry(EdgeIndex, Points);
        Inc(LoadedCount);

        if not OneWay then
        begin
          EdgeIndex := FRouteGraph.AddEdge(ExternalId + 1000000000, ToIndex, FromIndex, Dist, TimeSec);
          FRouteGraph.UpdateEdgeMetadata(EdgeIndex, RoadName, RoadRef, RoadType, False, Toll, Speed);
          FRouteGraph.SetEdgeGeometry(EdgeIndex, Points);
          Inc(ReverseCount);
          Inc(LoadedCount);
        end;
      except
        on E: Exception do
        begin
          Inc(SkippedCount);
          SetError('Edge import failed at feature ' + IntToStr(I + 1) + ': ' + E.Message);
          Exit(False);
        end;
      end;
    end;

    if FAutoBuildIndexes then
    begin
      FRouteGraph.BuildAdjacencyIndex;
      FRouteGraph.BuildSpatialIndex;
    end;

    Result := FRouteGraph.EdgeCount > 0;
    if Result then
      Report(Format('Loaded %d road edges (%d reverse). Skipped %d features.', [
        LoadedCount, ReverseCount, SkippedCount]), 100)
    else
      SetError(Format('No road edges were imported from %s.', [FEdgesFileName]));
  finally
    Data.Free;
  end;
end;

function TAIGeoJSONRouteImporter.Import: Boolean;
begin
  Result := ImportNodes and ImportEdges;
end;

initialization
  RegisterClass(TAIGeoJSONRouteImporter);
finalization
  UnRegisterClass(TAIGeoJSONRouteImporter);

end.
