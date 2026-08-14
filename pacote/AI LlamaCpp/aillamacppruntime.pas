unit aillamacppruntime;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, IniFiles,
  aibase,
  airuntimepaths,
  aiplatform,
  aillamacpptypes,
  aiprocessrunner, LResources;

type
  TAILlamaLogEvent = TAILogEvent;

  TAILlamaCppRuntime = class(TAIBaseComponent)
  private
    FRuntimeRoot: string;
    FBinPath: string;
    FLibraryPath: string;
    FLastRuntimeError: string;
  public
    constructor Create(AOwner: TComponent); override;
    function GetDefaultBinPath: string;
    function GetDefaultLibraryPath: string;
    function GetCliPath: string;
    function GetServerPath: string;
    function GetQuantizePath: string;
    function IsCliAvailable: Boolean;
    function IsServerAvailable: Boolean;
    function ValidateLibraries: Boolean;
    function ValidateRuntime: Boolean;
    function GetVersion: string;
    function LoadVersionInfo(out AInfo: TAILlamaVersionInfo): Boolean;
  published
    property RuntimeRoot: string read FRuntimeRoot write FRuntimeRoot;
    property BinPath: string read FBinPath write FBinPath;
    property LibraryPath: string read FLibraryPath write FLibraryPath;
    property LastRuntimeError: string read FLastRuntimeError;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('AI LlamaCpp', [TAILlamaCppRuntime]);
end;

constructor TAILlamaCppRuntime.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FRuntimeRoot := AIGetDefaultRuntimeRoot;
  FBinPath := GetDefaultBinPath;
  FLibraryPath := GetDefaultLibraryPath;
end;

function TAILlamaCppRuntime.GetDefaultBinPath: string;
begin
  Result := AICombinePath(FRuntimeRoot, 'bin');
end;

function TAILlamaCppRuntime.GetDefaultLibraryPath: string;
begin
  Result := AICombinePath(FRuntimeRoot, 'dll');
end;

function TAILlamaCppRuntime.GetCliPath: string;
begin
  Result := AICombinePath(FBinPath, AI_LLAMA_CLI_FILENAME);
end;

function TAILlamaCppRuntime.GetServerPath: string;
begin
  Result := AICombinePath(FBinPath, AI_LLAMA_SERVER_FILENAME);
end;

function TAILlamaCppRuntime.GetQuantizePath: string;
begin
  Result := AICombinePath(FBinPath, AI_LLAMA_QUANTIZE_FILENAME);
end;

function TAILlamaCppRuntime.IsCliAvailable: Boolean;
begin
  Result := FileExists(GetCliPath);
end;

function TAILlamaCppRuntime.IsServerAvailable: Boolean;
begin
  Result := FileExists(GetServerPath);
end;

function TAILlamaCppRuntime.ValidateLibraries: Boolean;
const
  REQUIRED_LIBRARIES: array[0..3] of string = (
    AI_LLAMA_LIBRARY_FILENAME,
    AI_GGML_LIBRARY_FILENAME,
    AI_GGML_BASE_LIBRARY_FILENAME,
    AI_GGML_CPU_LIBRARY_FILENAME
  );
var
  I: Integer;
  LFileName: string;
begin
  FLastRuntimeError := '';
  for I := Low(REQUIRED_LIBRARIES) to High(REQUIRED_LIBRARIES) do
  begin
    LFileName := AICombinePath(FLibraryPath, REQUIRED_LIBRARIES[I]);
    if not FileExists(LFileName) then
    begin
      FLastRuntimeError := 'Missing runtime DLL: ' + LFileName;
      Log(llError, FLastRuntimeError);
      Exit(False);
    end;
  end;
  Result := True;
end;

function TAILlamaCppRuntime.ValidateRuntime: Boolean;
begin
  FLastRuntimeError := '';
  Log(llInfo, 'Validating llama.cpp runtime.');

  if not DirectoryExists(FRuntimeRoot) then
  begin
    FLastRuntimeError := 'Runtime directory not found: ' + FRuntimeRoot;
    Log(llError, FLastRuntimeError);
    Exit(False);
  end;
  if not DirectoryExists(FBinPath) then
  begin
    FLastRuntimeError := 'Runtime bin directory not found: ' + FBinPath;
    Log(llError, FLastRuntimeError);
    Exit(False);
  end;
  if not DirectoryExists(FLibraryPath) then
  begin
    FLastRuntimeError := 'Runtime DLL directory not found: ' + FLibraryPath;
    Log(llError, FLastRuntimeError);
    Exit(False);
  end;

  if not IsCliAvailable then
  begin
    FLastRuntimeError := 'Runtime executable not found: ' + GetCliPath;
    Log(llError, FLastRuntimeError);
    Exit(False);
  end;
  if not IsServerAvailable then
  begin
    FLastRuntimeError := 'Runtime executable not found: ' + GetServerPath;
    Log(llError, FLastRuntimeError);
    Exit(False);
  end;

  Result := ValidateLibraries;
  if Result then
    Log(llInfo, 'llama.cpp runtime validation succeeded.');
end;

function TAILlamaCppRuntime.GetVersion: string;
var
  LRunner: TAIProcessRunner;
begin
  Result := '';
  LRunner := TAIProcessRunner.Create(nil);
  try
    LRunner.Executable := GetCliPath;
    LRunner.WorkingDirectory := FLibraryPath;
    if LRunner.Execute(['--version']) then
    begin
      Result := Trim(LRunner.StdOutText);
      if Result = '' then
        Result := Trim(LRunner.StdErrText);
      FLastRuntimeError := '';
    end
    else
    begin
      FLastRuntimeError := Trim(LRunner.StdErrText);
      if FLastRuntimeError = '' then
        FLastRuntimeError := LRunner.LastError;
      Log(llError, FLastRuntimeError);
    end;
  finally
    LRunner.Free;
  end;
end;

function TAILlamaCppRuntime.LoadVersionInfo(
  out AInfo: TAILlamaVersionInfo): Boolean;
var
  LFileName: string;
  LIni: TIniFile;
begin
  AInfo.Version := '';
  AInfo.Build := '';
  AInfo.Commit := '';
  AInfo.Architecture := '';
  AInfo.Backend := '';

  LFileName := AICombinePath(FRuntimeRoot, 'llamacpp.version');
  if not FileExists(LFileName) then
  begin
    FLastRuntimeError := 'Runtime version file not found: ' + LFileName;
    Log(llError, FLastRuntimeError);
    Exit(False);
  end;

  LIni := TIniFile.Create(LFileName);
  try
    AInfo.Version := LIni.ReadString('LlamaCpp', 'Version', '');
    AInfo.Build := LIni.ReadString('LlamaCpp', 'Build', '');
    AInfo.Commit := LIni.ReadString('LlamaCpp', 'Commit', '');
    AInfo.Architecture := LIni.ReadString('LlamaCpp', 'Architecture', '');
    AInfo.Backend := LIni.ReadString('LlamaCpp', 'Backend', '');
    Result := True;
  finally
    LIni.Free;
  end;
end;

initialization
  {$I aillamacppruntime_icon.lrs}

end.
