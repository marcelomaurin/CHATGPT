program marlin_console;
{$mode objfpc}{$H+}
uses Classes, SysUtils, aimarlinsimulator;
type
  TConsole = class
    procedure Response(Sender: TObject; const Text: string);
  end;
procedure TConsole.Response(Sender: TObject; const Text: string);
begin Write(Text); end;
var Sim: TAIMarlinSimulator; Console: TConsole; Line: string; Steps: Integer;
begin
  Sim := TAIMarlinSimulator.Create(nil); Console := TConsole.Create;
  try
    Sim.OnResponse := @Console.Response;
    Sim.Reset;
    while not EOF(Input) do begin
      ReadLn(Line);
      Sim.SubmitLine(Line);
      Steps := 0;
      repeat
        Sim.Advance(0.02); Inc(Steps);
      until Sim.IsIdle or Sim.State.Killed or (Steps >= 180000);
      if not Sim.IsIdle then begin Writeln(StdErr,'Simulation time limit exceeded'); Halt(2); end;
    end;
  finally Console.Free; Sim.Free; end;
end.
