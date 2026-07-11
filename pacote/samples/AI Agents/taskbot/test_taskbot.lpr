program test_taskbot;

{$mode objfpc}{$H+}

uses
  Classes, SysUtils, ubottasks, ubotactions, ubotplanner, ubotexecutor;

type
  { TTestLogHelper }
  TTestLogHelper = class
  public
    procedure LogMsg(const AMsg: string);
  end;

  { TSimpleMockAction }
  TSimpleMockAction = class(TBotAction)
  public
    function Execute(ATask: TBotTask; AContext: TExecContext): TActionResult; override;
  end;

  { TFailingMockAction }
  TFailingMockAction = class(TBotAction)
  public
    function Execute(ATask: TBotTask; AContext: TExecContext): TActionResult; override;
  end;

{ TTestLogHelper }

procedure TTestLogHelper.LogMsg(const AMsg: string);
begin
  // Suppress output or print if needed during tests
  // WriteLn('[TEST LOG] ' + AMsg);
end;

{ TSimpleMockAction }

function TSimpleMockAction.Execute(ATask: TBotTask; AContext: TExecContext): TActionResult;
begin
  AContext.SetValue('result.' + ATask.Id, ATask.Params.Values['input']);
  ATask.ResultMsg := 'Success';
  Result := aoSuccess;
end;

{ TFailingMockAction }

function TFailingMockAction.Execute(ATask: TBotTask; AContext: TExecContext): TActionResult;
begin
  ATask.ResultMsg := 'Intentional Failure';
  Result := aoFailed;
end;

var
  LogHelper: TTestLogHelper;

procedure AssertTrue(Condition: Boolean; const Msg: string);
begin
  if not Condition then
  begin
    WriteLn('Assertion FAILED: ' + Msg);
    Halt(1);
  end;
end;

procedure TestAllowlist;
var
  Context: TExecContext;
  Registry: TActionRegistry;
  Executor: TTaskExecutor;
  Tasks: TList;
  T1: TBotTask;
  Success: Boolean;
begin
  WriteLn('Running TestAllowlist...');
  Context := TExecContext.Create;
  Registry := TActionRegistry.Create;
  Executor := TTaskExecutor.Create;
  Executor.OnLog := @LogHelper.LogMsg;
  Tasks := TList.Create;
  try
    // Action 'ALLOWED' is registered, but task requests 'NOT_ALLOWED'
    Registry.Add(TSimpleMockAction.Create('ALLOWED'));

    T1 := NewTask('T1', 1, 'NOT_ALLOWED', 'Request unregistered action', '');
    Tasks.Add(T1);

    Success := Executor.Run(Tasks, Context, Registry);

    AssertTrue(not Success, 'Execution should fail when unregistered action is requested');
    AssertTrue(T1.Status = tsFailed, 'Task status should be tsFailed');
    AssertTrue(Pos('allowlist', LowerCase(T1.ResultMsg)) > 0, 'Error msg should mention allowlist');
  finally
    T1.Free;
    Tasks.Free;
    Executor.Free;
    Registry.Free;
    Context.Free;
  end;
end;

procedure TestCascadingCancellation;
var
  Context: TExecContext;
  Registry: TActionRegistry;
  Executor: TTaskExecutor;
  Tasks: TList;
  T1, T2, T3: TBotTask;
  Success: Boolean;
begin
  WriteLn('Running TestCascadingCancellation...');
  Context := TExecContext.Create;
  Registry := TActionRegistry.Create;
  Executor := TTaskExecutor.Create;
  Executor.OnLog := @LogHelper.LogMsg;
  Tasks := TList.Create;
  try
    Registry.Add(TFailingMockAction.Create('FAIL_ACTION'));
    Registry.Add(TSimpleMockAction.Create('SIMPLE'));

    T1 := NewTask('T1', 1, 'FAIL_ACTION', 'Must fail', '');
    Tasks.Add(T1);

    T2 := NewTask('T2', 2, 'SIMPLE', 'Depends on failed T1', 'T1');
    Tasks.Add(T2);

    T3 := NewTask('T3', 3, 'SIMPLE', 'Depends on canceled T2', 'T2');
    Tasks.Add(T3);

    Success := Executor.Run(Tasks, Context, Registry);

    AssertTrue(not Success, 'Execution should fail');
    AssertTrue(T1.Status = tsFailed, 'T1 should fail');
    AssertTrue(T2.Status = tsCanceled, 'T2 should be canceled because T1 failed');
    AssertTrue(T3.Status = tsCanceled, 'T3 should be canceled because T2 was canceled');
  finally
    T1.Free;
    T2.Free;
    T3.Free;
    Tasks.Free;
    Executor.Free;
    Registry.Free;
    Context.Free;
  end;
end;

procedure TestPlaceholderResolution;
var
  Context: TExecContext;
  Registry: TActionRegistry;
  Executor: TTaskExecutor;
  Tasks: TList;
  T1, T2: TBotTask;
  Success: Boolean;
begin
  WriteLn('Running TestPlaceholderResolution...');
  Context := TExecContext.Create;
  Registry := TActionRegistry.Create;
  Executor := TTaskExecutor.Create;
  Executor.OnLog := @LogHelper.LogMsg;
  Tasks := TList.Create;
  try
    Registry.Add(TSimpleMockAction.Create('SIMPLE'));

    T1 := NewTask('T1', 1, 'SIMPLE', 'Set value', '');
    T1.Params.Values['input'] := 'ResolvedValue';
    Tasks.Add(T1);

    T2 := NewTask('T2', 2, 'SIMPLE', 'Depends on T1 and uses placeholder', 'T1');
    T2.Params.Values['input'] := 'Value is {{result.T1}}';
    Tasks.Add(T2);

    Success := Executor.Run(Tasks, Context, Registry);

    AssertTrue(Success, 'Execution should succeed');
    AssertTrue(T2.Params.Values['input'] = 'Value is ResolvedValue', 'Placeholder should be resolved');
  finally
    T1.Free;
    T2.Free;
    Tasks.Free;
    Executor.Free;
    Registry.Free;
    Context.Free;
  end;
end;

begin
  LogHelper := TTestLogHelper.Create;
  try
    TestAllowlist;
    TestCascadingCancellation;
    TestPlaceholderResolution;
    WriteLn('ALL TESTS PASSED SUCCESSFULLY!');
  finally
    LogHelper.Free;
  end;
end.
