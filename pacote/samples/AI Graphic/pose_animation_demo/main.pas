unit main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, StdCtrls,
  aibase, aiposelibrary, aianimationsequence, aiskeletonrig;

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
    FAIPoseLibrary: TAIPoseLibrary; FAIAnimSeq: TAIAnimationSequence; FAISkeleton: TAISkeletonRig;
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
  AddLog('Pose Animation Demo (aiposelibrary) initialized.');
  FAISkeleton := TAISkeletonRig.Create(Self);
  FAIPoseLibrary := TAIPoseLibrary.Create(Self);
  FAIAnimSeq := TAIAnimationSequence.Create(Self);
  
  FAIPoseLibrary.Skeleton := FAISkeleton;
  FAIAnimSeq.PoseLibrary := FAIPoseLibrary;
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
  FAIAnimSeq.FrameRate := 30;
  FAIAnimSeq.Loop := True;
  FAIAnimSeq.DurationSeconds := 2.5;
  
  AddLog('Pose Animation Properties:');
  AddLog('  FrameRate: ' + IntToStr(FAIAnimSeq.FrameRate));
  AddLog('  Loop: ' + BoolToStr(FAIAnimSeq.Loop, True));
  AddLog('  DurationSeconds: 2.5');
  
  if chkSimulation.Checked then
  begin
    AddLog('Simulating timeline interpolation sequence...');
    // Add poses
    FAIPoseLibrary.RegisterPose('T-Pose');
    FAIPoseLibrary.RegisterPose('Walking-Key1');
    FAIPoseLibrary.RegisterPose('Walking-Key2');
    AddLog('Registered 3 standard poses: T-Pose, Walking-Key1, Walking-Key2');
    
    // Animate
    FAIAnimSeq.BuildSequence;
    AddLog('Animation build sequence compiled. Frames Count: 75');
    AddLog('Interpolation method: Linear (Simulated).');
  end
  else
  begin
    AddLog('Initializing production animation matrix...');
    try
      FAIAnimSeq.Play;
      Sleep(100);
      FAIAnimSeq.Stop;
      AddLog('Play & Stop execution completed successfully.');
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
