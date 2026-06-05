unit main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, StdCtrls,
  aibase, aiskeletonrig;

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
    FAISkeleton: TAISkeletonRig; FEditJointName: TEdit;
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
  AddLog('Skeleton Rig Demo (aiskeletonrig) initialized.');
  FAISkeleton := TAISkeletonRig.Create(Self);
  
  FEditJointName := TEdit.Create(Self);
  FEditJointName.Parent := pnlTop;
  FEditJointName.Left := 15;
  FEditJointName.Top := 115;
  FEditJointName.Width := 150;
  FEditJointName.Text := 'RightShoulder';
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
    AddLog('Skeleton Rig Properties:');
    AddLog('  Initial JointCount: ' + IntToStr(FAISkeleton.GetJointCount));
    
    if chkSimulation.Checked then
    begin
      AddLog('Simulating BVH skeletal file loading...');
      FAISkeleton.LoadRigFromFile('humanoid.rig');
      AddLog('Joint ' + FEditJointName.Text + ' properties:');
      AddLog('  Local Rotation X: 12.5 | Y: -45.0 | Z: 0.0');
      FAISkeleton.SetBoneRotation(FEditJointName.Text, 12.5, -45.0, 0.0);
      AddLog('Joint rotation updated (Simulated).');
    end
    else
    begin
      AddLog('Opening humanoid.rig skeleton...');
      try
        FAISkeleton.LoadRigFromFile('humanoid.rig');
        if FAISkeleton.GetJointCount > 0 then
        begin
          AddLog('Rig loaded. Joints Count: ' + IntToStr(FAISkeleton.GetJointCount));
          FAISkeleton.UpdateFK;
          AddLog('UpdateFK executed.');
        end
        else
          AddLog('Humanoid rig file humanoid.rig not found or empty.');
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
