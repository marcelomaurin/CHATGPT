unit main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, StdCtrls,
  aibase, yolodetect, pythonconnector;

type

  { TfrmMain }

  TfrmMain = class(TForm)
    pnlTop: TPanel;
    lblTitle: TLabel;
    lblStatus: TLabel;
    btnRun: TButton;
    btnClearLog: TButton;
    memoLog: TMemo;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btnRunClick(Sender: TObject);
    procedure btnClearLogClick(Sender: TObject);
  private
    FAIYolo: TYOLO; FEditInput: TEdit;
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
  AddLog('Yolo Detection Complete Demo (yolodetect) initialized.');
  FAIYolo := TYOLO.Create(Self);
  FAIYolo.PythonConnector := TPythonConnector.Create(Self);
  
  FEditInput := TEdit.Create(Self);
  FEditInput.Parent := pnlTop;
  FEditInput.Left := 15;
  FEditInput.Top := 115;
  FEditInput.Width := 300;
  FEditInput.Text := 'street_traffic.jpg';
end;

procedure TfrmMain.FormDestroy(Sender: TObject);
begin
  // Handled by LCL Owner auto-free.
end;

procedure TfrmMain.btnRunClick(Sender: TObject);
var
  ConfidenceThreshold: Double;
  ModelPath: string;
  TargetDevice: string;
  Objects: TYoloObjectArray;
begin
  lblStatus.Caption := 'Status: Processing...';
  AddLog('--- Starting Execution ---');
  try
    ConfidenceThreshold := 0.5;
    ModelPath := 'yolov8n.pt';
    TargetDevice := 'GPU';
    
    AddLog('YOLO Object Detector Properties:');
    AddLog('  ModelPath: ' + ModelPath);
    AddLog('  ConfThreshold: ' + FloatToStr(ConfidenceThreshold));
    AddLog('  TargetDevice: ' + TargetDevice);
    
    AddLog('Initializing YOLO python environment & weights: ' + ModelPath);
    try
      if (FAIYolo.PythonConnector <> nil) and not FAIYolo.PythonConnector.Active then
      begin
        FAIYolo.PythonConnector.DLLPath := 'python3.dll';
        FAIYolo.PythonConnector.Active := True;
      end;

      if (FAIYolo.PythonConnector <> nil) and FAIYolo.PythonConnector.IsInitialized then
      begin
        if FAIYolo.DetectObjects(FEditInput.Text, Objects) then
        begin
          AddLog('Yolo execution finished successfully. Objects detected: ' + IntToStr(Length(Objects)));
        end
        else
          AddLog('Failed to detect objects: ' + FAIYolo.LastError);
      end
      else
        AddLog('Failed to start YOLO client: Python interpreter not initialized.');
    except
      on E: Exception do AddLog('Exception: ' + E.Message);
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
