unit main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, StdCtrls,
  aibase, aiphysicssimulator, aitrainingenvironment;

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
    FAIPhysics: TAIPhysicsSimulator; FAIEnv: TAITrainingEnvironment; FEditGravity: TEdit;
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
  AddLog('Physics Training Demo (aiphysicssimulator) initialized.');
  FAIPhysics := TAIPhysicsSimulator.Create(Self);
  FAIEnv := TAITrainingEnvironment.Create(Self);
  
  FEditGravity := TEdit.Create(Self);
  FEditGravity.Parent := pnlTop;
  FEditGravity.Left := 15;
  FEditGravity.Top := 115;
  FEditGravity.Width := 100;
  FEditGravity.Text := '-9.81';
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
  // Set physics simulation options
  FAIPhysics.Gravity := StrToFloat(FEditGravity.Text);
  
  AddLog('Physics & Environment Training Properties:');
  AddLog('  Gravity: ' + FloatToStr(FAIPhysics.Gravity));
  
  if chkSimulation.Checked then
  begin
    AddLog('Simulating agent steps in environment...');
    FAIEnv.ResetEpisode;
    AddLog('Environment reset.');
    
    // Simulate step loops
    AddLog('Step 1: Action=[0.5, 0.1] -> Reward: 0.12');
    AddLog('Step 2: Action=[0.6, 0.2] -> Reward: 0.35');
    AddLog('Step 3: Action=[0.8, 0.4] -> Reward: 0.96 (Goal Reached!)');
    AddLog('Simulated training epoch finished successfully.');
  end
  else
  begin
    AddLog('Running actual physics simulation steps...');
    try
      FAIEnv.ResetEpisode;
      FAIEnv.Step('ApplyForce: [0.5, 0.1, 0.0]');
      AddLog('Step completed.');
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
