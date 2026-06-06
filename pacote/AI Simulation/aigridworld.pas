unit aigridworld;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, aibase, aisimentity, aigridcell;

type
  TNeighborhoodMode = (nmMoore, nmVonNeumann);
  TBoundaryMode = (bmBlock, bmWrap);

  { TAIGridWorld }

  TAIGridWorld = class(TAIBaseComponent)
  private
    FWidth: Integer;
    FHeight: Integer;
    FNeighborhoodMode: TNeighborhoodMode;
    FBoundaryMode: TBoundaryMode;
    FCells: array of array of TAIGridCell;
    FEntities: TList;
    
    procedure CleanCells;
    function GetCell(X, Y: Integer): TAIGridCell;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    
    procedure SetupWorld(AWidth, AHeight: Integer);
    procedure ClearWorld;
    
    function IsInBounds(X, Y: Integer): Boolean;
    function IsFree(X, Y: Integer): Boolean;
    
    function AddEntity(AEntity: TAISimEntity; X, Y: Integer): Boolean;
    function RemoveEntity(AEntity: TAISimEntity): Boolean;
    function MoveEntity(AEntity: TAISimEntity; NewX, NewY: Integer): Boolean;
    
    procedure GetNeighbors(X, Y: Integer; ARadius: Integer; AOutList: TList);
    procedure GetFreePositions(X, Y: Integer; ARadius: Integer; AOutList: TList);
    
    function CountEntitiesByType(const AType: string): Integer;
    procedure FindEntitiesByType(const AType: string; AOutList: TList);
    
    property Cells[X, Y: Integer]: TAIGridCell read GetCell;
    property Entities: TList read FEntities;
  published
    property Width: Integer read FWidth write FWidth default 10;
    property Height: Integer read FHeight write FHeight default 10;
    property NeighborhoodMode: TNeighborhoodMode read FNeighborhoodMode write FNeighborhoodMode default nmMoore;
    property BoundaryMode: TBoundaryMode read FBoundaryMode write FBoundaryMode default bmBlock;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('AI Simulation', [TAIGridWorld]);
end;

{ TAIGridWorld }

constructor TAIGridWorld.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FCategory := ccSimulation;
  FPrompt := 'Component TAIGridWorld manages a 2D cellular grid with configurable boundary modes (bmBlock, bmWrap) and neighborhood modes (nmMoore, nmVonNeumann).';
  FWidth := 10;
  FHeight := 10;
  FNeighborhoodMode := nmMoore;
  FBoundaryMode := bmBlock;
  FEntities := TList.Create;
  SetupWorld(FWidth, FHeight);
end;

destructor TAIGridWorld.Destroy;
begin
  ClearWorld;
  CleanCells;
  FEntities.Free;
  inherited Destroy;
end;

procedure TAIGridWorld.CleanCells;
var
  X, Y: Integer;
begin
  for X := 0 to Length(FCells) - 1 do
  begin
    for Y := 0 to Length(FCells[X]) - 1 do
    begin
      if Assigned(FCells[X, Y]) then
        FCells[X, Y].Free;
    end;
  end;
  FCells := nil;
end;

procedure TAIGridWorld.SetupWorld(AWidth, AHeight: Integer);
var
  X, Y: Integer;
begin
  ClearWorld;
  CleanCells;
  
  FWidth := AWidth;
  FHeight := AHeight;
  
  SetLength(FCells, FWidth);
  for X := 0 to FWidth - 1 do
  begin
    SetLength(FCells[X], FHeight);
    for Y := 0 to FHeight - 1 do
    begin
      FCells[X, Y] := TAIGridCell.Create;
      FCells[X, Y].X := X;
      FCells[X, Y].Y := Y;
      FCells[X, Y].Tag := X + (Y * FWidth);
    end;
  end;
end;

procedure TAIGridWorld.ClearWorld;
var
  X, Y: Integer;
begin
  for X := 0 to Length(FCells) - 1 do
  begin
    for Y := 0 to Length(FCells[X]) - 1 do
    begin
      if Assigned(FCells[X, Y]) then
        FCells[X, Y].Clear;
    end;
  end;
  if Assigned(FEntities) then
    FEntities.Clear;
end;

function TAIGridWorld.GetCell(X, Y: Integer): TAIGridCell;
begin
  Result := nil;
  if IsInBounds(X, Y) then
    Result := FCells[X, Y];
end;

function TAIGridWorld.IsInBounds(X, Y: Integer): Boolean;
begin
  Result := (X >= 0) and (X < FWidth) and (Y >= 0) and (Y < FHeight);
end;

function TAIGridWorld.IsFree(X, Y: Integer): Boolean;
begin
  Result := IsInBounds(X, Y) and FCells[X, Y].IsEmpty;
end;

function TAIGridWorld.AddEntity(AEntity: TAISimEntity; X, Y: Integer): Boolean;
begin
  Result := False;
  if not Assigned(AEntity) then Exit;
  if not IsInBounds(X, Y) then Exit;
  
  if IsFree(X, Y) then
  begin
    FCells[X, Y].Entity := AEntity;
    AEntity.X := X;
    AEntity.Y := Y;
    if FEntities.IndexOf(AEntity) < 0 then
      FEntities.Add(AEntity);
    Result := True;
  end;
end;

function TAIGridWorld.RemoveEntity(AEntity: TAISimEntity): Boolean;
var
  Idx: Integer;
begin
  Result := False;
  if not Assigned(AEntity) then Exit;
  
  Idx := FEntities.IndexOf(AEntity);
  if Idx >= 0 then
  begin
    FEntities.Delete(Idx);
    if IsInBounds(AEntity.X, AEntity.Y) then
    begin
      if FCells[AEntity.X, AEntity.Y].Entity = AEntity then
        FCells[AEntity.X, AEntity.Y].Entity := nil;
    end;
    AEntity.X := -1;
    AEntity.Y := -1;
    Result := True;
  end;
end;

function TAIGridWorld.MoveEntity(AEntity: TAISimEntity; NewX, NewY: Integer): Boolean;
var
  OldX, OldY: Integer;
begin
  Result := False;
  if not Assigned(AEntity) then Exit;
  
  if FBoundaryMode = bmWrap then
  begin
    NewX := (NewX mod FWidth + FWidth) mod FWidth;
    NewY := (NewY mod FHeight + FHeight) mod FHeight;
  end;
  
  if not IsInBounds(NewX, NewY) then Exit;
  
  if IsFree(NewX, NewY) then
  begin
    OldX := AEntity.X;
    OldY := AEntity.Y;
    
    if IsInBounds(OldX, OldY) and (FCells[OldX, OldY].Entity = AEntity) then
      FCells[OldX, OldY].Entity := nil;
      
    FCells[NewX, NewY].Entity := AEntity;
    AEntity.X := NewX;
    AEntity.Y := NewY;
    Result := True;
  end;
end;

procedure TAIGridWorld.GetNeighbors(X, Y: Integer; ARadius: Integer; AOutList: TList);
var
  dx, dy, nx, ny: Integer;
begin
  if not Assigned(AOutList) then Exit;
  AOutList.Clear;
  
  for dx := -ARadius to ARadius do
  begin
    for dy := -ARadius to ARadius do
    begin
      if (dx = 0) and (dy = 0) then Continue;
      
      // Filter by neighborhood mode
      if FNeighborhoodMode = nmVonNeumann then
      begin
        if Abs(dx) + Abs(dy) > ARadius then Continue;
      end;
      
      nx := X + dx;
      ny := Y + dy;
      
      if FBoundaryMode = bmWrap then
      begin
        nx := (nx mod FWidth + FWidth) mod FWidth;
        ny := (ny mod FHeight + FHeight) mod FHeight;
      end;
      
      if IsInBounds(nx, ny) then
      begin
        if AOutList.IndexOf(FCells[nx, ny]) < 0 then
          AOutList.Add(FCells[nx, ny]);
      end;
    end;
  end;
end;

procedure TAIGridWorld.GetFreePositions(X, Y: Integer; ARadius: Integer; AOutList: TList);
var
  LNeighbors: TList;
  i: Integer;
  LCell: TAIGridCell;
begin
  if not Assigned(AOutList) then Exit;
  AOutList.Clear;
  
  LNeighbors := TList.Create;
  try
    GetNeighbors(X, Y, ARadius, LNeighbors);
    for i := 0 to LNeighbors.Count - 1 do
    begin
      LCell := TAIGridCell(LNeighbors[i]);
      if LCell.IsEmpty then
        AOutList.Add(LCell);
    end;
  finally
    LNeighbors.Free;
  end;
end;

function TAIGridWorld.CountEntitiesByType(const AType: string): Integer;
var
  i: Integer;
  LEntity: TAISimEntity;
begin
  Result := 0;
  for i := 0 to FEntities.Count - 1 do
  begin
    LEntity := TAISimEntity(FEntities[i]);
    if SameText(LEntity.EntityType, AType) then
      Inc(Result);
  end;
end;

procedure TAIGridWorld.FindEntitiesByType(const AType: string; AOutList: TList);
var
  i: Integer;
  LEntity: TAISimEntity;
begin
  if not Assigned(AOutList) then Exit;
  AOutList.Clear;
  for i := 0 to FEntities.Count - 1 do
  begin
    LEntity := TAISimEntity(FEntities[i]);
    if SameText(LEntity.EntityType, AType) then
      AOutList.Add(LEntity);
  end;
end;

end.
