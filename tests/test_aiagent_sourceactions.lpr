program test_aiagent_sourceactions;

{$mode objfpc}{$H+}
{$codepage utf8}

uses
  Classes, SysUtils, aiagent_sourceactions, aiagent_testaction;

procedure Check(ACondition: Boolean; const AMessage: string);
begin
  if not ACondition then
    raise Exception.Create(AMessage);
end;

procedure SaveRaw(const AFileName: string; const AData: RawByteString);
var
  F: TFileStream;
begin
  F := TFileStream.Create(AFileName, fmCreate);
  try
    if Length(AData) > 0 then F.WriteBuffer(AData[1], Length(AData));
  finally
    F.Free;
  end;
end;

function LoadRaw(const AFileName: string): RawByteString;
var
  F: TFileStream;
begin
  Result := '';
  F := TFileStream.Create(AFileName, fmOpenRead or fmShareDenyNone);
  try
    SetLength(Result, F.Size);
    if F.Size > 0 then F.ReadBuffer(Result[1], F.Size);
  finally
    F.Free;
  end;
end;

function BackupFromOutput(const AText: string): string;
var
  Lines: TStringList;
  I: Integer;
begin
  Result := '';
  Lines := TStringList.Create;
  try
    Lines.Text := AText;
    for I := 0 to Lines.Count - 1 do
      if Pos('Backup: ', Lines[I]) = 1 then
        Exit(Copy(Lines[I], Length('Backup: ') + 1, MaxInt));
  finally
    Lines.Free;
  end;
end;

var
  Root, SourceFile, TestScript, BackupFile: string;
  Params: TStringList;
  ReadAction: TAISourceReadAction;
  ReplaceAction: TAISourceReplaceAction;
  RollbackAction: TAISourceRollbackAction;
  BuildAction: TAIProjectBuildAction;
  TestAction: TAITrustedProjectTestAction;
  Data: RawByteString;
begin
  Root := IncludeTrailingPathDelimiter(GetTempDir(False)) +
    'chatgpt_agent_sourceactions_test';
  ForceDirectories(Root);
  SourceFile := IncludeTrailingPathDelimiter(Root) + 'sample.pas';

  Params := TStringList.Create;
  ReadAction := TAISourceReadAction.Create(nil);
  ReplaceAction := TAISourceReplaceAction.Create(nil);
  RollbackAction := TAISourceRollbackAction.Create(nil);
  BuildAction := TAIProjectBuildAction.Create(nil);
  TestAction := TAITrustedProjectTestAction.Create(nil);
  try
    { UTF-8 BOM + CRLF: the replace operation must not normalize the file. }
    Data := #$EF#$BB#$BF + 'unit sample;' + #13#10 +
      'const VALUE = 1;' + #13#10 + 'end.' + #13#10;
    SaveRaw(SourceFile, Data);

    ReadAction.WorkspaceRoot := Root;
    Params.Values['file'] := 'sample.pas';
    Check(ReadAction.RunAction(Params, False), ReadAction.LastError);
    Check(Pos('VALUE = 1', ReadAction.LastOutput) > 0,
      'read_source não retornou conteúdo.');

    Params.Clear;
    ReplaceAction.WorkspaceRoot := Root;
    ReplaceAction.KeepBackup := True;
    Params.Values['file'] := 'sample.pas';
    Params.Values['old_text'] := 'VALUE = 1';
    Params.Values['new_text'] := 'VALUE = 2';
    Check(ReplaceAction.RunAction(Params, True), ReplaceAction.LastError);
    Data := LoadRaw(SourceFile);
    Check(Pos('VALUE = 1', string(Data)) > 0, 'simulação alterou o arquivo.');

    Check(ReplaceAction.RunAction(Params, False), ReplaceAction.LastError);
    Data := LoadRaw(SourceFile);
    Check(Pos('VALUE = 2', string(Data)) > 0,
      'replace_source não alterou o arquivo.');
    Check(Copy(Data, 1, 3) = #$EF#$BB#$BF,
      'replace_source removeu o BOM UTF-8.');
    Check(Pos(#13#10, string(Data)) > 0,
      'replace_source normalizou CRLF indevidamente.');

    BackupFile := BackupFromOutput(ReplaceAction.LastOutput);
    Check((BackupFile <> '') and FileExists(BackupFile),
      'backup durável não foi preservado.');

    RollbackAction.WorkspaceRoot := Root;
    Params.Clear;
    Params.Values['file'] := 'sample.pas';
    Params.Values['backup'] := BackupFile;
    Check(RollbackAction.RunAction(Params, False), RollbackAction.LastError);
    Data := LoadRaw(SourceFile);
    Check(Pos('VALUE = 1', string(Data)) > 0,
      'rollback_source não restaurou a versão anterior.');

    { Verification failure must roll back automatically. }
    ReplaceAction.VerifyAfterWrite := True;
    {$IFDEF WINDOWS}
    ReplaceAction.VerifierExecutable := 'cmd.exe';
    ReplaceAction.VerifierArguments := '/C exit 7';
    {$ELSE}
    ReplaceAction.VerifierExecutable := '/bin/false';
    ReplaceAction.VerifierArguments := '';
    {$ENDIF}
    Params.Clear;
    Params.Values['file'] := 'sample.pas';
    Params.Values['old_text'] := 'VALUE = 1';
    Params.Values['new_text'] := 'VALUE = 99';
    Check(not ReplaceAction.RunAction(Params, False),
      'replace_source deveria falhar quando o verificador falha.');
    Data := LoadRaw(SourceFile);
    Check(Pos('VALUE = 1', string(Data)) > 0,
      'falha de verificação não restaurou automaticamente o fonte.');
    ReplaceAction.VerifyAfterWrite := False;

    Params.Clear;
    Params.Values['file'] := '../outside.pas';
    Check(not ReadAction.RunAction(Params, False),
      'path traversal não foi bloqueado.');

    {$IFDEF WINDOWS}
    BuildAction.BuilderExecutable := 'cmd.exe';
    BuildAction.BuildArguments := '/C echo build-ok';
    BuildAction.ProjectFile := 'sample.pas';
    {$ELSE}
    BuildAction.BuilderExecutable := '/bin/echo';
    BuildAction.BuildArguments := 'build-ok';
    BuildAction.ProjectFile := 'sample.pas';
    {$ENDIF}
    BuildAction.WorkspaceRoot := Root;
    Params.Clear;
    Check(BuildAction.RunAction(Params, False), BuildAction.LastError);
    Check(Pos('build-ok', LowerCase(BuildAction.LastOutput)) > 0,
      'build_project não capturou saída.');

    {$IFDEF WINDOWS}
    TestScript := 'cmd.exe';
    TestAction.TestArguments := '/C echo test-ok';
    {$ELSE}
    TestScript := '/bin/echo';
    TestAction.TestArguments := 'test-ok';
    {$ENDIF}
    TestAction.WorkspaceRoot := Root;
    TestAction.TestExecutable := TestScript;
    Check(TestAction.RunAction(Params, False), TestAction.LastError);
    Check(Pos('test-ok', LowerCase(TestAction.LastOutput)) > 0,
      'run_tests não capturou saída.');

    WriteLn('OK: source actions safety + rollback');
  finally
    TestAction.Free;
    BuildAction.Free;
    RollbackAction.Free;
    ReplaceAction.Free;
    ReadAction.Free;
    Params.Free;
  end;
end.
