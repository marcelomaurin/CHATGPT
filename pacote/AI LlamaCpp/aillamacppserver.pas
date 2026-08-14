unit aillamacppserver;

{$mode ObjFPC}{$H+}

interface

uses
  Classes,
  ExtCtrls,
  fphttpclient,
  Process,
  SysUtils,
  aibase,
  chatgpt,
  aillamacppruntime,
  aillamacppmodel, LResources;

type
  TAILlamaServerErrorEvent = procedure(Sender: TObject;
    const Message: string) of object;

  TAILlamaCppServer = class(TAIBaseComponent)
  private
    FRuntime: TAILlamaCppRuntime;
    FModel: TAILlamaCppModel;
    FHost: string;
    FPort: Integer;
    FProcess: TProcess;
    FMonitorTimer: TTimer;
    FStdOutBuffer: string;
    FStdErrBuffer: string;
    FOnError: TAILlamaServerErrorEvent;
    FOnServerStarted: TNotifyEvent;
    FStartedNotified: Boolean;
    FOnServerStopped: TNotifyEvent;
    FStoppedNotified: Boolean;
    FStartupTimeout: Integer;
    FStartupStartedAt: QWord;
    FLastStartupProbeAt: QWord;
    procedure SetRuntime(AValue: TAILlamaCppRuntime);
    procedure SetModel(AValue: TAILlamaCppModel);
    function GetBaseURL: string;
    function GetRunning: Boolean;
    procedure MonitorTimer(Sender: TObject);
    procedure ReadStdOut;
    procedure ReadStdErr;
    procedure CheckServerStartedLine(const ALine: string);
    procedure NotifyServerStopped;
  protected
    procedure Notification(AComponent: TComponent;
      Operation: TOperation); override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure BuildParameters(AParameters: TStrings);
    function Start: Boolean;
    procedure Stop;
    function HealthCheck: Boolean;
    procedure ConfigureChatGPT(AChatGPT: TCHATGPT);
  published
    property Runtime: TAILlamaCppRuntime read FRuntime write SetRuntime;
    property Model: TAILlamaCppModel read FModel write SetModel;
    property Host: string read FHost write FHost;
    property Port: Integer read FPort write FPort default 8080;
    property BaseURL: string read GetBaseURL;
    property Running: Boolean read GetRunning;
    property OnError: TAILlamaServerErrorEvent read FOnError write FOnError;
    property OnServerStarted: TNotifyEvent read FOnServerStarted
      write FOnServerStarted;
    property OnServerStopped: TNotifyEvent read FOnServerStopped
      write FOnServerStopped;
    property StartupTimeout: Integer read FStartupTimeout
      write FStartupTimeout default 120000;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('AI LlamaCpp', [TAILlamaCppServer]);
end;

constructor TAILlamaCppServer.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FHost := '127.0.0.1';
  FPort := 8080;
  FStdOutBuffer := '';
  FStdErrBuffer := '';
  FStartedNotified := False;
  FStoppedNotified := False;
  FStartupTimeout := 120000;
  FStartupStartedAt := 0;
  FLastStartupProbeAt := 0;
  FMonitorTimer := TTimer.Create(Self);
  FMonitorTimer.Enabled := False;
  FMonitorTimer.Interval := 50;
  FMonitorTimer.OnTimer := @MonitorTimer;
end;

destructor TAILlamaCppServer.Destroy;
begin
  Stop;
  FreeAndNil(FMonitorTimer);
  inherited Destroy;
end;

procedure TAILlamaCppServer.BuildParameters(AParameters: TStrings);
begin
  if not Assigned(AParameters) then
    raise EArgumentNilException.Create('AParameters');
  AParameters.Clear;
  if Assigned(FModel) and (Trim(FModel.ModelFile) <> '') then
  begin
    AParameters.Add('-m');
    AParameters.Add(FModel.ModelFile);
  end;
  if Assigned(FModel) then
  begin
    AParameters.Add('-c');
    AParameters.Add(IntToStr(FModel.ContextSize));
  end;
  if Assigned(FModel) and (FModel.Threads > 0) then
  begin
    AParameters.Add('-t');
    AParameters.Add(IntToStr(FModel.Threads));
  end;
  AParameters.Add('--host');
  AParameters.Add(FHost);
  AParameters.Add('--port');
  AParameters.Add(IntToStr(FPort));
end;

function TAILlamaCppServer.Start: Boolean;
var
  I: Integer;
  LParameters: TStringList;
begin
  Result := False;
  if Assigned(FProcess) then
  begin
    SetError('llama-server process is already assigned.');
    Exit;
  end;
  if not Assigned(FRuntime) then
  begin
    SetError('Runtime is not assigned.');
    Exit;
  end;
  if not FRuntime.ValidateRuntime then
  begin
    SetError(FRuntime.LastRuntimeError);
    Exit;
  end;
  if not Assigned(FModel) then
  begin
    SetError('Model is not assigned.');
    Exit;
  end;
  if not FModel.ValidateModelFile then
  begin
    SetError(FModel.LastError);
    Exit;
  end;

  FStdOutBuffer := '';
  FStdErrBuffer := '';
  FStartedNotified := False;
  FStoppedNotified := False;
  FStartupStartedAt := GetTickCount64;
  FLastStartupProbeAt := 0;
  LParameters := TStringList.Create;
  try
    BuildParameters(LParameters);
    FProcess := TProcess.Create(nil);
    FProcess.Executable := FRuntime.GetServerPath;
    FProcess.CurrentDirectory := FRuntime.LibraryPath;
    FProcess.Options := [poUsePipes, poNoConsole];
    for I := 0 to LParameters.Count - 1 do
      FProcess.Parameters.Add(LParameters[I]);
    try
      FProcess.Execute;
    except
      on E: Exception do
      begin
        FreeAndNil(FProcess);
        SetError('Could not start llama-server: ' + E.Message);
        Exit;
      end;
    end;
  finally
    LParameters.Free;
  end;

  ClearError;
  FMonitorTimer.Enabled := True;
  Result := True;
end;

procedure TAILlamaCppServer.Stop;
begin
  if not Assigned(FProcess) then
    Exit;
  FMonitorTimer.Enabled := False;
  ReadStdOut;
  ReadStdErr;
  if FProcess.Running then
    FProcess.Terminate(0);
  FreeAndNil(FProcess);
  NotifyServerStopped;
end;

function TAILlamaCppServer.HealthCheck: Boolean;
var
  LClient: TFPHTTPClient;
begin
  Result := False;
  LClient := TFPHTTPClient.Create(nil);
  try
    LClient.ConnectTimeout := 1000;
    LClient.IOTimeout := 1000;
    try
      LClient.Get(BaseURL + '/health');
      Result := (LClient.ResponseStatusCode >= 200) and
        (LClient.ResponseStatusCode < 300);
    except
      on E: Exception do
      begin
        FLastError := 'llama-server health check failed: ' + E.Message;
        Exit;
      end;
    end;
    if Result then
      FLastError := '';
  finally
    LClient.Free;
  end;
end;

procedure TAILlamaCppServer.ConfigureChatGPT(AChatGPT: TCHATGPT);
begin
  if not Assigned(AChatGPT) then
    raise EArgumentNilException.Create('AChatGPT');
  AChatGPT.URL := BaseURL + '/v1/chat/completions';
end;

procedure TAILlamaCppServer.MonitorTimer(Sender: TObject);
var
  LNow: QWord;
  LTimeoutMessage: string;
begin
  ReadStdOut;
  ReadStdErr;
  if Assigned(FProcess) and FProcess.Running and not FStartedNotified then
  begin
    LNow := GetTickCount64;
    if (FLastStartupProbeAt = 0) or (LNow - FLastStartupProbeAt >= 250) then
    begin
      FLastStartupProbeAt := LNow;
      if HealthCheck then
      begin
        FStartedNotified := True;
        if Assigned(FOnServerStarted) then
          FOnServerStarted(Self);
      end;
    end;
    if not FStartedNotified and (FStartupTimeout > 0) and
      (LNow - FStartupStartedAt >= QWord(FStartupTimeout)) then
    begin
      LTimeoutMessage := 'llama-server startup timed out after ' +
        IntToStr(FStartupTimeout) + ' ms.';
      SetError(LTimeoutMessage);
      if Assigned(FOnError) then
        FOnError(Self, LTimeoutMessage);
      Stop;
      Exit;
    end;
  end;
  if Assigned(FProcess) and not FProcess.Running then
  begin
    FMonitorTimer.Enabled := False;
    if FStdOutBuffer <> '' then
    begin
      Log(llInfo, FStdOutBuffer);
      FStdOutBuffer := '';
    end;
    if FStdErrBuffer <> '' then
    begin
      if Assigned(FOnError) then
        FOnError(Self, FStdErrBuffer);
      FStdErrBuffer := '';
    end;
    NotifyServerStopped;
  end;
end;

procedure TAILlamaCppServer.ReadStdOut;
var
  LBytes: array[0..4095] of Byte;
  LChunk: string;
  LLine: string;
  LLineEnd: SizeInt;
  LRead: LongInt;
begin
  if not Assigned(FProcess) then
    Exit;
  while FProcess.Output.NumBytesAvailable > 0 do
  begin
    LRead := FProcess.Output.Read(LBytes, SizeOf(LBytes));
    if LRead <= 0 then
      Break;
    SetString(LChunk, PAnsiChar(@LBytes[0]), LRead);
    FStdOutBuffer := FStdOutBuffer + LChunk;
  end;

  LLineEnd := Pos(#10, FStdOutBuffer);
  while LLineEnd > 0 do
  begin
    LLine := Copy(FStdOutBuffer, 1, LLineEnd - 1);
    Delete(FStdOutBuffer, 1, LLineEnd);
    if (LLine <> '') and (LLine[Length(LLine)] = #13) then
      Delete(LLine, Length(LLine), 1);
    CheckServerStartedLine(LLine);
    Log(llInfo, LLine);
    LLineEnd := Pos(#10, FStdOutBuffer);
  end;
end;

procedure TAILlamaCppServer.ReadStdErr;
var
  LBytes: array[0..4095] of Byte;
  LChunk: string;
  LLine: string;
  LLineEnd: SizeInt;
  LRead: LongInt;
begin
  if not Assigned(FProcess) then
    Exit;
  while FProcess.Stderr.NumBytesAvailable > 0 do
  begin
    LRead := FProcess.Stderr.Read(LBytes, SizeOf(LBytes));
    if LRead <= 0 then
      Break;
    SetString(LChunk, PAnsiChar(@LBytes[0]), LRead);
    FStdErrBuffer := FStdErrBuffer + LChunk;
  end;

  LLineEnd := Pos(#10, FStdErrBuffer);
  while LLineEnd > 0 do
  begin
    LLine := Copy(FStdErrBuffer, 1, LLineEnd - 1);
    Delete(FStdErrBuffer, 1, LLineEnd);
    if (LLine <> '') and (LLine[Length(LLine)] = #13) then
      Delete(LLine, Length(LLine), 1);
    CheckServerStartedLine(LLine);
    if Assigned(FOnError) then
      FOnError(Self, LLine);
    LLineEnd := Pos(#10, FStdErrBuffer);
  end;
end;

procedure TAILlamaCppServer.CheckServerStartedLine(const ALine: string);
begin
  if FStartedNotified then
    Exit;
  if Pos('server is listening on', LowerCase(ALine)) = 0 then
    Exit;
  FStartedNotified := True;
  if Assigned(FOnServerStarted) then
    FOnServerStarted(Self);
end;

procedure TAILlamaCppServer.NotifyServerStopped;
begin
  if FStoppedNotified then
    Exit;
  FStoppedNotified := True;
  if Assigned(FOnServerStopped) then
    FOnServerStopped(Self);
end;

procedure TAILlamaCppServer.SetRuntime(AValue: TAILlamaCppRuntime);
begin
  if FRuntime = AValue then
    Exit;
  if Assigned(FRuntime) then
    FRuntime.RemoveFreeNotification(Self);
  FRuntime := AValue;
  if Assigned(FRuntime) then
    FRuntime.FreeNotification(Self);
end;

procedure TAILlamaCppServer.Notification(AComponent: TComponent;
  Operation: TOperation);
begin
  inherited Notification(AComponent, Operation);
  if (Operation = opRemove) and (AComponent = FRuntime) then
    FRuntime := nil;
  if (Operation = opRemove) and (AComponent = FModel) then
    FModel := nil;
end;

procedure TAILlamaCppServer.SetModel(AValue: TAILlamaCppModel);
begin
  if FModel = AValue then
    Exit;
  if Assigned(FModel) then
    FModel.RemoveFreeNotification(Self);
  FModel := AValue;
  if Assigned(FModel) then
    FModel.FreeNotification(Self);
end;

function TAILlamaCppServer.GetBaseURL: string;
begin
  Result := 'http://' + FHost + ':' + IntToStr(FPort);
end;

function TAILlamaCppServer.GetRunning: Boolean;
begin
  Result := Assigned(FProcess) and FProcess.Running;
end;

initialization
  {$I aillamacppserver_icon.lrs}

end.
