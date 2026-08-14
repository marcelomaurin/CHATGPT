unit airosagent;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Math, LResources, aibase, aiprocessrunner;

type
  { TAIROSAgent
    Lazarus/FPC wrapper around the ROS 2 command line interface.
    Read/introspection operations are enabled by default. Operations that can
    change robot state are blocked until AllowControl=True. }
  TAIROSAgent = class(TAIBaseComponent)
  private
    FRunner: TAIProcessRunner;
    FROS2Path: string;
    FWorkingDirectory: string;
    FTimeoutMs: Integer;
    FAllowControl: Boolean;
    function ExecuteROS(const AParams: array of string;
      ARequiresControl: Boolean = False): Boolean;
    function GetStdOutText: string;
    function GetStdErrText: string;
    function GetExitCode: Integer;
  public
    constructor Create(AOwner: TComponent); override;
    function CheckROS: Boolean;
    function ListNodes: Boolean;
    function ListTopics(AWithTypes: Boolean = True): Boolean;
    function ListServices(AWithTypes: Boolean = True): Boolean;
    function ListActions: Boolean;
    function TopicInfo(const ATopic: string): Boolean;
    function TopicEchoOnce(const ATopic: string): Boolean;
    function PublishOnce(const ATopic, AMessageType, AYAML: string): Boolean;
    function CallService(const AService, AServiceType, AYAML: string): Boolean;
    function GetParam(const ANode, AParamName: string): Boolean;
    function SetParam(const ANode, AParamName, AValue: string): Boolean;
    procedure Stop;
    property StdOutText: string read GetStdOutText;
    property StdErrText: string read GetStdErrText;
    property ExitCode: Integer read GetExitCode;
  published
    property ROS2Path: string read FROS2Path write FROS2Path;
    property WorkingDirectory: string read FWorkingDirectory write FWorkingDirectory;
    property TimeoutMs: Integer read FTimeoutMs write FTimeoutMs default 30000;
    property AllowControl: Boolean read FAllowControl write FAllowControl default False;
  end;

  { TAIRobotAgent
    High-level differential/mobile robot helper over a TAIROSAgent.
    Uses geometry_msgs/msg/Twist on CmdVelTopic. }
  TAIRobotAgent = class(TAIBaseComponent)
  private
    FROS: TAIROSAgent;
    FCmdVelTopic: string;
    FMaxLinearSpeed: Double;
    FMaxAngularSpeed: Double;
    procedure SetROS(AValue: TAIROSAgent);
    function FloatInvariant(const AValue: Double): string;
    function TwistYAML(ALinearX, AAngularZ: Double): string;
  protected
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
  public
    constructor Create(AOwner: TComponent); override;
    function Move(ALinearX, AAngularZ: Double): Boolean;
    function StopRobot: Boolean;
    function Forward(ASpeed: Double): Boolean;
    function Backward(ASpeed: Double): Boolean;
    function RotateLeft(AAngularSpeed: Double): Boolean;
    function RotateRight(AAngularSpeed: Double): Boolean;
  published
    property ROS: TAIROSAgent read FROS write SetROS;
    property CmdVelTopic: string read FCmdVelTopic write FCmdVelTopic;
    property MaxLinearSpeed: Double read FMaxLinearSpeed write FMaxLinearSpeed;
    property MaxAngularSpeed: Double read FMaxAngularSpeed write FMaxAngularSpeed;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('AI Robotics', [TAIROSAgent, TAIRobotAgent]);
end;

{ TAIROSAgent }

constructor TAIROSAgent.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FCategory := ccAction;
  FROS2Path := 'ros2';
  FTimeoutMs := 30000;
  FAllowControl := False;
  FRunner := TAIProcessRunner.Create(Self);
end;

function TAIROSAgent.ExecuteROS(const AParams: array of string;
  ARequiresControl: Boolean): Boolean;
begin
  ClearError;
  if ARequiresControl and (not FAllowControl) then
  begin
    SetError('AllowControl=False. Comando de controle ROS bloqueado.');
    Exit(False);
  end;

  FRunner.Executable := FROS2Path;
  FRunner.WorkingDirectory := FWorkingDirectory;
  FRunner.TimeoutMs := FTimeoutMs;
  Result := FRunner.Execute(AParams);
  FLastSuccess := Result;
  FLastResult := FRunner.StdOutText;
  if not Result then
    SetError(FRunner.LastError);
end;

function TAIROSAgent.GetStdOutText: string;
begin
  Result := FRunner.StdOutText;
end;

function TAIROSAgent.GetStdErrText: string;
begin
  Result := FRunner.StdErrText;
end;

function TAIROSAgent.GetExitCode: Integer;
begin
  Result := FRunner.LastExitCode;
end;

function TAIROSAgent.CheckROS: Boolean;
begin
  Result := ExecuteROS(['--help']);
end;

function TAIROSAgent.ListNodes: Boolean;
begin
  Result := ExecuteROS(['node', 'list']);
end;

function TAIROSAgent.ListTopics(AWithTypes: Boolean): Boolean;
begin
  if AWithTypes then
    Result := ExecuteROS(['topic', 'list', '-t'])
  else
    Result := ExecuteROS(['topic', 'list']);
end;

function TAIROSAgent.ListServices(AWithTypes: Boolean): Boolean;
begin
  if AWithTypes then
    Result := ExecuteROS(['service', 'list', '-t'])
  else
    Result := ExecuteROS(['service', 'list']);
end;

function TAIROSAgent.ListActions: Boolean;
begin
  Result := ExecuteROS(['action', 'list', '-t']);
end;

function TAIROSAgent.TopicInfo(const ATopic: string): Boolean;
begin
  if Trim(ATopic) = '' then
  begin
    SetError('Topic vazio.');
    Exit(False);
  end;
  Result := ExecuteROS(['topic', 'info', ATopic]);
end;

function TAIROSAgent.TopicEchoOnce(const ATopic: string): Boolean;
begin
  if Trim(ATopic) = '' then
  begin
    SetError('Topic vazio.');
    Exit(False);
  end;
  Result := ExecuteROS(['topic', 'echo', '--once', ATopic]);
end;

function TAIROSAgent.PublishOnce(const ATopic, AMessageType, AYAML: string): Boolean;
begin
  if (Trim(ATopic) = '') or (Trim(AMessageType) = '') then
  begin
    SetError('Topic e MessageType sao obrigatorios.');
    Exit(False);
  end;
  Result := ExecuteROS(['topic', 'pub', '--once', ATopic, AMessageType, AYAML], True);
end;

function TAIROSAgent.CallService(const AService, AServiceType, AYAML: string): Boolean;
begin
  if (Trim(AService) = '') or (Trim(AServiceType) = '') then
  begin
    SetError('Service e ServiceType sao obrigatorios.');
    Exit(False);
  end;
  Result := ExecuteROS(['service', 'call', AService, AServiceType, AYAML], True);
end;

function TAIROSAgent.GetParam(const ANode, AParamName: string): Boolean;
begin
  if (Trim(ANode) = '') or (Trim(AParamName) = '') then
  begin
    SetError('Node e ParamName sao obrigatorios.');
    Exit(False);
  end;
  Result := ExecuteROS(['param', 'get', ANode, AParamName]);
end;

function TAIROSAgent.SetParam(const ANode, AParamName, AValue: string): Boolean;
begin
  if (Trim(ANode) = '') or (Trim(AParamName) = '') then
  begin
    SetError('Node e ParamName sao obrigatorios.');
    Exit(False);
  end;
  Result := ExecuteROS(['param', 'set', ANode, AParamName, AValue], True);
end;

procedure TAIROSAgent.Stop;
begin
  FRunner.Stop;
end;

{ TAIRobotAgent }

constructor TAIRobotAgent.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FCategory := ccAction;
  FCmdVelTopic := '/cmd_vel';
  FMaxLinearSpeed := 1.0;
  FMaxAngularSpeed := 2.0;
end;

procedure TAIRobotAgent.SetROS(AValue: TAIROSAgent);
begin
  if FROS = AValue then Exit;
  if Assigned(FROS) then FROS.RemoveFreeNotification(Self);
  FROS := AValue;
  if Assigned(FROS) then FROS.FreeNotification(Self);
end;

procedure TAIRobotAgent.Notification(AComponent: TComponent; Operation: TOperation);
begin
  inherited Notification(AComponent, Operation);
  if (Operation = opRemove) and (AComponent = FROS) then
    FROS := nil;
end;

function TAIRobotAgent.FloatInvariant(const AValue: Double): string;
var
  FS: TFormatSettings;
begin
  FS := DefaultFormatSettings;
  FS.DecimalSeparator := '.';
  Result := FloatToStr(AValue, FS);
end;

function TAIRobotAgent.TwistYAML(ALinearX, AAngularZ: Double): string;
begin
  Result := '{linear: {x: ' + FloatInvariant(ALinearX) +
    ', y: 0.0, z: 0.0}, angular: {x: 0.0, y: 0.0, z: ' +
    FloatInvariant(AAngularZ) + '}}';
end;

function TAIRobotAgent.Move(ALinearX, AAngularZ: Double): Boolean;
begin
  ClearError;
  if FROS = nil then
  begin
    SetError('ROS nao configurado.');
    Exit(False);
  end;

  if FMaxLinearSpeed < 0 then FMaxLinearSpeed := Abs(FMaxLinearSpeed);
  if FMaxAngularSpeed < 0 then FMaxAngularSpeed := Abs(FMaxAngularSpeed);
  ALinearX := EnsureRange(ALinearX, -FMaxLinearSpeed, FMaxLinearSpeed);
  AAngularZ := EnsureRange(AAngularZ, -FMaxAngularSpeed, FMaxAngularSpeed);

  Result := FROS.PublishOnce(FCmdVelTopic, 'geometry_msgs/msg/Twist',
    TwistYAML(ALinearX, AAngularZ));
  FLastSuccess := Result;
  FLastResult := FROS.LastResult;
  if not Result then SetError(FROS.LastError);
end;

function TAIRobotAgent.StopRobot: Boolean;
begin
  Result := Move(0.0, 0.0);
end;

function TAIRobotAgent.Forward(ASpeed: Double): Boolean;
begin
  Result := Move(Abs(ASpeed), 0.0);
end;

function TAIRobotAgent.Backward(ASpeed: Double): Boolean;
begin
  Result := Move(-Abs(ASpeed), 0.0);
end;

function TAIRobotAgent.RotateLeft(AAngularSpeed: Double): Boolean;
begin
  Result := Move(0.0, Abs(AAngularSpeed));
end;

function TAIRobotAgent.RotateRight(AAngularSpeed: Double): Boolean;
begin
  Result := Move(0.0, -Abs(AAngularSpeed));
end;

initialization
  {$I airosagent_icon.lrs}

end.
