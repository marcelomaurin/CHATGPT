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
    pnlHeader: TPanel;
    lblProvider: TLabel;
    cbProvider: TComboBox;
    lblModel: TLabel;
    edtModel: TEdit;
    lblToken: TLabel;
    edtToken: TEdit;
    lblBaseURL: TLabel;
    edtBaseURL: TEdit;
    pnlClient: TPanel;
    pnlLeft: TPanel;
    splitterLeft: TSplitter;
    pnlCenter: TPanel;
    splitterCenter: TSplitter;
    pnlRight: TPanel;
    gbInput: TGroupBox;
    memInput: TMemo;
    btnRun: TButton;
    gbClassifier: TGroupBox;
    memClassifier: TMemo;
    gbDecision: TGroupBox;
    memDecision: TMemo;
    gbExecutor: TGroupBox;
    memExecutor: TMemo;
    gbMemoryMap: TGroupBox;
    memMemoryMap: TMemo;
    gbInfoLoss: TGroupBox;
    memInfoLoss: TMemo;
    gbErrors: TGroupBox;
    memErrors: TMemo;
    FChatGPT: TCHATGPT;
    FClassifier: TAIClassifierAgent;
    FDecisionAgent: TAIDecisionAgent;
    FActionBuilder: TAIActionBuilderAgent;
    FExecutor: TAIActionExecutor;
    FOrchestrator: TAIAgentOrchestrator;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btnRunClick(Sender: TObject);
    procedure cbProviderChange(Sender: TObject);
  private
    procedure SetupScenario;
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

  { Wire components together }
  FOrchestrator.ChatGPT := FChatGPT;
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

  SetupScenario;
end;

procedure TfrmAgentMemoryMapDemo.FormDestroy(Sender: TObject);
begin
  { Sub-components are owned by form, freed automatically }
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
  if Assigned(FOrchestrator.MemoryMap) then
    memMemoryMap.Text := FOrchestrator.MemoryMap.AsText;
end;

procedure TfrmAgentMemoryMapDemo.OnFlowError(Sender: TObject; AContexto: TAIFluxoEtapaContexto);
begin
  memErrors.Lines.Add('ERRO no fluxo: ' + AContexto.MensagemErro);
  if Assigned(FOrchestrator.MemoryMap) then
    memMemoryMap.Text := FOrchestrator.MemoryMap.AsText;
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
