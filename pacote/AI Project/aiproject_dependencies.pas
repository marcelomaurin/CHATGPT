unit aiproject_dependencies;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, aiproject, fpjson, LResources;

type
  { TAIProjectDependencies — access to serial/parallel dependency data }
  TAIProjectDependencies = class(TComponent)
  private
    FProject: TAIProject;
  public
    constructor Create(AOwner: TComponent); override;

    { Returns list of serial dependency IDs for a given task. }
    function GetSerialDependencies(const ATaskID: string): TStringList;

    { Returns textual explanation of all dependencies in the project. }
    function ExplainDependencies: string;

    { Raw access to serial dependency pairs as [predecessor -> successor] lines }
    function GetSerialPairs: TStringList;

    { Returns list of parallel group descriptions }
    function GetParallelGroups: TStringList;
  published
    property Project: TAIProject read FProject write FProject;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('AI Project', [TAIProjectDependencies]);
end;

constructor TAIProjectDependencies.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
end;

function TAIProjectDependencies.GetSerialDependencies(const ATaskID: string): TStringList;
var
  Tasks: TJSONArray;
  Task, DepObj: TJSONObject;
  Deps: TJSONArray;
  i, j: Integer;
begin
  Result := TStringList.Create;
  if not Assigned(FProject) or not Assigned(FProject.ProjectData) then Exit;
  Tasks := TJSONArray(FProject.ProjectData.FindPath('planning.tasks'));
  if not Assigned(Tasks) then Exit;
  for i := 0 to Tasks.Count - 1 do
  begin
    Task := Tasks.Objects[i];
    if Task.Strings['id'] = ATaskID then
    begin
      Deps := TJSONArray(Task.FindPath('dependencies'));
      if Assigned(Deps) then
        for j := 0 to Deps.Count - 1 do
        begin
          if Deps.Items[j] is TJSONObject then
          begin
            DepObj := TJSONObject(Deps.Items[j]);
            Result.Add(DepObj.Strings['task_id']);
          end
          else
            Result.Add(Deps.Strings[j]);
        end;
      Break;
    end;
  end;
end;

function TAIProjectDependencies.GetSerialPairs: TStringList;
var
  Tasks: TJSONArray;
  Task: TJSONObject;
  Deps: TJSONArray;
  i, j: Integer;
  DepID: string;
begin
  Result := TStringList.Create;
  if not Assigned(FProject) or not Assigned(FProject.ProjectData) then Exit;
  Tasks := TJSONArray(FProject.ProjectData.FindPath('planning.tasks'));
  if not Assigned(Tasks) then Exit;
  for i := 0 to Tasks.Count - 1 do
  begin
    Task := Tasks.Objects[i];
    Deps := TJSONArray(Task.FindPath('dependencies'));
    if not Assigned(Deps) or (Deps.Count = 0) then Continue;
    for j := 0 to Deps.Count - 1 do
    begin
      if Deps.Items[j] is TJSONObject then
        DepID := TJSONObject(Deps.Items[j]).Strings['task_id']
      else
        DepID := Deps.Strings[j];
      Result.Add(DepID + ' → ' + Task.Strings['id']
                 + ' (' + Task.Strings['title'] + ')');
    end;
  end;
end;

function TAIProjectDependencies.GetParallelGroups: TStringList;
var
  Tasks: TJSONArray;
  Task: TJSONObject;
  i: Integer;
begin
  Result := TStringList.Create;
  if not Assigned(FProject) or not Assigned(FProject.ProjectData) then Exit;
  Tasks := TJSONArray(FProject.ProjectData.FindPath('planning.tasks'));
  if not Assigned(Tasks) then Exit;
  for i := 0 to Tasks.Count - 1 do
  begin
    Task := Tasks.Objects[i];
    if Task.Booleans['can_run_in_parallel'] then
      Result.Add(Task.Strings['id'] + ': ' + Task.Strings['title'] + ' [parallel]');
  end;
end;

function TAIProjectDependencies.ExplainDependencies: string;
var
  Pairs, Parallel: TStringList;
  i: Integer;
begin
  Result := '';
  Pairs := GetSerialPairs;
  Parallel := GetParallelGroups;
  try
    if Pairs.Count > 0 then
    begin
      Result := 'Serial dependencies:' + LineEnding;
      for i := 0 to Pairs.Count - 1 do
        Result := Result + '  ' + Pairs[i] + LineEnding;
    end else
      Result := 'No serial dependencies found.' + LineEnding;

    if Parallel.Count > 0 then
    begin
      Result := Result + LineEnding + 'Tasks that can run in parallel:' + LineEnding;
      for i := 0 to Parallel.Count - 1 do
        Result := Result + '  ' + Parallel[i] + LineEnding;
    end;
  finally
    Pairs.Free;
    Parallel.Free;
  end;
end;

initialization
  {$I taiprojectdependencies_icon.lrs}

end.
