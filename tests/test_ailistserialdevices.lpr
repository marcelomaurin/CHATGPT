program test_ailistserialdevices;

{$mode objfpc}{$H+}

uses
  Classes, SysUtils, ailistserialdevices;

var
  Lister: TAIListSerialDevices;
  Item: TAIListSerialDeviceItem;
begin
  WriteLn('Testing TAIListSerialDevices...');
  
  Lister := TAIListSerialDevices.Create(nil);
  try
    WriteLn('Default OnlyAvailable: ', Lister.OnlyAvailable);
    WriteLn('Default ProbeOpenable: ', Lister.ProbeOpenable);
    WriteLn('Default AutoRefresh: ', Lister.AutoRefresh);
    
    // Add item manually
    Item := Lister.Devices.Add;
    Item.DeviceName := 'COM99';
    WriteLn('Created manually COM99.');
    WriteLn('  IsAvailable: ', Item.IsAvailable);
    WriteLn('  IsOpenable: ', Item.IsOpenable);
    
    // Check that Refresh runs without exceptions
    Lister.Refresh;
    WriteLn('Refresh completed successfully. Port count: ', Lister.Count);
    
  finally
    Lister.Free;
  end;
  
  WriteLn('Test passed successfully.');
end.
