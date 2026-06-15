unit main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, StdCtrls,
  ComCtrls, FileCtrl, aidisktreescanner, aidiskitem;

type

  { TfrmMain }

  TfrmMain = class(TForm)
    pnlTop: TPanel;
    pnlLeft: TPanel;
    pnlClient: TPanel;
    pnlBottom: TPanel;
    splitterLeft: TSplitter;

    btnLoadVolumes: TButton;
    btnScanSelected: TButton;
    btnScanRecursive: TButton;
    btnFindFile: TButton;
    btnFindDir: TButton;
    btnFindExt: TButton;
    btnBuildInventory: TButton;
    btnExportJSON: TButton;
    btnCancel: TButton;

    edtFind: TEdit;
    cbExtensions: TComboBox;
    tvDisk: TTreeView;
    lvFiles: TListView;
    memoLog: TMemo;
    lblStatus: TLabel;
    ProgressBar1: TProgressBar;

    procedure FormCreate(Sender: TObject);
    procedure btnLoadVolumesClick(Sender: TObject);
    procedure btnScanSelectedClick(Sender: TObject);
    procedure btnScanRecursiveClick(Sender: TObject);
    procedure btnFindFileClick(Sender: TObject);
    procedure btnFindDirClick(Sender: TObject);
    procedure btnFindExtClick(Sender: TObject);
    procedure btnBuildInventoryClick(Sender: TObject);
    procedure btnExportJSONClick(Sender: TObject);
    procedure btnCancelClick(Sender: TObject);
    procedure tvDiskSelectionChanged(Sender: TObject);

  private
    DiskTreeScanner1: TAIDiskTreeScanner;
    FCurrentTaskId: Integer;

    procedure DiskTaskStart(Sender: TObject; TaskId: Integer; const Description: string);
    procedure DiskItemFound(Sender: TObject; TaskId: Integer; Item: TAIDiskItem);
    procedure DiskProgress(Sender: TObject; TaskId: Integer; ProcessedDirs: Int64;
      ProcessedFiles: Int64; FoundItems: Int64; const CurrentPath: string);
    procedure DiskTaskFinish(Sender: TObject; TaskId: Integer; State: TAIDiskTaskState;
      TotalDirs: Int64; TotalFiles: Int64; TotalFound: Int64; const ErrorMsg: string);
    procedure DiskError(Sender: TObject; TaskId: Integer; const Path: string; const ErrorMsg: string);

    function FindNodeByPath(const APath: string): TTreeNode;
    procedure AddDirectoryToTree(const APath, AName, AParentPath: string);
    procedure LogMsg(const AMsg: string);
    procedure UpdateUIState;
  public

  end;

var
  frmMain: TfrmMain;

implementation

{$R *.lfm}

{ TfrmMain }

procedure TfrmMain.FormCreate(Sender: TObject);
begin
  DiskTreeScanner1 := TAIDiskTreeScanner.Create(Self);

  // Default configuration
  DiskTreeScanner1.IncludeFiles := True;
  DiskTreeScanner1.IncludeDirectories := True;
  DiskTreeScanner1.IncludeHidden := False;
  DiskTreeScanner1.IncludeSystem := False;
  DiskTreeScanner1.FollowSymlinks := False;
  DiskTreeScanner1.MaxDepth := 0;
  DiskTreeScanner1.ReturnOnMainThread := True;

  // Set default exclusions
  DiskTreeScanner1.ExcludeDirs.Add('.git');
  DiskTreeScanner1.ExcludeDirs.Add('.svn');
  DiskTreeScanner1.ExcludeDirs.Add('node_modules');
  DiskTreeScanner1.ExcludeDirs.Add('__pycache__');
  DiskTreeScanner1.ExcludeDirs.Add('venv');

  // Wire events
  DiskTreeScanner1.OnTaskStart := @DiskTaskStart;
  DiskTreeScanner1.OnItemFound := @DiskItemFound;
  DiskTreeScanner1.OnProgress := @DiskProgress;
  DiskTreeScanner1.OnTaskFinish := @DiskTaskFinish;
  DiskTreeScanner1.OnError := @DiskError;

  // Load combo box default search extensions
  cbExtensions.Items.Add('.jpg');
  cbExtensions.Items.Add('.png');
  cbExtensions.Items.Add('.txt');
  cbExtensions.Items.Add('.json');
  cbExtensions.Items.Add('.py');
  cbExtensions.Items.Add('.pas');
  cbExtensions.ItemIndex := 0;

  LogMsg('Disk Tree Scanner Demo initialized.');
  UpdateUIState;

  // Async load drive volumes
  FCurrentTaskId := DiskTreeScanner1.ListVolumesAsync;
end;

procedure TfrmMain.btnLoadVolumesClick(Sender: TObject);
begin
  tvDisk.Items.Clear;
  lvFiles.Items.Clear;
  memoLog.Clear;
  FCurrentTaskId := DiskTreeScanner1.ListVolumesAsync;
end;

procedure TfrmMain.btnScanSelectedClick(Sender: TObject);
var
  LPath: string;
begin
  if tvDisk.Selected = nil then
  begin
    ShowMessage('Please select a directory or volume first.');
    Exit;
  end;

  LPath := string(tvDisk.Selected.Data);
  lvFiles.Items.Clear;
  FCurrentTaskId := DiskTreeScanner1.ScanBranchAsync(LPath, dsmCurrentLevelOnly);
end;

procedure TfrmMain.btnScanRecursiveClick(Sender: TObject);
var
  LPath: string;
begin
  if tvDisk.Selected = nil then
  begin
    ShowMessage('Please select a directory or volume first.');
    Exit;
  end;

  LPath := string(tvDisk.Selected.Data);
  lvFiles.Items.Clear;
  FCurrentTaskId := DiskTreeScanner1.ScanBranchAsync(LPath, dsmRecursive);
end;

procedure TfrmMain.btnFindFileClick(Sender: TObject);
var
  LPath: string;
begin
  if tvDisk.Selected = nil then
  begin
    ShowMessage('Please select a directory or volume first.');
    Exit;
  end;

  if Trim(edtFind.Text) = '' then
  begin
    ShowMessage('Please type a file name to find.');
    Exit;
  end;

  LPath := string(tvDisk.Selected.Data);
  lvFiles.Items.Clear;
  FCurrentTaskId := DiskTreeScanner1.FindFileAsync(LPath, edtFind.Text, True);
end;

procedure TfrmMain.btnFindDirClick(Sender: TObject);
var
  LPath: string;
begin
  if tvDisk.Selected = nil then
  begin
    ShowMessage('Please select a directory or volume first.');
    Exit;
  end;

  if Trim(edtFind.Text) = '' then
  begin
    ShowMessage('Please type a directory name to find.');
    Exit;
  end;

  LPath := string(tvDisk.Selected.Data);
  lvFiles.Items.Clear;
  FCurrentTaskId := DiskTreeScanner1.FindDirAsync(LPath, edtFind.Text, True);
end;

procedure TfrmMain.btnFindExtClick(Sender: TObject);
var
  LPath: string;
begin
  if tvDisk.Selected = nil then
  begin
    ShowMessage('Please select a directory or volume first.');
    Exit;
  end;

  LPath := string(tvDisk.Selected.Data);
  lvFiles.Items.Clear;
  FCurrentTaskId := DiskTreeScanner1.FindExtAsync(LPath, cbExtensions.Text, True);
end;

procedure TfrmMain.btnBuildInventoryClick(Sender: TObject);
var
  LPath: string;
begin
  if tvDisk.Selected = nil then
  begin
    ShowMessage('Please select a directory or volume first.');
    Exit;
  end;

  LPath := string(tvDisk.Selected.Data);
  lvFiles.Items.Clear;
  FCurrentTaskId := DiskTreeScanner1.BuildDatasetInventoryAsync(LPath, True);
end;

procedure TfrmMain.btnExportJSONClick(Sender: TObject);
var
  SD: TSaveDialog;
begin
  if DiskTreeScanner1.ResultCount = 0 then
  begin
    ShowMessage('No results to export.');
    Exit;
  end;

  SD := TSaveDialog.Create(nil);
  try
    SD.Filter := 'JSON file (*.json)|*.json|CSV file (*.csv)|*.csv|Text file (*.txt)|*.txt';
    SD.DefaultExt := '.json';
    if SD.Execute then
    begin
      if SameText(ExtractFileExt(SD.FileName), '.json') then
      begin
        if DiskTreeScanner1.ExportToJSON(SD.FileName) then
          LogMsg('Exported successfully to: ' + SD.FileName);
      end
      else if SameText(ExtractFileExt(SD.FileName), '.csv') then
      begin
        if DiskTreeScanner1.ExportToCSV(SD.FileName) then
          LogMsg('Exported successfully to: ' + SD.FileName);
      end
      else
      begin
        if DiskTreeScanner1.ExportToTXT(SD.FileName) then
          LogMsg('Exported successfully to: ' + SD.FileName);
      end;
    end;
  finally
    SD.Free;
  end;
end;

procedure TfrmMain.btnCancelClick(Sender: TObject);
begin
  DiskTreeScanner1.Cancel;
end;

procedure TfrmMain.tvDiskSelectionChanged(Sender: TObject);
begin
  // Optionally auto scan current level
end;

procedure TfrmMain.DiskTaskStart(Sender: TObject; TaskId: Integer; const Description: string);
begin
  LogMsg(Format('[Task %d] Started: %s', [TaskId, Description]));
  ProgressBar1.Style := pbstMarquee;
  UpdateUIState;
end;

procedure TfrmMain.DiskItemFound(Sender: TObject; TaskId: Integer; Item: TAIDiskItem);
var
  ListItem: TListItem;
  ClassSug: string;
begin
  if Item.ItemType = ditVolume then
  begin
    AddDirectoryToTree(Item.FullPath, Item.FullPath, '');
  end
  else if Item.ItemType = ditDirectory then
  begin
    AddDirectoryToTree(Item.FullPath, Item.Name, Item.ParentPath);
  end;

  // Add all found items to ListView for display
  ListItem := lvFiles.Items.Add;
  ListItem.Caption := Item.Name;
  ListItem.SubItems.Add(Item.FullPath);
  
  if Item.ItemType = ditVolume then
    ListItem.SubItems.Add('Volume')
  else if Item.ItemType = ditDirectory then
    ListItem.SubItems.Add('Directory')
  else
    ListItem.SubItems.Add('File');

  if Item.ItemType = ditFile then
  begin
    ListItem.SubItems.Add(FormatFloat('#,##0 KB', Item.Size / 1024.0));
    ListItem.SubItems.Add(Item.Extension);
    ClassSug := ExtractFileName(ExcludeTrailingPathDelimiter(Item.ParentPath));
    ListItem.SubItems.Add(ClassSug); // Class Suggested
  end
  else
  begin
    ListItem.SubItems.Add('-');
    ListItem.SubItems.Add('-');
    ListItem.SubItems.Add('-');
  end;
end;

procedure TfrmMain.DiskProgress(Sender: TObject; TaskId: Integer; ProcessedDirs: Int64;
  ProcessedFiles: Int64; FoundItems: Int64; const CurrentPath: string);
begin
  lblStatus.Caption := Format('Processed Dirs: %d | Files: %d | Found: %d | Current: %s',
    [ProcessedDirs, ProcessedFiles, FoundItems, MinimizeName(CurrentPath, lblStatus.Canvas, 300)]);
end;

procedure TfrmMain.DiskTaskFinish(Sender: TObject; TaskId: Integer; State: TAIDiskTaskState;
  TotalDirs: Int64; TotalFiles: Int64; TotalFound: Int64; const ErrorMsg: string);
var
  StateStr: string;
begin
  ProgressBar1.Style := pbstNormal;
  ProgressBar1.Position := 0;

  case State of
    dtsFinished: StateStr := 'Finished';
    dtsCancelled: StateStr := 'Cancelled';
    dtsError: StateStr := 'Error: ' + ErrorMsg;
    else StateStr := 'Idle';
  end;

  LogMsg(Format('[Task %d] Finished with State: %s. Processed %d Dirs, %d Files. Found %d Items.',
    [TaskId, StateStr, TotalDirs, TotalFiles, TotalFound]));

  lblStatus.Caption := Format('Task %d Finished. Found: %d', [TaskId, TotalFound]);
  UpdateUIState;
end;

procedure TfrmMain.DiskError(Sender: TObject; TaskId: Integer; const Path: string; const ErrorMsg: string);
begin
  LogMsg(Format('[Error] on Path %s: %s', [Path, ErrorMsg]));
end;

function TfrmMain.FindNodeByPath(const APath: string): TTreeNode;
var
  Node: TTreeNode;
  CleanPath, NodePath: string;
begin
  Result := nil;
  CleanPath := ExcludeTrailingPathDelimiter(APath);
  Node := tvDisk.Items.GetFirstNode;
  while Assigned(Node) do
  begin
    if Node.Data <> nil then
    begin
      NodePath := ExcludeTrailingPathDelimiter(string(Node.Data));
      if SameText(NodePath, CleanPath) then
        Exit(Node);
    end;
    Node := Node.GetNext;
  end;
end;

procedure TfrmMain.AddDirectoryToTree(const APath, AName, AParentPath: string);
var
  ParentNode, Node: TTreeNode;
  PathStr: string;
begin
  Node := FindNodeByPath(APath);
  if Assigned(Node) then Exit;

  ParentNode := FindNodeByPath(AParentPath);
  Node := tvDisk.Items.AddChild(ParentNode, AName);
  
  // Safe string storage in Node.Data
  PathStr := APath;
  UniqueString(PathStr);
  Node.Data := Pointer(PathStr);
end;

procedure TfrmMain.LogMsg(const AMsg: string);
begin
  memoLog.Lines.Add(FormatDateTime('hh:nn:ss.zzz', Now) + ' - ' + AMsg);
end;

procedure TfrmMain.UpdateUIState;
var
  Running: Boolean;
begin
  Running := DiskTreeScanner1.IsBusy;
  btnLoadVolumes.Enabled := not Running;
  btnScanSelected.Enabled := not Running;
  btnScanRecursive.Enabled := not Running;
  btnFindFile.Enabled := not Running;
  btnFindDir.Enabled := not Running;
  btnFindExt.Enabled := not Running;
  btnBuildInventory.Enabled := not Running;
  btnExportJSON.Enabled := not Running;
  btnCancel.Enabled := Running;
end;

end.
