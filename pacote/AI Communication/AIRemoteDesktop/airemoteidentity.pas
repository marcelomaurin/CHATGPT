unit airemoteidentity;
{$mode objfpc}{$H+}
interface
uses Classes, SysUtils;
function AIRemoteRandomHex(Count: Integer): string;
function AIRemoteUUID: string;
procedure AIRemoteSaveSecret(const FileName, Value: string);
function AIRemoteLoadSecret(const FileName: string): string;
implementation
{$IFDEF WINDOWS}
uses Windows;
type
  TDataBlob = record
    cbData: DWORD;
    pbData: PByte;
  end;
function BCryptGenRandom(Algorithm: Pointer; Buffer: PByte; Size, Flags: ULONG): LongInt;
  stdcall; external 'bcrypt.dll';
function CryptProtectData(var Input: TDataBlob; Description: PWideChar; Entropy: Pointer;
  Reserved, Prompt: Pointer; Flags: DWORD; var Output: TDataBlob): BOOL;
  stdcall; external 'crypt32.dll';
function CryptUnprotectData(var Input: TDataBlob; Description: Pointer; Entropy: Pointer;
  Reserved, Prompt: Pointer; Flags: DWORD; var Output: TDataBlob): BOOL;
  stdcall; external 'crypt32.dll';
{$ENDIF}
function AIRemoteRandomHex(Count: Integer): string;
var B: array of Byte; I: Integer;
{$IFNDEF WINDOWS} F: TFileStream; {$ENDIF}
begin
  if (Count<1) or (Count>1024) then raise Exception.Create('Invalid random size');
  SetLength(B,Count);
  {$IFDEF WINDOWS}
  if BCryptGenRandom(nil,@B[0],Count,2)<>0 then raise Exception.Create('System random unavailable');
  {$ELSE}
  F:=TFileStream.Create('/dev/urandom',fmOpenRead or fmShareDenyNone);
  try F.ReadBuffer(B[0],Count); finally F.Free; end;
  {$ENDIF}
  Result:='';
  for I:=0 to Count-1 do Result:=Result+LowerCase(IntToHex(B[I],2));
end;
function AIRemoteUUID: string;
var H: string;
begin
  H:=AIRemoteRandomHex(16);
  H[13]:='4'; H[17]:='8';
  Result:=Copy(H,1,8)+'-'+Copy(H,9,4)+'-'+Copy(H,13,4)+'-'+Copy(H,17,4)+'-'+Copy(H,21,12);
end;
procedure AIRemoteSaveSecret(const FileName, Value: string);
{$IFDEF WINDOWS}
var A,B:TDataBlob; F:TFileStream; Temp:string;
{$ENDIF}
begin
  {$IFDEF WINDOWS}
  if Value='' then raise Exception.Create('Empty identity');
  A.cbData:=Length(Value); A.pbData:=PByte(PChar(Value));
  FillChar(B,SizeOf(B),0);
  if not CryptProtectData(A,nil,nil,nil,nil,1,B) then
    raise Exception.Create('Cannot protect identity');
  try
    if not ForceDirectories(ExtractFileDir(ExpandFileName(FileName))) then
      raise Exception.Create('Cannot create identity directory');
    Temp:=FileName+'.'+AIRemoteRandomHex(8)+'.tmp';
    try
      F:=TFileStream.Create(Temp,fmCreate);
      try F.WriteBuffer(B.pbData^,B.cbData); finally F.Free; end;
      if not MoveFileEx(PChar(Temp),PChar(FileName),MOVEFILE_REPLACE_EXISTING or $00000008) then
        raise Exception.Create('Cannot save protected identity');
    finally
      if FileExists(Temp) then SysUtils.DeleteFile(Temp);
    end;
  finally LocalFree(HLOCAL(B.pbData)); end;
  {$ELSE}
  raise Exception.Create('Secure identity storage backend not implemented on this platform');
  {$ENDIF}
end;
function AIRemoteLoadSecret(const FileName:string): string;
{$IFDEF WINDOWS}
var A,B:TDataBlob; Bytes:TBytes; F:TFileStream;
{$ENDIF}
begin
  {$IFDEF WINDOWS}
  F:=TFileStream.Create(FileName,fmOpenRead or fmShareDenyWrite);
  try
    if (F.Size<1) or (F.Size>65536) then raise Exception.Create('Invalid protected identity size');
    SetLength(Bytes,F.Size); F.ReadBuffer(Bytes[0],Length(Bytes));
  finally F.Free; end;
  A.cbData:=Length(Bytes); A.pbData:=@Bytes[0]; FillChar(B,SizeOf(B),0);
  if not CryptUnprotectData(A,nil,nil,nil,nil,1,B) then
    raise Exception.Create('Identity cannot be opened by this Windows user');
  try
    SetLength(Result,B.cbData);
    if B.cbData>0 then Move(B.pbData^,Result[1],B.cbData);
  finally LocalFree(HLOCAL(B.pbData)); end;
  {$ELSE}
  raise Exception.Create('Secure identity storage backend not implemented on this platform');
  {$ENDIF}
end;
end.
