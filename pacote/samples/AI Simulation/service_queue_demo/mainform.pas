unit mainform;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, StdCtrls,
  aigridworld, aigridcell, aisimentity, aientityfactory, aisimulationengine,
  airuleengine, aimovementengine, aitriggerengine, aisimulationstats,
  aigridrenderer2d, aisimulationexporter;

type

  { TfrmMain }

  TfrmMain = class(TForm)
    btnStart: TButton;
    btnPause: TButton;
    btnStep: TButton;
    btnStop: TButton;
    btnReset: TButton;
    btnExport: TButton;
    edtArrivalInterval: TEdit;
    edtServiceTime: TEdit;
    lblConfig: TLabel;
    lblIntervalPrompt: TLabel;
    lblServiceTimePrompt: TLabel;
    lblStatsTitle: TLabel;
    lblCycles: TLabel;
    lblWaiting: TLabel;
    lblBeingServed: TLabel;
    lblServed: TLabel;
    lblDesks: TLabel;
    lblWaitTime: TLabel;
    lblMaxQueue: TLabel;
    lblLogTitle: TLabel;
    lblLastEvent: TLabel;
    lblLastError: TLabel;
    lblStatus: TLabel;
    pbGrid: TPaintBox;
    pnlControl: TPanel;
    
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure pbGridPaint(Sender: TObject);
    procedure btnStartClick(Sender: TObject);
    procedure btnPauseClick(Sender: TObject);
    procedure btnStepClick(Sender: TObject);
    procedure btnStopClick(Sender: TObject);
    procedure btnResetClick(Sender: TObject);
    procedure btnExportClick(Sender: TObject);
  private
    FWorld: TAIGridWorld;
    FEngine: TAISimulationEngine;
    FMovement: TAIMovementEngine;
    FRules: TAIRuleEngine;
    FTrigger: TAITriggerEngine;
    FStats: TAISimulationStats;
    FRenderer: TAIGridRenderer2D;
    FExporter: TAISimulationExporter;
    
    FTotalWaiting: Integer;
    FTotalBeingServed: Integer;
    FTotalServed: Integer;
    
    FTotalWaitCycles: Integer;
    FTotalServiceCycles: Integer;
    FServicesCompleted: Integer;
    FMaxQueueRecorded: Integer;
    
    procedure OnEngineCycle(Sender: TObject);
    procedure ResetSimulation;
    procedure UpdateStatsLabels;
    procedure TriggerEvent(const AEventName: string; AEntity: TAISimEntity);
    
    // Trigger callbacks
    procedure OnTriggerRuleApplied(Sender: TObject; const RuleName: string; AEntity: TAISimEntity);
    procedure OnTriggerCycleStart(Sender: TObject; CycleNum: Integer);
    
    // Rules callbacks
    function CondSpawn(Sender: TObject; AEntity: TAISimEntity; AWorld: TAIGridWorld): Boolean;
    procedure ActSpawn(Sender: TObject; AEntity: TAISimEntity; AWorld: TAIGridWorld);
    
    function CondSearchDesk(Sender: TObject; AEntity: TAISimEntity; AWorld: TAIGridWorld): Boolean;
    procedure ActSearchDesk(Sender: TObject; AEntity: TAISimEntity; AWorld: TAIGridWorld);
    
    function CondStartService(Sender: TObject; AEntity: TAISimEntity; AWorld: TAIGridWorld): Boolean;
    procedure ActStartService(Sender: TObject; AEntity: TAISimEntity; AWorld: TAIGridWorld);
    
    function CondFinishService(Sender: TObject; AEntity: TAISimEntity; AWorld: TAIGridWorld): Boolean;
    procedure ActFinishService(Sender: TObject; AEntity: TAISimEntity; AWorld: TAIGridWorld);
    
    function CondMove(Sender: TObject; AEntity: TAISimEntity; AWorld: TAIGridWorld): Boolean;
    procedure ActMove(Sender: TObject; AEntity: TAISimEntity; AWorld: TAIGridWorld);
    
    function CondExit(Sender: TObject; AEntity: TAISimEntity; AWorld: TAIGridWorld): Boolean;
    procedure ActExit(Sender: TObject; AEntity: TAISimEntity; AWorld: TAIGridWorld);
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
  
  FTotalWaitCycles := 0;
  FTotalServiceCycles := 0;
  FServicesCompleted := 0;
  FMaxQueueRecorded := 0;

  // 1. Instantiate components dynamically to run out-of-the-box
  FWorld := TAIGridWorld.Create(Self);
  FWorld.SetupWorld(15, 15);
  FWorld.BoundaryMode := bmBlock;
  FWorld.NeighborhoodMode := nmMoore;

  FMovement := TAIMovementEngine.Create(Self);
  FMovement.GridWorld := FWorld;
  FMovement.Strategy := msStop;

  FRules := TAIRuleEngine.Create(Self);
  
  // Register behavior rules in prioritized order
  FRules.RegisterRule('ExitCheck', 60, @CondExit, @ActExit);
  FRules.RegisterRule('FinishService', 50, @CondFinishService, @ActFinishService);
  FRules.RegisterRule('StartService', 40, @CondStartService, @ActStartService);
  FRules.RegisterRule('SearchDesk', 30, @CondSearchDesk, @ActSearchDesk);
  FRules.RegisterRule('MovePerson', 20, @CondMove, @ActMove);
  FRules.RegisterRule('SpawnPerson', 10, @CondSpawn, @ActSpawn);

  FTrigger := TAITriggerEngine.Create(Self);
  FTrigger.OnRuleApplied := @OnTriggerRuleApplied;
  FTrigger.OnCycleStart := @OnTriggerCycleStart;

  FStats := TAISimulationStats.Create(Self);

  FEngine := TAISimulationEngine.Create(Self);
  FEngine.GridWorld := FWorld;
  FEngine.RuleEngine := FRules;
  FEngine.MovementEngine := FMovement;
  FEngine.TriggerEngine := FTrigger;
  FEngine.Stats := FStats;
  FEngine.CycleIntervalMs := 250;
  FEngine.OnCycle := @OnEngineCycle;

  FExporter := TAISimulationExporter.Create(Self);

  FRenderer := TAIGridRenderer2D.Create(Self);
  FRenderer.GridWorld := FWorld;
  FRenderer.CellSize := 38;
  FRenderer.ShowGridLines := True;
  
  // Setup color mapping
  FRenderer.TypeColors.Values['person_waiting'] := '$0000FFFF';      // Yellow
  FRenderer.TypeColors.Values['person_moving'] := '$00FF0000';       // Blue
  FRenderer.TypeColors.Values['person_being_served'] := '$0000A5FF'; // Orange
  FRenderer.TypeColors.Values['person_served'] := '$0000FF00';       // Green
  FRenderer.TypeColors.Values['service_desk_free'] := '$00D3D3D3';   // Light Gray
  FRenderer.TypeColors.Values['service_desk_busy'] := '$000000FF';   // Red
  FRenderer.TypeColors.Values['exit_point'] := '$00000000';          // Black

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

procedure TfrmMain.btnExportClick(Sender: TObject);
var
  LSaveDlg: TSaveDialog;
begin
  LSaveDlg := TSaveDialog.Create(Self);
  try
    LSaveDlg.Filter := 'Arquivo CSV (*.csv)|*.csv|Arquivo de Texto (*.txt)|*.txt';
    LSaveDlg.DefaultExt := 'csv';
    if LSaveDlg.Execute then
    begin
      if ExtractFileExt(LSaveDlg.FileName) = '.txt' then
        FExporter.ExportToTXT(LSaveDlg.FileName, FStats)
      else
        FExporter.ExportToCSV(LSaveDlg.FileName, FStats);
      ShowMessage('Estatísticas exportadas com sucesso!');
    end;
  finally
    LSaveDlg.Free;
  end;
end;

procedure TfrmMain.OnEngineCycle(Sender: TObject);
begin
  pbGrid.Invalidate;
  UpdateStatsLabels;
end;

procedure TfrmMain.ResetSimulation;
var
  y: Integer;
  LStation: TAISimEntity;
begin
  FEngine.StopSimulation;
  FWorld.ClearWorld;
  FStats.ClearStats;
  
  FTotalWaitCycles := 0;
  FTotalServiceCycles := 0;
  FServicesCompleted := 0;
  FMaxQueueRecorded := 0;
  
  // Set waiting lane walls to form a visual queue flow
  for y := 4 to 12 do
  begin
    FWorld.Cells[4, y].Blocked := True;
    FWorld.Cells[8, y].Blocked := True;
    FWorld.Cells[12, y].Blocked := True;
  end;
  
  // Place service desks at the top
  LStation := TAISimEntity.Create(Self);
  LStation.EntityType := 'service_desk_free';
  LStation.EntityName := 'Desk_A';
  LStation.SetPropertyString('status', 'free');
  FWorld.AddEntity(LStation, 2, 2);
  
  LStation := TAISimEntity.Create(Self);
  LStation.EntityType := 'service_desk_free';
  LStation.EntityName := 'Desk_B';
  LStation.SetPropertyString('status', 'free');
  FWorld.AddEntity(LStation, 6, 2);
  
  LStation := TAISimEntity.Create(Self);
  LStation.EntityType := 'service_desk_free';
  LStation.EntityName := 'Desk_C';
  LStation.SetPropertyString('status', 'free');
  FWorld.AddEntity(LStation, 10, 2);
  
  // Place Exit Point
  LStation := TAISimEntity.Create(Self);
  LStation.EntityType := 'exit_point';
  LStation.EntityName := 'Exit';
  FWorld.AddEntity(LStation, 14, 0);
  
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
  lblLastEvent.Caption := Format('%s (%s)', [RuleName, AEntity.EntityName]);
end;

procedure TfrmMain.OnTriggerCycleStart(Sender: TObject; CycleNum: Integer);
begin
  // Handle start of cycle if needed
end;

procedure TfrmMain.UpdateStatsLabels;
var
  i: Integer;
  LEntity: TAISimEntity;
  LStatus: string;
  LWaiting, LBeingServed, LServed: Integer;
  LFreeDesks, LBusyDesks: Integer;
  LAvgWait: Double;
begin
  LWaiting := 0;
  LBeingServed := 0;
  LServed := 0;
  LFreeDesks := 0;
  LBusyDesks := 0;
  
  if Assigned(FWorld) then
  begin
    for i := 0 to FWorld.Entities.Count - 1 do
    begin
      LEntity := TAISimEntity(FWorld.Entities[i]);
      if SameText(LEntity.EntityType, 'person_waiting') or SameText(LEntity.EntityType, 'person_moving') then
        Inc(LWaiting)
      else if SameText(LEntity.EntityType, 'person_being_served') then
        Inc(LBeingServed)
      else if SameText(LEntity.EntityType, 'person_served') then
        Inc(LServed)
      else if SameText(LEntity.EntityType, 'service_desk_free') then
        Inc(LFreeDesks)
      else if SameText(LEntity.EntityType, 'service_desk_busy') then
        Inc(LBusyDesks);
    end;
  end;
  
  if LWaiting > FMaxQueueRecorded then
    FMaxQueueRecorded := LWaiting;
    
  if FServicesCompleted > 0 then
    LAvgWait := FTotalWaitCycles / FServicesCompleted
  else
    LAvgWait := 0.0;

  lblCycles.Caption := Format('Ciclos: %d', [FStats.CycleCount]);
  lblWaiting.Caption := Format('Pessoas Aguardando: %d', [LWaiting]);
  lblBeingServed.Caption := Format('Pessoas em Atendimento: %d', [LBeingServed]);
  lblServed.Caption := Format('Pessoas Atendidas: %d', [FServicesCompleted]);
  lblDesks.Caption := Format('Guichês Livres: %d | Ocupados: %d', [LFreeDesks, LBusyDesks]);
  lblWaitTime.Caption := Format('Tempo Médio de Espera: %.1f ciclos', [LAvgWait]);
  lblMaxQueue.Caption := Format('Maior Fila Registrada: %d', [FMaxQueueRecorded]);
  
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

function TfrmMain.CondSpawn(Sender: TObject; AEntity: TAISimEntity; AWorld: TAIGridWorld): Boolean;
var
  LInterval: Integer;
begin
  // Spawn check: only evaluate on the world itself (AEntity = nil or special global rule)
  // But our airuleengine evaluates for active entities. So we can execute the spawn rule on the service_desks or on the exit point to trigger it once.
  // Let's check: if AEntity is the exit_point entity, we use it as a cycle hook to spawn a person.
  LInterval := StrToIntDef(edtArrivalInterval.Text, 5);
  Result := SameText(AEntity.EntityType, 'exit_point') and (AWorld.Entities.Count < 30) and (FStats.CycleCount mod LInterval = 0);
end;

procedure TfrmMain.ActSpawn(Sender: TObject; AEntity: TAISimEntity; AWorld: TAIGridWorld);
var
  LPerson: TAISimEntity;
begin
  if AWorld.IsFree(0, 14) then
  begin
    LPerson := TAISimEntity.Create(Self);
    LPerson.EntityType := 'person_waiting';
    LPerson.EntityName := 'Person_' + IntToStr(FStats.CreatedCount + 1);
    LPerson.SetPropertyString('status', 'waiting');
    LPerson.SetPropertyInteger('wait_cycles', 0);
    LPerson.SetPropertyInteger('service_cycles', 0);
    LPerson.SetPropertyString('target_desk', '');
    
    AWorld.AddEntity(LPerson, 0, 14);
    FStats.RecordEntityCreated(LPerson.EntityType);
    TriggerEvent('pessoa_criada', LPerson);
  end;
end;

function TfrmMain.CondSearchDesk(Sender: TObject; AEntity: TAISimEntity; AWorld: TAIGridWorld): Boolean;
begin
  // A person who is waiting and has no target desk (or target is busy)
  Result := SameText(AEntity.EntityType, 'person_waiting') and 
            (AEntity.GetPropertyString('target_desk') = '');
end;

procedure TfrmMain.ActSearchDesk(Sender: TObject; AEntity: TAISimEntity; AWorld: TAIGridWorld);
var
  LDesks: TList;
  i: Integer;
  LDesk, LBestDesk: TAISimEntity;
  LMinDist, LDist: Double;
begin
  LDesks := TList.Create;
  try
    AWorld.FindEntitiesByType('service_desk_free', LDesks);
    if LDesks.Count > 0 then
    begin
      LBestDesk := nil;
      LMinDist := 999999.0;
      for i := 0 to LDesks.Count - 1 do
      begin
        LDesk := TAISimEntity(LDesks[i]);
        LDist := Sqrt(Sqr(LDesk.X - AEntity.X) + Sqr(LDesk.Y - AEntity.Y));
        if LDist < LMinDist then
        begin
          LMinDist := LDist;
          LBestDesk := LDesk;
        end;
      end;
      
      if Assigned(LBestDesk) then
      begin
        AEntity.SetPropertyString('target_desk', LBestDesk.EntityName);
        AEntity.SetPropertyInteger('target_x', LBestDesk.X);
        AEntity.SetPropertyInteger('target_y', LBestDesk.Y);
        AEntity.EntityType := 'person_moving';
        AEntity.SetPropertyString('status', 'moving_to_desk');
      end;
    end;
  finally
    LDesks.Free;
  end;
end;

function TfrmMain.CondStartService(Sender: TObject; AEntity: TAISimEntity; AWorld: TAIGridWorld): Boolean;
var
  LTargetName: string;
  LDesk: TAISimEntity;
  i: Integer;
begin
  // If person is moving to desk and is adjacent (distance <= 1.5) to their target desk
  Result := False;
  if not SameText(AEntity.EntityType, 'person_moving') then Exit;
  LTargetName := AEntity.GetPropertyString('target_desk');
  if LTargetName = '' then Exit;
  
  for i := 0 to AWorld.Entities.Count - 1 do
  begin
    LDesk := TAISimEntity(AWorld.Entities[i]);
    if SameText(LDesk.EntityName, LTargetName) and SameText(LDesk.EntityType, 'service_desk_free') then
    begin
      // Check adjacency
      if Abs(LDesk.X - AEntity.X) + Abs(LDesk.Y - AEntity.Y) <= 1 then
      begin
        Result := True;
        Break;
      end;
    end;
  end;
end;

procedure TfrmMain.ActStartService(Sender: TObject; AEntity: TAISimEntity; AWorld: TAIGridWorld);
var
  LTargetName: string;
  LDesk: TAISimEntity;
  i: Integer;
begin
  LTargetName := AEntity.GetPropertyString('target_desk');
  for i := 0 to AWorld.Entities.Count - 1 do
  begin
    LDesk := TAISimEntity(AWorld.Entities[i]);
    if SameText(LDesk.EntityName, LTargetName) then
    begin
      LDesk.EntityType := 'service_desk_busy';
      LDesk.SetPropertyString('status', 'busy');
      LDesk.SetPropertyString('assigned_person_id', AEntity.Id);
      
      AEntity.EntityType := 'person_being_served';
      AEntity.SetPropertyString('status', 'being_served');
      
      FTotalWaitCycles := FTotalWaitCycles + AEntity.GetPropertyInteger('wait_cycles');
      
      TriggerEvent('atendimento_iniciado', AEntity);
      TriggerEvent('guiche_ocupado', LDesk);
      Break;
    end;
  end;
end;

function TfrmMain.CondFinishService(Sender: TObject; AEntity: TAISimEntity; AWorld: TAIGridWorld): Boolean;
var
  LReqTime: Integer;
begin
  LReqTime := StrToIntDef(edtServiceTime.Text, 6);
  Result := SameText(AEntity.EntityType, 'person_being_served') and 
            (AEntity.GetPropertyInteger('service_cycles') >= LReqTime);
end;

procedure TfrmMain.ActFinishService(Sender: TObject; AEntity: TAISimEntity; AWorld: TAIGridWorld);
var
  i: Integer;
  LDesk: TAISimEntity;
begin
  // Find the desk that was serving this person
  for i := 0 to AWorld.Entities.Count - 1 do
  begin
    LDesk := TAISimEntity(AWorld.Entities[i]);
    if SameText(LDesk.GetPropertyString('assigned_person_id'), AEntity.Id) then
    begin
      LDesk.EntityType := 'service_desk_free';
      LDesk.SetPropertyString('status', 'free');
      LDesk.SetPropertyString('assigned_person_id', '');
      TriggerEvent('guiche_livre', LDesk);
      Break;
    end;
  end;
  
  AEntity.EntityType := 'person_served';
  AEntity.SetPropertyString('status', 'leaving');
  AEntity.SetPropertyString('target_desk', '');
  
  Inc(FServicesCompleted);
  TriggerEvent('atendimento_finalizado', AEntity);
end;

function TfrmMain.CondMove(Sender: TObject; AEntity: TAISimEntity; AWorld: TAIGridWorld): Boolean;
begin
  Result := SameText(AEntity.EntityType, 'person_moving') or 
            SameText(AEntity.EntityType, 'person_served') or 
            SameText(AEntity.EntityType, 'person_waiting');
end;

procedure TfrmMain.ActMove(Sender: TObject; AEntity: TAISimEntity; AWorld: TAIGridWorld);
var
  LStatus: string;
  LTargetX, LTargetY: Integer;
  LFreeList: TList;
  LBestCell: TAIGridCell;
  LCell: TAIGridCell;
  LMinDist, LDist: Double;
  i: Integer;
begin
  LStatus := AEntity.GetPropertyString('status');
  
  if SameText(LStatus, 'waiting') then
  begin
    // Increment wait cycles
    AEntity.SetPropertyInteger('wait_cycles', AEntity.GetPropertyInteger('wait_cycles') + 1);
    Exit;
  end;
  
  if SameText(LStatus, 'moving_to_desk') then
  begin
    LTargetX := AEntity.GetPropertyInteger('target_x');
    LTargetY := AEntity.GetPropertyInteger('target_y');
    
    // Increment wait cycles while moving/waiting in line
    AEntity.SetPropertyInteger('wait_cycles', AEntity.GetPropertyInteger('wait_cycles') + 1);
  end
  else if SameText(LStatus, 'leaving') then
  begin
    LTargetX := 14;
    LTargetY := 0;
  end
  else
    Exit;
    
  // Simple custom path finding step towards target coordinates
  LFreeList := TList.Create;
  try
    AWorld.GetFreePositions(AEntity.X, AEntity.Y, 1, LFreeList);
    LBestCell := nil;
    LMinDist := Sqrt(Sqr(LTargetX - AEntity.X) + Sqr(LTargetY - AEntity.Y));
    
    for i := 0 to LFreeList.Count - 1 do
    begin
      LCell := TAIGridCell(LFreeList[i]);
      LDist := Sqrt(Sqr(LTargetX - LCell.X) + Sqr(LTargetY - LCell.Y));
      if LDist < LMinDist then
      begin
        LMinDist := LDist;
        LBestCell := LCell;
      end;
    end;
    
    if Assigned(LBestCell) then
    begin
      AWorld.MoveEntity(AEntity, LBestCell.X, LBestCell.Y);
    end;
  finally
    LFreeList.Free;
  end;
end;

function TfrmMain.CondExit(Sender: TObject; AEntity: TAISimEntity; AWorld: TAIGridWorld): Boolean;
begin
  Result := SameText(AEntity.EntityType, 'person_served') and 
            (AEntity.X = 14) and (AEntity.Y = 0);
end;

procedure TfrmMain.ActExit(Sender: TObject; AEntity: TAISimEntity; AWorld: TAIGridWorld);
begin
  AWorld.RemoveEntity(AEntity);
  FStats.RecordEntityRemoved(AEntity.EntityType);
  TriggerEvent('pessoa_saiu', AEntity);
  AEntity.Free;
end;

end.
