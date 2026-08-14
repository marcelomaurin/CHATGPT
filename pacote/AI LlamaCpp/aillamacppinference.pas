unit aillamacppinference;

{$mode ObjFPC}{$H+}

interface

uses
  Classes,
  SysUtils,
  aibase,
  aillamacppapi,
  aillamacppmodel,
  aillamacpptypes, LResources;

type
  TAILlamaTokenEvent = procedure(Sender: TObject;
    const Token: string) of object;
  TAILlamaInferenceErrorEvent = procedure(Sender: TObject;
    const ErrorMessage: string) of object;

  TAILlamaGenerationThread = class;

  TAILlamaCppInference = class(TAIBaseComponent)
  private
    FModel: TAILlamaCppModel;
    FAccessMode: TAILlamaAccessMode;
    FMaxTokens: Integer;
    FTemperature: Double;
    FTopK: Integer;
    FTopP: Double;
    FSeed: Integer;
    FOnToken: TAILlamaTokenEvent;
    FOnStart: TNotifyEvent;
    FOnFinish: TNotifyEvent;
    FOnError: TAILlamaInferenceErrorEvent;
    FGenerationThread: TAILlamaGenerationThread;
    procedure SetModel(AValue: TAILlamaCppModel);
    function GetGenerationRunning: Boolean;
    procedure HandleQueuedToken(const AToken: string);
    procedure HandleThreadFinished(AThread: TAILlamaGenerationThread);
  protected
    procedure Notification(AComponent: TComponent;
      Operation: TOperation); override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    function Generate: Boolean; overload;
    function Generate(const APrompt: string): Boolean; overload;
    function GenerateAsync: Boolean; overload;
    function GenerateAsync(const APrompt: string): Boolean; overload;
    procedure Cancel;
    property GenerationRunning: Boolean read GetGenerationRunning;
  published
    property Model: TAILlamaCppModel read FModel write SetModel;
    property AccessMode: TAILlamaAccessMode read FAccessMode write FAccessMode
      default llamServer;
    property MaxTokens: Integer read FMaxTokens write FMaxTokens default 128;
    property Temperature: Double read FTemperature write FTemperature;
    property TopK: Integer read FTopK write FTopK default 40;
    property TopP: Double read FTopP write FTopP;
    property Seed: Integer read FSeed write FSeed default -1;
    property OnToken: TAILlamaTokenEvent read FOnToken write FOnToken;
    property OnStart: TNotifyEvent read FOnStart write FOnStart;
    property OnFinish: TNotifyEvent read FOnFinish write FOnFinish;
    property OnError: TAILlamaInferenceErrorEvent read FOnError write FOnError;
  end;

  TAILlamaGenerationThread = class(TThread)
  private
    FInference: TAILlamaCppInference;
    FPrompt: string;
    FResultText: string;
    FErrorText: string;
    FPendingTokens: TStringList;
    FTokenLock: TRTLCriticalSection;
    FTokenQueueScheduled: Boolean;
    FCancelled: Boolean;
    procedure DispatchPendingTokens;
    procedure DispatchCompletion;
  protected
    procedure Execute; override;
  public
    constructor Create(AInference: TAILlamaCppInference;
      const APrompt: string);
    destructor Destroy; override;
    procedure ReceiveToken(const AToken: string);
    property ResultText: string read FResultText;
    property ErrorText: string read FErrorText;
    property Cancelled: Boolean read FCancelled;
  end;

procedure Register;

implementation

procedure NativeTokenCallback(ATokenUTF8: PAnsiChar;
  AUserData: Pointer); cdecl;
begin
  if Assigned(AUserData) and Assigned(ATokenUTF8) then
    TAILlamaGenerationThread(AUserData).ReceiveToken(
      string(AnsiString(ATokenUTF8)));
end;

procedure Register;
begin
  RegisterComponents('AI LlamaCpp', [TAILlamaCppInference]);
end;

constructor TAILlamaCppInference.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  Category := ccAction;
  FAccessMode := llamServer;
  FMaxTokens := 128;
  FTemperature := 0.8;
  FTopK := 40;
  FTopP := 0.95;
  FSeed := -1;
end;

destructor TAILlamaCppInference.Destroy;
begin
  Cancel;
  if Assigned(FGenerationThread) then
  begin
    FGenerationThread.WaitFor;
    FGenerationThread.Free;
    FGenerationThread := nil;
  end;
  inherited Destroy;
end;

procedure TAILlamaCppInference.Cancel;
begin
  if Assigned(FGenerationThread) and not FGenerationThread.Finished then
  begin
    FGenerationThread.Terminate;
    if Assigned(FModel) then
      FModel.AbortNative;
  end;
end;

procedure TAILlamaCppInference.SetModel(AValue: TAILlamaCppModel);
begin
  if FModel = AValue then
    Exit;
  if Assigned(FModel) then
    FModel.RemoveFreeNotification(Self);
  FModel := AValue;
  if Assigned(FModel) then
    FModel.FreeNotification(Self);
end;

procedure TAILlamaCppInference.Notification(AComponent: TComponent;
  Operation: TOperation);
begin
  inherited Notification(AComponent, Operation);
  if (Operation = opRemove) and (AComponent = FModel) then
    FModel := nil;
end;

function TAILlamaCppInference.Generate: Boolean;
begin
  Result := Generate(Prompt);
end;

function TAILlamaCppInference.Generate(const APrompt: string): Boolean;
var
  LText: string;
begin
  Result := False;
  FLastResult := '';
  if FAccessMode <> llamNative then
  begin
    SetError('AccessMode Server requires an HTTP client configuration. ' +
      'Select Native for direct GGUF inference.');
    Exit;
  end;
  if not Assigned(FModel) then
  begin
    SetError('Model is not assigned.');
    Exit;
  end;
  if Trim(APrompt) = '' then
  begin
    SetError('Prompt is empty.');
    Exit;
  end;
  if FMaxTokens <= 0 then
  begin
    SetError('MaxTokens must be greater than zero.');
    Exit;
  end;
  if FTemperature < 0 then
  begin
    SetError('Temperature cannot be negative.');
    Exit;
  end;
  if FTopK < 0 then
  begin
    SetError('TopK cannot be negative.');
    Exit;
  end;
  if (FTopP < 0) or (FTopP > 1) then
  begin
    SetError('TopP must be between zero and one.');
    Exit;
  end;

  if not FModel.Loaded and not FModel.Load then
  begin
    SetError(FModel.LastError);
    Exit;
  end;
  Log(llInfo, 'Starting synchronous native llama.cpp generation.');
  if not FModel.GenerateNative(APrompt, FMaxTokens, FTemperature,
    FTopK, FTopP, FSeed, LText) then
  begin
    SetError(FModel.LastError);
    Exit;
  end;

  FLastResult := LText;
  ClearError;
  Log(llInfo, 'Synchronous native llama.cpp generation completed.');
  Result := True;
end;

function TAILlamaCppInference.GetGenerationRunning: Boolean;
begin
  Result := Assigned(FGenerationThread) and
    not FGenerationThread.Finished;
end;

procedure TAILlamaCppInference.HandleQueuedToken(const AToken: string);
begin
  if Assigned(FOnToken) then
    FOnToken(Self, AToken);
end;

procedure TAILlamaCppInference.HandleThreadFinished(
  AThread: TAILlamaGenerationThread);
begin
  if AThread <> FGenerationThread then
    Exit;
  if AThread.ErrorText <> '' then
  begin
    SetError(AThread.ErrorText);
    if Assigned(FOnError) then
      FOnError(Self, AThread.ErrorText);
    Exit;
  end;
  FLastResult := AThread.ResultText;
  ClearError;
  if Assigned(FOnFinish) then
    FOnFinish(Self);
end;

function TAILlamaCppInference.GenerateAsync: Boolean;
begin
  Result := GenerateAsync(Prompt);
end;

function TAILlamaCppInference.GenerateAsync(
  const APrompt: string): Boolean;
begin
  Result := False;
  if Assigned(FGenerationThread) then
  begin
    if not FGenerationThread.Finished then
    begin
      SetError('A native generation is already running.');
      Exit;
    end;
    FGenerationThread.Free;
    FGenerationThread := nil;
  end;
  if FAccessMode <> llamNative then
  begin
    SetError('Select Native access mode before starting streaming.');
    Exit;
  end;
  if not Assigned(FModel) then
  begin
    SetError('Model is not assigned.');
    Exit;
  end;
  if Trim(APrompt) = '' then
  begin
    SetError('Prompt is empty.');
    Exit;
  end;
  if FMaxTokens <= 0 then
  begin
    SetError('MaxTokens must be greater than zero.');
    Exit;
  end;

  FLastResult := '';
  ClearError;
  FGenerationThread := TAILlamaGenerationThread.Create(Self, APrompt);
  if Assigned(FOnStart) then
    FOnStart(Self);
  FGenerationThread.Start;
  Result := True;
end;

constructor TAILlamaGenerationThread.Create(
  AInference: TAILlamaCppInference; const APrompt: string);
begin
  inherited Create(True);
  FreeOnTerminate := False;
  FInference := AInference;
  FPrompt := APrompt;
  FPendingTokens := TStringList.Create;
  InitCriticalSection(FTokenLock);
end;

procedure TAILlamaGenerationThread.ReceiveToken(const AToken: string);
var
  LSchedule: Boolean;
begin
  FResultText := FResultText + AToken;
  LSchedule := False;
  EnterCriticalSection(FTokenLock);
  try
    FPendingTokens.Add(AToken);
    if not FTokenQueueScheduled then
    begin
      FTokenQueueScheduled := True;
      LSchedule := True;
    end;
  finally
    LeaveCriticalSection(FTokenLock);
  end;
  if LSchedule then
    Queue(@DispatchPendingTokens);
end;

procedure TAILlamaGenerationThread.DispatchPendingTokens;
var
  I: Integer;
  LTokens: TStringList;
begin
  LTokens := TStringList.Create;
  try
    EnterCriticalSection(FTokenLock);
    try
      LTokens.Assign(FPendingTokens);
      FPendingTokens.Clear;
      FTokenQueueScheduled := False;
    finally
      LeaveCriticalSection(FTokenLock);
    end;
    for I := 0 to LTokens.Count - 1 do
      FInference.HandleQueuedToken(LTokens[I]);
  finally
    LTokens.Free;
  end;
end;

procedure TAILlamaGenerationThread.Execute;
begin
  try
    if Terminated then
    begin
      FCancelled := True;
      Exit;
    end;
    if not FInference.FModel.Loaded and not FInference.FModel.Load then
    begin
      FErrorText := FInference.FModel.LastError;
      Exit;
    end;
    if Terminated then
    begin
      FCancelled := True;
      Exit;
    end;
    if not FInference.FModel.GenerateStreamNative(FPrompt,
      FInference.FMaxTokens, FInference.FTemperature, FInference.FTopK,
      FInference.FTopP, FInference.FSeed, @NativeTokenCallback, Self) then
      FErrorText := FInference.FModel.LastError;
  finally
    FCancelled := Terminated;
    Queue(@DispatchCompletion);
  end;
end;

procedure TAILlamaGenerationThread.DispatchCompletion;
begin
  FInference.HandleThreadFinished(Self);
end;

destructor TAILlamaGenerationThread.Destroy;
begin
  TThread.RemoveQueuedEvents(Self);
  DoneCriticalSection(FTokenLock);
  FPendingTokens.Free;
  inherited Destroy;
end;

initialization
  {$I aillamacppinference_icon.lrs}

end.
