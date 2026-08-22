unit aiagent_sourceactions;

{$mode objfpc}{$H+}
{$codepage utf8}

interface

uses
  Classes, SysUtils, Process, StrUtils, aiagent_actions;

type
  TAIDeveloperWorkspaceAction = class(TAICustomAgentAction)
  private
    FWorkspaceRoot: string;
    FLastOutput: string;
    function NormalizeRoot: string;
    function PathInsideRoot(const ARoot, ACandidate: string): Boolean;
    function HasSymlinkSegment(const ARoot, ACandidate: string): Boolean;
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
    FKeepBackup: Boolean;
    FVerifyAfterWrite: Boolean;
    FVerifierExecutable: string;
    FVerifierArguments: string;
    FVerificationTimeoutMs: Integer;
    function CountOccurrences(const AText, ANeedle: RawByteString): Integer;
  public
    constructor Create(AOwner: TComponent); override;
    function RunAction(const AParams: TStrings; ASimulate: Boolean): Boolean; override;
  published
    property RequireUniqueMatch: Boolean read FRequireUniqueMatch
      write FRequireUniqueMatch default True;
    property KeepBackup: Boolean read FKeepBackup write FKeepBackup default True;
    property VerifyAfterWrite: Boolean read FVerifyAfterWrite write FVerifyAfterWrite default False;
    property VerifierExecutable: string read FVerifierExecutable write FVerifierExecutable;
    property VerifierArguments: string read FVerifierArguments write FVerifierArguments;
    property VerificationTimeoutMs: Integer read FVerificationTimeoutMs
      write FVerificationTimeoutMs default 120000;
  end;

  TAISourceRollbackAction = class(TAIDeveloperWorkspaceAction)
  public
    constructor Create(AOwner: TComponent); override;
    function RunAction(const AParams: TStrings; ASimulate: Boolean): Boolean; override;
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

implementation

function ParamValue(AParams: TStrings; const AName: string): string;
begin
  Result := '';
  if Assigned(AParams) then Result := AParams.Values[AName];
end;

function IsAbsoluteFileName(const APath: string): Boolean;
begin
  Result := False;
  if APath = '' then Exit;
  {$IFDEF Windows}
  Result := ((Length(APath) >= 2) and (APath[2] = ':')) or
            ((Length(APath) >= 2) and (APath[1] = '\') and (APath[2] = '\'));
  {$ELSE}
  Result := APath[1] = '/';
  {$ENDIF}
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

function RedactSecrets(const AText: string): string;
var
  Lines: TStringList;
  I, P, EqPos: Integer;
  S, L: string;
begin
  Lines := TStringList.Create;
  try
    Lines.Text := AText;
    for I := 0 to Lines.Count - 1 do
    begin
      S := Lines[I];
      L := LowerCase(S);
      P := Pos('authorization:', L);
      if P > 0 then
        S := Copy(S, 1, P + Length('authorization:') - 1) + ' ***REDACTED***'
      else
      begin
        P := Pos('bearer ', L);
        if P > 0 then
          S := Copy(S, 1, P + Length('bearer ') - 1) + '***REDACTED***'
        else
        begin
          P := Pos('api_key=', L);
          if P = 0 then P := Pos('apikey=', L);
          if P = 0 then P := Pos('token=', L);
          if P > 0 then
          begin
            EqPos := Pos('=', Copy(S, P, MaxInt));
            if EqPos > 0 then
              S := Copy(S, 1, P + EqPos - 1) + '***REDACTED***';
          end;
        end;
      end;
      Lines[I] := S;
    end;
    Result := Lines.Text;
  finally
    Lines.Free;
  end;
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
    AError := 'Executável não configurado pelo host.';
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
        AError := 'Tempo limite excedido ao executar ' + ExtractFileName(AExecutable);
        AOutput := RedactSecrets(AOutput);
        Exit(False);
      end;
      Sleep(10);
    end;
    AOutput := RedactSecrets(AOutput + ReadProcessOutput(P));
    Result := P.ExitStatus = 0;
    if not Result then
      AError := 'Processo terminou com código ' + IntToStr(P.ExitStatus) + '.';
  finally
    P.Free;
  end;
end;

function LoadRawFile(const AFileName: string; out AData: RawByteString;
  out AError: string): Boolean;
var
  F: TFileStream;
  N: Int64;
begin
  Result := False;
  AData := '';
  AError := '';
  try
    F := TFileStream.Create(AFileName, fmOpenRead or fmShareDenyNone);
    try
      N := F.Size;
      if N > MaxInt then
      begin
        AError := 'Arquivo grande demais para alteração segura.';
        Exit(False);
      end;
      SetLength(AData, Integer(N));
      if N > 0 then F.ReadBuffer(AData[1], Integer(N));
      Result := True;
    finally
      F.Free;
    end;
  except
    on E: Exception do AError := E.Message;
  end;
end;

function SaveRawFile(const AFileName: string; const AData: RawByteString;
  out AError: string): Boolean;
var
  F: TFileStream;
begin
  Result := False;
  AError := '';
  try
    F := TFileStream.Create(AFileName, fmCreate);
    try
      if Length(AData) > 0 then F.WriteBuffer(AData[1], Length(AData));
      Result := True;
    finally
      F.Free;
    end;
  except
    on E: Exception do AError := E.Message;
  end;
end;

function MakeBackupName(const AFileName: string): string;
begin
  Result := AFileName + '.aiagent.bak.' + FormatDateTime('yyyymmddhhnnsszzz', Now);
end;

function TAIDeveloperWorkspaceAction.NormalizeRoot: string;
begin
  if Trim(FWorkspaceRoot) = '' then
  begin
    Result := '';
    Exit;
  end;
  Result := IncludeTrailingPathDelimiter(ExpandFileName(Trim(FWorkspaceRoot)));
end;

function TAIDeveloperWorkspaceAction.PathInsideRoot(const ARoot,
  ACandidate: string): Boolean;
var
  RootNoSlash, CandidateExpanded, Prefix: string;
begin
  RootNoSlash := ExcludeTrailingPathDelimiter(ExpandFileName(ARoot));
  CandidateExpanded := ExpandFileName(ACandidate);
  {$IFDEF Windows}
  RootNoSlash := LowerCase(RootNoSlash);
  CandidateExpanded := LowerCase(CandidateExpanded);
  {$ENDIF}
  Prefix := IncludeTrailingPathDelimiter(RootNoSlash);
  Result := (CandidateExpanded = RootNoSlash) or
    (Pos(Prefix, CandidateExpanded + PathDelim) = 1);
end;

function TAIDeveloperWorkspaceAction.HasSymlinkSegment(const ARoot,
  ACandidate: string): Boolean;
var
  RootNoSlash, CandidateExpanded, RelPath, Current: string;
  Parts: TStringList;
  I, Attr: Integer;
begin
  Result := False;
  RootNoSlash := ExcludeTrailingPathDelimiter(ExpandFileName(ARoot));
  CandidateExpanded := ExpandFileName(ACandidate);
  if not PathInsideRoot(RootNoSlash, CandidateExpanded) then Exit(True);

  RelPath := Copy(CandidateExpanded, Length(RootNoSlash) + 1, MaxInt);
  while (RelPath <> '') and (RelPath[1] in ['/', '\']) do Delete(RelPath, 1, 1);
  Parts := TStringList.Create;
  try
    ExtractStrings(['/', '\'], [], PChar(RelPath), Parts);
    Current := RootNoSlash;
    for I := 0 to Parts.Count - 1 do
    begin
      Current := IncludeTrailingPathDelimiter(Current) + Parts[I];
      if not FileExists(Current) and not DirectoryExists(Current) then Continue;
      Attr := FileGetAttr(Current);
      if (Attr <> -1) and ((Attr and faSymLink) <> 0) then Exit(True);
    end;
  finally
    Parts.Free;
  end;
end;

function TAIDeveloperWorkspaceAction.ResolveWorkspacePath(const APath: string;
  out AFullPath, AError: string): Boolean;
var
  Root, Candidate: string;
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
  if IsAbsoluteFileName(APath) then Candidate := ExpandFileName(APath)
  else Candidate := ExpandFileName(Root + APath);

  if not PathInsideRoot(Root, Candidate) then
  begin
    AError := 'Acesso bloqueado fora do WorkspaceRoot: ' + Candidate;
    Exit;
  end;
  if HasSymlinkSegment(Root, Candidate) then
  begin
    AError := 'Acesso bloqueado por symlink/reparse dentro do caminho: ' + Candidate;
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
  Data: RawByteString;
begin
  Result := False;
  ClearError;
  SetOutput('');
  if not ResolveWorkspacePath(ParamValue(AParams, 'file'), FileName, ErrorText) then
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
  if not LoadRawFile(FileName, Data, ErrorText) then
  begin
    SetError(ErrorText);
    Exit(False);
  end;
  SetOutput(string(Data));
  Result := True;
end;

constructor TAISourceReplaceAction.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  ActionName := 'replace_source';
  FRequireUniqueMatch := True;
  FKeepBackup := True;
  FVerifyAfterWrite := False;
  FVerificationTimeoutMs := 120000;
end;

function TAISourceReplaceAction.CountOccurrences(const AText,
  ANeedle: RawByteString): Integer;
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
  FileName, ErrorText, TempFile, BackupFile, VerifyOutput: string;
  OldText, NewText, Content: RawByteString;
  Matches: Integer;
  Args: TStringList;
  VerificationOK: Boolean;
begin
  Result := False;
  ClearError;
  SetOutput('');
  if not ResolveWorkspacePath(ParamValue(AParams, 'file'), FileName, ErrorText) then
  begin
    SetError(ErrorText);
    Exit;
  end;
  OldText := RawByteString(ParamValue(AParams, 'old_text'));
  NewText := RawByteString(ParamValue(AParams, 'new_text'));
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
  if not LoadRawFile(FileName, Content, ErrorText) then
  begin
    SetError(ErrorText);
    Exit(False);
  end;

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
    SetOutput('SIMULATE replace_source ' + FileName +
      ' matches=' + IntToStr(Matches) +
      ' verify=' + BoolToStr(FVerifyAfterWrite, True));
    Exit(True);
  end;

  TempFile := FileName + '.aiagent.tmp';
  BackupFile := MakeBackupName(FileName);
  if not SaveRawFile(TempFile, Content, ErrorText) then
  begin
    SetError(ErrorText);
    Exit(False);
  end;

  try
    if not RenameFile(FileName, BackupFile) then
      raise Exception.Create('Não foi possível criar backup durável: ' + BackupFile);
    if not RenameFile(TempFile, FileName) then
    begin
      RenameFile(BackupFile, FileName);
      raise Exception.Create('Não foi possível substituir o fonte.');
    end;

    VerificationOK := True;
    VerifyOutput := '';
    if FVerifyAfterWrite then
    begin
      Args := TStringList.Create;
      try
        SplitArguments(FVerifierArguments, Args);
        VerificationOK := RunConfiguredProcess(FVerifierExecutable, Args,
          ExtractFileDir(FileName), FVerificationTimeoutMs, VerifyOutput, ErrorText);
      finally
        Args.Free;
      end;
      if not VerificationOK then
      begin
        DeleteFile(FileName);
        if not RenameFile(BackupFile, FileName) then
          raise Exception.Create('Verificação falhou e o rollback automático também falhou. Backup: ' + BackupFile);
        SetError('Verificação falhou; alteração revertida. ' + ErrorText + LineEnding + VerifyOutput);
        Exit(False);
      end;
    end;

    if not FKeepBackup then DeleteFile(BackupFile);
    SetOutput('Fonte atualizado: ' + FileName + LineEnding +
      'Backup: ' + BackupFile + LineEnding +
      'Verificação: ' + IfThen(FVerifyAfterWrite, 'PASS', 'não solicitada') +
      IfThen(VerifyOutput <> '', LineEnding + VerifyOutput, ''));
    Result := True;
  except
    on E: Exception do
    begin
      if FileExists(TempFile) then DeleteFile(TempFile);
      if (not FileExists(FileName)) and FileExists(BackupFile) then
        RenameFile(BackupFile, FileName);
      SetError(E.Message);
      Exit(False);
    end;
  end;
end;

constructor TAISourceRollbackAction.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  ActionName := 'rollback_source';
end;

function TAISourceRollbackAction.RunAction(const AParams: TStrings;
  ASimulate: Boolean): Boolean;
var
  FileName, BackupFile, ErrorText, SafetyBackup: string;
begin
  Result := False;
  ClearError;
  SetOutput('');
  if not ResolveWorkspacePath(ParamValue(AParams, 'file'), FileName, ErrorText) then
  begin
    SetError(ErrorText);
    Exit;
  end;
  if not ResolveWorkspacePath(ParamValue(AParams, 'backup'), BackupFile, ErrorText) then
  begin
    SetError(ErrorText);
    Exit;
  end;
  if not FileExists(BackupFile) then
  begin
    SetError('Backup não encontrado: ' + BackupFile);
    Exit;
  end;
  if ASimulate then
  begin
    SetOutput('SIMULATE rollback_source ' + BackupFile + ' -> ' + FileName);
    Exit(True);
  end;

  SafetyBackup := MakeBackupName(FileName) + '.before-rollback';
  try
    if FileExists(FileName) and not RenameFile(FileName, SafetyBackup) then
      raise Exception.Create('Não foi possível preservar a versão atual antes do rollback.');
    if not RenameFile(BackupFile, FileName) then
    begin
      if FileExists(SafetyBackup) then RenameFile(SafetyBackup, FileName);
      raise Exception.Create('Não foi possível restaurar o backup.');
    end;
    SetOutput('Rollback concluído: ' + FileName + LineEnding +
      'Versão anterior preservada em: ' + SafetyBackup);
    Result := True;
  except
    on E: Exception do SetError(E.Message);
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
  ClearError;
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

end.
