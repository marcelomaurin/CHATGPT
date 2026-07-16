unit aiarm_robot;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Math, Graphics, Controls, aibase,
  fpjson, jsonparser,
  GLScene, GLViewer, GLObjects, GLGeomObjects, GLMaterial,
  GLCoordinates, GLCrossPlatform, GLVectorGeometry, GLColor,
  GLVectorFileObjects;

type
  TAIArmVector3 = record
    X: Double;
    Y: Double;
    Z: Double;
  end;

  TAIArmVector3Array = array of TAIArmVector3;

  { TAI_Arm_robotJoint }

  TAI_Arm_robotJoint = class(TCollectionItem)
  private
    FName: string;
    FJointType: string;
    FAxisX: Double;
    FAxisY: Double;
    FAxisZ: Double;
    FDirectionX: Double;
    FDirectionY: Double;
    FDirectionZ: Double;
    FLength: Double;
    FAngleDeg: Double;
    FMinAngleDeg: Double;
    FMaxAngleDeg: Double;
    FDefaultAngleDeg: Double;
    FIsBase: Boolean;
    FVisible: Boolean;
    FColor: TColor;
    FLinkRadius: Double;
    FJointRadius: Double;
    procedure SetJointType(const AValue: string);
    procedure SetAxisX(AValue: Double);
    procedure SetAxisY(AValue: Double);
    procedure SetAxisZ(AValue: Double);
    procedure SetDirectionX(AValue: Double);
    procedure SetDirectionY(AValue: Double);
    procedure SetDirectionZ(AValue: Double);
    procedure SetLength(AValue: Double);
    procedure SetAngleDeg(AValue: Double);
    procedure SetMinAngleDeg(AValue: Double);
    procedure SetMaxAngleDeg(AValue: Double);
    procedure SetDefaultAngleDeg(AValue: Double);
    procedure SetIsBase(AValue: Boolean);
    procedure SetVisible(AValue: Boolean);
    procedure SetColor(AValue: TColor);
    procedure SetLinkRadius(AValue: Double);
    procedure SetJointRadius(AValue: Double);
    procedure NotifyOwnerChanged;
  public
    procedure Assign(Source: TPersistent); override;
  published
    property Name: string read FName write FName;
    property JointType: string read FJointType write SetJointType;
    property AxisX: Double read FAxisX write SetAxisX;
    property AxisY: Double read FAxisY write SetAxisY;
    property AxisZ: Double read FAxisZ write SetAxisZ;
    property RotationAxisX: Double read FAxisX write SetAxisX;
    property RotationAxisY: Double read FAxisY write SetAxisY;
    property RotationAxisZ: Double read FAxisZ write SetAxisZ;
    property DirectionX: Double read FDirectionX write SetDirectionX;
    property DirectionY: Double read FDirectionY write SetDirectionY;
    property DirectionZ: Double read FDirectionZ write SetDirectionZ;
    property Length: Double read FLength write SetLength;
    property AngleDeg: Double read FAngleDeg write SetAngleDeg;
    property MinAngleDeg: Double read FMinAngleDeg write SetMinAngleDeg;
    property MaxAngleDeg: Double read FMaxAngleDeg write SetMaxAngleDeg;
    property DefaultAngleDeg: Double read FDefaultAngleDeg write SetDefaultAngleDeg;
    property IsBase: Boolean read FIsBase write SetIsBase;
    property Visible: Boolean read FVisible write SetVisible;
    property Color: TColor read FColor write SetColor;
    property LinkRadius: Double read FLinkRadius write SetLinkRadius;
    property JointRadius: Double read FJointRadius write SetJointRadius;
    property Value: Double read FAngleDeg write SetAngleDeg;
    property MinValue: Double read FMinAngleDeg write SetMinAngleDeg;
    property MaxValue: Double read FMaxAngleDeg write SetMaxAngleDeg;
    property DefaultValue: Double read FDefaultAngleDeg write SetDefaultAngleDeg;
  end;

  { TAI_Arm_robotJoints }

  TAI_Arm_robotJoints = class(TOwnedCollection)
  private
    function GetItem(Index: Integer): TAI_Arm_robotJoint;
  public
    constructor Create(AOwner: TPersistent);
    function Add: TAI_Arm_robotJoint;
    property Items[Index: Integer]: TAI_Arm_robotJoint read GetItem; default;
  end;

  TAI_Arm_robotChangeEvent = procedure(Sender: TObject) of object;

  { TAI_Arm_robot }

  TAI_Arm_robot = class(TAIBaseComponent)
  private
    FJoints: TAI_Arm_robotJoints;
    FBaseX: Double;
    FBaseY: Double;
    FBaseZ: Double;
    FTargetX: Double;
    FTargetY: Double;
    FTargetZ: Double;
    FTolerance: Double;
    FMaxIterations: Integer;
    FUseLimits: Boolean;
    FLastEndX: Double;
    FLastEndY: Double;
    FLastEndZ: Double;
    FOnChange: TAI_Arm_robotChangeEvent;
    FLoading: Boolean;
    FViewBackgroundColor: TColor;
    FViewArmColor: TColor;
    FViewJointColor: TColor;
    FViewGridColor: TColor;
    FViewBaseColor: TColor;
    FViewBaseHighlightColor: TColor;
    FViewShowGrid: Boolean;
    FViewShowJointLabels: Boolean;
    FViewShowAxes: Boolean;
    FViewAutoFit: Boolean;
    FViewScale: Double;
    FViewAzimuthDeg: Double;
    FViewElevationDeg: Double;
    FViewShowBasePedestal: Boolean;
    FViewBaseRadius: Double;
    FViewBaseInnerRadius: Double;
    FViewBaseHeight: Double;
    FViewLinkThickness: Double;
    FViewJointRadius: Double;
    FViewGuideSize: Double;
    FViewCameraX: Double;
    FViewCameraY: Double;
    FViewCameraZ: Double;
    FViewCameraFocalLength: Double;
    FViewCameraDepthOfView: Double;
    FViewLightX: Double;
    FViewLightY: Double;
    FViewLightZ: Double;
    FViewActorInterval: Integer;
    FViewModelStyle: string;
    FViewPrintedColor: TColor;
    FViewServoColor: TColor;
    FViewMetalColor: TColor;
    FViewLinkWidth: Double;
    FViewLinkDepth: Double;
    FViewLinkSpacing: Double;
    FViewServoWidth: Double;
    FViewServoHeight: Double;
    FViewServoDepth: Double;
    FViewGripperWidth: Double;
    FViewGripperLength: Double;
    procedure SetBaseX(AValue: Double);
    procedure SetBaseY(AValue: Double);
    procedure SetBaseZ(AValue: Double);
    procedure SetTargetX(AValue: Double);
    procedure SetTargetY(AValue: Double);
    procedure SetTargetZ(AValue: Double);
    procedure SetTolerance(AValue: Double);
    procedure SetMaxIterations(AValue: Integer);
    procedure SetUseLimits(AValue: Boolean);
    function GetJointCount: Integer;
    procedure DoChanged;
    procedure NormalizeJointAxes(var AAxis: TAIArmVector3);
    procedure BuildPose(out APoints, AFrameX, AFrameY, AFrameZ: TAIArmVector3Array);
    procedure ClampJointAngle(AJoint: TAI_Arm_robotJoint);
    function SolveCCDOnce(const ATarget: TAIArmVector3): Boolean;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    procedure ClearJoints;
    function AddJoint(const AName: string; AX, AY, AZ, ALength: Double): TAI_Arm_robotJoint;
    procedure LoadSixAxisSample;
    procedure LoadFromJSON(const AJSON: string);
    procedure LoadFromJSONFile(const AFileName: string);
    procedure SaveToJSONFile(const AFileName: string);
    procedure ResetAngles;
    function ForwardKinematics(out APoints: TAIArmVector3Array): Boolean;
    procedure GetPoseFrames(out APoints, AFrameX, AFrameY, AFrameZ: TAIArmVector3Array);
    function GetEndEffectorPosition: TAIArmVector3;
    function SolveInverseKinematics(AX, AY, AZ: Double): Boolean; overload;
    function SolveInverseKinematics(const ATarget: TAIArmVector3): Boolean; overload;
    function ToJSON: string;
    function ToSetupPrompt: string;
    function ToSetupText: string;
    function BuildAISetupText: string;
    procedure UpdatePromptFromJoints;
    property JointCount: Integer read GetJointCount;
    property LastEndX: Double read FLastEndX;
    property LastEndY: Double read FLastEndY;
    property LastEndZ: Double read FLastEndZ;
  published
    property Joints: TAI_Arm_robotJoints read FJoints write FJoints;
    property BaseX: Double read FBaseX write SetBaseX;
    property BaseY: Double read FBaseY write SetBaseY;
    property BaseZ: Double read FBaseZ write SetBaseZ;
    property TargetX: Double read FTargetX write SetTargetX;
    property TargetY: Double read FTargetY write SetTargetY;
    property TargetZ: Double read FTargetZ write SetTargetZ;
    property Tolerance: Double read FTolerance write SetTolerance;
    property MaxIterations: Integer read FMaxIterations write SetMaxIterations;
    property UseLimits: Boolean read FUseLimits write SetUseLimits;
    property OnChange: TAI_Arm_robotChangeEvent read FOnChange write FOnChange;
    property ViewBackgroundColor: TColor read FViewBackgroundColor write FViewBackgroundColor;
    property ViewArmColor: TColor read FViewArmColor write FViewArmColor;
    property ViewJointColor: TColor read FViewJointColor write FViewJointColor;
    property ViewGridColor: TColor read FViewGridColor write FViewGridColor;
    property ViewBaseColor: TColor read FViewBaseColor write FViewBaseColor;
    property ViewBaseHighlightColor: TColor read FViewBaseHighlightColor write FViewBaseHighlightColor;
    property ViewShowGrid: Boolean read FViewShowGrid write FViewShowGrid;
    property ViewShowJointLabels: Boolean read FViewShowJointLabels write FViewShowJointLabels;
    property ViewShowAxes: Boolean read FViewShowAxes write FViewShowAxes;
    property ViewAutoFit: Boolean read FViewAutoFit write FViewAutoFit;
    property ViewScale: Double read FViewScale write FViewScale;
    property ViewAzimuthDeg: Double read FViewAzimuthDeg write FViewAzimuthDeg;
    property ViewElevationDeg: Double read FViewElevationDeg write FViewElevationDeg;
    property ViewShowBasePedestal: Boolean read FViewShowBasePedestal write FViewShowBasePedestal;
    property ViewBaseRadius: Double read FViewBaseRadius write FViewBaseRadius;
    property ViewBaseInnerRadius: Double read FViewBaseInnerRadius write FViewBaseInnerRadius;
    property ViewBaseHeight: Double read FViewBaseHeight write FViewBaseHeight;
    property ViewLinkThickness: Double read FViewLinkThickness write FViewLinkThickness;
    property ViewJointRadius: Double read FViewJointRadius write FViewJointRadius;
    property ViewGuideSize: Double read FViewGuideSize write FViewGuideSize;
    property ViewCameraX: Double read FViewCameraX write FViewCameraX;
    property ViewCameraY: Double read FViewCameraY write FViewCameraY;
    property ViewCameraZ: Double read FViewCameraZ write FViewCameraZ;
    property ViewCameraFocalLength: Double read FViewCameraFocalLength write FViewCameraFocalLength;
    property ViewCameraDepthOfView: Double read FViewCameraDepthOfView write FViewCameraDepthOfView;
    property ViewLightX: Double read FViewLightX write FViewLightX;
    property ViewLightY: Double read FViewLightY write FViewLightY;
    property ViewLightZ: Double read FViewLightZ write FViewLightZ;
    property ViewActorInterval: Integer read FViewActorInterval write FViewActorInterval;
    property ViewModelStyle: string read FViewModelStyle write FViewModelStyle;
    property ViewPrintedColor: TColor read FViewPrintedColor write FViewPrintedColor;
    property ViewServoColor: TColor read FViewServoColor write FViewServoColor;
    property ViewMetalColor: TColor read FViewMetalColor write FViewMetalColor;
    property ViewLinkWidth: Double read FViewLinkWidth write FViewLinkWidth;
    property ViewLinkDepth: Double read FViewLinkDepth write FViewLinkDepth;
    property ViewLinkSpacing: Double read FViewLinkSpacing write FViewLinkSpacing;
    property ViewServoWidth: Double read FViewServoWidth write FViewServoWidth;
    property ViewServoHeight: Double read FViewServoHeight write FViewServoHeight;
    property ViewServoDepth: Double read FViewServoDepth write FViewServoDepth;
    property ViewGripperWidth: Double read FViewGripperWidth write FViewGripperWidth;
    property ViewGripperLength: Double read FViewGripperLength write FViewGripperLength;
  end;

  { TAI_Arm_robotViewer }

  TAI_Arm_robotViewer = class(TCustomControl)
  private
    FArm: TAI_Arm_robot;
    FGLScene: TGLScene;
    FGLSceneViewer: TGLSceneViewer;
    FGLRoot: TGLDummyCube;
    FGLGuide: TGLDummyCube;
    FGLCamera: TGLCamera;
    FGLLight: TGLLightSource;
    FGLActor: TGLActor;
    FGLPedestal: TGLAnnulus;
    FGLBaseBody: TGLCylinder;
    FGLJointNodes: array of TGLDummyCube;
    FGLJointLinks: array of TGLCylinder;
    FGLJointSpheres: array of TGLSphere;
    FGLJointPlateA: array of TGLCube;
    FGLJointPlateB: array of TGLCube;
    FGLServoBodies: array of TGLCube;
    FGLGripperPalm: TGLCube;
    FGLGripperJawA: TGLCube;
    FGLGripperJawB: TGLCube;
    FAppliedAngles: array of Double;
    FBackgroundColor: TColor;
    FArmColor: TColor;
    FJointColor: TColor;
    FGridColor: TColor;
    FBaseColor: TColor;
    FBaseHighlightColor: TColor;
    FShowGrid: Boolean;
    FShowJointLabels: Boolean;
    FShowAxes: Boolean;
    FAutoFit: Boolean;
    FScale: Double;
    FAzimuthDeg: Double;
    FElevationDeg: Double;
    FShowBasePedestal: Boolean;
    FBaseRadius: Double;
    FBaseInnerRadius: Double;
    FBaseHeight: Double;
    FLinkThickness: Double;
    FJointRadius: Double;
    FGuideSize: Double;
    FCameraX: Double;
    FCameraY: Double;
    FCameraZ: Double;
    FCameraFocalLength: Double;
    FCameraDepthOfView: Double;
    FLightX: Double;
    FLightY: Double;
    FLightZ: Double;
    FActorInterval: Integer;
    FModelStyle: string;
    FPrintedColor: TColor;
    FServoColor: TColor;
    FMetalColor: TColor;
    FLinkWidth: Double;
    FLinkDepth: Double;
    FLinkSpacing: Double;
    FServoWidth: Double;
    FServoHeight: Double;
    FServoDepth: Double;
    FGripperWidth: Double;
    FGripperLength: Double;
    FSceneReady: Boolean;
    FMouseDownX: Integer;
    FMouseDownY: Integer;
    procedure SetArm(AValue: TAI_Arm_robot);
    procedure SetBackgroundColor(AValue: TColor);
    procedure SetArmColor(AValue: TColor);
    procedure SetJointColor(AValue: TColor);
    procedure SetGridColor(AValue: TColor);
    procedure SetBaseColor(AValue: TColor);
    procedure SetBaseHighlightColor(AValue: TColor);
    procedure SetShowGrid(AValue: Boolean);
    procedure SetShowJointLabels(AValue: Boolean);
    procedure SetShowAxes(AValue: Boolean);
    procedure SetAutoFit(AValue: Boolean);
    procedure SetScale(AValue: Double);
    procedure SetAzimuthDeg(AValue: Double);
    procedure SetElevationDeg(AValue: Double);
    procedure SetShowBasePedestal(AValue: Boolean);
    procedure SetBaseRadius(AValue: Double);
    procedure SetBaseInnerRadius(AValue: Double);
    procedure SetBaseHeight(AValue: Double);
    procedure SetLinkThickness(AValue: Double);
    procedure SetJointRadius(AValue: Double);
    procedure SetGuideSize(AValue: Double);
    procedure SetCameraX(AValue: Double);
    procedure SetCameraY(AValue: Double);
    procedure SetCameraZ(AValue: Double);
    procedure SetCameraFocalLength(AValue: Double);
    procedure SetCameraDepthOfView(AValue: Double);
    procedure SetLightX(AValue: Double);
    procedure SetLightY(AValue: Double);
    procedure SetLightZ(AValue: Double);
    procedure SetActorInterval(AValue: Integer);
    function ProjectPoint(const APoint: TAIArmVector3): TAIArmVector3;
    procedure DrawPlaceholder;
    procedure ClearScene;
    procedure BuildScene;
    procedure ApplyObjectColor(const AObject: TGLSceneObject; const AColor: TColor);
    procedure ApplyAppearance;
    procedure GLMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure GLMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
    procedure GLMouseWheel(Sender: TObject; Shift: TShiftState; WheelDelta: Integer; MousePos: TPoint; var Handled: Boolean);
  protected
    procedure Paint; override;
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
  public
    constructor Create(AOwner: TComponent); override;
    procedure SyncScene;
  published
    property Arm: TAI_Arm_robot read FArm write SetArm;
    property BackgroundColor: TColor read FBackgroundColor write SetBackgroundColor default clBlack;
    property ArmColor: TColor read FArmColor write SetArmColor default clLime;
    property JointColor: TColor read FJointColor write SetJointColor default clAqua;
    property GridColor: TColor read FGridColor write SetGridColor default clGray;
    property BaseColor: TColor read FBaseColor write SetBaseColor default clSilver;
    property BaseHighlightColor: TColor read FBaseHighlightColor write SetBaseHighlightColor default clWhite;
    property ShowGrid: Boolean read FShowGrid write SetShowGrid default True;
    property ShowJointLabels: Boolean read FShowJointLabels write SetShowJointLabels default True;
    property ShowAxes: Boolean read FShowAxes write SetShowAxes default True;
    property AutoFit: Boolean read FAutoFit write SetAutoFit default True;
    property Scale: Double read FScale write SetScale;
    property AzimuthDeg: Double read FAzimuthDeg write SetAzimuthDeg;
    property ElevationDeg: Double read FElevationDeg write SetElevationDeg;
    property ShowBasePedestal: Boolean read FShowBasePedestal write SetShowBasePedestal default True;
    property BaseRadius: Double read FBaseRadius write SetBaseRadius;
    property BaseInnerRadius: Double read FBaseInnerRadius write SetBaseInnerRadius;
    property BaseHeight: Double read FBaseHeight write SetBaseHeight;
    property LinkThickness: Double read FLinkThickness write SetLinkThickness;
    property JointRadius: Double read FJointRadius write SetJointRadius;
    property GuideSize: Double read FGuideSize write SetGuideSize;
    property CameraX: Double read FCameraX write SetCameraX;
    property CameraY: Double read FCameraY write SetCameraY;
    property CameraZ: Double read FCameraZ write SetCameraZ;
    property CameraFocalLength: Double read FCameraFocalLength write SetCameraFocalLength;
    property CameraDepthOfView: Double read FCameraDepthOfView write SetCameraDepthOfView;
    property LightX: Double read FLightX write SetLightX;
    property LightY: Double read FLightY write SetLightY;
    property LightZ: Double read FLightZ write SetLightZ;
    property ActorInterval: Integer read FActorInterval write SetActorInterval;
    property ModelStyle: string read FModelStyle write FModelStyle;
    property PrintedColor: TColor read FPrintedColor write FPrintedColor;
    property ServoColor: TColor read FServoColor write FServoColor;
    property MetalColor: TColor read FMetalColor write FMetalColor;
    property LinkWidth: Double read FLinkWidth write FLinkWidth;
    property LinkDepth: Double read FLinkDepth write FLinkDepth;
    property LinkSpacing: Double read FLinkSpacing write FLinkSpacing;
    property ServoWidth: Double read FServoWidth write FServoWidth;
    property ServoHeight: Double read FServoHeight write FServoHeight;
    property ServoDepth: Double read FServoDepth write FServoDepth;
    property GripperWidth: Double read FGripperWidth write FGripperWidth;
    property GripperLength: Double read FGripperLength write FGripperLength;
  end;

procedure Register;

implementation

function IsLinearJoint(const AJvalue: string): Boolean;
begin
  Result := SameText(AJvalue, 'linear') or
    SameText(AJvalue, 'prismatic') or SameText(AJvalue, 'prismatica');
end;

function DominantAxisName(const AX, AY, AZ: Double): string;
begin
  if (Abs(AX) >= Abs(AY)) and (Abs(AX) >= Abs(AZ)) then
    Result := 'x'
  else if Abs(AY) >= Abs(AZ) then
    Result := 'y'
  else
    Result := 'z';
end;

function V3(const AX, AY, AZ: Double): TAIArmVector3;
begin
  Result.X := AX;
  Result.Y := AY;
  Result.Z := AZ;
end;

function V3Add(const A, B: TAIArmVector3): TAIArmVector3;
begin
  Result := V3(A.X + B.X, A.Y + B.Y, A.Z + B.Z);
end;

function V3Sub(const A, B: TAIArmVector3): TAIArmVector3;
begin
  Result := V3(A.X - B.X, A.Y - B.Y, A.Z - B.Z);
end;

function V3Scale(const A: TAIArmVector3; const S: Double): TAIArmVector3;
begin
  Result := V3(A.X * S, A.Y * S, A.Z * S);
end;

function V3Dot(const A, B: TAIArmVector3): Double;
begin
  Result := (A.X * B.X) + (A.Y * B.Y) + (A.Z * B.Z);
end;

function V3Cross(const A, B: TAIArmVector3): TAIArmVector3;
begin
  Result := V3(
    (A.Y * B.Z) - (A.Z * B.Y),
    (A.Z * B.X) - (A.X * B.Z),
    (A.X * B.Y) - (A.Y * B.X)
  );
end;

function V3Len(const A: TAIArmVector3): Double;
begin
  Result := Sqrt(Sqr(A.X) + Sqr(A.Y) + Sqr(A.Z));
end;

function V3Normalize(const A: TAIArmVector3): TAIArmVector3;
var
  L: Double;
begin
  L := V3Len(A);
  if L < 1e-12 then
    Exit(V3(0, 0, 1));
  Result := V3Scale(A, 1 / L);
end;

function V3ProjectOnPlane(const A, ANormal: TAIArmVector3): TAIArmVector3;
var
  N: TAIArmVector3;
begin
  N := V3Normalize(ANormal);
  Result := V3Sub(A, V3Scale(N, V3Dot(A, N)));
end;

function V3RotateAroundAxis(const A, ANormal: TAIArmVector3; const AAngleRad: Double): TAIArmVector3;
var
  N: TAIArmVector3;
  C, S: Double;
begin
  N := V3Normalize(ANormal);
  C := Cos(AAngleRad);
  S := Sin(AAngleRad);
  Result := V3Add(
    V3Add(
      V3Scale(A, C),
      V3Scale(V3Cross(N, A), S)
    ),
    V3Scale(N, V3Dot(N, A) * (1 - C))
  );
end;

function V3SignedAngleAroundAxis(const AFrom, ATo, ANormal: TAIArmVector3): Double;
var
  FromProj, ToProj, N: TAIArmVector3;
  FromLen, ToLen, DotValue, CrossDot: Double;
begin
  N := V3Normalize(ANormal);
  FromProj := V3ProjectOnPlane(AFrom, N);
  ToProj := V3ProjectOnPlane(ATo, N);
  FromLen := V3Len(FromProj);
  ToLen := V3Len(ToProj);
  if (FromLen < 1e-12) or (ToLen < 1e-12) then
    Exit(0);
  FromProj := V3Scale(FromProj, 1 / FromLen);
  ToProj := V3Scale(ToProj, 1 / ToLen);
  DotValue := EnsureRange(V3Dot(FromProj, ToProj), -1, 1);
  CrossDot := V3Dot(N, V3Cross(FromProj, ToProj));
  Result := ArcTan2(CrossDot, DotValue);
end;

function JsonFloat(const AValue: Double): string;
var
  FS: TFormatSettings;
begin
  FS := DefaultFormatSettings;
  FS.DecimalSeparator := '.';
  Result := FloatToStr(AValue, FS);
end;

procedure Register;
begin
  RegisterComponents('AI Industrial', [TAI_Arm_robot, TAI_Arm_robotViewer]);
end;

{ TAI_Arm_robotJoint }

procedure TAI_Arm_robotJoint.NotifyOwnerChanged;
begin
  if Assigned(Collection) and (Collection.Owner is TAI_Arm_robot) then
    TAI_Arm_robot(Collection.Owner).DoChanged;
end;

procedure TAI_Arm_robotJoint.SetJointType(const AValue: string);
var
  LValue: string;
begin
  LValue := LowerCase(Trim(AValue));
  if LValue = '' then
    LValue := 'angular';
  if (LValue = 'revolute') or (LValue = 'rotational') then
    LValue := 'angular'
  else if (LValue = 'linear') or (LValue = 'prismatica') then
    LValue := 'prismatic';
  if FJointType = LValue then Exit;
  FJointType := LValue;
  NotifyOwnerChanged;
end;

procedure TAI_Arm_robotJoint.SetAxisX(AValue: Double);
begin
  if FAxisX = AValue then Exit;
  FAxisX := AValue;
  NotifyOwnerChanged;
end;

procedure TAI_Arm_robotJoint.SetAxisY(AValue: Double);
begin
  if FAxisY = AValue then Exit;
  FAxisY := AValue;
  NotifyOwnerChanged;
end;

procedure TAI_Arm_robotJoint.SetAxisZ(AValue: Double);
begin
  if FAxisZ = AValue then Exit;
  FAxisZ := AValue;
  NotifyOwnerChanged;
end;

procedure TAI_Arm_robotJoint.SetDirectionX(AValue: Double);
begin
  if FDirectionX = AValue then Exit;
  FDirectionX := AValue;
  NotifyOwnerChanged;
end;

procedure TAI_Arm_robotJoint.SetDirectionY(AValue: Double);
begin
  if FDirectionY = AValue then Exit;
  FDirectionY := AValue;
  NotifyOwnerChanged;
end;

procedure TAI_Arm_robotJoint.SetDirectionZ(AValue: Double);
begin
  if FDirectionZ = AValue then Exit;
  FDirectionZ := AValue;
  NotifyOwnerChanged;
end;

procedure TAI_Arm_robotJoint.SetLength(AValue: Double);
begin
  if FLength = AValue then Exit;
  FLength := AValue;
  NotifyOwnerChanged;
end;

procedure TAI_Arm_robotJoint.SetAngleDeg(AValue: Double);
begin
  if FAngleDeg = AValue then Exit;
  FAngleDeg := AValue;
  NotifyOwnerChanged;
end;

procedure TAI_Arm_robotJoint.SetMinAngleDeg(AValue: Double);
begin
  if FMinAngleDeg = AValue then Exit;
  FMinAngleDeg := AValue;
  NotifyOwnerChanged;
end;

procedure TAI_Arm_robotJoint.SetMaxAngleDeg(AValue: Double);
begin
  if FMaxAngleDeg = AValue then Exit;
  FMaxAngleDeg := AValue;
  NotifyOwnerChanged;
end;

procedure TAI_Arm_robotJoint.SetDefaultAngleDeg(AValue: Double);
begin
  if FDefaultAngleDeg = AValue then Exit;
  FDefaultAngleDeg := AValue;
  NotifyOwnerChanged;
end;

procedure TAI_Arm_robotJoint.SetIsBase(AValue: Boolean);
begin
  if FIsBase = AValue then Exit;
  FIsBase := AValue;
  NotifyOwnerChanged;
end;

procedure TAI_Arm_robotJoint.SetVisible(AValue: Boolean);
begin
  if FVisible = AValue then Exit;
  FVisible := AValue;
  NotifyOwnerChanged;
end;

procedure TAI_Arm_robotJoint.SetColor(AValue: TColor);
begin
  if FColor = AValue then Exit;
  FColor := AValue;
  NotifyOwnerChanged;
end;

procedure TAI_Arm_robotJoint.SetLinkRadius(AValue: Double);
begin
  if FLinkRadius = AValue then Exit;
  FLinkRadius := AValue;
  NotifyOwnerChanged;
end;

procedure TAI_Arm_robotJoint.SetJointRadius(AValue: Double);
begin
  if FJointRadius = AValue then Exit;
  FJointRadius := AValue;
  NotifyOwnerChanged;
end;

procedure TAI_Arm_robotJoint.Assign(Source: TPersistent);
var
  Src: TAI_Arm_robotJoint;
begin
  if Source is TAI_Arm_robotJoint then
  begin
    Src := TAI_Arm_robotJoint(Source);
    FName := Src.Name;
    FJointType := Src.JointType;
    FAxisX := Src.AxisX;
    FAxisY := Src.AxisY;
    FAxisZ := Src.AxisZ;
    FDirectionX := Src.DirectionX;
    FDirectionY := Src.DirectionY;
    FDirectionZ := Src.DirectionZ;
    FLength := Src.Length;
    FAngleDeg := Src.AngleDeg;
    FMinAngleDeg := Src.MinAngleDeg;
    FMaxAngleDeg := Src.MaxAngleDeg;
    FDefaultAngleDeg := Src.DefaultAngleDeg;
    FIsBase := Src.IsBase;
    FVisible := Src.Visible;
    FColor := Src.Color;
    FLinkRadius := Src.LinkRadius;
    FJointRadius := Src.JointRadius;
    NotifyOwnerChanged;
  end
  else
    inherited Assign(Source);
end;

{ TAI_Arm_robotJoints }

constructor TAI_Arm_robotJoints.Create(AOwner: TPersistent);
begin
  inherited Create(AOwner, TAI_Arm_robotJoint);
end;

function TAI_Arm_robotJoints.GetItem(Index: Integer): TAI_Arm_robotJoint;
begin
  Result := TAI_Arm_robotJoint(inherited GetItem(Index));
end;

function TAI_Arm_robotJoints.Add: TAI_Arm_robotJoint;
begin
  Result := TAI_Arm_robotJoint(inherited Add);
end;

{ TAI_Arm_robot }

constructor TAI_Arm_robot.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  Category := ccModel;
  FPrompt := 'Component TAI_Arm_robot models a 3D robotic arm chain with arbitrary joint axes. ' +
    'Published properties: BaseX, BaseY, BaseZ, TargetX, TargetY, TargetZ, Tolerance, MaxIterations, UseLimits, Joints. ' +
    'Each joint exposes Name, AxisX, AxisY, AxisZ, Length, AngleDeg, DefaultAngleDeg, MinAngleDeg, MaxAngleDeg, IsBase, Visible and Color. ' +
    'Methods: AddJoint, ClearJoints, LoadSixAxisSample, ResetAngles, ForwardKinematics, SolveInverseKinematics, GetEndEffectorPosition, ToJSON. ' +
    'Viewer: the base is fixed in space and the first joint acts as a fixed pedestal/turntable. ' +
    'AI Agent: use this component to calculate and solve the servo angles of a robotic arm from a target XYZ point and to export the arm configuration.';
  FJoints := TAI_Arm_robotJoints.Create(Self);
  FBaseX := 0;
  FBaseY := 0;
  FBaseZ := 0;
  FTargetX := 10;
  FTargetY := 0;
  FTargetZ := 15;
  FTolerance := 0.05;
  FMaxIterations := 80;
  FUseLimits := True;
  FLastEndX := 0;
  FLastEndY := 0;
  FLastEndZ := 0;
  FViewBackgroundColor := clBlack;
  FViewArmColor := $CCCCCC;
  FViewJointColor := $CCCCCC;
  FViewGridColor := $444444;
  FViewBaseColor := $CCCCCC;
  FViewBaseHighlightColor := clWhite;
  FViewShowGrid := False;
  FViewShowJointLabels := True;
  FViewShowAxes := True;
  FViewAutoFit := True;
  FViewScale := 14.0;
  FViewAzimuthDeg := -40;
  FViewElevationDeg := 18;
  FViewShowBasePedestal := True;
  FViewBaseRadius := 0.5;
  FViewBaseInnerRadius := 0.3;
  FViewBaseHeight := 3;
  FViewLinkThickness := 1;
  FViewJointRadius := 0.5;
  FViewGuideSize := 10;
  FViewCameraX := 15;
  FViewCameraY := 15;
  FViewCameraZ := 15;
  FViewCameraFocalLength := 50;
  FViewCameraDepthOfView := 100;
  FViewLightX := 100;
  FViewLightY := 100;
  FViewLightZ := 0;
  FViewActorInterval := 100;
  FViewModelStyle := 'sg90_printed';
  FViewPrintedColor := clWhite;
  FViewServoColor := $B44614;
  FViewMetalColor := $C0C0C0;
  FViewLinkWidth := 1.3;
  FViewLinkDepth := 0.25;
  FViewLinkSpacing := 1.0;
  FViewServoWidth := 1.4;
  FViewServoHeight := 2.3;
  FViewServoDepth := 1.1;
  FViewGripperWidth := 3.4;
  FViewGripperLength := 2.8;
  ClearError;
end;

destructor TAI_Arm_robot.Destroy;
begin
  FJoints.Free;
  inherited Destroy;
end;

procedure TAI_Arm_robot.DoChanged;
begin
  if FLoading then
    Exit;
  if Assigned(FOnChange) then
    FOnChange(Self);
end;

procedure TAI_Arm_robot.SetBaseX(AValue: Double);
begin
  if FBaseX = AValue then Exit;
  FBaseX := AValue;
  DoChanged;
end;

procedure TAI_Arm_robot.SetBaseY(AValue: Double);
begin
  if FBaseY = AValue then Exit;
  FBaseY := AValue;
  DoChanged;
end;

procedure TAI_Arm_robot.SetBaseZ(AValue: Double);
begin
  if FBaseZ = AValue then Exit;
  FBaseZ := AValue;
  DoChanged;
end;

procedure TAI_Arm_robot.SetTargetX(AValue: Double);
begin
  if FTargetX = AValue then Exit;
  FTargetX := AValue;
  DoChanged;
end;

procedure TAI_Arm_robot.SetTargetY(AValue: Double);
begin
  if FTargetY = AValue then Exit;
  FTargetY := AValue;
  DoChanged;
end;

procedure TAI_Arm_robot.SetTargetZ(AValue: Double);
begin
  if FTargetZ = AValue then Exit;
  FTargetZ := AValue;
  DoChanged;
end;

procedure TAI_Arm_robot.SetTolerance(AValue: Double);
begin
  if FTolerance = AValue then Exit;
  FTolerance := AValue;
  DoChanged;
end;

procedure TAI_Arm_robot.SetMaxIterations(AValue: Integer);
begin
  if FMaxIterations = AValue then Exit;
  FMaxIterations := AValue;
  DoChanged;
end;

procedure TAI_Arm_robot.SetUseLimits(AValue: Boolean);
begin
  if FUseLimits = AValue then Exit;
  FUseLimits := AValue;
  DoChanged;
end;

function TAI_Arm_robot.GetJointCount: Integer;
begin
  Result := FJoints.Count;
end;

procedure TAI_Arm_robot.ClearJoints;
begin
  FJoints.Clear;
  DoChanged;
end;

function TAI_Arm_robot.AddJoint(const AName: string; AX, AY, AZ, ALength: Double): TAI_Arm_robotJoint;
begin
  Result := FJoints.Add;
  Result.Name := AName;
  Result.JointType := 'angular';
  Result.AxisX := AX;
  Result.AxisY := AY;
  Result.AxisZ := AZ;
  Result.DirectionX := 0;
  Result.DirectionY := 1;
  Result.DirectionZ := 0;
  Result.Length := ALength;
  Result.AngleDeg := 0;
  Result.DefaultAngleDeg := 0;
  Result.MinAngleDeg := -180;
  Result.MaxAngleDeg := 180;
  Result.Visible := True;
  Result.Color := clLime;
  Result.LinkRadius := 0;
  Result.JointRadius := 0;
  DoChanged;
end;

procedure TAI_Arm_robot.LoadSixAxisSample;
begin
  ClearJoints;

  AddJoint('Girar base', 0, 0, 1, 2.4).Color := clWhite;
  FJoints[0].DirectionY := 0;
  FJoints[0].DirectionZ := 1;
  FJoints[0].IsBase := False;
  FJoints[0].DefaultAngleDeg := 0;
  FJoints[0].MinAngleDeg := -90;
  FJoints[0].MaxAngleDeg := 90;
  FJoints[0].LinkRadius := 0.5;
  FJoints[0].JointRadius := 0.6;

  AddJoint('Ombro', 0, 1, 0, 6.5).Color := clWhite;
  FJoints[1].DirectionY := 0;
  FJoints[1].DirectionZ := 1;
  FJoints[1].JointType := 'angular';
  FJoints[1].DefaultValue := 25;
  FJoints[1].MinValue := -20;
  FJoints[1].MaxValue := 110;
  FJoints[1].LinkRadius := 0.5;
  FJoints[1].JointRadius := 0.5;

  AddJoint('Cotovelo', 0, 1, 0, 6.0).Color := clWhite;
  FJoints[2].DirectionY := 0;
  FJoints[2].DirectionZ := 1;
  FJoints[2].JointType := 'angular';
  FJoints[2].DefaultValue := -40;
  FJoints[2].MinValue := -120;
  FJoints[2].MaxValue := 120;
  FJoints[2].LinkRadius := 0.5;
  FJoints[2].JointRadius := 0.5;

  AddJoint('Punho vertical', 0, 1, 0, 4.5).Color := clWhite;
  FJoints[3].DirectionY := 0;
  FJoints[3].DirectionZ := 1;
  FJoints[3].JointType := 'angular';
  FJoints[3].DefaultValue := -75;
  FJoints[3].MinValue := -120;
  FJoints[3].MaxValue := 120;
  FJoints[3].LinkRadius := 0.5;
  FJoints[3].JointRadius := 0.5;

  AddJoint('Girar punho', 0, 0, 1, 1.5).Color := clWhite;
  FJoints[4].DirectionY := 0;
  FJoints[4].DirectionZ := 1;
  FJoints[4].DefaultAngleDeg := 0;
  FJoints[4].MinAngleDeg := -135;
  FJoints[4].MaxAngleDeg := 135;
  FJoints[4].LinkRadius := 0.5;
  FJoints[4].JointRadius := 0.5;

  AddJoint('Garra', 0, 1, 0, 0.8).Color := clWhite;
  FJoints[5].DirectionY := 0;
  FJoints[5].DirectionZ := 1;
  FJoints[5].JointType := 'angular';
  FJoints[5].DefaultAngleDeg := 18;
  FJoints[5].MinAngleDeg := 0;
  FJoints[5].MaxAngleDeg := 35;
  FJoints[5].LinkRadius := 0.5;
  FJoints[5].JointRadius := 0.5;

  ResetAngles;
  DoChanged;
end;

function JsonObjectValue(const AParent: TJSONObject; const AName: string): TJSONObject;
var
  Data: TJSONData;
begin
  Result := nil;
  if not Assigned(AParent) then
    Exit;

  Data := AParent.Find(AName);
  if Data is TJSONObject then
    Result := TJSONObject(Data);
end;

function JsonArrayValue(const AParent: TJSONObject; const AName: string): TJSONArray;
var
  Data: TJSONData;
begin
  Result := nil;
  if not Assigned(AParent) then
    Exit;

  Data := AParent.Find(AName);
  if Data is TJSONArray then
    Result := TJSONArray(Data);
end;

function JsonFloatValue(const AParent: TJSONObject; const AName: string; const ADefault: Double): Double;
var
  Data: TJSONData;
begin
  Result := ADefault;
  if not Assigned(AParent) then
    Exit;

  Data := AParent.Find(AName);
  if Assigned(Data) then
    Result := Data.AsFloat;
end;

function JsonIntValue(const AParent: TJSONObject; const AName: string; const ADefault: Integer): Integer;
var
  Data: TJSONData;
begin
  Result := ADefault;
  if not Assigned(AParent) then
    Exit;

  Data := AParent.Find(AName);
  if Assigned(Data) then
    Result := Data.AsInteger;
end;

function JsonBoolValue(const AParent: TJSONObject; const AName: string; const ADefault: Boolean): Boolean;
var
  Data: TJSONData;
begin
  Result := ADefault;
  if not Assigned(AParent) then
    Exit;

  Data := AParent.Find(AName);
  if Assigned(Data) then
    Result := Data.AsBoolean;
end;

function JsonStringValue(const AParent: TJSONObject; const AName, ADefault: string): string;
var
  Data: TJSONData;
begin
  Result := ADefault;
  if not Assigned(AParent) then
    Exit;

  Data := AParent.Find(AName);
  if Assigned(Data) then
    Result := Data.AsString;
end;

function JsonVectorValue(const AParent: TJSONObject; const AName: string; const ADefault: TAIArmVector3): TAIArmVector3;
var
  Obj: TJSONObject;
begin
  Result := ADefault;
  Obj := JsonObjectValue(AParent, AName);
  if not Assigned(Obj) then
    Exit;
  Result.X := JsonFloatValue(Obj, 'x', Result.X);
  Result.Y := JsonFloatValue(Obj, 'y', Result.Y);
  Result.Z := JsonFloatValue(Obj, 'z', Result.Z);
end;

function JsonColorValue(const AParent: TJSONObject; const AName: string; const ADefault: TColor): TColor;
begin
  Result := TColor(JsonIntValue(AParent, AName, ColorToRGB(ADefault)));
end;

procedure TAI_Arm_robot.LoadFromJSON(const AJSON: string);
var
  RootData: TJSONData;
  RootObj, VisualObj, CameraObj, LightObj, ActorObj: TJSONObject;
  JointsArr: TJSONArray;
  JointData: TJSONData;
  JointObj, AxisObj, DirectionObj: TJSONObject;
  I: Integer;
  Joint: TAI_Arm_robotJoint;
  BaseVec, TargetVec, ViewVec: TAIArmVector3;
  AxisName: string;
begin
  RootData := GetJSON(AJSON);
  try
    if not (RootData is TJSONObject) then
      raise Exception.Create('JSON invalido para AI_Arm_robot.');

    RootObj := TJSONObject(RootData);

    FLoading := True;
    try
      VisualObj := JsonObjectValue(RootObj, 'visual');
      if Assigned(VisualObj) then
      begin
        FViewBackgroundColor := JsonColorValue(VisualObj, 'background_color', FViewBackgroundColor);
        FViewArmColor := JsonColorValue(VisualObj, 'arm_color', FViewArmColor);
        FViewJointColor := JsonColorValue(VisualObj, 'joint_color', FViewJointColor);
        FViewGridColor := JsonColorValue(VisualObj, 'grid_color', FViewGridColor);
        FViewBaseColor := JsonColorValue(VisualObj, 'base_color', FViewBaseColor);
        FViewBaseHighlightColor := JsonColorValue(VisualObj, 'base_highlight_color', FViewBaseHighlightColor);
        FViewShowGrid := JsonBoolValue(VisualObj, 'show_grid', FViewShowGrid);
        FViewShowJointLabels := JsonBoolValue(VisualObj, 'show_joint_labels', FViewShowJointLabels);
        FViewShowAxes := JsonBoolValue(VisualObj, 'show_axes', FViewShowAxes);
        FViewAutoFit := JsonBoolValue(VisualObj, 'auto_fit', FViewAutoFit);
        FViewScale := JsonFloatValue(VisualObj, 'scale', FViewScale);
        FViewAzimuthDeg := JsonFloatValue(VisualObj, 'azimuth_deg', FViewAzimuthDeg);
        FViewElevationDeg := JsonFloatValue(VisualObj, 'elevation_deg', FViewElevationDeg);
        FViewShowBasePedestal := JsonBoolValue(VisualObj, 'show_base_pedestal', FViewShowBasePedestal);
        FViewBaseRadius := JsonFloatValue(VisualObj, 'base_radius', FViewBaseRadius);
        FViewBaseInnerRadius := JsonFloatValue(VisualObj, 'base_inner_radius', FViewBaseInnerRadius);
        FViewBaseHeight := JsonFloatValue(VisualObj, 'base_height', FViewBaseHeight);
        FViewLinkThickness := JsonFloatValue(VisualObj, 'link_thickness', FViewLinkThickness);
        FViewJointRadius := JsonFloatValue(VisualObj, 'joint_radius', FViewJointRadius);
        FViewGuideSize := JsonFloatValue(VisualObj, 'guide_size', FViewGuideSize);

        CameraObj := JsonObjectValue(VisualObj, 'camera');
        if Assigned(CameraObj) then
        begin
          ViewVec := JsonVectorValue(CameraObj, 'position',
            V3(FViewCameraX, FViewCameraY, FViewCameraZ));
          FViewCameraX := ViewVec.X;
          FViewCameraY := ViewVec.Y;
          FViewCameraZ := ViewVec.Z;
          FViewCameraFocalLength := JsonFloatValue(CameraObj, 'focal_length', FViewCameraFocalLength);
          FViewCameraDepthOfView := JsonFloatValue(CameraObj, 'depth_of_view', FViewCameraDepthOfView);
        end;

        LightObj := JsonObjectValue(VisualObj, 'light');
        if Assigned(LightObj) then
        begin
          ViewVec := JsonVectorValue(LightObj, 'position',
            V3(FViewLightX, FViewLightY, FViewLightZ));
          FViewLightX := ViewVec.X;
          FViewLightY := ViewVec.Y;
          FViewLightZ := ViewVec.Z;
        end;

        ActorObj := JsonObjectValue(VisualObj, 'actor');
        if Assigned(ActorObj) then
          FViewActorInterval := JsonIntValue(ActorObj, 'interval', FViewActorInterval);

        FViewModelStyle := JsonStringValue(VisualObj, 'model_style', FViewModelStyle);
        FViewPrintedColor := JsonColorValue(VisualObj, 'printed_color', FViewPrintedColor);
        FViewServoColor := JsonColorValue(VisualObj, 'servo_color', FViewServoColor);
        FViewMetalColor := JsonColorValue(VisualObj, 'metal_color', FViewMetalColor);
        FViewLinkWidth := JsonFloatValue(VisualObj, 'link_width', FViewLinkWidth);
        FViewLinkDepth := JsonFloatValue(VisualObj, 'link_depth', FViewLinkDepth);
        FViewLinkSpacing := JsonFloatValue(VisualObj, 'link_spacing', FViewLinkSpacing);
        FViewServoWidth := JsonFloatValue(VisualObj, 'servo_width', FViewServoWidth);
        FViewServoHeight := JsonFloatValue(VisualObj, 'servo_height', FViewServoHeight);
        FViewServoDepth := JsonFloatValue(VisualObj, 'servo_depth', FViewServoDepth);
        FViewGripperWidth := JsonFloatValue(VisualObj, 'gripper_width', FViewGripperWidth);
        FViewGripperLength := JsonFloatValue(VisualObj, 'gripper_length', FViewGripperLength);
      end;

      BaseVec := JsonVectorValue(RootObj, 'base', V3(0, 0, 0));
      FBaseX := BaseVec.X;
      FBaseY := BaseVec.Y;
      FBaseZ := BaseVec.Z;

      TargetVec := JsonVectorValue(RootObj, 'target', V3(10, 0, 15));
      FTargetX := TargetVec.X;
      FTargetY := TargetVec.Y;
      FTargetZ := TargetVec.Z;

      FTolerance := JsonFloatValue(RootObj, 'tolerance', FTolerance);
      FMaxIterations := JsonIntValue(RootObj, 'max_iterations', FMaxIterations);
      FUseLimits := JsonBoolValue(RootObj, 'use_limits', FUseLimits);

      ClearJoints;
      JointsArr := JsonArrayValue(RootObj, 'joints');
      if Assigned(JointsArr) then
      begin
        for I := 0 to JointsArr.Count - 1 do
        begin
          JointData := JointsArr.Items[I];
          if not (JointData is TJSONObject) then
            Continue;

          JointObj := TJSONObject(JointData);
          AxisObj := JsonObjectValue(JointObj, 'rotation_axis');
          if not Assigned(AxisObj) then
            AxisObj := JsonObjectValue(JointObj, 'axis');
          DirectionObj := JsonObjectValue(JointObj, 'direction');
          Joint := AddJoint(
            JsonStringValue(JointObj, 'name', Format('Joint%d', [I])),
            JsonFloatValue(AxisObj, 'x', 0),
            JsonFloatValue(AxisObj, 'y', 0),
            JsonFloatValue(AxisObj, 'z', 1),
            JsonFloatValue(JointObj, 'length', 0)
          );
          Joint.DirectionX := JsonFloatValue(DirectionObj, 'x', 0);
          Joint.DirectionY := JsonFloatValue(DirectionObj, 'y', 1);
          Joint.DirectionZ := JsonFloatValue(DirectionObj, 'z', 0);
          Joint.JointType := JsonStringValue(JointObj, 'joint_type', 'angular');
          AxisName := LowerCase(JsonStringValue(JointObj, 'joint_axis', ''));
          if AxisName <> '' then
          begin
            if IsLinearJoint(Joint.JointType) then
            begin
              Joint.DirectionX := Ord(AxisName = 'x');
              Joint.DirectionY := Ord(AxisName = 'y');
              Joint.DirectionZ := Ord(AxisName = 'z');
            end
            else
            begin
              Joint.AxisX := Ord(AxisName = 'x');
              Joint.AxisY := Ord(AxisName = 'y');
              Joint.AxisZ := Ord(AxisName = 'z');
            end;
          end;
          Joint.Value := JsonFloatValue(JointObj, 'value',
            JsonFloatValue(JointObj, 'angle_deg', 0));
          Joint.DefaultValue := JsonFloatValue(JointObj, 'default_value',
            JsonFloatValue(JointObj, 'default_angle_deg', Joint.Value));
          Joint.MinValue := JsonFloatValue(JointObj, 'min_value',
            JsonFloatValue(JointObj, 'min_angle_deg', -180));
          Joint.MaxValue := JsonFloatValue(JointObj, 'max_value',
            JsonFloatValue(JointObj, 'max_angle_deg', 180));
          Joint.IsBase := JsonBoolValue(JointObj, 'is_base', I = 0);
          Joint.Visible := JsonBoolValue(JointObj, 'visible', True);
          Joint.Color := JsonColorValue(JointObj, 'color', Joint.Color);
          Joint.LinkRadius := JsonFloatValue(JointObj, 'link_radius', Joint.LinkRadius);
          Joint.JointRadius := JsonFloatValue(JointObj, 'joint_radius', Joint.JointRadius);
        end;
      end;
    finally
      FLoading := False;
    end;
  finally
    RootData.Free;
  end;

  DoChanged;
end;

procedure TAI_Arm_robot.LoadFromJSONFile(const AFileName: string);
var
  SL: TStringList;
begin
  SL := TStringList.Create;
  try
    SL.LoadFromFile(AFileName);
    LoadFromJSON(SL.Text);
  finally
    SL.Free;
  end;
end;

procedure TAI_Arm_robot.SaveToJSONFile(const AFileName: string);
var
  SL: TStringList;
begin
  SL := TStringList.Create;
  try
    SL.Text := ToJSON;
    SL.SaveToFile(AFileName);
  finally
    SL.Free;
  end;
end;

procedure TAI_Arm_robot.ResetAngles;
var
  I: Integer;
begin
  for I := 0 to FJoints.Count - 1 do
    FJoints[I].AngleDeg := FJoints[I].DefaultAngleDeg;
  DoChanged;
end;

procedure TAI_Arm_robot.NormalizeJointAxes(var AAxis: TAIArmVector3);
begin
  AAxis := V3Normalize(AAxis);
end;

procedure TAI_Arm_robot.BuildPose(out APoints, AFrameX, AFrameY, AFrameZ: TAIArmVector3Array);
var
  I: Integer;
  Pos: TAIArmVector3;
  CurX: TAIArmVector3;
  CurY: TAIArmVector3;
  CurZ: TAIArmVector3;
  AxisWorld: TAIArmVector3;
  DirectionWorld: TAIArmVector3;
  Joint: TAI_Arm_robotJoint;
begin
  SetLength(APoints, FJoints.Count + 1);
  SetLength(AFrameX, FJoints.Count);
  SetLength(AFrameY, FJoints.Count);
  SetLength(AFrameZ, FJoints.Count);

  Pos := V3(FBaseX, FBaseY, FBaseZ);
  CurX := V3(1, 0, 0);
  CurY := V3(0, 1, 0);
  CurZ := V3(0, 0, 1);
  APoints[0] := Pos;

  for I := 0 to FJoints.Count - 1 do
  begin
    Joint := FJoints[I];
    AFrameX[I] := CurX;
    AFrameY[I] := CurY;
    AFrameZ[I] := CurZ;

    AxisWorld := V3Normalize(V3Add(V3Add(
      V3Scale(CurX, Joint.AxisX),
      V3Scale(CurY, Joint.AxisY)),
      V3Scale(CurZ, Joint.AxisZ)));
    if V3Len(AxisWorld) < 1e-12 then
      AxisWorld := V3(0, 0, 1);

    if not IsLinearJoint(Joint.JointType) then
    begin
      CurX := V3RotateAroundAxis(CurX, AxisWorld, DegToRad(Joint.AngleDeg));
      CurY := V3RotateAroundAxis(CurY, AxisWorld, DegToRad(Joint.AngleDeg));
      CurZ := V3RotateAroundAxis(CurZ, AxisWorld, DegToRad(Joint.AngleDeg));
    end;

    DirectionWorld := V3Normalize(V3Add(V3Add(
      V3Scale(CurX, Joint.DirectionX),
      V3Scale(CurY, Joint.DirectionY)),
      V3Scale(CurZ, Joint.DirectionZ)));
    if IsLinearJoint(Joint.JointType) then
      Pos := V3Add(Pos, V3Scale(DirectionWorld, Joint.Length + Joint.Value))
    else
      Pos := V3Add(Pos, V3Scale(DirectionWorld, Joint.Length));
    APoints[I + 1] := Pos;
  end;

  FLastEndX := Pos.X;
  FLastEndY := Pos.Y;
  FLastEndZ := Pos.Z;
end;

procedure TAI_Arm_robot.ClampJointAngle(AJoint: TAI_Arm_robotJoint);
begin
  if not FUseLimits then
    Exit;
  if AJoint.AngleDeg < AJoint.MinAngleDeg then
    AJoint.FAngleDeg := AJoint.MinAngleDeg
  else
  if AJoint.AngleDeg > AJoint.MaxAngleDeg then
    AJoint.FAngleDeg := AJoint.MaxAngleDeg;
end;

function TAI_Arm_robot.SolveCCDOnce(const ATarget: TAIArmVector3): Boolean;
var
  Points, FrameX, FrameY, FrameZ: TAIArmVector3Array;
  I: Integer;
  Joint: TAI_Arm_robotJoint;
  AxisWorld, DirectionWorld, FromVec, ToVec: TAIArmVector3;
  DeltaRad, MoveDelta: Double;
begin
  Result := False;
  if FJoints.Count = 0 then
    Exit;

  BuildPose(Points, FrameX, FrameY, FrameZ);

  for I := FJoints.Count - 1 downto 0 do
  begin
    Joint := FJoints[I];
    if not Joint.Visible then
      Continue;

    if Joint.IsBase then
      Continue;

    if IsLinearJoint(Joint.JointType) then
    begin
      DirectionWorld := V3Normalize(V3Add(V3Add(
        V3Scale(FrameX[I], Joint.DirectionX),
        V3Scale(FrameY[I], Joint.DirectionY)),
        V3Scale(FrameZ[I], Joint.DirectionZ)));
      MoveDelta := V3Dot(V3Sub(ATarget, Points[High(Points)]), DirectionWorld);
      Joint.FAngleDeg := Joint.Value + MoveDelta;
      ClampJointAngle(Joint);
      BuildPose(Points, FrameX, FrameY, FrameZ);
      Continue;
    end;

    AxisWorld := V3Normalize(V3Add(V3Add(
      V3Scale(FrameX[I], Joint.AxisX),
      V3Scale(FrameY[I], Joint.AxisY)),
      V3Scale(FrameZ[I], Joint.AxisZ)));
    if V3Len(AxisWorld) < 1e-12 then
      AxisWorld := V3(0, 0, 1);

    FromVec := V3ProjectOnPlane(V3Sub(Points[High(Points)], Points[I]), AxisWorld);
    ToVec := V3ProjectOnPlane(V3Sub(ATarget, Points[I]), AxisWorld);
    if (V3Len(FromVec) < 1e-12) or (V3Len(ToVec) < 1e-12) then
      Continue;

    DeltaRad := V3SignedAngleAroundAxis(FromVec, ToVec, AxisWorld);
    Joint.FAngleDeg := Joint.AngleDeg + RadToDeg(DeltaRad);
    ClampJointAngle(Joint);

    BuildPose(Points, FrameX, FrameY, FrameZ);
  end;

  Result := True;
end;

function TAI_Arm_robot.ForwardKinematics(out APoints: TAIArmVector3Array): Boolean;
var
  DummyX, DummyY, DummyZ: TAIArmVector3Array;
begin
  BuildPose(APoints, DummyX, DummyY, DummyZ);
  Result := True;
end;

procedure TAI_Arm_robot.GetPoseFrames(out APoints, AFrameX, AFrameY,
  AFrameZ: TAIArmVector3Array);
begin
  BuildPose(APoints, AFrameX, AFrameY, AFrameZ);
end;

function TAI_Arm_robot.GetEndEffectorPosition: TAIArmVector3;
var
  Points: TAIArmVector3Array;
begin
  ForwardKinematics(Points);
  if Length(Points) > 0 then
    Result := Points[High(Points)]
  else
    Result := V3(FBaseX, FBaseY, FBaseZ);
end;

function TAI_Arm_robot.SolveInverseKinematics(AX, AY, AZ: Double): Boolean;
begin
  Result := SolveInverseKinematics(V3(AX, AY, AZ));
end;

function TAI_Arm_robot.SolveInverseKinematics(const ATarget: TAIArmVector3): Boolean;
var
  Iter: Integer;
  Points: TAIArmVector3Array;
  Dist: Double;
begin
  ClearError;
  if FJoints.Count = 0 then
  begin
    SetError('The arm has no joints configured.');
    Exit(False);
  end;

  FTargetX := ATarget.X;
  FTargetY := ATarget.Y;
  FTargetZ := ATarget.Z;

  for Iter := 0 to FMaxIterations - 1 do
  begin
    SolveCCDOnce(ATarget);
    ForwardKinematics(Points);
    Dist := V3Len(V3Sub(Points[High(Points)], ATarget));
    if Dist <= FTolerance then
    begin
      FLastResult := Format('IK solved in %d iterations. Distance=%s', [Iter + 1, JsonFloat(Dist)]);
      FLastSuccess := True;
      DoChanged;
      Exit(True);
    end;
  end;

  ForwardKinematics(Points);
  Dist := V3Len(V3Sub(Points[High(Points)], ATarget));
  if Dist <= FTolerance then
  begin
    FLastResult := 'IK solved at limit distance=' + JsonFloat(Dist);
    FLastSuccess := True;
    DoChanged;
    Exit(True);
  end;

  SetError('IK did not converge. Final distance=' + JsonFloat(Dist));
  DoChanged;
  Result := False;
end;

function TAI_Arm_robot.ToJSON: string;
var
  I: Integer;
  Joint: TAI_Arm_robotJoint;
  JointAxisName: string;
begin
  Result := '{';
  Result += '"base": {"x": ' + JsonFloat(FBaseX) + ', "y": ' + JsonFloat(FBaseY) + ', "z": ' + JsonFloat(FBaseZ) + '},';
  Result += '"target": {"x": ' + JsonFloat(FTargetX) + ', "y": ' + JsonFloat(FTargetY) + ', "z": ' + JsonFloat(FTargetZ) + '},';
  Result += '"tolerance": ' + JsonFloat(FTolerance) + ',';
  Result += '"max_iterations": ' + IntToStr(FMaxIterations) + ',';
  Result += '"use_limits": ' + LowerCase(BoolToStr(FUseLimits, True)) + ',';
  Result += '"visual": {';
  Result += '"background_color": ' + IntToStr(ColorToRGB(FViewBackgroundColor)) + ',';
  Result += '"arm_color": ' + IntToStr(ColorToRGB(FViewArmColor)) + ',';
  Result += '"joint_color": ' + IntToStr(ColorToRGB(FViewJointColor)) + ',';
  Result += '"grid_color": ' + IntToStr(ColorToRGB(FViewGridColor)) + ',';
  Result += '"base_color": ' + IntToStr(ColorToRGB(FViewBaseColor)) + ',';
  Result += '"base_highlight_color": ' + IntToStr(ColorToRGB(FViewBaseHighlightColor)) + ',';
  Result += '"show_grid": ' + LowerCase(BoolToStr(FViewShowGrid, True)) + ',';
  Result += '"show_joint_labels": ' + LowerCase(BoolToStr(FViewShowJointLabels, True)) + ',';
  Result += '"show_axes": ' + LowerCase(BoolToStr(FViewShowAxes, True)) + ',';
  Result += '"auto_fit": ' + LowerCase(BoolToStr(FViewAutoFit, True)) + ',';
  Result += '"scale": ' + JsonFloat(FViewScale) + ',';
  Result += '"azimuth_deg": ' + JsonFloat(FViewAzimuthDeg) + ',';
  Result += '"elevation_deg": ' + JsonFloat(FViewElevationDeg) + ',';
  Result += '"show_base_pedestal": ' + LowerCase(BoolToStr(FViewShowBasePedestal, True)) + ',';
  Result += '"base_radius": ' + JsonFloat(FViewBaseRadius) + ',';
  Result += '"base_inner_radius": ' + JsonFloat(FViewBaseInnerRadius) + ',';
  Result += '"base_height": ' + JsonFloat(FViewBaseHeight) + ',';
  Result += '"link_thickness": ' + JsonFloat(FViewLinkThickness) + ',';
  Result += '"joint_radius": ' + JsonFloat(FViewJointRadius) + ',';
  Result += '"guide_size": ' + JsonFloat(FViewGuideSize) + ',';
  Result += '"camera": {';
  Result += '"position": {"x": ' + JsonFloat(FViewCameraX) + ', "y": ' + JsonFloat(FViewCameraY) + ', "z": ' + JsonFloat(FViewCameraZ) + '},';
  Result += '"focal_length": ' + JsonFloat(FViewCameraFocalLength) + ',';
  Result += '"depth_of_view": ' + JsonFloat(FViewCameraDepthOfView);
  Result += '},';
  Result += '"light": {';
  Result += '"position": {"x": ' + JsonFloat(FViewLightX) + ', "y": ' + JsonFloat(FViewLightY) + ', "z": ' + JsonFloat(FViewLightZ) + '}';
  Result += '},';
  Result += '"actor": {"interval": ' + IntToStr(FViewActorInterval) + '},';
  Result += '"model_style": "' + StringReplace(FViewModelStyle, '"', '\"', [rfReplaceAll]) + '",';
  Result += '"printed_color": ' + IntToStr(ColorToRGB(FViewPrintedColor)) + ',';
  Result += '"servo_color": ' + IntToStr(ColorToRGB(FViewServoColor)) + ',';
  Result += '"metal_color": ' + IntToStr(ColorToRGB(FViewMetalColor)) + ',';
  Result += '"link_width": ' + JsonFloat(FViewLinkWidth) + ',';
  Result += '"link_depth": ' + JsonFloat(FViewLinkDepth) + ',';
  Result += '"link_spacing": ' + JsonFloat(FViewLinkSpacing) + ',';
  Result += '"servo_width": ' + JsonFloat(FViewServoWidth) + ',';
  Result += '"servo_height": ' + JsonFloat(FViewServoHeight) + ',';
  Result += '"servo_depth": ' + JsonFloat(FViewServoDepth) + ',';
  Result += '"gripper_width": ' + JsonFloat(FViewGripperWidth) + ',';
  Result += '"gripper_length": ' + JsonFloat(FViewGripperLength);
  Result += '},';
  Result += '"joints": [';
  for I := 0 to FJoints.Count - 1 do
  begin
    Joint := FJoints[I];
    if IsLinearJoint(Joint.JointType) then
      JointAxisName := DominantAxisName(Joint.DirectionX, Joint.DirectionY, Joint.DirectionZ)
    else
      JointAxisName := DominantAxisName(Joint.AxisX, Joint.AxisY, Joint.AxisZ);
    if I > 0 then
      Result += ',';
    Result += '{';
    Result += '"name": "' + StringReplace(Joint.Name, '"', '\"', [rfReplaceAll]) + '",';
    Result += '"joint_type": "' + StringReplace(Joint.JointType, '"', '\"', [rfReplaceAll]) + '",';
    Result += '"joint_axis": "' + JointAxisName + '",';
    Result += '"direction": {"x": ' + JsonFloat(Joint.DirectionX) + ', "y": ' + JsonFloat(Joint.DirectionY) + ', "z": ' + JsonFloat(Joint.DirectionZ) + '},';
    Result += '"rotation_axis": {"x": ' + JsonFloat(Joint.AxisX) + ', "y": ' + JsonFloat(Joint.AxisY) + ', "z": ' + JsonFloat(Joint.AxisZ) + '},';
    Result += '"length": ' + JsonFloat(Joint.Length) + ',';
    Result += '"value": ' + JsonFloat(Joint.Value) + ',';
    Result += '"default_value": ' + JsonFloat(Joint.DefaultValue) + ',';
    Result += '"min_value": ' + JsonFloat(Joint.MinValue) + ',';
    Result += '"max_value": ' + JsonFloat(Joint.MaxValue) + ',';
    Result += '"is_base": ' + LowerCase(BoolToStr(Joint.IsBase, True)) + ',';
    Result += '"visible": ' + LowerCase(BoolToStr(Joint.Visible, True)) + ',';
    Result += '"color": ' + IntToStr(ColorToRGB(Joint.Color)) + ',';
    Result += '"link_radius": ' + JsonFloat(Joint.LinkRadius) + ',';
    Result += '"joint_radius": ' + JsonFloat(Joint.JointRadius);
    Result += '}';
  end;
  Result += ']';
  Result += '}';
end;

function TAI_Arm_robot.ToSetupPrompt: string;
begin
  Result := BuildAISetupText;
end;

function TAI_Arm_robot.ToSetupText: string;
begin
  Result := BuildAISetupText;
end;

procedure TAI_Arm_robot.UpdatePromptFromJoints;
begin
  FPrompt := BuildAISetupText;
end;

function TAI_Arm_robot.BuildAISetupText: string;
var
  I: Integer;
  Joint: TAI_Arm_robotJoint;
begin
  Result := 'AI_Arm_robot configuration' + LineEnding;
  Result += 'Base: (' + JsonFloat(FBaseX) + ', ' + JsonFloat(FBaseY) + ', ' + JsonFloat(FBaseZ) + ')' + LineEnding;
  Result += 'Target: (' + JsonFloat(FTargetX) + ', ' + JsonFloat(FTargetY) + ', ' + JsonFloat(FTargetZ) + ')' + LineEnding;
  Result += 'Tolerance: ' + JsonFloat(FTolerance) + LineEnding;
  Result += 'MaxIterations: ' + IntToStr(FMaxIterations) + LineEnding;
  Result += 'UseLimits: ' + BoolToStr(FUseLimits, True) + LineEnding;
  Result += 'Joints:' + LineEnding;
  for I := 0 to FJoints.Count - 1 do
  begin
    Joint := FJoints[I];
    Result += Format('  %d. %s type=%s direction=(%s,%s,%s) rotation_axis=(%s,%s,%s) len=%s value=%s' + LineEnding,
      [I,
       Joint.Name,
       Joint.JointType,
       JsonFloat(Joint.DirectionX), JsonFloat(Joint.DirectionY), JsonFloat(Joint.DirectionZ),
       JsonFloat(Joint.AxisX), JsonFloat(Joint.AxisY), JsonFloat(Joint.AxisZ),
       JsonFloat(Joint.Length),
       JsonFloat(Joint.AngleDeg)]);
  end;
end;

{ TAI_Arm_robotViewer }

constructor TAI_Arm_robotViewer.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  ControlStyle := ControlStyle + [csOpaque];
  Width := 640;
  Height := 480;
  DoubleBuffered := True;
  ParentColor := False;
  FBackgroundColor := clBlack;
  FArmColor := $CCCCCC;
  FJointColor := $CCCCCC;
  FGridColor := $444444;
  FBaseColor := $CCCCCC;
  FBaseHighlightColor := clWhite;
  FShowGrid := False;
  FShowJointLabels := True;
  FShowAxes := True;
  FAutoFit := True;
  FScale := 14.0;
  FAzimuthDeg := -40;
  FElevationDeg := 18;
  FShowBasePedestal := True;
  FBaseRadius := 0.5;
  FBaseInnerRadius := 0.3;
  FBaseHeight := 3;
  FLinkThickness := 1;
  FJointRadius := 0.5;
  FGuideSize := 10;
  FCameraX := 15;
  FCameraY := 15;
  FCameraZ := 15;
  FCameraFocalLength := 50;
  FCameraDepthOfView := 100;
  FLightX := 100;
  FLightY := 100;
  FLightZ := 0;
  FActorInterval := 100;
  FModelStyle := 'sg90_printed';
  FPrintedColor := clWhite;
  FServoColor := $B44614;
  FMetalColor := $C0C0C0;
  FLinkWidth := 1.3;
  FLinkDepth := 0.25;
  FLinkSpacing := 1.0;
  FServoWidth := 1.4;
  FServoHeight := 2.3;
  FServoDepth := 1.1;
  FGripperWidth := 3.4;
  FGripperLength := 2.8;

  FGLScene := TGLScene.Create(Self);
  FGLSceneViewer := TGLSceneViewer.Create(Self);
  FGLSceneViewer.Parent := Self;
  FGLSceneViewer.Align := alClient;
  FGLSceneViewer.Buffer.BackgroundColor := FBackgroundColor;
  FGLSceneViewer.Buffer.AmbientColor.Color := VectorMake(0.2, 0.2, 0.2, 1.0);
  FGLSceneViewer.OnMouseDown := @GLMouseDown;
  FGLSceneViewer.OnMouseMove := @GLMouseMove;
  FGLSceneViewer.OnMouseWheel := @GLMouseWheel;
  FGLSceneViewer.Visible := True;

  FGLRoot := TGLDummyCube.CreateAsChild(FGLScene.Objects);
  FGLRoot.Name := 'Componentes';
  FGLRoot.Visible := True;

  FGLCamera := TGLCamera.CreateAsChild(FGLScene.Objects);
  FGLCamera.Name := 'camara';
  FGLCamera.Position.SetPoint(FCameraX, FCameraY, FCameraZ);
  FGLCamera.FocalLength := FCameraFocalLength;
  FGLCamera.DepthOfView := FCameraDepthOfView;
  FGLCamera.TargetObject := FGLRoot;
  FGLSceneViewer.Camera := FGLCamera;

  BuildScene;
end;

procedure TAI_Arm_robotViewer.SetArm(AValue: TAI_Arm_robot);
begin
  if FArm = AValue then Exit;
  if FArm <> nil then
    FArm.RemoveFreeNotification(Self);
  FArm := AValue;
  if FArm <> nil then
    FArm.FreeNotification(Self);
  BuildScene;
end;

procedure TAI_Arm_robotViewer.ClearScene;
begin
  if Assigned(FGLCamera) then
    FGLCamera.TargetObject := FGLRoot;
  if Assigned(FGLRoot) then
    FGLRoot.DeleteChildren;
  FGLGuide := nil;
  FGLLight := nil;
  FGLActor := nil;
  FGLPedestal := nil;
  FGLBaseBody := nil;
  FGLGripperPalm := nil;
  FGLGripperJawA := nil;
  FGLGripperJawB := nil;
  SetLength(FGLJointNodes, 0);
  SetLength(FGLJointLinks, 0);
  SetLength(FGLJointSpheres, 0);
  SetLength(FGLJointPlateA, 0);
  SetLength(FGLJointPlateB, 0);
  SetLength(FGLServoBodies, 0);
  SetLength(FAppliedAngles, 0);
  FSceneReady := False;
end;

procedure TAI_Arm_robotViewer.ApplyObjectColor(const AObject: TGLSceneObject;
  const AColor: TColor);
begin
  if not Assigned(AObject) then Exit;
  AObject.Material.FrontProperties.Diffuse.Color := ConvertWinColor(AColor);
  AObject.Material.FrontProperties.Ambient.Color := ConvertWinColor(AColor);
  AObject.Material.FrontProperties.Specular.Color := clrWhite;
  AObject.Material.FrontProperties.Shininess := 64;
end;

procedure TAI_Arm_robotViewer.ApplyAppearance;
var
  I: Integer;
  LJointColor: TColor;
begin
  if not Assigned(FGLSceneViewer) then Exit;
  FGLSceneViewer.Buffer.BackgroundColor := FBackgroundColor;
  FGLSceneViewer.Buffer.AmbientColor.Color := VectorMake(0.2, 0.2, 0.2, 1.0);

  if Assigned(FGLRoot) then
  begin
    if Assigned(FGLGuide) then
      FGLGuide.ShowAxes := FShowAxes;
    for I := 0 to High(FGLJointLinks) do
    begin
      if Assigned(FArm) and (I < FArm.JointCount) then
        LJointColor := FArm.Joints[I].Color
      else
        LJointColor := FArmColor;
      ApplyObjectColor(FGLJointLinks[I], LJointColor);
    end;
    for I := 0 to High(FGLJointSpheres) do
    begin
      if Assigned(FArm) and (I < FArm.JointCount) then
        LJointColor := FArm.Joints[I].Color
      else
        LJointColor := FJointColor;
      ApplyObjectColor(FGLJointSpheres[I], LJointColor);
    end;
    for I := 0 to High(FGLJointPlateA) do
    begin
      ApplyObjectColor(FGLJointPlateA[I], FPrintedColor);
      ApplyObjectColor(FGLJointPlateB[I], FPrintedColor);
      ApplyObjectColor(FGLServoBodies[I], FServoColor);
    end;
    ApplyObjectColor(FGLGripperPalm, FPrintedColor);
    ApplyObjectColor(FGLGripperJawA, FPrintedColor);
    ApplyObjectColor(FGLGripperJawB, FPrintedColor);
    ApplyObjectColor(FGLBaseBody, FPrintedColor);
    if Assigned(FGLPedestal) then
    begin
      ApplyObjectColor(FGLPedestal, FBaseColor);
      FGLPedestal.Visible := FShowBasePedestal;
    end;
  end;
end;

procedure TAI_Arm_robotViewer.BuildScene;
var
  I: Integer;
  Joint: TAI_Arm_robotJoint;
  JointNode, NextNode: TGLDummyCube;
  Link: TGLCylinder;
  Sphere: TGLSphere;
  PlateA, PlateB, ServoBody: TGLCube;
  Pedestal: TGLAnnulus;
  Radius: Double;
  PhotoStyle: Boolean;
begin
  if not Assigned(FGLScene) or not Assigned(FGLRoot) then Exit;

  ClearScene;
  FGLRoot.Position.SetPoint(0, 0, 0);

  FGLGuide := TGLDummyCube.CreateAsChild(FGLRoot);
  FGLGuide.Name := 'Guia';
  FGLGuide.CubeSize := Max(0.1, FGuideSize);
  FGLGuide.ShowAxes := FShowAxes;
  if Assigned(FArm) then
    FGLGuide.Position.SetPoint(FArm.BaseX, FArm.BaseZ, -FArm.BaseY);

  FGLLight := TGLLightSource.CreateAsChild(FGLGuide);
  FGLLight.Name := 'GLLightSource1';
  FGLLight.Position.SetPoint(FLightX, FLightY, FLightZ);
  FGLLight.ConstAttenuation := 1;
  FGLLight.Diffuse.Color := clrWhite;
  FGLLight.SpotCutOff := 180;
  FGLLight.LightStyle := lsOmni;

  FGLActor := TGLActor.CreateAsChild(FGLGuide);
  FGLActor.Name := 'GLActor1';
  FGLActor.Interval := Max(1, FActorInterval);

  Radius := Max(0.1, FBaseRadius);

  FGLBaseBody := TGLCylinder.CreateAsChild(FGLGuide);
  FGLBaseBody.Name := 'BASE_CORPO';
  FGLBaseBody.BottomRadius := Radius;
  FGLBaseBody.TopRadius := Radius;
  FGLBaseBody.Height := Max(0.5, FBaseHeight);
  FGLBaseBody.Position.SetPoint(0, FGLBaseBody.Height * 0.5, 0);
  FGLBaseBody.Slices := 32;
  FGLBaseBody.Stacks := 1;
  FGLBaseBody.Visible := FShowBasePedestal;

  Pedestal := TGLAnnulus.CreateAsChild(FGLGuide);
  Pedestal.Name := 'BASE';
  Pedestal.BottomRadius := Radius * 1.05;
  Pedestal.TopRadius := Radius * 1.05;
  Pedestal.BottomInnerRadius := EnsureRange(FBaseInnerRadius, 0, Radius * 0.95);
  Pedestal.TopInnerRadius := Pedestal.BottomInnerRadius;
  Pedestal.Height := Max(0.25, FBaseHeight * 0.16);
  Pedestal.Position.SetPoint(0, FGLBaseBody.Height + (Pedestal.Height * 0.5), 0);
  Pedestal.Slices := 32;
  Pedestal.Stacks := 1;
  Pedestal.Visible := FShowBasePedestal;
  FGLPedestal := Pedestal;

  FGLCamera.Position.SetPoint(FCameraX, FCameraY, FCameraZ);
  FGLCamera.FocalLength := Max(1.0, FCameraFocalLength);
  FGLCamera.DepthOfView := Max(1.0, FCameraDepthOfView);
  FGLCamera.TargetObject := FGLBaseBody;

  if (FArm = nil) or (FArm.JointCount = 0) then
  begin
    ApplyAppearance;
    FSceneReady := True;
    Exit;
  end;

  SetLength(FGLJointNodes, FArm.JointCount);
  SetLength(FGLJointLinks, FArm.JointCount);
  SetLength(FGLJointSpheres, FArm.JointCount);
  SetLength(FGLJointPlateA, FArm.JointCount);
  SetLength(FGLJointPlateB, FArm.JointCount);
  SetLength(FGLServoBodies, FArm.JointCount);
  SetLength(FAppliedAngles, FArm.JointCount);

  JointNode := TGLDummyCube.CreateAsChild(Pedestal);
  JointNode.Position.SetPoint(0, Pedestal.Height * 0.5, 0);
  PhotoStyle := SameText(FModelStyle, 'sg90_printed');

  for I := 0 to FArm.JointCount - 1 do
  begin
    Joint := FArm.Joints[I];
    FAppliedAngles[I] := 0;
    FGLJointNodes[I] := JointNode;
    JointNode.Name := Format('EIXO_%d', [I]);
    JointNode.ShowAxes := FShowAxes and (I = 1);

    Sphere := TGLSphere.CreateAsChild(JointNode);
    Sphere.Name := Format('JUNTA_%d', [I]);
    if Joint.JointRadius > 0 then
      Sphere.Radius := Max(0.1, Joint.JointRadius)
    else
      Sphere.Radius := Max(0.2, FJointRadius);
    Sphere.Slices := 16;
    Sphere.Stacks := 16;
    Sphere.Visible := Joint.Visible;
    FGLJointSpheres[I] := Sphere;

    Link := TGLCylinder.CreateAsChild(JointNode);
    Link.Name := Format('BRACO_%d', [I]);
    if Joint.LinkRadius > 0 then
      Link.BottomRadius := Max(0.1, Joint.LinkRadius)
    else
      Link.BottomRadius := Max(0.1, FLinkThickness * 0.5);
    Link.TopRadius := Link.BottomRadius;
    Link.Height := Max(0.05, Joint.Length);
    Link.Slices := 20;
    Link.Stacks := 1;
    Link.Position.SetPoint(0, Link.Height * 0.5, 0);
    Link.Visible := (not PhotoStyle) and Joint.Visible and
      (not Joint.IsBase) and (Joint.Length > 0.001);
    FGLJointLinks[I] := Link;

    PlateA := TGLCube.CreateAsChild(JointNode);
    PlateA.Name := Format('PLACA_A_%d', [I]);
    PlateA.CubeWidth := Max(0.2, FLinkWidth);
    PlateA.CubeHeight := Max(0.05, Joint.Length);
    PlateA.CubeDepth := Max(0.05, FLinkDepth);
    PlateA.Position.SetPoint(0, PlateA.CubeHeight * 0.5, -FLinkSpacing * 0.5);
    PlateA.Visible := PhotoStyle and Joint.Visible and
      (I < FArm.JointCount - 1) and (Joint.Length > 0.001);
    FGLJointPlateA[I] := PlateA;

    PlateB := TGLCube.CreateAsChild(JointNode);
    PlateB.Name := Format('PLACA_B_%d', [I]);
    PlateB.CubeWidth := PlateA.CubeWidth;
    PlateB.CubeHeight := PlateA.CubeHeight;
    PlateB.CubeDepth := PlateA.CubeDepth;
    PlateB.Position.SetPoint(0, PlateB.CubeHeight * 0.5, FLinkSpacing * 0.5);
    PlateB.Visible := PlateA.Visible;
    FGLJointPlateB[I] := PlateB;

    ServoBody := TGLCube.CreateAsChild(JointNode);
    ServoBody.Name := Format('SERVO_SG90_%d', [I]);
    ServoBody.CubeWidth := Max(0.2, FServoWidth);
    ServoBody.CubeHeight := Max(0.2, FServoHeight);
    ServoBody.CubeDepth := Max(0.2, FServoDepth);
    ServoBody.Position.SetPoint(0, FServoHeight * 0.15, 0);
    ServoBody.Visible := PhotoStyle and Joint.Visible;
    FGLServoBodies[I] := ServoBody;

    if I < High(FGLJointNodes) then
    begin
      NextNode := TGLDummyCube.CreateAsChild(JointNode);
      NextNode.Position.SetPoint(0, Max(0.0, Joint.Length), 0);
      JointNode := NextNode;
    end;
  end;

  if PhotoStyle and (FArm.JointCount > 0) then
  begin
    JointNode := FGLJointNodes[FArm.JointCount - 1];

    FGLGripperPalm := TGLCube.CreateAsChild(JointNode);
    FGLGripperPalm.Name := 'GARRA_BASE';
    FGLGripperPalm.CubeWidth := Max(0.5, FGripperWidth);
    FGLGripperPalm.CubeHeight := 0.4;
    FGLGripperPalm.CubeDepth := Max(0.4, FServoDepth * 1.25);
    FGLGripperPalm.Position.SetPoint(0, 0.35, 0);

    FGLGripperJawA := TGLCube.CreateAsChild(JointNode);
    FGLGripperJawA.Name := 'GARRA_MANDIBULA_A';
    FGLGripperJawA.CubeWidth := 0.55;
    FGLGripperJawA.CubeHeight := Max(0.8, FGripperLength);
    FGLGripperJawA.CubeDepth := Max(0.3, FServoDepth * 0.7);
    FGLGripperJawA.Position.SetPoint(-FGripperWidth * 0.32,
      (FGripperLength * 0.5) + 0.4, 0);

    FGLGripperJawB := TGLCube.CreateAsChild(JointNode);
    FGLGripperJawB.Name := 'GARRA_MANDIBULA_B';
    FGLGripperJawB.CubeWidth := FGLGripperJawA.CubeWidth;
    FGLGripperJawB.CubeHeight := FGLGripperJawA.CubeHeight;
    FGLGripperJawB.CubeDepth := FGLGripperJawA.CubeDepth;
    FGLGripperJawB.Position.SetPoint(FGripperWidth * 0.32,
      (FGripperLength * 0.5) + 0.4, 0);
  end;

  ApplyAppearance;
  FSceneReady := True;
  SyncScene;
end;

procedure TAI_Arm_robotViewer.SyncScene;
var
  I: Integer;
  Joint: TAI_Arm_robotJoint;
  AxisLocal, AxisGL: TAIArmVector3;
  Delta: Double;
  MoveNode: TGLDummyCube;
begin
  if (FArm = nil) or not FSceneReady or (Length(FGLJointNodes) = 0) then
  begin
    if Assigned(FGLSceneViewer) then
      FGLSceneViewer.Invalidate;
    Exit;
  end;

  for I := 0 to FArm.JointCount - 1 do
  begin
    Joint := FArm.Joints[I];
    AxisLocal := V3(Joint.AxisX, Joint.AxisY, Joint.AxisZ);
    AxisGL := V3Normalize(V3(AxisLocal.X, AxisLocal.Z, -AxisLocal.Y));
    Delta := Joint.AngleDeg - FAppliedAngles[I];
    if (Abs(Delta) > 1e-8) and (not Joint.IsBase) then
    begin
      if IsLinearJoint(Joint.JointType) then
      begin
        if I < High(FGLJointNodes) then
          MoveNode := FGLJointNodes[I + 1]
        else
          MoveNode := FGLJointNodes[I];
        MoveNode.Position.X := MoveNode.Position.X +
          (Delta * Joint.DirectionX);
        MoveNode.Position.Y := MoveNode.Position.Y +
          (Delta * Joint.DirectionY);
        MoveNode.Position.Z := MoveNode.Position.Z +
          (Delta * Joint.DirectionZ);
        if Assigned(FGLJointPlateA[I]) then
        begin
          FGLJointPlateA[I].CubeHeight := Max(0.05,
            FGLJointPlateA[I].CubeHeight + Delta);
          FGLJointPlateB[I].CubeHeight := FGLJointPlateA[I].CubeHeight;
          FGLJointPlateA[I].Position.Y := FGLJointPlateA[I].Position.Y + (Delta * 0.5);
          FGLJointPlateB[I].Position.Y := FGLJointPlateB[I].Position.Y + (Delta * 0.5);
        end;
      end
      else if (I = FArm.JointCount - 1) and Assigned(FGLGripperJawA) then
      begin
        FGLGripperJawA.Roll(-Delta);
        FGLGripperJawB.Roll(Delta);
      end
      else
        FGLJointNodes[I].RotateAbsolute(
          AffineVectorMake(AxisGL.X, AxisGL.Y, AxisGL.Z), Delta);
    end;
    FAppliedAngles[I] := Joint.AngleDeg;
  end;

  if Assigned(FGLSceneViewer) then
    FGLSceneViewer.Invalidate;
end;

procedure TAI_Arm_robotViewer.SetBackgroundColor(AValue: TColor);
begin
  if FBackgroundColor = AValue then Exit;
  FBackgroundColor := AValue;
  Invalidate;
end;

procedure TAI_Arm_robotViewer.SetArmColor(AValue: TColor);
begin
  if FArmColor = AValue then Exit;
  FArmColor := AValue;
  Invalidate;
end;

procedure TAI_Arm_robotViewer.SetJointColor(AValue: TColor);
begin
  if FJointColor = AValue then Exit;
  FJointColor := AValue;
  Invalidate;
end;

procedure TAI_Arm_robotViewer.SetGridColor(AValue: TColor);
begin
  if FGridColor = AValue then Exit;
  FGridColor := AValue;
  Invalidate;
end;

procedure TAI_Arm_robotViewer.SetBaseColor(AValue: TColor);
begin
  if FBaseColor = AValue then Exit;
  FBaseColor := AValue;
  Invalidate;
end;

procedure TAI_Arm_robotViewer.SetBaseHighlightColor(AValue: TColor);
begin
  if FBaseHighlightColor = AValue then Exit;
  FBaseHighlightColor := AValue;
  Invalidate;
end;

procedure TAI_Arm_robotViewer.SetShowGrid(AValue: Boolean);
begin
  if FShowGrid = AValue then Exit;
  FShowGrid := AValue;
  Invalidate;
end;

procedure TAI_Arm_robotViewer.SetShowJointLabels(AValue: Boolean);
begin
  if FShowJointLabels = AValue then Exit;
  FShowJointLabels := AValue;
  Invalidate;
end;

procedure TAI_Arm_robotViewer.SetShowAxes(AValue: Boolean);
begin
  if FShowAxes = AValue then Exit;
  FShowAxes := AValue;
  Invalidate;
end;

procedure TAI_Arm_robotViewer.SetAutoFit(AValue: Boolean);
begin
  if FAutoFit = AValue then Exit;
  FAutoFit := AValue;
  Invalidate;
end;

procedure TAI_Arm_robotViewer.SetScale(AValue: Double);
begin
  if FScale = AValue then Exit;
  FScale := AValue;
  Invalidate;
end;

procedure TAI_Arm_robotViewer.SetAzimuthDeg(AValue: Double);
begin
  if FAzimuthDeg = AValue then Exit;
  FAzimuthDeg := AValue;
  Invalidate;
end;

procedure TAI_Arm_robotViewer.SetElevationDeg(AValue: Double);
begin
  if FElevationDeg = AValue then Exit;
  FElevationDeg := AValue;
  Invalidate;
end;

procedure TAI_Arm_robotViewer.SetShowBasePedestal(AValue: Boolean);
begin
  if FShowBasePedestal = AValue then Exit;
  FShowBasePedestal := AValue;
  Invalidate;
end;

procedure TAI_Arm_robotViewer.SetBaseRadius(AValue: Double);
begin
  if FBaseRadius = AValue then Exit;
  FBaseRadius := AValue;
  Invalidate;
end;

procedure TAI_Arm_robotViewer.SetBaseInnerRadius(AValue: Double);
begin
  if FBaseInnerRadius = AValue then Exit;
  FBaseInnerRadius := AValue;
  Invalidate;
end;

procedure TAI_Arm_robotViewer.SetBaseHeight(AValue: Double);
begin
  if FBaseHeight = AValue then Exit;
  FBaseHeight := AValue;
  Invalidate;
end;

procedure TAI_Arm_robotViewer.SetLinkThickness(AValue: Double);
begin
  if FLinkThickness = AValue then Exit;
  FLinkThickness := AValue;
  Invalidate;
end;

procedure TAI_Arm_robotViewer.SetJointRadius(AValue: Double);
begin
  if FJointRadius = AValue then Exit;
  FJointRadius := AValue;
  Invalidate;
end;

procedure TAI_Arm_robotViewer.SetGuideSize(AValue: Double);
begin
  if FGuideSize = AValue then Exit;
  FGuideSize := AValue;
  if Assigned(FGLGuide) then
    FGLGuide.CubeSize := Max(0.1, FGuideSize);
  Invalidate;
end;

procedure TAI_Arm_robotViewer.SetCameraX(AValue: Double);
begin
  if FCameraX = AValue then Exit;
  FCameraX := AValue;
  if Assigned(FGLCamera) then
    FGLCamera.Position.SetPoint(FCameraX, FCameraY, FCameraZ);
end;

procedure TAI_Arm_robotViewer.SetCameraY(AValue: Double);
begin
  if FCameraY = AValue then Exit;
  FCameraY := AValue;
  if Assigned(FGLCamera) then
    FGLCamera.Position.SetPoint(FCameraX, FCameraY, FCameraZ);
end;

procedure TAI_Arm_robotViewer.SetCameraZ(AValue: Double);
begin
  if FCameraZ = AValue then Exit;
  FCameraZ := AValue;
  if Assigned(FGLCamera) then
    FGLCamera.Position.SetPoint(FCameraX, FCameraY, FCameraZ);
end;

procedure TAI_Arm_robotViewer.SetCameraFocalLength(AValue: Double);
begin
  AValue := EnsureRange(AValue, 1.0, 1000.0);
  if FCameraFocalLength = AValue then Exit;
  FCameraFocalLength := AValue;
  if Assigned(FGLCamera) then
    FGLCamera.FocalLength := FCameraFocalLength;
  Invalidate;
end;

procedure TAI_Arm_robotViewer.SetCameraDepthOfView(AValue: Double);
begin
  AValue := Max(1.0, AValue);
  if FCameraDepthOfView = AValue then Exit;
  FCameraDepthOfView := AValue;
  if Assigned(FGLCamera) then
    FGLCamera.DepthOfView := FCameraDepthOfView;
end;

procedure TAI_Arm_robotViewer.SetLightX(AValue: Double);
begin
  if FLightX = AValue then Exit;
  FLightX := AValue;
  if Assigned(FGLLight) then
    FGLLight.Position.SetPoint(FLightX, FLightY, FLightZ);
end;

procedure TAI_Arm_robotViewer.SetLightY(AValue: Double);
begin
  if FLightY = AValue then Exit;
  FLightY := AValue;
  if Assigned(FGLLight) then
    FGLLight.Position.SetPoint(FLightX, FLightY, FLightZ);
end;

procedure TAI_Arm_robotViewer.SetLightZ(AValue: Double);
begin
  if FLightZ = AValue then Exit;
  FLightZ := AValue;
  if Assigned(FGLLight) then
    FGLLight.Position.SetPoint(FLightX, FLightY, FLightZ);
end;

procedure TAI_Arm_robotViewer.SetActorInterval(AValue: Integer);
begin
  AValue := Max(1, AValue);
  if FActorInterval = AValue then Exit;
  FActorInterval := AValue;
  if Assigned(FGLActor) then
    FGLActor.Interval := FActorInterval;
end;

procedure TAI_Arm_robotViewer.GLMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  FMouseDownX := X;
  FMouseDownY := Y;
end;

procedure TAI_Arm_robotViewer.GLMouseMove(Sender: TObject; Shift: TShiftState;
  X, Y: Integer);
begin
  if (ssLeft in Shift) and Assigned(FGLCamera) then
  begin
    FGLCamera.MoveAroundTarget(FMouseDownY - Y, FMouseDownX - X);
    FMouseDownX := X;
    FMouseDownY := Y;
    if Assigned(FGLSceneViewer) then
      FGLSceneViewer.Invalidate;
  end
  else
  begin
    FMouseDownX := X;
    FMouseDownY := Y;
  end;
end;

procedure TAI_Arm_robotViewer.GLMouseWheel(Sender: TObject; Shift: TShiftState;
  WheelDelta: Integer; MousePos: TPoint; var Handled: Boolean);
begin
  if Assigned(FGLCamera) then
  begin
    FGLCamera.FocalLength := EnsureRange(FGLCamera.FocalLength + (WheelDelta / 45), 5, 500);
    FCameraFocalLength := FGLCamera.FocalLength;
    if Assigned(FGLSceneViewer) then
      FGLSceneViewer.Invalidate;
    Handled := True;
  end;
end;

function TAI_Arm_robotViewer.ProjectPoint(const APoint: TAIArmVector3): TAIArmVector3;
var
  Az, El, X1, Y1, Z1: Double;
begin
  Az := DegToRad(FAzimuthDeg);
  El := DegToRad(FElevationDeg);

  X1 := (Cos(Az) * APoint.X) - (Sin(Az) * APoint.Y);
  Y1 := (Sin(Az) * APoint.X) + (Cos(Az) * APoint.Y);
  Z1 := APoint.Z;

  Result.X := X1;
  Result.Y := (Y1 * Cos(El)) - (Z1 * Sin(El));
  Result.Z := (Y1 * Sin(El)) + (Z1 * Cos(El));
end;

procedure TAI_Arm_robotViewer.DrawPlaceholder;
begin
  Canvas.Brush.Color := FBackgroundColor;
  Canvas.FillRect(ClientRect);
  Canvas.Font.Color := clSilver;
  Canvas.TextOut(12, 12, 'AI_Arm_robot: link the Arm property to a TAI_Arm_robot component');
end;

procedure TAI_Arm_robotViewer.Paint;
var
  Points: TAIArmVector3Array;
  Proj: array of TAIArmVector3;
  I: Integer;
  MinX, MaxX, MinY, MaxY: Double;
  ScaleValue, OffsetX, OffsetY, Margin: Double;
  SX1, SY1, SX2, SY2: Integer;
  P: TAIArmVector3;
  CenterX, CenterY: Double;
  Axis1, Axis2: TAIArmVector3;
  BaseCX, BaseCY, BaseR, BaseH, JointR, LinkW: Integer;
  PedestalTopY, PedestalBottomY: Integer;
  LineW: Integer;
  SegmentLen: Double;
  function ToScreenX(const AValue: Double): Integer;
  begin
    Result := Round((AValue * ScaleValue) + OffsetX);
  end;
  function ToScreenY(const AValue: Double): Integer;
  begin
    Result := Round(OffsetY - (AValue * ScaleValue));
  end;
  procedure DrawCircle(const CX, CY, R: Integer; const FillColor, BorderColor: TColor);
  begin
    Canvas.Brush.Color := FillColor;
    Canvas.Pen.Color := BorderColor;
    Canvas.Ellipse(CX - R, CY - R, CX + R, CY + R);
  end;
begin
  Canvas.Brush.Color := FBackgroundColor;
  Canvas.FillRect(ClientRect);
  Canvas.Pen.Style := psSolid;
  Canvas.Font.Color := clSilver;

  if (FArm = nil) or (FArm.JointCount = 0) then
  begin
    DrawPlaceholder;
    Exit;
  end;

  FArm.ForwardKinematics(Points);
  if Length(Points) = 0 then
  begin
    DrawPlaceholder;
    Exit;
  end;

  SetLength(Proj, Length(Points));
  MinX := 1e30;
  MaxX := -1e30;
  MinY := 1e30;
  MaxY := -1e30;
  for I := 0 to High(Points) do
  begin
    Proj[I] := ProjectPoint(Points[I]);
    if Proj[I].X < MinX then MinX := Proj[I].X;
    if Proj[I].X > MaxX then MaxX := Proj[I].X;
    if Proj[I].Y < MinY then MinY := Proj[I].Y;
    if Proj[I].Y > MaxY then MaxY := Proj[I].Y;
  end;

  if FAutoFit then
  begin
    Margin := 24;
    if Abs(MaxX - MinX) < 1e-6 then
      MaxX := MinX + 1;
    if Abs(MaxY - MinY) < 1e-6 then
      MaxY := MinY + 1;
    ScaleValue := Min(
      (ClientWidth - (Margin * 2)) / (MaxX - MinX),
      (ClientHeight - (Margin * 2)) / (MaxY - MinY)
    );
    if IsNan(ScaleValue) or IsInfinite(ScaleValue) or (ScaleValue <= 0) then
      ScaleValue := FScale;
  end
  else
    ScaleValue := FScale;

  CenterX := ClientWidth / 2;
  CenterY := ClientHeight / 2;
  OffsetX := CenterX - (((MinX + MaxX) / 2) * ScaleValue);
  BaseR := Max(16, Round(FBaseRadius * ScaleValue * 0.35));
  BaseH := Max(20, Round(FBaseHeight * ScaleValue * 0.35));
  JointR := Max(5, Round(FJointRadius * ScaleValue * 0.18));
  LinkW := Max(4, Round(FLinkThickness * ScaleValue * 0.12));
  PedestalBottomY := ClientHeight - 20;
  PedestalTopY := PedestalBottomY - (BaseH * 2);
  OffsetY := PedestalTopY + (Proj[0].Y * ScaleValue);

  BaseCX := ToScreenX(Proj[0].X);
  BaseCY := ToScreenY(Proj[0].Y);

  if FShowGrid then
  begin
    Canvas.Pen.Color := FGridColor;
    Canvas.Pen.Width := 1;
    Canvas.MoveTo(0, Round(CenterY));
    Canvas.LineTo(ClientWidth, Round(CenterY));
    Canvas.MoveTo(Round(CenterX), 0);
    Canvas.LineTo(Round(CenterX), ClientHeight);
  end;

  if FShowBasePedestal then
  begin
    Canvas.Pen.Width := 1;
    Canvas.Pen.Color := clBlack;
    Canvas.Brush.Color := FBaseColor;
    Canvas.RoundRect(BaseCX - BaseR, BaseCY + (JointR div 2), BaseCX + BaseR, PedestalBottomY, BaseR div 2, BaseR div 2);

    Canvas.Brush.Color := FBaseHighlightColor;
    Canvas.Ellipse(BaseCX - (BaseR div 2), BaseCY - (JointR div 2), BaseCX + (BaseR div 2), BaseCY + (JointR div 2));

    Canvas.Brush.Color := FBaseColor;
    Canvas.Pen.Color := clGray;
    Canvas.RoundRect(BaseCX - (BaseR div 3), BaseCY - (BaseH div 2), BaseCX + (BaseR div 3), BaseCY + (BaseH div 4), BaseR div 3, BaseR div 3);

    Canvas.Brush.Color := FBaseHighlightColor;
    Canvas.Ellipse(BaseCX - (BaseR div 2), BaseCY - (BaseR div 4), BaseCX + (BaseR div 2), BaseCY);
  end;

  for I := 0 to High(Proj) - 1 do
  begin
    SegmentLen := V3Len(V3Sub(Points[I + 1], Points[I]));
    SX1 := Round((Proj[I].X * ScaleValue) + OffsetX);
    SY1 := Round(OffsetY - (Proj[I].Y * ScaleValue));
    SX2 := Round((Proj[I + 1].X * ScaleValue) + OffsetX);
    SY2 := Round(OffsetY - (Proj[I + 1].Y * ScaleValue));
    if SegmentLen > 1e-6 then
    begin
      LineW := LinkW;
      if I = 0 then
        Inc(LineW);
      Canvas.Pen.Width := LineW;
      Canvas.Pen.Color := FArmColor;
      Canvas.Brush.Style := bsClear;
      Canvas.MoveTo(SX1, SY1);
      Canvas.LineTo(SX2, SY2);
      Canvas.Brush.Style := bsSolid;
    end;

    if I > 0 then
    begin
      DrawCircle(SX1, SY1, JointR, FJointColor, clBlack);
      if FShowJointLabels then
        Canvas.TextOut(SX1 + JointR + 4, SY1 - 8, IntToStr(I));
    end;

    if (I = 0) and FShowJointLabels then
      Canvas.TextOut(SX1 + JointR + 4, SY1 - 8, '0');
  end;

  SX2 := Round((Proj[High(Proj)].X * ScaleValue) + OffsetX);
  SY2 := Round(OffsetY - (Proj[High(Proj)].Y * ScaleValue));
  DrawCircle(SX2, SY2, JointR + 1, clRed, clBlack);
  if FShowJointLabels then
    Canvas.TextOut(SX2 + 8, SY2 - 8, 'EE');

  if FShowAxes then
  begin
    Canvas.Pen.Width := 2;
    Axis1 := ProjectPoint(V3(4, 0, 0));
    Axis2 := ProjectPoint(V3(0, 4, 0));
    Canvas.Pen.Color := clRed;
    Canvas.MoveTo(Round(CenterX), Round(CenterY));
    Canvas.LineTo(Round(CenterX + Axis1.X * 6), Round(CenterY - Axis1.Y * 6));
    Canvas.Pen.Color := clGreen;
    Canvas.MoveTo(Round(CenterX), Round(CenterY));
    Canvas.LineTo(Round(CenterX + Axis2.X * 6), Round(CenterY - Axis2.Y * 6));
  end;
end;

procedure TAI_Arm_robotViewer.Notification(AComponent: TComponent; Operation: TOperation);
begin
  inherited Notification(AComponent, Operation);
  if (Operation = opRemove) and (AComponent = FArm) then
    FArm := nil;
end;

end.
