unit airuleengine;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, aibase, aisimentity, aigridworld, LResources;

type
  TRuleConditionEvent = function(Sender: TObject; AEntity: TAISimEntity; AWorld: TAIGridWorld): Boolean of object;
  TRuleActionEvent = procedure(Sender: TObject; AEntity: TAISimEntity; AWorld: TAIGridWorld) of object;

  { TAISimulationRule }

  TAISimulationRule = class(TCollectionItem)
  private
    FRuleName: string;
    FPriority: Integer;
    FActive: Boolean;
    FOnCondition: TRuleConditionEvent;
    FOnAction: TRuleActionEvent;
  published
    property RuleName: string read FRuleName write FRuleName;
    property Priority: Integer read FPriority write FPriority default 10;
    property Active: Boolean read FActive write FActive default True;
    // Callbacks assigned dynamically
    property OnCondition: TRuleConditionEvent read FOnCondition write FOnCondition;
    property OnAction: TRuleActionEvent read FOnAction write FOnAction;
  end;

  { TAISimulationRuleCollection }

  TAISimulationRuleCollection = class(TOwnedCollection)
  private
    function GetItem(Index: Integer): TAISimulationRule;
    procedure SetItem(Index: Integer; AValue: TAISimulationRule);
  public
    constructor Create(AOwner: TPersistent);
    function Add: TAISimulationRule;
    procedure SortByPriority;
    property Items[Index: Integer]: TAISimulationRule read GetItem write SetItem; default;
  end;

  { TAIRuleEngine }

  TAIRuleEngine = class(TAIBaseComponent)
  private
    FRules: TAISimulationRuleCollection;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    
    procedure RegisterRule(const AName: string; APriority: Integer; ACondition: TRuleConditionEvent; AAction: TRuleActionEvent);
    procedure ClearRules;
    
    function EvaluateAndExecute(AEntity: TAISimEntity; AWorld: TAIGridWorld): Boolean;
    procedure EvaluateWorldRules(AWorld: TAIGridWorld);
  published
    property Rules: TAISimulationRuleCollection read FRules write FRules;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('AI Simulation', [TAIRuleEngine]);
end;

{ TAISimulationRuleCollection }

constructor TAISimulationRuleCollection.Create(AOwner: TPersistent);
begin
  inherited Create(AOwner, TAISimulationRule);
end;

function TAISimulationRuleCollection.GetItem(Index: Integer): TAISimulationRule;
begin
  Result := TAISimulationRule(inherited GetItem(Index));
end;

procedure TAISimulationRuleCollection.SetItem(Index: Integer; AValue: TAISimulationRule);
begin
  inherited SetItem(Index, AValue);
end;

function TAISimulationRuleCollection.Add: TAISimulationRule;
begin
  Result := TAISimulationRule(inherited Add);
end;

procedure TAISimulationRuleCollection.SortByPriority;
var
  i, j: Integer;
  Temp: TCollectionItem;
begin
  // Standard bubble sort on Priority descending (highest priority executes first)
  for i := 0 to Count - 2 do
  begin
    for j := i + 1 to Count - 1 do
    begin
      if Items[j].Priority > Items[i].Priority then
      begin
        // Swap indexes
        // TOwnedCollection / TCollection allows index assignment
        Items[j].Index := i;
      end;
    end;
  end;
end;

{ TAIRuleEngine }

constructor TAIRuleEngine.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FCategory := ccSimulation;
  FPrompt := 'Component TAIRuleEngine manages condition-action rules for entities and globals in the simulation environment.';
  FRules := TAISimulationRuleCollection.Create(Self);
end;

destructor TAIRuleEngine.Destroy;
begin
  FRules.Free;
  inherited Destroy;
end;

procedure TAIRuleEngine.RegisterRule(const AName: string; APriority: Integer; ACondition: TRuleConditionEvent; AAction: TRuleActionEvent);
var
  LRule: TAISimulationRule;
begin
  LRule := FRules.Add;
  LRule.RuleName := AName;
  LRule.Priority := APriority;
  LRule.OnCondition := ACondition;
  LRule.OnAction := AAction;
  LRule.Active := True;
end;

procedure TAIRuleEngine.ClearRules;
begin
  FRules.Clear;
end;

function TAIRuleEngine.EvaluateAndExecute(AEntity: TAISimEntity; AWorld: TAIGridWorld): Boolean;
var
  i: Integer;
  LRule: TAISimulationRule;
begin
  Result := False;
  if FRules.Count = 0 then Exit;
  
  FRules.SortByPriority;
  
  for i := 0 to FRules.Count - 1 do
  begin
    LRule := FRules.Items[i];
    if LRule.Active and Assigned(LRule.OnCondition) and Assigned(LRule.OnAction) then
    begin
      if LRule.OnCondition(Self, AEntity, AWorld) then
      begin
        LRule.OnAction(Self, AEntity, AWorld);
        Result := True;
        // Return True on the first matching rule (or we can execute all matching rules depending on design)
        // Usually, in prioritised rules, we stop at the first successful match or execute all.
        // Let's execute the first match for normal rule processing, or let developer override.
        Break;
      end;
    end;
  end;
end;

procedure TAIRuleEngine.EvaluateWorldRules(AWorld: TAIGridWorld);
var
  i: Integer;
  LEntity: TAISimEntity;
  LTempList: TList;
begin
  if not Assigned(AWorld) then Exit;
  
  LTempList := TList.Create;
  try
    // Copy references to a temporary list to avoid modification-during-iteration errors
    for i := 0 to AWorld.Entities.Count - 1 do
      LTempList.Add(AWorld.Entities[i]);
      
    // Evaluate rules for each active entity in the world
    for i := 0 to LTempList.Count - 1 do
    begin
      LEntity := TAISimEntity(LTempList[i]);
      // Verify entity still exists in the world and is active
      if (AWorld.Entities.IndexOf(LEntity) >= 0) and LEntity.Active then
      begin
        EvaluateAndExecute(LEntity, AWorld);
      end;
    end;
  finally
    LTempList.Free;
  end;
end;

initialization
  {$I airuleengine_icon.lrs}

end.
