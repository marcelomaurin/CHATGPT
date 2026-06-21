unit main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, StdCtrls,
  aibase, aitrainingreport, aigraphmap;

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
    FAITrainingReport: TAITrainingReport; FAIGraphMap: TAIGraphMap;
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
  AddLog('Training Report Demo (aitrainingreport) initialized.');
  FAIGraphMap := TAIGraphMap.Create(Self);
  FAITrainingReport := TAITrainingReport.Create(Self);
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
  FAITrainingReport.GraphMap := FAIGraphMap;
  
  AddLog('Training Report Properties:');
  AddLog('  ReportTitle: Q2 Industrial Neural Training Log');
  AddLog('  DetailedMetrics: True');
  
  if chkSimulation.Checked then
  begin
    AddLog('Simulating report compiling...');
    AddLog('====================================');
    AddLog('Q2 Industrial Neural Training Log');
    AddLog('====================================');
    AddLog('Training status: Completed');
    AddLog('Iterations: 5000');
    AddLog('Initial Loss: 1.42');
    AddLog('Final Loss: 0.0034');
    AddLog('Report generated successfully (Simulated).');
  end
  else
  begin
    AddLog('Compiling report file...');
    try
      FAITrainingReport.SaveReport('report.txt');
      if FAITrainingReport.LastError <> '' then
        AddLog('Report compilation error: ' + FAITrainingReport.LastError)
      else
      begin
        AddLog('Training report written to report.txt');
        memoLog.Lines.AddStrings(FAITrainingReport.ReportText);
      end;
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
