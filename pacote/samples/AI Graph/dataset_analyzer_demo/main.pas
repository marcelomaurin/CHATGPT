unit main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Math, Types, Forms, Controls, Graphics, Dialogs, ExtCtrls,
  StdCtrls, ComCtrls, fpjson, jsonparser, aigraphmap;

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
    btnAnalyze: TButton;
    btnClearSelection: TButton;
    btnExportReport: TButton;
    btnGenerateReport: TButton;
    btnLoadDataset: TButton;
    btnSelectAll: TButton;
    edDatasetPath: TEdit;
    lblAnalyzeHint: TLabel;
    lblCategories: TLabel;
    lblDatasetPath: TLabel;
    lblDishCount: TLabel;
    lblIngredientCount: TLabel;
    lblIngredients: TLabel;
    lblLoadInfo: TLabel;
    lblRelationCount: TLabel;
    lblRelations: TLabel;
    lblSelectedCount: TLabel;
    lbAnalysisNodes: TListBox;
    lbCategories: TListBox;
    lbDishes: TListBox;
    lbIngredients: TListBox;
    lbRanking: TListBox;
    lbRelations: TListBox;
    memoAnalysis: TMemo;
    memoLoadInfo: TMemo;
    memoReport: TMemo;
    pcMain: TPageControl;
    pbGraph: TPaintBox;
    pnlAnalyzeLeft: TPanel;
    pnlAnalyzeRight: TPanel;
    pnlAnalyzeTop: TPanel;
    pnlLoadLeft: TPanel;
    pnlLoadRight: TPanel;
    pnlLoadTop: TPanel;
    pnlReportTop: TPanel;
    sdReport: TSaveDialog;
    tsAnalyze: TTabSheet;
    tsLoad: TTabSheet;
    tsReport: TTabSheet;
    procedure btnAnalyzeClick(Sender: TObject);
    procedure btnClearSelectionClick(Sender: TObject);
    procedure btnExportReportClick(Sender: TObject);
    procedure btnGenerateReportClick(Sender: TObject);
    procedure btnLoadDatasetClick(Sender: TObject);
    procedure btnSelectAllClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure lbAnalysisNodesClick(Sender: TObject);
    procedure pbGraphPaint(Sender: TObject);
  private
    FIngredientItems: TStringList;
    FDishItems: TStringList;
    FRelationItems: TStringList;
    FLastAnalysisQuery: string;
    FLastAnalysisRanking: TStringList;
    FLastAnalysisExplanation: TStringList;
    FLastReportText: TStringList;
    function DatasetPath: string;
    procedure ClearDatasetState;
    procedure DrawArrow(ACanvas: TCanvas; const X1, Y1, X2, Y2: Integer;
      AColor: TColor; AWidth: Integer);
    function EdgeColor(const AEdge: TAIGraphEdge): TColor;
    procedure GenerateAnalysis;
    procedure GenerateReport;
    procedure LoadDataset;
    procedure LoadDatasetFromFile(const AFileName: string);
    function NodeFillColor(ANode: TAIGraphNode): TColor;
    function SelectedIngredientQuery: string;
    procedure PopulateLoadTab;
    procedure PopulateAnalysisNodes;
    procedure RefreshGraph;
    procedure RenderGraph(ACanvas: TCanvas);
    function TruncatedText(const AText: string; AMaxLen: Integer): string;
    procedure UpdateSelectedCount;
  public

  end;

var
  frmMain: TfrmMain;

implementation

{$R *.lfm}

const
  SAMPLE_DATASET_FILE = 'dataset.json';

{ TfrmMain }

procedure TfrmMain.FormCreate(Sender: TObject);
begin
  DoubleBuffered := True;
  pcMain.ActivePage := tsLoad;

  FIngredientItems := TStringList.Create;
  FIngredientItems.Sorted := True;
  FIngredientItems.Duplicates := dupIgnore;

  FDishItems := TStringList.Create;
  FDishItems.Sorted := True;
  FDishItems.Duplicates := dupIgnore;

  FRelationItems := TStringList.Create;
  FRelationItems.Sorted := False;

  FLastAnalysisRanking := TStringList.Create;
  FLastAnalysisExplanation := TStringList.Create;
  FLastReportText := TStringList.Create;

  edDatasetPath.Text := DatasetPath;
  lbAnalysisNodes.MultiSelect := True;
  lbAnalysisNodes.ExtendedSelect := True;
  sdReport.Title := 'Save report';
  sdReport.DefaultExt := '.txt';
  sdReport.Filter := 'Text files (*.txt)|*.txt|All files (*.*)|*.*';

  LoadDataset;
end;

procedure TfrmMain.FormDestroy(Sender: TObject);
begin
  FLastReportText.Free;
  FLastAnalysisExplanation.Free;
  FLastAnalysisRanking.Free;
  FRelationItems.Free;
  FDishItems.Free;
  FIngredientItems.Free;
end;

procedure TfrmMain.btnLoadDatasetClick(Sender: TObject);
begin
  LoadDataset;
end;

procedure TfrmMain.btnAnalyzeClick(Sender: TObject);
begin
  GenerateAnalysis;
  pcMain.ActivePage := tsAnalyze;
end;

procedure TfrmMain.btnGenerateReportClick(Sender: TObject);
begin
  if FLastAnalysisQuery = '' then
    GenerateAnalysis;
  GenerateReport;
  pcMain.ActivePage := tsReport;
end;

procedure TfrmMain.btnExportReportClick(Sender: TObject);
begin
  if FLastReportText.Count = 0 then
    GenerateReport;
  if FLastReportText.Count = 0 then
    Exit;

  sdReport.FileName := 'dataset_report.txt';
  if not sdReport.Execute then
    Exit;

  FLastReportText.SaveToFile(sdReport.FileName);
  memoReport.Lines.Assign(FLastReportText);
end;

procedure TfrmMain.btnSelectAllClick(Sender: TObject);
var
  I: Integer;
begin
  for I := 0 to lbAnalysisNodes.Count - 1 do
    lbAnalysisNodes.Selected[I] := True;
  UpdateSelectedCount;
end;

procedure TfrmMain.btnClearSelectionClick(Sender: TObject);
var
  I: Integer;
begin
  for I := 0 to lbAnalysisNodes.Count - 1 do
    lbAnalysisNodes.Selected[I] := False;
  UpdateSelectedCount;
end;

procedure TfrmMain.lbAnalysisNodesClick(Sender: TObject);
begin
  UpdateSelectedCount;
end;

procedure TfrmMain.pbGraphPaint(Sender: TObject);
begin
  RenderGraph(pbGraph.Canvas);
end;

procedure TfrmMain.ClearDatasetState;
begin
  AIGraphMap1.ClearTraining;
  AIGraphMap1.ClearGraph;

  FIngredientItems.Clear;
  FDishItems.Clear;
  FRelationItems.Clear;
  FLastAnalysisQuery := '';
  FLastAnalysisRanking.Clear;
  FLastAnalysisExplanation.Clear;
  FLastReportText.Clear;

  lbIngredients.Clear;
  lbCategories.Clear;
  lbRelations.Clear;
  lbAnalysisNodes.Clear;
  lbRanking.Clear;
  memoLoadInfo.Clear;
  memoAnalysis.Clear;
  memoReport.Clear;

  lblIngredientCount.Caption := 'Ingredients: 0';
  lblDishCount.Caption := 'Dishes: 0';
  lblRelationCount.Caption := 'Relations: 0';
  lblSelectedCount.Caption := 'Selected nodes: 0';
end;

function TfrmMain.DatasetPath: string;
begin
  Result := IncludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0))) +
    SAMPLE_DATASET_FILE;
end;

procedure TfrmMain.LoadDataset;
begin
  edDatasetPath.Text := DatasetPath;
  if not FileExists(edDatasetPath.Text) then
  begin
    ClearDatasetState;
    memoLoadInfo.Lines.Add('Dataset file not found: ' + edDatasetPath.Text);
    memoLoadInfo.Lines.Add('Place dataset.json in the sample folder and load again.');
    RefreshGraph;
    Exit;
  end;

  try
    LoadDatasetFromFile(edDatasetPath.Text);
  except
    on E: Exception do
    begin
      ClearDatasetState;
      memoLoadInfo.Lines.Add('Load failed: ' + E.Message);
    end;
  end;
end;

procedure TfrmMain.LoadDatasetFromFile(const AFileName: string);
var
  SL: TStringList;
  Data: TJSONData;
  Root: TJSONObject;
  ItemsData: TJSONData;
  ItemsArr: TJSONArray;
  ItemObj: TJSONObject;
  IngredientData: TJSONData;
  IngredientArr: TJSONArray;
  DishName: string;
  Ingredient: string;
  Weight: Double;
  I, J: Integer;
  DishIngredients: TStringList;
  AddedRelations: Integer;
  TrainItem: TAITrainingItem;
begin
  ClearDatasetState;

  SL := TStringList.Create;
  DishIngredients := TStringList.Create;
  DishIngredients.Sorted := True;
  DishIngredients.Duplicates := dupIgnore;
  try
    SL.LoadFromFile(AFileName);
    Data := GetJSON(SL.Text);
    try
      if not (Data is TJSONObject) then
        raise Exception.Create('Dataset root must be a JSON object.');

      Root := TJSONObject(Data);
      ItemsData := Root.Find('items');
      if not Assigned(ItemsData) or not (ItemsData is TJSONArray) then
        raise Exception.Create('Dataset must contain an "items" array.');

      ItemsArr := TJSONArray(ItemsData);
      if ItemsArr.Count = 0 then
        raise Exception.Create('Dataset contains no dishes.');

      AddedRelations := 0;
      memoLoadInfo.Lines.Add('Dataset loaded from: ' + ExtractFileName(AFileName));
      memoLoadInfo.Lines.Add('Validating dishes and ingredient links...');

      for I := 0 to ItemsArr.Count - 1 do
      begin
        if not (ItemsArr.Items[I] is TJSONObject) then
          raise Exception.CreateFmt('Item %d is not a JSON object.', [I + 1]);

        ItemObj := TJSONObject(ItemsArr.Items[I]);
        DishName := Trim(ItemObj.Get('dish', ''));
        if DishName = '' then
          DishName := Trim(ItemObj.Get('category', ''));
        if DishName = '' then
          raise Exception.CreateFmt('Item %d is missing the dish name.', [I + 1]);

        if FDishItems.IndexOf(DishName) < 0 then
          FDishItems.Add(DishName);

        IngredientData := ItemObj.Find('ingredients');
        if not Assigned(IngredientData) or not (IngredientData is TJSONArray) then
          raise Exception.CreateFmt('Dish "%s" has no ingredient list.', [DishName]);

        IngredientArr := TJSONArray(IngredientData);
        DishIngredients.Clear;

        for J := 0 to IngredientArr.Count - 1 do
        begin
          Ingredient := Trim(IngredientArr.Items[J].AsString);
          if Ingredient = '' then
            Continue;

          if DishIngredients.IndexOf(Ingredient) >= 0 then
            Continue;
          DishIngredients.Add(Ingredient);

          if FIngredientItems.IndexOf(Ingredient) < 0 then
            FIngredientItems.Add(Ingredient);

          Weight := 1.0;
          if ItemObj.Find('weight') <> nil then
            Weight := ItemObj.Get('weight', 1.0);

          TrainItem := AIGraphMap1.Training.Add;
          TrainItem.InputText := Ingredient;
          TrainItem.OutputCategory := DishName;
          TrainItem.Weight := Weight;

          FRelationItems.Add(Ingredient + ' -> ' + DishName);
          Inc(AddedRelations);
        end;
      end;

      if FDishItems.Count < 50 then
        raise Exception.CreateFmt('The dataset must contain at least 50 dishes. Found %d.', [FDishItems.Count]);
      if FIngredientItems.Count = 0 then
        raise Exception.Create('No ingredients were loaded.');

      AIGraphMap1.Train;

      memoLoadInfo.Lines.Add(Format('Dishes validated: %d', [FDishItems.Count]));
      memoLoadInfo.Lines.Add(Format('Unique ingredients: %d', [FIngredientItems.Count]));
      memoLoadInfo.Lines.Add(Format('Relations created: %d', [AddedRelations]));
      memoLoadInfo.Lines.Add('The analysis tab starts with the first ingredients preselected.');
      PopulateLoadTab;
      PopulateAnalysisNodes;
      RefreshGraph;
    finally
      Data.Free;
    end;
  finally
    DishIngredients.Free;
    SL.Free;
  end;
end;

procedure TfrmMain.PopulateLoadTab;
begin
  lbIngredients.Items.Assign(FIngredientItems);
  lbCategories.Items.Assign(FDishItems);
  lbRelations.Items.Assign(FRelationItems);

  lblIngredientCount.Caption := Format('Ingredients: %d', [FIngredientItems.Count]);
  lblDishCount.Caption := Format('Dishes: %d', [FDishItems.Count]);
  lblRelationCount.Caption := Format('Relations: %d', [FRelationItems.Count]);

  memoLoadInfo.Lines.Add('');
  memoLoadInfo.Lines.Add('Load status: ready');
  memoLoadInfo.Lines.Add('Nodes are ingredients.');
  memoLoadInfo.Lines.Add('Categories are dishes.');
  memoLoadInfo.Lines.Add('Each ingredient is linked to the dishes that use it.');
end;

procedure TfrmMain.PopulateAnalysisNodes;
var
  I, MaxSelect: Integer;
begin
  lbAnalysisNodes.Items.Assign(FIngredientItems);
  for I := 0 to lbAnalysisNodes.Count - 1 do
    lbAnalysisNodes.Selected[I] := False;

  MaxSelect := Min(5, lbAnalysisNodes.Count);
  for I := 0 to MaxSelect - 1 do
    lbAnalysisNodes.Selected[I] := True;

  UpdateSelectedCount;
end;

function TfrmMain.SelectedIngredientQuery: string;
var
  I: Integer;
begin
  Result := '';
  for I := 0 to lbAnalysisNodes.Count - 1 do
  begin
    if not lbAnalysisNodes.Selected[I] then
      Continue;
    if Result <> '' then
      Result += ' ';
    Result += lbAnalysisNodes.Items[I];
  end;
end;

procedure TfrmMain.UpdateSelectedCount;
var
  I, CountSelected: Integer;
begin
  CountSelected := 0;
  for I := 0 to lbAnalysisNodes.Count - 1 do
    if lbAnalysisNodes.Selected[I] then
      Inc(CountSelected);
  lblSelectedCount.Caption := Format('Selected nodes: %d', [CountSelected]);
end;

procedure TfrmMain.GenerateAnalysis;
var
  Query: string;
  I, MaxItems: Integer;
  Line, CatName, ValueText: string;
  ScorePos: Integer;
  Score: Double;
begin
  Query := Trim(SelectedIngredientQuery);
  FLastAnalysisQuery := Query;
  FLastAnalysisRanking.Clear;
  FLastAnalysisExplanation.Clear;
  lbRanking.Clear;
  memoAnalysis.Clear;

  if Query = '' then
  begin
    memoAnalysis.Lines.Add('Select at least one ingredient on the Analysis tab.');
    Exit;
  end;

  AIGraphMap1.PredictRanking(Query, FLastAnalysisRanking);
  AIGraphMap1.ExplainPrediction(Query, FLastAnalysisExplanation);

  memoAnalysis.Lines.Add('Selected ingredients:');
  memoAnalysis.Lines.Add(Query);
  memoAnalysis.Lines.Add('');
  memoAnalysis.Lines.Add('Explanation:');
  memoAnalysis.Lines.AddStrings(FLastAnalysisExplanation);

  lbRanking.Items.Add('Top 5 matching categories:');
  MaxItems := Min(5, FLastAnalysisRanking.Count);
  for I := 0 to MaxItems - 1 do
  begin
    Line := FLastAnalysisRanking[I];
    ScorePos := Pos('=', Line);
    if ScorePos > 0 then
    begin
      CatName := Trim(Copy(Line, 1, ScorePos - 1));
      ValueText := Trim(Copy(Line, ScorePos + 1, MaxInt));
      Score := StrToFloatDef(StringReplace(ValueText, '%', '', [rfReplaceAll]), 0.0);
      lbRanking.Items.Add(Format('%d. %s - %s%% similarity', [
        I + 1,
        CatName,
        FormatFloat('0.0', Score)
      ]));
    end
    else
      lbRanking.Items.Add(Format('%d. %s', [I + 1, Line]));
  end;

  if MaxItems = 0 then
    lbRanking.Items.Add('No category ranking could be generated.');

  pcMain.ActivePage := tsAnalyze;
end;

procedure TfrmMain.GenerateReport;
var
  I, MaxItems, ScorePos: Integer;
  Line, CatName, ValueText: string;
  Score: Double;
begin
  if FLastAnalysisQuery = '' then
    GenerateAnalysis;

  FLastReportText.Clear;
  FLastReportText.Add('Dataset Analyzer Report');
  FLastReportText.Add('Dataset file: ' + edDatasetPath.Text);
  FLastReportText.Add(Format('Dishes: %d', [FDishItems.Count]));
  FLastReportText.Add(Format('Ingredients: %d', [FIngredientItems.Count]));
  FLastReportText.Add(Format('Relations: %d', [FRelationItems.Count]));
  FLastReportText.Add('');
  FLastReportText.Add('Selected ingredients:');
  FLastReportText.Add(FLastAnalysisQuery);
  FLastReportText.Add('');
  FLastReportText.Add('Top 5 categories by similarity:');

  MaxItems := Min(5, FLastAnalysisRanking.Count);
  for I := 0 to MaxItems - 1 do
  begin
    Line := FLastAnalysisRanking[I];
    ScorePos := Pos('=', Line);
    if ScorePos > 0 then
    begin
      CatName := Trim(Copy(Line, 1, ScorePos - 1));
      ValueText := Trim(Copy(Line, ScorePos + 1, MaxInt));
      Score := StrToFloatDef(StringReplace(ValueText, '%', '', [rfReplaceAll]), 0.0);
      FLastReportText.Add(Format('%d. %s - %s%% similarity', [
        I + 1,
        CatName,
        FormatFloat('0.0', Score)
      ]));
    end
    else
      FLastReportText.Add(Format('%d. %s', [I + 1, Line]));
  end;

  if MaxItems = 0 then
    FLastReportText.Add('No ranking available.');

  FLastReportText.Add('');
  FLastReportText.Add('Analysis notes:');
  if FLastAnalysisExplanation.Count > 0 then
    FLastReportText.AddStrings(FLastAnalysisExplanation)
  else
    FLastReportText.Add('No explanation available.');

  memoReport.Lines.Assign(FLastReportText);
  pcMain.ActivePage := tsReport;
end;

function TfrmMain.NodeFillColor(ANode: TAIGraphNode): TColor;
begin
  if ANode.NodeType = ntCategory then
    Result := RGBToColor(198, 224, 255)
  else
    Result := RGBToColor(255, 241, 214);
end;

function TfrmMain.EdgeColor(const AEdge: TAIGraphEdge): TColor;
begin
  if AEdge.Weight >= 3 then
    Exit(RGBToColor(220, 70, 70));
  if AEdge.Weight >= 2 then
    Exit(RGBToColor(119, 102, 212));
  Result := RGBToColor(96, 113, 128);
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

function TfrmMain.TruncatedText(const AText: string; AMaxLen: Integer): string;
begin
  if Length(AText) <= AMaxLen then
    Exit(AText);
  Result := Copy(AText, 1, AMaxLen - 1) + '…';
end;

procedure TfrmMain.RefreshGraph;
begin
  pbGraph.Invalidate;
end;

procedure TfrmMain.RenderGraph(ACanvas: TCanvas);
const
  MAX_VISIBLE_PER_SIDE = 18;
var
  W, H: Integer;
  TokenNodes, CategoryNodes: TList;
  Layouts: array of TNodeLayout;
  I, J, K, VisibleCount: Integer;
  Node: TAIGraphNode;
  Edge: TAIGraphEdge;
  NodeWidth, NodeHeight: Integer;
  LeftX, RightX, TopY, BottomY, YPos: Integer;
  SrcLayout, DstLayout: PNodeLayout;
  SrcPoint, DstPoint: TPoint;
  NodeRect: TRect;
  LabelRect: TRect;
  GroupCount: Integer;

  function CompareNodes(A, B: TAIGraphNode): Integer;
  begin
    if A.Weight > B.Weight then
      Exit(-1);
    if A.Weight < B.Weight then
      Exit(1);
    Result := CompareText(A.Text, B.Text);
  end;

  procedure SortNodes(AList: TList);
  var
    M, N: Integer;
    ANode, BNode: TAIGraphNode;
  begin
    for M := 0 to AList.Count - 2 do
      for N := M + 1 to AList.Count - 1 do
      begin
        ANode := TAIGraphNode(AList[M]);
        BNode := TAIGraphNode(AList[N]);
        if CompareNodes(ANode, BNode) > 0 then
        begin
          AList[M] := BNode;
          AList[N] := ANode;
        end;
      end;
  end;

  function FindLayout(AId: Integer): PNodeLayout;
  var
    L: Integer;
  begin
    Result := nil;
    for L := Low(Layouts) to High(Layouts) do
      if Assigned(Layouts[L].Node) and (Layouts[L].Node.Id = AId) then
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

  procedure DrawNode(const L: TNodeLayout);
  var
    R: TRect;
  begin
    R := L.Bounds;
    ACanvas.Brush.Color := NodeFillColor(L.Node);
    ACanvas.Pen.Color := RGBToColor(102, 115, 132);
    ACanvas.RoundRect(R.Left, R.Top, R.Right, R.Bottom, 14, 14);

    ACanvas.Font.Name := 'Segoe UI';
    ACanvas.Font.Size := 9;
    ACanvas.Font.Color := clBlack;
    ACanvas.Font.Style := [fsBold];
    LabelRect := R;
    InflateRect(LabelRect, -8, -8);
    ACanvas.TextRect(LabelRect, LabelRect.Left, LabelRect.Top + 2,
      TruncatedText(L.Node.Text, 24));

    ACanvas.Font.Style := [];
    ACanvas.Font.Color := clGrayText;
    ACanvas.TextRect(LabelRect, LabelRect.Left, LabelRect.Top + 18,
      Format('ID %d  Weight %.1f', [L.Node.Id, L.Node.Weight]));
  end;

begin
  W := pbGraph.ClientWidth;
  H := pbGraph.ClientHeight;

  ACanvas.Brush.Color := RGBToColor(249, 248, 244);
  ACanvas.FillRect(Rect(0, 0, W, H));

  if AIGraphMap1.NodeCount = 0 then
  begin
    ACanvas.Font.Color := clGrayText;
    ACanvas.Font.Size := 11;
    ACanvas.TextOut(24, 24, 'Load the dataset to preview the ingredient-to-dish graph.');
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

    SortNodes(TokenNodes);
    SortNodes(CategoryNodes);

    while TokenNodes.Count > MAX_VISIBLE_PER_SIDE do
      TokenNodes.Delete(TokenNodes.Count - 1);
    while CategoryNodes.Count > MAX_VISIBLE_PER_SIDE do
      CategoryNodes.Delete(CategoryNodes.Count - 1);

    VisibleCount := TokenNodes.Count + CategoryNodes.Count;
    Layouts := nil;
    SetLength(Layouts, VisibleCount);
    if Length(Layouts) > 0 then
      FillChar(Layouts[0], Length(Layouts) * SizeOf(TNodeLayout), 0);

    NodeWidth := 180;
    NodeHeight := 42;
    TopY := 70;
    BottomY := H - 30;
    LeftX := 170;
    RightX := W - 170;

    ACanvas.Font.Name := 'Segoe UI';
    ACanvas.Font.Size := 10;
    GroupCount := 0;

    for I := 0 to TokenNodes.Count - 1 do
    begin
      Node := TAIGraphNode(TokenNodes[I]);
      if TokenNodes.Count = 1 then
        YPos := (TopY + BottomY) div 2
      else
        YPos := TopY + Round((BottomY - TopY) * (I / (TokenNodes.Count - 1)));

      NodeRect := Rect(
        LeftX - (NodeWidth div 2),
        YPos - (NodeHeight div 2),
        LeftX + (NodeWidth div 2),
        YPos + (NodeHeight div 2)
      );

      Layouts[GroupCount].Node := Node;
      Layouts[GroupCount].Bounds := NodeRect;
      Layouts[GroupCount].Center := Point(LeftX, YPos);
      Inc(GroupCount);
    end;

    for I := 0 to CategoryNodes.Count - 1 do
    begin
      Node := TAIGraphNode(CategoryNodes[I]);
      if CategoryNodes.Count = 1 then
        YPos := (TopY + BottomY) div 2
      else
        YPos := TopY + Round((BottomY - TopY) * (I / (CategoryNodes.Count - 1)));

      NodeRect := Rect(
        RightX - (NodeWidth div 2),
        YPos - (NodeHeight div 2),
        RightX + (NodeWidth div 2),
        YPos + (NodeHeight div 2)
      );

      Layouts[GroupCount].Node := Node;
      Layouts[GroupCount].Bounds := NodeRect;
      Layouts[GroupCount].Center := Point(RightX, YPos);
      Inc(GroupCount);
    end;

    for I := 0 to AIGraphMap1.Edges.Count - 1 do
    begin
      Edge := TAIGraphEdge(AIGraphMap1.Edges[I]);
      SrcLayout := FindLayout(Edge.FromNodeId);
      DstLayout := FindLayout(Edge.ToNodeId);
      if (SrcLayout = nil) or (DstLayout = nil) then
        Continue;

      SrcPoint := BorderPoint(SrcLayout^.Center, DstLayout^.Center, SrcLayout^.Bounds);
      DstPoint := BorderPoint(DstLayout^.Center, SrcLayout^.Center, DstLayout^.Bounds);
      DrawArrow(ACanvas, SrcPoint.X, SrcPoint.Y, DstPoint.X, DstPoint.Y,
        EdgeColor(Edge), Max(1, Min(4, Round(Edge.Weight))));
    end;

    for I := 0 to High(Layouts) do
      if Assigned(Layouts[I].Node) then
        DrawNode(Layouts[I]);

    ACanvas.Brush.Style := bsClear;
    ACanvas.Font.Color := clBlack;
    ACanvas.Font.Size := 11;
    ACanvas.Font.Style := [fsBold];
    ACanvas.TextOut(24, 16, 'Ingredient to Dish Graph');
    ACanvas.Font.Style := [];
    ACanvas.Font.Color := clGrayText;
    ACanvas.TextOut(24, 34, Format('Nodes: %d   Edges: %d   Preview limited to %d nodes per side',
      [AIGraphMap1.NodeCount, AIGraphMap1.EdgeCount, MAX_VISIBLE_PER_SIDE]));
  finally
    CategoryNodes.Free;
    TokenNodes.Free;
  end;
end;

end.
