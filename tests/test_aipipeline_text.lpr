program test_aipipeline_text;

{$mode objfpc}{$H+}

uses
  Interfaces, Classes, SysUtils, aipipeline, aibase;

var
  Pipeline: TAIPipeline;
begin
  WriteLn('Running test_aipipeline_text...');
  Pipeline := TAIPipeline.Create(nil);
  try
    Pipeline.Mode := pmTextLLM;
    Pipeline.InputText := 'Hello world';
    
    if Pipeline.Run then
      raise Exception.Create('Test failed: Pipeline.Run should return False when ChatGPT is nil.');
      
    if Pipeline.LastError <> 'Component TCHATGPT is not connected.' then
      raise Exception.Create('Test failed: Incorrect LastError message: ' + Pipeline.LastError);
      
  finally
    Pipeline.Free;
  end;
  WriteLn('test_aipipeline_text COMPLETED SUCCESSFULLY.');
end.
