unit aillamacppapi;

{$mode ObjFPC}{$H+}

interface

uses
  DynLibs,
  Math,
  SysUtils,
  ailibraryloader;

const
  AI_LLAMA_BRIDGE_API_VERSION = 1;

type
  TAILlamaNativeHandle = Pointer;
  TAILlamaBridgeVersionFunc = function: PAnsiChar; cdecl;
  TAILlamaInitProc = procedure; cdecl;
  TAILlamaShutdownProc = procedure; cdecl;
  TAILlamaCreateHandleFunc = function: TAILlamaNativeHandle; cdecl;
  TAILlamaDestroyHandleProc = procedure(AHandle: TAILlamaNativeHandle); cdecl;
  TAILlamaLastErrorFunc = function(AHandle: TAILlamaNativeHandle): PAnsiChar;
    cdecl;
  TAILlamaModelLoadFunc = function(AHandle: TAILlamaNativeHandle;
    AFilename: PAnsiChar; AContextSize, AThreads: LongInt): LongInt; cdecl;
  TAILlamaModelUnloadProc = procedure(AHandle: TAILlamaNativeHandle); cdecl;
  TAILlamaGenerateFunc = function(AHandle: TAILlamaNativeHandle;
    APromptUTF8: PAnsiChar; AMaxTokens: LongInt; ATemperature: Single;
    ATopK: LongInt; ATopP: Single; ASeed: LongInt): PAnsiChar; cdecl;
  TAILlamaTokenCallback = procedure(ATokenUTF8: PAnsiChar;
    AUserData: Pointer); cdecl;
  TAILlamaGenerateStreamFunc = function(AHandle: TAILlamaNativeHandle;
    APromptUTF8: PAnsiChar; AMaxTokens: LongInt; ATemperature: Single;
    ATopK: LongInt; ATopP: Single; ASeed: LongInt;
    ACallback: TAILlamaTokenCallback; AUserData: Pointer): LongInt; cdecl;
  TAILlamaAbortProc = procedure(AHandle: TAILlamaNativeHandle); cdecl;
  TAILlamaLoRAApplyFunc = function(AHandle: TAILlamaNativeHandle;
    AAdapterFilenameUTF8: PAnsiChar; AScale: Single): LongInt; cdecl;
  TAILlamaLoRARemoveFunc = function(AHandle: TAILlamaNativeHandle): LongInt;
    cdecl;

  TAILlamaCppAPI = class
  private
    FLoader: TAILibraryLoader;
    FHandle: TLibHandle;
    FBridgeVersion: TAILlamaBridgeVersionFunc;
    FInit: TAILlamaInitProc;
    FShutdown: TAILlamaShutdownProc;
    FCreateHandle: TAILlamaCreateHandleFunc;
    FDestroyHandle: TAILlamaDestroyHandleProc;
    FHandleLastError: TAILlamaLastErrorFunc;
    FModelLoad: TAILlamaModelLoadFunc;
    FModelUnload: TAILlamaModelUnloadProc;
    FGenerate: TAILlamaGenerateFunc;
    FGenerateStream: TAILlamaGenerateStreamFunc;
    FAbort: TAILlamaAbortProc;
    FLoRAApply: TAILlamaLoRAApplyFunc;
    FLoRARemove: TAILlamaLoRARemoveFunc;
    FLastError: string;
    FVersion: string;
    FInitialized: Boolean;
    function ResolveBridgeExports: Boolean;
    procedure ClearBridgeExports;
  public
    constructor Create;
    destructor Destroy; override;
    function Load(const ALibraryPath: string): Boolean;
    procedure Unload;
    function Initialize: Boolean;
    procedure Shutdown;
    function CreateHandle: TAILlamaNativeHandle;
    procedure DestroyHandle(AHandle: TAILlamaNativeHandle);
    function HandleLastError(AHandle: TAILlamaNativeHandle): string;
    function ModelLoad(AHandle: TAILlamaNativeHandle;
      const AFilename: string; AContextSize, AThreads: Integer): Boolean;
    procedure ModelUnload(AHandle: TAILlamaNativeHandle);
    function Generate(AHandle: TAILlamaNativeHandle; const APrompt: string;
      AMaxTokens: Integer; ATemperature: Double; ATopK: Integer;
      ATopP: Double; ASeed: Integer; out AText: string): Boolean;
    function GenerateStream(AHandle: TAILlamaNativeHandle;
      const APrompt: string; AMaxTokens: Integer; ATemperature: Double;
      ATopK: Integer; ATopP: Double; ASeed: Integer;
      ACallback: TAILlamaTokenCallback; AUserData: Pointer): Boolean;
    procedure Abort(AHandle: TAILlamaNativeHandle);
    function LoRAApply(AHandle: TAILlamaNativeHandle;
      const AAdapterFile: string; AScale: Double): Boolean;
    function LoRARemove(AHandle: TAILlamaNativeHandle): Boolean;
    property LastError: string read FLastError;
    property Version: string read FVersion;
    property Initialized: Boolean read FInitialized;
  end;

implementation

constructor TAILlamaCppAPI.Create;
begin
  inherited Create;
  FLoader := TAILibraryLoader.Create;
  FHandle := NilHandle;
  ClearBridgeExports;
  FLastError := '';
  FVersion := '';
  FInitialized := False;
end;

procedure TAILlamaCppAPI.ClearBridgeExports;
begin
  FBridgeVersion := nil;
  FInit := nil;
  FShutdown := nil;
  FCreateHandle := nil;
  FDestroyHandle := nil;
  FHandleLastError := nil;
  FModelLoad := nil;
  FModelUnload := nil;
  FGenerate := nil;
  FGenerateStream := nil;
  FAbort := nil;
  FLoRAApply := nil;
  FLoRARemove := nil;
end;

function TAILlamaCppAPI.ResolveBridgeExports: Boolean;
begin
  Result := False;
  Pointer(FBridgeVersion) := FLoader.GetProc(FHandle,
    'ai_llama_bridge_version');
  if not Assigned(FBridgeVersion) then Exit;
  Pointer(FInit) := FLoader.GetProc(FHandle, 'ai_llama_init');
  if not Assigned(FInit) then Exit;
  Pointer(FShutdown) := FLoader.GetProc(FHandle, 'ai_llama_shutdown');
  if not Assigned(FShutdown) then Exit;
  Pointer(FCreateHandle) := FLoader.GetProc(FHandle,
    'ai_llama_create_handle');
  if not Assigned(FCreateHandle) then Exit;
  Pointer(FDestroyHandle) := FLoader.GetProc(FHandle,
    'ai_llama_destroy_handle');
  if not Assigned(FDestroyHandle) then Exit;
  Pointer(FHandleLastError) := FLoader.GetProc(FHandle,
    'ai_llama_last_error');
  if not Assigned(FHandleLastError) then Exit;
  Pointer(FModelLoad) := FLoader.GetProc(FHandle, 'ai_llama_model_load');
  if not Assigned(FModelLoad) then Exit;
  Pointer(FModelUnload) := FLoader.GetProc(FHandle,
    'ai_llama_model_unload');
  if not Assigned(FModelUnload) then Exit;
  Pointer(FGenerate) := FLoader.GetProc(FHandle, 'ai_llama_generate');
  if not Assigned(FGenerate) then Exit;
  Pointer(FGenerateStream) := FLoader.GetProc(FHandle,
    'ai_llama_generate_stream');
  if not Assigned(FGenerateStream) then Exit;
  Pointer(FAbort) := FLoader.GetProc(FHandle, 'ai_llama_abort');
  if not Assigned(FAbort) then Exit;
  Pointer(FLoRAApply) := FLoader.GetProc(FHandle, 'ai_llama_lora_apply');
  if not Assigned(FLoRAApply) then Exit;
  Pointer(FLoRARemove) := FLoader.GetProc(FHandle, 'ai_llama_lora_remove');
  Result := Assigned(FLoRARemove);
end;

function TAILlamaCppAPI.Load(const ALibraryPath: string): Boolean;
var
  LVersionValue: PAnsiChar;
begin
  Result := False;
  FLastError := '';
  FVersion := '';

  if FHandle <> NilHandle then
    Exit(True);

  FHandle := FLoader.LoadLibraryFromPaths('chatgpt_llama_bridge',
    [ALibraryPath]);
  if FHandle = NilHandle then
  begin
    FLastError := FLoader.LastError;
    Exit;
  end;

  if not ResolveBridgeExports then
  begin
    FLastError := FLoader.LastError;
    ClearBridgeExports;
    FLoader.Unload(FHandle);
    Exit;
  end;

  LVersionValue := FBridgeVersion();
  if not Assigned(LVersionValue) then
  begin
    FLastError := 'Bridge returned an empty API version.';
    ClearBridgeExports;
    FLoader.Unload(FHandle);
    Exit;
  end;
  FVersion := string(AnsiString(LVersionValue));
  if FVersion <> IntToStr(AI_LLAMA_BRIDGE_API_VERSION) then
  begin
    FLastError := 'Incompatible bridge API version. Expected ' +
      IntToStr(AI_LLAMA_BRIDGE_API_VERSION) + ', received ' + FVersion + '.';
    ClearBridgeExports;
    FLoader.Unload(FHandle);
    Exit;
  end;

  Result := True;
end;

procedure TAILlamaCppAPI.Unload;
begin
  Shutdown;
  ClearBridgeExports;
  FVersion := '';
  FLoader.Unload(FHandle);
end;

function TAILlamaCppAPI.Initialize: Boolean;
var
  LSavedMask: TFPUExceptionMask;
begin
  Result := False;
  FLastError := '';
  if FHandle = NilHandle then
  begin
    FLastError := 'The llama.cpp bridge is not loaded.';
    Exit;
  end;
  if FInitialized then
    Exit(True);
  if not Assigned(FInit) then
  begin
    FLastError := 'The llama.cpp initialization function is unavailable.';
    Exit;
  end;
  LSavedMask := GetExceptionMask;
  SetExceptionMask(LSavedMask + [exInvalidOp, exDenormalized,
    exZeroDivide, exOverflow, exUnderflow, exPrecision]);
  try
    FInit();
  finally
    ClearExceptions(False);
    SetExceptionMask(LSavedMask);
  end;
  FInitialized := True;
  Result := True;
end;

procedure TAILlamaCppAPI.Shutdown;
var
  LSavedMask: TFPUExceptionMask;
begin
  if FInitialized and Assigned(FShutdown) then
  begin
    LSavedMask := GetExceptionMask;
    SetExceptionMask(LSavedMask + [exInvalidOp, exDenormalized,
      exZeroDivide, exOverflow, exUnderflow, exPrecision]);
    try
      FShutdown();
    finally
      ClearExceptions(False);
      SetExceptionMask(LSavedMask);
    end;
  end;
  FInitialized := False;
end;

function TAILlamaCppAPI.CreateHandle: TAILlamaNativeHandle;
begin
  Result := nil;
  FLastError := '';
  if not FInitialized then
  begin
    FLastError := 'The llama.cpp bridge is not initialized.';
    Exit;
  end;
  if not Assigned(FCreateHandle) then
  begin
    FLastError := 'The llama.cpp handle creation function is unavailable.';
    Exit;
  end;
  Result := FCreateHandle();
  if not Assigned(Result) then
    FLastError := 'The llama.cpp bridge could not create a native handle.';
end;

procedure TAILlamaCppAPI.DestroyHandle(AHandle: TAILlamaNativeHandle);
var
  LSavedMask: TFPUExceptionMask;
begin
  if Assigned(AHandle) and Assigned(FDestroyHandle) then
  begin
    LSavedMask := GetExceptionMask;
    SetExceptionMask(LSavedMask + [exInvalidOp, exDenormalized,
      exZeroDivide, exOverflow, exUnderflow, exPrecision]);
    try
      FDestroyHandle(AHandle);
    finally
      ClearExceptions(False);
      SetExceptionMask(LSavedMask);
    end;
  end;
end;

function TAILlamaCppAPI.HandleLastError(
  AHandle: TAILlamaNativeHandle): string;
var
  LError: PAnsiChar;
begin
  Result := '';
  if not Assigned(FHandleLastError) then
    Exit;
  LError := FHandleLastError(AHandle);
  if Assigned(LError) then
    Result := string(AnsiString(LError));
end;

function TAILlamaCppAPI.ModelLoad(AHandle: TAILlamaNativeHandle;
  const AFilename: string; AContextSize, AThreads: Integer): Boolean;
var
  LFilename: UTF8String;
  LSavedMask: TFPUExceptionMask;
begin
  Result := False;
  FLastError := '';
  if not Assigned(AHandle) then
  begin
    FLastError := 'Invalid llama.cpp native handle.';
    Exit;
  end;
  if not Assigned(FModelLoad) then
  begin
    FLastError := 'The llama.cpp model load function is unavailable.';
    Exit;
  end;
  LFilename := UTF8Encode(AFilename);
  LSavedMask := GetExceptionMask;
  SetExceptionMask(LSavedMask + [exInvalidOp, exDenormalized,
    exZeroDivide, exOverflow, exUnderflow, exPrecision]);
  try
    Result := FModelLoad(AHandle, PAnsiChar(LFilename), AContextSize,
      AThreads) <> 0;
  finally
    ClearExceptions(False);
    SetExceptionMask(LSavedMask);
  end;
  if not Result then
  begin
    FLastError := HandleLastError(AHandle);
    if FLastError = '' then
      FLastError := 'The llama.cpp bridge could not load the model.';
  end;
end;

procedure TAILlamaCppAPI.ModelUnload(AHandle: TAILlamaNativeHandle);
var
  LSavedMask: TFPUExceptionMask;
begin
  if Assigned(AHandle) and Assigned(FModelUnload) then
  begin
    LSavedMask := GetExceptionMask;
    SetExceptionMask(LSavedMask + [exInvalidOp, exDenormalized,
      exZeroDivide, exOverflow, exUnderflow, exPrecision]);
    try
      FModelUnload(AHandle);
    finally
      ClearExceptions(False);
      SetExceptionMask(LSavedMask);
    end;
  end;
end;

function TAILlamaCppAPI.Generate(AHandle: TAILlamaNativeHandle;
  const APrompt: string; AMaxTokens: Integer; ATemperature: Double;
  ATopK: Integer; ATopP: Double; ASeed: Integer; out AText: string): Boolean;
var
  LPrompt: UTF8String;
  LResult: PAnsiChar;
  LSavedMask: TFPUExceptionMask;
begin
  Result := False;
  AText := '';
  FLastError := '';
  if not Assigned(AHandle) then
  begin
    FLastError := 'Invalid llama.cpp native handle.';
    Exit;
  end;
  if not Assigned(FGenerate) then
  begin
    FLastError := 'The llama.cpp generation function is unavailable.';
    Exit;
  end;

  LPrompt := UTF8Encode(APrompt);
  LSavedMask := GetExceptionMask;
  SetExceptionMask(LSavedMask + [exInvalidOp, exDenormalized,
    exZeroDivide, exOverflow, exUnderflow, exPrecision]);
  try
    LResult := FGenerate(AHandle, PAnsiChar(LPrompt), AMaxTokens,
      Single(ATemperature), ATopK, Single(ATopP), ASeed);
  finally
    ClearExceptions(False);
    SetExceptionMask(LSavedMask);
  end;

  if not Assigned(LResult) then
  begin
    FLastError := HandleLastError(AHandle);
    if FLastError = '' then
      FLastError := 'The llama.cpp bridge could not generate text.';
    Exit;
  end;
  AText := string(AnsiString(LResult));
  Result := True;
end;

function TAILlamaCppAPI.GenerateStream(AHandle: TAILlamaNativeHandle;
  const APrompt: string; AMaxTokens: Integer; ATemperature: Double;
  ATopK: Integer; ATopP: Double; ASeed: Integer;
  ACallback: TAILlamaTokenCallback; AUserData: Pointer): Boolean;
var
  LPrompt: UTF8String;
  LSavedMask: TFPUExceptionMask;
begin
  Result := False;
  FLastError := '';
  if not Assigned(AHandle) then
  begin
    FLastError := 'Invalid llama.cpp native handle.';
    Exit;
  end;
  if not Assigned(ACallback) then
  begin
    FLastError := 'The token callback is not assigned.';
    Exit;
  end;
  if not Assigned(FGenerateStream) then
  begin
    FLastError := 'The llama.cpp streaming function is unavailable.';
    Exit;
  end;

  LPrompt := UTF8Encode(APrompt);
  LSavedMask := GetExceptionMask;
  SetExceptionMask(LSavedMask + [exInvalidOp, exDenormalized,
    exZeroDivide, exOverflow, exUnderflow, exPrecision]);
  try
    Result := FGenerateStream(AHandle, PAnsiChar(LPrompt), AMaxTokens,
      Single(ATemperature), ATopK, Single(ATopP), ASeed, ACallback,
      AUserData) <> 0;
  finally
    ClearExceptions(False);
    SetExceptionMask(LSavedMask);
  end;

  if not Result then
  begin
    FLastError := HandleLastError(AHandle);
    if FLastError = '' then
      FLastError := 'The llama.cpp bridge could not stream text.';
  end;
end;

procedure TAILlamaCppAPI.Abort(AHandle: TAILlamaNativeHandle);
begin
  if Assigned(AHandle) and Assigned(FAbort) then
    FAbort(AHandle);
end;

function TAILlamaCppAPI.LoRAApply(AHandle: TAILlamaNativeHandle;
  const AAdapterFile: string; AScale: Double): Boolean;
var
  LAdapterFile: UTF8String;
  LSavedMask: TFPUExceptionMask;
begin
  Result := False;
  FLastError := '';
  if not Assigned(AHandle) then
  begin
    FLastError := 'Invalid llama.cpp native handle.';
    Exit;
  end;
  if not Assigned(FLoRAApply) then
  begin
    FLastError := 'The llama.cpp LoRA apply function is unavailable.';
    Exit;
  end;
  LAdapterFile := UTF8Encode(AAdapterFile);
  LSavedMask := GetExceptionMask;
  SetExceptionMask(LSavedMask + [exInvalidOp, exDenormalized,
    exZeroDivide, exOverflow, exUnderflow, exPrecision]);
  try
    Result := FLoRAApply(AHandle, PAnsiChar(LAdapterFile),
      Single(AScale)) <> 0;
  finally
    ClearExceptions(False);
    SetExceptionMask(LSavedMask);
  end;
  if not Result then
  begin
    FLastError := HandleLastError(AHandle);
    if FLastError = '' then
      FLastError := 'The llama.cpp bridge could not apply the LoRA adapter.';
  end;
end;

function TAILlamaCppAPI.LoRARemove(
  AHandle: TAILlamaNativeHandle): Boolean;
var
  LSavedMask: TFPUExceptionMask;
begin
  Result := False;
  FLastError := '';
  if not Assigned(AHandle) then
  begin
    FLastError := 'Invalid llama.cpp native handle.';
    Exit;
  end;
  if not Assigned(FLoRARemove) then
  begin
    FLastError := 'The llama.cpp LoRA remove function is unavailable.';
    Exit;
  end;
  LSavedMask := GetExceptionMask;
  SetExceptionMask(LSavedMask + [exInvalidOp, exDenormalized,
    exZeroDivide, exOverflow, exUnderflow, exPrecision]);
  try
    Result := FLoRARemove(AHandle) <> 0;
  finally
    ClearExceptions(False);
    SetExceptionMask(LSavedMask);
  end;
  if not Result then
  begin
    FLastError := HandleLastError(AHandle);
    if FLastError = '' then
      FLastError := 'The llama.cpp bridge could not remove the LoRA adapter.';
  end;
end;

destructor TAILlamaCppAPI.Destroy;
begin
  Unload;
  FLoader.Free;
  inherited Destroy;
end;

end.
