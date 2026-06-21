unit main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, StdCtrls,
  aibase, aidatasetgenerator, NeuralNetwork;

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
var
  Inputs, Targets: TMatrix;
  I: Integer;
begin
  lblStatus.Caption := 'Status: Processing...';
  AddLog('--- Starting Execution ---');
  try
  AddLog('Dataset Generator Initialized.');
  
  if chkSimulation.Checked then
  begin
    AddLog('Simulating dataset file generation...');
    FAIGenerator.Clear;
    for I := 1 to StrToInt(FEditSamples.Text) do
      FAIGenerator.AddDataRow(Format('%.2f;%.2f', [Random * 10, Random * 10]), Format('%d', [Random(2)]));
    FAIGenerator.SaveAsCSV('sim_dataset.csv', ';');
    AddLog('Created ' + FEditSamples.Text + ' samples of binary classification pairs.');
    AddLog('Dataset file generated: sim_dataset.csv (Simulated).');
  end
  else
  begin
    AddLog('Generating production dataset...');
    try
      FAIGenerator.Clear;
      FAIGenerator.AddDataRow('0.5;0.1', '1');
      FAIGenerator.AddDataRow('0.1;0.9', '0');
      FAIGenerator.SaveAsCSV('dataset_train.csv', ';');
      AddLog('Dataset successfully generated.');
      
      // Load back for testing
      FAIGenerator.LoadFromCSV('dataset_train.csv', Inputs, Targets, 2, 1, ';');
      AddLog('Loaded back ' + IntToStr(Length(Inputs)) + ' training rows.');
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
