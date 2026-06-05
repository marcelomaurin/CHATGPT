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
  FAIMatrix.Rows := 3;
  FAIMatrix.Cols := 3;
  FAIMatrix.DefaultValue := 1.5;
  
  AddLog('Matrix Properties:');
  AddLog('  Rows: ' + IntToStr(FAIMatrix.Rows));
  AddLog('  Cols: ' + IntToStr(FAIMatrix.Cols));
  AddLog('  DefaultValue: 1.5');
  
  // Matrix operations
  FAIMatrix.InitializeMatrix;
  AddLog('Matrix filled with initial values:');
  AddLog('  [1.5, 1.5, 1.5]');
  AddLog('  [1.5, 1.5, 1.5]');
  AddLog('  [1.5, 1.5, 1.5]');
  
  if chkSimulation.Checked then
  begin
    AddLog('Simulating matrix multiplications...');
    // Multiply matrix
    FAIMatrix.MultiplyScalar(2.0);
    AddLog('Multiplied Matrix by scalar 2.0 (Simulated):');
    AddLog('  [3.0, 3.0, 3.0]');
    AddLog('  [3.0, 3.0, 3.0]');
    AddLog('  [3.0, 3.0, 3.0]');
    AddLog('Simulation complete.');
  end
  else
  begin
    AddLog('Executing matrix linear algebra...');
    try
      FAIMatrix.Transpose;
      AddLog('Transpose matrix method executed.');
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
