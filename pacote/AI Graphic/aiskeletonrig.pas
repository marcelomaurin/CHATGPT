unit aiskeletonrig;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, aibase;

type
  { TAISkeletonRig }

  TAISkeletonRig = class(TAIBaseComponent)
  private
    FBonesList: TStrings;
    procedure SetBonesList(AValue: TStrings);
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure RotateBone(const ABoneName: string; const Angle: Double);
  published
    property BonesList: TStrings read FBonesList write SetBonesList;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('AI Graphic', [TAISkeletonRig]);
end;

{ TAISkeletonRig }

constructor TAISkeletonRig.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FCategory := ccOther;
  FPrompt := 'Component TAISkeletonRig manages rigging joints and bone hierarchies. Properties: BonesList. Methods: RotateBone.';
  FBonesList := TStringList.Create;
  FBonesList.Add('root');
  FBonesList.Add('spine');
  FBonesList.Add('head');
  FBonesList.Add('left_arm');
  FBonesList.Add('right_arm');
  FBonesList.Add('left_leg');
  FBonesList.Add('right_leg');
  ClearError;
end;

destructor TAISkeletonRig.Destroy;
begin
  FBonesList.Free;
  inherited Destroy;
end;

procedure TAISkeletonRig.SetBonesList(AValue: TStrings);
begin
  FBonesList.Assign(AValue);
end;

procedure TAISkeletonRig.RotateBone(const ABoneName: string; const Angle: Double);
begin
  Log(llDebug, Format('Rotated bone %s to angle %.2f', [ABoneName, Angle]));
end;

end.
