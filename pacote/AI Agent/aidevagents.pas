unit aidevagents;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, StrUtils, fphttpclient, opensslsockets, LResources,
  aibase, aiunifiedllm, aiprocessrunner;

type
  TAISourceAgent = class(TAIBaseComponent)
  private
    FLLM: TAIUnifiedLLM;
    FRootDirectory: string;
    FAllowWrite: Boolean;
    FCreateBackup: Boolean;
    FBackupExtension: string;
    FLastBackupFile: string;
    procedure SetLLM(AValue: TAIUnifiedLLM);
    function ResolveFile(const AFileName: string; out AResolved: string): Boolean;
    function ReadTextFile(const AFileName: string; out AText: string): Boolean;
    function StripCodeFence(const AText: string): string;
    function CopyFileSafe(const ASource, ADest: string): Boolean;
  protected
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
  public
    constructor Create(AOwner: TComponent); override;
    function AnalyzeFile(const AFileName, AInstruction: string): Boolean;
    function RewriteFile(const AFileName, AInstruction: string): Boolean;
    function RestoreBackup(const AFileName: string): Boolean;
    property LastBackupFile: string read FLastBackupFile;
  published
    property LLM: TAIUnifiedLLM read FLLM write SetLLM;
    property RootDirectory: string read FRootDirectory write FRootDirectory;
    property AllowWrite: Boolean read FAllowWrite write FAllowWrite default False;
    property CreateBackup: Boolean read FCreateBackup write FCreateBackup default True;
    property BackupExtension: string read FBackupExtension write FBackupExtension;
  end;

  TAILazarusBuildAgent = class(TAIBaseComponent)
  private
    FRunner: TAIProcessRunner;
    FLazBuildPath: string;
    FProjectFile: string;
    FBuildMode: string;
    FWorkingDirectory: string;
    FTimeoutMs: Integer;
    function GetStdOutText: string;
    function GetStdErrText: string;
    function GetExitCode: Integer;
  public
    constructor Create(AOwner: TComponent); override;
    function Build: Boolean;
    procedure Stop;
    property StdOutText: string read GetStdOutText;
    property StdErrText: string read GetStdErrText;
    property ExitCode: Integer read GetExitCode;
  published
    property LazBuildPath: string read FLazBuildPath write FLazBuildPath;
    property ProjectFile: string read FProjectFile write FProjectFile;
    property BuildMode: string read FBuildMode write FBuildMode;
    property WorkingDirectory: string read FWorkingDirectory write FWorkingDirectory;
    property TimeoutMs: Integer read FTimeoutMs write FTimeoutMs default 300000;
  end;

  TAITestAgent = class(TAIBaseComponent)
  private
    FRunner: TAIProcessRunner;
    FExecutable: string;
    FWorkingDirectory: string;
    FArguments: string;
    FTimeoutMs: Integer;
    function SplitArguments(const S: string): TStringList;
    function GetStdOutText: string;
    function GetStdErrText: string;
    function GetExitCode: Integer;
  public
    constructor Create(AOwner: TComponent); override;
    function Run: Boolean;
    procedure Stop;
    property StdOutText: string read GetStdOutText;
    property StdErrText: string read GetStdErrText;
    property ExitCode: Integer read GetExitCode;
  published
    property Executable: string read FExecutable write FExecutable;
    property WorkingDirectory: string read FWorkingDirectory write FWorkingDirectory;
    property Arguments: string read FArguments write FArguments;
    property TimeoutMs: Integer read FTimeoutMs write FTimeoutMs default 120000;
  end;

  TAINetworkAgent = class(TAIBaseComponent)
  private
    FRunner: TAIProcessRunner;
    FTimeoutMs: Integer;
    FHTTPTimeoutMs: Integer;
  public
    constructor Create(AOwner: TComponent); override;
    function PingHost(const AHost: string; ACount: Integer = 1): Boolean;
    function HTTPGet(const AURL: string): Boolean;
    procedure Stop;
  published
    property TimeoutMs: Integer read FTimeoutMs write FTimeoutMs default 10000;
    property HTTPTimeoutMs: Integer read FHTTPTimeoutMs write FHTTPTimeoutMs default 15000;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('AI Agents', [TAISourceAgent, TAILazarusBuildAgent,
    TAITestAgent, TAINetworkAgent]);
end;

function IsPathInsideRoot(const ARoot, AFileName: string): Boolean;
var
  RootPath, FilePath: string;
begin
  RootPath := IncludeTrailingPathDelimiter(ExpandFileName(ARoot));
  FilePath := ExpandFileName(AFileName);
  {$IFDEF WINDOWS}
  Result := AnsiStartsText(RootPath, FilePath);
  {$ELSE}
  Result := AnsiStartsStr(RootPath, FilePath);
  {$ENDIF}
end;

{ TAISourceAgent }

constructor TAISourceAgent.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FCategory := ccAction;
  FRootDirectory := GetCurrentDir;
  FAllowWrite := False;
  FCreateBackup := True;
  FBackupExtension := '.ai.bak';
end;

procedure TAISourceAgent.SetLLM(AValue: TAIUnifiedLLM);
begin
  if FLLM = AValue then Exit;
  if Assigned(FLLM) then FLLM.RemoveFreeNotification(Self);
  FLLM := AValue;
  if Assigned(FLLM) then FLLM.FreeNotification(Self);
end;

procedure TAISourceAgent.Notification(AComponent: TComponent; Operation: TOperation);
begin
  inherited Notification(AComponent, Operation);
  if (Operation = opRemove) and (AComponent = FLLM) then FLLM := nil;
end;

function TAISourceAgent.ResolveFile(const AFileName: string;
  out AResolved: string): Boolean;
begin
  ClearError;
  AResolved := '';
  if Trim(FRootDirectory) = '' then
  begin
    SetError('RootDirectory nao configurado.');
    Exit(False);
  end;
  if ExtractFilePath(AFileName) = '' then
    AResolved := ExpandFileName(IncludeTrailingPathDelimiter(FRootDirectory) + AFileName)
  else
    AResolved := ExpandFileName(AFileName);
  Result := IsPathInsideRoot(FRootDirectory, AResolved);
  if not Result then SetError('Arquivo fora de RootDirectory: ' + AResolved);
end;

function TAISourceAgent.ReadTextFile(const AFileName: string;
  out AText: string): Boolean;
var
  S: TStringList;
begin
  Result := False;
  AText := '';
  if not FileExists(AFileName) then
  begin
    SetError('Arquivo nao encontrado: ' + AFileName);
    Exit;
  end;
  S := TStringList.Create;
  try
    try
      S.LoadFromFile(AFileName);
      AText := S.Text;
      Result := True;
    except
      on E: Exception do SetError(E.Message);
    end;
  finally
    S.Free;
  end;
end;

function TAISourceAgent.CopyFileSafe(const ASource, ADest: string): Boolean;
var
  SourceStream, DestStream: TFileStream;
begin
  Result := False;
  try
    SourceStream := TFileStream.Create(ASource, fmOpenRead or fmShareDenyWrite);
    try
      DestStream := TFileStream.Create(ADest, fmCreate);
      try
        DestStream.CopyFrom(SourceStream, 0);
        Result := True;
      finally
        DestStream.Free;
      end;
    finally
      SourceStream.Free;
    end;
  except
    Result := False;
  end;
end;

function TAISourceAgent.StripCodeFence(const AText: string): string;
var
  S: string;
  P: SizeInt;
begin
  S := Trim(AText);
  if Pos('```', S) <> 1 then Exit(AText);
  P := Pos(LineEnding, S);
  if P > 0 then Delete(S, 1, P + Length(LineEnding) - 1);
  S := TrimRight(S);
  if RightStr(S, 3) = '```' then Delete(S, Length(S) - 2, 3);
  Result := S;
end;

function TAISourceAgent.AnalyzeFile(const AFileName, AInstruction: string): Boolean;
var
  FileName, Source, PromptText: string;
begin
  Result := False;
  if FLLM = nil then
  begin
    SetError('LLM nao configurado.');
    Exit;
  end;
  if not ResolveFile(AFileName, FileName) then Exit;
  if not ReadTextFile(FileName, Source) then Exit;
  PromptText := 'Analise o fonte Lazarus/Free Pascal abaixo conforme a orientacao. ' +
    'Nao altere o arquivo. Responda com problemas, riscos e correcoes sugeridas.' +
    LineEnding + 'ORIENTACAO:' + LineEnding + AInstruction + LineEnding +
    'ARQUIVO: ' + FileName + LineEnding + 'FONTE:' + LineEnding + Source;
  Result := FLLM.Ask(PromptText);
  if Result then
  begin
    FLastResult := FLLM.LastResult;
    FLastSuccess := True;
  end
  else
    SetError(FLLM.LastError);
end;

function TAISourceAgent.RewriteFile(const AFileName, AInstruction: string): Boolean;
var
  FileName, Source, PromptText, NewSource, BackupName: string;
  S: TStringList;
begin
  Result := False;
  FLastBackupFile := '';
  if not FAllowWrite then
  begin
    SetError('AllowWrite=False. Escrita bloqueada.');
    Exit;
  end;
  if FLLM = nil then
  begin
    SetError('LLM nao configurado.');
    Exit;
  end;
  if not ResolveFile(AFileName, FileName) then Exit;
  if not ReadTextFile(FileName, Source) then Exit;

  PromptText := 'Reescreva o arquivo Lazarus/Free Pascal conforme a orientacao. ' +
    'Preserve compatibilidade e todo codigo nao relacionado. Retorne SOMENTE o fonte completo, sem markdown.' +
    LineEnding + 'ORIENTACAO:' + LineEnding + AInstruction + LineEnding +
    'ARQUIVO: ' + FileName + LineEnding + 'FONTE ATUAL:' + LineEnding + Source;
  if not FLLM.Ask(PromptText) then
  begin
    SetError(FLLM.LastError);
    Exit;
  end;

  NewSource := StripCodeFence(FLLM.LastResult);
  if Trim(NewSource) = '' then
  begin
    SetError('LLM retornou fonte vazio.');
    Exit;
  end;

  if FCreateBackup then
  begin
    BackupName := FileName + FBackupExtension;
    if FileExists(BackupName) and (not DeleteFile(BackupName)) then
    begin
      SetError('Nao foi possivel substituir backup: ' + BackupName);
      Exit;
    end;
    if not CopyFileSafe(FileName, BackupName) then
    begin
      SetError('Nao foi possivel criar backup: ' + BackupName);
      Exit;
    end;
    FLastBackupFile := BackupName;
  end;

  S := TStringList.Create;
  try
    try
      S.Text := NewSource;
      S.SaveToFile(FileName);
      Result := True;
      FLastSuccess := True;
      FLastResult := FileName;
    except
      on E: Exception do SetError('Falha ao salvar fonte: ' + E.Message);
    end;
  finally
    S.Free;
  end;
end;

function TAISourceAgent.RestoreBackup(const AFileName: string): Boolean;
var
  FileName, BackupName: string;
begin
  Result := False;
  if not FAllowWrite then
  begin
    SetError('AllowWrite=False. Escrita bloqueada.');
    Exit;
  end;
  if not ResolveFile(AFileName, FileName) then Exit;
  BackupName := FileName + FBackupExtension;
  if not FileExists(BackupName) then
  begin
    SetError('Backup nao encontrado: ' + BackupName);
    Exit;
  end;
  Result := CopyFileSafe(BackupName, FileName);
  if Result then
  begin
    FLastSuccess := True;
    FLastResult := FileName;
  end
  else
    SetError('Falha ao restaurar backup.');
end;

{ TAILazarusBuildAgent }

constructor TAILazarusBuildAgent.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FCategory := ccAction;
  FLazBuildPath := 'lazbuild';
  FTimeoutMs := 300000;
  FRunner := TAIProcessRunner.Create(Self);
end;

function TAILazarusBuildAgent.GetStdOutText: string;
begin
  Result := FRunner.StdOutText;
end;

function TAILazarusBuildAgent.GetStdErrText: string;
begin
  Result := FRunner.StdErrText;
end;

function TAILazarusBuildAgent.GetExitCode: Integer;
begin
  Result := FRunner.LastExitCode;
end;

function TAILazarusBuildAgent.Build: Boolean;
var
  Params: array of string;
  ProjectPath: string;
begin
  ClearError;
  if Trim(FProjectFile) = '' then
  begin
    SetError('ProjectFile nao configurado.');
    Exit(False);
  end;
  ProjectPath := ExpandFileName(FProjectFile);
  FRunner.Executable := FLazBuildPath;
  FRunner.WorkingDirectory := FWorkingDirectory;
  if FRunner.WorkingDirectory = '' then
    FRunner.WorkingDirectory := ExtractFileDir(ProjectPath);
  FRunner.TimeoutMs := FTimeoutMs;
  if Trim(FBuildMode) <> '' then
  begin
    SetLength(Params, 2);
    Params[0] := '--build-mode=' + FBuildMode;
    Params[1] := ProjectPath;
  end
  else
  begin
    SetLength(Params, 1);
    Params[0] := ProjectPath;
  end;
  Result := FRunner.Execute(Params);
  FLastSuccess := Result;
  FLastResult := FRunner.StdOutText;
  if not Result then SetError(FRunner.LastError);
end;

procedure TAILazarusBuildAgent.Stop;
begin
  FRunner.Stop;
end;

{ TAITestAgent }

constructor TAITestAgent.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FCategory := ccAction;
  FTimeoutMs := 120000;
  FRunner := TAIProcessRunner.Create(Self);
end;

function TAITestAgent.GetStdOutText: string;
begin
  Result := FRunner.StdOutText;
end;

function TAITestAgent.GetStdErrText: string;
begin
  Result := FRunner.StdErrText;
end;

function TAITestAgent.GetExitCode: Integer;
begin
  Result := FRunner.LastExitCode;
end;

function TAITestAgent.SplitArguments(const S: string): TStringList;
var
  I: Integer;
  C, Quote: Char;
  Token: string;
begin
  Result := TStringList.Create;
  Token := '';
  Quote := #0;
  for I := 1 to Length(S) do
  begin
    C := S[I];
    if Quote <> #0 then
    begin
      if C = Quote then Quote := #0 else Token := Token + C;
    end
    else if (C = '"') or (C = #39) then
      Quote := C
    else if C in [' ', #9] then
    begin
      if Token <> '' then
      begin
        Result.Add(Token);
        Token := '';
      end;
    end
    else
      Token := Token + C;
  end;
  if Token <> '' then Result.Add(Token);
end;

function TAITestAgent.Run: Boolean;
var
  Args: TStringList;
  Params: array of string;
  I: Integer;
begin
  ClearError;
  if Trim(FExecutable) = '' then
  begin
    SetError('Executable nao configurado.');
    Exit(False);
  end;
  FRunner.Executable := FExecutable;
  FRunner.WorkingDirectory := FWorkingDirectory;
  FRunner.TimeoutMs := FTimeoutMs;
  Args := SplitArguments(FArguments);
  try
    SetLength(Params, Args.Count);
    for I := 0 to Args.Count - 1 do Params[I] := Args[I];
    Result := FRunner.Execute(Params);
  finally
    Args.Free;
  end;
  FLastSuccess := Result;
  FLastResult := FRunner.StdOutText;
  if not Result then SetError(FRunner.LastError);
end;

procedure TAITestAgent.Stop;
begin
  FRunner.Stop;
end;

{ TAINetworkAgent }

constructor TAINetworkAgent.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FCategory := ccAction;
  FTimeoutMs := 10000;
  FHTTPTimeoutMs := 15000;
  FRunner := TAIProcessRunner.Create(Self);
end;

function TAINetworkAgent.PingHost(const AHost: string; ACount: Integer): Boolean;
var
  Params: array of string;
begin
  ClearError;
  if Trim(AHost) = '' then
  begin
    SetError('Host vazio.');
    Exit(False);
  end;
  if ACount < 1 then ACount := 1;
  FRunner.Executable := 'ping';
  FRunner.TimeoutMs := FTimeoutMs;
  SetLength(Params, 3);
  {$IFDEF WINDOWS}
  Params[0] := '-n';
  {$ELSE}
  Params[0] := '-c';
  {$ENDIF}
  Params[1] := IntToStr(ACount);
  Params[2] := AHost;
  Result := FRunner.Execute(Params);
  FLastSuccess := Result;
  FLastResult := FRunner.StdOutText;
  if not Result then SetError(FRunner.LastError);
end;

function TAINetworkAgent.HTTPGet(const AURL: string): Boolean;
var
  HTTP: TFPHttpClient;
begin
  ClearError;
  Result := False;
  HTTP := TFPHttpClient.Create(nil);
  try
    HTTP.ConnectTimeout := FHTTPTimeoutMs;
    HTTP.IOTimeout := FHTTPTimeoutMs;
    try
      FLastResult := HTTP.Get(AURL);
      Result := True;
      FLastSuccess := True;
    except
      on E: Exception do SetError(E.Message);
    end;
  finally
    HTTP.Free;
  end;
end;

procedure TAINetworkAgent.Stop;
begin
  FRunner.Stop;
end;

initialization
  {$I aidevagents_icon.lrs}

end.
