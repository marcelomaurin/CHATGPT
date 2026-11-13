unit aideviceidentifier;

{$mode objfpc}{$H+}

interface

uses Classes, SysUtils, LResources;

type
  TAIDeviceKind = (dkArduinoMega, dkArduinoUno, dkESP32, dkESP8266,
    dkRS485, dkSerial, dkMouse, dkKeyboard, dkWebcam, dkOthers);
  TAIDeviceInfo = record
    DeviceID, HardwareID, VendorID, ProductID, Description, DeviceClass,
      Port: string;
    Kind: TAIDeviceKind;
  end;
  TAIDeviceArray = array of TAIDeviceInfo;
  TAISerialBindings = array[0..2] of string;
  TAISerialMatches = array[0..2] of Integer;
  TAIFirmwareEvidence = record
    Confirmed: Boolean;
    Kind: TAIDeviceKind;
    Line, Detail: string;
  end;
  TAIFirmwareEvidenceArray = array of TAIFirmwareEvidence;
  TAIFirmwareParser = class
  private
    FPending: string;
    FLCCount, FPOSCount, FStatusCount, FPesoCount: Integer;
    FEvidence: TAIFirmwareEvidence;
    procedure ParseLine(const Line: string);
  public
    procedure Feed(const Bytes: string);
    property Evidence: TAIFirmwareEvidence read FEvidence;
  end;
  TAIDeviceIdentifier = class(TComponent)
  private
    FDevices: TAIDeviceArray;
  public
    procedure Refresh;
    function ConfirmRS485Status(const Port: string;
      TimeoutMs: Cardinal = 800): TAIFirmwareEvidence;
    function ConfirmSerialFirmware(const Port: string;
      TimeoutMs: Cardinal = 3000): TAIFirmwareEvidence;
    property Devices: TAIDeviceArray read FDevices;
  end;

function AIIsCH340(const Device: TAIDeviceInfo): Boolean;
function AIModbusCRC(const Data: RawByteString): Word;
function AIParseMotorStatus(const Response: RawByteString; out Status: Word): Boolean;
function AIIsCH9102(const Device: TAIDeviceInfo): Boolean;
function AIDeviceKindName(AKind: TAIDeviceKind): string;
function AIClassifyDevice(const HardwareID, Description, DeviceClass,
  Port: string): TAIDeviceKind;
function AIResolveSerialRoles(const Devices: TAIDeviceArray;
  const Bindings: TAISerialBindings): TAISerialMatches;
function AIResolveConfirmedSerialRoles(const Devices: TAIDeviceArray;
  const Bindings: TAISerialBindings;
  const Evidence: TAIFirmwareEvidenceArray;
  AllowCH9102Fallback: Boolean = False;
  AllowRemainingCH340Fallback: Boolean = False): TAISerialMatches;
procedure Register;

implementation

{$IFDEF WINDOWS}
uses Windows;

{$PACKRECORDS C}
type
  TDeviceData = record
    cbSize: DWORD;
    ClassGuid: TGUID;
    DevInst: DWORD;
    Reserved: PtrUInt;
  end;
function SetupDiGetClassDevsW(Guid, Enumerator: Pointer; Parent: HWND;
  Flags: DWORD): THandle; stdcall; external 'setupapi.dll';
function SetupDiEnumDeviceInfo(H: THandle; Index: DWORD;
  var Data: TDeviceData): BOOL; stdcall; external 'setupapi.dll';
function SetupDiDestroyDeviceInfoList(H: THandle): BOOL; stdcall; external 'setupapi.dll';
function SetupDiGetDeviceRegistryPropertyW(H: THandle; var Data: TDeviceData;
  Prop: DWORD; PropType: Pointer; Buffer: Pointer; Size: DWORD;
  Required: Pointer): BOOL; stdcall; external 'setupapi.dll';
function SetupDiGetDeviceInstanceIdW(H: THandle; var Data: TDeviceData;
  Buffer: PWideChar; Size: DWORD; Required: Pointer): BOOL;
  stdcall; external 'setupapi.dll';
function SetupDiOpenDevRegKey(H: THandle; var Data: TDeviceData;
  Scope, Profile, KeyType, Access: DWORD): HKEY; stdcall; external 'setupapi.dll';

function ReadProperty(H: THandle; var Data: TDeviceData; Prop: DWORD): string;
var
  Needed, I: DWORD;
  Buf: array of WideChar;
begin
  Result := '';
  Needed := 0;
  SetupDiGetDeviceRegistryPropertyW(H, Data, Prop, nil, nil, 0, @Needed);
  if Needed = 0 then Exit;
  SetLength(Buf, Needed div SizeOf(WideChar) + 1);
  if not SetupDiGetDeviceRegistryPropertyW(H, Data, Prop, nil, @Buf[0],
    Needed, nil) then Exit;
  // Preserve every hardware ID in REG_MULTI_SZ, not only the first one.
  for I := 0 to Needed div SizeOf(WideChar) - 1 do
    if Buf[I] = #0 then Buf[I] := ' ';
  Result := Trim(UTF8Encode(UnicodeString(PWideChar(@Buf[0]))));
end;
{$ENDIF}

function AIIsCH340(const Device: TAIDeviceInfo): Boolean;
begin
  Result := (SameText(Device.VendorID,'1A86') and SameText(Device.ProductID,'7523')) or
    ((Pos('VID_1A86',UpperCase(Device.HardwareID)) > 0) and
     (Pos('PID_7523',UpperCase(Device.HardwareID)) > 0));
end;

function AIIsCH9102(const Device: TAIDeviceInfo): Boolean;
begin
  Result := (SameText(Device.VendorID, '1A86') and SameText(Device.ProductID, '55D4')) or
    ((Pos('VID_1A86', UpperCase(Device.HardwareID)) > 0) and
     (Pos('PID_55D4', UpperCase(Device.HardwareID)) > 0));
end;

function AIDeviceKindName(AKind: TAIDeviceKind): string;
const Names: array[TAIDeviceKind] of string = ('Arduino Mega', 'Arduino Uno',
  'ESP32', 'ESP8266', 'RS485', 'Serial', 'Mouse', 'Keyboard', 'Webcam', 'Others');
begin
  Result := Names[AKind];
end;

function AIClassifyDevice(const HardwareID, Description, DeviceClass,
  Port: string): TAIDeviceKind;
var H, D, C: string;
begin
  H := UpperCase(HardwareID);
  D := UpperCase(Description);
  C := UpperCase(DeviceClass);
  if C = 'MOUSE' then Exit(dkMouse);
  if C = 'KEYBOARD' then Exit(dkKeyboard);
  if (C = 'CAMERA') or ((C = 'IMAGE') and
    ((Pos('WEBCAM', D) > 0) or (Pos('CAMERA', D) > 0))) then Exit(dkWebcam);
  if ((Pos('VID_2341', H) > 0) or (Pos('VID_2A03', H) > 0)) then
  begin
    if (Pos('PID_0042', H) > 0) or (Pos('PID_0010', H) > 0) then Exit(dkArduinoMega);
    if (Pos('PID_0043', H) > 0) or (Pos('PID_0001', H) > 0) then Exit(dkArduinoUno);
  end;
  if Pos('ARDUINO', D) > 0 then
  begin
    if Pos('MEGA', D) > 0 then Exit(dkArduinoMega);
    if Pos('UNO', D) > 0 then Exit(dkArduinoUno);
  end;
  if Pos('ESP32', D) > 0 then Exit(dkESP32);
  if Pos('ESP8266', D) > 0 then Exit(dkESP8266);
  if (Pos('RS485', D) > 0) or (Pos('RS-485', D) > 0) or
    (Pos('RS 485', D) > 0) then Exit(dkRS485);
  // USB UART chips do not identify the board or electrical RS485 interface.
  if (Port <> '') or (C = 'PORTS') then Exit(dkSerial);
  Result := dkOthers;
end;

function AIResolveSerialRoles(const Devices: TAIDeviceArray;
  const Bindings: TAISerialBindings): TAISerialMatches;
const Kinds: array[0..2] of TAIDeviceKind = (dkArduinoMega, dkESP32, dkRS485);
var R, I, J, N, Candidate: Integer;
  Proposed: TAISerialMatches;
begin
  for R := 0 to 2 do Result[R] := -1;
  // Resolve saved identities first. A missing bound device must not be replaced.
  for R := 0 to 2 do
  begin
    N := 0; Candidate := -1;
    for I := 0 to High(Devices) do
      if Devices[I].Port <> '' then
        if ((Bindings[R] <> '') and SameText(Bindings[R], Devices[I].DeviceID)) or
          ((Bindings[R] = '') and (Devices[I].Kind = Kinds[R])) then
        begin Inc(N); Candidate := I; end;
    if N = 1 then Result[R] := Candidate;
  end;
  // Never assign a device or COM port to two roles, including corrupt bindings.
  Proposed := Result;
  for R := 0 to 2 do
    for J := R + 1 to 2 do
      if (Proposed[R] >= 0) and (Proposed[J] >= 0) and
        SameText(Devices[Proposed[R]].Port, Devices[Proposed[J]].Port) then
      begin Result[R] := -1; Result[J] := -1; end;
end;

procedure TAIDeviceIdentifier.Refresh;
{$IFDEF WINDOWS}
var H: THandle; Key: HKEY; Data: TDeviceData; Index, Size, RegType: DWORD;
  Buf: array[0..4095] of WideChar; D: TAIDeviceInfo; P: Integer;
begin
  SetLength(FDevices, 0);
  H := SetupDiGetClassDevsW(nil, nil, 0, $2 or $4); // PRESENT | ALLCLASSES
  if H = INVALID_HANDLE_VALUE then RaiseLastOSError;
  try
    Index := 0;
    while True do
    begin
      FillChar(Data, SizeOf(Data), 0); Data.cbSize := SizeOf(Data);
      if not SetupDiEnumDeviceInfo(H, Index, Data) then
      begin
        if GetLastError <> ERROR_NO_MORE_ITEMS then RaiseLastOSError;
        Break;
      end;
      Inc(Index);
      D := Default(TAIDeviceInfo);
      FillChar(Buf, SizeOf(Buf), 0);
      if not SetupDiGetDeviceInstanceIdW(H, Data, @Buf[0], Length(Buf), nil) then
        RaiseLastOSError;
      D.DeviceID := UTF8Encode(UnicodeString(PWideChar(@Buf[0])));
      D.HardwareID := ReadProperty(H, Data, 1);
      D.Description := ReadProperty(H, Data, 12);
      if D.Description = '' then D.Description := ReadProperty(H, Data, 0);
      D.DeviceClass := ReadProperty(H, Data, 7);
      P := Pos('VID_', UpperCase(D.HardwareID));
      if P > 0 then D.VendorID := Copy(D.HardwareID, P + 4, 4);
      P := Pos('PID_', UpperCase(D.HardwareID));
      if P > 0 then D.ProductID := Copy(D.HardwareID, P + 4, 4);
      Key := SetupDiOpenDevRegKey(H, Data, 1, 0, 1, KEY_QUERY_VALUE);
      if Key <> HKEY(INVALID_HANDLE_VALUE) then
      try
        FillChar(Buf, SizeOf(Buf), 0); Size := SizeOf(Buf);
        if RegQueryValueExW(Key, 'PortName', nil, @RegType, @Buf[0], @Size) = ERROR_SUCCESS then
          if RegType = REG_SZ then D.Port := UTF8Encode(UnicodeString(PWideChar(@Buf[0])));
      finally RegCloseKey(Key); end;
      if (Copy(UpperCase(D.Port), 1, 3) <> 'COM') or
        (StrToIntDef(Copy(D.Port, 4, MaxInt), 0) <= 0) then D.Port := '';
      D.Kind := AIClassifyDevice(D.HardwareID, D.Description, D.DeviceClass, D.Port);
      SetLength(FDevices, Length(FDevices) + 1);
      FDevices[High(FDevices)] := D;
    end;
  finally SetupDiDestroyDeviceInfoList(H); end;
end;
{$ELSE}
begin
  SetLength(FDevices, 0);
  raise ENotSupportedException.Create('Device identification requires Windows.');
end;
{$ENDIF}

procedure TAIFirmwareParser.ParseLine(const Line: string);
var S, Token: string; J: Integer; Parts: TStringList; N, Stamp, Value: Int64;
  X: Double; FS: TFormatSettings; Valid: Boolean;
begin
  if FEvidence.Confirmed then Exit;
  S := Trim(Line);
  if S <> '' then FEvidence.Line := Copy(S, 1, 512);
  if (Pos('# LEITOR_ESP32 FW=', S) = 1) and
    (Pos(' ADC=HX711', S) > Length('# LEITOR_ESP32 FW=')) then
  begin FEvidence.Kind := dkESP32; FEvidence.Confirmed := True; end
  else if (Pos('INFO FW=', S) = 1) and (Pos(' ADC=HX711 SPS=', S) > 0) and
    (Pos(' STREAM=', S) > 0) and (Pos(' SEQ=', S) > 0) and
    (Pos(' SAT=', S) > 0) and (Pos(' TMO=', S) > 0) then
  begin FEvidence.Kind := dkESP32; FEvidence.Confirmed := True; end
  else if (Pos('# Analisador de Amortecedor v', S) = 1) and
    (Pos(' - Bezerra Suspensoes', S) > 0) then
  begin FEvidence.Kind := dkArduinoMega; FEvidence.Confirmed := True; end
  else if (Pos('PESO:', UpperCase(S)) = 1) or (Pos('PESO=', UpperCase(S)) = 1) then
  begin
    // Legacy balance firmware already supported by the acquisition engine.
    FS := DefaultFormatSettings; FS.DecimalSeparator := '.';
    Token := Trim(Copy(S, 6, MaxInt));
    Valid := Token <> '';
    for J := 1 to Length(Token) do
      if not (Token[J] in ['0'..'9', '-', '+', '.', ',']) then Valid := False;
    if Valid then Valid := TryStrToFloat(StringReplace(Token, ',', '.', []), X, FS);
    if Valid and (X >= -2147483648.0) and (X <= 2147483647.0) then Inc(FPesoCount)
    else FPesoCount := 0;
    if FPesoCount >= 3 then
    begin
      FEvidence.Kind := dkESP32; FEvidence.Confirmed := True;
    end;
  end
  else if (Pos('LC=', S) = 1) or (Pos('POS=', S) = 1) then
  begin
    Parts := TStringList.Create;
    try
      Parts.StrictDelimiter := True; Parts.Delimiter := ',';
      Parts.DelimitedText := Copy(S, Pos('=', S) + 1, MaxInt);
      Valid := False;
      if (Parts.Count = 3) or (Parts.Count = 4) then
        Valid := TryStrToInt64(Parts[0], N) and (N >= 0) and (N <= High(LongWord)) and
          TryStrToInt64(Parts[1], Stamp) and (Stamp >= 0) and (Stamp <= High(LongWord)) and
          TryStrToInt64(Parts[2], Value);
      if Valid and (Copy(S, 1, 3) = 'LC=') and (Parts.Count = 3) and
        (Value >= -8388608) and (Value <= 8388607) then Inc(FLCCount);
      FS := DefaultFormatSettings; FS.DecimalSeparator := '.';
      if Valid and (Copy(S, 1, 4) = 'POS=') and (Parts.Count = 4) and
        (Value >= 0) and (Value <= 1023) and TryStrToFloat(Parts[3], X, FS) and
        (X >= -100000) and (X <= 100000) then Inc(FPOSCount);
      if FLCCount >= 3 then
      begin FEvidence.Kind := dkESP32; FEvidence.Confirmed := True; end;
      if FPOSCount >= 3 then
      begin FEvidence.Kind := dkArduinoMega; FEvidence.Confirmed := True; end;
    finally Parts.Free; end;
  end
  else if (Pos('[ATUADOR] ADC=', S) = 1) and
    (Pos(' | [BOTOEIRA] ADC=', S) > 0) and (Pos(' | [MOTORCMD]', S) > 0) then
  begin
    Inc(FStatusCount);
    if FStatusCount >= 2 then
    begin FEvidence.Kind := dkArduinoMega; FEvidence.Confirmed := True; end;
  end;
  if FEvidence.Confirmed then
  begin FEvidence.Line := S; FEvidence.Detail := 'Firmware confirmado pela saida serial'; end;
end;

procedure TAIFirmwareParser.Feed(const Bytes: string);
var I: Integer; C: Char;
begin
  for I := 1 to Length(Bytes) do
  begin
    C := Bytes[I];
    if C in [#10, #13] then
    begin
      if FPending <> '' then ParseLine(FPending);
      FPending := '';
    end
    else if (Ord(C) >= 32) and (Ord(C) <= 126) then
    begin
      FPending := FPending + C;
      if Length(FPending) > 2048 then FPending := '';
    end
    else FPending := ''; // Discard noise from another baud rate or boot ROM.
  end;
end;

function TAIDeviceIdentifier.ConfirmSerialFirmware(const Port: string;
  TimeoutMs: Cardinal): TAIFirmwareEvidence;
{$IFDEF WINDOWS}
var H: THandle; DCB, OriginalDCB: TDCB; Timeouts, OriginalTimeouts: TCOMMTIMEOUTS;
  Parser: TAIFirmwareParser; Buffer: array[0..1023] of Char;
  BytesRead, BytesWritten: DWORD; Started: QWord; S, Query: string;
  SavedDCB, SavedTimeouts, Queried: Boolean;
begin
  Result := Default(TAIFirmwareEvidence);
  Result.Kind := dkOthers;
  if (Copy(UpperCase(Port), 1, 3) <> 'COM') or
    (StrToIntDef(Copy(Port, 4, MaxInt), 0) <= 0) then
  begin Result.Detail := 'Porta invalida'; Exit; end;
  H := CreateFile(PChar('\\.\' + Port), GENERIC_READ or GENERIC_WRITE,
    0, nil, OPEN_EXISTING, 0, 0);
  if H = INVALID_HANDLE_VALUE then
  begin Result.Detail := 'Porta ocupada ou indisponivel: ' + SysErrorMessage(GetLastError); Exit; end;
  Parser := TAIFirmwareParser.Create;
  SavedDCB := False; SavedTimeouts := False;
  try
    FillChar(DCB, SizeOf(DCB), 0); DCB.DCBlength := SizeOf(DCB);
    if not GetCommState(H, DCB) then RaiseLastOSError;
    OriginalDCB := DCB; SavedDCB := True;
    if not GetCommTimeouts(H, OriginalTimeouts) then RaiseLastOSError;
    SavedTimeouts := True;
    DCB.BaudRate := 115200; DCB.ByteSize := 8;
    DCB.Parity := NOPARITY; DCB.StopBits := ONESTOPBIT;
    // Preserve DTR/RTS levels: do not request a reset or bootloader transition.
    DCB.Flags := (DCB.Flags and (($3 shl 4) or ($3 shl 12))) or 1;
    if not SetCommState(H, DCB) then RaiseLastOSError;
    FillChar(Timeouts, SizeOf(Timeouts), 0);
    Timeouts.WriteTotalTimeoutConstant := 200;
    Timeouts.ReadIntervalTimeout := MAXDWORD; // Nonblocking receive.
    if not SetCommTimeouts(H, Timeouts) then RaiseLastOSError;
    Started := GetTickCount64; Queried := False; Query := 'INFO' + #13#10;
    repeat
      if not ReadFile(H, Buffer, SizeOf(Buffer), BytesRead, nil) then RaiseLastOSError;
      if BytesRead > 0 then
      begin
        SetString(S, PChar(@Buffer[0]), BytesRead);
        Parser.Feed(S);
        if Parser.Evidence.Confirmed then Break;
      end
      else Sleep(10);
      if not Queried and (GetTickCount64 - Started >= 1200) then
      begin
        // Firmware read-only query; never START, STOP or motor commands.
        Queried := True;
        if not WriteFile(H, Query[1], Length(Query), BytesWritten, nil) then RaiseLastOSError;
        if BytesWritten <> DWORD(Length(Query)) then
          raise Exception.Create('Consulta INFO incompleta');
      end;
    until GetTickCount64 - Started >= TimeoutMs;
    Result := Parser.Evidence;
    if not Result.Confirmed then Result.Detail := 'Sem assinatura do firmware em 115200 baud';
  finally
    if SavedDCB then SetCommState(H, OriginalDCB);
    if SavedTimeouts then SetCommTimeouts(H, OriginalTimeouts);
    Parser.Free;
    CloseHandle(H);
  end;
end;
{$ELSE}
begin
  Result := Default(TAIFirmwareEvidence);
  Result.Detail := 'Confirmacao serial requer Windows';
end;
{$ENDIF}

function AIResolveConfirmedSerialRoles(const Devices: TAIDeviceArray;
  const Bindings: TAISerialBindings;
  const Evidence: TAIFirmwareEvidenceArray;
  AllowCH9102Fallback: Boolean;
  AllowRemainingCH340Fallback: Boolean): TAISerialMatches;
const Kinds: array[0..2] of TAIDeviceKind = (dkArduinoMega, dkESP32, dkRS485);
var R, I, Count, Candidate, Bound: Integer;
begin
  Result := AIResolveSerialRoles(Devices, Bindings);
  for R := 0 to 2 do
  begin
    Count := 0; Candidate := -1; Bound := -1;
    for I := 0 to High(Devices) do
      if (I < Length(Evidence)) and (Devices[I].Port <> '') and
        Evidence[I].Confirmed and (Evidence[I].Kind = Kinds[R]) then
      begin
        Inc(Count); Candidate := I;
        if (Bindings[R] <> '') and SameText(Devices[I].DeviceID, Bindings[R]) then Bound := I;
      end;
    Result[R] := -1;
    if Count = 1 then Result[R] := Candidate
    else if Bound >= 0 then Result[R] := Bound;
  end;
  // Application opt-in for the installation whose balance is known to use CH9102.
  // Do not turn a hardware-ID match into a firmware confirmation.
  if AllowCH9102Fallback and (Result[1] < 0) then
  begin
    Count := 0; Candidate := -1; Bound := -1;
    for I := 0 to High(Devices) do
      if (Devices[I].Port <> '') and AIIsCH9102(Devices[I]) and
        ((I >= Length(Evidence)) or not Evidence[I].Confirmed or
          (Evidence[I].Kind = dkESP32)) then
      begin
        Inc(Count); Candidate := I;
        if (Bindings[1] <> '') and SameText(Devices[I].DeviceID, Bindings[1]) then Bound := I;
      end;
    if Count = 1 then Result[1] := Candidate
    else if Bound >= 0 then Result[1] := Bound;
  end;
  // Plant-specific opt-in: choose the remaining CH340 after identifying the Mega.
  // This selects a port by exclusion without claiming that Modbus responded.
  if AllowRemainingCH340Fallback and (Result[2] < 0) and (Result[0] >= 0) then
  begin
    Count := 0; Candidate := -1; Bound := -1;
    for I := 0 to High(Devices) do
      if (Devices[I].Port <> '') and AIIsCH340(Devices[I]) and
        (Devices[I].Kind in [dkSerial, dkRS485]) and
        not SameText(Devices[I].Port, Devices[Result[0]].Port) and
        ((Result[1] < 0) or not SameText(Devices[I].Port, Devices[Result[1]].Port)) and
        ((I >= Length(Evidence)) or not Evidence[I].Confirmed or (Evidence[I].Kind = dkRS485)) then
      begin
        Inc(Count); Candidate := I;
        if (Bindings[2] <> '') and SameText(Devices[I].DeviceID, Bindings[2]) then Bound := I;
      end;
    if Count = 1 then Result[2] := Candidate
    else if Bound >= 0 then Result[2] := Bound;
  end;
  // A firmware-confirmed controller can never be the external RS485 adapter.
  if (Result[2] >= 0) and (Result[2] < Length(Evidence)) and Evidence[Result[2]].Confirmed and
    (Evidence[Result[2]].Kind <> dkRS485) then
    Result[2] := -1;
  for R := 0 to 1 do
    if (Result[R] >= 0) and (Result[2] >= 0) and
      SameText(Devices[Result[R]].Port, Devices[Result[2]].Port) then Result[2] := -1;
end;

function AIModbusCRC(const Data: RawByteString): Word;
var I, J: Integer;
begin
  Result := $FFFF;
  for I := 1 to Length(Data) do
  begin
    Result := Result xor Byte(Data[I]);
    for J := 0 to 7 do
      if Result and 1 <> 0 then Result := (Result shr 1) xor $A001
      else Result := Result shr 1;
  end;
end;

function AIParseMotorStatus(const Response: RawByteString;
  out Status: Word): Boolean;
var CRC: Word;
begin
  Status := 0; Result := False;
  if Length(Response) <> 7 then Exit;
  if (Byte(Response[1]) <> 1) or (Byte(Response[2]) <> 3) or
    (Byte(Response[3]) <> 2) then Exit;
  CRC := AIModbusCRC(Copy(Response, 1, 5));
  if (Byte(Response[6]) <> (CRC and $FF)) or
    (Byte(Response[7]) <> (CRC shr 8)) then Exit;
  Status := Word(Byte(Response[4])) shl 8 or Byte(Response[5]);
  // Register $3000 of the supported inverter: forward, reverse, stopped.
  Result := Status in [1, 2, 3];
end;

function TAIDeviceIdentifier.ConfirmRS485Status(const Port: string;
  TimeoutMs: Cardinal): TAIFirmwareEvidence;
{$IFDEF WINDOWS}
var H: THandle; DCB, OldDCB: TDCB; T, OldT: TCOMMTIMEOUTS;
  SavedDCB, SavedT: Boolean; Req, Received, Frame: RawByteString;
  CRC, Status: Word; Count, Written: DWORD; Buf: array[0..63] of Char;
  Started: QWord; I: Integer; State: string;
begin
  Result := Default(TAIFirmwareEvidence); Result.Kind := dkRS485;
  if (Copy(UpperCase(Port),1,3) <> 'COM') or
    (StrToIntDef(Copy(Port,4,MaxInt),0) <= 0) then
  begin Result.Detail := 'Porta invalida'; Exit; end;
  H := CreateFile(PChar('\\.\' + Port), GENERIC_READ or GENERIC_WRITE,
    0, nil, OPEN_EXISTING, 0, 0);
  if H = INVALID_HANDLE_VALUE then
  begin Result.Detail := 'Porta ocupada ou indisponivel: ' + SysErrorMessage(GetLastError); Exit; end;
  SavedDCB := False; SavedT := False;
  try
    FillChar(DCB,SizeOf(DCB),0); DCB.DCBlength := SizeOf(DCB);
    if not GetCommState(H,DCB) then RaiseLastOSError;
    OldDCB := DCB; SavedDCB := True;
    if not GetCommTimeouts(H,OldT) then RaiseLastOSError;
    SavedT := True;
    DCB.BaudRate := 9600; DCB.ByteSize := 8; DCB.Parity := NOPARITY;
    DCB.StopBits := ONESTOPBIT; // Same setting as the application's direct motor connection.
    DCB.Flags := (DCB.Flags and (($3 shl 4) or ($3 shl 12))) or 1;
    if not SetCommState(H,DCB) then RaiseLastOSError;
    FillChar(T,SizeOf(T),0); T.ReadIntervalTimeout := MAXDWORD;
    T.WriteTotalTimeoutConstant := 200;
    if not SetCommTimeouts(H,T) then RaiseLastOSError;
    PurgeComm(H,PURGE_RXCLEAR);
    Sleep(5); // RTU silent interval at 9600 baud.
    Req := #1#3#$30#0#0#1; // Read holding register $3000, slave 1, quantity 1.
    CRC := AIModbusCRC(Req); Req := Req + Char(CRC and $FF) + Char(CRC shr 8);
    if not WriteFile(H,Req[1],Length(Req),Written,nil) then RaiseLastOSError;
    if Written <> DWORD(Length(Req)) then
    begin Result.Detail := 'Consulta de status incompleta'; Exit; end;
    Started := GetTickCount64; Received := '';
    repeat
      if not ReadFile(H,Buf,SizeOf(Buf),Count,nil) then RaiseLastOSError;
      if Count > 0 then
      begin
        SetString(Frame,PChar(@Buf[0]),Count); Received := Received + Frame;
        for I := 1 to Length(Received)-6 do
          if AIParseMotorStatus(Copy(Received,I,7),Status) then
          begin
            case Status of 1: State := 'Frente'; 2: State := 'Reverso'; 3: State := 'Parado'; end;
            Result.Confirmed := True;
            Result.Line := 'Modbus slave=1 func=03 reg=$3000 status=$' + IntToHex(Status,4) + ' (' + State + ')';
            Result.Detail := 'Inversor RS485 confirmado por resposta de status com CRC valido';
            Exit;
          end;
        if Length(Received) > 128 then Delete(Received,1,Length(Received)-64);
      end
      else Sleep(10);
    until GetTickCount64-Started >= TimeoutMs;
    Result.Detail := 'Sem resposta valida ao status Modbus (9600 8N1, slave 1, reg=$3000)';
  finally
    if SavedDCB then SetCommState(H,OldDCB);
    if SavedT then SetCommTimeouts(H,OldT);
    CloseHandle(H);
  end;
end;
{$ELSE}
begin
  Result := Default(TAIFirmwareEvidence);
  Result.Detail := 'Confirmacao RS485 requer Windows';
end;
{$ENDIF}

procedure Register;
begin
  RegisterComponents('AI Hardware', [TAIDeviceIdentifier]);
end;

initialization
  {$I aideviceidentifier_icon.lrs}

end.
