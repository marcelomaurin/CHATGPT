unit aiagent_sourceactions;

{$mode objfpc}{$H+}
{$codepage utf8}

interface

uses
  Classes, SysUtils, Process, aiagent_actions, LResources, LazFileUtils;

type
  TAIDeveloperWorkspaceAction = class(TAICustomAgentAction)
  private
    FWorkspaceRoot: string;
    FLastOutput: string;
    function NormalizeRoot: string;
  protected
    function ResolveWorkspacePath(const APath: string; out AFullPath,
      AError: string): Boolean;
    procedure SetOutput(const AValue: string);
  public
    property LastOutput: string read FLastOutput;
  published
    property WorkspaceRoot: string read FWorkspaceRoot write FWorkspaceRoot;
  end;

  TAISourceReadAction = class(TAIDeveloperWorkspaceAction)
  public
    constructor Create(AOwner: TComponent); override;
    function RunAction(const AParams: TStrings; ASimulate: Boolean): Boolean; override;
  end;

  TAISourceReplaceAction = class(TAIDeveloperWorkspaceAction)
  private
    FRequireUniqueMatch: Boolean;
    function CountOccurrences(const AText, ANeedle: string): Integer;
  public
    constructor Create(AOwner: TComponent); override;
    function RunAction(const AParams: TStrings; ASimulate: Boolean): Boolean; override;
  published
    property RequireUniqueMatch: Boolean read FRequireUniqueMatch
      write FRequireUniqueMatch default True;
  end;

  TAIProjectBuildAction = class(TAIDeveloperWorkspaceAction)
  private
    FBuilderExecutable: string;
    FProjectFile: string;
    FBuildArguments: string;
    FTimeoutMs: Integer;
  public
    constructor Create(AOwner: TComponent); override;
    function RunAction(const AParams: TStrings; ASimulate: Boolean): Boolean; override;
  published
    property BuilderExecutable: string read FBuilderExecutable write FBuilderExecutable;
    property ProjectFile: string read FProjectFile write FProjectFile;
    property BuildArguments: string read FBuildArguments write FBuildArguments;
    property TimeoutMs: Integer read FTimeoutMs write FTimeoutMs default 120000;
  end;

procedure Register;

implementation

function ParamValue(AParams: TStrings; const AName: string): string;
begin
  Result := '';
  if Assigned(AParams) then Result := AParams.Values[AName];
end;

procedure SplitArguments(const AText: string; AArgs: TStrings);
var
  I: Integer;
  C: Char;
  Token: string;
  Quoted: Boolean;
begin
  AArgs.Clear;
  Token := '';
  Quoted := False;
  for I := 1 to Length(AText) do
  begin
    C := AText[I];
    if C = '"' then Quoted := not Quoted
    else if (C in [' ', #9]) and not Quoted then
    begin
      if Token <> '' then
      begin
        AArgs.Add(Token);
        Token := '';
      end;
    end
    else Token := Token + C;
  end;
  if Token <> '' then AArgs.Add(Token);
end;

function ReadProcessOutput(AProcess: TProcess): string;
var
  Buffer: array[0..4095] of Byte;
  N: LongInt;
  S: RawByteString;
begin
  Result := '';
  while AProcess.Output.NumBytesAvailable > 0 do
  begin
    N := AProcess.Output.Read(Buffer, SizeOf(Buffer));
    if N <= 0 then Break;
    SetString(S, PAnsiChar(@Buffer[0]), N);
    Result := Result + string(S);
  end;
end;

function RunConfiguredProcess(const AExecutable: string; AParams: TStrings;
  const AWorkingDir: string; ATimeoutMs: Integer; out AOutput,
  AError: string): Boolean;
var
  P: TProcess;
  StartTick: QWord;
  I: Integer;
begin
  Result := False;
  AOutput := '';
  AError := '';
  if Trim(AExecutable) = '' then
  begin
    AError := 'Executável não configurado.';
    Exit;
  end;
  P := TProcess.Create(nil);
  try
    P.Executable := AExecutable;
    P.CurrentDirectory := AWorkingDir;
    P.Options := [poUsePipes, poStderrToOutPut];
    for I := 0 to AParams.Count - 1 do P.Parameters.Add(AParams[I]);
    try
      P.Execute;
    except
      on E: Exception do
      begin
        AError := E.Message;
        Exit(False);
      end;
    end;
    StartTick := GetTickCount64;
    while P.Running do
    begin
      AOutput := AOutput + ReadProcessOutput(P);
      if (ATimeoutMs > 0) and
         (GetTickCount64 - StartTick > QWord(ATimeoutMs)) then
      begin
        P.Terminate(1);
        AError := 'Tempo limite excedido ao executar ' + AExecutable;
        Exit(False);
      end;
      Sleep(10);
    end;
    AOutput := AOutput + ReadProcessOutput(P);
    Result := P.ExitStatus = 0;
    if not Result then
      AError := 'Processo terminou com código ' + IntToStr(P.ExitStatus) + '.';
  finally
    P.Free;
  end;
end;

function TAIDeveloperWorkspaceAction.NormalizeRoot: string;
begin
  Result := ExpandFileName(Trim(FWorkspaceRoot));
  if Result <> '' then Result := IncludeTrailingPathDelimiter(Result);
end;

function TAIDeveloperWorkspaceAction.ResolveWorkspacePath(const APath: string;
  out AFullPath, AError: string): Boolean;
var
  Root, Candidate, CandidateDir: string;
begin
  Result := False;
  AError := '';
  AFullPath := '';
  Root := NormalizeRoot;
  if (Root = '') or not DirectoryExists(Root) then
  begin
    AError := 'WorkspaceRoot inválido: ' + FWorkspaceRoot;
    Exit;
  end;
  if Trim(APath) = '' then
  begin
    AError := 'Caminho não informado.';
    Exit;
  end;
  if FilenameIsAbsolute(APath) then Candidate := ExpandFileName(APath)
  else Candidate := ExpandFileName(Root + APath);
  CandidateDir := IncludeTrailingPathDelimiter(ExtractFileDir(Candidate));
  if Pos(LowerCase(Root), LowerCase(CandidateDir)) <> 1 then
  begin
    AError := 'Acesso bloqueado fora do WorkspaceRoot: ' + Candidate;
    Exit;
  end;
  AFullPath := Candidate;
  Result := True;
end;

procedure TAIDeveloperWorkspaceAction.SetOutput(const AValue: string);
begin
  FLastOutput := AValue;
end;

constructor TAISourceReadAction.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  ActionName := 'read_source';
end;

function TAISourceReadAction.RunAction(const AParams: TStrings;
  ASimulate: Boolean): Boolean;
var
  FileName, ErrorText: string;
  S: TStringList;
begin
  Result := False;
  SetOutput('');
  if not ResolveWorkspacePath(ParamValue(AParams, 'file'), FileName,
    ErrorText) then
  begin
    SetError(ErrorText);
    Exit;
  end;
  if not FileExists(FileName) then
  begin
    SetError('Arquivo não encontrado: ' + FileName);
    Exit;
  end;
  if ASimulate then
  begin
    SetOutput('SIMULATE read_source ' + FileName);
    Exit(True);
  end;
  S := TStringList.Create;
  try
    try
      S.LoadFromFile(FileName);
    except
      on E: Exception do
      begin
        SetError(E.Message);
        Exit(False);
      end;
    end;
    SetOutput(S.Text);
    Result := True;
  finally
    S.Free;
  end;
end;

constructor TAISourceReplaceAction.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  ActionName := 'replace_source';
  FRequireUniqueMatch := True;
end;

function TAISourceReplaceAction.CountOccurrences(const AText,
  ANeedle: string): Integer;
var
  P, Offset: Integer;
begin
  Result := 0;
  if ANeedle = '' then Exit;
  Offset := 1;
  repeat
    P := Pos(ANeedle, Copy(AText, Offset, MaxInt));
    if P > 0 then
    begin
      Inc(Result);
      Inc(Offset, P - 1 + Length(ANeedle));
    end;
  until P = 0;
end;

function TAISourceReplaceAction.RunAction(const AParams: TStrings;
  ASimulate: Boolean): Boolean;
var
  FileName, ErrorText, OldText, NewText, Content, TempFile,
  BackupFile: string;
  S: TStringList;
  Matches: Integer;
begin
  Result := False;
  SetOutput('');
  if not ResolveWorkspacePath(ParamValue(AParams, 'file'), FileName,
    ErrorText) then
  begin
    SetError(ErrorText);
    Exit;
  end;
  OldText := ParamValue(AParams, 'old_text');
  NewText := ParamValue(AParams, 'new_text');
  if OldText = '' then
  begin
    SetError('old_text não informado.');
    Exit;
  end;
  if not FileExists(FileName) then
  begin
    SetError('Arquivo não encontrado: ' + FileName);
    Exit;
  end;
  S := TStringList.Create;
  try
    try
      S.LoadFromFile(FileName);
    except
      on E: Exception do
      begin
        SetError(E.Message);
        Exit(False);
      end;
    end;
    Content := S.Text;
    Matches := CountOccurrences(Content, OldText);
    if Matches = 0 then
    begin
      SetError('Trecho old_text não encontrado.');
      Exit;
    end;
    if FRequireUniqueMatch and (Matches <> 1) then
    begin
      SetError('Trecho ambíguo: ' + IntToStr(Matches) + ' ocorrências.');
      Exit;
    end;
    Content := StringReplace(Content, OldText, NewText, [rfReplaceAll]);
    if ASimulate then
    begin
      SetOutput('SIMULATE replace_source ' + FileName);
      Exit(True);
    end;
    TempFile := FileName + '.aiagent.tmp';
    BackupFile := FileName + '.aiagent.bak';
    S.Text := Content;
    try
      S.SaveToFile(TempFile);
      if FileExists(BackupFile) then DeleteFile(BackupFile);
      if not RenameFile(FileName, BackupFile) then
        raise Exception.Create('Não foi possível criar backup temporário.');
      if not RenameFile(TempFile, FileName) then
      begin
        RenameFile(BackupFile, FileName);
        raise Exception.Create('Não foi possível substituir o fonte.');
      end;
      DeleteFile(BackupFile);
    except
      on E: Exception do
      begin
        if FileExists(TempFile) then DeleteFile(TempFile);
        SetError(E.Message);
        Exit(False);
      end;
    end;
    SetOutput('Fonte atualizado: ' + FileName);
    Result := True;
  finally
    S.Free;
  end;
end;

constructor TAIProjectBuildAction.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  ActionName := 'build_project';
  FBuilderExecutable := 'lazbuild';
  FTimeoutMs := 120000;
end;

function TAIProjectBuildAction.RunAction(const AParams: TStrings;
  ASimulate: Boolean): Boolean;
var
  ProjectPath, ErrorText, OutputText, ProjectParam: string;
  Args: TStringList;
begin
  Result := False;
  SetOutput('');
  ProjectParam := ParamValue(AParams, 'project');
  if ProjectParam = '' then ProjectParam := FProjectFile;
  if not ResolveWorkspacePath(ProjectParam, ProjectPath, ErrorText) then
  begin
    SetError(ErrorText);
    Exit;
  end;
  if not FileExists(ProjectPath) then
  begin
    SetError('Projeto não encontrado: ' + ProjectPath);
    Exit;
  end;
  Args := TStringList.Create;
  try
    SplitArguments(FBuildArguments, Args);
    Args.Add(ProjectPath);
    if ASimulate then
    begin
      SetOutput('SIMULATE build_project ' + ProjectPath);
      Exit(True);
    end;
    Result := RunConfiguredProcess(FBuilderExecutable, Args,
      ExtractFileDir(ProjectPath), FTimeoutMs, OutputText, ErrorText);
    SetOutput(OutputText);
    if not Result then SetError(ErrorText + LineEnding + OutputText);
  finally
    Args.Free;
  end;
end;

procedure Register;
begin
  RegisterComponents('AI Agents', [TAISourceReadAction,
    TAISourceReplaceAction, TAIProjectBuildAction]);
end;

initialization
  {$I aiagent_sourceactions_icon.lrs}

end.
