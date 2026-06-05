unit aiopencv;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, aibase, LResources, fpjson, jsonparser,
  aipythonruntime, aiprocessrunner, airuntimepaths, aiplatform;

type
  TAIOpenCVBackend = (
    ocvPythonProcess,
    ocvNativeDLL
  );

  TAIOpenCVFilterType = (
    ocvfNone,
    ocvfGray,
    ocvfBlur,
    ocvfCanny,
    ocvfThreshold,
    ocvfResize
  );

  TAIOpenCVStatus = (
    ocvsNotTested,
    ocvsAvailable,
    ocvsPythonNotFound,
    ocvsWorkerNotFound,
    ocvsOpenCVNotInstalled,
    ocvsBackendNotImplemented,
    ocvsError
  );

  TAIErrorEvent = procedure(Sender: TObject; const AError: string) of object;

  { TAIOpenCV }

  TAIOpenCV = class(TAIBaseComponent)
  private
    FBackend: TAIOpenCVBackend;
    FStatus: TAIOpenCVStatus;
    FRuntime: TAIPythonRuntime;

    FPythonPath: string;
    FWorkerScript: string;
    FTimeoutMs: Integer;

    FInputFile: string;
    FOutputFile: string;

    FFilterType: TAIOpenCVFilterType;

    FBlurKernelSize: Integer;
    FThresholdValue: Integer;
    FCannyThreshold1: Integer;
    FCannyThreshold2: Integer;
    FResizeWidth: Integer;
    FResizeHeight: Integer;

    FLibraryLoaded: Boolean;
    FVersion: string;

    FLastImageWidth: Integer;
    FLastImageHeight: Integer;
    FLastChannels: Integer;

    FAutoSave: Boolean;
    FOverwriteOutput: Boolean;

    FOnBeforeProcess: TNotifyEvent;
    FOnAfterProcess: TNotifyEvent;
    FOnImageProcessed: TNotifyEvent;
    FOnOpenCVError: TAIErrorEvent;

    function ResolvePythonExecutable: string;
    function ResolveWorkerScript: string;
    function ExecuteWorker(const AAction: string; const AExtraParams: array of string): string;
    function ParseWorkerJSON(const AJSON: string): Boolean;
    function FilterToAction(AFilter: TAIOpenCVFilterType): string;

    function ValidatePython: Boolean;
    function ValidateWorker: Boolean;
    function ValidateInputFile(const AFileName: string): Boolean;
    function ValidateOutputFile(const AFileName: string): Boolean;
    function ValidateParameters: Boolean;

    procedure DoError(const AMessage: string; AStatus: TAIOpenCVStatus = ocvsError);
    procedure DoLog(ALevel: TAILogLevel; const AMessage: string);
  public
    constructor Create(AOwner: TComponent); override;

    function LoadLibraries: Boolean;
    function SelfTest: Boolean;

    function GetImageInfo(const AFileName: string): Boolean;

    function ProcessFile(const AInputFile, AOutputFile: string): Boolean;
    function ApplyFilter: Boolean;

    procedure Clear;
  published
    property Backend: TAIOpenCVBackend read FBackend write FBackend default ocvPythonProcess;
    property Status: TAIOpenCVStatus read FStatus;
    property Runtime: TAIPythonRuntime read FRuntime write FRuntime;

    property PythonPath: string read FPythonPath write FPythonPath;
    property WorkerScript: string read FWorkerScript write FWorkerScript;
    property TimeoutMs: Integer read FTimeoutMs write FTimeoutMs default 120000;

    property InputFile: string read FInputFile write FInputFile;
    property OutputFile: string read FOutputFile write FOutputFile;

    property FilterType: TAIOpenCVFilterType read FFilterType write FFilterType default ocvfGray;

    property BlurKernelSize: Integer read FBlurKernelSize write FBlurKernelSize default 5;
    property ThresholdValue: Integer read FThresholdValue write FThresholdValue default 127;
    property CannyThreshold1: Integer read FCannyThreshold1 write FCannyThreshold1 default 100;
    property CannyThreshold2: Integer read FCannyThreshold2 write FCannyThreshold2 default 200;
    property ResizeWidth: Integer read FResizeWidth write FResizeWidth default 640;
    property ResizeHeight: Integer read FResizeHeight write FResizeHeight default 480;

    property LibraryLoaded: Boolean read FLibraryLoaded;
    property Version: string read FVersion;

    property LastImageWidth: Integer read FLastImageWidth;
    property LastImageHeight: Integer read FLastImageHeight;
    property LastChannels: Integer read FLastChannels;

    property AutoSave: Boolean read FAutoSave write FAutoSave default True;
    property OverwriteOutput: Boolean read FOverwriteOutput write FOverwriteOutput default True;

    property OnBeforeProcess: TNotifyEvent read FOnBeforeProcess write FOnBeforeProcess;
    property OnAfterProcess: TNotifyEvent read FOnAfterProcess write FOnAfterProcess;
    property OnImageProcessed: TNotifyEvent read FOnImageProcessed write FOnImageProcessed;
    property OnOpenCVError: TAIErrorEvent read FOnOpenCVError write FOnOpenCVError;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('AI Vision', [TAIOpenCV]);
end;

constructor TAIOpenCV.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FCategory := ccModel;
  FPrompt := 'Component TAIOpenCV uses a Python worker for OpenCV operations. Prefer assigning TAIPythonRuntime for portable execution.';

  FBackend := ocvPythonProcess;
  FStatus := ocvsNotTested;
  FRuntime := nil;

  FPythonPath := '';
  FWorkerScript := '';
  FTimeoutMs := 120000;

  FFilterType := ocvfGray;

  FBlurKernelSize := 5;
  FThresholdValue := 127;
  FCannyThreshold1 := 100;
  FCannyThreshold2 := 200;
  FResizeWidth := 640;
  FResizeHeight := 480;

  FAutoSave := True;
  FOverwriteOutput := True;

  FLibraryLoaded := False;
  FVersion := '';
  FLastImageWidth := 0;
  FLastImageHeight := 0;
  FLastChannels := 0;

  ClearError;
end;

function TAIOpenCV.ResolvePythonExecutable: string;
begin
  if Assigned(FRuntime) then
    Result := FRuntime.GetPythonExecutable
  else if Trim(FPythonPath) <> '' then
    Result := FPythonPath
  else
    Result := AIResolvePythonExecutable(AIGetDefaultRuntimeRoot);
end;

function TAIOpenCV.ResolveWorkerScript: string;
var
  Candidate: string;
begin
  if Assigned(FRuntime) then
    Result := FRuntime.GetWorkerPath('aiopencv_worker.py')
  else if Trim(FWorkerScript) <> '' then
    Result := FWorkerScript
  else
  begin
    Candidate := AIResolveWorkerPath(AIGetDefaultRuntimeRoot, 'aiopencv_worker.py');
    if FileExists(Candidate) then
      Result := Candidate
    else
      Result := AICombinePath(AICombinePath(ExtractFilePath(ParamStr(0)), 'python'), 'aiopencv_worker.py');
  end;
end;

function TAIOpenCV.ExecuteWorker(const AAction: string; const AExtraParams: array of string): string;
var
  Runner: TAIProcessRunner;
  Params: array of string;
  I: Integer;
begin
  Result := '';
  Runner := TAIProcessRunner.Create(nil);
  try
    Runner.Executable := ResolvePythonExecutable;
    Runner.TimeoutMs := FTimeoutMs;

    SetLength(Params, Length(AExtraParams) + 3);
    Params[0] := ResolveWorkerScript;
    Params[1] := '--action';
    Params[2] := AAction;
    for I := Low(AExtraParams) to High(AExtraParams) do
      Params[I + 3] := AExtraParams[I];

    DoLog(llDebug, 'Running OpenCV worker: ' + Runner.Executable + ' ' + Params[0] + ' --action ' + AAction);

    if not Runner.Execute(Params) then
    begin
      DoError(Runner.LastError, ocvsError);
      Exit;
    end;

    Result := Runner.StdOutText;
  finally
    Runner.Free;
  end;
end;

function TAIOpenCV.ParseWorkerJSON(const AJSON: string): Boolean;
var
  JSONData: TJSONData;
  JSONObj: TJSONObject;
  LSuccess: Boolean;
begin
  Result := False;
  JSONData := nil;
  try
    try
      JSONData := GetJSON(AJSON);
    except
      on E: Exception do
      begin
        DoError('Worker returned invalid JSON: ' + E.Message, ocvsError);
        Exit;
      end;
    end;

    if not Assigned(JSONData) or (not (JSONData is TJSONObject)) then
    begin
      DoError('Worker returned invalid JSON.', ocvsError);
      Exit;
    end;

    JSONObj := TJSONObject(JSONData);

    if JSONObj.Find('success') = nil then
    begin
      DoError('Worker returned invalid JSON: success field missing.', ocvsError);
      Exit;
    end;

    LSuccess := JSONObj.Booleans['success'];

    if LSuccess then
    begin
      FLastSuccess := True;

      if JSONObj.Find('message') <> nil then
        FLastResult := JSONObj.Strings['message'];

      if JSONObj.Find('version') <> nil then
      begin
        FVersion := JSONObj.Strings['version'];
        FLibraryLoaded := True;
        FStatus := ocvsAvailable;
      end;

      if JSONObj.Find('width') <> nil then
        FLastImageWidth := JSONObj.Integers['width'];

      if JSONObj.Find('height') <> nil then
        FLastImageHeight := JSONObj.Integers['height'];

      if JSONObj.Find('channels') <> nil then
        FLastChannels := JSONObj.Integers['channels'];

      Result := True;
    end
    else
    begin
      FLastSuccess := False;
      if JSONObj.Find('error') <> nil then
      begin
        FLastError := JSONObj.Strings['error'];
        if Pos('package not installed', LowerCase(FLastError)) > 0 then
          FStatus := ocvsOpenCVNotInstalled
        else
          FStatus := ocvsError;
        DoError(FLastError, FStatus);
      end
      else
        DoError('Image processing failed.', ocvsError);
    end;

  finally
    if Assigned(JSONData) then
      JSONData.Free;
  end;
end;

function TAIOpenCV.FilterToAction(AFilter: TAIOpenCVFilterType): string;
begin
  case AFilter of
    ocvfGray:      Result := 'gray';
    ocvfBlur:      Result := 'blur';
    ocvfCanny:     Result := 'canny';
    ocvfThreshold: Result := 'threshold';
    ocvfResize:    Result := 'resize';
    else           Result := 'none';
  end;
end;

function TAIOpenCV.ValidatePython: Boolean;
var
  Runner: TAIProcessRunner;
begin
  Result := False;
  if Assigned(FRuntime) then
  begin
    Result := FRuntime.ValidatePython;
    if not Result then
      DoError(FRuntime.LastError, ocvsPythonNotFound);
    Exit;
  end;

  Runner := TAIProcessRunner.Create(nil);
  try
    Runner.Executable := ResolvePythonExecutable;
    Runner.TimeoutMs := FTimeoutMs;
    Result := Runner.Execute(['--version']);
    if not Result then
      DoError('Python validation failed. ' + Runner.LastError, ocvsPythonNotFound);
  finally
    Runner.Free;
  end;
end;

function TAIOpenCV.ValidateWorker: Boolean;
begin
  FWorkerScript := ResolveWorkerScript;
  Result := FileExists(FWorkerScript);
  if not Result then
    DoError('Worker script not found: ' + FWorkerScript, ocvsWorkerNotFound);
end;

function TAIOpenCV.ValidateInputFile(const AFileName: string): Boolean;
begin
  Result := False;
  if AFileName = '' then
  begin
    DoError('Input file not found.', ocvsError);
    Exit;
  end;
  if not FileExists(AFileName) then
  begin
    DoError('Input file not found: ' + AFileName, ocvsError);
    Exit;
  end;
  Result := True;
end;

function TAIOpenCV.ValidateOutputFile(const AFileName: string): Boolean;
begin
  Result := False;
  if FAutoSave then
  begin
    if AFileName = '' then
    begin
      DoError('Output file is required.', ocvsError);
      Exit;
    end;
    if (not FOverwriteOutput) and FileExists(AFileName) then
    begin
      DoError('Output file already exists.', ocvsError);
      Exit;
    end;
  end;
  Result := True;
end;

function TAIOpenCV.ValidateParameters: Boolean;
begin
  Result := False;

  if FFilterType = ocvfBlur then
  begin
    if (FBlurKernelSize <= 0) or (FBlurKernelSize mod 2 = 0) then
    begin
      DoError('Invalid blur kernel size.', ocvsError);
      Exit;
    end;
  end;

  if FFilterType = ocvfThreshold then
  begin
    if (FThresholdValue < 0) or (FThresholdValue > 255) then
    begin
      DoError('Invalid threshold value.', ocvsError);
      Exit;
    end;
  end;

  if FFilterType = ocvfCanny then
  begin
    if (FCannyThreshold1 < 0) or (FCannyThreshold1 > 255) or
       (FCannyThreshold2 < 0) or (FCannyThreshold2 > 255) or
       (FCannyThreshold1 >= FCannyThreshold2) then
    begin
      DoError('Invalid Canny thresholds.', ocvsError);
      Exit;
    end;
  end;

  if FFilterType = ocvfResize then
  begin
    if (FResizeWidth <= 0) or (FResizeHeight <= 0) then
    begin
      DoError('Invalid resize dimensions.', ocvsError);
      Exit;
    end;
  end;

  Result := True;
end;

function TAIOpenCV.LoadLibraries: Boolean;
begin
  Result := SelfTest;
end;

function TAIOpenCV.SelfTest: Boolean;
var
  ResponseStr: string;
begin
  ClearError;
  Result := False;
  FStatus := ocvsNotTested;

  if FBackend = ocvNativeDLL then
  begin
    DoError('Native DLL backend is not implemented yet.', ocvsBackendNotImplemented);
    Exit;
  end;

  if Assigned(FRuntime) then
    FRuntime.ConfigureEnvironment;

  if not ValidatePython then Exit;
  if not ValidateWorker then Exit;

  ResponseStr := ExecuteWorker('selftest', []);
  if ResponseStr = '' then Exit;

  Result := ParseWorkerJSON(ResponseStr);
  if Result then
  begin
    FLastSuccess := True;
    FLastResult := 'OpenCV available. Version: ' + FVersion;
    DoLog(llInfo, FLastResult);
  end;
end;

function TAIOpenCV.GetImageInfo(const AFileName: string): Boolean;
var
  ResponseStr: string;
  FileToQuery: string;
begin
  ClearError;
  Result := False;

  if AFileName <> '' then
    FileToQuery := AFileName
  else
    FileToQuery := FInputFile;

  if not ValidateInputFile(FileToQuery) then Exit;
  if not ValidatePython then Exit;
  if not ValidateWorker then Exit;

  ResponseStr := ExecuteWorker('info', ['--input', FileToQuery]);
  if ResponseStr = '' then Exit;

  Result := ParseWorkerJSON(ResponseStr);
  if Result then
  begin
    FLastResult := 'Image info: ' + IntToStr(FLastImageWidth) + 'x' + IntToStr(FLastImageHeight) + ', channels: ' + IntToStr(FLastChannels);
    DoLog(llInfo, FLastResult);
  end;
end;

function TAIOpenCV.ProcessFile(const AInputFile, AOutputFile: string): Boolean;
var
  InFile, OutFile: string;
  ActionName: string;
  ResponseStr: string;
  ExtraArgs: array of string;
begin
  ClearError;
  Result := False;

  if Assigned(FOnBeforeProcess) then
    FOnBeforeProcess(Self);

  if FBackend = ocvNativeDLL then
  begin
    DoError('Native DLL backend is not implemented yet.', ocvsBackendNotImplemented);
    if Assigned(FOnAfterProcess) then FOnAfterProcess(Self);
    Exit;
  end;

  if AInputFile <> '' then
    InFile := AInputFile
  else
    InFile := FInputFile;

  if AOutputFile <> '' then
    OutFile := AOutputFile
  else
    OutFile := FOutputFile;

  if Assigned(FRuntime) then
    FRuntime.ConfigureEnvironment;

  if not ValidatePython then begin if Assigned(FOnAfterProcess) then FOnAfterProcess(Self); Exit; end;
  if not ValidateWorker then begin if Assigned(FOnAfterProcess) then FOnAfterProcess(Self); Exit; end;
  if not ValidateInputFile(InFile) then begin if Assigned(FOnAfterProcess) then FOnAfterProcess(Self); Exit; end;
  if not ValidateOutputFile(OutFile) then begin if Assigned(FOnAfterProcess) then FOnAfterProcess(Self); Exit; end;
  if not ValidateParameters then begin if Assigned(FOnAfterProcess) then FOnAfterProcess(Self); Exit; end;

  ActionName := FilterToAction(FFilterType);

  case FFilterType of
    ocvfBlur:
      begin
        SetLength(ExtraArgs, 6);
        ExtraArgs[0] := '--input';
        ExtraArgs[1] := InFile;
        ExtraArgs[2] := '--output';
        ExtraArgs[3] := OutFile;
        ExtraArgs[4] := '--kernel';
        ExtraArgs[5] := IntToStr(FBlurKernelSize);
      end;
    ocvfCanny:
      begin
        SetLength(ExtraArgs, 8);
        ExtraArgs[0] := '--input';
        ExtraArgs[1] := InFile;
        ExtraArgs[2] := '--output';
        ExtraArgs[3] := OutFile;
        ExtraArgs[4] := '--canny1';
        ExtraArgs[5] := IntToStr(FCannyThreshold1);
        ExtraArgs[6] := '--canny2';
        ExtraArgs[7] := IntToStr(FCannyThreshold2);
      end;
    ocvfThreshold:
      begin
        SetLength(ExtraArgs, 6);
        ExtraArgs[0] := '--input';
        ExtraArgs[1] := InFile;
        ExtraArgs[2] := '--output';
        ExtraArgs[3] := OutFile;
        ExtraArgs[4] := '--threshold';
        ExtraArgs[5] := IntToStr(FThresholdValue);
      end;
    ocvfResize:
      begin
        SetLength(ExtraArgs, 8);
        ExtraArgs[0] := '--input';
        ExtraArgs[1] := InFile;
        ExtraArgs[2] := '--output';
        ExtraArgs[3] := OutFile;
        ExtraArgs[4] := '--width';
        ExtraArgs[5] := IntToStr(FResizeWidth);
        ExtraArgs[6] := '--height';
        ExtraArgs[7] := IntToStr(FResizeHeight);
      end;
    else
      begin
        SetLength(ExtraArgs, 4);
        ExtraArgs[0] := '--input';
        ExtraArgs[1] := InFile;
        ExtraArgs[2] := '--output';
        ExtraArgs[3] := OutFile;
      end;
  end;

  ResponseStr := ExecuteWorker(ActionName, ExtraArgs);
  if ResponseStr = '' then
  begin
    if Assigned(FOnAfterProcess) then FOnAfterProcess(Self);
    Exit;
  end;

  Result := ParseWorkerJSON(ResponseStr);

  if Assigned(FOnAfterProcess) then
    FOnAfterProcess(Self);

  if Result and Assigned(FOnImageProcessed) then
    FOnImageProcessed(Self);
end;

function TAIOpenCV.ApplyFilter: Boolean;
begin
  Result := ProcessFile(FInputFile, FOutputFile);
end;

procedure TAIOpenCV.DoError(const AMessage: string; AStatus: TAIOpenCVStatus);
begin
  FLastError := AMessage;
  FLastSuccess := False;
  FStatus := AStatus;
  Log(llError, AMessage);
  if Assigned(FOnOpenCVError) then
    FOnOpenCVError(Self, AMessage);
end;

procedure TAIOpenCV.DoLog(ALevel: TAILogLevel; const AMessage: string);
begin
  Log(ALevel, AMessage);
end;

procedure TAIOpenCV.Clear;
begin
  FInputFile := '';
  FOutputFile := '';
  FLastImageWidth := 0;
  FLastImageHeight := 0;
  FLastChannels := 0;
  FLastResult := '';
  FLastError := '';
  FLastSuccess := True;
end;

initialization
  {$I aiopencv_icon.lrs}

end.
