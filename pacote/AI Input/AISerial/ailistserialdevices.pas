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
    property Kind: TSerialPortKind read FPortKind write FPortKind;
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
  TSerialDeviceRemovedEvent = procedure(Sender: TObject; const ADeviceName: string) of object;
  TSerialDeviceErrorEvent = procedure(Sender: TObject; const AMessage: string) of object;

  // Temporary helper structure for detected ports
  TDetectedDevice = record
    DeviceName: string;
    DisplayName: string;
    Description: string;
    PortKind: TSerialPortKind;
    IsAvailable: Boolean;
  end;
  TDetectedDeviceArray = array of TDetectedDevice;

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
    FIncludeTTYVariants: Boolean;
    FAutoRefreshIntervalMs: Integer;
    FRefreshTimer: TTimer;
    
    FOnBeforeRefresh: TNotifyEvent;
    FOnAfterRefresh: TNotifyEvent;
    FOnDeviceFound: TSerialDeviceFoundEvent;
    FOnDeviceRemoved: TSerialDeviceRemovedEvent;
    FOnError: TSerialDeviceErrorEvent;

    procedure SetDevices(AValue: TAIListSerialDeviceItems);
    procedure SetAutoRefresh(AValue: Boolean);
    procedure SetAutoRefreshIntervalMs(AValue: Integer);
    procedure DoAutoRefreshTimer(Sender: TObject);
    function ShouldInclude(AKind: TSerialPortKind): Boolean;
    procedure DoDeviceFound(Device: TAIListSerialDeviceItem);
    procedure DoDeviceRemoved(const ADeviceName: string);
    procedure DoError(const AMsg: string);
    procedure QueryWindowsSerialPorts(var ADetected: TDetectedDeviceArray);
    procedure QueryLinuxSerialPorts(var ADetected: TDetectedDeviceArray);
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
    property Devices: TAIListSerialDeviceItems read FDevices write SetDevices;
    property AutoRefresh: Boolean read FAutoRefresh write SetAutoRefresh default False;
    property AutoRefreshIntervalMs: Integer read FAutoRefreshIntervalMs write SetAutoRefreshIntervalMs default 3000;
    // When True, the component may open the serial port to check if it is usable.
    // Warning: opening Arduino Nano/Uno serial ports may toggle DTR and reset the board.
    property ProbeOpenable: Boolean read FProbeOpenable write FProbeOpenable default False;
    property OnlyAvailable: Boolean read FOnlyAvailable write FOnlyAvailable default True;
    property IncludeSystemPorts: Boolean read FIncludeSystemPorts write FIncludeSystemPorts default True;
    property IncludeUSBSerial: Boolean read FIncludeUSBSerial write FIncludeUSBSerial default True;
    property IncludeBluetooth: Boolean read FIncludeBluetooth write FIncludeBluetooth default True;
    property IncludeTTYVariants: Boolean read FIncludeTTYVariants write FIncludeTTYVariants default False;

    // Events
    property OnBeforeRefresh: TNotifyEvent read FOnBeforeRefresh write FOnBeforeRefresh;
    property OnAfterRefresh: TNotifyEvent read FOnAfterRefresh write FOnAfterRefresh;
    property OnDeviceFound: TSerialDeviceFoundEvent read FOnDeviceFound write FOnDeviceFound;
    property OnDeviceRemoved: TSerialDeviceRemovedEvent read FOnDeviceRemoved write FOnDeviceRemoved;
    property OnError: TSerialDeviceErrorEvent read FOnError write FOnError;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('AI Communication', [TAIListSerialDevices]);
end;

// Natural Sort Comparison Helper
function NaturalCompare(const Str1, Str2: string): Integer;
var
  Len1, Len2, I1, I2: Integer;
  Ch1, Ch2: Char;
  Num1, Num2: Int64;
begin
  Len1 := Length(Str1);
  Len2 := Length(Str2);
  I1 := 1;
  I2 := 1;
  Result := 0;
  while (I1 <= Len1) and (I2 <= Len2) do
  begin
    Ch1 := Str1[I1];
    Ch2 := Str2[I2];
    if (Ch1 in ['0'..'9']) and (Ch2 in ['0'..'9']) then
    begin
      Num1 := 0;
      while (I1 <= Len1) and (Str1[I1] in ['0'..'9']) do
      begin
        Num1 := Num1 * 10 + (Ord(Str1[I1]) - Ord('0'));
        Inc(I1);
      end;
      Num2 := 0;
      while (I2 <= Len2) and (Str2[I2] in ['0'..'9']) do
      begin
        Num2 := Num2 * 10 + (Ord(Str2[I2]) - Ord('0'));
        Inc(I2);
      end;
      if Num1 < Num2 then
      begin
        Result := -1;
        Exit;
      end
      else if Num1 > Num2 then
      begin
        Result := 1;
        Exit;
      end;
    end
    else
    begin
      if UpCase(Ch1) <> UpCase(Ch2) then
      begin
        if UpCase(Ch1) < UpCase(Ch2) then Result := -1 else Result := 1;
        Exit;
      end;
      Inc(I1);
      Inc(I2);
    end;
  end;
  if Result = 0 then
  begin
    if Len1 < Len2 then Result := -1
    else if Len1 > Len2 then Result := 1;
  end;
end;

procedure SortAndDeduplicate(var ADevices: TDetectedDeviceArray);
var
  I, J: Integer;
  Temp: TDetectedDevice;
  UniqueCount: Integer;
begin
  // Sort
  for I := 0 to Length(ADevices) - 2 do
  begin
    for J := I + 1 to Length(ADevices) - 1 do
    begin
      if NaturalCompare(ADevices[I].DeviceName, ADevices[J].DeviceName) > 0 then
      begin
        Temp := ADevices[I];
        ADevices[I] := ADevices[J];
        ADevices[J] := Temp;
      end;
    end;
  end;

  // Deduplicate
  if Length(ADevices) > 1 then
  begin
    UniqueCount := 1;
    for I := 1 to Length(ADevices) - 1 do
    begin
      if not SameText(ADevices[I].DeviceName, ADevices[UniqueCount - 1].DeviceName) then
      begin
        ADevices[UniqueCount] := ADevices[I];
        Inc(UniqueCount);
      end;
    end;
    SetLength(ADevices, UniqueCount);
  end;
end;

{$IFDEF UNIX}
function ResolveSymlink(const APath: string): string;
var
  Buffer: array[0..1023] of Char;
  Len: Integer;
begin
  Result := '';
  Len := fpReadlink(APath, @Buffer[0], SizeOf(Buffer) - 1);
  if Len > 0 then
  begin
    Buffer[Len] := #0;
    Result := StrPas(Buffer);
  end;
end;
{$ENDIF}

{$IFDEF MSWINDOWS}
const
  GUID_DEVINTERFACE_COMPORT: TGUID = '{86e0d1e0-8089-11d0-9ce4-08002b114960}';
  DIGCF_PRESENT = $00000002;
  DIGCF_DEVICEINTERFACE = $00000010;
  SPDRP_FRIENDLYNAME = $0000000C;
  SPDRP_HARDWAREID = $00000001;

type
  SP_DEVINFO_DATA = record
    cbSize: DWORD;
    ClassGuid: TGUID;
    DevInst: DWORD;
    Reserved: ULONG_PTR;
  end;
  PSP_DEVINFO_DATA = ^SP_DEVINFO_DATA;

  SP_DEVICE_INTERFACE_DATA = record
    cbSize: DWORD;
    InterfaceClassGuid: TGUID;
    Flags: DWORD;
    Reserved: ULONG_PTR;
  end;
  PSP_DEVICE_INTERFACE_DATA = ^SP_DEVICE_INTERFACE_DATA;

  SP_DEVICE_INTERFACE_DETAIL_DATA_W = record
    cbSize: DWORD;
    DevicePath: array[0..0] of WideChar;
  end;
  PSP_DEVICE_INTERFACE_DETAIL_DATA_W = ^SP_DEVICE_INTERFACE_DETAIL_DATA_W;

  TSetupDiGetClassDevsW = function(ClassGuid: PGUID; Enumerator: PWideChar; hwndParent: HWND; Flags: DWORD): THandle; stdcall;
  TSetupDiEnumDeviceInterfaces = function(DeviceInfoSet: THandle; DeviceInfoData: PSP_DEVINFO_DATA; const InterfaceClassGuid: TGUID; MemberIndex: DWORD; DeviceInterfaceData: PSP_DEVICE_INTERFACE_DATA): BOOL; stdcall;
  TSetupDiGetDeviceInterfaceDetailW = function(DeviceInfoSet: THandle; DeviceInterfaceData: PSP_DEVICE_INTERFACE_DATA; DeviceInterfaceDetailData: PSP_DEVICE_INTERFACE_DETAIL_DATA_W; DeviceInterfaceDetailDataSize: DWORD; RequiredSize: PDWORD; DeviceInfoData: PSP_DEVINFO_DATA): BOOL; stdcall;
  TSetupDiGetDeviceRegistryPropertyW = function(DeviceInfoSet: THandle; DeviceInfoData: PSP_DEVINFO_DATA; Property_: DWORD; PropertyRegDataType: PDWORD; PropertyBuffer: PByte; PropertyBufferSize: DWORD; RequiredSize: PDWORD): BOOL; stdcall;
  TSetupDiDestroyDeviceInfoList = function(DeviceInfoSet: THandle): BOOL; stdcall;
  TSetupDiOpenDevRegKey = function(DeviceInfoSet: THandle; DeviceInfoData: PSP_DEVINFO_DATA; Scope, HwProfile, KeyType: DWORD; samDesired: REGSAM): HKEY; stdcall;

var
  SetupAPILib: THandle = 0;
  SetupDiGetClassDevsW: TSetupDiGetClassDevsW = nil;
  SetupDiEnumDeviceInterfaces: TSetupDiEnumDeviceInterfaces = nil;
  SetupDiGetDeviceInterfaceDetailW: TSetupDiGetDeviceInterfaceDetailW = nil;
  SetupDiGetDeviceRegistryPropertyW: TSetupDiGetDeviceRegistryPropertyW = nil;
  SetupDiDestroyDeviceInfoList: TSetupDiDestroyDeviceInfoList = nil;
  SetupDiOpenDevRegKey: TSetupDiOpenDevRegKey = nil;

function LoadSetupAPI: Boolean;
begin
  if SetupAPILib <> 0 then Exit(True);
  SetupAPILib := LoadLibrary('setupapi.dll');
  if SetupAPILib <> 0 then
  begin
    SetupDiGetClassDevsW := TSetupDiGetClassDevsW(GetProcAddress(SetupAPILib, 'SetupDiGetClassDevsW'));
    SetupDiEnumDeviceInterfaces := TSetupDiEnumDeviceInterfaces(GetProcAddress(SetupAPILib, 'SetupDiEnumDeviceInterfaces'));
    SetupDiGetDeviceInterfaceDetailW := TSetupDiGetDeviceInterfaceDetailW(GetProcAddress(SetupAPILib, 'SetupDiGetDeviceInterfaceDetailW'));
    SetupDiGetDeviceRegistryPropertyW := TSetupDiGetDeviceRegistryPropertyW(GetProcAddress(SetupAPILib, 'SetupDiGetDeviceRegistryPropertyW'));
    SetupDiDestroyDeviceInfoList := TSetupDiDestroyDeviceInfoList(GetProcAddress(SetupAPILib, 'SetupDiDestroyDeviceInfoList'));
    SetupDiOpenDevRegKey := TSetupDiOpenDevRegKey(GetProcAddress(SetupAPILib, 'SetupDiOpenDevRegKey'));
  end;
  Result := (SetupDiGetClassDevsW <> nil) and 
            (SetupDiEnumDeviceInterfaces <> nil) and 
            (SetupDiGetDeviceInterfaceDetailW <> nil) and 
            (SetupDiGetDeviceRegistryPropertyW <> nil) and 
            (SetupDiDestroyDeviceInfoList <> nil) and
            (SetupDiOpenDevRegKey <> nil);
end;

procedure QueryWindowsSetupAPI(var ADetected: TDetectedDeviceArray);
var
  DevInfo: THandle;
  DevInfoData: SP_DEVINFO_DATA;
  InterfaceData: SP_DEVICE_INTERFACE_DATA;
  DetailData: PSP_DEVICE_INTERFACE_DETAIL_DATA_W;
  MemberIndex: DWORD;
  ReqSize: DWORD;
  FriendlyName: array[0..511] of WideChar;
  HardwareID: array[0..1023] of WideChar;
  PortName: array[0..255] of WideChar;
  RegKey: HKEY;
  ValType: DWORD;
  ValSize: DWORD;
  FriendlyStr, HardwareIDStr, PortStr: string;
  PStart, PEnd: Integer;
  Kind: TSerialPortKind;
  Item: TDetectedDevice;
begin
  if not LoadSetupAPI then Exit;

  DevInfo := SetupDiGetClassDevsW(@GUID_DEVINTERFACE_COMPORT, nil, 0, DIGCF_PRESENT or DIGCF_DEVICEINTERFACE);
  if DevInfo = THandle(INVALID_HANDLE_VALUE) then Exit;

  try
    MemberIndex := 0;
    InterfaceData.cbSize := SizeOf(SP_DEVICE_INTERFACE_DATA);
    while SetupDiEnumDeviceInterfaces(DevInfo, nil, GUID_DEVINTERFACE_COMPORT, MemberIndex, @InterfaceData) do
    begin
      DevInfoData.cbSize := SizeOf(SP_DEVINFO_DATA);
      ReqSize := 0;
      SetupDiGetDeviceInterfaceDetailW(DevInfo, @InterfaceData, nil, 0, @ReqSize, @DevInfoData);
      if ReqSize > 0 then
      begin
        DetailData := GetMem(ReqSize);
        try
          DetailData^.cbSize := SizeOf(SP_DEVICE_INTERFACE_DETAIL_DATA_W);
          if SetupDiGetDeviceInterfaceDetailW(DevInfo, @InterfaceData, DetailData, ReqSize, @ReqSize, @DevInfoData) then
          begin
            PortStr := '';
            RegKey := SetupDiOpenDevRegKey(DevInfo, @DevInfoData, 1 {DICS_FLAG_GLOBAL}, 0, 1 {DIREG_DEV}, KEY_READ);
            if RegKey <> HKEY(INVALID_HANDLE_VALUE) then
            begin
              ValSize := SizeOf(PortName);
              if RegQueryValueExW(RegKey, 'PortName', nil, @ValType, PByte(@PortName), @ValSize) = ERROR_SUCCESS then
              begin
                PortStr := PWideChar(@PortName);
              end;
              RegCloseKey(RegKey);
            end;

            FriendlyStr := '';
            if SetupDiGetDeviceRegistryPropertyW(DevInfo, @DevInfoData, SPDRP_FRIENDLYNAME, nil, PByte(@FriendlyName), SizeOf(FriendlyName), nil) then
            begin
              FriendlyStr := PWideChar(@FriendlyName);
            end;

            if PortStr = '' then
            begin
              PStart := Pos('(COM', FriendlyStr);
              if PStart > 0 then
              begin
                PEnd := Pos(')', FriendlyStr);
                if PEnd > PStart then
                begin
                  PortStr := Copy(FriendlyStr, PStart + 1, PEnd - PStart - 1);
                end;
              end;
            end;

            if PortStr <> '' then
            begin
              HardwareIDStr := '';
              if SetupDiGetDeviceRegistryPropertyW(DevInfo, @DevInfoData, SPDRP_HARDWAREID, nil, PByte(@HardwareID), SizeOf(HardwareID), nil) then
              begin
                HardwareIDStr := PWideChar(@HardwareID);
              end;

              Kind := spkSystem;
              HardwareIDStr := UpperCase(HardwareIDStr);
              
              if (Pos('USB', HardwareIDStr) > 0) or (Pos('FTDIBUS', HardwareIDStr) > 0) then
              begin
                if (Pos('VID_2341', HardwareIDStr) > 0) or (Pos('VID_2A03', HardwareIDStr) > 0) then
                  Kind := spkArduinoCompatible
                else
                  Kind := spkUSBSerial;
              end
              else if (Pos('BTHENUM', HardwareIDStr) > 0) or (Pos('BTHMODEM', HardwareIDStr) > 0) or (Pos('BLUETOOTH', HardwareIDStr) > 0) then
              begin
                Kind := spkBluetooth;
              end;

              Item.DeviceName := PortStr;
              if FriendlyStr <> '' then
                Item.DisplayName := FriendlyStr
              else
                Item.DisplayName := PortStr;
              Item.Description := HardwareIDStr;
              Item.PortKind := Kind;
              Item.IsAvailable := True;

              SetLength(ADetected, Length(ADetected) + 1);
              ADetected[Length(ADetected) - 1] := Item;
            end;
          end;
        finally
          FreeMem(DetailData);
        end;
      end;
      Inc(MemberIndex);
    end;
  finally
    SetupDiDestroyDeviceInfoList(DevInfo);
  end;
end;
{$ENDIF}

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
  FProbeOpenable := False;
  FOnlyAvailable := True;
  FIncludeSystemPorts := True;
  FIncludeUSBSerial := True;
  FIncludeBluetooth := True;
  FIncludeTTYVariants := False;
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

procedure TAIListSerialDevices.SetDevices(AValue: TAIListSerialDeviceItems);
begin
  FDevices.Assign(AValue);
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
  if AValue < 250 then AValue := 250;
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
    spkUSBSerial, spkArduinoCompatible:
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

procedure TAIListSerialDevices.DoDeviceRemoved(const ADeviceName: string);
begin
  if Assigned(FOnDeviceRemoved) then
    FOnDeviceRemoved(Self, ADeviceName);
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
  Err: DWORD;
{$ENDIF}
{$IFDEF UNIX}
var
  FD: Integer;
  Err: Integer;
{$ENDIF}
begin
  Device.IsOpenable := True;
  Device.IsAvailable := True;
  Device.LastError := '';
  
  if not FProbeOpenable then Exit;

  {$IFDEF MSWINDOWS}
  PortStr := '\\.\' + Device.DeviceName;
  HPort := CreateFile(PChar(PortStr), GENERIC_READ or GENERIC_WRITE, 0, nil, OPEN_EXISTING, 0, 0);
  if HPort = INVALID_HANDLE_VALUE then
  begin
    Err := GetLastError;
    Device.IsOpenable := False;
    case Err of
      ERROR_ACCESS_DENIED:
        Device.LastError := 'Port busy or access denied (in use)';
      ERROR_FILE_NOT_FOUND:
        begin
          Device.IsAvailable := False;
          Device.LastError := 'Port does not exist';
        end;
    else
      Device.LastError := SysErrorMessage(Err);
    end;
  end
  else
    CloseHandle(HPort);
  {$ENDIF}
  {$IFDEF UNIX}
  FD := FpOpen(Device.DeviceName, O_RDWR or O_NOCTTY or O_NONBLOCK);
  if FD < 0 then
  begin
    Err := fpGetErrno;
    Device.IsOpenable := False;
    case Err of
      ESysEBUSY:
        Device.LastError := 'Port busy (in use)';
      ESysEACCES:
        Device.LastError := 'Access denied (permission error - try adding user to dialout group)';
      ESysENOENT:
        begin
          Device.IsAvailable := False;
          Device.LastError := 'Device node does not exist';
        end;
    else
      Device.LastError := 'Error opening port: ' + IntToStr(Err) + ' - ' + SysErrorMessage(Err);
    end;
  end
  else
  begin
    FpClose(FD);
  end;
  {$ENDIF}
end;

procedure TAIListSerialDevices.QueryWindowsSerialPorts(var ADetected: TDetectedDeviceArray);
{$IFDEF MSWINDOWS}
var
  Reg: TRegistry;
  ValueList: TStringList;
  I: Integer;
  DeviceName, PortValue: string;
  DevUpper: string;
  Kind: TSerialPortKind;
  Item: TDetectedDevice;
{$ENDIF}
begin
  {$IFDEF MSWINDOWS}
  // Try SetupAPI first
  QueryWindowsSetupAPI(ADetected);
  if Length(ADetected) > 0 then Exit;

  // Fallback to Registry if SetupAPI did not return any ports
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
        try
          if Reg.GetDataType(DeviceName) = rdString then
          begin
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
                Item.DeviceName := PortValue;
                Item.Description := DeviceName;
                Item.PortKind := Kind;
                Item.IsAvailable := True;
                
                case Kind of
                  spkUSBSerial: Item.DisplayName := 'USB Serial Device (' + PortValue + ')';
                  spkBluetooth: Item.DisplayName := 'Bluetooth Link (' + PortValue + ')';
                else
                  Item.DisplayName := 'Serial Port (' + PortValue + ')';
                end;
                
                SetLength(ADetected, Length(ADetected) + 1);
                ADetected[Length(ADetected) - 1] := Item;
              end;
            end;
          end;
        except
          // Prevent registry read error on one device from aborting entire enumeration
        end;
      end;
    end;
  except
    on E: Exception do
      DoError('Windows Registry Query Error: ' + E.Message);
  end;
  ValueList.Free;
  Reg.Free;
  {$ENDIF}
end;

procedure TAIListSerialDevices.QueryLinuxSerialPorts(var ADetected: TDetectedDeviceArray);
var
  SR: TSearchRec;
  Item: TDetectedDevice;
  
  procedure AddPath(const APath, APrefix: string; AKind: TSerialPortKind);
  var
    KindVal: TSerialPortKind;
    IsAvailableVal: Boolean;
    DevNameLower: string;
  begin
    if FindFirst(APath, faAnyFile, SR) = 0 then
    begin
      repeat
        if (SR.Attr and faDirectory) = 0 then
        begin
          KindVal := AKind;
          {$IFDEF DARWIN}
          DevNameLower := LowerCase(SR.Name);
          if (Pos('usbserial', DevNameLower) > 0) or (Pos('usbmodem', DevNameLower) > 0) then
            KindVal := spkUSBSerial
          else if (Pos('bluetooth', DevNameLower) > 0) then
            KindVal := spkBluetooth
          else
            KindVal := spkUnknown;
          {$ENDIF}

          if ShouldInclude(KindVal) then
          begin
            IsAvailableVal := True;
            {$IFNDEF DARWIN}
            if (KindVal = spkSystem) and (Pos('ttyS', SR.Name) = 1) then
            begin
              if not DirectoryExists('/sys/class/tty/' + SR.Name + '/device') then
                IsAvailableVal := False;
            end;
            {$ENDIF}

            Item.DeviceName := APrefix + SR.Name;
            Item.DisplayName := SR.Name;
            Item.PortKind := KindVal;
            Item.Description := 'Unix serial device node';
            Item.IsAvailable := IsAvailableVal;

            SetLength(ADetected, Length(ADetected) + 1);
            ADetected[Length(ADetected) - 1] := Item;
          end;
        end;
      until FindNext(SR) <> 0;
      SysUtils.FindClose(SR);
    end;
  end;

{$IFDEF UNIX}
  procedure EnrichLinuxMetadata;
  var
    LinkSR: TSearchRec;
    LinkPath, ResolvedTarget, DevName: string;
    I: Integer;
    SysPath, VID, PID: string;
    
    function ReadSysfsValue(const APath: string): string;
    var
      F: TextFile;
    begin
      Result := '';
      if FileExists(APath) then
      begin
        try
          AssignFile(F, APath);
          Reset(F);
          if not Eof(F) then
            Readln(F, Result);
          CloseFile(F);
          Result := Trim(Result);
        except
          // ignore read errors
        end;
      end;
    end;
  begin
    if FindFirst('/dev/serial/by-id/*', faAnyFile, LinkSR) = 0 then
    begin
      repeat
        if (LinkSR.Attr and faDirectory) = 0 then
        begin
          LinkPath := '/dev/serial/by-id/' + LinkSR.Name;
          ResolvedTarget := ResolveSymlink(LinkPath);
          if ResolvedTarget <> '' then
          begin
            ResolvedTarget := ExpandFileName('/dev/serial/by-id/' + ResolvedTarget);
            DevName := ExtractFileName(ResolvedTarget);
            
            for I := 0 to Length(ADetected) - 1 do
            begin
              if SameText(ExtractFileName(ADetected[I].DeviceName), DevName) then
              begin
                ADetected[I].Description := LinkSR.Name;
                
                SysPath := '/sys/class/tty/' + DevName + '/device/';
                VID := ReadSysfsValue(SysPath + 'idVendor');
                if VID = '' then
                  VID := ReadSysfsValue(SysPath + '../idVendor');
                if VID = '' then
                  VID := ReadSysfsValue(SysPath + '../../idVendor');
                  
                PID := ReadSysfsValue(SysPath + 'idProduct');
                if PID = '' then
                  PID := ReadSysfsValue(SysPath + '../idProduct');
                if PID = '' then
                  PID := ReadSysfsValue(SysPath + '../../idProduct');
                  
                if (VID <> '') or (PID <> '') then
                begin
                  VID := LowerCase(VID);
                  PID := LowerCase(PID);
                  if (VID = '2341') or (VID = '2a03') then
                  begin
                    ADetected[I].PortKind := spkArduinoCompatible;
                    ADetected[I].DisplayName := 'Arduino Compatible (' + ExtractFileName(ADetected[I].DeviceName) + ')';
                  end
                  else if (VID = '1a86') or (VID = '10c4') or (VID = '0403') then
                  begin
                    ADetected[I].PortKind := spkUSBSerial;
                    ADetected[I].DisplayName := 'USB Serial Device (' + ExtractFileName(ADetected[I].DeviceName) + ')';
                  end;
                end;
                Break;
              end;
            end;
          end;
        end;
      until FindNext(LinkSR) <> 0;
      SysUtils.FindClose(LinkSR);
    end;
  end;
{$ENDIF}

begin
  {$IFDEF DARWIN}
  // macOS / Darwin ports
  AddPath('/dev/cu.*', '/dev/', spkUnknown);
  if FIncludeTTYVariants then
    AddPath('/dev/tty.*', '/dev/', spkUnknown);
  {$ELSE}
  // Linux USB serials
  AddPath('/dev/ttyUSB*', '/dev/', spkUSBSerial);
  AddPath('/dev/ttyACM*', '/dev/', spkUSBSerial);
  
  // Linux Standard/System ports
  AddPath('/dev/ttyS*', '/dev/', spkSystem);

  // Bluetooth
  if FIncludeBluetooth then
    AddPath('/dev/rfcomm*', '/dev/', spkBluetooth);

  // Linux SoC/Embedded UARTs
  AddPath('/dev/ttyAMA*', '/dev/', spkSystem);
  AddPath('/dev/ttyTHS*', '/dev/', spkSystem);

  {$IFDEF UNIX}
  EnrichLinuxMetadata;
  {$ENDIF}
  {$ENDIF}
end;

procedure TAIListSerialDevices.Refresh;
var
  Detected: TDetectedDeviceArray;
  I, J: Integer;
  Found: Boolean;
  NewItem: TAIListSerialDeviceItem;
  ActiveDevices: array of Boolean;
begin
  ClearError;
  if Assigned(FOnBeforeRefresh) then
    FOnBeforeRefresh(Self);

  try
    SetLength(Detected, 0);

    {$IFDEF MSWINDOWS}
    QueryWindowsSerialPorts(Detected);
    {$ELSE}
    QueryLinuxSerialPorts(Detected);
    {$ENDIF}

    SortAndDeduplicate(Detected);

    SetLength(ActiveDevices, FDevices.Count);
    for I := 0 to FDevices.Count - 1 do
      ActiveDevices[I] := False;

    for I := 0 to Length(Detected) - 1 do
    begin
      Found := False;
      for J := 0 to FDevices.Count - 1 do
      begin
        if SameText(FDevices[J].DeviceName, Detected[I].DeviceName) then
        begin
          Found := True;
          ActiveDevices[J] := True;
          FDevices[J].Description := Detected[I].Description;
          FDevices[J].PortKind := Detected[I].PortKind;
          FDevices[J].IsAvailable := Detected[I].IsAvailable;
          
          ProbePort(FDevices[J]);
          Break;
        end;
      end;

      if not Found then
      begin
        NewItem := FDevices.Add;
        NewItem.DeviceName := Detected[I].DeviceName;
        NewItem.DisplayName := Detected[I].DisplayName;
        NewItem.Description := Detected[I].Description;
        NewItem.PortKind := Detected[I].PortKind;
        NewItem.IsAvailable := Detected[I].IsAvailable;
        
        ProbePort(NewItem);
        DoDeviceFound(NewItem);
      end;
    end;

    for I := FDevices.Count - 1 downto 0 do
    begin
      if not ActiveDevices[I] then
      begin
        DoDeviceRemoved(FDevices[I].DeviceName);
        FDevices.Delete(I);
      end;
    end;

    // Apply sorting to the collection items to keep them in natural order
    for I := 0 to FDevices.Count - 2 do
    begin
      for J := I + 1 to FDevices.Count - 1 do
      begin
        if NaturalCompare(FDevices[I].DeviceName, FDevices[J].DeviceName) > 0 then
        begin
          FDevices[J].Index := I;
        end;
      end;
    end;

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
