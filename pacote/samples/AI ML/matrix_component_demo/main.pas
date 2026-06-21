unit main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, StdCtrls,
  aibase, matrizcomponent;

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
    FAIMatrix: TAMatrizComponent;
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
  AddLog('Matrix Component Demo (matrizcomponent) initialized.');
  FAIMatrix := TAMatrizComponent.Create(Self);
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
  FAIMatrix.ClearAll;
  
  // Add classification samples (Key = actual, Value = predicted)
  FAIMatrix.Add(1, 1); // True Positive
  FAIMatrix.Add(1, 1); // True Positive
  FAIMatrix.Add(0, 0); // True Negative
  FAIMatrix.Add(1, 0); // False Negative
  FAIMatrix.Add(0, 1); // False Positive
  
  AddLog('Confusion Matrix Properties:');
  AddLog('  Registered Samples Count: ' + IntToStr(FAIMatrix.Count));
  
  if chkSimulation.Checked then
  begin
    AddLog('Simulating matrix classification evaluations...');
    AddLog('Metrics (Simulated):');
    AddLog('  Precision: 0.75');
    AddLog('  Recall: 0.67');
    AddLog('  F1 Score: 0.71');
    AddLog('Simulation complete.');
  end
  else
  begin
    AddLog('Executing matrix metrics analysis...');
    try
      AddLog('Precision: ' + FloatToStr(FAIMatrix.Precision));
      AddLog('Recall: ' + FloatToStr(FAIMatrix.Recall));
      AddLog('F1 Score: ' + FloatToStr(FAIMatrix.F1Score));
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
