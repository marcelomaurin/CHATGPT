unit main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, StdCtrls,
  ComCtrls, Grids, fpjson, jsonparser, chatgpt, aiagent_flowevents, 
  aiagent_memorymap, aiagent_core, aiagent_classifier, aiagent_decision, 
  aiagent_actionbuilder, aiagent_executor, aiagent_orchestrator;

type

  { TfrmAgentMemoryMapDemo }

  TfrmAgentMemoryMapDemo = class(TForm)
    PageControl1: TPageControl;
    tsSetup: TTabSheet;
    gbAIConfig: TGroupBox;
    lblProvider: TLabel;
    cbProvider: TComboBox;
    lblModel: TLabel;
    edtModel: TEdit;
    lblToken: TLabel;
    edtToken: TEdit;
    lblBaseURL: TLabel;
    edtBaseURL: TEdit;
    gbScriptConfig: TGroupBox;
    lblScriptPath: TLabel;
    edtScriptPath: TEdit;
    btnLoadScript: TButton;
    btnSaveScript: TButton;
    btnNewScript: TButton;
    pnlSetupRun: TPanel;
    btnStartSim: TButton;
    btnStopSim: TButton;
    tsPlans: TTabSheet;
    sgPlans: TStringGrid;
    pnlEditPlan: TPanel;
    lblPlanID: TLabel;
    edtPlanID: TEdit;
    lblPlanName: TLabel;
    edtPlanName: TEdit;
    lblPlanDesc: TLabel;
    memPlanDesc: TMemo;
    btnAddPlan: TButton;
    btnSavePlan: TButton;
    btnDeletePlan: TButton;
    tsDialogues: TTabSheet;
    sgDialogues: TStringGrid;
    pnlEditDialogue: TPanel;
    lblExpectedPlan: TLabel;
    cbExpectedPlan: TComboBox;
    lblTurns: TLabel;
    memTurns: TMemo;
    btnAddDialogue: TButton;
    btnSaveDialogue: TButton;
    btnDeleteDialogue: TButton;
    tsConversas: TTabSheet;
    pnlConvLeft: TPanel;
    lblConvHistory: TLabel;
    memConvHistory: TMemo;
    splConv: TSplitter;
    pnlConvRight: TPanel;
    lblConvMemoryMap: TLabel;
    memConvMemoryMap: TMemo;
    tsExecution: TTabSheet;
    memLogs: TMemo;
    pnlExecutionBottom: TPanel;
    btnStopSimExecution: TButton;
    pbProgress: TProgressBar;
    tsStats: TTabSheet;
    memStats: TMemo;
    sgStatsPlans: TStringGrid;
    chkClassifierOnly: TCheckBox;
    FChatGPT: TCHATGPT;
    FClassifier: TAIClassifierAgent;
    FDecisionAgent: TAIDecisionAgent;
    FActionBuilder: TAIActionBuilderAgent;
    FExecutor: TAIActionExecutor;
    FOrchestrator: TAIAgentOrchestrator;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure cbProviderChange(Sender: TObject);
    procedure btnLoadScriptClick(Sender: TObject);
    procedure btnSaveScriptClick(Sender: TObject);
    procedure btnNewScriptClick(Sender: TObject);
    procedure btnStartSimClick(Sender: TObject);
    procedure btnStopSimClick(Sender: TObject);
    procedure sgPlansSelectionChanged(Sender: TObject; aCol, aRow: Integer);
    procedure sgPlansDblClick(Sender: TObject);
    procedure sgDialoguesSelectionChanged(Sender: TObject; aCol, aRow: Integer);
    procedure btnAddPlanClick(Sender: TObject);
    procedure btnSavePlanClick(Sender: TObject);
    procedure btnDeletePlanClick(Sender: TObject);
    procedure btnAddDialogueClick(Sender: TObject);
    procedure btnSaveDialogueClick(Sender: TObject);
    procedure btnDeleteDialogueClick(Sender: TObject);
  private
    FScriptData: TJSONObject;
    FStopSimulation: Boolean;
    FLastClassification: string;
    
    { Stats counters }
    FStatsTotal: Integer;
    FStatsCorrect: Integer;
    FStatsPlansTotal: TJSONObject;
    FStatsPlansCorrect: TJSONObject;

    function GetDefaultScriptPath: string;
    function CleanJSONResponse(const AResponse: string): string;
    function IsKnownActionPlan(const APlanID: string): Boolean;
    function ValidateClassificationOutput(const AOutput: string; out AClassification: string; out AError: string): Boolean;
    function ExecuteClassifierOnly(const AText: string; out AClassification: string): Boolean;
    procedure SetupScenario;
    function ConfigureChatGPT: Boolean;
    procedure LoadScriptFromFile(const APath: string);
    procedure RefreshPlansGrid;
    procedure RefreshDialoguesGrid;
    procedure RefreshPlansComboBox;
    procedure UpdateSystemPrompts;
    procedure ResetStats;
    procedure UpdateStatsUI;

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
  Caption := 'IA Multi-Agent & Memory Map Simulation';

  { Wire components together }
  FOrchestrator.ChatGPT := FChatGPT;
  FOrchestrator.Classifier := FClassifier;
  FOrchestrator.DecisionAgent := FDecisionAgent;
  FOrchestrator.ActionBuilder := FActionBuilder;
  FOrchestrator.Executor := FExecutor;

  FClassifier.ChatGPT := FChatGPT;
  FClassifier.OutputMode := comCompactRouting;
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

  FScriptData := nil;
  FStatsPlansTotal := TJSONObject.Create;
  FStatsPlansCorrect := TJSONObject.Create;

  SetupScenario;
end;

procedure TfrmAgentMemoryMapDemo.FormDestroy(Sender: TObject);
begin
  if Assigned(FScriptData) then FScriptData.Free;
  FStatsPlansTotal.Free;
  FStatsPlansCorrect.Free;
end;

function TfrmAgentMemoryMapDemo.GetDefaultScriptPath: string;
begin
  Result := IncludeTrailingPathDelimiter(
    ExtractFilePath(Application.ExeName)
  ) + 'maintenance_script.json';
  
  if not FileExists(Result) then
  begin
    if FileExists('maintenance_script.json') then
      Result := ExpandFileName('maintenance_script.json');
  end;
end;

function TfrmAgentMemoryMapDemo.CleanJSONResponse(const AResponse: string): string;
var
  LStart, LEnd: Integer;
begin
  Result := Trim(AResponse);
  if Result = '' then Exit;
  
  LStart := Pos('```json', Result);
  if LStart > 0 then
  begin
    Delete(Result, 1, LStart + 6);
    LEnd := Pos('```', Result);
    if LEnd > 0 then
      Result := Copy(Result, 1, LEnd - 1);
  end
  else
  begin
    LStart := Pos('```', Result);
    if LStart > 0 then
    begin
      Delete(Result, 1, LStart + 2);
      LEnd := Pos('```', Result);
      if LEnd > 0 then
        Result := Copy(Result, 1, LEnd - 1);
    end;
  end;
  Result := Trim(Result);
end;

function TfrmAgentMemoryMapDemo.ValidateClassificationOutput(
  const AOutput: string;
  out AClassification: string;
  out AError: string
): Boolean;
var
  LText: string;
  LData: TJSONData;
  LObject: TJSONObject;
  LTargetData: TJSONData;
  LArray: TJSONArray;
  LTargetVal: string;
begin
  Result := False;
  AClassification := '';
  AError := '';
  LData := nil;

  LText := Trim(CleanJSONResponse(AOutput));

  if LText = '' then
  begin
    AError := 'A resposta do classificador está vazia.';
    Exit;
  end;

  try
    try
      LData := GetJSON(LText);
    except
      on E: Exception do
      begin
        AError := 'JSON inválido: ' + E.Message;
        Exit;
      end;
    end;

    if not (LData is TJSONObject) then
    begin
      AError := 'A raiz da resposta deve ser um objeto JSON.';
      Exit;
    end;

    LObject := TJSONObject(LData);
    LTargetData := LObject.Find('target_agents');

    if not Assigned(LTargetData) then
    begin
      AError := 'A propriedade "target_agents" não foi encontrada.';
      Exit;
    end;

    if not (LTargetData is TJSONArray) then
    begin
      AError := 'A propriedade "target_agents" deve conter um array.';
      Exit;
    end;

    LArray := TJSONArray(LTargetData);

    if LArray.Count <> 1 then
    begin
      AError := 'O array "target_agents" deve conter exatamente um item.';
      Exit;
    end;

    if LArray.Items[0].JSONType <> jtString then
    begin
      AError := 'O item de target_agents deve ser uma string.';
      Exit;
    end;

    LTargetVal := Trim(LArray.Items[0].AsString);
    if LTargetVal = '' then
    begin
      AError := 'O identificador da classificação está vazio.';
      Exit;
    end;

    if not IsKnownActionPlan(LTargetVal) then
    begin
      AError := 'Erro de contrato: o modelo retornou um plano inexistente: "' + LTargetVal + '".';
      Exit;
    end;

    AClassification := LTargetVal;
    Result := True;
  finally
    if Assigned(LData) then
      LData.Free;
  end;
end;

function TfrmAgentMemoryMapDemo.IsKnownActionPlan(
  const APlanID: string
): Boolean;
var
  LData: TJSONData;
  LPlans: TJSONArray;
  LPlan: TJSONObject;
  I: Integer;
begin
  Result := False;

  if SameText(Trim(APlanID), 'nenhuma') then
    Exit(True);

  if not Assigned(FScriptData) then
    Exit;

  LData := FScriptData.Find('action_plans');

  if not (LData is TJSONArray) then
    Exit;

  LPlans := TJSONArray(LData);

  for I := 0 to LPlans.Count - 1 do
  begin
    if not (LPlans.Items[I] is TJSONObject) then
      Continue;

    LPlan := TJSONObject(LPlans.Items[I]);

    if SameText(
      Trim(LPlan.Get('id', '')),
      Trim(APlanID)
    ) then
      Exit(True);
  end;
end;

function TfrmAgentMemoryMapDemo.ExecuteClassifierOnly(const AText: string; out AClassification: string): Boolean;
var
  LOutput: string;
  LErr: string;
  LItem: TAIAgentMemoryMapItem;
begin
  Result := False;
  AClassification := '';
  
  if Assigned(FOrchestrator.MemoryMap) then
  begin
    LItem := FOrchestrator.MemoryMap.BeginAgentStep(
      'Classifier',
      tamClassificador,
      AText,
      '',
      0
    );
  end
  else
    LItem := nil;
  
  try
    if FClassifier.Classify(AText, LOutput) then
    begin
      if Assigned(LItem) then
        FOrchestrator.MemoryMap.EndAgentStep(LItem, 'Classificação concluída', '', 'SUCCESS', LOutput);
        
      if ValidateClassificationOutput(LOutput, AClassification, LErr) then
      begin
        FLastClassification := AClassification;
        Result := True;
      end
      else
      begin
        if Pos('Erro de contrato', LErr) > 0 then
          FLastClassification := '__CONTRACT_ERROR__'
        else
          FLastClassification := '__JSON_ERROR__';
        memLogs.Lines.Add(LErr);
        memLogs.Lines.Add('Resposta recebida: ' + LOutput);
      end;
    end
    else
    begin
      if Assigned(LItem) then
        FOrchestrator.MemoryMap.EndAgentStep(LItem, 'Falha na classificação', FClassifier.LastError, 'ERROR', '');
      memLogs.Lines.Add('Falha ao executar a classificação.');
    end;
  except
    on E: Exception do
    begin
      if Assigned(LItem) then
        FOrchestrator.MemoryMap.EndAgentStep(LItem, 'Erro de execução', E.Message, 'ERROR', '');
      memLogs.Lines.Add('Erro de execução do classificador: ' + E.Message);
    end;
  end;
end;

procedure TfrmAgentMemoryMapDemo.SetupScenario;
begin
  cbProvider.ItemIndex := 3; { Local (Ollama/LMStudio) }
  cbProviderChange(nil);
  
  edtScriptPath.Text := GetDefaultScriptPath;
  
  if FileExists(edtScriptPath.Text) then
    LoadScriptFromFile(edtScriptPath.Text)
  else
    btnNewScriptClick(nil);
end;

procedure TfrmAgentMemoryMapDemo.cbProviderChange(Sender: TObject);
begin
  case cbProvider.ItemIndex of
    0: begin // OpenAI
         edtBaseURL.Text := 'https://api.openai.com/v1';
         edtModel.Text := 'gpt-4o-mini';
       end;
    1: begin // OpenRouter
         edtBaseURL.Text := 'https://openrouter.ai/api/v1';
         edtModel.Text := 'google/gemma-2-9b-it:free';
       end;
    2: begin // Cerebras
         edtBaseURL.Text := 'https://api.cerebras.ai/v1';
         edtModel.Text := 'qwen-3-235b-a22b-instruct-2507';
       end;
    3: begin // Local
         edtBaseURL.Text := 'http://localhost:8095';
         edtModel.Text := 'Qwen2.5-05B-Instruct';
       end;
    4: begin // Gemini
         edtBaseURL.Text := 'https://generativelanguage.googleapis.com';
         edtModel.Text := 'gemini-2.5-flash';
       end;
    5: begin // Claude
         edtBaseURL.Text := 'https://api.anthropic.com/v1';
         edtModel.Text := 'claude-3-5-sonnet-20241022';
       end;
  end;
end;

function TfrmAgentMemoryMapDemo.ConfigureChatGPT: Boolean;
var
  LProvider: TAIProvider;
begin
  Result := False;
  
  LProvider := TAIProvider(cbProvider.ItemIndex);
  if (LProvider <> AIP_LOCAL) and (Trim(edtToken.Text) = '') then
  begin
    ShowMessage('Erro: O Token / Chave de API é obrigatório para o provedor selecionado.');
    Exit;
  end;
  
  FChatGPT.TOKEN := Trim(edtToken.Text);
  FChatGPT.CustomModel := Trim(edtModel.Text);
  FChatGPT.MaxTokens := 300;
  FChatGPT.Provider := LProvider;
  
  if LProvider = AIP_LOCAL then
  begin
    FChatGPT.URL := '';
    FChatGPT.LocalIP := edtBaseURL.Text;
  end
  else
  begin
    FChatGPT.URL := edtBaseURL.Text;
    FChatGPT.LocalIP := '';
  end;
  Result := True;
end;

procedure TfrmAgentMemoryMapDemo.LoadScriptFromFile(const APath: string);
var
  LStream: TFileStream;
  LParser: TJSONParser;
begin
  if not FileExists(APath) then Exit;
  
  if Assigned(FScriptData) then FreeAndNil(FScriptData);
  
  try
    LStream := TFileStream.Create(APath, fmOpenRead or fmShareDenyWrite);
    try
      LParser := TJSONParser.Create(LStream);
      try
        FScriptData := LParser.Parse as TJSONObject;
      finally
        LParser.Free;
      end;
    finally
      LStream.Free;
    end;
    
    if Assigned(FScriptData) then
    begin
      if (FScriptData.Arrays['action_plans'] = nil) or (FScriptData.Arrays['dialogues'] = nil) then
      begin
        ShowMessage('Erro: O arquivo JSON não contém as seções obrigatórias "action_plans" e "dialogues".');
        memLogs.Lines.Add('Erro de validação JSON: Seções obrigatórias ausentes.');
        Exit;
      end;
    end;
    
    RefreshPlansGrid;
    RefreshDialoguesGrid;
    RefreshPlansComboBox;
  except
    on E: Exception do
    begin
      ShowMessage('Erro ao carregar o script: ' + E.Message);
      memLogs.Lines.Add('Erro ao carregar JSON: ' + E.Message);
    end;
  end;
end;

procedure TfrmAgentMemoryMapDemo.RefreshPlansGrid;
var
  LPlans: TJSONArray;
  I: Integer;
  LPlan: TJSONObject;
begin
  sgPlans.RowCount := 1;
  if not Assigned(FScriptData) then Exit;
  
  LPlans := FScriptData.Arrays['action_plans'];
  if not Assigned(LPlans) then Exit;
  
  sgPlans.RowCount := LPlans.Count + 1;
  sgPlans.Cells[0, 0] := 'ID';
  sgPlans.Cells[1, 0] := 'Nome';
  
  for I := 0 to LPlans.Count - 1 do
  begin
    LPlan := LPlans.Objects[I];
    sgPlans.Cells[0, I + 1] := LPlan.Strings['id'];
    sgPlans.Cells[1, I + 1] := LPlan.Strings['name'];
  end;
end;

procedure TfrmAgentMemoryMapDemo.RefreshDialoguesGrid;
var
  LDialogues: TJSONArray;
  I: Integer;
  LDialogue: TJSONObject;
begin
  sgDialogues.RowCount := 1;
  if not Assigned(FScriptData) then Exit;
  
  LDialogues := FScriptData.Arrays['dialogues'];
  if not Assigned(LDialogues) then Exit;
  
  sgDialogues.RowCount := LDialogues.Count + 1;
  sgDialogues.Cells[0, 0] := 'ID';
  sgDialogues.Cells[1, 0] := 'Plano Esperado';
  sgDialogues.Cells[2, 0] := 'Resultado';
  
  for I := 0 to LDialogues.Count - 1 do
  begin
    LDialogue := LDialogues.Objects[I];
    sgDialogues.Cells[0, I + 1] := IntToStr(LDialogue.Integers['id']);
    sgDialogues.Cells[1, I + 1] := LDialogue.Strings['expected_action_plan'];
    sgDialogues.Cells[2, I + 1] := '';
  end;
end;

procedure TfrmAgentMemoryMapDemo.RefreshPlansComboBox;
var
  LPlans: TJSONArray;
  I: Integer;
begin
  cbExpectedPlan.Clear;
  if not Assigned(FScriptData) then Exit;
  
  LPlans := FScriptData.Arrays['action_plans'];
  if not Assigned(LPlans) then Exit;
  
  for I := 0 to LPlans.Count - 1 do
    cbExpectedPlan.Items.Add(LPlans.Objects[I].Strings['id']);
end;

procedure TfrmAgentMemoryMapDemo.sgPlansSelectionChanged(Sender: TObject; aCol, aRow: Integer);
var
  LPlans: TJSONArray;
  LPlan: TJSONObject;
begin
  if (aRow < 1) or not Assigned(FScriptData) then Exit;
  LPlans := FScriptData.Arrays['action_plans'];
  if (LPlans = nil) or (aRow - 1 >= LPlans.Count) then Exit;
  
  LPlan := LPlans.Objects[aRow - 1];
  edtPlanID.Text := LPlan.Strings['id'];
  edtPlanName.Text := LPlan.Strings['name'];
  memPlanDesc.Text := LPlan.Strings['description'];
end;

procedure TfrmAgentMemoryMapDemo.sgPlansDblClick(Sender: TObject);
var
  LForm: TForm;
  LEdtID, LEdtName: TEdit;
  LMemDesc: TMemo;
  LLblID, LLblName, LLblDesc: TLabel;
  LBtnOk, LBtnCancel: TButton;
  LRow: Integer;
  LPlans: TJSONArray;
  LPlan: TJSONObject;
begin
  LRow := sgPlans.Row;
  if (LRow < 1) or not Assigned(FScriptData) then Exit;
  
  LPlans := FScriptData.Arrays['action_plans'];
  if (LPlans = nil) or (LRow - 1 >= LPlans.Count) then Exit;
  LPlan := LPlans.Objects[LRow - 1];
  
  LForm := TForm.Create(nil);
  try
    LForm.Caption := 'Visualizar / Editar Plano de Ação';
    LForm.Width := 500;
    LForm.Height := 450;
    LForm.Position := poScreenCenter;
    LForm.BorderStyle := bsDialog;
    
    LLblID := TLabel.Create(LForm);
    LLblID.Parent := LForm;
    LLblID.Left := 20; LLblID.Top := 15;
    LLblID.Caption := 'Identificador:';
    
    LEdtID := TEdit.Create(LForm);
    LEdtID.Parent := LForm;
    LEdtID.Left := 20; LEdtID.Top := 35;
    LEdtID.Width := 460;
    LEdtID.Text := LPlan.Strings['id'];
    LEdtID.Enabled := False;
    
    LLblName := TLabel.Create(LForm);
    LLblName.Parent := LForm;
    LLblName.Left := 20; LLblName.Top := 75;
    LLblName.Caption := 'Nome do Plano:';
    
    LEdtName := TEdit.Create(LForm);
    LEdtName.Parent := LForm;
    LEdtName.Left := 20; LEdtName.Top := 95;
    LEdtName.Width := 460;
    LEdtName.Text := LPlan.Strings['name'];
    
    LLblDesc := TLabel.Create(LForm);
    LLblDesc.Parent := LForm;
    LLblDesc.Left := 20; LLblDesc.Top := 135;
    LLblDesc.Caption := 'Descrição/Explicação para o Agente:';
    
    LMemDesc := TMemo.Create(LForm);
    LMemDesc.Parent := LForm;
    LMemDesc.Left := 20; LMemDesc.Top := 155;
    LMemDesc.Width := 460; LMemDesc.Height := 200;
    LMemDesc.ScrollBars := ssAutoVertical;
    LMemDesc.Text := LPlan.Strings['description'];
    
    LBtnOk := TButton.Create(LForm);
    LBtnOk.Parent := LForm;
    LBtnOk.Caption := 'Gravar';
    LBtnOk.ModalResult := mrOk;
    LBtnOk.Left := 290; LBtnOk.Top := 380;
    LBtnOk.Width := 85; LBtnOk.Height := 30;
    LBtnOk.Default := True;
    
    LBtnCancel := TButton.Create(LForm);
    LBtnCancel.Parent := LForm;
    LBtnCancel.Caption := 'Cancelar';
    LBtnCancel.ModalResult := mrCancel;
    LBtnCancel.Left := 390; LBtnCancel.Top := 380;
    LBtnCancel.Width := 85; LBtnCancel.Height := 30;
    LBtnCancel.Cancel := True;
    
    if LForm.ShowModal = mrOk then
    begin
      LPlan.Strings['name'] := LEdtName.Text;
      LPlan.Strings['description'] := LMemDesc.Text;
      RefreshPlansGrid;
      RefreshPlansComboBox;
    end;
  finally
    LForm.Free;
  end;
end;

procedure TfrmAgentMemoryMapDemo.sgDialoguesSelectionChanged(Sender: TObject; aCol, aRow: Integer);
var
  LDialogues: TJSONArray;
  LDialogue: TJSONObject;
  LTurns: TJSONArray;
  I: Integer;
begin
  if (aRow < 1) or not Assigned(FScriptData) then Exit;
  LDialogues := FScriptData.Arrays['dialogues'];
  if (LDialogues = nil) or (aRow - 1 >= LDialogues.Count) then Exit;
  
  LDialogue := LDialogues.Objects[aRow - 1];
  cbExpectedPlan.ItemIndex := cbExpectedPlan.Items.IndexOf(LDialogue.Strings['expected_action_plan']);
  
  memTurns.Clear;
  LTurns := LDialogue.Arrays['turns'];
  if Assigned(LTurns) then
  begin
    for I := 0 to LTurns.Count - 1 do
      memTurns.Lines.Add(LTurns.Strings[I]);
  end;
end;

procedure TfrmAgentMemoryMapDemo.btnLoadScriptClick(Sender: TObject);
begin
  LoadScriptFromFile(edtScriptPath.Text);
end;

procedure TfrmAgentMemoryMapDemo.btnSaveScriptClick(Sender: TObject);
var
  LFile: TStringList;
begin
  if not Assigned(FScriptData) then Exit;
  
  LFile := TStringList.Create;
  try
    LFile.Text := FScriptData.FormatJSON();
    LFile.SaveToFile(edtScriptPath.Text);
    ShowMessage('Script gravado com sucesso em ' + edtScriptPath.Text);
  finally
    LFile.Free;
  end;
end;

procedure TfrmAgentMemoryMapDemo.btnNewScriptClick(Sender: TObject);
begin
  if Assigned(FScriptData) then FreeAndNil(FScriptData);
  
  FScriptData := TJSONObject.Create;
  FScriptData.Add('action_plans', TJSONArray.Create);
  FScriptData.Add('dialogues', TJSONArray.Create);
  
  RefreshPlansGrid;
  RefreshDialoguesGrid;
  RefreshPlansComboBox;
end;

procedure TfrmAgentMemoryMapDemo.btnAddPlanClick(Sender: TObject);
var
  LPlans: TJSONArray;
  LPlan: TJSONObject;
  I: Integer;
  LID: string;
begin
  if not Assigned(FScriptData) then Exit;
  
  LID := Trim(edtPlanID.Text);
  if LID = '' then
  begin
    ShowMessage('Erro: O ID do plano de ação não pode estar vazio.');
    Exit;
  end;
  
  if Trim(edtPlanName.Text) = '' then
  begin
    ShowMessage('Erro: O nome do plano de ação não pode estar vazio.');
    Exit;
  end;
  
  if Trim(memPlanDesc.Text) = '' then
  begin
    ShowMessage('Erro: A descrição do plano de ação não pode estar vazia.');
    Exit;
  end;
  
  LPlans := FScriptData.Arrays['action_plans'];
  if not Assigned(LPlans) then Exit;
  
  { Verificar se o ID já existe }
  for I := 0 to LPlans.Count - 1 do
  begin
    if SameText(LPlans.Objects[I].Strings['id'], LID) then
    begin
      ShowMessage('Erro: Já existe um plano de ação com o ID "' + LID + '".');
      Exit;
    end;
  end;
  
  LPlan := TJSONObject.Create;
  LPlan.Add('id', LID);
  LPlan.Add('name', Trim(edtPlanName.Text));
  LPlan.Add('description', Trim(memPlanDesc.Text));
  LPlans.Add(LPlan);
  
  RefreshPlansGrid;
  RefreshPlansComboBox;
end;

procedure TfrmAgentMemoryMapDemo.btnSavePlanClick(Sender: TObject);
var
  LPlans: TJSONArray;
  LPlan: TJSONObject;
  LIndex: Integer;
begin
  LIndex := sgPlans.Row - 1;
  if (LIndex < 0) or not Assigned(FScriptData) then Exit;
  
  LPlans := FScriptData.Arrays['action_plans'];
  if (LPlans = nil) or (LIndex >= LPlans.Count) then Exit;
  
  LPlan := LPlans.Objects[LIndex];
  LPlan.Strings['id'] := edtPlanID.Text;
  LPlan.Strings['name'] := edtPlanName.Text;
  LPlan.Strings['description'] := memPlanDesc.Text;
  
  RefreshPlansGrid;
  RefreshPlansComboBox;
end;

procedure TfrmAgentMemoryMapDemo.btnDeletePlanClick(Sender: TObject);
var
  LPlans: TJSONArray;
  LIndex: Integer;
begin
  LIndex := sgPlans.Row - 1;
  if (LIndex < 0) or not Assigned(FScriptData) then Exit;
  
  LPlans := FScriptData.Arrays['action_plans'];
  if (LPlans = nil) or (LIndex >= LPlans.Count) then Exit;
  
  LPlans.Delete(LIndex);
  RefreshPlansGrid;
  RefreshPlansComboBox;
end;

procedure TfrmAgentMemoryMapDemo.btnAddDialogueClick(Sender: TObject);
var
  LDialogues: TJSONArray;
  LDialogue: TJSONObject;
  LTurns: TJSONArray;
  I: Integer;
  LTurnText: string;
begin
  if not Assigned(FScriptData) then Exit;
  
  if Trim(cbExpectedPlan.Text) = '' then
  begin
    ShowMessage('Erro: É necessário selecionar um plano de ação esperado.');
    Exit;
  end;
  
  LDialogues := FScriptData.Arrays['dialogues'];
  if not Assigned(LDialogues) then Exit;
  
  LTurns := TJSONArray.Create;
  for I := 0 to memTurns.Lines.Count - 1 do
  begin
    LTurnText := Trim(memTurns.Lines[I]);
    if LTurnText <> '' then
      LTurns.Add(LTurnText);
  end;
  
  if LTurns.Count = 0 then
  begin
    LTurns.Free;
    ShowMessage('Erro: O diálogo de teste deve conter pelo menos um turno preenchido.');
    Exit;
  end;
  
  LDialogue := TJSONObject.Create;
  LDialogue.Add('id', LDialogues.Count + 1);
  LDialogue.Add('expected_action_plan', Trim(cbExpectedPlan.Text));
  LDialogue.Add('turns', LTurns);
  
  LDialogues.Add(LDialogue);
  RefreshDialoguesGrid;
end;

procedure TfrmAgentMemoryMapDemo.btnSaveDialogueClick(Sender: TObject);
var
  LDialogues: TJSONArray;
  LDialogue: TJSONObject;
  LTurns: TJSONArray;
  LIndex: Integer;
  I: Integer;
begin
  LIndex := sgDialogues.Row - 1;
  if (LIndex < 0) or not Assigned(FScriptData) then Exit;
  
  LDialogues := FScriptData.Arrays['dialogues'];
  if (LDialogues = nil) or (LIndex >= LDialogues.Count) then Exit;
  
  LDialogue := LDialogues.Objects[LIndex];
  LDialogue.Strings['expected_action_plan'] := cbExpectedPlan.Text;
  
  LTurns := TJSONArray.Create;
  for I := 0 to memTurns.Lines.Count - 1 do
    LTurns.Add(memTurns.Lines[I]);
    
  LDialogue.Arrays['turns'] := LTurns;
  RefreshDialoguesGrid;
end;

procedure TfrmAgentMemoryMapDemo.btnDeleteDialogueClick(Sender: TObject);
var
  LDialogues: TJSONArray;
  LIndex: Integer;
begin
  LIndex := sgDialogues.Row - 1;
  if (LIndex < 0) or not Assigned(FScriptData) then Exit;
  
  LDialogues := FScriptData.Arrays['dialogues'];
  if (LDialogues = nil) or (LIndex >= LDialogues.Count) then Exit;
  
  LDialogues.Delete(LIndex);
  RefreshDialoguesGrid;
end;

procedure TfrmAgentMemoryMapDemo.UpdateSystemPrompts;
var
  LPlans: TJSONArray;
  I: Integer;
  LPlan: TJSONObject;
  LPrompt: string;
  LMemoryText: string;
begin
  if not Assigned(FScriptData) then Exit;
  
  LPlans := FScriptData.Arrays['action_plans'];
  if not Assigned(LPlans) then Exit;
  
  LPrompt := 'Você é o Agente Classificador do sistema de suporte da TI.' + sLineBreak +
             'Seu trabalho é analisar a pergunta do usuário e verificar se ela corresponde a algum dos planos de ação disponíveis.' + sLineBreak;
             
  { Se houver itens na memória, injeta o contexto da memória }
  if Assigned(FOrchestrator.MemoryMap) and (FOrchestrator.MemoryMap.Items.Count > 0) then
  begin
    LMemoryText := FOrchestrator.MemoryMap.BuildConversationContext(3);
    LPrompt := LPrompt + sLineBreak + 
               'Histórico e contexto da conversa (Memory Map):' + sLineBreak +
               LMemoryText + sLineBreak + sLineBreak;
  end;
  
  LPrompt := LPrompt + 'Da pergunta acima, dá para identificar alguma das seguintes ações?' + sLineBreak + sLineBreak;
             
  for I := 0 to LPlans.Count - 1 do
  begin
    LPlan := LPlans.Objects[I];
    LPrompt := LPrompt + 'Ação: ' + LPlan.Strings['id'] + ' | Descrição: ' + LPlan.Strings['description'] + sLineBreak;
  end;
  
  LPrompt := LPrompt + sLineBreak +
             'REGRAS OBRIGATÓRIAS:' + sLineBreak +
             '1. A resposta deve ter um objeto JSON como raiz.' + sLineBreak +
             '2. A resposta deve começar com "{" e terminar com "}".' + sLineBreak +
             '3. O campo "target_agents" deve ser um array com exatamente um item.' + sLineBreak +
             '4. O item deve ser exatamente um dos identificadores de ação listados acima ou "nenhuma".' + sLineBreak +
             '5. Não retorne nomes de equipamentos, setores, objetos ou categorias em "target_agents".' + sLineBreak +
             '6. Nunca retorne somente um array como ["nenhuma"].' + sLineBreak +
             '7. Não inclua Markdown, comentários ou texto fora do JSON.';
             
  FClassifier.SystemPrompt := LPrompt;
end;

procedure TfrmAgentMemoryMapDemo.ResetStats;
var
  LPlans: TJSONArray;
  I: Integer;
  LPlan: TJSONObject;
begin
  FStatsTotal := 0;
  FStatsCorrect := 0;
  
  FStatsPlansTotal.Clear;
  FStatsPlansCorrect.Clear;
  
  if not Assigned(FScriptData) then Exit;
  
  LPlans := FScriptData.Arrays['action_plans'];
  if not Assigned(LPlans) then Exit;
  
  for I := 0 to LPlans.Count - 1 do
  begin
    LPlan := LPlans.Objects[I];
    FStatsPlansTotal.Add(LPlan.Strings['id'], 0);
    FStatsPlansCorrect.Add(LPlan.Strings['id'], 0);
  end;
end;

procedure TfrmAgentMemoryMapDemo.UpdateStatsUI;
var
  LPercent: Double;
  LPlans: TJSONArray;
  I: Integer;
  LPlanID: string;
  LTotal, LCorrect: Integer;
  LPlanPercent: Double;
begin
  memStats.Clear;
  if FStatsTotal > 0 then
    LPercent := (FStatsCorrect / FStatsTotal) * 100.0
  else
    LPercent := 0.0;
    
  memStats.Lines.Add('=== ESTATÍSTICAS GERAIS DA SIMULAÇÃO ===');
  memStats.Lines.Add(Format('Total de Diálogos Executados: %d', [FStatsTotal]));
  memStats.Lines.Add(Format('Classificações Corretas: %d', [FStatsCorrect]));
  memStats.Lines.Add(Format('Precisão Global: %0.2f%%', [LPercent]));
  memStats.Lines.Add('========================================');
  
  if not Assigned(FScriptData) then Exit;
  LPlans := FScriptData.Arrays['action_plans'];
  if not Assigned(LPlans) then Exit;
  
  sgStatsPlans.RowCount := LPlans.Count + 1;
  sgStatsPlans.Cells[0, 0] := 'Plano de Ação';
  sgStatsPlans.Cells[1, 0] := 'Total de Testes';
  sgStatsPlans.Cells[2, 0] := 'Acertos';
  sgStatsPlans.Cells[3, 0] := 'Precisão (%)';
  
  for I := 0 to LPlans.Count - 1 do
  begin
    LPlanID := LPlans.Objects[I].Strings['id'];
    LTotal := FStatsPlansTotal.Integers[LPlanID];
    LCorrect := FStatsPlansCorrect.Integers[LPlanID];
    
    if LTotal > 0 then
      LPlanPercent := (LCorrect / LTotal) * 100.0
    else
      LPlanPercent := 0.0;
      
    sgStatsPlans.Cells[0, I + 1] := LPlanID;
    sgStatsPlans.Cells[1, I + 1] := IntToStr(LTotal);
    sgStatsPlans.Cells[2, I + 1] := IntToStr(LCorrect);
    sgStatsPlans.Cells[3, I + 1] := Format('%0.2f%%', [LPlanPercent]);
  end;
end;

procedure TfrmAgentMemoryMapDemo.btnStopSimClick(Sender: TObject);
begin
  FStopSimulation := True;
  memLogs.Lines.Add('Parando simulação na próxima iteração...');
end;

procedure TfrmAgentMemoryMapDemo.btnStartSimClick(Sender: TObject);
var
  LDialogues: TJSONArray;
  I, J: Integer;
  LDialogue: TJSONObject;
  LTurns: TJSONArray;
  LExpected: string;
  LTurnText: string;
  LSuccess: Boolean;
  LHasExecError: Boolean;
begin
  LHasExecError := False;
  if not ConfigureChatGPT then Exit;
  if not Assigned(FScriptData) then Exit;
  
  LDialogues := FScriptData.Arrays['dialogues'];
  if (LDialogues = nil) or (LDialogues.Count = 0) then
  begin
    ShowMessage('Nenhum diálogo disponível no script.');
    Exit;
  end;
  
  UpdateSystemPrompts;
  ResetStats;
  UpdateStatsUI;
  
  FStopSimulation := False;
  btnStartSim.Enabled := False;
  btnStopSim.Enabled := True;
  btnStopSimExecution.Enabled := True;
  PageControl1.ActivePage := tsExecution;
  memLogs.Clear;
  memConvHistory.Clear;
  memConvMemoryMap.Clear;
  pbProgress.Min := 0;
  pbProgress.Max := LDialogues.Count;
  pbProgress.Position := 0;
  
  try
    for I := 0 to LDialogues.Count - 1 do
    begin
      if FStopSimulation then Break;
      
      LDialogue := LDialogues.Objects[I];
      LExpected := LDialogue.Strings['expected_action_plan'];
      LTurns := LDialogue.Arrays['turns'];
      
      memLogs.Lines.Add(Format('--- Iniciando Diálogo %d (Espera: %s) ---', [LDialogue.Integers['id'], LExpected]));
      memConvHistory.Lines.Add(Format('--- Diálogo %d (Espera: %s) ---', [LDialogue.Integers['id'], LExpected]));
      
      { Start conversational session }
      if LTurns.Count > 0 then
        FOrchestrator.BeginConversation(LTurns.Strings[0]);
        
      FLastClassification := '';
      LSuccess := True;
      
      for J := 0 to LTurns.Count - 1 do
      begin
        if FStopSimulation then Break;
        LTurnText := LTurns.Strings[J];
        memLogs.Lines.Add(Format('Turno %d: %s', [J + 1, LTurnText]));
        memConvHistory.Lines.Add(Format('Pergunta: %s', [LTurnText]));
        
        UpdateSystemPrompts;
        
        try
          if chkClassifierOnly.Checked then
          begin
            if not ExecuteClassifierOnly(LTurnText, FLastClassification) then
            begin
              memLogs.Lines.Add('Classificação falhou.');
              memConvHistory.Lines.Add('Resposta (Classificador): ERRO');
              LSuccess := False;
              Break;
            end;
          end
          else
          begin
            if not FOrchestrator.Run(LTurnText) then
            begin
              memLogs.Lines.Add('Fluxo retornou falha.');
              memConvHistory.Lines.Add('Resposta (Classificador): ERRO / FALHA');
              LSuccess := False;
              Break;
            end;
          end;
        except
          on E: Exception do
          begin
            memLogs.Lines.Add('Erro de execução: ' + E.Message);
            memConvHistory.Lines.Add('Resposta (Classificador): ERRO / ' + E.Message);
            LSuccess := False;
            Break;
          end;
        end;
        
        if (FLastClassification = '__CONTRACT_ERROR__') or (FLastClassification = '__JSON_ERROR__') or (FLastClassification = '') then
          memConvHistory.Lines.Add('Resposta (Classificador): ERRO DE CONTRATO')
        else
          memConvHistory.Lines.Add('Resposta (Classificador): ' + FLastClassification);
          
        if Assigned(FOrchestrator.MemoryMap) then
          memConvMemoryMap.Text := FOrchestrator.MemoryMap.AsText;
          
        Application.ProcessMessages;
      end;
      
      if LSuccess and not FStopSimulation then
      begin
        FStatsTotal := FStatsTotal + 1;
        FStatsPlansTotal.Integers[LExpected] := FStatsPlansTotal.Integers[LExpected] + 1;
        
        memLogs.Lines.Add(Format('Classificação do modelo: "%s" | Esperado: "%s"', [FLastClassification, LExpected]));
        
        if SameText(FLastClassification, LExpected) then
        begin
          FStatsCorrect := FStatsCorrect + 1;
          FStatsPlansCorrect.Integers[LExpected] := FStatsPlansCorrect.Integers[LExpected] + 1;
          memLogs.Lines.Add('Resultado: CORRETO');
          sgDialogues.Cells[2, I + 1] := 'CORRETO';
        end
        else
        begin
          memLogs.Lines.Add('Resultado: INCORRETO');
          sgDialogues.Cells[2, I + 1] := 'INCORRETO';
        end;
      end
      else if not LSuccess then
      begin
        sgDialogues.Cells[2, I + 1] := 'FALHA';
        LHasExecError := True;
      end;
      
      FOrchestrator.EndConversation;
      
      memLogs.Lines.Add('----------------------------------------' + sLineBreak);
      memConvHistory.Lines.Add('----------------------------------------');
      pbProgress.Position := I + 1;
      UpdateStatsUI;
      Application.ProcessMessages;
    end;
  finally
    btnStartSim.Enabled := True;
    btnStopSim.Enabled := False;
    btnStopSimExecution.Enabled := False;
    if FStopSimulation then
      ShowMessage('Simulação parada pelo usuário.')
    else if LHasExecError then
      ShowMessage('Simulação concluída com falhas ou erros de classificação!')
    else
      ShowMessage('Simulação concluída perfeitamente com 100% de acerto!');
  end;
end;

{ Event triggers }

procedure TfrmAgentMemoryMapDemo.OnBeforeFlowStart(Sender: TObject; AContexto: TAIFluxoEtapaContexto; var ACanContinue: Boolean);
begin
end;

procedure TfrmAgentMemoryMapDemo.OnAfterFlowStart(
  Sender: TObject;
  AContexto: TAIFluxoEtapaContexto
);
begin
  if Assigned(FOrchestrator.MemoryMap) then
    FOrchestrator.MemoryMap.DetectInformationLoss := False;
end;

procedure TfrmAgentMemoryMapDemo.OnBeforeClassifier(Sender: TObject; AContexto: TAIFluxoEtapaContexto; var ACanContinue: Boolean);
begin
end;

procedure TfrmAgentMemoryMapDemo.OnAfterClassifier(
  Sender: TObject;
  AContexto: TAIFluxoEtapaContexto
);
var
  LTargetAgent: string;
  LError: string;
begin
  FLastClassification := '';

  memLogs.Lines.Add('Resposta JSON do classificador:');
  memLogs.Lines.Add(AContexto.SaidaAtual);

  if not ValidateClassificationOutput(
    AContexto.SaidaAtual,
    LTargetAgent,
    LError
  ) then
  begin
    if Pos('Erro de contrato', LError) > 0 then
      FLastClassification := '__CONTRACT_ERROR__'
    else
      FLastClassification := '__JSON_ERROR__';
    memLogs.Lines.Add(LError);
    Exit;
  end;

  FLastClassification := LTargetAgent;

  memLogs.Lines.Add(
    'Classificação extraída: "' +
    FLastClassification + '".'
  );
end;

procedure TfrmAgentMemoryMapDemo.OnBeforeDecisionAgent(Sender: TObject; AContexto: TAIFluxoEtapaContexto; var ACanContinue: Boolean);
begin
end;

procedure TfrmAgentMemoryMapDemo.OnAfterDecisionAgent(Sender: TObject; AContexto: TAIFluxoEtapaContexto);
begin
end;

procedure TfrmAgentMemoryMapDemo.OnBeforeActionBuilder(Sender: TObject; AContexto: TAIFluxoEtapaContexto; var ACanContinue: Boolean);
begin
end;

procedure TfrmAgentMemoryMapDemo.OnAfterActionBuilder(Sender: TObject; AContexto: TAIFluxoEtapaContexto);
begin
end;

procedure TfrmAgentMemoryMapDemo.OnBeforeExecutor(Sender: TObject; AContexto: TAIFluxoEtapaContexto; var ACanContinue: Boolean);
begin
end;

procedure TfrmAgentMemoryMapDemo.OnAfterExecutor(Sender: TObject; AContexto: TAIFluxoEtapaContexto);
begin
end;

procedure TfrmAgentMemoryMapDemo.OnFlowFinished(Sender: TObject; AContexto: TAIFluxoEtapaContexto);
begin
end;

procedure TfrmAgentMemoryMapDemo.OnFlowError(Sender: TObject; AContexto: TAIFluxoEtapaContexto);
begin
  memLogs.Lines.Add('Erro detectado no fluxo: ' + AContexto.MensagemErro);
  memLogs.Lines.Add('=== RESPOSTA BRUTA DO MODELO (CHATGPT) ===');
  memLogs.Lines.Add(string(FChatGPT.Response));
  memLogs.Lines.Add('==========================================');
end;

procedure TfrmAgentMemoryMapDemo.OnFlowStage(Sender: TObject; AContexto: TAIFluxoEtapaContexto);
begin
end;

procedure TfrmAgentMemoryMapDemo.OnInformationLossDetected(Sender: TObject; AContexto: TAIFluxoEtapaContexto);
var
  I: Integer;
begin
  if Assigned(AContexto) and Assigned(AContexto.Alertas) then
  begin
    for I := 0 to AContexto.Alertas.Count - 1 do
    begin
      memLogs.Lines.Add('ALERTA: ' + AContexto.Alertas.Strings[I]);
    end;
  end;
end;

end.
