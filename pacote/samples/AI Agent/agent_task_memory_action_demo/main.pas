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
  aiagent_browseractions,
  aioutput_docs,
  aiemail,
  uCEFChromiumWindow,
  aichromiumbrowser;

type
  TSampleTaskStatus = (
    stsPending,
    stsProcessing,
    stsDone,
    stsFailed,
    stsCanceled
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

  TfrmMain = class;

  { TSampleCreateTextAction }

  TSampleCreateTextAction = class(TAICustomAgentAction)
  public
    MainForm: TfrmMain;
    LastGeneratedFile: string;
    LastContent: string;
    function RunAction(const AParams: TStrings; ASimulate: Boolean): Boolean; override;
  end;

  { TSampleSendEmailAction }

  TSampleSendEmailAction = class(TAICustomAgentAction)
  public
    MainForm: TfrmMain;
    EmailClient: TAIEmailClient;
    GeneratedTextFileName: string;

    SMTPHost: string;
    SMTPPort: Integer;
    SMTPUser: string;
    SMTPPassword: string;

    function RunAction(const AParams: TStrings; ASimulate: Boolean): Boolean; override;
  end;

  { TSampleRegisterResultAction }

  TSampleRegisterResultAction = class(TAICustomAgentAction)
  public
    MainForm: TfrmMain;
    function RunAction(const AParams: TStrings; ASimulate: Boolean): Boolean; override;
  end;

  { TfrmMain }

  TfrmMain = class(TForm)
    FMemoryMap: TAIAgentMemoryMap;

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
    tabBrowser: TTabSheet;

    { Prompt Tab Controls }
    gbPromptInput: TGroupBox;
    memPrompt: TMemo;
    pnlPromptCommands: TPanel;
    btnGerarTarefas: TButton;
    btnLimparPrompt: TButton;
    btnCenarioBrowser: TButton;
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

    { SMTP Fields }
    lblSMTPHost: TLabel;
    edSMTPHost: TEdit;
    lblSMTPPort: TLabel;
    edSMTPPort: TEdit;
    lblSMTPUser: TLabel;
    edSMTPUser: TEdit;
    lblSMTPPassword: TLabel;
    edSMTPPassword: TEdit;

    { Log Tab Controls }
    memLog: TMemo;
    pnlLogCommands: TPanel;
    btnLimparLog: TButton;
    btnSalvarLog: TButton;

    { Browser Tab Sheet Controls }
    pnlBrowserTop: TPanel;
    lblBrowserStatus: TLabel;
    edBrowserURL: TEdit;
    btnBrowserNavigate: TButton;
    AIChromiumBrowser1: TAIChromiumBrowser;
    ChromiumWindow1: TChromiumWindow;

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
    procedure btnCenarioBrowserClick(Sender: TObject);
    procedure cbProviderChange(Sender: TObject);
    procedure gridTarefasSelection(Sender: TObject; ACol, ARow: Integer);
    procedure gridMapaSelection(Sender: TObject; ACol, ARow: Integer);
    procedure btnAtualizarMapaClick(Sender: TObject);
    procedure btnExportarMapaTextoClick(Sender: TObject);
    procedure btnExportarMapaJSONClick(Sender: TObject);
    procedure btnLimparLogClick(Sender: TObject);
    procedure btnSalvarLogClick(Sender: TObject);
    procedure btnAbrirArquivoWordClick(Sender: TObject);
    procedure btnEnviarEmailRealClick(Sender: TObject);
    procedure btnBrowserNavigateClick(Sender: TObject);

    { Browser Events }
    procedure AIChromiumBrowser1LoadURL(Sender: TObject; const AURL: string; AIsMainFrame: Boolean);
    procedure AIChromiumBrowser1FinishedLoadURL(Sender: TObject; const AURL: string; AHttpStatusCode: Integer; AIsMainFrame: Boolean);
    procedure AIChromiumBrowser1DOMResult(Sender: TObject; const AKind: string; const ASelector: string; AIndex: Integer; ACount: Integer; const AJSON: string);

  private
    FCreateTextAction: TSampleCreateTextAction;
    FSendEmailAction: TSampleSendEmailAction;
    FRegisterResultAction: TSampleRegisterResultAction;

    FBrowserNavigateAction: TAIBrowserNavigateAction;
    FBrowserWaitSelectorAction: TAIBrowserWaitSelectorAction;
    FBrowserReadPageAction: TAIBrowserReadPageAction;
    FBrowserDOMListAction: TAIBrowserDOMListAction;
    FBrowserCaptureTextAction: TAIBrowserCaptureTextAction;
    FBrowserSetValueAction: TAIBrowserSetValueAction;
    FBrowserFocusAction: TAIBrowserFocusAction;
    FBrowserClickAction: TAIBrowserClickAction;
    FBrowserPressEnterAction: TAIBrowserPressEnterAction;
    FBrowserSubmitFormAction: TAIBrowserSubmitFormAction;
    FBrowserScreenshotAction: TAIBrowserScreenshotAction;

    FTasks: Contnrs.TObjectList;

    FCapturedWebText: string;
    FWaitingForDOMText: Boolean;
    FWaitingForNavigation: Boolean;
    FExpectedNavigationURL: string;

    FLastBrowserDOMKind: string;
    FLastBrowserDOMSelector: string;
    FLastBrowserDOMJSON: string;
    FWaitingBrowserDOM: Boolean;

    function ValidateProviderToken(out AErro: string): Boolean;
    function SanitizeLLMError(const AError: string): string;

    procedure LoadDefaultScenario;
    procedure ConfigureChatGPT;
    procedure ConfigureEmailAction;
    procedure AddLog(const AMsg: string);
    procedure RefreshTasksGrid;
    procedure RefreshMemoryMapGrid;
    function GetSelectedTask: TSampleTaskItem;
    function LoadTasksFromPlannerJSON(const AJSON: string): Boolean;
    function CanExecuteTask(ATask: TSampleTaskItem; out AError: string): Boolean;
    procedure ShowAgentStep(AItem: TAIAgentMemoryMapItem);
    function DispatchPreparedActions(const APreparedActionsJSON: string): Boolean;
    function ContainsBrowserAction(const APreparedActionsJSON: string): Boolean;
    function ParamsToJSON(AParams: TStrings): string;
    function BuildSingleActionJSON(ATask: TSampleTaskItem): string;
    function EnsureBrowser: Boolean;
    function ExtractURLFromPrompt(const APrompt: string): string;
    function WaitBrowserDOMResult(ATimeoutMs: Integer): Boolean;
    function WaitBrowserNavigation(ATimeoutMs: Integer): Boolean;
    procedure ActionExecutorBeforePreparedAction(Sender: TObject; const AActionName: string; AParams: TStrings; AExecutionContext: TStrings; var ACanExecute: Boolean);
    procedure ActionExecutorAfterPreparedAction(Sender: TObject; const AActionName: string; AParams: TStrings; AExecutionContext: TStrings; AResult: TStrings);

    { Replanning Helpers }
    function CanTriggerReplan(ATask: TSampleTaskItem): Boolean;
    function HasPendingTasksAfter(ATask: TSampleTaskItem): Boolean;
    function BuildPendingTasksJSON(const AAfterOrder: Integer): string;
    function BuildCompletedTasksSummary: string;
    function ReplanPendingTasksIfNeeded(ACurrentTask: TSampleTaskItem): Boolean;
    function ApplyReplanJSON(const AReplanJSON: string): Boolean;
    procedure SortTasksByOrder;

    function EnsureRuntimeObjects(out AErro: string): Boolean;
    procedure WireRuntimeObjects;
    function NormalizeChatEndpoint(const AURL: string): string;

    procedure ResetTasksGrid;

    { Events }
    procedure OnMemoryMapAfterCreateStep(Sender: TObject; AItem: TAIAgentMemoryMapItem);
    procedure OnMemoryMapAfterCloseStep(Sender: TObject; AItem: TAIAgentMemoryMapItem);
    procedure OnMemoryMapInformationLossDetected(Sender: TObject; AItem: TAIAgentMemoryMapItem; const ALostInfo: string);
    procedure OnMemoryMapLog(Sender: TObject; const AMessage: string);
    procedure ActionExecutorBeforeActionExecute(Sender: TObject; const AActionName: string; AParams: TStrings; AExecutionContext: TStrings);
    procedure ActionExecutorAfterActionExecute(Sender: TObject; const AActionName: string; AParams: TStrings; AResult: TStrings; AExecutionContext: TStrings);
  public
  end;

var
  frmMain: TfrmMain;

implementation

{$R *.lfm}

uses
  TypInfo;

function IsEmptyOrPlaceholder(const AText: string): Boolean;
var
  S: string;
begin
  S := LowerCase(Trim(AText));

  Result :=
    (S = '') or
    (Pos('conteúdo do currículo', S) > 0) or
    (Pos('currículo gerado', S) > 0) or
    (Pos('gerado a partir das informações', S) > 0) or
    (Pos('informações capturadas do site', S) > 0) or
    (Pos('conteudo do curriculo', S) > 0) or
    (Pos('curriculo gerado', S) > 0) or
    (Pos('informacoes capturadas do site', S) > 0) or
    (Pos('conteúdo gerado', S) > 0) or
    (Pos('conteudo gerado', S) > 0) or
    (Pos('resultado capturado', S) > 0) or
    (Pos('texto gerado a partir', S) > 0);
end;

function JSONValueToPlainText(AValue: TJSONData): string;
begin
  Result := '';

  if not Assigned(AValue) then
    Exit;

  case AValue.JSONType of
    jtString:
      Result := AValue.AsString;
    jtNumber,
    jtBoolean:
      Result := AValue.AsString;
  else
    Result := AValue.AsJSON;
  end;
end;

function GetJSONArrayField(AObj: TJSONObject; const AName: string; out AField: TJSONArray): Boolean;
var
  Data: TJSONData;
begin
  Result := False;
  AField := nil;

  if not Assigned(AObj) then
    Exit;

  Data := AObj.Find(AName);

  if Assigned(Data) and (Data is TJSONArray) then
  begin
    AField := TJSONArray(Data);
    Result := True;
  end;
end;

function LimitSampleText(const AText: string; AMaxChars: Integer): string;
begin
  if AMaxChars <= 0 then
  begin
    Result := '';
    Exit;
  end;

  if Length(AText) <= AMaxChars then
    Result := AText
  else
    Result :=
      Copy(AText, 1, AMaxChars) +
      sLineBreak +
      sLineBreak +
      '[CONTEÚDO CORTADO: texto original possuía ' +
      IntToStr(Length(AText)) +
      ' caracteres]';
end;

function IsBrowserActionName(const AActionName: string): Boolean;
begin
  Result := (Pos('BROWSER_', UpperCase(Trim(AActionName))) = 1) or SameText(AActionName, 'REPLAN_FROM_DOM');
end;

function LocalCleanJSONResponse(const AText: string): string;
var
  S: string;
  P1, P2: Integer;
begin
  S := Trim(AText);

  if Pos('```', S) = 1 then
  begin
    P1 := Pos('{', S);
    P2 := LastDelimiter('}', S);

    if (P1 > 0) and (P2 >= P1) then
    begin
      Result := Copy(S, P1, P2 - P1 + 1);
      Exit;
    end;

    P1 := Pos('[', S);
    P2 := LastDelimiter(']', S);

    if (P1 > 0) and (P2 >= P1) then
    begin
      Result := Copy(S, P1, P2 - P1 + 1);
      Exit;
    end;
  end;

  Result := S;
end;

{ TSampleTaskItem }

constructor TSampleTaskItem.Create;
begin
  inherited Create;
  Params := TStringList.Create;
  Status := stsPending;
  RawJSON := '';
  Resultado := '';
  ID := '';
  Ordem := 0;
  Tipo := '';
  Descricao := '';
  Agente := '';
  AcaoSugerida := '';
  Dependencia := '';
end;

destructor TSampleTaskItem.Destroy;
begin
  Params.Free;
  inherited Destroy;
end;

{ TSampleCreateTextAction }

function TSampleCreateTextAction.RunAction(const AParams: TStrings; ASimulate: Boolean): Boolean;
var
  FileName, FullFileName, Title, Content: string;
  SL: TStringList;
begin
  Result := False;

  if not Assigned(MainForm) then
    Exit;

  FileName := Trim(AParams.Values['file_name']);

  if FileName = '' then
    FileName := Trim(AParams.Values['filename']);

  if FileName = '' then
    FileName := 'texto_gerado_' + FormatDateTime('yyyymmdd_hhnnss', Now) + '.txt'
  else
    FileName := ChangeFileExt(ExtractFileName(FileName), '.txt');

  Title := Trim(AParams.Values['title']);

  if Title = '' then
    Title := Trim(AParams.Values['titulo']);

  if Title = '' then
    Title := 'Texto gerado';

  Content := AParams.Values['content'];

  if IsEmptyOrPlaceholder(Content) then
    Content := AParams.Values['text'];

  if IsEmptyOrPlaceholder(Content) then
    Content := AParams.Values['body'];

  if IsEmptyOrPlaceholder(Content) then
    Content := AParams.Values['document_text'];

  if IsEmptyOrPlaceholder(Content) then
    Content := AParams.Values['curriculum_text'];

  if IsEmptyOrPlaceholder(Content) and Assigned(MainForm.FActionExecutor) then
    Content := MainForm.FActionExecutor.ExecutionContext.Values['browser.last_result_text'];

  if IsEmptyOrPlaceholder(Content) and Assigned(MainForm.FActionExecutor) then
    Content := MainForm.FActionExecutor.ExecutionContext.Values['browser.last_text'];

  if IsEmptyOrPlaceholder(Content) and Assigned(MainForm.memConteudoCurriculo) then
    Content := MainForm.memConteudoCurriculo.Text;

  if IsEmptyOrPlaceholder(Content) then
  begin
    MainForm.AddLog('[CREATE_TEXT_DOCUMENT] ERRO: o agente não informou conteúdo real para gerar o texto.');
    Exit;
  end;

  LastGeneratedFile := FileName;
  LastContent := Content;

  if ASimulate then
  begin
    MainForm.AddLog('[CREATE_TEXT_DOCUMENT] Simulação recusada: o sample deve executar ações reais.');
    Exit(False);
  end;

  try
    ForceDirectories('output');

    FullFileName := 'output' + DirectorySeparator + FileName;

    if Assigned(MainForm.memConteudoCurriculo) then
    begin
      MainForm.memConteudoCurriculo.Clear;
      MainForm.memConteudoCurriculo.Lines.Add(Title);
      MainForm.memConteudoCurriculo.Lines.Add(StringOfChar('=', Length(Title)));
      MainForm.memConteudoCurriculo.Lines.Add('');
      MainForm.memConteudoCurriculo.Lines.Add(Content);
    end;

    SL := TStringList.Create;
    try
      SL.Add(Title);
      SL.Add(StringOfChar('=', Length(Title)));
      SL.Add('');
      SL.Add(Content);
      SL.SaveToFile(FullFileName);
    finally
      SL.Free;
    end;

    if Assigned(MainForm.edArquivoWordGerado) then
      MainForm.edArquivoWordGerado.Text := FullFileName;

    MainForm.AddLog(Format('[CREATE_TEXT_DOCUMENT] Texto "%s" gerado fisicamente.', [FullFileName]));

    Result := True;
  except
    on E: Exception do
    begin
      MainForm.AddLog('[CREATE_TEXT_DOCUMENT] ERRO: Falha ao gerar texto: ' + E.Message);
      Result := False;
    end;
  end;
end;

{ TSampleSendEmailAction }

function TSampleSendEmailAction.RunAction(const AParams: TStrings; ASimulate: Boolean): Boolean;
var
  ToAddr, Subject, Body: string;
begin
  Result := False;

  if not Assigned(MainForm) then
    Exit;

  if not Assigned(EmailClient) then
  begin
    MainForm.AddLog('[SEND_EMAIL] ERRO: EmailClient não foi inicializado.');
    Exit;
  end;

  ToAddr := Trim(AParams.Values['to']);

  if ToAddr = '' then
    ToAddr := Trim(AParams.Values['email']);

  if ToAddr = '' then
    ToAddr := Trim(AParams.Values['recipient']);

  if ToAddr = '' then
    ToAddr := Trim(MainForm.edEmailDestino.Text);

  if ToAddr = '' then
  begin
    MainForm.AddLog('[SEND_EMAIL] ERRO: destinatário não informado pelo agente nem pela tela.');
    Exit;
  end;

  Subject := Trim(AParams.Values['subject']);

  if Subject = '' then
    Subject := Trim(AParams.Values['assunto']);

  if Subject = '' then
    Subject := Trim(MainForm.edAssuntoEmail.Text);

  if Subject = '' then
    Subject := 'Sem assunto';

  Body := AParams.Values['body'];

  if IsEmptyOrPlaceholder(Body) then
    Body := AParams.Values['message'];

  if IsEmptyOrPlaceholder(Body) then
    Body := AParams.Values['corpo'];

  if IsEmptyOrPlaceholder(Body) and Assigned(MainForm.FActionExecutor) then
    Body := MainForm.FActionExecutor.ExecutionContext.Values['last_text_content'];

  if IsEmptyOrPlaceholder(Body) and Assigned(MainForm.FActionExecutor) then
    Body := MainForm.FActionExecutor.ExecutionContext.Values['browser.last_result_text'];

  if IsEmptyOrPlaceholder(Body) then
    Body := MainForm.memCorpoEmail.Text;

  if IsEmptyOrPlaceholder(Body) and Assigned(MainForm.memConteudoCurriculo) then
    Body := MainForm.memConteudoCurriculo.Text;

  if Assigned(MainForm.memCorpoEmail) then
    MainForm.memCorpoEmail.Text := Body;

  if Assigned(MainForm.edEmailDestino) then
    MainForm.edEmailDestino.Text := ToAddr;

  if Assigned(MainForm.edAssuntoEmail) then
    MainForm.edAssuntoEmail.Text := Subject;

  if IsEmptyOrPlaceholder(Body) then
  begin
    MainForm.AddLog('[SEND_EMAIL] ERRO: corpo do e-mail não informado e nenhum texto gerado disponível.');
    Exit;
  end;

  if (Pos('[link_aqui]', LowerCase(Body)) > 0) or
     (Pos('link_aqui', LowerCase(Body)) > 0) or
     (Pos('[preco_aqui]', LowerCase(Body)) > 0) or
     (Pos('preco_aqui', LowerCase(Body)) > 0) then
  begin
    MainForm.AddLog('[SEND_EMAIL] ERRO: corpo do e-mail ainda contém placeholder. Envio bloqueado.');
    Exit(False);
  end;

  if (Pos('http://', LowerCase(Body)) = 0) and
     (Pos('https://', LowerCase(Body)) = 0) and
     (Pos('link', LowerCase(Body)) > 0) then
  begin
    MainForm.AddLog('[SEND_EMAIL] ERRO: o corpo promete link, mas nenhuma URL real foi encontrada. Envio bloqueado.');
    Exit(False);
  end;

  if GeneratedTextFileName <> '' then
    Body := Body + sLineBreak + sLineBreak + 'Arquivo texto gerado localmente: ' + GeneratedTextFileName;

  if ASimulate then
  begin
    MainForm.AddLog('[SEND_EMAIL] Simulação recusada: o sample não deve simular envio no executor real.');
    Exit(False);
  end;

  if MessageDlg(
       'Confirmação Manual',
       Format('Deseja realmente enviar o e-mail real para "%s"?', [ToAddr]),
       mtConfirmation,
       [mbYes, mbNo],
       0
     ) = mrYes then
  begin
    try
      EmailClient.HostSMTP := SMTPHost;
      EmailClient.PortSMTP := SMTPPort;
      EmailClient.Username := SMTPUser;
      EmailClient.Password := SMTPPassword;

      if Trim(EmailClient.HostSMTP) = '' then
      begin
        MainForm.AddLog('[SEND_EMAIL] ERRO: servidor SMTP não informado.');
        Exit;
      end;

      EmailClient.SendEmail(ToAddr, Subject, Body);

      MainForm.AddLog(Format('[SEND_EMAIL] E-mail enviado com sucesso para "%s".', [ToAddr]));

      if Assigned(MainForm.edEmailDestino) then
        MainForm.edEmailDestino.Text := ToAddr;

      if Assigned(MainForm.edAssuntoEmail) then
        MainForm.edAssuntoEmail.Text := Subject;

      if Assigned(MainForm.memCorpoEmail) then
        MainForm.memCorpoEmail.Text := Body;

      Result := True;
    except
      on E: Exception do
      begin
        MainForm.AddLog('[SEND_EMAIL] ERRO: Falha ao enviar e-mail: ' + E.Message);
        Result := False;
      end;
    end;
  end
  else
  begin
    MainForm.AddLog('[SEND_EMAIL] Envio cancelado pelo usuário.');
    Result := False;
  end;
end;

{ TSampleRegisterResultAction }

function TSampleRegisterResultAction.RunAction(const AParams: TStrings; ASimulate: Boolean): Boolean;
var
  StatusMsg: string;
begin
  Result := False;

  if not Assigned(MainForm) then
    Exit;

  StatusMsg := AParams.Values['status'];

  if StatusMsg = '' then
    StatusMsg := AParams.Values['message'];

  if StatusMsg = '' then
    StatusMsg := AParams.Values['resultado'];

  if StatusMsg = '' then
  begin
    MainForm.AddLog('[REGISTER_RESULT] ERRO: status/resultado não informado pelo agente.');
    Exit;
  end;

  MainForm.AddLog('[REGISTER_RESULT] ' + StatusMsg);
  Result := True;
end;

{ TfrmMain }

procedure TfrmMain.FormCreate(Sender: TObject);
var
  Erro: string;
begin
  Position := poScreenCenter;
  Width := 1200;
  Height := 800;
  Caption := 'IA Multi-Agent Task-Oriented Workflow Demo';

  FTasks := TObjectList.Create(True);

  if not EnsureRuntimeObjects(Erro) then
  begin
    ShowMessage('Erro ao inicializar objetos do sample: ' + Erro);
    Exit;
  end;

  if Assigned(gbWordResult) then
    gbWordResult.Caption := 'Resultado em Texto';

  if Assigned(lblWordFile) then
    lblWordFile.Caption := 'Arquivo texto gerado:';

  if Assigned(btnAbrirArquivoWord) then
    btnAbrirArquivoWord.Caption := 'Abrir Texto';

  if Assigned(chkModoSimulado) then
  begin
    chkModoSimulado.Checked := False;
    chkModoSimulado.Visible := False;
  end;

  if Assigned(btnSimularEnvioEmail) then
    btnSimularEnvioEmail.Visible := False;

  if Assigned(chkPermitirGerarWordReal) then
  begin
    chkPermitirGerarWordReal.Caption := 'Permitir gerar arquivo texto real';
    chkPermitirGerarWordReal.Checked := True;
  end;

  if Assigned(AIChromiumBrowser1) and Assigned(ChromiumWindow1) then
  begin
    AIChromiumBrowser1.ChromiumWindow := ChromiumWindow1;
    AIChromiumBrowser1.MonitorDOMEvents := True;
    AIChromiumBrowser1.OnLoadURL := @AIChromiumBrowser1LoadURL;
    AIChromiumBrowser1.OnFinishedLoadURL := @AIChromiumBrowser1FinishedLoadURL;
    AIChromiumBrowser1.OnDOMResult := @AIChromiumBrowser1DOMResult;
  end
  else
    AddLog('Aviso: AIChromiumBrowser1 ou ChromiumWindow1 não foram encontrados no formulário.');

  FCapturedWebText := '';
  FWaitingForDOMText := False;
  FWaitingForNavigation := False;
  FExpectedNavigationURL := '';
  FLastBrowserDOMKind := '';
  FLastBrowserDOMSelector := '';
  FLastBrowserDOMJSON := '';
  FWaitingBrowserDOM := False;

  ResetTasksGrid;
  LoadDefaultScenario;

  AddLog('Sample inicializado e pronto.');
end;

procedure TfrmMain.FormDestroy(Sender: TObject);
begin
  FreeAndNil(FTasks);
end;

function TfrmMain.EnsureRuntimeObjects(out AErro: string): Boolean;
begin
  Result := False;
  AErro := '';

  try
    if not Assigned(FChatGPT) then
      FChatGPT := TCHATGPT.Create(Self);

    if not Assigned(FMemoryMap) then
      FMemoryMap := TAIAgentMemoryMap.Create(Self);

    if not Assigned(FClassifierAgent) then
      FClassifierAgent := TAIClassifierAgent.Create(Self);

    if not Assigned(FTaskPlannerAgent) then
      FTaskPlannerAgent := TAIDecisionAgent.Create(Self);

    if not Assigned(FTaskProcessorAgent) then
      FTaskProcessorAgent := TAIDecisionAgent.Create(Self);

    if not Assigned(FActionBuilderAgent) then
      FActionBuilderAgent := TAIActionBuilderAgent.Create(Self);

    if not Assigned(FActionExecutor) then
      FActionExecutor := TAIActionExecutor.Create(Self);

    if not Assigned(FEmailClient) then
      FEmailClient := TAIEmailClient.Create(Self);

    if not Assigned(FCreateTextAction) then
      FCreateTextAction := TSampleCreateTextAction.Create(Self);

    if not Assigned(FSendEmailAction) then
      FSendEmailAction := TSampleSendEmailAction.Create(Self);

    if not Assigned(FRegisterResultAction) then
      FRegisterResultAction := TSampleRegisterResultAction.Create(Self);

    if not Assigned(FBrowserNavigateAction) then
      FBrowserNavigateAction := TAIBrowserNavigateAction.Create(Self);

    if not Assigned(FBrowserWaitSelectorAction) then
      FBrowserWaitSelectorAction := TAIBrowserWaitSelectorAction.Create(Self);

    if not Assigned(FBrowserReadPageAction) then
      FBrowserReadPageAction := TAIBrowserReadPageAction.Create(Self);

    if not Assigned(FBrowserDOMListAction) then
      FBrowserDOMListAction := TAIBrowserDOMListAction.Create(Self);

    if not Assigned(FBrowserCaptureTextAction) then
      FBrowserCaptureTextAction := TAIBrowserCaptureTextAction.Create(Self);

    if not Assigned(FBrowserSetValueAction) then
      FBrowserSetValueAction := TAIBrowserSetValueAction.Create(Self);

    if not Assigned(FBrowserFocusAction) then
      FBrowserFocusAction := TAIBrowserFocusAction.Create(Self);

    if not Assigned(FBrowserClickAction) then
      FBrowserClickAction := TAIBrowserClickAction.Create(Self);

    if not Assigned(FBrowserPressEnterAction) then
      FBrowserPressEnterAction := TAIBrowserPressEnterAction.Create(Self);

    if not Assigned(FBrowserSubmitFormAction) then
      FBrowserSubmitFormAction := TAIBrowserSubmitFormAction.Create(Self);

    if not Assigned(FBrowserScreenshotAction) then
      FBrowserScreenshotAction := TAIBrowserScreenshotAction.Create(Self);

    WireRuntimeObjects;

    Result := True;
  except
    on E: Exception do
    begin
      AErro := E.Message;
      Result := False;
    end;
  end;
end;

procedure TfrmMain.WireRuntimeObjects;
begin
  if Assigned(FCreateTextAction) then
  begin
    FCreateTextAction.ActionName := 'CREATE_TEXT_DOCUMENT';
    FCreateTextAction.MainForm := Self;
    FCreateTextAction.MemoryMap := FMemoryMap;
  end;

  if Assigned(FSendEmailAction) then
  begin
    FSendEmailAction.ActionName := 'SEND_EMAIL';
    FSendEmailAction.MainForm := Self;
    FSendEmailAction.EmailClient := FEmailClient;
    FSendEmailAction.MemoryMap := FMemoryMap;
  end;

  if Assigned(FRegisterResultAction) then
  begin
    FRegisterResultAction.ActionName := 'REGISTER_RESULT';
    FRegisterResultAction.MainForm := Self;
    FRegisterResultAction.MemoryMap := FMemoryMap;
  end;

  if Assigned(FClassifierAgent) then
  begin
    FClassifierAgent.ChatGPT := FChatGPT;
    FClassifierAgent.MemoryMap := FMemoryMap;
    FClassifierAgent.NomeAgente := 'classifier_agent';
    FClassifierAgent.TipoAgenteMapa := tamClassificador;
  end;

  if Assigned(FTaskPlannerAgent) then
  begin
    FTaskPlannerAgent.ChatGPT := FChatGPT;
    FTaskPlannerAgent.MemoryMap := FMemoryMap;
    FTaskPlannerAgent.NomeAgente := 'task_planner_agent';
    FTaskPlannerAgent.TipoAgenteMapa := tamDecisor;
  end;

  if Assigned(FTaskProcessorAgent) then
  begin
    FTaskProcessorAgent.ChatGPT := FChatGPT;
    FTaskProcessorAgent.MemoryMap := FMemoryMap;
    FTaskProcessorAgent.NomeAgente := 'task_processor_agent';
    FTaskProcessorAgent.TipoAgenteMapa := tamDecisor;
  end;

  if Assigned(FActionBuilderAgent) then
  begin
    FActionBuilderAgent.ChatGPT := FChatGPT;
    FActionBuilderAgent.MemoryMap := FMemoryMap;
    FActionBuilderAgent.NomeAgente := 'action_builder_agent';
    FActionBuilderAgent.TipoAgenteMapa := tamAjustadorAcao;
  end;

  if Assigned(FBrowserNavigateAction) then FBrowserNavigateAction.Browser := AIChromiumBrowser1;
  if Assigned(FBrowserWaitSelectorAction) then FBrowserWaitSelectorAction.Browser := AIChromiumBrowser1;
  if Assigned(FBrowserReadPageAction) then FBrowserReadPageAction.Browser := AIChromiumBrowser1;
  if Assigned(FBrowserDOMListAction) then FBrowserDOMListAction.Browser := AIChromiumBrowser1;
  if Assigned(FBrowserCaptureTextAction) then FBrowserCaptureTextAction.Browser := AIChromiumBrowser1;
  if Assigned(FBrowserSetValueAction) then FBrowserSetValueAction.Browser := AIChromiumBrowser1;
  if Assigned(FBrowserFocusAction) then FBrowserFocusAction.Browser := AIChromiumBrowser1;
  if Assigned(FBrowserClickAction) then FBrowserClickAction.Browser := AIChromiumBrowser1;
  if Assigned(FBrowserPressEnterAction) then FBrowserPressEnterAction.Browser := AIChromiumBrowser1;
  if Assigned(FBrowserSubmitFormAction) then FBrowserSubmitFormAction.Browser := AIChromiumBrowser1;
  if Assigned(FBrowserScreenshotAction) then FBrowserScreenshotAction.Browser := AIChromiumBrowser1;

  if Assigned(FBrowserNavigateAction) then FBrowserNavigateAction.MemoryMap := FMemoryMap;
  if Assigned(FBrowserWaitSelectorAction) then FBrowserWaitSelectorAction.MemoryMap := FMemoryMap;
  if Assigned(FBrowserReadPageAction) then FBrowserReadPageAction.MemoryMap := FMemoryMap;
  if Assigned(FBrowserDOMListAction) then FBrowserDOMListAction.MemoryMap := FMemoryMap;
  if Assigned(FBrowserCaptureTextAction) then FBrowserCaptureTextAction.MemoryMap := FMemoryMap;
  if Assigned(FBrowserSetValueAction) then FBrowserSetValueAction.MemoryMap := FMemoryMap;
  if Assigned(FBrowserFocusAction) then FBrowserFocusAction.MemoryMap := FMemoryMap;
  if Assigned(FBrowserClickAction) then FBrowserClickAction.MemoryMap := FMemoryMap;
  if Assigned(FBrowserPressEnterAction) then FBrowserPressEnterAction.MemoryMap := FMemoryMap;
  if Assigned(FBrowserSubmitFormAction) then FBrowserSubmitFormAction.MemoryMap := FMemoryMap;
  if Assigned(FBrowserScreenshotAction) then FBrowserScreenshotAction.MemoryMap := FMemoryMap;

  if Assigned(FActionExecutor) then
  begin
    FActionExecutor.ChatGPT := FChatGPT;
    FActionExecutor.MemoryMap := FMemoryMap;
    FActionExecutor.NomeAgente := 'action_executor';
    FActionExecutor.OnBeforeActionExecute := @ActionExecutorBeforeActionExecute;
    FActionExecutor.OnAfterActionExecute := @ActionExecutorAfterActionExecute;
    FActionExecutor.OnBeforePreparedAction := @ActionExecutorBeforePreparedAction;
    FActionExecutor.OnAfterPreparedAction := @ActionExecutorAfterPreparedAction;

    FActionExecutor.RegisterAction(FCreateTextAction);
    FActionExecutor.RegisterAction(FSendEmailAction);
    FActionExecutor.RegisterAction(FRegisterResultAction);
    FActionExecutor.RegisterAction(FBrowserNavigateAction);
    FActionExecutor.RegisterAction(FBrowserWaitSelectorAction);
    FActionExecutor.RegisterAction(FBrowserReadPageAction);
    FActionExecutor.RegisterAction(FBrowserDOMListAction);
    FActionExecutor.RegisterAction(FBrowserCaptureTextAction);
    FActionExecutor.RegisterAction(FBrowserSetValueAction);
    FActionExecutor.RegisterAction(FBrowserFocusAction);
    FActionExecutor.RegisterAction(FBrowserClickAction);
    FActionExecutor.RegisterAction(FBrowserPressEnterAction);
    FActionExecutor.RegisterAction(FBrowserSubmitFormAction);
    FActionExecutor.RegisterAction(FBrowserScreenshotAction);
  end;

  if Assigned(FMemoryMap) then
  begin
    FMemoryMap.OnAfterCreateStep := @OnMemoryMapAfterCreateStep;
    FMemoryMap.OnAfterCloseStep := @OnMemoryMapAfterCloseStep;
    FMemoryMap.OnInformationLossDetected := @OnMemoryMapInformationLossDetected;
    FMemoryMap.OnMemoryMapLog := @OnMemoryMapLog;
  end;
end;

function TfrmMain.NormalizeChatEndpoint(const AURL: string): string;
var
  S, SL: string;
begin
  S := Trim(AURL);

  while (S <> '') and (S[Length(S)] = '/') do
    Delete(S, Length(S), 1);

  SL := LowerCase(S);

  if S = '' then
    Result := ''
  else if Pos('/chat/completions', SL) > 0 then
    Result := S
  else
    Result := S + '/chat/completions';
end;

function TfrmMain.ValidateProviderToken(out AErro: string): Boolean;
var
  LToken: string;
begin
  Result := False;
  AErro := '';
  LToken := Trim(edtToken.Text);

  if cbProvider.ItemIndex = 0 then
  begin
    if LToken = '' then
    begin
      AErro := 'Informe o token/API key antes de chamar a OpenAI.';
      Exit;
    end;

    if Pos('sk-', LToken) <> 1 then
    begin
      AErro :=
        'A chave informada não parece ser uma API key válida da OpenAI. ' +
        'Ela deve começar com "sk-".';
      Exit;
    end;
  end;

  Result := True;
end;

function TfrmMain.SanitizeLLMError(const AError: string): string;
var
  S, L: string;
begin
  S := Trim(AError);
  L := LowerCase(S);

  if S = '' then
  begin
    Result := 'Erro não informado pelo componente LLM.';
    Exit;
  end;

  if Pos('incorrect api key provided', L) > 0 then
  begin
    Result := 'API key inválida. Gere uma nova chave válida no provedor e atualize o campo Token.';
    Exit;
  end;

  if Pos('invalid_api_key', L) > 0 then
  begin
    Result := 'API key inválida. Gere uma nova chave válida no provedor e atualize o campo Token.';
    Exit;
  end;

  if Pos('401', L) > 0 then
  begin
    Result := 'Erro de autenticação no provedor de IA. Verifique o Token/API key.';
    Exit;
  end;

  Result := S;
end;

procedure TfrmMain.LoadDefaultScenario;
begin
  cbProvider.ItemIndex := 0;
  cbProviderChange(nil);

  memPrompt.Text :=
    'Entre no https://pt.aliexpress.com/ , e pesquise por multimetro digital automático, ' +
    'busque o preço mais barato e envie o link do produto.';

  if Assigned(memCorpoEmail) then
    memCorpoEmail.Clear;

  if Assigned(memConteudoCurriculo) then
    memConteudoCurriculo.Clear;

  if Assigned(edArquivoWordGerado) then
    edArquivoWordGerado.Clear;
end;

procedure TfrmMain.ConfigureChatGPT;
var
  BaseURL: string;
begin
  if not Assigned(FChatGPT) then
    Exit;

  FChatGPT.TOKEN := WideString(edtToken.Text);
  FChatGPT.CustomModel := WideString(cbModel.Text);

  BaseURL := Trim(edtBaseURL.Text);

  if cbProvider.ItemIndex = 0 then
  begin
    FChatGPT.Provider := AIP_OPENAI;

    if BaseURL = '' then
      BaseURL := 'https://api.openai.com/v1';

    FChatGPT.URL := WideString(NormalizeChatEndpoint(BaseURL));
  end
  else
  begin
    FChatGPT.Provider := AIP_LOCAL;

    if BaseURL = '' then
      BaseURL := 'http://localhost:11434/v1';

    FChatGPT.URL := WideString(NormalizeChatEndpoint(BaseURL));
  end;
end;

procedure TfrmMain.ConfigureEmailAction;
begin
  if not Assigned(FSendEmailAction) then
    Exit;

  if Assigned(edSMTPHost) then
    FSendEmailAction.SMTPHost := Trim(edSMTPHost.Text)
  else
    FSendEmailAction.SMTPHost := '';

  if Assigned(edSMTPPort) then
    FSendEmailAction.SMTPPort := StrToIntDef(Trim(edSMTPPort.Text), 25)
  else
    FSendEmailAction.SMTPPort := 25;

  if Assigned(edSMTPUser) then
    FSendEmailAction.SMTPUser := Trim(edSMTPUser.Text)
  else
    FSendEmailAction.SMTPUser := '';

  if Assigned(edSMTPPassword) then
    FSendEmailAction.SMTPPassword := edSMTPPassword.Text
  else
    FSendEmailAction.SMTPPassword := '';
end;

procedure TfrmMain.AddLog(const AMsg: string);
begin
  if Assigned(memLog) then
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

procedure TfrmMain.ResetTasksGrid;
begin
  if Assigned(FTasks) then
    FTasks.Clear;

  if Assigned(gridTarefas) then
  begin
    gridTarefas.RowCount := 1;
    gridTarefas.ColCount := 9;
    gridTarefas.Cells[0, 0] := 'Ordem';
    gridTarefas.Cells[1, 0] := 'ID';
    gridTarefas.Cells[2, 0] := 'Tipo';
    gridTarefas.Cells[3, 0] := 'Descrição';
    gridTarefas.Cells[4, 0] := 'Agente';
    gridTarefas.Cells[5, 0] := 'Ação';
    gridTarefas.Cells[6, 0] := 'Status';
    gridTarefas.Cells[7, 0] := 'Dependência';
    gridTarefas.Cells[8, 0] := 'Resultado';
  end;
end;

procedure TfrmMain.RefreshTasksGrid;
var
  i: Integer;
  T: TSampleTaskItem;
begin
  if not Assigned(gridTarefas) then
    Exit;

  if not Assigned(FTasks) then
  begin
    ResetTasksGrid;
    Exit;
  end;

  gridTarefas.ColCount := 9;
  gridTarefas.RowCount := FTasks.Count + 1;

  gridTarefas.Cells[0, 0] := 'Ordem';
  gridTarefas.Cells[1, 0] := 'ID';
  gridTarefas.Cells[2, 0] := 'Tipo';
  gridTarefas.Cells[3, 0] := 'Descrição';
  gridTarefas.Cells[4, 0] := 'Agente';
  gridTarefas.Cells[5, 0] := 'Ação';
  gridTarefas.Cells[6, 0] := 'Status';
  gridTarefas.Cells[7, 0] := 'Dependência';
  gridTarefas.Cells[8, 0] := 'Resultado';

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
  if not Assigned(gridMapaMemoria) then
    Exit;

  if (not Assigned(FMemoryMap)) or (not Assigned(FMemoryMap.Items)) then
  begin
    gridMapaMemoria.RowCount := 1;
    Exit;
  end;

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

  if (not Assigned(gridTarefas)) or (not Assigned(FTasks)) then
    Exit;

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

    if Assigned(T.Params) and (T.Params.Count > 0) then
    begin
      memDetalheTarefa.Lines.Add('');
      memDetalheTarefa.Lines.Add('Parâmetros:');
      memDetalheTarefa.Lines.Add(T.Params.Text);
    end;
  end;
end;

procedure TfrmMain.gridMapaSelection(Sender: TObject; ACol, ARow: Integer);
var
  Idx: Integer;
  Item: TAIAgentMemoryMapItem;
begin
  if (not Assigned(FMemoryMap)) or (not Assigned(FMemoryMap.Items)) then
    Exit;

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
  if not Assigned(AItem) then
    Exit;

  memEntradaAgente.Text := AItem.PedidoRecebido;
  memPerguntasAgente.Text := AItem.PerguntasAnalises.AsText;
  memAnaliseAgente.Text := AItem.Analise;
  memExplicacaoAgente.Text := AItem.Explicacao;
  memAcaoTomada.Text := AItem.AcaoTomada;
  memSaidaAgente.Text := AItem.AsJSON;
end;

procedure TfrmMain.btnLimparPromptClick(Sender: TObject);
begin
  if Assigned(memPrompt) then
    memPrompt.Clear;
end;

procedure TfrmMain.btnCenarioBrowserClick(Sender: TObject);
begin
  if Assigned(memPrompt) then
  begin
    memPrompt.Text :=
      'Acesse o site https://www.google.com, aguarde a página carregar, ' +
      'leia a página e liste os elementos do DOM para identificar o campo de busca. ' +
      'Pesquise por "Componentes de IA Lazarus", submeta o formulário de busca e capture os resultados. ' +
      'Gere um documento de texto com os resultados encontrados e salve localmente.';
  end;
end;

procedure TfrmMain.btnGerarTarefasClick(Sender: TObject);
var
  LClassificacaoJSON: string;
  LPlannerInput: string;
  LTarefasJSON: string;
  LURL: string;
  PlannerSuccess: Boolean;
  StartTicks: QWord;
  Erro: string;
  ClassifierSuccess: Boolean;
  PlannerAgentSuccess: Boolean;
begin
  if Trim(memPrompt.Text) = '' then
  begin
    ShowMessage('Por favor, digite um prompt de entrada.');
    Exit;
  end;

  if not EnsureRuntimeObjects(Erro) then
  begin
    AddLog('Erro ao preparar objetos do sample: ' + Erro);
    ShowMessage('Erro ao preparar objetos do sample: ' + Erro);
    Exit;
  end;

  if not ValidateProviderToken(Erro) then
  begin
    AddLog('Geração cancelada: ' + Erro);
    ShowMessage(Erro);
    Exit;
  end;

  btnGerarTarefas.Enabled := False;

  try
    ConfigureChatGPT;

    ResetTasksGrid;

    if Assigned(memDetalheTarefa) then
      memDetalheTarefa.Clear;

    if Assigned(memConteudoCurriculo) then
      memConteudoCurriculo.Clear;

    if Assigned(memCorpoEmail) then
      memCorpoEmail.Clear;

    if Assigned(edArquivoWordGerado) then
      edArquivoWordGerado.Clear;

    if Assigned(FActionExecutor) then
      FActionExecutor.ClearExecutionContext;

    FCapturedWebText := '';
    FWaitingForDOMText := False;
    FWaitingForNavigation := False;
    FExpectedNavigationURL := '';
    FWaitingBrowserDOM := False;
    FLastBrowserDOMJSON := '';

    LURL := ExtractURLFromPrompt(memPrompt.Text);

    if LURL <> '' then
    begin
      AddLog('URL detectada no prompt: ' + LURL);

      if not EnsureBrowser then
      begin
        AddLog('Erro: navegador não pôde ser inicializado. Não é possível capturar o conteúdo real da página.');
        ShowMessage('Não foi possível inicializar o Chromium para capturar o conteúdo real do site.');
        Exit;
      end;

      edBrowserURL.Text := LURL;
      FExpectedNavigationURL := LURL;
      FWaitingForNavigation := True;

      pgMain.ActivePage := tabBrowser;

      AddLog('Navegando para a URL real: ' + LURL);

      try
        AIChromiumBrowser1.Navigate(LURL);
      except
        on E: Exception do
        begin
          FWaitingForNavigation := False;
          FExpectedNavigationURL := '';
          AddLog('Erro ao navegar no Chromium: ' + E.Message);
          ShowMessage('Erro ao navegar no Chromium. Veja o log.');
          Exit;
        end;
      end;

      AddLog('Aguardando carregamento da página real (max 15 segundos)...');

      StartTicks := GetTickCount64;

      while FWaitingForNavigation and (GetTickCount64 - StartTicks < 15000) do
      begin
        Application.ProcessMessages;
        Sleep(50);
      end;

      if FWaitingForNavigation then
      begin
        FWaitingForNavigation := False;
        FExpectedNavigationURL := '';
        AddLog('Erro: timeout aguardando carregamento da URL real.');
        ShowMessage('Timeout aguardando carregamento da página real no Chromium.');
        Exit;
      end;

      FExpectedNavigationURL := '';

      FWaitingForDOMText := True;

      try
        AIChromiumBrowser1.CaptureText('body');
      except
        on E: Exception do
        begin
          FWaitingForDOMText := False;
          AddLog('Erro ao solicitar captura do DOM: ' + E.Message);
          ShowMessage('Erro ao capturar texto da página. Veja o log.');
          Exit;
        end;
      end;

      AddLog('Aguardando captura do texto real da página (max 10 segundos)...');

      StartTicks := GetTickCount64;

      while FWaitingForDOMText and (GetTickCount64 - StartTicks < 10000) do
      begin
        Application.ProcessMessages;
        Sleep(50);
      end;

      if FWaitingForDOMText then
      begin
        FWaitingForDOMText := False;
        AddLog('Erro: timeout aguardando resposta do DOM.');
        ShowMessage('Timeout aguardando captura do texto da página.');
        Exit;
      end;

      if Trim(FCapturedWebText) = '' then
      begin
        AddLog('Aviso: a página foi carregada, mas nenhum texto inicial foi capturado. O fluxo continuará com automação DOM.');
      end
      else
        AddLog(Format('Conteúdo real capturado com sucesso. Tamanho: %d caracteres.', [Length(FCapturedWebText)]));
    end;

    AddLog('Iniciando fluxo real de geração de tarefas...');

    try
      FMemoryMap.StartFlow(memPrompt.Text, 'Geração de Tarefas');
    except
      on E: Exception do
      begin
        AddLog('Erro ao iniciar mapa de memória: ' + E.Message);
        ShowMessage('Erro ao iniciar mapa de memória. Veja o log.');
        Exit;
      end;
    end;

    AddLog('Classificando prompt via LLM...');

    LPlannerInput := memPrompt.Text;

    if Trim(FCapturedWebText) <> '' then
    begin
      LPlannerInput :=
        LPlannerInput +
        sLineBreak +
        sLineBreak +
        '=== CONTEUDO REAL CAPTURADO DO SITE ===' +
        sLineBreak +
        FCapturedWebText;
    end;

    ClassifierSuccess := False;
    LClassificacaoJSON := '';

    try
      ClassifierSuccess := FClassifierAgent.Classify(LPlannerInput, LClassificacaoJSON);
    except
      on E: Exception do
      begin
        ClassifierSuccess := False;
        AddLog('Exception no classificador: ' + E.Message);
      end;
    end;

    if not ClassifierSuccess then
    begin
      AddLog('Erro no classificador: ' + SanitizeLLMError(FClassifierAgent.LastError));
      ShowMessage('Não foi possível classificar o prompt. Veja o log.');
      Exit;
    end;

    if Trim(LClassificacaoJSON) = '' then
    begin
      AddLog('Erro: classificador retornou sucesso, mas a classificação veio vazia.');
      ShowMessage('Classificador retornou resposta vazia. Veja o log.');
      Exit;
    end;

    AddLog('Classificação bem-sucedida.');

    LPlannerInput :=
      'PROMPT ORIGINAL:' +
      sLineBreak +
      memPrompt.Text +
      sLineBreak +
      sLineBreak +
      'CLASSIFICACAO:' +
      sLineBreak +
      LClassificacaoJSON;

    if Trim(FCapturedWebText) <> '' then
    begin
      LPlannerInput :=
        LPlannerInput +
        sLineBreak +
        sLineBreak +
        '=== CONTEUDO REAL CAPTURADO DO SITE ===' +
        sLineBreak +
        FCapturedWebText;
    end;

    LPlannerInput :=
      LPlannerInput +
      sLineBreak +
      sLineBreak +
      '=== INSTRUCOES OBRIGATORIAS PARA O PLANEJADOR ===' +
      sLineBreak +
      'Retorne exclusivamente JSON válido.' + sLineBreak +
      'O JSON deve conter o campo "tasks" como array.' + sLineBreak +
      'Cada item de "tasks" deve conter: id, order, type, description, agent, suggested_action, depends_on.' + sLineBreak +
      'Não crie tarefa para gerar Word ou DOCX.' + sLineBreak +
      'Para gerar texto, use suggested_action = "CREATE_TEXT_DOCUMENT".' + sLineBreak +
      'Para enviar e-mail, use suggested_action = "SEND_EMAIL".' + sLineBreak +
      'Para navegação/interação no browser, use suggested_action com uma das ações BROWSER_* permitidas ou REPLAN_FROM_DOM.' + sLineBreak +
      'Ações browser permitidas: REPLAN_FROM_DOM, BROWSER_NAVIGATE, BROWSER_WAIT_SELECTOR, BROWSER_READ_PAGE, BROWSER_DOM_LIST, BROWSER_CAPTURE_TEXT, BROWSER_SET_VALUE, BROWSER_FOCUS, BROWSER_CLICK, BROWSER_PRESS_ENTER, BROWSER_SUBMIT_FORM, BROWSER_SCREENSHOT.' + sLineBreak +
      'Sempre que ler o DOM com BROWSER_DOM_LIST, crie uma tarefa REPLAN_FROM_DOM em seguida para adequar os seletores reais.' + sLineBreak +
      'Antes de BROWSER_SET_VALUE, BROWSER_CLICK, BROWSER_PRESS_ENTER ou BROWSER_SUBMIT_FORM, gere tarefa anterior BROWSER_READ_PAGE ou BROWSER_DOM_LIST, exceto se o seletor CSS foi informado explicitamente.' + sLineBreak +
      'Para pesquisar em site: navegue, aguarde seletor/campo, leia DOM, execute REPLAN_FROM_DOM, preencha campo, pressione Enter ou submeta, capture resultado.' + sLineBreak +
      'Não invente dados que não estejam no prompt, no DOM lido ou no conteúdo real capturado.' + sLineBreak +
      'Formato obrigatório preferencial:' + sLineBreak +
      '{' + sLineBreak +
      '  "tasks": [' + sLineBreak +
      '    {' + sLineBreak +
      '      "id": "T001",' + sLineBreak +
      '      "order": 1,' + sLineBreak +
      '      "type": "browser",' + sLineBreak +
      '      "description": "Abrir a URL solicitada",' + sLineBreak +
      '      "agent": "task_processor_agent",' + sLineBreak +
      '      "suggested_action": "BROWSER_NAVIGATE",' + sLineBreak +
      '      "depends_on": ""' + sLineBreak +
      '    }' + sLineBreak +
      '  ]' + sLineBreak +
      '}' + sLineBreak +
      'Se ainda assim retornar action_plan/actions, cada action será tratada como tarefa operacional real.';

    AddLog('Planejando tarefas via LLM...');

    PlannerAgentSuccess := False;
    LTarefasJSON := '';

    try
      PlannerAgentSuccess := FTaskPlannerAgent.DecideAsTaskList(LPlannerInput, LTarefasJSON);
    except
      on E: Exception do
      begin
        PlannerAgentSuccess := False;
        AddLog('Exception no planejador: ' + E.Message);
      end;
    end;

    if not PlannerAgentSuccess then
    begin
      AddLog('Erro no planejador: ' + SanitizeLLMError(FTaskPlannerAgent.LastError));
      ShowMessage('Não foi possível planejar tarefas reais. Veja o log.');
      Exit;
    end;

    if Trim(LTarefasJSON) = '' then
    begin
      AddLog('Erro: planejador retornou sucesso, mas o JSON de tarefas veio vazio.');
      ShowMessage('Planejador retornou JSON vazio. Veja o log.');
      Exit;
    end;

    AddLog('Planejamento concluído pelo LLM.');
    AddLog('JSON bruto retornado pelo planejador: ' + Copy(LTarefasJSON, 1, 3000));

    PlannerSuccess := LoadTasksFromPlannerJSON(LTarefasJSON);

    if not PlannerSuccess then
    begin
      ShowMessage('O planejador retornou JSON inválido ou sem lista de tarefas/ações. Veja o log.');
      Exit;
    end;

    RefreshTasksGrid;
    RefreshMemoryMapGrid;

    if FTasks.Count > 0 then
    begin
      gridTarefas.Row := 1;
      gridTarefasSelection(gridTarefas, 0, 1);
    end;

    pgMain.ActivePage := tabTarefas;

    AddLog(Format('Geração de tarefas concluída. Total de tarefas reais carregadas: %d.', [FTasks.Count]));

  finally
    FWaitingForDOMText := False;
    FWaitingForNavigation := False;
    FExpectedNavigationURL := '';
    btnGerarTarefas.Enabled := True;
  end;
end;

function TfrmMain.LoadTasksFromPlannerJSON(const AJSON: string): Boolean;
var
  JSONData: TJSONData;
  TaskObj, ParamsObj: TJSONObject;
  Arr: TJSONArray;
  ItemData, ParamsData: TJSONData;
  CleanJSON: string;
  ArrayKind: string;
  i, j: Integer;
  T: TSampleTaskItem;
  PreviousTaskID: string;

  function FindPlannerArray(AData: TJSONData; out AArr: TJSONArray; out AKind: string): Boolean;
  var
    O: TJSONObject;
    D: TJSONData;
    K: Integer;
    N: string;
  begin
    Result := False;
    AArr := nil;
    AKind := '';

    if not Assigned(AData) then
      Exit;

    if AData is TJSONArray then
    begin
      AArr := TJSONArray(AData);
      AKind := 'tasks';
      Result := True;
      Exit;
    end;

    if not (AData is TJSONObject) then
      Exit;

    O := TJSONObject(AData);

    D := O.Find('tasks');
    if Assigned(D) and (D is TJSONArray) then
    begin
      AArr := TJSONArray(D);
      AKind := 'tasks';
      Result := True;
      Exit;
    end;

    D := O.Find('steps');
    if Assigned(D) and (D is TJSONArray) then
    begin
      AArr := TJSONArray(D);
      AKind := 'tasks';
      Result := True;
      Exit;
    end;

    D := O.Find('task_list');
    if Assigned(D) and (D is TJSONArray) then
    begin
      AArr := TJSONArray(D);
      AKind := 'tasks';
      Result := True;
      Exit;
    end;

    D := O.Find('actions');
    if Assigned(D) and (D is TJSONArray) then
    begin
      AArr := TJSONArray(D);
      AKind := 'actions';
      Result := True;
      Exit;
    end;

    for K := 0 to O.Count - 1 do
    begin
      N := O.Names[K];

      if SameText(N, 'plan') or
         SameText(N, 'result') or
         SameText(N, 'output') or
         SameText(N, 'data') or
         SameText(N, 'response') or
         SameText(N, 'action_plan') or
         SameText(N, 'task_plan') then
      begin
        if FindPlannerArray(O.Items[K], AArr, AKind) then
        begin
          Result := True;
          Exit;
        end;
      end;
    end;
  end;

  function GetJSONStr(AObj: TJSONObject; const AName, AAlt1, AAlt2: string): string;
  var
    D: TJSONData;
  begin
    Result := '';

    if not Assigned(AObj) then
      Exit;

    D := AObj.Find(AName);

    if (not Assigned(D)) and (AAlt1 <> '') then
      D := AObj.Find(AAlt1);

    if (not Assigned(D)) and (AAlt2 <> '') then
      D := AObj.Find(AAlt2);

    if Assigned(D) then
      Result := Trim(JSONValueToPlainText(D));
  end;

  function GetJSONInt(AObj: TJSONObject; const AName, AAlt1: string; ADefault: Integer): Integer;
  var
    D: TJSONData;
  begin
    Result := ADefault;

    if not Assigned(AObj) then
      Exit;

    D := AObj.Find(AName);

    if (not Assigned(D)) and (AAlt1 <> '') then
      D := AObj.Find(AAlt1);

    if Assigned(D) then
      Result := StrToIntDef(JSONValueToPlainText(D), ADefault);
  end;

begin
  Result := False;

  if Trim(AJSON) = '' then
  begin
    AddLog('JSON do planejador veio vazio.');
    Exit;
  end;

  CleanJSON := LocalCleanJSONResponse(AJSON);

  try
    JSONData := GetJSON(CleanJSON);
    try
      Arr := nil;
      ArrayKind := '';

      if not FindPlannerArray(JSONData, Arr, ArrayKind) then
      begin
        AddLog('JSON do planejador não possui array "tasks", "steps", "task_list" ou "actions" em nenhum nível aceito.');
        AddLog('JSON recebido: ' + Copy(CleanJSON, 1, 3000));
        Exit;
      end;

      if not Assigned(Arr) then
      begin
        AddLog('Array do planejador não localizado.');
        AddLog('JSON recebido: ' + Copy(CleanJSON, 1, 3000));
        Exit;
      end;

      if Arr.Count = 0 then
      begin
        AddLog('Array do planejador veio vazio.');
        AddLog('JSON recebido: ' + Copy(CleanJSON, 1, 3000));
        Exit;
      end;

      FTasks.Clear;
      PreviousTaskID := '';

      for i := 0 to Arr.Count - 1 do
      begin
        ItemData := Arr.Items[i];

        if not (ItemData is TJSONObject) then
        begin
          AddLog(Format('Item %d do array "%s" não é objeto JSON. Ignorado.', [i, ArrayKind]));
          Continue;
        end;

        TaskObj := TJSONObject(ItemData);
        T := TSampleTaskItem.Create;
        try
          if SameText(ArrayKind, 'actions') then
          begin
            T.ID := GetJSONStr(TaskObj, 'id', 'action_id', 'task_id');
            T.Ordem := GetJSONInt(TaskObj, 'order', 'step_number', i + 1);
            T.Tipo := 'action';
            T.AcaoSugerida := GetJSONStr(TaskObj, 'action', 'name', 'action_name');
            T.Descricao := GetJSONStr(TaskObj, 'description', 'descricao', '');

            if T.Descricao = '' then
              T.Descricao := 'Executar ação ' + T.AcaoSugerida;

            T.Agente := GetJSONStr(TaskObj, 'agent', 'agente', 'assigned_agent');
            if T.Agente = '' then
              T.Agente := 'task_processor_agent';

            T.Dependencia := GetJSONStr(TaskObj, 'depends_on', 'dependency', 'dependencia');

            if (T.Dependencia = '') and (PreviousTaskID <> '') and SameText(T.AcaoSugerida, 'SEND_EMAIL') then
              T.Dependencia := PreviousTaskID;

            ParamsData := TaskObj.Find('parameters');
            if Assigned(ParamsData) and (ParamsData is TJSONObject) then
            begin
              ParamsObj := TJSONObject(ParamsData);
              for j := 0 to ParamsObj.Count - 1 do
                T.Params.Values[ParamsObj.Names[j]] := JSONValueToPlainText(ParamsObj.Items[j]);
            end;
          end
          else
          begin
            T.ID := GetJSONStr(TaskObj, 'id', 'task_id', '');
            T.Ordem := GetJSONInt(TaskObj, 'order', 'step_number', i + 1);
            T.Tipo := GetJSONStr(TaskObj, 'type', 'tipo', 'category');
            T.Descricao := GetJSONStr(TaskObj, 'description', 'descricao', 'task');

            if T.Descricao = '' then
              T.Descricao := GetJSONStr(TaskObj, 'instruction', 'objective', 'step');

            T.Agente := GetJSONStr(TaskObj, 'agent', 'agente', 'assigned_agent');
            if T.Agente = '' then
              T.Agente := GetJSONStr(TaskObj, 'target_agent', 'responsible_agent', '');

            T.AcaoSugerida := GetJSONStr(TaskObj, 'suggested_action', 'action', 'acao');
            if T.AcaoSugerida = '' then
              T.AcaoSugerida := GetJSONStr(TaskObj, 'action_name', 'operation', '');

            T.Dependencia := GetJSONStr(TaskObj, 'depends_on', 'dependency', 'dependencia');
            if T.Dependencia = '' then
              T.Dependencia := GetJSONStr(TaskObj, 'depends', 'after', '');

            ParamsData := TaskObj.Find('parameters');
            if Assigned(ParamsData) and (ParamsData is TJSONObject) then
            begin
              ParamsObj := TJSONObject(ParamsData);
              for j := 0 to ParamsObj.Count - 1 do
                T.Params.Values[ParamsObj.Names[j]] := JSONValueToPlainText(ParamsObj.Items[j]);
            end;
          end;

          T.RawJSON := TaskObj.AsJSON;

          if T.ID = '' then
            T.ID := 'T' + Format('%.3d', [i + 1]);

          if T.Ordem <= 0 then
            T.Ordem := i + 1;

          if T.Tipo = '' then
            T.Tipo := 'task';

          if T.Descricao = '' then
          begin
            AddLog(Format('Tarefa %s ignorada: descrição não informada.', [T.ID]));
            T.Free;
            T := nil;
            Continue;
          end;

          if T.Agente = '' then
          begin
            AddLog(Format('Tarefa %s ignorada: agent/agente não informado.', [T.ID]));
            T.Free;
            T := nil;
            Continue;
          end;

          if SameText(T.AcaoSugerida, 'CREATE_WORD_DOCUMENT') then
            T.AcaoSugerida := 'CREATE_TEXT_DOCUMENT';

          if SameText(T.AcaoSugerida, 'CREATE_TEXT_DOCUMENT') and
             IsEmptyOrPlaceholder(T.Params.Values['content']) and
             (Trim(FCapturedWebText) <> '') then
            T.Params.Values['content'] := FCapturedWebText;

          FTasks.Add(T);
          PreviousTaskID := T.ID;
          T := nil;
        except
          on E: Exception do
          begin
            AddLog(Format('Erro ao carregar item %d do array "%s": %s', [i, ArrayKind, E.Message]));
            T.Free;
          end;
        end;
      end;

      if FTasks.Count = 0 then
      begin
        AddLog('Nenhuma tarefa válida foi carregada do JSON do planejador.');
        AddLog('JSON recebido: ' + Copy(CleanJSON, 1, 3000));
        Exit;
      end;

      Result := True;
    finally
      JSONData.Free;
    end;
  except
    on E: Exception do
    begin
      AddLog('Erro ao fazer parse do JSON do planejador: ' + E.Message);
      AddLog('JSON recebido: ' + Copy(CleanJSON, 1, 3000));
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

  if not Assigned(ATask) then
  begin
    Result := False;
    AError := 'Tarefa inválida.';
    Exit;
  end;

  if ATask.Dependencia = '' then
    Exit;

  if not Assigned(FTasks) then
  begin
    Result := False;
    AError := 'Lista de tarefas não foi inicializada.';
    Exit;
  end;

  for i := 0 to FTasks.Count - 1 do
  begin
    DepTask := TSampleTaskItem(FTasks[i]);

    if DepTask.ID = ATask.Dependencia then
    begin
      if DepTask.Status <> stsDone then
      begin
        Result := False;
        AError := Format(
          'A tarefa dependente "%s" (%s) não foi concluída.',
          [DepTask.ID, DepTask.Descricao]
        );
        Exit;
      end
      else
        Exit;
    end;
  end;

  Result := False;
  AError := Format('A tarefa dependente "%s" não foi encontrada.', [ATask.Dependencia]);
end;

procedure TfrmMain.btnExecutarTarefaSelecionadaClick(Sender: TObject);
var
  T: TSampleTaskItem;
  Err: string;
  LProcessorInput: string;
  ProcessorOutput: string;
  BuilderInput: string;
  BuilderOutput: string;
  ExecutorOutput: string;
  ProcessSuccess: Boolean;
  ActionBuildSuccess: Boolean;
  ExecutorSuccess: Boolean;
  ProcessorResultText: string;
  ErroRuntime: string;
  i: Integer;
  DepTask: TSampleTaskItem;
  CompletedContext: string;
begin
  if not EnsureRuntimeObjects(ErroRuntime) then
  begin
    AddLog('Erro ao preparar objetos antes de executar tarefa: ' + ErroRuntime);
    ShowMessage('Erro ao preparar objetos antes de executar tarefa: ' + ErroRuntime);
    Exit;
  end;

  if not ValidateProviderToken(ErroRuntime) then
  begin
    AddLog('Execução cancelada: ' + ErroRuntime);
    ShowMessage(ErroRuntime);
    Exit;
  end;

  T := GetSelectedTask;

  if T = nil then
  begin
    ShowMessage('Por favor, selecione uma tarefa no grid.');
    Exit;
  end;

  if T.Status = stsCanceled then
  begin
    ShowMessage('Esta tarefa está cancelada. Reprocesse a tarefa antes de executar.');
    AddLog(Format('Execução bloqueada: tarefa "%s" está cancelada.', [T.ID]));
    Exit;
  end;

  if T.Status = stsProcessing then
  begin
    ShowMessage('Esta tarefa já está em processamento.');
    AddLog(Format('Execução bloqueada: tarefa "%s" já está em processamento.', [T.ID]));
    Exit;
  end;

  if not CanExecuteTask(T, Err) then
  begin
    ShowMessage(Err);
    AddLog('Execução bloqueada: ' + Err);
    Exit;
  end;

  AddLog(Format('Iniciando processamento real da tarefa: %s (%s)...', [T.ID, T.Descricao]));

  T.Status := stsProcessing;
  T.Resultado := '';
  RefreshTasksGrid;
  Application.ProcessMessages;

  ConfigureChatGPT;

  CompletedContext := '';

  if Assigned(FTasks) then
  begin
    for i := 0 to FTasks.Count - 1 do
    begin
      DepTask := TSampleTaskItem(FTasks[i]);

      if (DepTask.Status = stsDone) and (Trim(DepTask.Resultado) <> '') then
      begin
        CompletedContext :=
          CompletedContext +
          sLineBreak +
          'TAREFA CONCLUÍDA: ' + DepTask.ID + sLineBreak +
          'Descrição: ' + DepTask.Descricao + sLineBreak +
          'Resultado: ' + DepTask.Resultado + sLineBreak;
      end;
    end;
  end;

  // Tarefa 2.5 — Limitar CompletedContext
  CompletedContext := LimitSampleText(CompletedContext, 12000);

  LProcessorInput :=
    '=== TAREFA SELECIONADA ===' + sLineBreak +
    'ID: ' + T.ID + sLineBreak +
    'Ordem: ' + IntToStr(T.Ordem) + sLineBreak +
    'Tipo: ' + T.Tipo + sLineBreak +
    'Descrição: ' + T.Descricao + sLineBreak +
    'Agente responsável: ' + T.Agente + sLineBreak +
    'Ação sugerida: ' + T.AcaoSugerida + sLineBreak +
    'Dependência: ' + T.Dependencia + sLineBreak;

  if Trim(T.RawJSON) <> '' then
  begin
    LProcessorInput :=
      LProcessorInput +
      sLineBreak +
      '=== JSON ORIGINAL DA TAREFA ===' +
      sLineBreak +
      T.RawJSON +
      sLineBreak;
  end;

  if Assigned(T.Params) and (T.Params.Count > 0) then
  begin
    LProcessorInput :=
      LProcessorInput +
      sLineBreak +
      '=== PARAMETROS OPERACIONAIS DA TAREFA ===' +
      sLineBreak +
      T.Params.Text +
      sLineBreak;
  end;

  if Trim(CompletedContext) <> '' then
  begin
    LProcessorInput :=
      LProcessorInput +
      sLineBreak +
      '=== CONTEXTO DAS TAREFAS JÁ CONCLUÍDAS ===' +
      sLineBreak +
      CompletedContext +
      sLineBreak;
  end;

  // Tarefa 2.3 — Limitar conteúdo capturado no LProcessorInput
  if Trim(FCapturedWebText) <> '' then
  begin
    LProcessorInput :=
      LProcessorInput +
      sLineBreak +
      '=== RESUMO DO CONTEÚDO REAL CAPTURADO DO SITE ===' +
      sLineBreak +
      LimitSampleText(FCapturedWebText, 12000) +
      sLineBreak;
  end;

  if Assigned(FActionExecutor) and (FActionExecutor.ExecutionContext.Count > 0) then
  begin
    LProcessorInput :=
      LProcessorInput +
      sLineBreak +
      '=== CONTEXTO DE EXECUÇÃO DO ACTION EXECUTOR ===' +
      sLineBreak +
      FActionExecutor.ExecutionContext.Text +
      sLineBreak;
  end;

  LProcessorInput :=
    LProcessorInput +
    sLineBreak +
    '=== REGRAS OBRIGATÓRIAS ===' + sLineBreak +
    'Execute somente a tarefa selecionada.' + sLineBreak +
    'Não invente dados.' + sLineBreak +
    'Use somente dados do prompt, do conteúdo real capturado, do DOM/browser e dos resultados das tarefas anteriores.' + sLineBreak +
    'Se faltar informação essencial, retorne erro claro explicando o que faltou.' + sLineBreak +
    'Se a tarefa for gerar currículo/texto/documento, produza o texto final completo.' + sLineBreak +
    'Se a tarefa for preparar e-mail, produza assunto, destinatário e corpo com base nos dados reais.' + sLineBreak +
    'Se a tarefa for BROWSER_*, preserve url, selector, value, index, timeout e objetivo da ação. Não invente resultado de navegação antes do executor DOM.';

  ProcessSuccess := False;
  ProcessorOutput := '';

  if IsBrowserActionName(T.AcaoSugerida) then
  begin
    AddLog('Tarefa operacional de browser detectada. Pulando ProcessTask para evitar processamento LLM desnecessário.');

    ProcessorOutput :=
      '{' +
      '"confidence":1.0,' +
      '"analysis":"Tarefa operacional de browser. Processamento cognitivo ignorado.",' +
      '"explanation":"A ação já possui parâmetros operacionais e será enviada ao ActionBuilder.",' +
      '"action_taken":"TASK_PROCESSED",' +
      '"result_type":"browser_instruction",' +
      '"result":"' + StringReplace(StringReplace(T.Descricao + ' ' + T.Params.Text, '\', '\\', [rfReplaceAll]), '"', '\"', [rfReplaceAll]) + '",' +
      '"missing_information":"",' +
      '"analysis_questions":[]' +
      '}';

    ProcessSuccess := True;
  end
  else
  begin
    AddLog('Executando TaskProcessorAgent.ProcessTask...');

    try
      ProcessSuccess := FTaskProcessorAgent.ProcessTask(LProcessorInput, ProcessorOutput);
    except
      on E: Exception do
      begin
        ProcessSuccess := False;
        AddLog('Exception no TaskProcessorAgent.ProcessTask: ' + E.Message);
      end;
    end;
  end;

  if not ProcessSuccess then
  begin
    T.Status := stsFailed;
    T.Resultado := SanitizeLLMError(FTaskProcessorAgent.LastError);

    AddLog('Falha no TaskProcessorAgent.ProcessTask: ' + T.Resultado);

    RefreshTasksGrid;
    RefreshMemoryMapGrid;
    Exit;
  end;

  if Trim(ProcessorOutput) = '' then
  begin
    T.Status := stsFailed;
    T.Resultado := 'TaskProcessorAgent.ProcessTask retornou resposta vazia.';

    AddLog('Falha no processamento: resposta vazia do TaskProcessorAgent.');

    RefreshTasksGrid;
    RefreshMemoryMapGrid;
    Exit;
  end;

  ProcessorResultText := '';
  if not FTaskProcessorAgent.ExtractTaskProcessResult(ProcessorOutput, ProcessorResultText) then
    ProcessorResultText := ProcessorOutput;

  T.Resultado :=
    ProcessorResultText +
    sLineBreak +
    sLineBreak +
    '=== JSON DO PROCESSADOR ===' +
    sLineBreak +
    ProcessorOutput;

  AddLog('Processamento cognitivo concluído.');

  if Trim(T.AcaoSugerida) = '' then
  begin
    T.Status := stsDone;
    AddLog(Format('Tarefa "%s" concluída sem ação operacional.', [T.ID]));

    RefreshTasksGrid;
    RefreshMemoryMapGrid;
    Exit;
  end;

  if SameText(T.AcaoSugerida, 'CREATE_WORD_DOCUMENT') then
  begin
    AddLog('Ação CREATE_WORD_DOCUMENT recusada: o sample agora gera somente texto.');
    T.Status := stsFailed;
    T.Resultado := 'Ação CREATE_WORD_DOCUMENT não é permitida. Use CREATE_TEXT_DOCUMENT.';

    RefreshTasksGrid;
    RefreshMemoryMapGrid;
    Exit;
  end;

  BuilderInput :=
    '=== RESULTADO DO PROCESSAMENTO DA TAREFA ===' + sLineBreak +
    ProcessorResultText +
    sLineBreak +
    sLineBreak +
    '=== AÇÃO OPERACIONAL SOLICITADA ===' + sLineBreak +
    T.AcaoSugerida +
    sLineBreak +
    sLineBreak +
    '=== PARAMETROS ORIGINAIS DA TAREFA ===' + sLineBreak +
    T.Params.Text +
    sLineBreak +
    '=== CONTEXTO DE EXECUÇÃO DISPONÍVEL ===' + sLineBreak;

  if Assigned(FActionExecutor) then
    BuilderInput := BuilderInput + FActionExecutor.ExecutionContext.Text + sLineBreak;

  BuilderInput :=
    BuilderInput +
    sLineBreak +
    '=== REGRAS OBRIGATÓRIAS PARA O ACTION BUILDER ===' + sLineBreak +
    'Retorne exclusivamente JSON válido.' + sLineBreak +
    'O JSON deve conter o campo "actions" como array.' + sLineBreak +
    'Cada item de "actions" deve conter "action" e "parameters".' + sLineBreak +
    'Use somente uma das ações permitidas:' + sLineBreak +
    '- CREATE_TEXT_DOCUMENT' + sLineBreak +
    '- SEND_EMAIL' + sLineBreak +
    '- REGISTER_RESULT' + sLineBreak +
    '- REPLAN_FROM_DOM' + sLineBreak +
    '- BROWSER_NAVIGATE' + sLineBreak +
    '- BROWSER_WAIT_SELECTOR' + sLineBreak +
    '- BROWSER_READ_PAGE' + sLineBreak +
    '- BROWSER_DOM_LIST' + sLineBreak +
    '- BROWSER_CAPTURE_TEXT' + sLineBreak +
    '- BROWSER_SET_VALUE' + sLineBreak +
    '- BROWSER_FOCUS' + sLineBreak +
    '- BROWSER_CLICK' + sLineBreak +
    '- BROWSER_PRESS_ENTER' + sLineBreak +
    '- BROWSER_SUBMIT_FORM' + sLineBreak +
    '- BROWSER_SCREENSHOT' + sLineBreak +
    'Não use CREATE_WORD_DOCUMENT.' + sLineBreak +
    'Não gere DOCX, Word ou anexo fake.' + sLineBreak +
    'Para CREATE_TEXT_DOCUMENT, parameters deve conter pelo menos "title" e "content".' + sLineBreak +
    'Para SEND_EMAIL, parameters deve conter pelo menos "to", "subject" e "body".' + sLineBreak +
    'Para REGISTER_RESULT, parameters deve conter "status" ou "message".' + sLineBreak +
    'Para BROWSER_NAVIGATE, parameters deve conter "url".' + sLineBreak +
    'Para BROWSER_WAIT_SELECTOR, parameters deve conter "selector" e opcionalmente "timeout".' + sLineBreak +
    'Para BROWSER_READ_PAGE, parameters pode conter "selector" e "dom_list_selector".' + sLineBreak +
    'Para BROWSER_DOM_LIST, parameters deve conter "selector".' + sLineBreak +
    'Para BROWSER_SET_VALUE, parameters deve conter "selector", "value" e opcionalmente "index".' + sLineBreak +
    'Para BROWSER_FOCUS, BROWSER_CLICK, BROWSER_PRESS_ENTER e BROWSER_SUBMIT_FORM, parameters deve conter "selector" e opcionalmente "index".' + sLineBreak +
    'Para BROWSER_CAPTURE_TEXT, parameters deve conter "selector".' + sLineBreak +
    'Se a ação for browser, preserve url, selector, index, timeout e value. Não invente seletor quando o DOM ainda não foi lido.';

  ActionBuildSuccess := False;
  BuilderOutput := '';

  if IsBrowserActionName(T.AcaoSugerida) and
     (Pos('BROWSER_', UpperCase(Trim(T.AcaoSugerida))) = 1) then
  begin
    AddLog('Tarefa BROWSER_* detectada. Montando ação única sem ActionBuilder para evitar SEND_EMAIL prematuro.');

    BuilderOutput := BuildSingleActionJSON(T);
    ActionBuildSuccess := True;

    AddLog('Plano determinístico gerado: uma única ação ' + T.AcaoSugerida + '.');
  end
  else
  begin
    AddLog('Gerando plano de ações pelo ActionBuilderAgent...');

    try
      ActionBuildSuccess := FActionBuilderAgent.BuildActionsWithRecovery(BuilderInput, BuilderOutput);
    except
      on E: Exception do
      begin
        ActionBuildSuccess := False;
        AddLog('Exception no ActionBuilderAgent: ' + E.Message);
      end;
    end;
  end;

  if not ActionBuildSuccess then
  begin
    T.Status := stsFailed;
    T.Resultado := SanitizeLLMError(FActionBuilderAgent.LastError);

    AddLog('Falha no ActionBuilderAgent: ' + T.Resultado);

    RefreshTasksGrid;
    RefreshMemoryMapGrid;
    Exit;
  end;

  if Trim(BuilderOutput) = '' then
  begin
    T.Status := stsFailed;
    T.Resultado := 'ActionBuilderAgent retornou plano de ações vazio.';

    AddLog('Falha no ActionBuilderAgent: plano de ações vazio.');

    RefreshTasksGrid;
    RefreshMemoryMapGrid;
    Exit;
  end;

  AddLog('Plano de ações gerado pelo ActionBuilderAgent.');
  AddLog('Validando/executando plano pelo ActionExecutor real...');

  ExecutorSuccess := False;
  ExecutorOutput := '';

  try
    ExecutorSuccess := FActionExecutor.ExecutePreparedActionsReal(BuilderOutput, ExecutorOutput);
  except
    on E: Exception do
    begin
      ExecutorSuccess := False;
      AddLog('Exception no ActionExecutor real: ' + E.Message);
    end;
  end;

  if not ExecutorSuccess then
  begin
    AddLog('[EXECUTOR REAL] Falhou: ' + SanitizeLLMError(FActionExecutor.LastError));

    if ContainsBrowserAction(BuilderOutput) then
    begin
      AddLog('[EXECUTOR REAL] Plano contém BROWSER_*. Fallback legado não será usado.');
    end
    else
    begin
      AddLog('[FALLBACK] Falha no Executor Real. Tentando legado DispatchPreparedActions...');
      try
        ExecutorSuccess := FActionExecutor.ExecutePlan(BuilderOutput, ExecutorOutput);
        if ExecutorSuccess then
          ExecutorSuccess := DispatchPreparedActions(BuilderOutput);
      except
        on E: Exception do
        begin
          ExecutorSuccess := False;
          AddLog('Exception no fallback legado: ' + E.Message);
        end;
      end;
    end;
  end;

  if not ExecutorSuccess then
  begin
    T.Status := stsFailed;
    T.Resultado := SanitizeLLMError(FActionExecutor.LastError);

    AddLog('Falha no ActionExecutor: ' + T.Resultado);

    RefreshTasksGrid;
    RefreshMemoryMapGrid;
    Exit;
  end;

  AddLog('Plano executado com sucesso pelo ActionExecutor real.');

  T.Status := stsDone;
  T.Resultado :=
    ProcessorOutput +
    sLineBreak +
    sLineBreak +
    '=== PLANO DE AÇÕES EXECUTADO ===' +
    sLineBreak +
    BuilderOutput;

  AddLog(Format('Tarefa "%s" concluída com sucesso.', [T.ID]));

  if CanTriggerReplan(T) and HasPendingTasksAfter(T) then
  begin
    AddLog('[REPLAN] Verificando se tarefas futuras precisam ser reescritas com base no resultado atual...');
    if not ReplanPendingTasksIfNeeded(T) then
      AddLog('[REPLAN] Falha ao replanejar tarefas futuras. Fluxo continuará com plano atual.');
  end;

  RefreshTasksGrid;
  RefreshMemoryMapGrid;
end;

function TfrmMain.DispatchPreparedActions(const APreparedActionsJSON: string): Boolean;
var
  JSONData: TJSONData;
  Obj, ActObj, ParamsObj: TJSONObject;
  ActionsArr: TJSONArray;
  ItemData: TJSONData;
  ParamsData: TJSONData;
  ActionName: string;
  Params: TStringList;
  ActionResultList: TStringList;
  CleanJSON: string;
  i, j: Integer;
  ActionOk: Boolean;
begin
  Result := False;

  if ContainsBrowserAction(APreparedActionsJSON) then
  begin
    AddLog('[DISPATCH] Plano contém ação BROWSER_*. Fallback legado recusado. Use ExecutePreparedActionsReal.');
    Exit;
  end;

  if Trim(APreparedActionsJSON) = '' then
  begin
    AddLog('Plano de ações vazio. Nada a despachar.');
    Exit;
  end;

  CleanJSON := LocalCleanJSONResponse(APreparedActionsJSON);

  try
    JSONData := GetJSON(CleanJSON);
    try
      ActionsArr := nil;

      if JSONData is TJSONObject then
      begin
        Obj := TJSONObject(JSONData);

        if not GetJSONArrayField(Obj, 'actions', ActionsArr) then
        begin
          AddLog('Plano de ações não possui array "actions".');
          Exit;
        end;
      end
      else if JSONData is TJSONArray then
        ActionsArr := TJSONArray(JSONData)
      else
      begin
        AddLog('Plano de ações não é objeto nem array JSON.');
        Exit;
      end;

      if not Assigned(ActionsArr) then
      begin
        AddLog('Array de ações não localizado.');
        Exit;
      end;

      if ActionsArr.Count = 0 then
      begin
        AddLog('Array "actions" veio vazio.');
        Exit;
      end;

      Params := TStringList.Create;
      try
        Result := True;

        for i := 0 to ActionsArr.Count - 1 do
        begin
          ItemData := ActionsArr.Items[i];

          if not (ItemData is TJSONObject) then
          begin
            AddLog(Format('Ação %d ignorada: item não é objeto JSON.', [i]));
            Result := False;
            Continue;
          end;

          ActObj := TJSONObject(ItemData);
          ActionName := Trim(ActObj.Get('action', ''));

          if ActionName = '' then
            ActionName := Trim(ActObj.Get('name', ''));

          if ActionName = '' then
          begin
            AddLog(Format('Ação %d sem campo "action/name".', [i]));
            Result := False;
            Continue;
          end;

          Params.Clear;

          ParamsData := ActObj.Find('parameters');

          if Assigned(ParamsData) then
          begin
            if ParamsData is TJSONObject then
            begin
              ParamsObj := TJSONObject(ParamsData);

              for j := 0 to ParamsObj.Count - 1 do
                Params.Values[ParamsObj.Names[j]] := JSONValueToPlainText(ParamsObj.Items[j]);
            end
            else
            begin
              AddLog(Format('Parâmetros da ação "%s" existem, mas não são objeto JSON.', [ActionName]));
              Result := False;
              Continue;
            end;
          end;

          if Assigned(FActionExecutor) and Assigned(FActionExecutor.OnBeforeActionExecute) then
            FActionExecutor.OnBeforeActionExecute(FActionExecutor, ActionName, Params, FActionExecutor.ExecutionContext);

          ActionOk := False;

          if SameText(ActionName, 'CREATE_TEXT_DOCUMENT') then
          begin
            if Assigned(FCreateTextAction) then
              ActionOk := FCreateTextAction.RunAction(Params, False)
            else
              AddLog('[DISPATCH] FCreateTextAction não inicializado.');
          end
          else if SameText(ActionName, 'SEND_EMAIL') then
          begin
            if Assigned(FSendEmailAction) then
            begin
              ConfigureEmailAction;
              FSendEmailAction.GeneratedTextFileName := edArquivoWordGerado.Text;
              ActionOk := FSendEmailAction.RunAction(Params, False);
            end
            else
              AddLog('[DISPATCH] FSendEmailAction não inicializado.');
          end
          else if SameText(ActionName, 'REGISTER_RESULT') then
          begin
            if Assigned(FRegisterResultAction) then
              ActionOk := FRegisterResultAction.RunAction(Params, False)
            else
              AddLog('[DISPATCH] FRegisterResultAction não inicializado.');
          end
          else
          begin
            AddLog('[DISPATCH] Ação desconhecida recusada: ' + ActionName);
            ActionOk := False;
          end;

          if ActionOk then
          begin
            ActionResultList := TStringList.Create;
            try
              if SameText(ActionName, 'CREATE_TEXT_DOCUMENT') then
              begin
                ActionResultList.Values['content'] := FCreateTextAction.LastContent;
                ActionResultList.Values['filename'] := FCreateTextAction.LastGeneratedFile;
              end;

              if Assigned(FActionExecutor) and Assigned(FActionExecutor.OnAfterActionExecute) then
                FActionExecutor.OnAfterActionExecute(FActionExecutor, ActionName, Params, ActionResultList, FActionExecutor.ExecutionContext);
            finally
              ActionResultList.Free;
            end;
          end;

          if not ActionOk then
            Result := False;
        end;
      finally
        Params.Free;
      end;
    finally
      JSONData.Free;
    end;
  except
    on E: Exception do
    begin
      AddLog('Falha ao despachar ações: ' + E.Message);
      AddLog('JSON recebido: ' + Copy(CleanJSON, 1, 1000));
      Result := False;
    end;
  end;
end;

function TfrmMain.ContainsBrowserAction(const APreparedActionsJSON: string): Boolean;
begin
  Result := Pos('BROWSER_', UpperCase(APreparedActionsJSON)) > 0;
end;

function TfrmMain.ParamsToJSON(AParams: TStrings): string;
var
  Obj: TJSONObject;
  i, ExistingIndex: Integer;
  Key, Value: string;
begin
  Obj := TJSONObject.Create;
  try
    if Assigned(AParams) then
    begin
      for i := 0 to AParams.Count - 1 do
      begin
        Key := Trim(AParams.Names[i]);

        if Key = '' then
          Continue;

        Value := AParams.ValueFromIndex[i];

        ExistingIndex := Obj.IndexOfName(Key);
        if ExistingIndex >= 0 then
          Obj.Delete(ExistingIndex);

        Obj.Add(Key, Value);
      end;
    end;

    Result := Obj.AsJSON;
  finally
    Obj.Free;
  end;
end;

function TfrmMain.BuildSingleActionJSON(ATask: TSampleTaskItem): string;
var
  ActionName: string;
begin
  if not Assigned(ATask) then
    Exit('{"actions":[]}');

  ActionName := Trim(ATask.AcaoSugerida);

  Result :=
    '{' +
    '"confidence":1.0,' +
    '"analysis":"Ação montada deterministicamente a partir da tarefa selecionada.",' +
    '"explanation":"O ActionBuilder foi ignorado para evitar expansão indevida do plano e execução prematura de ações como SEND_EMAIL.",' +
    '"action_taken":"ACTION_PARAMETERS_PREPARED",' +
    '"actions":[' +
      '{' +
        '"action":' + TJSONStringType(ActionName).AsJSON + ',' +
        '"parameters":' + ParamsToJSON(ATask.Params) +
      '}' +
    '],' +
    '"analysis_questions":[]' +
    '}';
end;

procedure TfrmMain.btnExecutarTodasClick(Sender: TObject);
var
  i: Integer;
  T: TSampleTaskItem;
  Err: string;
  ExecutedAny: Boolean;
begin
  if not Assigned(FTasks) then
    Exit;

  repeat
    ExecutedAny := False;

    for i := 0 to FTasks.Count - 1 do
    begin
      T := TSampleTaskItem(FTasks[i]);

      if (T.Status = stsPending) or (T.Status = stsFailed) then
      begin
        if CanExecuteTask(T, Err) then
        begin
          gridTarefas.Row := i + 1;
          btnExecutarTarefaSelecionadaClick(nil);
          ExecutedAny := True;
          Application.ProcessMessages;
          Sleep(500);
          Break;
        end
        else
          AddLog(Format('Tarefa "%s" aguardando dependência: %s', [T.ID, Err]));
      end;
    end;
  until not ExecutedAny;
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
var
  Erro: string;
begin
  if not EnsureRuntimeObjects(Erro) then
  begin
    ShowMessage('Erro ao preparar mapa de memória: ' + Erro);
    Exit;
  end;

  ForceDirectories('output');
  FMemoryMap.SaveToFile('output' + DirectorySeparator + 'memory_map.txt');
  ShowMessage('Mapa de Memória exportado como texto em output/memory_map.txt');
end;

procedure TfrmMain.btnExportarMapaJSONClick(Sender: TObject);
var
  Erro: string;
begin
  if not EnsureRuntimeObjects(Erro) then
  begin
    ShowMessage('Erro ao preparar mapa de memória: ' + Erro);
    Exit;
  end;

  ForceDirectories('output');
  FMemoryMap.SaveToFile('output' + DirectorySeparator + 'memory_map.json');
  ShowMessage('Mapa de Memória exportado como JSON em output/memory_map.json');
end;

procedure TfrmMain.btnLimparLogClick(Sender: TObject);
begin
  if Assigned(memLog) then
    memLog.Clear;
end;

procedure TfrmMain.btnSalvarLogClick(Sender: TObject);
begin
  ForceDirectories('output');

  if Assigned(memLog) then
    memLog.Lines.SaveToFile('output' + DirectorySeparator + 'agent_task_memory_action_demo.log');

  ShowMessage('Log salvo em output/agent_task_memory_action_demo.log');
end;

procedure TfrmMain.btnAbrirArquivoWordClick(Sender: TObject);
var
  Path: string;
begin
  Path := Trim(edArquivoWordGerado.Text);

  if Path = '' then
  begin
    ShowMessage('Nenhum arquivo texto foi gerado ainda.');
    Exit;
  end;

  if not FileExists(Path) then
  begin
    ShowMessage('Arquivo não encontrado: ' + Path);
    Exit;
  end;

  OpenURL('file:///' + ExpandFileName(Path));
end;

procedure TfrmMain.btnEnviarEmailRealClick(Sender: TObject);
var
  Params: TStringList;
  Erro: string;
begin
  if not EnsureRuntimeObjects(Erro) then
  begin
    ShowMessage('Erro ao preparar envio de e-mail: ' + Erro);
    Exit;
  end;

  Params := TStringList.Create;
  try
    Params.Values['to'] := edEmailDestino.Text;
    Params.Values['subject'] := edAssuntoEmail.Text;
    Params.Values['body'] := memCorpoEmail.Text;

    if Assigned(FSendEmailAction) then
    begin
      ConfigureEmailAction;
      FSendEmailAction.GeneratedTextFileName := edArquivoWordGerado.Text;
      FSendEmailAction.RunAction(Params, False);
    end
    else
      AddLog('FSendEmailAction não foi inicializado.');
  finally
    Params.Free;
  end;
end;

procedure TfrmMain.btnBrowserNavigateClick(Sender: TObject);
begin
  if Trim(edBrowserURL.Text) <> '' then
  begin
    if EnsureBrowser then
    begin
      AddLog('Navegando via botão do formulário para: ' + edBrowserURL.Text);
      AIChromiumBrowser1.Navigate(edBrowserURL.Text);
    end;
  end;
end;

procedure TfrmMain.AIChromiumBrowser1LoadURL(Sender: TObject; const AURL: string; AIsMainFrame: Boolean);
begin
  if AIsMainFrame then
  begin
    if Assigned(lblBrowserStatus) then
      lblBrowserStatus.Caption := 'Status: Carregando ' + AURL;

    AddLog('Carregando URL: ' + AURL);
  end;
end;

procedure TfrmMain.AIChromiumBrowser1FinishedLoadURL(Sender: TObject; const AURL: string; AHttpStatusCode: Integer; AIsMainFrame: Boolean);
begin
  if AIsMainFrame then
  begin
    if Assigned(lblBrowserStatus) then
      lblBrowserStatus.Caption := 'Status: Concluído ' + AURL;

    AddLog(Format('Concluído carregamento de "%s" com status %d.', [AURL, AHttpStatusCode]));

    if FWaitingForNavigation then
    begin
      if (FExpectedNavigationURL = '') or
         SameText(AURL, FExpectedNavigationURL) or
         (Pos(LowerCase(FExpectedNavigationURL), LowerCase(AURL)) = 1) then
      begin
        FWaitingForNavigation := False;
      end
      else
      begin
        AddLog('Navegação intermediária ignorada: ' + AURL);
      end;
    end;
  end;
end;

procedure TfrmMain.AIChromiumBrowser1DOMResult(Sender: TObject; const AKind: string; const ASelector: string; AIndex: Integer; ACount: Integer; const AJSON: string);
var
  ValueText: string;
  Parser: TJSONParser;
  Data: TJSONData;
  Obj: TJSONObject;
  ValueData: TJSONData;
begin
  AddLog(Format('DOM Result recebido: kind=%s, selector=%s', [AKind, ASelector]));

  FLastBrowserDOMKind := AKind;
  FLastBrowserDOMSelector := ASelector;
  FLastBrowserDOMJSON := AJSON;
  FWaitingBrowserDOM := False;

  ValueText := '';

  Parser := nil;
  Data := nil;
  try
    Parser := TJSONParser.Create(AJSON, []);
    Data := Parser.Parse;

    if Data is TJSONObject then
    begin
      Obj := TJSONObject(Data);
      ValueData := Obj.Find('value');

      if Assigned(ValueData) then
        ValueText := JSONValueToPlainText(ValueData);
    end;
  except
    on E: Exception do
      AddLog('Erro ao interpretar retorno DOM: ' + E.Message);
  end;

  Data.Free;
  Parser.Free;

  if (ValueText <> '') and
     (SameText(AKind, 'dom-get-property') or SameText(AKind, 'capture-text') or SameText(AKind, 'text')) then
  begin
    FCapturedWebText := ValueText;
    AddLog(Format('Texto real capturado da página. Tamanho: %d caracteres.', [Length(FCapturedWebText)]));
    FWaitingForDOMText := False;
  end;

  if SameText(ASelector, 'body') and (ValueText <> '') then
  begin
    FCapturedWebText := ValueText;
    FWaitingForDOMText := False;
  end;

  if Assigned(FActionExecutor) then
  begin
    FActionExecutor.ExecutionContext.Values['browser.last_dom_kind'] := AKind;
    FActionExecutor.ExecutionContext.Values['browser.last_dom_selector'] := ASelector;
    FActionExecutor.ExecutionContext.Values['browser.last_dom_json'] := AJSON;

    if ValueText <> '' then
    begin
      FActionExecutor.ExecutionContext.Values['browser.last_text'] := ValueText;
      FActionExecutor.ExecutionContext.Values['browser.last_result_text'] := ValueText;
    end;
  end;
end;

function TfrmMain.WaitBrowserDOMResult(ATimeoutMs: Integer): Boolean;
var
  StartTicks: QWord;
begin
  StartTicks := GetTickCount64;

  while FWaitingBrowserDOM and (GetTickCount64 - StartTicks < QWord(ATimeoutMs)) do
  begin
    Application.ProcessMessages;
    Sleep(50);
  end;

  if FWaitingBrowserDOM then
  begin
    FWaitingBrowserDOM := False;
    Exit(False);
  end;

  Result := True;
end;

function TfrmMain.WaitBrowserNavigation(ATimeoutMs: Integer): Boolean;
var
  StartTicks: QWord;
begin
  StartTicks := GetTickCount64;

  while FWaitingForNavigation and (GetTickCount64 - StartTicks < QWord(ATimeoutMs)) do
  begin
    Application.ProcessMessages;
    Sleep(50);
  end;

  if FWaitingForNavigation then
  begin
    FWaitingForNavigation := False;
    Exit(False);
  end;

  Result := True;
end;

function TfrmMain.EnsureBrowser: Boolean;
begin
  Result := False;

  if not Assigned(AIChromiumBrowser1) then
  begin
    AddLog('Erro: AIChromiumBrowser1 não foi inicializado.');
    Exit;
  end;

  if not Assigned(ChromiumWindow1) then
  begin
    AddLog('Erro: ChromiumWindow1 não foi inicializado.');
    Exit;
  end;

  if not Assigned(AIChromiumBrowser1.ChromiumWindow) then
    AIChromiumBrowser1.ChromiumWindow := ChromiumWindow1;

  if AIChromiumBrowser1.BrowserReady then
  begin
    Result := True;
    Exit;
  end;

  AddLog('Inicializando Chromium...');

  try
    Result := AIChromiumBrowser1.InitializeBrowser;
  except
    on E: Exception do
    begin
      Result := False;
      AddLog('Exception ao inicializar Chromium: ' + E.Message);
    end;
  end;

  if Result then
  begin
    if Assigned(lblBrowserStatus) then
      lblBrowserStatus.Caption := 'Status: Inicializando...';

    AddLog('Inicialização do Chromium solicitada.');
  end
  else
  begin
    if Assigned(lblBrowserStatus) then
      lblBrowserStatus.Caption := 'Status: Erro na inicialização';

    AddLog('Erro ao inicializar Chromium: ' + AIChromiumBrowser1.LastError);
  end;
end;

function TfrmMain.ExtractURLFromPrompt(const APrompt: string): string;
var
  StartPos, EndPos: Integer;
begin
  Result := '';

  StartPos := Pos('http://', APrompt);

  if StartPos = 0 then
    StartPos := Pos('https://', APrompt);

  if StartPos > 0 then
  begin
    EndPos := StartPos;

    while (EndPos <= Length(APrompt)) and (APrompt[EndPos] > ' ') do
      Inc(EndPos);

    Result := Copy(APrompt, StartPos, EndPos - StartPos);

    while (Result <> '') and (Result[Length(Result)] in ['.', ',', ';', ')', ']', '}']) do
      Delete(Result, Length(Result), 1);
  end;
end;

{ Event methods }

procedure TfrmMain.OnMemoryMapAfterCreateStep(Sender: TObject; AItem: TAIAgentMemoryMapItem);
begin
  if Assigned(AItem) then
    AddLog(Format('[MAPA] Criou etapa para o agente: %s', [AItem.NomeAgente]));
end;

procedure TfrmMain.OnMemoryMapAfterCloseStep(Sender: TObject; AItem: TAIAgentMemoryMapItem);
begin
  if Assigned(AItem) then
    AddLog(Format('[MAPA] Fechou etapa do agente: %s. Ação: %s', [AItem.NomeAgente, AItem.AcaoTomada]));

  RefreshMemoryMapGrid;
end;

procedure TfrmMain.OnMemoryMapInformationLossDetected(Sender: TObject; AItem: TAIAgentMemoryMapItem; const ALostInfo: string);
begin
  if Assigned(AItem) then
    AddLog(Format('[MAPA - ATENÇÃO] Perda de informação na etapa %s: %s', [AItem.NomeAgente, ALostInfo]))
  else
    AddLog('[MAPA - ATENÇÃO] Perda de informação: ' + ALostInfo);
end;

procedure TfrmMain.OnMemoryMapLog(Sender: TObject; const AMessage: string);
begin
  AddLog('[MAPA - LOG] ' + AMessage);
end;

procedure TfrmMain.ActionExecutorBeforeActionExecute(Sender: TObject; const AActionName: string; AParams: TStrings; AExecutionContext: TStrings);
begin
  AddLog(Format('[EXECUTOR - ANTES] Resolvendo parâmetros para ação: %s', [AActionName]));

  if SameText(AActionName, 'SEND_EMAIL') then
  begin
    if IsEmptyOrPlaceholder(AParams.Values['body']) then
    begin
      AParams.Values['body'] := AExecutionContext.Values['last_text_content'];
      AddLog('[EXECUTOR] Substituído corpo de e-mail genérico pelo texto do contexto de execução.');
    end;

    if IsEmptyOrPlaceholder(AParams.Values['body']) then
      AParams.Values['body'] := AExecutionContext.Values['browser.last_result_text'];

    if Assigned(memCorpoEmail) then
      memCorpoEmail.Text := AParams.Values['body'];
    if Assigned(edEmailDestino) then
      edEmailDestino.Text := AParams.Values['to'];
    if Assigned(edAssuntoEmail) then
      edAssuntoEmail.Text := AParams.Values['subject'];
  end;
end;

procedure TfrmMain.ActionExecutorAfterActionExecute(Sender: TObject; const AActionName: string; AParams: TStrings; AResult: TStrings; AExecutionContext: TStrings);
begin
  AddLog(Format('[EXECUTOR - DEPOIS] Ação concluída: %s', [AActionName]));

  if SameText(AActionName, 'CREATE_TEXT_DOCUMENT') then
  begin
    if Assigned(FCreateTextAction) then
    begin
      AExecutionContext.Values['last_text_content'] := FCreateTextAction.LastContent;
      AExecutionContext.Values['last_text_filename'] := FCreateTextAction.LastGeneratedFile;
    end;
    AddLog('[EXECUTOR] Publicado last_text_content e last_text_filename no contexto de execução.');
  end;
end;

procedure TfrmMain.ActionExecutorBeforePreparedAction(
  Sender: TObject;
  const AActionName: string;
  AParams: TStrings;
  AExecutionContext: TStrings;
  var ACanExecute: Boolean
);
var
  UrlStr, SelectorStr: string;
begin
  AddLog(Format('[EXECUTOR REAL] Preparando para executar ação: %s', [AActionName]));

  if SameText(AActionName, 'BROWSER_NAVIGATE') or
     SameText(AActionName, 'BROWSER_WAIT_SELECTOR') or
     SameText(AActionName, 'BROWSER_READ_PAGE') or
     SameText(AActionName, 'BROWSER_DOM_LIST') or
     SameText(AActionName, 'BROWSER_CAPTURE_TEXT') or
     SameText(AActionName, 'BROWSER_SET_VALUE') or
     SameText(AActionName, 'BROWSER_FOCUS') or
     SameText(AActionName, 'BROWSER_CLICK') or
     SameText(AActionName, 'BROWSER_PRESS_ENTER') or
     SameText(AActionName, 'BROWSER_SUBMIT_FORM') or
     SameText(AActionName, 'BROWSER_SCREENSHOT') then
  begin
    if not EnsureBrowser then
    begin
      AddLog('[EXECUTOR REAL] ERRO: Chromium não está pronto.');
      ACanExecute := False;
      Exit;
    end;
  end;

  if SameText(AActionName, 'BROWSER_NAVIGATE') then
  begin
    UrlStr := Trim(AParams.Values['url']);
    if UrlStr = '' then
    begin
      AddLog('[EXECUTOR REAL] ERRO: URL está vazia.');
      ACanExecute := False;
      Exit;
    end;

    FExpectedNavigationURL := UrlStr;
    FWaitingForNavigation := True;
  end
  else if SameText(AActionName, 'BROWSER_SET_VALUE') or
          SameText(AActionName, 'BROWSER_CLICK') or
          SameText(AActionName, 'BROWSER_FOCUS') or
          SameText(AActionName, 'BROWSER_PRESS_ENTER') or
          SameText(AActionName, 'BROWSER_SUBMIT_FORM') or
          SameText(AActionName, 'BROWSER_WAIT_SELECTOR') then
  begin
    SelectorStr := Trim(AParams.Values['selector']);
    if SelectorStr = '' then
    begin
      AddLog('[EXECUTOR REAL] ERRO: Seletor CSS vazio para ação interativa.');
      ACanExecute := False;
      Exit;
    end;
  end;

  if SameText(AActionName, 'BROWSER_READ_PAGE') or
     SameText(AActionName, 'BROWSER_DOM_LIST') or
     SameText(AActionName, 'BROWSER_CAPTURE_TEXT') then
  begin
    FWaitingBrowserDOM := True;
    FLastBrowserDOMJSON := '';
  end;

  if SameText(AActionName, 'CREATE_TEXT_DOCUMENT') then
  begin
    if IsEmptyOrPlaceholder(AParams.Values['content']) and (AExecutionContext.Values['browser.last_result_text'] <> '') then
    begin
      AParams.Values['content'] := AExecutionContext.Values['browser.last_result_text'];
      AddLog('[EXECUTOR REAL] Preenchido conteúdo do documento com o resultado capturado no browser.');
    end;

    if IsEmptyOrPlaceholder(AParams.Values['content']) and (AExecutionContext.Values['browser.last_text'] <> '') then
    begin
      AParams.Values['content'] := AExecutionContext.Values['browser.last_text'];
      AddLog('[EXECUTOR REAL] Preenchido conteúdo do documento com browser.last_text.');
    end;
  end;

  if SameText(AActionName, 'SEND_EMAIL') then
  begin
    ConfigureEmailAction;
    if Assigned(FSendEmailAction) then
      FSendEmailAction.GeneratedTextFileName := edArquivoWordGerado.Text;

    if IsEmptyOrPlaceholder(AParams.Values['body']) then
      AParams.Values['body'] := AExecutionContext.Values['last_text_content'];

    if IsEmptyOrPlaceholder(AParams.Values['body']) then
      AParams.Values['body'] := AExecutionContext.Values['browser.last_result_text'];

    if Assigned(memCorpoEmail) then
      memCorpoEmail.Text := AParams.Values['body'];
  end;
end;

procedure TfrmMain.ActionExecutorAfterPreparedAction(
  Sender: TObject;
  const AActionName: string;
  AParams: TStrings;
  AExecutionContext: TStrings;
  AResult: TStrings
);
begin
  AddLog(Format('[EXECUTOR REAL] Ação concluída com sucesso: %s', [AActionName]));

  if SameText(AActionName, 'BROWSER_NAVIGATE') then
  begin
    AddLog('[EXECUTOR REAL] Aguardando carregamento da página...');
    if not WaitBrowserNavigation(15000) then
      AddLog('[EXECUTOR REAL] Aviso: timeout aguardando navegação.');
  end
  else if SameText(AActionName, 'BROWSER_READ_PAGE') or
          SameText(AActionName, 'BROWSER_DOM_LIST') or
          SameText(AActionName, 'BROWSER_CAPTURE_TEXT') then
  begin
    AddLog('[EXECUTOR REAL] Aguardando resultado assíncrono do DOM...');
    if not WaitBrowserDOMResult(10000) then
      AddLog('[EXECUTOR REAL] Aviso: timeout aguardando resultado DOM.');

    if SameText(AActionName, 'BROWSER_CAPTURE_TEXT') or SameText(AActionName, 'BROWSER_READ_PAGE') then
    begin
      if Trim(FCapturedWebText) <> '' then
      begin
        AExecutionContext.Values['browser.last_result_text'] := FCapturedWebText;
        AExecutionContext.Values['browser.last_text'] := FCapturedWebText;
        AddLog('[EXECUTOR REAL] Registrado browser.last_result_text no ExecutionContext.');
      end;
    end;
  end
  else if SameText(AActionName, 'BROWSER_PRESS_ENTER') or
          SameText(AActionName, 'BROWSER_SUBMIT_FORM') then
  begin
    AddLog('[EXECUTOR REAL] Aguardando possível carregamento pós submissão...');
    Application.ProcessMessages;
    Sleep(2000);
    Application.ProcessMessages;
  end
  else if SameText(AActionName, 'CREATE_TEXT_DOCUMENT') then
  begin
    if Assigned(FCreateTextAction) then
    begin
      AExecutionContext.Values['last_text_content'] := FCreateTextAction.LastContent;
      AExecutionContext.Values['last_text_filename'] := FCreateTextAction.LastGeneratedFile;
      AddLog('[EXECUTOR REAL] Publicado texto gerado no contexto de execução.');
    end;
  end;
end;

function CompareTasks(Item1, Item2: Pointer): Integer;
var
  T1, T2: TSampleTaskItem;
begin
  T1 := TSampleTaskItem(Item1);
  T2 := TSampleTaskItem(Item2);
  if T1.Ordem < T2.Ordem then
    Result := -1
  else if T1.Ordem > T2.Ordem then
    Result := 1
  else
    Result := 0;
end;

procedure TfrmMain.SortTasksByOrder;
begin
  if Assigned(FTasks) then
    FTasks.Sort(@CompareTasks);
end;

function TfrmMain.CanTriggerReplan(ATask: TSampleTaskItem): Boolean;
begin
  Result := False;
  if not Assigned(ATask) then
    Exit;
  Result :=
    SameText(ATask.AcaoSugerida, 'BROWSER_DOM_LIST') or
    SameText(ATask.AcaoSugerida, 'BROWSER_READ_PAGE') or
    SameText(ATask.AcaoSugerida, 'BROWSER_CAPTURE_TEXT') or
    SameText(ATask.AcaoSugerida, 'REPLAN_FROM_DOM');
end;

function TfrmMain.HasPendingTasksAfter(ATask: TSampleTaskItem): Boolean;
var
  I: Integer;
  T: TSampleTaskItem;
begin
  Result := False;
  if (not Assigned(ATask)) or (not Assigned(FTasks)) then
    Exit;
  for I := 0 to FTasks.Count - 1 do
  begin
    T := TSampleTaskItem(FTasks[I]);
    if (T.Ordem > ATask.Ordem) and
       ((T.Status = stsPending) or (T.Status = stsFailed)) then
    begin
      Result := True;
      Exit;
    end;
  end;
end;

function TfrmMain.BuildPendingTasksJSON(const AAfterOrder: Integer): string;
var
  Arr: TJSONArray;
  Obj, ParamsObj: TJSONObject;
  I, J: Integer;
  T: TSampleTaskItem;
begin
  Arr := TJSONArray.Create;
  try
    if Assigned(FTasks) then
    begin
      for I := 0 to FTasks.Count - 1 do
      begin
        T := TSampleTaskItem(FTasks[I]);
        if (T.Ordem > AAfterOrder) and
           ((T.Status = stsPending) or (T.Status = stsFailed)) then
        begin
          Obj := TJSONObject.Create;
          Obj.Add('id', T.ID);
          Obj.Add('order', T.Ordem);
          Obj.Add('type', T.Tipo);
          Obj.Add('description', T.Descricao);
          Obj.Add('agent', T.Agente);
          Obj.Add('suggested_action', T.AcaoSugerida);
          Obj.Add('depends_on', T.Dependencia);

          ParamsObj := TJSONObject.Create;
          if Assigned(T.Params) then
          begin
            for J := 0 to T.Params.Count - 1 do
              ParamsObj.Add(T.Params.Names[J], T.Params.ValueFromIndex[J]);
          end;
          Obj.Add('parameters', ParamsObj);
          Arr.Add(Obj);
        end;
      end;
    end;
    Result := Arr.AsJSON;
  finally
    Arr.Free;
  end;
end;

function TfrmMain.BuildCompletedTasksSummary: string;
var
  I: Integer;
  T: TSampleTaskItem;
begin
  Result := '';
  if not Assigned(FTasks) then
    Exit;

  for I := 0 to FTasks.Count - 1 do
  begin
    T := TSampleTaskItem(FTasks[I]);
    if T.Status = stsDone then
    begin
      Result := Result + 'Tarefa ID: ' + T.ID + sLineBreak +
                'Ação: ' + T.AcaoSugerida + sLineBreak +
                'Descrição: ' + T.Descricao + sLineBreak +
                'Resultado: ' + T.Resultado + sLineBreak + sLineBreak;
    end;
  end;
end;

function TfrmMain.ReplanPendingTasksIfNeeded(ACurrentTask: TSampleTaskItem): Boolean;
var
  ReplanInput: string;
  ReplanOutput: string;
  DOMText: string;
begin
  Result := False;
  if not CanTriggerReplan(ACurrentTask) then
    Exit(True);

  if not HasPendingTasksAfter(ACurrentTask) then
    Exit(True);

  AddLog('[REPLAN] Iniciando análise de replanejamento com ReplannerAgent...');

  DOMText := FActionExecutor.ExecutionContext.Values['browser.last_dom_json'];
  if DOMText = '' then
    DOMText := FActionExecutor.ExecutionContext.Text;

  ReplanInput :=
    '=== OBJETIVO ORIGINAL ===' + sLineBreak +
    memPrompt.Text + sLineBreak + sLineBreak +
    '=== TAREFAS JÁ CONCLUÍDAS ===' + sLineBreak +
    BuildCompletedTasksSummary + sLineBreak +
    '=== TAREFA RECÉM EXECUTADA ===' + sLineBreak +
    'ID: ' + ACurrentTask.ID + sLineBreak +
    'Ação: ' + ACurrentTask.AcaoSugerida + sLineBreak +
    'Descrição: ' + ACurrentTask.Descricao + sLineBreak +
    'Resultado: ' + ACurrentTask.Resultado + sLineBreak + sLineBreak +
    '=== DOM/TEXTO CAPTURADO NO EXECUTION CONTEXT ===' + sLineBreak +
    LimitSampleText(DOMText, 25000) + sLineBreak + sLineBreak +
    '=== TAREFAS PENDENTES ATUAIS ===' + sLineBreak +
    BuildPendingTasksJSON(ACurrentTask.Ordem);

  ConfigureChatGPT;

  if FTaskPlannerAgent.ReplanTasks(ReplanInput, ReplanOutput) then
  begin
    AddLog('[REPLAN] ReplannerAgent respondeu com sucesso.');
    Result := ApplyReplanJSON(ReplanOutput);
  end
  else
  begin
    AddLog('[REPLAN] Falha na chamada ao ReplannerAgent: ' + FTaskPlannerAgent.LastError);
  end;
end;

function TfrmMain.ApplyReplanJSON(const AReplanJSON: string): Boolean;
var
  JSONData: TJSONData;
  Obj: TJSONObject;
  UpdatedTasks: TJSONArray;
  TasksToCancel: TJSONArray;
  I, J, K: Integer;
  TItemData: TJSONData;
  TObj: TJSONObject;
  CancelId: string;
  FoundTask: TSampleTaskItem;
  T: TSampleTaskItem;
  NewId: string;
  ParamsData: TJSONData;
  ParamsObj: TJSONObject;
begin
  Result := False;
  try
    JSONData := GetJSON(AReplanJSON);
    try
      if not (JSONData is TJSONObject) then
        Exit;

      Obj := TJSONObject(JSONData);
      if not Obj.Get('needs_replan', False) then
      begin
        AddLog('[REPLAN] IA decidiu manter tarefas futuras sem alteração.');
        Exit(True);
      end;

      AddLog('[REPLAN] IA identificou necessidade de replanejamento. Razão: ' + Obj.Get('reason', ''));

      // Cancelar tarefas indicadas
      TasksToCancel := TJSONArray(Obj.Find('tasks_to_cancel'));
      if Assigned(TasksToCancel) then
      begin
        for I := 0 to TasksToCancel.Count - 1 do
        begin
          CancelId := TasksToCancel.Items[I].AsString;
          if CancelId <> '' then
          begin
            for J := 0 to FTasks.Count - 1 do
            begin
              T := TSampleTaskItem(FTasks[J]);
              if SameText(T.ID, CancelId) then
              begin
                T.Status := stsCanceled;
                AddLog('[REPLAN] Tarefa cancelada pela IA: ' + CancelId);
              end;
            end;
          end;
        end;
      end;

      // Atualizar ou inserir tarefas
      UpdatedTasks := TJSONArray(Obj.Find('updated_tasks'));
      if Assigned(UpdatedTasks) then
      begin
        for I := 0 to UpdatedTasks.Count - 1 do
        begin
          TItemData := UpdatedTasks.Items[I];
          if TItemData is TJSONObject then
          begin
            TObj := TJSONObject(TItemData);
            NewId := TObj.Get('id', '');
            if NewId = '' then
              Continue;

            FoundTask := nil;
            for J := 0 to FTasks.Count - 1 do
            begin
              T := TSampleTaskItem(FTasks[J]);
              if SameText(T.ID, NewId) then
              begin
                FoundTask := T;
                Break;
              end;
            end;

            if not Assigned(FoundTask) then
            begin
              // Inserir nova tarefa
              FoundTask := TSampleTaskItem.Create;
              FoundTask.ID := NewId;
              FoundTask.Status := stsPending;
              FTasks.Add(FoundTask);
              AddLog('[REPLAN] Nova tarefa inserida no plano: ' + NewId + ' (' + TObj.Get('description', '') + ')');
            end
            else
            begin
              AddLog('[REPLAN] Atualizando tarefa existente no plano: ' + NewId);
            end;

            FoundTask.Ordem := TObj.Get('order', FoundTask.Ordem);
            FoundTask.Tipo := TObj.Get('type', FoundTask.Tipo);
            FoundTask.Descricao := TObj.Get('description', FoundTask.Descricao);
            FoundTask.Agente := TObj.Get('agent', FoundTask.Agente);
            FoundTask.AcaoSugerida := TObj.Get('suggested_action', FoundTask.AcaoSugerida);
            FoundTask.Dependencia := TObj.Get('depends_on', FoundTask.Dependencia);

            // Atualiza parâmetros
            if not Assigned(FoundTask.Params) then
              FoundTask.Params := TStringList.Create;
            FoundTask.Params.Clear;

            ParamsData := TObj.Find('parameters');
            if Assigned(ParamsData) and (ParamsData is TJSONObject) then
            begin
              ParamsObj := TJSONObject(ParamsData);
              for K := 0 to ParamsObj.Count - 1 do
              begin
                FoundTask.Params.Values[ParamsObj.Names[K]] := ParamsObj.Items[K].AsString;
              end;
            end;

            // Restaura status para pendente caso estivesse com erro
            if FoundTask.Status = stsFailed then
              FoundTask.Status := stsPending;

            FoundTask.RawJSON := TObj.AsJSON;
          end;
        end;
      end;

      SortTasksByOrder;
      Result := True;
    finally
      JSONData.Free;
    end;
  except
    on E: Exception do
      AddLog('[REPLAN] Erro ao aplicar JSON de replanejamento: ' + E.Message);
  end;
end;

end.

