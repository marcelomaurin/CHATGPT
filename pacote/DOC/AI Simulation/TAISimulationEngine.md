# TAISimulationEngine Documentation

The `TAISimulationEngine` component is the main controller of the simulation loop. It orchestrates movement, rule evaluation, entity steps, and statistics recording on each discrete time cycle.

## Class Hierarchy
- `TComponent`
  - `TAIBaseComponent`
    - **`TAISimulationEngine`**

## Key Properties

| Property | Type | Default | Description |
|---|---|---|---|
| `GridWorld` | `TAIGridWorld` | `nil` | The grid world to simulate. Must be assigned before calling `StartSimulation`. |
| `RuleEngine` | `TAIRuleEngine` | `nil` | Optional rule engine applied each cycle. |
| `TriggerEngine` | `TAITriggerEngine` | `nil` | Optional trigger engine for lifecycle events. |
| `MovementEngine` | `TAIMovementEngine` | `nil` | Optional movement engine for entity displacement. |
| `EvolutionEngine` | `TAIEvolutionEngine` | `nil` | Optional evolution engine for genetic adaptation. |
| `Stats` | `TAISimulationStats` | `nil` | Optional stats collector. |
| `CycleIntervalMs` | `Integer` | `500` | Timer interval in milliseconds between cycles. |
| `CycleLimit` | `Integer` | `0` | Maximum number of cycles before auto-stop. `0` = unlimited. |
| `Running` | `Boolean` | `False` | (Read-only) `True` if the simulation is active. |
| `Paused` | `Boolean` | `False` | (Read-only) `True` if the simulation is paused. |

## Key Methods

- **`procedure StartSimulation`**
  Starts the simulation timer. Requires `GridWorld` to be assigned.

- **`procedure PauseSimulation`**
  Toggles pause state. The timer is suspended while paused.

- **`procedure StopSimulation`**
  Stops the simulation and disables the internal timer.

- **`procedure StepCycle`**
  Manually executes a single simulation cycle. Useful for step-by-step debugging.

## Events

- **`OnCycle: TNotifyEvent`**
  Fired at the end of each cycle after all processing is complete.

## Cycle Execution Order

Each call to `StepCycle` executes in this sequence:
1. `TriggerEngine.TriggerCycleStart`
2. `MovementEngine`: process movement for all active entities
3. `RuleEngine`: evaluate behavioral rules for all entities
4. Entity internal `Step` method called for all active entities
5. `Stats.RecordCycle` with elapsed time
6. `TriggerEngine.TriggerCycleEnd`
7. `OnCycle` event fired
8. Check `CycleLimit` and auto-stop if reached

## Example Usage

```pascal
var
  Engine: TAISimulationEngine;
begin
  Engine := TAISimulationEngine.Create(Self);
  Engine.GridWorld := MyWorld;
  Engine.RuleEngine := MyRuleEngine;
  Engine.MovementEngine := MyMovementEngine;
  Engine.Stats := MyStats;
  Engine.CycleIntervalMs := 200;
  Engine.CycleLimit := 1000;
  Engine.OnCycle := @OnSimCycle;
  Engine.StartSimulation;
end;

procedure TForm1.OnSimCycle(Sender: TObject);
begin
  GridRenderer.DrawWorld(MyWorld, Image1.Canvas);
  lblCycles.Caption := IntToStr(MyStats.CycleCount);
end;
```
