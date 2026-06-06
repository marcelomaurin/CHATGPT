unit aisimulationengine;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, ExtCtrls, aibase, aisimentity, aigridworld, airuleengine, aitriggerengine, aimovementengine, aievolutionengine, aisimulationstats;

type
  { TAISimulationEngine }

  TAISimulationEngine = class(TAIBaseComponent)
  private
    FGridWorld: TAIGridWorld;
    FRuleEngine: TAIRuleEngine;
    FTriggerEngine: TAITriggerEngine;
    FMovementEngine: TAIMovementEngine;
    FEvolutionEngine: TAIEvolutionEngine;
    FStats: TAISimulationStats;
    
    FCycleIntervalMs: Integer;
    FCycleLimit: Integer;
    FRunning: Boolean;
    FPaused: Boolean;
    FTimer: TTimer;
    FOnCycle: TNotifyEvent;
    
    procedure OnTimerTick(Sender: TObject);
    procedure SetCycleIntervalMs(AValue: Integer);
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    
    procedure StartSimulation;
    procedure PauseSimulation;
    procedure StopSimulation;
    procedure StepCycle;
  published
    property GridWorld: TAIGridWorld read FGridWorld write FGridWorld;
    property RuleEngine: TAIRuleEngine read FRuleEngine write FRuleEngine;
    property TriggerEngine: TAITriggerEngine read FTriggerEngine write FTriggerEngine;
    property MovementEngine: TAIMovementEngine read FMovementEngine write FMovementEngine;
    property EvolutionEngine: TAIEvolutionEngine read FEvolutionEngine write FEvolutionEngine;
    property Stats: TAISimulationStats read FStats write FStats;
    
    property CycleIntervalMs: Integer read FCycleIntervalMs write SetCycleIntervalMs default 500;
    property CycleLimit: Integer read FCycleLimit write FCycleLimit default 0;
    property Running: Boolean read FRunning;
    property Paused: Boolean read FPaused;
    
    property OnCycle: TNotifyEvent read FOnCycle write FOnCycle;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('AI Simulation', [TAISimulationEngine]);
end;

{ TAISimulationEngine }

constructor TAISimulationEngine.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FCategory := ccSimulation;
  FPrompt := 'Component TAISimulationEngine runs the main simulation loop cycle-by-cycle, integrating grid state, movement, rules, evolution, stats and event dispatching.';
  
  FCycleIntervalMs := 500;
  FCycleLimit := 0;
  FRunning := False;
  FPaused := False;
  
  FTimer := TTimer.Create(Self);
  FTimer.Enabled := False;
  FTimer.Interval := FCycleIntervalMs;
  FTimer.OnTimer := @OnTimerTick;
  
  FGridWorld := nil;
  FRuleEngine := nil;
  FTriggerEngine := nil;
  FMovementEngine := nil;
  FEvolutionEngine := nil;
  FStats := nil;
end;

destructor TAISimulationEngine.Destroy;
begin
  FTimer.Enabled := False;
  inherited Destroy;
end;

procedure TAISimulationEngine.SetCycleIntervalMs(AValue: Integer);
begin
  if FCycleIntervalMs <> AValue then
  begin
    FCycleIntervalMs := AValue;
    FTimer.Interval := FCycleIntervalMs;
  end;
end;

procedure TAISimulationEngine.StartSimulation;
begin
  if not Assigned(FGridWorld) then
  begin
    SetError('GridWorld not assigned.');
    Exit;
  end;
  
  FRunning := True;
  FPaused := False;
  FTimer.Enabled := True;
  
  if Assigned(FStats) then
    FStats.ClearStats;
end;

procedure TAISimulationEngine.PauseSimulation;
begin
  if FRunning then
  begin
    FPaused := not FPaused;
    FTimer.Enabled := not FPaused;
  end;
end;

procedure TAISimulationEngine.StopSimulation;
begin
  FRunning := False;
  FPaused := False;
  FTimer.Enabled := False;
end;

procedure TAISimulationEngine.StepCycle;
var
  LStart, LEnd: TDateTime;
  LDiffMs: Double;
  i: Integer;
  LEntity: TObject;
  LSimEntity: aisimentity.TAISimEntity;
  LOldX, LOldY: Integer;
  LTempList: TList;
begin
  if not Assigned(FGridWorld) then Exit;
  
  LStart := Now;
  
  if Assigned(FTriggerEngine) then
    FTriggerEngine.TriggerCycleStart(FStats.CycleCount + 1);
    
  // 1. Process movement for all active entities
  if Assigned(FMovementEngine) then
  begin
    LTempList := TList.Create;
    try
      // Copy references to a temporary list
      for i := 0 to FGridWorld.Entities.Count - 1 do
        LTempList.Add(FGridWorld.Entities[i]);
        
      for i := 0 to LTempList.Count - 1 do
      begin
        LEntity := TObject(LTempList[i]);
        if Assigned(LEntity) and (LEntity is aisimentity.TAISimEntity) then
        begin
          LSimEntity := aisimentity.TAISimEntity(LEntity);
          // Verify entity still exists in the world and is active
          if (FGridWorld.Entities.IndexOf(LSimEntity) >= 0) and LSimEntity.Active then
          begin
            LOldX := LSimEntity.X;
            LOldY := LSimEntity.Y;
            if FMovementEngine.StepEntityMovement(LSimEntity) then
            begin
              if Assigned(FTriggerEngine) and ((LOldX <> LSimEntity.X) or (LOldY <> LSimEntity.Y)) then
                FTriggerEngine.TriggerEntityMoved(LSimEntity, LOldX, LOldY, LSimEntity.X, LSimEntity.Y);
            end;
          end;
        end;
      end;
    finally
      LTempList.Free;
    end;
  end;
  
  // 2. Process rules
  if Assigned(FRuleEngine) then
  begin
    FRuleEngine.EvaluateWorldRules(FGridWorld);
  end;
  
  // 3. Process individual entity internal steps
  LTempList := TList.Create;
  try
    // Copy references to a temporary list
    for i := 0 to FGridWorld.Entities.Count - 1 do
      LTempList.Add(FGridWorld.Entities[i]);
      
    for i := 0 to LTempList.Count - 1 do
    begin
      LEntity := TObject(LTempList[i]);
      if Assigned(LEntity) and (LEntity is aisimentity.TAISimEntity) then
      begin
        LSimEntity := aisimentity.TAISimEntity(LEntity);
        // Verify entity still exists in the world and is active
        if (FGridWorld.Entities.IndexOf(LSimEntity) >= 0) and LSimEntity.Active then
          LSimEntity.Step;
      end;
    end;
  finally
    LTempList.Free;
  end;
  
  LEnd := Now;
  LDiffMs := (LEnd - LStart) * 24 * 60 * 60 * 1000;
  
  // 4. Update Stats
  if Assigned(FStats) then
  begin
    FStats.RecordCycle(LDiffMs);
  end;
  
  if Assigned(FTriggerEngine) then
    FTriggerEngine.TriggerCycleEnd(FStats.CycleCount);
    
  if Assigned(FOnCycle) then
    FOnCycle(Self);
    
  // Check cycle limit
  if (FCycleLimit > 0) and Assigned(FStats) and (FStats.CycleCount >= FCycleLimit) then
  begin
    StopSimulation;
  end;
end;

procedure TAISimulationEngine.OnTimerTick(Sender: TObject);
begin
  // Temporarily disable timer to prevent overlap if step takes longer than interval
  FTimer.Enabled := False;
  try
    if FRunning and not FPaused then
      StepCycle;
  finally
    if FRunning and not FPaused then
      FTimer.Enabled := True;
  end;
end;

end.
