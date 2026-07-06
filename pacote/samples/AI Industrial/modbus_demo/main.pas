unit main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, StdCtrls,
  ComCtrls, Grids, Spin, aibase, aimodbus, ailistserialdevices, fpjson, jsonparser;

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
    tsConfig: TTabSheet;
    tsManip: TTabSheet;
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
    pnlCrud: TPanel;
    lblPin: TLabel;
    edtPin: TEdit;
    lblCoil: TLabel;
    edtCoil: TEdit;
    lblDI: TLabel;
    edtDI: TEdit;
    lblHRMode: TLabel;
    edtHRMode: TEdit;
    lblHRPWM: TLabel;
    edtHRPWM: TEdit;
    lblIR: TLabel;
    edtIR: TEdit;
    lblObs: TLabel;
    edtObs: TEdit;
    
    btnAddPin: TButton;
    btnUpdatePin: TButton;
    btnDeletePin: TButton;
    btnSaveJSON: TButton;
    btnLoadJSON: TButton;
    
    OpenDialog1: TOpenDialog;
    SaveDialog1: TSaveDialog;
    
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btnClearLogClick(Sender: TObject);
    procedure btnRefreshPortsClick(Sender: TObject);
    procedure btnConnectClick(Sender: TObject);
    procedure btnDisconnectClick(Sender: TObject);
    procedure btnReadClick(Sender: TObject);
    procedure btnWriteClick(Sender: TObject);
    procedure rgProtocolClick(Sender: TObject);
    
    procedure btnAddPinClick(Sender: TObject);
    procedure btnUpdatePinClick(Sender: TObject);
    procedure btnDeletePinClick(Sender: TObject);
    procedure btnSaveJSONClick(Sender: TObject);
    procedure btnLoadJSONClick(Sender: TObject);
    procedure StringGridPinoutSelection(Sender: TObject; aCol, aRow: Integer);
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
  end
  else
  begin
    AddLog('Erro na escrita: ' + AIModbusClient1.LastError);
    lblStatus.Caption := 'Status: Falha na operação';
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

procedure TfrmMain.btnAddPinClick(Sender: TObject);
var
  RowIdx: Integer;
begin
  if Trim(edtPin.Text) = '' then
  begin
    ShowMessage('Por favor, informe ao menos o nome do pino.');
    Exit;
  end;
  StringGridPinout.RowCount := StringGridPinout.RowCount + 1;
  RowIdx := StringGridPinout.RowCount - 1;
  StringGridPinout.Cells[0, RowIdx] := edtPin.Text;
  StringGridPinout.Cells[1, RowIdx] := edtCoil.Text;
  StringGridPinout.Cells[2, RowIdx] := edtDI.Text;
  StringGridPinout.Cells[3, RowIdx] := edtHRMode.Text;
  StringGridPinout.Cells[4, RowIdx] := edtHRPWM.Text;
  StringGridPinout.Cells[5, RowIdx] := edtIR.Text;
  StringGridPinout.Cells[6, RowIdx] := edtObs.Text;
  AddLog('Pino adicionado: ' + edtPin.Text);
end;

procedure TfrmMain.btnUpdatePinClick(Sender: TObject);
var
  RowIdx: Integer;
begin
  RowIdx := StringGridPinout.Row;
  if (RowIdx < 1) or (RowIdx >= StringGridPinout.RowCount) then
  begin
    ShowMessage('Por favor, selecione uma linha válida na tabela.');
    Exit;
  end;
  if Trim(edtPin.Text) = '' then
  begin
    ShowMessage('O nome do pino não pode ser vazio.');
    Exit;
  end;
  StringGridPinout.Cells[0, RowIdx] := edtPin.Text;
  StringGridPinout.Cells[1, RowIdx] := edtCoil.Text;
  StringGridPinout.Cells[2, RowIdx] := edtDI.Text;
  StringGridPinout.Cells[3, RowIdx] := edtHRMode.Text;
  StringGridPinout.Cells[4, RowIdx] := edtHRPWM.Text;
  StringGridPinout.Cells[5, RowIdx] := edtIR.Text;
  StringGridPinout.Cells[6, RowIdx] := edtObs.Text;
  AddLog('Pino atualizado: ' + edtPin.Text);
end;

procedure TfrmMain.btnDeletePinClick(Sender: TObject);
var
  RowIdx: Integer;
begin
  RowIdx := StringGridPinout.Row;
  if (RowIdx < 1) or (RowIdx >= StringGridPinout.RowCount) then
  begin
    ShowMessage('Por favor, selecione uma linha válida na tabela.');
    Exit;
  end;
  AddLog('Removendo pino: ' + StringGridPinout.Cells[0, RowIdx]);
  StringGridPinout.DeleteRow(RowIdx);
  if StringGridPinout.RowCount = 1 then
    StringGridPinout.RowCount := 2; // Keep at least one empty data row
end;

procedure TfrmMain.StringGridPinoutSelection(Sender: TObject; aCol, aRow: Integer);
begin
  if (aRow >= 1) and (aRow < StringGridPinout.RowCount) then
  begin
    edtPin.Text := StringGridPinout.Cells[0, aRow];
    edtCoil.Text := StringGridPinout.Cells[1, aRow];
    edtDI.Text := StringGridPinout.Cells[2, aRow];
    edtHRMode.Text := StringGridPinout.Cells[3, aRow];
    edtHRPWM.Text := StringGridPinout.Cells[4, aRow];
    edtIR.Text := StringGridPinout.Cells[5, aRow];
    edtObs.Text := StringGridPinout.Cells[6, aRow];
  end;
end;

procedure TfrmMain.btnSaveJSONClick(Sender: TObject);
var
  JSONArray: TJSONArray;
  JSONObject: TJSONObject;
  I: Integer;
  JSONFile: TStringList;
begin
  if not SaveDialog1.Execute then Exit;
  
  JSONArray := TJSONArray.Create;
  try
    for I := 1 to StringGridPinout.RowCount - 1 do
    begin
      if Trim(StringGridPinout.Cells[0, I]) <> '' then
      begin
        JSONObject := TJSONObject.Create;
        JSONObject.Add('pin', StringGridPinout.Cells[0, I]);
        JSONObject.Add('coil', StringGridPinout.Cells[1, I]);
        JSONObject.Add('di', StringGridPinout.Cells[2, I]);
        JSONObject.Add('hr_mode', StringGridPinout.Cells[3, I]);
        JSONObject.Add('hr_pwm', StringGridPinout.Cells[4, I]);
        JSONObject.Add('ir', StringGridPinout.Cells[5, I]);
        JSONObject.Add('observation', StringGridPinout.Cells[6, I]);
        JSONArray.Add(JSONObject);
      end;
    end;
    
    JSONFile := TStringList.Create;
    try
      JSONFile.Text := JSONArray.FormatJSON();
      JSONFile.SaveToFile(SaveDialog1.FileName);
      AddLog('Configurações salvas em JSON com sucesso: ' + SaveDialog1.FileName);
    finally
      JSONFile.Free;
    end;
  finally
    JSONArray.Free;
  end;
end;

procedure TfrmMain.btnLoadJSONClick(Sender: TObject);
var
  JSONFile: TStringList;
  JSONData: TJSONData;
  JSONArray: TJSONArray;
  JSONObject: TJSONObject;
  I, RowIdx: Integer;
begin
  if not OpenDialog1.Execute then Exit;
  
  JSONFile := TStringList.Create;
  try
    JSONFile.LoadFromFile(OpenDialog1.FileName);
    JSONData := GetJSON(JSONFile.Text);
    try
      if JSONData.JSONType = jtArray then
      begin
        JSONArray := TJSONArray(JSONData);
        StringGridPinout.RowCount := 1; // Clear and keep header
        for I := 0 to JSONArray.Count - 1 do
        begin
          JSONObject := TJSONObject(JSONArray.Items[I]);
          StringGridPinout.RowCount := StringGridPinout.RowCount + 1;
          RowIdx := StringGridPinout.RowCount - 1;
          StringGridPinout.Cells[0, RowIdx] := JSONObject.Get('pin', '');
          StringGridPinout.Cells[1, RowIdx] := JSONObject.Get('coil', '');
          StringGridPinout.Cells[2, RowIdx] := JSONObject.Get('di', '');
          StringGridPinout.Cells[3, RowIdx] := JSONObject.Get('hr_mode', '');
          StringGridPinout.Cells[4, RowIdx] := JSONObject.Get('hr_pwm', '');
          StringGridPinout.Cells[5, RowIdx] := JSONObject.Get('ir', '');
          StringGridPinout.Cells[6, RowIdx] := JSONObject.Get('observation', '');
        end;
        AddLog('Configurações carregadas do JSON com sucesso: ' + OpenDialog1.FileName);
      end
      else
        ShowMessage('Arquivo JSON inválido (deve ser um array).');
    finally
      JSONData.Free;
    end;
  finally
    JSONFile.Free;
  end;
end;

end.
