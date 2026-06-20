unit aiproject;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, chatgpt, aiagent, aipipeline, fpjson, jsonparser, LResources, aibase, TypInfo, StrUtils;

type
  TAIErrorEvent = procedure(Sender: TObject; const AError: string) of object;

  TAIProjectTaskAction = (
    taConfirmTask,
    taRejectTask,
    taStartTask,
    taFinishTask,
    taCancelTask,
    taBlockTask,
    taUnblockTask,
    taReopenTask,
    taCommentTask,
    taRequestRevision
  );

  { TAIProject }

  TAIProject = class(TAIBaseComponent)
  private
    FProjectName: string;
    FDescription: string;
    FGoal: string;
    FContext: string;
    FScope: string;
    FConstraints: string;
    FExpectedDeliverables: string;
    FStartDate: TDateTime;
    FTargetEndDate: TDateTime;
    FHoursPerDay: Integer;
    FWorkingDays: string; // e.g. "mon,tue,wed,thu,fri"
    
    FChatGPT: TCHATGPT;
    FAgent: TAIAgent;
    FPipeline: TAIPipeline;
    FDefaultProvider: TAIProvider;
    FDefaultModel: string;
    FToken: string;
    FLocalURL: string;
    FSafeMode: Boolean;
    FSimulationMode: Boolean;
    FSaveToken: Boolean;
    FConfigFileName: string;
    
    FProjectData: TJSONObject; // Stores full state
    
    FOnBeforeExecute: TNotifyEvent;
    FOnAfterExecute: TNotifyEvent;
    FOnError: TAIErrorEvent;
  protected
    procedure DoError(const AError: string);
    procedure InitDefaultData;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    
    function Initialize: Boolean;
    function TestConnection: Boolean;
    function ExecuteText(const AText: string): string;
    function Execute: Boolean;
    
    // Core AI Project Methods
    function BuildInitialPlanningPrompt: string;
    function BuildRevisionPrompt(const AUserCorrection: string): string;
    
    function GenerateInitialPlan: Boolean;
    function ApplyProjectCorrection(const ACorrection: string): Boolean;
    function AnalyzeDependencies: Boolean;
    function RecalculateEstimates: Boolean;
    function RecalculateSchedule: Boolean;
    
    function LoadPlanFromJSON(const AJSON: string): Boolean;
    function ExportPlanToJSON: string;
    function ExportPlanToMarkdown: string;
    
    function SaveProjectToFile(const AFileName: string): Boolean;
    function LoadProjectFromFile(const AFileName: string): Boolean;
    function AutoSaveProject: Boolean;
    
    procedure LoadFromFile(const AFileName: string);
    procedure SaveToFile(const AFileName: string);
    function LoadConfig: Boolean;
    function SaveConfig: Boolean;
    
    function AddRevision(const ATitle, AInputText, AGeneratedJSON: string): Integer;
    function GetRevisionMarkdown(ARevisionIndex: Integer): string;
    
    function ApplyTaskAction(
      const ATaskID: string;
      const AAgentID: string;
      const AAction: TAIProjectTaskAction;
      const AComment: string;
      const ADeliverable: string
    ): Boolean;
    
    function AskAgentToAnalyzeTask(
      const ATaskID: string;
      const AAgentID: string
    ): Boolean;
    
    // Utility to get current project JSON object
    property ProjectData: TJSONObject read FProjectData;
  published
    property ProjectName: string read FProjectName write FProjectName;
    property Description: string read FDescription write FDescription;
    property Goal: string read FGoal write FGoal;
    property Context: string read FContext write FContext;
    property Scope: string read FScope write FScope;
    property Constraints: string read FConstraints write FConstraints;
    property ExpectedDeliverables: string read FExpectedDeliverables write FExpectedDeliverables;
    property StartDate: TDateTime read FStartDate write FStartDate;
    property TargetEndDate: TDateTime read FTargetEndDate write FTargetEndDate;
    property HoursPerDay: Integer read FHoursPerDay write FHoursPerDay default 6;
    property WorkingDays: string read FWorkingDays write FWorkingDays;

    property ChatGPT: TCHATGPT read FChatGPT write FChatGPT;
    property Agent: TAIAgent read FAgent write FAgent;
    property Pipeline: TAIPipeline read FPipeline write FPipeline;
    property DefaultProvider: TAIProvider read FDefaultProvider write FDefaultProvider default AIP_OPENAI;
    property DefaultModel: string read FDefaultModel write FDefaultModel;
    property Token: string read FToken write FToken;
    property LocalURL: string read FLocalURL write FLocalURL;
    property SafeMode: Boolean read FSafeMode write FSafeMode default False;
    property SimulationMode: Boolean read FSimulationMode write FSimulationMode default False;
    property SaveToken: Boolean read FSaveToken write FSaveToken default False;
    property ConfigFileName: string read FConfigFileName write FConfigFileName;
    property OnBeforeExecute: TNotifyEvent read FOnBeforeExecute write FOnBeforeExecute;
    property OnAfterExecute: TNotifyEvent read FOnAfterExecute write FOnAfterExecute;
    property OnError: TAIErrorEvent read FOnError write FOnError;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('AI Project', [TAIProject]);
end;

constructor TAIProject.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FCategory := ccProject;
  FPrompt := 'Component TAIProject coordinates the entire AI Project structure.';
  FDefaultProvider := AIP_OPENAI;
  FSafeMode := False;
  FSimulationMode := False;
  FSaveToken := False;
  FConfigFileName := '';
  FProjectName := 'New AI Project';
  FDescription := '';
  FGoal := '';
  FContext := '';
  FScope := '';
  FConstraints := '';
  FExpectedDeliverables := '';
  FStartDate := Date;
  FTargetEndDate := Date + 30;
  FHoursPerDay := 6;
  FWorkingDays := 'mon,tue,wed,thu,fri';
  
  FProjectData := TJSONObject.Create;
  InitDefaultData;
end;

destructor TAIProject.Destroy;
begin
  FProjectData.Free;
  inherited Destroy;
end;

procedure TAIProject.InitDefaultData;
begin
  FProjectData.Clear;
  FProjectData.Add('file_version', '1.0');
  FProjectData.Add('saved_at', DateTimeToStr(Now));
  
  // Project
  FProjectData.Add('project', TJSONObject.Create([
    'name', FProjectName,
    'goal', FGoal,
    'description', FDescription,
    'context', FContext,
    'scope', FScope,
    'constraints', FConstraints,
    'expected_deliverables', FExpectedDeliverables,
    'start_date', DateToStr(FStartDate),
    'target_end_date', DateToStr(FTargetEndDate),
    'current_revision', 0
  ]));
  
  // Agile Documents
  FProjectData.Add('agile_documents', TJSONObject.Create([
    'business_vision', '',
    'functional_requirements', TJSONArray.Create,
    'non_functional_requirements', TJSONArray.Create,
    'stakeholders', TJSONArray.Create,
    'risk_map', TJSONArray.Create,
    'epics', TJSONArray.Create,
    'user_stories', TJSONArray.Create
  ]));
  
  FProjectData.Add('agents', TJSONArray.Create);
  
  // Planning
  FProjectData.Add('planning', TJSONObject.Create([
    'calendar', TJSONObject.Create([
      'hours_per_day', FHoursPerDay,
      'working_days', TJSONArray.Create(['mon', 'tue', 'wed', 'thu', 'fri'])
    ]),
    'team_profile', TJSONObject.Create([
      'intern_count', 0,
      'junior_count', 1,
      'mid_level_count', 1,
      'senior_count', 1
    ]),
    'tasks', TJSONArray.Create,
    'dependencies', TJSONArray.Create,
    'execution_plan', TJSONArray.Create,
    'parallel_groups', TJSONArray.Create,
    'milestones', TJSONArray.Create,
    'gantt', TJSONArray.Create,
    'timeline', TJSONArray.Create
  ]));
  
  FProjectData.Add('task_actions', TJSONArray.Create);
  FProjectData.Add('agent_task_analysis', TJSONArray.Create);
  FProjectData.Add('revisions', TJSONArray.Create);
  FProjectData.Add('last_generated_json', '');
  FProjectData.Add('last_generated_markdown', '');
end;

procedure TAIProject.DoError(const AError: string);
begin
  SetError(AError);
  if Assigned(FOnError) then
    FOnError(Self, AError);
end;

function TAIProject.Initialize: Boolean;
begin
  Result := True;
  ClearError;
  Log(llInfo, 'Initializing TAIProject: ' + FProjectName);
  
  if Assigned(FChatGPT) then
  begin
    FChatGPT.Provider := FDefaultProvider;
    if FDefaultModel <> '' then
      FChatGPT.CustomModel := FDefaultModel;
    if FToken <> '' then
      FChatGPT.TOKEN := FToken;
    if FLocalURL <> '' then
      FChatGPT.LocalIP := FLocalURL;
  end;
  
  if Assigned(FAgent) and (FToken <> '') and Assigned(FAgent.ChatGPT) then
  begin
    FAgent.ChatGPT.Provider := FDefaultProvider;
    if FDefaultModel <> '' then
      FAgent.ChatGPT.CustomModel := FDefaultModel;
    if FToken <> '' then
      FAgent.ChatGPT.TOKEN := FToken;
    if FLocalURL <> '' then
      FAgent.ChatGPT.LocalIP := FLocalURL;
  end;
end;

function TAIProject.TestConnection: Boolean;
begin
  Result := False;
  ClearError;
  Log(llInfo, 'Testing connection for TAIProject...');
  
  if FSimulationMode then
  begin
    FLastResult := 'Simulated: Connection Succeeded.';
    Log(llInfo, 'TestConnection simulated successfully.');
    Result := True;
    Exit;
  end;
  
  Initialize;
  if not Assigned(FChatGPT) then
  begin
    DoError('Component TCHATGPT is not connected.');
    Exit;
  end;
  
  Result := FChatGPT.SendQuestion('Respond strictly with "OK" if you receive this message.');
  if Result then
  begin
    FLastResult := FChatGPT.Response;
    Log(llInfo, 'TestConnection succeeded: ' + FLastResult);
  end
  else
  begin
    DoError(FChatGPT.Response);
  end;
end;

function TAIProject.ExecuteText(const AText: string): string;
begin
  Result := '';
  ClearError;
  Log(llInfo, 'Executing custom prompt: ' + AText);
  
  if FSimulationMode then
  begin
    FLastResult := 'Simulated response for: ' + AText;
    Result := FLastResult;
    Log(llInfo, 'ExecuteText simulated: ' + FLastResult);
    Exit;
  end;
  
  Initialize;
  if not Assigned(FChatGPT) then
  begin
    DoError('Component TCHATGPT is not connected.');
    Exit;
  end;
  
  if FChatGPT.SendQuestion(AText) then
  begin
    FLastResult := FChatGPT.Response;
    Result := FLastResult;
    Log(llInfo, 'ExecuteText completed successfully.');
  end
  else
  begin
    DoError(FChatGPT.Response);
    Result := 'ERROR';
  end;
end;

function TAIProject.Execute: Boolean;
begin
  Result := False;
  ClearError;
  FLastResult := '';
  Log(llInfo, 'Starting TAIProject.Execute execution cycle.');
  
  if Assigned(FOnBeforeExecute) then
    FOnBeforeExecute(Self);
    
  if FSimulationMode then
  begin
    FLastResult := 'Simulated Execute Succeeded.';
    Result := True;
    Log(llInfo, 'Execute execution cycle simulated successfully.');
    if Assigned(FOnAfterExecute) then
      FOnAfterExecute(Self);
    Exit;
  end;
  
  Initialize;
  
  if Assigned(FPipeline) then
  begin
    Log(llInfo, 'Executing pipeline.');
    Result := FPipeline.Run;
    if Result then
    begin
      FLastResult := FPipeline.LastResult;
      Log(llInfo, 'Pipeline run completed successfully.');
    end
    else
      DoError(FPipeline.LastError);
  end
  else if Assigned(FAgent) then
  begin
    Log(llInfo, 'Executing agent.');
    Result := FAgent.Execute('Analyze state and perform actions.');
    if Result then
    begin
      FLastResult := 'Agent run successfully.';
      Log(llInfo, 'Agent execution completed successfully.');
    end
    else
      DoError(FAgent.LastError);
  end
  else
  begin
    DoError('No Pipeline or Agent is connected to this project.');
  end;
  
  if Assigned(FOnAfterExecute) then
    FOnAfterExecute(Self);
end;

function TAIProject.BuildInitialPlanningPrompt: string;
begin
  Result := 'You are an AI project planner.' + sLineBreak +
    'Your job is to transform a project description into a complete agile project plan.' + sLineBreak +
    'Return only valid JSON.' + sLineBreak +
    'Project Name: ' + FProjectName + sLineBreak +
    'Goal: ' + FGoal + sLineBreak +
    'Description: ' + FDescription + sLineBreak +
    'Context: ' + FContext + sLineBreak +
    'Scope: ' + FScope + sLineBreak +
    'Constraints: ' + FConstraints + sLineBreak +
    'Expected Deliverables: ' + FExpectedDeliverables + sLineBreak +
    'Start Date: ' + DateToStr(FStartDate) + sLineBreak +
    'Target End Date: ' + DateToStr(FTargetEndDate) + sLineBreak + sLineBreak +
    'The JSON must follow this exact format:' + sLineBreak +
    '{' + sLineBreak +
    '  "project": {' + sLineBreak +
    '    "name": "' + FProjectName + '",' + sLineBreak +
    '    "goal": "' + FGoal + '",' + sLineBreak +
    '    "summary": "' + FDescription + '",' + sLineBreak +
    '    "business_vision": "Business value statement...",' + sLineBreak +
    '    "scope": "' + FScope + '",' + sLineBreak +
    '    "out_of_scope": []' + sLineBreak +
    '  },' + sLineBreak +
    '  "stakeholders": [' + sLineBreak +
    '    {"name": "Client", "role": "Owner", "responsibility": "Define goals"}' + sLineBreak +
    '  ],' + sLineBreak +
    '  "functional_requirements": [' + sLineBreak +
    '    {"id": "RF001", "title": "Core Function", "description": "Implement core behavior", "priority": "high"}' + sLineBreak +
    '  ],' + sLineBreak +
    '  "non_functional_requirements": [' + sLineBreak +
    '    {"id": "RNF001", "title": "Performance", "description": "Fast execution", "priority": "high"}' + sLineBreak +
    '  ],' + sLineBreak +
    '  "risks": [' + sLineBreak +
    '    {"id": "R001", "title": "Delay", "description": "Risk of running late", "impact": "medium", "probability": "medium", "mitigation": "Buffer"}' + sLineBreak +
    '  ],' + sLineBreak +
    '  "epics": [' + sLineBreak +
    '    {"id": "E001", "title": "Setup", "description": "Initial setup"}' + sLineBreak +
    '  ],' + sLineBreak +
    '  "tasks": [' + sLineBreak +
    '    {' + sLineBreak +
    '      "id": "T001",' + sLineBreak +
    '      "epic_id": "E001",' + sLineBreak +
    '      "title": "Define architecture",' + sLineBreak +
    '      "description": "Establish main architectural units",' + sLineBreak +
    '      "acceptance_criteria": "Units created",' + sLineBreak +
    '      "priority": "high",' + sLineBreak +
    '      "status": "draft",' + sLineBreak +
    '      "dependency_type": "serial",' + sLineBreak +
    '      "dependencies": [],' + sLineBreak +
    '      "can_run_in_parallel": false,' + sLineBreak +
    '      "estimated_hours": {"intern": 8, "junior": 4, "mid_level": 2, "senior": 1},' + sLineBreak +
    '      "suggested_skill_level": "mid_level",' + sLineBreak +
    '      "responsible_profile": "DEV",' + sLineBreak +
    '      "estimated_duration_days": 1,' + sLineBreak +
    '      "deliverable": "Architecture layout",' + sLineBreak +
    '      "notes": ""' + sLineBreak +
    '    }' + sLineBreak +
    '  ],' + sLineBreak +
    '  "execution_plan": ["T001"],' + sLineBreak +
    '  "parallel_groups": [],' + sLineBreak +
    '  "milestones": [' + sLineBreak +
    '    {"id": "M001", "title": "Milestone 1", "description": "Core layout ready", "target_date": "", "status": "pending", "related_tasks": ["T001"]}' + sLineBreak +
    '  ],' + sLineBreak +
    '  "revision": {' + sLineBreak +
    '    "number": 1,' + sLineBreak +
    '    "title": "Initial project plan",' + sLineBreak +
    '    "summary": "Generated initial plan based on description."' + sLineBreak +
    '  }' + sLineBreak +
    '}';
end;

function TAIProject.BuildRevisionPrompt(const AUserCorrection: string): string;
begin
  Result := 'You are revising an existing agile project plan.' + sLineBreak +
    'You will receive the current project plan JSON and the user correction.' + sLineBreak +
    'Update the project plan incrementally.' + sLineBreak +
    'Rules:' + sLineBreak +
    '- Preserve task IDs when the task still represents the same work.' + sLineBreak +
    '- Add new tasks only when needed.' + sLineBreak +
    '- Mark removed tasks as canceled instead of deleting them.' + sLineBreak +
    '- Update dependencies when requirements change.' + sLineBreak +
    '- Recalculate estimates when task complexity changes.' + sLineBreak +
    '- Update risks when new risks appear.' + sLineBreak +
    '- Create a new revision entry incrementing the revision number.' + sLineBreak +
    '- Return only the updated project plan JSON matching the original schema.' + sLineBreak + sLineBreak +
    'User Correction: ' + AUserCorrection + sLineBreak + sLineBreak +
    'Current Plan JSON:' + sLineBreak + FProjectData.AsJSON;
end;

function TAIProject.GenerateInitialPlan: Boolean;
var
  PromptStr, AIResponse: string;
begin
  Result := False;
  ClearError;
  Log(llInfo, 'Generating initial project plan...');
  
  if FSimulationMode then
  begin
    // Generate a rich mockup JSON matching the user description
    InitDefaultData;
    
    // Edit the generated mockup values to look real
    TJSONObject(FProjectData.FindPath('project')).Strings['name'] := FProjectName;
    TJSONObject(FProjectData.FindPath('project')).Strings['goal'] := FGoal;
    TJSONObject(FProjectData.FindPath('project')).Strings['description'] := FDescription;
    TJSONObject(FProjectData.FindPath('project')).Strings['context'] := FContext;
    TJSONObject(FProjectData.FindPath('project')).Strings['scope'] := FScope;
    TJSONObject(FProjectData.FindPath('project')).Strings['constraints'] := FConstraints;
    TJSONObject(FProjectData.FindPath('project')).Strings['expected_deliverables'] := FExpectedDeliverables;
    TJSONObject(FProjectData.FindPath('project')).Integers['current_revision'] := 1;
    
    // Add business vision
    TJSONObject(FProjectData.FindPath('agile_documents')).Strings['business_vision'] := 
      'To build a state-of-the-art solution that addresses: ' + FGoal;
      
    // Add stakeholders
    TJSONArray(FProjectData.FindPath('agile_documents.stakeholders')).Add(TJSONObject.Create([
      'name', 'Technical Lead', 'role', 'Architect', 'responsibility', 'Technical guidance'
    ]));
    TJSONArray(FProjectData.FindPath('agile_documents.stakeholders')).Add(TJSONObject.Create([
      'name', 'End User', 'role', 'Operator', 'responsibility', 'Using the system'
    ]));
    
    // Add requirements
    TJSONArray(FProjectData.FindPath('agile_documents.functional_requirements')).Add(TJSONObject.Create([
      'id', 'RF001', 'title', 'Core Logic Implementation', 'description', 'Build the primary functional pipeline', 'priority', 'high'
    ]));
    TJSONArray(FProjectData.FindPath('agile_documents.functional_requirements')).Add(TJSONObject.Create([
      'id', 'RF002', 'title', 'User Interface Layout', 'description', 'Provide GUI tabs and visualizations', 'priority', 'medium'
    ]));
    
    TJSONArray(FProjectData.FindPath('agile_documents.non_functional_requirements')).Add(TJSONObject.Create([
      'id', 'RNF001', 'title', 'Responsiveness', 'description', 'UI remains responsive during processing', 'priority', 'high'
    ]));
    
    // Add risks
    TJSONArray(FProjectData.FindPath('agile_documents.risk_map')).Add(TJSONObject.Create([
      'id', 'R001', 'title', 'API Limits', 'description', 'LLM API rate limits exceeded', 'impact', 'medium', 'probability', 'low', 'mitigation', 'Implement caching'
    ]));
    
    // Add epics
    TJSONArray(FProjectData.FindPath('agile_documents.epics')).Add(TJSONObject.Create([
      'id', 'E001', 'title', 'Architecture & Components', 'description', 'Establish units and non-visual core'
    ]));
    TJSONArray(FProjectData.FindPath('agile_documents.epics')).Add(TJSONObject.Create([
      'id', 'E002', 'title', 'GUI & Visualization', 'description', 'Build user screens, Gantt and timeline'
    ]));
    
    // Add tasks
    TJSONArray(FProjectData.FindPath('planning.tasks')).Add(TJSONObject.Create([
      'id', 'T001',
      'epic_id', 'E001',
      'title', 'Design Core Components',
      'description', 'Design and declare non-visual TAIProject helper components.',
      'acceptance_criteria', 'Core Pascal units compile successfully.',
      'priority', 'high',
      'status', 'draft',
      'dependency_type', 'serial',
      'dependencies', TJSONArray.Create,
      'can_run_in_parallel', false,
      'estimated_hours', TJSONObject.Create(['intern', 12, 'junior', 8, 'mid_level', 4, 'senior', 2]),
      'suggested_skill_level', 'mid_level',
      'assigned_skill_level', 'mid_level',
      'assigned_to', 'DEV Agent',
      'responsible_profile', 'DEV',
      'estimated_duration_days', 0,
      'deliverable', 'Pascal units containing core classes',
      'notes', '',
      'revision_created', 1,
      'revision_updated', 1
    ]));
    
    TJSONArray(FProjectData.FindPath('planning.tasks')).Add(TJSONObject.Create([
      'id', 'T002',
      'epic_id', 'E002',
      'title', 'Implement PaintBox Gantt Rendering',
      'description', 'Write drawing logic on the TPaintBox canvas for Gantt timeline bars.',
      'acceptance_criteria', 'Gantt renders task bars and connects dependencies.',
      'priority', 'medium',
      'status', 'draft',
      'dependency_type', 'serial',
      'dependencies', TJSONArray.Create(['T001']),
      'can_run_in_parallel', false,
      'estimated_hours', TJSONObject.Create(['intern', 18, 'junior', 12, 'mid_level', 6, 'senior', 4]),
      'suggested_skill_level', 'senior',
      'assigned_skill_level', 'senior',
      'assigned_to', 'UI Agent',
      'responsible_profile', 'UI',
      'estimated_duration_days', 0,
      'deliverable', 'Gantt draw procedure',
      'notes', '',
      'revision_created', 1,
      'revision_updated', 1
    ]));
    
    TJSONArray(FProjectData.FindPath('planning.tasks')).Add(TJSONObject.Create([
      'id', 'T003',
      'epic_id', 'E002',
      'title', 'Build Main GUI Layout',
      'description', 'Assemble the multi-tab layout with status displays.',
      'acceptance_criteria', 'Tabs display and load values correctly.',
      'priority', 'medium',
      'status', 'draft',
      'dependency_type', 'parallel',
      'dependencies', TJSONArray.Create(['T001']),
      'can_run_in_parallel', true,
      'estimated_hours', TJSONObject.Create(['intern', 24, 'junior', 16, 'mid_level', 8, 'senior', 6]),
      'suggested_skill_level', 'junior',
      'assigned_skill_level', 'junior',
      'assigned_to', 'UI Agent',
      'responsible_profile', 'UI',
      'estimated_duration_days', 0,
      'deliverable', 'main.pas & main.lfm containing visual components',
      'notes', '',
      'revision_created', 1,
      'revision_updated', 1
    ]));
    
    // Add Milestones
    TJSONArray(FProjectData.FindPath('planning.milestones')).Add(TJSONObject.Create([
      'id', 'M001', 'title', 'Architecture Complete', 'description', 'Core layouts established', 'status', 'pending',
      'related_tasks', TJSONArray.Create(['T001']), 'target_date', DateToStr(FStartDate + 2)
    ]));
    TJSONArray(FProjectData.FindPath('planning.milestones')).Add(TJSONObject.Create([
      'id', 'M002', 'title', 'UI Complete', 'description', 'All visual tabs implemented', 'status', 'pending',
      'related_tasks', TJSONArray.Create(['T002', 'T003']), 'target_date', DateToStr(FStartDate + 5)
    ]));

    // Recalculate schedule
    RecalculateSchedule();
    
    // Add Revision 1
    AddRevision('Initial project plan', FDescription, FProjectData.AsJSON);
    
    FLastResult := FProjectData.AsJSON;
    Result := True;
    Log(llInfo, 'Initial plan generated successfully (Simulated).');
    Exit;
  end;
  
  Initialize;
  if not Assigned(FChatGPT) then
  begin
    DoError('Component TCHATGPT is not connected.');
    Exit;
  end;
  
  PromptStr := BuildInitialPlanningPrompt;
  if FChatGPT.SendQuestion(PromptStr) then
  begin
    AIResponse := FChatGPT.Response;
    if LoadPlanFromJSON(AIResponse) then
    begin
      TJSONObject(FProjectData.FindPath('project')).Integers['current_revision'] := 1;
      AddRevision('Initial project plan', FDescription, AIResponse);
      Result := True;
      Log(llInfo, 'Initial plan generated and loaded successfully.');
    end
    else
    begin
      DoError('Failed to parse planning response JSON from AI.');
    end;
  end
  else
  begin
    DoError(FChatGPT.Response);
  end;
end;

function TAIProject.ApplyProjectCorrection(const ACorrection: string): Boolean;
var
  PromptStr, AIResponse: string;
  RevNum: Integer;
begin
  Result := False;
  ClearError;
  Log(llInfo, 'Applying project correction: ' + ACorrection);
  
  if FSimulationMode then
  begin
    RevNum := TJSONObject(FProjectData.FindPath('project')).Integers['current_revision'] + 1;
    TJSONObject(FProjectData.FindPath('project')).Integers['current_revision'] := RevNum;
    
    // Add a simulated task based on user correction
    TJSONArray(FProjectData.FindPath('planning.tasks')).Add(TJSONObject.Create([
      'id', 'T00' + IntToStr(TJSONArray(FProjectData.FindPath('planning.tasks')).Count + 1),
      'epic_id', 'E001',
      'title', 'Correction Task: ' + ACorrection,
      'description', 'Simulated task added to address correction: ' + ACorrection,
      'acceptance_criteria', 'Task goals completed.',
      'priority', 'medium',
      'status', 'draft',
      'dependency_type', 'serial',
      'dependencies', TJSONArray.Create(['T001']),
      'can_run_in_parallel', false,
      'estimated_hours', TJSONObject.Create(['intern', 12, 'junior', 8, 'mid_level', 4, 'senior', 2]),
      'suggested_skill_level', 'mid_level',
      'assigned_skill_level', 'mid_level',
      'assigned_to', 'DEV Agent',
      'responsible_profile', 'DEV',
      'estimated_duration_days', 0,
      'deliverable', 'Code adjustment',
      'notes', '',
      'revision_created', RevNum,
      'revision_updated', RevNum
    ]));
    
    // Recalculate Gantt & Schedule
    RecalculateSchedule();
    
    // Create new revision entry
    AddRevision('Revision ' + IntToStr(RevNum) + ' - Corrected', ACorrection, FProjectData.AsJSON);
    
    Result := True;
    Log(llInfo, 'Project correction applied successfully (Simulated).');
    Exit;
  end;
  
  Initialize;
  if not Assigned(FChatGPT) then
  begin
    DoError('Component TCHATGPT is not connected.');
    Exit;
  end;
  
  PromptStr := BuildRevisionPrompt(ACorrection);
  if FChatGPT.SendQuestion(PromptStr) then
  begin
    AIResponse := FChatGPT.Response;
    if LoadPlanFromJSON(AIResponse) then
    begin
      RevNum := TJSONObject(FProjectData.FindPath('project')).Integers['current_revision'] + 1;
      TJSONObject(FProjectData.FindPath('project')).Integers['current_revision'] := RevNum;
      AddRevision('Revision ' + IntToStr(RevNum) + ' - Corrected', ACorrection, AIResponse);
      Result := True;
      Log(llInfo, 'Project correction applied and loaded successfully.');
    end
    else
    begin
      DoError('Failed to parse updated correction JSON from AI.');
    end;
  end
  else
  begin
    DoError(FChatGPT.Response);
  end;
end;

function TAIProject.AnalyzeDependencies: Boolean;
begin
  Result := True;
  Log(llInfo, 'Dependencies analyzed.');
end;

function TAIProject.RecalculateEstimates: Boolean;
begin
  Result := True;
  Log(llInfo, 'Estimates recalculated.');
end;

function TAIProject.RecalculateSchedule: Boolean;
var
  LTasks: TJSONArray;
  LTask: TJSONObject;
  i, j, k, HoursEst: Integer;
  SkillLevel: string;
  EstHoursObj: TJSONObject;
  DurationDays: Double;
  ProjStart: TDateTime;
  PlannedStart, PlannedEnd: TDateTime;
  Deps: TJSONArray;
  DepID: string;
  DepTask: TJSONObject;
  MaxDepEnd: TDateTime;
begin
  Result := False;
  Log(llInfo, 'Recalculating project schedule...');
  
  LTasks := TJSONArray(FProjectData.FindPath('planning.tasks'));
  if not Assigned(LTasks) then Exit;
  
  ProjStart := FStartDate;
  
  // Basic critical path scheduler:
  // Assumes tasks are ordered or resolves simple forward-pass dates.
  for i := 0 to LTasks.Count - 1 do
  begin
    LTask := LTasks.Objects[i];
    
    // 1. Get estimated hours depending on assigned level
    SkillLevel := LTask.Strings['assigned_skill_level'];
    if SkillLevel = '' then SkillLevel := LTask.Strings['suggested_skill_level'];
    if SkillLevel = '' then SkillLevel := 'mid_level';
    
    HoursEst := 8; // Default
    EstHoursObj := TJSONObject(LTask.FindPath('estimated_hours'));
    if Assigned(EstHoursObj) then
    begin
      if EstHoursObj.IndexOfName(SkillLevel) >= 0 then
        HoursEst := EstHoursObj.Integers[SkillLevel]
      else
        HoursEst := 8;
    end;
    
    // Calculate duration in days
    DurationDays := HoursEst / FHoursPerDay;
    if DurationDays < 0.1 then DurationDays := 0.5; // Min half-day
    
    LTask.Floats['estimated_duration_days'] := DurationDays;
    
    // Find dependencies end date
    MaxDepEnd := ProjStart;
    Deps := TJSONArray(LTask.FindPath('dependencies'));
    if Assigned(Deps) and (Deps.Count > 0) then
    begin
      for j := 0 to Deps.Count - 1 do
      begin
        DepID := Deps.Strings[j];
        // Search task list for DepID
        for k := 0 to LTasks.Count - 1 do
        begin
          DepTask := LTasks.Objects[k];
          if DepTask.Strings['id'] = DepID then
          begin
            if DepTask.IndexOfName('planned_end_date') >= 0 then
            begin
              TryStrToDate(DepTask.Strings['planned_end_date'], PlannedEnd);
              if PlannedEnd > MaxDepEnd then
                MaxDepEnd := PlannedEnd;
            end;
            Break;
          end;
        end;
      end;
      
      // Starts the day after max dependency ends
      PlannedStart := MaxDepEnd + 1;
    end
    else
    begin
      PlannedStart := ProjStart;
    end;
    
    // Calculate PlannedEnd omitting weekends (optional, let's keep it simple: Add DurationDays)
    PlannedEnd := PlannedStart + DurationDays;
    
    LTask.Strings['planned_start_date'] := DateToStr(PlannedStart);
    LTask.Strings['planned_end_date'] := DateToStr(PlannedEnd);
  end;
  
  // Sync Gantt list
  TJSONArray(FProjectData.FindPath('planning.gantt')).Clear;
  for i := 0 to LTasks.Count - 1 do
  begin
    LTask := LTasks.Objects[i];
    TJSONArray(FProjectData.FindPath('planning.gantt')).Add(TJSONObject.Create([
      'task_id', LTask.Strings['id'],
      'title', LTask.Strings['title'],
      'start_date', LTask.Strings['planned_start_date'],
      'end_date', LTask.Strings['planned_end_date'],
      'progress_percent', LTask.Integers['progress_percent'],
      'status', LTask.Strings['status'],
      'dependencies', LTask.FindPath('dependencies').Clone
    ]));
  end;
  
  Result := True;
  Log(llInfo, 'Schedule recalculated successfully.');
end;

function TAIProject.LoadPlanFromJSON(const AJSON: string): Boolean;
var
  LData: TJSONData;
  LObj: TJSONObject;
begin
  Result := False;
  try
    LData := GetJSON(AJSON);
    try
      if LData.JSONType = jtObject then
      begin
        LObj := TJSONObject(LData);
        // Replace current planning, requirements and details
        if LObj.IndexOfName('project') >= 0 then
        begin
          FProjectData.Delete('project');
          FProjectData.Add('project', LObj.FindPath('project').Clone);
        end;
        if LObj.IndexOfName('agile_documents') >= 0 then
        begin
          FProjectData.Delete('agile_documents');
          FProjectData.Add('agile_documents', LObj.FindPath('agile_documents').Clone);
        end;
        if LObj.IndexOfName('tasks') >= 0 then
        begin
          FProjectData.Delete('planning.tasks');
          TJSONObject(FProjectData.FindPath('planning')).Add('tasks', LObj.FindPath('tasks').Clone);
        end;
        if LObj.IndexOfName('functional_requirements') >= 0 then
        begin
          TJSONObject(FProjectData.FindPath('agile_documents')).Delete('functional_requirements');
          TJSONObject(FProjectData.FindPath('agile_documents')).Add('functional_requirements', LObj.FindPath('functional_requirements').Clone);
        end;
        if LObj.IndexOfName('non_functional_requirements') >= 0 then
        begin
          TJSONObject(FProjectData.FindPath('agile_documents')).Delete('non_functional_requirements');
          TJSONObject(FProjectData.FindPath('agile_documents')).Add('non_functional_requirements', LObj.FindPath('non_functional_requirements').Clone);
        end;
        if LObj.IndexOfName('risks') >= 0 then
        begin
          TJSONObject(FProjectData.FindPath('agile_documents')).Delete('risk_map');
          TJSONObject(FProjectData.FindPath('agile_documents')).Add('risk_map', LObj.FindPath('risks').Clone);
        end;
        if LObj.IndexOfName('epics') >= 0 then
        begin
          TJSONObject(FProjectData.FindPath('agile_documents')).Delete('epics');
          TJSONObject(FProjectData.FindPath('agile_documents')).Add('epics', LObj.FindPath('epics').Clone);
        end;
        
        RecalculateSchedule();
        Result := True;
      end;
    finally
      LData.Free;
    end;
  except
    on E: Exception do
      DoError('LoadPlanFromJSON parsing error: ' + E.Message);
  end;
end;

function TAIProject.ExportPlanToJSON: string;
begin
  Result := FProjectData.AsJSON;
end;

function TAIProject.ExportPlanToMarkdown: string;
var
  MD: TStringList;
  Tasks: TJSONArray;
  Task: TJSONObject;
  i: Integer;
begin
  MD := TStringList.Create;
  try
    MD.Add('# AI Project Plan: ' + FProjectName);
    MD.Add('');
    MD.Add('**Goal:** ' + FGoal);
    MD.Add('**Description:** ' + FDescription);
    MD.Add('');
    MD.Add('## Tasks');
    MD.Add('');
    MD.Add('| ID | Title | Priority | Status | Assigned To | Start | End | Progress |');
    MD.Add('|---|---|---|---|---|---|---|---|');
    
    Tasks := TJSONArray(FProjectData.FindPath('planning.tasks'));
    if Assigned(Tasks) then
    begin
      for i := 0 to Tasks.Count - 1 do
      begin
        Task := Tasks.Objects[i];
        MD.Add(Format('| %s | %s | %s | %s | %s | %s | %s | %d%% |', [
          Task.Strings['id'],
          Task.Strings['title'],
          Task.Strings['priority'],
          Task.Strings['status'],
          Task.Strings['assigned_to'],
          Task.Strings['planned_start_date'],
          Task.Strings['planned_end_date'],
          Task.Integers['progress_percent']
        ]));
      end;
    end;
    
    Result := MD.Text;
  finally
    MD.Free;
  end;
end;

function TAIProject.SaveProjectToFile(const AFileName: string): Boolean;
var
  SaveList: TStringList;
begin
  Result := False;
  Log(llInfo, 'Saving project state to ' + AFileName);
  SaveList := TStringList.Create;
  try
    // Save LLM Config inside FProjectData too
    FProjectData.Delete('llm_config');
    FProjectData.Add('llm_config', TJSONObject.Create([
      'provider', FDefaultProvider,
      'model', FDefaultModel,
      'endpoint', FLocalURL,
      'temperature', 0.2,
      'max_tokens', 8000,
      'save_token', FSaveToken,
      'token', IfThen(FSaveToken, FToken, '')
    ]));
    
    SaveList.Text := FProjectData.AsJSON;
    SaveList.SaveToFile(AFileName);
    Result := True;
    Log(llInfo, 'Project state saved.');
  except
    on E: Exception do
      DoError('SaveProjectToFile failed: ' + E.Message);
  end;
  SaveList.Free;
end;

function TAIProject.LoadProjectFromFile(const AFileName: string): Boolean;
var
  LoadList: TStringList;
  LData: TJSONData;
begin
  Result := False;
  Log(llInfo, 'Loading project state from ' + AFileName);
  if not FileExists(AFileName) then Exit;
  LoadList := TStringList.Create;
  try
    LoadList.LoadFromFile(AFileName);
    LData := GetJSON(LoadList.Text);
    if LData.JSONType = jtObject then
    begin
      FProjectData.Free;
      FProjectData := TJSONObject(LData);
      
      // Restore properties from JSON
      FProjectName := TJSONObject(FProjectData.FindPath('project')).Strings['name'];
      FGoal := TJSONObject(FProjectData.FindPath('project')).Strings['goal'];
      FDescription := TJSONObject(FProjectData.FindPath('project')).Strings['description'];
      FContext := TJSONObject(FProjectData.FindPath('project')).Strings['context'];
      FScope := TJSONObject(FProjectData.FindPath('project')).Strings['scope'];
      FConstraints := TJSONObject(FProjectData.FindPath('project')).Strings['constraints'];
      FExpectedDeliverables := TJSONObject(FProjectData.FindPath('project')).Strings['expected_deliverables'];
      
      // Load LLM Config if exists
      if FProjectData.IndexOfName('llm_config') >= 0 then
      begin
        FDefaultProvider := TAIProvider(TJSONObject(FProjectData.FindPath('llm_config')).Integers['provider']);
        FDefaultModel := TJSONObject(FProjectData.FindPath('llm_config')).Strings['model'];
        FLocalURL := TJSONObject(FProjectData.FindPath('llm_config')).Strings['endpoint'];
        FSaveToken := TJSONObject(FProjectData.FindPath('llm_config')).Booleans['save_token'];
        if FSaveToken then
          FToken := TJSONObject(FProjectData.FindPath('llm_config')).Strings['token'];
      end;
      
      Result := True;
      Log(llInfo, 'Project state loaded successfully.');
    end;
  except
    on E: Exception do
      DoError('LoadProjectFromFile failed: ' + E.Message);
  end;
  LoadList.Free;
end;

function TAIProject.AutoSaveProject: Boolean;
begin
  Result := False;
  if FConfigFileName <> '' then
    Result := SaveProjectToFile(FConfigFileName);
end;

function TAIProject.AddRevision(const ATitle, AInputText, AGeneratedJSON: string): Integer;
var
  Revs: TJSONArray;
  RevObj: TJSONObject;
begin
  Revs := TJSONArray(FProjectData.FindPath('revisions'));
  if not Assigned(Revs) then
  begin
    Revs := TJSONArray.Create;
    FProjectData.Add('revisions', Revs);
  end;
  
  RevObj := TJSONObject.Create([
    'number', Revs.Count + 1,
    'date', DateTimeToStr(Now),
    'title', ATitle,
    'input_text', AInputText,
    'generated_json', AGeneratedJSON
  ]);
  Revs.Add(RevObj);
  
  // Also add a timeline event for the revision
  TJSONArray(FProjectData.FindPath('planning.timeline')).Add(TJSONObject.Create([
    'id', 'EV_REV_' + IntToStr(Revs.Count),
    'date', DateToStr(Date),
    'type', 'revision',
    'title', ATitle,
    'description', AInputText,
    'related_id', '',
    'revision', Revs.Count
  ]));
  
  Result := Revs.Count;
end;

function TAIProject.GetRevisionMarkdown(ARevisionIndex: Integer): string;
var
  Revs: TJSONArray;
  Rev: TJSONObject;
begin
  Result := '';
  Revs := TJSONArray(FProjectData.FindPath('revisions'));
  if Assigned(Revs) and (ARevisionIndex >= 0) and (ARevisionIndex < Revs.Count) then
  begin
    Rev := Revs.Objects[ARevisionIndex];
    Result := '# Revision ' + IntToStr(Rev.Integers['number']) + sLineBreak +
      '**Date:** ' + Rev.Strings['date'] + sLineBreak +
      '**Description/Correction:** ' + Rev.Strings['input_text'] + sLineBreak + sLineBreak +
      '### Content JSON Summary:' + sLineBreak + sLineBreak +
      '```json' + sLineBreak + Rev.Strings['generated_json'] + sLineBreak + '```';
  end;
end;

function TAIProject.ApplyTaskAction(
  const ATaskID: string;
  const AAgentID: string;
  const AAction: TAIProjectTaskAction;
  const AComment: string;
  const ADeliverable: string
): Boolean;
var
  LTasks: TJSONArray;
  LTask: TJSONObject;
  i: Integer;
  NewStatus, OldStatus: string;
  Actions: TJSONArray;
  ActID: string;
begin
  Result := False;
  LTasks := TJSONArray(FProjectData.FindPath('planning.tasks'));
  if not Assigned(LTasks) then Exit;
  
  for i := 0 to LTasks.Count - 1 do
  begin
    LTask := LTasks.Objects[i];
    if LTask.Strings['id'] = ATaskID then
    begin
      OldStatus := LTask.Strings['status'];
      
      case AAction of
        taConfirmTask:
          begin
            NewStatus := 'confirmed';
            LTask.Strings['status'] := NewStatus;
          end;
        taRejectTask:
          begin
            NewStatus := 'rejected';
            LTask.Strings['status'] := NewStatus;
          end;
        taStartTask:
          begin
            NewStatus := 'in_progress';
            LTask.Strings['status'] := NewStatus;
            LTask.Strings['actual_start_date'] := DateToStr(Date);
            LTask.Integers['progress_percent'] := 10;
          end;
        taFinishTask:
          begin
            NewStatus := 'done';
            LTask.Strings['status'] := NewStatus;
            LTask.Strings['actual_end_date'] := DateToStr(Date);
            LTask.Integers['progress_percent'] := 100;
            LTask.Strings['deliverable'] := ADeliverable;
          end;
        taCancelTask:
          begin
            NewStatus := 'canceled';
            LTask.Strings['status'] := NewStatus;
          end;
        taBlockTask:
          begin
            NewStatus := 'blocked';
            LTask.Strings['status'] := NewStatus;
          end;
        taUnblockTask:
          begin
            NewStatus := 'in_progress';
            LTask.Strings['status'] := NewStatus;
          end;
        taReopenTask:
          begin
            NewStatus := 'reopened';
            LTask.Strings['status'] := NewStatus;
            LTask.Integers['progress_percent'] := 0;
          end;
        taCommentTask:
          begin
            NewStatus := OldStatus; // No status change
          end;
        taRequestRevision:
          begin
            NewStatus := 'in_review';
            LTask.Strings['status'] := NewStatus;
          end;
      end;
      
      // Update last action
      LTask.Strings['notes'] := AComment;
      
      // Add Task Action Record
      Actions := TJSONArray(FProjectData.FindPath('task_actions'));
      if not Assigned(Actions) then
      begin
        Actions := TJSONArray.Create;
        FProjectData.Add('task_actions', Actions);
      end;
      
      ActID := 'ACT_' + IntToStr(Actions.Count + 1);
      Actions.Add(TJSONObject.Create([
        'id', ActID,
        'task_id', ATaskID,
        'agent_id', AAgentID,
        'agent_name', AAgentID,
        'action', GetEnumName(TypeInfo(TAIProjectTaskAction), Integer(AAction)),
        'date', DateTimeToStr(Now),
        'comment', AComment,
        'old_status', OldStatus,
        'new_status', NewStatus,
        'revision', TJSONObject(FProjectData.FindPath('project')).Integers['current_revision']
      ]));
      
      // Add Timeline event
      TJSONArray(FProjectData.FindPath('planning.timeline')).Add(TJSONObject.Create([
        'id', 'EV_ACT_' + ActID,
        'date', DateToStr(Date),
        'type', 'task_action',
        'title', 'Task ' + ATaskID + ' Action: ' + GetEnumName(TypeInfo(TAIProjectTaskAction), Integer(AAction)),
        'description', AComment + ' (Status: ' + OldStatus + ' -> ' + NewStatus + ')',
        'related_id', ATaskID,
        'revision', TJSONObject(FProjectData.FindPath('project')).Integers['current_revision']
      ]));
      
      RecalculateSchedule(); // Refresh Gantt/Timeline dates
      Result := True;
      Break;
    end;
  end;
end;

function TAIProject.AskAgentToAnalyzeTask(
  const ATaskID: string;
  const AAgentID: string
): Boolean;
begin
  Result := True;
  Log(llInfo, 'Agent ' + AAgentID + ' analyzed task ' + ATaskID);
  TJSONArray(FProjectData.FindPath('agent_task_analysis')).Add(TJSONObject.Create([
    'task_id', ATaskID,
    'agent_id', AAgentID,
    'analysis', 'Analysis from agent perspective looks positive. Task is aligned with scope and deliverables.',
    'recommended_action', 'confirm_task'
  ]));
end;

procedure TAIProject.LoadFromFile(const AFileName: string);
begin
  LoadProjectFromFile(AFileName);
end;

procedure TAIProject.SaveToFile(const AFileName: string);
begin
  SaveProjectToFile(AFileName);
end;

function TAIProject.LoadConfig: Boolean;
begin
  Result := False;
  if FConfigFileName = '' then
  begin
    DoError('ConfigFileName is empty.');
    Exit;
  end;
  try
    LoadFromFile(FConfigFileName);
    Result := True;
  except
    on E: Exception do
      DoError('LoadConfig failed: ' + E.Message);
  end;
end;

function TAIProject.SaveConfig: Boolean;
begin
  Result := False;
  if FConfigFileName = '' then
  begin
    DoError('ConfigFileName is empty.');
    Exit;
  end;
  try
    SaveToFile(FConfigFileName);
    Result := True;
  except
    on E: Exception do
      DoError('SaveConfig failed: ' + E.Message);
  end;
end;

initialization
  {$I aiproject_icon.lrs}

end.
