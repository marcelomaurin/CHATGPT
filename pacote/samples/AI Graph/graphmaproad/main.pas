unit main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Math, Types, Forms, Controls, Graphics, Dialogs, ExtCtrls,
  StdCtrls, ComCtrls, fphttpclient, opensslsockets, lazpng, aibase,
  airoutegraph_types, airoutegraph_utils, airoutegraph, aigeojsonrouteimporter,
  airoutespeedprofile, airoutecityindex, airoutecalculator;

type

  { TfrmMain }

  TfrmMain = class(TForm)
    AIGeoJSONRouteImporter1: TAIGeoJSONRouteImporter;
    AIRouteCalculator1: TAIRouteCalculator;
    AIRouteCityIndex1: TAIRouteCityIndex;
    AIRouteGraph1: TAIRouteGraph;
    AIRouteSpeedProfile1: TAIRouteSpeedProfile;
    btnCalculate: TButton;
    btnReload: TButton;
    btnFitView: TButton;
    btnZoomIn: TButton;
    btnZoomOut: TButton;
    cbDestination: TComboBox;
    cbOrigin: TComboBox;
    cbRouteMode: TComboBox;
    edDataFolder: TEdit;
    lblDataFolder: TLabel;
    lblDestination: TLabel;
    lblOrigin: TLabel;
    lblZoomLevel: TLabel;
    lblRouteMode: TLabel;
    lblStatus: TLabel;
    memoDataInfo: TMemo;
    memoLog: TMemo;
    memoRoute: TMemo;
    memoRouteSummary: TMemo;
    lbCities: TListBox;
    lbEdges: TListBox;
    lbNodes: TListBox;
    lbRouteEdges: TListBox;
    pcMain: TPageControl;
    pbMap: TPaintBox;
    tbMapZoom: TTrackBar;
    pnlHeader: TPanel;
    pnlMapLeft: TPanel;
    pnlMapRight: TPanel;
    pnlMapTop: TPanel;
    pnlRouteBottom: TPanel;
    pnlRouteStats: TPanel;
    pnlRouteTop: TPanel;
    tsData: TTabSheet;
    tsLog: TTabSheet;
    tsMap: TTabSheet;
    procedure btnCalculateClick(Sender: TObject);
    procedure btnReloadClick(Sender: TObject);
    procedure btnFitViewClick(Sender: TObject);
    procedure btnZoomInClick(Sender: TObject);
    procedure btnZoomOutClick(Sender: TObject);
    procedure cbDestinationChange(Sender: TObject);
    procedure cbOriginChange(Sender: TObject);
    procedure cbRouteModeChange(Sender: TObject);
    procedure edDataFolderChange(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure pbMapMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure pbMapMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
    procedure pbMapMouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure pbMapMouseWheelDown(Sender: TObject; Shift: TShiftState;
      MousePos: TPoint; var Handled: Boolean);
    procedure pbMapMouseWheelUp(Sender: TObject; Shift: TShiftState;
      MousePos: TPoint; var Handled: Boolean);
    procedure pbMapPaint(Sender: TObject);
    procedure tbMapZoomChange(Sender: TObject);
  private
    FDataFolder: string;
    FNodesFile: string;
    FEdgesFile: string;
    FCitiesFile: string;
    FLastRouteLoaded: Boolean;
    FGraphMinLat: Double;
    FGraphMaxLat: Double;
    FGraphMinLon: Double;
    FGraphMaxLon: Double;
    FMapCenterLat: Double;
    FMapCenterLon: Double;
    FMapZoomLevel: Integer;
    FMapPanX: Double;
    FMapPanY: Double;
    FMapDragging: Boolean;
    FMapDragStart: TPoint;
    FMapPanStartX: Double;
    FMapPanStartY: Double;
    FUpdatingZoomControl: Boolean;
    FTileCacheDir: string;
    procedure AddLog(const AMsg: string);
    procedure ClearView;
    procedure CalculateRoute;
    function CityByCombo(const ACombo: TComboBox): TAIRouteCity;
    function DefaultDataFolder: string;
    procedure DrawArrow(ACanvas: TCanvas; const X1, Y1, X2, Y2: Integer;
      AColor: TColor; AWidth: Integer);
    procedure DrawMapBackground(ACanvas: TCanvas);
    procedure DrawGraph(ACanvas: TCanvas);
    procedure DrawNode(ACanvas: TCanvas; const APoint: TPoint; const AText: string;
      const AColor: TColor; const ARadius: Integer = 5);
    function GeoToPoint(const ALatitude, ALongitude: Double): TPoint;
    function MapViewportRect: TRect;
    procedure LoadDataset;
    procedure PopulateDataLists;
    procedure PopulateCityCombos;
    procedure RefreshDataSummary;
    procedure RefreshRouteSummary;
    procedure RefreshStatus;
    procedure ResetMapView;
    procedure SetMapZoom(const AZoomLevel: Integer; const AAnchor: TPoint);
    function RoadColor(const AHighwayType: TAIRoadType): TColor;
    function RoadWidth(const AHighwayType: TAIRoadType): Integer;
    function ScreenToGeo(const APoint: TPoint; out ALatitude, ALongitude: Double): Boolean;
    function ScreenToGeoAtZoom(const APoint: TPoint; const AZoomLevel: Integer;
      out ALatitude, ALongitude: Double): Boolean;
    function LonToWorldX(const ALongitude: Double; const AZoomLevel: Integer): Double;
    function LatToWorldY(const ALatitude: Double; const AZoomLevel: Integer): Double;
    function WorldXToLon(const AWorldX: Double; const AZoomLevel: Integer): Double;
    function WorldYToLat(const AWorldY: Double; const AZoomLevel: Integer): Double;
    function FitZoomLevel: Integer;
    function FetchTileFile(const AZoomLevel, AX, AY: Integer): string;
    procedure UpdateGraphBounds;
    procedure UpdateMapTransform;
    procedure UpdateMapZoomLabel;
    function NodeLabel(const AIndex: Integer): string;
    function SelectedRouteMode: TAIRouteCostMode;
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
  FMapZoomLevel := 7;
  FMapPanX := 0;
  FMapPanY := 0;
  FMapDragging := False;
  FTileCacheDir := IncludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0))) +
    'osm_tile_cache';

  cbRouteMode.Items.Clear;
  cbRouteMode.Items.Add('Fastest');
  cbRouteMode.Items.Add('Shortest');
  cbRouteMode.ItemIndex := 0;

  if Assigned(tbMapZoom) then
  begin
    tbMapZoom.Min := 3;
    tbMapZoom.Max := 18;
    tbMapZoom.Position := FMapZoomLevel;
  end;

  edDataFolder.Text := DefaultDataFolder;
  pcMain.ActivePage := tsMap;
  memoRoute.Clear;
  memoRouteSummary.Clear;
  memoDataInfo.Clear;
  memoLog.Clear;

  LoadDataset;
end;

procedure TfrmMain.FormDestroy(Sender: TObject);
begin
end;

procedure TfrmMain.btnReloadClick(Sender: TObject);
begin
  LoadDataset;
end;

procedure TfrmMain.btnFitViewClick(Sender: TObject);
begin
  ResetMapView;
  pbMap.Invalidate;
end;

procedure TfrmMain.btnZoomInClick(Sender: TObject);
begin
  if Assigned(tbMapZoom) then
    tbMapZoom.Position := Min(tbMapZoom.Max, tbMapZoom.Position + 1);
end;

procedure TfrmMain.btnZoomOutClick(Sender: TObject);
begin
  if Assigned(tbMapZoom) then
    tbMapZoom.Position := Max(tbMapZoom.Min, tbMapZoom.Position - 1);
end;

procedure TfrmMain.btnCalculateClick(Sender: TObject);
begin
  CalculateRoute;
end;

procedure TfrmMain.cbOriginChange(Sender: TObject);
begin
  RefreshRouteSummary;
  pbMap.Invalidate;
end;

procedure TfrmMain.cbDestinationChange(Sender: TObject);
begin
  RefreshRouteSummary;
  pbMap.Invalidate;
end;

procedure TfrmMain.cbRouteModeChange(Sender: TObject);
begin
  RefreshStatus;
end;

procedure TfrmMain.tbMapZoomChange(Sender: TObject);
begin
  if FUpdatingZoomControl then
    Exit;
  SetMapZoom(tbMapZoom.Position, Point(pbMap.ClientWidth div 2, pbMap.ClientHeight div 2));
end;

procedure TfrmMain.edDataFolderChange(Sender: TObject);
begin
  FDataFolder := Trim(edDataFolder.Text);
end;

procedure TfrmMain.pbMapMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  if Button <> mbLeft then
    Exit;
  FMapDragging := True;
  FMapDragStart := Point(X, Y);
  FMapPanStartX := FMapPanX;
  FMapPanStartY := FMapPanY;
  pbMap.Cursor := crSizeAll;
end;

procedure TfrmMain.pbMapMouseMove(Sender: TObject; Shift: TShiftState; X,
  Y: Integer);
begin
  if not FMapDragging then
    Exit;
  FMapPanX := FMapPanStartX + (X - FMapDragStart.X);
  FMapPanY := FMapPanStartY + (Y - FMapDragStart.Y);
  pbMap.Invalidate;
end;

procedure TfrmMain.pbMapMouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  if Button = mbLeft then
  begin
    FMapDragging := False;
    pbMap.Cursor := crDefault;
  end;
end;

procedure TfrmMain.pbMapMouseWheelDown(Sender: TObject; Shift: TShiftState;
  MousePos: TPoint; var Handled: Boolean);
begin
  if Assigned(tbMapZoom) then
    tbMapZoom.Position := Max(tbMapZoom.Min, tbMapZoom.Position - 1);
  Handled := True;
end;

procedure TfrmMain.pbMapMouseWheelUp(Sender: TObject; Shift: TShiftState;
  MousePos: TPoint; var Handled: Boolean);
begin
  if Assigned(tbMapZoom) then
    tbMapZoom.Position := Min(tbMapZoom.Max, tbMapZoom.Position + 1);
  Handled := True;
end;

procedure TfrmMain.pbMapPaint(Sender: TObject);
begin
  try
    DrawGraph(pbMap.Canvas);
  except
    on E: Exception do
    begin
      pbMap.Canvas.Brush.Color := RGBToColor(245, 242, 236);
      pbMap.Canvas.FillRect(pbMap.ClientRect);
      pbMap.Canvas.Font.Color := clMaroon;
      pbMap.Canvas.TextOut(24, 24, 'Map drawing failed: ' + E.Message);
    end;
  end;
end;

procedure TfrmMain.AddLog(const AMsg: string);
begin
  memoLog.Lines.Add(FormatDateTime('hh:nn:ss', Time) + '  ' + AMsg);
end;

function TfrmMain.DefaultDataFolder: string;
begin
  Result := IncludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0))) +
    'route_data\generated';
end;

function TfrmMain.MapViewportRect: TRect;
begin
  Result := pbMap.ClientRect;
  InflateRect(Result, -24, -24);
  if Result.Right <= Result.Left then
    Result.Right := Result.Left + 1;
  if Result.Bottom <= Result.Top then
    Result.Bottom := Result.Top + 1;
end;

procedure TfrmMain.UpdateMapTransform;
begin
  if AIRouteGraph1.NodeCount = 0 then
  begin
    FMapCenterLat := 0;
    FMapCenterLon := 0;
    Exit;
  end;

  FMapCenterLat := (FGraphMinLat + FGraphMaxLat) / 2;
  FMapCenterLon := (FGraphMinLon + FGraphMaxLon) / 2;
end;

procedure TfrmMain.ResetMapView;
begin
  FMapZoomLevel := FitZoomLevel;
  FMapPanX := 0;
  FMapPanY := 0;
  if Assigned(tbMapZoom) then
  begin
    FUpdatingZoomControl := True;
    tbMapZoom.Position := FMapZoomLevel;
    FUpdatingZoomControl := False;
  end;
  UpdateMapTransform;
  UpdateMapZoomLabel;
end;

procedure TfrmMain.UpdateMapZoomLabel;
begin
  if Assigned(lblZoomLevel) then
    lblZoomLevel.Caption := Format('Zoom %d', [FMapZoomLevel]);
end;

procedure TfrmMain.SetMapZoom(const AZoomLevel: Integer; const AAnchor: TPoint);
var
  AnchorLat, AnchorLon: Double;
  NewPoint: TPoint;
  OldZoom: Integer;
begin
  if AIRouteGraph1.NodeCount = 0 then
    Exit;

  OldZoom := FMapZoomLevel;
  if not ScreenToGeoAtZoom(AAnchor, OldZoom, AnchorLat, AnchorLon) then
    Exit;

  FMapZoomLevel := EnsureRange(AZoomLevel, 3, 18);
  UpdateMapTransform;

  NewPoint := GeoToPoint(AnchorLat, AnchorLon);
  FMapPanX := FMapPanX + (AAnchor.X - NewPoint.X);
  FMapPanY := FMapPanY + (AAnchor.Y - NewPoint.Y);

  if Assigned(tbMapZoom) then
  begin
    FUpdatingZoomControl := True;
    tbMapZoom.Position := FMapZoomLevel;
    FUpdatingZoomControl := False;
  end;
  UpdateMapZoomLabel;
  pbMap.Invalidate;
end;

function TfrmMain.ScreenToGeo(const APoint: TPoint; out ALatitude,
  ALongitude: Double): Boolean;
begin
  Result := ScreenToGeoAtZoom(APoint, FMapZoomLevel, ALatitude, ALongitude);
end;

function TfrmMain.ScreenToGeoAtZoom(const APoint: TPoint;
  const AZoomLevel: Integer; out ALatitude, ALongitude: Double): Boolean;
var
  ViewRect: TRect;
  CenterX, CenterY: Double;
  WorldCenterX, WorldCenterY: Double;
  WorldX, WorldY: Double;
begin
  Result := False;
  if AIRouteGraph1.NodeCount = 0 then
    Exit;

  ViewRect := MapViewportRect;
  CenterX := (ViewRect.Left + ViewRect.Right) / 2 + FMapPanX;
  CenterY := (ViewRect.Top + ViewRect.Bottom) / 2 + FMapPanY;

  WorldCenterX := LonToWorldX(FMapCenterLon, AZoomLevel);
  WorldCenterY := LatToWorldY(FMapCenterLat, AZoomLevel);
  WorldX := WorldCenterX + (APoint.X - CenterX);
  WorldY := WorldCenterY + (APoint.Y - CenterY);

  ALongitude := WorldXToLon(WorldX, AZoomLevel);
  ALatitude := WorldYToLat(WorldY, AZoomLevel);
  Result := True;
end;

function TfrmMain.LonToWorldX(const ALongitude: Double; const AZoomLevel: Integer): Double;
begin
  Result := ((ALongitude + 180.0) / 360.0) * (256.0 * Power(2, AZoomLevel));
end;

function TfrmMain.LatToWorldY(const ALatitude: Double; const AZoomLevel: Integer): Double;
var
  LatRad: Double;
begin
  LatRad := DegToRad(EnsureRange(ALatitude, -85.05112878, 85.05112878));
  Result := (1 - Ln(Tan(LatRad) + (1 / Cos(LatRad))) / Pi) / 2 *
    (256.0 * Power(2, AZoomLevel));
end;

function TfrmMain.WorldXToLon(const AWorldX: Double; const AZoomLevel: Integer): Double;
begin
  Result := AWorldX / (256.0 * Power(2, AZoomLevel)) * 360.0 - 180.0;
end;

function TfrmMain.WorldYToLat(const AWorldY: Double; const AZoomLevel: Integer): Double;
var
  N: Double;
begin
  N := Pi - 2 * Pi * AWorldY / (256.0 * Power(2, AZoomLevel));
  Result := RadToDeg(ArcTan(Sinh(N)));
end;

function TfrmMain.FitZoomLevel: Integer;
var
  ViewRect: TRect;
  Zoom: Integer;
begin
  if AIRouteGraph1.NodeCount = 0 then
    Exit(7);

  ViewRect := MapViewportRect;
  for Zoom := 18 downto 3 do
  begin
    if (Abs(LonToWorldX(FGraphMaxLon, Zoom) - LonToWorldX(FGraphMinLon, Zoom)) <= (ViewRect.Right - ViewRect.Left) * 0.90) and
       (Abs(LatToWorldY(FGraphMinLat, Zoom) - LatToWorldY(FGraphMaxLat, Zoom)) <= (ViewRect.Bottom - ViewRect.Top) * 0.80) then
      Exit(Zoom);
  end;
  Result := 7;
end;

function TfrmMain.FetchTileFile(const AZoomLevel, AX, AY: Integer): string;
var
  Url: string;
  Client: TFPHTTPClient;
  FS: TFileStream;
begin
  Result := IncludeTrailingPathDelimiter(FTileCacheDir) + IntToStr(AZoomLevel) + PathDelim +
    IntToStr(AX) + PathDelim + IntToStr(AY) + '.png';
  if FileExists(Result) then
    Exit;

  ForceDirectories(ExtractFileDir(Result));
  Url := Format('https://tile.openstreetmap.org/%d/%d/%d.png', [AZoomLevel, AX, AY]);
  Client := TFPHTTPClient.Create(nil);
  try
    Client.AllowRedirect := True;
    Client.AddHeader('User-Agent', 'maurinsoft-graphmaproad/1.0');
    FS := TFileStream.Create(Result, fmCreate);
    try
      Client.Get(Url, FS);
    finally
      FS.Free;
    end;
  except
    on E: Exception do
    begin
      if FileExists(Result) then
        DeleteFile(Result);
      AddLog('Tile download failed: ' + E.Message);
      Result := '';
    end;
  end;
  Client.Free;
  if not FileExists(Result) then
    Result := '';
end;

function TfrmMain.RoadColor(const AHighwayType: TAIRoadType): TColor;
begin
  case AHighwayType of
    rtMotorway: Result := RGBToColor(245, 170, 65);
    rtTrunk: Result := RGBToColor(241, 133, 70);
    rtPrimary: Result := RGBToColor(220, 116, 73);
    rtSecondary: Result := RGBToColor(202, 153, 89);
    rtTertiary: Result := RGBToColor(156, 171, 118);
    rtResidential: Result := RGBToColor(188, 194, 204);
    rtService: Result := RGBToColor(170, 180, 188);
    rtTrack: Result := RGBToColor(160, 142, 120);
  else
    Result := RGBToColor(177, 185, 194);
  end;
end;

function TfrmMain.RoadWidth(const AHighwayType: TAIRoadType): Integer;
begin
  case AHighwayType of
    rtMotorway: Result := 3;
    rtTrunk: Result := 3;
    rtPrimary: Result := 2;
    rtSecondary: Result := 2;
    rtTertiary: Result := 2;
    rtResidential: Result := 1;
    rtService: Result := 1;
    rtTrack: Result := 1;
  else
    Result := 1;
  end;
end;

procedure TfrmMain.DrawMapBackground(ACanvas: TCanvas);
var
  ViewRect: TRect;
  ViewW, ViewH: Integer;
  CenterX, CenterY: Double;
  TopLeftX, TopLeftY: Double;
  TileXStart, TileXEnd, TileYStart, TileYEnd: Integer;
  TileX, TileY: Integer;
  TileLeft, TileTop: Integer;
  TileFile: string;
  Pic: TPortableNetworkGraphic;
  TileLimit: Integer;
begin
  ViewRect := MapViewportRect;
  ViewW := ViewRect.Right - ViewRect.Left;
  ViewH := ViewRect.Bottom - ViewRect.Top;

  ACanvas.Brush.Color := RGBToColor(238, 239, 236);
  ACanvas.FillRect(pbMap.ClientRect);

  if AIRouteGraph1.NodeCount = 0 then
    Exit;

  CenterX := LonToWorldX(FMapCenterLon, FMapZoomLevel);
  CenterY := LatToWorldY(FMapCenterLat, FMapZoomLevel);
  TopLeftX := CenterX - (ViewW / 2) - FMapPanX;
  TopLeftY := CenterY - (ViewH / 2) - FMapPanY;

  TileXStart := Floor(TopLeftX / 256);
  TileYStart := Floor(TopLeftY / 256);
  TileXEnd := Floor((TopLeftX + ViewW) / 256);
  TileYEnd := Floor((TopLeftY + ViewH) / 256);

  TileLimit := Trunc(Power(2, FMapZoomLevel)) - 1;
  if TileXStart < 0 then TileXStart := 0;
  if TileYStart < 0 then TileYStart := 0;
  if TileXEnd > TileLimit then TileXEnd := TileLimit;
  if TileYEnd > TileLimit then TileYEnd := TileLimit;

  for TileY := TileYStart to TileYEnd do
  begin
    for TileX := TileXStart to TileXEnd do
    begin
      TileLeft := Round(ViewRect.Left + TileX * 256 - TopLeftX);
      TileTop := Round(ViewRect.Top + TileY * 256 - TopLeftY);
      TileFile := FetchTileFile(FMapZoomLevel, TileX, TileY);
      if TileFile <> '' then
      begin
        Pic := TPortableNetworkGraphic.Create;
        try
          Pic.LoadFromFile(TileFile);
          ACanvas.Draw(TileLeft, TileTop, Pic);
        finally
          Pic.Free;
        end;
      end
      else
      begin
        ACanvas.Brush.Color := RGBToColor(229, 229, 226);
        ACanvas.Pen.Color := RGBToColor(210, 210, 205);
        ACanvas.Rectangle(TileLeft, TileTop, TileLeft + 256, TileTop + 256);
      end;
    end;
  end;

  ACanvas.Brush.Style := bsClear;
  ACanvas.Font.Name := 'Segoe UI';
  ACanvas.Font.Size := 8;
  ACanvas.Font.Color := RGBToColor(83, 83, 79);
  ACanvas.TextOut(ViewRect.Left + 8, ViewRect.Bottom - 20,
    Format('OpenStreetMap | Zoom %d', [FMapZoomLevel]));
end;

procedure TfrmMain.ClearView;
begin
  memoDataInfo.Clear;
  memoRoute.Clear;
  memoRouteSummary.Clear;
  lbCities.Clear;
  lbNodes.Clear;
  lbEdges.Clear;
  lbRouteEdges.Clear;
  FLastRouteLoaded := False;
  lblStatus.Caption := 'Status: Ready';
  FMapZoomLevel := 7;
  FMapPanX := 0;
  FMapPanY := 0;
  pbMap.Invalidate;
end;

procedure TfrmMain.LoadDataset;
var
  Phase: string;
begin
  try
    FDataFolder := Trim(edDataFolder.Text);
    if FDataFolder = '' then
      FDataFolder := DefaultDataFolder;

    FNodesFile := IncludeTrailingPathDelimiter(FDataFolder) + 'sp_route_nodes.geojson';
    FEdgesFile := IncludeTrailingPathDelimiter(FDataFolder) + 'sp_route_edges.geojson';
    FCitiesFile := IncludeTrailingPathDelimiter(FDataFolder) + 'sp_cities.geojson';

    ClearView;
    AIRouteGraph1.Clear;
    AIRouteCityIndex1.Clear;
    AIRouteGraph1.SourceFile := FNodesFile;

    if not FileExists(FNodesFile) then
      raise Exception.Create('Nodes file not found: ' + FNodesFile);
    if not FileExists(FEdgesFile) then
      raise Exception.Create('Edges file not found: ' + FEdgesFile);
    if not FileExists(FCitiesFile) then
      raise Exception.Create('Cities file not found: ' + FCitiesFile);

    Phase := 'road nodes';
    AddLog('Loading road nodes...');
    AIGeoJSONRouteImporter1.RouteGraph := AIRouteGraph1;
    AIGeoJSONRouteImporter1.NodesFileName := FNodesFile;
    AIGeoJSONRouteImporter1.EdgesFileName := FEdgesFile;

    if not AIGeoJSONRouteImporter1.ImportNodes then
      raise Exception.Create('Node import failed: ' + AIGeoJSONRouteImporter1.LastError);
    AddLog(Format('Nodes loaded successfully: %d nodes.', [AIRouteGraph1.NodeCount]));

    Phase := 'road edges';
    AddLog('Loading road edges...');
    if not AIGeoJSONRouteImporter1.ImportEdges then
      raise Exception.Create('Edge import failed: ' + AIGeoJSONRouteImporter1.LastError);
    AddLog(Format('Edges loaded successfully: %d edges.', [AIRouteGraph1.EdgeCount]));

    AddLog(Format('Road graph loaded: %d nodes, %d edges.', [
      AIRouteGraph1.NodeCount, AIRouteGraph1.EdgeCount]));

    Phase := 'city index';
    AddLog('Loading city index...');
    if not AIRouteCityIndex1.LoadGeoJSON(FCitiesFile) then
      raise Exception.Create('City load failed: ' + AIRouteCityIndex1.LastError);

    if not AIRouteCityIndex1.ConnectCitiesToGraph(AIRouteGraph1) then
      AddLog('City-to-road connection failed.')
    else
      AddLog(Format('City index loaded: %d cities.', [AIRouteCityIndex1.CityCount]));

    PopulateCityCombos;
    PopulateDataLists;
    RefreshDataSummary;
    UpdateGraphBounds;
    FLastRouteLoaded := False;

    if cbOrigin.Items.Count > 0 then
      cbOrigin.ItemIndex := 0;
    if cbDestination.Items.Count > 1 then
      cbDestination.ItemIndex := 1
    else if cbDestination.Items.Count > 0 then
      cbDestination.ItemIndex := 0;

    RefreshRouteSummary;
    RefreshStatus;
    ResetMapView;
    pbMap.Repaint;
    pbMap.Invalidate;
  except
    on E: Exception do
    begin
      AddLog(Format('LoadDataset failed during %s: %s (%s)', [
        Phase, E.Message, E.ClassName]));
      lblStatus.Caption := 'Status: load failed';
      FLastRouteLoaded := False;
      pbMap.Invalidate;
    end;
  end;
end;

procedure TfrmMain.PopulateCityCombos;
begin
  AIRouteCityIndex1.GetCityNames(cbOrigin.Items);
  cbDestination.Items.Assign(cbOrigin.Items);
end;

procedure TfrmMain.PopulateDataLists;
var
  I: Integer;
  Node: TAIRouteNode;
  Edge: TAIRouteEdge;
  City: TAIRouteCity;
begin
  lbCities.Clear;
  for I := 0 to AIRouteCityIndex1.CityCount - 1 do
  begin
    City := AIRouteCityIndex1.Cities[I];
    lbCities.Items.Add(Format('%s  [node %d]',
      [City.Name, City.NearestNodeIndex]));
  end;

  lbNodes.Clear;
  for I := 0 to AIRouteGraph1.NodeCount - 1 do
  begin
    Node := AIRouteGraph1.Nodes[I];
    lbNodes.Items.Add(Format('%d  %.4f, %.4f',
      [Node.ExternalId, Node.Latitude, Node.Longitude]));
  end;

  lbEdges.Clear;
  for I := 0 to AIRouteGraph1.EdgeCount - 1 do
  begin
    Edge := AIRouteGraph1.Edges[I];
    lbEdges.Items.Add(Format('%d  %s -> %s  %.1f km  %.1f min',
      [Edge.ExternalId, IntToStr(Edge.FromNodeIndex), IntToStr(Edge.ToNodeIndex),
      Edge.DistanceMeters / 1000, Edge.TravelTimeSeconds / 60]));
  end;
end;

procedure TfrmMain.RefreshDataSummary;
begin
  memoDataInfo.Lines.Clear;
  memoDataInfo.Lines.Add('Dataset folder');
  memoDataInfo.Lines.Add(FDataFolder);
  memoDataInfo.Lines.Add('');
  memoDataInfo.Lines.Add('Files');
  memoDataInfo.Lines.Add('Nodes:  ' + FNodesFile);
  memoDataInfo.Lines.Add('Edges:  ' + FEdgesFile);
  memoDataInfo.Lines.Add('Cities: ' + FCitiesFile);
  memoDataInfo.Lines.Add('');
  memoDataInfo.Lines.Add(Format('Graph nodes: %d', [AIRouteGraph1.NodeCount]));
  memoDataInfo.Lines.Add(Format('Graph edges: %d', [AIRouteGraph1.EdgeCount]));
  memoDataInfo.Lines.Add(Format('Cities loaded: %d', [AIRouteCityIndex1.CityCount]));
  memoDataInfo.Lines.Add('Origin and destination are selected from the city list.');
  memoDataInfo.Lines.Add('The route is calculated using the road graph and snap points.');
end;

procedure TfrmMain.RefreshRouteSummary;
var
  OriginCity, DestinationCity: TAIRouteCity;
  I: Integer;
  Edge: TAIRouteEdge;
begin
  memoRoute.Clear;
  memoRouteSummary.Clear;
  lbRouteEdges.Clear;

  OriginCity := CityByCombo(cbOrigin);
  DestinationCity := CityByCombo(cbDestination);

  if Assigned(OriginCity) then
    memoRoute.Lines.Add('Origin: ' + OriginCity.Name);
  if Assigned(DestinationCity) then
    memoRoute.Lines.Add('Destination: ' + DestinationCity.Name);
  memoRoute.Lines.Add('Mode: ' + cbRouteMode.Text);
  memoRoute.Lines.Add('');

  if FLastRouteLoaded and AIRouteCalculator1.LastRoute.Found then
  begin
    memoRouteSummary.Lines.Add(Format('Distance: %.1f km', [
      AIRouteCalculator1.LastRoute.TotalDistanceMeters / 1000]));
    memoRouteSummary.Lines.Add(Format('Estimated time: %.1f min', [
      AIRouteCalculator1.LastRoute.TotalTravelTimeSeconds / 60]));
    memoRouteSummary.Lines.Add(Format('Segments: %d', [Length(AIRouteCalculator1.LastRoute.EdgeIndexes)]));
    memoRouteSummary.Lines.Add(Format('Geometry points: %d', [Length(AIRouteCalculator1.LastRoute.Geometry)]));
    memoRouteSummary.Lines.Add(Format('Calculation time: %d ms', [
      AIRouteCalculator1.LastRoute.CalculationTimeMilliseconds]));
    memoRoute.Lines.Add(Format('Distance: %.1f km', [
      AIRouteCalculator1.LastRoute.TotalDistanceMeters / 1000]));
    memoRoute.Lines.Add(Format('Estimated time: %.1f min', [
      AIRouteCalculator1.LastRoute.TotalTravelTimeSeconds / 60]));
    memoRoute.Lines.Add(Format('Segments: %d', [Length(AIRouteCalculator1.LastRoute.EdgeIndexes)]));
    memoRoute.Lines.Add(Format('Geometry points: %d', [Length(AIRouteCalculator1.LastRoute.Geometry)]));
    memoRoute.Lines.Add('');
    memoRoute.Lines.Add('Route path');

    for I := 0 to High(AIRouteCalculator1.LastRoute.EdgeIndexes) do
    begin
      Edge := AIRouteGraph1.Edges[AIRouteCalculator1.LastRoute.EdgeIndexes[I]];
      lbRouteEdges.Items.Add(Format('%d. %s / %s - %.1f km - %.1f min', [
        I + 1, Edge.RoadName, Edge.RoadReference,
        Edge.DistanceMeters / 1000, Edge.TravelTimeSeconds / 60]));
      memoRoute.Lines.Add(Format('%d. %s / %s', [I + 1, Edge.RoadName, Edge.RoadReference]));
    end;
  end
  else
  begin
    memoRoute.Lines.Add('Select two cities and click Calculate.');
  end;
end;

procedure TfrmMain.RefreshStatus;
begin
  lblStatus.Caption := Format('Status: %s | Graph: %d nodes, %d edges | Cities: %d',
    [cbRouteMode.Text, AIRouteGraph1.NodeCount, AIRouteGraph1.EdgeCount, AIRouteCityIndex1.CityCount]);
end;

function TfrmMain.CityByCombo(const ACombo: TComboBox): TAIRouteCity;
begin
  Result := nil;
  if (ACombo.ItemIndex < 0) or (ACombo.ItemIndex >= AIRouteCityIndex1.CityCount) then
    Exit;
  Result := AIRouteCityIndex1.Cities[ACombo.ItemIndex];
end;

function TfrmMain.SelectedRouteMode: TAIRouteCostMode;
begin
  if cbRouteMode.ItemIndex = 1 then
    Result := rcmShortest
  else
    Result := rcmFastest;
end;

procedure TfrmMain.CalculateRoute;
var
  OriginCity, DestinationCity: TAIRouteCity;
begin
  OriginCity := CityByCombo(cbOrigin);
  DestinationCity := CityByCombo(cbDestination);

  if not Assigned(OriginCity) or not Assigned(DestinationCity) then
  begin
    AddLog('Select valid origin and destination cities.');
    Exit;
  end;

  if OriginCity.NormalizedName = DestinationCity.NormalizedName then
  begin
    AddLog('Origin and destination cannot be the same city.');
    Exit;
  end;

  if (OriginCity.NearestNodeIndex < 0) or (DestinationCity.NearestNodeIndex < 0) then
  begin
    AddLog('One or both cities are not connected to the road graph.');
    Exit;
  end;

  AIRouteCalculator1.RouteGraph := AIRouteGraph1;
  AIRouteCalculator1.SpeedProfile := AIRouteSpeedProfile1;
  AIRouteCalculator1.CostMode := SelectedRouteMode;
  AIRouteCalculator1.Algorithm := raAStar;

  AddLog(Format('Calculating route from %s to %s using %s mode.', [
    OriginCity.Name, DestinationCity.Name, cbRouteMode.Text]));
  AddLog(Format('Origin node: %d | Destination node: %d', [
    OriginCity.NearestNodeIndex, DestinationCity.NearestNodeIndex]));

  if not AIRouteCalculator1.CalculateRoute(
    OriginCity.NearestNodeIndex,
    DestinationCity.NearestNodeIndex) then
  begin
    AddLog('Route calculation failed: ' + AIRouteCalculator1.LastRoute.ErrorMessage);
    FLastRouteLoaded := False;
    RefreshRouteSummary;
    pbMap.Invalidate;
    Exit;
  end;

  FLastRouteLoaded := True;
  AddLog(Format('Route found: %.1f km in %.1f min.', [
    AIRouteCalculator1.LastRoute.TotalDistanceMeters / 1000,
    AIRouteCalculator1.LastRoute.TotalTravelTimeSeconds / 60]));
  AddLog('Calculation time: ' + IntToStr(AIRouteCalculator1.LastRoute.CalculationTimeMilliseconds) + ' ms');
  RefreshRouteSummary;
  pbMap.Invalidate;
end;

procedure TfrmMain.UpdateGraphBounds;
var
  I: Integer;
  Node: TAIRouteNode;
begin
  if AIRouteGraph1.NodeCount = 0 then
  begin
    FGraphMinLat := 0;
    FGraphMaxLat := 1;
    FGraphMinLon := 0;
    FGraphMaxLon := 1;
    Exit;
  end;

  FGraphMinLat := 1.0E30;
  FGraphMaxLat := -1.0E30;
  FGraphMinLon := 1.0E30;
  FGraphMaxLon := -1.0E30;
  for I := 0 to AIRouteGraph1.NodeCount - 1 do
  begin
    Node := AIRouteGraph1.Nodes[I];
    FGraphMinLat := Min(FGraphMinLat, Node.Latitude);
    FGraphMaxLat := Max(FGraphMaxLat, Node.Latitude);
    FGraphMinLon := Min(FGraphMinLon, Node.Longitude);
    FGraphMaxLon := Max(FGraphMaxLon, Node.Longitude);
  end;

  if Abs(FGraphMaxLat - FGraphMinLat) < 0.001 then
    FGraphMaxLat := FGraphMinLat + 0.001;
  if Abs(FGraphMaxLon - FGraphMinLon) < 0.001 then
    FGraphMaxLon := FGraphMinLon + 0.001;

  UpdateMapTransform;
  UpdateMapZoomLabel;
end;

function TfrmMain.GeoToPoint(const ALatitude, ALongitude: Double): TPoint;
var
  ViewRect: TRect;
  CenterX, CenterY: Double;
  WorldX, WorldY: Double;
begin
  ViewRect := MapViewportRect;
  CenterX := (ViewRect.Left + ViewRect.Right) / 2 + FMapPanX;
  CenterY := (ViewRect.Top + ViewRect.Bottom) / 2 + FMapPanY;
  WorldX := LonToWorldX(ALongitude, FMapZoomLevel);
  WorldY := LatToWorldY(ALatitude, FMapZoomLevel);
  Result.X := Round(CenterX + (WorldX - LonToWorldX(FMapCenterLon, FMapZoomLevel)));
  Result.Y := Round(CenterY + (WorldY - LatToWorldY(FMapCenterLat, FMapZoomLevel)));
end;

function TfrmMain.NodeLabel(const AIndex: Integer): string;
var
  I: Integer;
  Node: TAIRouteNode;
begin
  Result := IntToStr(AIndex);
  for I := 0 to AIRouteCityIndex1.CityCount - 1 do
  begin
    if AIRouteCityIndex1.Cities[I].NearestNodeIndex = AIndex then
      Exit(AIRouteCityIndex1.Cities[I].Name);
  end;
  Node := AIRouteGraph1.Nodes[AIndex];
  Result := IntToStr(Node.ExternalId);
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
  ACanvas.Pen.Style := psSolid;
end;

procedure TfrmMain.DrawNode(ACanvas: TCanvas; const APoint: TPoint; const AText: string;
  const AColor: TColor; const ARadius: Integer);
begin
  ACanvas.Brush.Color := AColor;
  ACanvas.Brush.Style := bsSolid;
  ACanvas.Pen.Color := clWhite;
  ACanvas.Pen.Style := psSolid;
  ACanvas.Ellipse(APoint.X - ARadius, APoint.Y - ARadius,
    APoint.X + ARadius, APoint.Y + ARadius);
  ACanvas.Font.Size := 8;
  ACanvas.Font.Color := clBlack;
  ACanvas.TextOut(APoint.X + ARadius + 2, APoint.Y - 4, AText);
end;

procedure TfrmMain.DrawGraph(ACanvas: TCanvas);
var
  I: Integer;
  J: Integer;
  Node: TAIRouteNode;
  Edge: TAIRouteEdge;
  P1, P2: TPoint;
  RoutePoints: array of TPoint;
  OriginCity, DestinationCity: TAIRouteCity;
begin
  DrawMapBackground(ACanvas);

  if AIRouteGraph1.NodeCount = 0 then
  begin
    ACanvas.Font.Color := clGrayText;
    ACanvas.TextOut(24, 24, 'Load the route dataset to view the road graph.');
    Exit;
  end;

  ACanvas.Font.Name := 'Segoe UI';
  ACanvas.Font.Size := 8;

  for I := 0 to AIRouteGraph1.EdgeCount - 1 do
  begin
    Edge := AIRouteGraph1.Edges[I];
    if Length(Edge.Geometry) >= 2 then
    begin
      SetLength(RoutePoints, Length(Edge.Geometry));
      for J := 0 to High(Edge.Geometry) do
        RoutePoints[J] := GeoToPoint(Edge.Geometry[J].Latitude,
          Edge.Geometry[J].Longitude);
      ACanvas.Pen.Color := RoadColor(Edge.HighwayType);
      ACanvas.Pen.Width := RoadWidth(Edge.HighwayType);
      ACanvas.Polyline(RoutePoints);
    end
    else
    begin
      P1 := GeoToPoint(AIRouteGraph1.Nodes[Edge.FromNodeIndex].Latitude,
        AIRouteGraph1.Nodes[Edge.FromNodeIndex].Longitude);
      P2 := GeoToPoint(AIRouteGraph1.Nodes[Edge.ToNodeIndex].Latitude,
        AIRouteGraph1.Nodes[Edge.ToNodeIndex].Longitude);
      ACanvas.Pen.Color := RoadColor(Edge.HighwayType);
      ACanvas.Pen.Width := RoadWidth(Edge.HighwayType);
      ACanvas.Line(P1, P2);
    end;
  end;

  if FLastRouteLoaded and AIRouteCalculator1.LastRoute.Found and
    (Length(AIRouteCalculator1.LastRoute.Geometry) > 0) then
  begin
    SetLength(RoutePoints, Length(AIRouteCalculator1.LastRoute.Geometry));
    for I := 0 to High(AIRouteCalculator1.LastRoute.Geometry) do
      RoutePoints[I] := GeoToPoint(
        AIRouteCalculator1.LastRoute.Geometry[I].Latitude,
        AIRouteCalculator1.LastRoute.Geometry[I].Longitude);

    ACanvas.Pen.Color := RGBToColor(214, 54, 54);
    ACanvas.Pen.Width := 4;
    ACanvas.Polyline(RoutePoints);
  end;

  OriginCity := CityByCombo(cbOrigin);
  DestinationCity := CityByCombo(cbDestination);

  for I := 0 to AIRouteGraph1.NodeCount - 1 do
  begin
    Node := AIRouteGraph1.Nodes[I];
    P1 := GeoToPoint(Node.Latitude, Node.Longitude);
    if Assigned(OriginCity) and (OriginCity.NearestNodeIndex = I) then
      DrawNode(ACanvas, P1, 'Origin', RGBToColor(74, 158, 84), 8)
    else if Assigned(DestinationCity) and (DestinationCity.NearestNodeIndex = I) then
      DrawNode(ACanvas, P1, 'Destination', RGBToColor(221, 128, 53), 8)
    else if (FLastRouteLoaded and AIRouteCalculator1.LastRoute.Found) and
      ((I = AIRouteCalculator1.LastRoute.OriginNodeIndex) or
       (I = AIRouteCalculator1.LastRoute.DestinationNodeIndex)) then
      DrawNode(ACanvas, P1, NodeLabel(I), RGBToColor(102, 147, 255), 6)
    else if FMapZoomLevel >= 11 then
      DrawNode(ACanvas, P1, NodeLabel(I), RGBToColor(103, 118, 136), 3)
    else
    begin
      DrawNode(ACanvas, P1, '', RGBToColor(100, 111, 126), 4);
    end;
  end;

  ACanvas.Font.Style := [fsBold];
  ACanvas.Font.Color := RGBToColor(40, 40, 40);
  ACanvas.TextOut(24, 16, 'Route Graph Road Preview');
  ACanvas.Font.Style := [];
  ACanvas.Font.Color := RGBToColor(89, 96, 102);
  ACanvas.TextOut(24, 34, Format('Nodes: %d   Edges: %d   Zoom: %d',
    [AIRouteGraph1.NodeCount, AIRouteGraph1.EdgeCount, FMapZoomLevel]));
end;

end.
