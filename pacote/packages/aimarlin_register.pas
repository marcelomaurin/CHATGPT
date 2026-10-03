unit aimarlin_register;
{$mode objfpc}{$H+}
interface
procedure Register;
implementation
uses Classes, aigcodeparser, aimarlinsimulator, aivirtualserialpair, aimarlinserialdevice;
procedure Register;
begin
  RegisterComponents('AI Simulation', [TAIGCodeParser, TAIMarlinSimulator,
    TAIVirtualSerialPair, TAIMarlinSerialDevice]);
end;
end.
