unit airuntimepaths;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, IniFiles, aiplatform;

type
  TAIRuntimeInfo = record
    RuntimeRoot: string;
    PythonPath: string;
    PythonLibrary: string;
    WorkerRoot: string;
    LibraryPath: string;
    PackagePath: string;
    PlatformName: string;
    ArchitectureName: string;
    LegacyWindows: Boolean;
  end;

function AIGetRuntimeFolderName: string;
function AIGetDefaultRuntimeRoot: string;
function AIGetRuntimeIniName: string;
function AIResolveWorkerPath(const ARuntimeRoot, AWorkerFile: string): string;
function AIResolvePythonExecutable(const ARuntimeRoot: string): string;
function AIResolvePythonLibrary(const ARuntimeRoot: string): string;
function AIResolveOpenSSLDirectory(const ABaseDir: string = ''): string;
function AIResolveOpenSSLLibraries(const ABaseDir: string; out ASSLLib, ACryptoLib: string): Boolean;
function AILoadRuntimeInfo(const AIniFile: string; out AInfo: TAIRuntimeInfo; out AError: string): Boolean;
procedure AIFillDefaultRuntimeInfo(out AInfo: TAIRuntimeInfo);

implementation

function AIGetRuntimeFolderName: string;
begin
  Result := AIOSName + '-' + AIArchitectureName;
end;

function AIGetDefaultRuntimeRoot: string;
var
  AppDir: string;
begin
  AppDir := IncludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0)));
  Result := AICombinePath(AppDir, 'runtime' + DirectorySeparator + AIGetRuntimeFolderName);
end;

function AIGetRuntimeIniName: string;
begin
  Result := AICombinePath(ExtractFilePath(ParamStr(0)), 'chatgpt_ai_runtime.ini');
end;

function AIResolveWorkerPath(const ARuntimeRoot, AWorkerFile: string): string;
begin
  Result := AICombinePath(AICombinePath(ARuntimeRoot, 'python'), AWorkerFile);
  if not FileExists(Result) then
    Result := AICombinePath(AICombinePath(ARuntimeRoot, 'workers'), AWorkerFile);
end;

function AIResolvePythonExecutable(const ARuntimeRoot: string): string;
var
  Candidate: string;
begin
  {$IFDEF MSWINDOWS}
  Candidate := AICombinePath(AICombinePath(ARuntimeRoot, 'python'), 'python.exe');
  {$ELSE}
  Candidate := AICombinePath(AICombinePath(AICombinePath(ARuntimeRoot, 'python'), 'bin'), 'python3');
  {$ENDIF}

  if FileExists(Candidate) then
    Result := Candidate
  else
  begin
    {$IFDEF MSWINDOWS}
    Result := 'python.exe';
    {$ELSE}
    Result := 'python3';
    {$ENDIF}
  end;
end;

function AIResolvePythonLibrary(const ARuntimeRoot: string): string;
begin
  {$IFDEF MSWINDOWS}
  Result := AICombinePath(AICombinePath(ARuntimeRoot, 'python'), 'python38.dll');
  if not FileExists(Result) then
    Result := AICombinePath(AICombinePath(ARuntimeRoot, 'python'), 'python311.dll');
  {$ELSE}
  Result := AICombinePath(AICombinePath(AICombinePath(ARuntimeRoot, 'python'), 'lib'), 'libpython3.11.so');
  if not FileExists(Result) then
    Result := AICombinePath(AICombinePath(AICombinePath(ARuntimeRoot, 'python'), 'lib'), 'libpython3.8.so');
  {$ENDIF}
end;

function AIResolveOpenSSLDirectory(const ABaseDir: string): string;
var
  SearchRoots: array[0..3] of string;
  ArchFolder: string;
  I: Integer;
  Candidate: string;
begin
  Result := '';
  {$IFDEF MSWINDOWS}
    {$IFDEF WIN64}
    ArchFolder := 'x64';
    {$ELSE}
    ArchFolder := 'X86';
    {$ENDIF}
  {$ELSE}
  ArchFolder := '';
  {$ENDIF}

  SearchRoots[0] := ABaseDir;
  SearchRoots[1] := ExtractFilePath(ParamStr(0));
  SearchRoots[2] := ExpandFileName(ExtractFilePath(ParamStr(0)) + '..' + DirectorySeparator);
  SearchRoots[3] := ExpandFileName(ExtractFilePath(ParamStr(0)) + '..' + DirectorySeparator + '..' + DirectorySeparator);

  for I := 0 to High(SearchRoots) do
  begin
    if SearchRoots[I] = '' then Continue;
    // Check runtime/OpenSSL/1.1.1.10/
    Candidate := AICombinePath(SearchRoots[I], 'runtime' + DirectorySeparator + 'OpenSSL' + DirectorySeparator + '1.1.1.10' + DirectorySeparator + ArchFolder);
    if DirectoryExists(Candidate) then
      Exit(Candidate);
    Candidate := AICombinePath(SearchRoots[I], 'OpenSSL' + DirectorySeparator + '1.1.1.10' + DirectorySeparator + ArchFolder);
    if DirectoryExists(Candidate) then
      Exit(Candidate);
  end;
end;

function AIResolveOpenSSLLibraries(const ABaseDir: string; out ASSLLib, ACryptoLib: string): Boolean;
var
  SSLDir: string;
begin
  Result := False;
  ASSLLib := '';
  ACryptoLib := '';
  SSLDir := AIResolveOpenSSLDirectory(ABaseDir);

  {$IFDEF MSWINDOWS}
    {$IFDEF WIN64}
    if SSLDir <> '' then
    begin
      ASSLLib := AICombinePath(SSLDir, 'libssl-1_1-x64.dll');
      ACryptoLib := AICombinePath(SSLDir, 'libcrypto-1_1-x64.dll');
    end
    else
    begin
      ASSLLib := 'libssl-1_1-x64.dll';
      ACryptoLib := 'libcrypto-1_1-x64.dll';
    end;
    {$ELSE}
    if SSLDir <> '' then
    begin
      ASSLLib := AICombinePath(SSLDir, 'libssl-1_1.dll');
      ACryptoLib := AICombinePath(SSLDir, 'libcrypto-1_1.dll');
    end
    else
    begin
      ASSLLib := 'libssl-1_1.dll';
      ACryptoLib := 'libcrypto-1_1.dll';
    end;
    {$ENDIF}
    Result := FileExists(ASSLLib) and FileExists(ACryptoLib);
  {$ELSE}
  ASSLLib := 'libssl.so.1.1';
  ACryptoLib := 'libcrypto.so.1.1';
  Result := True;
  {$ENDIF}
end;

procedure AIFillDefaultRuntimeInfo(out AInfo: TAIRuntimeInfo);
begin
  FillChar(AInfo, SizeOf(AInfo), 0);
  AInfo.RuntimeRoot := AIGetDefaultRuntimeRoot;
  AInfo.PlatformName := AIOSName;
  AInfo.ArchitectureName := AIArchitectureName;
  AInfo.PythonPath := AIResolvePythonExecutable(AInfo.RuntimeRoot);
  AInfo.PythonLibrary := AIResolvePythonLibrary(AInfo.RuntimeRoot);
  AInfo.WorkerRoot := AICombinePath(AInfo.RuntimeRoot, 'workers');
  AInfo.LibraryPath := AICombinePath(AInfo.RuntimeRoot, 'lib');
  {$IFDEF MSWINDOWS}
  AInfo.LibraryPath := AICombinePath(AInfo.RuntimeRoot, 'dll');
  {$ENDIF}
  AInfo.PackagePath := AICombinePath(AInfo.RuntimeRoot, 'packages');
  AInfo.LegacyWindows := False;
end;

function AILoadRuntimeInfo(const AIniFile: string; out AInfo: TAIRuntimeInfo; out AError: string): Boolean;
var
  Ini: TIniFile;
begin
  Result := False;
  AError := '';
  AIFillDefaultRuntimeInfo(AInfo);

  if not FileExists(AIniFile) then
  begin
    AError := 'Runtime INI not found: ' + AIniFile;
    Exit;
  end;

  Ini := TIniFile.Create(AIniFile);
  try
    AInfo.PlatformName := Ini.ReadString('Runtime', 'Platform', AInfo.PlatformName);
    AInfo.ArchitectureName := Ini.ReadString('Runtime', 'Architecture', AInfo.ArchitectureName);
    AInfo.RuntimeRoot := Ini.ReadString('Runtime', 'InstallPath', AInfo.RuntimeRoot);
    AInfo.PythonPath := Ini.ReadString('Runtime', 'PythonPath', AInfo.PythonPath);
    AInfo.PythonLibrary := Ini.ReadString('Runtime', 'PythonLibrary', AInfo.PythonLibrary);
    AInfo.WorkerRoot := Ini.ReadString('Runtime', 'WorkerRoot', AInfo.WorkerRoot);
    AInfo.LibraryPath := Ini.ReadString('Runtime', 'LibraryPath', AInfo.LibraryPath);
    AInfo.PackagePath := Ini.ReadString('Runtime', 'PackagePath', AInfo.PackagePath);
    AInfo.LegacyWindows := Ini.ReadBool('Runtime', 'LegacyWindows', False);
    Result := True;
  finally
    Ini.Free;
  end;
end;

end.
