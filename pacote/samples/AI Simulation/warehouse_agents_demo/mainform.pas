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
    edtNumWorkers: TEdit;
    edtNumPackages: TEdit;
    lblConfig: TLabel;
    lblWorkersPrompt: TLabel;
    lblPackagesPrompt: TLabel;
    lblStatsTitle: TLabel;
    lblCycles: TLabel;
    lblIdleWorkers: TLabel;
    lblSeekingWorkers: TLabel;
    lblCarryingWorkers: TLabel;
    lblWaitingPackages: TLabel;
    lblReservedPackages: TLabel;
    lblDeliveredPackages: TLabel;
    lblAvgDeliveryTime: TLabel;
    lblLogTitle: TLabel;
    lblLastEvent: TLabel;
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
    
    FTotalDelivered: Integer;
    FTotalDeliveryCycles: Integer;
    FAllDeliveredTriggered: Boolean;
    
    procedure OnEngineCycle(Sender: TObject);
    procedure ResetSimulation;
    procedure UpdateStatsLabels;
    procedure TriggerEvent(const AEventName: string; AEntity: TAISimEntity);
    
    // Trigger callbacks
    procedure OnTriggerRuleApplied(Sender: TObject; const RuleName: string; AEntity: TAISimEntity);
    
    // Rules callbacks
    function CondSearchPackage(Sender: TObject; AEntity: TAISimEntity; AWorld: TAIGridWorld): Boolean;
    procedure ActSearchPackage(Sender: TObject; AEntity: TAISimEntity; AWorld: TAIGridWorld);
    
    function CondCollectPackage(Sender: TObject; AEntity: TAISimEntity; AWorld: TAIGridWorld): Boolean;
    procedure ActCollectPackage(Sender: TObject; AEntity: TAISimEntity; AWorld: TAIGridWorld);
    
    function CondDeliverPackage(Sender: TObject; AEntity: TAISimEntity; AWorld: TAIGridWorld): Boolean;
    procedure ActDeliverPackage(Sender: TObject; AEntity: TAISimEntity; AWorld: TAIGridWorld);
    
    function CondMoveWorker(Sender: TObject; AEntity: TAISimEntity; AWorld: TAIGridWorld): Boolean;
    procedure ActMoveWorker(Sender: TObject; AEntity: TAISimEntity; AWorld: TAIGridWorld);
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
  
  FTotalDelivered := 0;
  FTotalDeliveryCycles := 0;
  FAllDeliveredTriggered := False;

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
  FRules.RegisterRule('DeliverPackage', 40, @CondDeliverPackage, @ActDeliverPackage);
  FRules.RegisterRule('CollectPackage', 30, @CondCollectPackage, @ActCollectPackage);
  FRules.RegisterRule('SearchPackage', 20, @CondSearchPackage, @ActSearchPackage);
  FRules.RegisterRule('MoveWorker', 10, @CondMoveWorker, @ActMoveWorker);

  FTrigger := TAITriggerEngine.Create(Self);
  FTrigger.OnRuleApplied := @OnTriggerRuleApplied;

  FStats := TAISimulationStats.Create(Self);

  FEngine := TAISimulationEngine.Create(Self);
  FEngine.GridWorld := FWorld;
  FEngine.RuleEngine := FRules;
  FEngine.MovementEngine := FMovement;
  FEngine.TriggerEngine := FTrigger;
  FEngine.Stats := FStats;
  FEngine.CycleIntervalMs := 200;
  FEngine.OnCycle := @OnEngineCycle;

  FExporter := TAISimulationExporter.Create(Self);

  FRenderer := TAIGridRenderer2D.Create(Self);
  FRenderer.GridWorld := FWorld;
  FRenderer.CellSize := 38;
  FRenderer.ShowGridLines := True;
  
  // Setup color mapping
  FRenderer.TypeColors.Values['worker_agent_idle'] := '$00FFC000';     // Light Blue
  FRenderer.TypeColors.Values['worker_agent_moving'] := '$00FF0000';   // Dark Blue
  FRenderer.TypeColors.Values['worker_agent_carrying'] := '$0000A5FF'; // Orange
  FRenderer.TypeColors.Values['package_waiting'] := '$0000FFFF';       // Yellow
  FRenderer.TypeColors.Values['package_reserved'] := '$00800080';      // Purple
  FRenderer.TypeColors.Values['delivery_zone'] := '$0000FF00';         // Green

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
  i, x, y: Integer;
  LWorker: TAISimEntity;
  LPkg: TAISimEntity;
  LZone: TAISimEntity;
  LWorkersLimit: Integer;
  LPackagesLimit: Integer;
begin
  FEngine.StopSimulation;
  FWorld.ClearWorld;
  FStats.ClearStats;
  
  FTotalDelivered := 0;
  FTotalDeliveryCycles := 0;
  FAllDeliveredTriggered := False;
  
  LWorkersLimit := StrToIntDef(edtNumWorkers.Text, 4);
  LPackagesLimit := StrToIntDef(edtNumPackages.Text, 10);
  
  // Set shelves obstacles (parallel lines)
  for y := 2 to 5 do
  begin
    FWorld.Cells[3, y].Blocked := True;
    FWorld.Cells[7, y].Blocked := True;
    FWorld.Cells[11, y].Blocked := True;
  end;
  for y := 9 to 12 do
  begin
    FWorld.Cells[3, y].Blocked := True;
    FWorld.Cells[7, y].Blocked := True;
    FWorld.Cells[11, y].Blocked := True;
  end;
  
  // Place Delivery Zone at bottom right
  LZone := TAISimEntity.Create(Self);
  LZone.EntityType := 'delivery_zone';
  LZone.EntityName := 'DeliveryZone';
  FWorld.AddEntity(LZone, 14, 14);
  
  // Spawn worker agents (starting at bottom left zone)
  for i := 1 to LWorkersLimit do
  begin
    LWorker := TAISimEntity.Create(Self);
    LWorker.EntityType := 'worker_agent_idle';
    LWorker.EntityName := 'Worker_' + IntToStr(i);
    LWorker.SetPropertyString('status', 'idle');
    LWorker.SetPropertyString('target_package_id', '');
    LWorker.SetPropertyInteger('target_x', -1);
    LWorker.SetPropertyInteger('target_y', -1);
    LWorker.SetPropertyInteger('delivery_cycles', 0);
    
    repeat
      x := Random(3);
      y := 12 + Random(3);
    until FWorld.IsFree(x, y);
    
    FWorld.AddEntity(LWorker, x, y);
    FStats.RecordEntityCreated('worker_agent');
  end;
  
  // Spawn packages
  for i := 1 to LPackagesLimit do
  begin
    LPkg := TAISimEntity.Create(Self);
    LPkg.EntityType := 'package_waiting';
    LPkg.EntityName := 'Package_' + IntToStr(i);
    LPkg.SetPropertyString('status', 'waiting');
    
    repeat
      x := Random(15);
      y := Random(15);
    until FWorld.IsFree(x, y);
    
    FWorld.AddEntity(LPkg, x, y);
    FStats.RecordEntityCreated('package');
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
  lblLastEvent.Caption := Format('%s (%s)', [RuleName, AEntity.EntityName]);
end;

procedure TfrmMain.UpdateStatsLabels;
var
  i: Integer;
  LEntity: TAISimEntity;
  LStatus: string;
  LIdle, LSeeking, LCarrying: Integer;
  LWaiting, LReserved: Integer;
  LAvgDelTime: Double;
begin
  LIdle := 0;
  LSeeking := 0;
  LCarrying := 0;
  LWaiting := 0;
  LReserved := 0;
  
  if Assigned(FWorld) then
  begin
    for i := 0 to FWorld.Entities.Count - 1 do
    begin
      LEntity := TAISimEntity(FWorld.Entities[i]);
      if SameText(LEntity.EntityType, 'worker_agent_idle') then
        Inc(LIdle)
      else if SameText(LEntity.EntityType, 'worker_agent_moving') then
        Inc(LSeeking)
      else if SameText(LEntity.EntityType, 'worker_agent_carrying') then
        Inc(LCarrying)
      else if SameText(LEntity.EntityType, 'package_waiting') then
        Inc(LWaiting)
      else if SameText(LEntity.EntityType, 'package_reserved') then
        Inc(LReserved);
    end;
  end;
  
  if FTotalDelivered > 0 then
    LAvgDelTime := FTotalDeliveryCycles / FTotalDelivered
  else
    LAvgDelTime := 0.0;
    
  // Check if all packages are delivered
  if (LWaiting = 0) and (LReserved = 0) and (LCarrying = 0) and not FAllDeliveredTriggered and (FStats.CycleCount > 0) then
  begin
    FAllDeliveredTriggered := True;
    LEntity := TAISimEntity.Create(Self);
    try
      LEntity.EntityName := 'Armazém';
      TriggerEvent('todos_pacotes_entregues', LEntity);
    finally
      LEntity.Free;
    end;
  end;

  lblCycles.Caption := Format('Ciclos: %d', [FStats.CycleCount]);
  lblIdleWorkers.Caption := Format('Agentes Livres (Azul Claro): %d', [LIdle]);
  lblSeekingWorkers.Caption := Format('Agentes Buscando (Azul Escuro): %d', [LSeeking]);
  lblCarryingWorkers.Caption := Format('Agentes Carregando (Laranja): %d', [LCarrying]);
  lblWaitingPackages.Caption := Format('Pacotes Aguardando (Amarelo): %d', [LWaiting]);
  lblReservedPackages.Caption := Format('Pacotes Reservados (Roxo): %d', [LReserved]);
  lblDeliveredPackages.Caption := Format('Pacotes Entregues (Verde): %d', [FTotalDelivered]);
  lblAvgDeliveryTime.Caption := Format('Tempo Médio Entrega: %.1f ciclos', [LAvgDelTime]);
  
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

function TfrmMain.CondSearchPackage(Sender: TObject; AEntity: TAISimEntity; AWorld: TAIGridWorld): Boolean;
begin
  Result := SameText(AEntity.EntityType, 'worker_agent_idle') and 
            (AEntity.GetPropertyString('target_package_id') = '');
end;

procedure TfrmMain.ActSearchPackage(Sender: TObject; AEntity: TAISimEntity; AWorld: TAIGridWorld);
var
  LPackages: TList;
  i: Integer;
  LPkg, LBestPkg: TAISimEntity;
  LMinDist, LDist: Double;
begin
  LPackages := TList.Create;
  try
    AWorld.FindEntitiesByType('package_waiting', LPackages);
    if LPackages.Count > 0 then
    begin
      LBestPkg := nil;
      LMinDist := 999999.0;
      for i := 0 to LPackages.Count - 1 do
      begin
        LPkg := TAISimEntity(LPackages[i]);
        LDist := Sqrt(Sqr(LPkg.X - AEntity.X) + Sqr(LPkg.Y - AEntity.Y));
        if LDist < LMinDist then
        begin
          LMinDist := LDist;
          LBestPkg := LPkg;
        end;
      end;
      
      if Assigned(LBestPkg) then
      begin
        // Lock package target
        LBestPkg.EntityType := 'package_reserved';
        LBestPkg.SetPropertyString('status', 'reserved');
        
        AEntity.SetPropertyString('target_package_id', LBestPkg.Id);
        AEntity.SetPropertyInteger('target_x', LBestPkg.X);
        AEntity.SetPropertyInteger('target_y', LBestPkg.Y);
        AEntity.EntityType := 'worker_agent_moving';
        AEntity.SetPropertyString('status', 'moving_to_package');
        
        TriggerEvent('pacote_reservado', LBestPkg);
      end;
    end;
  finally
    LPackages.Free;
  end;
end;

function TfrmMain.CondCollectPackage(Sender: TObject; AEntity: TAISimEntity; AWorld: TAIGridWorld): Boolean;
var
  LTargetX, LTargetY: Integer;
begin
  Result := False;
  if not SameText(AEntity.EntityType, 'worker_agent_moving') then Exit;
  LTargetX := AEntity.GetPropertyInteger('target_x');
  LTargetY := AEntity.GetPropertyInteger('target_y');
  
  if (LTargetX <> -1) and (LTargetY <> -1) then
  begin
    // Check if worker is adjacent to target package coordinates
    if Abs(LTargetX - AEntity.X) + Abs(LTargetY - AEntity.Y) <= 1 then
      Result := True;
  end;
end;

procedure TfrmMain.ActCollectPackage(Sender: TObject; AEntity: TAISimEntity; AWorld: TAIGridWorld);
var
  i: Integer;
  LPkg: TAISimEntity;
  LTargetId: string;
begin
  LTargetId := AEntity.GetPropertyString('target_package_id');
  
  // Find the package in the world and remove it since worker is carrying it
  for i := 0 to AWorld.Entities.Count - 1 do
  begin
    LPkg := TAISimEntity(AWorld.Entities[i]);
    if SameText(LPkg.Id, LTargetId) then
    begin
      AWorld.RemoveEntity(LPkg);
      FStats.RecordEntityRemoved('package');
      LPkg.Free;
      Break;
    end;
  end;
  
  AEntity.EntityType := 'worker_agent_carrying';
  AEntity.SetPropertyString('status', 'carrying_package');
  AEntity.SetPropertyInteger('target_x', 14); // Delivery zone target x
  AEntity.SetPropertyInteger('target_y', 14); // Delivery zone target y
  AEntity.SetPropertyInteger('delivery_cycles', 0);
  
  TriggerEvent('pacote_coletado', AEntity);
end;

function TfrmMain.CondDeliverPackage(Sender: TObject; AEntity: TAISimEntity; AWorld: TAIGridWorld): Boolean;
begin
  // Adjacent or on the delivery zone (14, 14)
  Result := SameText(AEntity.EntityType, 'worker_agent_carrying') and 
            (Abs(14 - AEntity.X) + Abs(14 - AEntity.Y) <= 1);
end;

procedure TfrmMain.ActDeliverPackage(Sender: TObject; AEntity: TAISimEntity; AWorld: TAIGridWorld);
begin
  Inc(FTotalDelivered);
  FTotalDeliveryCycles := FTotalDeliveryCycles + AEntity.GetPropertyInteger('delivery_cycles');
  
  AEntity.EntityType := 'worker_agent_idle';
  AEntity.SetPropertyString('status', 'idle');
  AEntity.SetPropertyString('target_package_id', '');
  AEntity.SetPropertyInteger('target_x', -1);
  AEntity.SetPropertyInteger('target_y', -1);
  
  TriggerEvent('pacote_entregue', AEntity);
end;

function TfrmMain.CondMoveWorker(Sender: TObject; AEntity: TAISimEntity; AWorld: TAIGridWorld): Boolean;
begin
  Result := SameText(AEntity.EntityType, 'worker_agent_moving') or 
            SameText(AEntity.EntityType, 'worker_agent_carrying');
end;

procedure TfrmMain.ActMoveWorker(Sender: TObject; AEntity: TAISimEntity; AWorld: TAIGridWorld);
var
  LTargetX, LTargetY: Integer;
  LFreeList: TList;
  LBestCell: TAIGridCell;
  LCell: TAIGridCell;
  LMinDist, LDist: Double;
  i: Integer;
  LStatus: string;
begin
  LTargetX := AEntity.GetPropertyInteger('target_x');
  LTargetY := AEntity.GetPropertyInteger('target_y');
  
  if (LTargetX = -1) or (LTargetY = -1) then Exit;
  
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
  
  LStatus := AEntity.GetPropertyString('status');
  if SameText(LStatus, 'carrying_package') then
  begin
    AEntity.SetPropertyInteger('delivery_cycles', AEntity.GetPropertyInteger('delivery_cycles') + 1);
  end;
end;

end.
