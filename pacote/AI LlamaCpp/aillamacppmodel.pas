unit aillamacppmodel;

{$mode ObjFPC}{$H+}

interface

uses
  Classes,
  SysUtils,
  aibase,
  aillamacppruntime,
  aillamacppapi;

type
  TAILlamaCppModel = class(TAIBaseComponent)
  private
    FRuntime: TAILlamaCppRuntime;
    FModelFile: string;
    FContextSize: Integer;
    FThreads: Integer;
    FBatchSize: Integer;
    FValid: Boolean;
    FNativeHandle: TAILlamaNativeHandle;
    FAPI: TAILlamaCppAPI;
    FLoaded: Boolean;
    procedure SetRuntime(AValue: TAILlamaCppRuntime);
    procedure SetModelFile(const AValue: string);
  protected
    procedure Notification(AComponent: TComponent;
      Operation: TOperation); override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    function ValidateModelFile: Boolean;
    function Load: Boolean;
    procedure Unload;
    function GenerateNative(const APrompt: string; AMaxTokens: Integer;
      ATemperature: Double; ATopK: Integer; ATopP: Double; ASeed: Integer;
      out AText: string): Boolean;
    function GenerateStreamNative(const APrompt: string; AMaxTokens: Integer;
      ATemperature: Double; ATopK: Integer; ATopP: Double; ASeed: Integer;
      ACallback: TAILlamaTokenCallback; AUserData: Pointer): Boolean;
    procedure AbortNative;
    function ApplyLoRA(const AAdapterFile: string; AScale: Double): Boolean;
    function RemoveLoRA: Boolean;
    property NativeHandle: TAILlamaNativeHandle read FNativeHandle;
  published
    property Runtime: TAILlamaCppRuntime read FRuntime write SetRuntime;
    property ModelFile: string read FModelFile write SetModelFile;
    property ContextSize: Integer read FContextSize write FContextSize
      default 2048;
    property Threads: Integer read FThreads write FThreads default 0;
    property BatchSize: Integer read FBatchSize write FBatchSize default 0;
    property Valid: Boolean read FValid;
    property Loaded: Boolean read FLoaded;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('AI LlamaCpp', [TAILlamaCppModel]);
end;

constructor TAILlamaCppModel.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FContextSize := 2048;
  FThreads := 0;
  FBatchSize := 0;
  FValid := False;
  FNativeHandle := nil;
  FAPI := TAILlamaCppAPI.Create;
  FLoaded := False;
end;

procedure TAILlamaCppModel.SetRuntime(AValue: TAILlamaCppRuntime);
begin
  if FRuntime = AValue then
    Exit;
  if Assigned(FRuntime) then
    FRuntime.RemoveFreeNotification(Self);
  FRuntime := AValue;
  if Assigned(FRuntime) then
    FRuntime.FreeNotification(Self);
end;

procedure TAILlamaCppModel.Notification(AComponent: TComponent;
  Operation: TOperation);
begin
  inherited Notification(AComponent, Operation);
  if (Operation = opRemove) and (AComponent = FRuntime) then
    FRuntime := nil;
end;

procedure TAILlamaCppModel.SetModelFile(const AValue: string);
begin
  if FModelFile = AValue then
    Exit;
  FModelFile := AValue;
  FValid := False;
end;

function TAILlamaCppModel.ValidateModelFile: Boolean;
begin
  FValid := False;
  Result := False;
  if Trim(FModelFile) = '' then
  begin
    SetError('ModelFile is empty. Select a GGUF model file.');
    Exit;
  end;
  if not FileExists(FModelFile) then
  begin
    SetError('GGUF model file was not found: ' + FModelFile);
    Exit;
  end;
  if LowerCase(ExtractFileExt(FModelFile)) <> '.gguf' then
  begin
    SetError('Invalid model file extension. Expected .gguf: ' + FModelFile);
    Exit;
  end;
  ClearError;
  FValid := True;
  Result := True;
end;

function TAILlamaCppModel.Load: Boolean;
begin
  Result := False;
  if Assigned(FNativeHandle) then
    Exit(True);
  if not ValidateModelFile then
    Exit;
  if not Assigned(FRuntime) then
  begin
    SetError('Runtime is not assigned.');
    Exit;
  end;
  if not FRuntime.ValidateLibraries then
  begin
    SetError(FRuntime.LastRuntimeError);
    Exit;
  end;
  if not FAPI.Load(FRuntime.LibraryPath) then
  begin
    SetError(FAPI.LastError);
    Exit;
  end;
  if not FAPI.Initialize then
  begin
    SetError(FAPI.LastError);
    Exit;
  end;

  FNativeHandle := FAPI.CreateHandle;
  if not Assigned(FNativeHandle) then
  begin
    SetError(FAPI.LastError);
    Exit;
  end;
  if not FAPI.ModelLoad(FNativeHandle, FModelFile, FContextSize,
    FThreads) then
  begin
    SetError(FAPI.LastError);
    FAPI.DestroyHandle(FNativeHandle);
    FNativeHandle := nil;
    Exit;
  end;

  ClearError;
  FLoaded := True;
  Log(llInfo, 'GGUF model loaded through the native llama.cpp bridge.');
  Result := True;
end;

procedure TAILlamaCppModel.Unload;
begin
  if Assigned(FNativeHandle) then
  begin
    FAPI.ModelUnload(FNativeHandle);
    FAPI.DestroyHandle(FNativeHandle);
    FNativeHandle := nil;
    Log(llInfo, 'GGUF model unloaded from the native llama.cpp bridge.');
  end;
  FLoaded := False;
end;

function TAILlamaCppModel.GenerateNative(const APrompt: string;
  AMaxTokens: Integer; ATemperature: Double; ATopK: Integer; ATopP: Double;
  ASeed: Integer; out AText: string): Boolean;
begin
  AText := '';
  if not FLoaded then
  begin
    SetError('The GGUF model is not loaded.');
    Exit(False);
  end;
  Result := FAPI.Generate(FNativeHandle, APrompt, AMaxTokens,
    ATemperature, ATopK, ATopP, ASeed, AText);
  if not Result then
    SetError(FAPI.LastError)
  else
    ClearError;
end;

function TAILlamaCppModel.GenerateStreamNative(const APrompt: string;
  AMaxTokens: Integer; ATemperature: Double; ATopK: Integer; ATopP: Double;
  ASeed: Integer; ACallback: TAILlamaTokenCallback;
  AUserData: Pointer): Boolean;
begin
  if not FLoaded then
  begin
    SetError('The GGUF model is not loaded.');
    Exit(False);
  end;
  Result := FAPI.GenerateStream(FNativeHandle, APrompt, AMaxTokens,
    ATemperature, ATopK, ATopP, ASeed, ACallback, AUserData);
  if not Result then
    SetError(FAPI.LastError)
  else
    ClearError;
end;

procedure TAILlamaCppModel.AbortNative;
begin
  if Assigned(FNativeHandle) then
    FAPI.Abort(FNativeHandle);
end;

function TAILlamaCppModel.ApplyLoRA(const AAdapterFile: string;
  AScale: Double): Boolean;
begin
  if not FLoaded then
  begin
    SetError('The GGUF model is not loaded.');
    Exit(False);
  end;
  Result := FAPI.LoRAApply(FNativeHandle, AAdapterFile, AScale);
  if not Result then
    SetError(FAPI.LastError)
  else
    ClearError;
end;

function TAILlamaCppModel.RemoveLoRA: Boolean;
begin
  if not FLoaded then
  begin
    SetError('The GGUF model is not loaded.');
    Exit(False);
  end;
  Result := FAPI.LoRARemove(FNativeHandle);
  if not Result then
    SetError(FAPI.LastError)
  else
    ClearError;
end;

destructor TAILlamaCppModel.Destroy;
begin
  Unload;
  FAPI.Free;
  inherited Destroy;
end;

end.
