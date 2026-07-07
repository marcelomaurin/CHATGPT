unit aikinectsensor;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, aibase, aikinect_types, aikinect_backend,
  aikinect_freenect, aikinect_sdk10, LResources;

type
  TAIKinectSensor = class(TAIBaseComponent)
  private
    FBackendObj   : TAIKinectNativeBackend;
    FDeviceIndex  : Integer;
    FKinectModel  : TAIKinectModel;
    FBackend      : TAIKinectBackendKind;
    FActive       : Boolean;
    FTiltAngle    : Integer;
    FLedColor     : TAIKinectLed;
    FOnConnect    : TNotifyEvent;
    FOnDisconnect : TNotifyEvent;
    FOnError      : TAIKinectErrorEvent;
    
    procedure SetActive(AValue: Boolean);
    procedure SetTiltAngle(AValue: Integer);
    procedure SetLedColor(AValue: TAIKinectLed);
  public
    constructor Create(AOwner: TComponent); override;
    destructor  Destroy; override;

    function  Open: Boolean;
    procedure Close;
    function  ListDevices: TStringList;
    function  DeviceCount: Integer;
    function  ReadAccelerometer(out AX, AY, AZ: Double): Boolean;
    function  IsConnected: Boolean;

    property BackendObject: TAIKinectNativeBackend read FBackendObj;
  published
    property DeviceIndex : Integer              read FDeviceIndex write FDeviceIndex default 0;
    property KinectModel : TAIKinectModel       read FKinectModel write FKinectModel default kmAuto;
    property Backend     : TAIKinectBackendKind read FBackend     write FBackend     default kbAuto;
    property Active      : Boolean              read FActive      write SetActive    default False;
    property TiltAngle   : Integer              read FTiltAngle   write SetTiltAngle default 0;
    property LedColor    : TAIKinectLed         read FLedColor    write SetLedColor  default klGreen;
    property OnConnect   : TNotifyEvent         read FOnConnect    write FOnConnect;
    property OnDisconnect: TNotifyEvent         read FOnDisconnect write FOnDisconnect;
    property OnError     : TAIKinectErrorEvent  read FOnError      write FOnError;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('AI Input', [TAIKinectSensor]);
end;

{ TAIKinectSensor }

constructor TAIKinectSensor.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FCategory := ccInput;
  FPrompt := 'Component TAIKinectSensor manages the physical connection to a ' +
    'Microsoft Kinect device (v1/Xbox360; v2 and Azure planned). It opens/closes ' +
    'the sensor, controls tilt motor (-27..27 deg), LED and reads the accelerometer. ' +
    'Stream components (TAIKinectColorStream, TAIKinectDepthStream, TAIKinectSkeleton, ' +
    'TAIKinectAudio) must point to it via the Sensor property.';
  FDeviceIndex := 0;
  FKinectModel := kmAuto;
  FBackend := kbAuto;
  FActive := False;
  FTiltAngle := 0;
  FLedColor := klGreen;
  FBackendObj := nil;
end;

destructor TAIKinectSensor.Destroy;
begin
  Close;
  inherited Destroy;
end;

function TAIKinectSensor.Open: Boolean;
begin
  if FActive then Exit(True);
  
  // Decide backend type
  try
    {$IFDEF MSWINDOWS}
    if (FBackend = kbAuto) or (FBackend = kbKinectSDK10) then
      FBackendObj := TAIKinectSDK10Backend.Create(FDeviceIndex, FKinectModel)
    else
      FBackendObj := TAIKinectFreenectBackend.Create(FDeviceIndex, FKinectModel);
    {$ELSE}
    if FBackend = kbKinectSDK10 then
    begin
      SetError('Kinect SDK is only supported on Windows.');
      Exit(False);
    end;
    FBackendObj := TAIKinectFreenectBackend.Create(FDeviceIndex, FKinectModel);
    {$ENDIF}
      
    if FBackendObj.Open then
    begin
      FActive := True;
      FBackendObj.SetTiltAngle(FTiltAngle);
      FBackendObj.SetLedColor(FLedColor);
      if Assigned(FOnConnect) then
        FOnConnect(Self);
      Result := True;
    end
    else
    begin
      SetError(FBackendObj.LastError);
      if Assigned(FOnError) then
        FOnError(Self, FLastError);
      FreeAndNil(FBackendObj);
      Result := False;
    end;
  except
    on E: Exception do
    begin
      SetError('Exception in TAIKinectSensor.Open: ' + E.ClassName + ': ' + E.Message);
      if Assigned(FOnError) then
        FOnError(Self, FLastError);
      Result := False;
    end;
  end;
end;

procedure TAIKinectSensor.Close;
begin
  if not FActive then Exit;
  FActive := False;
  if Assigned(FBackendObj) then
  begin
    FBackendObj.Close;
    FreeAndNil(FBackendObj);
  end;
  if Assigned(FOnDisconnect) then
    FOnDisconnect(Self);
end;

procedure TAIKinectSensor.SetActive(AValue: Boolean);
begin
  if FActive = AValue then Exit;
  if AValue then
    Open
  else
    Close;
end;

procedure TAIKinectSensor.SetTiltAngle(AValue: Integer);
begin
  if AValue < -27 then AValue := -27;
  if AValue > 27 then AValue := 27;
  FTiltAngle := AValue;
  if FActive and Assigned(FBackendObj) then
    FBackendObj.SetTiltAngle(FTiltAngle);
end;

procedure TAIKinectSensor.SetLedColor(AValue: TAIKinectLed);
begin
  FLedColor := AValue;
  if FActive and Assigned(FBackendObj) then
    FBackendObj.SetLedColor(FLedColor);
end;

function TAIKinectSensor.ListDevices: TStringList;
begin
  Result := TStringList.Create;
  Result.Add('0: Microsoft Kinect (Xbox 360)');
end;

function TAIKinectSensor.DeviceCount: Integer;
begin
  Result := 1;
end;

function TAIKinectSensor.ReadAccelerometer(out AX, AY, AZ: Double): Boolean;
begin
  AX := 0; AY := 0; AZ := 0;
  if FActive and Assigned(FBackendObj) then
    Result := FBackendObj.ReadAccelerometer(AX, AY, AZ)
  else
    Result := False;
end;

function TAIKinectSensor.IsConnected: Boolean;
begin
  Result := FActive and Assigned(FBackendObj) and FBackendObj.Connected;
end;

initialization
  {$I aikinect_icon.lrs}

end.
