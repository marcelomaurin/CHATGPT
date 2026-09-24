unit aivoicecredentialstore;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils,
  {$IFDEF MSWINDOWS}
  Windows,
  {$ENDIF}
  base64;

type
  { TVoiceCredentialStore: Secure credential storage helper for voice tokens }
  TVoiceCredentialStore = class
  private
    {$IFDEF MSWINDOWS}
    class function ProtectWinData(const AData: string): string;
    class function UnprotectWinData(const AEncData: string): string;
    {$ENDIF}
    class function Obfuscate(const S: string): string;
    class function Deobfuscate(const S: string): string;
  public
    class function ProtectToken(const APlainTextToken: string): string;
    class function UnprotectToken(const AProtectedToken: string): string;
  end;

implementation

{$IFDEF MSWINDOWS}
type
  PDATA_BLOB = ^DATA_BLOB;
  DATA_BLOB = record
    cbData: DWORD;
    pbData: PByte;
  end;

function CryptProtectData(pDataIn: PDATA_BLOB; szDataDescr: LPCWSTR; pOptionalEntropy: PDATA_BLOB;
  pvReserved: Pointer; pPromptStruct: Pointer; dwFlags: DWORD; pDataOut: PDATA_BLOB): BOOL; stdcall; external 'crypt32.dll';
function CryptUnprotectData(pDataIn: PDATA_BLOB; ppszDataDescr: PLPWSTR; pOptionalEntropy: PDATA_BLOB;
  pvReserved: Pointer; pPromptStruct: Pointer; dwFlags: DWORD; pDataOut: PDATA_BLOB): BOOL; stdcall; external 'crypt32.dll';

class function TVoiceCredentialStore.ProtectWinData(const AData: string): string;
var
  DataIn, DataOut: DATA_BLOB;
  RawBytes: AnsiString;
begin
  Result := '';
  if AData = '' then Exit;

  RawBytes := AnsiString(AData);
  DataIn.cbData := Length(RawBytes);
  DataIn.pbData := PByte(PAnsiChar(RawBytes));
  DataOut.cbData := 0;
  DataOut.pbData := nil;

  // CRYPTPROTECT_UI_FORBIDDEN = $01
  if CryptProtectData(@DataIn, nil, nil, nil, nil, $01, @DataOut) then
  begin
    try
      SetLength(RawBytes, DataOut.cbData);
      Move(DataOut.pbData^, RawBytes[1], DataOut.cbData);
      Result := 'dpapi:' + EncodeStringBase64(string(RawBytes));
    finally
      LocalFree(HLOCAL(DataOut.pbData));
    end;
  end;
end;

class function TVoiceCredentialStore.UnprotectWinData(const AEncData: string): string;
var
  DataIn, DataOut: DATA_BLOB;
  DecodedStr: string;
  RawBytes: AnsiString;
begin
  Result := '';
  if AEncData = '' then Exit;

  DecodedStr := DecodeStringBase64(AEncData);
  RawBytes := AnsiString(DecodedStr);
  DataIn.cbData := Length(RawBytes);
  DataIn.pbData := PByte(PAnsiChar(RawBytes));
  DataOut.cbData := 0;
  DataOut.pbData := nil;

  if CryptUnprotectData(@DataIn, nil, nil, nil, nil, $01, @DataOut) then
  begin
    try
      SetLength(RawBytes, DataOut.cbData);
      Move(DataOut.pbData^, RawBytes[1], DataOut.cbData);
      Result := string(RawBytes);
    finally
      LocalFree(HLOCAL(DataOut.pbData));
    end;
  end;
end;
{$ENDIF}

class function TVoiceCredentialStore.Obfuscate(const S: string): string;
var
  I: Integer;
  B: Byte;
  Res: string;
  Key: Byte;
begin
  Key := $5A;
  Res := '';
  for I := 1 to Length(S) do
  begin
    B := Byte(S[I]) xor Key;
    Res := Res + IntToHex(B, 2);
  end;
  Result := 'obf:' + Res;
end;

class function TVoiceCredentialStore.Deobfuscate(const S: string): string;
var
  I: Integer;
  HexByte: string;
  B: Byte;
  Key: Byte;
  CleanStr: string;
begin
  Result := '';
  CleanStr := S;
  if Copy(CleanStr, 1, 4) = 'obf:' then
    Delete(CleanStr, 1, 4);

  Key := $5A;
  I := 1;
  while I < Length(CleanStr) do
  begin
    HexByte := Copy(CleanStr, I, 2);
    try
      B := StrToInt('$' + HexByte) xor Key;
      Result := Result + Chr(B);
    except
      Exit('');
    end;
    Inc(I, 2);
  end;
end;

class function TVoiceCredentialStore.ProtectToken(const APlainTextToken: string): string;
begin
  if Trim(APlainTextToken) = '' then
    Exit('');

  {$IFDEF MSWINDOWS}
  try
    Result := ProtectWinData(APlainTextToken);
    if Result <> '' then Exit;
  except
  end;
  {$ENDIF}

  // Fallback to obfuscation
  Result := Obfuscate(APlainTextToken);
end;

class function TVoiceCredentialStore.UnprotectToken(const AProtectedToken: string): string;
var
  TokenTrimmed: string;
begin
  TokenTrimmed := Trim(AProtectedToken);
  if TokenTrimmed = '' then
    Exit('');

  {$IFDEF MSWINDOWS}
  if Copy(TokenTrimmed, 1, 6) = 'dpapi:' then
  begin
    try
      Result := UnprotectWinData(Copy(TokenTrimmed, 7, Length(TokenTrimmed) - 6));
      if Result <> '' then Exit;
    except
    end;
  end;
  {$ENDIF}

  if Copy(TokenTrimmed, 1, 4) = 'obf:' then
  begin
    Result := Deobfuscate(TokenTrimmed);
    Exit;
  end;

  // If not protected with prefix, treat as plain text (legacy migration support)
  Result := TokenTrimmed;
end;

end.
