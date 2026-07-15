unit main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Math, Types, fpjson, jsonparser, Forms, Controls, Graphics,
  Dialogs, ExtCtrls, StdCtrls, ComCtrls, aigraphmap, aitrainingexporter;

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
    AITrainingExporter1: TAITrainingExporter;
    btnBrowseDataset: TButton;
    btnExport: TButton;
    btnLoadDataset: TButton;
    btnValidate: TButton;
    cbExportFormat: TComboBox;
    cbVectorization: TComboBox;
    chkOneHotOutput: TCheckBox;
    chkOverwrite: TCheckBox;
    edDatasetPath: TEdit;
    edTargetFile: TEdit;
    lblCategories: TLabel;
    lblCategoriesCaption: TLabel;
    lblDatasetPath: TLabel;
    lblExportFormat: TLabel;
    lblIngredients: TLabel;
    lblIngredientsCaption: TLabel;
    lblPairs: TLabel;
    lblPairsCaption: TLabel;
    lblStatus: TLabel;
    lblTargetFile: TLabel;
    lblTokens: TLabel;
    lblTokensCaption: TLabel;
    lblValidation: TLabel;
    lblValidationCaption: TLabel;
    lbCategories: TListBox;
    lbIngredients: TListBox;
    lbRelations: TListBox;
    memoExportInfo: TMemo;
    memoLoadInfo: TMemo;
    memoLog: TMemo;
    memoReport: TMemo;
    odDataset: TOpenDialog;
    pcMain: TPageControl;
    pbGraph: TPaintBox;
    pnlExportActions: TPanel;
    pnlExportBottom: TPanel;
    pnlExportLeft: TPanel;
    pnlExportRight: TPanel;
    pnlHeader: TPanel;
    pnlReportBottom: TPanel;
    pnlReportTop: TPanel;
    pnlSourceBottom: TPanel;
    pnlSourceLeft: TPanel;
    pnlSourceRight: TPanel;
    pnlSourceTop: TPanel;
    sdExport: TSaveDialog;
    tsExport: TTabSheet;
    tsReport: TTabSheet;
    tsSource: TTabSheet;
    procedure btnBrowseDatasetClick(Sender: TObject);
    procedure btnExportClick(Sender: TObject);
    procedure btnLoadDatasetClick(Sender: TObject);
    procedure btnValidateClick(Sender: TObject);
    procedure cbExportFormatChange(Sender: TObject);
    procedure cbVectorizationChange(Sender: TObject);
    procedure chkOneHotOutputChange(Sender: TObject);
    procedure chkOverwriteChange(Sender: TObject);
    procedure edDatasetPathChange(Sender: TObject);
    procedure edTargetFileChange(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure pbGraphPaint(Sender: TObject);
  private
    FCategories: TStringList;
    FIngredients: TStringList;
    FRelations: TStringList;
    FLastExportMessage: string;
    FLastValidationMessage: string;
    FReportLines: TStringList;
    function BuildDefaultDatasetPath: string;
    function BuildDefaultExportFileName: string;
    function CurrentExportFormat: TAIExportFormat;
    function CurrentVectorizationMode: TAIVectorizationMode;
    function ExportExtension(AFormat: TAIExportFormat): string;
    function ExportFormatDisplayName(AFormat: TAIExportFormat): string;
    function SelectedDatasetFile: string;
    function SelectedFormatText: string;
    function VectorizationDisplayName(AMode: TAIVectorizationMode): string;
    procedure AddLog(const AMsg: string);
    procedure ClearDatasetState;
    procedure LoadDataset;
    procedure LoadDatasetFromFile(const AFileName: string);
    procedure PopulateSourceLists;
    procedure RefreshExportSettings;
    procedure RefreshGraph;
    procedure RefreshReport;
    procedure RefreshStats;
    procedure RenderGraph(ACanvas: TCanvas);
    function NodeFillColor(ANode: TAIGraphNode): TColor;
    function EdgeColor(const AEdge: TAIGraphEdge): TColor;
    procedure DrawArrow(ACanvas: TCanvas; const X1, Y1, X2, Y2: Integer;
      AColor: TColor; AWidth: Integer);
    function TruncatedText(const AText: string; AMaxLen: Integer): string;
    procedure UpdateStatusCaption;
    procedure SyncTargetFileName;
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

  cbExportFormat.Items.Clear;
  cbExportFormat.Items.Add('CSV');
  cbExportFormat.Items.Add('CSV Ranking');
  cbExportFormat.Items.Add('JSON');
  cbExportFormat.Items.Add('JSONL');
  cbExportFormat.Items.Add('CSV Numeric');
  cbExportFormat.Items.Add('Graph JSON');
  cbExportFormat.Items.Add('GraphViz DOT');
  cbExportFormat.Items.Add('TXT');
  cbExportFormat.Items.Add('ARFF');

  cbVectorization.Items.Clear;
  cbVectorization.Items.Add('Binary');
  cbVectorization.Items.Add('Frequency');

  FCategories := TStringList.Create;
  FCategories.Sorted := True;
  FCategories.Duplicates := dupIgnore;

  FIngredients := TStringList.Create;
  FIngredients.Sorted := True;
  FIngredients.Duplicates := dupIgnore;

  FRelations := TStringList.Create;
  FRelations.Sorted := False;

  FReportLines := TStringList.Create;

  AIGraphMap1.LowerCaseTokens := True;
  AIGraphMap1.RemoveAccents := True;
  AIGraphMap1.RemoveStopWords := True;
  AIGraphMap1.MinTokenLength := 1;
  AIGraphMap1.TokenDelimiterChars := ' ,;.:!?()[]{}''"/\@#$*&^%-_+=';
  AIGraphMap1.UniqueTokensPerText := True;
  AIGraphMap1.UseTokenSequenceEdges := False;
  AIGraphMap1.UseTokenCategoryEdges := True;
  AIGraphMap1.AutoClearBeforeTrain := False;
  AIGraphMap1.UseGraphDepthSearch := False;
  AIGraphMap1.NormalizeScores := True;
  AIGraphMap1.TokenEdgeWeight := 1;
  AIGraphMap1.CategoryEdgeWeight := 2;
  AIGraphMap1.RepetitionBoost := 1;
  AIGraphMap1.DepthDecay := 0.6;
  AIGraphMap1.MinimumScore := 0.01;
  AIGraphMap1.UnknownCategoryName := 'unknown';
  AIGraphMap1.StopWords.Text :=
    'a'#13#10 +
    'o'#13#10 +
    'as'#13#10 +
    'os'#13#10 +
    'um'#13#10 +
    'uma'#13#10 +
    'de'#13#10 +
    'do'#13#10 +
    'da'#13#10 +
    'dos'#13#10 +
    'das'#13#10 +
    'e'#13#10 +
    'em'#13#10 +
    'com'#13#10 +
    'para'#13#10 +
    'por'#13#10 +
    'ao'#13#10 +
    'na'#13#10 +
    'no'#13#10 +
    'que'#13#10 +
    'se'#13#10 +
    'nao';

  AITrainingExporter1.GraphMap := AIGraphMap1;
  AITrainingExporter1.ExportFormat := efCSV;
  AITrainingExporter1.VectorizationMode := vmBinary;
  AITrainingExporter1.OneHotOutput := True;
  AITrainingExporter1.Overwrite := True;
  AITrainingExporter1.TargetFileName := BuildDefaultExportFileName;

  pcMain.ActivePage := tsSource;
  cbExportFormat.ItemIndex := 0;
  cbVectorization.ItemIndex := 0;
  chkOneHotOutput.Checked := True;
  chkOverwrite.Checked := True;
  edDatasetPath.Text := BuildDefaultDatasetPath;
  edTargetFile.Text := BuildDefaultExportFileName;
  odDataset.FileName := edDatasetPath.Text;
  sdExport.FileName := edTargetFile.Text;
  sdExport.DefaultExt := '.csv';
  sdExport.Filter := 'All files (*.*)|*.*';
  memoExportInfo.Clear;
  memoLoadInfo.Clear;
  memoLog.Clear;
  memoReport.Clear;

  AddLog('Training Exporter Demo initialized.');
  AddLog('This sample loads a local dataset, trains a graph, and exports real data.');
  LoadDataset;
end;

procedure TfrmMain.FormDestroy(Sender: TObject);
begin
  FReportLines.Free;
  FRelations.Free;
  FIngredients.Free;
  FCategories.Free;
end;

procedure TfrmMain.btnBrowseDatasetClick(Sender: TObject);
begin
  odDataset.FileName := SelectedDatasetFile;
  if odDataset.Execute then
  begin
    edDatasetPath.Text := odDataset.FileName;
    LoadDataset;
  end;
end;

procedure TfrmMain.btnLoadDatasetClick(Sender: TObject);
begin
  LoadDataset;
end;

procedure TfrmMain.btnValidateClick(Sender: TObject);
begin
  RefreshStats;
  RefreshReport;
  pcMain.ActivePage := tsReport;
end;

procedure TfrmMain.btnExportClick(Sender: TObject);
var
  ValidationMessage: string;
begin
  ValidationMessage := '';
  SyncTargetFileName;
  AITrainingExporter1.ExportFormat := CurrentExportFormat;
  AITrainingExporter1.VectorizationMode := CurrentVectorizationMode;
  AITrainingExporter1.OneHotOutput := chkOneHotOutput.Checked;
  AITrainingExporter1.Overwrite := chkOverwrite.Checked;
  AITrainingExporter1.TargetFileName := edTargetFile.Text;

  if not AITrainingExporter1.ValidateDataset(ValidationMessage) then
  begin
    FLastValidationMessage := ValidationMessage;
    AddLog('Validation failed: ' + ValidationMessage);
    RefreshStats;
    RefreshReport;
    pcMain.ActivePage := tsReport;
    Exit;
  end;

  if AITrainingExporter1.ExportToFile(edTargetFile.Text) then
  begin
    FLastExportMessage := AITrainingExporter1.LastResult;
    AddLog('Export completed: ' + edTargetFile.Text);
    AddLog(FLastExportMessage);
    if FLastExportMessage = '' then
      FLastExportMessage := 'Export completed successfully.';
  end
  else
  begin
    FLastExportMessage := 'Export failed: ' + AITrainingExporter1.LastError;
    AddLog(FLastExportMessage);
  end;

  RefreshStats;
  RefreshReport;
  pcMain.ActivePage := tsReport;
end;

procedure TfrmMain.cbExportFormatChange(Sender: TObject);
begin
  SyncTargetFileName;
  RefreshExportSettings;
end;

procedure TfrmMain.cbVectorizationChange(Sender: TObject);
begin
  RefreshExportSettings;
end;

procedure TfrmMain.chkOneHotOutputChange(Sender: TObject);
begin
  RefreshExportSettings;
end;

procedure TfrmMain.chkOverwriteChange(Sender: TObject);
begin
  RefreshExportSettings;
end;

procedure TfrmMain.edDatasetPathChange(Sender: TObject);
begin
  odDataset.FileName := edDatasetPath.Text;
end;

procedure TfrmMain.edTargetFileChange(Sender: TObject);
begin
  sdExport.FileName := edTargetFile.Text;
end;

procedure TfrmMain.pbGraphPaint(Sender: TObject);
begin
  RenderGraph(pbGraph.Canvas);
end;

function TfrmMain.BuildDefaultDatasetPath: string;
begin
  Result := IncludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0))) +
    SAMPLE_DATASET_FILE;
end;

function TfrmMain.BuildDefaultExportFileName: string;
begin
  Result := IncludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0))) +
    'training_export.csv';
end;

function TfrmMain.CurrentExportFormat: TAIExportFormat;
begin
  case cbExportFormat.ItemIndex of
    0: Result := efCSV;
    1: Result := efCSVRanking;
    2: Result := efJSON;
    3: Result := efJSONL;
    4: Result := efCSVNumeric;
    5: Result := efGraphJSON;
    6: Result := efGraphViz;
    7: Result := efTXT;
  else
    Result := efARFF;
  end;
end;

function TfrmMain.CurrentVectorizationMode: TAIVectorizationMode;
begin
  if cbVectorization.ItemIndex = 1 then
    Result := vmFrequency
  else
    Result := vmBinary;
end;

function TfrmMain.ExportExtension(AFormat: TAIExportFormat): string;
begin
  case AFormat of
    efCSV, efCSVRanking, efCSVNumeric:
      Result := '.csv';
    efJSON, efGraphJSON:
      Result := '.json';
    efJSONL:
      Result := '.jsonl';
    efGraphViz:
      Result := '.dot';
    efTXT:
      Result := '.txt';
    efARFF:
      Result := '.arff';
  else
    Result := '.txt';
  end;
end;

function TfrmMain.ExportFormatDisplayName(AFormat: TAIExportFormat): string;
begin
  case AFormat of
    efCSV: Result := 'CSV';
    efCSVRanking: Result := 'CSV Ranking';
    efJSON: Result := 'JSON';
    efJSONL: Result := 'JSONL';
    efCSVNumeric: Result := 'CSV Numeric';
    efGraphJSON: Result := 'Graph JSON';
    efGraphViz: Result := 'GraphViz DOT';
    efTXT: Result := 'TXT';
    efARFF: Result := 'ARFF';
  else
    Result := 'CSV';
  end;
end;

function TfrmMain.SelectedDatasetFile: string;
begin
  if Trim(edDatasetPath.Text) = '' then
    Exit(BuildDefaultDatasetPath);
  Result := edDatasetPath.Text;
end;

function TfrmMain.SelectedFormatText: string;
begin
  Result := ExportFormatDisplayName(CurrentExportFormat);
end;

function TfrmMain.VectorizationDisplayName(AMode: TAIVectorizationMode): string;
begin
  case AMode of
    vmBinary: Result := 'Binary';
    vmFrequency: Result := 'Frequency';
  else
    Result := 'Binary';
  end;
end;

procedure TfrmMain.AddLog(const AMsg: string);
begin
  memoLog.Lines.Add(AMsg);
end;

procedure TfrmMain.ClearDatasetState;
begin
  AIGraphMap1.ClearTraining;
  AIGraphMap1.ClearGraph;

  FCategories.Clear;
  FIngredients.Clear;
  FRelations.Clear;
  FLastExportMessage := '';
  FLastValidationMessage := '';

  memoLoadInfo.Clear;
  memoExportInfo.Clear;
  memoReport.Clear;

  lblPairs.Caption := '0';
  lblCategories.Caption := '0';
  lblIngredients.Caption := '0';
  lblTokens.Caption := '0';
  lblValidation.Caption := 'Ready';

  PopulateSourceLists;
  RefreshGraph;
end;

procedure TfrmMain.LoadDataset;
var
  FileName: string;
begin
  FileName := SelectedDatasetFile;
  edDatasetPath.Text := FileName;
  odDataset.FileName := FileName;

  if not FileExists(FileName) then
  begin
    ClearDatasetState;
    lblStatus.Caption := 'Status: Dataset file not found';
    memoLoadInfo.Lines.Add('Dataset file not found: ' + FileName);
    memoLoadInfo.Lines.Add('Place dataset.json next to the sample executable.');
    RefreshExportSettings;
    RefreshReport;
    Exit;
  end;

  try
    LoadDatasetFromFile(FileName);
    lblStatus.Caption := 'Status: Dataset loaded';
  except
    on E: Exception do
    begin
      ClearDatasetState;
      lblStatus.Caption := 'Status: Load error';
      memoLoadInfo.Lines.Add('Load failed: ' + E.Message);
      AddLog('Load failed: ' + E.Message);
      RefreshExportSettings;
      RefreshReport;
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
  IngredientName: string;
  TrainItem: TAITrainingItem;
  LocalIngredients: TStringList;
  I, J: Integer;
  RelationCount: Integer;
begin
  ClearDatasetState;
  RelationCount := 0;

  SL := TStringList.Create;
  LocalIngredients := TStringList.Create;
  LocalIngredients.Sorted := True;
  LocalIngredients.Duplicates := dupIgnore;
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
        raise Exception.Create('Dataset contains no training items.');

      memoLoadInfo.Lines.Add('Dataset loaded from: ' + ExtractFileName(AFileName));
      memoLoadInfo.Lines.Add('Each ingredient is mapped to a dish category.');
      memoLoadInfo.Lines.Add('The graph is trained from real local JSON data.');

      for I := 0 to ItemsArr.Count - 1 do
      begin
        if not (ItemsArr.Items[I] is TJSONObject) then
          raise Exception.CreateFmt('Item %d is not a JSON object.', [I + 1]);

        ItemObj := TJSONObject(ItemsArr.Items[I]);
        DishName := Trim(ItemObj.Get('dish', ''));
        if DishName = '' then
          raise Exception.CreateFmt('Item %d is missing the dish name.', [I + 1]);

        if FCategories.IndexOf(DishName) < 0 then
          FCategories.Add(DishName);

        IngredientData := ItemObj.Find('ingredients');
        if not Assigned(IngredientData) or not (IngredientData is TJSONArray) then
          raise Exception.CreateFmt('Dish "%s" has no ingredient list.', [DishName]);

        IngredientArr := TJSONArray(IngredientData);
        LocalIngredients.Clear;

        for J := 0 to IngredientArr.Count - 1 do
        begin
          IngredientName := Trim(IngredientArr.Items[J].AsString);
          if IngredientName = '' then
            Continue;

          if LocalIngredients.IndexOf(IngredientName) >= 0 then
            Continue;
          LocalIngredients.Add(IngredientName);

          if FIngredients.IndexOf(IngredientName) < 0 then
            FIngredients.Add(IngredientName);

          TrainItem := AIGraphMap1.Training.Add;
          TrainItem.InputText := IngredientName;
          TrainItem.OutputCategory := DishName;
          TrainItem.Weight := 1.0;

          FRelations.Add(IngredientName + ' -> ' + DishName);
          Inc(RelationCount);
        end;
      end;

      AIGraphMap1.Train;

      memoLoadInfo.Lines.Add('');
      memoLoadInfo.Lines.Add(Format('Dishes loaded: %d', [FCategories.Count]));
      memoLoadInfo.Lines.Add(Format('Unique ingredients: %d', [FIngredients.Count]));
      memoLoadInfo.Lines.Add(Format('Training pairs: %d', [RelationCount]));
      memoLoadInfo.Lines.Add('Source tab shows the ingredient, category, and relation lists.');
      memoLoadInfo.Lines.Add('The export tab writes the trained dataset to disk.');
      AddLog(Format('Dataset loaded with %d training pairs.', [RelationCount]));
    finally
      Data.Free;
    end;
  finally
    LocalIngredients.Free;
    SL.Free;
  end;

  PopulateSourceLists;
  RefreshStats;
  RefreshExportSettings;
  RefreshReport;
  RefreshGraph;
end;

procedure TfrmMain.PopulateSourceLists;
begin
  lbIngredients.Items.Assign(FIngredients);
  lbCategories.Items.Assign(FCategories);
  lbRelations.Items.Assign(FRelations);
end;

procedure TfrmMain.RefreshExportSettings;
begin
  AITrainingExporter1.GraphMap := AIGraphMap1;
  AITrainingExporter1.ExportFormat := CurrentExportFormat;
  AITrainingExporter1.VectorizationMode := CurrentVectorizationMode;
  AITrainingExporter1.OneHotOutput := chkOneHotOutput.Checked;
  AITrainingExporter1.Overwrite := chkOverwrite.Checked;
  AITrainingExporter1.TargetFileName := edTargetFile.Text;

  memoExportInfo.Lines.Clear;
  memoExportInfo.Lines.Add('Export configuration');
  memoExportInfo.Lines.Add('Format: ' + SelectedFormatText);
  memoExportInfo.Lines.Add('Vectorization: ' + VectorizationDisplayName(CurrentVectorizationMode));
  memoExportInfo.Lines.Add('One-hot output: ' + BoolToStr(chkOneHotOutput.Checked, True));
  memoExportInfo.Lines.Add('Overwrite existing file: ' + BoolToStr(chkOverwrite.Checked, True));
  memoExportInfo.Lines.Add('Target file: ' + edTargetFile.Text);
  memoExportInfo.Lines.Add('');
  memoExportInfo.Lines.Add('Supported exports');
  memoExportInfo.Lines.Add('- CSV');
  memoExportInfo.Lines.Add('- CSV Ranking');
  memoExportInfo.Lines.Add('- JSON');
  memoExportInfo.Lines.Add('- JSONL');
  memoExportInfo.Lines.Add('- CSV Numeric');
  memoExportInfo.Lines.Add('- Graph JSON');
  memoExportInfo.Lines.Add('- GraphViz DOT');
  memoExportInfo.Lines.Add('- TXT');
  memoExportInfo.Lines.Add('- ARFF');
end;

procedure TfrmMain.RefreshGraph;
begin
  pbGraph.Invalidate;
end;

procedure TfrmMain.RefreshReport;
var
  TrainingCount: Integer;
  CategoryCount: Integer;
  TokenCount: Integer;
  ValidationMessage: string;
  I, MaxItems: Integer;
begin
  TrainingCount := 0;
  CategoryCount := 0;
  TokenCount := 0;
  ValidationMessage := '';
  FReportLines.Clear;
  FReportLines.Add('Training Exporter Demo');
  FReportLines.Add('Purpose: collect graph-based training pairs and export them in multiple formats.');
  FReportLines.Add('');
  FReportLines.Add('Dataset');
  FReportLines.Add('File: ' + edDatasetPath.Text);
  FReportLines.Add(Format('Categories: %d', [FCategories.Count]));
  FReportLines.Add(Format('Ingredients: %d', [FIngredients.Count]));
  FReportLines.Add(Format('Relations: %d', [FRelations.Count]));
  FReportLines.Add('');
  FReportLines.Add('Current export settings');
  FReportLines.Add('Format: ' + SelectedFormatText);
  FReportLines.Add('Vectorization: ' + VectorizationDisplayName(CurrentVectorizationMode));
  FReportLines.Add('One-hot output: ' + BoolToStr(chkOneHotOutput.Checked, True));
  FReportLines.Add('Overwrite: ' + BoolToStr(chkOverwrite.Checked, True));
  FReportLines.Add('Target file: ' + edTargetFile.Text);
  FReportLines.Add('');

  AITrainingExporter1.GetDatasetStats(TrainingCount, CategoryCount, TokenCount);
  FReportLines.Add('Exporter stats');
  FReportLines.Add(Format('Training pairs: %d', [TrainingCount]));
  FReportLines.Add(Format('Categories: %d', [CategoryCount]));
  FReportLines.Add(Format('Tokens: %d', [TokenCount]));

  if AITrainingExporter1.ValidateDataset(ValidationMessage) then
  begin
    FLastValidationMessage := 'Validation OK';
    FReportLines.Add('Validation: OK');
  end
  else
  begin
    FLastValidationMessage := ValidationMessage;
    FReportLines.Add('Validation: ' + ValidationMessage);
  end;

  if FLastExportMessage <> '' then
  begin
    FReportLines.Add('');
    FReportLines.Add('Last export result');
    FReportLines.Add(FLastExportMessage);
  end;

  if FRelations.Count > 0 then
  begin
    FReportLines.Add('');
    FReportLines.Add('Sample relations');
    MaxItems := Min(10, FRelations.Count);
    for I := 0 to MaxItems - 1 do
      FReportLines.Add(FRelations[I]);
  end;

  memoReport.Lines.Assign(FReportLines);
end;

procedure TfrmMain.RefreshStats;
var
  TrainingCount: Integer;
  CategoryCount: Integer;
  TokenCount: Integer;
  ValidationMessage: string;
begin
  TrainingCount := 0;
  CategoryCount := 0;
  TokenCount := 0;
  ValidationMessage := '';
  AITrainingExporter1.GetDatasetStats(TrainingCount, CategoryCount, TokenCount);
  lblPairs.Caption := IntToStr(TrainingCount);
  lblCategories.Caption := IntToStr(FCategories.Count);
  lblIngredients.Caption := IntToStr(FIngredients.Count);
  lblTokens.Caption := IntToStr(TokenCount);

  if AITrainingExporter1.ValidateDataset(ValidationMessage) then
  begin
    FLastValidationMessage := 'Validation OK';
    lblValidation.Caption := 'Validation OK';
  end
  else
  begin
    FLastValidationMessage := ValidationMessage;
    lblValidation.Caption := ValidationMessage;
  end;

  UpdateStatusCaption;
end;

procedure TfrmMain.RenderGraph(ACanvas: TCanvas);
const
  MAX_VISIBLE_PER_SIDE = 18;
var
  W, H: Integer;
  TokenNodes: TList;
  CategoryNodes: TList;
  Layouts: array of TNodeLayout;
  I, VisibleIndex: Integer;
  Node: TAIGraphNode;
  Edge: TAIGraphEdge;
  NodeWidth, NodeHeight: Integer;
  LeftX, RightX, TopY, BottomY, YPos: Integer;
  SrcLayout, DstLayout: PNodeLayout;
  SrcPoint, DstPoint: TPoint;
  NodeRect: TRect;
  LabelRect: TRect;

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
  begin
    ACanvas.Brush.Color := NodeFillColor(L.Node);
    ACanvas.Pen.Color := RGBToColor(102, 115, 132);
    ACanvas.RoundRect(L.Bounds.Left, L.Bounds.Top, L.Bounds.Right, L.Bounds.Bottom, 14, 14);

    LabelRect := L.Bounds;
    InflateRect(LabelRect, -8, -8);
    ACanvas.Font.Name := 'Segoe UI';
    ACanvas.Font.Size := 9;
    ACanvas.Font.Color := clBlack;
    ACanvas.Font.Style := [fsBold];
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
  Layouts := nil;

  ACanvas.Brush.Color := RGBToColor(249, 248, 244);
  ACanvas.FillRect(Rect(0, 0, W, H));

  if AIGraphMap1.NodeCount = 0 then
  begin
    ACanvas.Font.Color := clGrayText;
    ACanvas.Font.Size := 11;
    ACanvas.TextOut(24, 24, 'Load the dataset to preview the training graph.');
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

    SetLength(Layouts, TokenNodes.Count + CategoryNodes.Count);
    if Length(Layouts) > 0 then
      FillChar(Layouts[0], Length(Layouts) * SizeOf(TNodeLayout), 0);

    NodeWidth := 180;
    NodeHeight := 42;
    TopY := 70;
    BottomY := H - 30;
    LeftX := 170;
    RightX := W - 170;
    VisibleIndex := 0;

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

      Layouts[VisibleIndex].Node := Node;
      Layouts[VisibleIndex].Bounds := NodeRect;
      Layouts[VisibleIndex].Center := Point(LeftX, YPos);
      Inc(VisibleIndex);
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

      Layouts[VisibleIndex].Node := Node;
      Layouts[VisibleIndex].Bounds := NodeRect;
      Layouts[VisibleIndex].Center := Point(RightX, YPos);
      Inc(VisibleIndex);
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
    ACanvas.TextOut(24, 16, 'Training Graph Preview');
    ACanvas.Font.Style := [];
    ACanvas.Font.Color := clGrayText;
    ACanvas.TextOut(24, 34, Format('Nodes: %d   Edges: %d   Preview limited to %d nodes per side',
      [AIGraphMap1.NodeCount, AIGraphMap1.EdgeCount, MAX_VISIBLE_PER_SIDE]));
  finally
    CategoryNodes.Free;
    TokenNodes.Free;
  end;
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
  Result := Copy(AText, 1, Max(1, AMaxLen - 3)) + '...';
end;

procedure TfrmMain.UpdateStatusCaption;
begin
  lblStatus.Caption := Format('Status: %s | Dataset: %d dishes, %d ingredients, %d relations',
    [FLastValidationMessage, FCategories.Count, FIngredients.Count, FRelations.Count]);
end;

procedure TfrmMain.SyncTargetFileName;
var
  BaseName: string;
begin
  if Trim(edTargetFile.Text) = '' then
    edTargetFile.Text := BuildDefaultExportFileName;

  BaseName := ChangeFileExt(edTargetFile.Text, '');
  if BaseName = '' then
    BaseName := ChangeFileExt(ExtractFileName(edDatasetPath.Text), '');
  if BaseName = '' then
    BaseName := 'training_export';

  edTargetFile.Text := BaseName + ExportExtension(CurrentExportFormat);
  sdExport.FileName := edTargetFile.Text;
end;

end.
