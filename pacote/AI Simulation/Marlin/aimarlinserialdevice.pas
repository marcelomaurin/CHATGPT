unit aimarlinserialdevice;
{$mode objfpc}{$H+}
interface
uses Classes, SysUtils, aibase, aiserial, aimarlinsimulator;
type
  { Optional adapter: owns both components, leaving existing serial code intact.
    All calls/events on the caller's thread; use a timer in the host application. }
  TAIMarlinSerialDevice = class(TAIBaseComponent)
  private
    FSerial: TAISerialModem;
    FSimulator: TAIMarlinSimulator;
    FOnTraffic: TAIMarlinResponseEvent;
    procedure ReceiveBytes(Sender: TObject; const Text: string);
    procedure SendResponse(Sender: TObject; const Text: string);
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    function Open(const DeviceName: string; BaudRate: Integer = 115200): Boolean;
    procedure Close;
    procedure Poll(Seconds: Double);
    property Simulator: TAIMarlinSimulator read FSimulator;
    property Serial: TAISerialModem read FSerial;
  published
    property OnTraffic: TAIMarlinResponseEvent read FOnTraffic write FOnTraffic;
  end;
implementation
constructor TAIMarlinSerialDevice.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FSerial := TAISerialModem.Create(Self);
  FSimulator := TAIMarlinSimulator.Create(Self);
  FSerial.OnRXReceive := @ReceiveBytes;
  FSimulator.OnResponse := @SendResponse;
end;
destructor TAIMarlinSerialDevice.Destroy;
begin Close; inherited Destroy; end;
procedure TAIMarlinSerialDevice.ReceiveBytes(Sender: TObject; const Text: string);
begin
  if Assigned(FOnTraffic) then FOnTraffic(Self, 'RX ' + Text);
  FSimulator.Receive(Text);
end;
procedure TAIMarlinSerialDevice.SendResponse(Sender: TObject; const Text: string);
begin
  if FSerial.Active and not FSerial.WriteText(Text) then begin
    SetError(FSerial.LastError); Close;
  end;
  if Assigned(FOnTraffic) then FOnTraffic(Self, 'TX ' + Text);
end;
function TAIMarlinSerialDevice.Open(const DeviceName: string; BaudRate: Integer): Boolean;
begin
  Close; ClearError;
  if (Trim(DeviceName) = '') or (BaudRate <= 0) then begin
    SetError('Device name and positive baud rate required'); Exit(False);
  end;
  FSerial.DeviceName := DeviceName; FSerial.BaudRate := BaudRate;
  Result := FSerial.OpenPort;
  if Result then begin FSimulator.Reset; Result := FSerial.Active; end
  else SetError(FSerial.LastError);
end;
procedure TAIMarlinSerialDevice.Close;
begin
  FSerial.ClosePort;
  FSimulator.Pause;
end;
procedure TAIMarlinSerialDevice.Poll(Seconds: Double);
begin
  if not FSerial.Active then Exit;
  FSerial.Poll;
  if FSerial.Active then FSimulator.Advance(Seconds);
end;
end.
