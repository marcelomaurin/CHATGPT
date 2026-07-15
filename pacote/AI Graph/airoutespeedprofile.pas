unit airoutespeedprofile;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Math, aibase, airoutegraph_types, airoutegraph_utils;

type
  { TAIRouteSpeedProfile }

  TAIRouteSpeedProfile = class(TAIBaseComponent)
  private
    FMotorwaySpeed: Double;
    FTrunkSpeed: Double;
    FPrimarySpeed: Double;
    FSecondarySpeed: Double;
    FTertiarySpeed: Double;
    FUnclassifiedSpeed: Double;
    FResidentialSpeed: Double;
    FServiceSpeed: Double;
    FTrackSpeed: Double;
    FDefaultSpeed: Double;
    FSpeedFactor: Double;
  public
    constructor Create(AOwner: TComponent); override;
    function EstimateSpeedKmH(const ARoadType: TAIRoadType; const AMaxSpeedKmH: Double): Double;
  published
    property MotorwaySpeed: Double read FMotorwaySpeed write FMotorwaySpeed;
    property TrunkSpeed: Double read FTrunkSpeed write FTrunkSpeed;
    property PrimarySpeed: Double read FPrimarySpeed write FPrimarySpeed;
    property SecondarySpeed: Double read FSecondarySpeed write FSecondarySpeed;
    property TertiarySpeed: Double read FTertiarySpeed write FTertiarySpeed;
    property UnclassifiedSpeed: Double read FUnclassifiedSpeed write FUnclassifiedSpeed;
    property ResidentialSpeed: Double read FResidentialSpeed write FResidentialSpeed;
    property ServiceSpeed: Double read FServiceSpeed write FServiceSpeed;
    property TrackSpeed: Double read FTrackSpeed write FTrackSpeed;
    property DefaultSpeed: Double read FDefaultSpeed write FDefaultSpeed;
    property SpeedFactor: Double read FSpeedFactor write FSpeedFactor;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('AI Graph', [TAIRouteSpeedProfile]);
end;

{ TAIRouteSpeedProfile }

constructor TAIRouteSpeedProfile.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FCategory := ccOther;
  FPrompt := 'Component TAIRouteSpeedProfile provides default speed estimates for road types when maxspeed is absent.';
  FMotorwaySpeed := 100;
  FTrunkSpeed := 90;
  FPrimarySpeed := 80;
  FSecondarySpeed := 70;
  FTertiarySpeed := 60;
  FUnclassifiedSpeed := 50;
  FResidentialSpeed := 30;
  FServiceSpeed := 20;
  FTrackSpeed := 15;
  FDefaultSpeed := 40;
  FSpeedFactor := 0.85;
end;

function TAIRouteSpeedProfile.EstimateSpeedKmH(const ARoadType: TAIRoadType;
  const AMaxSpeedKmH: Double): Double;
var
  BaseSpeed: Double;
begin
  if AMaxSpeedKmH > 0 then
    BaseSpeed := AMaxSpeedKmH
  else
  begin
    case ARoadType of
      rtMotorway: BaseSpeed := FMotorwaySpeed;
      rtTrunk: BaseSpeed := FTrunkSpeed;
      rtPrimary: BaseSpeed := FPrimarySpeed;
      rtSecondary: BaseSpeed := FSecondarySpeed;
      rtTertiary: BaseSpeed := FTertiarySpeed;
      rtUnclassified: BaseSpeed := FUnclassifiedSpeed;
      rtResidential: BaseSpeed := FResidentialSpeed;
      rtService: BaseSpeed := FServiceSpeed;
      rtTrack: BaseSpeed := FTrackSpeed;
    else
      BaseSpeed := FDefaultSpeed;
    end;
  end;

  Result := Max(1, BaseSpeed * FSpeedFactor);
end;

initialization
  RegisterClass(TAIRouteSpeedProfile);
finalization
  UnRegisterClass(TAIRouteSpeedProfile);

end.
