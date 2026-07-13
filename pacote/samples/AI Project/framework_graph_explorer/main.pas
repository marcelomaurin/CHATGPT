unit main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, IniFiles, Forms, Controls, Graphics, Dialogs, ExtCtrls, StdCtrls,
  ComCtrls, EditBtn, Grids, Process, aidisktreescanner, aidiskitem,
  aidependencygraph, chatgpt, aioutput_docs, fgx_analyzer, fgx_findings,
  fgx_history;

type
  TArtifactKind = (akUnknown, akPackage, akPascal, akForm, akProject,
    akProjectSrc, akDoc, akData);

  { TfrmMain }

  TfrmMain = class(TForm)
    btnAnalyze: TButton;
    btnAnalyzeAI: TButton;
    btnDetectToolchain: TButton;
    btnGenerateAIReport: TButton;
    btnCompileSamples: TButton;
    btnOpenSample: TButton;
    btnSaveSetup: TButton;
    btnStop: TButton;
    btnTestToolchain: TButton;
    cbProvider: TComboBox;
    chkCompileSamples: TCheckBox;
    chkUseAI: TCheckBox;
    deLazarus: TDirectoryEdit;
    deRoot: TDirectoryEdit;
    deBuildOutput: TDirectoryEdit;
    edtEndpoint: TEdit;
    edtModel: TEdit;
    edtToken: TEdit;
    feFPC: TFileNameEdit;
    lblAIStatus: TLabel;
    lblAIReportStatus: TLabel;
    lblEndpoint: TLabel;
    lblInventoryStatus: TLabel;
    lblBuildOutput: TLabel;
    lblFPC: TLabel;
    lblLazarus: TLabel;
    lblModel: TLabel;
    lblProjectStatus: TLabel;
    lblProvider: TLabel;
    lblReportPath: TLabel;
    lblRoot: TLabel;
    lblSetupInfo: TLabel;
    lblToken: TLabel;
    lblToolchainStatus: TLabel;
    memAI: TMemo;
    memAIReportRaw: TMemo;
    memLog: TMemo;
    memReport: TMemo;
    PageControl1: TPageControl;
    pnlInventoryTop: TPanel;
    pnlProjectTop: TPanel;
    pnlSamplesTop: TPanel;
    pnlSetup: TPanel;
    ProgressBar1: TProgressBar;
    sgComponents: TStringGrid;
    sgAIReport: TStringGrid;
    sgCounts: TStringGrid;
    sgPackages: TStringGrid;
    sgSamples: TStringGrid;
    sgStages: TStringGrid;
    tsAI: TTabSheet;
    tsAIReport: TTabSheet;
    tsComponents: TTabSheet;
    tsInventory: TTabSheet;
    tsLog: TTabSheet;
    tsPackages: TTabSheet;
    tsProject: TTabSheet;
    tsReport: TTabSheet;
    tsSamples: TTabSheet;
    tsSetup: TTabSheet;
    tvInventory: TTreeView;
    procedure btnAnalyzeAIClick(Sender: TObject);
    procedure btnDetectToolchainClick(Sender: TObject);
    procedure btnGenerateAIReportClick(Sender: TObject);
    procedure btnAnalyzeClick(Sender: TObject);
    procedure btnCompileSamplesClick(Sender: TObject);
    procedure btnOpenSampleClick(Sender: TObject);
    procedure btnSaveSetupClick(Sender: TObject);
    procedure btnStopClick(Sender: TObject);
    procedure btnTestToolchainClick(Sender: TObject);
    procedure cbProviderChange(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
  private
    FScanner: TAIDiskTreeScanner;
    FGraph: TAIDependencyGraph;
    FChatGPT: TCHATGPT;
    FTXTOutput: TAITXTOutput;
    FAIReportFacts: TStringList;
    FFindings: TFGXFindingList;
    FHistoryFindings: TFGXFindingList;
    FHistorySummary: TStringList;
    FTreeIndex: TStringList;
    FCounts: array[TArtifactKind] of Integer;
    FDirectories: Integer;
    FFiles: Integer;
    FRootNode: TTreeNode;
    FRootPath: string;
    FScanRunning: Boolean;
    FPipelineRunning: Boolean;
    FCancelRequested: Boolean;
    FAnalysisReady: Boolean;
    FAnalysisStats: TFGXAnalysisStats;
    FHistoryFile: string;
    FTemporalRegressions: Integer;
    FHeadless: Boolean;
    FHeadlessExitCode: Integer;

    procedure ScannerTaskStart(Sender: TObject; TaskId: Integer; const Description: string);
    procedure ScannerItemFound(Sender: TObject; TaskId: Integer; Item: TAIDiskItem);
    procedure ScannerProgress(Sender: TObject; TaskId: Integer; ProcessedDirs: Int64;
      ProcessedFiles: Int64; FoundItems: Int64; const CurrentPath: string);
    procedure ScannerTaskFinish(Sender: TObject; TaskId: Integer; State: TAIDiskTaskState;
      TotalDirs: Int64; TotalFiles: Int64; TotalFound: Int64; const ErrorMsg: string);
    procedure ScannerError(Sender: TObject; TaskId: Integer; const Path: string;
      const ErrorMsg: string);

    procedure AddLog(const AText: string);
    procedure ResetView;
    procedure ConfigureScanner;
    procedure ConfigureGrid(AGrid: TStringGrid; const AHeaders: array of string);
    procedure UpdateButtons;
    procedure UpdateCountsGrid;
    procedure UpdateStatus(const AText: string);
    procedure SaveArtifacts;
    procedure UpdateHistory;
    procedure ConfigureCommandLine;
    procedure FinishHeadless;
    procedure AnalyzerStage(AStage, AStageCount: Integer;
      const AName, AStatus: string);
    procedure InitializeStages;
    procedure SetStageStatus(AStage: Integer; const AStatus: string);
    procedure GenerateFinalReport;
    procedure BuildAIReportFacts;
    procedure PopulateAIReportFacts(const ADefaultRecommendation: string);
    procedure PopulateAnalysisViews;
    procedure PopulatePackages;
    procedure PopulateComponents;
    procedure PopulateSamples;
    procedure EnsureRootNode;
    function NormalizePathKey(const APath: string): string;
    function FindTreeNode(const APath: string): TTreeNode;
    function EnsureTreeNode(const APath, ACaption: string): TTreeNode;
    function ArtifactKindForItem(const AItem: TAIDiskItem): TArtifactKind;
    function ArtifactKindLabel(AKind: TArtifactKind): string;
    function DetectRepoRoot(const AStartDir: string): string;
    procedure SetDefaultRoot;
    procedure DetectToolchain;
    procedure LoadSetup;
    procedure ProtectSetupFile;
    procedure SaveSetup;
    function SetupFileName: string;

    function ConfigureAI: Boolean;
    function ExecuteAIStage: Boolean;
    function ExecuteAIReportStage: Boolean;
    function ExecuteSampleStage: Boolean;
    function BuildAIContext: string;
    function BuildAIReportContext(AStartIndex, ACount: Integer): string;
    function FindLazBuild: string;
    function FindFPC: string;
    function BuildOutputRoot: string;
    function ResolveRepoPath(const APath: string): string;
    function ResolveValidationExecutable(ANode: TAIDependencyNode): string;
    function SafePathSegment(const AValue: string): string;
    function RunTool(const AExecutable: string; AArguments: TStrings;
      const AWorkingDir: string; out AOutput: string; out AExitCode: Integer): Boolean;
    function CompileSample(ANode: TAIDependencyNode): Boolean;
    function SelectedSampleNode: TAIDependencyNode;
    procedure SetSampleStatus(ANode: TAIDependencyNode; const ABuild, ARun: string);
  public
    property Headless: Boolean read FHeadless;
    property HeadlessExitCode: Integer read FHeadlessExitCode;
  end;

var
  frmMain: TfrmMain;

implementation

{$IFDEF UNIX}
uses BaseUnix;
{$ENDIF}

{$R *.lfm}

function JoinValues(AValues: TStrings; const ASeparator: string): string;
var
  I: Integer;
begin
  Result := '';
  for I := 0 to AValues.Count - 1 do
  begin
    if Result <> '' then
      Result := Result + ASeparator;
    Result := Result + AValues[I];
  end;
end;

function DelimitedPart(const AValue: string; AIndex: Integer): string;
var
  Parts: TStringList;
begin
  Result := '';
  Parts := TStringList.Create;
  try
    Parts.StrictDelimiter := True;
    Parts.Delimiter := #9;
    Parts.DelimitedText := AValue;
    if (AIndex >= 0) and (AIndex < Parts.Count) then
      Result := Parts[AIndex];
  finally
    Parts.Free;
  end;
end;

{ TfrmMain }

procedure TfrmMain.AddLog(const AText: string);
begin
  memLog.Lines.Add(FormatDateTime('hh:nn:ss', Now) + '  ' + AText);
  memLog.SelStart := Length(memLog.Text);
end;

procedure TfrmMain.InitializeStages;
const
  StageNames: array[1..10] of string = (
    'Inventory scan',
    'Packages and units',
    'Package dependencies',
    'Pascal components',
    'Sample coverage',
    'Graph validation',
    'Sample compilation',
    'AI analysis',
    'Final factual report',
    'AI report'
  );
var
  I: Integer;
begin
  sgStages.ColCount := 3;
  sgStages.RowCount := 11;
  sgStages.FixedCols := 0;
  sgStages.FixedRows := 1;
  sgStages.Cells[0, 0] := 'Step';
  sgStages.Cells[1, 0] := 'Process';
  sgStages.Cells[2, 0] := 'Status';
  sgStages.ColWidths[0] := 60;
  sgStages.ColWidths[1] := 500;
  sgStages.ColWidths[2] := 180;
  for I := 1 to 10 do
  begin
    sgStages.Cells[0, I] := IntToStr(I) + '/10';
    sgStages.Cells[1, I] := StageNames[I];
    sgStages.Cells[2, I] := 'PENDING';
  end;
  ProgressBar1.Min := 0;
  ProgressBar1.Max := 10;
  ProgressBar1.Position := 0;
end;

procedure TfrmMain.SetStageStatus(AStage: Integer; const AStatus: string);
begin
  if (AStage < 1) or (AStage > 10) then Exit;
  sgStages.Cells[2, AStage] := AStatus;
  if AStatus = 'RUNNING' then
    ProgressBar1.Position := AStage - 1
  else
    ProgressBar1.Position := AStage;
  Application.ProcessMessages;
end;

procedure TfrmMain.AnalyzerStage(AStage, AStageCount: Integer;
  const AName, AStatus: string);
begin
  SetStageStatus(AStage, AStatus);
  UpdateStatus(Format('Step %d/%d: %s - %s',
    [AStage, AStageCount, AName, AStatus]));
  if AStatus <> 'RUNNING' then
    AddLog(Format('Step %d/%d %s: %s',
      [AStage, AStageCount, AName, AStatus]));
end;

function TfrmMain.ArtifactKindLabel(AKind: TArtifactKind): string;
begin
  case AKind of
    akPackage: Result := 'LPK packages';
    akPascal: Result := 'Pascal source';
    akForm: Result := 'LFM forms';
    akProject: Result := 'LPI projects';
    akProjectSrc: Result := 'LPR programs';
    akDoc: Result := 'Documents';
    akData: Result := 'Data files';
  else
    Result := 'Other files';
  end;
end;

function TfrmMain.ArtifactKindForItem(const AItem: TAIDiskItem): TArtifactKind;
var
  Ext: string;
begin
  if AItem.ItemType = ditDirectory then
    Exit(akUnknown);
  Ext := LowerCase(AItem.Extension);
  if Ext = '.lpk' then Result := akPackage
  else if (Ext = '.pas') or (Ext = '.pp') or (Ext = '.inc') then Result := akPascal
  else if Ext = '.lfm' then Result := akForm
  else if Ext = '.lpi' then Result := akProject
  else if Ext = '.lpr' then Result := akProjectSrc
  else if (Ext = '.md') or (Ext = '.txt') then Result := akDoc
  else if (Ext = '.json') or (Ext = '.csv') then Result := akData
  else Result := akUnknown;
end;

function TfrmMain.NormalizePathKey(const APath: string): string;
begin
  if Trim(APath) = '' then Exit('');
  Result := ExcludeTrailingPathDelimiter(ExpandFileName(APath));
end;

function TfrmMain.FindTreeNode(const APath: string): TTreeNode;
var
  Idx: Integer;
begin
  Result := nil;
  Idx := FTreeIndex.IndexOf(NormalizePathKey(APath));
  if Idx >= 0 then
    Result := TTreeNode(FTreeIndex.Objects[Idx]);
end;

function TfrmMain.EnsureTreeNode(const APath, ACaption: string): TTreeNode;
var
  Key, ParentKey, CaptionText: string;
  ParentNode: TTreeNode;
begin
  Key := NormalizePathKey(APath);
  Result := FindTreeNode(Key);
  if Assigned(Result) then Exit;
  if SameText(Key, NormalizePathKey(FRootPath)) then
  begin
    CaptionText := ACaption;
    if CaptionText = '' then CaptionText := ExtractFileName(Key);
    if CaptionText = '' then CaptionText := Key;
    Result := tvInventory.Items.Add(nil, CaptionText);
    FTreeIndex.AddObject(Key, Result);
    FRootNode := Result;
    Exit;
  end;
  ParentKey := NormalizePathKey(ExtractFileDir(Key));
  ParentNode := FindTreeNode(ParentKey);
  if not Assigned(ParentNode) then ParentNode := FRootNode;
  CaptionText := ACaption;
  if CaptionText = '' then CaptionText := ExtractFileName(Key);
  Result := tvInventory.Items.AddChild(ParentNode, CaptionText);
  FTreeIndex.AddObject(Key, Result);
end;

procedure TfrmMain.ConfigureGrid(AGrid: TStringGrid; const AHeaders: array of string);
var
  I: Integer;
begin
  AGrid.FixedCols := 0;
  AGrid.FixedRows := 1;
  AGrid.ColCount := Length(AHeaders);
  AGrid.RowCount := 2;
  AGrid.Options := AGrid.Options + [goColSizing, goRowSelect];
  for I := 0 to High(AHeaders) do
    AGrid.Cells[I, 0] := AHeaders[I];
end;

procedure TfrmMain.ResetView;
begin
  tvInventory.Items.Clear;
  FTreeIndex.Clear;
  FRootNode := nil;
  FGraph.Clear;
  FillChar(FCounts, SizeOf(FCounts), 0);
  FillChar(FAnalysisStats, SizeOf(FAnalysisStats), 0);
  FDirectories := 0;
  FFiles := 0;
  FAnalysisReady := False;
  FTemporalRegressions := 0;
  FHistoryFile := '';
  FHistoryFindings.Clear;
  FHistorySummary.Clear;
  sgPackages.RowCount := 2;
  sgComponents.RowCount := 2;
  sgSamples.RowCount := 2;
  memAI.Clear;
  memAIReportRaw.Clear;
  FAIReportFacts.Clear;
  sgAIReport.RowCount := 2;
  memReport.Clear;
  InitializeStages;
  UpdateCountsGrid;
end;

procedure TfrmMain.ConfigureScanner;
begin
  FScanner.Clear;
  FScanner.AutoClearResults := True;
  FScanner.IncludeFiles := True;
  FScanner.IncludeDirectories := True;
  FScanner.IncludeHidden := False;
  FScanner.IncludeSystem := False;
  FScanner.FollowSymlinks := False;
  FScanner.MaxDepth := 0;
  FScanner.ReturnOnMainThread := True;
  FScanner.Recursive := True;
  FScanner.FileMask := '';
  FScanner.ExcludeDirs.Clear;
  FScanner.ExcludeDirs.Add('.git');
  FScanner.ExcludeDirs.Add('lib');
  FScanner.ExcludeDirs.Add('bin');
  FScanner.ExcludeDirs.Add('backup');
  FScanner.ExcludeDirs.Add('output');
  FScanner.ExcludeDirs.Add('__pycache__');
  FScanner.ExcludeDirs.Add('node_modules');
  FScanner.ExcludeDirs.Add('.vscode');
  FScanner.ExcludeDirs.Add('dist');
  FScanner.ExcludeDirs.Add('fixtures');
  FScanner.ExcludeExtensions.Clear;
end;

procedure TfrmMain.UpdateButtons;
begin
  btnAnalyze.Enabled := not FPipelineRunning;
  btnStop.Enabled := FPipelineRunning;
  deRoot.Enabled := not FPipelineRunning;
  chkCompileSamples.Enabled := not FPipelineRunning;
  chkUseAI.Enabled := not FPipelineRunning;
  btnCompileSamples.Enabled := FAnalysisReady and (not FPipelineRunning);
  btnOpenSample.Enabled := FAnalysisReady and (not FPipelineRunning);
  btnAnalyzeAI.Enabled := FAnalysisReady and (not FPipelineRunning);
  btnGenerateAIReport.Enabled := FAnalysisReady and (not FPipelineRunning);
  deLazarus.Enabled := not FPipelineRunning;
  feFPC.Enabled := not FPipelineRunning;
  deBuildOutput.Enabled := not FPipelineRunning;
  btnDetectToolchain.Enabled := not FPipelineRunning;
  btnTestToolchain.Enabled := not FPipelineRunning;
  btnSaveSetup.Enabled := not FPipelineRunning;
end;

procedure TfrmMain.UpdateStatus(const AText: string);
begin
  lblProjectStatus.Caption := AText;
  lblInventoryStatus.Caption := AText;
end;

procedure TfrmMain.SaveArtifacts;
var
  OutDir: string;
begin
  OutDir := IncludeTrailingPathDelimiter(ExtractFilePath(Application.ExeName));
  if not FScanner.ExportToJSON(OutDir + 'inventory.json') then
    AddLog('WARN: could not save inventory.json.');
  if not FGraph.SaveToJSON(OutDir + 'factual_graph.json') then
    AddLog('WARN: ' + FGraph.LastError);
  if not FGraph.SaveToDOT(OutDir + 'graph.dot') then
    AddLog('WARN: ' + FGraph.LastError);
  if not FGraph.SaveToMermaid(OutDir + 'graph.mmd') then
    AddLog('WARN: ' + FGraph.LastError);
  AddLog('Artifacts saved to ' + OutDir);
end;

procedure TfrmMain.UpdateHistory;
begin
  FHistoryFindings.Clear;
  if SaveAndCompareHistory(FGraph, FRootPath, FHistoryFindings,
    FHistorySummary, FHistoryFile, FTemporalRegressions) then
    AddLog(Format('History saved. Temporal regressions: %d.',
      [FTemporalRegressions]))
  else
    AddLog('WARN: history snapshot could not be saved.');
end;

procedure TfrmMain.ConfigureCommandLine;
var
  I: Integer;
  Arg, RootArg: string;
  BuildRequested, AIRequested: Boolean;
begin
  FHeadless := False;
  FHeadlessExitCode := 0;
  RootArg := '';
  BuildRequested := True;
  AIRequested := False;
  I := 1;
  while I <= ParamCount do
  begin
    Arg := ParamStr(I);
    if SameText(Arg, '--headless') then
      FHeadless := True
    else if SameText(Arg, '--no-build') then
      BuildRequested := False
    else if SameText(Arg, '--ai') then
      AIRequested := True
    else if SameText(Arg, '--no-ai') then
      AIRequested := False
    else if SameText(Arg, '--root') and (I < ParamCount) then
    begin
      Inc(I);
      RootArg := ParamStr(I);
    end
    else if Pos('--root=', LowerCase(Arg)) = 1 then
      RootArg := Copy(Arg, Length('--root=') + 1, MaxInt)
    else if (Copy(Arg, 1, 2) <> '--') and (RootArg = '') then
      RootArg := Arg;
    Inc(I);
  end;

  if RootArg = '' then Exit;
  if not DirectoryExists(RootArg) then
  begin
    if FHeadless then
    begin
      FHeadlessExitCode := 2;
      AddLog('FAIL: headless root does not exist: ' + RootArg);
      Application.Terminate;
    end;
    Exit;
  end;
  deRoot.Directory := ExpandFileName(RootArg);
  if FHeadless then
  begin
    chkCompileSamples.Checked := BuildRequested;
    chkUseAI.Checked := AIRequested;
  end
  else
  begin
    chkCompileSamples.Checked := False;
    chkUseAI.Checked := False;
  end;
  btnAnalyzeClick(nil);
end;

procedure TfrmMain.FinishHeadless;
begin
  if not FHeadless then Exit;
  if (sgStages.Cells[2, 1] = 'FAIL') or
     (sgStages.Cells[2, 6] = 'FAIL') or
     (sgStages.Cells[2, 7] = 'FAIL') or
     (FTemporalRegressions > 0) then
    FHeadlessExitCode := 1
  else if FCancelRequested or (sgStages.Cells[2, 1] = 'CANCELLED') then
    FHeadlessExitCode := 2
  else
    FHeadlessExitCode := 0;
  System.ExitCode := FHeadlessExitCode;
  AddLog(Format('Headless exit code: %d.', [FHeadlessExitCode]));
  Application.Terminate;
end;

procedure TfrmMain.GenerateFinalReport;
var
  Lines, Values: TStringList;
  I, J, Orphans, Covered, BuildPass, BuildFail, BuildSkipped,
    BuildPending: Integer;
  N, Target: TAIDependencyNode;
  E: TAIDependencyEdge;
  ReportFile, StatusText: string;
begin
  SetStageStatus(9, 'RUNNING');
  Lines := TStringList.Create;
  Values := TStringList.Create;
  try
    Covered := 0;
    for I := 0 to FGraph.Nodes.Count - 1 do
      if FGraph.Nodes[I].NodeType = AIDG_NODE_COMPONENT then
        for J := 0 to FGraph.Edges.Count - 1 do
          if (FGraph.Edges[J].FromId = FGraph.Nodes[I].Id) and
             (FGraph.Edges[J].EdgeType = AIDG_EDGE_DEMONSTRATED_BY) then
          begin
            Inc(Covered);
            Break;
          end;
    Orphans := FAnalysisStats.Components - Covered;
    BuildPass := 0;
    BuildFail := 0;
    BuildSkipped := 0;
    BuildPending := 0;

    Lines.Add('AI FRAMEWORK GRAPH EXPLORER - FINAL FACTUAL REPORT');
    Lines.Add(StringOfChar('=', 78));
    Lines.Add('Generated at: ' + FormatDateTime('yyyy-mm-dd hh:nn:ss', Now));
    Lines.Add('Repository: ' + FRootPath);
    Lines.Add('Factual graph validated: ' + BoolToStr(FGraph.Validated, True));
    Lines.Add('');
    Lines.Add('PIPELINE STEPS');
    Lines.Add(StringOfChar('-', 78));
    for I := 1 to 8 do
      Lines.Add(Format('%d/10 %-32s %s',
        [I, sgStages.Cells[1, I], sgStages.Cells[2, I]]));
    Lines.Add(Format('9/10 %-32s %s', ['Final factual report', 'PASS']));
    Lines.Add(Format('10/10 %-31s %s', ['AI report', sgStages.Cells[2, 10]]));

    if (sgStages.Cells[2, 1] = 'FAIL') or
       (sgStages.Cells[2, 2] = 'FAIL') or
       (sgStages.Cells[2, 3] = 'FAIL') or
       (sgStages.Cells[2, 4] = 'FAIL') or
       (sgStages.Cells[2, 5] = 'FAIL') or
       (sgStages.Cells[2, 6] = 'FAIL') or
       (sgStages.Cells[2, 7] = 'FAIL') or
       (sgStages.Cells[2, 8] = 'FAIL') or
       (sgStages.Cells[2, 10] = 'FAIL') or
       (FTemporalRegressions > 0) then
      Lines.Add('PIPELINE RESULT: FAIL')
    else if (sgStages.Cells[2, 7] <> 'PASS') or
            (sgStages.Cells[2, 8] <> 'PASS') or
            (sgStages.Cells[2, 10] <> 'PASS') then
      Lines.Add('PIPELINE RESULT: PARTIAL')
    else
      Lines.Add('PIPELINE RESULT: PASS');

    Lines.Add('');
    Lines.Add('FACTUAL SUMMARY');
    Lines.Add(StringOfChar('-', 78));
    Lines.Add(Format('Nodes: %d | Edges: %d', [FGraph.NodeCount, FGraph.EdgeCount]));
    Lines.Add(Format('Packages: %d | Units: %d | Components: %d | Samples: %d',
      [FAnalysisStats.Packages, FAnalysisStats.Units,
       FAnalysisStats.Components, FAnalysisStats.Samples]));
    Lines.Add(Format('External dependencies: %d | Parser errors: %d',
      [FAnalysisStats.ExternalDependencies, FAnalysisStats.ParseErrors]));
    Lines.Add(Format('Components: %d | with sample: %d | orphans: %d',
      [FAnalysisStats.Components, Covered, Orphans]));
    Lines.Add(Format('Package->dependency relations: %d', [FAnalysisStats.PackageLinks]));
    Lines.Add(Format('Component->sample links: %d',
      [FAnalysisStats.ComponentSampleLinks]));

    Lines.Add('');
    Lines.Add('TEMPORAL COMPARISON');
    Lines.Add(StringOfChar('-', 78));
    if FHistorySummary.Count > 0 then Lines.AddStrings(FHistorySummary)
    else Lines.Add('History comparison was not executed.');

    Lines.Add('');
    Lines.Add('PACKAGE DEPENDENCIES');
    Lines.Add(StringOfChar('-', 78));
    for I := 0 to FGraph.Nodes.Count - 1 do
    begin
      N := FGraph.Nodes[I];
      if N.NodeType <> AIDG_NODE_PACKAGE then Continue;
      Values.Clear;
      for J := 0 to FGraph.Edges.Count - 1 do
      begin
        E := FGraph.Edges[J];
        if (E.FromId = N.Id) and (E.EdgeType = AIDG_EDGE_REQUIRES_PACKAGE) then
        begin
          Target := FGraph.FindNode(E.ToId);
          if Assigned(Target) then
            Values.Add(Format('%s @ %s:%d [%s]', [Target.Name,
              E.Evidence.SourceFile, E.Evidence.Line, E.Evidence.Parser]));
        end;
      end;
      if Values.Count = 0 then StatusText := '(no declared dependencies)'
      else StatusText := JoinValues(Values, ', ');
      Lines.Add(N.Name + ' -> ' + StatusText);
    end;

    Lines.Add('');
    Lines.Add('COMPONENTS AND SAMPLE COVERAGE');
    Lines.Add(StringOfChar('-', 78));
    for I := 0 to FGraph.Nodes.Count - 1 do
    begin
      N := FGraph.Nodes[I];
      if N.NodeType <> AIDG_NODE_COMPONENT then Continue;
      Values.Clear;
      for J := 0 to FGraph.Edges.Count - 1 do
      begin
        E := FGraph.Edges[J];
        if (E.FromId = N.Id) and (E.EdgeType = AIDG_EDGE_DEMONSTRATED_BY) then
        begin
          Target := FGraph.FindNode(E.ToId);
          if Assigned(Target) then Values.Add(Target.Name);
        end;
      end;
      if Values.Count = 0 then
      begin
        StatusText := 'ORPHAN - no sample found';
      end
      else
        StatusText := JoinValues(Values, ', ');
      Lines.Add(Format('%s | package=%s | samples=%s | where=%s:%d [%s]',
        [N.Name, N.Attrs.Values['package'], StatusText,
         N.Evidence.SourceFile, N.Evidence.Line, N.Evidence.Parser]));
    end;
    Lines.Add(Format('TOTAL ORPHAN COMPONENTS: %d', [Orphans]));

    Lines.Add('');
    Lines.Add('SAMPLES');
    Lines.Add(StringOfChar('-', 78));
    for I := 0 to FGraph.Nodes.Count - 1 do
    begin
      N := FGraph.Nodes[I];
      if N.NodeType <> AIDG_NODE_SAMPLE then Continue;
      StatusText := N.Attrs.Values['build_status'];
      if StatusText = 'PASS' then Inc(BuildPass)
      else if StatusText = 'FAIL' then Inc(BuildFail)
      else if StatusText = 'SKIPPED' then Inc(BuildSkipped)
      else Inc(BuildPending);
      Lines.Add(Format('%s | build=%s | execution=%s | %s | evidence=%s:%d [%s]',
        [N.Name, StatusText, N.Attrs.Values['run_status'], N.Path,
         N.Evidence.SourceFile, N.Evidence.Line, N.Evidence.Parser]));
    end;
    Lines.Add(Format('TOTAL: PASS=%d | FAIL=%d | SKIPPED=%d | NOT TESTED=%d',
      [BuildPass, BuildFail, BuildSkipped, BuildPending]));

    Lines.Add('');
    Lines.Add('AI ANALYSIS');
    Lines.Add(StringOfChar('-', 78));
    Lines.Add('Status: ' + sgStages.Cells[2, 8]);
    if Trim(memAI.Text) <> '' then Lines.AddStrings(memAI.Lines)
    else Lines.Add('No AI analysis was produced.');

    Lines.Add('');
    Lines.Add('AI REPORT - LOCKED FACTS AND RECOMMENDATIONS');
    Lines.Add(StringOfChar('-', 78));
    Lines.Add('Status: ' + sgStages.Cells[2, 10]);
    Lines.Add('ID | ROLE | KIND | SEVERITY | ROOT_CAUSE | WHERE | WHAT | AI RECOMMENDATION');
    if FAIReportFacts.Count = 0 then
      Lines.Add('- | - | - | - | - | - | No factual issues were found. | No recommendation required.')
    else
      for I := 0 to FAIReportFacts.Count - 1 do
      begin
        if DelimitedPart(FAIReportFacts[I], 5) = '' then
          StatusText := 'ROOT'
        else
          StatusText := 'CONSEQUENCE';
        Lines.Add(Format('%s | %s | %s | %s | %s | %s | %s | %s',
          [DelimitedPart(FAIReportFacts[I], 0), StatusText,
           DelimitedPart(FAIReportFacts[I], 3),
           DelimitedPart(FAIReportFacts[I], 4),
           DelimitedPart(FAIReportFacts[I], 5),
           sgAIReport.Cells[0, I + 1], sgAIReport.Cells[1, I + 1],
           sgAIReport.Cells[2, I + 1]]));
      end;

    Lines.Add('');
    Lines.Add('INTERPRETATION NOTES');
    Lines.Add(StringOfChar('-', 78));
    Lines.Add('- Structural facts were extracted without an LLM.');
    Lines.Add('- Sample PASS means lazbuild returned exit code zero.');
    Lines.Add('- OPENED means manual visual validation started; it is not an automated functional test.');
    Lines.Add('- SKIPPED is never counted as PASS.');

    ReportFile := IncludeTrailingPathDelimiter(ExtractFilePath(Application.ExeName)) +
      'framework_graph_report.txt';
    FTXTOutput.Clear;
    FTXTOutput.FileName := ReportFile;
    for I := 0 to Lines.Count - 1 do FTXTOutput.AddLine(Lines[I]);
    if FTXTOutput.SaveText then
    begin
      SetStageStatus(9, 'PASS');
      lblReportPath.Caption := 'Report: ' + ReportFile;
      memReport.Lines.Assign(Lines);
      AddLog('Step 9/10 Final factual report: PASS');
    end
    else
    begin
      SetStageStatus(9, 'FAIL');
      lblReportPath.Caption := 'Failed to generate report: ' + FTXTOutput.LastError;
      AddLog('Step 9/10 Final factual report: FAIL - ' + FTXTOutput.LastError);
    end;
  finally
    Values.Free;
    Lines.Free;
  end;
end;

procedure TfrmMain.BuildAIReportFacts;
var
  I: Integer;
  F: TFGXFinding;
begin
  FAIReportFacts.Clear;
  DetectFindings(FGraph, memLog.Lines, FRootPath, FFindings);
  for I := 0 to FHistoryFindings.Count - 1 do
  begin
    F := FHistoryFindings[I];
    F := FFindings.AddFinding(F.Kind, F.Severity, F.WhereText, F.WhatText,
      F.EntityId);
    if Assigned(F) then F.RootCause := FHistoryFindings[I].RootCause;
  end;
  for I := 0 to FFindings.Count - 1 do
  begin
    F := FFindings[I];
    FAIReportFacts.Add(F.Id + #9 + F.WhereText + #9 + F.WhatText + #9 +
      F.Kind + #9 + FindingSeverityText(F.Severity) + #9 + F.RootCause);
  end;
end;

procedure TfrmMain.PopulateAIReportFacts(const ADefaultRecommendation: string);
var
  I: Integer;
begin
  sgAIReport.RowCount := FAIReportFacts.Count + 1;
  if sgAIReport.RowCount < 2 then sgAIReport.RowCount := 2;
  for I := 0 to FAIReportFacts.Count - 1 do
  begin
    sgAIReport.Cells[0, I + 1] := DelimitedPart(FAIReportFacts[I], 1);
    sgAIReport.Cells[1, I + 1] := DelimitedPart(FAIReportFacts[I], 2);
    sgAIReport.Cells[2, I + 1] := ADefaultRecommendation;
  end;
  if FAIReportFacts.Count = 0 then
  begin
    sgAIReport.Cells[0, 1] := '-';
    sgAIReport.Cells[1, 1] := 'No factual issues were found.';
    sgAIReport.Cells[2, 1] := 'No recommendation required.';
  end;
end;

function TfrmMain.BuildAIReportContext(AStartIndex, ACount: Integer): string;
var
  I, LastIndex: Integer;
begin
  Result :=
    'FACT LOCK: WHERE, WHAT, KIND, SEVERITY, and ROOT_CAUSE are immutable. ' +
    'Do not question, rewrite, summarize, add, remove, or infer facts. ' +
    'For every fact ID below, output exactly one line as ID<TAB>AI_RECOMMENDATION. ' +
    'Return only the concrete HOW. Do not say investigate, evaluate, or consider. ' +
    'If the correction is not supported by the supplied fact, answer I DO NOT KNOW. ' +
    'Do not output Markdown, headers, or facts not listed.' + LineEnding +
    LineEnding + 'FACT CATALOG' + LineEnding;
  LastIndex := AStartIndex + ACount - 1;
  if LastIndex >= FAIReportFacts.Count then LastIndex := FAIReportFacts.Count - 1;
  for I := AStartIndex to LastIndex do
    Result := Result + DelimitedPart(FAIReportFacts[I], 0) +
      ' KIND=' + DelimitedPart(FAIReportFacts[I], 3) +
      ' SEVERITY=' + DelimitedPart(FAIReportFacts[I], 4) +
      ' ROOT_CAUSE=' + DelimitedPart(FAIReportFacts[I], 5) +
      ' WHERE=' + DelimitedPart(FAIReportFacts[I], 1) +
      ' WHAT=' + DelimitedPart(FAIReportFacts[I], 2) + LineEnding;
end;

function TfrmMain.ExecuteAIReportStage: Boolean;
var
  I, J, UpdatedCount, TabAt, BatchStart, BatchCount: Integer;
  ResponseLine, FactId, Recommendation, BatchResponse: string;
begin
  Result := False;
  SetStageStatus(10, 'RUNNING');
  BuildAIReportFacts;
  PopulateAIReportFacts('PENDING');
  if FAIReportFacts.Count = 0 then
  begin
    lblAIReportStatus.Caption := 'PASS: no factual issues require AI review.';
    SetStageStatus(10, 'PASS');
    Exit(True);
  end;

  if not ConfigureAI then
  begin
    PopulateAIReportFacts('SKIPPED: configure AI on the Setup tab.');
    lblAIReportStatus.Caption := 'SKIPPED: AI is not configured.';
    SetStageStatus(10, 'SKIPPED');
    Exit;
  end;

  FChatGPT.Dev := UTF8Decode(
    'You review a locked factual catalog. WHERE and WHAT are immutable. ' +
    'Return only an actionable recommendation for each supplied fact ID.');
  FChatGPT.MaxTokens := 2500;
  lblAIReportStatus.Caption := 'Generating recommendations from factual findings...';
  Application.ProcessMessages;
  memAIReportRaw.Clear;
  BatchStart := 0;
  while BatchStart < FAIReportFacts.Count do
  begin
    BatchCount := 8;
    if BatchStart + BatchCount > FAIReportFacts.Count then
      BatchCount := FAIReportFacts.Count - BatchStart;
    if not FChatGPT.SendQuestion(UTF8Decode(
      BuildAIReportContext(BatchStart, BatchCount))) then
    begin
      lblAIReportStatus.Caption := 'FAIL: ' + FChatGPT.LastError;
      SetStageStatus(10, 'FAIL');
      Exit;
    end;
    BatchResponse := UTF8Encode(FChatGPT.Response);
    memAIReportRaw.Lines.Add(BatchResponse);
    Inc(BatchStart, BatchCount);
  end;
  UpdatedCount := 0;
  for I := 0 to memAIReportRaw.Lines.Count - 1 do
  begin
    ResponseLine := Trim(memAIReportRaw.Lines[I]);
    TabAt := Pos(#9, ResponseLine);
    if TabAt <= 1 then Continue;
    FactId := Trim(Copy(ResponseLine, 1, TabAt - 1));
    Recommendation := Trim(Copy(ResponseLine, TabAt + 1, MaxInt));
    if Recommendation = '' then Continue;
    for J := 0 to FAIReportFacts.Count - 1 do
      if SameText(FactId, DelimitedPart(FAIReportFacts[J], 0)) then
      begin
        if sgAIReport.Cells[2, J + 1] = 'PENDING' then
        begin
          sgAIReport.Cells[2, J + 1] := Recommendation;
          Inc(UpdatedCount);
        end;
        Break;
      end;
  end;

  if UpdatedCount = FAIReportFacts.Count then
  begin
    lblAIReportStatus.Caption := Format('PASS: %d factual items received recommendations.',
      [UpdatedCount]);
    SetStageStatus(10, 'PASS');
    Result := True;
  end
  else
  begin
    lblAIReportStatus.Caption := Format(
      'PARTIAL: %d of %d factual items received recommendations.',
      [UpdatedCount, FAIReportFacts.Count]);
    SetStageStatus(10, 'PARTIAL');
  end;
end;

procedure TfrmMain.btnGenerateAIReportClick(Sender: TObject);
begin
  if not FAnalysisReady then
  begin
    ShowMessage('Run the factual analysis first.');
    Exit;
  end;
  FPipelineRunning := True;
  UpdateButtons;
  try
    GenerateFinalReport;
    ExecuteAIReportStage;
    GenerateFinalReport;
  finally
    FPipelineRunning := False;
    UpdateButtons;
  end;
end;

procedure TfrmMain.UpdateCountsGrid;
var
  Row: Integer;
  K: TArtifactKind;
begin
  Row := 1;
  sgCounts.RowCount := 15;
  sgCounts.Cells[0, Row] := 'Total items';
  sgCounts.Cells[1, Row] := IntToStr(FFiles + FDirectories); Inc(Row);
  sgCounts.Cells[0, Row] := 'Directories';
  sgCounts.Cells[1, Row] := IntToStr(FDirectories); Inc(Row);
  sgCounts.Cells[0, Row] := 'Files';
  sgCounts.Cells[1, Row] := IntToStr(FFiles); Inc(Row);
  for K := Low(TArtifactKind) to High(TArtifactKind) do
  begin
    sgCounts.Cells[0, Row] := ArtifactKindLabel(K);
    sgCounts.Cells[1, Row] := IntToStr(FCounts[K]);
    Inc(Row);
  end;
end;

procedure TfrmMain.EnsureRootNode;
var
  CaptionText: string;
begin
  CaptionText := ExtractFileName(ExcludeTrailingPathDelimiter(FRootPath));
  if CaptionText = '' then CaptionText := FRootPath;
  FRootNode := tvInventory.Items.Add(nil, CaptionText);
  FTreeIndex.AddObject(NormalizePathKey(FRootPath), FRootNode);
end;

function TfrmMain.DetectRepoRoot(const AStartDir: string): string;
var
  CurDir, Probe: string;
  I: Integer;
begin
  CurDir := ExpandFileName(AStartDir);
  for I := 0 to 8 do
  begin
    Probe := IncludeTrailingPathDelimiter(CurDir);
    if DirectoryExists(Probe + 'DOC') and DirectoryExists(Probe + 'pacote') then
      Exit(ExcludeTrailingPathDelimiter(CurDir));
    CurDir := ExpandFileName(Probe + '..');
  end;
  Result := ExcludeTrailingPathDelimiter(ExpandFileName(AStartDir));
end;

procedure TfrmMain.SetDefaultRoot;
begin
  deRoot.Directory := DetectRepoRoot(ExtractFilePath(Application.ExeName));
end;

function TfrmMain.SetupFileName: string;
var
  ConfigDir: string;
begin
  {$IFDEF MSWINDOWS}
  ConfigDir := GetEnvironmentVariable('APPDATA');
  if ConfigDir = '' then
    ConfigDir := GetAppConfigDir(False);
  ConfigDir := IncludeTrailingPathDelimiter(ConfigDir) +
    'AIFrameworkGraphExplorer';
  {$ELSE}
  ConfigDir := IncludeTrailingPathDelimiter(GetUserDir) +
    '.framework_graph_explorer';
  {$ENDIF}
  Result := IncludeTrailingPathDelimiter(ConfigDir) +
    'framework_graph_explorer.ini';
end;

procedure TfrmMain.DetectToolchain;
var
  Drive, LazBuild: string;
begin
  LazBuild := FindLazBuild;
  if LazBuild <> '' then
    deLazarus.Directory := ExcludeTrailingPathDelimiter(ExtractFileDir(LazBuild));
  if (Trim(feFPC.FileName) = '') or (not FileExists(feFPC.FileName)) then
  begin
    feFPC.FileName := '';
    feFPC.FileName := FindFPC;
  end;
  if Trim(deBuildOutput.Directory) = '' then
  begin
    Drive := ExtractFileDrive(Application.ExeName);
    if Drive <> '' then
      deBuildOutput.Directory := IncludeTrailingPathDelimiter(Drive + PathDelim) +
        'fgx_sample_validation'
    else
      deBuildOutput.Directory := IncludeTrailingPathDelimiter(GetTempDir(False)) +
        'fgx_sample_validation';
  end;
  if FileExists(FindLazBuild) and FileExists(feFPC.FileName) then
    lblToolchainStatus.Caption := 'Toolchain detected. Use Test toolchain to validate it.'
  else
    lblToolchainStatus.Caption := 'Toolchain incomplete. Select Lazarus and FPC paths manually.';
end;

procedure TfrmMain.LoadSetup;
var
  Ini: TIniFile;
  ProviderIndex: Integer;
  ConfigFile, LegacyFile, LegacyLazBuild: string;
begin
  ConfigFile := SetupFileName;
  LegacyFile := ChangeFileExt(Application.ExeName, '.ini');
  if (not FileExists(ConfigFile)) and FileExists(LegacyFile) then
    ConfigFile := LegacyFile;
  if not FileExists(ConfigFile) then
  begin
    DetectToolchain;
    Exit;
  end;
  Ini := TIniFile.Create(ConfigFile);
  try
    ProviderIndex := Ini.ReadInteger('AI', 'Provider', cbProvider.ItemIndex);
    if (ProviderIndex >= 0) and (ProviderIndex < cbProvider.Items.Count) then
      cbProvider.ItemIndex := ProviderIndex;
    cbProviderChange(nil);
    edtModel.Text := Ini.ReadString('AI', 'Model', edtModel.Text);
    edtEndpoint.Text := Ini.ReadString('AI', 'Endpoint', edtEndpoint.Text);
    edtToken.Text := Ini.ReadString('AI', 'Token', '');
    deLazarus.Directory := Ini.ReadString('Toolchain', 'LazarusPath', '');
    if deLazarus.Directory = '' then
    begin
      LegacyLazBuild := Ini.ReadString('Toolchain', 'LazBuild', '');
      if FileExists(LegacyLazBuild) then
        deLazarus.Directory := ExtractFileDir(LegacyLazBuild);
    end;
    feFPC.FileName := Ini.ReadString('Toolchain', 'FPC', '');
    deBuildOutput.Directory := Ini.ReadString('Toolchain', 'BuildOutput', '');
  finally
    Ini.Free;
  end;
  DetectToolchain;
  if CompareText(ConfigFile, SetupFileName) <> 0 then
    SaveSetup;
end;

procedure TfrmMain.ProtectSetupFile;
begin
  {$IFDEF UNIX}
  if FileExists(SetupFileName) then
    fpChmod(PChar(SetupFileName), &600);
  {$ENDIF}
end;

procedure TfrmMain.SaveSetup;
var
  Ini: TIniFile;
begin
  ForceDirectories(ExtractFileDir(SetupFileName));
  Ini := TIniFile.Create(SetupFileName);
  try
    Ini.WriteInteger('AI', 'Provider', cbProvider.ItemIndex);
    Ini.WriteString('AI', 'Model', edtModel.Text);
    Ini.WriteString('AI', 'Endpoint', edtEndpoint.Text);
    Ini.WriteString('AI', 'Token', edtToken.Text);
    Ini.WriteString('Toolchain', 'LazarusPath', deLazarus.Directory);
    Ini.DeleteKey('Toolchain', 'LazBuild');
    Ini.WriteString('Toolchain', 'FPC', feFPC.FileName);
    Ini.WriteString('Toolchain', 'BuildOutput', deBuildOutput.Directory);
    Ini.UpdateFile;
  finally
    Ini.Free;
  end;
  ProtectSetupFile;
end;

procedure TfrmMain.btnDetectToolchainClick(Sender: TObject);
begin
  deLazarus.Directory := '';
  feFPC.FileName := '';
  DetectToolchain;
end;

procedure TfrmMain.btnSaveSetupClick(Sender: TObject);
begin
  SaveSetup;
  lblToolchainStatus.Caption := 'Setup saved to ' + SetupFileName +
    '. The API token was saved in the user profile.';
end;

procedure TfrmMain.btnTestToolchainClick(Sender: TObject);
var
  Args: TStringList;
  Output, LazBuild: string;
  ExitCode: Integer;
begin
  DetectToolchain;
  LazBuild := FindLazBuild;
  if (not FileExists(LazBuild)) or (not FileExists(feFPC.FileName)) then
  begin
    lblToolchainStatus.Caption := 'FAIL: select valid Lazarus and FPC paths.';
    Exit;
  end;
  Args := TStringList.Create;
  try
    Args.Add('-iV');
    if not RunTool(feFPC.FileName, Args, ExtractFileDir(feFPC.FileName),
      Output, ExitCode) then
    begin
      lblToolchainStatus.Caption := Format('FAIL: fpc returned exit code %d.', [ExitCode]);
      Exit;
    end;
    Args.Clear;
    Args.Add('--version');
    if not RunTool(LazBuild, Args, ExtractFileDir(LazBuild),
      Output, ExitCode) then
    begin
      lblToolchainStatus.Caption := Format('FAIL: lazbuild returned exit code %d.',
        [ExitCode]);
      Exit;
    end;
    lblToolchainStatus.Caption := 'PASS: FPC and lazbuild are configured.';
  finally
    Args.Free;
  end;
end;

procedure TfrmMain.FormCreate(Sender: TObject);
begin
  FScanner := TAIDiskTreeScanner.Create(Self);
  FGraph := TAIDependencyGraph.Create(Self);
  FChatGPT := TCHATGPT.Create(Self);
  FTXTOutput := TAITXTOutput.Create(Self);
  FAIReportFacts := TStringList.Create;
  FFindings := TFGXFindingList.Create;
  FHistoryFindings := TFGXFindingList.Create;
  FHistorySummary := TStringList.Create;
  FTreeIndex := TStringList.Create;
  FTreeIndex.Sorted := True;
  FTreeIndex.Duplicates := dupIgnore;
  FTreeIndex.CaseSensitive := False;

  FScanner.OnTaskStart := @ScannerTaskStart;
  FScanner.OnItemFound := @ScannerItemFound;
  FScanner.OnProgress := @ScannerProgress;
  FScanner.OnTaskFinish := @ScannerTaskFinish;
  FScanner.OnError := @ScannerError;

  ConfigureGrid(sgCounts, ['Type', 'Count']);
  ConfigureGrid(sgPackages, ['Package', 'Type / status', 'Depends on']);
  ConfigureGrid(sgComponents, ['Package', 'Component', 'Palette', 'Samples']);
  ConfigureGrid(sgSamples, ['Sample', 'Project', 'Used components', 'Build', 'Execution']);
  ConfigureGrid(sgAIReport, ['Where', 'What', 'AI recommendation']);
  InitializeStages;
  sgCounts.ColWidths[0] := 220;
  sgCounts.ColWidths[1] := 110;
  sgPackages.ColWidths[0] := 180;
  sgPackages.ColWidths[1] := 130;
  sgPackages.ColWidths[2] := 700;
  sgComponents.ColWidths[0] := 180;
  sgComponents.ColWidths[1] := 220;
  sgComponents.ColWidths[2] := 140;
  sgComponents.ColWidths[3] := 560;
  sgSamples.ColWidths[0] := 220;
  sgSamples.ColWidths[1] := 390;
  sgSamples.ColWidths[2] := 310;
  sgSamples.ColWidths[3] := 100;
  sgSamples.ColWidths[4] := 100;
  sgAIReport.ColWidths[0] := 380;
  sgAIReport.ColWidths[1] := 430;
  sgAIReport.ColWidths[2] := 470;

  cbProvider.Items.Add('Offline (no AI)');
  cbProvider.Items.Add('OpenAI');
  cbProvider.Items.Add('OpenRouter');
  cbProvider.Items.Add('Cerebras');
  cbProvider.Items.Add('Ollama / local');
  cbProvider.Items.Add('Google Gemini');
  cbProvider.Items.Add('Anthropic Claude');
  cbProvider.ItemIndex := 0;
  cbProviderChange(nil);
  LoadSetup;
  chkCompileSamples.Checked := True;
  chkUseAI.Checked := True;
  ConfigureScanner;
  SetDefaultRoot;
  UpdateCountsGrid;
  UpdateButtons;
  UpdateStatus('Ready to analyze.');
  AddLog('Application started. Factual analysis is available without AI.');
  ConfigureCommandLine;
end;

procedure TfrmMain.FormDestroy(Sender: TObject);
begin
  FScanner.Cancel;
  FHistorySummary.Free;
  FHistoryFindings.Free;
  FFindings.Free;
  FAIReportFacts.Free;
  FTreeIndex.Free;
end;

procedure TfrmMain.btnAnalyzeClick(Sender: TObject);
begin
  if (Trim(deRoot.Directory) = '') or (not DirectoryExists(deRoot.Directory)) then
  begin
    ShowMessage('Choose a valid repository root.');
    Exit;
  end;
  FRootPath := ExcludeTrailingPathDelimiter(ExpandFileName(deRoot.Directory));
  ResetView;
  ConfigureScanner;
  FCancelRequested := False;
  FScanRunning := True;
  FPipelineRunning := True;
  UpdateButtons;
  UpdateStatus('Step 1/10: inventory scan.');
  AddLog('Starting analysis of ' + FRootPath);
  ProgressBar1.Style := pbstNormal;
  FScanner.RootPath := FRootPath;
  FScanner.BuildDatasetInventoryAsync(FRootPath, True);
end;

procedure TfrmMain.btnStopClick(Sender: TObject);
begin
  FCancelRequested := True;
  FScanner.Cancel;
  UpdateStatus('Cancelling the pipeline after the current operation...');
end;

procedure TfrmMain.ScannerTaskStart(Sender: TObject; TaskId: Integer;
  const Description: string);
begin
  tvInventory.Items.BeginUpdate;
  EnsureRootNode;
  SetStageStatus(1, 'RUNNING');
  AddLog('Scanner: ' + Description);
end;

procedure TfrmMain.ScannerItemFound(Sender: TObject; TaskId: Integer; Item: TAIDiskItem);
var
  ParentNode, Node: TTreeNode;
  Kind: TArtifactKind;
begin
  if not Assigned(Item) then Exit;
  ParentNode := EnsureTreeNode(Item.ParentPath,
    ExtractFileName(ExcludeTrailingPathDelimiter(Item.ParentPath)));
  if not Assigned(ParentNode) then ParentNode := FRootNode;
  Node := EnsureTreeNode(Item.FullPath, Item.Name);
  if Assigned(Node) and Assigned(ParentNode) and (Node.Parent <> ParentNode) then
    Node.MoveTo(ParentNode, naAddChild);
  if Item.ItemType = ditDirectory then
    Inc(FDirectories)
  else
  begin
    Inc(FFiles);
    Kind := ArtifactKindForItem(Item);
    Inc(FCounts[Kind]);
  end;
end;

procedure TfrmMain.ScannerProgress(Sender: TObject; TaskId: Integer;
  ProcessedDirs, ProcessedFiles, FoundItems: Int64; const CurrentPath: string);
begin
  UpdateStatus(Format('Directories: %d | Files: %d | Items: %d | %s',
    [ProcessedDirs, ProcessedFiles, FoundItems, CurrentPath]));
end;

procedure TfrmMain.ScannerTaskFinish(Sender: TObject; TaskId: Integer;
  State: TAIDiskTaskState; TotalDirs, TotalFiles, TotalFound: Int64;
  const ErrorMsg: string);
var
  Passed: Boolean;
begin
  tvInventory.Items.EndUpdate;
  ProgressBar1.Style := pbstNormal;
  FScanRunning := False;
  UpdateCountsGrid;
  if State = dtsFinished then
  begin
    SetStageStatus(1, 'PASS');
    AddLog('Step 1/10 Inventory scan: PASS');
    UpdateStatus('Step 2/10: reading packages and units...');
    Application.ProcessMessages;
    Passed := BuildFactualGraph(FRootPath, FScanner, FGraph, memLog.Lines,
      @AnalyzerStage, FAnalysisStats);
    FAnalysisReady := FGraph.NodeCount > 0;
    PopulateAnalysisViews;
    SaveArtifacts;
    if Passed and (not FCancelRequested) then
    begin
      if chkCompileSamples.Checked then
        ExecuteSampleStage
      else
        SetStageStatus(7, 'SKIPPED');

      if chkUseAI.Checked and (not FCancelRequested) then
        ExecuteAIStage
      else
        SetStageStatus(8, 'SKIPPED');
    end
    else
    begin
      SetStageStatus(7, 'SKIPPED');
      SetStageStatus(8, 'SKIPPED');
    end;
    UpdateHistory;
    GenerateFinalReport;
    if Passed and chkUseAI.Checked and (not FCancelRequested) then
      ExecuteAIReportStage
    else
    begin
      BuildAIReportFacts;
      PopulateAIReportFacts('SKIPPED: AI report was not requested.');
      lblAIReportStatus.Caption := 'SKIPPED: AI report was not requested.';
      SetStageStatus(10, 'SKIPPED');
    end;
    GenerateFinalReport;
    if Passed and (not FCancelRequested) then
      UpdateStatus(Format('Pipeline completed: %d packages, %d components, %d samples.',
        [FAnalysisStats.Packages, FAnalysisStats.Components, FAnalysisStats.Samples]))
    else if FCancelRequested then
      UpdateStatus('Pipeline cancelled. A partial report was generated.')
    else
      UpdateStatus('FAIL: the factual graph did not pass validation.');
  end
  else if State = dtsCancelled then
  begin
    SetStageStatus(1, 'CANCELLED');
    UpdateStatus('Scan cancelled.');
  end
  else
  begin
    SetStageStatus(1, 'FAIL');
    UpdateStatus('Scanner error: ' + ErrorMsg);
  end;
  FPipelineRunning := False;
  UpdateButtons;
  FinishHeadless;
end;

procedure TfrmMain.ScannerError(Sender: TObject; TaskId: Integer; const Path,
  ErrorMsg: string);
begin
  AddLog('Scanner WARN at ' + Path + ': ' + ErrorMsg);
end;

procedure TfrmMain.PopulateAnalysisViews;
begin
  PopulatePackages;
  PopulateComponents;
  PopulateSamples;
end;

procedure TfrmMain.PopulatePackages;
var
  I, J, Row: Integer;
  N, Target: TAIDependencyNode;
  E: TAIDependencyEdge;
  Values: TStringList;
begin
  sgPackages.RowCount := FAnalysisStats.Packages + 1;
  if sgPackages.RowCount < 2 then sgPackages.RowCount := 2;
  Row := 1;
  Values := TStringList.Create;
  try
    for I := 0 to FGraph.Nodes.Count - 1 do
    begin
      N := FGraph.Nodes[I];
      if N.NodeType <> AIDG_NODE_PACKAGE then Continue;
      Values.Clear;
      for J := 0 to FGraph.Edges.Count - 1 do
      begin
        E := FGraph.Edges[J];
        if (E.FromId = N.Id) and (E.EdgeType = AIDG_EDGE_REQUIRES_PACKAGE) then
        begin
          Target := FGraph.FindNode(E.ToId);
          if Assigned(Target) then Values.Add(Target.Name);
        end;
      end;
      sgPackages.Cells[0, Row] := N.Name;
      sgPackages.Cells[1, Row] := N.Attrs.Values['package_type'] + ' / ' +
        N.Attrs.Values['status'];
      sgPackages.Cells[2, Row] := JoinValues(Values, ', ');
      Inc(Row);
    end;
  finally
    Values.Free;
  end;
end;

procedure TfrmMain.PopulateComponents;
var
  I, J, Row: Integer;
  N, SampleNode: TAIDependencyNode;
  E: TAIDependencyEdge;
  Values: TStringList;
begin
  sgComponents.RowCount := FAnalysisStats.Components + 1;
  if sgComponents.RowCount < 2 then sgComponents.RowCount := 2;
  Row := 1;
  Values := TStringList.Create;
  try
    for I := 0 to FGraph.Nodes.Count - 1 do
    begin
      N := FGraph.Nodes[I];
      if N.NodeType <> AIDG_NODE_COMPONENT then Continue;
      Values.Clear;
      for J := 0 to FGraph.Edges.Count - 1 do
      begin
        E := FGraph.Edges[J];
        if (E.FromId = N.Id) and (E.EdgeType = AIDG_EDGE_DEMONSTRATED_BY) then
        begin
          SampleNode := FGraph.FindNode(E.ToId);
          if Assigned(SampleNode) then Values.Add(SampleNode.Name);
        end;
      end;
      sgComponents.Cells[0, Row] := N.Attrs.Values['package'];
      sgComponents.Cells[1, Row] := N.Name;
      sgComponents.Cells[2, Row] := N.Attrs.Values['palette'];
      if Values.Count = 0 then
        sgComponents.Cells[3, Row] := 'ORPHAN: no sample found'
      else
        sgComponents.Cells[3, Row] := JoinValues(Values, ', ');
      Inc(Row);
    end;
  finally
    Values.Free;
  end;
end;

procedure TfrmMain.PopulateSamples;
var
  I, J, Row: Integer;
  N, ComponentNode: TAIDependencyNode;
  E: TAIDependencyEdge;
  Values: TStringList;
begin
  sgSamples.RowCount := FAnalysisStats.Samples + 1;
  if sgSamples.RowCount < 2 then sgSamples.RowCount := 2;
  Row := 1;
  Values := TStringList.Create;
  try
    for I := 0 to FGraph.Nodes.Count - 1 do
    begin
      N := FGraph.Nodes[I];
      if N.NodeType <> AIDG_NODE_SAMPLE then Continue;
      Values.Clear;
      for J := 0 to FGraph.Edges.Count - 1 do
      begin
        E := FGraph.Edges[J];
        if (E.ToId = N.Id) and (E.EdgeType = AIDG_EDGE_DEMONSTRATED_BY) then
        begin
          ComponentNode := FGraph.FindNode(E.FromId);
          if Assigned(ComponentNode) then Values.Add(ComponentNode.Name);
        end;
      end;
      sgSamples.Cells[0, Row] := N.Name;
      sgSamples.Cells[1, Row] := N.Path;
      sgSamples.Cells[2, Row] := JoinValues(Values, ', ');
      sgSamples.Cells[3, Row] := N.Attrs.Values['build_status'];
      sgSamples.Cells[4, Row] := N.Attrs.Values['run_status'];
      sgSamples.Objects[0, Row] := N;
      Inc(Row);
    end;
  finally
    Values.Free;
  end;
end;

procedure TfrmMain.cbProviderChange(Sender: TObject);
begin
  edtToken.Enabled := cbProvider.ItemIndex <> 0;
  edtModel.Enabled := cbProvider.ItemIndex <> 0;
  edtEndpoint.Enabled := cbProvider.ItemIndex <> 0;
  case cbProvider.ItemIndex of
    0: begin edtModel.Text := ''; edtEndpoint.Text := ''; end;
    1: begin edtModel.Text := 'gpt-4o-mini'; edtEndpoint.Text := 'https://api.openai.com/v1/chat/completions'; end;
    2: begin edtModel.Text := 'google/gemma-2-9b-it:free'; edtEndpoint.Text := 'https://openrouter.ai/api/v1/chat/completions'; end;
    3: begin edtModel.Text := 'qwen-3-235b-a22b-instruct-2507'; edtEndpoint.Text := 'https://api.cerebras.ai/v1/chat/completions'; end;
    4: begin edtModel.Text := 'llama3.2:3b'; edtEndpoint.Text := 'http://localhost:11434'; end;
    5: begin edtModel.Text := 'gemini-2.5-flash'; edtEndpoint.Text := ''; end;
    6: begin edtModel.Text := 'claude-3-5-sonnet-20241022'; edtEndpoint.Text := 'https://api.anthropic.com/v1/messages'; end;
  end;
end;

function TfrmMain.ConfigureAI: Boolean;
begin
  Result := False;
  if cbProvider.ItemIndex = 0 then
  begin
    lblAIStatus.Caption := 'SKIPPED: offline mode selected.';
    Exit;
  end;
  case cbProvider.ItemIndex of
    1: FChatGPT.Provider := AIP_OPENAI;
    2: FChatGPT.Provider := AIP_OPENROUTER;
    3: FChatGPT.Provider := AIP_CEREBRAS;
    4: FChatGPT.Provider := AIP_LOCAL;
    5: FChatGPT.Provider := AIP_GEMINI;
    6: FChatGPT.Provider := AIP_CLAUDE;
  end;
  if (FChatGPT.Provider <> AIP_LOCAL) and (Trim(edtToken.Text) = '') then
  begin
    lblAIStatus.Caption := 'SKIPPED: enter a token on the Setup tab.';
    Exit;
  end;
  FChatGPT.TOKEN := UTF8Decode(edtToken.Text);
  FChatGPT.TipoChat := VCT_CUSTOM;
  FChatGPT.CustomModel := UTF8Decode(edtModel.Text);
  FChatGPT.MaxTokens := 3000;
  if FChatGPT.Provider = AIP_LOCAL then
  begin
    FChatGPT.LocalIP := UTF8Decode(edtEndpoint.Text);
    FChatGPT.URL := '';
  end
  else
    FChatGPT.URL := UTF8Decode(edtEndpoint.Text);
  FChatGPT.Dev := UTF8Decode(
    'You are a software architect. Analyze only the supplied facts. ' +
    'Separate proven issues from recommendations and never invent packages, components, or samples.');
  Result := True;
end;

function TfrmMain.BuildAIContext: string;
var
  I, Orphans, Covered, BuildPass, BuildFail, NotTested: Integer;
  N: TAIDependencyNode;
  HasSample: Boolean;
  J: Integer;
begin
  Orphans := 0; Covered := 0; BuildPass := 0; BuildFail := 0; NotTested := 0;
  for I := 0 to FGraph.Nodes.Count - 1 do
  begin
    N := FGraph.Nodes[I];
    if N.NodeType = AIDG_NODE_COMPONENT then
    begin
      HasSample := False;
      for J := 0 to FGraph.Edges.Count - 1 do
        if (FGraph.Edges[J].FromId = N.Id) and
           (FGraph.Edges[J].EdgeType = AIDG_EDGE_DEMONSTRATED_BY) then
          HasSample := True;
      if not HasSample then Inc(Orphans) else Inc(Covered);
    end
    else if N.NodeType = AIDG_NODE_SAMPLE then
    begin
      if N.Attrs.Values['build_status'] = 'PASS' then Inc(BuildPass)
      else if N.Attrs.Values['build_status'] = 'FAIL' then Inc(BuildFail)
      else Inc(NotTested);
    end;
  end;
  Result := Format(
    'Analyzed repository: %s'#13#10 +
    'Factual graph validated: %s'#13#10 +
    'Packages: %d; units: %d; components: %d; samples: %d.'#13#10 +
    'Package dependencies: %d; component/sample links: %d.'#13#10 +
    'Component coverage: total=%d, with sample=%d, orphans=%d.'#13#10 +
    'Sample builds: PASS=%d, FAIL=%d, NOT TESTED=%d.'#13#10#13#10 +
    'Assess package coupling, sample coverage gaps, and test priorities. ' +
    'Clearly label every conclusion as FACT or RECOMMENDATION.',
    [FRootPath, BoolToStr(FGraph.Validated, True), FAnalysisStats.Packages,
     FAnalysisStats.Units, FAnalysisStats.Components, FAnalysisStats.Samples,
     FAnalysisStats.PackageLinks, FAnalysisStats.ComponentSampleLinks,
     FAnalysisStats.Components, Covered, Orphans,
     BuildPass, BuildFail, NotTested]);
end;

function TfrmMain.ExecuteAIStage: Boolean;
begin
  Result := False;
  SetStageStatus(8, 'RUNNING');
  if not ConfigureAI then
  begin
    SetStageStatus(8, 'SKIPPED');
    AddLog(lblAIStatus.Caption);
    Exit;
  end;
  lblAIStatus.Caption := 'Querying ' + UTF8Encode(FChatGPT.ProviderName) + '...';
  memAI.Text := 'Waiting for response...';
  Screen.Cursor := crHourGlass;
  Application.ProcessMessages;
  try
    if FChatGPT.SendQuestion(UTF8Decode(BuildAIContext)) then
    begin
      Result := True;
      memAI.Text := UTF8Encode(FChatGPT.Response);
      lblAIStatus.Caption := 'PASS: analysis received from ' +
        UTF8Encode(FChatGPT.TipoModelo) + '.';
      AddLog(lblAIStatus.Caption);
      SetStageStatus(8, 'PASS');
    end
    else
    begin
      memAI.Text := UTF8Encode(FChatGPT.Response);
      lblAIStatus.Caption := 'FAIL: ' + FChatGPT.LastError;
      AddLog(lblAIStatus.Caption);
      SetStageStatus(8, 'FAIL');
    end;
  finally
    Screen.Cursor := crDefault;
  end;
end;

procedure TfrmMain.btnAnalyzeAIClick(Sender: TObject);
begin
  FPipelineRunning := True;
  FCancelRequested := False;
  UpdateButtons;
  try
    ExecuteAIStage;
    GenerateFinalReport;
  finally
    FPipelineRunning := False;
    UpdateButtons;
  end;
end;

function TfrmMain.FindLazBuild: string;
var
  Candidate, LazarusDir: string;
begin
  if Assigned(deLazarus) then
  begin
    LazarusDir := ExcludeTrailingPathDelimiter(Trim(deLazarus.Directory));
    Candidate := IncludeTrailingPathDelimiter(LazarusDir) + 'lazbuild.exe';
    if (LazarusDir <> '') and FileExists(Candidate) then Exit(Candidate);
    Candidate := IncludeTrailingPathDelimiter(LazarusDir) + 'lazbuild';
    if (LazarusDir <> '') and FileExists(Candidate) then Exit(Candidate);
  end;
  Result := GetEnvironmentVariable('LAZBUILD');
  if (Result <> '') and FileExists(Result) then Exit;
  LazarusDir := GetEnvironmentVariable('LAZARUS');
  if DirectoryExists(LazarusDir) then
  begin
    Candidate := IncludeTrailingPathDelimiter(LazarusDir) + 'lazbuild.exe';
    if FileExists(Candidate) then Exit(Candidate);
    Candidate := IncludeTrailingPathDelimiter(LazarusDir) + 'lazbuild';
    if FileExists(Candidate) then Exit(Candidate);
  end;
  Candidate := FileSearch('lazbuild.exe', GetEnvironmentVariable('PATH'));
  if Candidate = '' then Candidate := FileSearch('lazbuild', GetEnvironmentVariable('PATH'));
  if Candidate <> '' then Exit(Candidate);
  Candidate := 'C:\lazarus\lazbuild.exe';
  if FileExists(Candidate) then Exit(Candidate);
  Candidate := IncludeTrailingPathDelimiter(ExtractFilePath(Application.ExeName)) + 'lazbuild.exe';
  if FileExists(Candidate) then Exit(Candidate);
  Result := '';
end;

function TfrmMain.FindFPC: string;
const
  TargetDirs: array[0..2] of string = ('i386-win32', 'x86_64-win64', '');
var
  Candidate, LazarusRoot, FpcRoot, BinRoot: string;
  SearchRec: TSearchRec;
  I: Integer;
begin
  if Assigned(feFPC) and FileExists(feFPC.FileName) then
    Exit(feFPC.FileName);
  Result := GetEnvironmentVariable('FPC');
  if (Result <> '') and FileExists(Result) then Exit;

  Candidate := FileSearch('fpc.exe', GetEnvironmentVariable('PATH'));
  if Candidate = '' then Candidate := FileSearch('fpc', GetEnvironmentVariable('PATH'));
  if Candidate <> '' then Exit(Candidate);

  LazarusRoot := '';
  if Assigned(deLazarus) and DirectoryExists(deLazarus.Directory) then
    LazarusRoot := ExcludeTrailingPathDelimiter(deLazarus.Directory);
  if LazarusRoot = '' then
    LazarusRoot := ExcludeTrailingPathDelimiter(ExtractFilePath(FindLazBuild));
  if LazarusRoot = '' then LazarusRoot := 'C:\lazarus';
  FpcRoot := IncludeTrailingPathDelimiter(LazarusRoot) + 'fpc';
  if FindFirst(IncludeTrailingPathDelimiter(FpcRoot) + '*', faDirectory, SearchRec) = 0 then
  try
    repeat
      if ((SearchRec.Attr and faDirectory) = 0) or
         (SearchRec.Name = '.') or (SearchRec.Name = '..') then Continue;
      BinRoot := IncludeTrailingPathDelimiter(FpcRoot) + SearchRec.Name +
        PathDelim + 'bin';
      for I := Low(TargetDirs) to High(TargetDirs) do
      begin
        if TargetDirs[I] = '' then
          Candidate := IncludeTrailingPathDelimiter(BinRoot) + 'fpc.exe'
        else
          Candidate := IncludeTrailingPathDelimiter(BinRoot) + TargetDirs[I] +
            PathDelim + 'fpc.exe';
        if FileExists(Candidate) then Exit(Candidate);
      end;
    until FindNext(SearchRec) <> 0;
  finally
    FindClose(SearchRec);
  end;

  Candidate := 'C:\lazarus\fpc\3.2.2\bin\i386-win32\fpc.exe';
  if FileExists(Candidate) then Exit(Candidate);
  Result := '';
end;

function TfrmMain.BuildOutputRoot: string;
var
  Drive: string;
begin
  Result := Trim(deBuildOutput.Directory);
  if Result <> '' then Exit(ExcludeTrailingPathDelimiter(ExpandFileName(Result)));
  Drive := ExtractFileDrive(FRootPath);
  if Drive = '' then Drive := ExtractFileDrive(Application.ExeName);
  if Drive <> '' then
    Result := IncludeTrailingPathDelimiter(Drive + PathDelim) +
      'fgx_sample_validation'
  else
    Result := IncludeTrailingPathDelimiter(GetTempDir(False)) +
      'fgx_sample_validation';
  Result := ExcludeTrailingPathDelimiter(Result);
end;

function TfrmMain.ResolveRepoPath(const APath: string): string;
begin
  if (ExtractFileDrive(APath) <> '') or
     ((APath <> '') and ((APath[1] = PathDelim) or (APath[1] = '/'))) then
    Exit(ExpandFileName(APath));
  Result := ExpandFileName(IncludeTrailingPathDelimiter(FRootPath) +
    StringReplace(APath, '/', PathDelim, [rfReplaceAll]));
end;

function TfrmMain.SafePathSegment(const AValue: string): string;
var
  I: Integer;
begin
  Result := AValue;
  for I := 1 to Length(Result) do
    if not (Result[I] in ['a'..'z', 'A'..'Z', '0'..'9', '-', '_', '.']) then
      Result[I] := '_';
  if Result = '' then Result := 'sample';
end;

function TfrmMain.ResolveValidationExecutable(
  ANode: TAIDependencyNode): string;
var
  RelativeName: string;
begin
  Result := '';
  if not Assigned(ANode) then Exit;
  RelativeName := ANode.Attrs.Values['validation_executable'];
  if RelativeName = '' then Exit;
  if ExtractFileDrive(RelativeName) <> '' then Exit(RelativeName);
  Result := ExpandFileName(IncludeTrailingPathDelimiter(BuildOutputRoot) +
    StringReplace(RelativeName, '/', PathDelim, [rfReplaceAll]));
end;

function TfrmMain.RunTool(const AExecutable: string; AArguments: TStrings;
  const AWorkingDir: string; out AOutput: string; out AExitCode: Integer): Boolean;
var
  P: TProcess;
  Buffer: array[0..4095] of Byte;
  Count, I, PathIndex: LongInt;
  OutputStream: TMemoryStream;
  EnvironmentPath, FpcPath: string;
begin
  Result := False;
  AOutput := '';
  AExitCode := -1;
  P := TProcess.Create(nil);
  OutputStream := TMemoryStream.Create;
  try
    FillChar(Buffer, SizeOf(Buffer), 0);
    P.Executable := AExecutable;
    P.Parameters.Assign(AArguments);
    P.CurrentDirectory := AWorkingDir;
    for I := 1 to GetEnvironmentVariableCount do
      P.Environment.Add(GetEnvironmentString(I));
    EnvironmentPath := GetEnvironmentVariable('PATH');
    FpcPath := FindFPC;
    EnvironmentPath := ExtractFilePath(AExecutable) + PathSeparator +
      ExtractFilePath(FpcPath) + PathSeparator + EnvironmentPath;
    PathIndex := P.Environment.IndexOfName('PATH');
    if PathIndex >= 0 then
      P.Environment.ValueFromIndex[PathIndex] := EnvironmentPath
    else
      P.Environment.Add('PATH=' + EnvironmentPath);
    if FpcPath <> '' then
      P.Environment.Values['FPC'] := FpcPath;
    P.Options := [poUsePipes, poStderrToOutPut];
    P.ShowWindow := swoHide;
    try
      P.Execute;
      while P.Running do
      begin
        if FCancelRequested then
        begin
          P.Terminate(1);
          Break;
        end;
        while P.Output.NumBytesAvailable > 0 do
        begin
          Count := P.Output.Read(Buffer, SizeOf(Buffer));
          if Count > 0 then OutputStream.WriteBuffer(Buffer, Count);
        end;
        Application.ProcessMessages;
        Sleep(15);
      end;
      repeat
        Count := P.Output.Read(Buffer, SizeOf(Buffer));
        if Count > 0 then OutputStream.WriteBuffer(Buffer, Count);
      until Count <= 0;
      AExitCode := P.ExitStatus;
      if OutputStream.Size > 0 then
      begin
        SetLength(AOutput, OutputStream.Size);
        OutputStream.Position := 0;
        OutputStream.ReadBuffer(AOutput[1], OutputStream.Size);
      end;
      Result := AExitCode = 0;
    except
      on E: Exception do
      begin
        AOutput := E.Message;
        AExitCode := -1;
      end;
    end;
  finally
    OutputStream.Free;
    P.Free;
  end;
end;

procedure TfrmMain.SetSampleStatus(ANode: TAIDependencyNode; const ABuild,
  ARun: string);
begin
  if not Assigned(ANode) then Exit;
  if ABuild <> '' then ANode.Attrs.Values['build_status'] := ABuild;
  if ARun <> '' then ANode.Attrs.Values['run_status'] := ARun;
end;

function TfrmMain.CompileSample(ANode: TAIDependencyNode): Boolean;
var
  LazBuild, FpcPath, ProjectFile, Output, ValidationRoot, ValidationDir, UnitsDir,
    ValidationExe, ValidationRel: string;
  ExitCode: Integer;
  Args: TStringList;
begin
  Result := False;
  if not Assigned(ANode) then Exit;
  LazBuild := FindLazBuild;
  if LazBuild = '' then
  begin
    SetSampleStatus(ANode, 'SKIPPED', '');
    AddLog('SKIPPED ' + ANode.Name + ': lazbuild was not found.');
    Exit;
  end;
  FpcPath := FindFPC;
  if FpcPath = '' then
  begin
    SetSampleStatus(ANode, 'SKIPPED', '');
    AddLog('SKIPPED ' + ANode.Name + ': fpc.exe was not found.');
    Exit;
  end;
  ProjectFile := ResolveRepoPath(ANode.Attrs.Values['project_file']);
  ValidationRoot := BuildOutputRoot;
  ValidationRel := SafePathSegment(ANode.Id) + '/' +
    ChangeFileExt(ExtractFileName(ProjectFile), '.exe');
  ValidationDir := IncludeTrailingPathDelimiter(ValidationRoot) +
    SafePathSegment(ANode.Id);
  UnitsDir := IncludeTrailingPathDelimiter(ValidationDir) + 'units';
  ForceDirectories(UnitsDir);
  ValidationExe := IncludeTrailingPathDelimiter(ValidationDir) +
    ChangeFileExt(ExtractFileName(ProjectFile), '.exe');
  Args := TStringList.Create;
  try
    Args.Add('--build-all');
    Args.Add('--ws=win32');
    Args.Add('--compiler=' + FpcPath);
    Args.Add('--opt=-o' + ValidationExe);
    Args.Add('--opt=-FU' + UnitsDir);
    Args.Add(ProjectFile);
    AddLog('Building sample ' + ANode.Name + '...');
    Result := RunTool(LazBuild, Args, ExtractFileDir(ProjectFile), Output, ExitCode);
    ANode.Attrs.Values['build_exit_code'] := IntToStr(ExitCode);
    ANode.Attrs.Values['validation_executable'] := ValidationRel;
    if Result then
    begin
      SetSampleStatus(ANode, 'PASS', '');
      AddLog(Format('PASS %s (exit code %d).', [ANode.Name, ExitCode]));
    end
    else
    begin
      SetSampleStatus(ANode, 'FAIL', '');
      AddLog(Format('FAIL %s (exit code %d).', [ANode.Name, ExitCode]));
      memLog.Lines.Add(Output);
    end;
  finally
    Args.Free;
  end;
end;

function TfrmMain.ExecuteSampleStage: Boolean;
var
  I, Passed, Failed, Skipped: Integer;
  N: TAIDependencyNode;
begin
  Result := False;
  Passed := 0; Failed := 0; Skipped := 0;
  SetStageStatus(7, 'RUNNING');
  Screen.Cursor := crHourGlass;
  try
    for I := 0 to FGraph.Nodes.Count - 1 do
    begin
      if FCancelRequested then Break;
      N := FGraph.Nodes[I];
      if N.NodeType <> AIDG_NODE_SAMPLE then Continue;
      if CompileSample(N) then Inc(Passed)
      else if N.Attrs.Values['build_status'] = 'SKIPPED' then Inc(Skipped)
      else Inc(Failed);
      PopulateSamples;
      Application.ProcessMessages;
    end;
    AddLog(Format('Samples: PASS=%d, FAIL=%d, SKIPPED=%d.', [Passed, Failed, Skipped]));
    if FCancelRequested then
      SetStageStatus(7, 'CANCELLED')
    else if Failed > 0 then
      SetStageStatus(7, 'FAIL')
    else if (Passed = 0) and (Skipped > 0) then
      SetStageStatus(7, 'SKIPPED')
    else if Skipped > 0 then
      SetStageStatus(7, 'PARTIAL')
    else
    begin
      SetStageStatus(7, 'PASS');
      Result := True;
    end;
    SaveArtifacts;
  finally
    Screen.Cursor := crDefault;
  end;
end;

procedure TfrmMain.btnCompileSamplesClick(Sender: TObject);
begin
  FPipelineRunning := True;
  FCancelRequested := False;
  UpdateButtons;
  try
    ExecuteSampleStage;
    GenerateFinalReport;
  finally
    FPipelineRunning := False;
    UpdateButtons;
  end;
end;

function TfrmMain.SelectedSampleNode: TAIDependencyNode;
begin
  Result := nil;
  if (sgSamples.Row > 0) and (sgSamples.Row < sgSamples.RowCount) then
    Result := TAIDependencyNode(sgSamples.Objects[0, sgSamples.Row]);
end;

procedure TfrmMain.btnOpenSampleClick(Sender: TObject);
var
  N: TAIDependencyNode;
  ExeFile, ProjectFile: string;
  P: TProcess;
begin
  N := SelectedSampleNode;
  if not Assigned(N) then
  begin
    ShowMessage('Select a sample in the table.');
    Exit;
  end;
  if N.Attrs.Values['build_status'] <> 'PASS' then
    if not CompileSample(N) then
    begin
      PopulateSamples;
      ShowMessage('The sample did not build. See the Log tab.');
      Exit;
    end;
  ProjectFile := N.Attrs.Values['project_file'];
  ProjectFile := ResolveRepoPath(ProjectFile);
  ExeFile := ResolveValidationExecutable(N);
  if ExeFile = '' then ExeFile := ChangeFileExt(ProjectFile, '.exe');
  if not FileExists(ExeFile) then
  begin
    SetSampleStatus(N, '', 'SKIPPED');
    PopulateSamples;
    ShowMessage('The project built, but its executable is not next to the .lpi file. ' +
      'Check the sample output configuration.');
    Exit;
  end;
  P := TProcess.Create(nil);
  try
    P.Executable := ExeFile;
    P.CurrentDirectory := ExtractFileDir(ExeFile);
    P.Options := [];
    P.Execute;
    SetSampleStatus(N, '', 'OPENED');
    AddLog('Sample opened for visual validation: ' + N.Name);
    PopulateSamples;
  except
    on E: Exception do
    begin
      SetSampleStatus(N, '', 'FAIL');
      AddLog('FAIL opening ' + N.Name + ': ' + E.Message);
      PopulateSamples;
    end;
  end;
  P.Free;
end;

end.
