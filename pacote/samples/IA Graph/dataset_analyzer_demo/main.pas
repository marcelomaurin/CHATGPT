unit main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, StdCtrls,
  aibase, aidatasetanalyzer;

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
    FAIDatasetAnalyzer: TAIDatasetAnalyzer; FEditMinSamples: TEdit;
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
  AddLog('Dataset Analyzer Demo (aidatasetanalyzer) initialized.');
  FAIDatasetAnalyzer := TAIDatasetAnalyzer.Create(Self);
  
  FEditMinSamples := TEdit.Create(Self);
  FEditMinSamples.Parent := pnlTop;
  FEditMinSamples.Left := 15;
  FEditMinSamples.Top := 115;
  FEditMinSamples.Width := 100;
  FEditMinSamples.Text := '10';
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
  FAIDatasetAnalyzer.MinSamplesPerClass := StrToInt(FEditMinSamples.Text);
  FAIDatasetAnalyzer.AutoBalance := True;
  
  AddLog('Dataset Analyzer Properties:');
  AddLog('  MinSamplesPerClass: ' + IntToStr(FAIDatasetAnalyzer.MinSamplesPerClass));
  AddLog('  AutoBalance: ' + BoolToStr(FAIDatasetAnalyzer.AutoBalance, True));
  
  if chkSimulation.Checked then
  begin
    AddLog('Simulating dataset evaluation analysis...');
    AddLog('Dataset analysis results:');
    AddLog('  Total samples: 150');
    AddLog('  Classes detected: 3 (Class A, Class B, Class C)');
    AddLog('  Class A count: 70 | Class B count: 65 | Class C count: 15');
    AddLog('  Balance check: OK (No extreme imbalances detected)');
    AddLog('  Missing/Nan inputs: 0');
    AddLog('Simulation complete.');
  end
  else
  begin
    AddLog('Running real dataset analysis steps...');
    try
      if FAIDatasetAnalyzer.AnalyzeDataset('train_dataset.csv') then
        AddLog('Analysis reports generated.')
      else
        AddLog('Failed: ' + FAIDatasetAnalyzer.LastError);
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
