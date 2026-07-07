program AIKinect_Test;

{$mode objfpc}{$H+}

uses
  Classes, SysUtils, aikinect_types, aikinectsensor, aikinectcolor, aikinectdepth;

var
  Sensor: TAIKinectSensor;
  ColorStream: TAIKinectColorStream;
  DepthStream: TAIKinectDepthStream;
  X, Y, Z: Double;

begin
  WriteLn('Initializing TAIKinectSensor Test Console...');
  
  Sensor := TAIKinectSensor.Create(nil);
  ColorStream := TAIKinectColorStream.Create(nil);
  DepthStream := TAIKinectDepthStream.Create(nil);
  try
    ColorStream.Sensor := Sensor;
    DepthStream.Sensor := Sensor;
    
    WriteLn('Listing Devices...');
    with Sensor.ListDevices do
    begin
      WriteLn(Text);
      Free;
    end;
    
    WriteLn('Opening Sensor...');
    if Sensor.Open then
    begin
      WriteLn('Sensor Opened Successfully!');
      
      Sensor.TiltAngle := 10;
      WriteLn('Set Tilt Angle to 10. Current Tilt: ', Sensor.TiltAngle);
      
      Sensor.LedColor := klYellow;
      WriteLn('Set LED to Yellow.');
      
      if Sensor.ReadAccelerometer(X, Y, Z) then
        WriteLn(Format('Accelerometer: X=%f, Y=%f, Z=%f', [X, Y, Z]));
        
      WriteLn('Starting Color Stream...');
      if ColorStream.StartStream then
        WriteLn('Color stream started!')
      else
        WriteLn('Failed to start color stream: ', ColorStream.LastError);
        
      WriteLn('Starting Depth Stream...');
      if DepthStream.StartStream then
      begin
        WriteLn('Depth stream started!');
        DepthStream.ExportPointCloudPLY('simulated_cloud.ply', True);
        WriteLn('Exported PLY cloud to simulated_cloud.ply.');
      end
      else
        WriteLn('Failed to start depth stream: ', DepthStream.LastError);
        
      WriteLn('Stopping Streams...');
      ColorStream.StopStream;
      DepthStream.StopStream;
      
      Sensor.Close;
      WriteLn('Sensor Closed.');
    end
    else
      WriteLn('Failed to open sensor: ', Sensor.LastError);
      
  finally
    ColorStream.Free;
    DepthStream.Free;
    Sensor.Free;
  end;
  
  WriteLn('Test Complete.');
end.
