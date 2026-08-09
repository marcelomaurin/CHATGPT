program fake_whisper;

{$mode objfpc}{$H+}

uses SysUtils;

var I: Integer; Audio: string;
begin
  Audio := '';
  for I := 1 to ParamCount - 1 do if ParamStr(I) = '-f' then Audio := ParamStr(I + 1);
  if Pos('_part_001', Audio) > 0 then Writeln('[00:00] ola mundo')
  else if Pos('_part_002', Audio) > 0 then Writeln('[00:01] mundo novamente')
  else if Pos('_part_003', Audio) > 0 then Writeln('[00:02] novamente fim')
  else Writeln('[00:00] fala reconhecida');
end.
