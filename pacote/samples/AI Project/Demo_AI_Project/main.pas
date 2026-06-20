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
    FTabReports: TTabSheet;
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

    // Tab Reports Controls
    FReportViewer: TAIProjectReportViewer;

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
  Caption := 'AI Project Manager Demo — Visual Component Showcase';
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
  // SimulationMode defaults to False — real LLM calls only

  // Tab control
  FPageControl := TPageControl.Create(Self);
  FPageControl.Parent := Self;
  FPageControl.Align := alClient;

  // 14 Tabs
  FTabConfig        := FPageControl.AddTabSheet; FTabConfig.Caption        := 'Configuration';
  FTabDescription   := FPageControl.AddTabSheet; FTabDescription.Caption   := 'Project Description';
  FTabAgileDocs     := FPageControl.AddTabSheet; FTabAgileDocs.Caption     := 'Agile Documents';
  FTabAgents        := FPageControl.AddTabSheet; FTabAgents.Caption        := 'Agents';
  FTabTasks         := FPageControl.AddTabSheet; FTabTasks.Caption         := 'Tasks';
  FTabActions       := FPageControl.AddTabSheet; FTabActions.Caption       := 'Task Actions';
  FTabDependencies  := FPageControl.AddTabSheet; FTabDependencies.Caption  := 'Dependencies';
  FTabExecutionPlan := FPageControl.AddTabSheet; FTabExecutionPlan.Caption := 'Execution Plan';
  FTabGantt         := FPageControl.AddTabSheet; FTabGantt.Caption         := 'Gantt';
  FTabTimeline      := FPageControl.AddTabSheet; FTabTimeline.Caption      := 'Timeline';
  FTabRevision      := FPageControl.AddTabSheet; FTabRevision.Caption      := 'Revision';
  FTabReports       := FPageControl.AddTabSheet; FTabReports.Caption       := 'Reports';
  FTabJSON          := FPageControl.AddTabSheet; FTabJSON.Caption          := 'JSON';
  FTabLog           := FPageControl.AddTabSheet; FTabLog.Caption           := 'Log';

  { ===== Tab Config ===== }
  with TLabel.Create(Self) do begin Parent := FTabConfig; SetBounds(20,5,200,18); Caption := 'Provider:'; end;
  FcbProvider := TComboBox.Create(Self);
  FcbProvider.Parent := FTabConfig;
  FcbProvider.SetBounds(20, 22, 200, 25);
  FcbProvider.Items.Add('OpenAI');
  FcbProvider.Items.Add('OpenRouter');
  FcbProvider.Items.Add('Cerebras');
  FcbProvider.Items.Add('Local (Ollama)');
  FcbProvider.Items.Add('Gemini');
  FcbProvider.Items.Add('Claude');
  FcbProvider.ItemIndex := 3; // Local (Ollama) default

  with TLabel.Create(Self) do begin Parent := FTabConfig; SetBounds(20,50,200,18); Caption := 'API Token / Key:'; end;
  FedtToken := TEdit.Create(Self);
  FedtToken.Parent := FTabConfig;
  FedtToken.SetBounds(20, 67, 200, 25);
  FedtToken.TextHint := 'Leave blank for Ollama';
  FedtToken.PasswordChar := '*';

  with TLabel.Create(Self) do begin Parent := FTabConfig; SetBounds(20,95,200,18); Caption := 'Model:'; end;
  FcbModel := TComboBox.Create(Self);
  FcbModel.Parent := FTabConfig;
  FcbModel.SetBounds(20, 112, 200, 25);
  FcbModel.Items.Add('llama3.2');
  FcbModel.Items.Add('deepseek-r1:8b');
  FcbModel.Items.Add('gpt-4o-mini');
  FcbModel.Items.Add('gemini-2.5-flash');
  FcbModel.ItemIndex := 0;

  with TLabel.Create(Self) do begin Parent := FTabConfig; SetBounds(20,140,200,18); Caption := 'Model Version:'; end;
  FedtModelVersion := TEdit.Create(Self);
  FedtModelVersion.Parent := FTabConfig;
  FedtModelVersion.SetBounds(20, 157, 200, 25);
  FedtModelVersion.Text := '1.0';

  with TLabel.Create(Self) do begin Parent := FTabConfig; SetBounds(20,185,200,18); Caption := 'Endpoint (Ollama):'; end;
  FedtEndpoint := TEdit.Create(Self);
  FedtEndpoint.Parent := FTabConfig;
  FedtEndpoint.SetBounds(20, 202, 300, 25);
  FedtEndpoint.Text := 'http://localhost:11434';

  with TLabel.Create(Self) do begin Parent := FTabConfig; SetBounds(20,230,200,18); Caption := 'Temperature:'; end;
  FedtTemperature := TEdit.Create(Self);
  FedtTemperature.Parent := FTabConfig;
  FedtTemperature.SetBounds(20, 247, 100, 25);
  FedtTemperature.Text := '0.2';

  with TLabel.Create(Self) do begin Parent := FTabConfig; SetBounds(130,230,200,18); Caption := 'Max Tokens:'; end;
  FedtMaxTokens := TEdit.Create(Self);
  FedtMaxTokens.Parent := FTabConfig;
  FedtMaxTokens.SetBounds(130, 247, 100, 25);
  FedtMaxTokens.Text := '8000';

  FchkSaveToken := TCheckBox.Create(Self);
  FchkSaveToken.Parent := FTabConfig;
  FchkSaveToken.SetBounds(20, 280, 280, 25);
  FchkSaveToken.Caption := 'Save API Token to file (security risk!)';
  FchkSaveToken.Checked := False; // Default: do NOT save token

  FbtnTestLLM := TButton.Create(Self);
  FbtnTestLLM.Parent := FTabConfig;
  FbtnTestLLM.SetBounds(20, 315, 160, 30);
  FbtnTestLLM.Caption := 'Test LLM Connection';
  FbtnTestLLM.OnClick := @DoTestLLM;

  FbtnSaveConfig := TButton.Create(Self);
  FbtnSaveConfig.Parent := FTabConfig;
  FbtnSaveConfig.SetBounds(190, 315, 150, 30);
  FbtnSaveConfig.Caption := 'Save Configuration';
  FbtnSaveConfig.OnClick := @DoSaveConfig;

  FbtnLoadConfig := TButton.Create(Self);
  FbtnLoadConfig.Parent := FTabConfig;
  FbtnLoadConfig.SetBounds(350, 315, 150, 30);
  FbtnLoadConfig.Caption := 'Load Configuration';
  FbtnLoadConfig.OnClick := @DoLoadConfig;

  with TLabel.Create(Self) do begin Parent := FTabConfig; SetBounds(20,360,600,40);
    Caption := 'NOTE: This is a visual component demo. Set up your LLM and click "Generate Plan" ' +
               'on the Project Description tab to load real data from the AI.';
    Font.Color := $005599; WordWrap := True; end;

  { ===== Tab Description ===== }
  with TLabel.Create(Self) do begin Parent := FTabDescription; SetBounds(20,5,200,18); Caption := 'Project Name:'; end;
  FedtProjectName := TEdit.Create(Self);
  FedtProjectName.Parent := FTabDescription;
  FedtProjectName.SetBounds(20, 22, 400, 25);
  FedtProjectName.Text := 'Lazarus Audio Capturer Component';

  with TLabel.Create(Self) do begin Parent := FTabDescription; SetBounds(20,50,200,18); Caption := 'Goal:'; end;
  FmemoProjectGoal := TMemo.Create(Self);
  FmemoProjectGoal.Parent := FTabDescription;
  FmemoProjectGoal.SetBounds(20, 67, 400, 60);
  FmemoProjectGoal.Text := 'Create a Lazarus component that captures real audio from the microphone, saves as WAV and provides a visual demo.';

  with TLabel.Create(Self) do begin Parent := FTabDescription; SetBounds(20,130,200,18); Caption := 'Context:'; end;
  FmemoProjectContext := TMemo.Create(Self);
  FmemoProjectContext.Parent := FTabDescription;
  FmemoProjectContext.SetBounds(20, 147, 400, 50);
  FmemoProjectContext.Text := 'Lazarus 3.x and Free Pascal on Windows and Linux.';

  with TLabel.Create(Self) do begin Parent := FTabDescription; SetBounds(20,200,200,18); Caption := 'Scope:'; end;
  FmemoScope := TMemo.Create(Self);
  FmemoScope.Parent := FTabDescription;
  FmemoScope.SetBounds(20, 217, 400, 50);
  FmemoScope.Text := 'TAIAudioInput component, sound filters, arecord and WASAPI drivers.';

  with TLabel.Create(Self) do begin Parent := FTabDescription; SetBounds(20,270,200,18); Caption := 'Constraints:'; end;
  FmemoConstraints := TMemo.Create(Self);
  FmemoConstraints.Parent := FTabDescription;
  FmemoConstraints.SetBounds(20, 287, 400, 50);
  FmemoConstraints.Text := 'No simulation mode in final demo.';

  with TLabel.Create(Self) do begin Parent := FTabDescription; SetBounds(20,340,200,18); Caption := 'Expected Deliverables:'; end;
  FmemoDeliverables := TMemo.Create(Self);
  FmemoDeliverables.Parent := FTabDescription;
  FmemoDeliverables.SetBounds(20, 357, 400, 50);
  FmemoDeliverables.Text := 'Component package, WAV validation utility, GUI test sample.';

  with TLabel.Create(Self) do begin Parent := FTabDescription; SetBounds(20,410,120,18); Caption := 'Start Date:'; end;
  FedtProjectStart := TEdit.Create(Self);
  FedtProjectStart.Parent := FTabDescription;
  FedtProjectStart.SetBounds(20, 427, 190, 25);
  FedtProjectStart.Text := DateToStr(Date);

  with TLabel.Create(Self) do begin Parent := FTabDescription; SetBounds(220,410,120,18); Caption := 'Target End Date:'; end;
  FedtTargetEnd := TEdit.Create(Self);
  FedtTargetEnd.Parent := FTabDescription;
  FedtTargetEnd.SetBounds(220, 427, 200, 25);
  FedtTargetEnd.Text := DateToStr(Date + 30);

  FbtnGenerateInitialPlan := TButton.Create(Self);
  FbtnGenerateInitialPlan.Parent := FTabDescription;
  FbtnGenerateInitialPlan.SetBounds(20, 465, 180, 30);
  FbtnGenerateInitialPlan.Caption := 'Generate Plan with AI';
  FbtnGenerateInitialPlan.OnClick := @DoGenerateInitialPlan;

  FbtnSaveProject := TButton.Create(Self);
  FbtnSaveProject.Parent := FTabDescription;
  FbtnSaveProject.SetBounds(210, 465, 140, 30);
  FbtnSaveProject.Caption := 'Save Project';
  FbtnSaveProject.OnClick := @DoSaveProject;

  FbtnLoadProject := TButton.Create(Self);
  FbtnLoadProject.Parent := FTabDescription;
  FbtnLoadProject.SetBounds(360, 465, 140, 30);
  FbtnLoadProject.Caption := 'Load Project';
  FbtnLoadProject.OnClick := @DoLoadProject;

  { ===== Tab Agile Docs ===== }
  with TLabel.Create(Self) do begin Parent := FTabAgileDocs; SetBounds(20,5,200,18); Caption := 'Business Vision:'; end;
  FmemoBusinessVision := TMemo.Create(Self);
  FmemoBusinessVision.Parent := FTabAgileDocs;
  FmemoBusinessVision.SetBounds(20, 22, 300, 80);
  FmemoBusinessVision.TextHint := 'Business Vision';

  with TLabel.Create(Self) do begin Parent := FTabAgileDocs; SetBounds(20,105,200,18); Caption := 'Functional Requirements:'; end;
  FgridFunctional := TStringGrid.Create(Self);
  FgridFunctional.Parent := FTabAgileDocs;
  FgridFunctional.SetBounds(20, 122, 300, 110);
  FgridFunctional.ColCount := 3;
  FgridFunctional.FixedCols := 0;
  FgridFunctional.Cells[0, 0] := 'ID';
  FgridFunctional.Cells[1, 0] := 'Requirement';
  FgridFunctional.Cells[2, 0] := 'Priority';

  with TLabel.Create(Self) do begin Parent := FTabAgileDocs; SetBounds(20,235,200,18); Caption := 'Non-Functional Requirements:'; end;
  FgridNonFunctional := TStringGrid.Create(Self);
  FgridNonFunctional.Parent := FTabAgileDocs;
  FgridNonFunctional.SetBounds(20, 252, 300, 110);
  FgridNonFunctional.ColCount := 3;
  FgridNonFunctional.FixedCols := 0;
  FgridNonFunctional.Cells[0, 0] := 'ID';
  FgridNonFunctional.Cells[1, 0] := 'Req';
  FgridNonFunctional.Cells[2, 0] := 'Priority';

  with TLabel.Create(Self) do begin Parent := FTabAgileDocs; SetBounds(340,5,200,18); Caption := 'Stakeholders:'; end;
  FgridStakeholders := TStringGrid.Create(Self);
  FgridStakeholders.Parent := FTabAgileDocs;
  FgridStakeholders.SetBounds(340, 22, 300, 80);
  FgridStakeholders.ColCount := 3;
  FgridStakeholders.FixedCols := 0;
  FgridStakeholders.Cells[0, 0] := 'Name';
  FgridStakeholders.Cells[1, 0] := 'Role';
  FgridStakeholders.Cells[2, 0] := 'Responsibility';

  with TLabel.Create(Self) do begin Parent := FTabAgileDocs; SetBounds(340,105,200,18); Caption := 'Risk Map:'; end;
  FgridRiskMap := TStringGrid.Create(Self);
  FgridRiskMap.Parent := FTabAgileDocs;
  FgridRiskMap.SetBounds(340, 122, 300, 110);
  FgridRiskMap.ColCount := 4;
  FgridRiskMap.FixedCols := 0;
  FgridRiskMap.Cells[0, 0] := 'ID';
  FgridRiskMap.Cells[1, 0] := 'Risk';
  FgridRiskMap.Cells[2, 0] := 'Impact';
  FgridRiskMap.Cells[3, 0] := 'Probability';

  FRiskMatrix := TAIRiskMatrix.Create(Self);
  FRiskMatrix.Parent := FTabAgileDocs;
  FRiskMatrix.SetBounds(660, 22, 200, 200);
  FRiskMatrix.Project := FAIProject;

  with TLabel.Create(Self) do begin Parent := FTabAgileDocs; SetBounds(340,235,200,18); Caption := 'Epics:'; end;
  FmemoEpics := TMemo.Create(Self);
  FmemoEpics.Parent := FTabAgileDocs;
  FmemoEpics.SetBounds(340, 252, 300, 55);
  FmemoEpics.TextHint := 'Epics';

  with TLabel.Create(Self) do begin Parent := FTabAgileDocs; SetBounds(340,310,200,18); Caption := 'User Stories:'; end;
  FmemoUserStories := TMemo.Create(Self);
  FmemoUserStories.Parent := FTabAgileDocs;
  FmemoUserStories.SetBounds(340, 327, 300, 55);
  FmemoUserStories.TextHint := 'User Stories';

  { ===== Tab Agents ===== }
  FlstAgents := TListBox.Create(Self);
  FlstAgents.Parent := FTabAgents;
  FlstAgents.SetBounds(20, 20, 150, 300);
  FlstAgents.OnClick := @OnAgentsClick;

  with TLabel.Create(Self) do begin Parent := FTabAgents; SetBounds(180,5,200,18); Caption := 'Agent Name:'; end;
  FedtAgentName := TEdit.Create(Self);
  FedtAgentName.Parent := FTabAgents;
  FedtAgentName.SetBounds(180, 22, 200, 25);
  FedtAgentName.TextHint := 'Agent Name';

  with TLabel.Create(Self) do begin Parent := FTabAgents; SetBounds(180,50,200,18); Caption := 'Profile:'; end;
  FcbAgentProfile := TComboBox.Create(Self);
  FcbAgentProfile.Parent := FTabAgents;
  FcbAgentProfile.SetBounds(180, 67, 200, 25);
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

  with TLabel.Create(Self) do begin Parent := FTabAgents; SetBounds(180,95,200,18); Caption := 'Skill Level:'; end;
  FcbAgentSkillLevel := TComboBox.Create(Self);
  FcbAgentSkillLevel.Parent := FTabAgents;
  FcbAgentSkillLevel.SetBounds(180, 112, 200, 25);
  FcbAgentSkillLevel.Items.Add('intern');
  FcbAgentSkillLevel.Items.Add('junior');
  FcbAgentSkillLevel.Items.Add('mid_level');
  FcbAgentSkillLevel.Items.Add('senior');
  FcbAgentSkillLevel.ItemIndex := 3;

  with TLabel.Create(Self) do begin Parent := FTabAgents; SetBounds(180,140,200,18); Caption := 'Description:'; end;
  FmemoAgentDescription := TMemo.Create(Self);
  FmemoAgentDescription.Parent := FTabAgents;
  FmemoAgentDescription.SetBounds(180, 157, 200, 55);
  FmemoAgentDescription.TextHint := 'Agent Description';

  with TLabel.Create(Self) do begin Parent := FTabAgents; SetBounds(180,215,200,18); Caption := 'Responsibilities:'; end;
  FmemoAgentResponsibilities := TMemo.Create(Self);
  FmemoAgentResponsibilities.Parent := FTabAgents;
  FmemoAgentResponsibilities.SetBounds(180, 232, 200, 55);
  FmemoAgentResponsibilities.TextHint := 'Responsibilities';

  with TLabel.Create(Self) do begin Parent := FTabAgents; SetBounds(395,5,200,18); Caption := 'Agent System Prompt:'; end;
  FmemoAgentPrompt := TMemo.Create(Self);
  FmemoAgentPrompt.Parent := FTabAgents;
  FmemoAgentPrompt.SetBounds(395, 22, 280, 150);
  FmemoAgentPrompt.TextHint := 'Agent System Prompt (AI use)';

  FchkAgentActive := TCheckBox.Create(Self);
  FchkAgentActive.Parent := FTabAgents;
  FchkAgentActive.SetBounds(395, 180, 200, 25);
  FchkAgentActive.Caption := 'Agent Active';
  FchkAgentActive.Checked := True;

  FbtnAddAgent := TButton.Create(Self);
  FbtnAddAgent.Parent := FTabAgents;
  FbtnAddAgent.SetBounds(180, 305, 90, 28);
  FbtnAddAgent.Caption := 'Add Agent';
  FbtnAddAgent.OnClick := @DoAddAgent;

  FbtnUpdateAgent := TButton.Create(Self);
  FbtnUpdateAgent.Parent := FTabAgents;
  FbtnUpdateAgent.SetBounds(280, 305, 90, 28);
  FbtnUpdateAgent.Caption := 'Update';
  FbtnUpdateAgent.OnClick := @DoUpdateAgent;

  FbtnRemoveAgent := TButton.Create(Self);
  FbtnRemoveAgent.Parent := FTabAgents;
  FbtnRemoveAgent.SetBounds(380, 305, 90, 28);
  FbtnRemoveAgent.Caption := 'Remove';
  FbtnRemoveAgent.OnClick := @DoRemoveAgent;

  FbtnCreateDefaultAgents := TButton.Create(Self);
  FbtnCreateDefaultAgents.Parent := FTabAgents;
  FbtnCreateDefaultAgents.SetBounds(480, 305, 160, 28);
  FbtnCreateDefaultAgents.Caption := 'Create Default Agents (9)';
  FbtnCreateDefaultAgents.OnClick := @DoCreateDefaultAgents;

  { ===== Tab Tasks ===== }
  FgridTasks := TStringGrid.Create(Self);
  FgridTasks.Parent := FTabTasks;
  FgridTasks.SetBounds(20, 20, 800, 290);
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
  FbtnAddTask.SetBounds(20, 325, 120, 28);
  FbtnAddTask.Caption := 'Add Task';
  FbtnAddTask.OnClick := @DoAddTask;

  FbtnCancelTask := TButton.Create(Self);
  FbtnCancelTask.Parent := FTabTasks;
  FbtnCancelTask.SetBounds(150, 325, 120, 28);
  FbtnCancelTask.Caption := 'Cancel Task';

  FbtnRecalculateEstimates := TButton.Create(Self);
  FbtnRecalculateEstimates.Parent := FTabTasks;
  FbtnRecalculateEstimates.SetBounds(280, 325, 160, 28);
  FbtnRecalculateEstimates.Caption := 'Recalculate Schedule';
  FbtnRecalculateEstimates.OnClick := @DoRefreshTimeline;

  FbtnAskAgentToAnalyzeTask := TButton.Create(Self);
  FbtnAskAgentToAnalyzeTask.Parent := FTabTasks;
  FbtnAskAgentToAnalyzeTask.SetBounds(450, 325, 200, 28);
  FbtnAskAgentToAnalyzeTask.Caption := 'Ask Agent to Analyze Task';

  { ===== Tab Actions ===== }
  with TLabel.Create(Self) do begin Parent := FTabActions; SetBounds(10,5,200,18); Caption := 'Task:'; end;
  FcbSelectedTask := TComboBox.Create(Self);
  FcbSelectedTask.Parent := FTabActions;
  FcbSelectedTask.SetBounds(10, 22, 200, 25);
  FcbSelectedTask.TextHint := 'Select Task';

  with TLabel.Create(Self) do begin Parent := FTabActions; SetBounds(10,50,200,18); Caption := 'Agent:'; end;
  FcbSelectedAgent := TComboBox.Create(Self);
  FcbSelectedAgent.Parent := FTabActions;
  FcbSelectedAgent.SetBounds(10, 67, 200, 25);
  FcbSelectedAgent.TextHint := 'Select Agent';

  with TLabel.Create(Self) do begin Parent := FTabActions; SetBounds(10,95,200,18); Caption := 'Action:'; end;
  FcbTaskAction := TComboBox.Create(Self);
  FcbTaskAction.Parent := FTabActions;
  FcbTaskAction.SetBounds(10, 112, 200, 25);
  FcbTaskAction.Items.Add('Confirm Task');
  FcbTaskAction.Items.Add('Reject Task');
  FcbTaskAction.Items.Add('Start Task');
  FcbTaskAction.Items.Add('Finish Task');
  FcbTaskAction.Items.Add('Cancel Task');
  FcbTaskAction.Items.Add('Block Task');
  FcbTaskAction.Items.Add('Unblock Task');
  FcbTaskAction.Items.Add('Reopen Task');
  FcbTaskAction.Items.Add('Comment Task');
  FcbTaskAction.Items.Add('Request Revision');
  FcbTaskAction.ItemIndex := 2;

  with TLabel.Create(Self) do begin Parent := FTabActions; SetBounds(10,140,200,18); Caption := 'Comment:'; end;
  FmemoActionComment := TMemo.Create(Self);
  FmemoActionComment.Parent := FTabActions;
  FmemoActionComment.SetBounds(10, 157, 250, 70);
  FmemoActionComment.TextHint := 'Action comment';

  with TLabel.Create(Self) do begin Parent := FTabActions; SetBounds(10,230,250,18); Caption := 'Deliverable (for Finish action):'; end;
  FedtActionDeliverable := TEdit.Create(Self);
  FedtActionDeliverable.Parent := FTabActions;
  FedtActionDeliverable.SetBounds(10, 247, 250, 25);
  FedtActionDeliverable.TextHint := 'File or URL';

  FbtnApplyTaskAction := TButton.Create(Self);
  FbtnApplyTaskAction.Parent := FTabActions;
  FbtnApplyTaskAction.SetBounds(10, 280, 160, 28);
  FbtnApplyTaskAction.Caption := 'Apply Task Action';
  FbtnApplyTaskAction.OnClick := @DoApplyTaskAction;

  with TLabel.Create(Self) do begin Parent := FTabActions; SetBounds(280,5,200,18); Caption := 'Action History:'; end;
  FmemoTaskActionHistory := TMemo.Create(Self);
  FmemoTaskActionHistory.Parent := FTabActions;
  FmemoTaskActionHistory.SetBounds(280, 22, 580, 290);
  FmemoTaskActionHistory.ScrollBars := ssAutoBoth;
  FmemoTaskActionHistory.ReadOnly := True;

  { ===== Tab Dependencies ===== }
  with TLabel.Create(Self) do begin Parent := FTabDependencies; SetBounds(20,5,200,18); Caption := 'Serial Dependencies:'; end;
  FlstSerialDependencies := TListBox.Create(Self);
  FlstSerialDependencies.Parent := FTabDependencies;
  FlstSerialDependencies.SetBounds(20, 22, 200, 200);

  with TLabel.Create(Self) do begin Parent := FTabDependencies; SetBounds(240,5,200,18); Caption := 'Parallel Tasks:'; end;
  FlstParallelGroups := TListBox.Create(Self);
  FlstParallelGroups.Parent := FTabDependencies;
  FlstParallelGroups.SetBounds(240, 22, 200, 200);

  with TLabel.Create(Self) do begin Parent := FTabDependencies; SetBounds(20,225,200,18); Caption := 'Explanation:'; end;
  FmemoDependencyExplanation := TMemo.Create(Self);
  FmemoDependencyExplanation.Parent := FTabDependencies;
  FmemoDependencyExplanation.SetBounds(20, 242, 420, 100);

  { ===== Tab Execution Plan ===== }
  with TLabel.Create(Self) do begin Parent := FTabExecutionPlan; SetBounds(20,5,200,18); Caption := 'Execution Plan:'; end;
  FmemoExecutionPlan := TMemo.Create(Self);
  FmemoExecutionPlan.Parent := FTabExecutionPlan;
  FmemoExecutionPlan.SetBounds(20, 22, 400, 240);
  FmemoExecutionPlan.ScrollBars := ssAutoBoth;

  with TLabel.Create(Self) do begin Parent := FTabExecutionPlan; SetBounds(440,5,200,18); Caption := 'Milestones:'; end;
  FmemoMilestones := TMemo.Create(Self);
  FmemoMilestones.Parent := FTabExecutionPlan;
  FmemoMilestones.SetBounds(440, 22, 380, 240);
  FmemoMilestones.ScrollBars := ssAutoBoth;

  { ===== Tab Gantt ===== }
  FpbGantt := TAIProjectGantt.Create(Self);
  FpbGantt.Parent := FTabGantt;
  FpbGantt.SetBounds(10, 10, 870, 360);
  FpbGantt.Project := FAIProject;

  FbtnRecalculateSchedule := TButton.Create(Self);
  FbtnRecalculateSchedule.Parent := FTabGantt;
  FbtnRecalculateSchedule.SetBounds(10, 380, 190, 28);
  FbtnRecalculateSchedule.Caption := 'Recalculate Schedule';
  FbtnRecalculateSchedule.OnClick := @DoRefreshTimeline;

  { ===== Tab Timeline ===== }
  FpbTimeline := TAIProjectTimeline.Create(Self);
  FpbTimeline.Parent := FTabTimeline;
  FpbTimeline.SetBounds(10, 10, 500, 350);
  FpbTimeline.Project := FAIProject;

  with TLabel.Create(Self) do begin Parent := FTabTimeline; SetBounds(525,5,200,18); Caption := 'Timeline Events:'; end;
  FlstTimelineEvents := TListBox.Create(Self);
  FlstTimelineEvents.Parent := FTabTimeline;
  FlstTimelineEvents.SetBounds(525, 22, 340, 190);

  with TLabel.Create(Self) do begin Parent := FTabTimeline; SetBounds(525,215,200,18); Caption := 'Details:'; end;
  FmemoTimelineDetails := TMemo.Create(Self);
  FmemoTimelineDetails.Parent := FTabTimeline;
  FmemoTimelineDetails.SetBounds(525, 232, 340, 130);

  { ===== Tab Revision ===== }
  with TLabel.Create(Self) do begin Parent := FTabRevision; SetBounds(20,5,400,18); Caption := 'Enter correction description to request a new revision from the AI:'; end;
  FmemoCorrection := TMemo.Create(Self);
  FmemoCorrection.Parent := FTabRevision;
  FmemoCorrection.SetBounds(20, 22, 400, 80);
  FmemoCorrection.TextHint := 'Example: Add Linux backend using arecord...';

  FbtnApplyCorrection := TButton.Create(Self);
  FbtnApplyCorrection.Parent := FTabRevision;
  FbtnApplyCorrection.SetBounds(20, 110, 200, 28);
  FbtnApplyCorrection.Caption := 'Apply Project Correction';
  FbtnApplyCorrection.OnClick := @DoApplyCorrection;

  with TLabel.Create(Self) do begin Parent := FTabRevision; SetBounds(20,145,200,18); Caption := 'Revisions:'; end;
  FlstRevisions := TListBox.Create(Self);
  FlstRevisions.Parent := FTabRevision;
  FlstRevisions.SetBounds(20, 162, 400, 150);
  FlstRevisions.OnClick := @OnRevisionsClick;

  with TLabel.Create(Self) do begin Parent := FTabRevision; SetBounds(440,5,200,18); Caption := 'Revision Details:'; end;
  FmemoRevisionDetails := TMemo.Create(Self);
  FmemoRevisionDetails.Parent := FTabRevision;
  FmemoRevisionDetails.SetBounds(440, 22, 430, 300);
  FmemoRevisionDetails.ScrollBars := ssAutoBoth;

  { ===== Tab Reports ===== }
  FReportViewer := TAIProjectReportViewer.Create(Self);
  FReportViewer.Parent := FTabReports;
  FReportViewer.SetBounds(10, 10, 870, 420);
  FReportViewer.Project := FAIProject;

  { ===== Tab JSON ===== }
  FbtnCopyJSON := TButton.Create(Self);
  FbtnCopyJSON.Parent := FTabJSON;
  FbtnCopyJSON.SetBounds(10, 10, 120, 28);
  FbtnCopyJSON.Caption := 'Copy JSON';
  FbtnCopyJSON.OnClick := @DoCopyJSON;

  FmemoCurrentJSON := TMemo.Create(Self);
  FmemoCurrentJSON.Parent := FTabJSON;
  FmemoCurrentJSON.SetBounds(10, 45, 870, 390);
  FmemoCurrentJSON.ScrollBars := ssAutoBoth;

  { ===== Tab Log ===== }
  FbtnClearLog := TButton.Create(Self);
  FbtnClearLog.Parent := FTabLog;
  FbtnClearLog.SetBounds(10, 10, 120, 28);
  FbtnClearLog.Caption := 'Clear Log';
  FbtnClearLog.OnClick := @DoClearLog;

  FmemoLog := TMemo.Create(Self);
  FmemoLog.Parent := FTabLog;
  FmemoLog.SetBounds(10, 45, 870, 390);
  FmemoLog.ScrollBars := ssAutoBoth;

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
    llDebug:   LvlStr := '[DEBUG] ';
    llInfo:    LvlStr := '[INFO] ';
    llWarning: LvlStr := '[WARNING] ';
    llError:   LvlStr := '[ERROR] ';
  end;
  FmemoLog.Lines.Add(LvlStr + Message);
end;

procedure TfrmMain.DoTestLLM(Sender: TObject);
begin
  FAIProject.DefaultProvider := TAIProvider(FcbProvider.ItemIndex);
  FAIProject.Token := FedtToken.Text;
  FAIProject.DefaultModel := FcbModel.Text;
  FAIProject.LocalURL := FedtEndpoint.Text;

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
  FAIProject.ProjectName := FedtProjectName.Text;
  FAIProject.Goal := FmemoProjectGoal.Text;
  FAIProject.Description := FmemoProjectGoal.Text;
  FAIProject.Context := FmemoProjectContext.Text;
  FAIProject.Scope := FmemoScope.Text;
  FAIProject.Constraints := FmemoConstraints.Text;
  FAIProject.ExpectedDeliverables := FmemoDeliverables.Text;

  if TryStrToDate(FedtProjectStart.Text, dtS) then FAIProject.StartDate := dtS;
  if TryStrToDate(FedtTargetEnd.Text, dtE) then FAIProject.TargetEndDate := dtE;

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
      // Token security: only saved if SaveToken=True
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
      end
      else
        ShowMessage('Failed to load project: ' + FAIProject.LastError);
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
  Agents.Add(TJSONObject.Create(['id', 'AG005', 'name', 'Operador', 'profile', 'Operador', 'description', 'System operator', 'skill_level', 'junior', 'active', true]));
  Agents.Add(TJSONObject.Create(['id', 'AG006', 'name', 'Key User', 'profile', 'Key User', 'description', 'Business validator', 'skill_level', 'mid_level', 'active', true]));
  Agents.Add(TJSONObject.Create(['id', 'AG007', 'name', 'Tester Agent', 'profile', 'Tester', 'description', 'QA validation', 'skill_level', 'junior', 'active', true]));
  Agents.Add(TJSONObject.Create(['id', 'AG008', 'name', 'Documentador', 'profile', 'Documentador', 'description', 'Technical writer', 'skill_level', 'mid_level', 'active', true]));
  Agents.Add(TJSONObject.Create(['id', 'AG009', 'name', 'Project Manager', 'profile', 'Gerente', 'description', 'Coordinates the team', 'skill_level', 'senior', 'active', true]));

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
    'id',                  'T' + Format('%.3d', [Tasks.Count + 1]),
    'epic_id',             'E001',
    'title',               'New Custom Task',
    'description',         'Added by user manually.',
    'acceptance_criteria', 'Custom criteria',
    'priority',            'medium',
    'status',              'draft',
    'dependency_type',     'serial',
    'dependencies',        TJSONArray.Create,
    'can_run_in_parallel', false,
    'estimated_hours',     TJSONObject.Create(['mid_level', 4]),
    'suggested_skill_level', 'mid_level',
    'assigned_skill_level',  'mid_level',
    'assigned_to',           'DEV Agent',
    'responsible_profile',   'DEV',
    'estimated_duration_days', 1,
    'deliverable',           '',
    'notes',                 '',
    'progress_percent',      0,
    'revision_created',      1,
    'revision_updated',      1
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
    FmemoTaskActionHistory.Lines.Add(DateTimeToStr(Now) + ' | ' + TaskID + ' | ' +
      AgentID + ' | ' + FcbTaskAction.Text);
    ShowMessage('Action applied successfully!');
    RefreshUI;
  end
  else
    ShowMessage('Action failed: ' + FAIProject.LastError);
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
  Funcs, NonFunc, Stakeh, Risks, Tasks, Timeline, Revisions, Deps, Parallel: TJSONArray;
  Obj: TJSONObject;
  i: Integer;
begin
  // Functional Requirements
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

  // Non-Functional Requirements
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
  if Assigned(FAIProject.ProjectData.FindPath('agile_documents.business_vision')) then
    FmemoBusinessVision.Text := FAIProject.ProjectData.FindPath('agile_documents.business_vision').AsString;

  // Epics
  FmemoEpics.Clear;
  Funcs := TJSONArray(FAIProject.ProjectData.FindPath('agile_documents.epics'));
  if Assigned(Funcs) then
    for i := 0 to Funcs.Count - 1 do
    begin
      Obj := Funcs.Objects[i];
      FmemoEpics.Lines.Add(Obj.Strings['id'] + ': ' + Obj.Strings['title']);
    end;

  // User Stories
  FmemoUserStories.Clear;
  Funcs := TJSONArray(FAIProject.ProjectData.FindPath('agile_documents.user_stories'));
  if Assigned(Funcs) then
    for i := 0 to Funcs.Count - 1 do
    begin
      Obj := Funcs.Objects[i];
      FmemoUserStories.Lines.Add(Obj.Strings['id'] + ': ' + Obj.Strings['title']);
    end;

  // Agents
  FlstAgents.Clear;
  Funcs := TJSONArray(FAIProject.ProjectData.FindPath('agents'));
  if Assigned(Funcs) then
    for i := 0 to Funcs.Count - 1 do
    begin
      Obj := Funcs.Objects[i];
      FlstAgents.Items.Add(Obj.Strings['name'] + ' (' + Obj.Strings['profile'] + ')');
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

  // Execution Plan
  FmemoExecutionPlan.Clear;
  Funcs := TJSONArray(FAIProject.ProjectData.FindPath('planning.execution_plan'));
  if Assigned(Funcs) then
    for i := 0 to Funcs.Count - 1 do
      FmemoExecutionPlan.Lines.Add(Funcs.Strings[i]);

  if (FmemoExecutionPlan.Lines.Count = 0) and Assigned(Tasks) then
    for i := 0 to Tasks.Count - 1 do
    begin
      Obj := Tasks.Objects[i];
      FmemoExecutionPlan.Lines.Add(IntToStr(i + 1) + '. ' + Obj.Strings['id'] + ' - ' + Obj.Strings['title']);
    end;

  // Milestones
  FmemoMilestones.Clear;
  Funcs := TJSONArray(FAIProject.ProjectData.FindPath('planning.milestones'));
  if Assigned(Funcs) then
    for i := 0 to Funcs.Count - 1 do
    begin
      Obj := Funcs.Objects[i];
      FmemoMilestones.Lines.Add(Obj.Strings['id'] + ': ' + Obj.Strings['title'] +
                                ' (Target: ' + Obj.Strings['target_date'] + ')');
    end;

  // Revisions List
  FlstRevisions.Clear;
  Revisions := TJSONArray(FAIProject.ProjectData.FindPath('revisions'));
  if Assigned(Revisions) then
    for i := 0 to Revisions.Count - 1 do
    begin
      Obj := Revisions.Objects[i];
      FlstRevisions.Items.Add('Rev ' + IntToStr(Obj.Integers['number']) + ' — ' + Obj.Strings['title']);
    end;

  // Timeline list
  FlstTimelineEvents.Clear;
  Timeline := TJSONArray(FAIProject.ProjectData.FindPath('planning.timeline'));
  if Assigned(Timeline) then
    for i := 0 to Timeline.Count - 1 do
    begin
      Obj := Timeline.Objects[i];
      FlstTimelineEvents.Items.Add(Obj.Strings['date'] + ': ' + Obj.Strings['title']);
    end;

  // Dependencies
  FlstSerialDependencies.Clear;
  FlstParallelGroups.Clear;
  if Assigned(Tasks) then
    for i := 0 to Tasks.Count - 1 do
    begin
      Obj := Tasks.Objects[i];
      Deps := TJSONArray(Obj.FindPath('dependencies'));
      if Assigned(Deps) and (Deps.Count > 0) then
        FlstSerialDependencies.Items.Add(Obj.Strings['id'] + ' depends on ' + Deps.Strings[0]);
      if Obj.Booleans['can_run_in_parallel'] then
        FlstParallelGroups.Items.Add(Obj.Strings['id'] + ': ' + Obj.Strings['title']);
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
    for i := 0 to Tasks.Count - 1 do
      FcbSelectedTask.Items.Add(Tasks.Objects[i].Strings['id']);
  if FcbSelectedTask.Items.Count > 0 then FcbSelectedTask.ItemIndex := 0;

  FcbSelectedAgent.Clear;
  Agents := TJSONArray(FAIProject.ProjectData.FindPath('agents'));
  if Assigned(Agents) then
    for i := 0 to Agents.Count - 1 do
      FcbSelectedAgent.Items.Add(Agents.Objects[i].Strings['name']);
  if FcbSelectedAgent.Items.Count > 0 then FcbSelectedAgent.ItemIndex := 0;
end;

end.
