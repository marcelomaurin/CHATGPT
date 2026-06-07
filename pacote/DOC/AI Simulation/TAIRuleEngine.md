# TAIRuleEngine Documentation

The `TAIRuleEngine` component manages a prioritized collection of condition-action rules that are evaluated for each active entity every simulation cycle.

## Class Hierarchy
- `TComponent`
  - `TAIBaseComponent`
    - **`TAIRuleEngine`**

## Key Properties

| Property | Type | Default | Description |
|---|---|---|---|
| `Rules` | `TAISimulationRuleCollection` | — | Collection of registered `TAISimulationRule` items. |

## TAISimulationRule Properties

| Property | Type | Default | Description |
|---|---|---|---|
| `RuleName` | `string` | `''` | Descriptive name for the rule. |
| `Priority` | `Integer` | `10` | Execution priority. Higher values execute first. |
| `Active` | `Boolean` | `True` | Inactive rules are skipped during evaluation. |
| `OnCondition` | `TRuleConditionEvent` | `nil` | `function(Sender, Entity, World): Boolean` — returns `True` when the rule applies. |
| `OnAction` | `TRuleActionEvent` | `nil` | `procedure(Sender, Entity, World)` — executed when condition is met. |

## Key Methods

- **`procedure RegisterRule(const AName: string; APriority: Integer; ACondition: TRuleConditionEvent; AAction: TRuleActionEvent)`**
  Adds a new rule to the collection with the given name, priority and callbacks.

- **`procedure ClearRules`**
  Removes all registered rules from the collection.

- **`function EvaluateAndExecute(AEntity: TAISimEntity; AWorld: TAIGridWorld): Boolean`**
  Evaluates rules sorted by priority for a single entity. Executes the first matching rule's action. Returns `True` if any rule was triggered.

- **`procedure EvaluateWorldRules(AWorld: TAIGridWorld)`**
  Iterates over all active entities in the world and calls `EvaluateAndExecute` for each one. Called automatically by `TAISimulationEngine` each cycle.

## Example Usage

```pascal
function TForm1.LowEnergyCondition(Sender: TObject; AEntity: TAISimEntity; AWorld: TAIGridWorld): Boolean;
begin
  Result := AEntity.Energy < 15.0;
end;

procedure TForm1.DieAction(Sender: TObject; AEntity: TAISimEntity; AWorld: TAIGridWorld);
begin
  AEntity.Active := False;
  AWorld.RemoveEntity(AEntity);
end;

// Registration
RuleEngine.RegisterRule('Starvation', 100, @LowEnergyCondition, @DieAction);
Engine.RuleEngine := RuleEngine;
```
