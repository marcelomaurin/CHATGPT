unit aiusb;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, ExtCtrls, Process, LResources
  {$IFDEF MSWINDOWS}
  , Registry
  {$ENDIF}
  ;

type
  TAIUSBDeviceState = (
    udsUnknown,
    udsConnected,
    udsDisconnected,
    udsChanged,
    udsError
  );

  TAIUSBDeviceItem = class(TCollectionItem)
  private
    FDeviceID: string;
    FVendorID: string;
    FProductID: string;
    FManufacturer: string;
    FProduct: string;
    FSerialNumber: string;
    FDeviceClass: string;
    FDevicePath: string;
    FBus: string;
    FPort: string;
    FState: TAIUSBDeviceState;
    FLastError: string;
  published
    property DeviceID: string read FDeviceID write FDeviceID;
    property VendorID: string read FVendorID write FVendorID;
    property ProductID: string read FProductID write FProductID;
    property Manufacturer: string read FManufacturer write FManufacturer;
    property Product: string read FProduct write FProduct;
    property SerialNumber: string read FSerialNumber write FSerialNumber;
    property DeviceClass: string read FDeviceClass write FDeviceClass;
    property DevicePath: string read FDevicePath write FDevicePath;
    property Bus: string read FBus write FBus;
    property Port: string read FPort write FPort;
    property State: TAIUSBDeviceState read FState write FState;
    property LastError: string read FLastError write FLastError;
  end;

  TAIUSBDeviceCollection = class(TOwnedCollection)
  private
    function GetItem(Index: Integer): TAIUSBDeviceItem;
  public
    constructor Create(AOwner: TPersistent);
    function Add: TAIUSBDeviceItem;
    property Items[Index: Integer]: TAIUSBDeviceItem read GetItem; default;
  end;

  TAIUSBDeviceEvent = procedure(Sender: TObject; Device: TAIUSBDeviceItem) of object;
  TAIUSBErrorEvent = procedure(Sender: TObject; const Msg: string) of object;

  TAIUSB = class(TComponent)
  private
    FDevices: TAIUSBDeviceCollection;
    FAutoRefresh: Boolean;
    FRefreshInterval: Integer;
    FTimer: TTimer;
    FLastError: string;

    FOnBeforeRefresh: TNotifyEvent;
    FOnAfterRefresh: TNotifyEvent;
    FOnDeviceConnected: TAIUSBDeviceEvent;
    FOnDeviceDisconnected: TAIUSBDeviceEvent;
    FOnDeviceChanged: TAIUSBDeviceEvent;
    FOnError: TAIUSBErrorEvent;

    procedure SetAutoRefresh(AValue: Boolean);
    procedure SetRefreshInterval(AValue: Integer);
    procedure TimerTick(Sender: TObject);

  protected
    procedure DoDeviceConnected(Device: TAIUSBDeviceItem);
    procedure DoDeviceDisconnected(Device: TAIUSBDeviceItem);
    procedure DoDeviceChanged(Device: TAIUSBDeviceItem);
    procedure DoError(const Msg: string);

  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    procedure Refresh;
    procedure Clear;
    function Count: Integer;
    function FindByDeviceID(const ADeviceID: string): TAIUSBDeviceItem;

  published
    property Devices: TAIUSBDeviceCollection read FDevices;
    property AutoRefresh: Boolean read FAutoRefresh write SetAutoRefresh default False;
    property RefreshInterval: Integer read FRefreshInterval write SetRefreshInterval default 2000;
    property LastError: string read FLastError;

    property OnBeforeRefresh: TNotifyEvent read FOnBeforeRefresh write FOnBeforeRefresh;
    property OnAfterRefresh: TNotifyEvent read FOnAfterRefresh write FOnAfterRefresh;
    property OnDeviceConnected: TAIUSBDeviceEvent read FOnDeviceConnected write FOnDeviceConnected;
    property OnDeviceDisconnected: TAIUSBDeviceEvent read FOnDeviceDisconnected write FOnDeviceDisconnected;
    property OnDeviceChanged: TAIUSBDeviceEvent read FOnDeviceChanged write FOnDeviceChanged;
    property OnError: TAIUSBErrorEvent read FOnError write FOnError;
  end;

type
  TDetectedUSBDevice = record
    DeviceID: string;
    VendorID: string;
    ProductID: string;
    Manufacturer: string;
    Product: string;
    SerialNumber: string;
    DeviceClass: string;
    DevicePath: string;
    Bus: string;
    Port: string;
  end;

  TDetectedUSBDeviceArray = array of TDetectedUSBDevice;

function ExtractUSBVID(const S: string): string;
function ExtractUSBPID(const S: string): string;
function NormalizeUSBID(const S: string): string;

implementation

function ExtractUSBVID(const S: string): string;
var
  P: SizeInt;
begin
  Result := '';
  P := Pos('VID_', UpperCase(S));
  if P > 0 then
    Result := Copy(S, P + 4, 4);
end;

function ExtractUSBPID(const S: string): string;
var
  P: SizeInt;
begin
  Result := '';
  P := Pos('PID_', UpperCase(S));
  if P > 0 then
    Result := Copy(S, P + 4, 4);
end;

function NormalizeUSBID(const S: string): string;
begin
  Result := UpperCase(Trim(S));
end;

constructor TAIUSBDeviceCollection.Create(AOwner: TPersistent);
begin
  inherited Create(AOwner, TAIUSBDeviceItem);
end;

function TAIUSBDeviceCollection.Add: TAIUSBDeviceItem;
begin
  Result := TAIUSBDeviceItem(inherited Add);
end;

function TAIUSBDeviceCollection.GetItem(Index: Integer): TAIUSBDeviceItem;
begin
  Result := TAIUSBDeviceItem(inherited GetItem(Index));
end;

{ TAIUSB }

constructor TAIUSB.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FDevices := TAIUSBDeviceCollection.Create(Self);
  FRefreshInterval := 2000;
  FAutoRefresh := False;

  FTimer := TTimer.Create(Self);
  FTimer.Enabled := False;
  FTimer.Interval := FRefreshInterval;
  FTimer.OnTimer := @TimerTick;
end;

destructor TAIUSB.Destroy;
begin
  if FTimer <> nil then
  begin
    FTimer.Enabled := False;
    FTimer.Free;
    FTimer := nil;
  end;
  FDevices.Free;
  inherited Destroy;
end;

procedure TAIUSB.SetAutoRefresh(AValue: Boolean);
begin
  if FAutoRefresh = AValue then
    Exit;

  FAutoRefresh := AValue;
  if FTimer <> nil then
  begin
    if not (csDesigning in ComponentState) then
      FTimer.Enabled := FAutoRefresh
    else
      FTimer.Enabled := False;
  end;
end;

procedure TAIUSB.SetRefreshInterval(AValue: Integer);
begin
  if AValue < 500 then
    AValue := 500;

  FRefreshInterval := AValue;
  if FTimer <> nil then
    FTimer.Interval := FRefreshInterval;
end;

procedure TAIUSB.TimerTick(Sender: TObject);
begin
  if not (csDesigning in ComponentState) then
    Refresh;
end;

procedure TAIUSB.Clear;
begin
  FDevices.Clear;
end;

function TAIUSB.Count: Integer;
begin
  Result := FDevices.Count;
end;

function TAIUSB.FindByDeviceID(const ADeviceID: string): TAIUSBDeviceItem;
var
  I: Integer;
begin
  Result := nil;
  for I := 0 to FDevices.Count - 1 do
  begin
    if SameText(FDevices[I].DeviceID, ADeviceID) then
      Exit(FDevices[I]);
  end;
end;

procedure TAIUSB.DoDeviceConnected(Device: TAIUSBDeviceItem);
begin
  if Assigned(FOnDeviceConnected) then
    FOnDeviceConnected(Self, Device);
end;

procedure TAIUSB.DoDeviceDisconnected(Device: TAIUSBDeviceItem);
begin
  if Assigned(FOnDeviceDisconnected) then
    FOnDeviceDisconnected(Self, Device);
end;

procedure TAIUSB.DoDeviceChanged(Device: TAIUSBDeviceItem);
begin
  if Assigned(FOnDeviceChanged) then
    FOnDeviceChanged(Self, Device);
end;

procedure TAIUSB.DoError(const Msg: string);
begin
  if Assigned(FOnError) then
    FOnError(Self, Msg);
end;

procedure SplitCSV(const S: string; List: TStrings);
var
  InQuote: Boolean;
  StartIdx, J: Integer;
  Part: string;
begin
  List.Clear;
  InQuote := False;
  StartIdx := 1;
  for J := 1 to Length(S) do
  begin
    if S[J] = '"' then
      InQuote := not InQuote
    else if (S[J] = ',') and not InQuote then
    begin
      Part := Copy(S, StartIdx, J - StartIdx);
      if (Length(Part) >= 2) and (Part[1] = '"') and (Part[Length(Part)] = '"') then
        Part := Copy(Part, 2, Length(Part) - 2);
      List.Add(Part);
      StartIdx := J + 1;
    end;
  end;
  Part := Copy(S, StartIdx, Length(S) - StartIdx + 1);
  if (Length(Part) >= 2) and (Part[1] = '"') and (Part[Length(Part)] = '"') then
    Part := Copy(Part, 2, Length(Part) - 2);
  List.Add(Part);
end;

{$IFDEF MSWINDOWS}
procedure QueryWindowsUSBDevices(var ADevices: TDetectedUSBDeviceArray);
var
  Reg: TRegistry;
  VidPidList, InstanceList: TStringList;
  I, J: Integer;
  KeyPath, InstanceKeyPath: string;
  Dev: TDetectedUSBDevice;
  Desc, Mfg, Cls: string;
begin
  SetLength(ADevices, 0);
  Reg := TRegistry.Create(KEY_READ);
  VidPidList := TStringList.Create;
  InstanceList := TStringList.Create;
  try
    Reg.RootKey := HKEY_LOCAL_MACHINE;
    if Reg.OpenKeyReadOnly('SYSTEM\CurrentControlSet\Enum\USB') then
    begin
      Reg.GetKeyNames(VidPidList);
      Reg.CloseKey;
      
      for I := 0 to VidPidList.Count - 1 do
      begin
        KeyPath := 'SYSTEM\CurrentControlSet\Enum\USB\' + VidPidList[I];
        if Reg.OpenKeyReadOnly(KeyPath) then
        begin
          Reg.GetKeyNames(InstanceList);
          Reg.CloseKey;
          
          for J := 0 to InstanceList.Count - 1 do
          begin
            InstanceKeyPath := KeyPath + '\' + InstanceList[J];
            // Check if the device is active (Control subkey exists)
            if Reg.OpenKeyReadOnly(InstanceKeyPath + '\Control') then
            begin
              Reg.CloseKey;
              
              // Now open the instance key to read properties
              if Reg.OpenKeyReadOnly(InstanceKeyPath) then
              begin
                Dev.DeviceID := VidPidList[I] + '\' + InstanceList[J];
                Dev.VendorID := ExtractUSBVID(VidPidList[I]);
                Dev.ProductID := ExtractUSBPID(VidPidList[I]);
                
                // Read description
                Desc := '';
                if Reg.ValueExists('DeviceDesc') then
                begin
                  Desc := Reg.ReadString('DeviceDesc');
                  if Pos(';', Desc) > 0 then
                    Desc := Copy(Desc, LastDelimiter(';', Desc) + 1, Length(Desc));
                end;
                if Desc = '' then
                  Desc := Reg.ReadString('FriendlyName');
                Dev.Product := Desc;
                
                // Read Manufacturer
                Mfg := '';
                if Reg.ValueExists('Mfg') then
                begin
                  Mfg := Reg.ReadString('Mfg');
                  if Pos(';', Mfg) > 0 then
                    Mfg := Copy(Mfg, LastDelimiter(';', Mfg) + 1, Length(Mfg));
                end;
                Dev.Manufacturer := Mfg;
                
                // Read Class
                Cls := '';
                if Reg.ValueExists('Class') then
                  Cls := Reg.ReadString('Class');
                Dev.DeviceClass := Cls;
                
                Dev.SerialNumber := InstanceList[J];
                Dev.DevicePath := '';
                Dev.Bus := '';
                Dev.Port := '';
                
                SetLength(ADevices, Length(ADevices) + 1);
                ADevices[Length(ADevices) - 1] := Dev;
                
                Reg.CloseKey;
              end;
            end;
          end;
        end;
      end;
    end;
  finally
    Reg.Free;
    VidPidList.Free;
    InstanceList.Free;
  end;
end;
{$ENDIF}

{$IFDEF UNIX}
procedure QueryLinuxUSBDevices(var ADevices: TDetectedUSBDeviceArray);
var
  SR: TSearchRec;
  Path, SysPath: string;
  Dev: TDetectedUSBDevice;
  
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
  SetLength(ADevices, 0);
  Path := '/sys/bus/usb/devices/*';
  if FindFirst(Path, faAnyFile, SR) = 0 then
  begin
    repeat
      SysPath := '/sys/bus/usb/devices/' + SR.Name + '/';
      if FileExists(SysPath + 'idVendor') and FileExists(SysPath + 'idProduct') then
      begin
        Dev.VendorID := NormalizeUSBID(ReadSysfsValue(SysPath + 'idVendor'));
        Dev.ProductID := NormalizeUSBID(ReadSysfsValue(SysPath + 'idProduct'));
        Dev.DeviceID := SR.Name;
        Dev.Manufacturer := ReadSysfsValue(SysPath + 'manufacturer');
        Dev.Product := ReadSysfsValue(SysPath + 'product');
        Dev.SerialNumber := ReadSysfsValue(SysPath + 'serial');
        Dev.DeviceClass := ReadSysfsValue(SysPath + 'bDeviceClass');
        Dev.DevicePath := '/dev/bus/usb/' + ReadSysfsValue(SysPath + 'busnum') + '/' + ReadSysfsValue(SysPath + 'devnum');
        Dev.Bus := ReadSysfsValue(SysPath + 'busnum');
        Dev.Port := ReadSysfsValue(SysPath + 'devnum');
        
        SetLength(ADevices, Length(ADevices) + 1);
        ADevices[Length(ADevices) - 1] := Dev;
      end;
    until FindNext(SR) <> 0;
    SysUtils.FindClose(SR);
  end;
end;
{$ENDIF}

procedure TAIUSB.Refresh;
var
  Detected: TDetectedUSBDeviceArray;
  ActiveDevices: array of Boolean;
  OldCount: Integer;
  I, J: Integer;
  Found: Boolean;
  NewItem: TAIUSBDeviceItem;
begin
  FLastError := '';

  if Assigned(FOnBeforeRefresh) then
    FOnBeforeRefresh(Self);

  try
    SetLength(Detected, 0);

    {$IFDEF MSWINDOWS}
    QueryWindowsUSBDevices(Detected);
    {$ENDIF}

    {$IFDEF UNIX}
    QueryLinuxUSBDevices(Detected);
    {$ENDIF}

    OldCount := FDevices.Count;
    SetLength(ActiveDevices, OldCount);

    for I := 0 to OldCount - 1 do
      ActiveDevices[I] := False;

    for I := 0 to Length(Detected) - 1 do
    begin
      Found := False;

      for J := 0 to OldCount - 1 do
      begin
        if SameText(FDevices[J].DeviceID, Detected[I].DeviceID) then
        begin
          Found := True;
          ActiveDevices[J] := True;

          if (FDevices[J].VendorID <> Detected[I].VendorID) or
             (FDevices[J].ProductID <> Detected[I].ProductID) or
             (FDevices[J].Manufacturer <> Detected[I].Manufacturer) or
             (FDevices[J].Product <> Detected[I].Product) then
          begin
            FDevices[J].VendorID := Detected[I].VendorID;
            FDevices[J].ProductID := Detected[I].ProductID;
            FDevices[J].Manufacturer := Detected[I].Manufacturer;
            FDevices[J].Product := Detected[I].Product;
            FDevices[J].SerialNumber := Detected[I].SerialNumber;
            FDevices[J].DeviceClass := Detected[I].DeviceClass;
            FDevices[J].DevicePath := Detected[I].DevicePath;
            FDevices[J].Bus := Detected[I].Bus;
            FDevices[J].Port := Detected[I].Port;
            FDevices[J].State := udsChanged;

            DoDeviceChanged(FDevices[J]);
          end;

          Break;
        end;
      end;

      if not Found then
      begin
        NewItem := FDevices.Add;
        NewItem.DeviceID := Detected[I].DeviceID;
        NewItem.VendorID := Detected[I].VendorID;
        NewItem.ProductID := Detected[I].ProductID;
        NewItem.Manufacturer := Detected[I].Manufacturer;
        NewItem.Product := Detected[I].Product;
        NewItem.SerialNumber := Detected[I].SerialNumber;
        NewItem.DeviceClass := Detected[I].DeviceClass;
        NewItem.DevicePath := Detected[I].DevicePath;
        NewItem.Bus := Detected[I].Bus;
        NewItem.Port := Detected[I].Port;
        NewItem.State := udsConnected;

        DoDeviceConnected(NewItem);
      end;
    end;

    for I := OldCount - 1 downto 0 do
    begin
      if not ActiveDevices[I] then
      begin
        FDevices[I].State := udsDisconnected;
        DoDeviceDisconnected(FDevices[I]);
        FDevices.Delete(I);
      end;
    end;

  except
    on E: Exception do
    begin
      FLastError := E.Message;
      DoError(E.Message);
    end;
  end;

  if Assigned(FOnAfterRefresh) then
    FOnAfterRefresh(Self);
end;

initialization
  {$I aiusb_icon.lrs}

end.
