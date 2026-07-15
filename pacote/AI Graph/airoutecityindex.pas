unit airoutecityindex;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpjson, jsonparser, jsonscanner, Contnrs, aibase, airoutegraph_types,
  airoutegraph, airoutegraph_utils;

type
  { TAIRouteCityIndex }

  TAIRouteCityIndex = class(TAIBaseComponent)
  private
    FCities: TObjectList;
    function GetCity(AIndex: Integer): TAIRouteCity;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    procedure Clear;
    function LoadGeoJSON(const AFileName: string): Boolean;
    function FindCity(const AName: string; out ACity: TAIRouteCity): Boolean;
    function ConnectCitiesToGraph(ARouteGraph: TAIRouteGraph): Boolean;
    procedure GetCityNames(AList: TStrings);
    function CityCount: Integer;
    property Cities[AIndex: Integer]: TAIRouteCity read GetCity;
  published
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('AI Graph', [TAIRouteCityIndex]);
end;

{ TAIRouteCityIndex }

constructor TAIRouteCityIndex.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FCategory := ccOther;
  FPrompt := 'Component TAIRouteCityIndex loads city coordinates and connects each city to the nearest road node.';
  FCities := TObjectList.Create(True);
end;

destructor TAIRouteCityIndex.Destroy;
begin
  FCities.Free;
  inherited Destroy;
end;

procedure TAIRouteCityIndex.Clear;
begin
  FCities.Clear;
end;

function TAIRouteCityIndex.CityCount: Integer;
begin
  Result := FCities.Count;
end;

function TAIRouteCityIndex.GetCity(AIndex: Integer): TAIRouteCity;
begin
  Result := TAIRouteCity(FCities[AIndex]);
end;

procedure TAIRouteCityIndex.GetCityNames(AList: TStrings);
var
  I: Integer;
begin
  AList.Clear;
  for I := 0 to FCities.Count - 1 do
    AList.Add(TAIRouteCity(FCities[I]).Name);
end;

function TAIRouteCityIndex.LoadGeoJSON(const AFileName: string): Boolean;
var
  FS: TFileStream;
  Parser: TJSONParser;
  Data: TJSONData;
  Root, Props: TJSONObject;
  FeaturesData: TJSONData;
  Features: TJSONArray;
  Feature, Geometry: TJSONObject;
  City: TAIRouteCity;
  I: Integer;
  Coordinates: TJSONArray;
begin
  Result := False;
  Clear;

  if not FileExists(AFileName) then
  begin
    SetError('City GeoJSON not found: ' + AFileName);
    Exit;
  end;

  FS := TFileStream.Create(AFileName, fmOpenRead or fmShareDenyWrite);
  try
    Parser := TJSONParser.Create(FS, [joUTF8, joBOMCheck]);
    try
      Data := Parser.Parse;
    finally
      Parser.Free;
    end;
    try
      if not (Data is TJSONObject) then
        raise Exception.Create('City GeoJSON root must be an object.');

      Root := TJSONObject(Data);
      FeaturesData := Root.Find('features');
      if not Assigned(FeaturesData) or not (FeaturesData is TJSONArray) then
        raise Exception.Create('City GeoJSON must contain a features array.');
      Features := TJSONArray(FeaturesData);
      for I := 0 to Features.Count - 1 do
      begin
        Feature := TJSONObject(Features[I]);
        Props := Feature.Find('properties') as TJSONObject;
        Geometry := Feature.Find('geometry') as TJSONObject;
        if not Assigned(Geometry) then
          Continue;
        if LowerCase(Geometry.Get('type', '')) <> 'point' then
          Continue;
        Coordinates := Geometry.Arrays['coordinates'];
        if (Coordinates = nil) or (Coordinates.Count < 2) then
          Continue;

        City := TAIRouteCity.Create;
        if Assigned(Props) then
        begin
          City.IBGECode := Props.Get('ibge_code', '');
          City.Name := Props.Get('name', '');
        end;
        City.NormalizedName := NormalizeRouteText(City.Name);
        City.Longitude := Coordinates[0].AsFloat;
        City.Latitude := Coordinates[1].AsFloat;
        City.NearestNodeIndex := -1;
        FCities.Add(City);
      end;
      Result := FCities.Count > 0;
    finally
      Data.Free;
    end;
  finally
    FS.Free;
  end;
end;

function TAIRouteCityIndex.FindCity(const AName: string; out ACity: TAIRouteCity): Boolean;
var
  Target: string;
  I: Integer;
  City: TAIRouteCity;
begin
  Result := False;
  ACity := nil;
  Target := NormalizeRouteText(AName);
  for I := 0 to FCities.Count - 1 do
  begin
    City := TAIRouteCity(FCities[I]);
    if City.NormalizedName = Target then
    begin
      ACity := City;
      Exit(True);
    end;
  end;
end;

function TAIRouteCityIndex.ConnectCitiesToGraph(ARouteGraph: TAIRouteGraph): Boolean;
var
  I, NodeIndex: Integer;
  City: TAIRouteCity;
begin
  Result := False;
  if not Assigned(ARouteGraph) then
    Exit;
  if ARouteGraph.NodeCount = 0 then
    Exit;

  for I := 0 to FCities.Count - 1 do
  begin
    City := TAIRouteCity(FCities[I]);
    if ARouteGraph.FindNearestNode(City.Latitude, City.Longitude, NodeIndex) then
      City.NearestNodeIndex := NodeIndex
    else
      City.NearestNodeIndex := -1;
  end;
  Result := True;
end;

initialization
  RegisterClass(TAIRouteCityIndex);
finalization
  UnRegisterClass(TAIRouteCityIndex);

end.
