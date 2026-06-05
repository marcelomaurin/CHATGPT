unit main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, StdCtrls,
  aibase, cnnclassifier;

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
    FAICNN: TCNNClassifier; FEditImage: TEdit;
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
  AddLog('Cnn Classifier Complete Demo (cnnclassifier) initialized.');
  FAICNN := TCNNClassifier.Create(Self);
  
  FEditImage := TEdit.Create(Self);
  FEditImage.Parent := pnlTop;
  FEditImage.Left := 15;
  FEditImage.Top := 115;
  FEditImage.Width := 300;
  FEditImage.Text := 'product_sample.jpg';
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
  FAICNN.WeightsFile := 'weights.h5';
  FAICNN.Threshold := 0.75;
  FAICNN.BackendMode := 'TensorFlow';
  
  AddLog('CNN Classifier Properties:');
  AddLog('  WeightsFile: ' + FAICNN.WeightsFile);
  AddLog('  Threshold: ' + FloatToStr(FAICNN.Threshold));
  AddLog('  BackendMode: ' + FAICNN.BackendMode);
  
  if chkSimulation.Checked then
  begin
    AddLog('Simulating CNN image forward pass...');
    AddLog('Input frame: ' + FEditImage.Text);
    AddLog('Predicted Class Index: 4');
    AddLog('Class Label: "Crankshaft_TypeB"');
    AddLog('Confidence Score: 94.6%');
    AddLog('Simulation complete.');
  end
  else
  begin
    AddLog('Loading model and forwarding real image matrix...');
    try
      if FAICNN.LoadWeights then
      begin
        FAICNN.ClassifyFrame(FEditImage.Text);
        AddLog('Classified Label: ' + FAICNN.LastLabel + ' | Confidence: ' + FloatToStr(FAICNN.LastConfidence));
      end
      else
        AddLog('Failed loading CNN weights: ' + FAICNN.LastError);
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
