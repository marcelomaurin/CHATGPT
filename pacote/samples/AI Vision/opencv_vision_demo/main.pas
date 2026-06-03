unit main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, StdCtrls,
  aiopencv, aicameracapture, aiframeprocessor, aifacetracker, aimotiontracker, aibase;

type

  { TfrmOpenCVVisionDemo }

  TfrmOpenCVVisionDemo = class(TForm)
    pnlHeader: TPanel;
    lblTitle: TLabel;
    pnlOpenCV: TPanel;
    lblOpenCVTitle: TLabel;
    btnLoadOpenCV: TButton;
    lblOpenCVStatus: TLabel;
    
    pnlCamera: TPanel;
    lblCameraTitle: TLabel;
    btnStartCamera: TButton;
    btnStopCamera: TButton;
    lblCameraStatus: TLabel;
    
    pnlProcessing: TPanel;
    lblProcTitle: TLabel;
    chkGrayscale: TCheckBox;
    chkEqualize: TCheckBox;
    btnProcessFrame: TButton;
    
    pnlTracking: TPanel;
    lblTrackTitle: TLabel;
    chkTrackFaces: TCheckBox;
    chkTrackMotion: TCheckBox;
    lblTrackStatus: TLabel;
    
    meLogs: TMemo;
    lblLogs: TLabel;
    
    tmrCamera: TTimer;

    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btnLoadOpenCVClick(Sender: TObject);
    procedure btnStartCameraClick(Sender: TObject);
    procedure btnStopCameraClick(Sender: TObject);
    procedure btnProcessFrameClick(Sender: TObject);
    procedure tmrCameraTimer(Sender: TObject);
    procedure ComponentLog(Sender: TObject; ALevel: TAILogLevel; const AMsg: string);
  private
    FOpenCV: TAIOpenCV;
    FCamera: TAICameraCapture;
    FProcessor: TAIFrameProcessor;
    FFaceTracker: TAIFaceTracker;
    FMotionTracker: TAIMotionTracker;
    
    procedure LogMsg(const AMsg: string);
    procedure UpdateUIState;
  public

  end;

var
  frmOpenCVVisionDemo: TfrmOpenCVVisionDemo;

implementation

{$R *.lfm}

{ TfrmOpenCVVisionDemo }

procedure TfrmOpenCVVisionDemo.FormCreate(Sender: TObject);
begin
  // 1. Instantiate the new AI Vision components
  FOpenCV := TAIOpenCV.Create(Self);
  FCamera := TAICameraCapture.Create(Self);
  FProcessor := TAIFrameProcessor.Create(Self);
  FFaceTracker := TAIFaceTracker.Create(Self);
  FMotionTracker := TAIMotionTracker.Create(Self);

  // 2. Set up logging redirection
  FOpenCV.OnLog := @ComponentLog;
  FCamera.OnLog := @ComponentLog;
  FProcessor.OnLog := @ComponentLog;
  FFaceTracker.OnLog := @ComponentLog;
  FMotionTracker.OnLog := @ComponentLog;

  LogMsg('AI Vision Demonstration initialized.');
  UpdateUIState;
end;

procedure TfrmOpenCVVisionDemo.FormDestroy(Sender: TObject);
begin
  // Components will be freed by the Owner (Self)
end;

procedure TfrmOpenCVVisionDemo.ComponentLog(Sender: TObject; ALevel: TAILogLevel; const AMsg: string);
var
  Prefix: string;
begin
  case ALevel of
    llDebug: Prefix := '[DEBUG] ';
    llInfo: Prefix := '[INFO] ';
    llWarning: Prefix := '[WARNING] ';
    llError: Prefix := '[ERROR] ';
  end;
  LogMsg(Prefix + Sender.ClassName + ': ' + AMsg);
end;

procedure TfrmOpenCVVisionDemo.LogMsg(const AMsg: string);
begin
  meLogs.Lines.Append('[' + FormatDateTime('hh:nn:ss.zzz', Now) + '] ' + AMsg);
end;

procedure TfrmOpenCVVisionDemo.UpdateUIState;
begin
  if FOpenCV.LibraryLoaded then
  begin
    lblOpenCVStatus.Caption := 'OpenCV Status: Loaded (' + FOpenCV.Version + ')';
    lblOpenCVStatus.Font.Color := clGreen;
  end
  else
  begin
    lblOpenCVStatus.Caption := 'OpenCV Status: Not Loaded';
    lblOpenCVStatus.Font.Color := clRed;
  end;

  if FCamera.Active then
  begin
    lblCameraStatus.Caption := 'Camera: Capturing (Device ' + IntToStr(FCamera.CameraIndex) + ')';
    lblCameraStatus.Font.Color := clGreen;
    btnStartCamera.Enabled := False;
    btnStopCamera.Enabled := True;
  end
  else
  begin
    lblCameraStatus.Caption := 'Camera: Stopped';
    lblCameraStatus.Font.Color := clRed;
    btnStartCamera.Enabled := True;
    btnStopCamera.Enabled := False;
  end;
end;

procedure TfrmOpenCVVisionDemo.btnLoadOpenCVClick(Sender: TObject);
begin
  LogMsg('Loading OpenCV libraries...');
  if FOpenCV.LoadLibraries then
  begin
    LogMsg('OpenCV libraries loaded successfully.');
  end
  else
  begin
    LogMsg('Warning: Could not load OpenCV binary libraries. Running in Simulation / Fallback Mode.');
    // Force loaded flag for simulation purposes in sample demo
    // The component provides fallback mocks if dynamic libs are missing.
  end;
  UpdateUIState;
end;

procedure TfrmOpenCVVisionDemo.btnStartCameraClick(Sender: TObject);
begin
  LogMsg('Starting camera capture...');
  FCamera.StartCapture;
  if FCamera.LastSuccess then
  begin
    tmrCamera.Enabled := True;
    LogMsg('Camera capture started.');
  end
  else
  begin
    LogMsg('Error starting camera capture: ' + FCamera.LastError);
  end;
  UpdateUIState;
end;

procedure TfrmOpenCVVisionDemo.btnStopCameraClick(Sender: TObject);
begin
  LogMsg('Stopping camera capture...');
  FCamera.StopCapture;
  tmrCamera.Enabled := False;
  LogMsg('Camera capture stopped.');
  UpdateUIState;
end;

procedure TfrmOpenCVVisionDemo.btnProcessFrameClick(Sender: TObject);
var
  DummyFrameIn, DummyFrameOut: TObject;
begin
  DummyFrameIn := TObject.Create;
  try
    LogMsg('Processing single frame manually...');
    FProcessor.Grayscale := chkGrayscale.Checked;
    DummyFrameOut := FProcessor.ProcessFrame(DummyFrameIn);
    if DummyFrameOut <> nil then
    begin
      LogMsg('Frame processed successfully.');
      DummyFrameOut.Free;
    end
    else
      LogMsg('Error processing frame: ' + FProcessor.LastError);
  finally
    DummyFrameIn.Free;
  end;
end;

procedure TfrmOpenCVVisionDemo.tmrCameraTimer(Sender: TObject);
var
  Frame: TObject;
  ProcessedFrame: TObject;
  X, Y, W, H: Integer;
begin
  // Periodic capture simulation
  Frame := FCamera.QueryFrame;
  if Frame <> nil then
  begin
    try
      // Apply frame processor options
      FProcessor.Grayscale := chkGrayscale.Checked;
      ProcessedFrame := FProcessor.ProcessFrame(Frame);
      
      if ProcessedFrame <> nil then
      begin
        try
          // Face tracking simulation
          if chkTrackFaces.Checked then
          begin
            if FFaceTracker.TrackFace(ProcessedFrame, X, Y, W, H) then
            begin
              lblTrackStatus.Caption := Format('Face Detected at X:%d Y:%d (W:%d, H:%d)', [X, Y, W, H]);
              lblTrackStatus.Font.Color := clGreen;
            end
            else
            begin
              lblTrackStatus.Caption := 'Tracking: No face detected';
              lblTrackStatus.Font.Color := clBlue;
            end;
          end;

          // Motion tracking simulation
          if chkTrackMotion.Checked then
          begin
            if FMotionTracker.DetectMotion(Frame, ProcessedFrame) then
            begin
              LogMsg('[MOTION] Significant motion detected between consecutive frames.');
            end;
          end;

        finally
          ProcessedFrame.Free;
        end;
      end;
    finally
      Frame.Free;
    end;
  end;
end;

end.
