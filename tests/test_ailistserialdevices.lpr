program test_ailistserialdevices;

{$mode objfpc}{$H+}

uses
  Interfaces, Classes, SysUtils, ailistserialdevices;

procedure AssertTrue(Condition: Boolean; const Msg: string);
begin
  if not Condition then
    raise Exception.Create('AssertTrue failed: ' + Msg);
end;

procedure AssertEquals(const Expected, Actual: string; const Msg: string);
begin
  if Expected <> Actual then
    raise Exception.Create('AssertEquals failed: Expected "' + Expected + '", Actual "' + Actual + '". ' + Msg);
end;

procedure AssertEqualsInt(Expected, Actual: Integer; const Msg: string);
begin
  if Expected <> Actual then
    raise Exception.Create('AssertEqualsInt failed: Expected ' + IntToStr(Expected) + ', Actual ' + IntToStr(Actual) + '. ' + Msg);
end;

procedure TestExtractUsbSerial;
begin
  WriteLn('Testing ExtractUsbSerialFromInstanceId...');
  AssertEquals('123456', ExtractUsbSerialFromInstanceId('USB\VID_1A86&PID_7523\123456'), 'Simple serial');
  AssertEquals('', ExtractUsbSerialFromInstanceId('USB\VID_1A86&PID_7523\5&2e4e1a0b&0&1'), 'Auto-generated serial containing &');
  AssertEquals('', ExtractUsbSerialFromInstanceId('COM1'), 'Non-USB instance path');
end;

procedure TestNaturalCompare;
begin
  WriteLn('Testing NaturalCompare...');
  AssertTrue(NaturalCompare('COM2', 'COM10') < 0, 'COM2 < COM10');
  AssertTrue(NaturalCompare('COM10', 'COM2') > 0, 'COM10 > COM2');
  AssertTrue(NaturalCompare('COM1', 'COM1') = 0, 'COM1 = COM1');
  AssertTrue(NaturalCompare('ttyUSB0', 'ttyUSB10') < 0, 'ttyUSB0 < ttyUSB10');
  AssertTrue(NaturalCompare('ttyS2', 'ttyS10') < 0, 'ttyS2 < ttyS10');
end;

procedure TestSortAndDeduplicate;
var
  Arr: TDetectedDeviceArray;
begin
  WriteLn('Testing SortAndDeduplicate...');
  SetLength(Arr, 3);
  
  Arr[0].DeviceName := 'COM10';
  Arr[0].InstanceID := '';
  
  Arr[1].DeviceName := 'COM2';
  Arr[1].InstanceID := 'USB\VID_1A86&PID_7523\12345';
  
  Arr[2].DeviceName := 'COM10';
  Arr[2].InstanceID := 'USB\VID_0403&PID_6001\FT1234';
  
  SortAndDeduplicate(Arr);
  
  // Devia ordenar como COM2, COM10 e desduplicar o COM10 priorizando aquele com InstanceID
  AssertEqualsInt(2, Length(Arr), 'Length after deduplication should be 2');
  AssertEquals('COM2', Arr[0].DeviceName, 'First element should be COM2');
  AssertEquals('COM10', Arr[1].DeviceName, 'Second element should be COM10');
  AssertEquals('USB\VID_0403&PID_6001\FT1234', Arr[1].InstanceID, 'COM10 should have kept the richer InstanceID');
end;

var
  Lister: TAIListSerialDevices;
  Item: TAIListSerialDeviceItem;
begin
  WriteLn('Testing TAIListSerialDevices...');
  
  try
    TestExtractUsbSerial;
    TestNaturalCompare;
    TestSortAndDeduplicate;
    
    Lister := TAIListSerialDevices.Create(nil);
    try
      AssertTrue(Lister.OnlyAvailable, 'Default OnlyAvailable');
      AssertTrue(not Lister.ProbeOpenable, 'Default ProbeOpenable');
      AssertTrue(not Lister.AutoRefresh, 'Default AutoRefresh');
      
      // Add item manually
      Item := Lister.Devices.Add;
      Item.DeviceName := 'COM99';
      AssertTrue(Item.IsAvailable, 'Manual item IsAvailable');
      AssertTrue(Item.IsOpenable, 'Manual item IsOpenable');
      
      // Check that Refresh runs without exceptions
      Lister.Refresh;
      WriteLn('Refresh completed successfully. Port count: ', Lister.Count);
      
    finally
      Lister.Free;
    end;
    
    WriteLn('All tests passed successfully.');
  except
    on E: Exception do
    begin
      WriteLn('TEST FAILED: ', E.Message);
      Halt(1);
    end;
  end;
end.
