unit aianimationsequence;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, aibase, LResources;

type
  { TAIAnimationSequence }

  TAIAnimationSequence = class(TAIBaseComponent)
  private
    FLoop: Boolean;
    FDuration: Integer;
  public
    constructor Create(AOwner: TComponent); override;
    procedure PlayAnimation;
    procedure StopAnimation;
  published
    property Loop: Boolean read FLoop write FLoop default False;
    property Duration: Integer read FDuration write FDuration default 1000;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('AI Graphic', [TAIAnimationSequence]);
end;

{ TAIAnimationSequence }

constructor TAIAnimationSequence.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FCategory := ccOther;
  FPrompt := 'Component TAIAnimationSequence plays back a sequence of joint animations. Properties: Loop, Duration. Methods: PlayAnimation, StopAnimation.';
  FLoop := False;
  FDuration := 1000;
  ClearError;
end;

procedure TAIAnimationSequence.PlayAnimation;
begin
  Log(llInfo, 'Playing animation sequence.');
  FLastResult := 'Animation playing.';
  FLastSuccess := True;
end;

procedure TAIAnimationSequence.StopAnimation;
begin
  Log(llInfo, 'Stopping animation sequence.');
  FLastResult := 'Animation stopped.';
  FLastSuccess := True;
end;

initialization
  {$I aianimationsequence_icon.lrs}

end.
