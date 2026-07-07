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
  , LResources;

type
  TSerialPortKind = (
    spkUnknown,
    spkSystem,
    spkUSBSerial,
    spkBluetooth,
    spkVirtual,
    spkArduinoCompatible
  );

  TSerialDeviceState = (
    sdsUnknown,
    sdsDetected,
    sdsIdentifying,
    sdsIdentified,
    sdsReady,
    sdsBusy,
    sdsError,
    sdsDisconnected
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
    FState: TSerialDeviceState;
    FVID: string;
    FPID: string;
    FManufacturer: string;
    FProduct: string;
    FSerialNumber: string;
    FProtocol: string;
    FConfidence: Integer;
    FInstanceID: string;
    FLocationInfo: string;
    FLocationPath: string;
    FDriverService: string;
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
    property State: TSerialDeviceState read FState write FState default sdsUnknown;
    property VID: string read FVID write FVID;
    property PID: string read FPID write FPID;
    property Manufacturer: string read FManufacturer write FManufacturer;
    property Product: string read FProduct write FProduct;
    property SerialNumber: string read FSerialNumber write FSerialNumber;
    property Protocol: string read FProtocol write FProtocol;
    property Confidence: Integer read FConfidence write FConfidence default 0;
    property InstanceID: string read FInstanceID write FInstanceID;
    property LocationInfo: string read FLocationInfo write FLocationInfo;
    property LocationPath: string read FLocationPath write FLocationPath;
    property DriverService: string read FDriverService write FDriverService;
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
  TSerialDeviceChangedEvent = procedure(Sender: TObject; Device: TAIListSerialDeviceItem) of object;
  TSerialDeviceIdentifiedEvent = procedure(Sender: TObject; Device: TAIListSerialDeviceItem) of object;

  // Temporary helper structure for detected ports
  TDetectedDevice = record
    DeviceName: string;
    DisplayName: string;
    Description: string;
    PortKind: TSerialPortKind;
    IsAvailable: Boolean;
    VID: string;
    PID: string;
    InstanceID: string;
    LocationInfo: string;
    LocationPath: string;
    DriverService: string;
    SerialNumber: string;
    Manufacturer: string;
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
    FOnDeviceChanged: TSerialDeviceChangedEvent;
    FOnDeviceIdentified: TSerialDeviceIdentifiedEvent;

    procedure SetDevices(AValue: TAIListSerialDeviceItems);
    procedure SetAutoRefresh(AValue: Boolean);
    procedure SetAutoRefreshIntervalMs(AValue: Integer);
    procedure DoAutoRefreshTimer(Sender: TObject);
    function ShouldInclude(AKind: TSerialPortKind): Boolean;
    procedure DoDeviceFound(Device: TAIListSerialDeviceItem);
    procedure DoDeviceRemoved(const ADeviceName: string);
    procedure DoError(const AMsg: string);
    procedure QueryWindowsSerialPorts(var ADetected: TDetectedDeviceArray);
    procedure QueryWindowsSetupAPI(var ADetected: TDetectedDeviceArray);
    procedure QueryLinuxSerialPorts(var ADetected: TDetectedDeviceArray);
    procedure EnrichLinuxMetadata(var ADetected: TDetectedDeviceArray);
    procedure ProbePort(Device: TAIListSerialDeviceItem);
    procedure IdentifyByVIDPID(Device: TAIListSerialDeviceItem);
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
    property OnDeviceChanged: TSerialDeviceChangedEvent read FOnDeviceChanged write FOnDeviceChanged;
    property OnDeviceIdentified: TSerialDeviceIdentifiedEvent read FOnDeviceIdentified write FOnDeviceIdentified;
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
  GUID_DEVCLASS_PORTS: TGUID = '{4d36e978-e325-11ce-bfc1-08002be10318}';
  DIGCF_PRESENT = $00000002;
  SPDRP_FRIENDLYNAME = $0000000C;
  SPDRP_HARDWAREID = $00000001;
  SPDRP_SERVICE              = $00000004;
  SPDRP_MFG                  = $0000000B;
  SPDRP_LOCATION_INFORMATION = $0000000D;
  SPDRP_LOCATION_PATHS       = $00000023;

type
  SP_DEVINFO_DATA = record
    cbSize: DWORD;
    ClassGuid: TGUID;
    DevInst: DWORD;
    Reserved: ULONG_PTR;
  end;
  PSP_DEVINFO_DATA = ^SP_DEVINFO_DATA;

  TSetupDiGetClassDevsW = function(ClassGuid: PGUID; Enumerator: PWideChar; hwndParent: HWND; Flags: DWORD): THandle; stdcall;
  TSetupDiGetDeviceRegistryPropertyW = function(DeviceInfoSet: THandle; DeviceInfoData: PSP_DEVINFO_DATA; Property_: DWORD; PropertyRegDataType: PDWORD; PropertyBuffer: PByte; PropertyBufferSize: DWORD; RequiredSize: PDWORD): BOOL; stdcall;
  TSetupDiDestroyDeviceInfoList = function(DeviceInfoSet: THandle): BOOL; stdcall;
  TSetupDiOpenDevRegKey = function(DeviceInfoSet: THandle; DeviceInfoData: PSP_DEVINFO_DATA; Scope, HwProfile, KeyType: DWORD; samDesired: REGSAM): HKEY; stdcall;
  TSetupDiEnumDeviceInfo = function(DeviceInfoSet: THandle; MemberIndex: DWORD;
    DeviceInfoData: PSP_DEVINFO_DATA): BOOL; stdcall;
  TSetupDiGetDeviceInstanceIdW = function(DeviceInfoSet: THandle;
    DeviceInfoData: PSP_DEVINFO_DATA; DeviceInstanceId: PWideChar;
    DeviceInstanceIdSize: DWORD; RequiredSize: PDWORD): BOOL; stdcall;

var
  SetupAPILib: THandle = 0;
  SetupDiGetClassDevsW: TSetupDiGetClassDevsW = nil;
  SetupDiGetDeviceRegistryPropertyW: TSetupDiGetDeviceRegistryPropertyW = nil;
  SetupDiDestroyDeviceInfoList: TSetupDiDestroyDeviceInfoList = nil;
  SetupDiOpenDevRegKey: TSetupDiOpenDevRegKey = nil;
  SetupDiEnumDeviceInfo: TSetupDiEnumDeviceInfo = nil;
  SetupDiGetDeviceInstanceIdW: TSetupDiGetDeviceInstanceIdW = nil;

function LoadSetupAPI: Boolean;
begin
  if SetupAPILib <> 0 then Exit(True);
  SetupAPILib := LoadLibrary('setupapi.dll');
  if SetupAPILib <> 0 then
  begin
    SetupDiGetClassDevsW := TSetupDiGetClassDevsW(GetProcAddress(SetupAPILib, 'SetupDiGetClassDevsW'));
    SetupDiGetDeviceRegistryPropertyW := TSetupDiGetDeviceRegistryPropertyW(GetProcAddress(SetupAPILib, 'SetupDiGetDeviceRegistryPropertyW'));
    SetupDiDestroyDeviceInfoList := TSetupDiDestroyDeviceInfoList(GetProcAddress(SetupAPILib, 'SetupDiDestroyDeviceInfoList'));
    SetupDiOpenDevRegKey := TSetupDiOpenDevRegKey(GetProcAddress(SetupAPILib, 'SetupDiOpenDevRegKey'));
    SetupDiEnumDeviceInfo := TSetupDiEnumDeviceInfo(GetProcAddress(SetupAPILib, 'SetupDiEnumDeviceInfo'));
    SetupDiGetDeviceInstanceIdW := TSetupDiGetDeviceInstanceIdW(GetProcAddress(SetupAPILib, 'SetupDiGetDeviceInstanceIdW'));
  end;
  Result := (SetupDiGetClassDevsW <> nil) and 
            (SetupDiGetDeviceRegistryPropertyW <> nil) and 
            (SetupDiDestroyDeviceInfoList <> nil) and
            (SetupDiOpenDevRegKey <> nil) and
            (SetupDiEnumDeviceInfo <> nil) and
            (SetupDiGetDeviceInstanceIdW <> nil);
end;

function GetDevPropStr(DevInfo: THandle; DevData: PSP_DEVINFO_DATA; Prop: DWORD): string;
var
  Buf: array[0..1023] of WideChar;
begin
  Result := '';
  FillChar(Buf, SizeOf(Buf), 0);
  if SetupDiGetDeviceRegistryPropertyW(DevInfo, DevData, Prop, nil,
       PByte(@Buf), SizeOf(Buf) - 2, nil) then
    Result := UTF8Encode(WideString(PWideChar(@Buf)));
  // Para REG_MULTI_SZ (ex.: SPDRP_LOCATION_PATHS) retorna apenas a 1a string,
  // pois PWideChar para no primeiro #0 — comportamento desejado.
end;

function ExtractUsbSerialFromInstanceId(const AInstanceId: string): string;
var
  P1, P2: Integer;
  Seg: string;
begin
  // Formato: BUS\VID_xxxx&PID_xxxx\SEGMENTO
  // Se SEGMENTO contem '&', foi gerado pelo Windows (chip sem serial, ex. CH340) -> retorna ''
  Result := '';
  P1 := Pos('\', AInstanceId);
  if P1 = 0 then Exit;
  P2 := Pos('\', AInstanceId, P1 + 1);
  if P2 = 0 then Exit;
  Seg := Copy(AInstanceId, P2 + 1, MaxInt);
  if (Seg <> '') and (Pos('&', Seg) = 0) then
    Result := Seg;
end;

{$ENDIF}

procedure TAIListSerialDevices.QueryWindowsSetupAPI(var ADetected: TDetectedDeviceArray);
{$IFDEF MSWINDOWS}
var
  DevInfo: THandle;
  DevInfoData: SP_DEVINFO_DATA;
  MemberIndex: DWORD;
  PortName: array[0..255] of WideChar;
  RegKey: HKEY;
  ValType: DWORD;
  ValSize: DWORD;
  PortStr, FriendlyStr, HardwareIDStr, InstId, SvcStr: string;
  InstBuf: array[0..511] of WideChar;
  Kind: TSerialPortKind;
  Item: TDetectedDevice;
  VIDStr, PIDStr: string;
  PVID, PPID: Integer;
begin
  if not LoadSetupAPI then Exit;

  DevInfo := SetupDiGetClassDevsW(@GUID_DEVCLASS_PORTS, nil, 0, DIGCF_PRESENT);
  if DevInfo = THandle(INVALID_HANDLE_VALUE) then Exit;

  try
    MemberIndex := 0;
    DevInfoData.cbSize := SizeOf(SP_DEVINFO_DATA);
    while SetupDiEnumDeviceInfo(DevInfo, MemberIndex, @DevInfoData) do
    begin
      // Nome da porta (COMx) via chave de registro do device
      PortStr := '';
      RegKey := SetupDiOpenDevRegKey(DevInfo, @DevInfoData,
        1 {DICS_FLAG_GLOBAL}, 0, 1 {DIREG_DEV}, KEY_READ);
      if RegKey <> HKEY(INVALID_HANDLE_VALUE) then
      begin
        ValSize := SizeOf(PortName);
        FillChar(PortName, SizeOf(PortName), 0);
        if RegQueryValueExW(RegKey, 'PortName', nil, @ValType,
             PByte(@PortName), @ValSize) = ERROR_SUCCESS then
          PortStr := UTF8Encode(WideString(PWideChar(@PortName)));
        RegCloseKey(RegKey);
      end;

      // Classe Ports inclui LPT: manter apenas COMx
      if (PortStr <> '') and (Pos('COM', UpperCase(PortStr)) = 1) then
      begin
        FriendlyStr   := GetDevPropStr(DevInfo, @DevInfoData, SPDRP_FRIENDLYNAME);
        HardwareIDStr := UpperCase(GetDevPropStr(DevInfo, @DevInfoData, SPDRP_HARDWAREID));
        SvcStr        := GetDevPropStr(DevInfo, @DevInfoData, SPDRP_SERVICE);

        InstId := '';
        FillChar(InstBuf, SizeOf(InstBuf), 0);
        if SetupDiGetDeviceInstanceIdW(DevInfo, @DevInfoData,
             @InstBuf[0], Length(InstBuf) - 1, nil) then
          InstId := UTF8Encode(WideString(PWideChar(@InstBuf)));

        VIDStr := '';
        PIDStr := '';
        PVID := Pos('VID_', HardwareIDStr);
        if PVID > 0 then VIDStr := Copy(HardwareIDStr, PVID + 4, 4);
        PPID := Pos('PID_', HardwareIDStr);
        if PPID > 0 then PIDStr := Copy(HardwareIDStr, PPID + 4, 4);

        Kind := spkSystem;
        if (Pos('USB', HardwareIDStr) > 0) or (Pos('FTDIBUS', HardwareIDStr) > 0) then
        begin
          if (VIDStr = '2341') or (VIDStr = '2A03') then
            Kind := spkArduinoCompatible
          else
            Kind := spkUSBSerial;
        end
        else if (Pos('BTHENUM', HardwareIDStr) > 0) or
                (Pos('BTHMODEM', HardwareIDStr) > 0) or
                (Pos('BLUETOOTH', HardwareIDStr) > 0) then
          Kind := spkBluetooth;

        if ShouldInclude(Kind) then
        begin
          Item := Default(TDetectedDevice);
          Item.DeviceName := PortStr;
          if FriendlyStr <> '' then
            Item.DisplayName := FriendlyStr
          else
            Item.DisplayName := PortStr;
          Item.Description   := HardwareIDStr;
          Item.PortKind      := Kind;
          Item.IsAvailable   := True;
          Item.VID           := VIDStr;
          Item.PID           := PIDStr;
          Item.InstanceID    := InstId;
          Item.LocationInfo  := GetDevPropStr(DevInfo, @DevInfoData, SPDRP_LOCATION_INFORMATION);
          Item.LocationPath  := GetDevPropStr(DevInfo, @DevInfoData, SPDRP_LOCATION_PATHS);
          Item.DriverService := SvcStr;
          Item.SerialNumber  := ExtractUsbSerialFromInstanceId(InstId);
          Item.Manufacturer  := GetDevPropStr(DevInfo, @DevInfoData, SPDRP_MFG);

          SetLength(ADetected, Length(ADetected) + 1);
          ADetected[Length(ADetected) - 1] := Item;
        end;
      end;
      Inc(MemberIndex);
    end;
  finally
    SetupDiDestroyDeviceInfoList(DevInfo);
  end;
end;
{$ELSE}
begin
end;
{$ENDIF}

{ TAIListSerialDeviceItem }

constructor TAIListSerialDeviceItem.Create(ACollection: TCollection);
begin
  inherited Create(ACollection);
  FIsAvailable := True;
  FIsOpenable := True;
  FLastError := '';
  FState := sdsUnknown;
  FVID := '';
  FPID := '';
  FManufacturer := '';
  FProduct := '';
  FSerialNumber := '';
  FProtocol := '';
  FConfidence := 0;
  FInstanceID := '';
  FLocationInfo := '';
  FLocationPath := '';
  FDriverService := '';
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
  Device.LastError := '';

  if not FProbeOpenable then
  begin
    Device.IsOpenable := True;
    Exit;
  end;

  Device.IsOpenable := False;

  {$IFDEF MSWINDOWS}
  PortStr := '\\.\' + Device.DeviceName;

  HPort := CreateFile(
    PChar(PortStr),
    GENERIC_READ or GENERIC_WRITE,
    0,
    nil,
    OPEN_EXISTING,
    0,
    0
  );

  if HPort = INVALID_HANDLE_VALUE then
  begin
    Err := GetLastError;

    case Err of
      ERROR_ACCESS_DENIED:
        begin
          Device.IsAvailable := True;
          Device.LastError := 'Port busy or access denied';
        end;

      ERROR_FILE_NOT_FOUND:
        begin
          Device.IsAvailable := False;
          Device.LastError := 'Port does not exist';
        end;

      else
        begin
          Device.IsAvailable := False;
          Device.LastError := SysErrorMessage(Err);
        end;
    end;
  end
  else
  begin
    Device.IsAvailable := True;
    Device.IsOpenable := True;
    CloseHandle(HPort);
  end;
  {$ENDIF}

  {$IFDEF UNIX}
  FD := FpOpen(Device.DeviceName, O_RDWR or O_NOCTTY or O_NONBLOCK);

  if FD < 0 then
  begin
    Err := fpGetErrno;

    case Err of
      ESysEBUSY:
        begin
          Device.IsAvailable := True;
          Device.LastError := 'Port busy';
        end;

      ESysEACCES:
        begin
          Device.IsAvailable := True;
          Device.LastError := 'Access denied - check dialout/uucp permissions';
        end;

      ESysENOENT:
        begin
          Device.IsAvailable := False;
          Device.LastError := 'Device node does not exist';
        end;

      else
        begin
          Device.IsAvailable := False;
          Device.LastError := 'Error opening port: ' + IntToStr(Err) + ' - ' + SysErrorMessage(Err);
        end;
    end;
  end
  else
  begin
    Device.IsAvailable := True;
    Device.IsOpenable := True;
    FpClose(FD);
  end;
  {$ENDIF}
end;

procedure TAIListSerialDevices.IdentifyByVIDPID(Device: TAIListSerialDeviceItem);
var
  MfgUpper: string;
begin
  Device.Confidence := 0;

  if SameText(Device.VID, '2341') or SameText(Device.VID, '2A03') then
  begin
    Device.PortKind := spkArduinoCompatible;
    if Device.Manufacturer = '' then Device.Manufacturer := 'Arduino';
    if Device.Product = '' then Device.Product := 'Arduino Compatible';
    Device.Confidence := 80;
  end;

  if SameText(Device.VID, '1A86') then
  begin
    Device.PortKind := spkUSBSerial;
    if Device.Manufacturer = '' then Device.Manufacturer := 'WCH';
    if Device.Product = '' then Device.Product := 'CH340/CH341 USB Serial';
    Device.Confidence := 70;
  end;

  if SameText(Device.VID, '10C4') then
  begin
    Device.PortKind := spkUSBSerial;
    if Device.Manufacturer = '' then Device.Manufacturer := 'Silicon Labs';
    if Device.Product = '' then Device.Product := 'CP210x USB Serial';
    Device.Confidence := 70;
  end;

  if SameText(Device.VID, '0403') then
  begin
    Device.PortKind := spkUSBSerial;
    if Device.Manufacturer = '' then Device.Manufacturer := 'FTDI';
    if Device.Product = '' then Device.Product := 'FTDI USB Serial';
    Device.Confidence := 70;
  end;

  if SameText(Device.VID, '067B') then
  begin
    Device.PortKind := spkUSBSerial;
    if Device.Manufacturer = '' then Device.Manufacturer := 'Prolific';
    if Device.Product = '' then Device.Product := 'PL2303 USB Serial';
    Device.Confidence := 70;
  end;

  // Se ja temos metadados ricos de fabricante conhecidos, dar um bonus de confianca
  MfgUpper := UpperCase(Device.Manufacturer);
  if (MfgUpper <> '') and (Device.Confidence > 0) then
  begin
    if (Pos('ARDUINO', MfgUpper) > 0) or (Pos('FTDI', MfgUpper) > 0) or
       (Pos('WCH', MfgUpper) > 0) or (Pos('SILICON LABS', MfgUpper) > 0) or
       (Pos('PROLIFIC', MfgUpper) > 0) then
      Device.Confidence := Device.Confidence + 15;
  end;

  // Fallback para identificacao baseada em strings de fabricante se VID/PID vazio
  if (Device.Confidence = 0) and (MfgUpper <> '') then
  begin
    if (Pos('ARDUINO', MfgUpper) > 0) then
    begin
      Device.PortKind := spkArduinoCompatible;
      Device.Confidence := 60;
    end
    else if (Pos('FTDI', MfgUpper) > 0) or (Pos('SILICON LABS', MfgUpper) > 0) or
            (Pos('WCH', MfgUpper) > 0) or (Pos('PROLIFIC', MfgUpper) > 0) then
    begin
      Device.PortKind := spkUSBSerial;
      Device.Confidence := 50;
    end;
  end;
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
  TempArr: TDetectedDeviceArray;
  Idx, J, FoundIdx: Integer;
{$ENDIF}
begin
  {$IFDEF MSWINDOWS}
  // Try SetupAPI first
  QueryWindowsSetupAPI(ADetected);

  // Uniao com o registro: captura portas virtuais fora da classe Ports
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
                Item.VID := '';
                Item.PID := '';
                
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

  // Deduplicacao mantendo o registro mais rico (ex. SetupAPI sobre o Registry cru)
  if Length(ADetected) > 1 then
  begin
    TempArr := nil;
    for Idx := 0 to Length(ADetected) - 1 do
    begin
      FoundIdx := -1;
      for J := 0 to Length(TempArr) - 1 do
      begin
        if SameText(TempArr[J].DeviceName, ADetected[Idx].DeviceName) then
        begin
          FoundIdx := J;
          Break;
        end;
      end;
      if FoundIdx = -1 then
      begin
        SetLength(TempArr, Length(TempArr) + 1);
        TempArr[Length(TempArr) - 1] := ADetected[Idx];
      end
      else
      begin
        if (TempArr[FoundIdx].InstanceID = '') and (ADetected[Idx].InstanceID <> '') then
          TempArr[FoundIdx] := ADetected[Idx];
      end;
    end;
    ADetected := TempArr;
  end;
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
            Item.VID := '';
            Item.PID := '';

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
                  ADetected[I].VID := VID;
                  ADetected[I].PID := PID;
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
  EnrichLinuxMetadata(ADetected);
  {$ENDIF}
  {$ENDIF}
end;

procedure TAIListSerialDevices.EnrichLinuxMetadata(var ADetected: TDetectedDeviceArray);
{$IFDEF UNIX}
var
  I, Limit: Integer;
  DevName, SysPath, ParentDir, DriverLink: string;
  FoundVendor: Boolean;

  function ReadSysFile(const AFileName: string): string;
  var
    F: TextFile;
    Line: string;
  begin
    Result := '';
    if FileExists(AFileName) then
    begin
      try
        AssignFile(F, AFileName);
        Reset(F);
        if not Eof(F) then
        begin
          Readln(F, Line);
          Result := Trim(Line);
        end;
        CloseFile(F);
      except
        // Ignore file errors
      end;
    end;
  end;

begin
  for I := 0 to Length(ADetected) - 1 do
  begin
    DevName := ExtractFileName(ADetected[I].DeviceName);
    SysPath := '/sys/class/tty/' + DevName;

    if DirectoryExists(SysPath) then
    begin
      ParentDir := SysPath + '/device';
      FoundVendor := False;
      Limit := 0;
      
      while (Length(ParentDir) > 10) and (Limit < 5) do
      begin
        if FileExists(ParentDir + '/idVendor') then
        begin
          ADetected[I].VID := ReadSysFile(ParentDir + '/idVendor');
          ADetected[I].PID := ReadSysFile(ParentDir + '/idProduct');
          ADetected[I].SerialNumber := ReadSysFile(ParentDir + '/serial');
          ADetected[I].Manufacturer := ReadSysFile(ParentDir + '/manufacturer');
          ADetected[I].LocationInfo := ReadSysFile(ParentDir + '/devpath');
          ADetected[I].LocationPath := ParentDir;
          
          DriverLink := ParentDir + '/driver';
          if DirectoryExists(DriverLink) then
            ADetected[I].DriverService := ExtractFileName(ResolveSymlink(DriverLink));
            
          FoundVendor := True;
          Break;
        end;
        ParentDir := ExpandFileName(ParentDir + '/..');
        Inc(Limit);
      end;
      
      if not FoundVendor then
      begin
        if DirectoryExists(SysPath + '/device') then
        begin
          ADetected[I].LocationPath := ExpandFileName(SysPath + '/device');
          DriverLink := SysPath + '/device/driver';
          if DirectoryExists(DriverLink) then
            ADetected[I].DriverService := ExtractFileName(ResolveSymlink(DriverLink));
        end;
      end;
    end;
  end;
end;
{$ELSE}
begin
end;
{$ENDIF}

procedure TAIListSerialDevices.Refresh;
var
  Detected: TDetectedDeviceArray;
  I, J: Integer;
  Found: Boolean;
  NewItem: TAIListSerialDeviceItem;
  ActiveDevices: array of Boolean;
  OldCount: Integer;
  HasChanged: Boolean;
  PrevState: TSerialDeviceState;
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

    OldCount := FDevices.Count;
    SetLength(ActiveDevices, OldCount);
    for I := 0 to OldCount - 1 do
      ActiveDevices[I] := False;

    for I := 0 to Length(Detected) - 1 do
    begin
      Found := False;
      for J := 0 to OldCount - 1 do
      begin
        if SameText(FDevices[J].DeviceName, Detected[I].DeviceName) then
        begin
          Found := True;
          ActiveDevices[J] := True;
          
          HasChanged := (FDevices[J].DisplayName <> Detected[I].DisplayName) or
                        (FDevices[J].Description <> Detected[I].Description) or
                        (FDevices[J].PortKind <> Detected[I].PortKind) or
                        (FDevices[J].IsAvailable <> Detected[I].IsAvailable) or
                        (FDevices[J].VID <> Detected[I].VID) or
                        (FDevices[J].PID <> Detected[I].PID) or
                        (FDevices[J].InstanceID <> Detected[I].InstanceID) or
                        (FDevices[J].LocationInfo <> Detected[I].LocationInfo) or
                        (FDevices[J].LocationPath <> Detected[I].LocationPath) or
                        (FDevices[J].DriverService <> Detected[I].DriverService) or
                        (FDevices[J].SerialNumber <> Detected[I].SerialNumber) or
                        (FDevices[J].Manufacturer <> Detected[I].Manufacturer);

          FDevices[J].DisplayName := Detected[I].DisplayName;
          FDevices[J].Description := Detected[I].Description;
          FDevices[J].PortKind := Detected[I].PortKind;
          FDevices[J].IsAvailable := Detected[I].IsAvailable;
          FDevices[J].VID := Detected[I].VID;
          FDevices[J].PID := Detected[I].PID;
          FDevices[J].InstanceID := Detected[I].InstanceID;
          FDevices[J].LocationInfo := Detected[I].LocationInfo;
          FDevices[J].LocationPath := Detected[I].LocationPath;
          FDevices[J].DriverService := Detected[I].DriverService;
          FDevices[J].SerialNumber := Detected[I].SerialNumber;
          FDevices[J].Manufacturer := Detected[I].Manufacturer;
          
          IdentifyByVIDPID(FDevices[J]);
          
          PrevState := FDevices[J].State;
          ProbePort(FDevices[J]);

          if FDevices[J].IsAvailable then
          begin
            if FDevices[J].IsOpenable then
              FDevices[J].State := sdsReady
            else
              FDevices[J].State := sdsBusy;
          end
          else
            FDevices[J].State := sdsError;

          if FDevices[J].State <> PrevState then
            HasChanged := True;

          if HasChanged then
          begin
            if Assigned(FOnDeviceChanged) then
              FOnDeviceChanged(Self, FDevices[J]);
          end;
          
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
        NewItem.VID := Detected[I].VID;
        NewItem.PID := Detected[I].PID;
        NewItem.InstanceID := Detected[I].InstanceID;
        NewItem.LocationInfo := Detected[I].LocationInfo;
        NewItem.LocationPath := Detected[I].LocationPath;
        NewItem.DriverService := Detected[I].DriverService;
        NewItem.SerialNumber := Detected[I].SerialNumber;
        NewItem.Manufacturer := Detected[I].Manufacturer;
        NewItem.State := sdsDetected;
        
        IdentifyByVIDPID(NewItem);
        if NewItem.Confidence > 0 then
        begin
          NewItem.State := sdsIdentified;
          if Assigned(FOnDeviceIdentified) then
            FOnDeviceIdentified(Self, NewItem);
        end;

        ProbePort(NewItem);
        if NewItem.IsAvailable then
        begin
          if NewItem.IsOpenable then
            NewItem.State := sdsReady
          else
            NewItem.State := sdsBusy;
        end
        else
          NewItem.State := sdsError;
          
        DoDeviceFound(NewItem);
      end;
    end;

    for I := OldCount - 1 downto 0 do
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

initialization
  {$I aiserial_icon.lrs}

end.
