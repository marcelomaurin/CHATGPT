unit aipythonruntime;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, aibase, aiplatform, airuntimepaths, aiprocessrunner;

type
  { TAIPythonRuntime }

  TAIPythonRuntime = class(TAIBaseComponent)
  private
    FRuntimeRoot: string;
    FPythonPath: string;
    FPythonLibrary: string;
    FWorkerRoot: string;
    FLibraryPath: string;
    FPackagePath: string;
    FPlatformName: string;
    FArchitectureName: string;
    FUseSystemPython: Boolean;
    FLegacyWindows: Boolean;
    FTimeoutMs: Integer;
  public
    constructor Create(AOwner: TComponent); override;
    function DetectRuntime: Boolean;
    function LoadFromIni(const AFileName: string): Boolean;
    function ValidatePython: Boolean;
    function ValidatePackage(const APackageName: string): Boolean;
    function ValidateLibrary(const ALibraryName: string): Boolean;
    function ConfigureEnvironment: Boolean;
    function GetPythonExecutable: string;
    function GetWorkerPath(const AWorkerFile: string): string;
    function GetLibraryFileName(const ABaseName: string): string;
  published
    property RuntimeRoot: string read FRuntimeRoot write FRuntimeRoot;
    property PythonPath: string read FPythonPath write FPythonPath;
    property PythonLibrary: string read FPythonLibrary write FPythonLibrary;
    property WorkerRoot: string read FWorkerRoot write FWorkerRoot;
    property LibraryPath: string read FLibraryPath write FLibraryPath;
    property PackagePath: string read FPackagePath write FPackagePath;
    property PlatformName: string read FPlatformName;
    property ArchitectureName: string read FArchitectureName;
    property UseSystemPython: Boolean read FUseSystemPython write FUseSystemPython default False;
    property LegacyWindows: Boolean read FLegacyWindows write FLegacyWindows default False;
    property TimeoutMs: Integer read FTimeoutMs write FTimeoutMs default 120000;
  end;

procedure Register;

implementation

uses
  {$IFDEF MSWINDOWS}
  Windows
  {$ELSE}
  BaseUnix
  {$ENDIF}
  ;

procedure Register;
begin
  RegisterComponents('AI Core', [TAIPythonRuntime]);
end;

constructor TAIPythonRuntime.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FCategory := ccOther;
  FPrompt := 'Python runtime resolver for Lazarus AI Suite components.';
  FUseSystemPython := False;
  FLegacyWindows := False;
  FTimeoutMs := 120000;
  DetectRuntime;
end;

function TAIPythonRuntime.DetectRuntime: Boolean;
var
  Info: TAIRuntimeInfo;
  IniName: string;
  Err: string;
begin
  ClearError;
  IniName := AIGetRuntimeIniName;

  if FileExists(IniName) then
    Result := AILoadRuntimeInfo(IniName, Info, Err)
  else
  begin
    AIFillDefaultRuntimeInfo(Info);
    Result := True;
  end;

  if not Result then
  begin
    SetError(Err);
    Exit;
  end;

  FRuntimeRoot := Info.RuntimeRoot;
  FPythonPath := Info.PythonPath;
  FPythonLibrary := Info.PythonLibrary;
  FWorkerRoot := Info.WorkerRoot;
  FLibraryPath := Info.LibraryPath;
  FPackagePath := Info.PackagePath;
  FPlatformName := Info.PlatformName;
  FArchitectureName := Info.ArchitectureName;
  FLegacyWindows := Info.LegacyWindows;
end;

function TAIPythonRuntime.LoadFromIni(const AFileName: string): Boolean;
var
  Info: TAIRuntimeInfo;
  Err: string;
begin
  ClearError;
  Result := AILoadRuntimeInfo(AFileName, Info, Err);
  if not Result then
  begin
    SetError(Err);
    Exit;
  end;

  FRuntimeRoot := Info.RuntimeRoot;
  FPythonPath := Info.PythonPath;
  FPythonLibrary := Info.PythonLibrary;
  FWorkerRoot := Info.WorkerRoot;
  FLibraryPath := Info.LibraryPath;
  FPackagePath := Info.PackagePath;
  FPlatformName := Info.PlatformName;
  FArchitectureName := Info.ArchitectureName;
  FLegacyWindows := Info.LegacyWindows;
end;

function TAIPythonRuntime.GetPythonExecutable: string;
begin
  if FUseSystemPython then
  begin
    {$IFDEF MSWINDOWS}
    Result := 'python.exe';
    {$ELSE}
    Result := 'python3';
    {$ENDIF}
  end
  else
    Result := FPythonPath;
end;

function TAIPythonRuntime.GetWorkerPath(const AWorkerFile: string): string;
begin
  if FWorkerRoot <> '' then
    Result := AICombinePath(FWorkerRoot, AWorkerFile)
  else
    Result := AIResolveWorkerPath(FRuntimeRoot, AWorkerFile);
end;

function TAIPythonRuntime.GetLibraryFileName(const ABaseName: string): string;
begin
  Result := AICombinePath(FLibraryPath, AIGetLibraryFileName(ABaseName));
end;

function TAIPythonRuntime.ConfigureEnvironment: Boolean;
var
  OldPath: string;
begin
  ClearError;
  Result := True;
  OldPath := SysUtils.GetEnvironmentVariable('PATH');
  if (FLibraryPath <> '') and DirectoryExists(FLibraryPath) then
  begin
    {$IFDEF MSWINDOWS}
    Result := Windows.SetEnvironmentVariable('PATH', PChar(FLibraryPath + PathSeparator + OldPath));
    {$ELSE}
    Result := fpSetEnv('PATH', FLibraryPath + PathSeparator + OldPath, 1) = 0;
    {$ENDIF}
  end;
end;

function TAIPythonRuntime.ValidatePython: Boolean;
var
  Runner: TAIProcessRunner;
begin
  ClearError;
  Runner := TAIProcessRunner.Create(nil);
  try
    Runner.Executable := GetPythonExecutable;
    Runner.TimeoutMs := FTimeoutMs;
    Result := Runner.Execute(['--version']);
    if not Result then
      SetError('Python validation failed: ' + Runner.LastError);
  finally
    Runner.Free;
  end;
end;

function TAIPythonRuntime.ValidatePackage(const APackageName: string): Boolean;
var
  Runner: TAIProcessRunner;
  Cmd: string;
begin
  ClearError;
  Runner := TAIProcessRunner.Create(nil);
  try
    Runner.Executable := GetPythonExecutable;
    Runner.TimeoutMs := FTimeoutMs;
    Cmd := 'import ' + APackageName;
    Result := Runner.Execute(['-c', Cmd]);
    if not Result then
      SetError('Python package not available: ' + APackageName + '. ' + Runner.LastError);
  finally
    Runner.Free;
  end;
end;

function TAIPythonRuntime.ValidateLibrary(const ALibraryName: string): Boolean;
var
  LibFile: string;
begin
  ClearError;
  LibFile := GetLibraryFileName(ALibraryName);
  Result := FileExists(LibFile);
  if not Result then
    SetError('Library not found: ' + LibFile);
end;

end.
