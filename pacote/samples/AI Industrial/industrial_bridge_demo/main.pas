unit main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, StdCtrls,
  aibase, aiindustrial;

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
    FAIBridge: TAIIndustrialBridge; FEditPlcModel: TEdit;
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
  AddLog('Industrial Bridge Demo (aiindustrial) initialized.');
  FAIBridge := TAIIndustrialBridge.Create(Self);
  
  FEditPlcModel := TEdit.Create(Self);
  FEditPlcModel.Parent := pnlTop;
  FEditPlcModel.Left := 15;
  FEditPlcModel.Top := 115;
  FEditPlcModel.Width := 150;
  FEditPlcModel.Text := 'Siemens S7-1200';
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
  FAIBridge.PlcType := FEditPlcModel.Text;
  FAIBridge.PlcIP := '192.168.0.1';
  FAIBridge.Rack := 0;
  FAIBridge.Slot := 1;
  
  AddLog('Industrial Bridge Properties:');
  AddLog('  PlcType: ' + FAIBridge.PlcType);
  AddLog('  IP: ' + FAIBridge.PlcIP);
  
  if chkSimulation.Checked then
  begin
    AddLog('Simulating Industrial PLC Bridge link...');
    if FAIBridge.ConnectBridge then
    begin
      AddLog('Connected to S7 PLC at ' + FAIBridge.PlcIP);
      AddLog('Reading telemetry variables DB10.DBW0: 420 (Normal)');
      AddLog('Reading telemetry variables DB10.DBW2: 65 (Optimal)');
      AddLog('Predictive status: OK');
    end;
  end
  else
  begin
    AddLog('Attempting connection to PLC ' + FAIBridge.PlcIP);
    try
      if FAIBridge.ConnectBridge then
      begin
        AddLog('S7 Connection established.');
        FAIBridge.DisconnectBridge;
      end
      else
        AddLog('PLC connection timeout: ' + FAIBridge.LastError);
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
