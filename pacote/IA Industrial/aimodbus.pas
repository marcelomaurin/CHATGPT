unit aimodbus;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, sockets, serial, aibase,
  {$IFDEF WIN32}
  winsock2
  {$ELSE}
    {$IFDEF WIN64}
    winsock2
    {$ELSE}
    netdb
    {$ENDIF}
  {$ENDIF}
  , LResources;

type
  TModbusProtocol = (mbTCP, mbRTU);

  { TAIModbusClient }

  TAIModbusClient = class(TAIBaseComponent)
  private
    FProtocolType: TModbusProtocol;
    FIPAddress: string;
    FPort: Integer;
    FDeviceName: string;
    FBaudRate: Integer;
    FActive: Boolean;
    FSocket: TSocket;
    FSerialHandle: TSerialHandle;
    FTransactionID: Word;
    procedure SetActive(AValue: Boolean);
    function ResolveHost(const AHost: string; var AAddr): Boolean;
    function SocketWrite(const ABuffer; ALength: Integer): Integer;
    function SocketRead(var ABuffer; ALength: Integer): Integer;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    
    function Connect: Boolean;
    procedure Disconnect;
    function ReadHoldingRegisters(SlaveID, Address, Count: Integer; out AData: array of Word): Boolean;
    function WriteSingleRegister(SlaveID, Address, Value: Integer): Boolean;
  published
    property ProtocolType: TModbusProtocol read FProtocolType write FProtocolType default mbTCP;
    property IPAddress: string read FIPAddress write FIPAddress;
    property Port: Integer read FPort write FPort default 502; // Modbus default port
    property DeviceName: string read FDeviceName write FDeviceName;
    property BaudRate: Integer read FBaudRate write FBaudRate default 9600;
    property Active: Boolean read FActive write SetActive default False;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('AI Automation', [TAIModbusClient]);
end;

constructor TAIModbusClient.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FPrompt := 'Component TAIModbusClient connects to PLCs/industrial equipment via Modbus TCP/RTU. Properties: ProtocolType: TModbusProtocol (mbTCP, mbRTU), IPAddress: string, Port: Integer (default 502), DeviceName: string, BaudRate: Integer, Active: Boolean. Methods: Connect, Disconnect, ReadHoldingRegisters(SlaveID, Address, Count: Integer; out AData: array of Word): Boolean, WriteSingleRegister(SlaveID, Address, Value: Integer): Boolean. AI Agent: Use this to read sensor states or write actuator commands in industrial automation.';
  FProtocolType := mbTCP;
  FIPAddress := '192.168.1.100';
  FPort := 502;
  FDeviceName := 'COM1';
  FBaudRate := 9600;
  FActive := False;
  FSocket := TSocket(-1);
  FSerialHandle := 0;
  FTransactionID := 0;
  ClearError;
end;

destructor TAIModbusClient.Destroy;
begin
  Disconnect;
  inherited Destroy;
end;

function TAIModbusClient.ResolveHost(const AHost: string; var AAddr): Boolean;
var
  AddrVal: Cardinal;
  {$IFDEF WIN32}
  HostEnt: PHostEnt;
  {$ELSE}
    {$IFDEF WIN64}
    HostEnt: PHostEnt;
    {$ELSE}
    HostEnt: THostEntry;
    {$ENDIF}
  {$ENDIF}
begin
  Result := False;
  AddrVal := 0;
  Move(StrToNetAddr(AHost), AddrVal, 4);
  if AddrVal <> 0 then
  begin
    Move(AddrVal, AAddr, 4);
    Exit(True);
  end;
    
  {$IFDEF WIN32}
  HostEnt := gethostbyname(PChar(AHost));
  if HostEnt <> nil then
  begin
    Move(HostEnt^.h_addr_list^^, AAddr, 4);
    Result := True;
  end;
  {$ELSE}
    {$IFDEF WIN64}
    HostEnt := gethostbyname(PChar(AHost));
    if HostEnt <> nil then
    begin
      Move(HostEnt^.h_addr_list^^, AAddr, 4);
      Result := True;
    end;
    {$ELSE}
    if netdb.ResolveHostByName(AHost, HostEnt) then
    begin
      Move(HostEnt.Addr, AAddr, SizeOf(TInAddr));
      Result := True;
    end;
    {$ENDIF}
  {$ENDIF}
end;

function TAIModbusClient.SocketWrite(const ABuffer; ALength: Integer): Integer;
begin
  if FSocket <> TSocket(-1) then
    Result := fpsend(FSocket, @ABuffer, ALength, 0)
  else
    Result := -1;
end;

function TAIModbusClient.SocketRead(var ABuffer; ALength: Integer): Integer;
begin
  if FSocket <> TSocket(-1) then
    Result := fprecv(FSocket, @ABuffer, ALength, 0)
  else
    Result := -1;
end;

procedure TAIModbusClient.SetActive(AValue: Boolean);
begin
  if FActive = AValue then Exit;
  if AValue then
    Connect
  else
    Disconnect;
end;

function TAIModbusClient.Connect: Boolean;
var
  Addr: TInetSockAddr;
  Res: Integer;
begin
  Result := False;
  ClearError;
  if FActive then Exit(True);
  
  try
    if FProtocolType = mbTCP then
    begin
      FSocket := fpSocket(AF_INET, SOCK_STREAM, 0);
      if FSocket = TSocket(-1) then
      begin
        SetError('Could not create socket.');
        Exit;
      end;
      
      Addr.sin_family := AF_INET;
      Addr.sin_port := htons(FPort);
      
      if not ResolveHost(FIPAddress, Addr.sin_addr) then
      begin
        sockets.CloseSocket(FSocket);
        FSocket := TSocket(-1);
        SetError('Host resolution failed: ' + FIPAddress);
        Exit;
      end;
      
      Res := fpConnect(FSocket, @Addr, SizeOf(Addr));
      if Res < 0 then
      begin
        sockets.CloseSocket(FSocket);
        FSocket := TSocket(-1);
        SetError('Connection to host failed.');
        Exit;
      end;
      
      FActive := True;
      FLastResult := 'Modbus TCP connection established';
      FLastSuccess := True;
      Result := True;
    end
    else
    begin
      FSerialHandle := SerOpen(FDeviceName);
      if FSerialHandle <> 0 then
      begin
        SerSetParams(FSerialHandle, FBaudRate, 8, NoneParity, 1, []);
        FActive := True;
        FLastResult := 'Modbus RTU serial connection established';
        FLastSuccess := True;
        Result := True;
      end
      else
        SetError('Failed to open Modbus RTU serial device: ' + FDeviceName);
    end;
  except
    on E: Exception do
      SetError('Modbus Connect Exception: ' + E.Message);
  end;
end;

procedure TAIModbusClient.Disconnect;
begin
  ClearError;
  try
    if not FActive then Exit;
    
    if FProtocolType = mbTCP then
    begin
      if FSocket <> TSocket(-1) then
      begin
        sockets.CloseSocket(FSocket);
        FSocket := TSocket(-1);
      end;
    end
    else
    begin
      if FSerialHandle <> 0 then
      begin
        SerClose(FSerialHandle);
        FSerialHandle := 0;
      end;
    end;
    
    FActive := False;
    FLastResult := 'Modbus disconnected';
    FLastSuccess := True;
  except
    on E: Exception do
      SetError('Modbus Disconnect Exception: ' + E.Message);
  end;
end;

function TAIModbusClient.ReadHoldingRegisters(SlaveID, Address, Count: Integer; out AData: array of Word): Boolean;
var
  Frame: array[0..11] of Byte;
  Response: array[0..255] of Byte;
  BytesRead, I: Integer;
begin
  Result := False;
  ClearError;
  if not FActive or (FProtocolType <> mbTCP) or (FSocket = TSocket(-1)) then
  begin
    SetError('Modbus client not active or not using TCP.');
    Exit;
  end;
  
  Inc(FTransactionID);
  
  // MBAP Header (Modbus TCP)
  Frame[0] := Hi(FTransactionID);
  Frame[1] := Lo(FTransactionID);
  Frame[2] := 0; // Protocol ID Hi
  Frame[3] := 0; // Protocol ID Lo
  Frame[4] := 0; // Length Hi
  Frame[5] := 6; // Length Lo (UnitID + FunctCode + Address + Count = 6 bytes)
  Frame[6] := SlaveID;
  
  // Modbus PDU
  Frame[7] := 3; // Function Code: Read Holding Registers
  Frame[8] := Hi(Address);
  Frame[9] := Lo(Address);
  Frame[10] := Hi(Count);
  Frame[11] := Lo(Count);
  
  try
    if SocketWrite(Frame[0], 12) <> 12 then
    begin
      SetError('Modbus TCP Write failed.');
      Exit;
    end;
    
    // Read MBAP Header of Response (7 bytes)
    BytesRead := SocketRead(Response[0], 7);
    if BytesRead = 7 then
    begin
      // Read remainder data: [FunctCode:1] [ByteCount:1] [RegisterValues:2*Count]
      BytesRead := SocketRead(Response[7], 2 + Count * 2);
      if (BytesRead = 2 + Count * 2) and (Response[7] = 3) then
      begin
        for I := 0 to Count - 1 do
        begin
          if I <= High(AData) then
            AData[I] := (Response[9 + I * 2] shl 8) or Response[9 + I * 2 + 1];
        end;
        FLastResult := 'Modbus Registers Read Succeeded';
        FLastSuccess := True;
        Result := True;
      end
      else
        SetError('Modbus TCP Read Exception or mismatch.');
    end
    else
      SetError('Modbus TCP Header Read failed.');
  except
    on E: Exception do
      SetError('Modbus Read Holding Registers Exception: ' + E.Message);
  end;
end;

function TAIModbusClient.WriteSingleRegister(SlaveID, Address, Value: Integer): Boolean;
var
  Frame: array[0..11] of Byte;
  Response: array[0..255] of Byte;
  BytesRead: Integer;
begin
  Result := False;
  ClearError;
  if not FActive or (FProtocolType <> mbTCP) or (FSocket = TSocket(-1)) then
  begin
    SetError('Modbus client not active or not using TCP.');
    Exit;
  end;
  
  Inc(FTransactionID);
  
  // MBAP Header
  Frame[0] := Hi(FTransactionID);
  Frame[1] := Lo(FTransactionID);
  Frame[2] := 0;
  Frame[3] := 0;
  Frame[4] := 0;
  Frame[5] := 6; // UnitID + FunctCode + Address + Value = 6 bytes
  Frame[6] := SlaveID;
  
  // PDU
  Frame[7] := 6; // Function Code: Write Single Register
  Frame[8] := Hi(Address);
  Frame[9] := Lo(Address);
  Frame[10] := Hi(Value);
  Frame[11] := Lo(Value);
  
  try
    if SocketWrite(Frame[0], 12) <> 12 then
    begin
      SetError('Modbus TCP Write failed.');
      Exit;
    end;
    
    // Read Response Header
    BytesRead := SocketRead(Response[0], 7);
    if BytesRead = 7 then
    begin
      // Read remainder response payload: [FunctCode:1] [Address:2] [Value:2]
      BytesRead := SocketRead(Response[7], 5);
      if (BytesRead = 5) and (Response[7] = 6) then
      begin
        FLastResult := 'Modbus Single Register Write Succeeded';
        FLastSuccess := True;
        Result := True;
      end
      else
        SetError('Modbus TCP Write Single Register Response mismatch.');
    end
    else
      SetError('Modbus TCP Header Read failed.');
  except
    on E: Exception do
      SetError('Modbus Write Register Exception: ' + E.Message);
  end;
end;

initialization
  {$I aimodbus_icon.lrs}

end.
