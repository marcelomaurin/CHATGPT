unit ailistserialdevices;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, ExtCtrls, aibase
  {$IFDEF MSWINDOWS}
  , Registry, Windows
  {$ENDIF}
  {$IFDEF UNIX}
  , BaseUnix
  {$ENDIF}
  ;

type
  TSerialPortKind = (
    spkUnknown,
    spkSystem,
    spkUSBSerial,
    spkBluetooth,
    spkVirtual,
    spkArduinoCompatible
  );

  { TAIListSerialDeviceItem }

  TAIListSerialDeviceItem = class(TCollectionItem)
  private
    FDeviceName: string;
    FDisplayName: string;
    FDescription: string;
    FPortKind: TSerialPortKind;
    FIsAvailable: Boolean;
    FIsOpenable: Boolean;
    FLastError: string;
  public
    constructor Create(ACollection: TCollection); override;
  published
    property DeviceName: string read FDeviceName write FDeviceName;
    property DisplayName: string read FDisplayName write FDisplayName;
    property Description: string read FDescription write FDescription;
    property PortKind: TSerialPortKind read FPortKind write FPortKind default spkUnknown;
    property Kind: TSerialPortKind read FPortKind write FPortKind default spkUnknown;
    property IsAvailable: Boolean read FIsAvailable write FIsAvailable default True;
    property IsOpenable: Boolean read FIsOpenable write FIsOpenable default True;
    property LastError: string read FLastError write FLastError;
  end;

  { TAIListSerialDeviceItems }

  TAIListSerialDeviceItems = class(TOwnedCollection)
  private
    function GetItem(Index: Integer): TAIListSerialDeviceItem;
    procedure SetItem(Index: Integer; AValue: TAIListSerialDeviceItem);
  public
    constructor Create(AOwner: TPersistent);
    function Add: TAIListSerialDeviceItem;
    property Items[Index: Integer]: TAIListSerialDeviceItem read GetItem write SetItem; default;
  end;

  TSerialDeviceFoundEvent = procedure(Sender: TObject; Device: TAIListSerialDeviceItem) of object;
  TSerialDeviceErrorEvent = procedure(Sender: TObject; const AMessage: string) of object;

  { TAIListSerialDevices }

  TAIListSerialDevices = class(TAIBaseComponent)
  private
    FDevices: TAIListSerialDeviceItems;
    FAutoRefresh: Boolean;
    FProbeOpenable: Boolean;
    FOnlyAvailable: Boolean;
    FIncludeSystemPorts: Boolean;
    FIncludeUSBSerial: Boolean;
    FIncludeBluetooth: Boolean;
    FAutoRefreshIntervalMs: Integer;
    FRefreshTimer: TTimer;
    
    FOnBeforeRefresh: TNotifyEvent;
    FOnAfterRefresh: TNotifyEvent;
    FOnDeviceFound: TSerialDeviceFoundEvent;
    FOnError: TSerialDeviceErrorEvent;

    procedure SetAutoRefresh(AValue: Boolean);
    procedure SetAutoRefreshIntervalMs(AValue: Integer);
    procedure DoAutoRefreshTimer(Sender: TObject);
    function ShouldInclude(AKind: TSerialPortKind): Boolean;
    procedure DoDeviceFound(Device: TAIListSerialDeviceItem);
    procedure DoError(const AMsg: string);
    procedure QueryWindowsSerialPorts;
    procedure QueryLinuxSerialPorts;
    procedure ProbePort(Device: TAIListSerialDeviceItem);
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    procedure Refresh;
    procedure Clear;
    procedure GetDeviceNames(AList: TStrings; AClearList: Boolean = True);
    function Count: Integer;
    function HasDevices: Boolean;
    function FindByDeviceName(const ADeviceName: string): TAIListSerialDeviceItem;
  published
    property Devices: TAIListSerialDeviceItems read FDevices write FDevices;
    property AutoRefresh: Boolean read FAutoRefresh write SetAutoRefresh default False;
    property AutoRefreshIntervalMs: Integer read FAutoRefreshIntervalMs write SetAutoRefreshIntervalMs default 3000;
    // When True, the component may open the serial port to check if it is usable.
    // Warning: opening Arduino Nano/Uno serial ports may toggle DTR and reset the board.
    property ProbeOpenable: Boolean read FProbeOpenable write FProbeOpenable default False;
    property OnlyAvailable: Boolean read FOnlyAvailable write FOnlyAvailable default True;
    property IncludeSystemPorts: Boolean read FIncludeSystemPorts write FIncludeSystemPorts default True;
    property IncludeUSBSerial: Boolean read FIncludeUSBSerial write FIncludeUSBSerial default True;
    property IncludeBluetooth: Boolean read FIncludeBluetooth write FIncludeBluetooth default True;

    // Events
    property OnBeforeRefresh: TNotifyEvent read FOnBeforeRefresh write FOnBeforeRefresh;
    property OnAfterRefresh: TNotifyEvent read FOnAfterRefresh write FOnAfterRefresh;
    property OnDeviceFound: TSerialDeviceFoundEvent read FOnDeviceFound write FOnDeviceFound;
    property OnError: TSerialDeviceErrorEvent read FOnError write FOnError;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('AI Communication', [TAIListSerialDevices]);
end;

{ TAIListSerialDeviceItem }

constructor TAIListSerialDeviceItem.Create(ACollection: TCollection);
begin
  inherited Create(ACollection);
  FIsAvailable := True;
  FIsOpenable := True;
  FLastError := '';
end;

{ TAIListSerialDeviceItems }

constructor TAIListSerialDeviceItems.Create(AOwner: TPersistent);
begin
  inherited Create(AOwner, TAIListSerialDeviceItem);
end;

function TAIListSerialDeviceItems.GetItem(Index: Integer): TAIListSerialDeviceItem;
begin
  Result := TAIListSerialDeviceItem(inherited GetItem(Index));
end;

procedure TAIListSerialDeviceItems.SetItem(Index: Integer; AValue: TAIListSerialDeviceItem);
begin
  inherited SetItem(Index, AValue);
end;

function TAIListSerialDeviceItems.Add: TAIListSerialDeviceItem;
begin
  Result := TAIListSerialDeviceItem(inherited Add);
end;

{ TAIListSerialDevices }

constructor TAIListSerialDevices.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FPrompt := 'Component TAIListSerialDevices queries and aggregates available serial hardware interfaces (COM/tty) on Windows and Linux/macOS. Methods: Refresh, GetDeviceNames(AList: TStrings).';
  FDevices := TAIListSerialDeviceItems.Create(Self);
  FAutoRefresh := False;
  FProbeOpenable := False; // Default False to prevent Arduino reset
  FOnlyAvailable := True;
  FIncludeSystemPorts := True;
  FIncludeUSBSerial := True;
  FIncludeBluetooth := True;
  FAutoRefreshIntervalMs := 3000;
  
  FRefreshTimer := TTimer.Create(Self);
  FRefreshTimer.Enabled := False;
  FRefreshTimer.Interval := FAutoRefreshIntervalMs;
  FRefreshTimer.OnTimer := @DoAutoRefreshTimer;
end;

destructor TAIListSerialDevices.Destroy;
begin
  if FRefreshTimer <> nil then
  begin
    FRefreshTimer.Enabled := False;
    FRefreshTimer.Free;
    FRefreshTimer := nil;
  end;
  FDevices.Free;
  inherited Destroy;
end;

procedure TAIListSerialDevices.SetAutoRefresh(AValue: Boolean);
begin
  if FAutoRefresh = AValue then Exit;
  FAutoRefresh := AValue;
  if FRefreshTimer <> nil then
  begin
    if not (csDesigning in ComponentState) then
      FRefreshTimer.Enabled := FAutoRefresh
    else
      FRefreshTimer.Enabled := False;
  end;
end;

procedure TAIListSerialDevices.SetAutoRefreshIntervalMs(AValue: Integer);
begin
  if FAutoRefreshIntervalMs = AValue then Exit;
  FAutoRefreshIntervalMs := AValue;
  if FRefreshTimer <> nil then
    FRefreshTimer.Interval := FAutoRefreshIntervalMs;
end;

procedure TAIListSerialDevices.DoAutoRefreshTimer(Sender: TObject);
begin
  if not (csDesigning in ComponentState) then
    Refresh;
end;

function TAIListSerialDevices.ShouldInclude(AKind: TSerialPortKind): Boolean;
begin
  case AKind of
    spkUSBSerial:
      Result := FIncludeUSBSerial;
    spkSystem:
      Result := FIncludeSystemPorts;
    spkBluetooth:
      Result := FIncludeBluetooth;
  else
    Result := True;
  end;
end;

procedure TAIListSerialDevices.DoDeviceFound(Device: TAIListSerialDeviceItem);
begin
  if Assigned(FOnDeviceFound) then
    FOnDeviceFound(Self, Device);
end;

procedure TAIListSerialDevices.DoError(const AMsg: string);
begin
  SetError(AMsg);
  if Assigned(FOnError) then
    FOnError(Self, AMsg);
end;

procedure TAIListSerialDevices.Clear;
begin
  FDevices.Clear;
end;

function TAIListSerialDevices.Count: Integer;
begin
  Result := FDevices.Count;
end;

function TAIListSerialDevices.HasDevices: Boolean;
begin
  Result := FDevices.Count > 0;
end;

function TAIListSerialDevices.FindByDeviceName(const ADeviceName: string): TAIListSerialDeviceItem;
var
  I: Integer;
begin
  Result := nil;
  for I := 0 to FDevices.Count - 1 do
  begin
    if SameText(FDevices[I].DeviceName, ADeviceName) then
    begin
      Result := FDevices[I];
      Exit;
    end;
  end;
end;

procedure TAIListSerialDevices.GetDeviceNames(AList: TStrings; AClearList: Boolean = True);
var
  I: Integer;
begin
  if AList = nil then Exit;
  if AClearList then
    AList.Clear;
  for I := 0 to FDevices.Count - 1 do
  begin
    if not FOnlyAvailable or (FDevices[I].IsOpenable and FDevices[I].IsAvailable) then
      AList.Add(FDevices[I].DeviceName);
  end;
end;

procedure TAIListSerialDevices.ProbePort(Device: TAIListSerialDeviceItem);
{$IFDEF MSWINDOWS}
var
  HPort: THandle;
  PortStr: string;
{$ENDIF}
begin
  Device.IsOpenable := True;
  Device.LastError := '';
  
  if not FProbeOpenable then Exit;

  {$IFDEF MSWINDOWS}
  PortStr := '\\.\' + Device.DeviceName;
  HPort := CreateFile(PChar(PortStr), GENERIC_READ or GENERIC_WRITE, 0, nil, OPEN_EXISTING, 0, 0);
  if HPort = INVALID_HANDLE_VALUE then
  begin
    Device.IsOpenable := False;
    Device.LastError := 'Port busy or access denied';
  end
  else
    CloseHandle(HPort);
  {$ELSE}
  // Unix/Linux/macOS serial checking can be added if needed, or left empty
  {$ENDIF}
end;

procedure TAIListSerialDevices.QueryWindowsSerialPorts;
var
  Reg: TRegistry;
  ValueList: TStringList;
  I: Integer;
  DeviceName, PortValue: string;
  Item: TAIListSerialDeviceItem;
  Kind: TSerialPortKind;
  DevUpper: string;
begin
  Reg := TRegistry.Create(KEY_READ);
  ValueList := TStringList.Create;
  try
    Reg.RootKey := HKEY_LOCAL_MACHINE;
    if Reg.OpenKeyReadOnly('HARDWARE\DEVICEMAP\SERIALCOMM') then
    begin
      Reg.GetValueNames(ValueList);
      for I := 0 to ValueList.Count - 1 do
      begin
        DeviceName := ValueList[I];
        PortValue := Reg.ReadString(DeviceName);
        if PortValue <> '' then
        begin
          DevUpper := UpperCase(DeviceName);
          if (Pos('USBSER', DevUpper) > 0) or (Pos('VCP', DevUpper) > 0) or
             (Pos('SILABSER', DevUpper) > 0) or (Pos('CH34', DevUpper) > 0) or
             (Pos('PROLIFIC', DevUpper) > 0) then
            Kind := spkUSBSerial
          else if (Pos('BTHNUM', DevUpper) > 0) or (Pos('BTHMODEM', DevUpper) > 0) then
            Kind := spkBluetooth
          else
            Kind := spkSystem;

          if ShouldInclude(Kind) then
          begin
            Item := FDevices.Add;
            Item.DeviceName := PortValue;
            Item.Description := DeviceName;
            Item.PortKind := Kind;
            
            case Kind of
              spkUSBSerial: Item.DisplayName := 'USB Serial Device (' + PortValue + ')';
              spkBluetooth: Item.DisplayName := 'Bluetooth Link (' + PortValue + ')';
            else
              Item.DisplayName := 'Serial Port (' + PortValue + ')';
            end;
            
            ProbePort(Item);
            DoDeviceFound(Item);
          end;
        end;
      end;
    end;
  except
    on E: Exception do
      DoError('Windows Registry Query Error: ' + E.Message);
  end;
  ValueList.Free;
  Reg.Free;
end;

procedure TAIListSerialDevices.QueryLinuxSerialPorts;
var
  SR: TSearchRec;
  Item: TAIListSerialDeviceItem;
  
  procedure AddPath(const APath, APrefix: string; AKind: TSerialPortKind);
  begin
    if not ShouldInclude(AKind) then Exit;
    if FindFirst(APath, faAnyFile, SR) = 0 then
    begin
      repeat
        if (SR.Attr and faDirectory) = 0 then
        begin
          Item := FDevices.Add;
          Item.DeviceName := APrefix + SR.Name;
          Item.DisplayName := SR.Name;
          Item.PortKind := AKind;
          Item.Description := 'Unix serial device node';
          ProbePort(Item);
          DoDeviceFound(Item);
        end;
      until FindNext(SR) <> 0;
      SysUtils.FindClose(SR);
    end;
  end;

begin
  {$IFDEF DARWIN}
  // macOS / Darwin ports
  AddPath('/dev/cu.usbserial*', '/dev/', spkUSBSerial);
  AddPath('/dev/cu.usbmodem*', '/dev/', spkUSBSerial);
  AddPath('/dev/tty.usbserial*', '/dev/', spkUSBSerial);
  AddPath('/dev/tty.usbmodem*', '/dev/', spkUSBSerial);
  {$ELSE}
  // Linux USB serials
  AddPath('/dev/ttyUSB*', '/dev/', spkUSBSerial);
  AddPath('/dev/ttyACM*', '/dev/', spkUSBSerial);
  
  // Linux Standard/System ports
  AddPath('/dev/ttyS*', '/dev/', spkSystem);
  {$ENDIF}
end;

procedure TAIListSerialDevices.Refresh;
begin
  ClearError;
  if Assigned(FOnBeforeRefresh) then
    FOnBeforeRefresh(Self);

  try
    Clear;

    {$IFDEF MSWINDOWS}
    QueryWindowsSerialPorts;
    {$ELSE}
    QueryLinuxSerialPorts;
    {$ENDIF}
  except
    on E: Exception do
    begin
      SetError(E.Message);
      DoError('Refresh Error: ' + E.Message);
    end;
  end;

  if Assigned(FOnAfterRefresh) then
    FOnAfterRefresh(Self);
end;

end.
