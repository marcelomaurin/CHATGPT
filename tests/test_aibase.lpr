program test_aibase;

{$mode objfpc}{$H+}

uses
  Classes, SysUtils, aibase;

type
  TMockBaseComponent = class(TAIBaseComponent)
  public
    procedure TriggerError(const Msg: string);
    procedure TriggerClear;
  end;

  TTestRunner = class
  public
    LoggedCount: Integer;
    LastLogLevel: TAILogLevel;
    LastLogMsg: string;
    procedure TestLogEvent(Sender: TObject; Level: TAILogLevel; const Msg: string);
  end;

procedure TMockBaseComponent.TriggerError(const Msg: string);
begin
  SetError(Msg);
end;

procedure TMockBaseComponent.TriggerClear;
begin
  ClearError;
end;

procedure TTestRunner.TestLogEvent(Sender: TObject; Level: TAILogLevel; const Msg: string);
begin
  Inc(LoggedCount);
  LastLogLevel := Level;
  LastLogMsg := Msg;
end;

var
  Mock: TMockBaseComponent;
  Runner: TTestRunner;

begin
  WriteLn('Running test_aibase...');
  Runner := TTestRunner.Create;
  Mock := TMockBaseComponent.Create(nil);
  try
    Mock.OnLog := @Runner.TestLogEvent;
    
    // Test Initial State
    if not Mock.LastSuccess then
      raise Exception.Create('Test failed: LastSuccess should initially be True.');
    if Mock.LastError <> '' then
      raise Exception.Create('Test failed: LastError should initially be empty.');
      
    // Test SetError
    Mock.TriggerError('A sample error');
    if Mock.LastSuccess then
      raise Exception.Create('Test failed: LastSuccess should be False after SetError.');
    if Mock.LastError <> 'A sample error' then
      raise Exception.Create('Test failed: LastError mismatch.');
    if Runner.LoggedCount <> 1 then
      raise Exception.Create('Test failed: LoggedCount should be 1.');
    if Runner.LastLogLevel <> llError then
      raise Exception.Create('Test failed: LogLevel should be llError.');
      
    // Test ClearError
    Mock.TriggerClear;
    if not Mock.LastSuccess then
      raise Exception.Create('Test failed: LastSuccess should be True after ClearError.');
    if Mock.LastError <> '' then
      raise Exception.Create('Test failed: LastError should be empty after ClearError.');
    if Runner.LoggedCount <> 2 then
      raise Exception.Create('Test failed: LoggedCount should be 2.');
    if Runner.LastLogLevel <> llDebug then
      raise Exception.Create('Test failed: LogLevel should be llDebug.');
      
  finally
    Mock.Free;
    Runner.Free;
  end;
  WriteLn('test_aibase COMPLETED SUCCESSFULLY.');
end.
