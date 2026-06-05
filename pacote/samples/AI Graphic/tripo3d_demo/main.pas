unit main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, StdCtrls,
  aibase, aitripo3dclient;

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
    FAITripo3D: TAITripo3DClient; FEditPrompt: TEdit;
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
  AddLog('Tripo3D Demo (aitripo3dclient) initialized.');
  FAITripo3D := TAITripo3DClient.Create(Self);
  
  FEditPrompt := TEdit.Create(Self);
  FEditPrompt.Parent := pnlTop;
  FEditPrompt.Left := 15;
  FEditPrompt.Top := 115;
  FEditPrompt.Width := 300;
  FEditPrompt.Text := 'A futuristic robotic arm, high detail';
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
  FAITripo3D.APIKey := 'dummy-tripo-api-key';
  FAITripo3D.OutputFormat := tfOBJ;
  FAITripo3D.GenerationMode := tmTextTo3D;
  
  AddLog('Tripo3D Client Properties:');
  AddLog('  OutputFormat: OBJ');
  AddLog('  GenerationMode: TextTo3D');
  AddLog('  Prompt: ' + FEditPrompt.Text);
  
  if chkSimulation.Checked then
  begin
    AddLog('Simulating API request to Tripo3D web hook...');
    AddLog('Sending task creation request: Prompt="' + FEditPrompt.Text + '"');
    AddLog('Created Task ID: task_tripo_abc123');
    AddLog('Task status: PROCESSING... (Progress: 35%)');
    AddLog('Task status: COMPLETED. Dowloading mesh payload (OBJ format)...');
    AddLog('Mesh saved: task_tripo_abc123.obj (Size: 2.3 MB)');
    AddLog('Simulation complete.');
  end
  else
  begin
    AddLog('Sending actual API request (production validation)...');
    try
      if FAITripo3D.GenerateFromText(FEditPrompt.Text) then
        AddLog('Task submitted successfully. ID: ' + FAITripo3D.LastTaskId)
      else
        AddLog('Submission failed: ' + FAITripo3D.LastError);
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
