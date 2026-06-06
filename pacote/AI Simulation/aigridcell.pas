unit aigridcell;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, aisimentity;

type
  { TAIGridCell }

  TAIGridCell = class
  private
    FEntity: TAISimEntity;
    FBlocked: Boolean;
    FCost: Double;
    FEnergy: Double;
    FTerrainType: string;
    FWeight: Double;
    FTag: Integer;
    FX: Integer;
    FY: Integer;
    FMetadata: TStringList;
    function GetIsEmpty: Boolean;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Clear;
    
    property Entity: TAISimEntity read FEntity write FEntity;
    property Blocked: Boolean read FBlocked write FBlocked;
    property Cost: Double read FCost write FCost;
    property Energy: Double read FEnergy write FEnergy;
    property TerrainType: string read FTerrainType write FTerrainType;
    property Weight: Double read FWeight write FWeight;
    property Tag: Integer read FTag write FTag;
    property X: Integer read FX write FX;
    property Y: Integer read FY write FY;
    property Metadata: TStringList read FMetadata;
    property IsEmpty: Boolean read GetIsEmpty;
  end;

  // Actual definition of TAISimEntity is in aisimentity.pas,
  // which will use this unit.

implementation

constructor TAIGridCell.Create;
begin
  FEntity := nil;
  FBlocked := False;
  FCost := 1.0;
  FEnergy := 0.0;
  FTerrainType := 'default';
  FWeight := 1.0;
  FTag := 0;
  FX := -1;
  FY := -1;
  FMetadata := TStringList.Create;
end;

destructor TAIGridCell.Destroy;
begin
  FMetadata.Free;
  inherited Destroy;
end;

procedure TAIGridCell.Clear;
begin
  FEntity := nil;
  FBlocked := False;
  FCost := 1.0;
  FEnergy := 0.0;
  FTerrainType := 'default';
  FWeight := 1.0;
  FTag := 0;
  FX := -1;
  FY := -1;
  FMetadata.Clear;
end;

function TAIGridCell.GetIsEmpty: Boolean;
begin
  Result := not Assigned(FEntity) and not FBlocked;
end;

end.
