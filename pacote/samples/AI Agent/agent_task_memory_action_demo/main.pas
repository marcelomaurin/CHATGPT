unit main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, StdCtrls,
  ComCtrls, Grids, Contnrs, fpjson, jsonparser, LCLType, LCLIntf,
  chatgpt,
  aiagent_flowevents,
  aiagent_memorymap,
  aiagent_core,
  aiagent_classifier,
  aiagent_decision,
  aiagent_actionbuilder,
  aiagent_executor,
  aiagent_actions,
  aioutput_docs,
  aiemail;

type
  TSampleTaskStatus = (
    stsPending,
    stsProcessing,
    stsDone,
    stsFailed,
    stsCanceled,
    stsSimulated
  );

  { TSampleTaskItem }
  TSampleTaskItem = class
  public
    ID: string;
    Ordem: Integer;
    Tipo: string;
    Descricao: string;
    Agente: string;
    AcaoSugerida: string;
    Dependencia: string;
    Status: TSampleTaskStatus;
    Resultado: string;
    RawJSON: string;
    Params: TStringList;
    constructor Create;
    destructor Destroy; override;
  end;

  { Actions declared locally inside the sample }
  TSampleCreateWordAction = class(TAICustomAgentAction)
  public
    WordOutput: TAIWordOutput;
    LastGeneratedFile: string;
    LastContent: string;
    function RunAction(const AParams: TStrings; ASimulate: Boolean): Boolean; override;
  end;

  TSampleSendEmailAction = class(TAICustomAgentAction)
  public
    EmailClient: TAIEmailClient;
    AttachmentFileName: string;
    function RunAction(const AParams: TStrings; ASimulate: Boolean): Boolean; override;
  end;

  TSampleRegisterResultAction = class(TAICustomAgentAction)
  public
    function RunAction(const AParams: TStrings; ASimulate: Boolean): Boolean; override;
  end;

  { TfrmMain }

  TfrmMain = class(TForm)
    FMemoryMap: TAIMapaDeMemoria;
    { Credentials & Provider Panels }
    pnlHeader: TPanel;
    lblProvider: TLabel;
    cbProvider: TComboBox;
    lblModel: TLabel;
    cbModel: TComboBox;
    lblToken: TLabel;
    edtToken: TEdit;
    lblBaseURL: TLabel;
    edtBaseURL: TEdit;

    { Main PageControl }
    pgMain: TPageControl;
    tabPrompt: TTabSheet;
    tabTarefas: TTabSheet;
    tabAgente: TTabSheet;
    tabMapaMemoria: TTabSheet;
    tabResultado: TTabSheet;
    tabLog: TTabSheet;

    { Prompt Tab Controls }
    gbPromptInput: TGroupBox;
    memPrompt: TMemo;
    pnlPromptCommands: TPanel;
    btnGerarTarefas: TButton;
    btnLimparPrompt: TButton;
    chkModoSimulado: TCheckBox;
    chkPermitirGerarWordReal: TCheckBox;
    chkPermitirEnvioEmailReal: TCheckBox;

    { Tasks Tab Controls }
    gridTarefas: TStringGrid;
    pnlTasksCommands: TPanel;
    btnExecutarTarefaSelecionada: TButton;
    btnExecutarTodas: TButton;
    btnReprocessarTarefa: TButton;
    btnCancelarTarefa: TButton;
    gbTaskDetail: TGroupBox;
    memDetalheTarefa: TMemo;

    { Agent Tab Controls }
    pnlAgentAuditor: TPanel;
    gbAgentInput: TGroupBox;
    memEntradaAgente: TMemo;
    gbAgentQuestions: TGroupBox;
    memPerguntasAgente: TMemo;
    gbAgentAnalysis: TGroupBox;
    memAnaliseAgente: TMemo;
    gbAgentExplanation: TGroupBox;
    memExplicacaoAgente: TMemo;
    gbAgentAction: TGroupBox;
    memAcaoTomada: TMemo;
    gbAgentOutput: TGroupBox;
    memSaidaAgente: TMemo;

    { Memory Map Tab Controls }
    gridMapaMemoria: TStringGrid;
    pnlMapCommands: TPanel;
    btnAtualizarMapa: TButton;
    btnExportarMapaTexto: TButton;
    btnExportarMapaJSON: TButton;
    gbMapDetail: TGroupBox;
    memMapaDetalhe: TMemo;
    gbInfoLoss: TGroupBox;
    memPerdasInformacao: TMemo;

    { Result Tab Controls }
    pnlResultLayout: TPanel;
    gbWordResult: TGroupBox;
    memConteudoCurriculo: TMemo;
    pnlWordParams: TPanel;
    lblWordFile: TLabel;
    edArquivoWordGerado: TEdit;
    btnAbrirArquivoWord: TButton;

    gbEmailResult: TGroupBox;
    pnlEmailParams: TPanel;
    lblEmailTo: TLabel;
    edEmailDestino: TEdit;
    lblEmailSubject: TLabel;
    edAssuntoEmail: TEdit;
    memCorpoEmail: TMemo;
    pnlEmailCommands: TPanel;
    btnSimularEnvioEmail: TButton;
    btnEnviarEmailReal: TButton;

    { Log Tab Controls }
    memLog: TMemo;
    pnlLogCommands: TPanel;
    btnLimparLog: TButton;
    btnSalvarLog: TButton;

    { Components }
    FChatGPT: TCHATGPT;
    FClassifierAgent: TAIClassifierAgent;
    FTaskPlannerAgent: TAIDecisionAgent;
    FTaskProcessorAgent: TAIDecisionAgent;
    FActionBuilderAgent: TAIActionBuilderAgent;
    FActionExecutor: TAIActionExecutor;
    FWordOutput: TAIWordOutput;
    FEmailClient: TAIEmailClient;

    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btnGerarTarefasClick(Sender: TObject);
    procedure btnExecutarTarefaSelecionadaClick(Sender: TObject);
    procedure btnExecutarTodasClick(Sender: TObject);
    procedure btnReprocessarTarefaClick(Sender: TObject);
    procedure btnCancelarTarefaClick(Sender: TObject);
    procedure btnLimparPromptClick(Sender: TObject);
    procedure cbProviderChange(Sender: TObject);
    procedure gridTarefasSelection(Sender: TObject; ACol, ARow: Integer);
    procedure gridMapaSelection(Sender: TObject; ACol, ARow: Integer);
    procedure btnAtualizarMapaClick(Sender: TObject);
    procedure btnExportarMapaTextoClick(Sender: TObject);
    procedure btnExportarMapaJSONClick(Sender: TObject);
    procedure btnLimparLogClick(Sender: TObject);
    procedure btnSalvarLogClick(Sender: TObject);
    procedure btnAbrirArquivoWordClick(Sender: TObject);
    procedure btnSimularEnvioEmailClick(Sender: TObject);
    procedure btnEnviarEmailRealClick(Sender: TObject);

  private
    FCreateWordAction: TSampleCreateWordAction;
    FSendEmailAction: TSampleSendEmailAction;
    FRegisterResultAction: TSampleRegisterResultAction;
    FTasks: Contnrs.TObjectList;

    procedure LoadDefaultScenario;
    procedure ConfigureChatGPT;
    procedure AddLog(const AMsg: string);
    procedure RefreshTasksGrid;
    procedure RefreshMemoryMapGrid;
    function GetSelectedTask: TSampleTaskItem;
    procedure CreateDefaultTasks;
    function LoadTasksFromPlannerJSON(const AJSON: string): Boolean;
    function CanExecuteTask(ATask: TSampleTaskItem; out AError: string): Boolean;
    procedure ExecuteTaskFallback(ATask: TSampleTaskItem);
    procedure ShowAgentStep(AItem: TAIAgentMemoryMapItem);
    function DispatchPreparedActions(const APreparedActionsJSON: string): Boolean;

    { Events }
    procedure OnMemoryMapAfterCreateStep(Sender: TObject; AItem: TAIAgentMemoryMapItem);
    procedure OnMemoryMapAfterCloseStep(Sender: TObject; AItem: TAIAgentMemoryMapItem);
    procedure OnMemoryMapInformationLossDetected(Sender: TObject; AItem: TAIAgentMemoryMapItem; const ALostInfo: string);
    procedure OnMemoryMapLog(Sender: TObject; const AMessage: string);
  public

  end;

var
  frmMain: TfrmMain;

implementation

{$R *.lfm}

uses
  TypInfo;

{ TSampleTaskItem }

constructor TSampleTaskItem.Create;
begin
  inherited Create;
  Params := TStringList.Create;
  Status := stsPending;
  RawJSON := '';
  Resultado := '';
end;

destructor TSampleTaskItem.Destroy;
begin
  Params.Free;
  inherited Destroy;
end;

{ TSampleCreateWordAction }

function TSampleCreateWordAction.RunAction(const AParams: TStrings; ASimulate: Boolean): Boolean;
var
  FileName, Title, Content: string;
begin
  Result := False;
  FileName := AParams.Values['file_name'];
  if FileName = '' then FileName := 'curriculo_rafael.docx';
  Title := AParams.Values['title'];
  if Title = '' then Title := 'Currículo Profissional - Rafael Almeida Costa';
  Content := AParams.Values['content'];
  if Content = '' then Content := 'Currículo';

  LastGeneratedFile := FileName;
  LastContent := Content;

  if ASimulate then
  begin
    frmMain.AddLog(Format('[CREATE_WORD_DOCUMENT] (SIMULADO) Documento "%s" seria gerado com o título: "%s"', [FileName, Title]));
    frmMain.edArquivoWordGerado.Text := '(Simulado) ' + FileName;
    frmMain.memConteudoCurriculo.Text := Content;
    Result := True;
  end;

  if not ASimulate then
  begin
    try
      WordOutput.FileName := 'output/' + FileName;
      WordOutput.Title := Title;
      
      // Ensure file path inside project directory or simple temp folder
      ForceDirectories('output');
      WordOutput.AddHeading(Title, 1);
      WordOutput.AddParagraph(Content);
      
      // Write document
      WordOutput.SaveWord;
      
      frmMain.AddLog(Format('[CREATE_WORD_DOCUMENT] (REAL) Documento "%s" gerado fisicamente.', [WordOutput.FileName]));
      frmMain.edArquivoWordGerado.Text := WordOutput.FileName;
      frmMain.memConteudoCurriculo.Text := Content;
      Result := True;
    except
      on E: Exception do
      begin
        frmMain.AddLog('[CREATE_WORD_DOCUMENT] (ERRO) Falha ao criar Word real: ' + E.Message);
        Result := False;
      end;
    end;
  end;
end;

{ TSampleSendEmailAction }

function TSampleSendEmailAction.RunAction(const AParams: TStrings; ASimulate: Boolean): Boolean;
var
  ToAddr, Subject, Body: string;
begin
  Result := False;
  ToAddr := AParams.Values['to'];
  if ToAddr = '' then ToAddr := 'marcelomaurinmartins@gmail.com';
  Subject := AParams.Values['subject'];
  if Subject = '' then Subject := 'Currículo';
  Body := AParams.Values['body'];
  if Body = '' then Body := 'Segue currículo em anexo.';

  if ASimulate then
  begin
    frmMain.AddLog(Format('[SEND_EMAIL] (SIMULADO) Envio de e-mail simulado para "%s". Assunto: "%s"', [ToAddr, Subject]));
    frmMain.edEmailDestino.Text := ToAddr;
    frmMain.edAssuntoEmail.Text := Subject;
    frmMain.memCorpoEmail.Text := Body;
    Result := True;
  end;

  if not ASimulate then
  begin
    if MessageDlg('Confirmação Manual', Format('Deseja realmente enviar o e-mail real para "%s"?', [ToAddr]), mtConfirmation, [mbYes, mbNo], 0) = mrYes then
    begin
      try
        // Include attachment path in the body as standard client does not support files attachment
        if AttachmentFileName <> '' then
          Body := Body + sLineBreak + sLineBreak + 'Anexo: ' + AttachmentFileName;
        
        EmailClient.SendEmail(ToAddr, Subject, Body);
        frmMain.AddLog(Format('[SEND_EMAIL] (REAL) E-mail enviado com sucesso para "%s".', [ToAddr]));
        frmMain.edEmailDestino.Text := ToAddr;
        frmMain.edAssuntoEmail.Text := Subject;
        frmMain.memCorpoEmail.Text := Body;
        Result := True;
      except
        on E: Exception do
        begin
          frmMain.AddLog('[SEND_EMAIL] (ERRO) Falha ao enviar e-mail: ' + E.Message);
          Result := False;
        end;
      end;
    end
    else
    begin
      frmMain.AddLog('[SEND_EMAIL] Envio cancelado pelo usuário.');
      Result := False;
    end;
  end;
end;

{ TSampleRegisterResultAction }

function TSampleRegisterResultAction.RunAction(const AParams: TStrings; ASimulate: Boolean): Boolean;
var
  StatusMsg: string;
begin
  StatusMsg := AParams.Values['status'];
  if StatusMsg = '' then StatusMsg := 'Concluído com sucesso!';
  
  frmMain.AddLog('[REGISTER_RESULT] ' + StatusMsg);
  Result := True;
end;

{ TfrmMain }

procedure TfrmMain.FormCreate(Sender: TObject);
begin
  Position := poScreenCenter;
  Width := 1200;
  Height := 800;
  Caption := 'IA Multi-Agent Task-Oriented Workflow Demo';

  FTasks := TObjectList.Create(True);

  { Actions wiring }
  FCreateWordAction := TSampleCreateWordAction.Create(Self);
  FCreateWordAction.WordOutput := FWordOutput;
  FCreateWordAction.MemoryMap := FMemoryMap;

  FSendEmailAction := TSampleSendEmailAction.Create(Self);
  FSendEmailAction.EmailClient := FEmailClient;
  FSendEmailAction.MemoryMap := FMemoryMap;

  FRegisterResultAction := TSampleRegisterResultAction.Create(Self);
  FRegisterResultAction.MemoryMap := FMemoryMap;

  { Setup agents configs }
  FClassifierAgent.ChatGPT := FChatGPT;
  FClassifierAgent.MemoryMap := FMemoryMap;
  FClassifierAgent.NomeAgente := 'classifier_agent';

  FTaskPlannerAgent.ChatGPT := FChatGPT;
  FTaskPlannerAgent.MemoryMap := FMemoryMap;
  FTaskPlannerAgent.NomeAgente := 'task_planner_agent';

  FTaskProcessorAgent.ChatGPT := FChatGPT;
  FTaskProcessorAgent.MemoryMap := FMemoryMap;
  FTaskProcessorAgent.NomeAgente := 'task_processor_agent';

  FActionBuilderAgent.ChatGPT := FChatGPT;
  FActionBuilderAgent.MemoryMap := FMemoryMap;
  FActionBuilderAgent.NomeAgente := 'action_builder_agent';

  FActionExecutor.ChatGPT := FChatGPT;
  FActionExecutor.MemoryMap := FMemoryMap;
  FActionExecutor.NomeAgente := 'action_executor';

  { Map events }
  FMemoryMap.OnAfterCreateStep := @OnMemoryMapAfterCreateStep;
  FMemoryMap.OnAfterCloseStep := @OnMemoryMapAfterCloseStep;
  FMemoryMap.OnInformationLossDetected := @OnMemoryMapInformationLossDetected;
  FMemoryMap.OnMemoryMapLog := @OnMemoryMapLog;

  LoadDefaultScenario;
  AddLog('Sample inicializado e pronto.');
end;

procedure TfrmMain.FormDestroy(Sender: TObject);
begin
  FTasks.Free;
end;



procedure TfrmMain.LoadDefaultScenario;
begin
  memPrompt.Text :=
    'Gere um documento Word com um currículo profissional fictício e envie para o e-mail marcelomaurinmartins@gmail.com.' + sLineBreak + sLineBreak +
    'Dados fictícios do currículo:' + sLineBreak + sLineBreak +
    'Nome: Rafael Almeida Costa' + sLineBreak +
    'Cargo desejado: Analista de Sistemas com foco em Inteligência Artificial' + sLineBreak +
    'Cidade: Ribeirão Preto - SP' + sLineBreak +
    'E-mail: rafael.almeida.demo@email.com' + sLineBreak +
    'Telefone: (16) 98888-1234' + sLineBreak + sLineBreak +
    'Resumo profissional:' + sLineBreak +
    'Profissional com experiência em desenvolvimento de sistemas, automação de processos, banco de dados e integração com APIs de inteligência artificial.' + sLineBreak + sLineBreak +
    'Experiências:' + sLineBreak +
    '- Desenvolvedor Pascal/Lazarus na empresa Tech Saúde Sistemas, de 2021 a 2025.' + sLineBreak +
    '- Analista de Suporte e Automação na empresa Ribeirão Soluções Digitais, de 2018 a 2021.' + sLineBreak + sLineBreak +
    'Formação:' + sLineBreak +
    '- Tecnologia em Análise e Desenvolvimento de Sistemas' + sLineBreak +
    '- Pós-graduação em Inteligência Artificial Aplicada' + sLineBreak + sLineBreak +
    'Competências:' + sLineBreak +
    '- Lazarus/Free Pascal' + sLineBreak +
    '- PostgreSQL' + sLineBreak +
    '- Python' + sLineBreak +
    '- Integração com APIs' + sLineBreak +
    '- Automação de processos' + sLineBreak +
    '- Documentação técnica' + sLineBreak + sLineBreak +
    'Objetivo:' + sLineBreak +
    'Criar um currículo profissional em formato Word e enviar o documento por e-mail.';

  cbProvider.ItemIndex := 0;
  cbProviderChange(nil);

  edEmailDestino.Text := 'marcelomaurinmartins@gmail.com';
  edAssuntoEmail.Text := 'Currículo Profissional - Rafael Almeida Costa';
end;

procedure TfrmMain.ConfigureChatGPT;
begin
  FChatGPT.TOKEN := edtToken.Text;
  FChatGPT.URL := edtBaseURL.Text;
  FChatGPT.CustomModel := cbModel.Text;
  
  if cbProvider.ItemIndex = 0 then
    FChatGPT.Provider := AIP_OPENAI
  else
    FChatGPT.Provider := AIP_LOCAL;
end;

procedure TfrmMain.AddLog(const AMsg: string);
begin
  memLog.Lines.Add(Format('[%s] %s', [FormatDateTime('yyyy-mm-dd hh:nn:ss', Now), AMsg]));
end;

procedure TfrmMain.cbProviderChange(Sender: TObject);
begin
  if cbProvider.ItemIndex = 0 then
  begin
    edtBaseURL.Text := 'https://api.openai.com/v1';
    cbModel.Clear;
    cbModel.Items.Add('gpt-4o-mini');
    cbModel.Items.Add('gpt-4o');
    cbModel.Text := 'gpt-4o-mini';
  end
  else
  begin
    edtBaseURL.Text := 'http://localhost:11434/v1';
    cbModel.Clear;
    cbModel.Items.Add('llama3.2');
    cbModel.Items.Add('deepseek-r1');
    cbModel.Text := 'llama3.2';
  end;
end;

procedure TfrmMain.CreateDefaultTasks;
var
  T: TSampleTaskItem;
begin
  FTasks.Clear;

  T := TSampleTaskItem.Create;
  T.ID := 'T001'; T.Ordem := 1; T.Tipo := 'analysis'; T.Descricao := 'Analisar pedido do usuário'; T.Agente := 'classifier_agent'; T.AcaoSugerida := 'ANALYZE_REQUEST'; T.Dependencia := ''; FTasks.Add(T);

  T := TSampleTaskItem.Create;
  T.ID := 'T002'; T.Ordem := 2; T.Tipo := 'content'; T.Descricao := 'Extrair e organizar dados do currículo'; T.Agente := 'task_processor_agent'; T.AcaoSugerida := 'EXTRACT_DATA'; T.Dependencia := 'T001'; FTasks.Add(T);

  T := TSampleTaskItem.Create;
  T.ID := 'T003'; T.Ordem := 3; T.Tipo := 'content'; T.Descricao := 'Gerar conteúdo textual do currículo'; T.Agente := 'task_processor_agent'; T.AcaoSugerida := 'GENERATE_TEXT'; T.Dependencia := 'T002'; FTasks.Add(T);

  T := TSampleTaskItem.Create;
  T.ID := 'T004'; T.Ordem := 4; T.Tipo := 'document'; T.Descricao := 'Criar documento Word com o currículo'; T.Agente := 'action_builder_agent'; T.AcaoSugerida := 'CREATE_WORD_DOCUMENT'; T.Dependencia := 'T003'; FTasks.Add(T);

  T := TSampleTaskItem.Create;
  T.ID := 'T005'; T.Ordem := 5; T.Tipo := 'email'; T.Descricao := 'Preparar e-mail'; T.Agente := 'task_processor_agent'; T.AcaoSugerida := 'PREPARE_EMAIL'; T.Dependencia := 'T004'; FTasks.Add(T);

  T := TSampleTaskItem.Create;
  T.ID := 'T006'; T.Ordem := 6; T.Tipo := 'email'; T.Descricao := 'Enviar e-mail com o documento anexado'; T.Agente := 'action_builder_agent'; T.AcaoSugerida := 'SEND_EMAIL'; T.Dependencia := 'T005'; FTasks.Add(T);

  T := TSampleTaskItem.Create;
  T.ID := 'T007'; T.Ordem := 7; T.Tipo := 'log'; T.Descricao := 'Registrar resultado final'; T.Agente := 'action_builder_agent'; T.AcaoSugerida := 'REGISTER_RESULT'; T.Dependencia := 'T006'; FTasks.Add(T);
end;

procedure TfrmMain.RefreshTasksGrid;
var
  i: Integer;
  T: TSampleTaskItem;
begin
  gridTarefas.RowCount := FTasks.Count + 1;
  for i := 0 to FTasks.Count - 1 do
  begin
    T := TSampleTaskItem(FTasks[i]);
    gridTarefas.Cells[0, i + 1] := IntToStr(T.Ordem);
    gridTarefas.Cells[1, i + 1] := T.ID;
    gridTarefas.Cells[2, i + 1] := T.Tipo;
    gridTarefas.Cells[3, i + 1] := T.Descricao;
    gridTarefas.Cells[4, i + 1] := T.Agente;
    gridTarefas.Cells[5, i + 1] := T.AcaoSugerida;
    gridTarefas.Cells[6, i + 1] := GetEnumName(TypeInfo(TSampleTaskStatus), Ord(T.Status));
    gridTarefas.Cells[7, i + 1] := T.Dependencia;
    gridTarefas.Cells[8, i + 1] := T.Resultado;
  end;
end;

procedure TfrmMain.RefreshMemoryMapGrid;
var
  i: Integer;
  Item: TAIAgentMemoryMapItem;
begin
  gridMapaMemoria.RowCount := FMemoryMap.Items.Count + 1;
  for i := 0 to FMemoryMap.Items.Count - 1 do
  begin
    Item := FMemoryMap.Items[i];
    gridMapaMemoria.Cells[0, i + 1] := IntToStr(Item.Ordem);
    gridMapaMemoria.Cells[1, i + 1] := Item.NomeAgente;
    gridMapaMemoria.Cells[2, i + 1] := GetEnumName(TypeInfo(TAITipoAgenteMapa), Ord(Item.TipoAgente));
    gridMapaMemoria.Cells[3, i + 1] := GetEnumName(TypeInfo(TAIStatusEtapaMapa), Ord(Item.Status));
    gridMapaMemoria.Cells[4, i + 1] := Item.PedidoRecebido;
    gridMapaMemoria.Cells[5, i + 1] := Item.Analise;
    gridMapaMemoria.Cells[6, i + 1] := Item.Explicacao;
    gridMapaMemoria.Cells[7, i + 1] := Item.AcaoTomada;
    gridMapaMemoria.Cells[8, i + 1] := Item.InformacoesPerdidas.CommaText;
  end;
end;

function TfrmMain.GetSelectedTask: TSampleTaskItem;
var
  Row: Integer;
  ID: string;
  i: Integer;
begin
  Result := nil;
  Row := gridTarefas.Row;
  if (Row > 0) and (Row <= FTasks.Count) then
  begin
    ID := gridTarefas.Cells[1, Row];
    for i := 0 to FTasks.Count - 1 do
    begin
      if TSampleTaskItem(FTasks[i]).ID = ID then
      begin
        Result := TSampleTaskItem(FTasks[i]);
        Exit;
      end;
    end;
  end;
end;

procedure TfrmMain.gridTarefasSelection(Sender: TObject; ACol, ARow: Integer);
var
  T: TSampleTaskItem;
begin
  T := GetSelectedTask;
  if T <> nil then
  begin
    memDetalheTarefa.Clear;
    memDetalheTarefa.Lines.Add('ID: ' + T.ID);
    memDetalheTarefa.Lines.Add('Ordem: ' + IntToStr(T.Ordem));
    memDetalheTarefa.Lines.Add('Tipo: ' + T.Tipo);
    memDetalheTarefa.Lines.Add('Descrição: ' + T.Descricao);
    memDetalheTarefa.Lines.Add('Agente: ' + T.Agente);
    memDetalheTarefa.Lines.Add('Ação Sugerida: ' + T.AcaoSugerida);
    memDetalheTarefa.Lines.Add('Status: ' + GetEnumName(TypeInfo(TSampleTaskStatus), Ord(T.Status)));
    memDetalheTarefa.Lines.Add('Dependência: ' + T.Dependencia);
    memDetalheTarefa.Lines.Add('Resultado: ' + T.Resultado);
    if T.RawJSON <> '' then
      memDetalheTarefa.Lines.Add('JSON Bruto: ' + T.RawJSON);
  end;
end;

procedure TfrmMain.gridMapaSelection(Sender: TObject; ACol, ARow: Integer);
var
  Idx: Integer;
  Item: TAIAgentMemoryMapItem;
begin
  Idx := ARow - 1;
  if (Idx >= 0) and (Idx < FMemoryMap.Items.Count) then
  begin
    Item := FMemoryMap.Items[Idx];
    memMapaDetalhe.Text := Item.AsText;
    memPerdasInformacao.Text := Item.InformacoesPerdidas.Text;
    ShowAgentStep(Item);
  end;
end;

procedure TfrmMain.ShowAgentStep(AItem: TAIAgentMemoryMapItem);
begin
  memEntradaAgente.Text := AItem.PedidoRecebido;
  memPerguntasAgente.Text := AItem.PerguntasAnalises.AsText;
  memAnaliseAgente.Text := AItem.Analise;
  memExplicacaoAgente.Text := AItem.Explicacao;
  memAcaoTomada.Text := AItem.AcaoTomada;
  memSaidaAgente.Text := AItem.AsJSON;
end;

procedure TfrmMain.btnLimparPromptClick(Sender: TObject);
begin
  memPrompt.Clear;
end;

procedure TfrmMain.btnGerarTarefasClick(Sender: TObject);
var
  LClassificacaoJSON, LPlannerInput, LTarefasJSON: string;
  PlannerSuccess: Boolean;
begin
  if Trim(memPrompt.Text) = '' then
  begin
    ShowMessage('Por favor, digite um prompt de entrada.');
    Exit;
  end;

  btnGerarTarefas.Enabled := False;
  try
    ConfigureChatGPT;
    AddLog('Iniciando fluxo de geração de tarefas...');

    FMemoryMap.StartFlow(memPrompt.Text, 'Geração de Tarefas');
    CreateDefaultTasks;

    // 1. Classify Request
    if edtToken.Text <> '' then
    begin
      AddLog('Classificando prompt via LLM...');
      if FClassifierAgent.Classify(memPrompt.Text, LClassificacaoJSON) then
      begin
        AddLog('Classificação bem-sucedida.');
        // 2. Plan Tasks
        LPlannerInput := 'PROMPT ORIGINAL:' + sLineBreak + memPrompt.Text + sLineBreak + 'CLASSIFICACAO:' + sLineBreak + LClassificacaoJSON;
        AddLog('Planejando tarefas via LLM...');
        if FTaskPlannerAgent.Decide(LPlannerInput, LTarefasJSON) then
        begin
          AddLog('Planejamento concluído pelo LLM.');
          PlannerSuccess := LoadTasksFromPlannerJSON(LTarefasJSON);
          if not PlannerSuccess then
          begin
            AddLog('Aviso: Falha ao carregar JSON do planejador. Usando tarefas locais.');
            CreateDefaultTasks;
          end;
        end
        else
        begin
          AddLog('Erro no planejador. Usando tarefas locais de fallback.');
          CreateDefaultTasks;
        end;
      end
      else
      begin
        AddLog('Erro no classificador. Usando tarefas locais de fallback.');
        CreateDefaultTasks;
      end;
    end
    else
    begin
      AddLog('Nenhum token fornecido. Usando tarefas padrão (Fallback Local).');
      CreateDefaultTasks;
    end;

    RefreshTasksGrid;
    RefreshMemoryMapGrid;
    pgMain.ActivePage := tabTarefas;

  finally
    btnGerarTarefas.Enabled := True;
  end;
end;

function TfrmMain.LoadTasksFromPlannerJSON(const AJSON: string): Boolean;
var
  JSONData: TJSONData;
  Obj, TaskObj: TJSONObject;
  Arr: TJSONArray;
  i: Integer;
  T: TSampleTaskItem;
begin
  Result := False;
  try
    JSONData := GetJSON(AJSON);
    try
      if JSONData is TJSONObject then
      begin
        Obj := TJSONObject(JSONData);
        Arr := Obj.Arrays['tasks'];
        if Assigned(Arr) then
        begin
          FTasks.Clear;
          for i := 0 to Arr.Count - 1 do
          begin
            TaskObj := Arr.Objects[i];
            T := TSampleTaskItem.Create;
            T.ID := TaskObj.Get('id', '');
            T.Ordem := TaskObj.Get('order', i + 1);
            T.Tipo := TaskObj.Get('type', '');
            T.Descricao := TaskObj.Get('description', '');
            T.Agente := TaskObj.Get('agent', 'task_processor_agent');
            T.AcaoSugerida := TaskObj.Get('suggested_action', '');
            T.Dependencia := TaskObj.Get('depends_on', '');
            FTasks.Add(T);
          end;
          Result := True;
        end;
      end;
    finally
      JSONData.Free;
    end;
  except
    on E: Exception do
    begin
      AddLog('Erro ao fazer parse do JSON do planejador: ' + E.Message);
      Result := False;
    end;
  end;
end;

function TfrmMain.CanExecuteTask(ATask: TSampleTaskItem; out AError: string): Boolean;
var
  i: Integer;
  DepTask: TSampleTaskItem;
begin
  Result := True;
  AError := '';
  if ATask.Dependencia = '' then Exit;

  for i := 0 to FTasks.Count - 1 do
  begin
    DepTask := TSampleTaskItem(FTasks[i]);
    if DepTask.ID = ATask.Dependencia then
    begin
      if (DepTask.Status <> stsDone) and (DepTask.Status <> stsSimulated) then
      begin
        Result := False;
        AError := Format('A tarefa dependente "%s" (%s) não foi concluída.', [DepTask.ID, DepTask.Descricao]);
        Exit;
      end;
    end;
  end;
end;

procedure TfrmMain.btnExecutarTarefaSelecionadaClick(Sender: TObject);
var
  T: TSampleTaskItem;
  Err: string;
  ProcessorOutput, BuilderOutput, ExecutorOutput: string;
  AgentStep: TAIAgentMemoryMapItem;
  ProcessSuccess, ActionsSuccess, ExecSuccess: Boolean;
begin
  T := GetSelectedTask;
  if T = nil then
  begin
    ShowMessage('Por favor, selecione uma tarefa no grid.');
    Exit;
  end;

  if not CanExecuteTask(T, Err) then
  begin
    ShowMessage(Err);
    Exit;
  end;

  AddLog(Format('Iniciando processamento da tarefa: %s (%s)...', [T.ID, T.Descricao]));
  T.Status := stsProcessing;
  RefreshTasksGrid;

  ConfigureChatGPT;

  ProcessSuccess := False;
  // If LLM is configured, call cognitive agents
  if edtToken.Text <> '' then
  begin
    AddLog('Executando TaskProcessorAgent...');
    if FTaskProcessorAgent.Decide(Format('Tarefa a processar: %s. Descrição: %s. Dependência: %s', [T.ID, T.Descricao, T.Dependencia]), ProcessorOutput) then
    begin
      T.Resultado := ProcessorOutput;
      ProcessSuccess := True;
      AddLog('Processamento cognitivo concluído.');
      
      // Check if action suggestion exists
      if T.AcaoSugerida <> '' then
      begin
        AddLog('Gerando plano de ações...');
        if FActionBuilderAgent.BuildActions(ProcessorOutput, BuilderOutput) then
        begin
          AddLog('Plano de ações gerado.');
          AddLog('Analisando plano pelo Executor...');
          if FActionExecutor.ExecutePlan(BuilderOutput, ExecutorOutput) then
          begin
            AddLog('Plano validado e simulado.');
            DispatchPreparedActions(BuilderOutput);
            if chkModoSimulado.Checked then
              T.Status := stsSimulated
            else
              T.Status := stsDone;
          end
          else
          begin
            AddLog('Falha no executor: ' + FActionExecutor.LastError);
            T.Status := stsFailed;
            T.Resultado := FActionExecutor.LastError;
          end;
        end
        else
        begin
          AddLog('Falha no action builder.');
          T.Status := stsFailed;
        end;
      end
      else
      begin
        T.Status := stsDone;
      end;
    end;
  end;

  // Fallback if LLM fails or is not used
  if not ProcessSuccess then
  begin
    AddLog('Executando fallback local para a tarefa...');
    ExecuteTaskFallback(T);
  end;

  RefreshTasksGrid;
  RefreshMemoryMapGrid;
end;

procedure TfrmMain.ExecuteTaskFallback(ATask: TSampleTaskItem);
var
  Params: TStringList;
begin
  Params := TStringList.Create;
  try
    if ATask.ID = 'T001' then
    begin
      ATask.Resultado := 'Pedido de currículo profissional para Rafael Almeida Costa em Ribeirão Preto - SP.';
      ATask.Status := stsDone;
    end
    else if ATask.ID = 'T002' then
    begin
      ATask.Resultado := 'Nome: Rafael Almeida Costa, Cargo: Analista IA, Contato: rafael.almeida.demo@email.com';
      ATask.Status := stsDone;
    end
    else if ATask.ID = 'T003' then
    begin
      ATask.Resultado := 'Texto completo do currículo gerado com resumo e qualificações.';
      memConteudoCurriculo.Text := 'CURRÍCULO PROFISSIONAL' + sLineBreak + 'Nome: Rafael Almeida Costa' + sLineBreak + 'Cargo: Analista IA';
      ATask.Status := stsDone;
    end
    else if ATask.ID = 'T004' then
    begin
      Params.Values['file_name'] := 'curriculo_rafael.docx';
      Params.Values['title'] := 'Currículo - Rafael Almeida Costa';
      Params.Values['content'] := memConteudoCurriculo.Text;
      FCreateWordAction.RunAction(Params, chkModoSimulado.Checked or not chkPermitirGerarWordReal.Checked);
      if chkModoSimulado.Checked or not chkPermitirGerarWordReal.Checked then
        ATask.Status := stsSimulated
      else
        ATask.Status := stsDone;
      ATask.Resultado := edArquivoWordGerado.Text;
    end
    else if ATask.ID = 'T005' then
    begin
      memCorpoEmail.Text := 'Prezado,' + sLineBreak + sLineBreak + 'Segue anexo o currículo profissional solicitado.' + sLineBreak + sLineBreak + 'Atenciosamente,' + sLineBreak + 'Rafael Almeida Costa';
      ATask.Resultado := 'E-mail estruturado.';
      ATask.Status := stsDone;
    end
    else if ATask.ID = 'T006' then
    begin
      Params.Values['to'] := edEmailDestino.Text;
      Params.Values['subject'] := edAssuntoEmail.Text;
      Params.Values['body'] := memCorpoEmail.Text;
      FSendEmailAction.AttachmentFileName := edArquivoWordGerado.Text;
      FSendEmailAction.RunAction(Params, chkModoSimulado.Checked or not chkPermitirEnvioEmailReal.Checked);
      if chkModoSimulado.Checked or not chkPermitirEnvioEmailReal.Checked then
        ATask.Status := stsSimulated
      else
        ATask.Status := stsDone;
      ATask.Resultado := 'Enviado.';
    end
    else if ATask.ID = 'T007' then
    begin
      Params.Values['status'] := 'Processo finalizado com sucesso.';
      FRegisterResultAction.RunAction(Params, True);
      ATask.Status := stsDone;
      ATask.Resultado := 'Finalizado';
    end;
  finally
    Params.Free;
  end;
end;

function TfrmMain.DispatchPreparedActions(const APreparedActionsJSON: string): Boolean;
var
  JSONData: TJSONData;
  Obj, ActObj, ParamsObj: TJSONObject;
  ActionsArr: TJSONArray;
  i, j: Integer;
  ActionName: string;
  Params: TStringList;
  DeveSimular: Boolean;
begin
  Result := False;
  try
    JSONData := GetJSON(APreparedActionsJSON);
    try
      if JSONData is TJSONObject then
      begin
        Obj := TJSONObject(JSONData);
        ActionsArr := Obj.Arrays['actions'];
        if Assigned(ActionsArr) then
        begin
          Params := TStringList.Create;
          try
            for i := 0 to ActionsArr.Count - 1 do
            begin
              ActObj := ActionsArr.Objects[i];
              ActionName := ActObj.Get('action', '');
              Params.Clear;
              
              ParamsObj := ActObj.Objects['parameters'];
              if Assigned(ParamsObj) then
              begin
                for j := 0 to ParamsObj.Count - 1 do
                  Params.Values[ParamsObj.Names[j]] := ParamsObj.Items[j].AsString;
              end;

              DeveSimular := chkModoSimulado.Checked or
                ((ActionName = 'CREATE_WORD_DOCUMENT') and not chkPermitirGerarWordReal.Checked) or
                ((ActionName = 'SEND_EMAIL') and not chkPermitirEnvioEmailReal.Checked);

              if ActionName = 'CREATE_WORD_DOCUMENT' then
                FCreateWordAction.RunAction(Params, DeveSimular)
              else if ActionName = 'SEND_EMAIL' then
              begin
                FSendEmailAction.AttachmentFileName := edArquivoWordGerado.Text;
                FSendEmailAction.RunAction(Params, DeveSimular);
              end
              else if ActionName = 'REGISTER_RESULT' then
                FRegisterResultAction.RunAction(Params, True);
            end;
            Result := True;
          finally
            Params.Free;
          end;
        end;
      end;
    finally
      JSONData.Free;
    end;
  except
    on E: Exception do
      AddLog('Falha ao despachar ações: ' + E.Message);
  end;
end;

procedure TfrmMain.btnExecutarTodasClick(Sender: TObject);
var
  i: Integer;
  T: TSampleTaskItem;
  Err: string;
begin
  for i := 0 to FTasks.Count - 1 do
  begin
    T := TSampleTaskItem(FTasks[i]);
    if (T.Status = stsPending) or (T.Status = stsFailed) then
    begin
      if CanExecuteTask(T, Err) then
      begin
        gridTarefas.Row := i + 1;
        btnExecutarTarefaSelecionadaClick(nil);
        Application.ProcessMessages;
        Sleep(500); // small delay for user visibility
      end;
    end;
  end;
end;

procedure TfrmMain.btnReprocessarTarefaClick(Sender: TObject);
var
  T: TSampleTaskItem;
begin
  T := GetSelectedTask;
  if T <> nil then
  begin
    T.Status := stsPending;
    T.Resultado := '';
    RefreshTasksGrid;
    AddLog(Format('Tarefa "%s" reiniciada para reprocessamento.', [T.ID]));
  end;
end;

procedure TfrmMain.btnCancelarTarefaClick(Sender: TObject);
var
  T: TSampleTaskItem;
begin
  T := GetSelectedTask;
  if T <> nil then
  begin
    T.Status := stsCanceled;
    RefreshTasksGrid;
    AddLog(Format('Tarefa "%s" cancelada.', [T.ID]));
  end;
end;

procedure TfrmMain.btnAtualizarMapaClick(Sender: TObject);
begin
  RefreshMemoryMapGrid;
end;

procedure TfrmMain.btnExportarMapaTextoClick(Sender: TObject);
begin
  ForceDirectories('output');
  FMemoryMap.SaveToFile('output/memory_map.txt');
  ShowMessage('Mapa de Memória exportado como texto em output/memory_map.txt');
end;

procedure TfrmMain.btnExportarMapaJSONClick(Sender: TObject);
begin
  ForceDirectories('output');
  FMemoryMap.SaveToFile('output/memory_map.json');
  ShowMessage('Mapa de Memória exportado como JSON em output/memory_map.json');
end;

procedure TfrmMain.btnLimparLogClick(Sender: TObject);
begin
  memLog.Clear;
end;

procedure TfrmMain.btnSalvarLogClick(Sender: TObject);
begin
  ForceDirectories('output');
  memLog.Lines.SaveToFile('output/agent_task_memory_action_demo.log');
  ShowMessage('Log salvo em output/agent_task_memory_action_demo.log');
end;

procedure TfrmMain.btnAbrirArquivoWordClick(Sender: TObject);
var
  Path: string;
begin
  Path := edArquivoWordGerado.Text;
  if (Path = '') or (Pos('(Simulado)', Path) > 0) then
  begin
    ShowMessage('Nenhum arquivo físico real foi gerado ainda.');
    Exit;
  end;
  OpenURL('file:///' + ExpandFileName(Path));
end;

procedure TfrmMain.btnSimularEnvioEmailClick(Sender: TObject);
var
  Params: TStringList;
begin
  Params := TStringList.Create;
  try
    Params.Values['to'] := edEmailDestino.Text;
    Params.Values['subject'] := edAssuntoEmail.Text;
    Params.Values['body'] := memCorpoEmail.Text;
    FSendEmailAction.RunAction(Params, True);
  finally
    Params.Free;
  end;
end;

procedure TfrmMain.btnEnviarEmailRealClick(Sender: TObject);
var
  Params: TStringList;
begin
  Params := TStringList.Create;
  try
    Params.Values['to'] := edEmailDestino.Text;
    Params.Values['subject'] := edAssuntoEmail.Text;
    Params.Values['body'] := memCorpoEmail.Text;
    FSendEmailAction.RunAction(Params, False);
  finally
    Params.Free;
  end;
end;

{ Event methods }

procedure TfrmMain.OnMemoryMapAfterCreateStep(Sender: TObject; AItem: TAIAgentMemoryMapItem);
begin
  AddLog(Format('[MAPA] Criou etapa para o agente: %s', [AItem.NomeAgente]));
end;

procedure TfrmMain.OnMemoryMapAfterCloseStep(Sender: TObject; AItem: TAIAgentMemoryMapItem);
begin
  AddLog(Format('[MAPA] Fechou etapa do agente: %s. Ação: %s', [AItem.NomeAgente, AItem.AcaoTomada]));
  RefreshMemoryMapGrid;
end;

procedure TfrmMain.OnMemoryMapInformationLossDetected(Sender: TObject; AItem: TAIAgentMemoryMapItem; const ALostInfo: string);
begin
  AddLog(Format('[MAPA - ATENÇÃO] Perda de informação na etapa %s: %s', [AItem.NomeAgente, ALostInfo]));
end;

procedure TfrmMain.OnMemoryMapLog(Sender: TObject; const AMessage: string);
begin
  AddLog('[MAPA - LOG] ' + AMessage);
end;

end.
