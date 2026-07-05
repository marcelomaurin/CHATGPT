unit main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, ExtCtrls,
  ComCtrls, Grids, ValEdit, typinfo,
  aimodbus, aiarduinomodbuspinmap, aimodbuscommandmap, ailistserialdevices;

type

  { TfrmMain }

  TfrmMain = class(TForm)
    pnlLeft: TPanel;
    pnlRight: TPanel;
    lblTitle: TLabel;
    lblDevice: TLabel;
    cbSerialDevice: TComboBox;
    btnRefreshPorts: TButton;
    lblPort: TLabel;
    edtPort: TEdit;
    lblBoard: TLabel;
    cbBoard: TComboBox;
    btnConnect: TButton;
    btnDisconnect: TButton;
    
    // PageControl with tabs
    PageControl1: TPageControl;
    tsPins: TTabSheet;
    tsCommands: TTabSheet;
    tsLog: TTabSheet;
    
    // Pins Tab components
    sgPins: TStringGrid;
    pnlPinEdit: TPanel;
    lblPinEditTitle: TLabel;
    lblPinTag: TLabel;
    edtPinTag: TEdit;
    lblPinGroup: TLabel;
    edtPinGroup: TEdit;
    lblPinShortName: TLabel;
    edtPinShortName: TEdit;
    lblPinDirection: TLabel;
    cbPinDirection: TComboBox;
    lblPinPullMode: TLabel;
    cbPinPullMode: TComboBox;
    lblPinPolarity: TLabel;
    cbPinPolarity: TComboBox;
    lblPinContactType: TLabel;
    cbPinContactType: TComboBox;
    chkSetupEnabled: TCheckBox;
    chkNotifyOnChange: TCheckBox;
    lblDefaultValue: TLabel;
    edtDefaultValue: TEdit;
    btnApplyPinSettings: TButton;
    
    pnlPinActions: TPanel;
    btnSetupPins: TButton;
    btnReadSelected: TButton;
    btnWriteSelected: TButton;
    btnReadGroup: TButton;
    btnWriteGroup: TButton;
    btnExportPinsAI: TButton;
    
    // Commands Tab components
    sgCommands: TStringGrid;
    pnlCommandActions: TPanel;
    btnLoadStandardCommands: TButton;
    btnAddCustomCommand: TButton;
    btnToggleCommand: TButton;
    btnExportCommandsAI: TButton;
    
    // Log Tab component
    memoLog: TMemo;
    
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btnConnectClick(Sender: TObject);
    procedure btnDisconnectClick(Sender: TObject);
    procedure cbBoardChange(Sender: TObject);
    procedure sgPinsSelectCell(Sender: TObject; aCol, aRow: Integer; var CanSelect: Boolean);
    procedure btnApplyPinSettingsClick(Sender: TObject);
    procedure btnSetupPinsClick(Sender: TObject);
    procedure btnReadSelectedClick(Sender: TObject);
    procedure btnWriteSelectedClick(Sender: TObject);
    procedure btnReadGroupClick(Sender: TObject);
    procedure btnWriteGroupClick(Sender: TObject);
    procedure btnExportPinsAIClick(Sender: TObject);
    
    procedure btnLoadStandardCommandsClick(Sender: TObject);
    procedure btnAddCustomCommandClick(Sender: TObject);
    procedure btnToggleCommandClick(Sender: TObject);
    procedure btnExportCommandsAIClick(Sender: TObject);
    procedure btnRefreshPortsClick(Sender: TObject);
    
    procedure PinStateChangedHandler(Sender: TObject; Pin: TAIArduinoPinMapItem; OldValue, NewValue: Integer; Source: TArduinoPinChangeSource);
    procedure PinModeChangedHandler(Sender: TObject; Pin: TAIArduinoPinMapItem; OldMode, NewMode: TArduinoPinMode);
    procedure PinErrorHandler(Sender: TObject; Pin: TAIArduinoPinMapItem; const AMessage: string);
  private
    FModbusClient: TAIModbusClient;
    FPinMap: TAIArduinoModbusPinMap;
    FCommandMap: TAIModbusCommandMap;
    FSerialDevices: TAIListSerialDevices;
    
    procedure Log(const Msg: string);
    procedure UpdatePinsGrid;
    procedure UpdateCommandsGrid;
    procedure PopulateComboBoxes;
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
  FModbusClient := TAIModbusClient.Create(Self);
  FModbusClient.ProtocolType := mbRTU;
  
  FCommandMap := TAIModbusCommandMap.Create(Self);
  FCommandMap.LoadDefaultModbusCommands;
  
  FPinMap := TAIArduinoModbusPinMap.Create(Self);
  FPinMap.ModbusClient := FModbusClient;
  FPinMap.CommandMap := FCommandMap;
  
  FSerialDevices := TAIListSerialDevices.Create(Self);
  
  // Set events
  FPinMap.OnPinStateChanged := @PinStateChangedHandler;
  FPinMap.OnPinModeChanged := @PinModeChangedHandler;
  FPinMap.OnPinError := @PinErrorHandler;

  PopulateComboBoxes;
  RefreshSerialPorts;
  
  cbBoard.ItemIndex := 0; // Nano
  FPinMap.BoardType := abtNano;
  
  UpdatePinsGrid;
  UpdateCommandsGrid;
  
  Log('Arduino Modbus PinMap evolved Demo initialized.');
end;

procedure TfrmMain.FormDestroy(Sender: TObject);
begin
  // Handled by Self ownership
end;

procedure TfrmMain.RefreshSerialPorts;
begin
  FSerialDevices.Refresh;
  cbSerialDevice.Items.Clear;
  FSerialDevices.GetDeviceNames(cbSerialDevice.Items);
  if cbSerialDevice.Items.Count > 0 then
    cbSerialDevice.ItemIndex := 0
  else
    Log('No serial ports detected.');
end;

procedure TfrmMain.btnRefreshPortsClick(Sender: TObject);
begin
  Log('Refreshing serial ports list...');
  RefreshSerialPorts;
end;

procedure TfrmMain.PopulateComboBoxes;
var
  I: Integer;
begin
  // Pin Direction combobox
  cbPinDirection.Clear;
  for I := 0 to Ord(High(TArduinoPinDirection)) do
    cbPinDirection.Items.Add(GetEnumName(TypeInfo(TArduinoPinDirection), I));
  cbPinDirection.ItemIndex := 0;

  // Pull Mode combobox
  cbPinPullMode.Clear;
  for I := 0 to Ord(High(TArduinoPinPullMode)) do
    cbPinPullMode.Items.Add(GetEnumName(TypeInfo(TArduinoPinPullMode), I));
  cbPinPullMode.ItemIndex := 0;

  // Polarity combobox
  cbPinPolarity.Clear;
  for I := 0 to Ord(High(TArduinoPinPolarity)) do
    cbPinPolarity.Items.Add(GetEnumName(TypeInfo(TArduinoPinPolarity), I));
  cbPinPolarity.ItemIndex := 0;

  // Contact Type combobox
  cbPinContactType.Clear;
  for I := 0 to Ord(High(TArduinoContactType)) do
    cbPinContactType.Items.Add(GetEnumName(TypeInfo(TArduinoContactType), I));
  cbPinContactType.ItemIndex := 0;
end;

procedure TfrmMain.cbBoardChange(Sender: TObject);
begin
  case cbBoard.ItemIndex of
    0: FPinMap.BoardType := abtNano;
    1: FPinMap.BoardType := abtUno;
    2: FPinMap.BoardType := abtMega;
    3: FPinMap.BoardType := abtESP32;
  end;
  
  case FPinMap.BoardType of
    abtNano: FPinMap.LoadArduinoNanoDefaultMap;
    abtUno: FPinMap.LoadArduinoUnoDefaultMap;
    abtMega: FPinMap.LoadArduinoMegaDefaultMap;
    abtESP32: FPinMap.LoadESP32DefaultMap;
  end;
  
  UpdatePinsGrid;
end;

procedure TfrmMain.UpdatePinsGrid;
var
  I: Integer;
  Pin: TAIArduinoPinMapItem;
begin
  sgPins.BeginUpdate;
  try
    sgPins.Clear;
    sgPins.RowCount := FPinMap.Pins.Count + 1;
    sgPins.ColCount := 15;
    
    // Header
    sgPins.Cells[0, 0] := 'Tag';
    sgPins.Cells[1, 0] := 'Group';
    sgPins.Cells[2, 0] := 'ShortName';
    sgPins.Cells[3, 0] := 'Name';
    sgPins.Cells[4, 0] := 'PinNo';
    sgPins.Cells[5, 0] := 'Direction';
    sgPins.Cells[6, 0] := 'Mode';
    sgPins.Cells[7, 0] := 'PullMode';
    sgPins.Cells[8, 0] := 'Polarity';
    sgPins.Cells[9, 0] := 'Contact';
    sgPins.Cells[10, 0] := 'Value';
    sgPins.Cells[11, 0] := 'ModeReg';
    sgPins.Cells[12, 0] := 'DigReg';
    sgPins.Cells[13, 0] := 'AnaReg';
    sgPins.Cells[14, 0] := 'PWMReg';
    
    for I := 0 to FPinMap.Pins.Count - 1 do
    begin
      Pin := FPinMap.Pins[I];
      sgPins.Cells[0, I + 1] := IntToStr(Pin.Tag);
      sgPins.Cells[1, I + 1] := Pin.Group;
      sgPins.Cells[2, I + 1] := Pin.ShortName;
      sgPins.Cells[3, I + 1] := Pin.Name;
      sgPins.Cells[4, I + 1] := IntToStr(Pin.PinNumber);
      sgPins.Cells[5, I + 1] := GetEnumName(TypeInfo(TArduinoPinDirection), Ord(Pin.Direction));
      sgPins.Cells[6, I + 1] := GetEnumName(TypeInfo(TArduinoPinMode), Ord(Pin.Mode));
      sgPins.Cells[7, I + 1] := GetEnumName(TypeInfo(TArduinoPinPullMode), Ord(Pin.PullMode));
      sgPins.Cells[8, I + 1] := GetEnumName(TypeInfo(TArduinoPinPolarity), Ord(Pin.Polarity));
      sgPins.Cells[9, I + 1] := GetEnumName(TypeInfo(TArduinoContactType), Ord(Pin.ContactType));
      sgPins.Cells[10, I + 1] := IntToStr(Pin.LastValue);
      sgPins.Cells[11, I + 1] := IntToStr(Pin.ModeRegister);
      sgPins.Cells[12, I + 1] := IntToStr(Pin.DigitalRegister);
      sgPins.Cells[13, I + 1] := IntToStr(Pin.AnalogRegister);
      sgPins.Cells[14, I + 1] := IntToStr(Pin.PWMRegister);
    end;
  finally
    sgPins.EndUpdate;
  end;
end;

procedure TfrmMain.UpdateCommandsGrid;
var
  I: Integer;
  Cmd: TAIModbusCommandItem;
begin
  sgCommands.BeginUpdate;
  try
    sgCommands.Clear;
    sgCommands.RowCount := FCommandMap.Commands.Count + 1;
    sgCommands.ColCount := 9;
    
    sgCommands.Cells[0, 0] := 'Code';
    sgCommands.Cells[1, 0] := 'ShortName';
    sgCommands.Cells[2, 0] := 'Name';
    sgCommands.Cells[3, 0] := 'Group';
    sgCommands.Cells[4, 0] := 'Kind';
    sgCommands.Cells[5, 0] := 'Access';
    sgCommands.Cells[6, 0] := 'DataArea';
    sgCommands.Cells[7, 0] := 'Enabled';
    sgCommands.Cells[8, 0] := 'Valid PinMap';
    
    for I := 0 to FCommandMap.Commands.Count - 1 do
    begin
      Cmd := FCommandMap.Commands[I];
      sgCommands.Cells[0, I + 1] := IntToStr(Cmd.Code);
      sgCommands.Cells[1, I + 1] := Cmd.ShortName;
      sgCommands.Cells[2, I + 1] := Cmd.Name;
      sgCommands.Cells[3, I + 1] := Cmd.Group;
      sgCommands.Cells[4, I + 1] := GetEnumName(TypeInfo(TModbusCommandKind), Ord(Cmd.Kind));
      sgCommands.Cells[5, I + 1] := GetEnumName(TypeInfo(TModbusCommandAccess), Ord(Cmd.Access));
      sgCommands.Cells[6, I + 1] := GetEnumName(TypeInfo(TModbusCommandDataArea), Ord(Cmd.DataArea));
      sgCommands.Cells[7, I + 1] := BoolToStr(Cmd.Enabled, True);
      sgCommands.Cells[8, I + 1] := BoolToStr(Cmd.IsValidForArduinoPinMap, True);
    end;
  finally
    sgCommands.EndUpdate;
  end;
end;

procedure TfrmMain.sgPinsSelectCell(Sender: TObject; aCol, aRow: Integer; var CanSelect: Boolean);
var
  Pin: TAIArduinoPinMapItem;
begin
  if (aRow >= 1) and (aRow <= FPinMap.Pins.Count) then
  begin
    Pin := FPinMap.Pins[aRow - 1];
    edtPinTag.Text := IntToStr(Pin.Tag);
    edtPinGroup.Text := Pin.Group;
    edtPinShortName.Text := Pin.ShortName;
    cbPinDirection.ItemIndex := Ord(Pin.Direction);
    cbPinPullMode.ItemIndex := Ord(Pin.PullMode);
    cbPinPolarity.ItemIndex := Ord(Pin.Polarity);
    cbPinContactType.ItemIndex := Ord(Pin.ContactType);
    chkSetupEnabled.Checked := Pin.SetupEnabled;
    chkNotifyOnChange.Checked := Pin.NotifyOnChange;
    edtDefaultValue.Text := IntToStr(Pin.DefaultValue);
  end;
end;

procedure TfrmMain.btnApplyPinSettingsClick(Sender: TObject);
var
  Row: Integer;
  Pin: TAIArduinoPinMapItem;
begin
  Row := sgPins.Row;
  if (Row >= 1) and (Row <= FPinMap.Pins.Count) then
  begin
    Pin := FPinMap.Pins[Row - 1];
    Pin.Tag := StrToIntDef(edtPinTag.Text, Pin.Tag);
    Pin.Group := edtPinGroup.Text;
    Pin.ShortName := edtPinShortName.Text;
    Pin.Direction := TArduinoPinDirection(cbPinDirection.ItemIndex);
    Pin.PullMode := TArduinoPinPullMode(cbPinPullMode.ItemIndex);
    Pin.Polarity := TArduinoPinPolarity(cbPinPolarity.ItemIndex);
    Pin.ContactType := TArduinoContactType(cbPinContactType.ItemIndex);
    Pin.SetupEnabled := chkSetupEnabled.Checked;
    Pin.NotifyOnChange := chkNotifyOnChange.Checked;
    Pin.DefaultValue := StrToIntDef(edtDefaultValue.Text, Pin.DefaultValue);
    
    Log('Settings applied for Pin: ' + Pin.Name);
    UpdatePinsGrid;
  end;
end;

procedure TfrmMain.Log(const Msg: string);
begin
  memoLog.Lines.Add(FormatDateTime('hh:nn:ss.zzz', Now) + ' - ' + Msg);
end;

procedure TfrmMain.btnConnectClick(Sender: TObject);
begin
  FModbusClient.DeviceName := cbSerialDevice.Text;
  FModbusClient.BaudRate := StrToIntDef(edtPort.Text, 9600);
  
  Log('Connecting to: ' + FModbusClient.DeviceName + ' @ ' + IntToStr(FModbusClient.BaudRate));
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

procedure TfrmMain.btnSetupPinsClick(Sender: TObject);
begin
  Log('Starting SetupPins routine...');
  if FPinMap.SetupPins then
    Log('SetupPins completed successfully!')
  else
    Log('SetupPins failed: ' + FPinMap.LastError);
end;

procedure TfrmMain.btnReadSelectedClick(Sender: TObject);
var
  Row: Integer;
  Pin: TAIArduinoPinMapItem;
  Val: Integer;
begin
  Row := sgPins.Row;
  if (Row >= 1) and (Row <= FPinMap.Pins.Count) then
  begin
    Pin := FPinMap.Pins[Row - 1];
    Log('Reading Pin: ' + Pin.Name + ' (Tag: ' + IntToStr(Pin.Tag) + ')...');
    
    if Pin.Kind = apkAnalog then
    begin
      if FPinMap.ReadAnalog(Pin.Name, Val) then
      begin
        Log(Format('Read Analog Succeeded: %d', [Val]));
        UpdatePinsGrid;
      end
      else
        Log('Read Analog failed: ' + FPinMap.LastError);
    end
    else
    begin
      if FPinMap.ReadPin(Pin.Name, Val) then
      begin
        Log(Format('Read Digital Succeeded: %d', [Val]));
        UpdatePinsGrid;
      end
      else
        Log('Read Digital failed: ' + FPinMap.LastError);
    end;
  end;
end;

procedure TfrmMain.btnWriteSelectedClick(Sender: TObject);
var
  Row: Integer;
  Pin: TAIArduinoPinMapItem;
  Val: Integer;
begin
  Row := sgPins.Row;
  if (Row >= 1) and (Row <= FPinMap.Pins.Count) then
  begin
    Pin := FPinMap.Pins[Row - 1];
    Val := StrToIntDef(edtDefaultValue.Text, 0);
    Log('Writing Pin: ' + Pin.Name + ' = ' + IntToStr(Val) + '...');
    
    if Pin.Mode = apmPWM then
    begin
      if FPinMap.SetPWM(Pin.Name, Val) then
        Log('PWM Write Succeeded')
      else
        Log('PWM Write failed: ' + FPinMap.LastError);
    end
    else
    begin
      if FPinMap.WritePin(Pin.Name, Val) then
      begin
        Log('Digital Write Succeeded');
        UpdatePinsGrid;
      end
      else
        Log('Digital Write failed: ' + FPinMap.LastError);
    end;
  end;
end;

procedure TfrmMain.btnReadGroupClick(Sender: TObject);
var
  Row: Integer;
  Pin: TAIArduinoPinMapItem;
  List: TList;
  I, Val: Integer;
begin
  Row := sgPins.Row;
  if (Row >= 1) and (Row <= FPinMap.Pins.Count) then
  begin
    Pin := FPinMap.Pins[Row - 1];
    if Pin.Group = '' then Exit;
    
    Log('Reading Group: ' + Pin.Group);
    List := TList.Create;
    try
      FPinMap.FindPinsByGroup(Pin.Group, List);
      for I := 0 to List.Count - 1 do
      begin
        Pin := TAIArduinoPinMapItem(List[I]);
        if Pin.Kind = apkAnalog then
          FPinMap.ReadAnalog(Pin.Name, Val)
        else
          FPinMap.ReadPin(Pin.Name, Val);
      end;
      UpdatePinsGrid;
    finally
      List.Free;
    end;
  end;
end;

procedure TfrmMain.btnWriteGroupClick(Sender: TObject);
var
  Row: Integer;
  Pin: TAIArduinoPinMapItem;
  List: TList;
  I, Val: Integer;
begin
  Row := sgPins.Row;
  if (Row >= 1) and (Row <= FPinMap.Pins.Count) then
  begin
    Pin := FPinMap.Pins[Row - 1];
    if Pin.Group = '' then Exit;
    Val := StrToIntDef(edtDefaultValue.Text, 0);
    
    Log('Writing Group: ' + Pin.Group + ' = ' + IntToStr(Val));
    List := TList.Create;
    try
      FPinMap.FindPinsByGroup(Pin.Group, List);
      for I := 0 to List.Count - 1 do
      begin
        Pin := TAIArduinoPinMapItem(List[I]);
        if Pin.Mode = apmPWM then
          FPinMap.SetPWM(Pin.Name, Val)
        else
          FPinMap.WritePin(Pin.Name, Val);
      end;
      UpdatePinsGrid;
    finally
      List.Free;
    end;
  end;
end;

procedure TfrmMain.btnExportPinsAIClick(Sender: TObject);
begin
  FPinMap.UpdatePromptFromPinMap;
  Log('--- AI Context Prompt ---');
  Log(FPinMap.Prompt);
  Log('--- End Context Prompt ---');
end;

procedure TfrmMain.btnLoadStandardCommandsClick(Sender: TObject);
begin
  FCommandMap.LoadDefaultModbusCommands;
  UpdateCommandsGrid;
  Log('Standard Modbus commands reloaded.');
end;

procedure TfrmMain.btnAddCustomCommandClick(Sender: TObject);
var
  CodeStr: string;
  Code: Integer;
  Cmd: TAIModbusCommandItem;
begin
  CodeStr := '65';
  if InputQuery('Add Custom Command', 'Enter User-Defined Code (65..72, 100..110):', CodeStr) then
  begin
    Code := StrToIntDef(CodeStr, 0);
    Cmd := FCommandMap.AddCustomCommand(Code, 'Custom_' + CodeStr, 'User Custom Command ' + CodeStr);
    if Cmd <> nil then
    begin
      UpdateCommandsGrid;
      Log('Custom Command added: ' + Cmd.Name);
    end
    else
      Log('Failed to add custom command. Verify Code fits within user-defined ranges.');
  end;
end;

procedure TfrmMain.btnToggleCommandClick(Sender: TObject);
var
  Row: Integer;
  Cmd: TAIModbusCommandItem;
begin
  Row := sgCommands.Row;
  if (Row >= 1) and (Row <= FCommandMap.Commands.Count) then
  begin
    Cmd := FCommandMap.Commands[Row - 1];
    Cmd.Enabled := not Cmd.Enabled;
    UpdateCommandsGrid;
    Log(Format('Command %d toggled. Enabled = %s', [Cmd.Code, BoolToStr(Cmd.Enabled, True)]));
  end;
end;

procedure TfrmMain.btnExportCommandsAIClick(Sender: TObject);
begin
  Log('--- AI Command Map Context ---');
  Log(FCommandMap.ToSetupPrompt);
  Log('--- End Command Map ---');
end;

procedure TfrmMain.PinStateChangedHandler(Sender: TObject; Pin: TAIArduinoPinMapItem; OldValue, NewValue: Integer; Source: TArduinoPinChangeSource);
begin
  Log(Format('EVENT [StateChanged] Pin %s: Old=%d, New=%d (Source: %s)', 
    [Pin.Name, OldValue, NewValue, GetEnumName(TypeInfo(TArduinoPinChangeSource), Ord(Source))]));
end;

procedure TfrmMain.PinModeChangedHandler(Sender: TObject; Pin: TAIArduinoPinMapItem; OldMode, NewMode: TArduinoPinMode);
begin
  Log(Format('EVENT [ModeChanged] Pin %s: Old=%s, New=%s', 
    [Pin.Name, GetEnumName(TypeInfo(TArduinoPinMode), Ord(OldMode)), GetEnumName(TypeInfo(TArduinoPinMode), Ord(NewMode))]));
end;

procedure TfrmMain.PinErrorHandler(Sender: TObject; Pin: TAIArduinoPinMapItem; const AMessage: string);
begin
  Log(Format('EVENT [Error] Pin %s: %s', [Pin.Name, AMessage]));
end;

end.
