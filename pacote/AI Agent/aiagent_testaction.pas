unit aiagent_testaction;

{$mode objfpc}{$H+}
{$codepage utf8}

interface

uses
  Classes, SysUtils, Process, aiagent_sourceactions, LResources, LazFileUtils;

type
  { Trusted test runner. The application configures the executable; the LLM may
    supply only arguments. Workspace file access remains confined to WorkspaceRoot. }
  TAITrustedProjectTestAction = class(TAIDeveloperWorkspaceAction)
  private
    FTestExecutable: string;
    FTestArguments: string;
    FTimeoutMs: Integer;
    function CommandExists(const ACommand: string): Boolean;
  public
    constructor Create(AOwner: TComponent); override;
    function RunAction(const AParams: TStrings; ASimulate: Boolean): Boolean; override;
  published
    property TestExecutable: string read FTestExecutable write FTestExecutable;
    property TestArguments: string read FTestArguments write FTestArguments;
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
    if C = '"' then
      Quoted := not Quoted
    else if (C in [' ', #9]) and not Quoted then
    begin
      if Token <> '' then
      begin
        AArgs.Add(Token);
        Token := '';
      end;
    end
    else
      Token := Token + C;
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

function RunProcess(const AExecutable: string; AParams: TStrings;
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
        AError := 'Tempo limite excedido ao executar testes.';
        Exit(False);
      end;
      Sleep(10);
    end;
    AOutput := AOutput + ReadProcessOutput(P);
    Result := P.ExitStatus = 0;
    if not Result then
      AError := 'Testes terminaram com código ' + IntToStr(P.ExitStatus) + '.';
  finally
    P.Free;
  end;
end;

constructor TAITrustedProjectTestAction.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  ActionName := 'run_tests';
  FTimeoutMs := 120000;
end;

function TAITrustedProjectTestAction.CommandExists(
  const ACommand: string): Boolean;
begin
  if FilenameIsAbsolute(ACommand) or (ExtractFilePath(ACommand) <> '') then
    Exit(FileExists(ACommand));
  Result := FileSearch(ACommand, GetEnvironmentVariable('PATH')) <> '';
end;

function TAITrustedProjectTestAction.RunAction(const AParams: TStrings;
  ASimulate: Boolean): Boolean;
var
  ErrorText, OutputText, ExtraArgs, Root: string;
  Args, ExtraList: TStringList;
  I: Integer;
begin
  Result := False;
  SetOutput('');
  Root := ExpandFileName(Trim(WorkspaceRoot));
  if (Root = '') or not DirectoryExists(Root) then
  begin
    SetError('WorkspaceRoot inválido: ' + WorkspaceRoot);
    Exit;
  end;
  if Trim(FTestExecutable) = '' then
  begin
    SetError('TestExecutable não configurado.');
    Exit;
  end;
  if not CommandExists(FTestExecutable) then
  begin
    SetError('Executável de teste não encontrado: ' + FTestExecutable);
    Exit;
  end;

  Args := TStringList.Create;
  ExtraList := TStringList.Create;
  try
    SplitArguments(FTestArguments, Args);
    ExtraArgs := ParamValue(AParams, 'arguments');
    if Trim(ExtraArgs) <> '' then
    begin
      SplitArguments(ExtraArgs, ExtraList);
      for I := 0 to ExtraList.Count - 1 do
        Args.Add(ExtraList[I]);
    end;
    if ASimulate then
    begin
      SetOutput('SIMULATE run_tests ' + FTestExecutable);
      Exit(True);
    end;
    Result := RunProcess(FTestExecutable, Args, Root, FTimeoutMs,
      OutputText, ErrorText);
    SetOutput(OutputText);
    if not Result then SetError(ErrorText + LineEnding + OutputText);
  finally
    ExtraList.Free;
    Args.Free;
  end;
end;

procedure Register;
begin
  RegisterComponents('AI Agents', [TAITrustedProjectTestAction]);
end;

initialization
  {$I aiagent_testaction_icon.lrs}

end.
