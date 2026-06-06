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
    edtInitialPeople: TEdit;
    edtInitialInfected: TEdit;
    edtContaminationChance: TEdit;
    edtRecoveryTime: TEdit;
    lblConfig: TLabel;
    lblPeoplePrompt: TLabel;
    lblInfectedPrompt: TLabel;
    lblChancePrompt: TLabel;
    lblRecoveryPrompt: TLabel;
    lblStatsTitle: TLabel;
    lblCycles: TLabel;
    lblHealthy: TLabel;
    lblInfected: TLabel;
    lblRecovered: TLabel;
    lblTotalContaminated: TLabel;
    lblStabilization: TLabel;
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
    
    FTotalContaminations: Integer;
    FStabilizationCycle: Integer;
    
    procedure OnEngineCycle(Sender: TObject);
    procedure ResetSimulation;
    procedure UpdateStatsLabels;
    procedure TriggerEvent(const AEventName: string; AEntity: TAISimEntity);
    
    // Trigger callbacks
    procedure OnTriggerRuleApplied(Sender: TObject; const RuleName: string; AEntity: TAISimEntity);
    
    // Rules callbacks
    function CondContamination(Sender: TObject; AEntity: TAISimEntity; AWorld: TAIGridWorld): Boolean;
    procedure ActContamination(Sender: TObject; AEntity: TAISimEntity; AWorld: TAIGridWorld);
    
    function CondRecovery(Sender: TObject; AEntity: TAISimEntity; AWorld: TAIGridWorld): Boolean;
    procedure ActRecovery(Sender: TObject; AEntity: TAISimEntity; AWorld: TAIGridWorld);
    
    function CondMovement(Sender: TObject; AEntity: TAISimEntity; AWorld: TAIGridWorld): Boolean;
    procedure ActMovement(Sender: TObject; AEntity: TAISimEntity; AWorld: TAIGridWorld);
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
  
  FTotalContaminations := 0;
  FStabilizationCycle := -1;

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
  FRules.RegisterRule('Contamination', 30, @CondContamination, @ActContamination);
  FRules.RegisterRule('Recovery', 20, @CondRecovery, @ActRecovery);
  FRules.RegisterRule('Movement', 10, @CondMovement, @ActMovement);

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
  FRenderer.TypeColors.Values['person_healthy'] := '$00FF0000';   // Blue
  FRenderer.TypeColors.Values['person_infected'] := '$000000FF';  // Red
  FRenderer.TypeColors.Values['person_recovered'] := '$0000FF00'; // Green

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
  LPerson: TAISimEntity;
  LPeopleLimit: Integer;
  LInfectedLimit: Integer;
begin
  FEngine.StopSimulation;
  FWorld.ClearWorld;
  FStats.ClearStats;
  
  FTotalContaminations := 0;
  FStabilizationCycle := -1;
  
  LPeopleLimit := StrToIntDef(edtInitialPeople.Text, 30);
  LInfectedLimit := StrToIntDef(edtInitialInfected.Text, 2);
  
  // Set some simple inner walls/obstacles
  for x := 3 to 11 do
  begin
    FWorld.Cells[x, 7].Blocked := True;
  end;
  
  // Spawn Healthy People
  for i := 1 to LPeopleLimit do
  begin
    LPerson := TAISimEntity.Create(Self);
    LPerson.EntityType := 'person_healthy';
    LPerson.EntityName := 'Person_' + IntToStr(i);
    LPerson.SetPropertyInteger('infected_cycles', 0);
    LPerson.SetPropertyBoolean('healthy', True);
    
    repeat
      x := Random(15);
      y := Random(15);
    until FWorld.IsFree(x, y);
    
    FWorld.AddEntity(LPerson, x, y);
    FStats.RecordEntityCreated(LPerson.EntityType);
  end;
  
  // Spawn Infected People
  for i := 1 to LInfectedLimit do
  begin
    LPerson := TAISimEntity.Create(Self);
    LPerson.EntityType := 'person_infected';
    LPerson.EntityName := 'Patient_' + IntToStr(i);
    LPerson.SetPropertyInteger('infected_cycles', 0);
    LPerson.SetPropertyBoolean('healthy', False);
    
    repeat
      x := Random(15);
      y := Random(15);
    until FWorld.IsFree(x, y);
    
    FWorld.AddEntity(LPerson, x, y);
    FStats.RecordEntityCreated(LPerson.EntityType);
    Inc(FTotalContaminations);
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
  LEntity, LPerson: TAISimEntity;
  LHealthy, LInfected, LRecovered: Integer;
begin
  LHealthy := 0;
  LInfected := 0;
  LRecovered := 0;
  
  if Assigned(FWorld) then
  begin
    for i := 0 to FWorld.Entities.Count - 1 do
    begin
      LEntity := TAISimEntity(FWorld.Entities[i]);
      if SameText(LEntity.EntityType, 'person_healthy') then
        Inc(LHealthy)
      else if SameText(LEntity.EntityType, 'person_infected') then
        Inc(LInfected)
      else if SameText(LEntity.EntityType, 'person_recovered') then
        Inc(LRecovered);
    end;
  end;
  
  // Track Stabilization
  if (LInfected = 0) and (FStabilizationCycle = -1) and (FStats.CycleCount > 0) then
  begin
    FStabilizationCycle := FStats.CycleCount;
    // Log stabilization in TriggerEngine
    LPerson := TAISimEntity.Create(Self);
    try
      LPerson.EntityName := 'Mundo';
      TriggerEvent('estabilizacao_simulacao', LPerson);
    finally
      LPerson.Free;
    end;
  end;

  lblCycles.Caption := Format('Ciclos: %d', [FStats.CycleCount]);
  lblHealthy.Caption := Format('Saudáveis (Azul): %d', [LHealthy]);
  lblInfected.Caption := Format('Infectados (Vermelho): %d', [LInfected]);
  lblRecovered.Caption := Format('Recuperados (Verde): %d', [LRecovered]);
  lblTotalContaminated.Caption := Format('Total Acumulado Contaminações: %d', [FTotalContaminations]);
  
  if FStabilizationCycle <> -1 then
    lblStabilization.Caption := Format('Tempo até Estabilização: %d ciclos', [FStabilizationCycle])
  else
    lblStabilization.Caption := 'Tempo até Estabilização: N/A';
  
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

function TfrmMain.CondContamination(Sender: TObject; AEntity: TAISimEntity; AWorld: TAIGridWorld): Boolean;
var
  LNeighbors: TList;
  i: Integer;
  LCell: TAIGridCell;
begin
  Result := False;
  if not SameText(AEntity.EntityType, 'person_healthy') then Exit;
  
  // Check if adjacent to an infected person
  LNeighbors := TList.Create;
  try
    AWorld.GetNeighbors(AEntity.X, AEntity.Y, 1, LNeighbors);
    for i := 0 to LNeighbors.Count - 1 do
    begin
      LCell := TAIGridCell(LNeighbors[i]);
      if Assigned(LCell.Entity) and SameText(LCell.Entity.EntityType, 'person_infected') then
      begin
        Result := True;
        Break;
      end;
    end;
  finally
    LNeighbors.Free;
  end;
end;

procedure TfrmMain.ActContamination(Sender: TObject; AEntity: TAISimEntity; AWorld: TAIGridWorld);
var
  LChance: Integer;
begin
  LChance := StrToIntDef(edtContaminationChance.Text, 30);
  if Random(100) < LChance then
  begin
    AEntity.EntityType := 'person_infected';
    AEntity.SetPropertyInteger('infected_cycles', 0);
    AEntity.SetPropertyBoolean('healthy', False);
    Inc(FTotalContaminations);
    
    FStats.RecordEntityRemoved('person_healthy');
    FStats.RecordEntityCreated('person_infected');
    
    TriggerEvent('pessoa_contaminada', AEntity);
  end;
end;

function TfrmMain.CondRecovery(Sender: TObject; AEntity: TAISimEntity; AWorld: TAIGridWorld): Boolean;
var
  LReqTime: Integer;
begin
  LReqTime := StrToIntDef(edtRecoveryTime.Text, 15);
  Result := SameText(AEntity.EntityType, 'person_infected') and 
            (AEntity.GetPropertyInteger('infected_cycles') >= LReqTime);
end;

procedure TfrmMain.ActRecovery(Sender: TObject; AEntity: TAISimEntity; AWorld: TAIGridWorld);
begin
  AEntity.EntityType := 'person_recovered';
  AEntity.SetPropertyInteger('infected_cycles', 0);
  
  FStats.RecordEntityRemoved('person_infected');
  FStats.RecordEntityCreated('person_recovered');
  
  TriggerEvent('pessoa_recuperada', AEntity);
end;

function TfrmMain.CondMovement(Sender: TObject; AEntity: TAISimEntity; AWorld: TAIGridWorld): Boolean;
begin
  Result := SameText(AEntity.EntityType, 'person_healthy') or 
            SameText(AEntity.EntityType, 'person_infected') or 
            SameText(AEntity.EntityType, 'person_recovered');
end;

procedure TfrmMain.ActMovement(Sender: TObject; AEntity: TAISimEntity; AWorld: TAIGridWorld);
begin
  // Move randomly
  FMovement.MoveRandomly(AEntity);
  
  // Increment infected cycle counter if infected
  if SameText(AEntity.EntityType, 'person_infected') then
  begin
    AEntity.SetPropertyInteger('infected_cycles', AEntity.GetPropertyInteger('infected_cycles') + 1);
  end;
end;

end.
