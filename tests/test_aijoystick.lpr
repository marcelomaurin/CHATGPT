program test_aijoystick;

{$mode objfpc}{$H+}

uses
  Classes, SysUtils, Math, aibase, aijoystick;

type
  TMockAIJoystick = class(TAIJoystick)
  public
    MockReadResult: Boolean;
    MockState: TAIJoystickState;
    MockDevices: TAIJoystickDevices;
    LastReadID: string;

    constructor Create(AOwner: TComponent); override;
  protected
    function ReadDevice(const ID: string; out S: TAIJoystickState): Boolean; override;
    procedure ScanDevices; override;
  end;

constructor TMockAIJoystick.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  MockReadResult := True;
  FillChar(MockState, SizeOf(MockState), 0);
  MockState.Connected := True;
  MockState.DeviceID := 'xinput:0';
  MockState.DeviceName := 'Mock Controller';
end;

function TMockAIJoystick.ReadDevice(const ID: string; out S: TAIJoystickState): Boolean;
begin
  LastReadID := ID;
  if MockReadResult then
  begin
    S := MockState;
    S.DeviceID := ID;
    Result := True;
  end
  else
  begin
    S := Default(TAIJoystickState);
    Result := False;
  end;
end;

procedure TMockAIJoystick.ScanDevices;
begin
  FDevices := Copy(MockDevices);
end;

procedure Check(Condition: Boolean; const Msg: string);
begin
  if not Condition then
    raise Exception.Create('Check failed: ' + Msg);
end;

procedure CheckDouble(Actual, Expected: Double; const Msg: string; Tolerance: Double = 0.0001);
begin
  if Abs(Actual - Expected) > Tolerance then
    raise Exception.CreateFmt('%s (expected %.4f, got %.4f)', [Msg, Expected, Actual]);
end;

procedure TestNormalizeAxis;
begin
  CheckDouble(TAIJoystick.NormalizeAxis(0, -32768, 32767), 0.0, 'Center axis zero');
  CheckDouble(TAIJoystick.NormalizeAxis(-32768, -32768, 32767), -1.0, 'Min axis value');
  CheckDouble(TAIJoystick.NormalizeAxis(32767, -32768, 32767), 1.0, 'Max axis value');
  CheckDouble(TAIJoystick.NormalizeAxis(-40000, -32768, 32767), -1.0, 'Clamped below min');
  CheckDouble(TAIJoystick.NormalizeAxis(40000, -32768, 32767), 1.0, 'Clamped above max');
  CheckDouble(TAIJoystick.NormalizeAxis(32767, 0, 65535), 0.0, 'Unsigned center', 0.001);
  CheckDouble(TAIJoystick.NormalizeAxis(0, 0, 65535), -1.0, 'Unsigned min');
  CheckDouble(TAIJoystick.NormalizeAxis(65535, 0, 65535), 1.0, 'Unsigned max');
  CheckDouble(TAIJoystick.NormalizeAxis(10, 10, 10), 0.0, 'Min equals max returns zero');
  CheckDouble(TAIJoystick.NormalizeAxis(10, 20, 10), 0.0, 'Min greater than max returns zero');
end;

procedure TestMockPolling;
var
  J: TMockAIJoystick;
begin
  J := TMockAIJoystick.Create(nil);
  try
    SetLength(J.MockDevices, 2);
    J.MockDevices[0].ID := 'xinput:0';
    J.MockDevices[0].Name := 'Mock Controller 1';
    J.MockDevices[1].ID := 'winmm:0';
    J.MockDevices[1].Name := 'Mock Generic 1';

    Check(J.Poll, 'Poll successful in auto mode');
    Check(J.State.Connected, 'Device reported connected');
    Check(J.State.DeviceID = 'xinput:0', 'Connected to first available device');

    J.MockState.Axes[0] := 0.75;
    J.MockState.Controls[ajA] := True;
    J.MockState.Controls[ajRT] := True;
    Check(J.Poll, 'Second poll');
    CheckDouble(J.State.Axes[0], 0.75, 'Axis 0 reflected');
    Check(J.State.Controls[ajA], 'Button A pressed');
    Check(J.State.Controls[ajRT], 'Virtual trigger RT pressed');

    J.MockReadResult := False;
    Check(not J.Poll, 'Poll returns false when disconnected');
    Check(not J.State.Connected, 'State reflects disconnected');

    J.DeviceID := 'winmm:0';
    J.MockReadResult := True;
    Check(J.Poll, 'Poll returns true for manual selection');
    Check(J.LastReadID = 'winmm:0', 'Read requested for specified DeviceID');
  finally
    J.Free;
  end;
end;

begin
  try
    TestNormalizeAxis;
    TestMockPolling;
    WriteLn('PASS: all TAIJoystick tests passed successfully.');
  except
    on E: Exception do
    begin
      WriteLn('FAIL: ' + E.Message);
      Halt(1);
    end;
  end;
end.