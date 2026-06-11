unit main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, StdCtrls,
  aibase, lstmpredictor;

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
    FAILSTM: TLSTMPredictor; FEditHistory: TEdit;
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
  AddLog('Lstm Timeseries Demo (lstmpredictor) initialized.');
  FAILSTM := TLSTMPredictor.Create(Self);
  
  FEditHistory := TEdit.Create(Self);
  FEditHistory.Parent := pnlTop;
  FEditHistory.Left := 15;
  FEditHistory.Top := 115;
  FEditHistory.Width := 300;
  FEditHistory.Text := 'history_data.csv';
end;

procedure TfrmMain.FormDestroy(Sender: TObject);
begin
  // Handled by LCL Owner auto-free.
end;

procedure TfrmMain.btnRunClick(Sender: TObject);
var
  Series: TDoubleArray;
  LastWindow: TDoubleArray;
  PredVal: Double;
  LookbackWindow: Integer;
  ForecastSteps: Integer;
  Epochs: Integer;
  I: Integer;
begin
  lblStatus.Caption := 'Status: Processing...';
  AddLog('--- Starting Execution ---');
  try
    LookbackWindow := 24;
    ForecastSteps := 5;
    Epochs := 10;
    
    AddLog('LSTM Timeseries Predictor Properties:');
    AddLog('  LookbackWindow: ' + IntToStr(LookbackWindow));
    AddLog('  ForecastSteps: ' + IntToStr(ForecastSteps));
    
    if chkSimulation.Checked then
    begin
      AddLog('Simulating LSTM neural forecast sequence...');
      AddLog('Loaded: ' + FEditHistory.Text);
      AddLog('Fitted sequence values successfully.');
      AddLog('Forecast predictions for next 5 timeframes:');
      AddLog('  t+1: 142.4');
      AddLog('  t+2: 145.1');
      AddLog('  t+3: 143.9');
      AddLog('  t+4: 146.2');
      AddLog('  t+5: 148.0');
      AddLog('Simulation complete.');
    end
    else
    begin
      AddLog('Training real LSTM node layout...');
      try
        SetLength(Series, 100);
        for I := 0 to 99 do
          Series[I] := I * 1.5;
          
        if FAILSTM.TrainLSTM(Series, LookbackWindow, Epochs) then
        begin
          SetLength(LastWindow, LookbackWindow);
          for I := 0 to LookbackWindow - 1 do
            LastWindow[I] := (76 + I) * 1.5;
            
          if FAILSTM.PredictNext(LastWindow, PredVal) then
            AddLog('LSTM Forecasting complete. Next predicted value: ' + FloatToStr(PredVal))
          else
            AddLog('Failed to predict: ' + FAILSTM.LastError);
        end
        else
          AddLog('Failed to train model: ' + FAILSTM.LastError);
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
