unit aiphysicssimulator;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, aibase, LResources;

type
  { TAIPhysicsSimulator }

  TAIPhysicsSimulator = class(TAIBaseComponent)
  private
    FGravity: Double;
    FFriction: Double;
    FCollisionDetection: Boolean;
  public
    constructor Create(AOwner: TComponent); override;
    procedure ApplyForce(const AObjectID: string; const AX, AY, AZ: Double);
  published
    property Gravity: Double read FGravity write FGravity;
    property Friction: Double read FFriction write FFriction;
    property CollisionDetection: Boolean read FCollisionDetection write FCollisionDetection default True;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('AI Graphic', [TAIPhysicsSimulator]);
end;

{ TAIPhysicsSimulator }

constructor TAIPhysicsSimulator.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FCategory := ccOther;
  FPrompt := 'Component TAIPhysicsSimulator applies forces and handles collisions in simulations. Properties: Gravity, Friction, CollisionDetection. Methods: ApplyForce.';
  FGravity := -9.81;
  FFriction := 0.1;
  FCollisionDetection := True;
  ClearError;
end;

procedure TAIPhysicsSimulator.ApplyForce(const AObjectID: string; const AX, AY, AZ: Double);
begin
  Log(llDebug, Format('Applied force to object %s: (%.2f, %.2f, %.2f)', [AObjectID, AX, AY, AZ]));
end;

initialization
  {$I aiphysicssimulator_icon.lrs}

end.
