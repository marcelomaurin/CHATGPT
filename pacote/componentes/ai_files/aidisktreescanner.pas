unit aidisktreescanner;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Contnrs, aidiskitem, Masks;

type
  TAIDiskTaskState = (
    dtsIdle,
    dtsRunning,
    dtsFinished,
    dtsCancelled,
    dtsError
  );

  TAIDiskScanMode = (
    dsmCurrentLevelOnly,
    dsmRecursive
  );

  TAIDiskFindMode = (
    dfmFileName,
    dfmDirectoryName,
    dfmExtension,
    dfmMask,
    dfmContentTag
  );

  // Events
  TAIDiskTaskStartEvent = procedure(
    Sender: TObject;
    TaskId: Integer;
    const Description: string
  ) of object;

  TAIDiskItemEvent = procedure(
    Sender: TObject;
    TaskId: Integer;
    Item: TAIDiskItem
  ) of object;

  TAIDiskProgressEvent = procedure(
    Sender: TObject;
    TaskId: Integer;
    ProcessedDirs: Int64;
    ProcessedFiles: Int64;
    FoundItems: Int64;
    const CurrentPath: string
  ) of object;

  TAIDiskFinishEvent = procedure(
    Sender: TObject;
    TaskId: Integer;
    State: TAIDiskTaskState;
    TotalDirs: Int64;
    TotalFiles: Int64;
    TotalFound: Int64;
    const ErrorMsg: string
  ) of object;

  TAIDiskErrorEvent = procedure(
    Sender: TObject;
    TaskId: Integer;
    const Path: string;
    const ErrorMsg: string
  ) of object;

  // Forward declaration
  TAIDiskTreeScanner = class;

  TScanTaskType = (
    sttListVolumes,
    sttScanBranch,
    sttFindFile,
    sttFindDir,
    sttFindExt,
    sttFindExts,
    sttFindMask,
    sttBuildInventory
  );

  { TAIDiskScanThread }

  TAIDiskScanThread = class(TThread)
  private
    FScanner: TAIDiskTreeScanner;
    FTaskId: Integer;
    FTaskType: TScanTaskType;
    FStartPath: string;
    FSearchQuery: string;
    FSearchExtensions: TStringList;
    FRecursive: Boolean;
    FScanMode: TAIDiskScanMode;

    FProcessedDirs: Int64;
    FProcessedFiles: Int64;
    FFoundItemsCount: Int64;
    FCurrentPath: string;
    FErrorPath: string;
    FErrorMsg: string;
    FTaskDescription: string;
    FTaskState: TAIDiskTaskState;

    FItemToNotify: TAIDiskItem;

    procedure SyncStart;
    procedure SyncItemFound;
    procedure SyncProgress;
    procedure SyncError;
    procedure SyncFinish;

    procedure NotifyStart(const ADescription: string);
    procedure NotifyItemFound(AItem: TAIDiskItem);
    procedure NotifyProgress(const ACurrentPath: string);
    procedure NotifyError(const APath, AMsg: string);
    procedure NotifyFinish(AState: TAIDiskTaskState; const AErrorMsg: string);

    function MatchesFilters(const AFileName: string; ASize: Int64; AAttr: Integer): Boolean;
    function ShouldExcludeDir(const ADirName: string): Boolean;
    procedure ScanDirectory(const APath: string; ADepth: Integer);
    procedure DoScan;
    procedure ExecuteTask;
  protected
    procedure Execute; override;
  public
    constructor Create(AScanner: TAIDiskTreeScanner; ATaskId: Integer; ATaskType: TScanTaskType;
      const AStartPath: string; ARecursive: Boolean; const ASearchQuery: string = '');
    destructor Destroy; override;
  end;

  { TAIDiskTreeScanner }

  TAIDiskTreeScanner = class(TComponent)
  private
    FActive: Boolean;
    FBusy: Boolean;
    FLastError: string;
    FLastTaskId: Integer;

    FRootPath: string;
    FIncludeFiles: Boolean;
    FIncludeDirectories: Boolean;
    FRecursive: Boolean;

    FMaxDepth: Integer;
    FFollowSymlinks: Boolean;
    FIncludeHidden: Boolean;
    FIncludeSystem: Boolean;

    FFileMask: string;
    FExtensions: TStringList;
    FExcludeDirs: TStringList;
    FExcludeExtensions: TStringList;

    FMinFileSize: Int64;
    FMaxFileSize: Int64;

    FReturnOnMainThread: Boolean;
    FAutoClearResults: Boolean;
    FCalculateHash: Boolean;
    FHashAlgorithm: string;

    FResults: TObjectList;
    FCurrentThread: TAIDiskScanThread;

    FOnTaskStart: TAIDiskTaskStartEvent;
    FOnItemFound: TAIDiskItemEvent;
    FOnProgress: TAIDiskProgressEvent;
    FOnTaskFinish: TAIDiskFinishEvent;
    FOnError: TAIDiskErrorEvent;

    function GenerateTaskId: Integer;
    procedure SetBusy(const AValue: Boolean);
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    procedure Clear;
    procedure Cancel;
    function IsBusy: Boolean;
    function GetLastError: string;

    function ListVolumesAsync: Integer;
    function ListVolumes: TObjectList;

    function ScanBranchAsync(const APath: string; AMode: TAIDiskScanMode): Integer;
    function FindFileAsync(const AStartPath, AFileName: string; ARecursive: Boolean = True): Integer;
    function FindDirAsync(const AStartPath, ADirName: string; ARecursive: Boolean = True): Integer;
    function FindExtAsync(const AStartPath, AExtension: string; ARecursive: Boolean = True): Integer;
    function FindExtsAsync(const AStartPath: string; AExtensions: TStrings; ARecursive: Boolean = True): Integer;
    function FindMaskAsync(const AStartPath, AMask: string; ARecursive: Boolean = True): Integer;
    function BuildDatasetInventoryAsync(const AStartPath: string; ARecursive: Boolean = True): Integer;

    function ExportToJSON(const AFileName: string): Boolean;
    function ExportToCSV(const AFileName: string): Boolean;
    function ExportToTXT(const AFileName: string): Boolean;

    // AI Mappings
    function IsImageFile(const AFileName: string): Boolean;
    function IsTextFile(const AFileName: string): Boolean;
    function IsAudioFile(const AFileName: string): Boolean;
    function IsVideoFile(const AFileName: string): Boolean;
    function IsDataFile(const AFileName: string): Boolean;

    function ResultCount: Integer;
    function GetResult(AIndex: Integer): TAIDiskItem;
    procedure ClearResults;

    property Results: TObjectList read FResults;
  published
    property Active: Boolean read FActive;
    property Busy: Boolean read FBusy;
    property LastError: string read FLastError;
    property LastTaskId: Integer read FLastTaskId;

    property RootPath: string read FRootPath write FRootPath;
    property IncludeFiles: Boolean read FIncludeFiles write FIncludeFiles;
    property IncludeDirectories: Boolean read FIncludeDirectories write FIncludeDirectories;
    property Recursive: Boolean read FRecursive write FRecursive;

    property MaxDepth: Integer read FMaxDepth write FMaxDepth;
    property FollowSymlinks: Boolean read FFollowSymlinks write FFollowSymlinks;
    property IncludeHidden: Boolean read FIncludeHidden write FIncludeHidden;
    property IncludeSystem: Boolean read FIncludeSystem write FIncludeSystem;

    property FileMask: string read FFileMask write FFileMask;
    property Extensions: TStringList read FExtensions;
    property ExcludeDirs: TStringList read FExcludeDirs;
    property ExcludeExtensions: TStringList read FExcludeExtensions;

    property MinFileSize: Int64 read FMinFileSize write FMinFileSize;
    property MaxFileSize: Int64 read FMaxFileSize write FMaxFileSize;

    property ReturnOnMainThread: Boolean read FReturnOnMainThread write FReturnOnMainThread;
    property AutoClearResults: Boolean read FAutoClearResults write FAutoClearResults;
    property CalculateHash: Boolean read FCalculateHash write FCalculateHash;
    property HashAlgorithm: string read FHashAlgorithm write FHashAlgorithm;

    // Events
    property OnTaskStart: TAIDiskTaskStartEvent read FOnTaskStart write FOnTaskStart;
    property OnItemFound: TAIDiskItemEvent read FOnItemFound write FOnItemFound;
    property OnProgress: TAIDiskProgressEvent read FOnProgress write FOnProgress;
    property OnTaskFinish: TAIDiskFinishEvent read FOnTaskFinish write FOnTaskFinish;
    property OnError: TAIDiskErrorEvent read FOnError write FOnError;
  end;

procedure Register;

implementation

{$IFDEF MSWINDOWS}
uses
  Windows;
{$ENDIF}

procedure Register;
begin
  RegisterComponents('AI Native Vision', [TAIDiskTreeScanner]);
end;

{ TAIDiskScanThread }

constructor TAIDiskScanThread.Create(AScanner: TAIDiskTreeScanner; ATaskId: Integer;
  ATaskType: TScanTaskType; const AStartPath: string; ARecursive: Boolean;
  const ASearchQuery: string);
begin
  inherited Create(True);
  FScanner := AScanner;
  FTaskId := ATaskId;
  FTaskType := ATaskType;
  FStartPath := AStartPath;
  FRecursive := ARecursive;
  FSearchQuery := ASearchQuery;
  FSearchExtensions := TStringList.Create;
  
  if FRecursive then
    FScanMode := dsmRecursive
  else
    FScanMode := dsmCurrentLevelOnly;

  FProcessedDirs := 0;
  FProcessedFiles := 0;
  FFoundItemsCount := 0;
  FCurrentPath := '';
  FTaskState := dtsIdle;
  FreeOnTerminate := False;
end;

destructor TAIDiskScanThread.Destroy;
begin
  FSearchExtensions.Free;
  inherited Destroy;
end;

procedure TAIDiskScanThread.SyncStart;
begin
  if Assigned(FScanner.FOnTaskStart) then
    FScanner.FOnTaskStart(FScanner, FTaskId, FTaskDescription);
end;

procedure TAIDiskScanThread.SyncItemFound;
begin
  if Assigned(FScanner.FOnItemFound) then
    FScanner.FOnItemFound(FScanner, FTaskId, FItemToNotify);
end;

procedure TAIDiskScanThread.SyncProgress;
begin
  if Assigned(FScanner.FOnProgress) then
    FScanner.FOnProgress(FScanner, FTaskId, FProcessedDirs, FProcessedFiles, FFoundItemsCount, FCurrentPath);
end;

procedure TAIDiskScanThread.SyncError;
begin
  if Assigned(FScanner.FOnError) then
    FScanner.FOnError(FScanner, FTaskId, FErrorPath, FErrorMsg);
end;

procedure TAIDiskScanThread.SyncFinish;
begin
  if Assigned(FScanner.FOnTaskFinish) then
    FScanner.FOnTaskFinish(FScanner, FTaskId, FTaskState, FProcessedDirs, FProcessedFiles, FFoundItemsCount, FErrorMsg);
end;

procedure TAIDiskScanThread.NotifyStart(const ADescription: string);
begin
  FTaskDescription := ADescription;
  if FScanner.ReturnOnMainThread then
    Synchronize(@SyncStart)
  else
    SyncStart;
end;

procedure TAIDiskScanThread.NotifyItemFound(AItem: TAIDiskItem);
begin
  FItemToNotify := AItem;
  if FScanner.ReturnOnMainThread then
    Synchronize(@SyncItemFound)
  else
    SyncItemFound;
end;

procedure TAIDiskScanThread.NotifyProgress(const ACurrentPath: string);
begin
  FCurrentPath := ACurrentPath;
  if FScanner.ReturnOnMainThread then
    Synchronize(@SyncProgress)
  else
    SyncProgress;
end;

procedure TAIDiskScanThread.NotifyError(const APath, AMsg: string);
begin
  FErrorPath := APath;
  FErrorMsg := AMsg;
  if FScanner.ReturnOnMainThread then
    Synchronize(@SyncError)
  else
    SyncError;
end;

procedure TAIDiskScanThread.NotifyFinish(AState: TAIDiskTaskState; const AErrorMsg: string);
begin
  FTaskState := AState;
  FErrorMsg := AErrorMsg;
  if FScanner.ReturnOnMainThread then
    Synchronize(@SyncFinish)
  else
    SyncFinish;
end;

function TAIDiskScanThread.MatchesFilters(const AFileName: string; ASize: Int64; AAttr: Integer): Boolean;
var
  Ext: string;
  I: Integer;
  Matched: Boolean;
begin
  Result := True;

  // Min/Max File Size
  if (FScanner.FMinFileSize > 0) and (ASize < FScanner.FMinFileSize) then
    Exit(False);
  if (FScanner.FMaxFileSize > 0) and (ASize > FScanner.FMaxFileSize) then
    Exit(False);

  // Exclude system/hidden
  {$IFDEF MSWINDOWS}
  if not FScanner.IncludeSystem and ((AAttr and faSysFile) <> 0) then
    Exit(False);
  if not FScanner.IncludeHidden and ((AAttr and faHidden) <> 0) then
    Exit(False);
  {$ELSE}
  if not FScanner.IncludeHidden and (AFileName <> '') and (AFileName[1] = '.') then
    Exit(False);
  {$ENDIF}

  Ext := LowerCase(ExtractFileExt(AFileName));

  // Exclude extensions
  if FScanner.ExcludeExtensions.Count > 0 then
  begin
    for I := 0 to FScanner.ExcludeExtensions.Count - 1 do
    begin
      if Ext = LowerCase(FScanner.ExcludeExtensions[I]) then
        Exit(False);
    end;
  end;

  // Include extensions (filter check)
  if FSearchExtensions.Count > 0 then
  begin
    Matched := False;
    for I := 0 to FSearchExtensions.Count - 1 do
    begin
      if Ext = LowerCase(FSearchExtensions[I]) then
      begin
        Matched := True;
        Break;
      end;
    end;
    if not Matched then
      Exit(False);
  end;

  // File mask check (e.g. *.pas)
  if FScanner.FileMask <> '' then
  begin
    if not MatchesMask(AFileName, FScanner.FileMask) then
      Exit(False);
  end;
end;

function TAIDiskScanThread.ShouldExcludeDir(const ADirName: string): Boolean;
var
  I: Integer;
begin
  Result := False;
  for I := 0 to FScanner.ExcludeDirs.Count - 1 do
  begin
    if SameText(ADirName, FScanner.ExcludeDirs[I]) then
      Exit(True);
  end;
end;

procedure TAIDiskScanThread.ScanDirectory(const APath: string; ADepth: Integer);
var
  SR: TSearchRec;
  FindRes: Integer;
  FullPath: string;
  Item: TAIDiskItem;
  SubDirsList: TStringList;
  I: Integer;
begin
  if Terminated then Exit;

  // Depth Limit Check
  if (FScanner.MaxDepth > 0) and (ADepth > FScanner.MaxDepth) then
    Exit;

  NotifyProgress(APath);
  Inc(FProcessedDirs);

  SubDirsList := TStringList.Create;
  try
    FindRes := FindFirst(IncludeTrailingPathDelimiter(APath) + '*', faAnyFile, SR);
    try
      while (FindRes = 0) and not Terminated do
      begin
        if (SR.Name <> '.') and (SR.Name <> '..') then
        begin
          FullPath := IncludeTrailingPathDelimiter(APath) + SR.Name;

          if (SR.Attr and faDirectory) <> 0 then
          begin
            if not ShouldExcludeDir(SR.Name) then
            begin
              if FScanner.IncludeDirectories then
              begin
                if (FTaskType = sttScanBranch) or 
                   ((FTaskType = sttFindDir) and (Pos(LowerCase(FSearchQuery), LowerCase(SR.Name)) > 0)) then
                begin
                  Item := TAIDiskItem.Create;
                  Item.FullPath := FullPath;
                  Item.Name := SR.Name;
                  Item.ParentPath := APath;
                  Item.ItemType := ditDirectory;
                  Item.Depth := ADepth;
                  Item.ModifiedAt := FileDateToDateTime(SR.Time);
                  Item.CreatedAt := Item.ModifiedAt;
                  
                  {$IFDEF MSWINDOWS}
                  Item.IsHidden := (SR.Attr and faHidden) <> 0;
                  Item.IsSystem := (SR.Attr and faSysFile) <> 0;
                  Item.IsReadOnly := (SR.Attr and faReadOnly) <> 0;
                  {$ELSE}
                  Item.IsHidden := (SR.Name <> '') and (SR.Name[1] = '.');
                  {$ENDIF}

                  FScanner.Results.Add(Item);
                  Inc(FFoundItemsCount);
                  NotifyItemFound(Item);
                end;
              end;

              if FRecursive then
                SubDirsList.Add(FullPath);
            end;
          end;
        end;
        FindRes := FindNext(SR);
      end;
    finally
      SysUtils.FindClose(SR);
    end;

    // Scan Files in second pass
    if FScanner.IncludeFiles then
    begin
      FindRes := FindFirst(IncludeTrailingPathDelimiter(APath) + '*', faAnyFile, SR);
      try
        while (FindRes = 0) and not Terminated do
        begin
          if (SR.Name <> '.') and (SR.Name <> '..') and ((SR.Attr and faDirectory) = 0) then
          begin
            FullPath := IncludeTrailingPathDelimiter(APath) + SR.Name;
            Inc(FProcessedFiles);

            if MatchesFilters(SR.Name, SR.Size, SR.Attr) then
            begin
              if (FTaskType = sttScanBranch) or
                 (FTaskType = sttBuildInventory) or
                 ((FTaskType = sttFindFile) and (Pos(LowerCase(FSearchQuery), LowerCase(SR.Name)) > 0)) or
                 ((FTaskType = sttFindExt) and (SameText(ExtractFileExt(SR.Name), FSearchQuery))) or
                 ((FTaskType = sttFindExts) and (FSearchExtensions.IndexOf(ExtractFileExt(SR.Name)) >= 0)) or
                 ((FTaskType = sttFindMask) and (MatchesMask(SR.Name, FSearchQuery))) then
              begin
                Item := TAIDiskItem.Create;
                Item.FullPath := FullPath;
                Item.Name := SR.Name;
                Item.Extension := ExtractFileExt(SR.Name);
                Item.ParentPath := APath;
                Item.ItemType := ditFile;
                Item.Size := SR.Size;
                Item.Depth := ADepth;
                Item.ModifiedAt := FileDateToDateTime(SR.Time);
                Item.CreatedAt := Item.ModifiedAt;
                
                {$IFDEF MSWINDOWS}
                Item.IsHidden := (SR.Attr and faHidden) <> 0;
                Item.IsSystem := (SR.Attr and faSysFile) <> 0;
                Item.IsReadOnly := (SR.Attr and faReadOnly) <> 0;
                {$ELSE}
                Item.IsHidden := (SR.Name <> '') and (SR.Name[1] = '.');
                {$ENDIF}

                FScanner.Results.Add(Item);
                Inc(FFoundItemsCount);
                NotifyItemFound(Item);
              end;
            end;
          end;
          FindRes := FindNext(SR);
        end;
      finally
        SysUtils.FindClose(SR);
      end;
    end;

    if FRecursive and not Terminated then
    begin
      for I := 0 to SubDirsList.Count - 1 do
      begin
        if Terminated then Break;
        ScanDirectory(SubDirsList[I], ADepth + 1);
      end;
    end;

  except
    on E: Exception do
      NotifyError(APath, E.Message);
  end;
  SubDirsList.Free;
end;

procedure TAIDiskScanThread.DoScan;
begin
  if FTaskType = sttListVolumes then
  begin
    ExecuteTask;
    Exit;
  end;

  if FStartPath = '' then
    FStartPath := FScanner.RootPath;

  if FStartPath = '' then
  begin
    NotifyError('', 'RootPath or StartPath not defined.');
    Exit;
  end;

  ScanDirectory(FStartPath, 1);
end;

procedure TAIDiskScanThread.ExecuteTask;
var
  List: TStringList;
  I: Integer;
  Item: TAIDiskItem;
  {$IFDEF MSWINDOWS}
  DriveStr: array[0..512] of Char;
  Len: DWORD;
  P: PChar;
  {$ENDIF}
begin
  List := TStringList.Create;
  try
    {$IFDEF MSWINDOWS}
    Len := GetLogicalDriveStrings(512, DriveStr);
    if Len > 0 then
    begin
      P := DriveStr;
      while P^ <> #0 do
      begin
        List.Add(string(P));
        Inc(P, StrLen(P) + 1);
      end;
    end;
    {$ELSE}
    List.Add('/');
    if DirectoryExists('/home') then List.Add('/home');
    if DirectoryExists('/mnt') then List.Add('/mnt');
    if DirectoryExists('/media') then List.Add('/media');
    if DirectoryExists('/run/media') then List.Add('/run/media');
    {$ENDIF}

    for I := 0 to List.Count - 1 do
    begin
      Item := TAIDiskItem.Create;
      Item.FullPath := List[I];
      Item.Name := List[I];
      Item.ItemType := ditVolume;
      
      FScanner.Results.Add(Item);
      Inc(FFoundItemsCount);
      NotifyItemFound(Item);
    end;
  finally
    List.Free;
  end;
end;

procedure TAIDiskScanThread.Execute;
var
  I, J: Integer;
begin
  FTaskState := dtsRunning;
  NotifyStart('Scanning started task.');

  try
    if (FTaskType = sttFindExt) then
    begin
      if FSearchQuery <> '' then
      begin
        if FSearchQuery[1] <> '.' then
          FSearchQuery := '.' + FSearchQuery;
      end;
    end
    else if (FTaskType = sttFindExts) then
    begin
      FSearchExtensions.CommaText := FSearchQuery;
      for J := 0 to FSearchExtensions.Count - 1 do
      begin
        if (FSearchExtensions[J] <> '') and (FSearchExtensions[J][1] <> '.') then
          FSearchExtensions[J] := '.' + FSearchExtensions[J];
      end;
    end;

    if FScanner.Extensions.Count > 0 then
    begin
      for I := 0 to FScanner.Extensions.Count - 1 do
      begin
        if FScanner.Extensions[I] <> '' then
        begin
          if FScanner.Extensions[I][1] = '.' then
            FSearchExtensions.Add(FScanner.Extensions[I])
          else
            FSearchExtensions.Add('.' + FScanner.Extensions[I]);
        end;
      end;
    end;

    DoScan;

    if Terminated then
      FTaskState := dtsCancelled
    else
      FTaskState := dtsFinished;

    NotifyFinish(FTaskState, '');
  except
    on E: Exception do
    begin
      FTaskState := dtsError;
      NotifyFinish(dtsError, E.Message);
    end;
  end;
end;

{ TAIDiskTreeScanner }

constructor TAIDiskTreeScanner.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FActive := False;
  FBusy := False;
  FLastError := '';
  FLastTaskId := 0;

  FRootPath := '';
  FIncludeFiles := True;
  FIncludeDirectories := True;
  FRecursive := False;
  FMaxDepth := 0;
  FFollowSymlinks := False;
  FIncludeHidden := False;
  FIncludeSystem := False;

  FFileMask := '';
  FMinFileSize := 0;
  FMaxFileSize := 0;

  FReturnOnMainThread := True;
  FAutoClearResults := True;
  FCalculateHash := False;
  FHashAlgorithm := 'SHA256';

  FExtensions := TStringList.Create;
  FExcludeDirs := TStringList.Create;
  FExcludeExtensions := TStringList.Create;
  FResults := TObjectList.Create(True);
  FCurrentThread := nil;
end;

destructor TAIDiskTreeScanner.Destroy;
begin
  Cancel;
  FExtensions.Free;
  FExcludeDirs.Free;
  FExcludeExtensions.Free;
  FResults.Free;
  inherited Destroy;
end;

function TAIDiskTreeScanner.GenerateTaskId: Integer;
begin
  Inc(FLastTaskId);
  Result := FLastTaskId;
end;

procedure TAIDiskTreeScanner.SetBusy(const AValue: Boolean);
begin
  FBusy := AValue;
  FActive := AValue;
end;

procedure TAIDiskTreeScanner.Clear;
begin
  ClearResults;
  FLastError := '';
  SetBusy(False);
end;

procedure TAIDiskTreeScanner.Cancel;
begin
  if Assigned(FCurrentThread) then
  begin
    FCurrentThread.Terminate;
    FCurrentThread.WaitFor;
    FreeAndNil(FCurrentThread);
    SetBusy(False);
  end;
end;

function TAIDiskTreeScanner.IsBusy: Boolean;
begin
  Result := FBusy;
end;

function TAIDiskTreeScanner.GetLastError: string;
begin
  Result := FLastError;
end;

procedure TAIDiskTreeScanner.ClearResults;
begin
  FResults.Clear;
end;

function TAIDiskTreeScanner.ResultCount: Integer;
begin
  Result := FResults.Count;
end;

function TAIDiskTreeScanner.GetResult(AIndex: Integer): TAIDiskItem;
begin
  if (AIndex >= 0) and (AIndex < FResults.Count) then
    Result := TAIDiskItem(FResults[AIndex])
  else
    Result := nil;
end;

function TAIDiskTreeScanner.ListVolumesAsync: Integer;
begin
  Cancel;
  if FAutoClearResults then ClearResults;
  SetBusy(True);
  Result := GenerateTaskId;
  FCurrentThread := TAIDiskScanThread.Create(Self, Result, sttListVolumes, '', False);
  FCurrentThread.Start;
end;

function TAIDiskTreeScanner.ListVolumes: TObjectList;
var
  TaskId: Integer;
begin
  TaskId := ListVolumesAsync;
  if Assigned(FCurrentThread) then
  begin
    FCurrentThread.WaitFor;
    FreeAndNil(FCurrentThread);
    SetBusy(False);
  end;
  Result := FResults;
end;

function TAIDiskTreeScanner.ScanBranchAsync(const APath: string; AMode: TAIDiskScanMode): Integer;
begin
  Cancel;
  if FAutoClearResults then ClearResults;
  SetBusy(True);
  Result := GenerateTaskId;
  FCurrentThread := TAIDiskScanThread.Create(Self, Result, sttScanBranch, APath, AMode = dsmRecursive);
  FCurrentThread.Start;
end;

function TAIDiskTreeScanner.FindFileAsync(const AStartPath, AFileName: string; ARecursive: Boolean): Integer;
begin
  Cancel;
  if FAutoClearResults then ClearResults;
  SetBusy(True);
  Result := GenerateTaskId;
  FCurrentThread := TAIDiskScanThread.Create(Self, Result, sttFindFile, AStartPath, ARecursive, AFileName);
  FCurrentThread.Start;
end;

// Alias FindDirAsync
function TAIDiskTreeScanner.FindDirAsync(const AStartPath, ADirName: string; ARecursive: Boolean): Integer;
begin
  Cancel;
  if FAutoClearResults then ClearResults;
  SetBusy(True);
  Result := GenerateTaskId;
  FCurrentThread := TAIDiskScanThread.Create(Self, Result, sttFindDir, AStartPath, ARecursive, ADirName);
  FCurrentThread.Start;
end;

function TAIDiskTreeScanner.FindExtAsync(const AStartPath, AExtension: string; ARecursive: Boolean): Integer;
begin
  Cancel;
  if FAutoClearResults then ClearResults;
  SetBusy(True);
  Result := GenerateTaskId;
  FCurrentThread := TAIDiskScanThread.Create(Self, Result, sttFindExt, AStartPath, ARecursive, AExtension);
  FCurrentThread.Start;
end;

function TAIDiskTreeScanner.FindExtsAsync(const AStartPath: string; AExtensions: TStrings; ARecursive: Boolean): Integer;
begin
  Cancel;
  if FAutoClearResults then ClearResults;
  SetBusy(True);
  Result := GenerateTaskId;
  FCurrentThread := TAIDiskScanThread.Create(Self, Result, sttFindExts, AStartPath, ARecursive, AExtensions.CommaText);
  FCurrentThread.Start;
end;

function TAIDiskTreeScanner.FindMaskAsync(const AStartPath, AMask: string; ARecursive: Boolean): Integer;
begin
  Cancel;
  if FAutoClearResults then ClearResults;
  SetBusy(True);
  Result := GenerateTaskId;
  FCurrentThread := TAIDiskScanThread.Create(Self, Result, sttFindMask, AStartPath, ARecursive, AMask);
  FCurrentThread.Start;
end;

function TAIDiskTreeScanner.BuildDatasetInventoryAsync(const AStartPath: string; ARecursive: Boolean): Integer;
begin
  Cancel;
  if FAutoClearResults then ClearResults;
  SetBusy(True);
  Result := GenerateTaskId;
  FCurrentThread := TAIDiskScanThread.Create(Self, Result, sttBuildInventory, AStartPath, ARecursive);
  FCurrentThread.Start;
end;

function TAIDiskTreeScanner.ExportToJSON(const AFileName: string): Boolean;
var
  FS: TStringList;
  I: Integer;
  Item: TAIDiskItem;
  ClassSug: string;
begin
  Result := False;
  FS := TStringList.Create;
  try
    FS.Add('[');
    for I := 0 to FResults.Count - 1 do
    begin
      Item := TAIDiskItem(FResults[I]);
      ClassSug := ExtractFileName(ExcludeTrailingPathDelimiter(Item.ParentPath));
      FS.Add('  {');
      FS.Add('    "path": "' + StringReplace(Item.FullPath, '\', '/', [rfReplaceAll]) + '",');
      FS.Add('    "name": "' + Item.Name + '",');
      FS.Add('    "extension": "' + Item.Extension + '",');
      FS.Add('    "type": "' + BoolToStr(Item.ItemType = ditFile, 'file', 'directory') + '",');
      FS.Add('    "class": "' + ClassSug + '",');
      FS.Add('    "size": ' + IntToStr(Item.Size));
      if I = FResults.Count - 1 then
        FS.Add('  }')
      else
        FS.Add('  },');
    end;
    FS.Add(']');
    FS.SaveToFile(AFileName);
    Result := True;
  finally
    FS.Free;
  end;
end;

function TAIDiskTreeScanner.ExportToCSV(const AFileName: string): Boolean;
var
  FS: TStringList;
  I: Integer;
  Item: TAIDiskItem;
  ClassSug: string;
begin
  Result := False;
  FS := TStringList.Create;
  try
    FS.Add('path,name,extension,type,class,size');
    for I := 0 to FResults.Count - 1 do
    begin
      Item := TAIDiskItem(FResults[I]);
      ClassSug := ExtractFileName(ExcludeTrailingPathDelimiter(Item.ParentPath));
      FS.Add(Format('"%s","%s","%s","%s","%s",%d', [
        StringReplace(Item.FullPath, '\', '/', [rfReplaceAll]),
        Item.Name,
        Item.Extension,
        BoolToStr(Item.ItemType = ditFile, 'file', 'directory'),
        ClassSug,
        Item.Size
      ]));
    end;
    FS.SaveToFile(AFileName);
    Result := True;
  finally
    FS.Free;
  end;
end;

function TAIDiskTreeScanner.ExportToTXT(const AFileName: string): Boolean;
var
  FS: TStringList;
  I: Integer;
  Item: TAIDiskItem;
begin
  Result := False;
  FS := TStringList.Create;
  try
    for I := 0 to FResults.Count - 1 do
    begin
      Item := TAIDiskItem(FResults[I]);
      FS.Add(Item.FullPath);
    end;
    FS.SaveToFile(AFileName);
    Result := True;
  finally
    FS.Free;
  end;
end;

function TAIDiskTreeScanner.IsImageFile(const AFileName: string): Boolean;
var
  Ext: string;
begin
  Ext := LowerCase(ExtractFileExt(AFileName));
  Result := (Ext = '.jpg') or (Ext = '.jpeg') or (Ext = '.png') or (Ext = '.bmp') or
            (Ext = '.gif') or (Ext = '.webp') or (Ext = '.tif') or (Ext = '.tiff');
end;

function TAIDiskTreeScanner.IsTextFile(const AFileName: string): Boolean;
var
  Ext: string;
begin
  Ext := LowerCase(ExtractFileExt(AFileName));
  Result := (Ext = '.txt') or (Ext = '.md') or (Ext = '.csv') or (Ext = '.json') or
            (Ext = '.xml') or (Ext = '.html') or (Ext = '.pas') or (Ext = '.pp') or
            (Ext = '.py') or (Ext = '.c') or (Ext = '.cpp') or (Ext = '.h');
end;

function TAIDiskTreeScanner.IsAudioFile(const AFileName: string): Boolean;
var
  Ext: string;
begin
  Ext := LowerCase(ExtractFileExt(AFileName));
  Result := (Ext = '.wav') or (Ext = '.mp3') or (Ext = '.ogg') or (Ext = '.flac');
end;

function TAIDiskTreeScanner.IsVideoFile(const AFileName: string): Boolean;
var
  Ext: string;
begin
  Ext := LowerCase(ExtractFileExt(AFileName));
  Result := (Ext = '.mp4') or (Ext = '.avi') or (Ext = '.mkv') or (Ext = '.mov');
end;

function TAIDiskTreeScanner.IsDataFile(const AFileName: string): Boolean;
var
  Ext: string;
begin
  Ext := LowerCase(ExtractFileExt(AFileName));
  Result := (Ext = '.csv') or (Ext = '.json') or (Ext = '.xml') or (Ext = '.sqlite') or (Ext = '.db');
end;

end.
