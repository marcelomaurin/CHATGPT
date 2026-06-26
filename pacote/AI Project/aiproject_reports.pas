unit aiproject_reports;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, aiproject, fpjson, LResources;

type
  TReportType = (
    rtProjectSummary,
    rtAgileDocs,
    rtTasks,
    rtRisks,
    rtAgents,
    rtGantt,
    rtTimeline,
    rtRevisionHistory
  );

  TReportExportFormat = (refMarkdown, refCSV, refJSON);

  { TAIProjectReports — generates text reports from project data }
  TAIProjectReports = class(TComponent)
  private
    FProject: TAIProject;
    FLastError: string;
    function BuildSummaryReport: string;
    function BuildAgileDocsReport: string;
    function BuildTasksReport: string;
    function BuildRisksReport: string;
    function BuildAgentsReport: string;
    function BuildGanttReport: string;
    function BuildTimelineReport: string;
    function BuildRevisionHistoryReport: string;
  public
    constructor Create(AOwner: TComponent); override;

    { Generates a report of the given type in Markdown format. }
    function GenerateReport(AType: TReportType): string;

    { Exports a specific report type to the desired format. }
    function ExportReport(AType: TReportType;
                          AFormat: TReportExportFormat;
                          const AFilename: string): Boolean;

    { Exports full project as Markdown. }
    function ExportFullMarkdown(const AFilename: string): Boolean;

    { Exports full project as JSON. }
    function ExportFullJSON(const AFilename: string): Boolean;

    property LastError: string read FLastError;
  published
    property Project: TAIProject read FProject write FProject;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('AI Project', [TAIProjectReports]);
end;

constructor TAIProjectReports.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
end;

function TAIProjectReports.BuildSummaryReport: string;
var
  Tasks: TJSONArray;
  i, TotalTasks, DoneTasks, InProgress, Blocked: Integer;
  Task: TJSONObject;
  Status: string;
begin
  TotalTasks := 0; DoneTasks := 0; InProgress := 0; Blocked := 0;
  if Assigned(FProject) and Assigned(FProject.ProjectData) then
  begin
    Tasks := TJSONArray(FProject.ProjectData.FindPath('planning.tasks'));
    if Assigned(Tasks) then
    begin
      TotalTasks := Tasks.Count;
      for i := 0 to Tasks.Count - 1 do
      begin
        Task := Tasks.Objects[i];
        Status := Task.Strings['status'];
        if Status = 'done' then Inc(DoneTasks)
        else if Status = 'in_progress' then Inc(InProgress)
        else if Status = 'blocked' then Inc(Blocked);
      end;
    end;
  end;

  Result :=
    '# Project Summary' + LineEnding + LineEnding +
    '**Project:** ' + FProject.ProjectName + LineEnding +
    '**Goal:** ' + FProject.Goal + LineEnding +
    '**Start:** ' + DateToStr(FProject.StartDate) + LineEnding +
    '**Target End:** ' + DateToStr(FProject.TargetEndDate) + LineEnding + LineEnding +
    '## Task Status' + LineEnding +
    '| Status | Count |' + LineEnding +
    '|--------|-------|' + LineEnding +
    '| Total  | ' + IntToStr(TotalTasks) + ' |' + LineEnding +
    '| Done   | ' + IntToStr(DoneTasks) + ' |' + LineEnding +
    '| In Progress | ' + IntToStr(InProgress) + ' |' + LineEnding +
    '| Blocked | ' + IntToStr(Blocked) + ' |' + LineEnding;
end;

function TAIProjectReports.BuildAgileDocsReport: string;
begin
  if not Assigned(FProject) then begin Result := ''; Exit; end;
  Result := FProject.ExportPlanToMarkdown;
end;

function TAIProjectReports.BuildTasksReport: string;
var
  Tasks: TJSONArray;
  Task: TJSONObject;
  i: Integer;
begin
  Result := '# Tasks Report' + LineEnding + LineEnding;
  Result := Result + '| ID | Title | Status | Priority | Agent | Start | End | Progress |' + LineEnding;
  Result := Result + '|----|-------|--------|----------|-------|-------|-----|----------|' + LineEnding;
  if not Assigned(FProject) or not Assigned(FProject.ProjectData) then Exit;
  Tasks := TJSONArray(FProject.ProjectData.FindPath('planning.tasks'));
  if not Assigned(Tasks) then Exit;
  for i := 0 to Tasks.Count - 1 do
  begin
    Task := Tasks.Objects[i];
    Result := Result + '| ' + Task.Strings['id']
              + ' | ' + Task.Strings['title']
              + ' | ' + Task.Strings['status']
              + ' | ' + Task.Strings['priority']
              + ' | ' + Task.Strings['assigned_to']
              + ' | ' + Task.Strings['planned_start_date']
              + ' | ' + Task.Strings['planned_end_date']
              + ' | ' + IntToStr(Task.Integers['progress_percent']) + '% |' + LineEnding;
  end;
end;

function TAIProjectReports.BuildRisksReport: string;
var
  Risks: TJSONArray;
  Risk: TJSONObject;
  i: Integer;
begin
  Result := '# Risk Map' + LineEnding + LineEnding;
  Result := Result + '| ID | Risk | Impact | Probability |' + LineEnding;
  Result := Result + '|----|------|--------|-------------|' + LineEnding;
  if not Assigned(FProject) or not Assigned(FProject.ProjectData) then Exit;
  Risks := TJSONArray(FProject.ProjectData.FindPath('agile_documents.risk_map'));
  if not Assigned(Risks) then Exit;
  for i := 0 to Risks.Count - 1 do
  begin
    Risk := Risks.Objects[i];
    Result := Result + '| ' + Risk.Strings['id']
              + ' | ' + Risk.Strings['title']
              + ' | ' + Risk.Strings['impact']
              + ' | ' + Risk.Strings['probability'] + ' |' + LineEnding;
  end;
end;

function TAIProjectReports.BuildAgentsReport: string;
var
  Agents: TJSONArray;
  Agent: TJSONObject;
  i: Integer;
begin
  Result := '# Agents Report' + LineEnding + LineEnding;
  Result := Result + '| ID | Name | Profile | Skill Level | Active |' + LineEnding;
  Result := Result + '|----|------|---------|-------------|--------|' + LineEnding;
  if not Assigned(FProject) or not Assigned(FProject.ProjectData) then Exit;
  Agents := TJSONArray(FProject.ProjectData.FindPath('agents'));
  if not Assigned(Agents) then Exit;
  for i := 0 to Agents.Count - 1 do
  begin
    Agent := Agents.Objects[i];
    Result := Result + '| ' + Agent.Strings['id']
              + ' | ' + Agent.Strings['name']
              + ' | ' + Agent.Strings['profile']
              + ' | ' + Agent.Strings['skill_level']
              + ' | ' + BoolToStr(Agent.Booleans['active'], 'Yes', 'No') + ' |' + LineEnding;
  end;
end;

function TAIProjectReports.BuildGanttReport: string;
var
  Tasks: TJSONArray;
  Task: TJSONObject;
  i: Integer;
begin
  Result := '# Gantt Chart (Text)' + LineEnding + LineEnding;
  if not Assigned(FProject) or not Assigned(FProject.ProjectData) then Exit;
  Tasks := TJSONArray(FProject.ProjectData.FindPath('planning.tasks'));
  if not Assigned(Tasks) then Exit;
  for i := 0 to Tasks.Count - 1 do
  begin
    Task := Tasks.Objects[i];
    Result := Result + Task.Strings['id'] + ' | '
              + Task.Strings['planned_start_date'] + ' → '
              + Task.Strings['planned_end_date'] + ' | '
              + Task.Strings['title'] + ' ['
              + Task.Strings['status'] + ']' + LineEnding;
  end;
end;

function TAIProjectReports.BuildTimelineReport: string;
var
  Timeline: TJSONArray;
  Event: TJSONObject;
  i: Integer;
begin
  Result := '# Timeline' + LineEnding + LineEnding;
  if not Assigned(FProject) or not Assigned(FProject.ProjectData) then Exit;
  Timeline := TJSONArray(FProject.ProjectData.FindPath('planning.timeline'));
  if not Assigned(Timeline) then Exit;
  for i := 0 to Timeline.Count - 1 do
  begin
    Event := Timeline.Objects[i];
    Result := Result + '- **' + Event.Strings['date'] + '** '
              + Event.Strings['title'] + LineEnding;
  end;
end;

function TAIProjectReports.BuildRevisionHistoryReport: string;
var
  Revisions: TJSONArray;
  Rev: TJSONObject;
  i: Integer;
begin
  Result := '# Revision History' + LineEnding + LineEnding;
  if not Assigned(FProject) or not Assigned(FProject.ProjectData) then Exit;
  Revisions := TJSONArray(FProject.ProjectData.FindPath('revisions'));
  if not Assigned(Revisions) then Exit;
  for i := 0 to Revisions.Count - 1 do
  begin
    Rev := Revisions.Objects[i];
    Result := Result + '## Revision ' + IntToStr(Rev.Integers['number'])
              + ' — ' + Rev.Strings['title'] + LineEnding;
    Result := Result + '**Date:** ' + Rev.Strings['date'] + LineEnding;
    Result := Result + '**Input:** ' + Rev.Strings['input'] + LineEnding + LineEnding;
  end;
end;

function TAIProjectReports.GenerateReport(AType: TReportType): string;
begin
  Result := '';
  FLastError := '';
  if not Assigned(FProject) then
  begin
    FLastError := 'No project linked.';
    Exit;
  end;
  case AType of
    rtProjectSummary:  Result := BuildSummaryReport;
    rtAgileDocs:       Result := BuildAgileDocsReport;
    rtTasks:           Result := BuildTasksReport;
    rtRisks:           Result := BuildRisksReport;
    rtAgents:          Result := BuildAgentsReport;
    rtGantt:           Result := BuildGanttReport;
    rtTimeline:        Result := BuildTimelineReport;
    rtRevisionHistory: Result := BuildRevisionHistoryReport;
  end;
end;

function TAIProjectReports.ExportReport(AType: TReportType;
  AFormat: TReportExportFormat; const AFilename: string): Boolean;
var
  Content: string;
  SL: TStringList;
begin
  Result := False;
  FLastError := '';
  Content := GenerateReport(AType);
  if Content = '' then Exit;

  if AFormat = refJSON then
  begin
    // For JSON, export entire project if summary; else wrap content
    Content := FProject.ExportPlanToJSON;
  end;

  SL := TStringList.Create;
  try
    SL.Text := Content;
    try
      SL.SaveToFile(AFilename);
      Result := True;
    except
      on E: Exception do
        FLastError := 'Cannot write file: ' + E.Message;
    end;
  finally
    SL.Free;
  end;
end;

function TAIProjectReports.ExportFullMarkdown(const AFilename: string): Boolean;
var
  SL: TStringList;
begin
  Result := False;
  FLastError := '';
  if not Assigned(FProject) then begin FLastError := 'No project linked.'; Exit; end;
  SL := TStringList.Create;
  try
    SL.Text := FProject.ExportPlanToMarkdown;
    try
      SL.SaveToFile(AFilename);
      Result := True;
    except
      on E: Exception do FLastError := E.Message;
    end;
  finally
    SL.Free;
  end;
end;

function TAIProjectReports.ExportFullJSON(const AFilename: string): Boolean;
var
  SL: TStringList;
begin
  Result := False;
  FLastError := '';
  if not Assigned(FProject) then begin FLastError := 'No project linked.'; Exit; end;
  SL := TStringList.Create;
  try
    SL.Text := FProject.ExportPlanToJSON;
    try
      SL.SaveToFile(AFilename);
      Result := True;
    except
      on E: Exception do FLastError := E.Message;
    end;
  finally
    SL.Free;
  end;
end;

initialization
  {$I taiprojectreports_icon.lrs}

end.
