program source_fix_agent_demo;

{$mode objfpc}{$H+}
{$codepage utf8}

uses
  Classes, SysUtils,
  aiagent_executor, aiagent_sourceactions, aiagent_testaction;

var
  Executor: TAIActionExecutor;
  ReadAction: TAISourceReadAction;
  ReplaceAction: TAISourceReplaceAction;
  BuildAction: TAIProjectBuildAction;
  TestAction: TAITrustedProjectTestAction;
  Root, Plan, OutputText: string;
begin
  if ParamCount < 1 then
  begin
    WriteLn('Uso: source_fix_agent_demo <workspace>');
    Halt(1);
  end;

  Root := ExpandFileName(ParamStr(1));
  Executor := TAIActionExecutor.Create(nil);
  ReadAction := TAISourceReadAction.Create(nil);
  ReplaceAction := TAISourceReplaceAction.Create(nil);
  BuildAction := TAIProjectBuildAction.Create(nil);
  TestAction := TAITrustedProjectTestAction.Create(nil);
  try
    ReadAction.WorkspaceRoot := Root;
    ReplaceAction.WorkspaceRoot := Root;
    BuildAction.WorkspaceRoot := Root;
    TestAction.WorkspaceRoot := Root;

    Executor.RegisterAction(ReadAction);
    Executor.RegisterAction(ReplaceAction);
    Executor.RegisterAction(BuildAction);
    Executor.RegisterAction(TestAction);

    Plan := '{"actions":[{"action":"read_source","parameters":{"file":"README.md"}}]}';
    if not Executor.ExecutePreparedActionsReal(Plan, OutputText) then
    begin
      WriteLn(StdErr, Executor.LastError);
      Halt(2);
    end;

    WriteLn(OutputText);
    WriteLn(ReadAction.LastOutput);
  finally
    TestAction.Free;
    BuildAction.Free;
    ReplaceAction.Free;
    ReadAction.Free;
    Executor.Free;
  end;
end.
