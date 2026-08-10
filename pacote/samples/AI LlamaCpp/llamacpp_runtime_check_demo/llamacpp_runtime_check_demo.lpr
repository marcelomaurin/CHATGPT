program llamacpp_runtime_check_demo;

{$mode ObjFPC}{$H+}

uses
  Interfaces,
  Classes,
  Forms,
  SysUtils,
  aillamacppruntime,
  aillamacpptypes,
  main;

{$R *.res}

function RunRuntimeSelfTest(const AReportFile: string): Boolean;
var
  LInfo: TAILlamaVersionInfo;
  LReport: TStringList;
  LRuntime: TAILlamaCppRuntime;
  LRuntimeRoot: string;
  LVersion: string;
begin
  Result := False;
  LReport := TStringList.Create;
  LRuntime := TAILlamaCppRuntime.Create(nil);
  try
    LRuntimeRoot := ExpandFileName(IncludeTrailingPathDelimiter(
      ExtractFilePath(ParamStr(0))) + '..\..\..\..\runtime\windows-x64');
    LRuntime.RuntimeRoot := LRuntimeRoot;
    LRuntime.BinPath := IncludeTrailingPathDelimiter(LRuntimeRoot) + 'bin';
    LRuntime.LibraryPath := IncludeTrailingPathDelimiter(LRuntimeRoot) + 'dll';
    Result := LRuntime.ValidateRuntime;
    LVersion := LRuntime.GetVersion;
    Result := Result and (LVersion <> '') and
      FileExists(LRuntime.GetQuantizePath) and
      LRuntime.LoadVersionInfo(LInfo) and
      SameText(LInfo.Architecture, 'x86_64') and
      SameText(LInfo.Backend, 'CPU');
    LReport.Add('RuntimeRoot=' + LRuntimeRoot);
    LReport.Add('ValidateRuntime=' + BoolToStr(
      LRuntime.ValidateRuntime, True));
    LReport.Add('Cli=' + LRuntime.GetCliPath);
    LReport.Add('Server=' + LRuntime.GetServerPath);
    LReport.Add('Quantizer=' + LRuntime.GetQuantizePath);
    LReport.Add('Version=' + LVersion);
    LReport.Add('Architecture=' + LInfo.Architecture);
    LReport.Add('Backend=' + LInfo.Backend);
    LReport.Add('LastError=' + LRuntime.LastRuntimeError);
    LReport.Add('Passed=' + BoolToStr(Result, True));
    LReport.SaveToFile(AReportFile);
  finally
    LRuntime.Free;
    LReport.Free;
  end;
end;

begin
  if (ParamCount >= 2) and SameText(ParamStr(1), '--self-test') then
  begin
    if RunRuntimeSelfTest(ParamStr(2)) then
      Halt(0)
    else
      Halt(1);
  end;
  RequireDerivedFormResource := True;
  Application.Scaled := True;
  Application.Initialize;
  Application.CreateForm(TfrmMain, frmMain);
  Application.Run;
end.
