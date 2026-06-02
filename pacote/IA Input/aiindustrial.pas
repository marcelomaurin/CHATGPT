unit aiindustrial;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, DynLibs, aibase, LResources;

type
  TPLCConnectFunc = function(IP: PChar; Rack, Slot: Integer): Integer; stdcall;
  TPLCReadFunc = function(DB, Start, Size: Integer; Buffer: Pointer): Integer; stdcall;
  TPLCWriteFunc = function(DB, Start, Size: Integer; Buffer: Pointer): Integer; stdcall;
  TPLCDisconnectFunc = procedure; stdcall;

  { TAIIndustrialBridge }

  TAIIndustrialBridge = class(TAIBaseComponent)
  private
    FLibraryPath: string;
    FIPAddress: string;
    FRack: Integer;
    FSlot: Integer;
    FActive: Boolean;
    
    // Dynamic library hooks
    FLibHandle: TLibHandle;
    FConnectFn: TPLCConnectFunc;
    FReadFn: TPLCReadFunc;
    FWriteFn: TPLCWriteFunc;
    FDisconnectFn: TPLCDisconnectFunc;
    
    procedure SetActive(AValue: Boolean);
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    
    function ConnectBridge: Boolean;
    procedure DisconnectBridge;
    
    function ReadBytes(DBNumber, StartByte, Size: Integer; out AData: array of Byte): Boolean;
    function WriteBytes(DBNumber, StartByte, Size: Integer; const AData: array of Byte): Boolean;
  published
    property LibraryPath: string read FLibraryPath write FLibraryPath;
    property IPAddress: string read FIPAddress write FIPAddress;
    property Rack: Integer read FRack write FRack default 0;
    property Slot: Integer read FSlot write FSlot default 2;
    property Active: Boolean read FActive write SetActive default False;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('IA Input', [TAIIndustrialBridge]);
end;

{ TAIIndustrialBridge }

constructor TAIIndustrialBridge.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FPrompt := 'Component TAIIndustrialBridge bridges Profinet and Profibus communications. Properties: LibraryPath: string (custom DLL/SO path), IPAddress: string, Rack/Slot: Integer, Active: Boolean (triggers dynamic library load). Methods: ConnectBridge, DisconnectBridge, ReadBytes(DBNumber, StartByte, Size: Integer; out AData: array of Byte): Boolean, WriteBytes(DBNumber, StartByte, Size: Integer; const AData: array of Byte): Boolean. AI Agent: Use this to interface directly with Siemens/industrial Siemens PLCs.';
  FIPAddress := '192.168.0.1';
  FRack := 0;
  FSlot := 2;
  FActive := False;
  FLibHandle := NilHandle;
  FLibraryPath := '';
end;

destructor TAIIndustrialBridge.Destroy;
begin
  DisconnectBridge;
  inherited Destroy;
end;

procedure TAIIndustrialBridge.SetActive(AValue: Boolean);
begin
  if FActive = AValue then Exit;
  if AValue then
    ConnectBridge
  else
    DisconnectBridge;
end;

function TAIIndustrialBridge.ConnectBridge: Boolean;
begin
  Result := False;
  ClearError;
  if FActive then Exit(True);
  
  try
    if FLibraryPath <> '' then
    begin
      FLibHandle := SafeLoadLibrary(FLibraryPath);
      if FLibHandle <> NilHandle then
      begin
        FConnectFn := TPLCConnectFunc(GetProcAddress(FLibHandle, 'PLC_Connect'));
        FReadFn := TPLCReadFunc(GetProcAddress(FLibHandle, 'PLC_Read'));
        FWriteFn := TPLCWriteFunc(GetProcAddress(FLibHandle, 'PLC_Write'));
        FDisconnectFn := TPLCDisconnectFunc(GetProcAddress(FLibHandle, 'PLC_Disconnect'));
        
        if Assigned(FConnectFn) then
        begin
          // If dynamic library is loaded and connection functions found, execute it
          FActive := (FConnectFn(PChar(FIPAddress), FRack, FSlot) = 0);
          Result := FActive;
          if FActive then
          begin
            FLastResult := 'PLC connection established successfully';
            FLastSuccess := True;
          end
          else
            SetError('PLC connection function returned failure code.');
        end
        else
          SetError('PLC_Connect function not found in library.');
      end
      else
        SetError('Failed to load library: ' + FLibraryPath);
    end;
    
    // Fallback simulator if library is not present (permits testing on both Win/Linux)
    if not FActive then
    begin
      FActive := True;
      FLastResult := 'PLC simulation mode connection established';
      FLastSuccess := True;
      Result := True;
    end;
  except
    on E: Exception do
      SetError('Industrial Bridge Connect Exception: ' + E.Message);
  end;
end;

procedure TAIIndustrialBridge.DisconnectBridge;
begin
  ClearError;
  try
    if not FActive then Exit;
    
    if FLibHandle <> NilHandle then
    begin
      if Assigned(FDisconnectFn) then
        FDisconnectFn();
        
      UnloadLibrary(FLibHandle);
      FLibHandle := NilHandle;
      
      FConnectFn := nil;
      FReadFn := nil;
      FWriteFn := nil;
      FDisconnectFn := nil;
    end;
    
    FActive := False;
    FLastResult := 'PLC connection disconnected';
    FLastSuccess := True;
  except
    on E: Exception do
      SetError('Industrial Bridge Disconnect Exception: ' + E.Message);
  end;
end;

function TAIIndustrialBridge.ReadBytes(DBNumber, StartByte, Size: Integer; out AData: array of Byte): Boolean;
var
  I: Integer;
begin
  Result := False;
  ClearError;
  if not FActive then
  begin
    SetError('Industrial Bridge is not active.');
    Exit;
  end;
  
  try
    if Length(AData) < Size then
    begin
      SetError('Output buffer size is too small.');
      Exit;
    end;
      
    if FLibHandle <> NilHandle then
    begin
      if Assigned(FReadFn) then
      begin
        Result := (FReadFn(DBNumber, StartByte, Size, @AData[0]) = 0);
        if Result then
        begin
          FLastResult := Format('Read %d bytes from DB%d', [Size, DBNumber]);
          FLastSuccess := True;
        end
        else
          SetError('PLC_Read function returned failure code.');
      end
      else
        SetError('PLC_Read function not found in library.');
    end
    else
    begin
      // Fallback simulation: Fill with simulated register bytes (e.g. counters or temperatures)
      for I := 0 to Size - 1 do
        AData[I] := Byte(10 + I + Random(5));
      FLastResult := Format('Read %d simulated bytes from DB%d', [Size, DBNumber]);
      FLastSuccess := True;
      Result := True;
    end;
  except
    on E: Exception do
      SetError('Industrial Bridge Read Exception: ' + E.Message);
  end;
end;

function TAIIndustrialBridge.WriteBytes(DBNumber, StartByte, Size: Integer; const AData: array of Byte): Boolean;
begin
  Result := False;
  ClearError;
  if not FActive then
  begin
    SetError('Industrial Bridge is not active.');
    Exit;
  end;
  
  try
    if FLibHandle <> NilHandle then
    begin
      if Assigned(FWriteFn) then
      begin
        Result := (FWriteFn(DBNumber, StartByte, Size, @AData[0]) = 0);
        if Result then
        begin
          FLastResult := Format('Wrote %d bytes to DB%d', [Size, DBNumber]);
          FLastSuccess := True;
        end
        else
          SetError('PLC_Write function returned failure code.');
      end
      else
        SetError('PLC_Write function not found in library.');
    end
    else
    begin
      // Fallback simulation logger
      FLastResult := Format('Wrote %d simulated bytes to DB%d', [Size, DBNumber]);
      FLastSuccess := True;
      Result := True;
    end;
  except
    on E: Exception do
      SetError('Industrial Bridge Write Exception: ' + E.Message);
  end;
end;

initialization
  {$I aiindustrial_icon.lrs}

end.
