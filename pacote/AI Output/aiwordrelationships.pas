unit aiwordrelationships;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, DOM, aiwordxml;

type
  TAIWordRelationshipItem = record
    Id: string;
    RelType: string;
    Target: string;
  end;

  { TAIWordRelationships }

  TAIWordRelationships = class
  private
    FItems: array of TAIWordRelationshipItem;
    FFileName: string;
    FNextIdVal: Integer;
    function GetCount: Integer;
    function GetItem(AIndex: Integer): TAIWordRelationshipItem;
  public
    constructor Create;
    destructor Destroy; override;

    function LoadFromFile(const AFileName: string): Boolean;
    function SaveToFile(const AFileName: string = ''): Boolean;

    function AddRelationship(const ARelType, ATarget: string): string;
    function FindRelationshipId(const ATarget: string): string;
    function FindTargetById(const AId: string): string;
    procedure Clear;

    property Count: Integer read GetCount;
    property Items[Index: Integer]: TAIWordRelationshipItem read GetItem;
  end;

implementation

constructor TAIWordRelationships.Create;
begin
  FFileName := '';
  FNextIdVal := 1;
  SetLength(FItems, 0);
end;

destructor TAIWordRelationships.Destroy;
begin
  SetLength(FItems, 0);
  inherited Destroy;
end;

function TAIWordRelationships.GetCount: Integer;
begin
  Result := Length(FItems);
end;

function TAIWordRelationships.GetItem(AIndex: Integer): TAIWordRelationshipItem;
begin
  Result := FItems[AIndex];
end;

procedure TAIWordRelationships.Clear;
begin
  SetLength(FItems, 0);
  FNextIdVal := 1;
end;

function TAIWordRelationships.LoadFromFile(const AFileName: string): Boolean;
var
  Doc: TXMLDocument;
  RNode, Child: TDOMNode;
  Item: TAIWordRelationshipItem;
  IdNum: Integer;
  IdStr: string;
begin
  Clear;
  FFileName := AFileName;
  if not FileExists(AFileName) then
    Exit(True); // Empty or new relationships file

  try
    Doc := LoadXML(AFileName);
    if not Assigned(Doc) then
      Exit(False);
      
    RNode := FindChildNode(Doc, 'Relationships');
    if Assigned(RNode) then
    begin
      Child := RNode.FirstChild;
      while Assigned(Child) do
      begin
        if Child.NodeName = 'Relationship' then
        begin
          Item.Id := GetNodeAttribute(Child, 'Id');
          Item.RelType := GetNodeAttribute(Child, 'Type');
          Item.Target := GetNodeAttribute(Child, 'Target');
          
          SetLength(FItems, Length(FItems) + 1);
          FItems[High(FItems)] := Item;
          
          // Track maximum Id number
          if (Length(Item.Id) > 3) and (Copy(Item.Id, 1, 3) = 'rId') then
          begin
            IdStr := Copy(Item.Id, 4, Length(Item.Id) - 3);
            if TryStrToInt(IdStr, IdNum) then
            begin
              if IdNum >= FNextIdVal then
                FNextIdVal := IdNum + 1;
            end;
          end;
        end;
        Child := Child.NextSibling;
      end;
    end;
    Doc.Free;
    Result := True;
  except
    Result := False;
  end;
end;

function TAIWordRelationships.SaveToFile(const AFileName: string): Boolean;
var
  Doc: TXMLDocument;
  RNode, NewNode: TDOMNode;
  I: Integer;
  SavePath: string;
begin
  if AFileName <> '' then
    SavePath := AFileName
  else
    SavePath := FFileName;
    
  if SavePath = '' then
    Exit(False);
    
  try
    Doc := TXMLDocument.Create;
    RNode := Doc.CreateElement('Relationships');
    SetNodeAttribute(RNode, 'xmlns', 'http://schemas.openxmlformats.org/package/2006/relationships');
    Doc.AppendChild(RNode);
    
    for I := 0 to High(FItems) do
    begin
      NewNode := Doc.CreateElement('Relationship');
      SetNodeAttribute(NewNode, 'Id', FItems[I].Id);
      SetNodeAttribute(NewNode, 'Type', FItems[I].RelType);
      SetNodeAttribute(NewNode, 'Target', FItems[I].Target);
      RNode.AppendChild(NewNode);
    end;
    
    SaveXML(Doc, SavePath);
    Doc.Free;
    Result := True;
  except
    Result := False;
  end;
end;

function TAIWordRelationships.AddRelationship(const ARelType, ATarget: string): string;
var
  Item: TAIWordRelationshipItem;
begin
  // Check if relationship already exists
  Result := FindRelationshipId(ATarget);
  if Result <> '' then
    Exit;
    
  Item.Id := 'rId' + IntToStr(FNextIdVal);
  Inc(FNextIdVal);
  Item.RelType := ARelType;
  Item.Target := ATarget;
  
  SetLength(FItems, Length(FItems) + 1);
  FItems[High(FItems)] := Item;
  
  Result := Item.Id;
end;

function TAIWordRelationships.FindRelationshipId(const ATarget: string): string;
var
  I: Integer;
begin
  Result := '';
  for I := 0 to High(FItems) do
  begin
    if FItems[I].Target = ATarget then
    begin
      Result := FItems[I].Id;
      Exit;
    end;
  end;
end;

function TAIWordRelationships.FindTargetById(const AId: string): string;
var
  I: Integer;
begin
  Result := '';
  for I := 0 to High(FItems) do
  begin
    if FItems[I].Id = AId then
    begin
      Result := FItems[I].Target;
      Exit;
    end;
  end;
end;

end.
