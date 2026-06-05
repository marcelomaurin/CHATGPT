unit main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, StdCtrls,
  aibase, aicameracapture, aicamera_backend;

type

  { TfrmMain }

  TfrmMain = class(TForm)
    pnlTop: TPanel;
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
    FAICamera: TAICameraCapture; FEditDevicePath: TEdit;
    procedure AddLog(const AMsg: string);
  public

  end;

var
  frmMain: TfrmMain;

implementation

{$R *.lfm}

{ TfrmMain }

procedure TfrmMain.FormCreate(Sender: TObject);
begin
  AddLog('Camera Capture Linux Demo (aicameracapture) initialized.');
  FAICamera := TAICameraCapture.Create(Self);
  
  FEditDevicePath := TEdit.Create(Self);
  FEditDevicePath.Parent := pnlTop;
  FEditDevicePath.Left := 15;
  FEditDevicePath.Top := 115;
  FEditDevicePath.Width := 200;
  FEditDevicePath.Text := '/dev/video0';
end;

procedure TfrmMain.FormDestroy(Sender: TObject);
begin
  // Handled by LCL Owner auto-free.
end;

procedure TfrmMain.btnRunClick(Sender: TObject);
begin
  lblStatus.Caption := 'Status: Processing...';
  AddLog('--- Starting Execution ---');
  try
  FAICamera.DeviceName := FEditDevicePath.Text;
  FAICamera.FPS := 25;
  FAICamera.Backend := cbLinuxV4L2;
  
  AddLog('Linux Camera Capture Properties:');
  AddLog('  DeviceName: ' + FAICamera.DeviceName);
  AddLog('  FPS: ' + IntToStr(FAICamera.FPS));
  AddLog('  Backend: cbLinuxV4L2');
  
  if chkSimulation.Checked then
  begin
    AddLog('Simulating Linux V4L2 frame query...');
    FAICamera.StartCapture;
    AddLog('Stream active on ' + FAICamera.DeviceName);
    AddLog('QueryFrame: Frame obtained. Pixels: 1280x720 RGB24 (Simulated).');
    FAICamera.StopCapture;
    AddLog('Linux camera stream stopped.');
  end;
  // Let's remove the empty line or keep formatting
  AddLog('Connecting to Windows device ' + FEditDevicePath.Text + '...');
  try
    FAICamera.StartCapture;
    if FAICamera.Active then
    begin
      AddLog('Capture active.');
      FAICamera.StopCapture;
    end
    else
      AddLog('Failed to bind V4L2 handler file.');
  except
    on E: Exception do AddLog('Exception: ' + E.Message);
  end;
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
  memoLog.Lines.Add(AMsg);
end;

end.
