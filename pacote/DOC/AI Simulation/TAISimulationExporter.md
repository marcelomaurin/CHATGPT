# TAISimulationExporter Documentation

The `TAISimulationExporter` component exports simulation results and world snapshots to standard file formats for external analysis.

## Class Hierarchy
- `TComponent`
  - `TAIBaseComponent`
    - **`TAISimulationExporter`**

## Key Methods

- **`function ExportToCSV(AStats: TAISimulationStats; const AFileName: string): Boolean`**
  Writes the accumulated per-cycle statistics (cycle number, entity count, average energy, cycle duration) to a CSV file. Returns `True` on success.

- **`function ExportToTXT(AStats: TAISimulationStats; const AFileName: string): Boolean`**
  Writes a human-readable summary of the simulation run to a plain text file.

- **`function ExportToJSON(AWorld: TAIGridWorld; const AFileName: string): Boolean`**
  Serializes the complete current world state (all cells and entities with their properties) to a JSON snapshot file.

## Error Handling
Returns `False` on failure. Check `LastError` for the error description.

## Example Usage

```pascal
var
  Exporter: TAISimulationExporter;
begin
  Exporter := TAISimulationExporter.Create(nil);
  try
    // Export per-cycle statistics
    if not Exporter.ExportToCSV(SimStats, 'results.csv') then
      ShowMessage('CSV export failed: ' + Exporter.LastError);

    // Export world snapshot
    if not Exporter.ExportToJSON(SimWorld, 'snapshot_cycle_100.json') then
      ShowMessage('JSON export failed: ' + Exporter.LastError);

    // Export summary
    Exporter.ExportToTXT(SimStats, 'summary.txt');
  finally
    Exporter.Free;
  end;
end;
```
