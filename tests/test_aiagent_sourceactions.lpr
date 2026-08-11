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

var
  Root, SourceFile, TestScript: string;
  Params: TStringList;
  ReadAction: TAISourceReadAction;
  ReplaceAction: TAISourceReplaceAction;
  BuildAction: TAIProjectBuildAction;
  TestAction: TAITrustedProjectTestAction;
  S: TStringList;
begin
  Root := IncludeTrailingPathDelimiter(GetTempDir(False)) +
    'chatgpt_agent_sourceactions_test';
  ForceDirectories(Root);
  SourceFile := IncludeTrailingPathDelimiter(Root) + 'sample.pas';
  S := TStringList.Create;
  Params := TStringList.Create;
  ReadAction := TAISourceReadAction.Create(nil);
  ReplaceAction := TAISourceReplaceAction.Create(nil);
  BuildAction := TAIProjectBuildAction.Create(nil);
  TestAction := TAITrustedProjectTestAction.Create(nil);
  try
    S.Text := 'unit sample;' + LineEnding + 'const VALUE = 1;' +
      LineEnding + 'end.' + LineEnding;
    S.SaveToFile(SourceFile);

    ReadAction.WorkspaceRoot := Root;
    Params.Values['file'] := 'sample.pas';
    Check(ReadAction.RunAction(Params, False), ReadAction.LastError);
    Check(Pos('VALUE = 1', ReadAction.LastOutput) > 0,
      'read_source não retornou conteúdo.');

    Params.Clear;
    ReplaceAction.WorkspaceRoot := Root;
    Params.Values['file'] := 'sample.pas';
    Params.Values['old_text'] := 'VALUE = 1';
    Params.Values['new_text'] := 'VALUE = 2';
    Check(ReplaceAction.RunAction(Params, True), ReplaceAction.LastError);
    S.LoadFromFile(SourceFile);
    Check(Pos('VALUE = 1', S.Text) > 0, 'simulação alterou o arquivo.');
    Check(ReplaceAction.RunAction(Params, False), ReplaceAction.LastError);
    S.LoadFromFile(SourceFile);
    Check(Pos('VALUE = 2', S.Text) > 0,
      'replace_source não alterou o arquivo.');

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

    WriteLn('OK: source actions');
  finally
    TestAction.Free;
    BuildAction.Free;
    ReplaceAction.Free;
    ReadAction.Free;
    Params.Free;
    S.Free;
  end;
end.
