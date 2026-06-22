unit main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ComCtrls, StdCtrls,
  ExtCtrls, aiproject, aiproject_llmconfig, aiproject_storage, aiproject_tasks,
  aiproject_agents, aiproject_actions, aiproject_reports, aiproject_taskgrid,
  aiproject_statuspanel, aiproject_gantt, aiproject_timeline,
  aiproject_taskactionpanel, chatgpt;

type

  { TfrmMain }

  TfrmMain = class(TForm)
    AIProject1: TAIProject;
    ChatGPT1: TCHATGPT;
    AIProjectAgents1: TAIProjectAgents;
    AIProjectLLMConfig1: TAIProjectLLMConfig;
    ProjectReports1: TAIProjectReports;
    AIProjectStorage1: TAIProjectStorage;
    AIProjectTasks1: TAIProjectTasks;
    btnCarregarProjeto: TButton;
    btnSalvarProjeto: TButton;
    btnApplyConfig: TButton;
    btnAddManualTask: TButton;
    btnTestConnection: TButton;
    btnGenerateTasks: TButton;
    btnCreateDefaultAgents: TButton;
    btnGenerateSummary: TButton;
    btnGenerateTaskReport: TButton;
    btnGenerateAgentReport: TButton;
    btnExportMarkdown: TButton;
    btnExportJSON: TButton;
    Gantt1: TAIProjectGantt;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    MemoProjectName: TMemo;
    MemoGoal: TMemo;
    MemoConstraints: TMemo;
    MemoDeliverables: TMemo;
    MemoJSON: TMemo;
    MemoLog: TMemo;
    MemoReport: TMemo;
    PageControl1: TPageControl;
    StatusPanel1: TAIProjectStatusPanel;
    tabConfig: TTabSheet;
    tabProject: TTabSheet;
    tabTasks: TTabSheet;
    tabExecution: TTabSheet;
    tabReport: TTabSheet;
    tabJSONLog: TTabSheet;
    TaskActionPanel1: TAITaskActionPanel;
    TaskActions1: TAITaskActions;
    TaskGrid1: TAIProjectTaskGrid;
    Timeline1: TAIProjectTimeline;
    procedure btnAddManualTaskClick(Sender: TObject);
    procedure btnApplyConfigClick(Sender: TObject);
    procedure btnCarregarProjetoClick(Sender: TObject);
    procedure btnCreateDefaultAgentsClick(Sender: TObject);
    procedure btnExportJSONClick(Sender: TObject);
    procedure btnExportMarkdownClick(Sender: TObject);
    procedure btnGenerateAgentReportClick(Sender: TObject);
    procedure btnGenerateSummaryClick(Sender: TObject);
    procedure btnGenerateTaskReportClick(Sender: TObject);
    procedure btnGenerateTasksClick(Sender: TObject);
    procedure btnSalvarProjetoClick(Sender: TObject);
    procedure btnTestConnectionClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private
    procedure LogMsg(const AMsg: string);
    procedure RefreshAllViews;
  public
  end;

var
  frmMain: TfrmMain;

implementation

uses
  fpjson, jsonparser;

{$R *.lfm}

{ TfrmMain }

procedure TfrmMain.FormCreate(Sender: TObject);
begin
  // Ensures pointers are correctly assigned
  AIProject1.ChatGPT := ChatGPT1;
  AIProjectLLMConfig1.Project := AIProject1;
  AIProjectStorage1.Project := AIProject1;
  AIProjectTasks1.Project := AIProject1;
  AIProjectAgents1.Project := AIProject1;
  TaskActions1.Project := AIProject1;
  ProjectReports1.Project := AIProject1;

  TaskGrid1.Project := AIProject1;
  StatusPanel1.Project := AIProject1;
  Gantt1.Project := AIProject1;
  Timeline1.Project := AIProject1;
  TaskActionPanel1.Project := AIProject1;
  
end;

procedure TfrmMain.LogMsg(const AMsg: string);
begin
  MemoLog.Lines.Add(AMsg);
end;

procedure TfrmMain.RefreshAllViews;
begin
  TaskGrid1.LoadTasks;
  StatusPanel1.RefreshStatus;
  TaskActionPanel1.LoadCombos;
  Gantt1.Invalidate;
  Timeline1.Invalidate;
  if Assigned(AIProject1.ProjectData) then
    MemoJSON.Text := AIProject1.ProjectData.FormatJSON();
end;

procedure TfrmMain.btnApplyConfigClick(Sender: TObject);
begin
  AIProjectLLMConfig1.ApplyToProject;
  LogMsg('[OK] Configuração de LLM aplicada ao projeto.');
end;

procedure TfrmMain.btnTestConnectionClick(Sender: TObject);
begin
  // Simple validation mechanism
  if AIProjectLLMConfig1.TestConnection then
    LogMsg('[OK] Teste de conexão bem-sucedido.')
  else
    LogMsg('[ERRO] Falha no teste de conexão.');
end;

procedure TfrmMain.btnCreateDefaultAgentsClick(Sender: TObject);
begin
  AIProjectAgents1.CreateDefaultAgents;
  TaskActionPanel1.LoadCombos;
  LogMsg('[OK] Agentes padrão criados com sucesso.');
  RefreshAllViews;
end;

procedure TfrmMain.btnGenerateTasksClick(Sender: TObject);
var
  LPrompt: string;
  LResponse: string;
  LJSON: TJSONObject;
  LArray: TJSONArray;
  i: Integer;
begin
  AIProjectLLMConfig1.ApplyToProject;
  
  AIProject1.ProjectName := MemoProjectName.Text;
  AIProject1.Goal := MemoGoal.Text;
  AIProject1.Constraints := MemoConstraints.Text;
  AIProject1.ExpectedDeliverables := MemoDeliverables.Text;

  LPrompt := 'Atue como um gerente de projetos especialista. Baseado nas seguintes descrições:' + sLineBreak +
             'Nome: ' + AIProject1.ProjectName + sLineBreak +
             'Objetivo: ' + AIProject1.Goal + sLineBreak +
             'Restrições: ' + AIProject1.Constraints + sLineBreak +
             'Entregáveis: ' + AIProject1.ExpectedDeliverables + sLineBreak +
             'Crie um planejamento de projeto contendo uma lista de tarefas. ' + sLineBreak +
             'Responda ESTRITAMENTE em formato JSON contendo a raiz "planning" e dentro dela "tasks" ' +
             'que é um array de objetos. Cada objeto de task deve conter os campos: ' +
             'id, title, description, priority, status, assigned_to, responsible_profile, planned_start_date (YYYY-MM-DD), ' +
             'planned_end_date (YYYY-MM-DD), progress_percent e deliverable. ' +
             'Gere entre 3 e 5 tarefas realistas.';

  LogMsg('[INFO] Solicitando tarefas à IA...');
  Application.ProcessMessages;
  
  if AIProject1.ChatGPT = nil then
  begin
    LogMsg('[ERRO] Componente ChatGPT não está associado.');
    Exit;
  end;
  
  if AIProject1.ChatGPT.SendQuestion(LPrompt) then
    LResponse := AIProject1.ChatGPT.Response
  else
    LResponse := '';
  
  try
    LJSON := GetJSON(LResponse) as TJSONObject;
    if Assigned(LJSON) then
    begin
      // Update our project data with the generated planning
      if AIProject1.ProjectData.IndexOfName('planning') >= 0 then
        AIProject1.ProjectData.Delete('planning');
        
      AIProject1.ProjectData.Add('planning', LJSON.Extract('planning'));
      LJSON.Free;
      
      LogMsg('[OK] Tarefas geradas e incorporadas pela IA.');
      RefreshAllViews;
    end
    else
      LogMsg('[ERRO] IA não retornou um JSON válido.');
  except
    on E: Exception do
      LogMsg('[ERRO] Falha no parse do JSON: ' + E.Message);
  end;
end;

procedure TfrmMain.btnAddManualTaskClick(Sender: TObject);
begin
  AIProjectTasks1.AddTask(
    'Criar tela principal manual',
    'Criar formulário com abas principais (tarefa inserida via código).',
    'alta',
    'UI',
    'UI Agent',
    4
  );
  LogMsg('[OK] Tarefa manual adicionada.');
  RefreshAllViews;
end;

procedure TfrmMain.btnSalvarProjetoClick(Sender: TObject);
begin
  if AIProjectStorage1.SaveProjectToFile('project_tasklist_demo.aiproj.json') then
    LogMsg('[OK] Projeto salvo em project_tasklist_demo.aiproj.json')
  else
    LogMsg('[ERRO] Falha ao salvar projeto.');
end;

procedure TfrmMain.btnCarregarProjetoClick(Sender: TObject);
begin
  if AIProjectStorage1.LoadProjectFromFile('project_tasklist_demo.aiproj.json') then
  begin
    LogMsg('[OK] Projeto carregado com sucesso.');
    RefreshAllViews;
  end
  else
    LogMsg('[ERRO] Falha ao carregar projeto.');
end;

procedure TfrmMain.btnGenerateSummaryClick(Sender: TObject);
begin
  MemoReport.Text := ProjectReports1.GenerateReport(rtProjectSummary);
  LogMsg('[OK] Relatório de resumo gerado.');
end;

procedure TfrmMain.btnGenerateTaskReportClick(Sender: TObject);
begin
  MemoReport.Text := ProjectReports1.GenerateReport(rtTasks);
  LogMsg('[OK] Relatório de tarefas gerado.');
end;

procedure TfrmMain.btnGenerateAgentReportClick(Sender: TObject);
begin
  MemoReport.Text := ProjectReports1.GenerateReport(rtAgents);
  LogMsg('[OK] Relatório de agentes gerado.');
end;

procedure TfrmMain.btnExportMarkdownClick(Sender: TObject);
begin
  ProjectReports1.ExportFullMarkdown('report_export.md');
  LogMsg('[OK] Relatório exportado para report_export.md');
end;

procedure TfrmMain.btnExportJSONClick(Sender: TObject);
begin
  ProjectReports1.ExportFullJSON('report_export.json');
  LogMsg('[OK] Relatório exportado para report_export.json');
end;

end.
