unit aientityfactory;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, aibase, aisimentity, fpjson, jsonparser, LResources;

type
  { TEntityRegistryItem }
  TEntityRegistryItem = class(TCollectionItem)
  private
    FTypeName: string;
    FDefaultName: string;
    FPropertiesJSON: string;
  published
    property TypeName: string read FTypeName write FTypeName;
    property DefaultName: string read FDefaultName write FDefaultName;
    property PropertiesJSON: string read FPropertiesJSON write FPropertiesJSON;
  end;

  { TEntityRegistryCollection }
  TEntityRegistryCollection = class(TOwnedCollection)
  private
    function GetItem(Index: Integer): TEntityRegistryItem;
    procedure SetItem(Index: Integer; AValue: TEntityRegistryItem);
  public
    constructor Create(AOwner: TPersistent);
    function Add: TEntityRegistryItem;
    property Items[Index: Integer]: TEntityRegistryItem read GetItem write SetItem; default;
  end;

  { TAIEntityFactory }

  TAIEntityFactory = class(TAIBaseComponent)
  private
    FRegistry: TEntityRegistryCollection;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    
    procedure RegisterType(const ATypeName, ADefaultName, APropertiesJSON: string);
    function CreateEntity(const ATypeName: string; AOwner: TComponent): TAISimEntity;
    procedure CreateBatch(const ATypeName: string; ACount: Integer; AOwner: TComponent; AOutList: TList);
  published
    property Registry: TEntityRegistryCollection read FRegistry write FRegistry;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('AI Simulation', [TAIEntityFactory]);
end;

{ TEntityRegistryCollection }

constructor TEntityRegistryCollection.Create(AOwner: TPersistent);
begin
  inherited Create(AOwner, TEntityRegistryItem);
end;

function TEntityRegistryCollection.Add: TEntityRegistryItem;
begin
  Result := TEntityRegistryItem(inherited Add);
end;

function TEntityRegistryCollection.GetItem(Index: Integer): TEntityRegistryItem;
begin
  Result := TEntityRegistryItem(inherited GetItem(Index));
end;

procedure TEntityRegistryCollection.SetItem(Index: Integer; AValue: TEntityRegistryItem);
begin
  inherited SetItem(Index, AValue);
end;

{ TAIEntityFactory }

constructor TAIEntityFactory.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FCategory := ccSimulation;
  FPrompt := 'Component TAIEntityFactory registers and instantiates entities dynamically based on registered type definitions.';
  FRegistry := TEntityRegistryCollection.Create(Self);
end;

destructor TAIEntityFactory.Destroy;
begin
  FRegistry.Free;
  inherited Destroy;
end;

procedure TAIEntityFactory.RegisterType(const ATypeName, ADefaultName, APropertiesJSON: string);
var
  LItem: TEntityRegistryItem;
  i: Integer;
begin
  LItem := nil;
  for i := 0 to FRegistry.Count - 1 do
  begin
    if SameText(FRegistry[i].TypeName, ATypeName) then
    begin
      LItem := FRegistry[i];
      Break;
    end;
  end;
  
  if not Assigned(LItem) then
    LItem := FRegistry.Add;
    
  LItem.TypeName := ATypeName;
  LItem.DefaultName := ADefaultName;
  LItem.PropertiesJSON := APropertiesJSON;
end;

function TAIEntityFactory.CreateEntity(const ATypeName: string; AOwner: TComponent): TAISimEntity;
var
  i, j: Integer;
  LItem: TEntityRegistryItem;
  LData: string;
  LJSON: TJSONData;
  LObj: TJSONObject;
begin
  Result := nil;
  LItem := nil;
  for i := 0 to FRegistry.Count - 1 do
  begin
    if SameText(FRegistry[i].TypeName, ATypeName) then
    begin
      LItem := FRegistry[i];
      Break;
    end;
  end;
  
  Result := TAISimEntity.Create(AOwner);
  if Assigned(LItem) then
  begin
    Result.EntityType := LItem.TypeName;
    Result.EntityName := LItem.DefaultName;
    if LItem.PropertiesJSON <> '' then
    begin
      try
        LData := LItem.PropertiesJSON;
        LJSON := GetJSON(LData);
        if Assigned(LJSON) and (LJSON is TJSONObject) then
        begin
          LObj := TJSONObject(LJSON);
          for j := 0 to LObj.Count - 1 do
          begin
            Result.Properties.Add(LObj.Names[j], LObj.Items[j].Clone);
          end;
          LJSON.Free;
        end;
      except
        // Ignore JSON parsing errors for default values
      end;
    end;
  end
  else
  begin
    Result.EntityType := ATypeName;
    Result.EntityName := ATypeName + '_' + Result.Id;
  end;
end;

procedure TAIEntityFactory.CreateBatch(const ATypeName: string; ACount: Integer; AOwner: TComponent; AOutList: TList);
var
  i: Integer;
begin
  if not Assigned(AOutList) then Exit;
  for i := 1 to ACount do
  begin
    AOutList.Add(CreateEntity(ATypeName, AOwner));
  end;
end;

initialization
  {$I aientityfactory_icon.lrs}

end.
