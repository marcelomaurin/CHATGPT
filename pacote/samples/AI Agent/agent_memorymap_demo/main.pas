unit main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, StdCtrls,
  ComCtrls, chatgpt, aiagent_flowevents, aiagent_memorymap, aiagent_core,
  aiagent_classifier, aiagent_decision, aiagent_actionbuilder, aiagent_executor,
  aiagent_orchestrator;

type

  { TfrmAgentMemoryMapDemo }

  TfrmAgentMemoryMapDemo = class(TForm)
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
  private
    { Config Controls }
    pnlHeader: TPanel;
    lblProvider: TLabel;
    cbProvider: TComboBox;
    lblModel: TLabel;
    edtModel: TEdit;
    lblToken: TLabel;
    edtToken: TEdit;
    lblBaseURL: TLabel;
    edtBaseURL: TEdit;

    { Main Panels }
    pnlClient: TPanel;
    pnlLeft: TPanel;
    splitterLeft: TSplitter;
    pnlCenter: TPanel;
    splitterCenter: TSplitter;
    pnlRight: TPanel;

    { Left Controls }
    gbInput: TGroupBox;
    memInput: TMemo;
    btnRun: TButton;

    { Center Controls }
    gbClassifier: TGroupBox;
    memClassifier: TMemo;
    gbDecision: TGroupBox;
    memDecision: TMemo;
    gbExecutor: TGroupBox;
    memExecutor: TMemo;

    { Right Controls }
    gbMemoryMap: TGroupBox;
    memMemoryMap: TMemo;
    gbInfoLoss: TGroupBox;
    memInfoLoss: TMemo;
    gbErrors: TGroupBox;
    memErrors: TMemo;

    { Components }
    FChatGPT: TCHATGPT;
    FMapaDeMemoria: TAIMapaDeMemoria;
    FClassifier: TAIClassifierAgent;
    FDecisionAgent: TAIDecisionAgent;
    FActionBuilder: TAIActionBuilderAgent;
    FExecutor: TAIActionExecutor;
    FOrchestrator: TAIAgentOrchestrator;

    procedure CreateLayout;
    procedure SetupScenario;
    procedure btnRunClick(Sender: TObject);
    procedure cbProviderChange(Sender: TObject);
    function ConfigureChatGPT: Boolean;

    { Orchestrator stage events }
    procedure OnBeforeFlowStart(Sender: TObject; AContexto: TAIFluxoEtapaContexto; var ACanContinue: Boolean);
    procedure OnAfterFlowStart(Sender: TObject; AContexto: TAIFluxoEtapaContexto);
    procedure OnBeforeClassifier(Sender: TObject; AContexto: TAIFluxoEtapaContexto; var ACanContinue: Boolean);
    procedure OnAfterClassifier(Sender: TObject; AContexto: TAIFluxoEtapaContexto);
    procedure OnBeforeDecisionAgent(Sender: TObject; AContexto: TAIFluxoEtapaContexto; var ACanContinue: Boolean);
    procedure OnAfterDecisionAgent(Sender: TObject; AContexto: TAIFluxoEtapaContexto);
    procedure OnBeforeActionBuilder(Sender: TObject; AContexto: TAIFluxoEtapaContexto; var ACanContinue: Boolean);
    procedure OnAfterActionBuilder(Sender: TObject; AContexto: TAIFluxoEtapaContexto);
    procedure OnBeforeExecutor(Sender: TObject; AContexto: TAIFluxoEtapaContexto; var ACanContinue: Boolean);
    procedure OnAfterExecutor(Sender: TObject; AContexto: TAIFluxoEtapaContexto);
    procedure OnFlowFinished(Sender: TObject; AContexto: TAIFluxoEtapaContexto);
    procedure OnFlowError(Sender: TObject; AContexto: TAIFluxoEtapaContexto);
    procedure OnFlowStage(Sender: TObject; AContexto: TAIFluxoEtapaContexto);
    procedure OnInformationLossDetected(Sender: TObject; AContexto: TAIFluxoEtapaContexto);
  public

  end;

var
  frmAgentMemoryMapDemo: TfrmAgentMemoryMapDemo;

implementation

{$R *.lfm}

{ TfrmAgentMemoryMapDemo }

procedure TfrmAgentMemoryMapDemo.FormCreate(Sender: TObject);
begin
  Position := poScreenCenter;
  Caption := 'IA Multi-Agent & Memory Map Demo';

  { Instantiate components }
  FChatGPT := TCHATGPT.Create(Self);
  FMapaDeMemoria := TAIMapaDeMemoria.Create(Self);
  FClassifier := TAIClassifierAgent.Create(Self);
  FDecisionAgent := TAIDecisionAgent.Create(Self);
  FActionBuilder := TAIActionBuilderAgent.Create(Self);
  FExecutor := TAIActionExecutor.Create(Self);
  FOrchestrator := TAIAgentOrchestrator.Create(Self);

  { Wire components together }
  FOrchestrator.ChatGPT := FChatGPT;
  FOrchestrator.MapaDeMemoria := FMapaDeMemoria;
  FOrchestrator.Classifier := FClassifier;
  FOrchestrator.DecisionAgent := FDecisionAgent;
  FOrchestrator.ActionBuilder := FActionBuilder;
  FOrchestrator.Executor := FExecutor;

  FClassifier.ChatGPT := FChatGPT;
  FDecisionAgent.ChatGPT := FChatGPT;
  FActionBuilder.ChatGPT := FChatGPT;
  FExecutor.ChatGPT := FChatGPT;

  { Orchestrator events }
  FOrchestrator.OnBeforeFlowStart := @OnBeforeFlowStart;
  FOrchestrator.OnAfterFlowStart := @OnAfterFlowStart;
  FOrchestrator.OnBeforeClassifier := @OnBeforeClassifier;
  FOrchestrator.OnAfterClassifier := @OnAfterClassifier;
  FOrchestrator.OnBeforeDecisionAgent := @OnBeforeDecisionAgent;
  FOrchestrator.OnAfterDecisionAgent := @OnAfterDecisionAgent;
  FOrchestrator.OnBeforeActionBuilder := @OnBeforeActionBuilder;
  FOrchestrator.OnAfterActionBuilder := @OnAfterActionBuilder;
  FOrchestrator.OnBeforeExecutor := @OnBeforeExecutor;
  FOrchestrator.OnAfterExecutor := @OnAfterExecutor;
  FOrchestrator.OnFlowFinished := @OnFlowFinished;
  FOrchestrator.OnFlowError := @OnFlowError;
  FOrchestrator.OnFlowStage := @OnFlowStage;
  FOrchestrator.OnInformationLossDetected := @OnInformationLossDetected;

  CreateLayout;
  SetupScenario;
end;

procedure TfrmAgentMemoryMapDemo.FormDestroy(Sender: TObject);
begin
  { Sub-components are owned by form, freed automatically }
end;

procedure TfrmAgentMemoryMapDemo.CreateLayout;
var
  pnlSep: TPanel;
begin
  { Header Panel }
  pnlHeader := TPanel.Create(Self);
  pnlHeader.Parent := Self;
  pnlHeader.Align := alTop;
  pnlHeader.Height := 50;
  pnlHeader.BevelOuter := bvNone;
  pnlHeader.BorderWidth := 5;

  lblProvider := TLabel.Create(Self);
  lblProvider.Parent := pnlHeader;
  lblProvider.Align := alLeft;
  lblProvider.Caption := ' Provedor: ';
  lblProvider.Layout := tlCenter;

  cbProvider := TComboBox.Create(Self);
  cbProvider.Parent := pnlHeader;
  cbProvider.Align := alLeft;
  cbProvider.Width := 100;
  cbProvider.Items.Add('OpenAI');
  cbProvider.Items.Add('Local (Ollama/LMStudio)');
  cbProvider.Style := csDropDownList;
  cbProvider.OnChange := @cbProviderChange;

  lblModel := TLabel.Create(Self);
  lblModel.Parent := pnlHeader;
  lblModel.Align := alLeft;
  lblModel.Caption := ' Modelo: ';
  lblModel.Layout := tlCenter;

  edtModel := TEdit.Create(Self);
  edtModel.Parent := pnlHeader;
  edtModel.Align := alLeft;
  edtModel.Width := 120;
  edtModel.Text := 'gpt-4o-mini';

  lblToken := TLabel.Create(Self);
  lblToken.Parent := pnlHeader;
  lblToken.Align := alLeft;
  lblToken.Caption := ' API Token: ';
  lblToken.Layout := tlCenter;

  edtToken := TEdit.Create(Self);
  edtToken.Parent := pnlHeader;
  edtToken.Align := alLeft;
  edtToken.Width := 150;
  edtToken.PasswordChar := '*';

  lblBaseURL := TLabel.Create(Self);
  lblBaseURL.Parent := pnlHeader;
  lblBaseURL.Align := alLeft;
  lblBaseURL.Caption := ' Base URL: ';
  lblBaseURL.Layout := tlCenter;

  edtBaseURL := TEdit.Create(Self);
  edtBaseURL.Parent := pnlHeader;
  edtBaseURL.Align := alLeft;
  edtBaseURL.Width := 180;
  edtBaseURL.Text := 'https://api.openai.com/v1';

  { Client panel }
  pnlClient := TPanel.Create(Self);
  pnlClient.Parent := Self;
  pnlClient.Align := alClient;
  pnlClient.BevelOuter := bvNone;

  { Left panel }
  pnlLeft := TPanel.Create(Self);
  pnlLeft.Parent := pnlClient;
  pnlLeft.Align := alLeft;
  pnlLeft.Width := 300;
  pnlLeft.BevelOuter := bvNone;

  splitterLeft := TSplitter.Create(Self);
  splitterLeft.Parent := pnlClient;
  splitterLeft.Align := alLeft;

  { Right panel }
  pnlRight := TPanel.Create(Self);
  pnlRight.Parent := pnlClient;
  pnlRight.Align := alRight;
  pnlRight.Width := 350;
  pnlRight.BevelOuter := bvNone;

  splitterCenter := TSplitter.Create(Self);
  splitterCenter.Parent := pnlClient;
  splitterCenter.Align := alRight;

  { Center panel }
  pnlCenter := TPanel.Create(Self);
  pnlCenter.Parent := pnlClient;
  pnlCenter.Align := alClient;
  pnlCenter.BevelOuter := bvNone;

  { Left Controls: Input }
  gbInput := TGroupBox.Create(Self);
  gbInput.Parent := pnlLeft;
  gbInput.Align := alClient;
  gbInput.Caption := 'Entrada Original do Usuário';

  memInput := TMemo.Create(Self);
  memInput.Parent := gbInput;
  memInput.Align := alClient;
  memInput.ScrollBars := ssAutoVertical;

  pnlSep := TPanel.Create(Self);
  pnlSep.Parent := pnlLeft;
  pnlSep.Align := alBottom;
  pnlSep.Height := 45;
  pnlSep.BevelOuter := bvNone;

  btnRun := TButton.Create(Self);
  btnRun.Parent := pnlSep;
  btnRun.Align := alClient;
  btnRun.Caption := 'Executar Fluxo Multiagente';
  btnRun.OnClick := @btnRunClick;

  { Center Controls: Agents logs }
  gbClassifier := TGroupBox.Create(Self);
  gbClassifier.Parent := pnlCenter;
  gbClassifier.Align := alTop;
  gbClassifier.Height := 200;
  gbClassifier.Caption := 'Etapa 1: Classificador (Resultado)';

  memClassifier := TMemo.Create(Self);
  memClassifier.Parent := gbClassifier;
  memClassifier.Align := alClient;
  memClassifier.ReadOnly := True;
  memClassifier.ScrollBars := ssAutoVertical;

  gbDecision := TGroupBox.Create(Self);
  gbDecision.Parent := pnlCenter;
  gbDecision.Align := alTop;
  gbDecision.Height := 200;
  gbDecision.Caption := 'Etapa 2: Decisor & Ajustador (Resultado)';

  memDecision := TMemo.Create(Self);
  memDecision.Parent := gbDecision;
  memDecision.Align := alClient;
  memDecision.ReadOnly := True;
  memDecision.ScrollBars := ssAutoVertical;

  gbExecutor := TGroupBox.Create(Self);
  gbExecutor.Parent := pnlCenter;
  gbExecutor.Align := alClient;
  gbExecutor.Caption := 'Etapa 3: Executor de Ações';

  memExecutor := TMemo.Create(Self);
  memExecutor.Parent := gbExecutor;
  memExecutor.Align := alClient;
  memExecutor.ReadOnly := True;
  memExecutor.ScrollBars := ssAutoVertical;

  { Right Controls: Memory Map, Info Loss & Errors }
  gbMemoryMap := TGroupBox.Create(Self);
  gbMemoryMap.Parent := pnlRight;
  gbMemoryMap.Align := alTop;
  gbMemoryMap.Height := 350;
  gbMemoryMap.Caption := 'Histórico e Mapa de Memória';

  memMemoryMap := TMemo.Create(Self);
  memMemoryMap.Parent := gbMemoryMap;
  memMemoryMap.Align := alClient;
  memMemoryMap.ReadOnly := True;
  memMemoryMap.ScrollBars := ssAutoVertical;

  gbInfoLoss := TGroupBox.Create(Self);
  gbInfoLoss.Parent := pnlRight;
  gbInfoLoss.Align := alTop;
  gbInfoLoss.Height := 150;
  gbInfoLoss.Caption := 'Alertas de Perda de Informações';

  memInfoLoss := TMemo.Create(Self);
  memInfoLoss.Parent := gbInfoLoss;
  memInfoLoss.Align := alClient;
  memInfoLoss.ReadOnly := True;
  memInfoLoss.ScrollBars := ssAutoVertical;

  gbErrors := TGroupBox.Create(Self);
  gbErrors.Parent := pnlRight;
  gbErrors.Align := alClient;
  gbErrors.Caption := 'Erros do Fluxo';

  memErrors := TMemo.Create(Self);
  memErrors.Parent := gbErrors;
  memErrors.Align := alClient;
  memErrors.ReadOnly := True;
  memErrors.ScrollBars := ssAutoVertical;
end;

procedure TfrmAgentMemoryMapDemo.SetupScenario;
begin
  memInput.Text := 'O computador da recepção não liga e a unidade precisa de atendimento urgente.';
  cbProvider.ItemIndex := 0;
  cbProviderChange(nil);
end;

procedure TfrmAgentMemoryMapDemo.cbProviderChange(Sender: TObject);
begin
  if cbProvider.ItemIndex = 0 then
  begin
    edtBaseURL.Text := 'https://api.openai.com/v1';
    edtModel.Text := 'gpt-4o-mini';
  end
  else
  begin
    edtBaseURL.Text := 'http://localhost:11434/v1';
    edtModel.Text := 'llama3';
  end;
end;

function TfrmAgentMemoryMapDemo.ConfigureChatGPT: Boolean;
begin
  Result := False;
  FChatGPT.TOKEN := edtToken.Text;
  FChatGPT.URL := edtBaseURL.Text;
  FChatGPT.CustomModel := edtModel.Text;
  Result := True;
end;

procedure TfrmAgentMemoryMapDemo.btnRunClick(Sender: TObject);
begin
  memClassifier.Clear;
  memDecision.Clear;
  memExecutor.Clear;
  memMemoryMap.Clear;
  memInfoLoss.Clear;
  memErrors.Clear;

  if not ConfigureChatGPT then Exit;

  btnRun.Enabled := False;
  try
    FOrchestrator.Run(memInput.Text);
  finally
    btnRun.Enabled := True;
  end;
end;

{ Event triggers }

procedure TfrmAgentMemoryMapDemo.OnBeforeFlowStart(Sender: TObject; AContexto: TAIFluxoEtapaContexto; var ACanContinue: Boolean);
begin
  memErrors.Lines.Add('Fluxo iniciando...');
end;

procedure TfrmAgentMemoryMapDemo.OnAfterFlowStart(Sender: TObject; AContexto: TAIFluxoEtapaContexto);
begin
  memErrors.Lines.Add('Fluxo iniciado.');
end;

procedure TfrmAgentMemoryMapDemo.OnBeforeClassifier(Sender: TObject; AContexto: TAIFluxoEtapaContexto; var ACanContinue: Boolean);
begin
  memClassifier.Lines.Add('Iniciando Classificação...');
end;

procedure TfrmAgentMemoryMapDemo.OnAfterClassifier(Sender: TObject; AContexto: TAIFluxoEtapaContexto);
begin
  memClassifier.Lines.Add('Classificação concluída.');
  memClassifier.Lines.Add(AContexto.SaidaAtual);
end;

procedure TfrmAgentMemoryMapDemo.OnBeforeDecisionAgent(Sender: TObject; AContexto: TAIFluxoEtapaContexto; var ACanContinue: Boolean);
begin
  memDecision.Lines.Add('Iniciando Decisor...');
end;

procedure TfrmAgentMemoryMapDemo.OnAfterDecisionAgent(Sender: TObject; AContexto: TAIFluxoEtapaContexto);
begin
  memDecision.Lines.Add('Decisão concluída.');
  memDecision.Lines.Add(AContexto.SaidaAtual);
end;

procedure TfrmAgentMemoryMapDemo.OnBeforeActionBuilder(Sender: TObject; AContexto: TAIFluxoEtapaContexto; var ACanContinue: Boolean);
begin
  memDecision.Lines.Add('Ajustando Plano de Ação...');
end;

procedure TfrmAgentMemoryMapDemo.OnAfterActionBuilder(Sender: TObject; AContexto: TAIFluxoEtapaContexto);
begin
  memDecision.Lines.Add('Parâmetros de ações ajustados.');
  memDecision.Lines.Add(AContexto.SaidaAtual);
end;

procedure TfrmAgentMemoryMapDemo.OnBeforeExecutor(Sender: TObject; AContexto: TAIFluxoEtapaContexto; var ACanContinue: Boolean);
begin
  memExecutor.Lines.Add('Iniciando Execução do Plano...');
end;

procedure TfrmAgentMemoryMapDemo.OnAfterExecutor(Sender: TObject; AContexto: TAIFluxoEtapaContexto);
begin
  memExecutor.Lines.Add('Execução concluída.');
  memExecutor.Lines.Add(AContexto.SaidaAtual);
end;

procedure TfrmAgentMemoryMapDemo.OnFlowFinished(Sender: TObject; AContexto: TAIFluxoEtapaContexto);
begin
  memErrors.Lines.Add('Fluxo encerrado com sucesso.');
  if Assigned(FMapaDeMemoria) then
    memMemoryMap.Text := FMapaDeMemoria.AsText;
end;

procedure TfrmAgentMemoryMapDemo.OnFlowError(Sender: TObject; AContexto: TAIFluxoEtapaContexto);
begin
  memErrors.Lines.Add('ERRO no fluxo: ' + AContexto.MensagemErro);
  if Assigned(FMapaDeMemoria) then
    memMemoryMap.Text := FMapaDeMemoria.AsText;
end;

procedure TfrmAgentMemoryMapDemo.OnFlowStage(Sender: TObject; AContexto: TAIFluxoEtapaContexto);
begin
  { Real-time debug log }
end;

procedure TfrmAgentMemoryMapDemo.OnInformationLossDetected(Sender: TObject; AContexto: TAIFluxoEtapaContexto);
begin
  memInfoLoss.Lines.Add('ATENÇÃO: Perda de informação identificada!');
  memInfoLoss.Lines.Add(AContexto.AsText);
end;

end.
