unit main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, StdCtrls,
  ComCtrls, EditBtn, Grids, aidisktreescanner, aidiskitem,
  aidependencygraph;

type
  TArtifactKind = (akUnknown, akPackage, akPascal, akForm, akProject,
    akProjectSrc, akDoc, akData);

  { TfrmMain }

  TfrmMain = class(TForm)
    btnAnalyze: TButton;
    btnStop: TButton;
    deRoot: TDirectoryEdit;
    lblInventoryStatus: TLabel;
    lblProjectStatus: TLabel;
    lblRoot: TLabel;
    PageControl1: TPageControl;
    pnlProjectTop: TPanel;
    pnlInventoryTop: TPanel;
    ProgressBar1: TProgressBar;
    sgCounts: TStringGrid;
    tsInventory: TTabSheet;
    tsProject: TTabSheet;
    tvInventory: TTreeView;
    procedure btnAnalyzeClick(Sender: TObject);
    procedure btnStopClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
  private
    FScanner: TAIDiskTreeScanner;
    FGraph: TAIDependencyGraph;
    FTreeIndex: TStringList;
    FGraphIndex: TStringList;
    FCounts: array[TArtifactKind] of Integer;
    FDirectories: Integer;
    FFiles: Integer;
    FRootNode: TTreeNode;
    FRootPath: string;
    FScanRunning: Boolean;

    procedure ScannerTaskStart(Sender: TObject; TaskId: Integer; const Description: string);
    procedure ScannerItemFound(Sender: TObject; TaskId: Integer; Item: TAIDiskItem);
    procedure ScannerProgress(Sender: TObject; TaskId: Integer; ProcessedDirs: Int64;
      ProcessedFiles: Int64; FoundItems: Int64; const CurrentPath: string);
    procedure ScannerTaskFinish(Sender: TObject; TaskId: Integer; State: TAIDiskTaskState;
      TotalDirs: Int64; TotalFiles: Int64; TotalFound: Int64; const ErrorMsg: string);
    procedure ScannerError(Sender: TObject; TaskId: Integer; const Path: string;
      const ErrorMsg: string);

    procedure ResetView;
    procedure ConfigureScanner;
    procedure UpdateButtons;
    procedure UpdateCountsGrid;
    procedure UpdateStatus(const AText: string);
    procedure EnsureRootNode;
    function NormalizePathKey(const APath: string): string;
    function FindTreeNode(const APath: string): TTreeNode;
    function EnsureTreeNode(const APath, ACaption: string): TTreeNode;
    function ArtifactKindForItem(const AItem: TAIDiskItem): TArtifactKind;
    function ArtifactKindName(AKind: TArtifactKind): string;
    function ArtifactKindLabel(AKind: TArtifactKind): string;
    function GraphNodeTypeForItem(const AItem: TAIDiskItem): string;
    function GraphNodeIdForPath(const APath, ANodeType: string): string;
    function FindGraphNodeId(const APath: string): string;
    procedure AddToGraph(const AItem: TAIDiskItem);
    function DetectRepoRoot(const AStartDir: string): string;
    procedure SetDefaultRoot;
  end;

var
  frmMain: TfrmMain;

implementation

{$R *.lfm}

function MakeScannerEvidence(const APath: string): TAIDependencyEvidence;
begin
  Result := MakeAIDependencyEvidence(APath, 0, 'TAIDiskTreeScanner');
end;

{ TfrmMain }

function TfrmMain.ArtifactKindName(AKind: TArtifactKind): string;
begin
  case AKind of
    akPackage: Result := 'package';
    akPascal: Result := 'pascal';
    akForm: Result := 'form';
    akProject: Result := 'project';
    akProjectSrc: Result := 'project_source';
    akDoc: Result := 'document';
    akData: Result := 'data';
  else
    Result := 'unknown';
  end;
end;

function TfrmMain.ArtifactKindLabel(AKind: TArtifactKind): string;
begin
  case AKind of
    akPackage: Result := 'LPK';
    akPascal: Result := 'Pascal';
    akForm: Result := 'Form';
    akProject: Result := 'LPI';
    akProjectSrc: Result := 'LPR';
    akDoc: Result := 'Document';
    akData: Result := 'Data';
  else
    Result := 'Unknown';
  end;
end;

function TfrmMain.ArtifactKindForItem(const AItem: TAIDiskItem): TArtifactKind;
var
  Ext: string;
begin
  if AItem.ItemType = ditDirectory then
    Exit(akUnknown);

  Ext := LowerCase(AItem.Extension);
  if Ext = '.lpk' then
    Result := akPackage
  else if (Ext = '.pas') or (Ext = '.pp') or (Ext = '.inc') then
    Result := akPascal
  else if Ext = '.lfm' then
    Result := akForm
  else if Ext = '.lpi' then
    Result := akProject
  else if Ext = '.lpr' then
    Result := akProjectSrc
  else if (Ext = '.md') or (Ext = '.txt') then
    Result := akDoc
  else if (Ext = '.json') or (Ext = '.csv') then
    Result := akData
  else
    Result := akUnknown;
end;

function TfrmMain.GraphNodeTypeForItem(const AItem: TAIDiskItem): string;
begin
  if AItem.ItemType = ditDirectory then
    Exit('directory');

  case ArtifactKindForItem(AItem) of
    akPackage: Result := AIDG_NODE_PACKAGE;
    akPascal: Result := AIDG_NODE_UNIT;
    akForm: Result := AIDG_NODE_COMPONENT;
    akProject,
    akProjectSrc: Result := AIDG_NODE_SAMPLE;
    akDoc,
    akData,
    akUnknown: Result := AIDG_NODE_EXTERNAL;
  else
    Result := AIDG_NODE_EXTERNAL;
  end;
end;

function TfrmMain.GraphNodeIdForPath(const APath, ANodeType: string): string;
begin
  Result := ANodeType + ':' + LowerCase(NormalizePathKey(APath));
end;

function TfrmMain.FindGraphNodeId(const APath: string): string;
var
  Idx: Integer;
begin
  Result := '';
  Idx := FGraphIndex.IndexOfName(NormalizePathKey(APath));
  if Idx >= 0 then
    Result := FGraphIndex.ValueFromIndex[Idx];
end;

function TfrmMain.NormalizePathKey(const APath: string): string;
begin
  if Trim(APath) = '' then
    Exit('');
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
  Key, ParentKey: string;
  ParentNode: TTreeNode;
  CaptionText: string;
begin
  Key := NormalizePathKey(APath);
  Result := FindTreeNode(Key);
  if Assigned(Result) then
    Exit;

  if SameText(Key, NormalizePathKey(FRootPath)) then
  begin
    CaptionText := ACaption;
    if CaptionText = '' then
      CaptionText := ExtractFileName(Key);
    if CaptionText = '' then
      CaptionText := Key;
    Result := tvInventory.Items.Add(nil, CaptionText);
    FTreeIndex.AddObject(Key, Result);
    FRootNode := Result;
    Exit;
  end;

  ParentKey := NormalizePathKey(ExtractFileDir(Key));
  ParentNode := FindTreeNode(ParentKey);
  if not Assigned(ParentNode) then
    ParentNode := FRootNode;

  CaptionText := ACaption;
  if CaptionText = '' then
    CaptionText := ExtractFileName(Key);
  if CaptionText = '' then
    CaptionText := Key;

  Result := tvInventory.Items.AddChild(ParentNode, CaptionText);
  FTreeIndex.AddObject(Key, Result);
end;

procedure TfrmMain.ResetView;
begin
  tvInventory.Items.BeginUpdate;
  try
    tvInventory.Items.Clear;
    FTreeIndex.Clear;
    FGraphIndex.Clear;
    FRootNode := nil;
  finally
    tvInventory.Items.EndUpdate;
  end;

  FGraph.Clear;
  FillChar(FCounts, SizeOf(FCounts), 0);
  FDirectories := 0;
  FFiles := 0;
  UpdateCountsGrid;
end;

procedure TfrmMain.ConfigureScanner;
var
  S: TStringList;
  I: Integer;
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
  S := TStringList.Create;
  try
    S.CommaText := '.git,lib,bin,backup,output,__pycache__,node_modules,.vscode,dist,fixtures';
    for I := 0 to S.Count - 1 do
      if Trim(S[I]) <> '' then
        FScanner.ExcludeDirs.Add(Trim(S[I]));
  finally
    S.Free;
  end;

  FScanner.ExcludeExtensions.Clear;
end;

procedure TfrmMain.UpdateButtons;
begin
  btnAnalyze.Enabled := not FScanRunning;
  btnStop.Enabled := FScanRunning;
  deRoot.Enabled := not FScanRunning;
end;

procedure TfrmMain.UpdateStatus(const AText: string);
begin
  lblProjectStatus.Caption := AText;
  lblInventoryStatus.Caption := AText;
end;

procedure TfrmMain.UpdateCountsGrid;
var
  Row: Integer;
  K: TArtifactKind;
begin
  sgCounts.Cells[0, 0] := 'Tipo';
  sgCounts.Cells[1, 0] := 'Quantidade';

  Row := 1;
  sgCounts.Cells[0, Row] := 'Total encontrados';
  sgCounts.Cells[1, Row] := IntToStr(FFiles + FDirectories);
  Inc(Row);

  sgCounts.Cells[0, Row] := 'Diretórios';
  sgCounts.Cells[1, Row] := IntToStr(FDirectories);
  Inc(Row);

  sgCounts.Cells[0, Row] := 'Arquivos';
  sgCounts.Cells[1, Row] := IntToStr(FFiles);
  Inc(Row);

  for K := Low(TArtifactKind) to High(TArtifactKind) do
  begin
    sgCounts.Cells[0, Row] := ArtifactKindLabel(K);
    sgCounts.Cells[1, Row] := IntToStr(FCounts[K]);
    Inc(Row);
  end;

  while Row <= sgCounts.RowCount - 1 do
  begin
    sgCounts.Cells[0, Row] := '';
    sgCounts.Cells[1, Row] := '';
    Inc(Row);
  end;
end;

procedure TfrmMain.EnsureRootNode;
var
  RootCaption: string;
begin
  RootCaption := ExtractFileName(ExcludeTrailingPathDelimiter(FRootPath));
  if RootCaption = '' then
    RootCaption := ExcludeTrailingPathDelimiter(FRootPath);
  FRootNode := tvInventory.Items.Add(nil, RootCaption);
  FTreeIndex.AddObject(NormalizePathKey(FRootPath), FRootNode);

  FGraph.AddNode(
    GraphNodeIdForPath(FRootPath, AIDG_NODE_REPOSITORY),
    AIDG_NODE_REPOSITORY,
    RootCaption,
    NormalizePathKey(FRootPath),
    MakeScannerEvidence(FRootPath)
  );
  FGraphIndex.Values[NormalizePathKey(FRootPath)] := GraphNodeIdForPath(FRootPath, AIDG_NODE_REPOSITORY);
end;

procedure TfrmMain.AddToGraph(const AItem: TAIDiskItem);
var
  NodeType, NodeId, ParentId, ItemPath, ParentPath: string;
  Evidence: TAIDependencyEvidence;
  ItemNode: TAIDependencyNode;
begin
  ItemPath := NormalizePathKey(AItem.FullPath);
  if ItemPath = '' then
    Exit;

  if FGraphIndex.IndexOfName(ItemPath) >= 0 then
    Exit;

  NodeType := GraphNodeTypeForItem(AItem);
  NodeId := GraphNodeIdForPath(ItemPath, NodeType);
  ParentPath := NormalizePathKey(AItem.ParentPath);
  ParentId := FindGraphNodeId(ParentPath);
  if ParentId = '' then
    ParentId := GraphNodeIdForPath(FRootPath, AIDG_NODE_REPOSITORY);

  Evidence := MakeScannerEvidence(AItem.FullPath);
  ItemNode := FGraph.AddNode(NodeId, NodeType, AItem.Name, ItemPath, Evidence);
  if Assigned(ItemNode) and (ParentId <> '') and (ParentId <> NodeId) then
    FGraph.AddEdge(ParentId, NodeId, AIDG_EDGE_CONTAINS, Evidence);

  FGraphIndex.Values[ItemPath] := NodeId;
end;

function TfrmMain.DetectRepoRoot(const AStartDir: string): string;
var
  CurDir, Probe: string;
  I: Integer;
begin
  CurDir := ExpandFileName(AStartDir);
  for I := 0 to 6 do
  begin
    Probe := IncludeTrailingPathDelimiter(CurDir);
    if DirectoryExists(Probe + 'DOC') and DirectoryExists(Probe + 'pacote') then
      Exit(ExcludeTrailingPathDelimiter(CurDir));
    CurDir := ExpandFileName(IncludeTrailingPathDelimiter(CurDir) + '..');
  end;
  Result := ExcludeTrailingPathDelimiter(ExpandFileName(AStartDir));
end;

procedure TfrmMain.SetDefaultRoot;
begin
  if DirectoryExists(DetectRepoRoot(ExtractFilePath(Application.ExeName))) then
    deRoot.Directory := DetectRepoRoot(ExtractFilePath(Application.ExeName))
  else
    deRoot.Directory := GetCurrentDir;
end;

procedure TfrmMain.FormCreate(Sender: TObject);
begin
  FScanner := TAIDiskTreeScanner.Create(Self);
  FGraph := TAIDependencyGraph.Create(Self);
  FTreeIndex := TStringList.Create;
  FTreeIndex.Sorted := True;
  FTreeIndex.Duplicates := dupIgnore;
  FTreeIndex.CaseSensitive := False;
  FGraphIndex := TStringList.Create;
  FGraphIndex.Sorted := True;
  FGraphIndex.Duplicates := dupIgnore;
  FGraphIndex.CaseSensitive := False;
  FGraphIndex.NameValueSeparator := '=';
  FGraphIndex.NameValueSeparator := '=';

  FScanner.OnTaskStart := @ScannerTaskStart;
  FScanner.OnItemFound := @ScannerItemFound;
  FScanner.OnProgress := @ScannerProgress;
  FScanner.OnTaskFinish := @ScannerTaskFinish;
  FScanner.OnError := @ScannerError;

  ConfigureScanner;
  SetDefaultRoot;

  sgCounts.ColCount := 2;
  sgCounts.RowCount := 12;
  sgCounts.FixedRows := 1;
  sgCounts.FixedCols := 0;
  sgCounts.Cells[0, 0] := 'Tipo';
  sgCounts.Cells[1, 0] := 'Quantidade';
  sgCounts.Options := sgCounts.Options + [goColSizing, goRowSelect];
  sgCounts.ColWidths[0] := 180;
  sgCounts.ColWidths[1] := 100;

  tvInventory.ReadOnly := True;
  tvInventory.HideSelection := False;
  tvInventory.ShowLines := True;
  tvInventory.ShowRoot := True;

  UpdateCountsGrid;
  UpdateButtons;
  UpdateStatus('Pronto.');
end;

procedure TfrmMain.FormDestroy(Sender: TObject);
begin
  FScanner.Cancel;
  FGraphIndex.Free;
  FTreeIndex.Free;
end;

procedure TfrmMain.btnAnalyzeClick(Sender: TObject);
begin
  if Trim(deRoot.Directory) = '' then
  begin
    ShowMessage('Escolha a raiz do repositório primeiro.');
    Exit;
  end;

  if not DirectoryExists(deRoot.Directory) then
  begin
    ShowMessage('A raiz informada não existe.');
    Exit;
  end;

  FRootPath := ExcludeTrailingPathDelimiter(ExpandFileName(deRoot.Directory));
  ResetView;
  ConfigureScanner;

  FScanRunning := True;
  UpdateButtons;
  UpdateStatus('Iniciando varredura...');
  ProgressBar1.Style := pbstMarquee;
  FScanner.RootPath := FRootPath;
  FScanner.BuildDatasetInventoryAsync(FRootPath, True);
end;

procedure TfrmMain.btnStopClick(Sender: TObject);
begin
  FScanner.Cancel;
  UpdateStatus('Cancelando...');
end;

procedure TfrmMain.ScannerTaskStart(Sender: TObject; TaskId: Integer; const Description: string);
begin
  ProgressBar1.Style := pbstMarquee;
  UpdateStatus('Varredura iniciada.');
  tvInventory.Items.BeginUpdate;
  EnsureRootNode;
end;

procedure TfrmMain.ScannerItemFound(Sender: TObject; TaskId: Integer; Item: TAIDiskItem);
var
  ParentNode: TTreeNode;
  Node: TTreeNode;
  Kind: TArtifactKind;
begin
  if not Assigned(Item) then
    Exit;

  ParentNode := EnsureTreeNode(Item.ParentPath, ExtractFileName(ExcludeTrailingPathDelimiter(Item.ParentPath)));
  if not Assigned(ParentNode) then
    ParentNode := FRootNode;

  Node := EnsureTreeNode(Item.FullPath, Item.Name);
  if Assigned(Node) and Assigned(ParentNode) and (Node.Parent <> ParentNode) then
    Node.MoveTo(ParentNode, naAddChild);

  AddToGraph(Item);

  if Item.ItemType = ditDirectory then
  begin
    Inc(FDirectories);
  end
  else
  begin
    Inc(FFiles);
    Kind := ArtifactKindForItem(Item);
    Inc(FCounts[Kind]);
  end;
end;

procedure TfrmMain.ScannerProgress(Sender: TObject; TaskId: Integer; ProcessedDirs: Int64;
  ProcessedFiles: Int64; FoundItems: Int64; const CurrentPath: string);
begin
  UpdateStatus(Format('Dirs: %d | Files: %d | Itens: %d | Atual: %s',
    [ProcessedDirs, ProcessedFiles, FoundItems, CurrentPath]));
end;

procedure TfrmMain.ScannerTaskFinish(Sender: TObject; TaskId: Integer; State: TAIDiskTaskState;
  TotalDirs: Int64; TotalFiles: Int64; TotalFound: Int64; const ErrorMsg: string);
var
  V: TAIDependencyValidation;
begin
  tvInventory.Items.EndUpdate;
  ProgressBar1.Style := pbstNormal;
  ProgressBar1.Position := 0;
  FScanRunning := False;
  UpdateButtons;
  UpdateCountsGrid;

  if State = dtsFinished then
  begin
    V := FGraph.Validate;
    UpdateStatus(Format('Concluído. Scanner: %d itens. Grafo: %d nós / %d arestas / %s.',
      [TotalFound, FGraph.NodeCount, FGraph.EdgeCount, BoolToStr(V.Passed, True)]));
  end
  else if State = dtsCancelled then
    UpdateStatus('Varredura cancelada.')
  else
    UpdateStatus('Erro: ' + ErrorMsg);
end;

procedure TfrmMain.ScannerError(Sender: TObject; TaskId: Integer; const Path: string;
  const ErrorMsg: string);
begin
  UpdateStatus('Erro em ' + Path + ': ' + ErrorMsg);
end;

end.
