unit main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, StdCtrls,
  aibase, aicapturesource, aicamera_backend;

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
    FAICamera: TAICaptureSource; FEditDevice: TEdit;
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
  AddLog('Camera Capture Windows Demo (aicameracapture) initialized.');
  FAICamera := TAICaptureSource.Create(Self);
  
  FEditDevice := TEdit.Create(Self);
  FEditDevice.Parent := pnlTop;
  FEditDevice.Left := 15;
  FEditDevice.Top := 115;
  FEditDevice.Width := 100;
  FEditDevice.Text := '0';
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
  FAICamera.CameraIndex := StrToInt(FEditDevice.Text);
  FAICamera.FPS := 30;
  FAICamera.Backend := cbWindowsVFW;
  
  AddLog('Windows Camera Capture Properties:');
  AddLog('  CameraIndex: ' + IntToStr(FAICamera.CameraIndex));
  AddLog('  FPS: ' + IntToStr(FAICamera.FPS));
  AddLog('  Backend: cbWindowsVFW');
  
  if chkSimulation.Checked then
  begin
    AddLog('Simulating Windows camera frame grabbing...');
    FAICamera.StartCapture;
    AddLog('Windows camera stream initialized. State Active = ' + BoolToStr(FAICamera.Active, True));
    Sleep(100);
    // Method grab
    AddLog('Grabbed frame at timestamp ' + FormatDateTime('hh:nn:ss.zzz', Now));
    FAICamera.StopCapture;
    AddLog('Windows camera stopped.');
  end
  else
  begin
    AddLog('Connecting to Windows device ' + FEditDevice.Text + '...');
    try
      FAICamera.StartCapture;
      if FAICamera.Active then
      begin
        AddLog('Capture active. Grabbing...');
        FAICamera.StopCapture;
      end
      else
        AddLog('Could not start capture. Driver not connected.');
    except
      on E: Exception do AddLog('Exception: ' + E.Message);
    end;
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
