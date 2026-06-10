unit main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, StdCtrls,
  ComCtrls, cnnclassifier, pythonconnector;

type

  { TfrmMain }

  TfrmMain = class(TForm)
    btnApplyPythonPath: TButton;
    btnBrowsePythonDll: TButton;
    btnClearLog: TButton;
    btnRun: TButton;
    btnTestPythonConfig: TButton;
    CNNClassifier1: TCNNClassifier;
    dlgPythonLib: TOpenDialog;
    edPythonDllPath: TEdit;
    Label1: TLabel;
    lblPythonInfo: TLabel;
    lblPythonMode: TLabel;
    lblPythonPath: TLabel;
    lblStatus: TLabel;
    lblTitle: TLabel;
    melog: TMemo;
    memoLog: TMemo;
    pcMain: TPageControl;
    pnlConfig: TPanel;
    pnlTop: TPanel;
    PythonConnector1: TPythonConnector;
    tsConfig: TTabSheet;
    tsDemo: TTabSheet;
    pnlRight: TPanel;
    lblSelectImage: TLabel;
    cbImageSelect: TComboBox;
    lblImagePath: TLabel;
    imgPreview: TImage;

    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btnRunClick(Sender: TObject);
    procedure btnClearLogClick(Sender: TObject);
    procedure btnApplyPythonPathClick(Sender: TObject);
    procedure btnBrowsePythonDllClick(Sender: TObject);
    procedure btnTestPythonConfigClick(Sender: TObject);
    procedure cbImageSelectChange(Sender: TObject);

  private

    procedure AddLog(const AMsg: string);
    procedure AddConnLog(const AMsg: string);
    procedure AddConnectorError(const AContext: string);
    procedure AddDiagnosticLog;

    function ProjectRootPath: string;
    function RuntimePythonLibDir: string;
    function DefaultPythonLibraryName: string;
    function FindPythonLibraryFile(const ALibDir: string): string;

    function SampleImageDir: string;
    function SampleImageFile: string;

    procedure ConfigureDefaultPythonPath;
    procedure ApplyPythonPath;
    procedure UpdateConfigFromConnector;

  public

  end;

var
  frmMain: TfrmMain;

implementation

{$R *.lfm}

{ TfrmMain }

procedure TfrmMain.FormCreate(Sender: TObject);
var
  SR: TSearchRec;
begin
  if Assigned(pcMain) and Assigned(tsConfig) then
    pcMain.ActivePage := tsConfig;

  CNNClassifier1.PythonConnector := PythonConnector1;
  CNNClassifier1.PreferProcessMode := False;
  CNNClassifier1.AutoInstallDependencies := True;

  // Uso puro por DLL/SO.
  // Não usa python.exe e não abre processo externo.
  PythonConnector1.Active := False;
  PythonConnector1.ExecutionMode := pemDLL;
  PythonConnector1.LoadMode := plmManualPath;

  ConfigureDefaultPythonPath;

  // Carregar imagens do diretório no cbImageSelect
  if not DirectoryExists(SampleImageDir) then
    ForceDirectories(SampleImageDir);

  if Assigned(lblImagePath) then
    lblImagePath.Caption := 'Path: ' + SampleImageDir;

  if Assigned(cbImageSelect) then
  begin
    cbImageSelect.Items.Clear;
    cbImageSelect.Style := csDropDownList;
    
    // Procura arquivos de imagem no diretório
    if FindFirst(IncludeTrailingPathDelimiter(SampleImageDir) + '*.*', faAnyFile, SR) = 0 then
    begin
      try
        repeat
          if (SR.Attr and faDirectory) = 0 then
          begin
            if SameText(ExtractFileExt(SR.Name), '.jpg') or
               SameText(ExtractFileExt(SR.Name), '.jpeg') or
               SameText(ExtractFileExt(SR.Name), '.png') then
            begin
              cbImageSelect.Items.Add(SR.Name);
            end;
          end;
        until FindNext(SR) <> 0;
      finally
        FindClose(SR);
      end;
    end;

    if cbImageSelect.Items.Count > 0 then
    begin
      cbImageSelect.ItemIndex := 0;
      cbImageSelectChange(nil);
    end;
  end;

  UpdateConfigFromConnector;

  AddLog('Cnn Classifier Complete Demo (cnnclassifier) initialized.');
  AddLog('Components linked: CNNClassifier1 -> PythonConnector1');
  if cbImageSelect.ItemIndex >= 0 then
    AddLog('Sample image selected: ' + cbImageSelect.Items[cbImageSelect.ItemIndex])
  else
    AddLog('No sample images found in: ' + SampleImageDir);

  AddConnLog('Configuration log initialized.');
  AddConnLog('Using visual component: PythonConnector1.');
  AddConnLog('PythonConnector1 configured as pemDLL / plmManualPath.');
  AddConnLog('CNNClassifier1 AutoInstallDependencies=True.');
end;

procedure TfrmMain.FormDestroy(Sender: TObject);
begin
  if Assigned(PythonConnector1) and PythonConnector1.Active then
    PythonConnector1.Active := False;
end;

function TfrmMain.ProjectRootPath: string;
var
  LDir: string;
  LTestDir: string;
  I: Integer;
begin
  LDir := ExpandFileName(ExtractFilePath(ParamStr(0)));

  for I := 0 to 10 do
  begin
    LTestDir :=
      IncludeTrailingPathDelimiter(LDir) +
      'runtime' + DirectorySeparator +
      'python' + DirectorySeparator +
      'libs';

    if DirectoryExists(LTestDir) then
    begin
      Result := ExcludeTrailingPathDelimiter(LDir);
      Exit;
    end;

    LDir := ExpandFileName(
      IncludeTrailingPathDelimiter(LDir) +
      '..'
    );
  end;

  // Fallback para:
  // CHATGPT\pacote\samples\IA Python\cnn_classifier_complete_demo
  Result := ExpandFileName(
    IncludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0))) +
    '..' + DirectorySeparator +
    '..' + DirectorySeparator +
    '..' + DirectorySeparator +
    '..'
  );

  Result := ExcludeTrailingPathDelimiter(Result);
end;

function TfrmMain.RuntimePythonLibDir: string;
var
  LBase: string;
begin
  LBase :=
    IncludeTrailingPathDelimiter(ProjectRootPath) +
    'runtime' + DirectorySeparator +
    'python' + DirectorySeparator +
    'libs' + DirectorySeparator;

  {$IFDEF MSWINDOWS}
    {$IFDEF CPU64}
    Result := LBase + 'windows' + DirectorySeparator + 'x86_64';
    {$ELSE}
    Result := LBase + 'windows' + DirectorySeparator + 'x86';
    {$ENDIF}
  {$ENDIF}

  {$IFDEF LINUX}
    {$IFDEF CPUAARCH64}
    Result := LBase + 'linux' + DirectorySeparator + 'arm64';
    {$ELSE}
      {$IFDEF CPUARM}
      Result := LBase + 'linux' + DirectorySeparator + 'arm';
      {$ELSE}
        {$IFDEF CPU64}
        Result := LBase + 'linux' + DirectorySeparator + 'x86_64';
        {$ELSE}
        Result := LBase + 'linux' + DirectorySeparator + 'x86';
        {$ENDIF}
      {$ENDIF}
    {$ENDIF}
  {$ENDIF}

  {$IFDEF DARWIN}
    {$IFDEF CPU64}
    Result := LBase + 'macos' + DirectorySeparator + 'x86_64';
    {$ELSE}
    Result := LBase + 'macos' + DirectorySeparator + 'x86';
    {$ENDIF}
  {$ENDIF}

  Result := ExpandFileName(Result);
end;

function TfrmMain.DefaultPythonLibraryName: string;
begin
  Result := '';

  // Preferência por Python 3.12 porque seu TensorFlow está instalado no Python312.
  {$IFDEF MSWINDOWS}
  Result := 'python312.dll';
  {$ENDIF}

  {$IFDEF LINUX}
  Result := 'libpython3.12.so';
  {$ENDIF}

  {$IFDEF DARWIN}
  Result := 'libpython3.12.dylib';
  {$ENDIF}
end;

function TfrmMain.FindPythonLibraryFile(const ALibDir: string): string;
const
  PreferredVersions: array[0..6] of Integer = (12, 14, 13, 11, 10, 9, 8);
var
  I: Integer;
  VersionNumber: Integer;
  Candidate: string;
  SR: TSearchRec;
  LMask: string;
begin
  Result := '';
  LMask := '';
  Candidate := '';

  if not DirectoryExists(ALibDir) then
    Exit;

  // Primeiro tenta versões específicas.
  // 3.12 fica primeiro porque é a versão onde seus pacotes TensorFlow/Pillow/NumPy apareceram instalados.
  for I := Low(PreferredVersions) to High(PreferredVersions) do
  begin
    VersionNumber := PreferredVersions[I];

    {$IFDEF MSWINDOWS}
    Candidate :=
      IncludeTrailingPathDelimiter(ALibDir) +
      'python3' + IntToStr(VersionNumber) + '.dll';
    {$ENDIF}

    {$IFDEF LINUX}
    Candidate :=
      IncludeTrailingPathDelimiter(ALibDir) +
      'libpython3.' + IntToStr(VersionNumber) + '.so';
    {$ENDIF}

    {$IFDEF DARWIN}
    Candidate :=
      IncludeTrailingPathDelimiter(ALibDir) +
      'libpython3.' + IntToStr(VersionNumber) + '.dylib';
    {$ENDIF}

    if FileExists(Candidate) then
    begin
      Result := Candidate;
      Exit;
    end;
  end;

  // Depois procura qualquer biblioteca versionada.
  {$IFDEF MSWINDOWS}
  LMask := IncludeTrailingPathDelimiter(ALibDir) + 'python3??.dll';
  {$ENDIF}

  {$IFDEF LINUX}
  LMask := IncludeTrailingPathDelimiter(ALibDir) + 'libpython3.*.so*';
  {$ENDIF}

  {$IFDEF DARWIN}
  LMask := IncludeTrailingPathDelimiter(ALibDir) + 'libpython3.*.dylib';
  {$ENDIF}

  if LMask <> '' then
  begin
    if FindFirst(LMask, faAnyFile, SR) = 0 then
    begin
      try
        repeat
          if (SR.Attr and faDirectory) = 0 then
          begin
            Result := IncludeTrailingPathDelimiter(ALibDir) + SR.Name;
            Exit;
          end;
        until FindNext(SR) <> 0;
      finally
        FindClose(SR);
      end;
    end;
  end;

  // Último fallback: biblioteca genérica.
  {$IFDEF MSWINDOWS}
  Candidate := IncludeTrailingPathDelimiter(ALibDir) + 'python3.dll';
  {$ENDIF}

  {$IFDEF LINUX}
  Candidate := IncludeTrailingPathDelimiter(ALibDir) + 'libpython3.so';
  {$ENDIF}

  {$IFDEF DARWIN}
  Candidate := IncludeTrailingPathDelimiter(ALibDir) + 'libpython3.dylib';
  {$ENDIF}

  if FileExists(Candidate) then
    Result := Candidate;
end;

function TfrmMain.SampleImageDir: string;
begin
  Result :=
    IncludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0))) +
    'imagem';

  Result := ExpandFileName(Result);
end;

function TfrmMain.SampleImageFile: string;
begin
  Result :=
    IncludeTrailingPathDelimiter(SampleImageDir) +
    'product_sample.jpg';

  Result := ExpandFileName(Result);
end;

procedure TfrmMain.ConfigureDefaultPythonPath;
var
  LDir: string;
  LFile: string;
begin
  LDir := RuntimePythonLibDir;
  LFile := FindPythonLibraryFile(LDir);

  if LFile = '' then
    LFile := IncludeTrailingPathDelimiter(LDir) + DefaultPythonLibraryName;

  PythonConnector1.Active := False;
  PythonConnector1.ExecutionMode := pemDLL;
  PythonConnector1.LoadMode := plmManualPath;
  PythonConnector1.DLLPath := LFile;

  if Assigned(edPythonDllPath) then
    edPythonDllPath.Text := LFile;

  AddConnLog('Project root: ' + ProjectRootPath);
  AddConnLog('Python runtime library dir: ' + LDir);
  AddConnLog('Python DLL/SO selected: ' + LFile);

  if not DirectoryExists(LDir) then
    AddConnLog('WARNING: Python runtime directory not found: ' + LDir);

  if not FileExists(LFile) then
    AddConnLog('WARNING: Python DLL/SO file not found: ' + LFile);

  {$IFDEF MSWINDOWS}
  if SameText(ExtractFileName(LFile), 'python3.dll') then
  begin
    AddConnLog('WARNING: python3.dll was selected.');
    AddConnLog('For pemDLL mode, prefer a versioned Python DLL, for example: python312.dll, python313.dll, python314.dll.');
    AddConnLog('If only python3.dll exists in this folder, copy the real versioned Python DLL into the runtime folder.');
  end;
  {$ENDIF}
end;

procedure TfrmMain.ApplyPythonPath;
begin
  if PythonConnector1.Active then
  begin
    AddConnLog('PythonConnector1 was active. Deactivating before applying new Python DLL/SO...');
    PythonConnector1.Active := False;
  end;

  PythonConnector1.ExecutionMode := pemDLL;
  PythonConnector1.LoadMode := plmManualPath;
  PythonConnector1.DLLPath := Trim(edPythonDllPath.Text);

  if PythonConnector1.DLLPath = '' then
  begin
    AddConnLog('Python DLL/SO path is empty. Loading default path...');
    ConfigureDefaultPythonPath;
  end;

  CNNClassifier1.PythonConnector := PythonConnector1;
  CNNClassifier1.PreferProcessMode := False;
  CNNClassifier1.AutoInstallDependencies := True;

  UpdateConfigFromConnector;

  AddConnLog('Python DLL/SO path applied to PythonConnector1.DLLPath: ' + PythonConnector1.DLLPath);

  if not FileExists(PythonConnector1.DLLPath) then
    AddConnLog('ERROR: Applied Python DLL/SO does not exist: ' + PythonConnector1.DLLPath);

  {$IFDEF MSWINDOWS}
  if SameText(ExtractFileName(PythonConnector1.DLLPath), 'python3.dll') then
  begin
    AddConnLog('WARNING: The selected file is python3.dll.');
    AddConnLog('This file may not export Py_Initialize / PyRun_SimpleString.');
    AddConnLog('Use python312.dll, python313.dll, python314.dll or another versioned Python DLL when possible.');
  end;
  {$ENDIF}
end;

procedure TfrmMain.UpdateConfigFromConnector;
begin
  if Assigned(edPythonDllPath) then
    edPythonDllPath.Text := PythonConnector1.DLLPath;

  if Assigned(lblPythonPath) then
    lblPythonPath.Caption := 'Python DLL/SO path:';

  if Assigned(lblPythonMode) then
    lblPythonMode.Caption := 'ExecutionMode: pemDLL | Component: PythonConnector1';

  if Assigned(lblPythonInfo) then
  begin
    if PythonConnector1.Active then
      lblPythonInfo.Caption := 'Python status: Active'
    else
      lblPythonInfo.Caption := 'Python status: Inactive';
  end;
end;

procedure TfrmMain.AddDiagnosticLog;
var
  LReport: TStringList;
  I: Integer;
begin
  LReport := TStringList.Create;
  try
    PythonConnector1.GetDiagnosticReport(LReport);

    AddConnLog('--- PythonConnector Diagnostic Report ---');

    for I := 0 to LReport.Count - 1 do
      AddConnLog(LReport[I]);

    AddConnLog('--- End Diagnostic Report ---');
  finally
    LReport.Free;
  end;
end;

procedure TfrmMain.AddConnectorError(const AContext: string);
begin
  AddConnLog('--- Connection Error ---');
  AddConnLog('Context: ' + AContext);
  AddConnLog('Component: PythonConnector1');
  AddConnLog('Python DLL/SO: ' + PythonConnector1.DLLPath);
  AddConnLog('ExecutionMode: pemDLL');
  AddConnLog('LoadMode: plmManualPath');
  AddConnLog('Active: ' + BoolToStr(PythonConnector1.Active, True));
  AddConnLog('Initialized: ' + BoolToStr(PythonConnector1.IsInitialized, True));

  if PythonConnector1.LastError <> '' then
    AddConnLog('LastError: ' + PythonConnector1.LastError)
  else
    AddConnLog('LastError: <empty>');

  AddDiagnosticLog;
end;

procedure TfrmMain.btnApplyPythonPathClick(Sender: TObject);
begin
  AddConnLog('--- Applying Python DLL/SO path ---');
  ApplyPythonPath;
  AddConnLog('--- Apply Finished ---');
end;

procedure TfrmMain.btnBrowsePythonDllClick(Sender: TObject);
begin
  dlgPythonLib.FileName := edPythonDllPath.Text;

  {$IFDEF MSWINDOWS}
  dlgPythonLib.Filter := 'Python DLL|python*.dll|All files|*.*';
  {$ENDIF}

  {$IFDEF LINUX}
  dlgPythonLib.Filter := 'Python SO|libpython*.so*|All files|*.*';
  {$ENDIF}

  {$IFDEF DARWIN}
  dlgPythonLib.Filter := 'Python DYLIB|libpython*.dylib|All files|*.*';
  {$ENDIF}

  dlgPythonLib.Title := 'Select Python DLL/SO';

  if dlgPythonLib.Execute then
  begin
    edPythonDllPath.Text := dlgPythonLib.FileName;
    ApplyPythonPath;
  end;
end;

procedure TfrmMain.btnTestPythonConfigClick(Sender: TObject);
begin
  AddConnLog('--- Testing PythonConnector1 DLL/SO Configuration ---');

  try
    ApplyPythonPath;

    if not FileExists(PythonConnector1.DLLPath) then
    begin
      AddConnLog('ERROR: Python DLL/SO file not found: ' + PythonConnector1.DLLPath);
      lblPythonInfo.Caption := 'Python status: File not found';
      Exit;
    end;

    AddConnLog('Activating PythonConnector1 with DLL/SO...');

    if not PythonConnector1.Active then
      PythonConnector1.Active := True;

    if not PythonConnector1.IsInitialized then
    begin
      AddConnLog('ERROR: PythonConnector1 was not initialized.');
      AddConnectorError('Testing PythonConnector1 DLL/SO configuration');
      lblPythonInfo.Caption := 'Python status: Error';
      Exit;
    end;

    AddConnLog('PythonConnector1 initialized successfully.');

    if PythonConnector1.ExecString(
      'import sys' + sLineBreak +
      'import platform' + sLineBreak +
      'py_version = sys.version' + sLineBreak +
      'py_platform = platform.platform()' + sLineBreak +
      'py_executable = sys.executable' + sLineBreak +
      'py_machine = platform.machine()' + sLineBreak +
      'py_path = "|".join(sys.path)'
    ) then
    begin
      AddConnLog('Python test executed successfully.');
      AddConnLog('Version: ' + PythonConnector1.GetVar('py_version'));
      AddConnLog('Executable: ' + PythonConnector1.GetVar('py_executable'));
      AddConnLog('Platform: ' + PythonConnector1.GetVar('py_platform'));
      AddConnLog('Machine: ' + PythonConnector1.GetVar('py_machine'));
      AddConnLog('sys.path: ' + PythonConnector1.GetVar('py_path'));

      lblPythonInfo.Caption := 'Python status: OK';
    end
    else
    begin
      AddConnLog('ERROR: Python test failed.');
      AddConnectorError('Executing Python test script');
      lblPythonInfo.Caption := 'Python status: Error';
    end;

  except
    on E: Exception do
    begin
      AddConnLog('EXCEPTION: Python configuration exception: ' + E.Message);
      AddConnectorError('Exception while testing PythonConnector1 DLL/SO configuration');
      lblPythonInfo.Caption := 'Python status: Exception';
    end;
  end;

  UpdateConfigFromConnector;
  AddConnLog('--- PythonConnector1 DLL/SO Configuration Test Finished ---');
end;

procedure TfrmMain.btnRunClick(Sender: TObject);
var
  LSelectedImage: string;
begin
  lblStatus.Caption := 'Status: Processing...';
  AddLog('--- Starting Execution ---');

  try
    ApplyPythonPath;

    if (cbImageSelect.ItemIndex < 0) then
    begin
      AddLog('Error: No image selected.');
      lblStatus.Caption := 'Status: No Image Selected';
      Exit;
    end;

    LSelectedImage := IncludeTrailingPathDelimiter(SampleImageDir) + cbImageSelect.Items[cbImageSelect.ItemIndex];

    CNNClassifier1.WeightsFile := 'weights.h5';
    CNNClassifier1.Threshold := 0.75;
    CNNClassifier1.BackendMode := 'TensorFlow';
    CNNClassifier1.AutoInstallDependencies := True;

    AddLog('CNN Classifier Properties:');
    AddLog('  Component: PythonConnector1');
    AddLog('  Python DLL/SO: ' + PythonConnector1.DLLPath);
    AddLog('  ExecutionMode: pemDLL');
    AddLog('  LoadMode: plmManualPath');
    AddLog('  WeightsFile: ' + CNNClassifier1.WeightsFile);
    AddLog('  Threshold: ' + FloatToStr(CNNClassifier1.Threshold));
    AddLog('  BackendMode: ' + CNNClassifier1.BackendMode);
    AddLog('  AutoInstallDependencies: True');
    AddLog('  Image: ' + LSelectedImage);

    if not FileExists(PythonConnector1.DLLPath) then
    begin
      AddLog('Python DLL/SO file not found. See connection log.');
      AddConnLog('ERROR: Python DLL/SO file not found during execution: ' + PythonConnector1.DLLPath);
      lblStatus.Caption := 'Status: Python DLL/SO Not Found';
      Exit;
    end;

    if not FileExists(LSelectedImage) then
    begin
      AddLog('Image file not found: ' + LSelectedImage);
      AddConnLog('ERROR: Sample image file not found: ' + LSelectedImage);
      lblStatus.Caption := 'Status: Image Not Found';
      Exit;
    end;

    AddLog('Activating PythonConnector1 by DLL/SO...');
    AddConnLog('Activating PythonConnector1 for CNN execution using pemDLL...');

    if not PythonConnector1.Active then
      PythonConnector1.Active := True;

    if not PythonConnector1.IsInitialized then
    begin
      AddLog('PythonConnector1 was not initialized. See connection log.');
      AddConnectorError('Activating Python DLL/SO before CNN execution');
      lblStatus.Caption := 'Status: Python Not Initialized';
      Exit;
    end;

    AddConnLog('PythonConnector1 active and initialized.');

    AddLog('Loading CNN model and classifying image...');

    if CNNClassifier1.LoadWeights then
    begin
      if CNNClassifier1.ClassifyFrame(LSelectedImage) then
      begin
        AddLog(
          'Classified Label: ' +
          CNNClassifier1.LastLabel +
          ' | Confidence: ' +
          FloatToStr(CNNClassifier1.LastConfidence)
        );

        lblStatus.Caption := 'Identified: ' + CNNClassifier1.LastLabel + ' (Confidence: ' + FloatToStrF(CNNClassifier1.LastConfidence, ffFixed, 1, 4) + ')';
      end
      else
      begin
        AddLog('Failed classifying image: ' + CNNClassifier1.LastError);
        AddConnLog('CNN classification failed: ' + CNNClassifier1.LastError);
        lblStatus.Caption := 'Status: ' + CNNClassifier1.LastError;
        Exit;
      end;
    end
    else
    begin
      AddLog('Failed loading CNN weights. See connection log.');
      AddConnLog('Failed loading CNN weights: ' + CNNClassifier1.LastError);
      AddConnectorError('Loading CNN weights');
      lblStatus.Caption := 'Status: Model Load Error - ' + CNNClassifier1.LastError;
      Exit;
    end;

  except
    on E: Exception do
    begin
      AddLog('Critical Error: ' + E.Message);
      AddConnLog('CRITICAL EXCEPTION: ' + E.Message);
      AddConnectorError('Critical exception during execution');
      lblStatus.Caption := 'Status: Execution Error';
    end;
  end;

  UpdateConfigFromConnector;
  AddLog('--- Execution Finished ---');
end;

procedure TfrmMain.cbImageSelectChange(Sender: TObject);
var
  LFilePath: string;
begin
  if cbImageSelect.ItemIndex >= 0 then
  begin
    LFilePath := IncludeTrailingPathDelimiter(SampleImageDir) + cbImageSelect.Items[cbImageSelect.ItemIndex];
    if FileExists(LFilePath) then
    begin
      try
        imgPreview.Picture.LoadFromFile(LFilePath);
        AddLog('Loaded preview: ' + cbImageSelect.Items[cbImageSelect.ItemIndex]);
      except
        on E: Exception do
          AddLog('Error loading preview image: ' + E.Message);
      end;
    end;
  end;
end;

procedure TfrmMain.btnClearLogClick(Sender: TObject);
begin
  if Assigned(memoLog) then
    memoLog.Clear;

  if Assigned(melog) then
    melog.Clear;
end;

procedure TfrmMain.AddLog(const AMsg: string);
begin
  if Assigned(memoLog) then
    memoLog.Lines.Add(AMsg);
end;

procedure TfrmMain.AddConnLog(const AMsg: string);
begin
  if Assigned(melog) then
    melog.Lines.Add(AMsg);
end;

end.
