unit aiarduinomodbuspinmap;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, strutils, typinfo, aibase, aimodbus, aimodbuscommandmap;

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

  TArduinoPinDirection = (
    apdUnknown,
    apdInput,
    apdOutput,
    apdInputOutput
  );

  TArduinoPinPullMode = (
    appNone,
    appPullUp,
    appPullDown,
    appExternalPullUp,
    appExternalPullDown
  );

  TArduinoPinPolarity = (
    aplActiveHigh,
    aplActiveLow
  );

  TArduinoContactType = (
    actNone,
    actNormallyOpen,
    actNormallyClosed
  );

  TArduinoPinChangeSource = (
    pcsUnknown,
    pcsRead,
    pcsWrite,
    pcsSetup,
    pcsPolling
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

    // Industrial / Electrical Properties
    FTag: Integer;
    FShortName: string;
    FGroup: string;
    FDescription: string;
    FDirection: TArduinoPinDirection;
    FPullMode: TArduinoPinPullMode;
    FPolarity: TArduinoPinPolarity;
    FContactType: TArduinoContactType;
    FDefaultValue: Integer;
    FLastValue: Integer;
    FLastReadValue: Integer;
    FLastWriteValue: Integer;
    FSetupEnabled: Boolean;
    FNotifyOnChange: Boolean;
    FPullModeRegister: Integer;
    FPolarityRegister: Integer;
    FContactTypeRegister: Integer;
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

    // Industrial Published Properties
    property Tag: Integer read FTag write FTag;
    property ShortName: string read FShortName write FShortName;
    property Group: string read FGroup write FGroup;
    property Description: string read FDescription write FDescription;
    property Direction: TArduinoPinDirection read FDirection write FDirection;
    property PullMode: TArduinoPinPullMode read FPullMode write FPullMode;
    property Polarity: TArduinoPinPolarity read FPolarity write FPolarity;
    property ContactType: TArduinoContactType read FContactType write FContactType;
    property DefaultValue: Integer read FDefaultValue write FDefaultValue;
    property LastValue: Integer read FLastValue write FLastValue;
    property LastReadValue: Integer read FLastReadValue write FLastReadValue;
    property LastWriteValue: Integer read FLastWriteValue write FLastWriteValue;
    property SetupEnabled: Boolean read FSetupEnabled write FSetupEnabled;
    property NotifyOnChange: Boolean read FNotifyOnChange write FNotifyOnChange;
    property PullModeRegister: Integer read FPullModeRegister write FPullModeRegister;
    property PolarityRegister: Integer read FPolarityRegister write FPolarityRegister;
    property ContactTypeRegister: Integer read FContactTypeRegister write FContactTypeRegister;
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

  // Events definition
  TArduinoPinStateChangedEvent = procedure(
    Sender: TObject;
    Pin: TAIArduinoPinMapItem;
    OldValue: Integer;
    NewValue: Integer;
    Source: TArduinoPinChangeSource
  ) of object;

  TArduinoPinModeChangedEvent = procedure(
    Sender: TObject;
    Pin: TAIArduinoPinMapItem;
    OldMode: TArduinoPinMode;
    NewMode: TArduinoPinMode
  ) of object;

  TArduinoPinErrorEvent = procedure(
    Sender: TObject;
    Pin: TAIArduinoPinMapItem;
    const AMessage: string
  ) of object;

  TArduinoPinSetupEvent = procedure(
    Sender: TObject;
    Pin: TAIArduinoPinMapItem
  ) of object;

  { TAIArduinoModbusPinMap }

  TAIArduinoModbusPinMap = class(TAIBaseComponent)
  private
    FBoardType: TArduinoBoardType;
    FModbusClient: TAIModbusClient;
    FCommandMap: TAIModbusCommandMap;
    FPins: TAIArduinoPinMapItems;
    FSlaveID: Integer;
    FAutoConnect: Boolean;

    // Event fields
    FOnPinStateChanged: TArduinoPinStateChangedEvent;
    FOnPinModeChanged: TArduinoPinModeChangedEvent;
    FOnPinError: TArduinoPinErrorEvent;
    FOnBeforePinSetup: TArduinoPinSetupEvent;
    FOnAfterPinSetup: TArduinoPinSetupEvent;

    // AI/ChatGPT properties
    FAISetupName: string;
    FAISetupEnabled: Boolean;

    function PinModeToWord(AMode: TArduinoPinMode): Word;
    function WordToPinMode(AValue: Word): TArduinoPinMode;

    function NormalizeOutputValue(Pin: TAIArduinoPinMapItem; AValue: Integer): Integer;
    function NormalizeInputValue(Pin: TAIArduinoPinMapItem; AValue: Integer): Integer;

    procedure DoPinStateChanged(Pin: TAIArduinoPinMapItem; OldVal, NewVal: Integer; Source: TArduinoPinChangeSource);
    procedure DoPinModeChanged(Pin: TAIArduinoPinMapItem; OldMode, NewMode: TArduinoPinMode);
    procedure DoPinError(Pin: TAIArduinoPinMapItem; const AMsg: string);
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

    // Pin Finders
    function FindPinByName(const APinName: string): TAIArduinoPinMapItem;
    function FindPinByShortName(const AShortName: string): TAIArduinoPinMapItem;
    function FindPinByTag(ATag: Integer): TAIArduinoPinMapItem;
    function FindPinsByGroup(const AGroup: string; AList: TList): Integer;
    // Compatibility finder
    function FindPin(const APinName: string): TAIArduinoPinMapItem;

    // Operations by Name
    function SetPinMode(const APinName: string; AMode: TArduinoPinMode): Boolean;
    function ReadPin(const APinName: string; out AValue: Integer): Boolean;
    function WritePin(const APinName: string; AValue: Integer): Boolean;
    function SetPWM(const APinName: string; AValue: Integer): Boolean;
    function ReadAnalog(const APinName: string; out AValue: Integer): Boolean;

    // Operations by Tag
    function SetPinModeByTag(ATag: Integer; AMode: TArduinoPinMode): Boolean;
    function WritePinByTag(ATag: Integer; AValue: Integer): Boolean;
    function ReadPinByTag(ATag: Integer; out AValue: Integer): Boolean;

    // Operations by ShortName
    function SetPinModeByShortName(const AShortName: string; AMode: TArduinoPinMode): Boolean;
    function WritePinByShortName(const AShortName: string; AValue: Integer): Boolean;
    function ReadPinByShortName(const AShortName: string; out AValue: Integer): Boolean;

    // Setup pins method
    function SetupPins: Boolean;

    // AI / JSON Export
    function ToJSON: string;
    function ToSetupPrompt: string;
    function ToSetupText: string;
    function GetInitializedPinsText: string;
    function BuildAISetupContext: string;
    function BuildAISetupJSON: string;
    procedure UpdatePromptFromPinMap;
  published
    property BoardType: TArduinoBoardType read FBoardType write FBoardType default abtNano;
    property ModbusClient: TAIModbusClient read FModbusClient write FModbusClient;
    property CommandMap: TAIModbusCommandMap read FCommandMap write FCommandMap;
    property Pins: TAIArduinoPinMapItems read FPins write FPins;
    property SlaveID: Integer read FSlaveID write FSlaveID default 1;
    property AutoConnect: Boolean read FAutoConnect write FAutoConnect default False;

    // Event Properties
    property OnPinStateChanged: TArduinoPinStateChangedEvent read FOnPinStateChanged write FOnPinStateChanged;
    property OnPinModeChanged: TArduinoPinModeChangedEvent read FOnPinModeChanged write FOnPinModeChanged;
    property OnPinError: TArduinoPinErrorEvent read FOnPinError write FOnPinError;
    property OnBeforePinSetup: TArduinoPinSetupEvent read FOnBeforePinSetup write FOnBeforePinSetup;
    property OnAfterPinSetup: TArduinoPinSetupEvent read FOnAfterPinSetup write FOnAfterPinSetup;

    // AI Properties
    property AISetupName: string read FAISetupName write FAISetupName;
    property AISetupEnabled: Boolean read FAISetupEnabled write FAISetupEnabled default True;
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

    // Copy new industrial fields
    FTag := Src.Tag;
    FShortName := Src.ShortName;
    FGroup := Src.Group;
    FDescription := Src.Description;
    FDirection := Src.Direction;
    FPullMode := Src.PullMode;
    FPolarity := Src.Polarity;
    FContactType := Src.ContactType;
    FDefaultValue := Src.DefaultValue;
    FLastValue := Src.LastValue;
    FLastReadValue := Src.LastReadValue;
    FLastWriteValue := Src.LastWriteValue;
    FSetupEnabled := Src.SetupEnabled;
    FNotifyOnChange := Src.NotifyOnChange;
    FPullModeRegister := Src.PullModeRegister;
    FPolarityRegister := Src.PolarityRegister;
    FContactTypeRegister := Src.ContactTypeRegister;
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
  FAISetupEnabled := True;
  LoadArduinoNanoDefaultMap;
end;

destructor TAIArduinoModbusPinMap.Destroy;
begin
  FPins.Free;
  inherited Destroy;
end;

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

function TAIArduinoModbusPinMap.NormalizeOutputValue(Pin: TAIArduinoPinMapItem; AValue: Integer): Integer;
begin
  if Pin.Polarity = aplActiveLow then
  begin
    if AValue <> 0 then Result := 0 else Result := 1;
  end
  else
    Result := AValue;
end;

function TAIArduinoModbusPinMap.NormalizeInputValue(Pin: TAIArduinoPinMapItem; AValue: Integer): Integer;
begin
  if Pin.Polarity = aplActiveLow then
  begin
    if AValue <> 0 then Result := 0 else Result := 1;
  end
  else
    Result := AValue;
end;

procedure TAIArduinoModbusPinMap.DoPinStateChanged(Pin: TAIArduinoPinMapItem; OldVal, NewVal: Integer; Source: TArduinoPinChangeSource);
begin
  if Assigned(FOnPinStateChanged) then
    FOnPinStateChanged(Self, Pin, OldVal, NewVal, Source);
end;

procedure TAIArduinoModbusPinMap.DoPinModeChanged(Pin: TAIArduinoPinMapItem; OldMode, NewMode: TArduinoPinMode);
begin
  if Assigned(FOnPinModeChanged) then
    FOnPinModeChanged(Self, Pin, OldMode, NewMode);
end;

procedure TAIArduinoModbusPinMap.DoPinError(Pin: TAIArduinoPinMapItem; const AMsg: string);
begin
  if Assigned(FOnPinError) then
    FOnPinError(Self, Pin, AMsg);
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
    Item.ShortName := Item.Name;
    Item.Tag := I;
    Item.PinNumber := I;
    Item.Mode := apmDisabled;
    Item.Kind := apkDigital;
    Item.Direction := apdUnknown;
    Item.CanPWM := False;
    Item.CanAnalog := False;
    Item.Reserved := True;
    Item.ModeRegister := 10 + I;
    Item.DigitalRegister := 50 + I;
    Item.AnalogRegister := -1;
    Item.PWMRegister := -1;
    Item.PullModeRegister := 240 + I;
    Item.PolarityRegister := 330 + I;
    Item.ContactTypeRegister := 420 + I;
  end;

  // D2..D13
  for I := 2 to 13 do
  begin
    Item := FPins.Add;
    Item.Name := 'D' + IntToStr(I);
    Item.ShortName := Item.Name;
    Item.Tag := I;
    Item.PinNumber := I;
    Item.Mode := apmInput;
    Item.Kind := apkDigital;
    Item.Direction := apdInputOutput;
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
    Item.PullModeRegister := 240 + I;
    Item.PolarityRegister := 330 + I;
    Item.ContactTypeRegister := 420 + I;
    Item.SetupEnabled := True;
  end;

  // A0..A5
  for I := 0 to 5 do
  begin
    Item := FPins.Add;
    Item.Name := 'A' + IntToStr(I);
    Item.ShortName := Item.Name;
    Item.Tag := 14 + I;
    Item.PinNumber := 14 + I;
    Item.Mode := apmInput;
    Item.Kind := apkAnalog;
    Item.Direction := apdInput;
    Item.CanPWM := False;
    Item.CanAnalog := True;
    Item.Reserved := False;
    Item.ModeRegister := 10 + Item.PinNumber;
    Item.DigitalRegister := 50 + Item.PinNumber;
    Item.AnalogRegister := 100 + I;
    Item.PWMRegister := -1;
    Item.PullModeRegister := 240 + Item.PinNumber;
    Item.PolarityRegister := 330 + Item.PinNumber;
    Item.ContactTypeRegister := 420 + Item.PinNumber;
    Item.SetupEnabled := True;
  end;

  // A6 & A7
  for I := 6 to 7 do
  begin
    Item := FPins.Add;
    Item.Name := 'A' + IntToStr(I);
    Item.ShortName := Item.Name;
    Item.Tag := 14 + I;
    Item.PinNumber := 14 + I;
    Item.Mode := apmInput;
    Item.Kind := apkAnalog;
    Item.Direction := apdInput;
    Item.CanPWM := False;
    Item.CanAnalog := True;
    Item.Reserved := False;
    Item.ModeRegister := -1;
    Item.DigitalRegister := -1;
    Item.AnalogRegister := 100 + I;
    Item.PWMRegister := -1;
    Item.PullModeRegister := -1;
    Item.PolarityRegister := -1;
    Item.ContactTypeRegister := -1;
  end;
  UpdatePromptFromPinMap;
end;

procedure TAIArduinoModbusPinMap.LoadArduinoUnoDefaultMap;
var
  Item: TAIArduinoPinMapItem;
  I: Integer;
begin
  ClearMap;
  
  // D0 & D1
  for I := 0 to 1 do
  begin
    Item := FPins.Add;
    Item.Name := 'D' + IntToStr(I);
    Item.ShortName := Item.Name;
    Item.Tag := I;
    Item.PinNumber := I;
    Item.Mode := apmDisabled;
    Item.Kind := apkDigital;
    Item.Direction := apdUnknown;
    Item.CanPWM := False;
    Item.CanAnalog := False;
    Item.Reserved := True;
    Item.ModeRegister := 10 + I;
    Item.DigitalRegister := 50 + I;
    Item.AnalogRegister := -1;
    Item.PWMRegister := -1;
    Item.PullModeRegister := 240 + I;
    Item.PolarityRegister := 330 + I;
    Item.ContactTypeRegister := 420 + I;
  end;

  // D2..D13
  for I := 2 to 13 do
  begin
    Item := FPins.Add;
    Item.Name := 'D' + IntToStr(I);
    Item.ShortName := Item.Name;
    Item.Tag := I;
    Item.PinNumber := I;
    Item.Mode := apmInput;
    Item.Kind := apkDigital;
    Item.Direction := apdInputOutput;
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
    Item.PullModeRegister := 240 + I;
    Item.PolarityRegister := 330 + I;
    Item.ContactTypeRegister := 420 + I;
    Item.SetupEnabled := True;
  end;

  // A0..A5
  for I := 0 to 5 do
  begin
    Item := FPins.Add;
    Item.Name := 'A' + IntToStr(I);
    Item.ShortName := Item.Name;
    Item.Tag := 14 + I;
    Item.PinNumber := 14 + I;
    Item.Mode := apmInput;
    Item.Kind := apkAnalog;
    Item.Direction := apdInput;
    Item.CanPWM := False;
    Item.CanAnalog := True;
    Item.Reserved := False;
    Item.ModeRegister := 10 + Item.PinNumber;
    Item.DigitalRegister := 50 + Item.PinNumber;
    Item.AnalogRegister := 100 + I;
    Item.PWMRegister := -1;
    Item.PullModeRegister := 240 + Item.PinNumber;
    Item.PolarityRegister := 330 + Item.PinNumber;
    Item.ContactTypeRegister := 420 + Item.PinNumber;
    Item.SetupEnabled := True;
  end;
  UpdatePromptFromPinMap;
end;

procedure TAIArduinoModbusPinMap.LoadArduinoMegaDefaultMap;
var
  Item: TAIArduinoPinMapItem;
  I: Integer;
begin
  ClearMap;
  
  // D0 & D1
  for I := 0 to 1 do
  begin
    Item := FPins.Add;
    Item.Name := 'D' + IntToStr(I);
    Item.ShortName := Item.Name;
    Item.Tag := I;
    Item.PinNumber := I;
    Item.Mode := apmDisabled;
    Item.Kind := apkDigital;
    Item.Direction := apdUnknown;
    Item.CanPWM := False;
    Item.CanAnalog := False;
    Item.Reserved := True;
    Item.ModeRegister := 10 + I;
    Item.DigitalRegister := 50 + I;
    Item.AnalogRegister := -1;
    Item.PWMRegister := -1;
    Item.PullModeRegister := 240 + I;
    Item.PolarityRegister := 330 + I;
    Item.ContactTypeRegister := 420 + I;
  end;

  // D2..D53
  for I := 2 to 53 do
  begin
    Item := FPins.Add;
    Item.Name := 'D' + IntToStr(I);
    Item.ShortName := Item.Name;
    Item.Tag := I;
    Item.PinNumber := I;
    Item.Mode := apmInput;
    Item.Kind := apkDigital;
    Item.Direction := apdInputOutput;
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
    Item.PullModeRegister := 240 + I;
    Item.PolarityRegister := 330 + I;
    Item.ContactTypeRegister := 420 + I;
    Item.SetupEnabled := True;
  end;

  // A0..A15
  for I := 0 to 15 do
  begin
    Item := FPins.Add;
    Item.Name := 'A' + IntToStr(I);
    Item.ShortName := Item.Name;
    Item.Tag := 54 + I;
    Item.PinNumber := 54 + I;
    Item.Mode := apmInput;
    Item.Kind := apkAnalog;
    Item.Direction := apdInput;
    Item.CanPWM := False;
    Item.CanAnalog := True;
    Item.Reserved := False;
    Item.ModeRegister := 10 + Item.PinNumber;
    Item.DigitalRegister := 50 + Item.PinNumber;
    Item.AnalogRegister := 100 + I;
    Item.PWMRegister := -1;
    Item.PullModeRegister := 240 + Item.PinNumber;
    Item.PolarityRegister := 330 + Item.PinNumber;
    Item.ContactTypeRegister := 420 + Item.PinNumber;
    Item.SetupEnabled := True;
  end;
  UpdatePromptFromPinMap;
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
    Item.ShortName := Item.Name;
    Item.Tag := GPIOPins[I];
    Item.PinNumber := GPIOPins[I];
    Item.Mode := apmInput;
    Item.Kind := apkDigital;
    Item.Direction := apdInputOutput;
    Item.CanPWM := True;
    Item.CanAnalog := False;
    Item.Reserved := False;
    Item.ModeRegister := 10 + Item.PinNumber;
    Item.DigitalRegister := 50 + Item.PinNumber;
    Item.AnalogRegister := -1;
    Item.PWMRegister := 150 + Item.PinNumber;
    Item.PullModeRegister := 240 + Item.PinNumber;
    Item.PolarityRegister := 330 + Item.PinNumber;
    Item.ContactTypeRegister := 420 + Item.PinNumber;
    Item.SetupEnabled := True;
  end;

  for I := 0 to High(AnalogPins) do
  begin
    Item := FPins.Add;
    Item.Name := 'ADC' + IntToStr(I);
    Item.ShortName := Item.Name;
    Item.Tag := AnalogPins[I];
    Item.PinNumber := AnalogPins[I];
    Item.Mode := apmInput;
    Item.Kind := apkAnalog;
    Item.Direction := apdInput;
    Item.CanPWM := False;
    Item.CanAnalog := True;
    Item.Reserved := False;
    Item.ModeRegister := 10 + Item.PinNumber;
    Item.DigitalRegister := 50 + Item.PinNumber;
    Item.AnalogRegister := 100 + I;
    Item.PWMRegister := -1;
    Item.PullModeRegister := 240 + Item.PinNumber;
    Item.PolarityRegister := 330 + Item.PinNumber;
    Item.ContactTypeRegister := 420 + Item.PinNumber;
    Item.SetupEnabled := True;
  end;
  UpdatePromptFromPinMap;
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

function TAIArduinoModbusPinMap.FindPinByName(const APinName: string): TAIArduinoPinMapItem;
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

function TAIArduinoModbusPinMap.FindPinByShortName(const AShortName: string): TAIArduinoPinMapItem;
var
  I: Integer;
begin
  Result := nil;
  for I := 0 to FPins.Count - 1 do
  begin
    if SameText(FPins[I].ShortName, AShortName) then
    begin
      Result := FPins[I];
      Exit;
    end;
  end;
end;

function TAIArduinoModbusPinMap.FindPinByTag(ATag: Integer): TAIArduinoPinMapItem;
var
  I: Integer;
begin
  Result := nil;
  for I := 0 to FPins.Count - 1 do
  begin
    if FPins[I].Tag = ATag then
    begin
      Result := FPins[I];
      Exit;
    end;
  end;
end;

function TAIArduinoModbusPinMap.FindPinsByGroup(const AGroup: string; AList: TList): Integer;
var
  I: Integer;
begin
  Result := 0;
  if AList = nil then Exit;
  for I := 0 to FPins.Count - 1 do
  begin
    if SameText(FPins[I].Group, AGroup) then
    begin
      AList.Add(FPins[I]);
      Inc(Result);
    end;
  end;
end;

function TAIArduinoModbusPinMap.FindPin(const APinName: string): TAIArduinoPinMapItem;
begin
  Result := FindPinByName(APinName);
end;

function TAIArduinoModbusPinMap.SetPinMode(const APinName: string; AMode: TArduinoPinMode): Boolean;
var
  Pin: TAIArduinoPinMapItem;
  OldMode: TArduinoPinMode;
begin
  Result := False;
  ClearError;
  Pin := FindPinByName(APinName);
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

  if (FCommandMap <> nil) and not FCommandMap.IsValidFunctionCode(6) then
  begin
    SetError('Function code 06 is not enabled in command map.');
    Exit;
  end;

  if FAutoConnect and (FModbusClient <> nil) and not FModbusClient.Active then
    Connect;

  if (FModbusClient <> nil) and FModbusClient.Active then
  begin
    OldMode := Pin.Mode;
    Result := FModbusClient.WriteSingleRegister(FSlaveID, Pin.ModeRegister, PinModeToWord(AMode));
    if Result then
    begin
      Pin.Mode := AMode;
      DoPinModeChanged(Pin, OldMode, AMode);
    end
    else
    begin
      SetError('Modbus Write failed: ' + FModbusClient.LastError);
      DoPinError(Pin, FModbusClient.LastError);
    end;
  end
  else
    SetError('Modbus connection is not active.');
end;

function TAIArduinoModbusPinMap.ReadPin(const APinName: string; out AValue: Integer): Boolean;
var
  Pin: TAIArduinoPinMapItem;
  Data: array[0..0] of Word;
  OldValue, NewValue: Integer;
begin
  Result := False;
  AValue := 0;
  ClearError;
  Pin := FindPinByName(APinName);
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

  if (FCommandMap <> nil) and not FCommandMap.IsValidFunctionCode(3) then
  begin
    SetError('Function code 03 is not enabled in command map.');
    Exit;
  end;

  if FAutoConnect and (FModbusClient <> nil) and not FModbusClient.Active then
    Connect;

  if (FModbusClient <> nil) and FModbusClient.Active then
  begin
    Result := FModbusClient.ReadHoldingRegisters(FSlaveID, Pin.DigitalRegister, 1, Data);
    if Result then
    begin
      OldValue := Pin.LastValue;
      NewValue := NormalizeInputValue(Pin, Data[0]);
      AValue := NewValue;
      Pin.LastReadValue := NewValue;
      Pin.LastValue := NewValue;
      if Pin.NotifyOnChange and (OldValue <> NewValue) then
        DoPinStateChanged(Pin, OldValue, NewValue, pcsRead);
    end
    else
    begin
      SetError('Modbus Read failed: ' + FModbusClient.LastError);
      DoPinError(Pin, FModbusClient.LastError);
    end;
  end
  else
    SetError('Modbus connection is not active.');
end;

function TAIArduinoModbusPinMap.WritePin(const APinName: string; AValue: Integer): Boolean;
var
  Pin: TAIArduinoPinMapItem;
  OldValue, PhysicalValue: Integer;
begin
  Result := False;
  ClearError;
  Pin := FindPinByName(APinName);
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

  if (FCommandMap <> nil) and not FCommandMap.IsValidFunctionCode(6) then
  begin
    SetError('Function code 06 is not enabled in command map.');
    Exit;
  end;

  if FAutoConnect and (FModbusClient <> nil) and not FModbusClient.Active then
    Connect;

  if (FModbusClient <> nil) and FModbusClient.Active then
  begin
    OldValue := Pin.LastValue;
    PhysicalValue := NormalizeOutputValue(Pin, AValue);
    Result := FModbusClient.WriteSingleRegister(FSlaveID, Pin.DigitalRegister, PhysicalValue);
    if Result then
    begin
      Pin.LastWriteValue := AValue;
      Pin.LastValue := AValue;
      if Pin.NotifyOnChange and (OldValue <> AValue) then
        DoPinStateChanged(Pin, OldValue, AValue, pcsWrite);
    end
    else
    begin
      SetError('Modbus Write failed: ' + FModbusClient.LastError);
      DoPinError(Pin, FModbusClient.LastError);
    end;
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
  Pin := FindPinByName(APinName);
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

  if (FCommandMap <> nil) and not FCommandMap.IsValidFunctionCode(6) then
  begin
    SetError('Function code 06 is not enabled in command map.');
    Exit;
  end;

  if FAutoConnect and (FModbusClient <> nil) and not FModbusClient.Active then
    Connect;

  if (FModbusClient <> nil) and FModbusClient.Active then
  begin
    Result := FModbusClient.WriteSingleRegister(FSlaveID, Pin.PWMRegister, AValue);
    if not Result then
    begin
      SetError('Modbus Write PWM failed: ' + FModbusClient.LastError);
      DoPinError(Pin, FModbusClient.LastError);
    end;
  end
  else
    SetError('Modbus connection is not active.');
end;

function TAIArduinoModbusPinMap.ReadAnalog(const APinName: string; out AValue: Integer): Boolean;
var
  Pin: TAIArduinoPinMapItem;
  Data: array[0..0] of Word;
  OldValue: Integer;
begin
  Result := False;
  AValue := 0;
  ClearError;
  Pin := FindPinByName(APinName);
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

  if (FCommandMap <> nil) and not FCommandMap.IsValidFunctionCode(3) then
  begin
    SetError('Function code 03 is not enabled in command map.');
    Exit;
  end;

  if FAutoConnect and (FModbusClient <> nil) and not FModbusClient.Active then
    Connect;

  if (FModbusClient <> nil) and FModbusClient.Active then
  begin
    Result := FModbusClient.ReadHoldingRegisters(FSlaveID, Pin.AnalogRegister, 1, Data);
    if Result then
    begin
      OldValue := Pin.LastValue;
      AValue := Data[0];
      Pin.LastReadValue := Data[0];
      Pin.LastValue := Data[0];
      if Pin.NotifyOnChange and (OldValue <> Data[0]) then
        DoPinStateChanged(Pin, OldValue, Data[0], pcsRead);
    end
    else
    begin
      SetError('Modbus Read Analog failed: ' + FModbusClient.LastError);
      DoPinError(Pin, FModbusClient.LastError);
    end;
  end
  else
    SetError('Modbus connection is not active.');
end;

// Tag implementation methods
function TAIArduinoModbusPinMap.SetPinModeByTag(ATag: Integer; AMode: TArduinoPinMode): Boolean;
var
  Pin: TAIArduinoPinMapItem;
begin
  Pin := FindPinByTag(ATag);
  if Pin <> nil then
    Result := SetPinMode(Pin.Name, AMode)
  else
  begin
    SetError('Pin not found with tag: ' + IntToStr(ATag));
    Result := False;
  end;
end;

function TAIArduinoModbusPinMap.WritePinByTag(ATag: Integer; AValue: Integer): Boolean;
var
  Pin: TAIArduinoPinMapItem;
begin
  Pin := FindPinByTag(ATag);
  if Pin <> nil then
    Result := WritePin(Pin.Name, AValue)
  else
  begin
    SetError('Pin not found with tag: ' + IntToStr(ATag));
    Result := False;
  end;
end;

function TAIArduinoModbusPinMap.ReadPinByTag(ATag: Integer; out AValue: Integer): Boolean;
var
  Pin: TAIArduinoPinMapItem;
begin
  AValue := 0;
  Pin := FindPinByTag(ATag);
  if Pin <> nil then
    Result := ReadPin(Pin.Name, AValue)
  else
  begin
    SetError('Pin not found with tag: ' + IntToStr(ATag));
    Result := False;
  end;
end;

// ShortName implementation methods
function TAIArduinoModbusPinMap.SetPinModeByShortName(const AShortName: string; AMode: TArduinoPinMode): Boolean;
var
  Pin: TAIArduinoPinMapItem;
begin
  Pin := FindPinByShortName(AShortName);
  if Pin <> nil then
    Result := SetPinMode(Pin.Name, AMode)
  else
  begin
    SetError('Pin not found with ShortName: ' + AShortName);
    Result := False;
  end;
end;

function TAIArduinoModbusPinMap.WritePinByShortName(const AShortName: string; AValue: Integer): Boolean;
var
  Pin: TAIArduinoPinMapItem;
begin
  Pin := FindPinByShortName(AShortName);
  if Pin <> nil then
    Result := WritePin(Pin.Name, AValue)
  else
  begin
    SetError('Pin not found with ShortName: ' + AShortName);
    Result := False;
  end;
end;

function TAIArduinoModbusPinMap.ReadPinByShortName(const AShortName: string; out AValue: Integer): Boolean;
var
  Pin: TAIArduinoPinMapItem;
begin
  AValue := 0;
  Pin := FindPinByShortName(AShortName);
  if Pin <> nil then
    Result := ReadPin(Pin.Name, AValue)
  else
  begin
    SetError('Pin not found with ShortName: ' + AShortName);
    Result := False;
  end;
end;

function TAIArduinoModbusPinMap.SetupPins: Boolean;
var
  I: Integer;
  Pin: TAIArduinoPinMapItem;
begin
  Result := True;
  ClearError;
  for I := 0 to FPins.Count - 1 do
  begin
    Pin := FPins[I];
    if Pin.SetupEnabled and not Pin.Reserved then
    begin
      if Assigned(FOnBeforePinSetup) then
        FOnBeforePinSetup(Self, Pin);

      // Write Mode
      if Pin.ModeRegister >= 0 then
      begin
        if not SetPinMode(Pin.Name, Pin.Mode) then
        begin
          Result := False;
          Break;
        end;
      end;

      // Write default output values
      if Pin.Mode = apmOutput then
      begin
        if not WritePin(Pin.Name, Pin.DefaultValue) then
        begin
          Result := False;
          Break;
        end;
      end
      else if Pin.Mode = apmPWM then
      begin
        if not SetPWM(Pin.Name, Pin.DefaultValue) then
        begin
          Result := False;
          Break;
        end;
      end;

      // Pull Mode configuration
      if (Pin.PullModeRegister >= 0) and (Pin.PullMode <> appNone) then
      begin
        if not FModbusClient.WriteSingleRegister(FSlaveID, Pin.PullModeRegister, Ord(Pin.PullMode)) then
        begin
          Result := False;
          Break;
        end;
      end;

      if Assigned(FOnAfterPinSetup) then
        FOnAfterPinSetup(Self, Pin);
    end;
  end;
end;

function TAIArduinoModbusPinMap.ToJSON: string;
var
  I: Integer;
  Pin: TAIArduinoPinMapItem;
begin
  Result := '{';
  Result := Result + Format('"board": "%s", "slave_id": %d, "transport": "Modbus RTU", "pins": [', 
    [IfThen(FBoardType = abtNano, 'Arduino Nano', IfThen(FBoardType = abtUno, 'Arduino Uno', IfThen(FBoardType = abtMega, 'Arduino Mega', 'ESP32'))),
     FSlaveID]);
  for I := 0 to FPins.Count - 1 do
  begin
    Pin := FPins[I];
    if I > 0 then Result := Result + ',';
    Result := Result + Format(
      '{"name": "%s", "short_name": "%s", "group": "%s", "tag": %d, "pin_number": %d, "direction": "%s", "pull": "%s", "polarity": "%s", "contact": "%s", "registers": {"mode": %d, "digital": %d, "analog": %d, "pwm": %d}}',
      [Pin.Name, Pin.ShortName, Pin.Group, Pin.Tag, Pin.PinNumber,
       IfThen(Pin.Direction = apdInput, 'input', IfThen(Pin.Direction = apdOutput, 'output', 'inout')),
       IfThen(Pin.PullMode = appPullUp, 'pullup', IfThen(Pin.PullMode = appPullDown, 'pulldown', 'none')),
       IfThen(Pin.Polarity = aplActiveLow, 'active_low', 'active_high'),
       IfThen(Pin.ContactType = actNormallyClosed, 'normally_closed', 'normally_open'),
       Pin.ModeRegister, Pin.DigitalRegister, Pin.AnalogRegister, Pin.PWMRegister]
    );
  end;
  Result := Result + ']}';
end;

function TAIArduinoModbusPinMap.ToSetupPrompt: string;
begin
  Result := BuildAISetupContext;
end;

function TAIArduinoModbusPinMap.ToSetupText: string;
begin
  Result := BuildAISetupContext;
end;

function TAIArduinoModbusPinMap.GetInitializedPinsText: string;
var
  I: Integer;
  Pin: TAIArduinoPinMapItem;
begin
  Result := 'Initialized Pins State:' + LineEnding;
  for I := 0 to FPins.Count - 1 do
  begin
    Pin := FPins[I];
    if Pin.SetupEnabled then
      Result := Result + Format('  - %s (%s, Group: %s, Tag: %d): Mode=%s, Value=%d' + LineEnding,
        [Pin.Name, Pin.ShortName, Pin.Group, Pin.Tag, GetEnumName(TypeInfo(TArduinoPinMode), Ord(Pin.Mode)), Pin.LastValue]);
  end;
end;

function TAIArduinoModbusPinMap.BuildAISetupContext: string;
begin
  Result := 'Arduino Modbus PinMap Configuration:' + LineEnding +
            '  Board Type: ' + GetEnumName(TypeInfo(TArduinoBoardType), Ord(FBoardType)) + LineEnding +
            '  Slave ID: ' + IntToStr(FSlaveID) + LineEnding +
            ToJSON;
end;

function TAIArduinoModbusPinMap.BuildAISetupJSON: string;
begin
  Result := ToJSON;
end;

procedure TAIArduinoModbusPinMap.UpdatePromptFromPinMap;
begin
  FPrompt := 'TAIArduinoModbusPinMap Interface Configuration:' + LineEnding +
             BuildAISetupContext + LineEnding +
             GetInitializedPinsText;
end;

end.
