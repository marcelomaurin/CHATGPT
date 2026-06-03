unit aitrainingenvironment;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, aibase, aiscene2d3d;

type
  { TAITrainingEnvironment }

  TAITrainingEnvironment = class(TAIBaseComponent)
  private
    FMaxStepsPerEpisode: Integer;
    FEpisodeCount: Integer;
    FScene: TAIScene2D3D;
    FCurrentStep: Integer;
    FOnEpisodeStart: TNotifyEvent;
    FOnEpisodeEnd: TNotifyEvent;
    FOnStepPerformed: TNotifyEvent;
    procedure SetScene(AValue: TAIScene2D3D);
  protected
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
  public
    constructor Create(AOwner: TComponent); override;
    procedure ResetEpisode;
    procedure Step(const AAction: string);
    function IsEpisodeDone: Boolean;
  published
    property MaxStepsPerEpisode: Integer read FMaxStepsPerEpisode write FMaxStepsPerEpisode default 1000;
    property EpisodeCount: Integer read FEpisodeCount write FEpisodeCount;
    property Scene: TAIScene2D3D read FScene write SetScene;
    property OnEpisodeStart: TNotifyEvent read FOnEpisodeStart write FOnEpisodeStart;
    property OnEpisodeEnd: TNotifyEvent read FOnEpisodeEnd write FOnEpisodeEnd;
    property OnStepPerformed: TNotifyEvent read FOnStepPerformed write FOnStepPerformed;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('AI Graphic', [TAITrainingEnvironment]);
end;

{ TAITrainingEnvironment }

constructor TAITrainingEnvironment.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FCategory := ccOther;
  FPrompt := 'Component TAITrainingEnvironment orchestrates reinforcement learning training episodes using a TAIScene2D3D. Properties: MaxStepsPerEpisode, EpisodeCount, Scene. Methods: ResetEpisode, Step, IsEpisodeDone.';
  FMaxStepsPerEpisode := 1000;
  FEpisodeCount := 0;
  FScene := nil;
  FCurrentStep := 0;
  ClearError;
end;

procedure TAITrainingEnvironment.SetScene(AValue: TAIScene2D3D);
begin
  if FScene <> AValue then
  begin
    FScene := AValue;
    if FScene <> nil then
      FScene.FreeNotification(Self);
  end;
end;

procedure TAITrainingEnvironment.Notification(AComponent: TComponent; Operation: TOperation);
begin
  inherited Notification(AComponent, Operation);
  if (Operation = opRemove) and (AComponent = FScene) then
    FScene := nil;
end;

procedure TAITrainingEnvironment.ResetEpisode;
begin
  FCurrentStep := 0;
  Inc(FEpisodeCount);
  Log(llInfo, 'Episode reset. Starting episode ' + IntToStr(FEpisodeCount));
  if Assigned(FOnEpisodeStart) then
    FOnEpisodeStart(Self);
end;

procedure TAITrainingEnvironment.Step(const AAction: string);
begin
  Inc(FCurrentStep);
  Log(llDebug, 'Step ' + IntToStr(FCurrentStep) + ' action: ' + AAction);
  if Assigned(FOnStepPerformed) then
    FOnStepPerformed(Self);
    
  if IsEpisodeDone then
  begin
    Log(llInfo, 'Episode ' + IntToStr(FEpisodeCount) + ' finished.');
    if Assigned(FOnEpisodeEnd) then
      FOnEpisodeEnd(Self);
  end;
end;

function TAITrainingEnvironment.IsEpisodeDone: Boolean;
begin
  Result := FCurrentStep >= FMaxStepsPerEpisode;
end;

end.
