unit main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, StdCtrls,
  ComCtrls, Grids, Spin, aibase, aimodbus, ailistserialdevices;

type

  { TfrmMain }

  TfrmMain = class(TForm)
    memoLog: TMemo;
    PageControl1: TPageControl;
    pnlTop: TPanel;
    lblTitle: TLabel;
    lblStatus: TLabel;
    btnClearLog: TButton;
    tsMapaPinout: TTabSheet;
    tsOper: TTabSheet;
    tsLog: TTabSheet;
    
    // Components
    AIModbusClient1: TAIModbusClient;
    AIListSerialDevices1: TAIListSerialDevices;
    
    // Connections Panel / GroupBox
    gbConnection: TGroupBox;
    rgProtocol: TRadioGroup;
    pnlTCP: TPanel;
    lblIPAddress: TLabel;
    edtIPAddress: TEdit;
    lblPort: TLabel;
    edtPort: TEdit;
    pnlRTU: TPanel;
    lblSerialPort: TLabel;
    cbSerial: TComboBox;
    btnRefreshPorts: TButton;
    lblBaudRate: TLabel;
    cbBaudRate: TComboBox;
    btnConnect: TButton;
    btnDisconnect: TButton;
    
    // Operations GroupBox
    gbOperations: TGroupBox;
    lblSlaveID: TLabel;
    spSlaveID: TSpinEdit;
    lblAddress: TLabel;
    spAddress: TSpinEdit;
    lblCount: TLabel;
    spCount: TSpinEdit;
    lblValue: TLabel;
    spValue: TSpinEdit;
    chkAllowWrite: TCheckBox;
    btnRead: TButton;
    btnWrite: TButton;
    
    // Pinout Grid
    StringGridPinout: TStringGrid;
    
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btnClearLogClick(Sender: TObject);
    procedure btnRefreshPortsClick(Sender: TObject);
    procedure btnConnectClick(Sender: TObject);
    procedure btnDisconnectClick(Sender: TObject);
    procedure btnReadClick(Sender: TObject);
    procedure btnWriteClick(Sender: TObject);
    procedure rgProtocolClick(Sender: TObject);
  private
    procedure AddLog(const AMsg: string);
    procedure RefreshSerialPorts;
    procedure PopulatePinoutGrid;
    procedure UpdateUIState;
  public

  end;

var
  frmMain: TfrmMain;

implementation

{$R *.lfm}

{ TfrmMain }

procedure TfrmMain.FormCreate(Sender: TObject);
begin
  AddLog('Modbus Client Demo inicializado.');
  
  // Setup Grid
  StringGridPinout.ColCount := 7;
  StringGridPinout.RowCount := 10;
  StringGridPinout.FixedCols := 0;
  StringGridPinout.FixedRows := 1;
  StringGridPinout.Cells[0, 0] := 'Pino';
  StringGridPinout.Cells[1, 0] := 'Coil';
  StringGridPinout.Cells[2, 0] := 'Discrete Input';
  StringGridPinout.Cells[3, 0] := 'HR Modo';
  StringGridPinout.Cells[4, 0] := 'HR PWM';
  StringGridPinout.Cells[5, 0] := 'Input Register';
  StringGridPinout.Cells[6, 0] := 'Observação';
  
  PopulatePinoutGrid;
  
  cbBaudRate.ItemIndex := cbBaudRate.Items.IndexOf('9600');
  if cbBaudRate.ItemIndex = -1 then cbBaudRate.ItemIndex := 0;
  
  RefreshSerialPorts;
  
  rgProtocol.ItemIndex := 0; // RTU
  UpdateUIState;
end;

procedure TfrmMain.FormDestroy(Sender: TObject);
begin
  if AIModbusClient1.Active then
    AIModbusClient1.Disconnect;
end;

procedure TfrmMain.RefreshSerialPorts;
begin
  AIListSerialDevices1.OnlyAvailable := True;
  AIListSerialDevices1.ProbeOpenable := False;
  AIListSerialDevices1.IncludeUSBSerial := True;
  AIListSerialDevices1.IncludeBluetooth := False;
  AIListSerialDevices1.IncludeSystemPorts := False;
  AIListSerialDevices1.Refresh;
  cbSerial.Items.Clear;
  AIListSerialDevices1.GetDeviceNames(cbSerial.Items);
  if cbSerial.Items.Count > 0 then
    cbSerial.ItemIndex := 0
  else
    AddLog('Nenhuma porta serial disponível encontrada.');
end;

procedure TfrmMain.PopulatePinoutGrid;
begin
  StringGridPinout.RowCount := 10;
  
  // D0
  StringGridPinout.Cells[0, 1] := 'D0';
  StringGridPinout.Cells[1, 1] := 'Coil 0';
  StringGridPinout.Cells[2, 1] := 'DI 0';
  StringGridPinout.Cells[3, 1] := 'HR 0';
  StringGridPinout.Cells[4, 1] := 'HR 20';
  StringGridPinout.Cells[5, 1] := '-';
  StringGridPinout.Cells[6, 1] := 'Serial RX, evitar uso';
  
  // D1
  StringGridPinout.Cells[0, 2] := 'D1';
  StringGridPinout.Cells[1, 2] := 'Coil 1';
  StringGridPinout.Cells[2, 2] := 'DI 1';
  StringGridPinout.Cells[3, 2] := 'HR 1';
  StringGridPinout.Cells[4, 2] := 'HR 21';
  StringGridPinout.Cells[5, 2] := '-';
  StringGridPinout.Cells[6, 2] := 'Serial TX, evitar uso';
  
  // D2
  StringGridPinout.Cells[0, 3] := 'D2';
  StringGridPinout.Cells[1, 3] := 'Coil 2';
  StringGridPinout.Cells[2, 3] := 'DI 2';
  StringGridPinout.Cells[3, 3] := 'HR 2';
  StringGridPinout.Cells[4, 3] := 'HR 22';
  StringGridPinout.Cells[5, 3] := '-';
  StringGridPinout.Cells[6, 3] := 'Digital I/O';
  
  // D5
  StringGridPinout.Cells[0, 4] := 'D5';
  StringGridPinout.Cells[1, 4] := 'Coil 5';
  StringGridPinout.Cells[2, 4] := 'DI 5';
  StringGridPinout.Cells[3, 4] := 'HR 5';
  StringGridPinout.Cells[4, 4] := 'HR 25';
  StringGridPinout.Cells[5, 4] := '-';
  StringGridPinout.Cells[6, 4] := 'PWM Habilitado';
  
  // D13
  StringGridPinout.Cells[0, 5] := 'D13';
  StringGridPinout.Cells[1, 5] := 'Coil 13';
  StringGridPinout.Cells[2, 5] := 'DI 13';
  StringGridPinout.Cells[3, 5] := 'HR 13';
  StringGridPinout.Cells[4, 5] := 'HR 33';
  StringGridPinout.Cells[5, 5] := '-';
  StringGridPinout.Cells[6, 5] := 'LED Interno Arduino';
  
  // A0
  StringGridPinout.Cells[0, 6] := 'A0';
  StringGridPinout.Cells[1, 6] := '-';
  StringGridPinout.Cells[2, 6] := '-';
  StringGridPinout.Cells[3, 6] := '-';
  StringGridPinout.Cells[4, 6] := '-';
  StringGridPinout.Cells[5, 6] := 'IR 0';
  StringGridPinout.Cells[6, 6] := 'Leitura Analógica';
  
  // A1
  StringGridPinout.Cells[0, 7] := 'A1';
  StringGridPinout.Cells[1, 7] := '-';
  StringGridPinout.Cells[2, 7] := '-';
  StringGridPinout.Cells[3, 7] := '-';
  StringGridPinout.Cells[4, 7] := '-';
  StringGridPinout.Cells[5, 7] := 'IR 1';
  StringGridPinout.Cells[6, 7] := 'Leitura Analógica';
  
  // Esteira D6
  StringGridPinout.Cells[0, 8] := 'D6';
  StringGridPinout.Cells[1, 8] := 'Coil 6';
  StringGridPinout.Cells[2, 8] := 'DI 6';
  StringGridPinout.Cells[3, 8] := 'HR 6';
  StringGridPinout.Cells[4, 8] := 'HR 26';
  StringGridPinout.Cells[5, 8] := '-';
  StringGridPinout.Cells[6, 8] := 'Esteira Transportadora';
  
  // Garra D9
  StringGridPinout.Cells[0, 9] := 'D9';
  StringGridPinout.Cells[1, 9] := 'Coil 9';
  StringGridPinout.Cells[2, 9] := 'DI 9';
  StringGridPinout.Cells[3, 9] := 'HR 9';
  StringGridPinout.Cells[4, 9] := 'HR 29';
  StringGridPinout.Cells[5, 9] := '-';
  StringGridPinout.Cells[6, 9] := 'Servo Braço Robótico';
end;

procedure TfrmMain.UpdateUIState;
var
  IsActive: Boolean;
begin
  IsActive := AIModbusClient1.Active;
  
  pnlTCP.Visible := rgProtocol.ItemIndex = 1;
  pnlRTU.Visible := rgProtocol.ItemIndex = 0;
  
  rgProtocol.Enabled := not IsActive;
  edtIPAddress.Enabled := not IsActive;
  edtPort.Enabled := not IsActive;
  cbSerial.Enabled := not IsActive;
  cbBaudRate.Enabled := not IsActive;
  btnRefreshPorts.Enabled := not IsActive;
  
  btnConnect.Enabled := not IsActive;
  btnDisconnect.Enabled := IsActive;
  
  btnRead.Enabled := IsActive;
  btnWrite.Enabled := IsActive;
end;

procedure TfrmMain.rgProtocolClick(Sender: TObject);
begin
  UpdateUIState;
end;

procedure TfrmMain.btnConnectClick(Sender: TObject);
begin
  if rgProtocol.ItemIndex = 0 then
  begin
    if Trim(cbSerial.Text) = '' then
    begin
      AddLog('Erro: Nenhuma porta serial selecionada.');
      lblStatus.Caption := 'Status: Porta serial ausente';
      Exit;
    end;
    AIModbusClient1.ProtocolType := mbRTU;
    AIModbusClient1.DeviceName := cbSerial.Text;
    AIModbusClient1.BaudRate := StrToIntDef(cbBaudRate.Text, 9600);
    AddLog('Conectando via RTU na porta ' + AIModbusClient1.DeviceName + ' (' + cbBaudRate.Text + ')...');
  end
  else
  begin
    if Trim(edtIPAddress.Text) = '' then
    begin
      AddLog('Erro: Endereço IP não informado.');
      lblStatus.Caption := 'Status: IP ausente';
      Exit;
    end;
    AIModbusClient1.ProtocolType := mbTCP;
    AIModbusClient1.IPAddress := edtIPAddress.Text;
    AIModbusClient1.Port := StrToIntDef(edtPort.Text, 502);
    AddLog('Conectando via TCP em ' + AIModbusClient1.IPAddress + ':' + edtPort.Text + '...');
  end;
  
  if AIModbusClient1.Connect then
  begin
    AddLog('Conexão estabelecida.');
    lblStatus.Caption := 'Status: Conectado';
    if rgProtocol.ItemIndex = 0 then
    begin
      AddLog('Conectado. Aguardando estabilização da porta serial...');
      Sleep(2000);
      AddLog('Pronto.');
    end;
  end;
  UpdateUIState;
end;

procedure TfrmMain.btnDisconnectClick(Sender: TObject);
begin
  AddLog('Desconectando...');
  AIModbusClient1.Disconnect;
  AddLog('Desconectado.');
  lblStatus.Caption := 'Status: Desconectado';
  UpdateUIState;
end;

procedure TfrmMain.btnReadClick(Sender: TObject);
var
  Data: array of Word;
  I: Integer;
begin
  lblStatus.Caption := 'Status: Lendo...';
  SetLength(Data, spCount.Value);
  AddLog('Lendo ' + IntToStr(spCount.Value) + ' Holding Registers a partir do endereço ' + IntToStr(spAddress.Value) + ' (Slave ID: ' + IntToStr(spSlaveID.Value) + ')...');
  
  if AIModbusClient1.ReadHoldingRegisters(spSlaveID.Value, spAddress.Value, spCount.Value, Data) then
  begin
    for I := 0 to High(Data) do
    begin
      AddLog('  HR[' + IntToStr(spAddress.Value + I) + '] = ' + IntToStr(Data[I]));
    end;
    lblStatus.Caption := 'Status: Operação concluída';
  end
  else
  begin
    AddLog('Erro na leitura: ' + AIModbusClient1.LastError);
    lblStatus.Caption := 'Status: Falha na operação';
  end;
end;

procedure TfrmMain.btnWriteClick(Sender: TObject);
begin
  if not chkAllowWrite.Checked then
  begin
    AddLog('Aviso: Escrita bloqueada pelo usuário.');
    Exit;
  end;
  
  lblStatus.Caption := 'Status: Escrevendo...';
  AddLog('Escrevendo valor ' + IntToStr(spValue.Value) + ' no registrador ' + IntToStr(spAddress.Value) + ' (Slave ID: ' + IntToStr(spSlaveID.Value) + ')...');
  
  if AIModbusClient1.WriteSingleRegister(spSlaveID.Value, spAddress.Value, spValue.Value) then
  begin
    AddLog('Escrita concluída com sucesso.');
    lblStatus.Caption := 'Status: Operação concluída';
  end;
end;

procedure TfrmMain.btnClearLogClick(Sender: TObject);
begin
  memoLog.Clear;
end;

procedure TfrmMain.btnRefreshPortsClick(Sender: TObject);
begin
  AddLog('Recarregando portas seriais...');
  RefreshSerialPorts;
end;

procedure TfrmMain.AddLog(const AMsg: string);
begin
  memoLog.Lines.Add(AMsg);
end;

end.
