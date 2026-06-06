unit aigridbuffer;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, aigridworld, aigridcell;

type
  TCellStateRecord = record
    Blocked: Boolean;
    Cost: Double;
    Energy: Double;
    TerrainType: string;
    Weight: Double;
    Tag: Integer;
  end;

  { TAIGridBuffer }

  TAIGridBuffer = class
  private
    FWorld: TAIGridWorld;
    FCurrentStates: array of array of TCellStateRecord;
    FNextStates: array of array of TCellStateRecord;
    FWidth: Integer;
    FHeight: Integer;
  public
    constructor Create(AWorld: TAIGridWorld);
    destructor Destroy; override;
    
    procedure PrepareCycle;
    procedure SetNextBlocked(X, Y: Integer; ABlocked: Boolean);
    procedure SetNextTerrain(X, Y: Integer; const ATerrain: string);
    procedure SetNextCost(X, Y: Integer; ACost: Double);
    procedure SetNextEnergy(X, Y: Integer; AEnergy: Double);
    
    procedure CommitCycle;
    procedure RollbackCycle;
  end;

implementation

constructor TAIGridBuffer.Create(AWorld: TAIGridWorld);
begin
  FWorld := AWorld;
  FWidth := 0;
  FHeight := 0;
end;

destructor TAIGridBuffer.Destroy;
begin
  inherited Destroy;
end;

procedure TAIGridBuffer.PrepareCycle;
var
  X, Y: Integer;
  LCell: TAIGridCell;
begin
  if not Assigned(FWorld) then Exit;
  
  FWidth := FWorld.Width;
  FHeight := FWorld.Height;
  
  SetLength(FCurrentStates, FWidth, FHeight);
  SetLength(FNextStates, FWidth, FHeight);
  
  for X := 0 to FWidth - 1 do
  begin
    for Y := 0 to FHeight - 1 do
    begin
      LCell := FWorld.Cells[X, Y];
      if Assigned(LCell) then
      begin
        FCurrentStates[X, Y].Blocked := LCell.Blocked;
        FCurrentStates[X, Y].Cost := LCell.Cost;
        FCurrentStates[X, Y].Energy := LCell.Energy;
        FCurrentStates[X, Y].TerrainType := LCell.TerrainType;
        FCurrentStates[X, Y].Weight := LCell.Weight;
        FCurrentStates[X, Y].Tag := LCell.Tag;
        
        // Next states start as a copy of current states
        FNextStates[X, Y] := FCurrentStates[X, Y];
      end;
    end;
  end;
end;

procedure TAIGridBuffer.SetNextBlocked(X, Y: Integer; ABlocked: Boolean);
begin
  if (X >= 0) and (X < FWidth) and (Y >= 0) and (Y < FHeight) then
    FNextStates[X, Y].Blocked := ABlocked;
end;

procedure TAIGridBuffer.SetNextTerrain(X, Y: Integer; const ATerrain: string);
begin
  if (X >= 0) and (X < FWidth) and (Y >= 0) and (Y < FHeight) then
    FNextStates[X, Y].TerrainType := ATerrain;
end;

procedure TAIGridBuffer.SetNextCost(X, Y: Integer; ACost: Double);
begin
  if (X >= 0) and (X < FWidth) and (Y >= 0) and (Y < FHeight) then
    FNextStates[X, Y].Cost := ACost;
end;

procedure TAIGridBuffer.SetNextEnergy(X, Y: Integer; AEnergy: Double);
begin
  if (X >= 0) and (X < FWidth) and (Y >= 0) and (Y < FHeight) then
    FNextStates[X, Y].Energy := AEnergy;
end;

procedure TAIGridBuffer.CommitCycle;
var
  X, Y: Integer;
  LCell: TAIGridCell;
begin
  if not Assigned(FWorld) then Exit;
  
  for X := 0 to FWidth - 1 do
  begin
    for Y := 0 to FHeight - 1 do
    begin
      LCell := FWorld.Cells[X, Y];
      if Assigned(LCell) then
      begin
        LCell.Blocked := FNextStates[X, Y].Blocked;
        LCell.Cost := FNextStates[X, Y].Cost;
        LCell.Energy := FNextStates[X, Y].Energy;
        LCell.TerrainType := FNextStates[X, Y].TerrainType;
        LCell.Weight := FNextStates[X, Y].Weight;
        LCell.Tag := FNextStates[X, Y].Tag;
      end;
    end;
  end;
end;

procedure TAIGridBuffer.RollbackCycle;
begin
  // Rollback simply means discarding next states, so we copy current states back
  FNextStates := FCurrentStates;
end;

end.
