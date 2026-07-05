unit main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, ExtCtrls,
  aimodbus, aiarduinomodbuspinmap;

type

  { TfrmMain }

  TfrmMain = class(TForm)
    pnlLeft: TPanel;
    pnlRight: TPanel;
    lblTitle: TLabel;
    lblProtocol: TLabel;
    cbProtocol: TComboBox;
    lblDevice: TLabel;
    edtDevice: TEdit;
    lblPort: TLabel;
    edtPort: TEdit;
    lblBoard: TLabel;
    cbBoard: TComboBox;
    btnConnect: TButton;
    btnDisconnect: TButton;
    
    lblPinSection: TLabel;
    lblPins: TLabel;
    cbPins: TComboBox;
    lblMode: TLabel;
    cbMode: TComboBox;
    btnSetMode: TButton;
    
    lblValue: TLabel;
    edtValue: TEdit;
    btnWriteDigital: TButton;
    btnReadDigital: TButton;
    btnReadAnalog: TButton;
    btnWritePWM: TButton;
    
    memoLog: TMemo;
    
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btnConnectClick(Sender: TObject);
    procedure btnDisconnectClick(Sender: TObject);
    procedure btnSetModeClick(Sender: TObject);
    procedure btnWriteDigitalClick(Sender: TObject);
    procedure btnReadDigitalClick(Sender: TObject);
    procedure btnReadAnalogClick(Sender: TObject);
    procedure btnWritePWMClick(Sender: TObject);
    procedure cbBoardChange(Sender: TObject);
    procedure cbProtocolChange(Sender: TObject);
  private
    FModbusClient: TAIModbusClient;
    FPinMap: TAIArduinoModbusPinMap;
    procedure Log(const Msg: string);
    procedure UpdatePinsList;
  public

  end;

var
  frmMain: TfrmMain;

implementation

{$R *.lfm}

{ TfrmMain }

procedure TfrmMain.FormCreate(Sender: TObject);
begin
  FModbusClient := TAIModbusClient.Create(Self);
  FPinMap := TAIArduinoModbusPinMap.Create(Self);
  FPinMap.ModbusClient := FModbusClient;
  
  // Set default settings
  cbProtocol.ItemIndex := 0; // TCP
  edtDevice.Text := '192.168.1.100';
  edtPort.Text := '502';
  cbBoard.ItemIndex := 0; // Nano
  
  cbMode.ItemIndex := 1; // Input
  
  UpdatePinsList;
  Log('Arduino Modbus PinMap Demo initialized.');
end;

procedure TfrmMain.FormDestroy(Sender: TObject);
begin
  // Handled by Self ownership
end;

procedure TfrmMain.cbProtocolChange(Sender: TObject);
begin
  if cbProtocol.ItemIndex = 0 then
  begin
    // TCP
    lblDevice.Caption := 'IP Address:';
    edtDevice.Text := '192.168.1.100';
    lblPort.Caption := 'Port:';
    edtPort.Text := '502';
  end
  else
  begin
    // RTU
    lblDevice.Caption := 'Serial Port:';
    edtDevice.Text := 'COM3';
    lblPort.Caption := 'Baud Rate:';
    edtPort.Text := '9600';
  end;
end;

procedure TfrmMain.cbBoardChange(Sender: TObject);
begin
  case cbBoard.ItemIndex of
    0: FPinMap.BoardType := abtNano;
    1: FPinMap.BoardType := abtUno;
    2: FPinMap.BoardType := abtMega;
  end;
  UpdatePinsList;
end;

procedure TfrmMain.UpdatePinsList;
var
  I: Integer;
begin
  cbPins.Clear;
  // Apply default mapping
  case FPinMap.BoardType of
    abtNano: FPinMap.LoadArduinoNanoDefaultMap;
    abtUno: FPinMap.LoadArduinoUnoDefaultMap;
    abtMega: FPinMap.LoadArduinoMegaDefaultMap;
  end;
  
  for I := 0 to FPinMap.Pins.Count - 1 do
  begin
    cbPins.Items.Add(FPinMap.Pins[I].Name);
  end;
  if cbPins.Items.Count > 0 then
    cbPins.ItemIndex := 0;
end;

procedure TfrmMain.Log(const Msg: string);
begin
  memoLog.Lines.Add(FormatDateTime('hh:nn:ss.zzz', Now) + ' - ' + Msg);
end;

procedure TfrmMain.btnConnectClick(Sender: TObject);
begin
  if cbProtocol.ItemIndex = 0 then
  begin
    FModbusClient.ProtocolType := mbTCP;
    FModbusClient.IPAddress := edtDevice.Text;
    FModbusClient.Port := StrToIntDef(edtPort.Text, 502);
  end
  else
  begin
    FModbusClient.ProtocolType := mbRTU;
    FModbusClient.DeviceName := edtDevice.Text;
    FModbusClient.BaudRate := StrToIntDef(edtPort.Text, 9600);
  end;

  Log('Connecting to device...');
  if FPinMap.Connect then
    Log('Connected successfully!')
  else
    Log('Connection failed: ' + FPinMap.LastError);
end;

procedure TfrmMain.btnDisconnectClick(Sender: TObject);
begin
  Log('Disconnecting...');
  FPinMap.Disconnect;
  Log('Disconnected.');
end;

procedure TfrmMain.btnSetModeClick(Sender: TObject);
var
  PinName: string;
  Mode: TArduinoPinMode;
begin
  PinName := cbPins.Text;
  Mode := TArduinoPinMode(cbMode.ItemIndex);
  Log(Format('Setting Pin %s mode to %s...', [PinName, cbMode.Text]));
  
  if FPinMap.SetPinMode(PinName, Mode) then
    Log('Pin mode updated successfully.')
  else
    Log('Failed: ' + FPinMap.LastError);
end;

procedure TfrmMain.btnWriteDigitalClick(Sender: TObject);
var
  PinName: string;
  Val: Integer;
begin
  PinName := cbPins.Text;
  Val := StrToIntDef(edtValue.Text, 0);
  Log(Format('Writing Digital Pin %s = %d...', [PinName, Val]));
  
  if FPinMap.WritePin(PinName, Val) then
    Log('Write successful.')
  else
    Log('Failed: ' + FPinMap.LastError);
end;

procedure TfrmMain.btnReadDigitalClick(Sender: TObject);
var
  PinName: string;
  Val: Integer;
begin
  PinName := cbPins.Text;
  Log(Format('Reading Digital Pin %s...', [PinName]));
  
  if FPinMap.ReadPin(PinName, Val) then
    Log(Format('Read successful. Value: %d', [Val]))
  else
    Log('Failed: ' + FPinMap.LastError);
end;

procedure TfrmMain.btnReadAnalogClick(Sender: TObject);
var
  PinName: string;
  Val: Integer;
begin
  PinName := cbPins.Text;
  Log(Format('Reading Analog Pin %s...', [PinName]));
  
  if FPinMap.ReadAnalog(PinName, Val) then
    Log(Format('Read successful. Value: %d', [Val]))
  else
    Log('Failed: ' + FPinMap.LastError);
end;

procedure TfrmMain.btnWritePWMClick(Sender: TObject);
var
  PinName: string;
  Val: Integer;
begin
  PinName := cbPins.Text;
  Val := StrToIntDef(edtValue.Text, 0);
  Log(Format('Writing PWM Pin %s = %d...', [PinName, Val]));
  
  if FPinMap.SetPWM(PinName, Val) then
    Log('PWM write successful.')
  else
    Log('Failed: ' + FPinMap.LastError);
end;

end.
