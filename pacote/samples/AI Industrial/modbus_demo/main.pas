unit main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, StdCtrls,
  ComCtrls, aibase, aimodbus, ailistserialdevices;

type

  { TfrmMain }

  TfrmMain = class(TForm)
    cbSerial: TComboBox;
    Label1: TLabel;
    memoLog: TMemo;
    PageControl1: TPageControl;
    pnlTop: TPanel;
    lblTitle: TLabel;
    lblStatus: TLabel;
    btnRun: TButton;
    btnClearLog: TButton;
    tsMapaPinout: TTabSheet;
    tsOper: TTabSheet;
    tsLog: TTabSheet;
    
    // Non-visual and visual components on the form
    AIModbusClient1: TAIModbusClient;
    AIListSerialDevices1: TAIListSerialDevices;
    edtRegister: TEdit;
    lblRegister: TLabel;
    
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btnRunClick(Sender: TObject);
    procedure btnClearLogClick(Sender: TObject);
  private
    procedure AddLog(const AMsg: string);
    procedure RefreshSerialPorts;
  public

  end;

var
  frmMain: TfrmMain;

implementation

{$R *.lfm}

{ TfrmMain }

procedure TfrmMain.FormCreate(Sender: TObject);
begin
  AddLog('Modbus RTU Demo (aimodbus) initialized with Form components.');
  AIModbusClient1.ProtocolType := mbRTU;
  RefreshSerialPorts;
end;

procedure TfrmMain.FormDestroy(Sender: TObject);
begin
  // Handled automatically by owner form
end;

procedure TfrmMain.RefreshSerialPorts;
var
  I: Integer;
  Dev: TAIListSerialDeviceItem;
begin
  AIListSerialDevices1.ProbeOpenable := True;
  AIListSerialDevices1.Refresh;
  cbSerial.Items.Clear;
  for I := 0 to AIListSerialDevices1.Devices.Count - 1 do
  begin
    Dev := AIListSerialDevices1.Devices[I];
    if Dev.IsOpenable and Dev.IsAvailable then
      cbSerial.Items.Add(Dev.DeviceName);
  end;
  if cbSerial.Items.Count > 0 then
    cbSerial.ItemIndex := 0
  else
    AddLog('Nenhuma porta serial disponível encontrada.');
end;

procedure TfrmMain.btnRunClick(Sender: TObject);
var
  Data: array[0..0] of Word;
begin
  lblStatus.Caption := 'Status: Processing...';
  AddLog('--- Starting Modbus RTU Execution ---');
  try
    AIModbusClient1.DeviceName := cbSerial.Text;
    AIModbusClient1.BaudRate := 9600;
    
    AddLog('Modbus RTU Client Properties:');
    AddLog('  DeviceName: ' + AIModbusClient1.DeviceName);
    AddLog('  BaudRate: ' + IntToStr(AIModbusClient1.BaudRate));
    
    AddLog('Connecting to Modbus RTU Slave...');
    try
      if AIModbusClient1.Connect then
      begin
        AddLog('Modbus RTU Connected.');
        
        AddLog('Reading holding register: ' + edtRegister.Text);
        if AIModbusClient1.ReadHoldingRegisters(1, StrToIntDef(edtRegister.Text, 10), 1, Data) then
          AddLog('Read value: ' + IntToStr(Data[0]))
        else
          AddLog('Read failed: ' + AIModbusClient1.LastError);
          
        AIModbusClient1.Disconnect;
        AddLog('Disconnected.');
      end
      else
        AddLog('Failed to connect: ' + AIModbusClient1.LastError);
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
