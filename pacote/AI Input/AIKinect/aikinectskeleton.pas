unit aikinectskeleton;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, aibase, aikinect_types, aikinectsensor, LResources;

type
  TAIKinectSkeleton = class(TAIBaseComponent)
  private
    FSensor       : TAIKinectSensor;
    FActive       : Boolean;
    FSeatedMode   : Boolean;
    FSmoothFactor : Double;
    FBodies       : TAIKinectBodies;
    FOnSkeleton   : TAIKinectSkeletonEvent;
    
    procedure SetActive(AValue: Boolean);
    procedure DoOnSkeleton(Sender: TObject; const ABodies: TAIKinectBodies);
  protected
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    
    function  StartTracking: Boolean;
    procedure StopTracking;
    function  TrackedBodyCount: Integer;
    function  GetBodies: TAIKinectBodies;
    function  ToPoseLandmarks(ABodyIndex: Integer): string;
  published
    property Sensor       : TAIKinectSensor         read FSensor write FSensor;
    property Active       : Boolean                 read FActive write SetActive default False;
    property SeatedMode   : Boolean                 read FSeatedMode write FSeatedMode default False;
    property SmoothFactor : Double                  read FSmoothFactor write FSmoothFactor;
    property OnSkeletonFrame: TAIKinectSkeletonEvent read FOnSkeleton write FOnSkeleton;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('AI Input', [TAIKinectSkeleton]);
end;

{ TAIKinectSkeleton }

constructor TAIKinectSkeleton.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FCategory := ccInput;
  FPrompt := 'Provides body skeleton tracking from the Kinect sensor. ' +
    'Extracts up to 20 joints per body, converting them into compatible landmarks.';
  FSensor := nil;
  FActive := False;
  FSeatedMode := False;
  FSmoothFactor := 0.5;
  SetLength(FBodies, 0);
end;

destructor TAIKinectSkeleton.Destroy;
begin
  StopTracking;
  inherited Destroy;
end;

procedure TAIKinectSkeleton.Notification(AComponent: TComponent; Operation: TOperation);
begin
  inherited Notification(AComponent, Operation);
  if (Operation = opRemove) and (AComponent = FSensor) then
  begin
    StopTracking;
    FSensor := nil;
  end;
end;

function TAIKinectSkeleton.StartTracking: Boolean;
begin
  Result := False;
  if FActive then Exit(True);
  if not Assigned(FSensor) or not FSensor.IsConnected then
  begin
    SetError('Sensor is not connected');
    Exit(False);
  end;

  FSensor.BackendObject.ConfigureSkeleton(FSeatedMode, FSmoothFactor);
  FSensor.BackendObject.OnSkeletonFrame := @DoOnSkeleton;
  if FSensor.BackendObject.StartSkeletonStream then
  begin
    FActive := True;
    Result := True;
  end
  else
  begin
    SetError(FSensor.BackendObject.LastError);
    FSensor.BackendObject.OnSkeletonFrame := nil;
  end;
end;

procedure TAIKinectSkeleton.StopTracking;
begin
  if not FActive then Exit;
  FActive := False;
  if Assigned(FSensor) and FSensor.IsConnected then
  begin
    FSensor.BackendObject.StopSkeletonStream;
    FSensor.BackendObject.OnSkeletonFrame := nil;
  end;
end;

procedure TAIKinectSkeleton.SetActive(AValue: Boolean);
begin
  if FActive = AValue then Exit;
  if AValue then
    StartTracking
  else
    StopTracking;
end;

procedure TAIKinectSkeleton.DoOnSkeleton(Sender: TObject; const ABodies: TAIKinectBodies);
var
  I: Integer;
begin
  if not FActive then Exit;
  SetLength(FBodies, Length(ABodies));
  for I := 0 to Length(ABodies) - 1 do
    FBodies[I] := ABodies[I];
    
  if Assigned(FOnSkeleton) then
    FOnSkeleton(Self, FBodies);
end;

function TAIKinectSkeleton.TrackedBodyCount: Integer;
var
  I, Count: Integer;
begin
  Count := 0;
  for I := 0 to Length(FBodies) - 1 do
    if FBodies[I].Tracked then
      Inc(Count);
  Result := Count;
end;

function TAIKinectSkeleton.GetBodies: TAIKinectBodies;
begin
  Result := FBodies;
end;

function TAIKinectSkeleton.ToPoseLandmarks(ABodyIndex: Integer): string;
var
  JSON: string;
  J: TAIKinectJointType;
begin
  if (ABodyIndex < 0) or (ABodyIndex >= Length(FBodies)) or not FBodies[ABodyIndex].Tracked then
    Exit('{}');
    
  JSON := '{"tracking_id": ' + IntToStr(FBodies[ABodyIndex].TrackingId) + ', "landmarks": [';
  for J := Low(TAIKinectJointType) to High(TAIKinectJointType) do
  begin
    JSON := JSON + Format('{"joint_id": %d, "x": %f, "y": %f, "z": %f, "screen_x": %d, "screen_y": %d, "state": %d}',
      [Integer(J), FBodies[ABodyIndex].Joints[J].X, FBodies[ABodyIndex].Joints[J].Y, FBodies[ABodyIndex].Joints[J].Z,
       FBodies[ABodyIndex].Joints[J].ScreenX, FBodies[ABodyIndex].Joints[J].ScreenY, Integer(FBodies[ABodyIndex].Joints[J].State)]);
    if J <> High(TAIKinectJointType) then
      JSON := JSON + ', ';
  end;
  JSON := JSON + ']}';
  Result := JSON;
end;

initialization
  {$I aikinect_icon.lrs}

end.
