unit main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, StdCtrls,
  aibase, aioutput, aiinput;

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
    FAIOutput: TAIOutputData; FAIInput: TAIInputData;
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
  AddLog('Output Text Json Demo (aioutput) initialized.');
  FAIOutput := TAIOutputData.Create(Self);
  FAIInput := TAIInputData.Create(Self);
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
  // Method 1: Set output options
  FAIOutput.ClassificationResult := 'Normal Operations';
  SetLength(FAIOutput.Probabilities, 3);
  FAIOutput.Probabilities[0] := 0.05;
  FAIOutput.Probabilities[1] := 0.90;
  FAIOutput.Probabilities[2] := 0.05;
  
  AddLog('Output Data Properties:');
  AddLog('  ClassificationResult: ' + FAIOutput.ClassificationResult);
  AddLog('  Probabilities: [0.05, 0.90, 0.05]');
  
  // Method 2: Convert/format
  FAIOutput.SoftMax;
  AddLog('After SoftMax applied.');
  
  if chkSimulation.Checked then
  begin
    AddLog('Simulated formatting text and export:');
    AddLog('Format: JSON');
    AddLog('Exported JSON String:');
    AddLog('  { "result": "Normal Operations", "prob_normal": 0.90, "timestamp": "2026-06-05" }');
  end
  else
  begin
    AddLog('Exporting formatted files...');
    try
      FAIOutput.UpdateResult;
      AddLog('Formatted CSV: ' + FAIOutput.ClassificationResult);
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
