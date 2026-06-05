unit main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, StdCtrls,
  aibase, aidatasetgenerator;

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
    FAIGenerator: TAIDatasetGenerator; FEditSamples: TEdit;
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
  AddLog('Dataset Generator Visual Demo (aidatasetgenerator) initialized.');
  FAIGenerator := TAIDatasetGenerator.Create(Self);
  
  FEditSamples := TEdit.Create(Self);
  FEditSamples.Parent := pnlTop;
  FEditSamples.Left := 15;
  FEditSamples.Top := 115;
  FEditSamples.Width := 100;
  FEditSamples.Text := '200';
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
  FAIGenerator.SampleCount := StrToInt(FEditSamples.Text);
  FAIGenerator.NoiseLevel := 0.05;
  FAIGenerator.TargetFormat := 'CSV';
  
  AddLog('Dataset Generator Properties:');
  AddLog('  SampleCount: ' + IntToStr(FAIGenerator.SampleCount));
  AddLog('  NoiseLevel: ' + FloatToStr(FAIGenerator.NoiseLevel));
  AddLog('  TargetFormat: ' + FAIGenerator.TargetFormat);
  
  if chkSimulation.Checked then
  begin
    AddLog('Simulating dataset file generation...');
    FAIGenerator.GenerateClassificationData('sim_dataset.csv');
    AddLog('Created 200 samples of binary classification pairs.');
    AddLog('Input feature dimension: 2');
    AddLog('Noise variance added: 5% gaussian variance.');
    AddLog('Dataset file generated: sim_dataset.csv (Simulated).');
  end
  else
  begin
    AddLog('Generating production dataset...');
    try
      if FAIGenerator.GenerateDataset('dataset_train.csv') then
        AddLog('Dataset successfully generated.')
      else
        AddLog('Generation failed: ' + FAIGenerator.LastError);
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
