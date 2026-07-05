unit aimodbuscommandmap;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, strutils, aibase;

type
  TModbusCommandKind = (
    mckStandard,
    mckCustom
  );

  TModbusCommandAccess = (
    mcaRead,
    mcaWrite,
    mcaReadWrite
  );

  TModbusCommandDataArea = (
    mcdaCoil,
    mcdaDiscreteInput,
    mcdaHoldingRegister,
    mcdaInputRegister,
    mcdaCustom
  );

  { TAIModbusCommandItem }

  TAIModbusCommandItem = class(TCollectionItem)
  private
    FCode: Integer;
    FName: string;
    FShortName: string;
    FGroup: string;
    FDescription: string;
    FKind: TModbusCommandKind;
    FAccess: TModbusCommandAccess;
    FDataArea: TModbusCommandDataArea;
    FEnabled: Boolean;
    FIsValidForArduinoPinMap: Boolean;
    FDefaultAddress: Integer;
    FDefaultQuantity: Integer;
    FMinAddress: Integer;
    FMaxAddress: Integer;
    FMinValue: Integer;
    FMaxValue: Integer;
  public
    procedure Assign(Source: TPersistent); override;
  published
    property Code: Integer read FCode write FCode;
    property Name: string read FName write FName;
    property ShortName: string read FShortName write FShortName;
    property Group: string read FGroup write FGroup;
    property Description: string read FDescription write FDescription;
    property Kind: TModbusCommandKind read FKind write FKind;
    property Access: TModbusCommandAccess read FAccess write FAccess;
    property DataArea: TModbusCommandDataArea read FDataArea write FDataArea;
    property Enabled: Boolean read FEnabled write FEnabled;
    property IsValidForArduinoPinMap: Boolean read FIsValidForArduinoPinMap write FIsValidForArduinoPinMap;
    property DefaultAddress: Integer read FDefaultAddress write FDefaultAddress;
    property DefaultQuantity: Integer read FDefaultQuantity write FDefaultQuantity;
    property MinAddress: Integer read FMinAddress write FMinAddress;
    property MaxAddress: Integer read FMaxAddress write FMaxAddress;
    property MinValue: Integer read FMinValue write FMinValue;
    property MaxValue: Integer read FMaxValue write FMaxValue;
  end;

  { TAIModbusCommandItems }

  TAIModbusCommandItems = class(TOwnedCollection)
  private
    function GetItem(Index: Integer): TAIModbusCommandItem;
    procedure SetItem(Index: Integer; AValue: TAIModbusCommandItem);
  public
    constructor Create(AOwner: TPersistent);
    function Add: TAIModbusCommandItem;
    function FindByCode(ACode: Integer): TAIModbusCommandItem;
    function FindByShortName(const AShortName: string): TAIModbusCommandItem;
    property Items[Index: Integer]: TAIModbusCommandItem read GetItem write SetItem; default;
  end;

  { TAIModbusCommandMap }

  TAIModbusCommandMap = class(TAIBaseComponent)
  private
    FCommands: TAIModbusCommandItems;
    FAllowCustomCommands: Boolean;
    FStrictValidation: Boolean;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    procedure Clear;
    procedure LoadDefaultModbusCommands;
    function IsValidFunctionCode(ACode: Integer): Boolean;
    function IsUserDefinedFunctionCode(ACode: Integer): Boolean;
    // Helper to add commands
    function AddCommand(ACode: Integer; const AShortName, AName: string; ADataArea: TModbusCommandDataArea; AAccess: TModbusCommandAccess): TAIModbusCommandItem;
    function AddCustomCommand(ACode: Integer; const AShortName, AName: string): TAIModbusCommandItem;
    
    function ToJSON: string;
    function ToSetupPrompt: string;
  published
    property Commands: TAIModbusCommandItems read FCommands write FCommands;
    property AllowCustomCommands: Boolean read FAllowCustomCommands write FAllowCustomCommands default True;
    property StrictValidation: Boolean read FStrictValidation write FStrictValidation default True;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('AI Industrial', [TAIModbusCommandMap]);
end;

{ TAIModbusCommandItem }

procedure TAIModbusCommandItem.Assign(Source: TPersistent);
var
  Src: TAIModbusCommandItem;
begin
  if Source is TAIModbusCommandItem then
  begin
    Src := TAIModbusCommandItem(Source);
    FCode := Src.Code;
    FName := Src.Name;
    FShortName := Src.ShortName;
    FGroup := Src.Group;
    FDescription := Src.Description;
    FKind := Src.Kind;
    FAccess := Src.Access;
    FDataArea := Src.DataArea;
    FEnabled := Src.Enabled;
    FIsValidForArduinoPinMap := Src.IsValidForArduinoPinMap;
    FDefaultAddress := Src.DefaultAddress;
    FDefaultQuantity := Src.DefaultQuantity;
    FMinAddress := Src.MinAddress;
    FMaxAddress := Src.MaxAddress;
    FMinValue := Src.MinValue;
    FMaxValue := Src.MaxValue;
  end
  else
    inherited Assign(Source);
end;

{ TAIModbusCommandItems }

constructor TAIModbusCommandItems.Create(AOwner: TPersistent);
begin
  inherited Create(AOwner, TAIModbusCommandItem);
end;

function TAIModbusCommandItems.GetItem(Index: Integer): TAIModbusCommandItem;
begin
  Result := TAIModbusCommandItem(inherited GetItem(Index));
end;

procedure TAIModbusCommandItems.SetItem(Index: Integer; AValue: TAIModbusCommandItem);
begin
  inherited SetItem(Index, AValue);
end;

function TAIModbusCommandItems.Add: TAIModbusCommandItem;
begin
  Result := TAIModbusCommandItem(inherited Add);
end;

function TAIModbusCommandItems.FindByCode(ACode: Integer): TAIModbusCommandItem;
var
  I: Integer;
begin
  Result := nil;
  for I := 0 to Count - 1 do
  begin
    if Items[I].Code = ACode then
    begin
      Result := Items[I];
      Exit;
    end;
  end;
end;

function TAIModbusCommandItems.FindByShortName(const AShortName: string): TAIModbusCommandItem;
var
  I: Integer;
begin
  Result := nil;
  for I := 0 to Count - 1 do
  begin
    if SameText(Items[I].ShortName, AShortName) then
    begin
      Result := Items[I];
      Exit;
    end;
  end;
end;

{ TAIModbusCommandMap }

constructor TAIModbusCommandMap.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FPrompt := 'Component TAIModbusCommandMap maintains a register of valid Modbus Function Codes, including standard codes and custom user-defined codes.';
  FCommands := TAIModbusCommandItems.Create(Self);
  FAllowCustomCommands := True;
  FStrictValidation := True;
  LoadDefaultModbusCommands;
end;

destructor TAIModbusCommandMap.Destroy;
begin
  FCommands.Free;
  inherited Destroy;
end;

procedure TAIModbusCommandMap.Clear;
begin
  FCommands.Clear;
end;

function TAIModbusCommandMap.AddCommand(ACode: Integer; const AShortName, AName: string; ADataArea: TModbusCommandDataArea; AAccess: TModbusCommandAccess): TAIModbusCommandItem;
begin
  Result := FCommands.Add;
  Result.Code := ACode;
  Result.ShortName := AShortName;
  Result.Name := AName;
  Result.Kind := mckStandard;
  Result.DataArea := ADataArea;
  Result.Access := AAccess;
  Result.Enabled := True;
  Result.IsValidForArduinoPinMap := False;
end;

procedure TAIModbusCommandMap.LoadDefaultModbusCommands;
var
  Item: TAIModbusCommandItem;
begin
  Clear;
  // 01 Read Coils
  Item := AddCommand(1, 'ReadCoils', 'Read Coils', mcdaCoil, mcaRead);
  
  // 02 Read Discrete Inputs
  Item := AddCommand(2, 'ReadDiscreteInputs', 'Read Discrete Inputs', mcdaDiscreteInput, mcaRead);
  
  // 03 Read Holding Registers
  Item := AddCommand(3, 'ReadHoldingRegisters', 'Read Holding Registers', mcdaHoldingRegister, mcaRead);
  Item.IsValidForArduinoPinMap := True;
  
  // 04 Read Input Registers
  Item := AddCommand(4, 'ReadInputRegisters', 'Read Input Registers', mcdaInputRegister, mcaRead);
  
  // 05 Write Single Coil
  Item := AddCommand(5, 'WriteSingleCoil', 'Write Single Coil', mcdaCoil, mcaWrite);
  
  // 06 Write Single Register
  Item := AddCommand(6, 'WriteSingleRegister', 'Write Single Register', mcdaHoldingRegister, mcaWrite);
  Item.IsValidForArduinoPinMap := True;
  
  // 15 Write Multiple Coils
  Item := AddCommand(15, 'WriteMultipleCoils', 'Write Multiple Coils', mcdaCoil, mcaWrite);
  
  // 16 Write Multiple Registers
  Item := AddCommand(16, 'WriteMultipleRegisters', 'Write Multiple Registers', mcdaHoldingRegister, mcaWrite);
  Item.IsValidForArduinoPinMap := True;
  
  // 23 Read/Write Multiple Registers
  Item := AddCommand(23, 'ReadWriteMultipleRegisters', 'Read/Write Multiple Registers', mcdaHoldingRegister, mcaReadWrite);
end;

function TAIModbusCommandMap.IsValidFunctionCode(ACode: Integer): Boolean;
var
  Cmd: TAIModbusCommandItem;
begin
  Cmd := FCommands.FindByCode(ACode);
  if Cmd <> nil then
  begin
    Result := Cmd.Enabled;
  end
  else
  begin
    if FAllowCustomCommands then
    begin
      if FStrictValidation then
        Result := IsUserDefinedFunctionCode(ACode)
      else
        Result := True;
    end
    else
      Result := False;
  end;
end;

function TAIModbusCommandMap.IsUserDefinedFunctionCode(ACode: Integer): Boolean;
begin
  Result := ((ACode >= 65) and (ACode <= 72)) or
            ((ACode >= 100) and (ACode <= 110));
end;

function TAIModbusCommandMap.AddCustomCommand(ACode: Integer; const AShortName, AName: string): TAIModbusCommandItem;
begin
  Result := nil;
  if FStrictValidation and not IsUserDefinedFunctionCode(ACode) then
    Exit;
  
  Result := FCommands.Add;
  Result.Code := ACode;
  Result.ShortName := AShortName;
  Result.Name := AName;
  Result.Kind := mckCustom;
  Result.DataArea := mcdaCustom;
  Result.Access := mcaReadWrite;
  Result.Enabled := True;
  Result.IsValidForArduinoPinMap := False;
end;

function TAIModbusCommandMap.ToJSON: string;
var
  I: Integer;
  Cmd: TAIModbusCommandItem;
begin
  Result := '[';
  for I := 0 to FCommands.Count - 1 do
  begin
    Cmd := FCommands[I];
    if I > 0 then Result := Result + ',';
    Result := Result + Format(
      '{"code": %d, "short_name": "%s", "name": "%s", "kind": "%s", "access": "%s", "data_area": "%s", "enabled": %s}',
      [Cmd.Code, Cmd.ShortName, Cmd.Name, 
       IfThen(Cmd.Kind = mckStandard, 'standard', 'custom'),
       IfThen(Cmd.Access = mcaRead, 'read', IfThen(Cmd.Access = mcaWrite, 'write', 'readwrite')),
       IfThen(Cmd.DataArea = mcdaCoil, 'coil', IfThen(Cmd.DataArea = mcdaDiscreteInput, 'discrete_input', IfThen(Cmd.DataArea = mcdaHoldingRegister, 'holding_register', IfThen(Cmd.DataArea = mcdaInputRegister, 'input_register', 'custom')))),
       IfThen(Cmd.Enabled, 'true', 'false')]
    );
  end;
  Result := Result + ']';
end;

function TAIModbusCommandMap.ToSetupPrompt: string;
var
  I: Integer;
  Cmd: TAIModbusCommandItem;
begin
  Result := 'Modbus Commands Registered:' + LineEnding;
  for I := 0 to FCommands.Count - 1 do
  begin
    Cmd := FCommands[I];
    if Cmd.Enabled then
    begin
      Result := Result + Format('  - Code %d: %s (%s, Access: %s)' + LineEnding, 
        [Cmd.Code, Cmd.Name, Cmd.ShortName, IfThen(Cmd.Access = mcaRead, 'Read', IfThen(Cmd.Access = mcaWrite, 'Write', 'Read/Write'))]);
    end;
  end;
end;

end.
