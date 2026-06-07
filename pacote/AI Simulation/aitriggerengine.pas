unit aitriggerengine;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, aibase, aisimentity, LResources;

type
  TOnCycleEvent = procedure(Sender: TObject; CycleNum: Integer) of object;
  TOnEntityEvent = procedure(Sender: TObject; AEntity: TAISimEntity) of object;
  TOnEntityMovedEvent = procedure(Sender: TObject; AEntity: TAISimEntity; FromX, FromY, ToX, ToY: Integer) of object;
  TOnRuleAppliedEvent = procedure(Sender: TObject; const RuleName: string; AEntity: TAISimEntity) of object;
  TOnTriggerErrorEvent = procedure(Sender: TObject; const AError: string) of object;

  { TAITriggerEngine }

  TAITriggerEngine = class(TAIBaseComponent)
  private
    FOnCycleStart: TOnCycleEvent;
    FOnCycleEnd: TOnCycleEvent;
    FOnEntityCreated: TOnEntityEvent;
    FOnEntityRemoved: TOnEntityEvent;
    FOnEntityMoved: TOnEntityMovedEvent;
    FOnRuleApplied: TOnRuleAppliedEvent;
    FOnTriggerError: TOnTriggerErrorEvent;
  public
    constructor Create(AOwner: TComponent); override;
    
    procedure TriggerCycleStart(CycleNum: Integer);
    procedure TriggerCycleEnd(CycleNum: Integer);
    procedure TriggerEntityCreated(AEntity: TAISimEntity);
    procedure TriggerEntityRemoved(AEntity: TAISimEntity);
    procedure TriggerEntityMoved(AEntity: TAISimEntity; FromX, FromY, ToX, ToY: Integer);
    procedure TriggerRuleApplied(const RuleName: string; AEntity: TAISimEntity);
    procedure TriggerError(const AError: string);
  published
    property OnCycleStart: TOnCycleEvent read FOnCycleStart write FOnCycleStart;
    property OnCycleEnd: TOnCycleEvent read FOnCycleEnd write FOnCycleEnd;
    property OnEntityCreated: TOnEntityEvent read FOnEntityCreated write FOnEntityCreated;
    property OnEntityRemoved: TOnEntityEvent read FOnEntityRemoved write FOnEntityRemoved;
    property OnEntityMoved: TOnEntityMovedEvent read FOnEntityMoved write FOnEntityMoved;
    property OnRuleApplied: TOnRuleAppliedEvent read FOnRuleApplied write FOnRuleApplied;
    property OnTriggerError: TOnTriggerErrorEvent read FOnTriggerError write FOnTriggerError;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('AI Simulation', [TAITriggerEngine]);
end;

{ TAITriggerEngine }

constructor TAITriggerEngine.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FCategory := ccSimulation;
  FPrompt := 'Component TAITriggerEngine handles event triggering and notifications for simulation cycle and entity events.';
end;

procedure TAITriggerEngine.TriggerCycleStart(CycleNum: Integer);
begin
  if Assigned(FOnCycleStart) then
    FOnCycleStart(Self, CycleNum);
end;

procedure TAITriggerEngine.TriggerCycleEnd(CycleNum: Integer);
begin
  if Assigned(FOnCycleEnd) then
    FOnCycleEnd(Self, CycleNum);
end;

procedure TAITriggerEngine.TriggerEntityCreated(AEntity: TAISimEntity);
begin
  if Assigned(FOnEntityCreated) then
    FOnEntityCreated(Self, AEntity);
end;

procedure TAITriggerEngine.TriggerEntityRemoved(AEntity: TAISimEntity);
begin
  if Assigned(FOnEntityRemoved) then
    FOnEntityRemoved(Self, AEntity);
end;

procedure TAITriggerEngine.TriggerEntityMoved(AEntity: TAISimEntity; FromX, FromY, ToX, ToY: Integer);
begin
  if Assigned(FOnEntityMoved) then
    FOnEntityMoved(Self, AEntity, FromX, FromY, ToX, ToY);
end;

procedure TAITriggerEngine.TriggerRuleApplied(const RuleName: string; AEntity: TAISimEntity);
begin
  if Assigned(FOnRuleApplied) then
    FOnRuleApplied(Self, RuleName, AEntity);
end;

procedure TAITriggerEngine.TriggerError(const AError: string);
begin
  if Assigned(FOnTriggerError) then
    FOnTriggerError(Self, AError);
  SetError(AError);
end;

initialization
  {$I aitriggerengine_icon.lrs}

end.
