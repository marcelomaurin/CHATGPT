# TAISimulationStats Documentation

The `TAISimulationStats` component collects and stores performance and population metrics for each simulation cycle.

## Class Hierarchy
- `TComponent`
  - `TAIBaseComponent`
    - **`TAISimulationStats`**

## Key Properties

| Property | Type | Description |
|---|---|---|
| `CycleCount` | `Integer` | Total number of cycles executed since last `ClearStats`. |
| `LastCycleMs` | `Double` | Duration of the last cycle in milliseconds. |
| `AverageCycleMs` | `Double` | Running average cycle duration in milliseconds. |
| `TotalEntities` | `Integer` | Total entity count recorded in the last cycle. |

## Key Methods

- **`procedure RecordCycle(AElapsedMs: Double)`**
  Records a completed cycle with its duration. Increments `CycleCount` and updates averages.

- **`procedure ClearStats`**
  Resets all counters and averages to zero.

## Example Usage

```pascal
// Called automatically by TAISimulationEngine.
// Can also read metrics to update UI:
procedure TForm1.OnSimCycle(Sender: TObject);
begin
  lblCycles.Caption  := IntToStr(SimStats.CycleCount);
  lblAvgMs.Caption   := Format('%.1f ms', [SimStats.AverageCycleMs]);
end;
```
