unit aiproject_documents;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, aiproject, fpjson;

type
  { TAIAgileDocuments — stores and provides access to agile document sections }
  TAIAgileDocuments = class(TComponent)
  private
    FProject: TAIProject;
    FLastError: string;
    function GetBusinessVision: string;
    function GetEpics: string;
    function GetUserStories: string;
    function GetFunctionalRequirements: TJSONArray;
    function GetNonFunctionalRequirements: TJSONArray;
    function GetStakeholders: TJSONArray;
    function GetRiskMap: TJSONArray;
  public
    constructor Create(AOwner: TComponent); override;

    { Syncs UI values back to the project JSON. }
    procedure SaveToProject(const ABusinessVision, AEpics, AUserStories: string);

    { Reads agile documents from project JSON. }
    procedure LoadFromProject;

    { Exports all agile docs as Markdown string. }
    function ExportToMarkdown: string;

    { Read-only access to JSON arrays for grid binding. }
    property FunctionalRequirements: TJSONArray read GetFunctionalRequirements;
    property NonFunctionalRequirements: TJSONArray read GetNonFunctionalRequirements;
    property Stakeholders: TJSONArray read GetStakeholders;
    property RiskMap: TJSONArray read GetRiskMap;

    { Convenience string access. }
    property BusinessVision: string read GetBusinessVision;
    property Epics: string read GetEpics;
    property UserStories: string read GetUserStories;

    property LastError: string read FLastError;
  published
    property Project: TAIProject read FProject write FProject;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('AI Project', [TAIAgileDocuments]);
end;

constructor TAIAgileDocuments.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
end;

function TAIAgileDocuments.GetBusinessVision: string;
var
  N: TJSONData;
begin
  Result := '';
  if not Assigned(FProject) or not Assigned(FProject.ProjectData) then Exit;
  N := FProject.ProjectData.FindPath('agile_documents.business_vision');
  if Assigned(N) then Result := N.AsString;
end;

function TAIAgileDocuments.GetEpics: string;
var
  Arr: TJSONArray;
  i: Integer;
begin
  Result := '';
  if not Assigned(FProject) or not Assigned(FProject.ProjectData) then Exit;
  Arr := TJSONArray(FProject.ProjectData.FindPath('agile_documents.epics'));
  if not Assigned(Arr) then Exit;
  for i := 0 to Arr.Count - 1 do
    Result := Result + Arr.Objects[i].Strings['id'] + ': '
              + Arr.Objects[i].Strings['title'] + LineEnding;
end;

function TAIAgileDocuments.GetUserStories: string;
var
  Arr: TJSONArray;
  i: Integer;
begin
  Result := '';
  if not Assigned(FProject) or not Assigned(FProject.ProjectData) then Exit;
  Arr := TJSONArray(FProject.ProjectData.FindPath('agile_documents.user_stories'));
  if not Assigned(Arr) then Exit;
  for i := 0 to Arr.Count - 1 do
    Result := Result + Arr.Objects[i].Strings['id'] + ': '
              + Arr.Objects[i].Strings['title'] + LineEnding;
end;

function TAIAgileDocuments.GetFunctionalRequirements: TJSONArray;
begin
  Result := nil;
  if not Assigned(FProject) or not Assigned(FProject.ProjectData) then Exit;
  Result := TJSONArray(FProject.ProjectData.FindPath('agile_documents.functional_requirements'));
end;

function TAIAgileDocuments.GetNonFunctionalRequirements: TJSONArray;
begin
  Result := nil;
  if not Assigned(FProject) or not Assigned(FProject.ProjectData) then Exit;
  Result := TJSONArray(FProject.ProjectData.FindPath('agile_documents.non_functional_requirements'));
end;

function TAIAgileDocuments.GetStakeholders: TJSONArray;
begin
  Result := nil;
  if not Assigned(FProject) or not Assigned(FProject.ProjectData) then Exit;
  Result := TJSONArray(FProject.ProjectData.FindPath('agile_documents.stakeholders'));
end;

function TAIAgileDocuments.GetRiskMap: TJSONArray;
begin
  Result := nil;
  if not Assigned(FProject) or not Assigned(FProject.ProjectData) then Exit;
  Result := TJSONArray(FProject.ProjectData.FindPath('agile_documents.risk_map'));
end;

procedure TAIAgileDocuments.SaveToProject(const ABusinessVision, AEpics, AUserStories: string);
var
  AgileDocs: TJSONObject;
begin
  if not Assigned(FProject) or not Assigned(FProject.ProjectData) then Exit;
  AgileDocs := TJSONObject(FProject.ProjectData.FindPath('agile_documents'));
  if not Assigned(AgileDocs) then Exit;
  AgileDocs.Strings['business_vision'] := ABusinessVision;
end;

procedure TAIAgileDocuments.LoadFromProject;
begin
  // Access is direct via properties — nothing to cache
end;

function TAIAgileDocuments.ExportToMarkdown: string;
var
  Arr: TJSONArray;
  Obj: TJSONObject;
  i: Integer;
begin
  Result := '# Agile Documents' + LineEnding + LineEnding;

  Result := Result + '## Business Vision' + LineEnding;
  Result := Result + BusinessVision + LineEnding + LineEnding;

  Result := Result + '## Functional Requirements' + LineEnding;
  Arr := FunctionalRequirements;
  if Assigned(Arr) then
    for i := 0 to Arr.Count - 1 do
    begin
      Obj := Arr.Objects[i];
      Result := Result + '- **' + Obj.Strings['id'] + '** ' + Obj.Strings['title']
                + ' (Priority: ' + Obj.Strings['priority'] + ')' + LineEnding;
    end;

  Result := Result + LineEnding + '## Non-Functional Requirements' + LineEnding;
  Arr := NonFunctionalRequirements;
  if Assigned(Arr) then
    for i := 0 to Arr.Count - 1 do
    begin
      Obj := Arr.Objects[i];
      Result := Result + '- **' + Obj.Strings['id'] + '** ' + Obj.Strings['title']
                + ' (Priority: ' + Obj.Strings['priority'] + ')' + LineEnding;
    end;

  Result := Result + LineEnding + '## Stakeholders' + LineEnding;
  Arr := Stakeholders;
  if Assigned(Arr) then
    for i := 0 to Arr.Count - 1 do
    begin
      Obj := Arr.Objects[i];
      Result := Result + '- **' + Obj.Strings['name'] + '** — '
                + Obj.Strings['role'] + ': ' + Obj.Strings['responsibility'] + LineEnding;
    end;

  Result := Result + LineEnding + '## Risk Map' + LineEnding;
  Arr := RiskMap;
  if Assigned(Arr) then
    for i := 0 to Arr.Count - 1 do
    begin
      Obj := Arr.Objects[i];
      Result := Result + '- **' + Obj.Strings['id'] + '** ' + Obj.Strings['title']
                + ' | Impact: ' + Obj.Strings['impact']
                + ' | Probability: ' + Obj.Strings['probability'] + LineEnding;
    end;

  Result := Result + LineEnding + '## Epics' + LineEnding + Epics;
  Result := Result + LineEnding + '## User Stories' + LineEnding + UserStories;
end;

end.
