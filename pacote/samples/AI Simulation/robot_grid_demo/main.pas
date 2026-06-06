unit main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, StdCtrls,
  aigridworld, aigridcell, aisimentity, aientityfactory, aisimulationengine,
  airuleengine, aimovementengine, aitriggerengine, aisimulationstats, aigridrenderer2d;

type

  { TfrmMain }

  TfrmMain = class(TForm)
    btnStart: TButton;
    btnPause: TButton;
    btnStep: TButton;
    btnStop: TButton;
    btnReset: TButton;
    pbGrid: TPaintBox;
    pnlControl: TPanel;
    lblStatsTitle: TLabel;
    lblCycles: TLabel;
    lblActive: TLabel;
    lblMoving: TLabel;
    lblSeekingCharge: TLabel;
    lblCharging: TLabel;
    lblBlocked: TLabel;
    lblInactive: TLabel;
    lblDead: TLabel;
    lblRecharges: TLabel;
    lblCycleMoves: TLabel;
    lblTotalMoves: TLabel;
    lblLogTitle: TLabel;
    lblLastEvent: TLabel;
    lblStatus: TLabel;
    
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure pbGridPaint(Sender: TObject);
    procedure btnStartClick(Sender: TObject);
    procedure btnPauseClick(Sender: TObject);
    procedure btnStepClick(Sender: TObject);
    procedure btnStopClick(Sender: TObject);
    procedure btnResetClick(Sender: TObject);
  private
    FWorld: TAIGridWorld;
    FEngine: TAISimulationEngine;
    FMovement: TAIMovementEngine;
    FRules: TAIRuleEngine;
    FTrigger: TAITriggerEngine;
    FStats: TAISimulationStats;
    FRenderer: TAIGridRenderer2D;
    
    FTotalRecharges: Integer;
    FCycleMoves: Integer;
    FTotalMoves: Integer;
    
    procedure OnEngineCycle(Sender: TObject);
    procedure ResetSimulation;
    procedure UpdateStatsLabels;
    procedure TriggerEvent(const AEventName: string; AEntity: TAISimEntity);
    
    // Trigger callbacks
    procedure OnTriggerRuleApplied(Sender: TObject; const RuleName: string; AEntity: TAISimEntity);
    procedure OnTriggerCycleStart(Sender: TObject; CycleNum: Integer);
    
    // Rules callbacks
    function CondDeathCheck(Sender: TObject; AEntity: TAISimEntity; AWorld: TAIGridWorld): Boolean;
    procedure ActDeathCheck(Sender: TObject; AEntity: TAISimEntity; AWorld: TAIGridWorld);
    
    function CondRecharge(Sender: TObject; AEntity: TAISimEntity; AWorld: TAIGridWorld): Boolean;
    procedure ActRecharge(Sender: TObject; AEntity: TAISimEntity; AWorld: TAIGridWorld);
    
    function CondLowEnergyMove(Sender: TObject; AEntity: TAISimEntity; AWorld: TAIGridWorld): Boolean;
    procedure ActLowEnergyMove(Sender: TObject; AEntity: TAISimEntity; AWorld: TAIGridWorld);
    
    function CondNormalMove(Sender: TObject; AEntity: TAISimEntity; AWorld: TAIGridWorld): Boolean;
    procedure ActNormalMove(Sender: TObject; AEntity: TAISimEntity; AWorld: TAIGridWorld);
  public

  end;

var
  frmMain: TfrmMain;

implementation

{$R *.lfm}

{ TfrmMain }

procedure TfrmMain.FormCreate(Sender: TObject);
begin
  Randomize;
  FTotalRecharges := 0;
  FCycleMoves := 0;
  FTotalMoves := 0;

  // 1. Instantiate components dynamically to run out-of-the-box
  FWorld := TAIGridWorld.Create(Self);
  FWorld.SetupWorld(15, 15);
  FWorld.BoundaryMode := bmBlock;
  FWorld.NeighborhoodMode := nmMoore;

  FMovement := TAIMovementEngine.Create(Self);
  FMovement.GridWorld := FWorld;
  FMovement.Strategy := msStop; // Stopped by default, rule engine dictates movement

  FRules := TAIRuleEngine.Create(Self);
  
  // Register behavior rules in prioritized order (highest executed first)
  FRules.RegisterRule('DeathCheck', 40, @CondDeathCheck, @ActDeathCheck);
  FRules.RegisterRule('Recharge', 30, @CondRecharge, @ActRecharge);
  FRules.RegisterRule('LowEnergyMove', 20, @CondLowEnergyMove, @ActLowEnergyMove);
  FRules.RegisterRule('NormalMove', 10, @CondNormalMove, @ActNormalMove);

  FTrigger := TAITriggerEngine.Create(Self);
  FTrigger.OnRuleApplied := @OnTriggerRuleApplied;
  FTrigger.OnCycleStart := @OnTriggerCycleStart;

  FStats := TAISimulationStats.Create(Self);

  FEngine := TAISimulationEngine.Create(Self);
  FEngine.GridWorld := FWorld;
  FEngine.RuleEngine := FRules;
  FEngine.MovementEngine := FMovement; // Obligatorily calls movement engine
  FEngine.TriggerEngine := FTrigger;
  FEngine.Stats := FStats;
  FEngine.CycleIntervalMs := 300;
  FEngine.OnCycle := @OnEngineCycle;

  FRenderer := TAIGridRenderer2D.Create(Self);
  FRenderer.GridWorld := FWorld;
  FRenderer.CellSize := 38;
  FRenderer.ShowGridLines := True;
  
  // Setup color mapping: Blue for robot, Green for station, Red for inactive
  FRenderer.TypeColors.Values['robot'] := '$00FF0000'; // Blue in BGR
  FRenderer.TypeColors.Values['charging_station'] := '$0000FF00'; // Green
  FRenderer.TypeColors.Values['inactive_robot'] := '$000000FF'; // Red

  ResetSimulation;
end;

procedure TfrmMain.FormDestroy(Sender: TObject);
begin
  FEngine.StopSimulation;
end;

procedure TfrmMain.pbGridPaint(Sender: TObject);
begin
  FRenderer.RenderToCanvas(pbGrid.Canvas, pbGrid.ClientRect);
end;

procedure TfrmMain.btnStartClick(Sender: TObject);
begin
  FEngine.StartSimulation;
  UpdateStatsLabels;
end;

procedure TfrmMain.btnPauseClick(Sender: TObject);
begin
  FEngine.PauseSimulation;
  UpdateStatsLabels;
end;

procedure TfrmMain.btnStepClick(Sender: TObject);
begin
  FEngine.StepCycle;
end;

procedure TfrmMain.btnStopClick(Sender: TObject);
begin
  FEngine.StopSimulation;
  UpdateStatsLabels;
end;

procedure TfrmMain.btnResetClick(Sender: TObject);
begin
  ResetSimulation;
end;

procedure TfrmMain.OnEngineCycle(Sender: TObject);
begin
  pbGrid.Invalidate;
  UpdateStatsLabels;
end;

procedure TfrmMain.ResetSimulation;
var
  i, x, y: Integer;
  LBot: TAISimEntity;
  LStation: TAISimEntity;
begin
  FEngine.StopSimulation;
  FWorld.ClearWorld;
  FStats.ClearStats;
  FTotalRecharges := 0;
  FCycleMoves := 0;
  FTotalMoves := 0;
  
  // Set some obstacles (blocked cells)
  for y := 4 to 10 do
  begin
    FWorld.Cells[7, y].Blocked := True;
  end;
  
  // Place two charging stations
  LStation := TAISimEntity.Create(Self);
  LStation.EntityType := 'charging_station';
  LStation.EntityName := 'Station_A';
  FWorld.AddEntity(LStation, 2, 7);
  
  LStation := TAISimEntity.Create(Self);
  LStation.EntityType := 'charging_station';
  LStation.EntityName := 'Station_B';
  FWorld.AddEntity(LStation, 12, 7);
  
  // Spawn 5 robots with 100 energy, default status: idle
  for i := 1 to 5 do
  begin
    LBot := TAISimEntity.Create(Self);
    LBot.EntityType := 'robot';
    LBot.EntityName := 'Robot_' + IntToStr(i);
    LBot.SetPropertyDouble('energy', 100.0);
    LBot.SetPropertyString('status', 'idle');
    
    // Find a random free position
    repeat
      x := Random(15);
      y := Random(15);
    until FWorld.IsFree(x, y);
    
    FWorld.AddEntity(LBot, x, y);
  end;
  
  pbGrid.Invalidate;
  UpdateStatsLabels;
  lblLastEvent.Caption := 'Último Evento: N/A';
end;

procedure TfrmMain.TriggerEvent(const AEventName: string; AEntity: TAISimEntity);
begin
  if Assigned(FTrigger) then
    FTrigger.TriggerRuleApplied(AEventName, AEntity);
end;

procedure TfrmMain.OnTriggerRuleApplied(Sender: TObject; const RuleName: string; AEntity: TAISimEntity);
begin
  lblLastEvent.Caption := Format('Último Evento: %s (%s)', [RuleName, AEntity.EntityName]);
end;

procedure TfrmMain.OnTriggerCycleStart(Sender: TObject; CycleNum: Integer);
begin
  FCycleMoves := 0;
end;

procedure TfrmMain.UpdateStatsLabels;
var
  i: Integer;
  LEntity: TAISimEntity;
  LStatus: string;
  LNumMoving, LNumSeeking, LNumCharging, LNumBlocked, LNumInactive: Integer;
begin
  LNumMoving := 0;
  LNumSeeking := 0;
  LNumCharging := 0;
  LNumBlocked := 0;
  LNumInactive := 0;
  
  if Assigned(FWorld) then
  begin
    for i := 0 to FWorld.Entities.Count - 1 do
    begin
      LEntity := TAISimEntity(FWorld.Entities[i]);
      if SameText(LEntity.EntityType, 'robot') or SameText(LEntity.EntityType, 'inactive_robot') then
      begin
        LStatus := LEntity.GetPropertyString('status', 'idle');
        if SameText(LStatus, 'moving') then Inc(LNumMoving)
        else if SameText(LStatus, 'seeking_charge') then Inc(LNumSeeking)
        else if SameText(LStatus, 'charging') then Inc(LNumCharging)
        else if SameText(LStatus, 'blocked') then Inc(LNumBlocked)
        else if SameText(LStatus, 'inactive') then Inc(LNumInactive);
      end;
    end;
  end;

  lblCycles.Caption := Format('Ciclos: %d', [FStats.CycleCount]);
  lblActive.Caption := Format('Robôs Ativos: %d', [FWorld.CountEntitiesByType('robot')]);
  lblMoving.Caption := Format('Em Movimento: %d', [LNumMoving]);
  lblSeekingCharge.Caption := Format('Buscando Recarga: %d', [LNumSeeking]);
  lblCharging.Caption := Format('Carregando: %d', [LNumCharging]);
  lblBlocked.Caption := Format('Bloqueados: %d', [LNumBlocked]);
  lblInactive.Caption := Format('Inativos: %d', [LNumInactive]);
  lblDead.Caption := Format('Sem Energia: %d', [LNumInactive]);
  lblRecharges.Caption := Format('Recargas Realizadas: %d', [FTotalRecharges]);
  lblCycleMoves.Caption := Format('Movimentos no Ciclo: %d', [FCycleMoves]);
  lblTotalMoves.Caption := Format('Movimentos Totais: %d', [FTotalMoves]);
  
  if FEngine.Running then
  begin
    if FEngine.Paused then
      lblStatus.Caption := 'Status: Pausado'
    else
      lblStatus.Caption := 'Status: Executando';
  end
  else
    lblStatus.Caption := 'Status: Parado';
end;

// --- Behavior Rules Implementation ---

function TfrmMain.CondDeathCheck(Sender: TObject; AEntity: TAISimEntity; AWorld: TAIGridWorld): Boolean;
begin
  Result := SameText(AEntity.EntityType, 'robot') and (AEntity.GetPropertyDouble('energy') <= 0.0);
end;

procedure TfrmMain.ActDeathCheck(Sender: TObject; AEntity: TAISimEntity; AWorld: TAIGridWorld);
begin
  AEntity.Active := False;
  AEntity.EntityType := 'inactive_robot';
  AEntity.SetPropertyString('status', 'inactive');
  TriggerEvent('robot_inactive', AEntity);
end;

function TfrmMain.CondRecharge(Sender: TObject; AEntity: TAISimEntity; AWorld: TAIGridWorld): Boolean;
var
  LNeighbors: TList;
  i: Integer;
  LCell: TAIGridCell;
begin
  Result := False;
  if not SameText(AEntity.EntityType, 'robot') then Exit;
  if AEntity.GetPropertyDouble('energy') >= 100.0 then Exit;
  
  LNeighbors := TList.Create;
  try
    AWorld.GetNeighbors(AEntity.X, AEntity.Y, 1, LNeighbors);
    for i := 0 to LNeighbors.Count - 1 do
    begin
      LCell := TAIGridCell(LNeighbors[i]);
      if Assigned(LCell.Entity) and SameText(LCell.Entity.EntityType, 'charging_station') then
      begin
        Result := True;
        Break;
      end;
    end;
  finally
    LNeighbors.Free;
  end;
end;

procedure TfrmMain.ActRecharge(Sender: TObject; AEntity: TAISimEntity; AWorld: TAIGridWorld);
begin
  AEntity.SetPropertyString('status', 'charging');
  TriggerEvent('robot_charging', AEntity);
  AEntity.SetPropertyDouble('energy', 100.0);
  Inc(FTotalRecharges);
  TriggerEvent('robot_recharged', AEntity);
  AEntity.SetPropertyString('status', 'idle');
end;

function TfrmMain.CondLowEnergyMove(Sender: TObject; AEntity: TAISimEntity; AWorld: TAIGridWorld): Boolean;
begin
  Result := SameText(AEntity.EntityType, 'robot') and (AEntity.GetPropertyDouble('energy') <= 30.0);
end;

procedure TfrmMain.ActLowEnergyMove(Sender: TObject; AEntity: TAISimEntity; AWorld: TAIGridWorld);
var
  LEnergy: Double;
  LOldX, LOldY: Integer;
begin
  LOldX := AEntity.X;
  LOldY := AEntity.Y;
  
  AEntity.SetPropertyString('status', 'seeking_charge');
  TriggerEvent('robot_low_energy', AEntity);
  
  if FMovement.MoveTowardsTarget(AEntity, 'charging_station') then
  begin
    Inc(FCycleMoves);
    Inc(FTotalMoves);
    TriggerEvent('robot_moved', AEntity);
  end;
  
  // Verify if it stayed in the same position (blocked)
  if (AEntity.X = LOldX) and (AEntity.Y = LOldY) then
  begin
    AEntity.SetPropertyString('status', 'blocked');
    TriggerEvent('robot_blocked', AEntity);
  end;
  
  LEnergy := AEntity.GetPropertyDouble('energy');
  AEntity.SetPropertyDouble('energy', LEnergy - 3.0);
end;

function TfrmMain.CondNormalMove(Sender: TObject; AEntity: TAISimEntity; AWorld: TAIGridWorld): Boolean;
begin
  Result := SameText(AEntity.EntityType, 'robot') and (AEntity.GetPropertyDouble('energy') > 30.0);
end;

procedure TfrmMain.ActNormalMove(Sender: TObject; AEntity: TAISimEntity; AWorld: TAIGridWorld);
var
  LEnergy: Double;
  LOldX, LOldY: Integer;
begin
  LOldX := AEntity.X;
  LOldY := AEntity.Y;
  
  AEntity.SetPropertyString('status', 'moving');
  
  if FMovement.MoveRandomly(AEntity) then
  begin
    Inc(FCycleMoves);
    Inc(FTotalMoves);
    TriggerEvent('robot_moved', AEntity);
  end;
  
  // Verify if it stayed in the same position (blocked)
  if (AEntity.X = LOldX) and (AEntity.Y = LOldY) then
  begin
    AEntity.SetPropertyString('status', 'blocked');
    TriggerEvent('robot_blocked', AEntity);
  end;
  
  LEnergy := AEntity.GetPropertyDouble('energy');
  AEntity.SetPropertyDouble('energy', LEnergy - 5.0);
end;

end.
