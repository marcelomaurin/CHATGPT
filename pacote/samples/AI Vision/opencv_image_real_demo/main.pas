unit main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, StdCtrls,
  aibase, aiopencv, aiframeprocessor;

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
    FAIOpenCV: TAIOpenCV; FFrameProc: TAIFrameProcessor; FEditFile: TEdit;
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
  AddLog('Opencv Image Real Demo (aiopencv) initialized.');
  FAIOpenCV := TAIOpenCV.Create(Self);
  FFrameProc := TAIFrameProcessor.Create(Self);
  
  FEditFile := TEdit.Create(Self);
  FEditFile.Parent := pnlTop;
  FEditFile.Left := 15;
  FEditFile.Top := 115;
  FEditFile.Width := 300;
  FEditFile.Text := 'sample.jpg';
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
  FAIOpenCV.LibraryPath := 'opencv_world.dll';
  FFrameProc.UseGrayscale := True;
  FFrameProc.ResizeWidth := 640;
  FFrameProc.ResizeHeight := 480;
  
  AddLog('OpenCV Real Image Demo Properties:');
  AddLog('  LibraryPath: ' + FAIOpenCV.LibraryPath);
  AddLog('  UseGrayscale: ' + BoolToStr(FFrameProc.UseGrayscale, True));
  AddLog('  ResizeWidth: ' + IntToStr(FFrameProc.ResizeWidth));
  
  if chkSimulation.Checked then
  begin
    AddLog('Simulating OpenCV script matrix operations...');
    AddLog('Loaded: ' + FEditFile.Text);
    AddLog('Applied Grayscale conversion filter.');
    AddLog('Resized frame matrix to 640x480 pixels.');
    AddLog('Saved processed frame: sample_processed.jpg');
    AddLog('Process complete (Simulated).');
  end
  else
  begin
    AddLog('Validating production environment for OpenCV DLL...');
    try
      if FAIOpenCV.LoadLibraries then
      begin
        AddLog('OpenCV binaries loaded successfully.');
        FFrameProc.ProcessFrame(FEditFile.Text, 'sample_processed.jpg');
        AddLog('Frame saved.');
      end
      else
        AddLog('OpenCV binaries failed to load. Falling back.');
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
