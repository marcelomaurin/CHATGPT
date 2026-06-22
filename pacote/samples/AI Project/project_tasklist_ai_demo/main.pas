unit main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ComCtrls, StdCtrls,
  ExtCtrls, aiproject, aiproject_llmconfig, aiproject_storage, aiproject_tasks,
  aiproject_agents, aiproject_actions, aiproject_reports, aiproject_taskgrid,
  aiproject_statuspanel, aiproject_gantt, aiproject_timeline,
  aiproject_taskactionpanel, chatgpt, fpjson, jsonparser;

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
    cbTipoIA: TComboBox;
    edtModelo: TComboBox;
    edtToken: TEdit;
    edtEndpoint: TEdit;
    chkSalvarToken: TCheckBox;
    LabelTipoIA: TLabel;
    LabelModelo: TLabel;
    LabelToken: TLabel;
    LabelEndpoint: TLabel;
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
    procedure ValidarConfigIA;
    procedure EnsureProjectDataStructure;
    procedure ApplyProjectTextToComponent;
    function ExtractJSONFromAIResponse(const AText: string): string;
    procedure NormalizeGeneratedTasks(APlanning: TJSONObject);
    procedure ReplaceJSONValue(AObject: TJSONObject; const AName: string; AValue: TJSONData);
    function GetOrCreateObject(AParent: TJSONObject; const AName: string): TJSONObject;
    function GetOrCreateArray(AParent: TJSONObject; const AName: string): TJSONArray;
    function NormalizeStatus(const AStatus: string): string;
    function NormalizePriority(const APriority: string): string;
    function ISODate(ADate: TDateTime): string;
  public
  end;

var
  frmMain: TfrmMain;

implementation

{$R *.lfm}

{ TfrmMain }

procedure TfrmMain.FormCreate(Sender: TObject);
begin
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

  if cbTipoIA.Items.Count = 0 then
  begin
    cbTipoIA.Items.Add('OpenAI');
    cbTipoIA.Items.Add('Ollama');
    cbTipoIA.Items.Add('LM Studio');
    cbTipoIA.Items.Add('Local HTTP');
    cbTipoIA.Items.Add('Outro');
  end;

  if Trim(cbTipoIA.Text) = '' then
    cbTipoIA.Text := 'Ollama';

  if edtModelo.Items.Count = 0 then
  begin
    edtModelo.Items.Add('llama3.2');
    edtModelo.Items.Add('qwen2.5');
    edtModelo.Items.Add('mistral');
    edtModelo.Items.Add('gpt-4o-mini');
    edtModelo.Items.Add('gpt-4.1-mini');
  end;

  if Trim(edtModelo.Text) = '' then
    edtModelo.Text := 'llama3.2';

  if Trim(edtEndpoint.Text) = '' then
    edtEndpoint.Text := 'http://localhost:11434';

  chkSalvarToken.Checked := False;

  EnsureProjectDataStructure;
  RefreshAllViews;
  LogMsg('[OK] Formulário inicializado.');
end;

procedure TfrmMain.LogMsg(const AMsg: string);
begin
  if Assigned(MemoLog) then
    MemoLog.Lines.Add(FormatDateTime('hh:nn:ss', Now) + ' ' + AMsg);
end;

procedure TfrmMain.ReplaceJSONValue(AObject: TJSONObject; const AName: string; AValue: TJSONData);
var
  LIndex: Integer;
begin
  if not Assigned(AObject) then
  begin
    AValue.Free;
    Exit;
  end;

  LIndex := AObject.IndexOfName(AName);
  if LIndex >= 0 then
    AObject.Delete(LIndex);

  AObject.Add(AName, AValue);
end;

function TfrmMain.GetOrCreateObject(AParent: TJSONObject; const AName: string): TJSONObject;
var
  LData: TJSONData;
  LIndex: Integer;
begin
  Result := nil;
  if not Assigned(AParent) then
    Exit;

  LData := AParent.Find(AName);
  if LData is TJSONObject then
    Exit(TJSONObject(LData));

  LIndex := AParent.IndexOfName(AName);
  if LIndex >= 0 then
    AParent.Delete(LIndex);

  Result := TJSONObject.Create;
  AParent.Add(AName, Result);
end;

function TfrmMain.GetOrCreateArray(AParent: TJSONObject; const AName: string): TJSONArray;
var
  LData: TJSONData;
  LIndex: Integer;
begin
  Result := nil;
  if not Assigned(AParent) then
    Exit;

  LData := AParent.Find(AName);
  if LData is TJSONArray then
    Exit(TJSONArray(LData));

  LIndex := AParent.IndexOfName(AName);
  if LIndex >= 0 then
    AParent.Delete(LIndex);

  Result := TJSONArray.Create;
  AParent.Add(AName, Result);
end;

procedure TfrmMain.EnsureProjectDataStructure;
var
  LPlanning: TJSONObject;
begin
  if not Assigned(AIProject1.ProjectData) then
    raise Exception.Create(
      'AIProject1.ProjectData está nil. Corrija o constructor do TAIProject para criar FProjectData.'
    );

  GetOrCreateArray(AIProject1.ProjectData, 'agents');
  LPlanning := GetOrCreateObject(AIProject1.ProjectData, 'planning');
  GetOrCreateArray(LPlanning, 'tasks');
  GetOrCreateArray(LPlanning, 'timeline');
  GetOrCreateArray(AIProject1.ProjectData, 'task_action_history');
  GetOrCreateArray(AIProject1.ProjectData, 'revisions');
end;

procedure TfrmMain.ApplyProjectTextToComponent;
begin
  AIProject1.ProjectName := Trim(MemoProjectName.Text);
  AIProject1.Goal := Trim(MemoGoal.Text);
  AIProject1.Constraints := Trim(MemoConstraints.Text);
  AIProject1.ExpectedDeliverables := Trim(MemoDeliverables.Text);
end;

procedure TfrmMain.RefreshAllViews;
begin
  EnsureProjectDataStructure;

  if Assigned(TaskGrid1) then
    TaskGrid1.LoadTasks;

  if Assigned(StatusPanel1) then
    StatusPanel1.RefreshStatus;

  if Assigned(TaskActionPanel1) then
    TaskActionPanel1.LoadCombos;

  if Assigned(Gantt1) then
    Gantt1.Invalidate;

  if Assigned(Timeline1) then
    Timeline1.Invalidate;

  if Assigned(MemoJSON) and Assigned(AIProject1.ProjectData) then
    MemoJSON.Text := AIProject1.ProjectData.FormatJSON;
end;

procedure TfrmMain.ValidarConfigIA;
begin
  if Trim(cbTipoIA.Text) = '' then
    raise Exception.Create('Informe o tipo de IA.');

  if Trim(edtModelo.Text) = '' then
    raise Exception.Create('Informe o modelo da IA.');

  if SameText(cbTipoIA.Text, 'OpenAI') then
  begin
    if Trim(edtToken.Text) = '' then
      raise Exception.Create('Informe o token da API.');
  end
  else
  begin
    if Trim(edtEndpoint.Text) = '' then
      raise Exception.Create('Informe o endpoint da IA local ou servidor.');
  end;
end;

function TfrmMain.ISODate(ADate: TDateTime): string;
begin
  Result := FormatDateTime('yyyy"-"mm"-"dd', ADate);
end;

function TfrmMain.NormalizeStatus(const AStatus: string): string;
var
  S: string;
begin
  S := LowerCase(Trim(AStatus));

  if (S = '') or (S = 'pendente') or (S = 'pending') or (S = 'todo') or
     (S = 'a fazer') or (S = 'draft') then
    Exit('draft');

  if (S = 'confirmado') or (S = 'confirmed') or (S = 'aprovado') then
    Exit('confirmed');

  if (S = 'em andamento') or (S = 'andamento') or (S = 'in progress') or
     (S = 'in_progress') or (S = 'doing') then
    Exit('in_progress');

  if (S = 'concluido') or (S = 'concluído') or (S = 'concluida') or
     (S = 'concluída') or (S = 'finalizado') or (S = 'done') or
     (S = 'finished') then
    Exit('done');

  if (S = 'bloqueado') or (S = 'blocked') then
    Exit('blocked');

  if (S = 'cancelado') or (S = 'cancelled') or (S = 'canceled') then
    Exit('canceled');

  Result := 'draft';
end;

function TfrmMain.NormalizePriority(const APriority: string): string;
var
  S: string;
begin
  S := LowerCase(Trim(APriority));

  if (S = 'crítica') or (S = 'critica') or (S = 'critical') then
    Exit('critica');

  if (S = 'alta') or (S = 'high') then
    Exit('alta');

  if (S = 'média') or (S = 'media') or (S = 'medium') then
    Exit('media');

  if (S = 'baixa') or (S = 'low') then
    Exit('baixa');

  Result := 'media';
end;

function TfrmMain.ExtractJSONFromAIResponse(const AText: string): string;
var
  I, StartPos: Integer;
  CurlyCount, SquareCount: Integer;
  InString, EscapeNext: Boolean;
  Ch: Char;
begin
  Result := '';
  StartPos := 0;

  for I := 1 to Length(AText) do
  begin
    if (AText[I] = '{') or (AText[I] = '[') then
    begin
      StartPos := I;
      Break;
    end;
  end;

  if StartPos = 0 then
    raise Exception.Create('A resposta da IA não contém JSON.');

  CurlyCount := 0;
  SquareCount := 0;
  InString := False;
  EscapeNext := False;

  for I := StartPos to Length(AText) do
  begin
    Ch := AText[I];

    if InString then
    begin
      if EscapeNext then
        EscapeNext := False
      else if Ch = '\' then
        EscapeNext := True
      else if Ch = '"' then
        InString := False;
    end
    else
    begin
      case Ch of
        '"': InString := True;
        '{': Inc(CurlyCount);
        '}': Dec(CurlyCount);
        '[': Inc(SquareCount);
        ']': Dec(SquareCount);
      end;

      if (CurlyCount = 0) and (SquareCount = 0) then
      begin
        Result := Trim(Copy(AText, StartPos, I - StartPos + 1));
        Exit;
      end;
    end;
  end;

  raise Exception.Create('O JSON retornado pela IA está incompleto ou mal fechado.');
end;

procedure TfrmMain.NormalizeGeneratedTasks(APlanning: TJSONObject);
var
  LTasks: TJSONArray;
  LTask: TJSONObject;
  I: Integer;
  LID, LTitle, LDescription, LAssignedTo, LProfile, LDeliverable: string;
begin
  if not Assigned(APlanning) then
    raise Exception.Create('Objeto planning não encontrado no JSON.');

  LTasks := TJSONArray(APlanning.Find('tasks'));
  if not Assigned(LTasks) then
    raise Exception.Create('Array planning.tasks não encontrado no JSON.');

  for I := 0 to LTasks.Count - 1 do
  begin
    if not (LTasks.Items[I] is TJSONObject) then
      Continue;

    LTask := LTasks.Objects[I];

    LID := Trim(LTask.Get('id', ''));
    if (LID = '') or (Copy(UpperCase(LID), 1, 1) <> 'T') then
      LID := 'T' + Format('%.3d', [I + 1]);

    LTitle := Trim(LTask.Get('title', 'Tarefa ' + IntToStr(I + 1)));
    LDescription := Trim(LTask.Get('description', ''));
    LAssignedTo := Trim(LTask.Get('assigned_to', 'DEV Agent'));
    LProfile := Trim(LTask.Get('responsible_profile', 'DEV'));
    LDeliverable := Trim(LTask.Get('deliverable', ''));

    ReplaceJSONValue(LTask, 'id', TJSONString.Create(LID));
    ReplaceJSONValue(LTask, 'title', TJSONString.Create(LTitle));
    ReplaceJSONValue(LTask, 'description', TJSONString.Create(LDescription));
    ReplaceJSONValue(LTask, 'priority', TJSONString.Create(NormalizePriority(LTask.Get('priority', 'media'))));
    ReplaceJSONValue(LTask, 'status', TJSONString.Create(NormalizeStatus(LTask.Get('status', 'draft'))));
    ReplaceJSONValue(LTask, 'assigned_to', TJSONString.Create(LAssignedTo));
    ReplaceJSONValue(LTask, 'responsible_profile', TJSONString.Create(LProfile));
    ReplaceJSONValue(LTask, 'planned_start_date', TJSONString.Create(ISODate(Date + (I * 2))));
    ReplaceJSONValue(LTask, 'planned_end_date', TJSONString.Create(ISODate(Date + (I * 2) + 1)));
    ReplaceJSONValue(LTask, 'progress_percent', TJSONIntegerNumber.Create(LTask.Get('progress_percent', 0)));
    ReplaceJSONValue(LTask, 'deliverable', TJSONString.Create(LDeliverable));

    if LTask.Find('dependencies') = nil then
      LTask.Add('dependencies', TJSONArray.Create);

    if LTask.Find('estimated_hours') = nil then
      LTask.Add('estimated_hours', TJSONObject.Create(['mid_level', 4]));
  end;
end;

procedure TfrmMain.btnApplyConfigClick(Sender: TObject);
begin
  try
    ValidarConfigIA;

    if SameText(cbTipoIA.Text, 'OpenAI') then
      AIProjectLLMConfig1.Provider := AIP_OPENAI
    else
      AIProjectLLMConfig1.Provider := AIP_LOCAL;

    AIProjectLLMConfig1.Model := Trim(edtModelo.Text);
    AIProjectLLMConfig1.Token := Trim(edtToken.Text);
    AIProjectLLMConfig1.Endpoint := Trim(edtEndpoint.Text);
    AIProjectLLMConfig1.SaveToken := chkSalvarToken.Checked;
    AIProjectStorage1.SaveToken := chkSalvarToken.Checked;

    AIProjectLLMConfig1.ApplyToProject;

    ChatGPT1.CustomModel := Trim(edtModelo.Text);
    if Trim(edtEndpoint.Text) <> '' then
      ChatGPT1.URL := Trim(edtEndpoint.Text);

    LogMsg('[OK] Configuração de IA aplicada. Tipo=' + cbTipoIA.Text + ', Modelo=' + edtModelo.Text);
  except
    on E: Exception do
      LogMsg('[ERRO] Configuração inválida: ' + E.Message);
  end;
end;

procedure TfrmMain.btnTestConnectionClick(Sender: TObject);
var
  LPrompt: string;
begin
  try
    ValidarConfigIA;
    btnApplyConfigClick(nil);

    LPrompt := 'Responda somente com a palavra OK.';

    LogMsg('[INFO] Testando conexão com a IA...');
    Application.ProcessMessages;

    if ChatGPT1.SendQuestion(LPrompt) then
    begin
      LogMsg('[OK] IA respondeu: ' + Trim(ChatGPT1.Response));
    end
    else
      LogMsg('[ERRO] Falha ao enviar pergunta para IA.');
  except
    on E: Exception do
      LogMsg('[ERRO] Falha ao testar IA: ' + E.Message);
  end;
end;

procedure TfrmMain.btnCreateDefaultAgentsClick(Sender: TObject);
begin
  try
    EnsureProjectDataStructure;
    AIProjectAgents1.CreateDefaultAgents;
    RefreshAllViews;
    LogMsg('[OK] Agentes padrão criados.');
  except
    on E: Exception do
      LogMsg('[ERRO] Falha ao criar agentes padrão: ' + E.Message);
  end;
end;

procedure TfrmMain.btnGenerateTasksClick(Sender: TObject);
var
  LPrompt: string;
  LResponse: string;
  LCleanJSON: string;
  LData: TJSONData;
  LJSON: TJSONObject;
  LPlanning: TJSONObject;
begin
  LData := nil;

  try
    ValidarConfigIA;
    btnApplyConfigClick(nil);
    EnsureProjectDataStructure;
    ApplyProjectTextToComponent;

    LPrompt :=
      'Atue como um gerente de projetos especialista.' + sLineBreak +
      'Gere uma lista simples de tarefas para o projeto informado.' + sLineBreak + sLineBreak +
      'Nome do projeto: ' + AIProject1.ProjectName + sLineBreak +
      'Objetivo: ' + AIProject1.Goal + sLineBreak +
      'Restrições: ' + AIProject1.Constraints + sLineBreak +
      'Entregáveis: ' + AIProject1.ExpectedDeliverables + sLineBreak + sLineBreak +
      'REGRAS OBRIGATÓRIAS:' + sLineBreak +
      '1. Responda somente com JSON puro.' + sLineBreak +
      '2. Não use Markdown.' + sLineBreak +
      '3. Não use ```json.' + sLineBreak +
      '4. Não escreva explicações antes ou depois.' + sLineBreak +
      '5. A resposta deve começar com { e terminar com }.' + sLineBreak +
      '6. Use datas a partir de ' + ISODate(Date) + '.' + sLineBreak +
      '7. O campo id deve ser string no formato T001, T002, T003.' + sLineBreak +
      '8. Use status somente: draft, confirmed, in_progress, done, blocked, canceled.' + sLineBreak +
      '9. Use priority somente: baixa, media, alta, critica.' + sLineBreak +
      '10. Gere entre 3 e 5 tarefas.' + sLineBreak + sLineBreak +
      'Formato obrigatório:' + sLineBreak +
      '{' + sLineBreak +
      '  "planning": {' + sLineBreak +
      '    "tasks": [' + sLineBreak +
      '      {' + sLineBreak +
      '        "id": "T001",' + sLineBreak +
      '        "title": "",' + sLineBreak +
      '        "description": "",' + sLineBreak +
      '        "priority": "alta",' + sLineBreak +
      '        "status": "draft",' + sLineBreak +
      '        "assigned_to": "DEV Agent",' + sLineBreak +
      '        "responsible_profile": "DEV",' + sLineBreak +
      '        "planned_start_date": "' + ISODate(Date) + '",' + sLineBreak +
      '        "planned_end_date": "' + ISODate(Date + 1) + '",' + sLineBreak +
      '        "progress_percent": 0,' + sLineBreak +
      '        "deliverable": ""' + sLineBreak +
      '      }' + sLineBreak +
      '    ]' + sLineBreak +
      '  }' + sLineBreak +
      '}';

    LogMsg('[INFO] Solicitando tarefas à IA...');
    Application.ProcessMessages;

    if not Assigned(AIProject1.ChatGPT) then
      raise Exception.Create('Componente ChatGPT não está associado ao AIProject.');

    if AIProject1.ChatGPT.SendQuestion(LPrompt) then
      LResponse := AIProject1.ChatGPT.Response
    else
      raise Exception.Create('A IA não retornou resposta.');

    LCleanJSON := ExtractJSONFromAIResponse(LResponse);
    LData := GetJSON(LCleanJSON);

    if not (LData is TJSONObject) then
      raise Exception.Create('A resposta da IA não retornou um objeto JSON.');

    LJSON := TJSONObject(LData);
    LPlanning := TJSONObject(LJSON.Find('planning'));
    if not Assigned(LPlanning) then
      raise Exception.Create('A resposta não contém o objeto planning.');

    NormalizeGeneratedTasks(LPlanning);

    if AIProject1.ProjectData.IndexOfName('planning') >= 0 then
      AIProject1.ProjectData.Delete(AIProject1.ProjectData.IndexOfName('planning'));

    AIProject1.ProjectData.Add('planning', LPlanning.Clone);

    AIProjectTasks1.RecalculateEstimates;
    RefreshAllViews;

    LogMsg('[OK] Tarefas geradas e incorporadas pela IA.');
  except
    on E: Exception do
    begin
      LogMsg('[ERRO] Falha ao gerar tarefas: ' + E.Message);
      if Trim(LResponse) <> '' then
      begin
        LogMsg('[DEBUG] Resposta original da IA:');
        MemoLog.Lines.Add(LResponse);
      end;
    end;
  end;

  LData.Free;
end;

procedure TfrmMain.btnAddManualTaskClick(Sender: TObject);
var
  LID: string;
begin
  try
    EnsureProjectDataStructure;

    LID := AIProjectTasks1.AddTask(
      'Criar tela principal manual',
      'Criar formulário com abas principais (tarefa inserida via código).',
      'alta',
      'UI',
      'UI Agent',
      4
    );

    if LID = '' then
      raise Exception.Create(AIProjectTasks1.LastError);

    LogMsg('[OK] Tarefa manual adicionada: ' + LID);
    RefreshAllViews;
  except
    on E: Exception do
      LogMsg('[ERRO] Falha ao adicionar tarefa manual: ' + E.Message);
  end;
end;

procedure TfrmMain.btnSalvarProjetoClick(Sender: TObject);
begin
  try
    AIProjectStorage1.SaveToken := chkSalvarToken.Checked;

    if AIProjectStorage1.SaveProjectToFile('project_tasklist_demo.aiproj.json') then
      LogMsg('[OK] Projeto salvo em project_tasklist_demo.aiproj.json')
    else
      LogMsg('[ERRO] Falha ao salvar projeto: ' + AIProjectStorage1.LastError);
  except
    on E: Exception do
      LogMsg('[ERRO] Falha ao salvar projeto: ' + E.Message);
  end;
end;

procedure TfrmMain.btnCarregarProjetoClick(Sender: TObject);
begin
  try
    if AIProjectStorage1.LoadProjectFromFile('project_tasklist_demo.aiproj.json') then
    begin
      EnsureProjectDataStructure;
      LogMsg('[OK] Projeto carregado com sucesso.');
      RefreshAllViews;
    end
    else
      LogMsg('[ERRO] Falha ao carregar projeto: ' + AIProjectStorage1.LastError);
  except
    on E: Exception do
      LogMsg('[ERRO] Falha ao carregar projeto: ' + E.Message);
  end;
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
  if ProjectReports1.ExportFullMarkdown('report_export.md') then
    LogMsg('[OK] Relatório exportado para report_export.md')
  else
    LogMsg('[ERRO] Falha ao exportar Markdown: ' + ProjectReports1.LastError);
end;

procedure TfrmMain.btnExportJSONClick(Sender: TObject);
begin
  if ProjectReports1.ExportFullJSON('report_export.json') then
    LogMsg('[OK] Relatório exportado para report_export.json')
  else
    LogMsg('[ERRO] Falha ao exportar JSON: ' + ProjectReports1.LastError);
end;

end.

