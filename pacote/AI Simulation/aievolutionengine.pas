unit aievolutionengine;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, aibase, aisimentity, aientityfactory, fpjson;

type
  { TAIEvolutionEngine }

  TAIEvolutionEngine = class(TAIBaseComponent)
  private
    FMutationRate: Double;
    FSeed: Integer;
    FDeterministic: Boolean;
    FFactory: TAIEntityFactory;
  public
    constructor Create(AOwner: TComponent); override;
    
    procedure ApplyMutation(AEntity: TAISimEntity; const APropertyName: string; MinVal, MaxVal: Double);
    function CreateDerivedEntity(AEntity: TAISimEntity; AOwner: TComponent): TAISimEntity;
  published
    property MutationRate: Double read FMutationRate write FMutationRate;
    property Seed: Integer read FSeed write FSeed default 0;
    property Deterministic: Boolean read FDeterministic write FDeterministic default False;
    property Factory: TAIEntityFactory read FFactory write FFactory;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('AI Simulation', [TAIEvolutionEngine]);
end;

{ TAIEvolutionEngine }

constructor TAIEvolutionEngine.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FCategory := ccSimulation;
  FPrompt := 'Component TAIEvolutionEngine models genetic algorithms, crossover, mutation rates and attribute heredity across simulation generations.';
  FMutationRate := 0.05;
  FSeed := 0;
  FDeterministic := False;
  FFactory := nil;
end;

procedure TAIEvolutionEngine.ApplyMutation(AEntity: TAISimEntity; const APropertyName: string; MinVal, MaxVal: Double);
var
  LVal: Double;
  LChance: Double;
begin
  if not Assigned(AEntity) then Exit;
  
  if FDeterministic then
    RandSeed := FSeed;
    
  LChance := Random;
  if LChance <= FMutationRate then
  begin
    LVal := MinVal + (Random * (MaxVal - MinVal));
    AEntity.SetPropertyDouble(APropertyName, LVal);
  end;
end;

function TAIEvolutionEngine.CreateDerivedEntity(AEntity: TAISimEntity; AOwner: TComponent): TAISimEntity;
begin
  Result := nil;
  if not Assigned(AEntity) then Exit;
  
  // Create a clone of the base entity
  Result := AEntity.Clone(AOwner);
  
  // Set generation or inheritance tags if needed
  if Assigned(Result) then
  begin
    Result.EntityName := 'mutated_' + AEntity.EntityName;
  end;
end;

end.
