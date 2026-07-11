program test_openai_output;

{$mode objfpc}{$H+}

uses
  Classes, consoletestrunner, test_languages;

var
  Application: TTestRunner;
begin
  Application := TTestRunner.Create(nil);
  Application.Initialize;
  Application.Title := 'AI Output Unit Tests';
  Application.Run;
  Application.Free;
end.
