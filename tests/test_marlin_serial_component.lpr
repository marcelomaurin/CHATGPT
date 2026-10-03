program test_marlin_serial_component;
{$mode objfpc}{$H+}
uses Interfaces, Classes, SysUtils, aimarlinserialdevice;
var Device: TAIMarlinSerialDevice;
begin
  Device := TAIMarlinSerialDevice.Create(nil);
  try
    if Device.Open('',115200) then Halt(1);
    if Device.LastError='' then Halt(2);
    if Device.Serial.Active then Halt(3);
    Device.Simulator.SubmitLine('M115');
    Device.Simulator.Advance(0);
    Device.Close;
    Device.Poll(0.1);
    Writeln('PASS serial adapter lifecycle and invalid configuration (no port opened)');
  finally Device.Free; end;
end.
