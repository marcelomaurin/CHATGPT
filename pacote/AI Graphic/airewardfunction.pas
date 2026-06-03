unit airewardfunction;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, aibase;

type
  { TAIRewardFunction }

  TAIRewardFunction = class(TAIBaseComponent)
  private
    FTargetDistanceWeight: Double;
    FCollisionPenalty: Double;
  public
    constructor Create(AOwner: TComponent); override;
    function CalculateReward(const AState: string): Double;
  published
    property TargetDistanceWeight: Double read FTargetDistanceWeight write FTargetDistanceWeight;
    property CollisionPenalty: Double read FCollisionPenalty write FCollisionPenalty;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('AI Graphic', [TAIRewardFunction]);
end;

{ TAIRewardFunction }

constructor TAIRewardFunction.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FCategory := ccOther;
  FPrompt := 'Component TAIRewardFunction calculates dynamic rewards or penalties for agents. Properties: TargetDistanceWeight, CollisionPenalty. Methods: CalculateReward.';
  FTargetDistanceWeight := 1.0;
  FCollisionPenalty := -10.0;
  ClearError;
end;

function TAIRewardFunction.CalculateReward(const AState: string): Double;
begin
  Result := 0.0;
  Log(llDebug, 'Calculating reward for state.');
end;

end.
