unit main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, StdCtrls,
  aibase, aimqtt;

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
    FAIMQTT: TAIMQTTClient; FEditBroker: TEdit; FEditTopic: TEdit;
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
  AddLog('Mqtt Demo (aimqtt) initialized.');
  FAIMQTT := TAIMQTTClient.Create(Self);
  
  FEditBroker := TEdit.Create(Self);
  FEditBroker.Parent := pnlTop;
  FEditBroker.Left := 15;
  FEditBroker.Top := 115;
  FEditBroker.Width := 200;
  FEditBroker.Text := 'broker.hivemq.com';
  
  FEditTopic := TEdit.Create(Self);
  FEditTopic.Parent := pnlTop;
  FEditTopic.Left := 230;
  FEditTopic.Top := 115;
  FEditTopic.Width := 200;
  FEditTopic.Text := 'lazarus/ai/telemetry';
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
  FAIMQTT.BrokerHost := FEditBroker.Text;
  FAIMQTT.BrokerPort := 1883;
  FAIMQTT.ClientID := 'LazarusAI_Agent';
  
  AddLog('MQTT Client Properties:');
  AddLog('  Broker: ' + FAIMQTT.BrokerHost);
  AddLog('  Port: ' + IntToStr(FAIMQTT.BrokerPort));
  AddLog('  ClientID: ' + FAIMQTT.ClientID);
  
  if chkSimulation.Checked then
  begin
    AddLog('Simulating MQTT broker operations...');
    AddLog('Connected to ' + FAIMQTT.BrokerHost);
    AddLog('Subscribed to topic: ' + FEditTopic.Text);
    AddLog('Published message: {"temperature": 23.5, "status": "OK"} to ' + FEditTopic.Text);
    AddLog('Received topic update: ' + FEditTopic.Text + ' -> {"ping": "ack"}');
    AddLog('MQTT execution successfully completed (Simulated).');
  end
  else
  begin
    AddLog('Connecting to MQTT broker: ' + FAIMQTT.BrokerHost);
    try
      if FAIMQTT.ConnectBroker then
      begin
        AddLog('Broker Connected.');
        FAIMQTT.Publish(FEditTopic.Text, '{"status":"active"}');
        AddLog('Message published.');
        FAIMQTT.DisconnectBroker;
        AddLog('Disconnected.');
      end
      else
        AddLog('Failed: ' + FAIMQTT.LastError);
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
