# AI Simulation Layer

This directory documents the **AI Simulation** components in the Lazarus AI Suite. These components implement a 2D cellular grid simulation engine using pure Lazarus/Free Pascal code.

The simulation engine supports discrete-time multi-agent worlds with configurable rules, movement strategies, scenario persistence, rendering and statistical export.

## Purpose

The **AI Simulation** layer provides simulation engines for creating controlled scenarios where AI behavior can be trained, tested or validated before being applied to real environments.

Typical use cases include:

- robot, vehicle or agent movement on a 2D grid;
- service queues, people flow and resource allocation;
- warehouse movement, logistics and route testing;
- space occupation and interaction models;
- rule-based or statistical agent training;
- repeatable scenarios for comparing AI strategies.

## Table of Components

| Component | Class | Purpose | Key Properties/Methods |
|---|---|---|---|
| **Grid World** | `TAIGridWorld` | 2D discrete grid world | `SetupWorld`, `AddEntity`, `MoveEntity`, `GetNeighbors` |
| **Grid Cell** | `TAIGridCell` | Individual grid cell | `X`, `Y`, `Entity`, `IsEmpty` |
| **Grid Buffer** | `TAIGridBuffer` | Double-buffer for atomic updates | `SwapBuffers`, `GetCurrent`, `GetNext` |
| **Sim Entity** | `TAISimEntity` | Active agent/object in the world | `EntityType`, `Energy`, `Age`, `Step` |
| **Entity Factory** | `TAIEntityFactory` | Creates and places typed entities | `CreateEntity`, `RegisterType` |
| **Simulation Engine** | `TAISimulationEngine` | Main simulation loop controller | `StartSimulation`, `StopSimulation`, `StepCycle` |
| **Rule Engine** | `TAIRuleEngine` | Condition-action behavioral rules | `RegisterRule`, `EvaluateWorldRules` |
| **Trigger Engine** | `TAITriggerEngine` | Event callbacks for simulation lifecycle | `TriggerCycleStart`, `TriggerEntityMoved` |
| **Movement Engine** | `TAIMovementEngine` | Entity displacement strategies | `StepEntityMovement`, `MovementStrategy` |
| **Evolution Engine** | `TAIEvolutionEngine` | Genetic mutation and adaptation | `Mutate`, `SelectFittest` |
| **Simulation Stats** | `TAISimulationStats` | Metrics collector per cycle | `RecordCycle`, `CycleCount`, `ClearStats` |
| **Grid Renderer 2D** | `TAIGridRenderer2D` | Native 2D canvas renderer | `DrawWorld`, `CellSize`, `EntityColors` |
| **Scenario Config** | `TAIScenarioConfig` | Save/load layouts as JSON | `SaveToFile`, `LoadFromFile` |
| **Scenario Generator** | `TAIScenarioGenerator` | LLM-based scenario generation | `GenerateFromPrompt` |
| **Simulation Exporter** | `TAISimulationExporter` | Export results to CSV/TXT/JSON | `ExportToCSV`, `ExportToJSON` |

---

## Code Examples

### 1. Setting Up a Basic Grid World

```pascal
var
  World: TAIGridWorld;
  Engine: TAISimulationEngine;
begin
  World := TAIGridWorld.Create(nil);
  World.SetupWorld(20, 20);
  World.NeighborhoodMode := nmMoore;
  World.BoundaryMode := bmWrap;

  Engine := TAISimulationEngine.Create(nil);
  Engine.GridWorld := World;
  Engine.CycleIntervalMs := 250;
  Engine.OnCycle := @OnSimCycle;
  Engine.StartSimulation;
end;
```

### 2. Registering a Behavioral Rule

```pascal
procedure TForm1.OnLowEnergyCondition(Sender: TObject; AEntity: TAISimEntity; AWorld: TAIGridWorld; var AResult: Boolean);
begin
  AResult := AEntity.Energy < 20;
end;

procedure TForm1.OnLowEnergyAction(Sender: TObject; AEntity: TAISimEntity; AWorld: TAIGridWorld);
begin
  AEntity.Energy := AEntity.Energy - 1;
end;

RuleEngine.RegisterRule('LowEnergy', 10, @OnLowEnergyCondition, @OnLowEnergyAction);
```

### 3. Exporting Simulation Results

```pascal
var
  Exporter: TAISimulationExporter;
begin
  Exporter := TAISimulationExporter.Create(nil);
  try
    Exporter.ExportToCSV(Stats, 'simulation_results.csv');
    Exporter.ExportToJSON(World, 'world_snapshot.json');
  finally
    Exporter.Free;
  end;
end;
```
