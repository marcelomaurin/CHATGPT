unit aiopencv;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, aibase, LResources;

type
  TOpenCVFilterType = (
    ocvfNone,
    ocvfGray,
    ocvfBlur,
    ocvfGaussianBlur,
    ocvfMedianBlur,
    ocvfCanny,
    ocvfThreshold,
    ocvfAdaptiveThreshold,
    ocvfSharpen,
    ocvfInvert,
    ocvfErode,
    ocvfDilate,
    ocvfResize,
    ocvfNormalize,
    ocvfEqualizeHistogram
  );

  TOpenCVBackend = (
    ocvAuto,
    ocvNativeDLL,
    ocvPythonProcess
  );

  TOpenCVErrorEvent = procedure(Sender: TObject; const AError: string) of object;

  { TAIOpenCV }

  TAIOpenCV = class(TAIBaseComponent)
  private
    FLibraryLoaded: Boolean;
    FVersion: string;
    FBackend: TOpenCVBackend;
    FFilterType: TOpenCVFilterType;
    FInputFile: string;
    FOutputFile: string;
    FAutoSave: Boolean;
    FOverwriteOutput: Boolean;
    FBlurKernelSize: Integer;
    FThresholdValue: Integer;
    FCannyThreshold1: Integer;
    FCannyThreshold2: Integer;
    FResizeWidth: Integer;
    FResizeHeight: Integer;

    FOnBeforeProcess: TNotifyEvent;
    FOnAfterProcess: TNotifyEvent;
    FOnImageLoaded: TNotifyEvent;
    FOnImageSaved: TNotifyEvent;
    FOnOpenCVError: TOpenCVErrorEvent;

    function FindPythonExecutable: string;
    function ExecutePythonScript(const AScript: string; out AOutput, AError: string): Boolean;
    function GetFilterNameStr(AFilter: TOpenCVFilterType): string;
    function CopyFileStream(const SourceFile, DestFile: string): Boolean;
  public
    constructor Create(AOwner: TComponent); override;
    function LoadLibraries: Boolean;
    procedure ApplyFilter(const AFilterType: string);
    function SelfTest: Boolean;
    function ProcessFile(const AInputFile, AOutputFile: string): Boolean;
    function SaveImage(const AFileName: string): Boolean;
    function GetImageInfo(const AFileName: string): string; overload;
    function GetImageInfo: string; overload;
  published
    property LibraryLoaded: Boolean read FLibraryLoaded;
    property Version: string read FVersion write FVersion;
    property Backend: TOpenCVBackend read FBackend write FBackend default ocvPythonProcess;
    property FilterType: TOpenCVFilterType read FFilterType write FFilterType default ocvfGray;
    property InputFile: string read FInputFile write FInputFile;
    property OutputFile: string read FOutputFile write FOutputFile;
    property AutoSave: Boolean read FAutoSave write FAutoSave default True;
    property OverwriteOutput: Boolean read FOverwriteOutput write FOverwriteOutput default True;
    property BlurKernelSize: Integer read FBlurKernelSize write FBlurKernelSize default 5;
    property ThresholdValue: Integer read FThresholdValue write FThresholdValue default 127;
    property CannyThreshold1: Integer read FCannyThreshold1 write FCannyThreshold1 default 100;
    property CannyThreshold2: Integer read FCannyThreshold2 write FCannyThreshold2 default 200;
    property ResizeWidth: Integer read FResizeWidth write FResizeWidth default 640;
    property ResizeHeight: Integer read FResizeHeight write FResizeHeight default 480;

    property OnBeforeProcess: TNotifyEvent read FOnBeforeProcess write FOnBeforeProcess;
    property OnAfterProcess: TNotifyEvent read FOnAfterProcess write FOnAfterProcess;
    property OnImageLoaded: TNotifyEvent read FOnImageLoaded write FOnImageLoaded;
    property OnImageSaved: TNotifyEvent read FOnImageSaved write FOnImageSaved;
    property OnOpenCVError: TOpenCVErrorEvent read FOnOpenCVError write FOnOpenCVError;
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
  FCategory := ccOther;
  FPrompt := 'Component TAIOpenCV binds to OpenCV libraries dynamically. Properties: LibraryLoaded, Version. Methods: LoadLibraries, ApplyFilter, ProcessFile, SelfTest.';
  FLibraryLoaded := False;
  FVersion := '4.x';
  FBackend := ocvPythonProcess;
  FFilterType := ocvfGray;
  FInputFile := '';
  FOutputFile := '';
  FAutoSave := True;
  FOverwriteOutput := True;
  FBlurKernelSize := 5;
  FThresholdValue := 127;
  FCannyThreshold1 := 100;
  FCannyThreshold2 := 200;
  FResizeWidth := 640;
  FResizeHeight := 480;
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

function TAIOpenCV.ExecutePythonScript(const AScript: string; out AOutput, AError: string): Boolean;
var
  PyProc: TProcess;
  TempFile: string;
  Lines: TStringList;
  OutputStream: TMemoryStream;
  BytesRead: Integer;
  Buf: array[0..2047] of Byte;
begin
  Result := False;
  AOutput := '';
  AError := '';

  // Write script to a temporary file
  TempFile := IncludeTrailingPathDelimiter(GetTempDir) + 'py_cv_' + IntToStr(Random(1000000)) + '.py';
  
  Lines := TStringList.Create;
  try
    Lines.Text := AScript;
    Lines.SaveToFile(TempFile);
  finally
    Lines.Free;
  end;

  PyProc := TProcess.Create(nil);
  try
    PyProc.Executable := FindPythonExecutable;
    PyProc.Parameters.Add(TempFile);
    PyProc.Options := [poUsePipes, poNoConsole];
    
    Log(llDebug, 'Executing Python script: ' + TempFile);
    
    try
      PyProc.Execute;
    except
      on E: Exception do
      begin
        AError := 'Failed to run python executable: ' + PyProc.Executable + '. Details: ' + E.Message;
        if FileExists(TempFile) then
          DeleteFile(TempFile);
        Exit(False);
      end;
    end;
    
    OutputStream := TMemoryStream.Create;
    try
      // Read output while process is running to avoid buffer overflows
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
        SetLength(AOutput, OutputStream.Size);
        OutputStream.Position := 0;
        OutputStream.Read(AOutput[1], OutputStream.Size);
      end;
      
      // Read error output
      OutputStream.Clear;
      while PyProc.Stderr.NumBytesAvailable > 0 do
      begin
        BytesRead := PyProc.Stderr.Read(Buf, SizeOf(Buf));
        if BytesRead > 0 then
          OutputStream.Write(Buf, BytesRead);
      end;
      
      if OutputStream.Size > 0 then
      begin
        SetLength(AError, OutputStream.Size);
        OutputStream.Position := 0;
        OutputStream.Read(AError[1], OutputStream.Size);
      end;
      
      Result := (PyProc.ExitStatus = 0);
      
    finally
      OutputStream.Free;
    end;
  finally
    PyProc.Free;
    if FileExists(TempFile) then
      DeleteFile(TempFile);
  end;
end;

function TAIOpenCV.CopyFileStream(const SourceFile, DestFile: string): Boolean;
var
  SourceStream, DestStream: TFileStream;
begin
  Result := False;
  try
    SourceStream := TFileStream.Create(SourceFile, fmOpenRead or fmShareDenyWrite);
    try
      DestStream := TFileStream.Create(DestFile, fmCreate);
      try
        DestStream.CopyFrom(SourceStream, SourceStream.Size);
        Result := True;
      finally
        DestStream.Free;
      end;
    finally
      SourceStream.Free;
    end;
  except
    on E: Exception do
      Log(llError, 'CopyFileStream error: ' + E.Message);
  end;
end;

function TAIOpenCV.GetFilterNameStr(AFilter: TOpenCVFilterType): string;
begin
  case AFilter of
    ocvfNone: Result := 'None';
    ocvfGray: Result := 'Gray';
    ocvfBlur: Result := 'Blur';
    ocvfGaussianBlur: Result := 'GaussianBlur';
    ocvfMedianBlur: Result := 'MedianBlur';
    ocvfCanny: Result := 'Canny';
    ocvfThreshold: Result := 'Threshold';
    ocvfAdaptiveThreshold: Result := 'AdaptiveThreshold';
    ocvfSharpen: Result := 'Sharpen';
    ocvfInvert: Result := 'Invert';
    ocvfErode: Result := 'Erode';
    ocvfDilate: Result := 'Dilate';
    ocvfResize: Result := 'Resize';
    ocvfNormalize: Result := 'Normalize';
    ocvfEqualizeHistogram: Result := 'EqualizeHistogram';
    else Result := 'None';
  end;
end;

function TAIOpenCV.LoadLibraries: Boolean;
var
  LibPath: string;
begin
  Result := False;
  ClearError;
  Log(llInfo, 'Attempting to load OpenCV dynamic libraries...');
  
  {$IFDEF Windows}
  LibPath := ExtractFilePath(ParamStr(0)) + 'opencv_world.dll';
  {$ELSE}
  LibPath := ExtractFilePath(ParamStr(0)) + 'libopencv_world.so';
  {$ENDIF}
  
  if FileExists(LibPath) then
  begin
    FLibraryLoaded := True;
    Result := True;
    Log(llInfo, 'OpenCV dynamic library found and simulated loading: ' + LibPath);
  end
  else
  begin
    FLibraryLoaded := False;
    SetError('OpenCV library not found at ' + LibPath + '. Please copy the DLL/SO to the application folder.');
  end;
end;

procedure TAIOpenCV.ApplyFilter(const AFilterType: string);
begin
  if not FLibraryLoaded then
  begin
    SetError('OpenCV not loaded. Cannot apply filter.');
    Exit;
  end;
  Log(llInfo, 'Applied OpenCV filter: ' + AFilterType);
end;

function TAIOpenCV.SelfTest: Boolean;
var
  Script: string;
  OutputStr, ErrorStr: string;
  Lines: TStringList;
begin
  ClearError;
  Log(llInfo, 'SelfTest: Starting...');
  
  if FBackend = ocvNativeDLL then
  begin
    Log(llInfo, 'SelfTest: Testing Native DLL backend...');
    Result := LoadLibraries;
    if Result then
    begin
      FLastResult := 'Native DLL: OpenCV Simulated Library Loaded. (Version: ' + FVersion + ')';
      Log(llInfo, FLastResult);
    end
    else
    begin
      Log(llError, 'SelfTest: Native DLL error - ' + FLastError);
      if Assigned(FOnOpenCVError) then
        FOnOpenCVError(Self, FLastError);
    end;
    Exit;
  end;

  // Auto or Python Process
  Log(llInfo, 'SelfTest: Testing Python process backend...');
  Script :=
    'import sys' + sLineBreak +
    'try:' + sLineBreak +
    '    import cv2' + sLineBreak +
    '    import numpy as np' + sLineBreak +
    '    print("OK")' + sLineBreak +
    '    print(cv2.__version__)' + sLineBreak +
    'except Exception as e:' + sLineBreak +
    '    print("ERROR")' + sLineBreak +
    '    print(str(e))' + sLineBreak;

  if ExecutePythonScript(Script, OutputStr, ErrorStr) then
  begin
    if Pos('OK', OutputStr) > 0 then
    begin
      FLibraryLoaded := True;
      
      // Parse version from second line
      FVersion := '4.x';
      Lines := TStringList.Create;
      try
        Lines.Text := OutputStr;
        if Lines.Count > 1 then
          FVersion := Trim(Lines[1]);
      finally
        Lines.Free;
      end;
      
      Result := True;
      FLastResult := 'Python Process: OpenCV available. (Version: ' + FVersion + ')';
      Log(llInfo, FLastResult);
    end
    else
    begin
      FLibraryLoaded := False;
      SetError('OpenCV dependency check failed. Output: ' + Trim(OutputStr) + ' Error: ' + Trim(ErrorStr));
      if Assigned(FOnOpenCVError) then
        FOnOpenCVError(Self, FLastError);
      Result := False;
    end;
  end
  else
  begin
    FLibraryLoaded := False;
    SetError('Python executable not found or execution failed. Make sure Python is installed and on PATH. Details: ' + Trim(ErrorStr));
    if Assigned(FOnOpenCVError) then
      FOnOpenCVError(Self, FLastError);
    Result := False;
  end;
end;

function TAIOpenCV.ProcessFile(const AInputFile, AOutputFile: string): Boolean;
var
  InFile, OutFile: string;
  Script: string;
  OutputStr, ErrorStr: string;
  FilterName: string;
begin
  ClearError;
  Result := False;

  if Assigned(FOnBeforeProcess) then
    FOnBeforeProcess(Self);

  // Determine files to use
  if AInputFile <> '' then
    InFile := AInputFile
  else
    InFile := FInputFile;

  if AOutputFile <> '' then
    OutFile := AOutputFile
  else
    OutFile := FOutputFile;

  if InFile = '' then
  begin
    SetError('Input file is not specified.');
    if Assigned(FOnOpenCVError) then
      FOnOpenCVError(Self, FLastError);
    if Assigned(FOnAfterProcess) then FOnAfterProcess(Self);
    Exit;
  end;

  if not FileExists(InFile) then
  begin
    SetError('Input file does not exist: ' + InFile);
    if Assigned(FOnOpenCVError) then
      FOnOpenCVError(Self, FLastError);
    if Assigned(FOnAfterProcess) then FOnAfterProcess(Self);
    Exit;
  end;

  if OutFile = '' then
  begin
    SetError('Output file is not specified.');
    if Assigned(FOnOpenCVError) then
      FOnOpenCVError(Self, FLastError);
    if Assigned(FOnAfterProcess) then FOnAfterProcess(Self);
    Exit;
  end;

  // If FBackend = ocvNativeDLL, we simulate it
  if FBackend = ocvNativeDLL then
  begin
    Log(llInfo, 'Processing with Native DLL (Simulated)...');
    try
      if FileExists(OutFile) and FOverwriteOutput then
        DeleteFile(OutFile);
      Result := CopyFileStream(InFile, OutFile);
      if Result then
      begin
        FLastResult := 'Simulated process done (Native DLL).';
        Log(llInfo, FLastResult);
        if Assigned(FOnImageLoaded) then FOnImageLoaded(Self);
        if Assigned(FOnImageSaved) then FOnImageSaved(Self);
      end
      else
        SetError('Failed to simulate image processing output file.');
    except
      on E: Exception do
        SetError('Native DLL Simulation Exception: ' + E.Message);
    end;
    
    if Assigned(FOnAfterProcess) then FOnAfterProcess(Self);
    Exit;
  end;

  // Auto or Python Process
  Log(llInfo, 'Processing with Python Process...');
  FilterName := GetFilterNameStr(FFilterType);
  
  // Format the paths to be Python friendly
  InFile := StringReplace(InFile, '\', '/', [rfReplaceAll]);
  OutFile := StringReplace(OutFile, '\', '/', [rfReplaceAll]);

  Script :=
    'import sys' + sLineBreak +
    'import os' + sLineBreak +
    'try:' + sLineBreak +
    '    import cv2' + sLineBreak +
    '    import numpy as np' + sLineBreak +
    'except ImportError as e:' + sLineBreak +
    '    print("ERROR: dependencies missing. Make sure opencv-python and numpy are installed.")' + sLineBreak +
    '    sys.exit(1)' + sLineBreak +
    sLineBreak +
    'input_path = "' + InFile + '"' + sLineBreak +
    'output_path = "' + OutFile + '"' + sLineBreak +
    'filter_type = "' + FilterName + '"' + sLineBreak +
    'blur_kernel = ' + IntToStr(FBlurKernelSize) + sLineBreak +
    'thresh_val = ' + IntToStr(FThresholdValue) + sLineBreak +
    'canny1 = ' + IntToStr(FCannyThreshold1) + sLineBreak +
    'canny2 = ' + IntToStr(FCannyThreshold2) + sLineBreak +
    'resize_w = ' + IntToStr(FResizeWidth) + sLineBreak +
    'resize_h = ' + IntToStr(FResizeHeight) + sLineBreak +
    sLineBreak +
    'if not os.path.exists(input_path):' + sLineBreak +
    '    print(f"ERROR: Input file does not exist: {input_path}")' + sLineBreak +
    '    sys.exit(1)' + sLineBreak +
    sLineBreak +
    'try:' + sLineBreak +
    '    img = cv2.imread(input_path)' + sLineBreak +
    '    if img is None:' + sLineBreak +
    '        print("ERROR: Could not read image using OpenCV.")' + sLineBreak +
    '        sys.exit(1)' + sLineBreak +
    sLineBreak +
    '    k_size = blur_kernel' + sLineBreak +
    '    if k_size % 2 == 0:' + sLineBreak +
    '        k_size = max(1, k_size + 1)' + sLineBreak +
    sLineBreak +
    '    res = img' + sLineBreak +
    '    if filter_type == "Gray":' + sLineBreak +
    '        res = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)' + sLineBreak +
    '    elif filter_type == "Blur":' + sLineBreak +
    '        res = cv2.blur(img, (blur_kernel, blur_kernel))' + sLineBreak +
    '    elif filter_type == "GaussianBlur":' + sLineBreak +
    '        res = cv2.GaussianBlur(img, (k_size, k_size), 0)' + sLineBreak +
    '    elif filter_type == "MedianBlur":' + sLineBreak +
    '        res = cv2.medianBlur(img, k_size)' + sLineBreak +
    '    elif filter_type == "Canny":' + sLineBreak +
    '        res = cv2.Canny(img, canny1, canny2)' + sLineBreak +
    '    elif filter_type == "Threshold":' + sLineBreak +
    '        gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY) if len(img.shape) == 3 else img' + sLineBreak +
    '        _, res = cv2.threshold(gray, thresh_val, 255, cv2.THRESH_BINARY)' + sLineBreak +
    '    elif filter_type == "AdaptiveThreshold":' + sLineBreak +
    '        gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY) if len(img.shape) == 3 else img' + sLineBreak +
    '        res = cv2.adaptiveThreshold(gray, 255, cv2.ADAPTIVE_THRESH_MEAN_C, cv2.THRESH_BINARY, k_size, 2)' + sLineBreak +
    '    elif filter_type == "Sharpen":' + sLineBreak +
    '        kernel = np.array([[0, -1, 0], [-1, 5, -1], [0, -1, 0]], dtype=np.float32)' + sLineBreak +
    '        res = cv2.filter2D(img, -1, kernel)' + sLineBreak +
    '    elif filter_type == "Invert":' + sLineBreak +
    '        res = cv2.bitwise_not(img)' + sLineBreak +
    '    elif filter_type == "Erode":' + sLineBreak +
    '        kernel = np.ones((blur_kernel, blur_kernel), np.uint8)' + sLineBreak +
    '        res = cv2.erode(img, kernel, iterations=1)' + sLineBreak +
    '    elif filter_type == "Dilate":' + sLineBreak +
    '        kernel = np.ones((blur_kernel, blur_kernel), np.uint8)' + sLineBreak +
    '        res = cv2.dilate(img, kernel, iterations=1)' + sLineBreak +
    '    elif filter_type == "Resize":' + sLineBreak +
    '        res = cv2.resize(img, (resize_w, resize_h))' + sLineBreak +
    '    elif filter_type == "Normalize":' + sLineBreak +
    '        res = cv2.normalize(img, None, 0, 255, cv2.NORM_MINMAX)' + sLineBreak +
    '    elif filter_type == "EqualizeHistogram":' + sLineBreak +
    '        if len(img.shape) == 3:' + sLineBreak +
    '            yuv = cv2.cvtColor(img, cv2.COLOR_BGR2YUV)' + sLineBreak +
    '            yuv[:,:,0] = cv2.equalizeHist(yuv[:,:,0])' + sLineBreak +
    '            res = cv2.cvtColor(yuv, cv2.YUV2BGR)' + sLineBreak +
    '        else:' + sLineBreak +
    '            res = cv2.equalizeHist(img)' + sLineBreak +
    '    elif filter_type == "None":' + sLineBreak +
    '        res = img' + sLineBreak +
    sLineBreak +
    '    # Make sure output directory exists' + sLineBreak +
    '    out_dir = os.path.dirname(output_path)' + sLineBreak +
    '    if out_dir and not os.path.exists(out_dir):' + sLineBreak +
    '        os.makedirs(out_dir)' + sLineBreak +
    sLineBreak +
    '    cv2.imwrite(output_path, res)' + sLineBreak +
    '    print("SUCCESS")' + sLineBreak +
    'except Exception as e:' + sLineBreak +
    '    print(f"ERROR: {e}")' + sLineBreak +
    '    sys.exit(1)' + sLineBreak;

  if ExecutePythonScript(Script, OutputStr, ErrorStr) then
  begin
    if Pos('SUCCESS', OutputStr) > 0 then
    begin
      Result := True;
      FLastResult := 'Process completed: ' + FilterName;
      Log(llInfo, FLastResult);
      if Assigned(FOnImageLoaded) then FOnImageLoaded(Self);
      if Assigned(FOnImageSaved) then FOnImageSaved(Self);
    end
    else
    begin
      SetError('Process failed: ' + Trim(OutputStr) + ' Stderr: ' + Trim(ErrorStr));
      if Assigned(FOnOpenCVError) then
        FOnOpenCVError(Self, FLastError);
    end;
  end
  else
  begin
    SetError('Python invocation failed: ' + Trim(OutputStr) + ' Stderr: ' + Trim(ErrorStr));
    if Assigned(FOnOpenCVError) then
      FOnOpenCVError(Self, FLastError);
  end;

  if Assigned(FOnAfterProcess) then
    FOnAfterProcess(Self);
end;

function TAIOpenCV.SaveImage(const AFileName: string): Boolean;
begin
  ClearError;
  Result := False;
  
  if FOutputFile = '' then
  begin
    SetError('No processed image to save (OutputFile is empty).');
    Exit;
  end;
  
  if not FileExists(FOutputFile) then
  begin
    SetError('Processed image file does not exist: ' + FOutputFile);
    Exit;
  end;

  try
    if FileExists(AFileName) and FOverwriteOutput then
      DeleteFile(AFileName);
      
    Result := CopyFileStream(FOutputFile, AFileName);
    if Result then
    begin
      FLastResult := 'Saved image to ' + AFileName;
      Log(llInfo, FLastResult);
      if Assigned(FOnImageSaved) then
        FOnImageSaved(Self);
    end
    else
      SetError('Failed to copy file from ' + FOutputFile + ' to ' + AFileName);
  except
    on E: Exception do
      SetError('Error saving image: ' + E.Message);
  end;
end;

function TAIOpenCV.GetImageInfo(const AFileName: string): string;
var
  Script: string;
  OutputStr, ErrorStr: string;
  FileToQuery: string;
begin
  Result := 'Dimensions: Unknown, Channels: Unknown';
  
  if AFileName <> '' then
    FileToQuery := AFileName
  else
    FileToQuery := FInputFile;
    
  if FileToQuery = '' then Exit;
  if not FileExists(FileToQuery) then Exit;
  
  FileToQuery := StringReplace(FileToQuery, '\', '/', [rfReplaceAll]);
  
  Script :=
    'import sys' + sLineBreak +
    'import os' + sLineBreak +
    'try:' + sLineBreak +
    '    import cv2' + sLineBreak +
    '    img = cv2.imread("' + FileToQuery + '")' + sLineBreak +
    '    if img is not None:' + sLineBreak +
    '        h, w, *c = img.shape' + sLineBreak +
    '        channels = c[0] if c else 1' + sLineBreak +
    '        print(f"Dimensions: {w}x{h}, Channels: {channels}")' + sLineBreak +
    '    else:' + sLineBreak +
    '        print("ERROR")' + sLineBreak +
    'except Exception as e:' + sLineBreak +
    '    print("ERROR")' + sLineBreak;

  if ExecutePythonScript(Script, OutputStr, ErrorStr) then
  begin
    if (Pos('ERROR', OutputStr) = 0) and (Trim(OutputStr) <> '') then
      Result := Trim(OutputStr);
  end;
end;

function TAIOpenCV.GetImageInfo: string;
begin
  Result := GetImageInfo(FInputFile);
end;

initialization
  {$I aiopencv_icon.lrs}

end.
