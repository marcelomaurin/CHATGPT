program llamacpp_model_demo;

{$mode ObjFPC}{$H+}

uses
  Interfaces,
  Classes,
  Forms,
  SysUtils,
  aillamacppinference,
  aillamacppmodel,
  aillamacppruntime,
  aillamacpptypes,
  main;

{$R *.res}

procedure RunModelSelfTest(const AModelFile, AReportFile: string);
const
  LOAD_CYCLES = 5;
var
  I: Integer;
  LLoadResult: Boolean;
  LPassed: Boolean;
  LReport: TStringList;
  LRuntime: TAILlamaCppRuntime;
  LModel: TAILlamaCppModel;
  LRuntimeRoot: string;
begin
  LReport := TStringList.Create;
  LRuntime := TAILlamaCppRuntime.Create(nil);
  LModel := TAILlamaCppModel.Create(nil);
  try
    LRuntimeRoot := ExpandFileName(IncludeTrailingPathDelimiter(
      ExtractFilePath(ParamStr(0))) + '..\..\..\..\runtime\windows-x64');
    LRuntime.RuntimeRoot := LRuntimeRoot;
    LRuntime.BinPath := IncludeTrailingPathDelimiter(LRuntimeRoot) + 'bin';
    LRuntime.LibraryPath := IncludeTrailingPathDelimiter(LRuntimeRoot) + 'dll';
    LModel.Runtime := LRuntime;
    LModel.ModelFile := AModelFile;

    LPassed := True;
    LReport.Add('Model: ' + AModelFile);
    LReport.Add('Runtime: ' + LRuntimeRoot);
    LReport.Add('Cycles requested: ' + IntToStr(LOAD_CYCLES));
    LReport.SaveToFile(AReportFile);
    for I := 1 to LOAD_CYCLES do
    begin
      LLoadResult := LModel.Load;
      LReport.Add(Format('Cycle %d load: %s',
        [I, BoolToStr(LLoadResult, True)]));
      LReport.Add(Format('Cycle %d Loaded after load: %s',
        [I, BoolToStr(LModel.Loaded, True)]));
      LReport.SaveToFile(AReportFile);
      if not LLoadResult then
      begin
        LReport.Add('Error: ' + LModel.LastError);
        LPassed := False;
        Break;
      end;
      LModel.Unload;
      LReport.Add(Format('Cycle %d Loaded after unload: %s',
        [I, BoolToStr(LModel.Loaded, True)]));
      LReport.SaveToFile(AReportFile);
      if LModel.Loaded then
      begin
        LPassed := False;
        Break;
      end;
    end;
    LModel.Unload;
    LReport.Add('Passed: ' + BoolToStr(LPassed, True));
    LReport.SaveToFile(AReportFile);
  except
    on E: Exception do
    begin
      LReport.Add('Exception: ' + E.ClassName + ': ' + E.Message);
      LReport.Add('Passed: False');
      LReport.SaveToFile(AReportFile);
    end;
  end;
  LModel.Free;
  LRuntime.Free;
  LReport.Free;
end;

procedure RunGenerateSelfTest(const AModelFile, AReportFile: string);
const
  TEST_PROMPT = 'Responda somente: OK';
var
  LInference: TAILlamaCppInference;
  LModel: TAILlamaCppModel;
  LReport: TStringList;
  LRuntime: TAILlamaCppRuntime;
  LRuntimeRoot: string;
  LSuccess: Boolean;
  LNormalized: string;
begin
  LReport := TStringList.Create;
  LRuntime := TAILlamaCppRuntime.Create(nil);
  LModel := TAILlamaCppModel.Create(nil);
  LInference := TAILlamaCppInference.Create(nil);
  try
    LRuntimeRoot := ExpandFileName(IncludeTrailingPathDelimiter(
      ExtractFilePath(ParamStr(0))) + '..\..\..\..\runtime\windows-x64');
    LRuntime.RuntimeRoot := LRuntimeRoot;
    LRuntime.BinPath := IncludeTrailingPathDelimiter(LRuntimeRoot) + 'bin';
    LRuntime.LibraryPath := IncludeTrailingPathDelimiter(LRuntimeRoot) + 'dll';
    LModel.Runtime := LRuntime;
    LModel.ModelFile := AModelFile;
    LInference.Model := LModel;
    LInference.AccessMode := llamNative;
    LInference.MaxTokens := 16;
    LInference.Temperature := 0.8;
    LInference.Seed := 1;

    LReport.Add('Model: ' + AModelFile);
    LReport.Add('Prompt: ' + TEST_PROMPT);
    LSuccess := LInference.Generate(TEST_PROMPT);
    LReport.Add('Generate: ' + BoolToStr(LSuccess, True));
    LReport.Add('Response: ' + Trim(LInference.LastResult));
    if not LSuccess then
      LReport.Add('Error: ' + LInference.LastError);
    LNormalized := UpperCase(Trim(LInference.LastResult));
    while (Length(LNormalized) > 0) and
      (LNormalized[Length(LNormalized)] in ['.', '!']) do
      Delete(LNormalized, Length(LNormalized), 1);
    LReport.Add('Normalized response: ' + LNormalized);
    LReport.Add('Passed: ' + BoolToStr(LSuccess and
      (LNormalized = 'OK'), True));
    LReport.SaveToFile(AReportFile);
  except
    on E: Exception do
    begin
      LReport.Add('Exception: ' + E.ClassName + ': ' + E.Message);
      LReport.Add('Passed: False');
      LReport.SaveToFile(AReportFile);
    end;
  end;
  LInference.Free;
  LModel.Free;
  LRuntime.Free;
  LReport.Free;
end;

begin
  if (ParamCount >= 3) and SameText(ParamStr(1), '--self-test') then
  begin
    RunModelSelfTest(ParamStr(2), ParamStr(3));
    Halt(0);
  end;
  if (ParamCount >= 3) and SameText(ParamStr(1), '--generate-test') then
  begin
    RunGenerateSelfTest(ParamStr(2), ParamStr(3));
    Halt(0);
  end;
  RequireDerivedFormResource := True;
  Application.Scaled := True;
  Application.Initialize;
  Application.CreateForm(TfrmMain, frmMain);
  Application.Run;
end.
