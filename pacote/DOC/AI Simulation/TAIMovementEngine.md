# TAIMovementEngine Documentation

The `TAIMovementEngine` component handles entity displacement within the `TAIGridWorld` each simulation cycle, implementing pluggable movement strategies.

## Class Hierarchy
- `TComponent`
  - `TAIBaseComponent`
    - **`TAIMovementEngine`**

## Key Properties

| Property | Type | Default | Description |
|---|---|---|---|
| `MovementStrategy` | `TAIMovementStrategy` | `msRandom` | Default strategy applied to entities without a custom strategy: `msRandom`, `msDirected`, `msFlee`, `msStill`. |
| `GridWorld` | `TAIGridWorld` | `nil` | Reference to the world used for movement resolution. |

## Key Methods

- **`function StepEntityMovement(AEntity: TAISimEntity): Boolean`**
  Attempts to move the entity one step according to its assigned strategy. Returns `True` if the entity moved to a new cell.

- **`function MoveRandom(AEntity: TAISimEntity): Boolean`**
  Picks a random free neighbor cell and moves the entity there.

- **`function MoveToward(AEntity: TAISimEntity; TargetX, TargetY: Integer): Boolean`**
  Moves the entity one step in the direction of the target coordinates.

- **`function Flee(AEntity: TAISimEntity; SourceX, SourceY: Integer): Boolean`**
  Moves the entity one step away from the given source coordinates.

## Example Usage

```pascal
var
  MovEngine: TAIMovementEngine;
begin
  MovEngine := TAIMovementEngine.Create(nil);
  MovEngine.GridWorld := MyWorld;
  MovEngine.MovementStrategy := msRandom;
  Engine.MovementEngine := MovEngine;
end;
```
