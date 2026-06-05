unit main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, StdCtrls,
  aibase, aioscapture;

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
    FAIOSCapture: TAIOSInputCapture; FImage: TImage;
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
  AddLog('Os Capture Demo (aioscapture) initialized.');
  FAIOSCapture := TAIOSInputCapture.Create(Self);
  
  FImage := TImage.Create(Self);
  FImage.Parent := Self;
  FImage.Left := 10;
  FImage.Top := 150;
  FImage.Width := 780;
  FImage.Height := 200;
  FImage.Proportional := True;
  FImage.Center := True;
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
  FAIOSCapture.CaptureWidth := 1024;
  FAIOSCapture.CaptureHeight := 768;
  FAIOSCapture.Quality := 85;
  
  AddLog('OS Input Capture Properties:');
  AddLog('  CaptureWidth: ' + IntToStr(FAIOSCapture.CaptureWidth));
  AddLog('  CaptureHeight: ' + IntToStr(FAIOSCapture.CaptureHeight));
  AddLog('  Quality: ' + IntToStr(FAIOSCapture.Quality));
  
  if chkSimulation.Checked then
  begin
    AddLog('Simulating Screen capture...');
    // Create a mock canvas image
    FImage.Picture.Bitmap.SetSize(200, 150);
    FImage.Picture.Bitmap.Canvas.Brush.Color := clNavy;
    FImage.Picture.Bitmap.Canvas.FillRect(0, 0, 200, 150);
    FImage.Picture.Bitmap.Canvas.Font.Color := clWhite;
    FImage.Picture.Bitmap.Canvas.TextOut(10, 50, 'Simulated Screen');
    AddLog('Screenshot captured to visual TImage component (Simulated).');
  end
  else
  begin
    AddLog('Capturing real screen active context...');
    try
      if FAIOSCapture.CaptureScreen then
      begin
        AddLog('Screenshot saved: ' + FAIOSCapture.LastCaptureFile);
        if FileExists(FAIOSCapture.LastCaptureFile) then
          FImage.Picture.LoadFromFile(FAIOSCapture.LastCaptureFile);
      end
      else
        AddLog('Capture failed: ' + FAIOSCapture.LastError);
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
