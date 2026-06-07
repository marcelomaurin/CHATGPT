unit aimovementengine;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, aibase, aisimentity, aigridworld, aigridcell, LResources;

type
  TMovementStrategy = (msStop, msRandom, msTarget, msFlee);

  { TAIMovementEngine }

  TAIMovementEngine = class(TAIBaseComponent)
  private
    FGridWorld: TAIGridWorld;
    FStrategy: TMovementStrategy;
    FTargetType: string;
    FThreatType: string;
    FMoveLimitPerCycle: Integer;
    
    function GetDistance(X1, Y1, X2, Y2: Integer): Double;
  public
    constructor Create(AOwner: TComponent); override;
    
    function MoveRandomly(AEntity: TAISimEntity): Boolean;
    function MoveTowardsTarget(AEntity: TAISimEntity; const ATargetType: string): Boolean;
    function FleeFromThreat(AEntity: TAISimEntity; const AThreatType: string): Boolean;
    
    function StepEntityMovement(AEntity: TAISimEntity): Boolean;
  published
    property GridWorld: TAIGridWorld read FGridWorld write FGridWorld;
    property Strategy: TMovementStrategy read FStrategy write FStrategy default msRandom;
    property TargetType: string read FTargetType write FTargetType;
    property ThreatType: string read FThreatType write FThreatType;
    property MoveLimitPerCycle: Integer read FMoveLimitPerCycle write FMoveLimitPerCycle default 1;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('AI Simulation', [TAIMovementEngine]);
end;

{ TAIMovementEngine }

constructor TAIMovementEngine.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FCategory := ccSimulation;
  FPrompt := 'Component TAIMovementEngine provides movement algorithms like Random, Target seeking, and Threat fleeing on a TAIGridWorld.';
  FStrategy := msRandom;
  FTargetType := '';
  FThreatType := '';
  FMoveLimitPerCycle := 1;
  FGridWorld := nil;
end;

function TAIMovementEngine.GetDistance(X1, Y1, X2, Y2: Integer): Double;
begin
  Result := Sqrt(Sqr(X2 - X1) + Sqr(Y2 - Y1));
end;

function TAIMovementEngine.MoveRandomly(AEntity: TAISimEntity): Boolean;
var
  LFreeList: TList;
  LCell: TAIGridCell;
  LIdx: Integer;
begin
  Result := False;
  if not Assigned(FGridWorld) or not Assigned(AEntity) then Exit;
  
  LFreeList := TList.Create;
  try
    FGridWorld.GetFreePositions(AEntity.X, AEntity.Y, 1, LFreeList);
    if LFreeList.Count > 0 then
    begin
      // Pick a random free position
      LIdx := Random(LFreeList.Count);
      LCell := TAIGridCell(LFreeList[LIdx]);
      Result := FGridWorld.MoveEntity(AEntity, LCell.X, LCell.Y);
    end;
  finally
    LFreeList.Free;
  end;
end;

function TAIMovementEngine.MoveTowardsTarget(AEntity: TAISimEntity; const ATargetType: string): Boolean;
var
  i: Integer;
  LTargets: TList;
  LBestTarget: TAISimEntity;
  LMinDist, LDist: Double;
  LTarget: TAISimEntity;
  LNeighbors: TList;
  LBestCell: TAIGridCell;
  LCell: TAIGridCell;
begin
  Result := False;
  if not Assigned(FGridWorld) or not Assigned(AEntity) or (ATargetType = '') then Exit;
  
  LTargets := TList.Create;
  try
    FGridWorld.FindEntitiesByType(ATargetType, LTargets);
    if LTargets.Count = 0 then Exit;
    
    // Find closest target
    LBestTarget := nil;
    LMinDist := 999999.0;
    
    for i := 0 to LTargets.Count - 1 do
    begin
      LTarget := TAISimEntity(LTargets[i]);
      LDist := GetDistance(AEntity.X, AEntity.Y, LTarget.X, LTarget.Y);
      if LDist < LMinDist then
      begin
        LMinDist := LDist;
        LBestTarget := LTarget;
      end;
    end;
    
    if Assigned(LBestTarget) then
    begin
      // Find neighboring cell that gets us closest to the target
      LNeighbors := TList.Create;
      try
        FGridWorld.GetFreePositions(AEntity.X, AEntity.Y, 1, LNeighbors);
        
        // Also check if we can move into the target's cell if they overlap or if that's the goal
        // (usually we can't move into an occupied cell, but we look for the closest free cell next to it)
        LBestCell := nil;
        LMinDist := GetDistance(AEntity.X, AEntity.Y, LBestTarget.X, LBestTarget.Y);
        
        for i := 0 to LNeighbors.Count - 1 do
        begin
          LCell := TAIGridCell(LNeighbors[i]);
          LDist := GetDistance(LCell.X, LCell.Y, LBestTarget.X, LBestTarget.Y);
          if LDist < LMinDist then
          begin
            LMinDist := LDist;
            LBestCell := LCell;
          end;
        end;
        
        if Assigned(LBestCell) then
        begin
          Result := FGridWorld.MoveEntity(AEntity, LBestCell.X, LBestCell.Y);
        end;
      finally
        LNeighbors.Free;
      end;
    end;
  finally
    LTargets.Free;
  end;
end;

function TAIMovementEngine.FleeFromThreat(AEntity: TAISimEntity; const AThreatType: string): Boolean;
var
  i: Integer;
  LThreats: TList;
  LBestThreat: TAISimEntity;
  LMinDist, LDist: Double;
  LThreat: TAISimEntity;
  LNeighbors: TList;
  LBestCell: TAIGridCell;
  LCell: TAIGridCell;
  LMaxDist: Double;
begin
  Result := False;
  if not Assigned(FGridWorld) or not Assigned(AEntity) or (AThreatType = '') then Exit;
  
  LThreats := TList.Create;
  try
    FGridWorld.FindEntitiesByType(AThreatType, LThreats);
    if LThreats.Count = 0 then Exit;
    
    // Find closest threat
    LBestThreat := nil;
    LMinDist := 999999.0;
    
    for i := 0 to LThreats.Count - 1 do
    begin
      LThreat := TAISimEntity(LThreats[i]);
      LDist := GetDistance(AEntity.X, AEntity.Y, LThreat.X, LThreat.Y);
      if LDist < LMinDist then
      begin
        LMinDist := LDist;
        LBestThreat := LThreat;
      end;
    end;
    
    if Assigned(LBestThreat) then
    begin
      // Move to neighboring cell that maximizes the distance to the threat
      LNeighbors := TList.Create;
      try
        FGridWorld.GetFreePositions(AEntity.X, AEntity.Y, 1, LNeighbors);
        
        LBestCell := nil;
        LMaxDist := GetDistance(AEntity.X, AEntity.Y, LBestThreat.X, LBestThreat.Y);
        
        for i := 0 to LNeighbors.Count - 1 do
        begin
          LCell := TAIGridCell(LNeighbors[i]);
          LDist := GetDistance(LCell.X, LCell.Y, LBestThreat.X, LBestThreat.Y);
          if LDist > LMaxDist then
          begin
            LMaxDist := LDist;
            LBestCell := LCell;
          end;
        end;
        
        if Assigned(LBestCell) then
        begin
          Result := FGridWorld.MoveEntity(AEntity, LBestCell.X, LBestCell.Y);
        end;
      finally
        LNeighbors.Free;
      end;
    end;
  finally
    LThreats.Free;
  end;
end;

function TAIMovementEngine.StepEntityMovement(AEntity: TAISimEntity): Boolean;
begin
  Result := False;
  case FStrategy of
    msStop: Result := True;
    msRandom: Result := MoveRandomly(AEntity);
    msTarget: Result := MoveTowardsTarget(AEntity, FTargetType);
    msFlee: Result := FleeFromThreat(AEntity, FThreatType);
  end;
end;

initialization
  {$I aimovementengine_icon.lrs}

end.
