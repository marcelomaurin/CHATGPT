unit main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ComCtrls, StdCtrls,
  ExtCtrls, Grids, Buttons, Clipbrd, chatgpt, aiproject,
  aiproject_llmconfig, aiproject_storage, aiproject_documents, aiproject_tasks,
  aiproject_dependencies, aiproject_agents, aiproject_actions, aiproject_reports,
  aiproject_revisions, aiproject_taskgrid, aiproject_gantt, aiproject_timeline,
  aiproject_riskmatrix, aiproject_statuspanel, aiproject_agentmanager,
  aiproject_taskactionpanel, aiproject_reportviewer, aibase, fpjson, jsonparser;

type
  { TfrmMain }

  TfrmMain = class(TForm)
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
  private
    // UI Page Control
    FPageControl: TPageControl;
    
    // Tabs
    FTabConfig: TTabSheet;
    FTabDescription: TTabSheet;
    FTabAgileDocs: TTabSheet;
    FTabAgents: TTabSheet;
    FTabTasks: TTabSheet;
    FTabActions: TTabSheet;
    FTabDependencies: TTabSheet;
    FTabExecutionPlan: TTabSheet;
    FTabGantt: TTabSheet;
    FTabTimeline: TTabSheet;
    FTabRevision: TTabSheet;
    FTabJSON: TTabSheet;
    FTabLog: TTabSheet;

    // Components (from AI Project palette)
    FAIProject: TAIProject;
    FChatGPT: TCHATGPT;
    
    // Tab Config Controls
    FcbProvider: TComboBox;
    FedtToken: TEdit;
    FcbModel: TComboBox;
    FedtModelVersion: TEdit;
    FedtEndpoint: TEdit;
    FedtTemperature: TEdit;
    FedtMaxTokens: TEdit;
    FchkSaveToken: TCheckBox;
    FchkSimulation: TCheckBox;
    FbtnTestLLM: TButton;
    FbtnSaveConfig: TButton;
    FbtnLoadConfig: TButton;

    // Tab Description Controls
    FedtProjectName: TEdit;
    FmemoProjectGoal: TMemo;
    FmemoProjectContext: TMemo;
    FmemoScope: TMemo;
    FmemoConstraints: TMemo;
    FmemoDeliverables: TMemo;
    FedtProjectStart: TEdit;
    FedtTargetEnd: TEdit;
    FbtnGenerateInitialPlan: TButton;
    FbtnSaveProject: TButton;
    FbtnLoadProject: TButton;

    // Tab Agile Docs Controls
    FmemoBusinessVision: TMemo;
    FgridFunctional: TStringGrid;
    FgridNonFunctional: TStringGrid;
    FgridStakeholders: TStringGrid;
    FgridRiskMap: TStringGrid;
    FRiskMatrix: TAIRiskMatrix;
    FmemoEpics: TMemo;
    FmemoUserStories: TMemo;

    // Tab Agents Controls
    FlstAgents: TListBox;
    FedtAgentName: TEdit;
    FcbAgentProfile: TComboBox;
    FcbAgentSkillLevel: TComboBox;
    FmemoAgentDescription: TMemo;
    FmemoAgentResponsibilities: TMemo;
    FmemoAgentPrompt: TMemo;
    FchkAgentActive: TCheckBox;
    FbtnAddAgent: TButton;
    FbtnUpdateAgent: TButton;
    FbtnRemoveAgent: TButton;
    FbtnCreateDefaultAgents: TButton;

    // Tab Tasks Controls
    FgridTasks: TStringGrid;
    FbtnAddTask: TButton;
    FbtnEditTask: TButton;
    FbtnCancelTask: TButton;
    FbtnRecalculateEstimates: TButton;
    FbtnAskAgentToAnalyzeTask: TButton;

    // Tab Actions Controls
    FcbSelectedTask: TComboBox;
    FcbSelectedAgent: TComboBox;
    FcbTaskAction: TComboBox;
    FmemoActionComment: TMemo;
    FedtActionDeliverable: TEdit;
    FbtnApplyTaskAction: TButton;
    FmemoTaskActionHistory: TMemo;

    // Tab Dependencies Controls
    FlstSerialDependencies: TListBox;
    FlstParallelGroups: TListBox;
    FmemoDependencyExplanation: TMemo;

    // Tab Execution Plan Controls
    FmemoExecutionPlan: TMemo;
    FmemoMilestones: TMemo;

    // Tab Gantt Controls
    FpbGantt: TAIProjectGantt;
    FbtnRecalculateSchedule: TButton;

    // Tab Timeline Controls
    FpbTimeline: TAIProjectTimeline;
    FlstTimelineEvents: TListBox;
    FmemoTimelineDetails: TMemo;

    // Tab Revision Controls
    FmemoCorrection: TMemo;
    FbtnApplyCorrection: TButton;
    FlstRevisions: TListBox;
    FmemoRevisionDetails: TMemo;

    // Tab JSON Controls
    FmemoCurrentJSON: TMemo;
    FbtnCopyJSON: TButton;

    // Tab Log Controls
    FmemoLog: TMemo;
    FbtnClearLog: TButton;

    procedure OnLog(Sender: TObject; Level: TAILogLevel; const Message: string);
    procedure DoTestLLM(Sender: TObject);
    procedure DoSaveConfig(Sender: TObject);
    procedure DoLoadConfig(Sender: TObject);
    procedure DoGenerateInitialPlan(Sender: TObject);
    procedure DoSaveProject(Sender: TObject);
    procedure DoLoadProject(Sender: TObject);
    procedure DoCreateDefaultAgents(Sender: TObject);
    procedure DoAddAgent(Sender: TObject);
    procedure DoUpdateAgent(Sender: TObject);
    procedure DoRemoveAgent(Sender: TObject);
    procedure DoAddTask(Sender: TObject);
    procedure DoApplyTaskAction(Sender: TObject);
    procedure DoApplyCorrection(Sender: TObject);
    procedure DoCopyJSON(Sender: TObject);
    procedure DoClearLog(Sender: TObject);
    procedure DoRefreshTimeline(Sender: TObject);
    procedure OnRevisionsClick(Sender: TObject);
    procedure OnAgentsClick(Sender: TObject);
    
    procedure RefreshUI;
    procedure LoadGrids;
    procedure LoadTaskComboBoxes;
  public
  end;

var
  frmMain: TfrmMain;

implementation

{ TfrmMain }

procedure TfrmMain.FormCreate(Sender: TObject);
begin
  Caption := 'AI Project Manager Demo (TAIProject)';
  Width := 1024;
  Height := 768;
  Position := poScreenCenter;

  // Initialize components
  FChatGPT := TCHATGPT.Create(Self);
  FChatGPT.Name := 'ChatGPT';
  
  FAIProject := TAIProject.Create(Self);
  FAIProject.Name := 'AIProject';
  FAIProject.ChatGPT := FChatGPT;
  FAIProject.OnLog := @OnLog;
  
  // Tab control
  FPageControl := TPageControl.Create(Self);
  FPageControl.Parent := Self;
  FPageControl.Align := alClient;

  // 12 Tabs
  FTabConfig := FPageControl.AddTabSheet; FTabConfig.Caption := 'Configuration';
  FTabDescription := FPageControl.AddTabSheet; FTabDescription.Caption := 'Project Description';
  FTabAgileDocs := FPageControl.AddTabSheet; FTabAgileDocs.Caption := 'Agile Documents';
  FTabAgents := FPageControl.AddTabSheet; FTabAgents.Caption := 'Agents';
  FTabTasks := FPageControl.AddTabSheet; FTabTasks.Caption := 'Tasks';
  FTabActions := FPageControl.AddTabSheet; FTabActions.Caption := 'Task Actions';
  FTabDependencies := FPageControl.AddTabSheet; FTabDependencies.Caption := 'Dependencies';
  FTabExecutionPlan := FPageControl.AddTabSheet; FTabExecutionPlan.Caption := 'Execution Plan';
  FTabGantt := FPageControl.AddTabSheet; FTabGantt.Caption := 'Gantt';
  FTabTimeline := FPageControl.AddTabSheet; FTabTimeline.Caption := 'Timeline';
  FTabRevision := FPageControl.AddTabSheet; FTabRevision.Caption := 'Revision';
  FTabJSON := FPageControl.AddTabSheet; FTabJSON.Caption := 'JSON';
  FTabLog := FPageControl.AddTabSheet; FTabLog.Caption := 'Log';

  { Tab Config Setup }
  with TPanel.Create(Self) do
  begin
    Parent := FTabConfig;
    Align := alClient;
    BorderWidth := 10;
  end;

  FcbProvider := TComboBox.Create(Self);
  FcbProvider.Parent := FTabConfig;
  FcbProvider.SetBounds(20, 20, 200, 25);
  FcbProvider.Items.Add('OpenAI');
  FcbProvider.Items.Add('OpenRouter');
  FcbProvider.Items.Add('Cerebras');
  FcbProvider.Items.Add('Local (Ollama)');
  FcbProvider.Items.Add('Gemini');
  FcbProvider.Items.Add('Claude');
  FcbProvider.ItemIndex := 3; // Local (Ollama) default

  FedtToken := TEdit.Create(Self);
  FedtToken.Parent := FTabConfig;
  FedtToken.SetBounds(20, 60, 200, 25);
  FedtToken.TextHint := 'API Token / Key';

  FcbModel := TComboBox.Create(Self);
  FcbModel.Parent := FTabConfig;
  FcbModel.SetBounds(20, 100, 200, 25);
  FcbModel.Items.Add('llama3.2');
  FcbModel.Items.Add('deepseek-r1:8b');
  FcbModel.Items.Add('gpt-4o-mini');
  FcbModel.Items.Add('gemini-2.5-flash');
  FcbModel.ItemIndex := 0;

  FedtModelVersion := TEdit.Create(Self);
  FedtModelVersion.Parent := FTabConfig;
  FedtModelVersion.SetBounds(20, 140, 200, 25);
  FedtModelVersion.Text := '1.0';

  FedtEndpoint := TEdit.Create(Self);
  FedtEndpoint.Parent := FTabConfig;
  FedtEndpoint.SetBounds(20, 180, 200, 25);
  FedtEndpoint.Text := 'http://localhost:11434';

  FedtTemperature := TEdit.Create(Self);
  FedtTemperature.Parent := FTabConfig;
  FedtTemperature.SetBounds(20, 220, 200, 25);
  FedtTemperature.Text := '0.2';

  FedtMaxTokens := TEdit.Create(Self);
  FedtMaxTokens.Parent := FTabConfig;
  FedtMaxTokens.SetBounds(20, 260, 200, 25);
  FedtMaxTokens.Text := '8000';

  FchkSaveToken := TCheckBox.Create(Self);
  FchkSaveToken.Parent := FTabConfig;
  FchkSaveToken.SetBounds(20, 300, 200, 25);
  FchkSaveToken.Caption := 'Save API Token to file';

  FchkSimulation := TCheckBox.Create(Self);
  FchkSimulation.Parent := FTabConfig;
  FchkSimulation.SetBounds(20, 330, 200, 25);
  FchkSimulation.Caption := 'Simulation Mode (Mock Offline)';
  FchkSimulation.Checked := True;

  FbtnTestLLM := TButton.Create(Self);
  FbtnTestLLM.Parent := FTabConfig;
  FbtnTestLLM.SetBounds(20, 370, 150, 30);
  FbtnTestLLM.Caption := 'Test LLM Connection';
  FbtnTestLLM.OnClick := @DoTestLLM;

  FbtnSaveConfig := TButton.Create(Self);
  FbtnSaveConfig.Parent := FTabConfig;
  FbtnSaveConfig.SetBounds(180, 370, 150, 30);
  FbtnSaveConfig.Caption := 'Save Configuration';
  FbtnSaveConfig.OnClick := @DoSaveConfig;

  FbtnLoadConfig := TButton.Create(Self);
  FbtnLoadConfig.Parent := FTabConfig;
  FbtnLoadConfig.SetBounds(340, 370, 150, 30);
  FbtnLoadConfig.Caption := 'Load Configuration';
  FbtnLoadConfig.OnClick := @DoLoadConfig;

  { Tab Description Setup }
  FedtProjectName := TEdit.Create(Self);
  FedtProjectName.Parent := FTabDescription;
  FedtProjectName.SetBounds(20, 20, 400, 25);
  FedtProjectName.Text := 'Lazarus Audio Capturer Component';

  FmemoProjectGoal := TMemo.Create(Self);
  FmemoProjectGoal.Parent := FTabDescription;
  FmemoProjectGoal.SetBounds(20, 60, 400, 60);
  FmemoProjectGoal.Text := 'I want to create a Lazarus component that captures real audio from the microphone, saves it as WAV, validates the generated file and provides a visual demo without simulation mode.';

  FmemoProjectContext := TMemo.Create(Self);
  FmemoProjectContext.Parent := FTabDescription;
  FmemoProjectContext.SetBounds(20, 130, 400, 60);
  FmemoProjectContext.Text := 'Lazarus 3.x and Free Pascal on Windows and Linux.';

  FmemoScope := TMemo.Create(Self);
  FmemoScope.Parent := FTabDescription;
  FmemoScope.SetBounds(20, 200, 400, 60);
  FmemoScope.Text := 'Includes TAIAudioInput component, sound filters, arecord and WASAPI drivers.';

  FmemoConstraints := TMemo.Create(Self);
  FmemoConstraints.Parent := FTabDescription;
  FmemoConstraints.SetBounds(20, 270, 400, 60);
  FmemoConstraints.Text := 'No simulation mode allowed for audio capture in final demo.';

  FmemoDeliverables := TMemo.Create(Self);
  FmemoDeliverables.Parent := FTabDescription;
  FmemoDeliverables.SetBounds(20, 340, 400, 60);
  FmemoDeliverables.Text := 'Component package, WAV validation utility, GUI test sample.';

  FedtProjectStart := TEdit.Create(Self);
  FedtProjectStart.Parent := FTabDescription;
  FedtProjectStart.SetBounds(20, 410, 190, 25);
  FedtProjectStart.Text := DateToStr(Date);
  FedtProjectStart.TextHint := 'Start Date (YYYY-MM-DD)';

  FedtTargetEnd := TEdit.Create(Self);
  FedtTargetEnd.Parent := FTabDescription;
  FedtTargetEnd.SetBounds(220, 410, 200, 25);
  FedtTargetEnd.Text := DateToStr(Date + 30);
  FedtTargetEnd.TextHint := 'Target End Date (YYYY-MM-DD)';

  FbtnGenerateInitialPlan := TButton.Create(Self);
  FbtnGenerateInitialPlan.Parent := FTabDescription;
  FbtnGenerateInitialPlan.SetBounds(20, 450, 180, 30);
  FbtnGenerateInitialPlan.Caption := 'Generate Plan with IA';
  FbtnGenerateInitialPlan.OnClick := @DoGenerateInitialPlan;

  FbtnSaveProject := TButton.Create(Self);
  FbtnSaveProject.Parent := FTabDescription;
  FbtnSaveProject.SetBounds(210, 450, 150, 30);
  FbtnSaveProject.Caption := 'Save Project';
  FbtnSaveProject.OnClick := @DoSaveProject;

  FbtnLoadProject := TButton.Create(Self);
  FbtnLoadProject.Parent := FTabDescription;
  FbtnLoadProject.SetBounds(370, 450, 150, 30);
  FbtnLoadProject.Caption := 'Load Project';
  FbtnLoadProject.OnClick := @DoLoadProject;

  { Tab Agile Docs Setup }
  FmemoBusinessVision := TMemo.Create(Self);
  FmemoBusinessVision.Parent := FTabAgileDocs;
  FmemoBusinessVision.SetBounds(20, 20, 300, 100);
  FmemoBusinessVision.TextHint := 'Business Vision';

  FgridFunctional := TStringGrid.Create(Self);
  FgridFunctional.Parent := FTabAgileDocs;
  FgridFunctional.SetBounds(20, 130, 300, 120);
  FgridFunctional.ColCount := 3;
  FgridFunctional.FixedCols := 0;
  FgridFunctional.Cells[0, 0] := 'ID';
  FgridFunctional.Cells[1, 0] := 'Requirement';
  FgridFunctional.Cells[2, 0] := 'Priority';

  FgridNonFunctional := TStringGrid.Create(Self);
  FgridNonFunctional.Parent := FTabAgileDocs;
  FgridNonFunctional.SetBounds(20, 260, 300, 120);
  FgridNonFunctional.ColCount := 3;
  FgridNonFunctional.FixedCols := 0;
  FgridNonFunctional.Cells[0, 0] := 'ID';
  FgridNonFunctional.Cells[1, 0] := 'Req';
  FgridNonFunctional.Cells[2, 0] := 'Priority';

  FgridStakeholders := TStringGrid.Create(Self);
  FgridStakeholders.Parent := FTabAgileDocs;
  FgridStakeholders.SetBounds(340, 20, 300, 100);
  FgridStakeholders.ColCount := 3;
  FgridStakeholders.FixedCols := 0;
  FgridStakeholders.Cells[0, 0] := 'Name';
  FgridStakeholders.Cells[1, 0] := 'Role';
  FgridStakeholders.Cells[2, 0] := 'Responsibility';

  FgridRiskMap := TStringGrid.Create(Self);
  FgridRiskMap.Parent := FTabAgileDocs;
  FgridRiskMap.SetBounds(340, 130, 300, 120);
  FgridRiskMap.ColCount := 4;
  FgridRiskMap.FixedCols := 0;
  FgridRiskMap.Cells[0, 0] := 'ID';
  FgridRiskMap.Cells[1, 0] := 'Risk';
  FgridRiskMap.Cells[2, 0] := 'Impact';
  FgridRiskMap.Cells[3, 0] := 'Probability';

  FRiskMatrix := TAIRiskMatrix.Create(Self);
  FRiskMatrix.Parent := FTabAgileDocs;
  FRiskMatrix.SetBounds(660, 20, 220, 220);
  FRiskMatrix.Project := FAIProject;

  FmemoEpics := TMemo.Create(Self);
  FmemoEpics.Parent := FTabAgileDocs;
  FmemoEpics.SetBounds(340, 260, 300, 120);
  FmemoEpics.TextHint := 'Epics';

  { Tab Agents Setup }
  FlstAgents := TListBox.Create(Self);
  FlstAgents.Parent := FTabAgents;
  FlstAgents.SetBounds(20, 20, 150, 300);
  FlstAgents.OnClick := @OnAgentsClick;

  FedtAgentName := TEdit.Create(Self);
  FedtAgentName.Parent := FTabAgents;
  FedtAgentName.SetBounds(180, 20, 200, 25);
  FedtAgentName.TextHint := 'Agent Name';

  FcbAgentProfile := TComboBox.Create(Self);
  FcbAgentProfile.Parent := FTabAgents;
  FcbAgentProfile.SetBounds(180, 60, 200, 25);
  FcbAgentProfile.Items.Add('UI');
  FcbAgentProfile.Items.Add('DBA');
  FcbAgentProfile.Items.Add('DEV');
  FcbAgentProfile.Items.Add('Infra');
  FcbAgentProfile.Items.Add('Operador');
  FcbAgentProfile.Items.Add('Key User');
  FcbAgentProfile.Items.Add('Tester');
  FcbAgentProfile.Items.Add('Documentador');
  FcbAgentProfile.Items.Add('Gerente de Projeto');
  FcbAgentProfile.ItemIndex := 2;

  FcbAgentSkillLevel := TComboBox.Create(Self);
  FcbAgentSkillLevel.Parent := FTabAgents;
  FcbAgentSkillLevel.SetBounds(180, 100, 200, 25);
  FcbAgentSkillLevel.Items.Add('intern');
  FcbAgentSkillLevel.Items.Add('junior');
  FcbAgentSkillLevel.Items.Add('mid_level');
  FcbAgentSkillLevel.Items.Add('senior');
  FcbAgentSkillLevel.ItemIndex := 3;

  FmemoAgentDescription := TMemo.Create(Self);
  FmemoAgentDescription.Parent := FTabAgents;
  FmemoAgentDescription.SetBounds(180, 140, 200, 60);
  FmemoAgentDescription.TextHint := 'Agent Description';

  FmemoAgentResponsibilities := TMemo.Create(Self);
  FmemoAgentResponsibilities.Parent := FTabAgents;
  FmemoAgentResponsibilities.SetBounds(180, 210, 200, 60);
  FmemoAgentResponsibilities.TextHint := 'Responsibilities';

  FmemoAgentPrompt := TMemo.Create(Self);
  FmemoAgentPrompt.Parent := FTabAgents;
  FmemoAgentPrompt.SetBounds(390, 20, 300, 180);
  FmemoAgentPrompt.TextHint := 'Agent System Prompt';

  FchkAgentActive := TCheckBox.Create(Self);
  FchkAgentActive.Parent := FTabAgents;
  FchkAgentActive.SetBounds(390, 210, 200, 25);
  FchkAgentActive.Caption := 'Agent Active';
  FchkAgentActive.Checked := True;

  FbtnAddAgent := TButton.Create(Self);
  FbtnAddAgent.Parent := FTabAgents;
  FbtnAddAgent.SetBounds(180, 290, 90, 30);
  FbtnAddAgent.Caption := 'Add Agent';
  FbtnAddAgent.OnClick := @DoAddAgent;

  FbtnUpdateAgent := TButton.Create(Self);
  FbtnUpdateAgent.Parent := FTabAgents;
  FbtnUpdateAgent.SetBounds(280, 290, 90, 30);
  FbtnUpdateAgent.Caption := 'Update';
  FbtnUpdateAgent.OnClick := @DoUpdateAgent;

  FbtnRemoveAgent := TButton.Create(Self);
  FbtnRemoveAgent.Parent := FTabAgents;
  FbtnRemoveAgent.SetBounds(380, 290, 90, 30);
  FbtnRemoveAgent.Caption := 'Remove';
  FbtnRemoveAgent.OnClick := @DoRemoveAgent;

  FbtnCreateDefaultAgents := TButton.Create(Self);
  FbtnCreateDefaultAgents.Parent := FTabAgents;
  FbtnCreateDefaultAgents.SetBounds(480, 290, 150, 30);
  FbtnCreateDefaultAgents.Caption := 'Create Default Agents';
  FbtnCreateDefaultAgents.OnClick := @DoCreateDefaultAgents;

  { Tab Tasks Setup }
  FgridTasks := TStringGrid.Create(Self);
  FgridTasks.Parent := FTabTasks;
  FgridTasks.SetBounds(20, 20, 800, 300);
  FgridTasks.ColCount := 9;
  FgridTasks.FixedCols := 0;
  FgridTasks.Cells[0, 0] := 'ID';
  FgridTasks.Cells[1, 0] := 'Task Title';
  FgridTasks.Cells[2, 0] := 'Status';
  FgridTasks.Cells[3, 0] := 'Priority';
  FgridTasks.Cells[4, 0] := 'Assigned Agent';
  FgridTasks.Cells[5, 0] := 'Profile';
  FgridTasks.Cells[6, 0] := 'Start Date';
  FgridTasks.Cells[7, 0] := 'End Date';
  FgridTasks.Cells[8, 0] := 'Progress';

  FbtnAddTask := TButton.Create(Self);
  FbtnAddTask.Parent := FTabTasks;
  FbtnAddTask.SetBounds(20, 335, 120, 30);
  FbtnAddTask.Caption := 'Add Task';
  FbtnAddTask.OnClick := @DoAddTask;

  FbtnCancelTask := TButton.Create(Self);
  FbtnCancelTask.Parent := FTabTasks;
  FbtnCancelTask.SetBounds(150, 335, 120, 30);
  FbtnCancelTask.Caption := 'Cancel Task';

  { Tab Actions Setup }
  FcbSelectedTask := TComboBox.Create(Self);
  FcbSelectedTask.Parent := FTabActions;
  FcbSelectedTask.SetBounds(20, 20, 200, 25);
  FcbSelectedTask.TextHint := 'Select Task';

  FcbSelectedAgent := TComboBox.Create(Self);
  FcbSelectedAgent.Parent := FTabActions;
  FcbSelectedAgent.SetBounds(20, 60, 200, 25);
  FcbSelectedAgent.TextHint := 'Select Agent';

  FcbTaskAction := TComboBox.Create(Self);
  FcbTaskAction.Parent := FTabActions;
  FcbTaskAction.SetBounds(20, 100, 200, 25);
  FcbTaskAction.Items.Add('Confirm Task');
  FcbTaskAction.Items.Add('Reject Task');
  FcbTaskAction.Items.Add('Start Task');
  FcbTaskAction.Items.Add('Finish Task');
  FcbTaskAction.Items.Add('Cancel Task');
  FcbTaskAction.Items.Add('Block Task');
  FcbTaskAction.Items.Add('Unblock Task');
  FcbTaskAction.Items.Add('Reopen Task');
  FcbTaskAction.ItemIndex := 2; // Start Task

  FmemoActionComment := TMemo.Create(Self);
  FmemoActionComment.Parent := FTabActions;
  FmemoActionComment.SetBounds(20, 140, 250, 80);
  FmemoActionComment.TextHint := 'Action Comment';

  FedtActionDeliverable := TEdit.Create(Self);
  FedtActionDeliverable.Parent := FTabActions;
  FedtActionDeliverable.SetBounds(20, 230, 250, 25);
  FedtActionDeliverable.TextHint := 'Deliverable (for finish action)';

  FbtnApplyTaskAction := TButton.Create(Self);
  FbtnApplyTaskAction.Parent := FTabActions;
  FbtnApplyTaskAction.SetBounds(20, 270, 150, 30);
  FbtnApplyTaskAction.Caption := 'Apply Task Action';
  FbtnApplyTaskAction.OnClick := @DoApplyTaskAction;

  FmemoTaskActionHistory := TMemo.Create(Self);
  FmemoTaskActionHistory.Parent := FTabActions;
  FmemoTaskActionHistory.SetBounds(300, 20, 400, 280);
  FmemoTaskActionHistory.ScrollBars := ssAutoBoth;
  FmemoTaskActionHistory.TextHint := 'Action History Log';

  { Tab Dependencies Controls }
  FlstSerialDependencies := TListBox.Create(Self);
  FlstSerialDependencies.Parent := FTabDependencies;
  FlstSerialDependencies.SetBounds(20, 20, 200, 200);

  FlstParallelGroups := TListBox.Create(Self);
  FlstParallelGroups.Parent := FTabDependencies;
  FlstParallelGroups.SetBounds(240, 20, 200, 200);

  FmemoDependencyExplanation := TMemo.Create(Self);
  FmemoDependencyExplanation.Parent := FTabDependencies;
  FmemoDependencyExplanation.SetBounds(20, 240, 420, 100);

  { Tab Execution Plan Setup }
  FmemoExecutionPlan := TMemo.Create(Self);
  FmemoExecutionPlan.Parent := FTabExecutionPlan;
  FmemoExecutionPlan.SetBounds(20, 20, 400, 250);

  FmemoMilestones := TMemo.Create(Self);
  FmemoMilestones.Parent := FTabExecutionPlan;
  FmemoMilestones.SetBounds(440, 20, 400, 250);

  { Tab Gantt Setup }
  FpbGantt := TAIProjectGantt.Create(Self);
  FpbGantt.Parent := FTabGantt;
  FpbGantt.SetBounds(20, 20, 700, 350);
  FpbGantt.Project := FAIProject;

  FbtnRecalculateSchedule := TButton.Create(Self);
  FbtnRecalculateSchedule.Parent := FTabGantt;
  FbtnRecalculateSchedule.SetBounds(20, 385, 180, 30);
  FbtnRecalculateSchedule.Caption := 'Recalculate Schedule';
  FbtnRecalculateSchedule.OnClick := @DoRefreshTimeline;

  { Tab Timeline Setup }
  FpbTimeline := TAIProjectTimeline.Create(Self);
  FpbTimeline.Parent := FTabTimeline;
  FpbTimeline.SetBounds(20, 20, 500, 350);
  FpbTimeline.Project := FAIProject;

  FlstTimelineEvents := TListBox.Create(Self);
  FlstTimelineEvents.Parent := FTabTimeline;
  FlstTimelineEvents.SetBounds(540, 20, 250, 200);

  FmemoTimelineDetails := TMemo.Create(Self);
  FmemoTimelineDetails.Parent := FTabTimeline;
  FmemoTimelineDetails.SetBounds(540, 230, 250, 140);

  { Tab Revision Setup }
  FmemoCorrection := TMemo.Create(Self);
  FmemoCorrection.Parent := FTabRevision;
  FmemoCorrection.SetBounds(20, 20, 400, 80);
  FmemoCorrection.TextHint := 'Enter project correction description here... (e.g. Add Linux backend using arecord)';

  FbtnApplyCorrection := TButton.Create(Self);
  FbtnApplyCorrection.Parent := FTabRevision;
  FbtnApplyCorrection.SetBounds(20, 110, 180, 30);
  FbtnApplyCorrection.Caption := 'Apply Project Correction';
  FbtnApplyCorrection.OnClick := @DoApplyCorrection;

  FlstRevisions := TListBox.Create(Self);
  FlstRevisions.Parent := FTabRevision;
  FlstRevisions.SetBounds(20, 150, 400, 150);
  FlstRevisions.OnClick := @OnRevisionsClick;

  FmemoRevisionDetails := TMemo.Create(Self);
  FmemoRevisionDetails.Parent := FTabRevision;
  FmemoRevisionDetails.SetBounds(440, 20, 400, 280);
  FmemoRevisionDetails.ScrollBars := ssAutoBoth;

  { Tab JSON Setup }
  FmemoCurrentJSON := TMemo.Create(Self);
  FmemoCurrentJSON.Parent := FTabJSON;
  FmemoCurrentJSON.Align := alClient;
  FmemoCurrentJSON.ScrollBars := ssAutoBoth;

  TPanel.Create(Self); // placeholder/spacing
  FbtnCopyJSON := TButton.Create(Self);
  FbtnCopyJSON.Parent := FTabJSON;
  FbtnCopyJSON.SetBounds(10, 10, 100, 25);
  FbtnCopyJSON.Caption := 'Copy JSON';
  FbtnCopyJSON.OnClick := @DoCopyJSON;

  { Tab Log Setup }
  FmemoLog := TMemo.Create(Self);
  FmemoLog.Parent := FTabLog;
  FmemoLog.Align := alClient;
  FmemoLog.ScrollBars := ssAutoBoth;

  FbtnClearLog := TButton.Create(Self);
  FbtnClearLog.Parent := FTabLog;
  FbtnClearLog.SetBounds(10, 10, 100, 25);
  FbtnClearLog.Caption := 'Clear Log';
  FbtnClearLog.OnClick := @DoClearLog;
  
  DoCreateDefaultAgents(nil);
  RefreshUI;
end;

procedure TfrmMain.FormDestroy(Sender: TObject);
begin
  // Handled by Lazarus owner management
end;

procedure TfrmMain.OnLog(Sender: TObject; Level: TAILogLevel; const Message: string);
var
  LvlStr: string;
begin
  case Level of
    llDebug: LvlStr := '[DEBUG] ';
    llInfo: LvlStr := '[INFO] ';
    llWarning: LvlStr := '[WARNING] ';
    llError: LvlStr := '[ERROR] ';
  end;
  FmemoLog.Lines.Add(LvlStr + Message);
end;

procedure TfrmMain.DoTestLLM(Sender: TObject);
begin
  FAIProject.DefaultProvider := TAIProvider(FcbProvider.ItemIndex);
  FAIProject.Token := FedtToken.Text;
  FAIProject.DefaultModel := FcbModel.Text;
  FAIProject.LocalURL := FedtEndpoint.Text;
  FAIProject.SimulationMode := FchkSimulation.Checked;
  
  if FAIProject.TestConnection then
    ShowMessage('LLM Connection Successful!')
  else
    ShowMessage('Connection failed: ' + FAIProject.LastError);
end;

procedure TfrmMain.DoSaveConfig(Sender: TObject);
begin
  FAIProject.DefaultProvider := TAIProvider(FcbProvider.ItemIndex);
  FAIProject.Token := FedtToken.Text;
  FAIProject.DefaultModel := FcbModel.Text;
  FAIProject.LocalURL := FedtEndpoint.Text;
  FAIProject.SimulationMode := FchkSimulation.Checked;
  FAIProject.SaveToken := FchkSaveToken.Checked;
  FAIProject.ConfigFileName := ExtractFilePath(Application.ExeName) + 'llm_config.json';
  
  if FAIProject.SaveConfig then
    ShowMessage('LLM Configuration Saved to ' + FAIProject.ConfigFileName)
  else
    ShowMessage('Save config failed: ' + FAIProject.LastError);
end;

procedure TfrmMain.DoLoadConfig(Sender: TObject);
begin
  FAIProject.ConfigFileName := ExtractFilePath(Application.ExeName) + 'llm_config.json';
  if FAIProject.LoadConfig then
  begin
    FcbProvider.ItemIndex := Integer(FAIProject.DefaultProvider);
    FedtToken.Text := FAIProject.Token;
    FcbModel.Text := FAIProject.DefaultModel;
    FedtEndpoint.Text := FAIProject.LocalURL;
    FchkSimulation.Checked := FAIProject.SimulationMode;
    FchkSaveToken.Checked := FAIProject.SaveToken;
    ShowMessage('LLM Configuration Loaded.');
  end
  else
    ShowMessage('Load config failed: ' + FAIProject.LastError);
end;

procedure TfrmMain.DoGenerateInitialPlan(Sender: TObject);
var
  dtS, dtE: TDateTime;
begin
  // Set properties from fields
  FAIProject.ProjectName := FedtProjectName.Text;
  FAIProject.Goal := FmemoProjectGoal.Text;
  FAIProject.Description := FmemoProjectGoal.Text;
  FAIProject.Context := FmemoProjectContext.Text;
  FAIProject.Scope := FmemoScope.Text;
  FAIProject.Constraints := FmemoConstraints.Text;
  FAIProject.ExpectedDeliverables := FmemoDeliverables.Text;
  
  if TryStrToDate(FedtProjectStart.Text, dtS) then FAIProject.StartDate := dtS;
  if TryStrToDate(FedtTargetEnd.Text, dtE) then FAIProject.TargetEndDate := dtE;
  
  FAIProject.SimulationMode := FchkSimulation.Checked;
  FAIProject.DefaultProvider := TAIProvider(FcbProvider.ItemIndex);
  FAIProject.Token := FedtToken.Text;
  FAIProject.DefaultModel := FcbModel.Text;
  FAIProject.LocalURL := FedtEndpoint.Text;

  if FAIProject.GenerateInitialPlan then
  begin
    ShowMessage('Initial project plan generated successfully!');
    RefreshUI;
  end
  else
    ShowMessage('Failed to generate plan: ' + FAIProject.LastError);
end;

procedure TfrmMain.DoSaveProject(Sender: TObject);
var
  SaveDialog: TSaveDialog;
begin
  SaveDialog := TSaveDialog.Create(nil);
  try
    SaveDialog.Filter := 'AI Project Files (*.aiproj.json)|*.aiproj.json';
    SaveDialog.InitialDir := ExtractFilePath(Application.ExeName);
    if SaveDialog.Execute then
    begin
      if FAIProject.SaveProjectToFile(SaveDialog.FileName) then
        ShowMessage('Project saved successfully.')
      else
        ShowMessage('Failed to save project: ' + FAIProject.LastError);
    end;
  finally
    SaveDialog.Free;
  end;
end;

procedure TfrmMain.DoLoadProject(Sender: TObject);
var
  OpenDialog: TOpenDialog;
begin
  OpenDialog := TOpenDialog.Create(nil);
  try
    OpenDialog.Filter := 'AI Project Files (*.aiproj.json)|*.aiproj.json';
    OpenDialog.InitialDir := ExtractFilePath(Application.ExeName);
    if OpenDialog.Execute then
    begin
      if FAIProject.LoadProjectFromFile(OpenDialog.FileName) then
      begin
        // Update Description Fields
        FedtProjectName.Text := FAIProject.ProjectName;
        FmemoProjectGoal.Text := FAIProject.Goal;
        FmemoProjectContext.Text := FAIProject.Context;
        FmemoScope.Text := FAIProject.Scope;
        FmemoConstraints.Text := FAIProject.Constraints;
        FmemoDeliverables.Text := FAIProject.ExpectedDeliverables;
        FedtProjectStart.Text := DateToStr(FAIProject.StartDate);
        FedtTargetEnd.Text := DateToStr(FAIProject.TargetEndDate);
        
        ShowMessage('Project loaded successfully.');
        RefreshUI;
      end;
    end;
  finally
    OpenDialog.Free;
  end;
end;

procedure TfrmMain.DoCreateDefaultAgents(Sender: TObject);
var
  Agents: TJSONArray;
begin
  Agents := TJSONArray(FAIProject.ProjectData.FindPath('agents'));
  if not Assigned(Agents) then Exit;
  
  Agents.Clear;
  Agents.Add(TJSONObject.Create(['id', 'AG001', 'name', 'UI Agent', 'profile', 'UI', 'description', 'Specialist in screen flow', 'skill_level', 'senior', 'active', true]));
  Agents.Add(TJSONObject.Create(['id', 'AG002', 'name', 'DBA Agent', 'profile', 'DBA', 'description', 'Specialist in database & storage', 'skill_level', 'senior', 'active', true]));
  Agents.Add(TJSONObject.Create(['id', 'AG003', 'name', 'DEV Agent', 'profile', 'DEV', 'description', 'Software Developer', 'skill_level', 'mid_level', 'active', true]));
  Agents.Add(TJSONObject.Create(['id', 'AG004', 'name', 'Infra Agent', 'profile', 'Infra', 'description', 'Deployment expert', 'skill_level', 'senior', 'active', true]));
  Agents.Add(TJSONObject.Create(['id', 'AG005', 'name', 'Tester Agent', 'profile', 'Tester', 'description', 'QA validation', 'skill_level', 'junior', 'active', true]));
  Agents.Add(TJSONObject.Create(['id', 'AG006', 'name', 'Project Manager', 'profile', 'Gerente de Projeto', 'description', 'Coordinates the team', 'skill_level', 'senior', 'active', true]));

  RefreshUI;
end;

procedure TfrmMain.DoAddAgent(Sender: TObject);
var
  Agents: TJSONArray;
  AgentObj: TJSONObject;
begin
  Agents := TJSONArray(FAIProject.ProjectData.FindPath('agents'));
  if not Assigned(Agents) then Exit;
  
  AgentObj := TJSONObject.Create([
    'id', 'AG' + IntToStr(Agents.Count + 1),
    'name', FedtAgentName.Text,
    'profile', FcbAgentProfile.Text,
    'description', FmemoAgentDescription.Text,
    'skill_level', FcbAgentSkillLevel.Text,
    'active', FchkAgentActive.Checked
  ]);
  Agents.Add(AgentObj);
  RefreshUI;
end;

procedure TfrmMain.DoUpdateAgent(Sender: TObject);
var
  Agents: TJSONArray;
  AgentObj: TJSONObject;
  Idx: Integer;
begin
  Idx := FlstAgents.ItemIndex;
  if Idx < 0 then Exit;
  Agents := TJSONArray(FAIProject.ProjectData.FindPath('agents'));
  if not Assigned(Agents) then Exit;
  
  AgentObj := Agents.Objects[Idx];
  AgentObj.Strings['name'] := FedtAgentName.Text;
  AgentObj.Strings['profile'] := FcbAgentProfile.Text;
  AgentObj.Strings['description'] := FmemoAgentDescription.Text;
  AgentObj.Strings['skill_level'] := FcbAgentSkillLevel.Text;
  AgentObj.Booleans['active'] := FchkAgentActive.Checked;
  
  RefreshUI;
end;

procedure TfrmMain.DoRemoveAgent(Sender: TObject);
var
  Agents: TJSONArray;
  Idx: Integer;
begin
  Idx := FlstAgents.ItemIndex;
  if Idx < 0 then Exit;
  Agents := TJSONArray(FAIProject.ProjectData.FindPath('agents'));
  if Assigned(Agents) then
  begin
    Agents.Delete(Idx);
    RefreshUI;
  end;
end;

procedure TfrmMain.DoAddTask(Sender: TObject);
var
  Tasks: TJSONArray;
begin
  Tasks := TJSONArray(FAIProject.ProjectData.FindPath('planning.tasks'));
  if not Assigned(Tasks) then Exit;
  
  Tasks.Add(TJSONObject.Create([
    'id', 'T00' + IntToStr(Tasks.Count + 1),
    'epic_id', 'E001',
    'title', 'New Custom Task',
    'description', 'Added by user manually.',
    'acceptance_criteria', 'Custom criteria',
    'priority', 'medium',
    'status', 'draft',
    'dependency_type', 'serial',
    'dependencies', TJSONArray.Create,
    'can_run_in_parallel', false,
    'estimated_hours', TJSONObject.Create(['intern', 12, 'junior', 8, 'mid_level', 4, 'senior', 2]),
    'suggested_skill_level', 'mid_level',
    'assigned_skill_level', 'mid_level',
    'assigned_to', 'DEV Agent',
    'responsible_profile', 'DEV',
    'estimated_duration_days', 1,
    'deliverable', 'Layout',
    'notes', '',
    'revision_created', 1,
    'revision_updated', 1
  ]));
  
  FAIProject.RecalculateSchedule;
  RefreshUI;
end;

procedure TfrmMain.DoApplyTaskAction(Sender: TObject);
var
  TaskID, AgentID, Comm, Deliv: string;
  TaskAct: TAIProjectTaskAction;
begin
  if FcbSelectedTask.ItemIndex < 0 then Exit;
  TaskID := FcbSelectedTask.Text;
  AgentID := FcbSelectedAgent.Text;
  TaskAct := TAIProjectTaskAction(FcbTaskAction.ItemIndex);
  Comm := FmemoActionComment.Text;
  Deliv := FedtActionDeliverable.Text;
  
  if FAIProject.ApplyTaskAction(TaskID, AgentID, TaskAct, Comm, Deliv) then
  begin
    ShowMessage('Action applied successfully!');
    RefreshUI;
  end
  else
    ShowMessage('Action failed.');
end;

procedure TfrmMain.DoApplyCorrection(Sender: TObject);
begin
  if FAIProject.ApplyProjectCorrection(FmemoCorrection.Text) then
  begin
    ShowMessage('Correction applied and revision created successfully!');
    RefreshUI;
  end
  else
    ShowMessage('Failed to apply correction: ' + FAIProject.LastError);
end;

procedure TfrmMain.DoCopyJSON(Sender: TObject);
begin
  Clipboard.AsText := FmemoCurrentJSON.Text;
  ShowMessage('JSON copied to Clipboard.');
end;

procedure TfrmMain.DoClearLog(Sender: TObject);
begin
  FmemoLog.Clear;
end;

procedure TfrmMain.DoRefreshTimeline(Sender: TObject);
begin
  FAIProject.RecalculateSchedule;
  RefreshUI;
end;

procedure TfrmMain.OnRevisionsClick(Sender: TObject);
var
  Idx: Integer;
begin
  Idx := FlstRevisions.ItemIndex;
  if Idx >= 0 then
    FmemoRevisionDetails.Text := FAIProject.GetRevisionMarkdown(Idx);
end;

procedure TfrmMain.OnAgentsClick(Sender: TObject);
var
  Agents: TJSONArray;
  AgentObj: TJSONObject;
  Idx: Integer;
begin
  Idx := FlstAgents.ItemIndex;
  if Idx < 0 then Exit;
  Agents := TJSONArray(FAIProject.ProjectData.FindPath('agents'));
  if not Assigned(Agents) then Exit;
  
  AgentObj := Agents.Objects[Idx];
  FedtAgentName.Text := AgentObj.Strings['name'];
  FcbAgentProfile.ItemIndex := FcbAgentProfile.Items.IndexOf(AgentObj.Strings['profile']);
  FcbAgentSkillLevel.ItemIndex := FcbAgentSkillLevel.Items.IndexOf(AgentObj.Strings['skill_level']);
  FmemoAgentDescription.Text := AgentObj.Strings['description'];
  FchkAgentActive.Checked := AgentObj.Booleans['active'];
end;

procedure TfrmMain.RefreshUI;
begin
  LoadGrids;
  LoadTaskComboBoxes;
  FpbGantt.Invalidate;
  FRiskMatrix.Invalidate;
  FpbTimeline.Invalidate;
  FmemoCurrentJSON.Text := FAIProject.ExportPlanToJSON;
end;

procedure TfrmMain.LoadGrids;
var
  Funcs, NonFunc, Stakeh, Risks, Tasks, Timeline, Revisions: TJSONArray;
  Obj: TJSONObject;
  i: Integer;
begin
  // Clean Functional
  FgridFunctional.RowCount := 1;
  Funcs := TJSONArray(FAIProject.ProjectData.FindPath('agile_documents.functional_requirements'));
  if Assigned(Funcs) then
  begin
    FgridFunctional.RowCount := Funcs.Count + 1;
    for i := 0 to Funcs.Count - 1 do
    begin
      Obj := Funcs.Objects[i];
      FgridFunctional.Cells[0, i + 1] := Obj.Strings['id'];
      FgridFunctional.Cells[1, i + 1] := Obj.Strings['title'];
      FgridFunctional.Cells[2, i + 1] := Obj.Strings['priority'];
    end;
  end;

  // Non-Functional
  FgridNonFunctional.RowCount := 1;
  NonFunc := TJSONArray(FAIProject.ProjectData.FindPath('agile_documents.non_functional_requirements'));
  if Assigned(NonFunc) then
  begin
    FgridNonFunctional.RowCount := NonFunc.Count + 1;
    for i := 0 to NonFunc.Count - 1 do
    begin
      Obj := NonFunc.Objects[i];
      FgridNonFunctional.Cells[0, i + 1] := Obj.Strings['id'];
      FgridNonFunctional.Cells[1, i + 1] := Obj.Strings['title'];
      FgridNonFunctional.Cells[2, i + 1] := Obj.Strings['priority'];
    end;
  end;

  // Stakeholders
  FgridStakeholders.RowCount := 1;
  Stakeh := TJSONArray(FAIProject.ProjectData.FindPath('agile_documents.stakeholders'));
  if Assigned(Stakeh) then
  begin
    FgridStakeholders.RowCount := Stakeh.Count + 1;
    for i := 0 to Stakeh.Count - 1 do
    begin
      Obj := Stakeh.Objects[i];
      FgridStakeholders.Cells[0, i + 1] := Obj.Strings['name'];
      FgridStakeholders.Cells[1, i + 1] := Obj.Strings['role'];
      FgridStakeholders.Cells[2, i + 1] := Obj.Strings['responsibility'];
    end;
  end;

  // Risks
  FgridRiskMap.RowCount := 1;
  Risks := TJSONArray(FAIProject.ProjectData.FindPath('agile_documents.risk_map'));
  if Assigned(Risks) then
  begin
    FgridRiskMap.RowCount := Risks.Count + 1;
    for i := 0 to Risks.Count - 1 do
    begin
      Obj := Risks.Objects[i];
      FgridRiskMap.Cells[0, i + 1] := Obj.Strings['id'];
      FgridRiskMap.Cells[1, i + 1] := Obj.Strings['title'];
      FgridRiskMap.Cells[2, i + 1] := Obj.Strings['impact'];
      FgridRiskMap.Cells[3, i + 1] := Obj.Strings['probability'];
    end;
  end;

  // Business Vision
  FmemoBusinessVision.Text := FAIProject.ProjectData.FindPath('agile_documents.business_vision').AsString;

  // Epics
  FmemoEpics.Clear;
  Funcs := TJSONArray(FAIProject.ProjectData.FindPath('agile_documents.epics'));
  if Assigned(Funcs) then
  begin
    for i := 0 to Funcs.Count - 1 do
    begin
      Obj := Funcs.Objects[i];
      FmemoEpics.Lines.Add(Obj.Strings['id'] + ': ' + Obj.Strings['title'] + ' - ' + Obj.Strings['description']);
    end;
  end;

  // User Stories
  FmemoUserStories.Clear;
  Funcs := TJSONArray(FAIProject.ProjectData.FindPath('agile_documents.user_stories'));
  if Assigned(Funcs) then
  begin
    for i := 0 to Funcs.Count - 1 do
    begin
      Obj := Funcs.Objects[i];
      FmemoUserStories.Lines.Add(Obj.Strings['id'] + ': ' + Obj.Strings['title']);
    end;
  end;

  // Agents
  FlstAgents.Clear;
  Funcs := TJSONArray(FAIProject.ProjectData.FindPath('agents'));
  if Assigned(Funcs) then
  begin
    for i := 0 to Funcs.Count - 1 do
    begin
      Obj := Funcs.Objects[i];
      FlstAgents.Items.Add(Obj.Strings['name'] + ' (' + Obj.Strings['profile'] + ')');
    end;
  end;

  // Tasks Grid
  FgridTasks.RowCount := 1;
  Tasks := TJSONArray(FAIProject.ProjectData.FindPath('planning.tasks'));
  if Assigned(Tasks) then
  begin
    FgridTasks.RowCount := Tasks.Count + 1;
    for i := 0 to Tasks.Count - 1 do
    begin
      Obj := Tasks.Objects[i];
      FgridTasks.Cells[0, i + 1] := Obj.Strings['id'];
      FgridTasks.Cells[1, i + 1] := Obj.Strings['title'];
      FgridTasks.Cells[2, i + 1] := Obj.Strings['status'];
      FgridTasks.Cells[3, i + 1] := Obj.Strings['priority'];
      FgridTasks.Cells[4, i + 1] := Obj.Strings['assigned_to'];
      FgridTasks.Cells[5, i + 1] := Obj.Strings['responsible_profile'];
      FgridTasks.Cells[6, i + 1] := Obj.Strings['planned_start_date'];
      FgridTasks.Cells[7, i + 1] := Obj.Strings['planned_end_date'];
      FgridTasks.Cells[8, i + 1] := IntToStr(Obj.Integers['progress_percent']) + '%';
    end;
  end;

  // Execution Plan list
  FmemoExecutionPlan.Clear;
  Funcs := TJSONArray(FAIProject.ProjectData.FindPath('planning.execution_plan'));
  if Assigned(Funcs) then
  begin
    for i := 0 to Funcs.Count - 1 do
      FmemoExecutionPlan.Lines.Add(Funcs.Strings[i]);
  end;
  
  if (FmemoExecutionPlan.Lines.Count = 0) and Assigned(Tasks) then
  begin
    for i := 0 to Tasks.Count - 1 do
    begin
      Obj := Tasks.Objects[i];
      FmemoExecutionPlan.Lines.Add(IntToStr(i + 1) + '. ' + Obj.Strings['id'] + ' - ' + Obj.Strings['title']);
    end;
  end;

  // Milestones
  FmemoMilestones.Clear;
  Funcs := TJSONArray(FAIProject.ProjectData.FindPath('planning.milestones'));
  if Assigned(Funcs) then
  begin
    for i := 0 to Funcs.Count - 1 do
    begin
      Obj := Funcs.Objects[i];
      FmemoMilestones.Lines.Add(Obj.Strings['id'] + ': ' + Obj.Strings['title'] + ' (Target: ' + Obj.Strings['target_date'] + ')');
    end;
  end;

  // Revisions List
  FlstRevisions.Clear;
  Revisions := TJSONArray(FAIProject.ProjectData.FindPath('revisions'));
  if Assigned(Revisions) then
  begin
    for i := 0 to Revisions.Count - 1 do
    begin
      Obj := Revisions.Objects[i];
      FlstRevisions.Items.Add('Revision ' + IntToStr(Obj.Integers['number']) + ' - ' + Obj.Strings['title']);
    end;
  end;

  // Timeline list
  FlstTimelineEvents.Clear;
  Timeline := TJSONArray(FAIProject.ProjectData.FindPath('planning.timeline'));
  if Assigned(Timeline) then
  begin
    for i := 0 to Timeline.Count - 1 do
    begin
      Obj := Timeline.Objects[i];
      FlstTimelineEvents.Items.Add(Obj.Strings['date'] + ': ' + Obj.Strings['title']);
    end;
  end;
end;

procedure TfrmMain.LoadTaskComboBoxes;
var
  Tasks, Agents: TJSONArray;
  i: Integer;
begin
  FcbSelectedTask.Clear;
  Tasks := TJSONArray(FAIProject.ProjectData.FindPath('planning.tasks'));
  if Assigned(Tasks) then
  begin
    for i := 0 to Tasks.Count - 1 do
      FcbSelectedTask.Items.Add(Tasks.Objects[i].Strings['id']);
    end;
  if FcbSelectedTask.Items.Count > 0 then FcbSelectedTask.ItemIndex := 0;

  FcbSelectedAgent.Clear;
  Agents := TJSONArray(FAIProject.ProjectData.FindPath('agents'));
  if Assigned(Agents) then
  begin
    for i := 0 to Agents.Count - 1 do
      FcbSelectedAgent.Items.Add(Agents.Objects[i].Strings['name']);
  end;
  if FcbSelectedAgent.Items.Count > 0 then FcbSelectedAgent.ItemIndex := 0;
end;

end.
