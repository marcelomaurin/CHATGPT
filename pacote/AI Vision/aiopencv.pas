unit aiopencv;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, aibase, LResources, fpjson, jsonparser;

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

    FPythonPath: string;
    FWorkerScript: string;

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

    // Helper functions
    function FindPythonExecutable: string;
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

    property PythonPath: string read FPythonPath write FPythonPath;
    property WorkerScript: string read FWorkerScript write FWorkerScript;

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

uses
  Process;

procedure Register;
begin
  RegisterComponents('AI Vision', [TAIOpenCV]);
end;

{ TAIOpenCV }

constructor TAIOpenCV.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FCategory := ccModel;
  FPrompt := 'Component TAIOpenCV binds to OpenCV libraries dynamically. Properties: LibraryLoaded, Version. Methods: LoadLibraries, ApplyFilter, ProcessFile, SelfTest.';
  
  FBackend := ocvPythonProcess;
  FStatus := ocvsNotTested;

  FPythonPath := 'python';
  FWorkerScript := ExtractFilePath(ParamStr(0)) + 'python' + DirectorySeparator + 'aiopencv_worker.py';

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

function TAIOpenCV.FindPythonExecutable: string;
var
  PathEnv: string;
  Paths: TStringList;
  I: Integer;
  Candidate: string;
  ExeName: string;
  AppDir: string;
begin
  Result := '';
  AppDir := IncludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0)));
  {$IFDEF MSWINDOWS}
  ExeName := 'python.exe';
  {$ELSE}
  ExeName := 'python3';
  {$ENDIF}

  // 1. Check in application directory
  if FileExists(AppDir + ExeName) then
    Exit(AppDir + ExeName);

  // 2. Check in PATH environment variable
  PathEnv := GetEnvironmentVariable('PATH');
  if PathEnv <> '' then
  begin
    Paths := TStringList.Create;
    try
      {$IFDEF MSWINDOWS}
      Paths.Delimiter := ';';
      {$ELSE}
      Paths.Delimiter := ':';
      {$ENDIF}
      Paths.StrictDelimiter := True;
      Paths.DelimitedText := PathEnv;
      for I := 0 to Paths.Count - 1 do
      begin
        if Paths[I] <> '' then
        begin
          Candidate := IncludeTrailingPathDelimiter(Paths[I]) + ExeName;
          if FileExists(Candidate) then
          begin
            Result := Candidate;
            Break;
          end;
        end;
      end;
    finally
      Paths.Free;
    end;
  end;

  if Result <> '' then Exit;

  // 3. Fallbacks on Windows
  {$IFDEF MSWINDOWS}
  for I := 14 downto 8 do
  begin
    Candidate := 'C:\Python3' + IntToStr(I) + '\python.exe';
    if FileExists(Candidate) then
      Exit(Candidate);

    Candidate := GetEnvironmentVariable('USERPROFILE') + '\AppData\Local\Programs\Python\Python3' + IntToStr(I) + '\python.exe';
    if FileExists(Candidate) then
      Exit(Candidate);
  end;
  {$ENDIF}

  // 4. Default fallback
  Result := ExeName;
end;

function TAIOpenCV.ExecuteWorker(const AAction: string; const AExtraParams: array of string): string;
var
  PyProc: TProcess;
  I: Integer;
  OutputStream: TMemoryStream;
  BytesRead: Integer;
  Buf: array[0..2047] of Byte;
  OutputStr, ErrorStr: string;
begin
  Result := '';
  PyProc := TProcess.Create(nil);
  try
    PyProc.Executable := FPythonPath;
    PyProc.Parameters.Add(FWorkerScript);
    PyProc.Parameters.Add('--action');
    PyProc.Parameters.Add(AAction);
    
    // Add extra parameters
    for I := Low(AExtraParams) to High(AExtraParams) do
      PyProc.Parameters.Add(AExtraParams[I]);
      
    PyProc.Options := [poUsePipes, poNoConsole];
    
    DoLog(llDebug, 'Running worker: ' + PyProc.Executable + ' ' + FWorkerScript + ' --action ' + AAction);
    
    try
      PyProc.Execute;
    except
      on E: Exception do
      begin
        DoError('Python executable not found.', ocvsPythonNotFound);
        Exit;
      end;
    end;
    
    OutputStream := TMemoryStream.Create;
    try
      // Read stdout
      while PyProc.Running or (PyProc.Output.NumBytesAvailable > 0) do
      begin
        if PyProc.Output.NumBytesAvailable > 0 then
        begin
          BytesRead := PyProc.Output.Read(Buf, SizeOf(Buf));
          if BytesRead > 0 then
            OutputStream.Write(Buf, BytesRead);
        end
        else
          Sleep(10);
      end;
      
      if OutputStream.Size > 0 then
      begin
        SetLength(OutputStr, OutputStream.Size);
        OutputStream.Position := 0;
        OutputStream.Read(OutputStr[1], OutputStream.Size);
      end;
      
      // Read stderr
      OutputStream.Clear;
      while PyProc.Stderr.NumBytesAvailable > 0 do
      begin
        BytesRead := PyProc.Stderr.Read(Buf, SizeOf(Buf));
        if BytesRead > 0 then
          OutputStream.Write(Buf, BytesRead);
      end;
      
      if OutputStream.Size > 0 then
      begin
        SetLength(ErrorStr, OutputStream.Size);
        OutputStream.Position := 0;
        OutputStream.Read(ErrorStr[1], OutputStream.Size);
      end;
      
      if PyProc.ExitStatus <> 0 then
      begin
        if Trim(OutputStr) = '' then
        begin
          DoError('Image processing failed. Stderr: ' + Trim(ErrorStr), ocvsError);
          Exit;
        end;
      end;
      
      Result := OutputStr;
      
    finally
      OutputStream.Free;
    end;
  finally
    PyProc.Free;
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
        DoError('Worker returned invalid JSON.', ocvsError);
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
      DoError('Worker returned invalid JSON.', ocvsError);
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
        if Pos('package not installed', FLastError) > 0 then
          FStatus := ocvsOpenCVNotInstalled
        else if Pos('not found', FLastError) > 0 then
          FStatus := ocvsError
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
  PyProc: TProcess;
begin
  Result := False;
  PyProc := TProcess.Create(nil);
  try
    PyProc.Executable := FPythonPath;
    PyProc.Parameters.Add('--version');
    PyProc.Options := [poUsePipes, poNoConsole];
    try
      PyProc.Execute;
      while PyProc.Running do Sleep(10);
      Result := (PyProc.ExitStatus = 0) or (PyProc.ExitStatus = 1);
    except
      // Try to auto-resolve Python executable
      FPythonPath := FindPythonExecutable;
      PyProc.Executable := FPythonPath;
      try
        PyProc.Execute;
        while PyProc.Running do Sleep(10);
        Result := True;
      except
        DoError('Python executable not found.', ocvsPythonNotFound);
      end;
    end;
  finally
    PyProc.Free;
  end;
end;

function TAIOpenCV.ValidateWorker: Boolean;
var
  FallbackPath: string;
begin
  Result := FileExists(FWorkerScript);
  if not Result then
  begin
    // Check fallback relative to samples/AI Vision/opencv_filter_demo/ or run directories
    FallbackPath := ExpandFileName(ExtractFilePath(ParamStr(0)) + '..' + DirectorySeparator + '..' + DirectorySeparator + '..' + DirectorySeparator + 'python' + DirectorySeparator + 'aiopencv_worker.py');
    if FileExists(FallbackPath) then
    begin
      FWorkerScript := FallbackPath;
      Result := True;
    end;
  end;
  
  if not Result then
    DoError('Worker script not found.', ocvsWorkerNotFound);
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
    DoError('Input file not found.', ocvsError);
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
  
  FileToQuery := StringReplace(FileToQuery, '\', '/', [rfReplaceAll]);
  
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
  
  // Set files to process
  if AInputFile <> '' then
    InFile := AInputFile
  else
    InFile := FInputFile;
    
  if AOutputFile <> '' then
    OutFile := AOutputFile
  else
    OutFile := FOutputFile;
    
  // Validate Python, worker, files, parameters
  if not ValidatePython then begin if Assigned(FOnAfterProcess) then FOnAfterProcess(Self); Exit; end;
  if not ValidateWorker then begin if Assigned(FOnAfterProcess) then FOnAfterProcess(Self); Exit; end;
  if not ValidateInputFile(InFile) then begin if Assigned(FOnAfterProcess) then FOnAfterProcess(Self); Exit; end;
  if not ValidateOutputFile(OutFile) then begin if Assigned(FOnAfterProcess) then FOnAfterProcess(Self); Exit; end;
  if not ValidateParameters then begin if Assigned(FOnAfterProcess) then FOnAfterProcess(Self); Exit; end;
  
  ActionName := FilterToAction(FFilterType);
  InFile := StringReplace(InFile, '\', '/', [rfReplaceAll]);
  OutFile := StringReplace(OutFile, '\', '/', [rfReplaceAll]);
  
  // Build arguments list based on filter
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
    
  if Result then
  begin
    if Assigned(FOnImageProcessed) then
      FOnImageProcessed(Self);
  end;
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
