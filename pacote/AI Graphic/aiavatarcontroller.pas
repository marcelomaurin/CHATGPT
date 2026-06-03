unit aiavatarcontroller;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, aibase, aiskeletonrig, LResources;

type
  TAvatarExpression = (exNeutral, exHappy, exSad, exThinking);

  { TAIAvatarController }

  TAIAvatarController = class(TAIBaseComponent)
  private
    FSkeleton: TAISkeletonRig;
    FExpression: TAvatarExpression;
    procedure SetSkeleton(AValue: TAISkeletonRig);
  protected
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
  public
    constructor Create(AOwner: TComponent); override;
    procedure SetPose(const APoseName: string);
    procedure SetExpression(const AExpression: string);
  published
    property Skeleton: TAISkeletonRig read FSkeleton write SetSkeleton;
    property Expression: TAvatarExpression read FExpression write FExpression default exNeutral;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('AI Graphic', [TAIAvatarController]);
end;

{ TAIAvatarController }

constructor TAIAvatarController.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FCategory := ccOther;
  FPrompt := 'Component TAIAvatarController handles high-level avatar facial expression and joint gestures. Properties: Skeleton, Expression. Methods: SetPose, SetExpression.';
  FSkeleton := nil;
  FExpression := exNeutral;
  ClearError;
end;

procedure TAIAvatarController.SetSkeleton(AValue: TAISkeletonRig);
begin
  if FSkeleton <> AValue then
  begin
    FSkeleton := AValue;
    if FSkeleton <> nil then
      FSkeleton.FreeNotification(Self);
  end;
end;

procedure TAIAvatarController.Notification(AComponent: TComponent; Operation: TOperation);
begin
  inherited Notification(AComponent, Operation);
  if (Operation = opRemove) and (AComponent = FSkeleton) then
    FSkeleton := nil;
end;

procedure TAIAvatarController.SetPose(const APoseName: string);
begin
  Log(llInfo, 'Applying pose: ' + APoseName);
  FLastResult := 'Pose applied: ' + APoseName;
  FLastSuccess := True;
end;

procedure TAIAvatarController.SetExpression(const AExpression: string);
begin
  Log(llInfo, 'Setting expression to: ' + AExpression);
  if SameText(AExpression, 'happy') then FExpression := exHappy
  else if SameText(AExpression, 'sad') then FExpression := exSad
  else if SameText(AExpression, 'thinking') then FExpression := exThinking
  else FExpression := exNeutral;
  FLastResult := 'Expression set: ' + AExpression;
  FLastSuccess := True;
end;

initialization
  {$I aiavatarcontroller_icon.lrs}

end.
