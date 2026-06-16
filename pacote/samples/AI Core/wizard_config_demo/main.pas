unit main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, StdCtrls,
  aibase, aiwizardconfig, aiproject, chatgpt, aipipeline;

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
    FAIWizardConfig: TAIWizardConfig; FAIProject: TAIProject; FChatGPT: TCHATGPT; FAIPipeline: TAIPipeline; FEditURL: TEdit;
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
  AddLog('Wizard Config Demo (aiwizardconfig) initialized.');
  FAIProject := TAIProject.Create(Self);
  FChatGPT := TCHATGPT.Create(Self);
  FAIPipeline := TAIPipeline.Create(Self);
  
  FAIWizardConfig := TAIWizardConfig.Create(Self);
  FAIWizardConfig.Project := FAIProject;
  FAIWizardConfig.ChatGPT := FChatGPT;
  FAIWizardConfig.Pipeline := FAIPipeline;
  
  FEditURL := TEdit.Create(Self);
  FEditURL.Parent := pnlTop;
  FEditURL.Left := 15;
  FEditURL.Top := 115;
  FEditURL.Width := 300;
  FEditURL.Text := 'http://localhost:11434';
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
  FAIWizardConfig.ProjectType := 'Assistant';
  FAIWizardConfig.ProviderName := 'Ollama';
  FAIWizardConfig.LocalURL := FEditURL.Text;
  FAIWizardConfig.SimulationMode := chkSimulation.Checked;
  
  AddLog('Wizard Config Properties:');
  AddLog('  ProjectType: ' + FAIWizardConfig.ProjectType);
  AddLog('  ProviderName: ' + FAIWizardConfig.ProviderName);
  AddLog('  LocalURL: ' + FAIWizardConfig.LocalURL);
  
  // Method 1: Apply configurations
  FAIWizardConfig.Apply;
  AddLog('Configurations applied to Project, ChatGPT and Pipeline.');
  
  // Method 2: Test connection
  if chkSimulation.Checked then
  begin
    AddLog('Simulating Connection Test...');
    if FAIWizardConfig.TestConnection then
      AddLog('Connection Status: SUCCESS (Simulated)')
    else
      AddLog('Connection Status: FAILED');
  end
  else
  begin
    AddLog('Testing actual connection to: ' + FAIWizardConfig.LocalURL);
    if FAIWizardConfig.TestConnection then
      AddLog('Connection SUCCESS')
    else
      AddLog('Connection FAILED: ' + FAIWizardConfig.LastError);
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
