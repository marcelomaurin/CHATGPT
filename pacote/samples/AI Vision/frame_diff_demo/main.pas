unit main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, StdCtrls,
  aibase, aiframediff, aimotiontracker;

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
    FAIFrameDiff: TAIFrameDiff; FMotionTracker: TAIMotionTracker;
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
  AddLog('Frame Diff Demo (aiframediff) initialized.');
  FAIFrameDiff := TAIFrameDiff.Create(Self);
  FMotionTracker := TAIMotionTracker.Create(Self);
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
  FAIFrameDiff.Threshold := 35;
  FAIFrameDiff.Mode := fdmAbsolute;
  FMotionTracker.Sensitivity := 10;
  
  AddLog('Frame Diff & Motion Tracker Properties:');
  AddLog('  Threshold: ' + IntToStr(FAIFrameDiff.Threshold));
  AddLog('  Sensitivity: ' + IntToStr(FMotionTracker.Sensitivity));
  
  if chkSimulation.Checked then
  begin
    AddLog('Simulating frame evaluation difference analysis...');
    AddLog('Frame A: 640x480 | Frame B: 640x480');
    // Call methods
    FAIFrameDiff.ProcessDiff('frameA.bmp', 'frameB.bmp', 'diff.bmp');
    AddLog('Absolute difference calculated. Matrix difference threshold pixels: 1245');
    FMotionTracker.TrackMotion('diff.bmp');
    AddLog('Motion percentage: 4.8% -> Alert: None');
    AddLog('Simulation complete.');
  end
  else
  begin
    AddLog('Processing real frame buffer difference details...');
    try
      FAIFrameDiff.ProcessDiff('frameA.bmp', 'frameB.bmp', 'diff.bmp');
      AddLog('Frame process completed.');
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
