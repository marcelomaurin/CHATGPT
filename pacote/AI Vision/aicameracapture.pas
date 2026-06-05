unit aicameracapture;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, aibase, ExtCtrls, LResources;

type
  TAICameraBackend = (
    cbOpenCVPython,
    cbNativeStub
  );

  TAIFrameEvent = procedure(Sender: TObject; const AFrameFile: string) of object;
  TAICameraErrorEvent = procedure(Sender: TObject; const AError: string) of object;
  TAICameraStateEvent = procedure(Sender: TObject; AActive: Boolean) of object;

  { TAICameraCapture }

  TAICameraCapture = class(TAIBaseComponent)
  private
    FCameraIndex: Integer;
    FActive: Boolean;
    FWidth: Integer;
    FHeight: Integer;
    FFPS: Integer;
    FBackend: TAICameraBackend;
    FLastFrameFile: string;
    FAutoDeleteTempFiles: Boolean;
    FCaptureInterval: Integer;
    FMaxCameraScan: Integer;

    FPythonPath: string;
    FScriptPath: string;

    FTimer: TTimer;
    FInTimerCall: Boolean;

    FOnFrame: TAIFrameEvent;
    FOnError: TAICameraErrorEvent;
    FOnStateChange: TAICameraStateEvent;

    // Helper functions
    function FindPythonExecutable: string;
    function ExecuteCaptureScript(const AAction: string; const AExtraParams: array of string; out AOutput: string): Boolean;
    function ValidatePython: Boolean;
    function ValidateWorker: Boolean;
    procedure OnTimerCapture(Sender: TObject);
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    function StartCapture: Boolean;
    procedure StopCapture;
    function QueryFrame: Boolean;
    function CaptureToFile(const AFileName: string): Boolean;
    function CaptureToImage(AImage: TImage): Boolean;
    function SelfTest: Boolean;
    function ListAvailableCameras: TStringList;

    property Active: Boolean read FActive;
    property LastFrameFile: string read FLastFrameFile;
  published
    property CameraIndex: Integer read FCameraIndex write FCameraIndex default 0;
    property Width: Integer read FWidth write FWidth default 640;
    property Height: Integer read FHeight write FHeight default 480;
    property FPS: Integer read FFPS write FFPS default 30;
    property Backend: TAICameraBackend read FBackend write FBackend default cbOpenCVPython;
    property AutoDeleteTempFiles: Boolean read FAutoDeleteTempFiles write FAutoDeleteTempFiles default True;
    property CaptureInterval: Integer read FCaptureInterval write FCaptureInterval default 100;
    property MaxCameraScan: Integer read FMaxCameraScan write FMaxCameraScan default 5;
    property PythonPath: string read FPythonPath write FPythonPath;
    property ScriptPath: string read FScriptPath write FScriptPath;

    // Events
    property OnFrame: TAIFrameEvent read FOnFrame write FOnFrame;
    property OnError: TAICameraErrorEvent read FOnError write FOnError;
    property OnStateChange: TAICameraStateEvent read FOnStateChange write FOnStateChange;
  end;

procedure Register;

implementation

uses
  Process, fpjson, jsonparser;

procedure Register;
begin
  RegisterComponents('AI Vision', [TAICameraCapture]);
end;

{ TAICameraCapture }

constructor TAICameraCapture.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FCategory := ccInput;
  FPrompt := 'Component TAICameraCapture captures frames from camera inputs using OpenCV and Python.';
  FCameraIndex := 0;
  FActive := False;
  FWidth := 640;
  FHeight := 480;
  FFPS := 30;
  FBackend := cbOpenCVPython;
  FLastFrameFile := '';
  FAutoDeleteTempFiles := True;
  FCaptureInterval := 100;
  FMaxCameraScan := 5;

  FPythonPath := 'python';
  FScriptPath := ExtractFilePath(ParamStr(0)) + 'python' + DirectorySeparator + 'camera_capture.py';

  FTimer := TTimer.Create(Self);
  FTimer.Enabled := False;
  FTimer.OnTimer := @OnTimerCapture;
  FInTimerCall := False;

  ClearError;
end;

destructor TAICameraCapture.Destroy;
begin
  StopCapture;
  if FAutoDeleteTempFiles and (FLastFrameFile <> '') and FileExists(FLastFrameFile) then
  begin
    try
      DeleteFile(FLastFrameFile);
    except
      // ignore
    end;
  end;
  inherited Destroy;
end;

function TAICameraCapture.FindPythonExecutable: string;
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

  if FileExists(AppDir + ExeName) then
    Exit(AppDir + ExeName);

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

  Result := ExeName;
end;

function TAICameraCapture.ExecuteCaptureScript(const AAction: string; const AExtraParams: array of string; out AOutput: string): Boolean;
var
  PyProc: TProcess;
  I: Integer;
  OutputStream: TMemoryStream;
  BytesRead: Integer;
  Buf: array[0..2047] of Byte;
  OutputStr, ErrorStr: string;
  JSONData: TJSONData;
  JSONObj: TJSONObject;
begin
  Result := False;
  AOutput := '';
  OutputStr := '';
  ErrorStr := '';
  FillChar(Buf, SizeOf(Buf), 0);
  PyProc := TProcess.Create(nil);
  try
    PyProc.Executable := FPythonPath;
    PyProc.Parameters.Add(FScriptPath);
    PyProc.Parameters.Add('--action');
    PyProc.Parameters.Add(AAction);
    
    for I := Low(AExtraParams) to High(AExtraParams) do
      PyProc.Parameters.Add(AExtraParams[I]);
      
    PyProc.Options := [poUsePipes, poNoConsole];
    
    try
      PyProc.Execute;
    except
      on E: Exception do
      begin
        SetError('Python executable not found.');
        if Assigned(FOnError) then
          FOnError(Self, FLastError);
        Exit;
      end;
    end;
    
    OutputStream := TMemoryStream.Create;
    try
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
      
      AOutput := OutputStr;
      
      if PyProc.ExitStatus <> 0 then
      begin
        // Try to parse structured JSON error first
        if Trim(OutputStr) <> '' then
        begin
          try
            JSONData := GetJSON(OutputStr);
            try
              if Assigned(JSONData) and (JSONData is TJSONObject) then
              begin
                JSONObj := TJSONObject(JSONData);
                if JSONObj.Find('error') <> nil then
                begin
                  SetError(JSONObj.Strings['error']);
                  if Assigned(FOnError) then
                    FOnError(Self, FLastError);
                  Exit;
                end;
              end;
            finally
              JSONData.Free;
            end;
          except
            // fallback if not JSON
          end;
        end;

        if Pos('ERROR:', ErrorStr) > 0 then
          SetError(Trim(ErrorStr))
        else if Pos('ERROR:', OutputStr) > 0 then
          SetError(Trim(OutputStr))
        else if Trim(ErrorStr) <> '' then
          SetError('Capture process failed. Stderr: ' + Trim(ErrorStr))
        else
          SetError('Capture process failed with code ' + IntToStr(PyProc.ExitStatus));
          
        if Assigned(FOnError) then
          FOnError(Self, FLastError);
        Exit;
      end;
      
      Result := True;
    finally
      OutputStream.Free;
    end;
  finally
    PyProc.Free;
  end;
end;

function TAICameraCapture.ValidatePython: Boolean;
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
      FPythonPath := FindPythonExecutable;
      PyProc.Executable := FPythonPath;
      try
        PyProc.Execute;
        while PyProc.Running do Sleep(10);
        Result := True;
      except
        SetError('Python executable not found.');
        if Assigned(FOnError) then
          FOnError(Self, FLastError);
      end;
    end;
  finally
    PyProc.Free;
  end;
end;

function TAICameraCapture.ValidateWorker: Boolean;
var
  FallbackPath: string;
begin
  Result := FileExists(FScriptPath);
  if not Result then
  begin
    FallbackPath := ExpandFileName(ExtractFilePath(ParamStr(0)) + '..' + DirectorySeparator + '..' + DirectorySeparator + '..' + DirectorySeparator + 'python' + DirectorySeparator + 'camera_capture.py');
    if FileExists(FallbackPath) then
    begin
      FScriptPath := FallbackPath;
      Result := True;
    end;
  end;
  
  if not Result then
  begin
    SetError('OpenCV camera capture helper script not found.');
    if Assigned(FOnError) then
      FOnError(Self, FLastError);
  end;
end;

procedure TAICameraCapture.OnTimerCapture(Sender: TObject);
begin
  if FInTimerCall then Exit;
  FInTimerCall := True;
  try
    if FActive then
      QueryFrame;
  finally
    FInTimerCall := False;
  end;
end;

function TAICameraCapture.StartCapture: Boolean;
begin
  Result := False;
  ClearError;
  
  if FActive then
  begin
    Result := True;
    Exit;
  end;

  if FBackend = cbNativeStub then
  begin
    SetError('Native camera backend is not implemented yet.');
    if Assigned(FOnError) then
      FOnError(Self, FLastError);
    Exit;
  end;

  // Temporarily set active to True so QueryFrame executes
  FActive := True; 
  try
    if not QueryFrame then
    begin
      FActive := False;
      Exit;
    end;
  except
    on E: Exception do
    begin
      FActive := False;
      SetError('Failed to capture initial frame: ' + E.Message);
      if Assigned(FOnError) then
        FOnError(Self, FLastError);
      Exit;
    end;
  end;

  FTimer.Interval := FCaptureInterval;
  FTimer.Enabled := True;
  
  if Assigned(FOnStateChange) then
    FOnStateChange(Self, True);

  Result := True;
end;

procedure TAICameraCapture.StopCapture;
begin
  if not FActive then Exit;
  
  FTimer.Enabled := False;
  FActive := False;
  
  if Assigned(FOnStateChange) then
    FOnStateChange(Self, False);
end;

function TAICameraCapture.QueryFrame: Boolean;
var
  LTempFile: string;
  LOutput: string;
  LParams: array of string;
begin
  Result := False;
  ClearError;
  LParams := nil;

  if FBackend = cbNativeStub then
  begin
    SetError('Native camera backend is not implemented yet.');
    if Assigned(FOnError) then
      FOnError(Self, FLastError);
    Exit;
  end;

  if not ValidatePython then Exit;
  if not ValidateWorker then Exit;

  LTempFile := IncludeTrailingPathDelimiter(GetTempDir) + 'tai_frame_' + IntToStr(GetTickCount64) + '.png';
  LTempFile := StringReplace(LTempFile, '\', '/', [rfReplaceAll]);

  SetLength(LParams, 8);
  LParams[0] := '--camera';
  LParams[1] := IntToStr(FCameraIndex);
  LParams[2] := '--width';
  LParams[3] := IntToStr(FWidth);
  LParams[4] := '--height';
  LParams[5] := IntToStr(FHeight);
  LParams[6] := '--output';
  LParams[7] := LTempFile;

  if ExecuteCaptureScript('capture', LParams, LOutput) then
  begin
    if FileExists(LTempFile) then
    begin
      if FAutoDeleteTempFiles and (FLastFrameFile <> '') and (FLastFrameFile <> LTempFile) and FileExists(FLastFrameFile) then
      begin
        try
          DeleteFile(FLastFrameFile);
        except
          // ignore
        end;
      end;

      FLastFrameFile := LTempFile;
      FLastResult := 'Frame captured successfully: ' + LTempFile;
      FLastSuccess := True;
      Result := True;

      if Assigned(FOnFrame) then
        FOnFrame(Self, FLastFrameFile);
    end
    else
    begin
      SetError('Frame file was not created by capture process.');
      if Assigned(FOnError) then
        FOnError(Self, FLastError);
    end;
  end;
end;

function TAICameraCapture.CaptureToFile(const AFileName: string): Boolean;
var
  LParams: array of string;
  LOutput: string;
  LFileClean: string;
begin
  Result := False;
  ClearError;
  LParams := nil;
  LOutput := '';
  LFileClean := '';

  if FBackend = cbNativeStub then
  begin
    SetError('Native camera backend is not implemented yet.');
    if Assigned(FOnError) then
      FOnError(Self, FLastError);
    Exit;
  end;

  if not ValidatePython then Exit;
  if not ValidateWorker then Exit;

  LFileClean := StringReplace(AFileName, '\', '/', [rfReplaceAll]);

  SetLength(LParams, 8);
  LParams[0] := '--camera';
  LParams[1] := IntToStr(FCameraIndex);
  LParams[2] := '--width';
  LParams[3] := IntToStr(FWidth);
  LParams[4] := '--height';
  LParams[5] := IntToStr(FHeight);
  LParams[6] := '--output';
  LParams[7] := LFileClean;

  if ExecuteCaptureScript('capture', LParams, LOutput) then
  begin
    if FileExists(AFileName) then
    begin
      FLastResult := 'Frame captured to file: ' + AFileName;
      FLastSuccess := True;
      Result := True;
    end
    else
    begin
      SetError('Output file was not created.');
      if Assigned(FOnError) then
        FOnError(Self, FLastError);
    end;
  end;
end;

function TAICameraCapture.CaptureToImage(AImage: TImage): Boolean;
begin
  Result := False;
  if not Assigned(AImage) then
  begin
    SetError('TImage nil.');
    if Assigned(FOnError) then
      FOnError(Self, FLastError);
    Exit;
  end;

  if QueryFrame then
  begin
    try
      AImage.Picture.LoadFromFile(FLastFrameFile);
      Result := True;
    except
      on E: Exception do
      begin
        SetError('Failed to load image into TImage: ' + E.Message);
        if Assigned(FOnError) then
          FOnError(Self, FLastError);
      end;
    end;
  end;
end;

function TAICameraCapture.SelfTest: Boolean;
var
  LOutput: string;
  LParams: array of string;
  JSONData: TJSONData;
  JSONObj: TJSONObject;
begin
  Result := False;
  ClearError;
  LParams := nil;

  if FBackend = cbNativeStub then
  begin
    SetError('Native camera backend is not implemented yet.');
    Exit;
  end;

  if not ValidatePython then Exit;
  if not ValidateWorker then Exit;

  SetLength(LParams, 2);
  LParams[0] := '--camera';
  LParams[1] := IntToStr(FCameraIndex);

  if not ExecuteCaptureScript('selftest', LParams, LOutput) then
    Exit;

  JSONData := nil;
  try
    try
      JSONData := GetJSON(LOutput);
    except
      on E: Exception do
      begin
        SetError('SelfTest returned invalid JSON output.');
        Exit;
      end;
    end;

    if Assigned(JSONData) and (JSONData is TJSONObject) then
    begin
      JSONObj := TJSONObject(JSONData);
      if JSONObj.Find('success') <> nil then
      begin
        if JSONObj.Booleans['success'] then
        begin
          FLastResult := 'SelfTest succeeded. ' + JSONObj.Strings['message'];
          FLastSuccess := True;
          Result := True;
        end
        else
        begin
          SetError(JSONObj.Strings['error']);
        end;
      end
      else
        SetError('SelfTest returned invalid JSON structure.');
    end
    else
      SetError('SelfTest returned invalid JSON data.');
  finally
    if Assigned(JSONData) then
      JSONData.Free;
  end;
end;

function TAICameraCapture.ListAvailableCameras: TStringList;
var
  LOutput: string;
  LParams: array of string;
  LTempList: TStringList;
begin
  LTempList := TStringList.Create;
  Result := LTempList;
  ClearError;
  LParams := nil;

  if FBackend = cbNativeStub then
  begin
    SetError('Native camera backend is not implemented yet.');
    Exit;
  end;

  if not ValidatePython then Exit;
  if not ValidateWorker then Exit;

  SetLength(LParams, 2);
  LParams[0] := '--max-scan';
  LParams[1] := IntToStr(FMaxCameraScan);

  if ExecuteCaptureScript('list', LParams, LOutput) then
  begin
    LTempList.Text := LOutput;
  end;
end;

initialization
  {$I aicameracapture_icon.lrs}

end.
