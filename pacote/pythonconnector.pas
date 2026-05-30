unit pythonconnector;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, DynLibs, LResources;

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

    procedure SetActive(const AValue: Boolean);
    function LoadPythonDLL: Boolean;
    procedure UnloadPythonDLL;
    function GetVersion: string;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    function ExecString(const AScript: string): Boolean;
    function GetVar(const AVarName: string): string;
    procedure SetVar(const AVarName, AValue: string);
    function Eval(const AExpression: string): string;

    property IsInitialized: Boolean read FInitialized;
    property LastError: string read FLastError;
  published
    property DLLPath: string read FDLLPath write FDLLPath;
    property Active: Boolean read FActive write SetActive;
    property Version: string read GetVersion;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('IA', [TPythonConnector]);
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
end;

destructor TPythonConnector.Destroy;
begin
  if FActive then
    SetActive(False);
  inherited Destroy;
end;

function TPythonConnector.LoadPythonDLL: Boolean;
begin
  Result := False;
  FLastError := '';

  if FLibHandle <> NilHandle then
    Exit(True);

  if FDLLPath = '' then
  begin
    FLastError := 'Caminho para Python DLL não configurado.';
    Exit;
  end;

  FLibHandle := SafeLoadLibrary(FDLLPath);
  if FLibHandle = NilHandle then
  begin
    FLastError := 'Falha ao carregar biblioteca dinâmica: ' + FDLLPath + '. Certifique-se de que o caminho está correto e de que possui a mesma arquitetura do executável.';
    Exit;
  end;

  // Resolve procedure addresses
  Py_Initialize := TPy_Initialize(GetProcedureAddress(FLibHandle, 'Py_Initialize'));
  Py_Finalize := TPy_Finalize(GetProcedureAddress(FLibHandle, 'Py_Finalize'));
  Py_IsInitialized := TPy_IsInitialized(GetProcedureAddress(FLibHandle, 'Py_IsInitialized'));
  PyRun_SimpleString := TPyRun_SimpleString(GetProcedureAddress(FLibHandle, 'PyRun_SimpleString'));
  Py_GetVersion := TPy_GetVersion(GetProcedureAddress(FLibHandle, 'Py_GetVersion'));
  PyImport_AddModule := TPyImport_AddModule(GetProcedureAddress(FLibHandle, 'PyImport_AddModule'));
  PyModule_GetDict := TPyModule_GetDict(GetProcedureAddress(FLibHandle, 'PyModule_GetDict'));
  PyDict_GetItemString := TPyDict_GetItemString(GetProcedureAddress(FLibHandle, 'PyDict_GetItemString'));
  PyObject_Str := TPyObject_Str(GetProcedureAddress(FLibHandle, 'PyObject_Str'));
  PyUnicode_AsUTF8 := TPyUnicode_AsUTF8(GetProcedureAddress(FLibHandle, 'PyUnicode_AsUTF8'));
  Py_DecRef := TPy_DecRef(GetProcedureAddress(FLibHandle, 'Py_DecRef'));
  Py_IncRef := TPy_IncRef(GetProcedureAddress(FLibHandle, 'Py_IncRef'));

  if not Assigned(Py_Initialize) or not Assigned(Py_Finalize) or
     not Assigned(PyRun_SimpleString) or not Assigned(Py_GetVersion) then
  begin
    FLastError := 'Algumas funções essenciais da API C do Python não foram encontradas na biblioteca.';
    UnloadPythonDLL;
    Exit;
  end;

  Result := True;
end;

procedure TPythonConnector.UnloadPythonDLL;
begin
  if FLibHandle <> NilHandle then
  begin
    FreeLibrary(FLibHandle);
    FLibHandle := NilHandle;
  end;

  // Clear pointers
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
end;

procedure TPythonConnector.SetActive(const AValue: Boolean);
begin
  if FActive = AValue then Exit;

  if AValue then
  begin
    if LoadPythonDLL then
    begin
      try
        Py_Initialize();
        FInitialized := True;
        FActive := True;
      except
        on E: Exception do
        begin
          FLastError := 'Exceção ao inicializar interpretador Python: ' + E.Message;
          UnloadPythonDLL;
          FActive := False;
          FInitialized := False;
        end;
      end;
    end
    else
    begin
      FActive := False;
    end;
  end
  else
  begin
    if FInitialized and Assigned(Py_Finalize) then
    begin
      try
        Py_Finalize();
      except
        // Ignora erros ao finalizar
      end;
    end;
    FInitialized := False;
    UnloadPythonDLL;
    FActive := False;
  end;
end;

function TPythonConnector.GetVersion: string;
begin
  if FInitialized and Assigned(Py_GetVersion) then
    Result := string(Py_GetVersion())
  else
    Result := 'Inativo';
end;

function TPythonConnector.ExecString(const AScript: string): Boolean;
begin
  Result := False;
  if not FInitialized or not Assigned(PyRun_SimpleString) then
  begin
    FLastError := 'Interpretador Python não ativado.';
    Exit;
  end;

  try
    Result := (PyRun_SimpleString(PAnsiChar(AnsiString(AScript))) = 0);
    if not Result then
      FLastError := 'Falha na execução do script Python (verifique o console ou a sintaxe).';
  except
    on E: Exception do
    begin
      FLastError := 'Exceção ao executar instrução: ' + E.Message;
      Result := False;
    end;
  end;
end;

function TPythonConnector.GetVar(const AVarName: string): string;
var
  module, dict, obj, strObj: Pointer;
  pstr: PAnsiChar;
begin
  Result := '';
  if not FInitialized or not Assigned(PyImport_AddModule) or
     not Assigned(PyModule_GetDict) or not Assigned(PyDict_GetItemString) then
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

procedure TPythonConnector.SetVar(const AVarName, AValue: string);
var
  EscapedVal: string;
begin
  EscapedVal := StringReplace(AValue, '\', '\\', [rfReplaceAll]);
  EscapedVal := StringReplace(EscapedVal, '"', '\"', [rfReplaceAll]);
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
