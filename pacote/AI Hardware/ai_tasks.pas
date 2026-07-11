unit ai_tasks;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Math
  {$IFDEF MSWINDOWS}, Windows{$ENDIF}
  {$IFDEF UNIX}, BaseUnix, Unix, Process{$ENDIF}
  {$IFDEF DARWIN}, MacOSAll{$ENDIF};

type
  TAITaskState = (tsUnknown, tsRunning, tsSleeping, tsDiskSleep, tsStopped,
    tsZombie, tsTracing, tsDead, tsIdle);

  TAITaskSortBy = (sbPID, sbName, sbCPU, sbMemory, sbThreads, sbStartTime);
  TAIProcessSortBy = TAITaskSortBy;

  TAITask = class(TCollectionItem)
  private
    FPID: Int64;
    FPPID: Int64;
    FName: string;
    FExePath: string;
    FCommandLine: string;
    FUser: string;
    FState: TAITaskState;
    FPriority: Integer;
    FNice: Integer;
    FThreads: Integer;
    FMemoryWorking: Int64;
    FMemoryVirtual: Int64;
    FMemoryShared: Int64;
    FCPUTimeMS: Int64;
    FCPUPercent: Double;
    FStartTime: TDateTime;
    FStartTicks: QWord;
    FSessionID: Integer;
    FIsElevated: Boolean;
    FHandleCount: Integer;
    FIOReadBytes: Int64;
    FIOWriteBytes: Int64;
    function GetStateStr: string;
    function GetElapsed: TDateTime;
    function GetElapsedStr: string;
  public
    property PID: Int64 read FPID write FPID;
    property PPID: Int64 read FPPID write FPPID;
    property Name: string read FName write FName;
    property ExePath: string read FExePath write FExePath;
    property CommandLine: string read FCommandLine write FCommandLine;
    property User: string read FUser write FUser;
    property State: TAITaskState read FState write FState;
    property StateStr: string read GetStateStr;
    property Priority: Integer read FPriority write FPriority;
    property Nice: Integer read FNice write FNice;
    property Threads: Integer read FThreads write FThreads;
    property MemoryWorking: Int64 read FMemoryWorking write FMemoryWorking;
    property MemoryVirtual: Int64 read FMemoryVirtual write FMemoryVirtual;
    property MemoryShared: Int64 read FMemoryShared write FMemoryShared;
    property CPUTimeMS: Int64 read FCPUTimeMS write FCPUTimeMS;
    property CPUPercent: Double read FCPUPercent write FCPUPercent;
    property StartTime: TDateTime read FStartTime write FStartTime;
    property StartTicks: QWord read FStartTicks write FStartTicks;
    property Elapsed: TDateTime read GetElapsed;
    property ElapsedStr: string read GetElapsedStr;
    property SessionID: Integer read FSessionID write FSessionID;
    property IsElevated: Boolean read FIsElevated write FIsElevated;
    property HandleCount: Integer read FHandleCount write FHandleCount;
    property IOReadBytes: Int64 read FIOReadBytes write FIOReadBytes;
    property IOWriteBytes: Int64 read FIOWriteBytes write FIOWriteBytes;
  end;

  TAITaskList = class(TCollection)
  private
    function GetItem(I: Integer): TAITask;
  public
    constructor Create;
    function Add: TAITask;
    property Items[I: Integer]: TAITask read GetItem; default;
  end;

  TAITasks = class(TComponent)
  private
    FTasks: TAITaskList;
    FPrev: TStringList;
    FPrevTick: QWord;
    FHasPrev: Boolean;
    FCoreCount: Integer;
    FIncludeSystem: Boolean;
    FOnlyCurrentUser: Boolean;
    FSortBy: TAITaskSortBy;
    FSortDescending: Boolean;
    FLastError: string;
    FTotalCPU: Double;
    FTotalMemory: Int64;
    function GetCount: Integer;
    procedure CollectWindows;
    procedure CollectLinux;
    procedure CollectMac;
    procedure ComputeCPUPercent;
    procedure SortTasks;
    function TaskKey(T: TAITask): string;
    function CurrentUserName: string;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure Refresh;
    procedure MeasureCPU(IntervalMS: Integer = 1000);
    procedure ResetHistory;
    function FindByPID(APID: Int64): TAITask;
    function FindByName(const AName: string): TAITask;
    function FindAllByName(const AName: string): TList;
    function IsRunning(const AName: string): Boolean;
    function CountByName(const AName: string): Integer;
    function TopByCPU(N: Integer = 10): TList;
    function TopByMemory(N: Integer = 10): TList;
    function Kill(APID: Int64; Force: Boolean = False): Boolean;
    function KillByName(const AName: string; Force: Boolean = False): Integer;
    procedure GetInfo(Lines: TStrings);
    procedure GetTaskList(Lines: TStrings);
    procedure SaveToCSV(const FileName: string);
    property Tasks: TAITaskList read FTasks;
    property Count: Integer read GetCount;
    property TotalCPU: Double read FTotalCPU;
    property TotalMemory: Int64 read FTotalMemory;
    property CoreCount: Integer read FCoreCount;
    property LastError: string read FLastError;
  published
    property IncludeSystem: Boolean read FIncludeSystem write FIncludeSystem default True;
    property OnlyCurrentUser: Boolean read FOnlyCurrentUser write FOnlyCurrentUser default False;
    property SortBy: TAITaskSortBy read FSortBy write FSortBy default sbCPU;
    property SortDescending: Boolean read FSortDescending write FSortDescending default True;
  end;

  TAITaskSnapshot = record
    Key: string;
    CPUTimeMS: Int64;
  end;

{$IFDEF MSWINDOWS}
type
  PProcessMemoryCounters = ^TProcessMemoryCounters;
  TProcessMemoryCounters = record
    cb: DWORD;
    PageFaultCount: DWORD;
    PeakWorkingSetSize: SIZE_T;
    WorkingSetSize: SIZE_T;
    QuotaPeakPagedPoolUsage: SIZE_T;
    QuotaPagedPoolUsage: SIZE_T;
    QuotaPeakNonPagedPoolUsage: SIZE_T;
    QuotaNonPagedPoolUsage: SIZE_T;
    PagefileUsage: SIZE_T;
    PeakPagefileUsage: SIZE_T;
  end;

  PProcessEntry32 = ^TProcessEntry32;
  TProcessEntry32 = record
    dwSize: DWORD;
    cntUsage: DWORD;
    th32ProcessID: DWORD;
    th32DefaultHeapID: NativeUInt;
    th32ModuleID: DWORD;
    cntThreads: DWORD;
    th32ParentProcessID: DWORD;
    pcPriClassBase: Longint;
    dwFlags: DWORD;
    szExeFile: array[0..MAX_PATH - 1] of Char;
  end;

const
  TH32CS_SNAPPROCESS = $00000002;

function CreateToolhelp32Snapshot(dwFlags, th32ProcessID: DWORD): THandle; stdcall; external 'kernel32.dll';
function Process32First(hSnapshot: THandle; var lppe: TProcessEntry32): BOOL; stdcall; external 'kernel32.dll' name 'Process32FirstW';
function Process32Next(hSnapshot: THandle; var lppe: TProcessEntry32): BOOL; stdcall; external 'kernel32.dll' name 'Process32NextW';
function GetProcessHandleCount(hProcess: THandle; var pdwHandleCount: DWORD): BOOL; stdcall; external 'kernel32.dll';
{$ENDIF}

procedure Register;

implementation

uses
  StrUtils, DateUtils
  {$IFDEF LINUX}, Users{$ENDIF};

{$IFDEF MSWINDOWS}
function GetProcessMemoryInfo(hProcess: THandle; ppsmemCounters: PProcessMemoryCounters;
  cb: DWORD): BOOL; stdcall; external 'psapi.dll' name 'GetProcessMemoryInfo';
{$ENDIF}

function SafeStrToInt64Ex(const S: string; Def: Int64 = 0): Int64;
begin
  Result := Def;
  try
    Result := StrToInt64(Trim(S));
  except
  end;
end;

function SafeStrToFloatEx(const S: string; Def: Double = 0): Double;
begin
  Result := Def;
  try
    Result := StrToFloat(StringReplace(Trim(S), ',', '.', [rfReplaceAll]));
  except
  end;
end;

function LoadTextFileEx(const FileName: string): string;
var
  SL: TStringList;
begin
  Result := '';
  if not FileExists(FileName) then Exit;
  SL := TStringList.Create;
  try
    SL.LoadFromFile(FileName);
    Result := SL.Text;
  finally
    SL.Free;
  end;
end;

function ExtractAfterEx(const S, Token: string): string;
var
  P: SizeInt;
begin
  P := Pos(Token, S);
  if P > 0 then
    Result := Copy(S, P + Length(Token), MaxInt)
  else
    Result := '';
end;

function FormatBytesEx(Value: Int64): string;
const
  KB = 1024;
  MB = KB * 1024;
  GB = MB * 1024;
begin
  if Abs(Value) >= GB then Exit(FormatFloat('0.00 GB', Value / GB));
  if Abs(Value) >= MB then Exit(FormatFloat('0.00 MB', Value / MB));
  if Abs(Value) >= KB then Exit(FormatFloat('0.00 KB', Value / KB));
  Result := IntToStr(Value) + ' B';
end;

function GetSystemThreadCountEx: Integer;
{$IFDEF WINDOWS}
var
  SI: TSystemInfo;
{$ENDIF}
begin
  Result := 1;
  {$IFDEF WINDOWS}
  FillChar(SI, SizeOf(SI), 0);
  GetSystemInfo(SI);
  Result := SI.dwNumberOfProcessors;
  {$ELSE}
  try
    Result := GetCPUCount;
  except
    Result := 1;
  end;
  {$ENDIF}
  if Result < 1 then Result := 1;
end;

function RunCmdEx(const Exe: string; const Args: array of string; out Output: string): Boolean;
{$IFDEF UNIX}
var
  P: TProcess;
  I: Integer;
begin
  Output := '';
  P := TProcess.Create(nil);
  try
    P.Executable := Exe;
    for I := 0 to High(Args) do
      P.Parameters.Add(Args[I]);
    P.Options := [poUsePipes, poStderrToOutput];
    Result := P.Execute = 0;
    if Result then
    begin
      Output := P.Output.ReadAnsiString;
      while P.Running do
        Sleep(1);
    end;
  finally
    P.Free;
  end;
end;
{$ELSE}
begin
  Output := '';
  Result := False;
end;
{$ENDIF}

function TAITask.GetStateStr: string;
begin
  case FState of
    tsRunning: Result := 'Executando';
    tsSleeping: Result := 'Dormindo';
    tsDiskSleep: Result := 'Aguardando I/O';
    tsStopped: Result := 'Parado';
    tsZombie: Result := 'Zumbi';
    tsTracing: Result := 'Em depuracao';
    tsDead: Result := 'Morto';
    tsIdle: Result := 'Ocioso';
  else
    Result := 'Desconhecido';
  end;
end;

function TAITask.GetElapsed: TDateTime;
begin
  if FStartTime <= 0 then Exit(0);
  Result := Now - FStartTime;
end;

function TAITask.GetElapsedStr: string;
var
  S, D, H, M: Int64;
begin
  if FStartTime <= 0 then Exit('n/d');
  S := SecondsBetween(Now, FStartTime);
  D := S div 86400;
  H := (S mod 86400) div 3600;
  M := (S mod 3600) div 60;
  if D > 0 then
    Result := Format('%dd %02d:%02d', [D, H, M])
  else
    Result := Format('%02d:%02d:%02d', [H, M, S mod 60]);
end;

constructor TAITaskList.Create;
begin
  inherited Create(TAITask);
end;

function TAITaskList.Add: TAITask;
begin
  Result := TAITask(inherited Add);
end;

function TAITaskList.GetItem(I: Integer): TAITask;
begin
  Result := TAITask(inherited Items[I]);
end;

constructor TAITasks.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FTasks := TAITaskList.Create;
  FPrev := TStringList.Create;
  FPrev.Sorted := True;
  FPrev.Duplicates := dupIgnore;
  FIncludeSystem := True;
  FOnlyCurrentUser := False;
  FSortBy := sbCPU;
  FSortDescending := True;
  FCoreCount := GetSystemThreadCountEx;
end;

destructor TAITasks.Destroy;
begin
  FTasks.Free;
  FPrev.Free;
  inherited Destroy;
end;

function TAITasks.GetCount: Integer;
begin
  Result := FTasks.Count;
end;

function TAITasks.TaskKey(T: TAITask): string;
begin
  Result := Format('%d|%u', [T.PID, T.StartTicks]);
end;

function TAITasks.CurrentUserName: string;
begin
  Result := SysUtils.GetEnvironmentVariable('USERNAME');
  if Result = '' then
    Result := SysUtils.GetEnvironmentVariable('USER');
end;

procedure TAITasks.ResetHistory;
begin
  FPrev.Clear;
  FPrevTick := 0;
  FHasPrev := False;
end;

procedure TAITasks.Refresh;
begin
  FLastError := '';
  FTasks.Clear;
  FTotalCPU := 0;
  FTotalMemory := 0;
  try
    {$IFDEF WINDOWS} CollectWindows; {$ENDIF}
    {$IFDEF LINUX} CollectLinux; {$ENDIF}
    {$IFDEF DARWIN} CollectMac; {$ENDIF}
  except
    on E: Exception do
      FLastError := E.Message;
  end;
  ComputeCPUPercent;
  SortTasks;
end;

procedure TAITasks.MeasureCPU(IntervalMS: Integer);
begin
  ResetHistory;
  Refresh;
  Sleep(IntervalMS);
  Refresh;
end;

procedure TAITasks.ComputeCPUPercent;
var
  I, Idx: Integer;
  T: TAITask;
  NowTick, PrevCPU, DeltaCPU, DeltaWall: Int64;
  NewPrev: TStringList;
  Key: string;
begin
  NowTick := GetTickCount64;
  NewPrev := TStringList.Create;
  try
    NewPrev.Sorted := True;
    NewPrev.Duplicates := dupIgnore;
    if FHasPrev then
      DeltaWall := Int64(NowTick - FPrevTick)
    else
      DeltaWall := 0;
    for I := 0 to FTasks.Count - 1 do
    begin
      T := FTasks[I];
      Key := TaskKey(T);
      NewPrev.Values[Key] := IntToStr(T.CPUTimeMS);
      T.CPUPercent := 0;
      if (not FHasPrev) or (DeltaWall <= 0) then
        Continue;
      Idx := FPrev.IndexOfName(Key);
      if Idx < 0 then
        Continue;
      PrevCPU := SafeStrToInt64Ex(FPrev.ValueFromIndex[Idx], 0);
      DeltaCPU := T.CPUTimeMS - PrevCPU;
      if DeltaCPU < 0 then
        Continue;
      T.CPUPercent := (DeltaCPU / DeltaWall) * 100 / FCoreCount;
      T.CPUPercent := Math.Max(0, Math.Min(100, T.CPUPercent));
    end;
    FPrev.Assign(NewPrev);
    FPrevTick := NowTick;
    FHasPrev := True;
  finally
    NewPrev.Free;
  end;
end;

{$IFDEF WINDOWS}
function FileTimeToMS(const FT: TFileTime): Int64;
var
  L: ULARGE_INTEGER;
begin
  L.LowPart := FT.dwLowDateTime;
  L.HighPart := FT.dwHighDateTime;
  Result := Int64(L.QuadPart) div 10000;
end;

function FileTimeToDT(const FT: TFileTime): TDateTime;
var
  Local: TFileTime;
  ST: TSystemTime;
begin
  Result := 0;
  if (FT.dwLowDateTime = 0) and (FT.dwHighDateTime = 0) then Exit;
  if not FileTimeToLocalFileTime(FT, Local) then Exit;
  if not FileTimeToSystemTime(Local, ST) then Exit;
  try
    Result := SystemTimeToDateTime(ST);
  except
    Result := 0;
  end;
end;

procedure TAITasks.CollectWindows;
var
  Snap: THandle;
  PE: TProcessEntry32;
  T: TAITask;
  H: THandle;
  PMC: TProcessMemoryCounters;
  CT, ET, KT, UT: TFileTime;
  HC: DWORD;
begin
  Snap := CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0);
  if Snap = INVALID_HANDLE_VALUE then
  begin
    FLastError := SysErrorMessage(GetLastError);
    Exit;
  end;
  try
    PE.dwSize := SizeOf(PE);
    if not Process32First(Snap, PE) then Exit;
    repeat
      if (PE.th32ProcessID = 0) and (not FIncludeSystem) then
        Continue;
      T := FTasks.Add;
      T.PID := PE.th32ProcessID;
      T.PPID := PE.th32ParentProcessID;
      T.Name := StrPas(PE.szExeFile);
      T.Threads := PE.cntThreads;
      T.Priority := PE.pcPriClassBase;
      T.State := tsRunning;
      H := OpenProcess(PROCESS_QUERY_LIMITED_INFORMATION or PROCESS_VM_READ, False, PE.th32ProcessID);
      if H = 0 then
        H := OpenProcess($1000, False, PE.th32ProcessID);
      if H <> 0 then
      try
        FillChar(PMC, SizeOf(PMC), 0);
        PMC.cb := SizeOf(PMC);
        if GetProcessMemoryInfo(H, @PMC, SizeOf(PMC)) then
        begin
          T.MemoryWorking := PMC.WorkingSetSize;
          T.MemoryVirtual := PMC.PagefileUsage;
        end;
        if GetProcessTimes(H, CT, ET, KT, UT) then
        begin
          T.CPUTimeMS := FileTimeToMS(KT) + FileTimeToMS(UT);
          T.StartTime := FileTimeToDT(CT);
          T.StartTicks := (QWord(CT.dwHighDateTime) shl 32) or CT.dwLowDateTime;
        end;
        HC := 0;
        if GetProcessHandleCount(H, HC) then
          T.HandleCount := HC;
      finally
        CloseHandle(H);
      end;
      if FOnlyCurrentUser and (AnsiCompareText(CurrentUserName, T.User) <> 0) then
        Continue;
    until not Process32Next(Snap, PE);
  finally
    CloseHandle(Snap);
  end;
end;
{$ELSE}
procedure TAITasks.CollectWindows;
begin
end;
{$ENDIF}

{$IFDEF LINUX}
procedure TAITasks.CollectLinux;
var
  SR: TSearchRec;
  PID: Int64;
  Base, S: string;
  T: TAITask;
  Cols, Lines: TStringList;
  I, P: Integer;
  ClkTck, BootTime, Uid, MeuUid: Int64;
  Utime, Stime, Starttime: Int64;

  function ReadProc(const Rel: string): string;
  begin
    Result := LoadTextFileEx(Base + Rel);
  end;

begin
  ClkTck := 100;
  BootTime := 0;
  Lines := TStringList.Create;
  try
    Lines.Text := LoadTextFileEx('/proc/stat');
    for I := 0 to Lines.Count - 1 do
      if StartsText('btime ', Lines[I]) then
      begin
        BootTime := SafeStrToInt64Ex(ExtractAfterEx(Lines[I], 'btime '), 0);
        Break;
      end;
  finally
    Lines.Free;
  end;

  MeuUid := fpGetUid;
  if FindFirst('/proc/*', faDirectory, SR) <> 0 then
  begin
    FLastError := '/proc inacessivel';
    Exit;
  end;
  Cols := TStringList.Create;
  Lines := TStringList.Create;
  try
    repeat
      if not TryStrToInt64(SR.Name, PID) then
        Continue;
      Base := '/proc/' + SR.Name + '/';
      S := ReadProc('stat');
      if S = '' then
        Continue;
      P := LastDelimiter(')', S);
      if P = 0 then
        Continue;
      T := FTasks.Add;
      T.PID := PID;
      T.Name := Copy(S, Pos('(', S) + 1, P - Pos('(', S) - 1);
      Cols.Clear;
      Cols.Delimiter := ' ';
      Cols.StrictDelimiter := False;
      Cols.DelimitedText := Trim(Copy(S, P + 1, MaxInt));
      if Cols.Count > 0 then
        case Cols[0][1] of
          'R': T.State := tsRunning;
          'S': T.State := tsSleeping;
          'D': T.State := tsDiskSleep;
          'T': T.State := tsStopped;
          'Z': T.State := tsZombie;
          't': T.State := tsTracing;
          'X', 'x': T.State := tsDead;
          'I': T.State := tsIdle;
        else
          T.State := tsUnknown;
        end;
      if Cols.Count > 1 then T.PPID := SafeStrToInt64Ex(Cols[1], 0);
      Utime := 0; Stime := 0; Starttime := 0;
      if Cols.Count > 11 then Utime := SafeStrToInt64Ex(Cols[11], 0);
      if Cols.Count > 12 then Stime := SafeStrToInt64Ex(Cols[12], 0);
      if Cols.Count > 15 then T.Priority := SafeStrToInt64Ex(Cols[15], 0);
      if Cols.Count > 16 then T.Nice := SafeStrToInt64Ex(Cols[16], 0);
      if Cols.Count > 17 then T.Threads := SafeStrToInt64Ex(Cols[17], 0);
      if Cols.Count > 19 then Starttime := SafeStrToInt64Ex(Cols[19], 0);
      T.CPUTimeMS := ((Utime + Stime) * 1000) div ClkTck;
      T.StartTicks := QWord(Starttime);
      if (BootTime > 0) and (Starttime > 0) then
        T.StartTime := UnixToDateTime(BootTime + (Starttime / ClkTck));
      S := ReadProc('statm');
      if S <> '' then
      begin
        Cols.Clear;
        Cols.Delimiter := ' ';
        Cols.StrictDelimiter := False;
        Cols.DelimitedText := Trim(S);
        if Cols.Count >= 3 then
        begin
          T.MemoryVirtual := SafeStrToInt64Ex(Cols[0], 0) * 4096;
          T.MemoryWorking := SafeStrToInt64Ex(Cols[1], 0) * 4096;
          T.MemoryShared := SafeStrToInt64Ex(Cols[2], 0) * 4096;
        end;
      end;
      Lines.Text := ReadProc('status');
      Uid := -1;
      for I := 0 to Lines.Count - 1 do
        if StartsText('Uid:', Lines[I]) then
        begin
          Cols.Clear;
          Cols.Delimiter := ' ';
          Cols.StrictDelimiter := False;
          Cols.DelimitedText := Trim(ExtractAfterEx(Lines[I], 'Uid:'));
          if Cols.Count > 0 then Uid := SafeStrToInt64Ex(Cols[0], -1);
          Break;
        end;
      if Uid >= 0 then
        T.User := GetUserName(Uid)
      else
        T.User := '';
      if T.User = '' then T.User := IntToStr(Uid);
      T.ExePath := fpReadLink(Base + 'exe');
      S := ReadProc('cmdline');
      T.CommandLine := Trim(StringReplace(S, #0, ' ', [rfReplaceAll]));
      if (T.ExePath = '') and (T.CommandLine = '') then
      begin
        if not FIncludeSystem then
        begin
          T.Free;
          Continue;
        end;
        T.Name := '[' + T.Name + ']';
      end;
      if FOnlyCurrentUser and (Uid <> MeuUid) then
      begin
        T.Free;
        Continue;
      end;
    until FindNext(SR) <> 0;
  finally
    FindClose(SR);
    Lines.Free;
    Cols.Free;
  end;
end;
{$ELSE}
procedure TAITasks.CollectLinux;
begin
end;
{$ENDIF}

{$IFDEF DARWIN}
procedure TAITasks.CollectMac;
var
  Saida, Ln: string;
  Lines, Cols: TStringList;
  I, J: Integer;
  T: TAITask;
begin
  if not RunCmdEx('ps', ['-Ao', 'pid=,ppid=,user=,state=,pri=,nice=,rss=,vsz=,time=,comm='], Saida) then
  begin
    FLastError := 'ps falhou';
    Exit;
  end;
  Lines := TStringList.Create;
  Cols := TStringList.Create;
  try
    Lines.Text := Saida;
    for I := 0 to Lines.Count - 1 do
    begin
      Ln := Trim(Lines[I]);
      if Ln = '' then Continue;
      Cols.Clear;
      Cols.Delimiter := ' ';
      Cols.StrictDelimiter := False;
      Cols.DelimitedText := Ln;
      if Cols.Count < 10 then Continue;
      T := FTasks.Add;
      T.PID := SafeStrToInt64Ex(Cols[0], 0);
      T.PPID := SafeStrToInt64Ex(Cols[1], 0);
      T.User := Cols[2];
      case UpCase(Cols[3][1]) of
        'R': T.State := tsRunning;
        'S', 'I': T.State := tsSleeping;
        'U': T.State := tsDiskSleep;
        'T': T.State := tsStopped;
        'Z': T.State := tsZombie;
      else
        T.State := tsUnknown;
      end;
      T.Priority := SafeStrToInt64Ex(Cols[4], 0);
      T.Nice := SafeStrToInt64Ex(Cols[5], 0);
      T.MemoryWorking := SafeStrToInt64Ex(Cols[6], 0) * 1024;
      T.MemoryVirtual := SafeStrToInt64Ex(Cols[7], 0) * 1024;
      T.CPUTimeMS := 0;
      for J := 9 to Cols.Count - 1 do
        T.Name := Trim(T.Name + ' ' + Cols[J]);
      T.Name := Trim(T.Name);
      T.ExePath := T.Name;
      T.CommandLine := T.ExePath;
      T.StartTicks := 0;
      T.StartTime := 0;
      T.User := Cols[2];
    end;
  finally
    Cols.Free;
    Lines.Free;
  end;
end;
{$ELSE}
procedure TAITasks.CollectMac;
begin
end;
{$ENDIF}

procedure TAITasks.SortTasks;
var
  Arr: array of TAITask;
  I, J: Integer;
  Tmp: TAITask;

  function Better(A, B: TAITask): Boolean;
  begin
    case FSortBy of
      sbPID: Result := A.PID < B.PID;
      sbName: Result := CompareText(A.Name, B.Name) < 0;
      sbCPU: Result := A.CPUPercent < B.CPUPercent;
      sbMemory: Result := A.MemoryWorking < B.MemoryWorking;
      sbThreads: Result := A.Threads < B.Threads;
      sbStartTime: Result := A.StartTime < B.StartTime;
    else
      Result := A.PID < B.PID;
    end;
    if FSortDescending then
      Result := not Result;
  end;

begin
  if FTasks.Count < 2 then Exit;
  SetLength(Arr, FTasks.Count);
  for I := 0 to FTasks.Count - 1 do
    Arr[I] := FTasks[I];
  for I := 1 to High(Arr) do
  begin
    Tmp := Arr[I];
    J := I - 1;
    while (J >= 0) and Better(Tmp, Arr[J]) do
    begin
      Arr[J + 1] := Arr[J];
      Dec(J);
    end;
    Arr[J + 1] := Tmp;
  end;
  for I := 0 to High(Arr) do
    Arr[I].Index := I;
end;

function TAITasks.FindByPID(APID: Int64): TAITask;
var
  I: Integer;
begin
  Result := nil;
  for I := 0 to FTasks.Count - 1 do
    if FTasks[I].PID = APID then Exit(FTasks[I]);
end;

function TAITasks.FindByName(const AName: string): TAITask;
var
  I: Integer;
begin
  Result := nil;
  for I := 0 to FTasks.Count - 1 do
    if SameText(FTasks[I].Name, AName) then Exit(FTasks[I]);
end;

function TAITasks.FindAllByName(const AName: string): TList;
var
  I: Integer;
begin
  Result := TList.Create;
  for I := 0 to FTasks.Count - 1 do
    if SameText(FTasks[I].Name, AName) then
      Result.Add(FTasks[I]);
end;

function TAITasks.IsRunning(const AName: string): Boolean;
begin
  Result := FindByName(AName) <> nil;
end;

function TAITasks.CountByName(const AName: string): Integer;
var
  I: Integer;
begin
  Result := 0;
  for I := 0 to FTasks.Count - 1 do
    if SameText(FTasks[I].Name, AName) then Inc(Result);
end;

function TAITasks.TopByCPU(N: Integer): TList;
var
  I: Integer;
  OldSort: TAITaskSortBy;
  OldDesc: Boolean;
begin
  OldSort := FSortBy;
  OldDesc := FSortDescending;
  FSortBy := sbCPU;
  FSortDescending := True;
  SortTasks;
  Result := TList.Create;
  for I := 0 to Min(N, FTasks.Count) - 1 do
    Result.Add(FTasks[I]);
  FSortBy := OldSort;
  FSortDescending := OldDesc;
  SortTasks;
end;

function TAITasks.TopByMemory(N: Integer): TList;
var
  I: Integer;
  OldSort: TAITaskSortBy;
  OldDesc: Boolean;
begin
  OldSort := FSortBy;
  OldDesc := FSortDescending;
  FSortBy := sbMemory;
  FSortDescending := True;
  SortTasks;
  Result := TList.Create;
  for I := 0 to Min(N, FTasks.Count) - 1 do
    Result.Add(FTasks[I]);
  FSortBy := OldSort;
  FSortDescending := OldDesc;
  SortTasks;
end;

function TAITasks.Kill(APID: Int64; Force: Boolean): Boolean;
{$IFDEF WINDOWS}
var
  H: THandle;
begin
  H := OpenProcess(PROCESS_TERMINATE, False, APID);
  if H = 0 then
  begin
    FLastError := SysErrorMessage(GetLastError);
    Exit(False);
  end;
  try
    Result := TerminateProcess(H, 1);
  finally
    CloseHandle(H);
  end;
end;
{$ELSE}
var
  Sig: Integer;
begin
  if Force then Sig := SIGKILL else Sig := SIGTERM;
  Result := fpKill(APID, Sig) = 0;
  if not Result then
    FLastError := SysErrorMessage(fpGetErrno);
end;
{$ENDIF}

function TAITasks.KillByName(const AName: string; Force: Boolean): Integer;
var
  L: TList;
  I: Integer;
begin
  Result := 0;
  L := FindAllByName(AName);
  try
    for I := 0 to L.Count - 1 do
      if Kill(TAITask(L[I]).PID, Force) then
        Inc(Result);
  finally
    L.Free;
  end;
end;

procedure TAITasks.GetTaskList(Lines: TStrings);
var
  I: Integer;
  T: TAITask;
begin
  Lines.Add(Format('%-7s %-7s %-20s %8s %12s %-12s %s',
    ['PID', 'PPID', 'NOME', 'CPU%', 'MEM', 'ESTADO', 'USUARIO']));
  Lines.Add(StringOfChar('-', 90));
  for I := 0 to FTasks.Count - 1 do
  begin
    T := FTasks[I];
    Lines.Add(Format('%-7d %-7d %-20s %7.1f%% %12s %-12s %s',
      [T.PID, T.PPID, Copy(T.Name, 1, 20), T.CPUPercent,
       FormatBytesEx(T.MemoryWorking), T.StateStr, T.User]));
  end;
end;

procedure TAITasks.GetInfo(Lines: TStrings);
var
  I: Integer;
  L: TList;
  T: TAITask;
begin
  Lines.Add('=== TAREFAS EM EXECUCAO ===');
  Lines.Add(Format('Processos.......: %d', [Count]));
  Lines.Add(Format('Nucleos.........: %d', [FCoreCount]));
  Lines.Add(Format('Memoria total...: %s', [FormatBytesEx(FTotalMemory)]));
  if not FHasPrev then
    Lines.Add('[nota] Primeiro Refresh: CPU% = 0. Chame Refresh de novo.');
  Lines.Add('');
  Lines.Add('--- Top 10 por CPU ---');
  L := TopByCPU(10);
  try
    for I := 0 to L.Count - 1 do
    begin
      T := TAITask(L[I]);
      Lines.Add(Format('  %6.2f%%  %-24s (PID %d, %d threads)',
        [T.CPUPercent, T.Name, T.PID, T.Threads]));
    end;
  finally
    L.Free;
  end;
  Lines.Add('');
  Lines.Add('--- Top 10 por memoria (RSS) ---');
  L := TopByMemory(10);
  try
    for I := 0 to L.Count - 1 do
    begin
      T := TAITask(L[I]);
      Lines.Add(Format('  %10s  %-24s (PID %d)',
        [FormatBytesEx(T.MemoryWorking), T.Name, T.PID]));
    end;
  finally
    L.Free;
  end;
  if FLastError <> '' then
  begin
    Lines.Add('');
    Lines.Add('[aviso] ' + FLastError);
  end;
end;

procedure TAITasks.SaveToCSV(const FileName: string);
var
  L: TStringList;
  I: Integer;
  T: TAITask;

  function Q(const S: string): string;
  begin
    Result := '"' + StringReplace(S, '"', '""', [rfReplaceAll]) + '"';
  end;

begin
  L := TStringList.Create;
  try
    L.Add('PID;PPID;Nome;Usuario;Estado;CPU%;MemoriaRSS;MemoriaVirtual;Threads;Prioridade;Inicio;Caminho');
    for I := 0 to FTasks.Count - 1 do
    begin
      T := FTasks[I];
      L.Add(Format('%d;%d;%s;%s;%s;%.2f;%d;%d;%d;%d;%s;%s',
        [T.PID, T.PPID, Q(T.Name), Q(T.User), Q(T.StateStr), T.CPUPercent,
         T.MemoryWorking, T.MemoryVirtual, T.Threads, T.Priority,
         IfThen(T.StartTime > 0, DateTimeToStr(T.StartTime), ''), Q(T.ExePath)]));
    end;
    L.SaveToFile(FileName);
  finally
    L.Free;
  end;
end;

procedure Register;
begin
  RegisterComponents('AI Hardware', [TAITasks]);
end;

end.
