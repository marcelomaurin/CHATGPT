# TAIGridWorld Documentation

The `TAIGridWorld` component manages a 2D discrete grid space where simulation entities live and interact. It supports configurable boundary and neighborhood modes.

## Class Hierarchy
- `TComponent`
  - `TAIBaseComponent`
    - **`TAIGridWorld`**

## Key Properties

| Property | Type | Default | Description |
|---|---|---|---|
| `Width` | `Integer` | `10` | Number of columns in the grid. |
| `Height` | `Integer` | `10` | Number of rows in the grid. |
| `NeighborhoodMode` | `TNeighborhoodMode` | `nmMoore` | `nmMoore` (8 neighbors) or `nmVonNeumann` (4 neighbors). |
| `BoundaryMode` | `TBoundaryMode` | `bmBlock` | `bmBlock` (solid walls) or `bmWrap` (toroidal world). |
| `Entities` | `TList` | — | (Read-only) List of all active entities in the world. |
| `Cells[X, Y]` | `TAIGridCell` | — | (Read-only) Direct access to a specific grid cell. |

## Key Methods

- **`procedure SetupWorld(AWidth, AHeight: Integer)`**
  Initializes the grid with the given dimensions, creating all cell objects.

- **`procedure ClearWorld`**
  Removes all entities from all cells without destroying the grid structure.

- **`function IsInBounds(X, Y: Integer): Boolean`**
  Returns `True` if the coordinates are within the grid boundaries.

- **`function IsFree(X, Y: Integer): Boolean`**
  Returns `True` if the cell at `(X, Y)` exists and has no entity.

- **`function AddEntity(AEntity: TAISimEntity; X, Y: Integer): Boolean`**
  Places an entity on the specified cell. Returns `False` if the cell is occupied.

- **`function RemoveEntity(AEntity: TAISimEntity): Boolean`**
  Removes an entity from the world, freeing its cell.

- **`function MoveEntity(AEntity: TAISimEntity; NewX, NewY: Integer): Boolean`**
  Moves an entity to a new cell, respecting boundary mode. Returns `False` if target is occupied.

- **`procedure GetNeighbors(X, Y, ARadius: Integer; AOutList: TList)`**
  Fills `AOutList` with `TAIGridCell` references within radius, filtered by neighborhood mode.

- **`procedure GetFreePositions(X, Y, ARadius: Integer; AOutList: TList)`**
  Fills `AOutList` with empty `TAIGridCell` references within radius.

- **`function CountEntitiesByType(const AType: string): Integer`**
  Returns the count of entities matching the given `EntityType` string.

## Error Handling
Returns `False` on method failure. Check `LastError` and `LastSuccess` for details.

## Example Usage

```pascal
var
  World: TAIGridWorld;
  Entity: TAISimEntity;
begin
  World := TAIGridWorld.Create(nil);
  try
    World.SetupWorld(30, 30);
    World.BoundaryMode := bmWrap;
    World.NeighborhoodMode := nmMoore;

    Entity := TAISimEntity.Create(nil);
    Entity.EntityType := 'Prey';
    Entity.Energy := 100;

    if World.AddEntity(Entity, 10, 10) then
      WriteLn('Entity placed at (10,10)')
    else
      WriteLn('Cell occupied: ', World.LastError);
  finally
    World.Free;
  end;
end;
```
