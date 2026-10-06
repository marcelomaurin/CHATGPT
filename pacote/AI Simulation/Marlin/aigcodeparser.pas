unit aigcodeparser;
{$mode objfpc}{$H+}
interface
uses Classes, SysUtils, Math;
type
  TAIGCodeCommand = record
    Letter: Char;
    Code, LineNumber: Integer;
    HasLineNumber, HasChecksum, Empty: Boolean;
    Present: array['A'..'Z'] of Boolean;
    HasValue: array['A'..'Z'] of Boolean;
    Values: array['A'..'Z'] of Double;
  end;
  TAIGCodeParser = class(TComponent)
  public
    class function Parse(const Line: string; out Command: TAIGCodeCommand;
      out ErrorText: string): Boolean; static;
    class function Checksum(const Text: string): Byte; static;
  end;
function GCodeFloat(const Value: Double): string;
implementation
function GCodeFloat(const Value: Double): string;
var F: TFormatSettings;
begin
  F := DefaultFormatSettings; F.DecimalSeparator := '.';
  Result := FloatToStrF(Value, ffFixed, 15, 3, F);
end;
class function TAIGCodeParser.Checksum(const Text: string): Byte;
var I: Integer;
begin
  Result := 0;
  for I := 1 to Length(Text) do Result := Result xor Ord(Text[I]);
end;
class function TAIGCodeParser.Parse(const Line: string;
  out Command: TAIGCodeCommand; out ErrorText: string): Boolean;
var S, Clean, Token: string; I, Start, Star, Sum, Depth: Integer;
    Key: Char; V: Double; F: TFormatSettings;
  function Fail(const Msg: string): Boolean;
  begin ErrorText := Msg; Result := False; end;
  function Number(out N: Double): Boolean;
  begin
    Start := I;
    if (I <= Length(S)) and (S[I] in ['+', '-']) then Inc(I);
    while (I <= Length(S)) and (S[I] in ['0'..'9', '.']) do Inc(I);
    Token := Copy(S, Start, I - Start);
    Result := (Token <> '') and TryStrToFloat(Token, N, F);
    if Result then Result := not IsNan(N) and not IsInfinite(N) and (Abs(N) <= 1e9);
  end;
begin
  FillChar(Command, SizeOf(Command), 0);
  Command.Empty := True; ErrorText := ''; Result := False;
  if Length(Line) > 1024 then Exit(Fail('Line exceeds 1024 bytes'));
  S := Line; Star := 0; Depth := 0;
  for I := 1 to Length(S) do begin
    if S[I] in [#0, #10, #13] then Exit(Fail('Control character in line'));
    if S[I] = '(' then Inc(Depth);
    if S[I] = ')' then Dec(Depth);
    if (Depth = 0) and (S[I] = ';') then Break;
    if (Depth = 0) and (S[I] = '*') then begin Star := I; Break; end;
  end;
  if Star > 0 then begin
    Token := Copy(S, Star + 1, MaxInt);
    I := Pos(';', Token); if I > 0 then Delete(Token, I, MaxInt);
    if not TryStrToInt(Trim(Token), Sum) or (Sum < 0) or (Sum > 255) then
      Exit(Fail('Invalid checksum'));
    if Checksum(Copy(S, 1, Star - 1)) <> Sum then Exit(Fail('Checksum mismatch'));
    Command.HasChecksum := True; S := Copy(S, 1, Star - 1);
  end;
  Clean := ''; Depth := 0;
  for I := 1 to Length(S) do begin
    if (S[I] = ';') and (Depth = 0) then Break;
    if S[I] = '(' then begin Inc(Depth); Continue; end;
    if S[I] = ')' then begin
      Dec(Depth); if Depth < 0 then Exit(Fail('Unmatched comment')); Continue;
    end;
    if Depth = 0 then Clean := Clean + S[I];
  end;
  if Depth <> 0 then Exit(Fail('Unclosed comment'));
  S := UpperCase(Trim(Clean));
  if (S = '') or (S = '%') then Exit(True);
  F := DefaultFormatSettings; F.DecimalSeparator := '.'; I := 1;
  if S[I] = 'N' then begin
    Inc(I);
    if not Number(V) then Exit(Fail('Invalid line number'));
    if (V < 0) or (Frac(V) <> 0) then Exit(Fail('Invalid line number'));
    Command.HasLineNumber := True; Command.LineNumber := Round(V);
  end;
  while (I <= Length(S)) and (S[I] in [' ', #9]) do Inc(I);
  if (I > Length(S)) or not (S[I] in ['G', 'M', 'T']) then
    Exit(Fail('Expected G, M or T command'));
  Command.Letter := S[I]; Inc(I);
  if not Number(V) then Exit(Fail('Invalid command number'));
  if (V < 0) or (Frac(V) <> 0) then Exit(Fail('Subcodes are not supported'));
  Command.Code := Round(V); Command.Empty := False;
  while I <= Length(S) do begin
    if S[I] in [' ', #9] then begin Inc(I); Continue; end;
    Key := S[I]; Inc(I);
    if not (Key in ['A'..'Z']) then Exit(Fail('Invalid parameter'));
    if Command.Present[Key] then Exit(Fail('Duplicate parameter'));
    Command.Present[Key] := True;
    while (I <= Length(S)) and (S[I] in [' ', #9]) do Inc(I);
    if (I > Length(S)) or (S[I] in ['A'..'Z']) then V := 0
    else begin
      if not Number(V) then Exit(Fail('Invalid parameter value'));
      Command.HasValue[Key] := True;
    end;
    Command.Values[Key] := V;
  end;
  Result := True;
end;
end.
