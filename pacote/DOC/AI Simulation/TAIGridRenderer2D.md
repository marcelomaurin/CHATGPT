# TAIGridRenderer2D Documentation

The `TAIGridRenderer2D` component renders the current state of a `TAIGridWorld` onto any `TCanvas`, providing a visual representation of the simulation without any external graphics dependencies.

## Class Hierarchy
- `TComponent`
  - `TAIBaseComponent`
    - **`TAIGridRenderer2D`**

## Key Properties

| Property | Type | Default | Description |
|---|---|---|---|
| `CellSize` | `Integer` | `16` | Size in pixels of each grid cell. |
| `OffsetX` | `Integer` | `0` | Horizontal pixel offset for the rendered grid. |
| `OffsetY` | `Integer` | `0` | Vertical pixel offset for the rendered grid. |
| `EmptyCellColor` | `TColor` | `clWhite` | Background color for empty cells. |
| `GridLineColor` | `TColor` | `clSilver` | Color of the grid lines between cells. |
| `ShowGrid` | `Boolean` | `True` | When `True`, draws cell boundary lines. |

## Key Methods

- **`procedure DrawWorld(AWorld: TAIGridWorld; ACanvas: TCanvas)`**
  Renders the complete grid world state onto `ACanvas` using the current rendering settings.

- **`procedure SetEntityColor(const AEntityType: string; AColor: TColor)`**
  Registers a color for a specific entity type. Entities without a registered color use a default fallback.

- **`function GetEntityColor(const AEntityType: string): TColor`**
  Returns the registered color for the given entity type.

## Example Usage

```pascal
var
  Renderer: TAIGridRenderer2D;
begin
  Renderer := TAIGridRenderer2D.Create(nil);
  Renderer.CellSize := 20;
  Renderer.ShowGrid := True;
  Renderer.SetEntityColor('Prey', clGreen);
  Renderer.SetEntityColor('Predator', clRed);
  Renderer.SetEntityColor('Food', clYellow);

  // Call inside OnCycle or Paint event
  Renderer.DrawWorld(MyWorld, PaintBox1.Canvas);
end;
```
