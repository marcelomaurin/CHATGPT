# TAIScenarioConfig Documentation

The `TAIScenarioConfig` component provides save/load functionality for simulation layouts, persisting world dimensions, entity placements, and engine parameters as JSON files.

## Class Hierarchy
- `TComponent`
  - `TAIBaseComponent`
    - **`TAIScenarioConfig`**

## Key Properties

| Property | Type | Default | Description |
|---|---|---|---|
| `WorldWidth` | `Integer` | `20` | Grid width stored in the scenario. |
| `WorldHeight` | `Integer` | `20` | Grid height stored in the scenario. |
| `CycleIntervalMs` | `Integer` | `500` | Simulation cycle interval stored in the scenario. |
| `ScenarioName` | `string` | `''` | Human-readable name for the scenario. |
| `Description` | `string` | `''` | Optional scenario description. |

## Key Methods

- **`function SaveToFile(const AFileName: string): Boolean`**
  Serializes the current scenario configuration to a JSON file. Returns `True` on success.

- **`function LoadFromFile(const AFileName: string): Boolean`**
  Loads a previously saved scenario JSON file and populates all properties. Returns `True` on success.

- **`procedure ApplyToEngine(AEngine: TAISimulationEngine)`**
  Applies the loaded configuration directly to a simulation engine instance.

## Example Usage

```pascal
var
  Config: TAIScenarioConfig;
begin
  Config := TAIScenarioConfig.Create(nil);
  try
    Config.LoadFromFile('my_scenario.json');
    Config.ApplyToEngine(SimEngine);
    WriteLn('Loaded: ', Config.ScenarioName);
  finally
    Config.Free;
  end;
end;
```
