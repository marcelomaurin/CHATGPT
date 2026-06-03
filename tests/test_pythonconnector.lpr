program test_pythonconnector;

{$mode objfpc}{$H+}

uses
  Classes, SysUtils, pythonconnector;

procedure RunDLLModeTest;
var
  Connector: TPythonConnector;
  Report: TStringList;
  I: Integer;
begin
  WriteLn('----------------------------------------');
  WriteLn('Testing DLL Mode (pemDLL)...');
  WriteLn('----------------------------------------');
  
  Connector := TPythonConnector.Create(nil);
  Report := TStringList.Create;
  try
    Connector.ExecutionMode := pemDLL;
    Connector.LoadMode := plmAuto;
    
    WriteLn('Activating connector in DLL mode...');
    Connector.Active := True;
    
    if Connector.IsInitialized then
    begin
      WriteLn('SUCCESS: Python DLL loaded and initialized.');
      WriteLn('Version: ', Connector.Version);
      
      // Test execution
      if Connector.ExecString('a = 42' + sLineBreak + 'b = 100') then
        WriteLn('ExecString: OK')
      else
        WriteLn('ExecString: FAILED - ', Connector.LastError);
        
      WriteLn('GetVar(a): ', Connector.GetVar('a'));
      WriteLn('GetVar(b): ', Connector.GetVar('b'));
      
      Connector.SetVar('c', 'Hello from Pascal');
      WriteLn('GetVar(c) after SetVar: ', Connector.GetVar('c'));
      
      WriteLn('Eval(a + b): ', Connector.Eval('a + b'));
    end
    else
    begin
      WriteLn('WARNING: Python DLL not initialized. This is expected if no matching python3 DLL is installed.');
      WriteLn('LastError: ', Connector.LastError);
    end;
    
    WriteLn('');
    WriteLn('Diagnostic Report:');
    Connector.GetDiagnosticReport(Report);
    for I := 0 to Report.Count - 1 do
      WriteLn(Report[I]);
      
    Connector.Active := False;
  finally
    Connector.Free;
    Report.Free;
  end;
end;

procedure RunProcessModeTest;
var
  Connector: TPythonConnector;
  Report: TStringList;
  I: Integer;
begin
  WriteLn('----------------------------------------');
  WriteLn('Testing Process Mode (pemProcess)...');
  WriteLn('----------------------------------------');
  
  Connector := TPythonConnector.Create(nil);
  Report := TStringList.Create;
  try
    Connector.ExecutionMode := pemProcess;
    
    WriteLn('Activating connector in Process mode...');
    Connector.Active := True;
    
    if Connector.IsInitialized then
    begin
      WriteLn('SUCCESS: Python Process started and initialized.');
      WriteLn('Version: ', Connector.Version);
      
      // Test execution
      if Connector.ExecString('x = 50' + sLineBreak + 'y = 250') then
        WriteLn('ExecString: OK')
      else
        WriteLn('ExecString: FAILED - ', Connector.LastError);
        
      WriteLn('GetVar(x): ', Connector.GetVar('x'));
      WriteLn('GetVar(y): ', Connector.GetVar('y'));
      
      Connector.SetVar('z', 'Hello process mode');
      WriteLn('GetVar(z) after SetVar: ', Connector.GetVar('z'));
      
      WriteLn('Eval(x * y): ', Connector.Eval('x * y'));
    end
    else
    begin
      WriteLn('FAILED: Python Process not initialized. Verify if Python is in system PATH.');
      WriteLn('LastError: ', Connector.LastError);
    end;
    
    WriteLn('');
    WriteLn('Diagnostic Report:');
    Connector.GetDiagnosticReport(Report);
    for I := 0 to Report.Count - 1 do
      WriteLn(Report[I]);
      
    Connector.Active := False;
  finally
    Connector.Free;
    Report.Free;
  end;
end;

begin
  WriteLn('Starting Python Connector integration tests...');
  try
    RunDLLModeTest;
    WriteLn('');
    RunProcessModeTest;
    WriteLn('');
    WriteLn('Python Connector tests COMPLETED.');
  except
    on E: Exception do
      WriteLn('Test execution error: ', E.Message);
  end;
end.
