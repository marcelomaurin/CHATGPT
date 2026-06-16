unit pythonconnector;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, DynLibs, Process, pipes, LResources;

type
  { Functions signature in Python C API }
  TPy_Initialize = procedure; cdecl;
  TPy_Finalize = procedure; cdecl;
  TPy_IsInitialized = function: Integer; cdecl;
  TPyRun_SimpleString = function(str: PAnsiChar): Integer; cdecl;
  TPy_GetVersion = function: PAnsiChar; cdecl;
  TPyImport_AddModule = function(name: PAnsiChar): Pointer; cdecl;
  TPyModule_GetDict = function(module: Pointer): Pointer; cdecl;
  TPyDict_GetItemString = function(dict: Pointer; key: PAnsiChar): Pointer; cdecl;
  TPyObject_Str = function(obj: Pointer): Pointer; cdecl;
  TPyUnicode_AsUTF8 = function(obj: Pointer): PAnsiChar; cdecl;
  TPy_DecRef = procedure(obj: Pointer); cdecl;
  TPy_IncRef = procedure(obj: Pointer); cdecl;

  { Fallback & modern signatures }
  TPyRun_SimpleStringFlags = function(str: PAnsiChar; flags: Pointer): Integer; cdecl;
  TPy_FinalizeEx = function: Integer; cdecl;

  TPythonPlatform = (
    ppUnknown,
    ppWindows32,
    ppWindows64,
    ppLinux32,
    ppLinux64,
    ppLinuxARM,
    ppLinuxARM64,
    ppDarwin64
  );

  TPythonLoadMode = (
    plmAuto,
    plmManualPath,
    plmSystemPath,
    plmApplicationFolder,
    plmEmbeddedFolder
  );

  TPythonExecutionMode = (
    pemDLL,
    pemProcess
  );

  { TPythonConnector }

  TPythonConnector = class(TComponent)
  private
    FDLLPath      : string;
    FActive       : Boolean;
    FLibHandle    : TLibHandle;
    FInitialized  : Boolean;
    FLastError    : string;

    // Loaded function pointers
    Py_Initialize: TPy_Initialize;
    Py_Finalize: TPy_Finalize;
    Py_IsInitialized: TPy_IsInitialized;
    PyRun_SimpleString: TPyRun_SimpleString;
    Py_GetVersion: TPy_GetVersion;
    PyImport_AddModule: TPyImport_AddModule;
    PyModule_GetDict: TPyModule_GetDict;
    PyDict_GetItemString: TPyDict_GetItemString;
    PyObject_Str: TPyObject_Str;
    PyUnicode_AsUTF8: TPyUnicode_AsUTF8;
    Py_DecRef: TPy_DecRef;
    Py_IncRef: TPy_IncRef;

    // Fallbacks
    PyRun_SimpleStringFlags: TPyRun_SimpleStringFlags;
    Py_FinalizeEx: TPy_FinalizeEx;

    // Diagnostic fields
    FLoadedDLLPath      : string;
    FDiagnosticLog      : TStrings;
    FPythonVersionText  : string;
    FPythonMajor        : Integer;
    FPythonMinor        : Integer;
    FPythonPatch        : Integer;
    FRequiredMethodsOK  : Boolean;
    FOptionalMethodsOK  : Boolean;
    FLastLoadStep       : string;
    FLoadMode           : TPythonLoadMode;
    FExecutionMode      : TPythonExecutionMode;
    FLazarusArchitecture: string;
    FPythonArchitecture : string;
    FArchitectureCompatible: Boolean;
    FMinPythonMajor     : Integer;
    FMinPythonMinor     : Integer;
    FMaxPythonMajor     : Integer;
    FMaxPythonMinor     : Integer;
    FCompiledPlatform   : TPythonPlatform;

    // Process mode fields
    FProcess            : TProcess;
    FLastValue          : string;
    FTempFileName       : string;
    FLastOutput         : string;

    procedure SetActive(const AValue: Boolean);

    function DiagnosePythonDLL: Boolean;
    function ResolveFunctions: Boolean;
    function ValidateVersionConstraints: Boolean;
    procedure ParseVersionNumbers(const AVersionStr: string);

    function StartPythonProcess: Boolean;
    procedure StopPythonProcess;
    function ReadLineFromProcess(out ALine: string; AMaxWaitMS: Integer = 120000): Boolean;
    function FindPythonExecutable: string;

    procedure UnloadPythonDLL;
    function GetVersion: string;
    function DetectCompiledPlatform: TPythonPlatform;
    procedure BuildPythonCandidates(AList: TStrings);

  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    function StartPython: Boolean;
    function SelfTest: Boolean;
    procedure GetDiagnosticReport(AReport: TStrings);

    procedure StopExecution;

    function ExecString(const AScript: string): Boolean;
    function GetVar(const AVarName: string): string;
    procedure SetVar(const AVarName, AValue: string);
    function Eval(const AExpression: string): string;

    property IsInitialized: Boolean read FInitialized;
    property LastError: string read FLastError;
    property LastOutput: string read FLastOutput;

    // Read-only diagnostic properties
    property LoadedDLLPath: string read FLoadedDLLPath;
    property DiagnosticLog: TStrings read FDiagnosticLog;
    property PythonVersionText: string read FPythonVersionText;
    property PythonMajor: Integer read FPythonMajor;
    property PythonMinor: Integer read FPythonMinor;
    property PythonPatch: Integer read FPythonPatch;
    property RequiredMethodsOK: Boolean read FRequiredMethodsOK;
    property OptionalMethodsOK: Boolean read FOptionalMethodsOK;
    property LastLoadStep: string read FLastLoadStep;
    property LazarusArchitecture: string read FLazarusArchitecture;
    property PythonArchitecture: string read FPythonArchitecture;
    property ArchitectureCompatible: Boolean read FArchitectureCompatible;

  published
    property DLLPath: string read FDLLPath write FDLLPath;
    property Active: Boolean read FActive write SetActive;
    property Version: string read GetVersion;
    property LoadMode: TPythonLoadMode read FLoadMode write FLoadMode default plmAuto;
    property ExecutionMode: TPythonExecutionMode read FExecutionMode write FExecutionMode default pemDLL;
    property MinPythonMajor: Integer read FMinPythonMajor write FMinPythonMajor default 3;
    property MinPythonMinor: Integer read FMinPythonMinor write FMinPythonMinor default 8;
    property MaxPythonMajor: Integer read FMaxPythonMajor write FMaxPythonMajor default 3;
    property MaxPythonMinor: Integer read FMaxPythonMinor write FMaxPythonMinor default 14;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('AI Machine Learning', [TPythonConnector]);
end;

{ TPythonConnector }

constructor TPythonConnector.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);

  FDLLPath := 'python3.dll';
  FActive := False;
  FLibHandle := NilHandle;
  FInitialized := False;
  FLastError := '';

  FDiagnosticLog := TStringList.Create;
  FLoadMode := plmAuto;
  FExecutionMode := pemDLL;

  FMinPythonMajor := 3;
  FMinPythonMinor := 8;
  FMaxPythonMajor := 3;
  FMaxPythonMinor := 14;

  FProcess := nil;
  FLastValue := '';
  FTempFileName := '';
  FLastOutput := '';

  FPythonVersionText := '';
  FPythonMajor := 0;
  FPythonMinor := 0;
  FPythonPatch := 0;

  FRequiredMethodsOK := False;
  FOptionalMethodsOK := False;
  FLastLoadStep := '';

  {$IFDEF CPU64}
  FLazarusArchitecture := 'x86_64';
  {$ELSE}
  FLazarusArchitecture := 'i386';
  {$ENDIF}

  FPythonArchitecture := '';
  FArchitectureCompatible := False;
  FCompiledPlatform := DetectCompiledPlatform;
end;

destructor TPythonConnector.Destroy;
begin
  if FActive then
    SetActive(False);

  FDiagnosticLog.Free;

  inherited Destroy;
end;

function TPythonConnector.DetectCompiledPlatform: TPythonPlatform;
begin
  Result := ppUnknown;

  {$IFDEF MSWINDOWS}
    {$IFDEF CPU64}
      Result := ppWindows64;
    {$ELSE}
      Result := ppWindows32;
    {$ENDIF}
  {$ENDIF}

  {$IFDEF LINUX}
    {$IFDEF CPUAARCH64}
      Result := ppLinuxARM64;
    {$ELSE}
      {$IFDEF CPUARM}
        Result := ppLinuxARM;
      {$ELSE}
        {$IFDEF CPU64}
          Result := ppLinux64;
        {$ELSE}
          Result := ppLinux32;
        {$ENDIF}
      {$ENDIF}
    {$ENDIF}
  {$ENDIF}

  {$IFDEF DARWIN}
    {$IFDEF CPU64}
      Result := ppDarwin64;
    {$ELSE}
      Result := ppUnknown;
    {$ENDIF}
  {$ENDIF}
end;

procedure TPythonConnector.BuildPythonCandidates(AList: TStrings);
var
  AppDir: string;
  I: Integer;
  VerStr: string;
begin
  AList.Clear;
  AppDir := IncludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0)));

  if Trim(FDLLPath) <> '' then
    AList.Add(FDLLPath);

  case FCompiledPlatform of
    ppWindows64:
    begin
      for I := 14 downto 8 do
      begin
        VerStr := IntToStr(I);
        AList.Add(AppDir + 'libs\windows\x86_64\python3' + VerStr + '.dll');
        AList.Add(AppDir + 'python64\python3' + VerStr + '.dll');
        AList.Add(AppDir + 'python3' + VerStr + '.dll');
        AList.Add('python3' + VerStr + '.dll');
      end;

      AList.Add(AppDir + 'libs\windows\x86_64\python3.dll');
      AList.Add('python3.dll');
    end;

    ppWindows32:
    begin
      for I := 14 downto 8 do
      begin
        VerStr := IntToStr(I);
        AList.Add(AppDir + 'libs\windows\x86\python3' + VerStr + '.dll');
        AList.Add(AppDir + 'python32\python3' + VerStr + '.dll');
        AList.Add(AppDir + 'python3' + VerStr + '.dll');
        AList.Add('python3' + VerStr + '.dll');
      end;

      AList.Add(AppDir + 'libs\windows\x86\python3.dll');
      AList.Add('python3.dll');
    end;

    ppLinux64:
    begin
      for I := 14 downto 8 do
      begin
        VerStr := IntToStr(I);
        AList.Add(AppDir + 'libs/linux/x86_64/libpython3.' + VerStr + '.so');
        AList.Add(AppDir + 'python64/libpython3.' + VerStr + '.so');
        AList.Add(AppDir + 'lib/x86_64-linux/libpython3.' + VerStr + '.so');
        AList.Add('/usr/lib/x86_64-linux-gnu/libpython3.' + VerStr + '.so');
        AList.Add('/usr/local/lib/libpython3.' + VerStr + '.so');
      end;

      AList.Add(AppDir + 'libs/linux/x86_64/libpython3.so');
      AList.Add('libpython3.so');
    end;

    ppLinux32:
    begin
      for I := 12 downto 8 do
      begin
        VerStr := IntToStr(I);
        AList.Add(AppDir + 'libs/linux/x86/libpython3.' + VerStr + '.so');
        AList.Add(AppDir + 'python32/libpython3.' + VerStr + '.so');
        AList.Add(AppDir + 'lib/i386-linux/libpython3.' + VerStr + '.so');
        AList.Add('/usr/lib/i386-linux-gnu/libpython3.' + VerStr + '.so');
        AList.Add('/usr/local/lib/libpython3.' + VerStr + '.so');
      end;

      AList.Add(AppDir + 'libs/linux/x86/libpython3.so');
      AList.Add('libpython3.so');
    end;

    ppLinuxARM64:
    begin
      for I := 14 downto 8 do
      begin
        VerStr := IntToStr(I);
        AList.Add(AppDir + 'libs/linux/arm64/libpython3.' + VerStr + '.so');
        AList.Add(AppDir + 'libs/linux/arm/libpython3.' + VerStr + '.so');
        AList.Add('/usr/lib/aarch64-linux-gnu/libpython3.' + VerStr + '.so');
        AList.Add('/usr/lib/libpython3.' + VerStr + '.so');
        AList.Add('/usr/local/lib/libpython3.' + VerStr + '.so');
      end;

      AList.Add(AppDir + 'libs/linux/arm64/libpython3.so');
      AList.Add(AppDir + 'libs/linux/arm/libpython3.so');
      AList.Add('libpython3.so');
    end;

    ppLinuxARM:
    begin
      for I := 14 downto 8 do
      begin
        VerStr := IntToStr(I);
        AList.Add(AppDir + 'libs/linux/arm/libpython3.' + VerStr + '.so');
        AList.Add('/usr/lib/arm-linux-gnueabihf/libpython3.' + VerStr + '.so');
        AList.Add('/usr/lib/libpython3.' + VerStr + '.so');
        AList.Add('/usr/local/lib/libpython3.' + VerStr + '.so');
      end;

      AList.Add(AppDir + 'libs/linux/arm/libpython3.so');
      AList.Add('libpython3.so');
    end;

    ppDarwin64:
    begin
      for I := 14 downto 8 do
      begin
        VerStr := IntToStr(I);
        AList.Add(AppDir + 'libs/mac/x86_64/libpython3.' + VerStr + '.dylib');
        AList.Add(AppDir + 'libs/mac/arm/libpython3.' + VerStr + '.dylib');
        AList.Add(AppDir + 'python64/libpython3.' + VerStr + '.dylib');
        AList.Add('/usr/local/lib/libpython3.' + VerStr + '.dylib');
        AList.Add('/opt/homebrew/lib/libpython3.' + VerStr + '.dylib');
      end;

      AList.Add(AppDir + 'libs/mac/x86_64/libpython3.dylib');
      AList.Add(AppDir + 'libs/mac/arm/libpython3.dylib');
      AList.Add('libpython3.dylib');
    end;

  else
    FLastError := 'Plataforma compilada não reconhecida.';
  end;
end;

function TPythonConnector.DiagnosePythonDLL: Boolean;
var
  Candidates: TStringList;
  I: Integer;
begin
  Result := False;
  FLastLoadStep := 'Iniciando diagnóstico da DLL';
  FDiagnosticLog.Clear;
  FDiagnosticLog.Add('Diagnóstico da DLL iniciado.');
  FDiagnosticLog.Add('Arquitetura do Lazarus: ' + FLazarusArchitecture);

  case FCompiledPlatform of
    ppWindows64:
    begin
      FDiagnosticLog.Add('Componente compilado para: Windows 64 bits');
      FDiagnosticLog.Add('Serão procuradas apenas DLLs Windows 64 bits.');
    end;

    ppWindows32:
    begin
      FDiagnosticLog.Add('Componente compilado para: Windows 32 bits');
      FDiagnosticLog.Add('Serão procuradas apenas DLLs Windows 32 bits.');
    end;

    ppLinux64:
    begin
      FDiagnosticLog.Add('Componente compilado para: Linux 64 bits');
      FDiagnosticLog.Add('Serão procuradas apenas bibliotecas Linux 64 bits.');
    end;

    ppLinux32:
    begin
      FDiagnosticLog.Add('Componente compilado para: Linux 32 bits');
      FDiagnosticLog.Add('Serão procuradas apenas bibliotecas Linux 32 bits.');
    end;

    ppLinuxARM64:
    begin
      FDiagnosticLog.Add('Componente compilado para: Linux ARM 64 bits');
      FDiagnosticLog.Add('Serão procuradas apenas bibliotecas Linux ARM 64 bits.');
    end;

    ppLinuxARM:
    begin
      FDiagnosticLog.Add('Componente compilado para: Linux ARM 32 bits');
      FDiagnosticLog.Add('Serão procuradas apenas bibliotecas Linux ARM 32 bits.');
    end;

    ppDarwin64:
    begin
      FDiagnosticLog.Add('Componente compilado para: macOS 64 bits');
      FDiagnosticLog.Add('Serão procuradas apenas dylibs macOS 64 bits.');
    end;

  else
    FDiagnosticLog.Add('Componente compilado para: Plataforma desconhecida');
  end;

  if FLibHandle <> NilHandle then
  begin
    FDiagnosticLog.Add('DLL/SO já carregada anteriormente.');
    Exit(True);
  end;

  Candidates := TStringList.Create;
  try
    if FLoadMode = plmManualPath then
    begin
      if Trim(FDLLPath) <> '' then
        Candidates.Add(Trim(FDLLPath));
    end
    else
      BuildPythonCandidates(Candidates);

    for I := Candidates.Count - 1 downto 0 do
    begin
      if (Candidates[I] = '') or (Candidates.IndexOf(Candidates[I]) < I) then
        Candidates.Delete(I);
    end;

    FDiagnosticLog.Add('Candidatos:');
    for I := 0 to Candidates.Count - 1 do
      FDiagnosticLog.Add(Format('  [%d] %s', [I + 1, Candidates[I]]));

    FLastLoadStep := 'Tentando carregar bibliotecas';

    for I := 0 to Candidates.Count - 1 do
    begin
      FDiagnosticLog.Add('Tentando carregar: ' + Candidates[I]);

      FLibHandle := SafeLoadLibrary(Candidates[I]);

      if FLibHandle <> NilHandle then
      begin
        FLoadedDLLPath := Candidates[I];
        FDiagnosticLog.Add('Sucesso ao carregar biblioteca: ' + FLoadedDLLPath);
        Result := True;
        Break;
      end;
    end;

    if not Result then
    begin
      case FCompiledPlatform of
        ppWindows64:
          FLastError := 'Falha ao carregar python3.dll.' + sLineBreak +
                        'A aplicação foi compilada para Windows 64 bits.' + sLineBreak +
                        'Instale o Python 64 bits compatível.';

        ppWindows32:
          FLastError := 'Falha ao carregar python3.dll.' + sLineBreak +
                        'A aplicação foi compilada para Windows 32 bits.' + sLineBreak +
                        'Instale o Python 32 bits compatível.';

        ppLinux64:
          FLastError := 'Falha ao carregar libpython.' + sLineBreak +
                        'A aplicação foi compilada para Linux 64 bits.' + sLineBreak +
                        'Instale a biblioteca Python compatível, por exemplo:' + sLineBreak +
                        'sudo apt install libpython3.12-dev';

        ppLinux32:
          FLastError := 'Falha ao carregar libpython.' + sLineBreak +
                        'A aplicação foi compilada para Linux 32 bits.' + sLineBreak +
                        'Instale uma libpython 32 bits compatível com esta aplicação.';

        ppLinuxARM64:
          FLastError := 'Falha ao carregar libpython.' + sLineBreak +
                        'A aplicação foi compilada para Linux ARM 64 bits.' + sLineBreak +
                        'Instale a biblioteca Python compatível para aarch64.';

        ppLinuxARM:
          FLastError := 'Falha ao carregar libpython.' + sLineBreak +
                        'A aplicação foi compilada para Linux ARM 32 bits.' + sLineBreak +
                        'Instale uma libpython ARM 32 bits compatível.';

        ppDarwin64:
          FLastError := 'Falha ao carregar libpython.dylib.' + sLineBreak +
                        'A aplicação foi compilada para macOS 64 bits.' + sLineBreak +
                        'Instale o Python compatível.';

      else
        FLastError := 'Nenhum candidato de DLL/SO/Dylib carregou com sucesso.';
      end;

      FDiagnosticLog.Add('Erro: ' + FLastError);
      FLastLoadStep := 'Falha ao carregar DLL/SO';
      Exit;
    end;

  finally
    Candidates.Free;
  end;
end;

function TPythonConnector.ResolveFunctions: Boolean;
begin
  Result := False;
  FLastLoadStep := 'Resolvendo funções da DLL/SO';

  Py_Initialize := TPy_Initialize(GetProcedureAddress(FLibHandle, 'Py_Initialize'));
  Py_Finalize := TPy_Finalize(GetProcedureAddress(FLibHandle, 'Py_Finalize'));
  Py_IsInitialized := TPy_IsInitialized(GetProcedureAddress(FLibHandle, 'Py_IsInitialized'));
  PyRun_SimpleString := TPyRun_SimpleString(GetProcedureAddress(FLibHandle, 'PyRun_SimpleString'));
  Py_GetVersion := TPy_GetVersion(GetProcedureAddress(FLibHandle, 'Py_GetVersion'));

  PyRun_SimpleStringFlags := TPyRun_SimpleStringFlags(GetProcedureAddress(FLibHandle, 'PyRun_SimpleStringFlags'));
  Py_FinalizeEx := TPy_FinalizeEx(GetProcedureAddress(FLibHandle, 'Py_FinalizeEx'));

  PyImport_AddModule := TPyImport_AddModule(GetProcedureAddress(FLibHandle, 'PyImport_AddModule'));
  PyModule_GetDict := TPyModule_GetDict(GetProcedureAddress(FLibHandle, 'PyModule_GetDict'));
  PyDict_GetItemString := TPyDict_GetItemString(GetProcedureAddress(FLibHandle, 'PyDict_GetItemString'));
  PyObject_Str := TPyObject_Str(GetProcedureAddress(FLibHandle, 'PyObject_Str'));
  PyUnicode_AsUTF8 := TPyUnicode_AsUTF8(GetProcedureAddress(FLibHandle, 'PyUnicode_AsUTF8'));
  Py_DecRef := TPy_DecRef(GetProcedureAddress(FLibHandle, 'Py_DecRef'));
  Py_IncRef := TPy_IncRef(GetProcedureAddress(FLibHandle, 'Py_IncRef'));

  FRequiredMethodsOK :=
    Assigned(Py_Initialize) and
    (Assigned(Py_Finalize) or Assigned(Py_FinalizeEx)) and
    Assigned(Py_IsInitialized) and
    (Assigned(PyRun_SimpleString) or Assigned(PyRun_SimpleStringFlags)) and
    Assigned(Py_GetVersion);

  FOptionalMethodsOK :=
    Assigned(PyImport_AddModule) and
    Assigned(PyModule_GetDict) and
    Assigned(PyDict_GetItemString) and
    Assigned(PyObject_Str) and
    Assigned(PyUnicode_AsUTF8) and
    Assigned(Py_DecRef) and
    Assigned(Py_IncRef);

  FDiagnosticLog.Add('Funções Obrigatórias OK: ' + BoolToStr(FRequiredMethodsOK, True));
  FDiagnosticLog.Add('Funções Opcionais OK: ' + BoolToStr(FOptionalMethodsOK, True));

  FDiagnosticLog.Add('  Py_Initialize: ' + BoolToStr(Assigned(Py_Initialize), 'OK', 'FAIL'));
  FDiagnosticLog.Add('  Py_Finalize: ' + BoolToStr(Assigned(Py_Finalize), 'OK', 'FAIL'));
  FDiagnosticLog.Add('  Py_FinalizeEx: ' + BoolToStr(Assigned(Py_FinalizeEx), 'OK', 'FAIL'));
  FDiagnosticLog.Add('  Py_IsInitialized: ' + BoolToStr(Assigned(Py_IsInitialized), 'OK', 'FAIL'));
  FDiagnosticLog.Add('  PyRun_SimpleString: ' + BoolToStr(Assigned(PyRun_SimpleString), 'OK', 'FAIL'));
  FDiagnosticLog.Add('  PyRun_SimpleStringFlags: ' + BoolToStr(Assigned(PyRun_SimpleStringFlags), 'OK', 'FAIL'));
  FDiagnosticLog.Add('  Py_GetVersion: ' + BoolToStr(Assigned(Py_GetVersion), 'OK', 'FAIL'));

  FDiagnosticLog.Add('  PyImport_AddModule: ' + BoolToStr(Assigned(PyImport_AddModule), 'OK', 'FAIL'));
  FDiagnosticLog.Add('  PyModule_GetDict: ' + BoolToStr(Assigned(PyModule_GetDict), 'OK', 'FAIL'));
  FDiagnosticLog.Add('  PyDict_GetItemString: ' + BoolToStr(Assigned(PyDict_GetItemString), 'OK', 'FAIL'));
  FDiagnosticLog.Add('  PyObject_Str: ' + BoolToStr(Assigned(PyObject_Str), 'OK', 'FAIL'));
  FDiagnosticLog.Add('  PyUnicode_AsUTF8: ' + BoolToStr(Assigned(PyUnicode_AsUTF8), 'OK', 'FAIL'));
  FDiagnosticLog.Add('  Py_DecRef: ' + BoolToStr(Assigned(Py_DecRef), 'OK', 'FAIL'));
  FDiagnosticLog.Add('  Py_IncRef: ' + BoolToStr(Assigned(Py_IncRef), 'OK', 'FAIL'));

  if not FRequiredMethodsOK then
  begin
    FLastError := 'Funções essenciais da API C do Python ausentes na biblioteca.';
    FDiagnosticLog.Add('Erro: ' + FLastError);
    UnloadPythonDLL;
    Exit;
  end;

  Result := True;
end;

function TPythonConnector.ValidateVersionConstraints: Boolean;
begin
  Result := False;

  FDiagnosticLog.Add(
    'Validando restrições de versão: ' +
    IntToStr(FPythonMajor) + '.' + IntToStr(FPythonMinor)
  );

  if FPythonMajor = 2 then
  begin
    FLastError := 'Python 2.x não é suportado pelo conector.';
    FDiagnosticLog.Add('Erro: ' + FLastError);
    Exit;
  end;

  if FPythonMajor <> 3 then
    FDiagnosticLog.Add('Aviso: versão major do Python desconhecida: ' + IntToStr(FPythonMajor));

  if (FPythonMajor = 3) and
     ((FPythonMinor < FMinPythonMinor) or (FPythonMinor > FMaxPythonMinor)) then
  begin
    FLastError := Format(
      'Versão do Python não suportada: %d.%d. Esperado entre %d.%d e %d.%d',
      [FPythonMajor, FPythonMinor, FMinPythonMajor, FMinPythonMinor,
       FMaxPythonMajor, FMaxPythonMinor]
    );

    FDiagnosticLog.Add('Erro: ' + FLastError);
    Exit;
  end;

  Result := True;
end;

procedure TPythonConnector.ParseVersionNumbers(const AVersionStr: string);
var
  I, State: Integer;
  S: string;
begin
  FPythonMajor := 0;
  FPythonMinor := 0;
  FPythonPatch := 0;

  S := '';
  State := 0;

  for I := 1 to Length(AVersionStr) do
  begin
    if AVersionStr[I] in ['0'..'9'] then
      S := S + AVersionStr[I]
    else if AVersionStr[I] = '.' then
    begin
      case State of
        0: FPythonMajor := StrToIntDef(S, 0);
        1: FPythonMinor := StrToIntDef(S, 0);
      end;

      S := '';
      Inc(State);

      if State > 2 then
        Break;
    end
    else
    begin
      if S <> '' then
      begin
        case State of
          0: FPythonMajor := StrToIntDef(S, 0);
          1: FPythonMinor := StrToIntDef(S, 0);
          2: FPythonPatch := StrToIntDef(S, 0);
        end;

        Break;
      end;
    end;
  end;

  if S <> '' then
  begin
    case State of
      0: FPythonMajor := StrToIntDef(S, 0);
      1: FPythonMinor := StrToIntDef(S, 0);
      2: FPythonPatch := StrToIntDef(S, 0);
    end;
  end;
end;

function TPythonConnector.FindPythonExecutable: string;
var
  AppDir: string;
  PathEnv: string;
  Paths: TStringList;
  I: Integer;
  Candidate: string;
  ExeName: string;
begin
  Result := '';
  AppDir := IncludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0)));

  {$IFDEF MSWINDOWS}
  ExeName := 'python.exe';
  {$ELSE}
  ExeName := 'python3';
  {$ENDIF}

  if FileExists(FDLLPath) then
    Exit(FDLLPath);

  {$IFDEF MSWINDOWS}
  if SameText(FDLLPath, 'python.exe') or SameText(FDLLPath, 'python3.exe') then
    Exit(FDLLPath);
  {$ELSE}
  if (FDLLPath = 'python3') or (FDLLPath = 'python') then
    Exit(FDLLPath);
  {$ENDIF}

  if FileExists(AppDir + ExeName) then
    Exit(AppDir + ExeName);

  {$IFDEF MSWINDOWS}
  if FileExists(AppDir + 'python3.exe') then
    Exit(AppDir + 'python3.exe');
  {$ELSE}
  if FileExists(AppDir + 'python') then
    Exit(AppDir + 'python');
  {$ENDIF}

  PathEnv := GetEnvironmentVariable('PATH');
  Paths := TStringList.Create;
  try
    {$IFDEF MSWINDOWS}
    Paths.Delimiter := ';';
    {$ELSE}
    Paths.Delimiter := ':';
    {$ENDIF}

    Paths.StrictDelimiter := True;
    Paths.DelimitedText := PathEnv;

    for I := 0 to Paths.Count - 1 do
    begin
      if Paths[I] <> '' then
      begin
        Candidate := IncludeTrailingPathDelimiter(Paths[I]) + ExeName;
        if FileExists(Candidate) then
          Exit(Candidate);

        {$IFNDEF MSWINDOWS}
        Candidate := IncludeTrailingPathDelimiter(Paths[I]) + 'python';
        if FileExists(Candidate) then
          Exit(Candidate);
        {$ENDIF}
      end;
    end;
  finally
    Paths.Free;
  end;

  {$IFDEF MSWINDOWS}
  for I := 14 downto 8 do
  begin
    Candidate := 'C:\Python3' + IntToStr(I) + '\python.exe';
    if FileExists(Candidate) then
      Exit(Candidate);

    Candidate :=
      GetEnvironmentVariable('USERPROFILE') +
      '\AppData\Local\Programs\Python\Python3' +
      IntToStr(I) + '\python.exe';

    if FileExists(Candidate) then
      Exit(Candidate);
  end;

  Result := 'python.exe';
  {$ELSE}
  if FileExists('/usr/bin/python3') then
    Exit('/usr/bin/python3');

  if FileExists('/usr/bin/python') then
    Exit('/usr/bin/python');

  if FileExists('/usr/local/bin/python3') then
    Exit('/usr/local/bin/python3');

  Result := 'python3';
  {$ENDIF}
end;

function TPythonConnector.StartPythonProcess: Boolean;
var
  PythonExe: string;
  Line: string;
  Params: TStringList;
  OutputStr: string;
  I: Integer;
begin
  Result := False;
  FLastLoadStep := 'Iniciando Processo Python';
  FDiagnosticLog.Add('StartPythonProcess iniciado.');

  PythonExe := FindPythonExecutable;
  FDiagnosticLog.Add('Executável Python resolvido: ' + PythonExe);

  // 1. Teste inicial: versão e arquitetura do Python
  Params := TStringList.Create;
  try
    FDiagnosticLog.Add('Executando teste síncrono de versão via TProcess...');
    OutputStr := '';

    FProcess := TProcess.Create(nil);
    try
      FProcess.Executable := PythonExe;
      FProcess.Parameters.Add('-u');
      FProcess.Parameters.Add('-c');
      FProcess.Parameters.Add(
        'import sys, platform; ' +
        'print("VER:" + sys.version); ' +
        'print("ARCH:" + platform.machine())'
      );

      // IMPORTANTE:
      // poStderrToOutPut evita travamento quando TensorFlow/Keras/CUDA escrevem no stderr.
      FProcess.Options := [poWaitOnExit, poUsePipes, poNoConsole, poStderrToOutPut];

      try
        FProcess.Execute;

        Params.LoadFromStream(FProcess.Output);
        OutputStr := Params.Text;

        FDiagnosticLog.Add('ExitStatus do teste síncrono: ' + IntToStr(FProcess.ExitStatus));

      except
        on E: Exception do
        begin
          FLastError := 'Falha ao executar Python (' + PythonExe + '): ' + E.Message;
          FDiagnosticLog.Add('Erro: ' + FLastError);
          Exit;
        end;
      end;

    finally
      FProcess.Free;
      FProcess := nil;
    end;

    FDiagnosticLog.Add('Saída do teste síncrono:');
    FDiagnosticLog.Add(OutputStr);

    FPythonVersionText := '';
    FPythonArchitecture := '';

    Params.Text := OutputStr;

    for I := 0 to Params.Count - 1 do
    begin
      if Copy(Params[I], 1, 4) = 'VER:' then
      begin
        FPythonVersionText := Copy(Params[I], 5, MaxInt);
        ParseVersionNumbers(FPythonVersionText);
      end
      else if Copy(Params[I], 1, 5) = 'ARCH:' then
      begin
        FPythonArchitecture := Trim(Copy(Params[I], 6, MaxInt));
      end;
    end;

    FDiagnosticLog.Add('Versão detectada do processo: ' + FPythonVersionText);
    FDiagnosticLog.Add('Arquitetura detectada do processo: ' + FPythonArchitecture);

    // Em modo processo, se o executável iniciou, consideramos compatível.
    FArchitectureCompatible := True;

    if not ValidateVersionConstraints then
      Exit;

  finally
    Params.Free;
  end;

  // 2. Criar script Python persistente
  FTempFileName :=
    IncludeTrailingPathDelimiter(GetTempDir) +
    'py_conn_' + IntToStr(Random(1000000)) + '.py';

  Params := TStringList.Create;
  try
    Params.Add('import sys');
    Params.Add('import traceback');
    Params.Add('globals_dict = {}');
    Params.Add('print("PYTHON_CONNECTOR_READY", flush=True)');
    Params.Add('while True:');
    Params.Add('    lines = []');
    Params.Add('    while True:');
    Params.Add('        line = sys.stdin.readline()');
    Params.Add('        if not line: break');
    Params.Add('        if line.strip() == "__EOF_PYTHON_SCRIPT__": break');
    Params.Add('        lines.append(line)');
    Params.Add('    if not lines and not line: break');
    Params.Add('    code = "".join(lines)');
    Params.Add('    if not code.strip(): continue');
    Params.Add('    try:');
    Params.Add('        exec(code, globals_dict)');
    Params.Add('        print("SUCCESS", flush=True)');
    Params.Add('    except Exception as e:');
    Params.Add('        print("ERROR: " + str(e), flush=True)');
    Params.Add('        traceback.print_exc(file=sys.stdout)');
    Params.Add('        print("ERROR_END", flush=True)');

    try
      Params.SaveToFile(FTempFileName);
      FDiagnosticLog.Add('Script temporário criado em: ' + FTempFileName);
    except
      on E: Exception do
      begin
        FLastError := 'Falha ao gravar script temporário: ' + E.Message;
        FDiagnosticLog.Add('Erro: ' + FLastError);
        Exit;
      end;
    end;

  finally
    Params.Free;
  end;

  // 3. Iniciar processo persistente
  FProcess := TProcess.Create(nil);
  FProcess.Executable := PythonExe;
  FProcess.Parameters.Add('-u');
  FProcess.Parameters.Add(FTempFileName);

  // IMPORTANTE:
  // poStderrToOutPut evita que stderr cheio trave o TensorFlow/MobileNet.
  FProcess.Options := [poUsePipes, poNoConsole, poStderrToOutPut];

  Params := TStringList.Create;
  try
    try
      FProcess.Execute;

      FDiagnosticLog.Add('Processo persistente iniciado. Aguardando PYTHON_CONNECTOR_READY...');

      if ReadLineFromProcess(Line, 5000) then
      begin
        FDiagnosticLog.Add('Recebido do processo: ' + Line);

        if Line = 'PYTHON_CONNECTOR_READY' then
        begin
          Result := True;
          FDiagnosticLog.Add('Processo Python inicializado com sucesso.');
        end
        else
        begin
          FLastError := 'Saída inesperada do processo Python: ' + Line;
          FDiagnosticLog.Add('Erro: ' + FLastError);
          StopPythonProcess;
        end;
      end
      else
      begin
        FLastError := 'Timeout aguardando prontidão do processo Python.';
        FDiagnosticLog.Add('Erro: ' + FLastError);
        StopPythonProcess;
      end;

    except
      on E: Exception do
      begin
        FLastError := 'Exceção ao executar processo Python: ' + E.Message;
        FDiagnosticLog.Add('Erro: ' + FLastError);
        StopPythonProcess;
      end;
    end;

  finally
    Params.Free;
  end;
end;

procedure TPythonConnector.StopPythonProcess;
begin
  if FProcess <> nil then
  begin
    try
      if FProcess.Running then
      begin
        try
          FProcess.Terminate(0);
        except
        end;
      end;
    finally
      FreeAndNil(FProcess);
    end;
  end;

  if FTempFileName <> '' then
  begin
    if FileExists(FTempFileName) then
      DeleteFile(FTempFileName);

    FTempFileName := '';
  end;
end;

procedure TPythonConnector.StopExecution;
begin
  FLastError := 'Execução Python interrompida pelo usuário.';

  if FExecutionMode = pemProcess then
  begin
    StopPythonProcess;
    FInitialized := False;
    FActive := False;
    Exit;
  end;

  if FInitialized then
  begin
    try
      if Assigned(Py_FinalizeEx) then
        Py_FinalizeEx()
      else if Assigned(Py_Finalize) then
        Py_Finalize();
    except
    end;
  end;

  UnloadPythonDLL;
  FInitialized := False;
  FActive := False;
end;

function TPythonConnector.ReadLineFromProcess(out ALine: string; AMaxWaitMS: Integer): Boolean;
var
  Ch: Char;
  BytesRead: Integer;
  StartTicks: QWord;
  UseTimeout: Boolean;
begin
  ALine := '';
  Result := False;

  if FProcess = nil then
    Exit;

  UseTimeout := AMaxWaitMS > 0;
  StartTicks := GetTickCount64;

  while True do
  begin
    if UseTimeout then
    begin
      if (GetTickCount64 - StartTicks >= QWord(AMaxWaitMS)) then
      begin
        FLastError := 'Timeout aguardando resposta do processo Python.';
        Exit(False);
      end;
    end;

    if FProcess = nil then
      Exit(False);

    if FProcess.Output.NumBytesAvailable > 0 then
    begin
      BytesRead := FProcess.Output.Read(Ch, 1);

      if BytesRead = 1 then
      begin
        if Ch = #10 then
        begin
          Result := True;
          Exit;
        end;

        if Ch <> #13 then
          ALine := ALine + Ch;
      end;
    end
    else
    begin
      Sleep(10);

      if FProcess = nil then
        Exit(False);

      if not FProcess.Running then
      begin
        if ALine <> '' then
          Result := True;

        Exit;
      end;
    end;
  end;
end;

procedure TPythonConnector.UnloadPythonDLL;
begin
  if FLibHandle <> NilHandle then
  begin
    FreeLibrary(FLibHandle);
    FLibHandle := NilHandle;
  end;

  FLoadedDLLPath := '';

  Py_Initialize := nil;
  Py_Finalize := nil;
  Py_IsInitialized := nil;
  PyRun_SimpleString := nil;
  Py_GetVersion := nil;
  PyImport_AddModule := nil;
  PyModule_GetDict := nil;
  PyDict_GetItemString := nil;
  PyObject_Str := nil;
  PyUnicode_AsUTF8 := nil;
  Py_DecRef := nil;
  Py_IncRef := nil;
  PyRun_SimpleStringFlags := nil;
  Py_FinalizeEx := nil;
end;

procedure TPythonConnector.SetActive(const AValue: Boolean);
begin
  if FActive = AValue then
    Exit;

  if AValue then
    StartPython
  else
  begin
    if FExecutionMode = pemProcess then
      StopPythonProcess
    else
    begin
      if FInitialized then
      begin
        try
          if Assigned(Py_FinalizeEx) then
            Py_FinalizeEx()
          else if Assigned(Py_Finalize) then
            Py_Finalize();
        except
        end;
      end;

      UnloadPythonDLL;
    end;

    FInitialized := False;
    FActive := False;
  end;
end;

function TPythonConnector.StartPython: Boolean;
begin
  Result := False;
  FLastError := '';
  FLastOutput := '';
  FDiagnosticLog.Clear;
  FDiagnosticLog.Add('StartPython iniciado.');

  if FExecutionMode = pemProcess then
  begin
    Result := StartPythonProcess;

    if Result then
    begin
      FInitialized := True;
      FActive := True;

      if not SelfTest then
      begin
        StopPythonProcess;
        FInitialized := False;
        FActive := False;
        Result := False;
      end;
    end
    else
    begin
      FInitialized := False;
      FActive := False;
    end;

    Exit;
  end;

  if not DiagnosePythonDLL then
  begin
    FInitialized := False;
    FActive := False;
    Exit;
  end;

  if not ResolveFunctions then
  begin
    FInitialized := False;
    FActive := False;
    Exit;
  end;

  try
    FLastLoadStep := 'Chamando Py_Initialize';
    Py_Initialize();
    FInitialized := True;

    if Assigned(PyRun_SimpleString) then
    begin
      PyRun_SimpleString(
        'import sys, io' + sLineBreak +
        '_connector_stdout = io.StringIO()' + sLineBreak +
        '_connector_stderr = io.StringIO()' + sLineBreak +
        'sys.stdout = _connector_stdout' + sLineBreak +
        'sys.stderr = _connector_stderr'
      );
    end;

    if Assigned(Py_GetVersion) then
    begin
      FPythonVersionText := string(Py_GetVersion());
      ParseVersionNumbers(FPythonVersionText);
      FPythonArchitecture := FLazarusArchitecture;
      FArchitectureCompatible := True;
    end;

    if not ValidateVersionConstraints then
    begin
      if Assigned(Py_FinalizeEx) then
        Py_FinalizeEx()
      else if Assigned(Py_Finalize) then
        Py_Finalize();

      UnloadPythonDLL;
      FInitialized := False;
      FActive := False;
      Exit;
    end;

    if not SelfTest then
    begin
      if Assigned(Py_FinalizeEx) then
        Py_FinalizeEx()
      else if Assigned(Py_Finalize) then
        Py_Finalize();

      UnloadPythonDLL;
      FInitialized := False;
      FActive := False;
      Exit;
    end;

    FActive := True;
    Result := True;
    FDiagnosticLog.Add('DLL/SO Python carregada, inicializada e testada com sucesso.');

  except
    on E: Exception do
    begin
      FLastError := 'Exceção ao inicializar Python: ' + E.Message;
      FDiagnosticLog.Add('Erro: ' + FLastError);
      UnloadPythonDLL;
      FInitialized := False;
      FActive := False;
    end;
  end;
end;

function TPythonConnector.SelfTest: Boolean;
var
  TestScript: string;
  TestOk, TestVer: string;
begin
  Result := False;
  FLastLoadStep := 'Executando Autoteste';
  FDiagnosticLog.Add('Executando autoteste...');

  TestScript :=
    'import sys' + sLineBreak +
    '_connector_test_version = sys.version' + sLineBreak +
    '_connector_test_ok = 1';

  if not ExecString(TestScript) then
  begin
    FLastError := 'SelfTest: falha ao executar script mínimo.';
    FDiagnosticLog.Add('Erro: ' + FLastError);
    Exit;
  end;

  TestOk := GetVar('_connector_test_ok');
  TestVer := GetVar('_connector_test_version');

  if (TestOk <> '1') or (TestVer = '') then
  begin
    if FExecutionMode = pemDLL then
      FLastError :=
        'Python executa scripts, mas falhou ao recuperar variáveis.' + sLineBreak +
        'Verifique PyImport_AddModule, PyModule_GetDict, PyDict_GetItemString, ' +
        'PyObject_Str e PyUnicode_AsUTF8.'
    else
      FLastError := 'Python executa scripts, mas falhou ao recuperar variáveis via processo.';

    FDiagnosticLog.Add('Erro: ' + FLastError);
    Exit;
  end;

  FDiagnosticLog.Add('SelfTest concluído com sucesso.');
  FDiagnosticLog.Add('Versão obtida no teste: ' + TestVer);
  Result := True;
end;

procedure TPythonConnector.GetDiagnosticReport(AReport: TStrings);
var
  I: Integer;
begin
  AReport.Clear;
  AReport.Add('TPythonConnector Diagnostic Report');
  AReport.Add('----------------------------------');

  case FCompiledPlatform of
    ppWindows64: AReport.Add('Componente compilado para: Windows 64 bits');
    ppWindows32: AReport.Add('Componente compilado para: Windows 32 bits');
    ppLinux64: AReport.Add('Componente compilado para: Linux 64 bits');
    ppLinux32: AReport.Add('Componente compilado para: Linux 32 bits');
    ppLinuxARM64: AReport.Add('Componente compilado para: Linux ARM 64 bits');
    ppLinuxARM: AReport.Add('Componente compilado para: Linux ARM 32 bits');
    ppDarwin64: AReport.Add('Componente compilado para: macOS 64 bits');
  else
    AReport.Add('Componente compilado para: plataforma desconhecida');
  end;

  AReport.Add('Lazarus architecture: ' + FLazarusArchitecture);

  {$IFDEF MSWINDOWS}
  AReport.Add('Operating system: Windows');
  {$ELSE}
    {$IFDEF DARWIN}
    AReport.Add('Operating system: macOS');
    {$ELSE}
    AReport.Add('Operating system: Linux');
    {$ENDIF}
  {$ENDIF}

  if FExecutionMode = pemDLL then
  begin
    AReport.Add('Execution Mode: DLL/SO');
    AReport.Add('Configured DLLPath: ' + FDLLPath);
    AReport.Add('Loaded Library: ' + FLoadedDLLPath);
  end
  else
  begin
    AReport.Add('Execution Mode: Process');
    AReport.Add('Configured Python Executable: ' + FDLLPath);

    if (FProcess <> nil) and FProcess.Running then
      AReport.Add('Python Process: RUNNING')
    else
      AReport.Add('Python Process: NOT RUNNING');
  end;

  AReport.Add('Python version: ' + FPythonVersionText);
  AReport.Add('Python architecture: ' + FPythonArchitecture);
  AReport.Add('Architecture compatible: ' + BoolToStr(FArchitectureCompatible, 'Yes', 'No'));
  AReport.Add('');

  if FExecutionMode = pemDLL then
  begin
    AReport.Add('Required methods:');
    AReport.Add(Format('[%s] Py_Initialize', [BoolToStr(Assigned(Py_Initialize), 'OK', 'FAIL')]));
    AReport.Add(Format('[%s] Py_Finalize/Py_FinalizeEx', [BoolToStr(Assigned(Py_Finalize) or Assigned(Py_FinalizeEx), 'OK', 'FAIL')]));
    AReport.Add(Format('[%s] Py_IsInitialized', [BoolToStr(Assigned(Py_IsInitialized), 'OK', 'FAIL')]));
    AReport.Add(Format('[%s] PyRun_SimpleString/PyRun_SimpleStringFlags', [BoolToStr(Assigned(PyRun_SimpleString) or Assigned(PyRun_SimpleStringFlags), 'OK', 'FAIL')]));
    AReport.Add(Format('[%s] Py_GetVersion', [BoolToStr(Assigned(Py_GetVersion), 'OK', 'FAIL')]));
    AReport.Add('');
  end;

  AReport.Add('Last load step: ' + FLastLoadStep);

  if FLastError <> '' then
    AReport.Add('Last Error: ' + FLastError)
  else
    AReport.Add('Result: Python connector ready.');

  AReport.Add('');
  AReport.Add('Diagnostic Log:');

  for I := 0 to FDiagnosticLog.Count - 1 do
    AReport.Add('  ' + FDiagnosticLog[I]);
end;

function TPythonConnector.GetVersion: string;
begin
  if FInitialized then
    Result := FPythonVersionText
  else
    Result := 'Inativo';
end;

function TPythonConnector.ExecString(const AScript: string): Boolean;
var
  InputStr: string;
  Line: string;
  ErrLines: string;
  IsError: Boolean;
  Params: TStringList;
begin
  Result := False;
  FLastOutput := '';

  if not FInitialized then
  begin
    FLastError := 'Interpretador Python não ativado.';
    Exit;
  end;

  if FExecutionMode = pemProcess then
  begin
    if (FProcess = nil) or not FProcess.Running then
    begin
      FLastError := 'Processo Python não está ativo.';
      Exit;
    end;

    FLastError := '';
    FLastValue := '';

    InputStr := AScript + sLineBreak + '__EOF_PYTHON_SCRIPT__' + sLineBreak;

    try
      if Length(InputStr) > 0 then
        FProcess.Input.Write(InputStr[1], Length(InputStr));
    except
      on E: Exception do
      begin
        FLastError := 'Erro ao enviar script para o processo Python: ' + E.Message;
        Exit;
      end;
    end;

    IsError := False;
    ErrLines := '';

    while ReadLineFromProcess(Line, 0) do
    begin
      if Line = 'SUCCESS' then
      begin
        Result := True;
        Break;
      end
      else if Copy(Line, 1, 6) = 'ERROR: ' then
      begin
        IsError := True;
        FLastError := Copy(Line, 7, MaxInt);
      end
      else if Line = 'ERROR_END' then
      begin
        Result := False;

        if FLastError = '' then
          FLastError := ErrLines
        else
          FLastError := FLastError + sLineBreak + ErrLines;

        Break;
      end
      else if Copy(Line, 1, 10) = '__VALUE__:' then
        FLastValue := Copy(Line, 11, MaxInt)
      else if IsError then
        ErrLines := ErrLines + Line + sLineBreak
      else
        FLastOutput := FLastOutput + Line + sLineBreak;
    end;

    if not Result then
    begin
      if (FProcess <> nil) and not FProcess.Running then
      begin
        Params := TStringList.Create;
        try
          if FProcess.Stderr.NumBytesAvailable > 0 then
          begin
            Params.LoadFromStream(FProcess.Stderr);
            FLastError :=
              'Processo Python terminou inesperadamente. ExitStatus: ' +
              IntToStr(FProcess.ExitStatus) + sLineBreak +
              'Erro Python: ' + Trim(Params.Text);
          end
          else if FLastError = '' then
            FLastError :=
              'Processo Python terminou inesperadamente com ExitStatus: ' +
              IntToStr(FProcess.ExitStatus);
        finally
          Params.Free;
        end;

        StopPythonProcess;
        FInitialized := False;
        FActive := False;
      end
      else if FLastError = '' then
        FLastError := 'Execução Python interrompida ou sem resposta de sucesso.';
    end;
  end
  else
  begin
    if not Assigned(PyRun_SimpleString) and not Assigned(PyRun_SimpleStringFlags) then
    begin
      FLastError := 'Funções de execução de string não disponíveis.';
      Exit;
    end;

    try
      if Assigned(PyRun_SimpleString) then
        PyRun_SimpleString(
          '_connector_stdout.seek(0); _connector_stdout.truncate(0); ' +
          '_connector_stderr.seek(0); _connector_stderr.truncate(0)'
        );

      if Assigned(PyRun_SimpleString) then
        Result := (PyRun_SimpleString(PAnsiChar(AnsiString(AScript))) = 0)
      else
        Result := (PyRun_SimpleStringFlags(PAnsiChar(AnsiString(AScript)), nil) = 0);

      if Assigned(PyRun_SimpleString) then
      begin
        PyRun_SimpleString(
          '_connector_stdout_val = _connector_stdout.getvalue(); ' +
          '_connector_stderr_val = _connector_stderr.getvalue()'
        );

        FLastOutput := GetVar('_connector_stdout_val');
      end;

      if not Result then
      begin
        FLastError := GetVar('_connector_stderr_val');

        if FLastError = '' then
          FLastError := 'Falha na execução do script Python.';
      end;

    except
      on E: Exception do
      begin
        FLastError := 'Exceção ao executar instrução Python: ' + E.Message;
        Result := False;
      end;
    end;
  end;
end;

function TPythonConnector.GetVar(const AVarName: string): string;
var
  module, dict, obj, strObj: Pointer;
  pstr: PAnsiChar;
  Script: string;
begin
  Result := '';

  if not FInitialized then
    Exit;

  if FExecutionMode = pemProcess then
  begin
    FLastValue := '';

    Script :=
      'try:' + sLineBreak +
      '    _val = globals().get(' + QuotedStr(AVarName) + ')' + sLineBreak +
      '    if _val is not None:' + sLineBreak +
      '        print("__VALUE__:" + str(_val), flush=True)' + sLineBreak +
      '    else:' + sLineBreak +
      '        print("__VALUE__:", flush=True)' + sLineBreak +
      'except Exception as e:' + sLineBreak +
      '    print("__VALUE__:Erro: " + str(e), flush=True)';

    if ExecString(Script) then
      Result := FLastValue;
  end
  else
  begin
    if not Assigned(PyImport_AddModule) or
       not Assigned(PyModule_GetDict) or
       not Assigned(PyDict_GetItemString) then
      Exit;

    try
      module := PyImport_AddModule('__main__');

      if module <> nil then
      begin
        dict := PyModule_GetDict(module);

        if dict <> nil then
        begin
          obj := PyDict_GetItemString(dict, PAnsiChar(AnsiString(AVarName)));

          if obj <> nil then
          begin
            if Assigned(PyObject_Str) then
            begin
              strObj := PyObject_Str(obj);

              if strObj <> nil then
              begin
                if Assigned(PyUnicode_AsUTF8) then
                begin
                  pstr := PyUnicode_AsUTF8(strObj);

                  if pstr <> nil then
                    Result := string(pstr);
                end;

                if Assigned(Py_DecRef) then
                  Py_DecRef(strObj);
              end;
            end;
          end;
        end;
      end;

    except
      on E: Exception do
        Result := 'Erro: ' + E.Message;
    end;
  end;
end;

procedure TPythonConnector.SetVar(const AVarName, AValue: string);
var
  EscapedVal: string;
begin
  if not FInitialized then
    Exit;

  EscapedVal := StringReplace(AValue, '\', '\\', [rfReplaceAll]);
  EscapedVal := StringReplace(EscapedVal, '"', '\"', [rfReplaceAll]);

  if FExecutionMode = pemProcess then
  begin
    EscapedVal := StringReplace(EscapedVal, #10, '\n', [rfReplaceAll]);
    EscapedVal := StringReplace(EscapedVal, #13, '\r', [rfReplaceAll]);
  end;

  ExecString(AVarName + ' = """' + EscapedVal + '"""');
end;

function TPythonConnector.Eval(const AExpression: string): string;
begin
  Result := '';

  if ExecString('_connector_eval_tmp = ' + AExpression) then
  begin
    Result := GetVar('_connector_eval_tmp');
    ExecString('del _connector_eval_tmp');
  end;
end;

initialization
  {$I pythonconnector_icon.lrs}

end.
