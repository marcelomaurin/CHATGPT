unit aiprinter_bytebuilder;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, LConvEncoding, aiprinter_types;

type
  { TAIByteBuilder }

  TAIByteBuilder = class
  private
    FBytes: TBytes;
    FLength: Integer;
    procedure EnsureCapacity(ACapacity: Integer);
  public
    constructor Create;
    destructor Destroy; override;
    
    procedure Clear;
    procedure AddByte(B: Byte);
    procedure AddBytes(const ABytes: TBytes);
    procedure AddAscii(const S: RawByteString);
    procedure AddTextEncoded(const S: string; AEncoding: TPrinterEncoding);
    
    function ToBytes: TBytes;
  end;

function BytesToHex(const ABytes: TBytes): string;
function HexToBytes(const AHex: string): TBytes;

implementation

{ TAIByteBuilder }

constructor TAIByteBuilder.Create;
begin
  inherited Create;
  FLength := 0;
  SetLength(FBytes, 0);
end;

destructor TAIByteBuilder.Destroy;
begin
  SetLength(FBytes, 0);
  inherited Destroy;
end;

procedure TAIByteBuilder.Clear;
begin
  FLength := 0;
  SetLength(FBytes, 0);
end;

procedure TAIByteBuilder.EnsureCapacity(ACapacity: Integer);
begin
  if Length(FBytes) < ACapacity then
  begin
    if Length(FBytes) = 0 then
      SetLength(FBytes, ACapacity + 128)
    else
      SetLength(FBytes, Length(FBytes) * 2 + ACapacity);
  end;
end;

procedure TAIByteBuilder.AddByte(B: Byte);
begin
  EnsureCapacity(FLength + 1);
  FBytes[FLength] := B;
  Inc(FLength);
end;


procedure TAIByteBuilder.AddBytes(const ABytes: TBytes);
var
  Len: Integer;
begin
  Len := Length(ABytes);
  if Len = 0 then Exit;
  EnsureCapacity(FLength + Len);
  Move(ABytes[0], FBytes[FLength], Len);
  Inc(FLength, Len);
end;

procedure TAIByteBuilder.AddAscii(const S: RawByteString);
var
  Len: Integer;
begin
  Len := Length(S);
  if Len = 0 then Exit;
  EnsureCapacity(FLength + Len);
  Move(S[1], FBytes[FLength], Len);
  Inc(FLength, Len);
end;

procedure TAIByteBuilder.AddTextEncoded(const S: string; AEncoding: TPrinterEncoding);
var Raw: RawByteString;
begin
  if S = '' then Exit;
  case AEncoding of
    peCP437:       Raw := UTF8ToCP437(S);
    peCP850:       Raw := UTF8ToCP850(S);
    peWindows1252: Raw := UTF8ToCP1252(S);
    peUTF8:        Raw := S;
  else             Raw := RawByteString(S);   // peRawAscii
  end;
  AddAscii(Raw);
end;

function TAIByteBuilder.ToBytes: TBytes;
var
  ResultBytes: TBytes;
begin
  SetLength(ResultBytes, FLength);
  if FLength > 0 then
    Move(FBytes[0], ResultBytes[0], FLength);
  Result := ResultBytes;
end;

function BytesToHex(const ABytes: TBytes): string;
var
  I: Integer;
  SB: TStringBuilder;
begin
  Result := '';
  if Length(ABytes) = 0 then Exit;
  SB := TStringBuilder.Create(Length(ABytes) * 4);
  try
    for I := 0 to Length(ABytes) - 1 do
    begin
      if I > 0 then SB.Append(' ');
      SB.Append(Format('$%02X', [ABytes[I]]));
    end;
    Result := SB.ToString;
  finally
    SB.Free;
  end;
end;

function HexToBytes(const AHex: string): TBytes;
var
  List: TStringList;
  I: Integer;
  S: string;
  Val: Integer;
begin
  SetLength(Result, 0);
  List := TStringList.Create;
  try
    List.Delimiter := ' ';
    List.DelimitedText := AHex;
    SetLength(Result, List.Count);
    for I := 0 to List.Count - 1 do
    begin
      S := Trim(List[I]);
      if (Length(S) > 1) and (S[1] = '$') then
        S := '0x' + Copy(S, 2, Length(S))
      else if (Length(S) > 1) and (S[1] = '#') then
        S := Copy(S, 2, Length(S));
      Val := StrToIntDef(S, 0);
      Result[I] := Byte(Val);
    end;
  finally
    List.Free;
  end;
end;

end.
