unit aimarlin_register;
{$mode objfpc}{$H+}
interface
procedure Register;
implementation
uses LResources, Classes, aigcodeparser, aimarlinsimulator, aivirtualserialpair, aimarlinserialdevice;
procedure Register;
begin
  RegisterComponents('AI Simulation', [TAIGCodeParser, TAIMarlinSimulator,
    TAIVirtualSerialPair, TAIMarlinSerialDevice]);
end;
initialization
  {$I aimarlin_register_icon.lrs}

end.
