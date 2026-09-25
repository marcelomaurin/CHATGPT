unit main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, StdCtrls,
  aibase, aicapturesource, aicamera_backend;

type
  TfrmMain = class(TForm)
    pnlTop: TPanel;
    pnlPreview: TPanel;
    lblTitle: TLabel;
    lblStatus: TLabel;
    chkSimulation: TCheckBox;
    btnRun: TButton;
    btnClearLog: TButton;
    memoLog: TMemo;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btnRunClick(Sender: TObject);
    procedure btnClearLogClick(Sender: TObject);
  private
    FAICamera: TAICaptureSource;
    FEditDevice: TEdit;
    FLastCaptureError: string;
    procedure AddLog(const AMsg: string);
    procedure CameraError(Sender: TObject; const AError: string);
    procedure UpdateControls;
  end;

var
  frmMain: TfrmMain;

implementation

{$R *.lfm}

procedure TfrmMain.FormCreate(Sender: TObject);
begin
  FAICamera := TAICaptureSource.Create(Self);
  FAICamera.OnError := @CameraError;
  FEditDevice := TEdit.Create(Self);
  FEditDevice.Parent := pnlTop;
  FEditDevice.SetBounds(15, 115, 100, 25);
  FEditDevice.Text := '0';
  FEditDevice.Hint := 'VFW camera driver index (0-9)';
  FEditDevice.ShowHint := True;
  AddLog('Camera preview ready. Enter a camera index and click Start Camera.');
  UpdateControls;
end;

procedure TfrmMain.FormDestroy(Sender: TObject);
begin
  // Release the native capture window before its parent panel is destroyed.
  if Assigned(FAICamera) then
    FAICamera.StopCapture;
end;

procedure TfrmMain.UpdateControls;
begin
  FEditDevice.Enabled := not FAICamera.Active;
  chkSimulation.Enabled := not FAICamera.Active;
  if FAICamera.Active then
    btnRun.Caption := 'Stop Camera'
  else
    btnRun.Caption := 'Start Camera';
end;

procedure TfrmMain.CameraError(Sender: TObject; const AError: string);
begin
  lblStatus.Caption := 'Status: Capture Error (see log)';
  if FLastCaptureError <> AError then
    AddLog('Camera error: ' + AError);
  FLastCaptureError := AError;
end;

procedure TfrmMain.btnRunClick(Sender: TObject);
var
  DeviceIndex: Integer;
begin
  if FAICamera.Active then
  begin
    FAICamera.StopCapture;
    lblStatus.Caption := 'Status: Stopped';
    AddLog('Camera stopped.');
    pnlPreview.Invalidate;
    UpdateControls;
    Exit;
  end;

  FLastCaptureError := '';
  if chkSimulation.Checked then
  begin
    AddLog('Simulation: no camera is opened. Disable Simulation Mode for live preview.');
    lblStatus.Caption := 'Status: Simulation Completed';
    Exit;
  end;

  if not TryStrToInt(FEditDevice.Text, DeviceIndex) or
     (DeviceIndex < 0) or (DeviceIndex > 9) then
  begin
    CameraError(Self, 'Enter a VFW camera driver index from 0 to 9.');
    Exit;
  end;

  lblStatus.Caption := 'Status: Connecting...';
  try
    FAICamera.SourceKind := cskCameraLocal;
    FAICamera.CameraIndex := DeviceIndex;
    FAICamera.FPS := 30;
    FAICamera.Backend := cbWindowsVFW;
    FAICamera.Width := pnlPreview.ClientWidth;
    FAICamera.Height := pnlPreview.ClientHeight;
    FAICamera.PreviewEnabled := True;
    FAICamera.PreviewHandle := pnlPreview.Handle;
    AddLog('Connecting to camera driver ' + IntToStr(DeviceIndex) + '...');
    if FAICamera.StartCapture then
    begin
      lblStatus.Caption := 'Status: Camera Active';
      AddLog('Live preview active. Click Stop Camera to release the device.');
    end
    else
      CameraError(Self, FAICamera.LastError);
  except
    on E: Exception do
    begin
      FAICamera.StopCapture;
      CameraError(Self, E.Message);
    end;
  end;
  UpdateControls;
end;

procedure TfrmMain.btnClearLogClick(Sender: TObject);
begin
  memoLog.Clear;
  FLastCaptureError := '';
end;

procedure TfrmMain.AddLog(const AMsg: string);
begin
  memoLog.Lines.Add(AMsg);
end;

end.
