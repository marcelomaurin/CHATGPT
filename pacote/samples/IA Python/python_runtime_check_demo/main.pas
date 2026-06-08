unit main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, StdCtrls,
  pythonconnector, aipythonruntime
  {$IFDEF MSWINDOWS}, Windows{$ENDIF};

type

  { TfrmMain }

  TfrmMain = class(TForm)
    pnlTop: TPanel;
    lblTitle: TLabel;
    lblStatus: TLabel;
    btnRun: TButton;
    btnClearLog: TButton;
    memoLog: TMemo;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btnRunClick(Sender: TObject);
    procedure btnClearLogClick(Sender: TObject);
  private
    FConnector: TPythonConnector;
    FEditExecutable: TEdit;
    FLabelExecutable: TLabel;

    procedure AddLog(const AMsg: string);
    procedure AddDiagnosticReport;
    procedure TestPythonImports;

    function GetRuntimePythonWindowsBasePath: string;
    function GetRuntimePythonFolder: string;
    function GetRuntimePythonDLL: string;

    procedure PreparePythonDllEnvironment(const APythonFolder: string);
  public

  end;

var
  frmMain: TfrmMain;

implementation

{$R *.lfm}

{ TfrmMain }

function TfrmMain.GetRuntimePythonWindowsBasePath: string;
var
  AppDir: string;
  TestDir: string;
  I: Integer;
begin
  Result := '';

  AppDir := IncludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0)));
  TestDir := AppDir;

  // Procura a pasta runtime\python\libs\windows subindo a partir do executável.
  // Assim funciona quando o EXE estiver dentro da árvore do projeto.
  for I := 0 to 10 do
  begin
    if DirectoryExists(TestDir + 'runtime\python\libs\windows') then
    begin
      Result := IncludeTrailingPathDelimiter(TestDir + 'runtime\python\libs\windows');
      Exit;
    end;

    TestDir := IncludeTrailingPathDelimiter(ExpandFileName(TestDir + '..'));
  end;

  // Fallback fixo do seu ambiente de desenvolvimento.
  Result := IncludeTrailingPathDelimiter(
    'D:\projetos\maurinsoft\CHATGPT\runtime\python\libs\windows'
  );
end;

function TfrmMain.GetRuntimePythonFolder: string;
begin
  {$IFDEF MSWINDOWS}

    {$IFDEF CPU64}
    Result := IncludeTrailingPathDelimiter(GetRuntimePythonWindowsBasePath + 'x86_64');
    {$ELSE}
    Result := IncludeTrailingPathDelimiter(GetRuntimePythonWindowsBasePath + 'x86');
    {$ENDIF}

  {$ELSE}

    Result := '';

  {$ENDIF}
end;

function TfrmMain.GetRuntimePythonDLL: string;
begin
  {$IFDEF MSWINDOWS}
  Result := GetRuntimePythonFolder + 'python314.dll';
  {$ELSE}
  Result := '';
  {$ENDIF}
end;

procedure TfrmMain.PreparePythonDllEnvironment(const APythonFolder: string);
{$IFDEF MSWINDOWS}
var
  CurrentPath: string;
  FolderNoSlash: string;
{$ENDIF}
begin
  {$IFDEF MSWINDOWS}
  FolderNoSlash := ExcludeTrailingPathDelimiter(APythonFolder);
  CurrentPath := SysUtils.GetEnvironmentVariable('PATH');

  // Garante que as DLLs dependentes do Python sejam localizadas.
  if Pos(UpperCase(FolderNoSlash), UpperCase(CurrentPath)) = 0 then
    Windows.SetEnvironmentVariable(
      'PATH',
      PChar(FolderNoSlash + ';' + CurrentPath)
    );
  {$ENDIF}
end;

procedure TfrmMain.FormCreate(Sender: TObject);
begin
  FConnector := TPythonConnector.Create(Self);

  FLabelExecutable := TLabel.Create(Self);
  FLabelExecutable.Parent := pnlTop;
  FLabelExecutable.Left := 15;
  FLabelExecutable.Top := 95;
  FLabelExecutable.Caption := 'Python DLL:';

  FEditExecutable := TEdit.Create(Self);
  FEditExecutable.Parent := pnlTop;
  FEditExecutable.Left := 15;
  FEditExecutable.Top := 115;
  FEditExecutable.Width := 620;

  {$IFDEF MSWINDOWS}
  FEditExecutable.Text := GetRuntimePythonDLL;
  {$ELSE}
  FEditExecutable.Text := '';
  {$ENDIF}

  // Configura o conector já no Create do Form.
  FConnector.ExecutionMode := pemDLL;
  FConnector.LoadMode := plmManualPath;
  FConnector.DLLPath := FEditExecutable.Text;

  lblStatus.Caption := 'Status: Ready';

  AddLog('Python Runtime Check Demo initialized.');
  AddLog('Using TPythonConnector in DLL mode.');
  AddLog('Runtime Python folder: ' + GetRuntimePythonFolder);
  AddLog('Runtime Python DLL: ' + FConnector.DLLPath);
end;

procedure TfrmMain.FormDestroy(Sender: TObject);
begin
  if Assigned(FConnector) then
  begin
    if FConnector.Active then
      FConnector.StopExecution;
  end;

  // Os componentes criados com Owner Self serão liberados pela LCL.
end;

procedure TfrmMain.btnRunClick(Sender: TObject);
var
  PythonFolder: string;
  PythonDLL: string;
begin
  lblStatus.Caption := 'Status: Processing...';
  AddLog('--- Starting Execution ---');

  try
    if FConnector.Active then
      FConnector.StopExecution;

    {$IFDEF MSWINDOWS}
    PythonFolder := GetRuntimePythonFolder;
    PythonDLL := GetRuntimePythonDLL;
    {$ELSE}
    PythonFolder := '';
    PythonDLL := '';
    {$ENDIF}

    FEditExecutable.Text := PythonDLL;

    AddLog('Checking Python DLL path...');
    AddLog('  Python folder: ' + PythonFolder);
    AddLog('  Expected DLL: ' + PythonDLL);

    {$IFDEF MSWINDOWS}
    if not DirectoryExists(PythonFolder) then
    begin
      AddLog('ERROR: Python runtime folder not found.');
      AddLog('Expected folder: ' + PythonFolder);

      AddLog('');
      AddLog('Verifique a estrutura:');
      AddLog('  32 bits: runtime\python\libs\windows\x86\python314.dll');
      AddLog('  64 bits: runtime\python\libs\windows\x86_64\python314.dll');

      lblStatus.Caption := 'Status: Python Folder Not Found';
      AddLog('--- Execution Finished ---');
      Exit;
    end;

    if not FileExists(PythonDLL) then
    begin
      AddLog('ERROR: python314.dll not found.');
      AddLog('Expected DLL: ' + PythonDLL);

      AddLog('');
      AddLog('Se o projeto estiver compilado em 32 bits, a DLL deve estar em:');
      AddLog('  runtime\python\libs\windows\x86\python314.dll');
      AddLog('');
      AddLog('Se o projeto estiver compilado em 64 bits, a DLL deve estar em:');
      AddLog('  runtime\python\libs\windows\x86_64\python314.dll');

      lblStatus.Caption := 'Status: Python DLL Not Found';
      AddLog('--- Execution Finished ---');
      Exit;
    end;

    PreparePythonDllEnvironment(PythonFolder);
    {$ELSE}
    AddLog('ERROR: This sample is configured for Windows DLL mode.');
    lblStatus.Caption := 'Status: Unsupported Platform';
    AddLog('--- Execution Finished ---');
    Exit;
    {$ENDIF}

    FConnector.ExecutionMode := pemDLL;
    FConnector.LoadMode := plmManualPath;
    FConnector.DLLPath := PythonDLL;

    AddLog('Python Runtime Properties:');
    AddLog('  Python DLL: ' + FConnector.DLLPath);
    AddLog('  Execution mode: pemDLL');
    AddLog('  Load mode: plmManualPath');

    AddLog('Starting Python connector...');

    if not FConnector.StartPython then
    begin
      AddLog('Failed to start Python connector.');
      AddLog('Error: ' + FConnector.LastError);
      AddDiagnosticReport;

      lblStatus.Caption := 'Status: Runtime Error';
      AddLog('--- Execution Finished ---');
      Exit;
    end;

    AddLog('Python connector started successfully.');
    AddLog('Python version: ' + FConnector.PythonVersionText);
    AddLog('Python architecture: ' + FConnector.PythonArchitecture);
    AddLog('Architecture compatible: ' + BoolToStr(FConnector.ArchitectureCompatible, True));

    TestPythonImports;

    AddDiagnosticReport;

    lblStatus.Caption := 'Status: Completed Successfully';

  except
    on E: Exception do
    begin
      AddLog('Critical Error: ' + E.Message);
      lblStatus.Caption := 'Status: Execution Error';
    end;
  end;

  AddLog('--- Execution Finished ---');
end;

procedure TfrmMain.btnClearLogClick(Sender: TObject);
begin
  memoLog.Clear;
end;

procedure TfrmMain.AddLog(const AMsg: string);
begin
  if Assigned(memoLog) then
    memoLog.Lines.Add(AMsg);
end;

procedure TfrmMain.AddDiagnosticReport;
var
  Report: TStringList;
  I: Integer;
begin
  if not Assigned(FConnector) then
    Exit;

  Report := TStringList.Create;
  try
    FConnector.GetDiagnosticReport(Report);

    AddLog('');
    AddLog('--- Diagnostic Report ---');

    for I := 0 to Report.Count - 1 do
      AddLog(Report[I]);

    AddLog('--- End Diagnostic Report ---');
    AddLog('');
  finally
    Report.Free;
  end;
end;

procedure TfrmMain.TestPythonImports;
var
  Script: string;
  NumPyResult: string;
  OpenCVResult: string;
  SysVersion: string;
begin
  AddLog('Testing Python imports...');

  Script :=
    'import sys' + sLineBreak +

    '_connector_sys_version = sys.version' + sLineBreak +

    'try:' + sLineBreak +
    '    import numpy as np' + sLineBreak +
    '    _connector_numpy_result = "OK: " + np.__version__' + sLineBreak +
    'except Exception as e:' + sLineBreak +
    '    _connector_numpy_result = "ERROR: " + str(e)' + sLineBreak +

    'try:' + sLineBreak +
    '    import cv2' + sLineBreak +
    '    _connector_opencv_result = "OK: " + cv2.__version__' + sLineBreak +
    'except Exception as e:' + sLineBreak +
    '    _connector_opencv_result = "ERROR: " + str(e)' + sLineBreak;

  if not FConnector.ExecString(Script) then
  begin
    AddLog('Failed import validation script.');
    AddLog('Error: ' + FConnector.LastError);
    Exit;
  end;

  SysVersion := FConnector.GetVar('_connector_sys_version');
  NumPyResult := FConnector.GetVar('_connector_numpy_result');
  OpenCVResult := FConnector.GetVar('_connector_opencv_result');

  AddLog('Python sys.version: ' + SysVersion);
  AddLog('NumPy import check: ' + NumPyResult);
  AddLog('OpenCV import check: ' + OpenCVResult);

  if Pos('ERROR:', NumPyResult) = 1 then
    AddLog('Warning: NumPy is not available in this Python environment.');

  if Pos('ERROR:', OpenCVResult) = 1 then
    AddLog('Warning: OpenCV/cv2 is not available in this Python environment.');
end;

end.
