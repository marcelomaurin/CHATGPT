program fgx_parser_tests;

{$mode objfpc}{$H+}

uses
  SysUtils, fgx_pascal;

procedure Check(ACondition: Boolean; const AMessage: string);
begin
  if not ACondition then
  begin
    WriteLn('FAIL: ', AMessage);
    Halt(1);
  end;
end;

var
  Info: TPascalUnitInfo;
  I: Integer;
  HasClasses, HasSysUtils, HasMath: Boolean;
begin
  if ParamCount <> 1 then Halt(2);
  Info := ParsePascalUnit(ParamStr(1));
  try
    Check(Info.ParseErrors.Count = 0, 'parser reported an error');
    Check(SameText(Info.UnitName, 'parser_fixture'), 'unit name');
    HasClasses := False;
    HasSysUtils := False;
    HasMath := False;
    for I := 0 to Info.InterfaceUses.Count - 1 do
    begin
      HasClasses := HasClasses or SameText(Info.InterfaceUses[I].Name, 'Classes');
      HasSysUtils := HasSysUtils or SameText(Info.InterfaceUses[I].Name, 'SysUtils');
    end;
    for I := 0 to Info.ImplementationUses.Count - 1 do
      HasMath := HasMath or SameText(Info.ImplementationUses[I].Name, 'Math');
    Check(HasClasses and HasSysUtils and HasMath, 'uses clauses');
    Check(Info.PublicClasses.Count = 1, 'implementation class leaked');
    Check(SameText(Info.PublicClasses[0].Name, 'TVisibleComponent'), 'class name');
    Check(SameText(Info.PublicClasses[0].Ancestor, 'TComponent'), 'ancestor');
    Check(Info.Registrations.Count = 1, 'registration count');
    Check(SameText(Info.Registrations[0].Palette, 'AI Tests'), 'palette');
    Check(SameText(Info.Registrations[0].ClassName, 'TVisibleComponent'), 'registered class');
    WriteLn('PASS');
  finally
    Info.Free;
  end;
end.
