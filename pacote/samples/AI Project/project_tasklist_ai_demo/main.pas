unit main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ComCtrls, StdCtrls,
  ExtCtrls, aiproject, aiproject_llmconfig, aiproject_storage, aiproject_tasks,
  aiproject_specification, aiproject_agents, aiproject_actions,
  aiproject_reports, aiproject_taskgrid, aiproject_statuspanel, aiproject_gantt,
  aiproject_timeline, aiproject_taskactionpanel, aiproject_description,
  aiproject_revisions, aiproject_agentmanager, chatgpt, fpjson, jsonparser,
  typinfo;

type

  { TfrmMain }

  TfrmMain = class(TForm)
    AIAgentManagerFrame1: TAIAgentManagerFrame;
    AIProject1: TAIProject;
    AIProjectAgents1: TAIProjectAgents;
    AIProjectDescription1: TAIProjectDescription;
    AIProjectRevisions1: TAIProjectRevisions;
    AITaskActions1: TAITaskActions;
    ChatGPT1: TCHATGPT;
    AIProjectLLMConfig1: TAIProjectLLMConfig;
    AIProjectStorage1: TAIProjectStorage;
    AIProjectTasks1: TAIProjectTasks;
    AIProjectSpecification1: TAIProjectSpecification;
    btnCarregarProjeto: TButton;
    btnSalvarProjeto: TButton;
    btnClearProject: TButton;
    btnApplyConfig: TButton;
    btnAddManualTask: TButton;
    btnTestConnection: TButton;
    chkSalvarToken: TCheckBox;
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
    tsAgent: TTabSheet;
    tabTasks: TTabSheet;
    tabJSONLog: TTabSheet;
    TaskGrid1: TAIProjectTaskGrid;
    MemoTaskDescription: TMemo;
    btnGenerateDescription: TButton;
    lblProvider: TLabel;
    cbProvider: TComboBox;
    lblModel: TLabel;
    cbModel: TComboBox;
    lblToken: TLabel;
    edtToken: TEdit;
    lblEndpoint: TLabel;
    edtEndpoint: TEdit;
    lblVersaoIA: TLabel;
    cbVersaoIA: TComboBox;

    procedure btnAddManualTaskClick(Sender: TObject);
    procedure btnApplyConfigClick(Sender: TObject);
    procedure btnCarregarProjetoClick(Sender: TObject);
    procedure btnClearProjectClick(Sender: TObject);
    procedure btnCreateDefaultAgentsClick(Sender: TObject);
    procedure btnExportJSONClick(Sender: TObject);
    procedure btnExportMarkdownClick(Sender: TObject);
    procedure btnGenerateAgentReportClick(Sender: TObject);
    procedure btnGenerateDescriptionClick(Sender: TObject);
    procedure btnGenerateSummaryClick(Sender: TObject);
    procedure btnGenerateTaskReportClick(Sender: TObject);
    procedure btnGenerateTasksClick(Sender: TObject);
    procedure btnSalvarProjetoClick(Sender: TObject);
    procedure btnTestConnectionClick(Sender: TObject);
    procedure TaskGrid1SelectCell(Sender: TObject; aCol, aRow: Integer; var CanSelect: Boolean);
    procedure cbProviderChange(Sender: TObject);
    procedure FormCreate(Sender: TObject);

  private
    procedure LogMsg(const AMsg: string);
    procedure RefreshAllViews;
    procedure ValidarConfigIA;
    procedure RequireChatGPTReady;
    procedure ApplyProjectTextToComponent;
    procedure RequireProjectInput;

    function SendPromptWithChatGPT(const APrompt, AContext: string): string;
    function ExtractJSONFromAIResponse(const AText: string): string;

    procedure ReplaceJSONValue(AObject: TJSONObject; const AName: string; AValue: TJSONData);
    procedure CopyJSONField(ASource, ADest: TJSONObject; const AName: string);

    function ISODate(ADate: TDateTime): string;
    function JSONTypeName(AData: TJSONData): string;

    function IsAllowedTaskStatus(const AStatus: string): Boolean;
    function IsAllowedPriority(const APriority: string): Boolean;
    function IsAllowedSkillLevel(const ASkill: string): Boolean;

    procedure RequireStringField(AObj: TJSONObject; const AField, AContext: string);
    procedure RequireNumberField(AObj: TJSONObject; const AField, AContext: string);
    procedure RequireBooleanField(AObj: TJSONObject; const AField, AContext: string);
    procedure RequireObjectField(AObj: TJSONObject; const AField, AContext: string);
    procedure RequireArrayField(AObj: TJSONObject; const AField, AContext: string);

    function BuildSpecificationPrompt: string;
    function BuildTasksPrompt: string;
    function BuildSingleTaskPrompt: string;
    function BuildAgentsPrompt: string;
    function BuildSummaryPrompt: string;
    function BuildTaskReportPrompt: string;
    function BuildAgentReportPrompt: string;
    function BuildMarkdownExportPrompt: string;
    function BuildJSONValidationPrompt: string;
    function BuildClearConfirmationPrompt: string;

    procedure ValidateSpecificationJSON(AJSON: TJSONObject);
    procedure IntegrateSpecificationJSON(AJSON: TJSONObject);

    procedure ValidateGeneratedTasks(APlanning: TJSONObject);
    procedure ReplaceTasksFromPlanning(APlanning: TJSONObject);
    procedure AppendTasksFromPlanning(APlanning: TJSONObject);
    function TaskIDExists(const ATaskID: string): Boolean;

    procedure ValidateGeneratedAgents(AJSON: TJSONObject);
    procedure ReplaceAgentsFromJSON(AJSON: TJSONObject);

    procedure LoadFirstTaskDescription;

  public
  end;

var
  frmMain: TfrmMain;

implementation

{$R *.lfm}

{ TfrmMain }

procedure TfrmMain.FormCreate(Sender: TObject);
var
  i: TVersionChat;
begin
  AIProject1.ChatGPT := ChatGPT1;
  AIProject1.SimulationMode := False;

  AIProjectLLMConfig1.ChatGPT := ChatGPT1;
  AIProjectLLMConfig1.Project := AIProject1;

  AIProjectStorage1.Project := AIProject1;
  AIProjectTasks1.Project := AIProject1;
  AIProjectSpecification1.Project := AIProject1;

  TaskGrid1.Project := AIProject1;
  StatusPanel1.Project := AIProject1;

  btnAddManualTask.Caption := 'Gerar tarefa com IA';

  //btnCreateDefaultAgents.OnClick := @btnCreateDefaultAgentsClick;
  //btnGenerateSummary.OnClick := @btnGenerateSummaryClick;
  //btnGenerateTaskReport.OnClick := @btnGenerateTaskReportClick;
  //btnGenerateAgentReport.OnClick := @btnGenerateAgentReportClick;
  //btnExportMarkdown.OnClick := @btnExportMarkdownClick;
  //btnExportJSON.OnClick := @btnExportJSONClick;

  cbVersaoIA.Items.Clear;
  for i := Low(TVersionChat) to High(TVersionChat) do
    cbVersaoIA.Items.Add(GetEnumName(TypeInfo(TVersionChat), Ord(i)));

  cbVersaoIA.ItemIndex := Ord(ChatGPT1.TipoChat);

  cbProvider.ItemIndex := 0;
  cbProviderChange(nil);

  chkSalvarToken.Checked := False;

  AIProject1.EnsureProjectStructure;
  RefreshAllViews;

  LogMsg('[OK] Formulário inicializado sem modo simulado.');
end;

procedure TfrmMain.cbProviderChange(Sender: TObject);
begin
  cbModel.Items.Clear;
  edtEndpoint.Text := '';
  edtEndpoint.Enabled := False;

  if SameText(cbProvider.Text, 'OpenAI') then
  begin
    cbModel.Items.Add('gpt-4o');
    cbModel.Items.Add('gpt-4o-mini');
    cbModel.Items.Add('o3-mini');
    cbModel.Items.Add('o1-mini');
    cbModel.Items.Add('o1');
    cbModel.Items.Add('gpt-4-turbo');
    cbModel.Items.Add('gpt-3.5-turbo');
    cbModel.Text := 'gpt-4o-mini';
  end
  else if SameText(cbProvider.Text, 'Gemini') then
  begin
    cbModel.Items.Add('gemini-2.5-flash');
    cbModel.Items.Add('gemini-2.5-pro');
    cbModel.Items.Add('gemini-2.0-flash');
    cbModel.Text := 'gemini-2.5-flash';
  end
  else if SameText(cbProvider.Text, 'Claude') then
  begin
    cbModel.Items.Add('claude-3-5-sonnet-20241022');
    cbModel.Items.Add('claude-3-5-haiku-20241022');
    cbModel.Items.Add('claude-3-opus-20240229');
    cbModel.Text := 'claude-3-5-sonnet-20241022';
  end
  else if SameText(cbProvider.Text, 'OpenRouter') then
  begin
    cbModel.Items.Add('meta-llama/llama-3-8b-instruct:free');
    cbModel.Items.Add('google/gemma-2-9b-it:free');
    cbModel.Items.Add('deepseek/deepseek-r1:free');
    cbModel.Items.Add('meta-llama/llama-3.2-3b-instruct:free');
    cbModel.Text := 'google/gemma-2-9b-it:free';
  end
  else if SameText(cbProvider.Text, 'Cerebras') then
  begin
    cbModel.Items.Add('qwen-3-235b-a22b-instruct-2507');
    cbModel.Text := 'qwen-3-235b-a22b-instruct-2507';
  end
  else if SameText(cbProvider.Text, 'Ollama') then
  begin
    cbModel.Items.Add('llama3.2');
    cbModel.Items.Add('llama3.2:3b');
    cbModel.Items.Add('qwen2.5');
    cbModel.Items.Add('qwen2.5:1.5b');
    cbModel.Items.Add('mistral');
    cbModel.Text := 'llama3.2:3b';
    edtEndpoint.Text := 'http://localhost:11434';
    edtEndpoint.Enabled := True;
  end
  else if SameText(cbProvider.Text, 'LM Studio') then
  begin
    cbModel.Items.Add('local-model');
    cbModel.Text := 'local-model';
    edtEndpoint.Text := 'http://localhost:1234/v1';
    edtEndpoint.Enabled := True;
  end
  else if SameText(cbProvider.Text, 'Local HTTP') then
  begin
    cbModel.Items.Add('local-model');
    cbModel.Text := 'local-model';
    edtEndpoint.Text := 'http://localhost:8080';
    edtEndpoint.Enabled := True;
  end;
end;

procedure TfrmMain.LogMsg(const AMsg: string);
begin
  if Assigned(MemoLog) then
    MemoLog.Lines.Add(FormatDateTime('hh:nn:ss', Now) + ' ' + AMsg);
end;

procedure TfrmMain.RefreshAllViews;
begin
  if Assigned(AIProject1) then
    AIProject1.EnsureProjectStructure;

  if Assigned(TaskGrid1) then
    TaskGrid1.LoadTasks;

  if Assigned(StatusPanel1) then
    StatusPanel1.RefreshStatus;

  if Assigned(MemoJSON) and Assigned(AIProject1.ProjectData) then
    MemoJSON.Text := AIProject1.ProjectData.FormatJSON;
end;

procedure TfrmMain.ValidarConfigIA;
begin
  if Trim(cbProvider.Text) = '' then
    raise Exception.Create('Selecione o provedor de IA.');

  if Trim(cbModel.Text) = '' then
    raise Exception.Create('Informe o modelo.');

  if (SameText(cbProvider.Text, 'OpenAI') or
      SameText(cbProvider.Text, 'Gemini') or
      SameText(cbProvider.Text, 'Claude') or
      SameText(cbProvider.Text, 'OpenRouter') or
      SameText(cbProvider.Text, 'Cerebras')) and
     (Trim(edtToken.Text) = '') then
    raise Exception.Create('Para provedores em nuvem, o Token de API é obrigatório.');

  if (SameText(cbProvider.Text, 'Ollama') or
      SameText(cbProvider.Text, 'LM Studio') or
      SameText(cbProvider.Text, 'Local HTTP')) and
     (Trim(edtEndpoint.Text) = '') then
    raise Exception.Create('Para provedor local, o endpoint é obrigatório.');
end;

procedure TfrmMain.RequireChatGPTReady;
begin
  ValidarConfigIA;

  AIProject1.ChatGPT := ChatGPT1;
  AIProject1.SimulationMode := False;

  btnApplyConfigClick(nil);

  if not Assigned(ChatGPT1) then
    raise Exception.Create('ChatGPT1 não está disponível.');

  if not Assigned(AIProject1.ChatGPT) then
    raise Exception.Create('AIProject1.ChatGPT não está associado ao ChatGPT1.');

  if AIProject1.ChatGPT <> ChatGPT1 then
    raise Exception.Create('AIProject1.ChatGPT precisa apontar para ChatGPT1.');
end;

procedure TfrmMain.ApplyProjectTextToComponent;
begin
  AIProject1.ProjectName := Trim(MemoProjectName.Text);
  AIProject1.Goal := Trim(MemoGoal.Text);
  AIProject1.Constraints := Trim(MemoConstraints.Text);
  AIProject1.ExpectedDeliverables := Trim(MemoDeliverables.Text);
end;

procedure TfrmMain.RequireProjectInput;
begin
  if Trim(MemoProjectName.Text) = '' then
    raise Exception.Create('Informe o nome do projeto.');

  if Trim(MemoGoal.Text) = '' then
    raise Exception.Create('Informe a descrição/objetivo do projeto.');
end;

function TfrmMain.SendPromptWithChatGPT(const APrompt, AContext: string): string;
begin
  Result := '';

  RequireChatGPTReady;

  LogMsg('[INFO] Enviando solicitação ao ChatGPT1: ' + AContext);
  Application.ProcessMessages;

  if ChatGPT1.SendQuestion(APrompt) then
  begin
    Result := ChatGPT1.Response;

    if Trim(Result) = '' then
      raise Exception.Create('ChatGPT1 retornou resposta vazia em: ' + AContext);
  end
  else
  begin
    if Trim(ChatGPT1.Response) <> '' then
      raise Exception.Create('ChatGPT1 falhou em ' + AContext + ': ' + ChatGPT1.Response)
    else
      raise Exception.Create('ChatGPT1 falhou em ' + AContext + '.');
  end;
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

procedure TfrmMain.CopyJSONField(ASource, ADest: TJSONObject; const AName: string);
var
  LData: TJSONData;
begin
  if not Assigned(ASource) then
    Exit;

  if not Assigned(ADest) then
    Exit;

  LData := ASource.Find(AName);

  if Assigned(LData) then
    ReplaceJSONValue(ADest, AName, LData.Clone);
end;

function TfrmMain.ISODate(ADate: TDateTime): string;
begin
  Result := FormatDateTime('yyyy"-"mm"-"dd', ADate);
end;

function TfrmMain.JSONTypeName(AData: TJSONData): string;
begin
  Result := 'nil';

  if not Assigned(AData) then
    Exit;

  case AData.JSONType of
    jtUnknown: Result := 'unknown';
    jtNumber: Result := 'number';
    jtString: Result := 'string';
    jtBoolean: Result := 'boolean';
    jtNull: Result := 'null';
    jtArray: Result := 'array';
    jtObject: Result := 'object';
  else
    Result := 'unknown';
  end;
end;

function TfrmMain.IsAllowedTaskStatus(const AStatus: string): Boolean;
var
  S: string;
begin
  S := LowerCase(Trim(AStatus));

  Result :=
    (S = 'draft') or
    (S = 'confirmed') or
    (S = 'in_progress') or
    (S = 'done') or
    (S = 'blocked') or
    (S = 'canceled');
end;

function TfrmMain.IsAllowedPriority(const APriority: string): Boolean;
var
  S: string;
begin
  S := LowerCase(Trim(APriority));

  Result :=
    (S = 'baixa') or
    (S = 'media') or
    (S = 'alta') or
    (S = 'critica');
end;

function TfrmMain.IsAllowedSkillLevel(const ASkill: string): Boolean;
var
  S: string;
begin
  S := LowerCase(Trim(ASkill));

  Result :=
    (S = 'intern') or
    (S = 'junior') or
    (S = 'mid_level') or
    (S = 'senior');
end;

procedure TfrmMain.RequireStringField(AObj: TJSONObject; const AField, AContext: string);
var
  LData: TJSONData;
begin
  if not Assigned(AObj) then
    raise Exception.Create(AContext + ': objeto JSON não informado.');

  LData := AObj.Find(AField);

  if not Assigned(LData) then
    raise Exception.Create(AContext + ': campo obrigatório ausente: ' + AField);

  if LData.JSONType <> jtString then
    raise Exception.Create(AContext + ': campo ' + AField + ' precisa ser string. Tipo recebido: ' + JSONTypeName(LData));

  if Trim(LData.AsString) = '' then
    raise Exception.Create(AContext + ': campo obrigatório vazio: ' + AField);
end;

procedure TfrmMain.RequireNumberField(AObj: TJSONObject; const AField, AContext: string);
var
  LData: TJSONData;
begin
  if not Assigned(AObj) then
    raise Exception.Create(AContext + ': objeto JSON não informado.');

  LData := AObj.Find(AField);

  if not Assigned(LData) then
    raise Exception.Create(AContext + ': campo obrigatório ausente: ' + AField);

  if LData.JSONType <> jtNumber then
    raise Exception.Create(AContext + ': campo ' + AField + ' precisa ser number. Tipo recebido: ' + JSONTypeName(LData));
end;

procedure TfrmMain.RequireBooleanField(AObj: TJSONObject; const AField, AContext: string);
var
  LData: TJSONData;
begin
  if not Assigned(AObj) then
    raise Exception.Create(AContext + ': objeto JSON não informado.');

  LData := AObj.Find(AField);

  if not Assigned(LData) then
    raise Exception.Create(AContext + ': campo obrigatório ausente: ' + AField);

  if LData.JSONType <> jtBoolean then
    raise Exception.Create(AContext + ': campo ' + AField + ' precisa ser boolean. Tipo recebido: ' + JSONTypeName(LData));
end;

procedure TfrmMain.RequireObjectField(AObj: TJSONObject; const AField, AContext: string);
var
  LData: TJSONData;
begin
  if not Assigned(AObj) then
    raise Exception.Create(AContext + ': objeto JSON não informado.');

  LData := AObj.Find(AField);

  if not Assigned(LData) then
    raise Exception.Create(AContext + ': objeto obrigatório ausente: ' + AField);

  if not (LData is TJSONObject) then
    raise Exception.Create(AContext + ': campo ' + AField + ' precisa ser object. Tipo recebido: ' + JSONTypeName(LData));
end;

procedure TfrmMain.RequireArrayField(AObj: TJSONObject; const AField, AContext: string);
var
  LData: TJSONData;
begin
  if not Assigned(AObj) then
    raise Exception.Create(AContext + ': objeto JSON não informado.');

  LData := AObj.Find(AField);

  if not Assigned(LData) then
    raise Exception.Create(AContext + ': array obrigatório ausente: ' + AField);

  if not (LData is TJSONArray) then
    raise Exception.Create(AContext + ': campo ' + AField + ' precisa ser array. Tipo recebido: ' + JSONTypeName(LData));
end;

function TfrmMain.BuildSpecificationPrompt: string;
begin
  Result :=
    'Atue como analista de sistemas, arquiteto de software e gerente de projetos.' + sLineBreak +
    'Crie uma especificação inicial real do projeto informado pelo usuário.' + sLineBreak +
    'Não crie dados simulados, exemplos genéricos ou placeholders artificiais.' + sLineBreak +
    'Quando uma informação não foi fornecida pelo usuário, escreva claramente "não informado pelo usuário".' + sLineBreak +
    'Responda somente com JSON puro e válido.' + sLineBreak +
    'Não use Markdown. Não use bloco ```json. Não escreva explicações antes ou depois.' + sLineBreak +
    sLineBreak +
    'DADOS INFORMADOS PELO USUÁRIO:' + sLineBreak +
    'Nome do projeto: ' + Trim(MemoProjectName.Text) + sLineBreak +
    'Objetivo/descrição: ' + Trim(MemoGoal.Text) + sLineBreak +
    'Restrições: ' + Trim(MemoConstraints.Text) + sLineBreak +
    'Entregáveis esperados: ' + Trim(MemoDeliverables.Text) + sLineBreak +
    sLineBreak +
    'FORMATO OBRIGATÓRIO:' + sLineBreak +
    '{' + sLineBreak +
    '  "project": {' + sLineBreak +
    '    "name": "nome real do projeto",' + sLineBreak +
    '    "description": "descrição detalhada real",' + sLineBreak +
    '    "goal": "objetivo real",' + sLineBreak +
    '    "context": "contexto real",' + sLineBreak +
    '    "scope": "escopo real",' + sLineBreak +
    '    "constraints": "restrições reais ou não informado pelo usuário",' + sLineBreak +
    '    "expected_deliverables": "entregáveis reais ou não informado pelo usuário"' + sLineBreak +
    '  },' + sLineBreak +
    '  "agile_documents": {' + sLineBreak +
    '    "business_vision": "visão de negócio real",' + sLineBreak +
    '    "functional_requirements": [' + sLineBreak +
    '      {"id":"RF001","title":"título real","description":"descrição real","priority":"alta","status":"draft"}' + sLineBreak +
    '    ],' + sLineBreak +
    '    "non_functional_requirements": [' + sLineBreak +
    '      {"id":"RNF001","title":"título real","description":"descrição real","priority":"alta","status":"draft"}' + sLineBreak +
    '    ],' + sLineBreak +
    '    "stakeholders": [' + sLineBreak +
    '      {"name":"nome ou perfil real","role":"papel real","responsibility":"responsabilidade real","interest_level":"baixo|medio|alto","influence_level":"baixo|medio|alto"}' + sLineBreak +
    '    ],' + sLineBreak +
    '    "risk_map": [' + sLineBreak +
    '      {"id":"R001","title":"risco real","description":"descrição real","impact":"baixo|medio|alto","probability":"baixa|media|alta","mitigation":"mitigação real","status":"open"}' + sLineBreak +
    '    ],' + sLineBreak +
    '    "epics": [' + sLineBreak +
    '      {"id":"E001","title":"épico real","description":"descrição real"}' + sLineBreak +
    '    ],' + sLineBreak +
    '    "user_stories": [' + sLineBreak +
    '      {"id":"US001","title":"história real","description":"descrição real","acceptance_criteria":"critério real"}' + sLineBreak +
    '    ]' + sLineBreak +
    '  }' + sLineBreak +
    '}';
end;

function TfrmMain.BuildTasksPrompt: string;
begin
  Result :=
    'Atue como gerente de projetos técnico.' + sLineBreak +
    'Gere tarefas reais a partir da especificação JSON atual do projeto.' + sLineBreak +
    'Não gere tarefas fake, genéricas, simuladas ou de exemplo.' + sLineBreak +
    'Não preencha campos com valores artificiais.' + sLineBreak +
    'Todos os campos obrigatórios devem ser preenchidos pela IA com base na especificação.' + sLineBreak +
    'Responda somente com JSON puro e válido.' + sLineBreak +
    'Não use Markdown. Não use bloco ```json. Não escreva explicações antes ou depois.' + sLineBreak +
    sLineBreak +
    'REGRAS:' + sLineBreak +
    '1. Gere entre 3 e 8 tarefas reais.' + sLineBreak +
    '2. IDs devem ser T001, T002, T003...' + sLineBreak +
    '3. status permitido: draft, confirmed, in_progress, done, blocked, canceled.' + sLineBreak +
    '4. priority permitido: baixa, media, alta, critica.' + sLineBreak +
    '5. suggested_skill_level e assigned_skill_level permitidos: intern, junior, mid_level, senior.' + sLineBreak +
    '6. Datas devem usar formato ISO yyyy-mm-dd, a partir de ' + ISODate(Date) + '.' + sLineBreak +
    '7. Cada tarefa precisa ter estimated_hours com intern, junior, mid_level e senior.' + sLineBreak +
    sLineBreak +
    'ESPECIFICAÇÃO ATUAL DO PROJETO:' + sLineBreak +
    AIProject1.ProjectData.FormatJSON + sLineBreak +
    sLineBreak +
    'FORMATO OBRIGATÓRIO:' + sLineBreak +
    '{' + sLineBreak +
    '  "planning": {' + sLineBreak +
    '    "tasks": [' + sLineBreak +
    '      {' + sLineBreak +
    '        "id": "T001",' + sLineBreak +
    '        "epic_id": "E001",' + sLineBreak +
    '        "title": "título real da tarefa",' + sLineBreak +
    '        "description": "descrição real da tarefa",' + sLineBreak +
    '        "long_description": "especificação detalhada real da tarefa",' + sLineBreak +
    '        "acceptance_criteria": "critério real de aceite",' + sLineBreak +
    '        "priority": "alta",' + sLineBreak +
    '        "status": "draft",' + sLineBreak +
    '        "dependency_type": "serial",' + sLineBreak +
    '        "dependencies": [],' + sLineBreak +
    '        "can_run_in_parallel": false,' + sLineBreak +
    '        "estimated_hours": {"intern": 8, "junior": 6, "mid_level": 4, "senior": 2},' + sLineBreak +
    '        "suggested_skill_level": "mid_level",' + sLineBreak +
    '        "assigned_skill_level": "mid_level",' + sLineBreak +
    '        "assigned_to": "agente ou perfil responsável real",' + sLineBreak +
    '        "responsible_profile": "DEV",' + sLineBreak +
    '        "planned_start_date": "' + ISODate(Date) + '",' + sLineBreak +
    '        "planned_end_date": "' + ISODate(Date + 1) + '",' + sLineBreak +
    '        "estimated_duration_days": 1,' + sLineBreak +
    '        "progress_percent": 0,' + sLineBreak +
    '        "deliverable": "entregável real",' + sLineBreak +
    '        "notes": "observações reais ou não informado pelo usuário",' + sLineBreak +
    '        "revision_created": 1,' + sLineBreak +
    '        "revision_updated": 1' + sLineBreak +
    '      }' + sLineBreak +
    '    ]' + sLineBreak +
    '  }' + sLineBreak +
    '}';
end;

function TfrmMain.BuildSingleTaskPrompt: string;
begin
  Result :=
    'Atue como gerente de projetos técnico.' + sLineBreak +
    'Gere exatamente 1 tarefa real para o projeto atual.' + sLineBreak +
    'A tarefa deve ser baseada no texto informado pelo usuário e na especificação atual.' + sLineBreak +
    'Não crie tarefa fake, manual, simulada ou genérica.' + sLineBreak +
    'Responda somente com JSON puro e válido.' + sLineBreak +
    'Não use Markdown. Não use bloco ```json. Não escreva explicações antes ou depois.' + sLineBreak +
    sLineBreak +
    'Texto informado para a nova tarefa:' + sLineBreak +
    Trim(MemoTaskDescription.Text) + sLineBreak +
    sLineBreak +
    'Projeto atual:' + sLineBreak +
    AIProject1.ProjectData.FormatJSON + sLineBreak +
    sLineBreak +
    'Regras:' + sLineBreak +
    '1. Gere exatamente uma tarefa dentro de planning.tasks.' + sLineBreak +
    '2. Use um ID novo que ainda não exista no JSON atual.' + sLineBreak +
    '3. status permitido: draft, confirmed, in_progress, done, blocked, canceled.' + sLineBreak +
    '4. priority permitido: baixa, media, alta, critica.' + sLineBreak +
    '5. skill_level permitido: intern, junior, mid_level, senior.' + sLineBreak +
    sLineBreak +
    'Formato obrigatório igual ao de geração de tarefas:' + sLineBreak +
    BuildTasksPrompt;
end;

function TfrmMain.BuildAgentsPrompt: string;
begin
  Result :=
    'Atue como gestor de equipe técnica.' + sLineBreak +
    'Crie agentes reais necessários para executar o projeto atual.' + sLineBreak +
    'Não use agentes fake, genéricos ou simulados.' + sLineBreak +
    'Os agentes devem ser derivados da especificação e das tarefas atuais.' + sLineBreak +
    'Responda somente com JSON puro e válido.' + sLineBreak +
    'Não use Markdown. Não use bloco ```json. Não escreva explicações antes ou depois.' + sLineBreak +
    sLineBreak +
    'Projeto atual:' + sLineBreak +
    AIProject1.ProjectData.FormatJSON + sLineBreak +
    sLineBreak +
    'FORMATO OBRIGATÓRIO:' + sLineBreak +
    '{' + sLineBreak +
    '  "agents": [' + sLineBreak +
    '    {' + sLineBreak +
    '      "id": "AG001",' + sLineBreak +
    '      "name": "nome real do agente/perfil",' + sLineBreak +
    '      "profile": "DEV|UI|DBA|QA|INFRA|KEYUSER|OPERADOR|GESTOR",' + sLineBreak +
    '      "responsibility": "responsabilidade real no projeto",' + sLineBreak +
    '      "skills": ["habilidade real"],' + sLineBreak +
    '      "related_tasks": ["T001"]' + sLineBreak +
    '    }' + sLineBreak +
    '  ]' + sLineBreak +
    '}';
end;

function TfrmMain.BuildSummaryPrompt: string;
begin
  Result :=
    'Gere um resumo executivo real do projeto abaixo.' + sLineBreak +
    'Não invente dados ausentes. Quando faltar informação, diga que não foi informado.' + sLineBreak +
    'Use português do Brasil.' + sLineBreak +
    sLineBreak +
    'JSON atual do projeto:' + sLineBreak +
    AIProject1.ProjectData.FormatJSON;
end;

function TfrmMain.BuildTaskReportPrompt: string;
begin
  Result :=
    'Gere um relatório real das tarefas do projeto abaixo.' + sLineBreak +
    'Inclua status, prioridades, dependências, riscos de execução e próximos passos.' + sLineBreak +
    'Não invente tarefas ou informações não presentes no JSON.' + sLineBreak +
    'Use português do Brasil.' + sLineBreak +
    sLineBreak +
    'JSON atual do projeto:' + sLineBreak +
    AIProject1.ProjectData.FormatJSON;
end;

function TfrmMain.BuildAgentReportPrompt: string;
begin
  Result :=
    'Gere um relatório real dos agentes/perfis do projeto abaixo.' + sLineBreak +
    'Relacione responsabilidades, tarefas associadas e lacunas de equipe.' + sLineBreak +
    'Não invente agentes ou informações não presentes no JSON.' + sLineBreak +
    'Use português do Brasil.' + sLineBreak +
    sLineBreak +
    'JSON atual do projeto:' + sLineBreak +
    AIProject1.ProjectData.FormatJSON;
end;

function TfrmMain.BuildMarkdownExportPrompt: string;
begin
  Result :=
    'Converta o JSON real do projeto abaixo para um documento Markdown.' + sLineBreak +
    'Não invente dados.' + sLineBreak +
    'Não adicione tarefas, agentes, requisitos ou riscos que não existam no JSON.' + sLineBreak +
    'Use português do Brasil.' + sLineBreak +
    sLineBreak +
    'JSON atual do projeto:' + sLineBreak +
    AIProject1.ProjectData.FormatJSON;
end;

function TfrmMain.BuildJSONValidationPrompt: string;
begin
  Result :=
    'Valide o JSON real do projeto abaixo.' + sLineBreak +
    'Não reescreva o projeto. Não invente dados.' + sLineBreak +
    'Responda somente com JSON puro no formato:' + sLineBreak +
    '{"valid":true,"errors":[],"warnings":[]}' + sLineBreak +
    sLineBreak +
    'JSON atual do projeto:' + sLineBreak +
    AIProject1.ProjectData.FormatJSON;
end;

function TfrmMain.BuildClearConfirmationPrompt: string;
begin
  Result :=
    'O usuário solicitou limpar o projeto local atual no demo.' + sLineBreak +
    'Não gere nenhum dado novo.' + sLineBreak +
    'Responda somente com o JSON puro:' + sLineBreak +
    '{"clear_confirmed":true}';
end;

procedure TfrmMain.ValidateSpecificationJSON(AJSON: TJSONObject);
var
  LProject: TJSONObject;
  LDocs: TJSONObject;
begin
  if not Assigned(AJSON) then
    raise Exception.Create('JSON da especificação não informado.');

  if not (AJSON.Find('project') is TJSONObject) then
    raise Exception.Create('A especificação não contém objeto project.');

  if not (AJSON.Find('agile_documents') is TJSONObject) then
    raise Exception.Create('A especificação não contém objeto agile_documents.');

  LProject := TJSONObject(AJSON.Find('project'));
  LDocs := TJSONObject(AJSON.Find('agile_documents'));

  RequireStringField(LProject, 'name', 'project');
  RequireStringField(LProject, 'description', 'project');
  RequireStringField(LProject, 'goal', 'project');
  RequireStringField(LProject, 'context', 'project');
  RequireStringField(LProject, 'scope', 'project');
  RequireStringField(LProject, 'constraints', 'project');
  RequireStringField(LProject, 'expected_deliverables', 'project');

  RequireStringField(LDocs, 'business_vision', 'agile_documents');
  RequireArrayField(LDocs, 'functional_requirements', 'agile_documents');
  RequireArrayField(LDocs, 'non_functional_requirements', 'agile_documents');
  RequireArrayField(LDocs, 'stakeholders', 'agile_documents');
  RequireArrayField(LDocs, 'risk_map', 'agile_documents');
  RequireArrayField(LDocs, 'epics', 'agile_documents');
  RequireArrayField(LDocs, 'user_stories', 'agile_documents');

  if TJSONArray(LDocs.Find('functional_requirements')).Count = 0 then
    raise Exception.Create('A IA retornou functional_requirements vazio.');

  if TJSONArray(LDocs.Find('non_functional_requirements')).Count = 0 then
    raise Exception.Create('A IA retornou non_functional_requirements vazio.');

  if TJSONArray(LDocs.Find('epics')).Count = 0 then
    raise Exception.Create('A IA retornou epics vazio.');
end;

procedure TfrmMain.IntegrateSpecificationJSON(AJSON: TJSONObject);
var
  LSourceProject: TJSONObject;
  LSourceDocs: TJSONObject;
  LDestProject: TJSONObject;
  LDestDocs: TJSONObject;
begin
  ValidateSpecificationJSON(AJSON);

  AIProject1.EnsureProjectStructure;

  LSourceProject := TJSONObject(AJSON.Find('project'));
  LSourceDocs := TJSONObject(AJSON.Find('agile_documents'));

  if not (AIProject1.ProjectData.Find('project') is TJSONObject) then
    ReplaceJSONValue(AIProject1.ProjectData, 'project', TJSONObject.Create);

  if not (AIProject1.ProjectData.Find('agile_documents') is TJSONObject) then
    ReplaceJSONValue(AIProject1.ProjectData, 'agile_documents', TJSONObject.Create);

  LDestProject := TJSONObject(AIProject1.ProjectData.Find('project'));
  LDestDocs := TJSONObject(AIProject1.ProjectData.Find('agile_documents'));

  CopyJSONField(LSourceProject, LDestProject, 'name');
  CopyJSONField(LSourceProject, LDestProject, 'description');
  CopyJSONField(LSourceProject, LDestProject, 'goal');
  CopyJSONField(LSourceProject, LDestProject, 'context');
  CopyJSONField(LSourceProject, LDestProject, 'scope');
  CopyJSONField(LSourceProject, LDestProject, 'constraints');
  CopyJSONField(LSourceProject, LDestProject, 'expected_deliverables');

  CopyJSONField(LSourceDocs, LDestDocs, 'business_vision');
  CopyJSONField(LSourceDocs, LDestDocs, 'functional_requirements');
  CopyJSONField(LSourceDocs, LDestDocs, 'non_functional_requirements');
  CopyJSONField(LSourceDocs, LDestDocs, 'stakeholders');
  CopyJSONField(LSourceDocs, LDestDocs, 'risk_map');
  CopyJSONField(LSourceDocs, LDestDocs, 'epics');
  CopyJSONField(LSourceDocs, LDestDocs, 'user_stories');

  AIProject1.ProjectName := LDestProject.Get('name', '');
  AIProject1.Description := LDestProject.Get('description', '');
  AIProject1.Goal := LDestProject.Get('goal', '');
  AIProject1.Context := LDestProject.Get('context', '');
  AIProject1.Scope := LDestProject.Get('scope', '');
  AIProject1.Constraints := LDestProject.Get('constraints', '');
  AIProject1.ExpectedDeliverables := LDestProject.Get('expected_deliverables', '');

  MemoProjectName.Text := AIProject1.ProjectName;
  MemoGoal.Text := AIProject1.Goal;
  MemoConstraints.Text := AIProject1.Constraints;
  MemoDeliverables.Text := AIProject1.ExpectedDeliverables;
end;

procedure TfrmMain.ValidateGeneratedTasks(APlanning: TJSONObject);
var
  LTasks: TJSONArray;
  LTask: TJSONObject;
  LHours: TJSONObject;
  I: Integer;
  LID: string;
  LIDs: TStringList;
begin
  if not Assigned(APlanning) then
    raise Exception.Create('Objeto planning não encontrado no JSON retornado pela IA.');

  if not (APlanning.Find('tasks') is TJSONArray) then
    raise Exception.Create('Array planning.tasks não encontrado no JSON retornado pela IA.');

  LTasks := TJSONArray(APlanning.Find('tasks'));

  if LTasks.Count = 0 then
    raise Exception.Create('A IA retornou planning.tasks vazio.');

  LIDs := TStringList.Create;
  try
    for I := 0 to LTasks.Count - 1 do
    begin
      if not (LTasks.Items[I] is TJSONObject) then
        raise Exception.Create('planning.tasks[' + IntToStr(I) + '] não é objeto JSON.');

      LTask := LTasks.Objects[I];

      RequireStringField(LTask, 'id', 'planning.tasks[' + IntToStr(I) + ']');
      RequireStringField(LTask, 'epic_id', 'planning.tasks[' + IntToStr(I) + ']');
      RequireStringField(LTask, 'title', 'planning.tasks[' + IntToStr(I) + ']');
      RequireStringField(LTask, 'description', 'planning.tasks[' + IntToStr(I) + ']');
      RequireStringField(LTask, 'long_description', 'planning.tasks[' + IntToStr(I) + ']');
      RequireStringField(LTask, 'acceptance_criteria', 'planning.tasks[' + IntToStr(I) + ']');
      RequireStringField(LTask, 'priority', 'planning.tasks[' + IntToStr(I) + ']');
      RequireStringField(LTask, 'status', 'planning.tasks[' + IntToStr(I) + ']');
      RequireStringField(LTask, 'dependency_type', 'planning.tasks[' + IntToStr(I) + ']');
      RequireArrayField(LTask, 'dependencies', 'planning.tasks[' + IntToStr(I) + ']');
      RequireBooleanField(LTask, 'can_run_in_parallel', 'planning.tasks[' + IntToStr(I) + ']');
      RequireObjectField(LTask, 'estimated_hours', 'planning.tasks[' + IntToStr(I) + ']');
      RequireStringField(LTask, 'suggested_skill_level', 'planning.tasks[' + IntToStr(I) + ']');
      RequireStringField(LTask, 'assigned_skill_level', 'planning.tasks[' + IntToStr(I) + ']');
      RequireStringField(LTask, 'assigned_to', 'planning.tasks[' + IntToStr(I) + ']');
      RequireStringField(LTask, 'responsible_profile', 'planning.tasks[' + IntToStr(I) + ']');
      RequireStringField(LTask, 'planned_start_date', 'planning.tasks[' + IntToStr(I) + ']');
      RequireStringField(LTask, 'planned_end_date', 'planning.tasks[' + IntToStr(I) + ']');
      RequireNumberField(LTask, 'estimated_duration_days', 'planning.tasks[' + IntToStr(I) + ']');
      RequireNumberField(LTask, 'progress_percent', 'planning.tasks[' + IntToStr(I) + ']');
      RequireStringField(LTask, 'deliverable', 'planning.tasks[' + IntToStr(I) + ']');
      RequireStringField(LTask, 'notes', 'planning.tasks[' + IntToStr(I) + ']');
      RequireNumberField(LTask, 'revision_created', 'planning.tasks[' + IntToStr(I) + ']');
      RequireNumberField(LTask, 'revision_updated', 'planning.tasks[' + IntToStr(I) + ']');

      LID := Trim(LTask.Get('id', ''));

      if Copy(UpperCase(LID), 1, 1) <> 'T' then
        raise Exception.Create('ID inválido em planning.tasks[' + IntToStr(I) + ']: ' + LID);

      if LIDs.IndexOf(LID) >= 0 then
        raise Exception.Create('ID duplicado retornado pela IA: ' + LID);

      LIDs.Add(LID);

      if not IsAllowedPriority(LTask.Get('priority', '')) then
        raise Exception.Create('Prioridade inválida em ' + LID + ': ' + LTask.Get('priority', ''));

      if not IsAllowedTaskStatus(LTask.Get('status', '')) then
        raise Exception.Create('Status inválido em ' + LID + ': ' + LTask.Get('status', ''));

      if not IsAllowedSkillLevel(LTask.Get('suggested_skill_level', '')) then
        raise Exception.Create('suggested_skill_level inválido em ' + LID + ': ' + LTask.Get('suggested_skill_level', ''));

      if not IsAllowedSkillLevel(LTask.Get('assigned_skill_level', '')) then
        raise Exception.Create('assigned_skill_level inválido em ' + LID + ': ' + LTask.Get('assigned_skill_level', ''));

      LHours := TJSONObject(LTask.Find('estimated_hours'));
      RequireNumberField(LHours, 'intern', 'estimated_hours de ' + LID);
      RequireNumberField(LHours, 'junior', 'estimated_hours de ' + LID);
      RequireNumberField(LHours, 'mid_level', 'estimated_hours de ' + LID);
      RequireNumberField(LHours, 'senior', 'estimated_hours de ' + LID);
    end;
  finally
    LIDs.Free;
  end;
end;

procedure TfrmMain.ReplaceTasksFromPlanning(APlanning: TJSONObject);
var
  LProjectPlanning: TJSONObject;
  LIndex: Integer;
begin
  ValidateGeneratedTasks(APlanning);

  AIProject1.EnsureProjectStructure;

  if not (AIProject1.ProjectData.FindPath('planning') is TJSONObject) then
    raise Exception.Create('ProjectData.planning não encontrado.');

  LProjectPlanning := TJSONObject(AIProject1.ProjectData.FindPath('planning'));

  LIndex := LProjectPlanning.IndexOfName('tasks');

  if LIndex >= 0 then
    LProjectPlanning.Delete(LIndex);

  LProjectPlanning.Add('tasks', APlanning.Find('tasks').Clone);
end;

procedure TfrmMain.AppendTasksFromPlanning(APlanning: TJSONObject);
var
  LProjectPlanning: TJSONObject;
  LProjectTasks: TJSONArray;
  LNewTasks: TJSONArray;
  LTask: TJSONObject;
  I: Integer;
  LID: string;
begin
  ValidateGeneratedTasks(APlanning);

  AIProject1.EnsureProjectStructure;

  if not (AIProject1.ProjectData.FindPath('planning') is TJSONObject) then
    raise Exception.Create('ProjectData.planning não encontrado.');

  LProjectPlanning := TJSONObject(AIProject1.ProjectData.FindPath('planning'));

  if not (LProjectPlanning.Find('tasks') is TJSONArray) then
  begin
    if LProjectPlanning.IndexOfName('tasks') >= 0 then
      LProjectPlanning.Delete(LProjectPlanning.IndexOfName('tasks'));

    LProjectPlanning.Add('tasks', TJSONArray.Create);
  end;

  LProjectTasks := TJSONArray(LProjectPlanning.Find('tasks'));
  LNewTasks := TJSONArray(APlanning.Find('tasks'));

  for I := 0 to LNewTasks.Count - 1 do
  begin
    LTask := LNewTasks.Objects[I];
    LID := LTask.Get('id', '');

    if TaskIDExists(LID) then
      raise Exception.Create('A IA retornou ID de tarefa já existente: ' + LID);

    LProjectTasks.Add(LTask.Clone);
  end;
end;

function TfrmMain.TaskIDExists(const ATaskID: string): Boolean;
var
  LTasks: TJSONArray;
  I: Integer;
begin
  Result := False;

  if not Assigned(AIProject1) or not Assigned(AIProject1.ProjectData) then
    Exit;

  if not (AIProject1.ProjectData.FindPath('planning.tasks') is TJSONArray) then
    Exit;

  LTasks := TJSONArray(AIProject1.ProjectData.FindPath('planning.tasks'));

  for I := 0 to LTasks.Count - 1 do
  begin
    if (LTasks.Items[I] is TJSONObject) and
       SameText(TJSONObject(LTasks.Items[I]).Get('id', ''), ATaskID) then
    begin
      Result := True;
      Exit;
    end;
  end;
end;

procedure TfrmMain.ValidateGeneratedAgents(AJSON: TJSONObject);
var
  LAgents: TJSONArray;
  LAgent: TJSONObject;
  I: Integer;
begin
  if not Assigned(AJSON) then
    raise Exception.Create('JSON de agentes não informado.');

  if not (AJSON.Find('agents') is TJSONArray) then
    raise Exception.Create('A IA não retornou o array agents.');

  LAgents := TJSONArray(AJSON.Find('agents'));

  if LAgents.Count = 0 then
    raise Exception.Create('A IA retornou agents vazio.');

  for I := 0 to LAgents.Count - 1 do
  begin
    if not (LAgents.Items[I] is TJSONObject) then
      raise Exception.Create('agents[' + IntToStr(I) + '] não é objeto JSON.');

    LAgent := LAgents.Objects[I];

    RequireStringField(LAgent, 'id', 'agents[' + IntToStr(I) + ']');
    RequireStringField(LAgent, 'name', 'agents[' + IntToStr(I) + ']');
    RequireStringField(LAgent, 'profile', 'agents[' + IntToStr(I) + ']');
    RequireStringField(LAgent, 'responsibility', 'agents[' + IntToStr(I) + ']');
    RequireArrayField(LAgent, 'skills', 'agents[' + IntToStr(I) + ']');
    RequireArrayField(LAgent, 'related_tasks', 'agents[' + IntToStr(I) + ']');
  end;
end;

procedure TfrmMain.ReplaceAgentsFromJSON(AJSON: TJSONObject);
var
  LIndex: Integer;
begin
  ValidateGeneratedAgents(AJSON);

  AIProject1.EnsureProjectStructure;

  LIndex := AIProject1.ProjectData.IndexOfName('agents');

  if LIndex >= 0 then
    AIProject1.ProjectData.Delete(LIndex);

  AIProject1.ProjectData.Add('agents', AJSON.Find('agents').Clone);
end;

procedure TfrmMain.LoadFirstTaskDescription;
begin
  if Assigned(TaskGrid1) and (TaskGrid1.RowCount > 1) then
  begin
    TaskGrid1.Row := 1;

    if Assigned(MemoTaskDescription) then
      MemoTaskDescription.Text := AIProjectTasks1.TaskLongDescription[TaskGrid1.Cells[0, 1]];
  end;
end;

procedure TfrmMain.btnApplyConfigClick(Sender: TObject);
begin
  try
    ValidarConfigIA;

    if SameText(cbProvider.Text, 'OpenAI') then
      AIProjectLLMConfig1.Provider := AIP_OPENAI
    else if SameText(cbProvider.Text, 'Gemini') then
      AIProjectLLMConfig1.Provider := AIP_GEMINI
    else if SameText(cbProvider.Text, 'Claude') then
      AIProjectLLMConfig1.Provider := AIP_CLAUDE
    else if SameText(cbProvider.Text, 'OpenRouter') then
      AIProjectLLMConfig1.Provider := AIP_OPENROUTER
    else if SameText(cbProvider.Text, 'Cerebras') then
      AIProjectLLMConfig1.Provider := AIP_CEREBRAS
    else
      AIProjectLLMConfig1.Provider := AIP_LOCAL;

    AIProjectLLMConfig1.Model := Trim(cbModel.Text);
    AIProjectLLMConfig1.Token := Trim(edtToken.Text);
    AIProjectLLMConfig1.Endpoint := Trim(edtEndpoint.Text);
    AIProjectLLMConfig1.SaveToken := chkSalvarToken.Checked;
    AIProjectStorage1.SaveToken := chkSalvarToken.Checked;

    AIProjectLLMConfig1.ApplyToProject;

    ChatGPT1.CustomModel := Trim(cbModel.Text);
    ChatGPT1.TOKEN := Trim(edtToken.Text);

    if Trim(edtEndpoint.Text) <> '' then
      ChatGPT1.LocalIP := Trim(edtEndpoint.Text);

    if cbVersaoIA.ItemIndex >= 0 then
      ChatGPT1.TipoChat := TVersionChat(cbVersaoIA.ItemIndex);

    AIProject1.ChatGPT := ChatGPT1;
    AIProject1.SimulationMode := False;

    LogMsg('[OK] Configuração aplicada ao ChatGPT1. Provedor=' + cbProvider.Text + ', Modelo=' + cbModel.Text);
  except
    on E: Exception do
      LogMsg('[ERRO] Configuração inválida: ' + E.Message);
  end;
end;

procedure TfrmMain.btnTestConnectionClick(Sender: TObject);
var
  LResponse: string;
begin
  try
    LResponse := SendPromptWithChatGPT(
      'Responda somente com o texto OK.',
      'teste de conexão'
    );

    LogMsg('[OK] ChatGPT1 respondeu: ' + LResponse);
  except
    on E: Exception do
      LogMsg('[ERRO] Falha ao testar ChatGPT1: ' + E.Message);
  end;
end;

procedure TfrmMain.btnGenerateDescriptionClick(Sender: TObject);
var
  LResponse: string;
  LJSONText: string;
  LData: TJSONData;
begin
  LData := nil;

  try
    RequireProjectInput;
    ApplyProjectTextToComponent;

    LResponse := SendPromptWithChatGPT(
      BuildSpecificationPrompt,
      'geração de especificação do projeto'
    );

    LJSONText := ExtractJSONFromAIResponse(LResponse);
    LData := GetJSON(LJSONText);

    if not (LData is TJSONObject) then
      raise Exception.Create('A especificação retornada pela IA não é um objeto JSON.');

    IntegrateSpecificationJSON(TJSONObject(LData));

    MemoReport.Text := BuildSummaryPrompt;
    RefreshAllViews;

    LogMsg('[OK] Especificação real gerada pelo ChatGPT1 e incorporada ao projeto.');
  except
    on E: Exception do
    begin
      LogMsg('[ERRO] Falha ao gerar especificação: ' + E.Message);

      if Trim(LResponse) <> '' then
      begin
        LogMsg('[DEBUG] Resposta original do ChatGPT1:');
        MemoLog.Lines.Add(LResponse);
      end;
    end;
  end;

  LData.Free;
end;

procedure TfrmMain.btnGenerateTasksClick(Sender: TObject);
var
  LResponse: string;
  LJSONText: string;
  LData: TJSONData;
  LJSON: TJSONObject;
  LPlanning: TJSONObject;
begin
  LData := nil;

  try
    RequireProjectInput;
    ApplyProjectTextToComponent;
    AIProject1.EnsureProjectStructure;

    LResponse := SendPromptWithChatGPT(
      BuildTasksPrompt,
      'geração de tarefas do projeto'
    );

    LJSONText := ExtractJSONFromAIResponse(LResponse);
    LData := GetJSON(LJSONText);

    if not (LData is TJSONObject) then
      raise Exception.Create('A resposta de tarefas da IA não retornou um objeto JSON.');

    LJSON := TJSONObject(LData);

    if not (LJSON.Find('planning') is TJSONObject) then
      raise Exception.Create('A resposta da IA não contém o objeto planning.');

    LPlanning := TJSONObject(LJSON.Find('planning'));

    ReplaceTasksFromPlanning(LPlanning);

    if not AIProjectTasks1.RecalculateEstimates then
      raise Exception.Create(AIProjectTasks1.LastError);

    RefreshAllViews;
    LoadFirstTaskDescription;

    LogMsg('[OK] Tarefas reais geradas pelo ChatGPT1 e incorporadas ao projeto.');
  except
    on E: Exception do
    begin
      LogMsg('[ERRO] Falha ao gerar tarefas: ' + E.Message);

      if Trim(LResponse) <> '' then
      begin
        LogMsg('[DEBUG] Resposta original do ChatGPT1:');
        MemoLog.Lines.Add(LResponse);
      end;
    end;
  end;

  LData.Free;
end;

procedure TfrmMain.btnAddManualTaskClick(Sender: TObject);
var
  LResponse: string;
  LJSONText: string;
  LData: TJSONData;
  LJSON: TJSONObject;
  LPlanning: TJSONObject;
begin
  LData := nil;

  try
    RequireProjectInput;
    ApplyProjectTextToComponent;
    AIProject1.EnsureProjectStructure;

    if Trim(MemoTaskDescription.Text) = '' then
      raise Exception.Create('Digite no MemoTaskDescription a necessidade da nova tarefa.');

    LResponse := SendPromptWithChatGPT(
      BuildSingleTaskPrompt,
      'geração de uma nova tarefa pelo ChatGPT1'
    );

    LJSONText := ExtractJSONFromAIResponse(LResponse);
    LData := GetJSON(LJSONText);

    if not (LData is TJSONObject) then
      raise Exception.Create('A resposta da nova tarefa não retornou um objeto JSON.');

    LJSON := TJSONObject(LData);

    if not (LJSON.Find('planning') is TJSONObject) then
      raise Exception.Create('A resposta da nova tarefa não contém planning.');

    LPlanning := TJSONObject(LJSON.Find('planning'));

    AppendTasksFromPlanning(LPlanning);

    if not AIProjectTasks1.RecalculateEstimates then
      raise Exception.Create(AIProjectTasks1.LastError);

    RefreshAllViews;
    LoadFirstTaskDescription;

    LogMsg('[OK] Nova tarefa gerada pelo ChatGPT1. Nenhuma tarefa manual/fake foi criada.');
  except
    on E: Exception do
    begin
      LogMsg('[ERRO] Falha ao gerar nova tarefa com ChatGPT1: ' + E.Message);

      if Trim(LResponse) <> '' then
      begin
        LogMsg('[DEBUG] Resposta original do ChatGPT1:');
        MemoLog.Lines.Add(LResponse);
      end;
    end;
  end;

  LData.Free;
end;

procedure TfrmMain.btnCreateDefaultAgentsClick(Sender: TObject);
var
  LResponse: string;
  LJSONText: string;
  LData: TJSONData;
begin
  LData := nil;

  try
    RequireProjectInput;
    ApplyProjectTextToComponent;
    AIProject1.EnsureProjectStructure;

    LResponse := SendPromptWithChatGPT(
      BuildAgentsPrompt,
      'geração de agentes do projeto'
    );

    LJSONText := ExtractJSONFromAIResponse(LResponse);
    LData := GetJSON(LJSONText);

    if not (LData is TJSONObject) then
      raise Exception.Create('A resposta de agentes não retornou um objeto JSON.');

    ReplaceAgentsFromJSON(TJSONObject(LData));

    RefreshAllViews;

    LogMsg('[OK] Agentes reais gerados pelo ChatGPT1 e incorporados ao projeto.');
  except
    on E: Exception do
    begin
      LogMsg('[ERRO] Falha ao gerar agentes com ChatGPT1: ' + E.Message);

      if Trim(LResponse) <> '' then
      begin
        LogMsg('[DEBUG] Resposta original do ChatGPT1:');
        MemoLog.Lines.Add(LResponse);
      end;
    end;
  end;

  LData.Free;
end;

procedure TfrmMain.btnGenerateSummaryClick(Sender: TObject);
var
  LResponse: string;
begin
  try
    AIProject1.EnsureProjectStructure;

    LResponse := SendPromptWithChatGPT(
      BuildSummaryPrompt,
      'resumo executivo do projeto'
    );

    MemoReport.Text := LResponse;
    LogMsg('[OK] Resumo gerado pelo ChatGPT1.');
  except
    on E: Exception do
      LogMsg('[ERRO] Falha ao gerar resumo: ' + E.Message);
  end;
end;

procedure TfrmMain.btnGenerateTaskReportClick(Sender: TObject);
var
  LResponse: string;
begin
  try
    AIProject1.EnsureProjectStructure;

    LResponse := SendPromptWithChatGPT(
      BuildTaskReportPrompt,
      'relatório de tarefas'
    );

    MemoReport.Text := LResponse;
    LogMsg('[OK] Relatório de tarefas gerado pelo ChatGPT1.');
  except
    on E: Exception do
      LogMsg('[ERRO] Falha ao gerar relatório de tarefas: ' + E.Message);
  end;
end;

procedure TfrmMain.btnGenerateAgentReportClick(Sender: TObject);
var
  LResponse: string;
begin
  try
    AIProject1.EnsureProjectStructure;

    LResponse := SendPromptWithChatGPT(
      BuildAgentReportPrompt,
      'relatório de agentes'
    );

    MemoReport.Text := LResponse;
    LogMsg('[OK] Relatório de agentes gerado pelo ChatGPT1.');
  except
    on E: Exception do
      LogMsg('[ERRO] Falha ao gerar relatório de agentes: ' + E.Message);
  end;
end;

procedure TfrmMain.btnExportMarkdownClick(Sender: TObject);
var
  LResponse: string;
begin
  try
    AIProject1.EnsureProjectStructure;

    LResponse := SendPromptWithChatGPT(
      BuildMarkdownExportPrompt,
      'exportação Markdown'
    );

    MemoReport.Text := LResponse;
    LogMsg('[OK] Markdown gerado pelo ChatGPT1 a partir do JSON real.');
  except
    on E: Exception do
      LogMsg('[ERRO] Falha ao exportar Markdown: ' + E.Message);
  end;
end;

procedure TfrmMain.btnExportJSONClick(Sender: TObject);
var
  LResponse: string;
begin
  try
    AIProject1.EnsureProjectStructure;

    LResponse := SendPromptWithChatGPT(
      BuildJSONValidationPrompt,
      'validação do JSON do projeto'
    );

    MemoJSON.Text := AIProject1.ProjectData.FormatJSON;
    MemoReport.Text := LResponse;

    LogMsg('[OK] JSON real exibido e validado pelo ChatGPT1.');
  except
    on E: Exception do
      LogMsg('[ERRO] Falha ao validar/exportar JSON: ' + E.Message);
  end;
end;

procedure TfrmMain.btnSalvarProjetoClick(Sender: TObject);
var
  LValidation: string;
begin
  try
    AIProject1.EnsureProjectStructure;

    LValidation := SendPromptWithChatGPT(
      BuildJSONValidationPrompt,
      'validação antes de salvar'
    );

    MemoReport.Text := LValidation;

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
var
  LResponse: string;
begin
  try
    if AIProjectStorage1.LoadProjectFromFile('project_tasklist_demo.aiproj.json') then
    begin
      AIProject1.ChatGPT := ChatGPT1;
      AIProject1.SimulationMode := False;
      AIProject1.EnsureProjectStructure;

      RefreshAllViews;

      LResponse := SendPromptWithChatGPT(
        BuildSummaryPrompt,
        'resumo do projeto carregado'
      );

      MemoReport.Text := LResponse;

      LogMsg('[OK] Projeto carregado e resumido pelo ChatGPT1.');
    end
    else
      LogMsg('[ERRO] Falha ao carregar projeto: ' + AIProjectStorage1.LastError);
  except
    on E: Exception do
      LogMsg('[ERRO] Falha ao carregar projeto: ' + E.Message);
  end;
end;

procedure TfrmMain.btnClearProjectClick(Sender: TObject);
var
  LResponse: string;
begin
  try
    if MessageDlg(
      'Confirmação',
      'Tem certeza que deseja limpar todo o projeto e começar do zero?',
      mtConfirmation,
      [mbYes, mbNo],
      0
    ) <> mrYes then
      Exit;

    LResponse := SendPromptWithChatGPT(
      BuildClearConfirmationPrompt,
      'confirmação de limpeza do projeto'
    );

    if Pos('"clear_confirmed":true', StringReplace(LowerCase(LResponse), ' ', '', [rfReplaceAll])) <= 0 then
      raise Exception.Create('ChatGPT1 não confirmou a limpeza do projeto.');

    AIProject1.ProjectData.Clear;
    AIProject1.EnsureProjectStructure;

    AIProject1.ProjectName := '';
    AIProject1.Description := '';
    AIProject1.Goal := '';
    AIProject1.Context := '';
    AIProject1.Scope := '';
    AIProject1.Constraints := '';
    AIProject1.ExpectedDeliverables := '';
    AIProject1.SimulationMode := False;
    AIProject1.ChatGPT := ChatGPT1;

    MemoProjectName.Clear;
    MemoGoal.Clear;
    MemoConstraints.Clear;
    MemoDeliverables.Clear;
    MemoTaskDescription.Clear;
    MemoReport.Clear;

    RefreshAllViews;

    LogMsg('[OK] Projeto limpo. Nenhum dado fake foi criado.');
  except
    on E: Exception do
      LogMsg('[ERRO] Falha ao limpar projeto: ' + E.Message);
  end;
end;

procedure TfrmMain.TaskGrid1SelectCell(Sender: TObject; aCol, aRow: Integer; var CanSelect: Boolean);
var
  LTaskID: string;
begin
  if not Assigned(AIProject1) or not Assigned(AIProject1.ProjectData) then
    Exit;

  if (aRow <= 0) or (aRow >= TaskGrid1.RowCount) then
    Exit;

  LTaskID := TaskGrid1.Cells[0, aRow];

  if LTaskID = '' then
    Exit;

  if Assigned(MemoTaskDescription) then
    MemoTaskDescription.Text := AIProjectTasks1.TaskLongDescription[LTaskID];
end;

end.
