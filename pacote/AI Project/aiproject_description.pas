unit aiproject_description;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, aiproject, fpjson;

type
  { TAIProjectDescription — manages the project high-level description data }
  TAIProjectDescription = class(TComponent)
  private
    FProject: TAIProject;
    FLastError: string;
  public
    constructor Create(AOwner: TComponent); override;

    { Syncs UI values back to the project JSON. }
    procedure SaveToProject(const AName, AGoal, AContext, AScope, AConstraints, ADeliverables: string; AStart, ATargetEnd: TDateTime);

    { Reads values from project JSON. }
    procedure LoadFromProject(var AName, AGoal, AContext, AScope, AConstraints, ADeliverables: string; var AStart, ATargetEnd: TDateTime);

    property LastError: string read FLastError;
  published
    property Project: TAIProject read FProject write FProject;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('AI Project', [TAIProjectDescription]);
end;

constructor TAIProjectDescription.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
end;

procedure TAIProjectDescription.SaveToProject(const AName, AGoal, AContext, AScope, AConstraints, ADeliverables: string; AStart, ATargetEnd: TDateTime);
var
  ProjObj: TJSONObject;
begin
  if not Assigned(FProject) or not Assigned(FProject.ProjectData) then Exit;
  ProjObj := TJSONObject(FProject.ProjectData.FindPath('project'));
  if not Assigned(ProjObj) then Exit;
  
  ProjObj.Strings['name'] := AName;
  ProjObj.Strings['goal'] := AGoal;
  ProjObj.Strings['context'] := AContext;
  ProjObj.Strings['scope'] := AScope;
  ProjObj.Strings['constraints'] := AConstraints;
  ProjObj.Strings['expected_deliverables'] := ADeliverables;
  
  FProject.ProjectName := AName;
  FProject.Goal := AGoal;
  FProject.Context := AContext;
  FProject.Scope := AScope;
  FProject.Constraints := AConstraints;
  FProject.ExpectedDeliverables := ADeliverables;
  FProject.StartDate := AStart;
  FProject.TargetEndDate := ATargetEnd;
end;

procedure TAIProjectDescription.LoadFromProject(var AName, AGoal, AContext, AScope, AConstraints, ADeliverables: string; var AStart, ATargetEnd: TDateTime);
var
  ProjObj: TJSONObject;
begin
  if not Assigned(FProject) or not Assigned(FProject.ProjectData) then Exit;
  ProjObj := TJSONObject(FProject.ProjectData.FindPath('project'));
  if not Assigned(ProjObj) then Exit;
  
  AName := ProjObj.Strings['name'];
  AGoal := ProjObj.Strings['goal'];
  AContext := ProjObj.Strings['context'];
  AScope := ProjObj.Strings['scope'];
  AConstraints := ProjObj.Strings['constraints'];
  ADeliverables := ProjObj.Strings['expected_deliverables'];
  
  AStart := FProject.StartDate;
  ATargetEnd := FProject.TargetEndDate;
end;

end.
