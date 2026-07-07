# AI Simulation Layer

This directory documents the **AI Simulation** components in the Lazarus AI Suite. These components implement a complete 2D cellular grid simulation engine using 100% pure Lazarus/Free Pascal code, with no external dependencies.

The simulation engine supports discrete-time multi-agent worlds with configurable rules, movement strategies, genetic evolution, scenario persistence, rendering and statistical export.

> **Important:** in this project, **AI Simulation** does not mean fake components, mocked results or artificial success messages. This layer is dedicated to computational simulation of real or controlled environments, allowing developers to model movement, queues, agents, resources, propagation, logistics and other scenarios used to train, validate or test AI behavior safely before applying it to real systems.

Typical use cases include:

- robot, vehicle or agent movement on a 2D grid;
- service queues, people flow and resource allocation;
- warehouse movement, logistics and route testing;
- contamination, propagation, occupation and interaction models;
- rule-based, evolutionary or statistical agent training;
- safe validation of AI decisions in repeatable scenarios.

Therefore, **AI Simulation** is a legitimate simulation domain inside the suite. It must not be confused with simulated/fake behavior in unrelated components. Components outside this layer that do not have a real backend should report clear unavailability/errors instead of generating artificial results.

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

## AI Simulation vs. Fake Component Simulation

| Term | Correct meaning in this project |
|---|---|
| **AI Simulation** | A simulation layer for modeling real or controlled environments, useful for AI training, testing and validation. |
| **Fake/simulated component** | A component that pretends to execute a real operation and returns artificial success/data. This must not be used as production behavior. |
| **Placeholder** | An incomplete structure. It must be documented as incomplete and should return a clear unsupported/unavailable error when called. |

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
procedure TForm1.OnHungerCondition(Sender: TObject; AEntity: TAISimEntity; AWorld: TAIGridWorld; var AResult: Boolean);
begin
  AResult := AEntity.Energy < 20;
end;

procedure TForm1.OnHungerAction(Sender: TObject; AEntity: TAISimEntity; AWorld: TAIGridWorld);
begin
  AEntity.Energy := AEntity.Energy - 1; // starving
end;

// Registration
RuleEngine.RegisterRule('Hunger', 10, @OnHungerCondition, @OnHungerAction);
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
