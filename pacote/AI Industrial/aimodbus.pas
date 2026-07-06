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
    FTimeoutMs: Integer;
    procedure SetActive(AValue: Boolean);
    function ResolveHost(const AHost: string; var AAddr): Boolean;
    function SocketWrite(const ABuffer; ALength: Integer): Integer;
    function SocketRead(var ABuffer; ALength: Integer): Integer;
    function SocketReadExact(var ABuffer; ALength: Integer): Boolean;
    function SerialReadBytes(var ABuffer; ALength: Integer; TimeoutMs: Integer = 500): Integer;
    procedure UnpackBits(const Src: array of Byte; SrcIndex: Integer; Count: Integer; var Dest: array of Boolean);
    function ExecuteTransaction(SlaveID, FunctCode: Byte; const RequestPDU: array of Byte; RequestPDULen: Integer; out ResponsePDU: array of Byte; var ResponsePDULen: Integer): Boolean;
    function NormalizeSerialDeviceName(const AName: string): string;
    function IsSerialHandleValid(AHandle: TSerialHandle): Boolean;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    
    function Connect: Boolean;
    procedure Disconnect;
    function ReadCoils(SlaveID, Address, Count: Integer; out AData: array of Boolean): Boolean;
    function ReadDiscreteInputs(SlaveID, Address, Count: Integer; out AData: array of Boolean): Boolean;
    function ReadHoldingRegisters(SlaveID, Address, Count: Integer; out AData: array of Word): Boolean;
    function ReadInputRegisters(SlaveID, Address, Count: Integer; out AData: array of Word): Boolean;
    function WriteSingleCoil(SlaveID, Address: Integer; Value: Boolean): Boolean;
    function WriteSingleRegister(SlaveID, Address, Value: Integer): Boolean;
    function WriteMultipleRegisters(SlaveID, Address: Integer; const Values: array of Word): Boolean;
  published
    property ProtocolType: TModbusProtocol read FProtocolType write FProtocolType default mbTCP;
    property IPAddress: string read FIPAddress write FIPAddress;
    property Port: Integer read FPort write FPort default 502; // Modbus default port
    property DeviceName: string read FDeviceName write FDeviceName;
    property BaudRate: Integer read FBaudRate write FBaudRate default 9600;
    property TimeoutMs: Integer read FTimeoutMs write FTimeoutMs default 1000;
    property Active: Boolean read FActive write SetActive default False;
  end;

procedure Register;

implementation

function MB_CRC16(const ABuf: array of Byte; ALen: Integer): Word;
var
  I, J: Integer;
begin
  Result := $FFFF;
  for I := 0 to ALen - 1 do
  begin
    Result := Result xor ABuf[I];
    for J := 0 to 7 do
    begin
      if (Result and 1) <> 0 then
        Result := (Result shr 1) xor $A001
      else
        Result := Result shr 1;
    end;
  end;
end;

procedure Register;
begin
  RegisterComponents('AI Industrial', [TAIModbusClient]);
end;

constructor TAIModbusClient.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FPrompt :=
    'Component TAIModbusClient connects to PLCs/industrial equipment via Modbus TCP/RTU. ' + LineEnding +
    'Properties: ProtocolType: TModbusProtocol (mbTCP, mbRTU), IPAddress: string, Port: Integer (default 502), DeviceName: string, BaudRate: Integer, Active: Boolean. ' + LineEnding +
    'Methods: Connect, Disconnect, ReadHoldingRegisters, WriteSingleRegister. ' + LineEnding +
    'AI Agent: Use this to read sensor states or write actuator commands in industrial automation.';
  FProtocolType := mbTCP;
  FIPAddress := '192.168.1.100';
  FPort := 502;
  FDeviceName := 'COM1';
  FBaudRate := 9600;
  FActive := False;
  FSocket := TSocket(-1);
  FSerialHandle := 0;
  FTransactionID := 0;
  FTimeoutMs := 1000;
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

function TAIModbusClient.SerialReadBytes(var ABuffer; ALength: Integer; TimeoutMs: Integer = 500): Integer;
var
  BytesRead, TotalRead: Integer;
  StartTime: QWord;
  PBuf: PByte;
begin
  TotalRead := 0;
  PBuf := @ABuffer;
  StartTime := GetTickCount64;
  while (TotalRead < ALength) and (GetTickCount64 - StartTime < Cardinal(TimeoutMs)) do
  begin
    BytesRead := SerRead(FSerialHandle, PBuf[TotalRead], ALength - TotalRead);
    if BytesRead > 0 then
    begin
      TotalRead := TotalRead + BytesRead;
    end
    else
    begin
      Sleep(10);
    end;
  end;
  Result := TotalRead;
end;
function TAIModbusClient.NormalizeSerialDeviceName(const AName: string): string;
begin
  {$IFDEF MSWINDOWS}
  if SameText(Copy(AName, 1, 3), 'COM') and (StrToIntDef(Copy(AName, 4, MaxInt), 0) >= 10) then
    Result := '\\.\' + AName
  else
  {$ENDIF}
    Result := AName;
end;

function TAIModbusClient.IsSerialHandleValid(AHandle: TSerialHandle): Boolean;
begin
  {$IFDEF MSWINDOWS}
  Result := (AHandle <> 0) and (AHandle <> TSerialHandle(-1));
  {$ELSE}
  Result := AHandle > 0;
  {$ENDIF}
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
  {$IFDEF WINDOWS}
  TimeoutVal: DWORD;
  {$ELSE}
  TimeoutVal: TTimeVal;
  {$ENDIF}
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
      
      // Set receive and send timeouts
      {$IFDEF WINDOWS}
      TimeoutVal := FTimeoutMs;
      fpsetsockopt(FSocket, $FFFF, $1006, @TimeoutVal, SizeOf(TimeoutVal));
      fpsetsockopt(FSocket, $FFFF, $1007, @TimeoutVal, SizeOf(TimeoutVal));
      {$ELSE}
      TimeoutVal.tv_sec := FTimeoutMs div 1000;
      TimeoutVal.tv_usec := (FTimeoutMs mod 1000) * 1000;
      fpsetsockopt(FSocket, 1, 20, @TimeoutVal, SizeOf(TimeoutVal));
      fpsetsockopt(FSocket, 1, 21, @TimeoutVal, SizeOf(TimeoutVal));
      {$ENDIF}
      
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
      FSerialHandle := SerOpen(NormalizeSerialDeviceName(FDeviceName));
      if IsSerialHandleValid(FSerialHandle) then
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
      if IsSerialHandleValid(FSerialHandle) then
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

function TAIModbusClient.SocketReadExact(var ABuffer; ALength: Integer): Boolean;
var
  TotalRead, BytesRead: Integer;
  PBuf: PByte;
  StartTime: QWord;
begin
  Result := False;
  TotalRead := 0;
  PBuf := @ABuffer;
  StartTime := GetTickCount64;
  while TotalRead < ALength do
  begin
    BytesRead := SocketRead(PBuf[TotalRead], ALength - TotalRead);
    if BytesRead > 0 then
    begin
      TotalRead := TotalRead + BytesRead;
      StartTime := GetTickCount64;
    end
    else if BytesRead < 0 then
    begin
      Exit(False);
    end;
    
    if GetTickCount64 - StartTime > Cardinal(FTimeoutMs) then
    begin
      SetError('Socket read timeout.');
      Exit(False);
    end;
    
    if BytesRead = 0 then
    begin
      Exit(False);
    end;
    Sleep(5);
  end;
  Result := True;
end;

procedure TAIModbusClient.UnpackBits(const Src: array of Byte; SrcIndex: Integer; Count: Integer; var Dest: array of Boolean);
var
  I: Integer;
begin
  for I := 0 to Count - 1 do
  begin
    if I <= High(Dest) then
      Dest[I] := ((Src[SrcIndex + (I div 8)] shr (I mod 8)) and 1) <> 0;
  end;
end;

function TAIModbusClient.ExecuteTransaction(SlaveID, FunctCode: Byte; const RequestPDU: array of Byte; RequestPDULen: Integer; out ResponsePDU: array of Byte; var ResponsePDULen: Integer): Boolean;
var
  Frame: array[0..259] of Byte;
  Response: array[0..259] of Byte;
  BytesRead, I, ExpectedLen: Integer;
  CRC, ExpectedCRC: Word;
  ByteCount: Byte;
begin
  Result := False;
  ClearError;
  if not FActive then
  begin
    SetError('Modbus client not active.');
    Exit;
  end;
  
  if FProtocolType = mbTCP then
  begin
    if FSocket = TSocket(-1) then
    begin
      SetError('Modbus client socket not open.');
      Exit;
    end;
    
    Inc(FTransactionID);
    
    // MBAP Header
    Frame[0] := Hi(FTransactionID);
    Frame[1] := Lo(FTransactionID);
    Frame[2] := 0; // Protocol ID Hi
    Frame[3] := 0; // Protocol ID Lo
    Frame[4] := Hi(RequestPDULen + 1);
    Frame[5] := Lo(RequestPDULen + 1);
    Frame[6] := SlaveID;
    
    // Copy PDU
    for I := 0 to RequestPDULen - 1 do
      Frame[7 + I] := RequestPDU[I];
      
    try
      if SocketWrite(Frame[0], 7 + RequestPDULen) <> (7 + RequestPDULen) then
      begin
        SetError('Modbus TCP write failed.');
        Exit;
      end;
      
      // Read 7 bytes MBAP header
      if not SocketReadExact(Response[0], 7) then
      begin
        SetError('Modbus TCP read header failed/timeout.');
        Exit;
      end;
      
      ExpectedLen := (Response[4] shl 8) or Response[5];
      if (ExpectedLen < 2) or (ExpectedLen > 250) then
      begin
        SetError('Modbus TCP invalid response length: ' + IntToStr(ExpectedLen));
        Exit;
      end;
      
      // Read remainder (Length - 1 bytes)
      if not SocketReadExact(Response[7], ExpectedLen - 1) then
      begin
        SetError('Modbus TCP read payload failed/timeout.');
        Exit;
      end;
      
      // Check exception
      if Response[7] = (FunctCode or $80) then
      begin
        SetError('Modbus TCP Exception: function=' + Format('%.2x', [FunctCode]) + ' exception=' + Format('%.2x', [Response[8]]));
        Exit;
      end;
      
      if Response[7] <> FunctCode then
      begin
        SetError('Modbus TCP function mismatch: expected ' + IntToStr(FunctCode) + ', got ' + IntToStr(Response[7]));
        Exit;
      end;
      
      ResponsePDULen := ExpectedLen - 1;
      for I := 0 to ResponsePDULen - 1 do
        ResponsePDU[I] := Response[7 + I];
        
      Result := True;
    except
      on E: Exception do SetError('Modbus TCP Exception: ' + E.Message);
    end;
  end
  else
  begin
    // Modbus RTU
    if not IsSerialHandleValid(FSerialHandle) then
    begin
      SetError('Modbus client serial port not open.');
      Exit;
    end;
    
    // Flush serial input buffer
    SerFlushInput(FSerialHandle);
    
    Frame[0] := SlaveID;
    for I := 0 to RequestPDULen - 1 do
      Frame[1 + I] := RequestPDU[I];
      
    CRC := MB_CRC16(Frame, 1 + RequestPDULen);
    Frame[1 + RequestPDULen] := Lo(CRC);
    Frame[1 + RequestPDULen + 1] := Hi(CRC);
    
    try
      if SerWrite(FSerialHandle, Frame[0], 3 + RequestPDULen) <> (3 + RequestPDULen) then
      begin
        SetError('Modbus RTU serial write failed.');
        Exit;
      end;
      
      // Read first 3 bytes: [SlaveID] [FuncCode] [ByteCount/ExceptionCode/AddrHi]
      if SerialReadBytes(Response[0], 3, FTimeoutMs) <> 3 then
      begin
        SetError('Modbus RTU response timeout/no header.');
        Exit;
      end;
      
      if Response[0] <> SlaveID then
      begin
        SetError('Modbus RTU slave ID mismatch.');
        Exit;
      end;
      
      if Response[1] = (FunctCode or $80) then
      begin
        // Exception response (5 bytes total, we already read 3)
        if SerialReadBytes(Response[3], 2, FTimeoutMs) <> 2 then
        begin
          SetError('Modbus RTU exception response timeout.');
          Exit;
        end;
        CRC := MB_CRC16(Response, 3);
        ExpectedCRC := (Response[4] shl 8) or Response[3];
        if CRC = ExpectedCRC then
          SetError('Modbus RTU Exception: function=' + Format('%.2x', [FunctCode]) + ' exception=' + Format('%.2x', [Response[2]]))
        else
          SetError('Modbus RTU exception CRC mismatch.');
        Exit;
      end;
      
      if Response[1] <> FunctCode then
      begin
        SetError('Modbus RTU function mismatch: expected ' + IntToStr(FunctCode) + ', got ' + IntToStr(Response[1]));
        Exit;
      end;
      
      // Determine remaining bytes to read
      if FunctCode in [1, 2, 3, 4] then
      begin
        ByteCount := Response[2];
        // Read ByteCount + 2 (CRC) bytes
        if SerialReadBytes(Response[3], ByteCount + 2, FTimeoutMs) <> (ByteCount + 2) then
        begin
          SetError('Modbus RTU response payload timeout.');
          Exit;
        end;
        CRC := MB_CRC16(Response, 3 + ByteCount);
        ExpectedCRC := (Response[3 + ByteCount + 1] shl 8) or Response[3 + ByteCount];
        if CRC <> ExpectedCRC then
        begin
          SetError('Modbus RTU CRC mismatch.');
          Exit;
        end;
        ResponsePDULen := 2 + ByteCount; // FunctCode + ByteCount + data
      end
      else
      begin
        // FC05, FC06, FC16 have 8 bytes response total. We read 3, need to read 5 more.
        if SerialReadBytes(Response[3], 5, FTimeoutMs) <> 5 then
        begin
          SetError('Modbus RTU response payload timeout.');
          Exit;
        end;
        CRC := MB_CRC16(Response, 6);
        ExpectedCRC := (Response[7] shl 8) or Response[6];
        if CRC <> ExpectedCRC then
        begin
          SetError('Modbus RTU CRC mismatch.');
          Exit;
        end;
        ResponsePDULen := 5; // FunctCode + Addr/Count (4 bytes)
      end;
      
      for I := 0 to ResponsePDULen - 1 do
        ResponsePDU[I] := Response[1 + I];
        
      Result := True;
    except
      on E: Exception do SetError('Modbus RTU Exception: ' + E.Message);
    end;
  end;
end;

function TAIModbusClient.ReadCoils(SlaveID, Address, Count: Integer; out AData: array of Boolean): Boolean;
var
  Req: array[0..4] of Byte;
  Resp: array[0..255] of Byte;
  RespLen: Integer;
begin
  Req[0] := 1; // Function code
  Req[1] := Hi(Address);
  Req[2] := Lo(Address);
  Req[3] := Hi(Count);
  Req[4] := Lo(Count);
  Result := ExecuteTransaction(SlaveID, 1, Req, 5, Resp, RespLen);
  if Result then
    UnpackBits(Resp, 2, Count, AData);
end;

function TAIModbusClient.ReadDiscreteInputs(SlaveID, Address, Count: Integer; out AData: array of Boolean): Boolean;
var
  Req: array[0..4] of Byte;
  Resp: array[0..255] of Byte;
  RespLen: Integer;
begin
  Req[0] := 2; // Function code
  Req[1] := Hi(Address);
  Req[2] := Lo(Address);
  Req[3] := Hi(Count);
  Req[4] := Lo(Count);
  Result := ExecuteTransaction(SlaveID, 2, Req, 5, Resp, RespLen);
  if Result then
    UnpackBits(Resp, 2, Count, AData);
end;

function TAIModbusClient.ReadHoldingRegisters(SlaveID, Address, Count: Integer; out AData: array of Word): Boolean;
var
  Req: array[0..4] of Byte;
  Resp: array[0..255] of Byte;
  RespLen, I: Integer;
begin
  Req[0] := 3; // Function code
  Req[1] := Hi(Address);
  Req[2] := Lo(Address);
  Req[3] := Hi(Count);
  Req[4] := Lo(Count);
  Result := ExecuteTransaction(SlaveID, 3, Req, 5, Resp, RespLen);
  if Result then
  begin
    for I := 0 to Count - 1 do
    begin
      if I <= High(AData) then
        AData[I] := (Resp[2 + I * 2] shl 8) or Resp[2 + I * 2 + 1];
    end;
  end;
end;

function TAIModbusClient.ReadInputRegisters(SlaveID, Address, Count: Integer; out AData: array of Word): Boolean;
var
  Req: array[0..4] of Byte;
  Resp: array[0..255] of Byte;
  RespLen, I: Integer;
begin
  Req[0] := 4; // Function code
  Req[1] := Hi(Address);
  Req[2] := Lo(Address);
  Req[3] := Hi(Count);
  Req[4] := Lo(Count);
  Result := ExecuteTransaction(SlaveID, 4, Req, 5, Resp, RespLen);
  if Result then
  begin
    for I := 0 to Count - 1 do
    begin
      if I <= High(AData) then
        AData[I] := (Resp[2 + I * 2] shl 8) or Resp[2 + I * 2 + 1];
    end;
  end;
end;

function TAIModbusClient.WriteSingleCoil(SlaveID, Address: Integer; Value: Boolean): Boolean;
var
  Req: array[0..4] of Byte;
  Resp: array[0..255] of Byte;
  RespLen: Integer;
begin
  Req[0] := 5; // Function code
  Req[1] := Hi(Address);
  Req[2] := Lo(Address);
  if Value then
  begin
    Req[3] := $FF;
    Req[4] := $00;
  end
  else
  begin
    Req[3] := $00;
    Req[4] := $00;
  end;
  Result := ExecuteTransaction(SlaveID, 5, Req, 5, Resp, RespLen);
end;

function TAIModbusClient.WriteSingleRegister(SlaveID, Address, Value: Integer): Boolean;
var
  Req: array[0..4] of Byte;
  Resp: array[0..255] of Byte;
  RespLen: Integer;
begin
  Req[0] := 6; // Function code
  Req[1] := Hi(Address);
  Req[2] := Lo(Address);
  Req[3] := Hi(Value);
  Req[4] := Lo(Value);
  Result := ExecuteTransaction(SlaveID, 6, Req, 5, Resp, RespLen);
end;

function TAIModbusClient.WriteMultipleRegisters(SlaveID, Address: Integer; const Values: array of Word): Boolean;
var
  Req: array[0..255] of Byte;
  Resp: array[0..255] of Byte;
  RespLen, Count, ByteCount, I: Integer;
begin
  Count := Length(Values);
  ByteCount := Count * 2;
  Req[0] := 16; // Function code
  Req[1] := Hi(Address);
  Req[2] := Lo(Address);
  Req[3] := Hi(Count);
  Req[4] := Lo(Count);
  Req[5] := ByteCount;
  for I := 0 to Count - 1 do
  begin
    Req[6 + I * 2] := Hi(Values[I]);
    Req[6 + I * 2 + 1] := Lo(Values[I]);
  end;
  Result := ExecuteTransaction(SlaveID, 16, Req, 6 + ByteCount, Resp, RespLen);
end;

initialization
  {$I aimodbus_icon.lrs}

end.
