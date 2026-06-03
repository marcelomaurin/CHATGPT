unit aimotiontracker;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, aibase, LResources;

type
  { TAIMotionTracker }

  TAIMotionTracker = class(TAIBaseComponent)
  private
    FSensitivity: Integer;
  public
    constructor Create(AOwner: TComponent); override;
    function DetectMotion(AFrameA, AFrameB: TObject): Boolean;
  published
    property Sensitivity: Integer read FSensitivity write FSensitivity default 10;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('AI Vision', [TAIMotionTracker]);
end;

{ TAIMotionTracker }

constructor TAIMotionTracker.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FCategory := ccOther;
  FPrompt := 'Component TAIMotionTracker detects motion difference between two frames. Properties: Sensitivity. Methods: DetectMotion.';
  FSensitivity := 10;
  ClearError;
end;

function TAIMotionTracker.DetectMotion(AFrameA, AFrameB: TObject): Boolean;
begin
  Result := False;
  Log(llDebug, 'Comparing frames for motion.');
end;

initialization
  {$I aimotiontracker_icon.lrs}

end.
