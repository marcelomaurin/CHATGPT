unit main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, StdCtrls,
  Grids, EditBtn, ComCtrls, FileCtrl, aidisktreescanner, aidiskitem;

type

  { TfrmMain }

  TfrmMain = class(TForm)
    pnlTop: TPanel;
    lblTarget: TLabel;
    deTarget: TDirectoryEdit;
    btnScan: TButton;
    btnStop: TButton;
    sgFiles: TStringGrid;
    pnlStatus: TPanel;
    lblStatus: TLabel;
    ProgressBar1: TProgressBar;

    procedure FormCreate(Sender: TObject);
    procedure btnScanClick(Sender: TObject);
    procedure btnStopClick(Sender: TObject);

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

    procedure UpdateUIState;
  public

  end;

var
  frmMain: TfrmMain;

implementation

{$R *.lfm}

{$IFDEF MSWINDOWS}
uses
  Windows;

function GetFileOwner(const APath: string): string;
var
  SecDesc: PSECURITY_DESCRIPTOR;
  Needed: DWORD;
  OwnerSID: PSID;
  OwnerDefaulted: LongBool;
  NameLen, DomainLen: DWORD;
  Name, Domain: array[0..255] of AnsiChar;
  Use: SID_NAME_USE;
begin
  Result := 'Unknown';
  Needed := 0;
  OwnerSID := nil;
  OwnerDefaulted := False;
  GetFileSecurityA(PAnsiChar(APath), OWNER_SECURITY_INFORMATION, nil, 0, @Needed);
  if Needed > 0 then
  begin
    GetMem(SecDesc, Needed);
    try
      if GetFileSecurityA(PAnsiChar(APath), OWNER_SECURITY_INFORMATION, SecDesc, Needed, @Needed) then
      begin
        if GetSecurityDescriptorOwner(SecDesc, OwnerSID, @OwnerDefaulted) then
        begin
          if Assigned(OwnerSID) then
          begin
            NameLen := 256;
            DomainLen := 256;
            if LookupAccountSidA(nil, OwnerSID, Name, NameLen, Domain, DomainLen, Use) then
            begin
              if DomainLen > 0 then
                Result := string(Domain) + '\' + string(Name)
              else
                Result := string(Name);
            end;
          end;
        end;
      end;
    finally
      FreeMem(SecDesc);
    end;
  end;
end;
{$ELSE}
uses
  BaseUnix, Unix;

function GetFileOwner(const APath: string): string;
var
  S: stat;
  Passwd: PPasswd;
begin
  Result := 'Unknown';
  if fpstat(PChar(APath), S) = 0 then
  begin
    Passwd := getpwuid(S.st_uid);
    if Assigned(Passwd) then
      Result := string(Passwd^.pw_name)
    else
      Result := IntToStr(S.st_uid);
  end;
end;
{$ENDIF}

{ TfrmMain }

procedure TfrmMain.FormCreate(Sender: TObject);
begin
  DiskTreeScanner1 := TAIDiskTreeScanner.Create(Self);

  // Setup events
  DiskTreeScanner1.OnTaskStart := @DiskTaskStart;
  DiskTreeScanner1.OnItemFound := @DiskItemFound;
  DiskTreeScanner1.OnProgress := @DiskProgress;
  DiskTreeScanner1.OnTaskFinish := @DiskTaskFinish;
  DiskTreeScanner1.OnError := @DiskError;

  // Scanner config
  DiskTreeScanner1.IncludeFiles := True;
  DiskTreeScanner1.IncludeDirectories := True;
  DiskTreeScanner1.IncludeHidden := False;
  DiskTreeScanner1.IncludeSystem := False;
  DiskTreeScanner1.FollowSymlinks := False;
  DiskTreeScanner1.MaxDepth := 0; // Unlimited recursion by default
  DiskTreeScanner1.ReturnOnMainThread := True;

  // Default target path
  {$IFDEF MSWINDOWS}
  deTarget.Directory := 'C:\';
  {$ELSE}
  deTarget.Directory := '/';
  {$ENDIF}

  // Setup StringGrid Headers
  sgFiles.ColCount := 7;
  sgFiles.RowCount := 1;
  sgFiles.FixedRows := 1;
  sgFiles.FixedCols := 0;
  
  sgFiles.Cells[0, 0] := 'Depth';
  sgFiles.Cells[1, 0] := 'Absolute Path';
  sgFiles.Cells[2, 0] := 'File Name';
  sgFiles.Cells[3, 0] := 'Extension';
  sgFiles.Cells[4, 0] := 'Properties';
  sgFiles.Cells[5, 0] := 'Size (Bytes)';
  sgFiles.Cells[6, 0] := 'Owner';

  // Set default widths
  sgFiles.ColWidths[0] := 60;
  sgFiles.ColWidths[1] := 320;
  sgFiles.ColWidths[2] := 180;
  sgFiles.ColWidths[3] := 80;
  sgFiles.ColWidths[4] := 90;
  sgFiles.ColWidths[5] := 100;
  sgFiles.ColWidths[6] := 120;

  UpdateUIState;
end;

procedure TfrmMain.btnScanClick(Sender: TObject);
begin
  if Trim(deTarget.Directory) = '' then
  begin
    ShowMessage('Please select a target directory first.');
    Exit;
  end;

  sgFiles.RowCount := 1; // Clear Grid leaving header
  DiskTreeScanner1.RootPath := deTarget.Directory;
  FCurrentTaskId := DiskTreeScanner1.ScanBranchAsync(deTarget.Directory, dsmRecursive);
end;

procedure TfrmMain.btnStopClick(Sender: TObject);
begin
  DiskTreeScanner1.Cancel;
end;

procedure TfrmMain.DiskTaskStart(Sender: TObject; TaskId: Integer; const Description: string);
begin
  ProgressBar1.Style := pbstMarquee;
  UpdateUIState;
  lblStatus.Caption := 'Scanning started...';
end;

procedure TfrmMain.DiskItemFound(Sender: TObject; TaskId: Integer; Item: TAIDiskItem);
var
  NewRow: Integer;
  AttrStr: string;
begin
  sgFiles.RowCount := sgFiles.RowCount + 1;
  NewRow := sgFiles.RowCount - 1;

  sgFiles.Cells[0, NewRow] := IntToStr(Item.Depth);
  sgFiles.Cells[1, NewRow] := Item.FullPath;
  sgFiles.Cells[2, NewRow] := Item.Name;
  
  if Item.ItemType = ditFile then
  begin
    sgFiles.Cells[3, NewRow] := Item.Extension;
    sgFiles.Cells[5, NewRow] := IntToStr(Item.Size);
  end
  else
  begin
    sgFiles.Cells[3, NewRow] := '(Folder)';
    sgFiles.Cells[5, NewRow] := '-';
  end;

  // Properties/Attributes
  AttrStr := '';
  if Item.IsReadOnly then AttrStr := AttrStr + 'R';
  if Item.IsHidden then AttrStr := AttrStr + 'H';
  if Item.IsSystem then AttrStr := AttrStr + 'S';
  if AttrStr = '' then AttrStr := 'Normal';
  sgFiles.Cells[4, NewRow] := AttrStr;

  // File Owner
  sgFiles.Cells[6, NewRow] := GetFileOwner(Item.FullPath);
end;

procedure TfrmMain.DiskProgress(Sender: TObject; TaskId: Integer; ProcessedDirs: Int64;
  ProcessedFiles: Int64; FoundItems: Int64; const CurrentPath: string);
begin
  lblStatus.Caption := Format('Processed: Dirs: %d | Files: %d | Found: %d | Current: %s',
    [ProcessedDirs, ProcessedFiles, FoundItems, MinimizeName(CurrentPath, lblStatus.Canvas, 400)]);
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

  lblStatus.Caption := Format('Task %d Finished. State: %s. Total items found: %d', [TaskId, StateStr, TotalFound]);
  UpdateUIState;
end;

procedure TfrmMain.DiskError(Sender: TObject; TaskId: Integer; const Path: string; const ErrorMsg: string);
begin
  // Show error
end;

procedure TfrmMain.UpdateUIState;
var
  Running: Boolean;
begin
  Running := DiskTreeScanner1.IsBusy;
  deTarget.Enabled := not Running;
  btnScan.Enabled := not Running;
  btnStop.Enabled := Running;
end;

end.
