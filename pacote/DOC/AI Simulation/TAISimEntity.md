# TAISimEntity Documentation

The `TAISimEntity` component represents an active agent or object living inside a `TAIGridWorld`. Each entity has a type, energy, age, position, and a virtual `Step` method called every simulation cycle.

## Class Hierarchy
- `TComponent`
  - `TAIBaseComponent`
    - **`TAISimEntity`**

## Key Properties

| Property | Type | Default | Description |
|---|---|---|---|
| `EntityType` | `string` | `''` | Logical type identifier (e.g. `'Prey'`, `'Predator'`, `'Food'`). |
| `Energy` | `Double` | `100.0` | Current energy level. Used by rules and evolution. |
| `Age` | `Integer` | `0` | Cycle count since the entity was created. |
| `Speed` | `Integer` | `1` | Number of cells the entity can move per cycle. |
| `Active` | `Boolean` | `True` | Inactive entities are skipped during rule and movement evaluation. |
| `X` | `Integer` | `-1` | Current column position in the grid. `-1` = not placed. |
| `Y` | `Integer` | `-1` | Current row position in the grid. `-1` = not placed. |

## Key Methods

- **`procedure Step`**
  Called automatically each cycle by the `TAISimulationEngine`. Override in subclasses to implement custom entity behavior.

- **`procedure ClearError`**
  Resets `LastError` and `LastSuccess` to default values.

## Example Usage

```pascal
var
  Entity: TAISimEntity;
begin
  Entity := TAISimEntity.Create(nil);
  try
    Entity.EntityType := 'Predator';
    Entity.Energy := 150.0;
    Entity.Speed := 2;

    if World.AddEntity(Entity, 5, 5) then
      WriteLn('Predator placed at (5,5), Energy: ', Entity.Energy:0:1);
  finally
    // Entity is owned by the world; do not free directly
  end;
end;
```
