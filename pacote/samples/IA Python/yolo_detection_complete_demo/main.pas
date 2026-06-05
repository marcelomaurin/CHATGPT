unit main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, StdCtrls,
  aibase, yolodetect;

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
begin
  lblStatus.Caption := 'Status: Processing...';
  AddLog('--- Starting Execution ---');
  try
  FAIYolo.ConfidenceThreshold := 0.5;
  FAIYolo.ModelPath := 'yolov8n.pt';
  FAIYolo.TargetDevice := 'GPU';
  
  AddLog('YOLO Object Detector Properties:');
  AddLog('  ModelPath: ' + FAIYolo.ModelPath);
  AddLog('  ConfThreshold: ' + FloatToStr(FAIYolo.ConfidenceThreshold));
  AddLog('  TargetDevice: ' + FAIYolo.TargetDevice);
  
  if chkSimulation.Checked then
  begin
    AddLog('Simulating YOLO image scanning...');
    AddLog('Scanning street_traffic.jpg:');
    AddLog('  [Object 1]: Class="Person", Box=[120, 340, 200, 480], Score=0.88');
    AddLog('  [Object 2]: Class="Car", Box=[450, 200, 600, 350], Score=0.92');
    AddLog('  [Object 3]: Class="Traffic Light", Box=[10, 50, 40, 120], Score=0.74');
    AddLog('Annotated image street_traffic_yolo.jpg created (Simulated).');
  end
  else
  begin
    AddLog('Initializing YOLO python environment & weights: ' + FAIYolo.ModelPath);
    try
      if FAIYolo.InitializeModel then
      begin
        FAIYolo.DetectObjects(FEditInput.Text, 'street_traffic_yolo.jpg');
        AddLog('Yolo execution finished successfully.');
      end
      else
        AddLog('Failed to start YOLO client: ' + FAIYolo.LastError);
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
