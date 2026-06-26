unit aiproject_revisions;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, aiproject, fpjson, LResources;

type
  TRevisionEventType = (
    retRevisionCreated,
    retTaskStarted,
    retTaskFinished,
    retRiskAdded,
    retDeadlineChanged,
    retAgentAnalyzedTask,
    retCorrectionApplied,
    retMilestoneReached
  );

  { TAIProjectRevisions — manages revision history and event registration }
  TAIProjectRevisions = class(TComponent)
  private
    FProject: TAIProject;
    FLastError: string;
    function GetRevisions: TJSONArray;
    function GetCount: Integer;
  public
    constructor Create(AOwner: TComponent); override;

    { Adds a new revision to the project. Returns revision number or -1. }
    function AddRevision(const ATitle, AInputText, AGeneratedJSON: string): Integer;

    { Returns Markdown description of revision at given index. }
    function GetRevisionMarkdown(AIndex: Integer): string;

    { Applies a user-provided correction, generating a new revision via AI. }
    function ApplyCorrection(const ACorrection: string): Boolean;

    { Registers a timeline event (e.g. Task started, Risk added). }
    procedure RegisterEvent(AEventType: TRevisionEventType;
                            const ADescription: string;
                            const ARelatedID: string = '');

    { Human-readable event type name }
    class function EventTypeName(AType: TRevisionEventType): string;

    property Revisions: TJSONArray read GetRevisions;
    property Count: Integer read GetCount;
    property LastError: string read FLastError;
  published
    property Project: TAIProject read FProject write FProject;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('AI Project', [TAIProjectRevisions]);
end;

constructor TAIProjectRevisions.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
end;

class function TAIProjectRevisions.EventTypeName(AType: TRevisionEventType): string;
begin
  case AType of
    retRevisionCreated:   Result := 'Revision created';
    retTaskStarted:       Result := 'Task started';
    retTaskFinished:      Result := 'Task finished';
    retRiskAdded:         Result := 'Risk added';
    retDeadlineChanged:   Result := 'Deadline changed';
    retAgentAnalyzedTask: Result := 'Agent analyzed task';
    retCorrectionApplied: Result := 'Correction applied';
    retMilestoneReached:  Result := 'Milestone reached';
  else
    Result := 'Event';
  end;
end;

function TAIProjectRevisions.GetRevisions: TJSONArray;
begin
  Result := nil;
  if Assigned(FProject) and Assigned(FProject.ProjectData) then
    Result := TJSONArray(FProject.ProjectData.FindPath('revisions'));
end;

function TAIProjectRevisions.GetCount: Integer;
var
  Arr: TJSONArray;
begin
  Arr := GetRevisions;
  if Assigned(Arr) then Result := Arr.Count else Result := 0;
end;

function TAIProjectRevisions.AddRevision(const ATitle, AInputText,
  AGeneratedJSON: string): Integer;
begin
  Result := -1;
  FLastError := '';
  if not Assigned(FProject) then
  begin
    FLastError := 'No project linked.';
    Exit;
  end;
  Result := FProject.AddRevision(ATitle, AInputText, AGeneratedJSON);
end;

function TAIProjectRevisions.GetRevisionMarkdown(AIndex: Integer): string;
begin
  Result := '';
  if not Assigned(FProject) then Exit;
  Result := FProject.GetRevisionMarkdown(AIndex);
end;

function TAIProjectRevisions.ApplyCorrection(const ACorrection: string): Boolean;
begin
  Result := False;
  FLastError := '';
  if not Assigned(FProject) then
  begin
    FLastError := 'No project linked.';
    Exit;
  end;
  Result := FProject.ApplyProjectCorrection(ACorrection);
  if not Result then
    FLastError := FProject.LastError;
end;

procedure TAIProjectRevisions.RegisterEvent(AEventType: TRevisionEventType;
  const ADescription: string; const ARelatedID: string);
var
  Timeline: TJSONArray;
  Event: TJSONObject;
begin
  if not Assigned(FProject) or not Assigned(FProject.ProjectData) then Exit;
  Timeline := TJSONArray(FProject.ProjectData.FindPath('planning.timeline'));
  if not Assigned(Timeline) then Exit;

  Event := TJSONObject.Create([
    'date',        DateTimeToStr(Now),
    'type',        EventTypeName(AEventType),
    'title',       ADescription,
    'related_id',  ARelatedID
  ]);
  Timeline.Add(Event);
end;

initialization
  {$I taiprojectrevisions_icon.lrs}

end.
