unit ailistserialdevices;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Registry, aibase
  {$IFDEF MSWINDOWS}
  , Windows
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
  published
    property DeviceName: string read FDeviceName write FDeviceName;
    property DisplayName: string read FDisplayName write FDisplayName;
    property Description: string read FDescription write FDescription;
    property PortKind: TSerialPortKind read FPortKind write FPortKind default spkUnknown;
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
    
    FOnBeforeRefresh: TNotifyEvent;
    FOnAfterRefresh: TNotifyEvent;
    FOnDeviceFound: TSerialDeviceFoundEvent;
    FOnError: TSerialDeviceErrorEvent;

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
    procedure GetDeviceNames(AList: TStrings);
    function Count: Integer;
    function HasDevices: Boolean;
    function FindByDeviceName(const ADeviceName: string): TAIListSerialDeviceItem;
  published
    property Devices: TAIListSerialDeviceItems read FDevices write FDevices;
    property AutoRefresh: Boolean read FAutoRefresh write FAutoRefresh default False;
    property ProbeOpenable: Boolean read FProbeOpenable write FProbeOpenable default True;
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
  FProbeOpenable := True;
  FOnlyAvailable := True;
  FIncludeSystemPorts := True;
  FIncludeUSBSerial := True;
  FIncludeBluetooth := True;
end;

destructor TAIListSerialDevices.Destroy;
begin
  FDevices.Free;
  inherited Destroy;
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

procedure TAIListSerialDevices.GetDeviceNames(AList: TStrings);
var
  I: Integer;
begin
  if AList = nil then Exit;
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
  
  if not FProbeOpenable and not FOnlyAvailable then Exit;

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
  // Linux test check (try to open serial node)
  // In Linux, we can try to check if the file descriptor is openable.
  // Note: we only do it if the user enabled it, as it may reset some Arduino boards.
  {$ENDIF}
end;

procedure TAIListSerialDevices.QueryWindowsSerialPorts;
var
  Reg: TRegistry;
  ValueList: TStringList;
  I: Integer;
  DeviceName, PortValue: string;
  Item: TAIListSerialDeviceItem;
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
          Item := FDevices.Add;
          Item.DeviceName := PortValue;
          Item.Description := DeviceName;
          
          if Pos('USBSER', UpperCase(DeviceName)) > 0 then
          begin
            Item.PortKind := spkUSBSerial;
            Item.DisplayName := 'USB Serial Device (' + PortValue + ')';
          end
          else if Pos('BTHNUM', UpperCase(DeviceName)) > 0 then
          begin
            Item.PortKind := spkBluetooth;
            Item.DisplayName := 'Bluetooth Link (' + PortValue + ')';
          end
          else
          begin
            Item.PortKind := spkSystem;
            Item.DisplayName := 'Serial Port (' + PortValue + ')';
          end;
          
          ProbePort(Item);
          DoDeviceFound(Item);
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
    if FindFirst(APath, faAnyFile, SR) = 0 then
    begin
      repeat
        if (SR.Attr and faDirectory) = 0 then
        begin
          Item := FDevices.Add;
          Item.DeviceName := APrefix + SR.Name;
          Item.DisplayName := SR.Name;
          Item.PortKind := AKind;
          Item.Description := 'Linux serial device node';
          ProbePort(Item);
          DoDeviceFound(Item);
        end;
      until FindNext(SR) <> 0;
      SysUtils.FindClose(SR);
    end;
  end;

begin
  // USB serials (ex: /dev/ttyUSB0)
  if FIncludeUSBSerial then
  begin
    AddPath('/dev/ttyUSB*', '/dev/', spkUSBSerial);
    AddPath('/dev/ttyACM*', '/dev/', spkUSBSerial);
  end;
  
  // Standard/System ports
  if FIncludeSystemPorts then
  begin
    AddPath('/dev/ttyS*', '/dev/', spkSystem);
  end;
end;

procedure TAIListSerialDevices.Refresh;
begin
  if Assigned(FOnBeforeRefresh) then
    FOnBeforeRefresh(Self);

  Clear;

  {$IFDEF MSWINDOWS}
  QueryWindowsSerialPorts;
  {$ELSE}
  QueryLinuxSerialPorts;
  {$ENDIF}

  if Assigned(FOnAfterRefresh) then
    FOnAfterRefresh(Self);
end;

end.
