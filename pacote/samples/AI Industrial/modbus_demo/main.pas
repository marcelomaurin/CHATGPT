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
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btnRunClick(Sender: TObject);
    procedure btnClearLogClick(Sender: TObject);
  private
    FAIModbus: TAIModbusClient;
    FSerialDevices: TAIListSerialDevices;
    FEditRegister: TEdit;
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
  AddLog('Modbus RTU Demo (aimodbus) initialized.');
  FAIModbus := TAIModbusClient.Create(Self);
  FAIModbus.ProtocolType := mbRTU;
  
  FSerialDevices := TAIListSerialDevices.Create(Self);
  RefreshSerialPorts;
  
  FEditRegister := TEdit.Create(Self);
  FEditRegister.Parent := pnlTop;
  FEditRegister.Left := 350;
  FEditRegister.Top := 67;
  FEditRegister.Width := 100;
  FEditRegister.Text := '10'; // Default Modbus Register
end;

procedure TfrmMain.FormDestroy(Sender: TObject);
begin
  // Handled by LCL Owner auto-free.
end;

procedure TfrmMain.RefreshSerialPorts;
begin
  FSerialDevices.Refresh;
  cbSerial.Items.Clear;
  FSerialDevices.GetDeviceNames(cbSerial.Items);
  if cbSerial.Items.Count > 0 then
    cbSerial.ItemIndex := 0
  else
    AddLog('Nenhuma porta serial encontrada.');
end;

procedure TfrmMain.btnRunClick(Sender: TObject);
var
  Data: array[0..0] of Word;
begin
  lblStatus.Caption := 'Status: Processing...';
  AddLog('--- Starting Modbus RTU Execution ---');
  try
    FAIModbus.DeviceName := cbSerial.Text;
    FAIModbus.BaudRate := 9600;
    
    AddLog('Modbus RTU Client Properties:');
    AddLog('  DeviceName: ' + FAIModbus.DeviceName);
    AddLog('  BaudRate: ' + IntToStr(FAIModbus.BaudRate));
    
    AddLog('Connecting to Modbus RTU Slave...');
    try
      if FAIModbus.Connect then
      begin
        AddLog('Modbus RTU Connected.');
        
        // Example read operation
        AddLog('Reading holding register: ' + FEditRegister.Text);
        if FAIModbus.ReadHoldingRegisters(1, StrToIntDef(FEditRegister.Text, 10), 1, Data) then
          AddLog('Read value: ' + IntToStr(Data[0]))
        else
          AddLog('Read failed: ' + FAIModbus.LastError);
          
        FAIModbus.Disconnect;
        AddLog('Disconnected.');
      end
      else
        AddLog('Failed to connect: ' + FAIModbus.LastError);
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
