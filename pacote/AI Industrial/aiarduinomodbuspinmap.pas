unit aiarduinomodbuspinmap;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, aibase, aimodbus;

type
  TArduinoBoardType = (
    abtNano,
    abtUno,
    abtMega,
    abtESP32
  );

  TArduinoPinMode = (
    apmDisabled,
    apmInput,
    apmInputPullup,
    apmOutput,
    apmPWM
  );

  TArduinoPinKind = (
    apkDigital,
    apkAnalog,
    apkPWM
  );

  { TAIArduinoPinMapItem }

  TAIArduinoPinMapItem = class(TCollectionItem)
  private
    FName: string;
    FPinNumber: Integer;
    FMode: TArduinoPinMode;
    FKind: TArduinoPinKind;
    FCanPWM: Boolean;
    FCanAnalog: Boolean;
    FReserved: Boolean;
    FModeRegister: Integer;
    FDigitalRegister: Integer;
    FAnalogRegister: Integer;
    FPWMRegister: Integer;
  public
    procedure Assign(Source: TPersistent); override;
  published
    property Name: string read FName write FName;
    property PinNumber: Integer read FPinNumber write FPinNumber;
    property Mode: TArduinoPinMode read FMode write FMode;
    property Kind: TArduinoPinKind read FKind write FKind;
    property CanPWM: Boolean read FCanPWM write FCanPWM;
    property CanAnalog: Boolean read FCanAnalog write FCanAnalog;
    property Reserved: Boolean read FReserved write FReserved;
    property ModeRegister: Integer read FModeRegister write FModeRegister;
    property DigitalRegister: Integer read FDigitalRegister write FDigitalRegister;
    property AnalogRegister: Integer read FAnalogRegister write FAnalogRegister;
    property PWMRegister: Integer read FPWMRegister write FPWMRegister;
  end;

  { TAIArduinoPinMapItems }

  TAIArduinoPinMapItems = class(TOwnedCollection)
  private
    function GetItem(Index: Integer): TAIArduinoPinMapItem;
    procedure SetItem(Index: Integer; AValue: TAIArduinoPinMapItem);
  public
    constructor Create(AOwner: TPersistent);
    function Add: TAIArduinoPinMapItem;
    property Items[Index: Integer]: TAIArduinoPinMapItem read GetItem write SetItem; default;
  end;

  { TAIArduinoModbusPinMap }

  TAIArduinoModbusPinMap = class(TAIBaseComponent)
  private
    FBoardType: TArduinoBoardType;
    FModbusClient: TAIModbusClient;
    FPins: TAIArduinoPinMapItems;
    FSlaveID: Integer;
    FAutoConnect: Boolean;

    function FindPin(const APinName: string): TAIArduinoPinMapItem;
    function PinModeToWord(AMode: TArduinoPinMode): Word;
    function WordToPinMode(AValue: Word): TArduinoPinMode;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    procedure ClearMap;
    procedure LoadArduinoNanoDefaultMap;
    procedure LoadArduinoUnoDefaultMap;
    procedure LoadArduinoMegaDefaultMap;
    procedure LoadESP32DefaultMap;

    function Connect: Boolean;
    procedure Disconnect;

    function SetPinMode(const APinName: string; AMode: TArduinoPinMode): Boolean;
    function ReadPin(const APinName: string; out AValue: Integer): Boolean;
    function WritePin(const APinName: string; AValue: Integer): Boolean;
    function SetPWM(const APinName: string; AValue: Integer): Boolean;
    function ReadAnalog(const APinName: string; out AValue: Integer): Boolean;
  published
    property BoardType: TArduinoBoardType read FBoardType write FBoardType default abtNano;
    property ModbusClient: TAIModbusClient read FModbusClient write FModbusClient;
    property Pins: TAIArduinoPinMapItems read FPins write FPins;
    property SlaveID: Integer read FSlaveID write FSlaveID default 1;
    property AutoConnect: Boolean read FAutoConnect write FAutoConnect default False;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('AI Industrial', [TAIArduinoModbusPinMap]);
end;

{ TAIArduinoPinMapItem }

procedure TAIArduinoPinMapItem.Assign(Source: TPersistent);
var
  Src: TAIArduinoPinMapItem;
begin
  if Source is TAIArduinoPinMapItem then
  begin
    Src := TAIArduinoPinMapItem(Source);
    FName := Src.Name;
    FPinNumber := Src.PinNumber;
    FMode := Src.Mode;
    FKind := Src.Kind;
    FCanPWM := Src.CanPWM;
    FCanAnalog := Src.CanAnalog;
    FReserved := Src.Reserved;
    FModeRegister := Src.ModeRegister;
    FDigitalRegister := Src.DigitalRegister;
    FAnalogRegister := Src.AnalogRegister;
    FPWMRegister := Src.PWMRegister;
  end
  else
    inherited Assign(Source);
end;

{ TAIArduinoPinMapItems }

constructor TAIArduinoPinMapItems.Create(AOwner: TPersistent);
begin
  inherited Create(AOwner, TAIArduinoPinMapItem);
end;

function TAIArduinoPinMapItems.GetItem(Index: Integer): TAIArduinoPinMapItem;
begin
  Result := TAIArduinoPinMapItem(inherited GetItem(Index));
end;

procedure TAIArduinoPinMapItems.SetItem(Index: Integer; AValue: TAIArduinoPinMapItem);
begin
  inherited SetItem(Index, AValue);
end;

function TAIArduinoPinMapItems.Add: TAIArduinoPinMapItem;
begin
  Result := TAIArduinoPinMapItem(inherited Add);
end;

{ TAIArduinoModbusPinMap }

constructor TAIArduinoModbusPinMap.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FPrompt := 'Component TAIArduinoModbusPinMap exposes physical Arduino/ESP32 pins as high-level commands, translating calls like SetPinMode or WritePin to Modbus Holding Register transactions via an associated TAIModbusClient.';
  FPins := TAIArduinoPinMapItems.Create(Self);
  FBoardType := abtNano;
  FSlaveID := 1;
  FAutoConnect := False;
  LoadArduinoNanoDefaultMap;
end;

destructor TAIArduinoModbusPinMap.Destroy;
begin
  FPins.Free;
  inherited Destroy;
end;

function TAIArduinoModbusPinMap.FindPin(const APinName: string): TAIArduinoPinMapItem;
var
  I: Integer;
begin
  Result := nil;
  for I := 0 to FPins.Count - 1 do
  begin
    if SameText(FPins[I].Name, APinName) then
    begin
      Result := FPins[I];
      Exit;
    end;
  end;
end;

// Helper mapping to avoid warnings:
type
  TArduinoPinModeHelper = TArduinoPinMode;

function TAIArduinoModbusPinMap.PinModeToWord(AMode: TArduinoPinMode): Word;
begin
  Result := Ord(AMode);
end;

function TAIArduinoModbusPinMap.WordToPinMode(AValue: Word): TArduinoPinMode;
begin
  if AValue > Ord(High(TArduinoPinMode)) then
    Result := apmDisabled
  else
    Result := TArduinoPinMode(AValue);
end;

procedure TAIArduinoModbusPinMap.ClearMap;
begin
  FPins.Clear;
end;

procedure TAIArduinoModbusPinMap.LoadArduinoNanoDefaultMap;
var
  Item: TAIArduinoPinMapItem;
  I: Integer;
begin
  ClearMap;
  
  // D0 & D1 (Reserved for RX/TX)
  for I := 0 to 1 do
  begin
    Item := FPins.Add;
    Item.Name := 'D' + IntToStr(I);
    Item.PinNumber := I;
    Item.Mode := apmDisabled;
    Item.Kind := apkDigital;
    Item.CanPWM := False;
    Item.CanAnalog := False;
    Item.Reserved := True;
    Item.ModeRegister := 10 + I;
    Item.DigitalRegister := 50 + I;
    Item.AnalogRegister := -1;
    Item.PWMRegister := -1;
  end;

  // D2..D13
  for I := 2 to 13 do
  begin
    Item := FPins.Add;
    Item.Name := 'D' + IntToStr(I);
    Item.PinNumber := I;
    Item.Mode := apmInput;
    Item.Kind := apkDigital;
    // PWM pins on Nano: D3, D5, D6, D9, D10, D11
    Item.CanPWM := (I = 3) or (I = 5) or (I = 6) or (I = 9) or (I = 10) or (I = 11);
    Item.CanAnalog := False;
    Item.Reserved := False;
    Item.ModeRegister := 10 + I;
    Item.DigitalRegister := 50 + I;
    Item.AnalogRegister := -1;
    if Item.CanPWM then
      Item.PWMRegister := 150 + I
    else
      Item.PWMRegister := -1;
  end;

  // A0..A5 (Analog inputs that can also be digital GPIO)
  for I := 0 to 5 do
  begin
    Item := FPins.Add;
    Item.Name := 'A' + IntToStr(I);
    Item.PinNumber := 14 + I;
    Item.Mode := apmInput;
    Item.Kind := apkAnalog;
    Item.CanPWM := False;
    Item.CanAnalog := True;
    Item.Reserved := False;
    Item.ModeRegister := 10 + Item.PinNumber;
    Item.DigitalRegister := 50 + Item.PinNumber;
    Item.AnalogRegister := 100 + I;
    Item.PWMRegister := -1;
  end;

  // A6 & A7 (Analog-only inputs)
  for I := 6 to 7 do
  begin
    Item := FPins.Add;
    Item.Name := 'A' + IntToStr(I);
    Item.PinNumber := 14 + I;
    Item.Mode := apmInput;
    Item.Kind := apkAnalog;
    Item.CanPWM := False;
    Item.CanAnalog := True;
    Item.Reserved := False;
    Item.ModeRegister := -1; // Analog-only, mode cannot be changed
    Item.DigitalRegister := -1;
    Item.AnalogRegister := 100 + I;
    Item.PWMRegister := -1;
  end;
end;

procedure TAIArduinoModbusPinMap.LoadArduinoUnoDefaultMap;
var
  Item: TAIArduinoPinMapItem;
  I: Integer;
begin
  ClearMap;
  
  // D0 & D1 (Reserved for RX/TX)
  for I := 0 to 1 do
  begin
    Item := FPins.Add;
    Item.Name := 'D' + IntToStr(I);
    Item.PinNumber := I;
    Item.Mode := apmDisabled;
    Item.Kind := apkDigital;
    Item.CanPWM := False;
    Item.CanAnalog := False;
    Item.Reserved := True;
    Item.ModeRegister := 10 + I;
    Item.DigitalRegister := 50 + I;
    Item.AnalogRegister := -1;
    Item.PWMRegister := -1;
  end;

  // D2..D13
  for I := 2 to 13 do
  begin
    Item := FPins.Add;
    Item.Name := 'D' + IntToStr(I);
    Item.PinNumber := I;
    Item.Mode := apmInput;
    Item.Kind := apkDigital;
    // PWM pins on Uno: D3, D5, D6, D9, D10, D11
    Item.CanPWM := (I = 3) or (I = 5) or (I = 6) or (I = 9) or (I = 10) or (I = 11);
    Item.CanAnalog := False;
    Item.Reserved := False;
    Item.ModeRegister := 10 + I;
    Item.DigitalRegister := 50 + I;
    Item.AnalogRegister := -1;
    if Item.CanPWM then
      Item.PWMRegister := 150 + I
    else
      Item.PWMRegister := -1;
  end;

  // A0..A5
  for I := 0 to 5 do
  begin
    Item := FPins.Add;
    Item.Name := 'A' + IntToStr(I);
    Item.PinNumber := 14 + I;
    Item.Mode := apmInput;
    Item.Kind := apkAnalog;
    Item.CanPWM := False;
    Item.CanAnalog := True;
    Item.Reserved := False;
    Item.ModeRegister := 10 + Item.PinNumber;
    Item.DigitalRegister := 50 + Item.PinNumber;
    Item.AnalogRegister := 100 + I;
    Item.PWMRegister := -1;
  end;
end;

procedure TAIArduinoModbusPinMap.LoadArduinoMegaDefaultMap;
var
  Item: TAIArduinoPinMapItem;
  I: Integer;
begin
  ClearMap;
  
  // D0 & D1 (Reserved for RX/TX)
  for I := 0 to 1 do
  begin
    Item := FPins.Add;
    Item.Name := 'D' + IntToStr(I);
    Item.PinNumber := I;
    Item.Mode := apmDisabled;
    Item.Kind := apkDigital;
    Item.CanPWM := False;
    Item.CanAnalog := False;
    Item.Reserved := True;
    Item.ModeRegister := 10 + I;
    Item.DigitalRegister := 50 + I;
    Item.AnalogRegister := -1;
    Item.PWMRegister := -1;
  end;

  // D2..D53 (Simplification: D2..D53 digital pins, Mega has PWM on 2..13 and 44..46)
  for I := 2 to 53 do
  begin
    Item := FPins.Add;
    Item.Name := 'D' + IntToStr(I);
    Item.PinNumber := I;
    Item.Mode := apmInput;
    Item.Kind := apkDigital;
    Item.CanPWM := (I >= 2) and (I <= 13) or (I >= 44) and (I <= 46);
    Item.CanAnalog := False;
    Item.Reserved := False;
    Item.ModeRegister := 10 + I;
    Item.DigitalRegister := 50 + I;
    Item.AnalogRegister := -1;
    if Item.CanPWM then
      Item.PWMRegister := 150 + I
    else
      Item.PWMRegister := -1;
  end;

  // A0..A15 (Mega has 16 analog inputs)
  for I := 0 to 15 do
  begin
    Item := FPins.Add;
    Item.Name := 'A' + IntToStr(I);
    Item.PinNumber := 54 + I;
    Item.Mode := apmInput;
    Item.Kind := apkAnalog;
    Item.CanPWM := False;
    Item.CanAnalog := True;
    Item.Reserved := False;
    Item.ModeRegister := 10 + Item.PinNumber;
    Item.DigitalRegister := 50 + Item.PinNumber;
    Item.AnalogRegister := 100 + I;
    Item.PWMRegister := -1;
  end;
end;

procedure TAIArduinoModbusPinMap.LoadESP32DefaultMap;
var
  Item: TAIArduinoPinMapItem;
  I: Integer;
  GPIOPins: array[0..17] of Integer = (2, 4, 5, 12, 13, 14, 15, 16, 17, 18, 19, 21, 22, 23, 25, 26, 27, 32);
  AnalogPins: array[0..5] of Integer = (33, 34, 35, 36, 39, 32);
begin
  ClearMap;
  
  for I := 0 to High(GPIOPins) do
  begin
    Item := FPins.Add;
    Item.Name := 'GPIO' + IntToStr(GPIOPins[I]);
    Item.PinNumber := GPIOPins[I];
    Item.Mode := apmInput;
    Item.Kind := apkDigital;
    Item.CanPWM := True;
    Item.CanAnalog := False;
    Item.Reserved := False;
    Item.ModeRegister := 10 + Item.PinNumber;
    Item.DigitalRegister := 50 + Item.PinNumber;
    Item.AnalogRegister := -1;
    Item.PWMRegister := 150 + Item.PinNumber;
  end;

  for I := 0 to High(AnalogPins) do
  begin
    Item := FPins.Add;
    Item.Name := 'ADC' + IntToStr(I);
    Item.PinNumber := AnalogPins[I];
    Item.Mode := apmInput;
    Item.Kind := apkAnalog;
    Item.CanPWM := False;
    Item.CanAnalog := True;
    Item.Reserved := False;
    Item.ModeRegister := 10 + Item.PinNumber;
    Item.DigitalRegister := 50 + Item.PinNumber;
    Item.AnalogRegister := 100 + I;
    Item.PWMRegister := -1;
  end;
end;

function TAIArduinoModbusPinMap.Connect: Boolean;
begin
  Result := False;
  ClearError;
  if FModbusClient = nil then
  begin
    SetError('Modbus Client reference not set.');
    Exit;
  end;
  Result := FModbusClient.Connect;
  if not Result then
    SetError(FModbusClient.LastError);
end;

procedure TAIArduinoModbusPinMap.Disconnect;
begin
  if FModbusClient <> nil then
    FModbusClient.Disconnect;
end;

function TAIArduinoModbusPinMap.SetPinMode(const APinName: string; AMode: TArduinoPinMode): Boolean;
var
  Pin: TAIArduinoPinMapItem;
begin
  Result := False;
  ClearError;
  Pin := FindPin(APinName);
  if Pin = nil then
  begin
    SetError('Pin not found in map: ' + APinName);
    Exit;
  end;
  if Pin.Reserved then
  begin
    SetError('Pin ' + APinName + ' is reserved and cannot be configured.');
    Exit;
  end;
  if Pin.ModeRegister < 0 then
  begin
    SetError('Pin ' + APinName + ' does not support mode modification.');
    Exit;
  end;
  if (AMode = apmPWM) and not Pin.CanPWM then
  begin
    SetError('Pin ' + APinName + ' does not support PWM.');
    Exit;
  end;

  if FAutoConnect and (FModbusClient <> nil) and not FModbusClient.Active then
    Connect;

  if (FModbusClient <> nil) and FModbusClient.Active then
  begin
    Result := FModbusClient.WriteSingleRegister(FSlaveID, Pin.ModeRegister, PinModeToWord(AMode));
    if Result then
      Pin.Mode := AMode
    else
      SetError('Modbus Write failed: ' + FModbusClient.LastError);
  end
  else
    SetError('Modbus connection is not active.');
end;

function TAIArduinoModbusPinMap.ReadPin(const APinName: string; out AValue: Integer): Boolean;
var
  Pin: TAIArduinoPinMapItem;
  Data: array[0..0] of Word;
begin
  Result := False;
  AValue := 0;
  ClearError;
  Pin := FindPin(APinName);
  if Pin = nil then
  begin
    SetError('Pin not found in map: ' + APinName);
    Exit;
  end;
  if Pin.Reserved then
  begin
    SetError('Pin ' + APinName + ' is reserved.');
    Exit;
  end;
  if Pin.DigitalRegister < 0 then
  begin
    SetError('Pin ' + APinName + ' does not support digital read.');
    Exit;
  end;

  if FAutoConnect and (FModbusClient <> nil) and not FModbusClient.Active then
    Connect;

  if (FModbusClient <> nil) and FModbusClient.Active then
  begin
    Result := FModbusClient.ReadHoldingRegisters(FSlaveID, Pin.DigitalRegister, 1, Data);
    if Result then
      AValue := Data[0]
    else
      SetError('Modbus Read failed: ' + FModbusClient.LastError);
  end
  else
    SetError('Modbus connection is not active.');
end;

function TAIArduinoModbusPinMap.WritePin(const APinName: string; AValue: Integer): Boolean;
var
  Pin: TAIArduinoPinMapItem;
begin
  Result := False;
  ClearError;
  Pin := FindPin(APinName);
  if Pin = nil then
  begin
    SetError('Pin not found in map: ' + APinName);
    Exit;
  end;
  if Pin.Reserved then
  begin
    SetError('Pin ' + APinName + ' is reserved.');
    Exit;
  end;
  if Pin.DigitalRegister < 0 then
  begin
    SetError('Pin ' + APinName + ' does not support digital write.');
    Exit;
  end;

  if FAutoConnect and (FModbusClient <> nil) and not FModbusClient.Active then
    Connect;

  if (FModbusClient <> nil) and FModbusClient.Active then
  begin
    Result := FModbusClient.WriteSingleRegister(FSlaveID, Pin.DigitalRegister, AValue);
    if not Result then
      SetError('Modbus Write failed: ' + FModbusClient.LastError);
  end
  else
    SetError('Modbus connection is not active.');
end;

function TAIArduinoModbusPinMap.SetPWM(const APinName: string; AValue: Integer): Boolean;
var
  Pin: TAIArduinoPinMapItem;
begin
  Result := False;
  ClearError;
  Pin := FindPin(APinName);
  if Pin = nil then
  begin
    SetError('Pin not found in map: ' + APinName);
    Exit;
  end;
  if Pin.Reserved then
  begin
    SetError('Pin ' + APinName + ' is reserved.');
    Exit;
  end;
  if not Pin.CanPWM or (Pin.PWMRegister < 0) then
  begin
    SetError('Pin ' + APinName + ' does not support PWM.');
    Exit;
  end;
  if (AValue < 0) or (AValue > 255) then
  begin
    SetError('PWM value must be in range 0..255.');
    Exit;
  end;

  if FAutoConnect and (FModbusClient <> nil) and not FModbusClient.Active then
    Connect;

  if (FModbusClient <> nil) and FModbusClient.Active then
  begin
    Result := FModbusClient.WriteSingleRegister(FSlaveID, Pin.PWMRegister, AValue);
    if not Result then
      SetError('Modbus Write PWM failed: ' + FModbusClient.LastError);
  end
  else
    SetError('Modbus connection is not active.');
end;

function TAIArduinoModbusPinMap.ReadAnalog(const APinName: string; out AValue: Integer): Boolean;
var
  Pin: TAIArduinoPinMapItem;
  Data: array[0..0] of Word;
begin
  Result := False;
  AValue := 0;
  ClearError;
  Pin := FindPin(APinName);
  if Pin = nil then
  begin
    SetError('Pin not found in map: ' + APinName);
    Exit;
  end;
  if Pin.Reserved then
  begin
    SetError('Pin ' + APinName + ' is reserved.');
    Exit;
  end;
  if not Pin.CanAnalog or (Pin.AnalogRegister < 0) then
  begin
    SetError('Pin ' + APinName + ' does not support analog read.');
    Exit;
  end;

  if FAutoConnect and (FModbusClient <> nil) and not FModbusClient.Active then
    Connect;

  if (FModbusClient <> nil) and FModbusClient.Active then
  begin
    Result := FModbusClient.ReadHoldingRegisters(FSlaveID, Pin.AnalogRegister, 1, Data);
    if Result then
      AValue := Data[0]
    else
      SetError('Modbus Read Analog failed: ' + FModbusClient.LastError);
  end
  else
    SetError('Modbus connection is not active.');
end;

end.
