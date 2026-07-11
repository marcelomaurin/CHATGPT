unit frm_aiwizardconfig;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, StdCtrls, ExtCtrls, Dialogs, chatgpt, aiproject, aipipeline, aimodelregistry;

type
  { TFormAIWizardConfig }

  TFormAIWizardConfig = class(TForm)
  private
    FProject: TAIProject;
    FChatGPT: TCHATGPT;
    FPipeline: TAIPipeline;
    FRegistry: TAIModelRegistry;

    // UI Panels and controls
    pnlHeader: TPanel;
    lblHeaderTitle: TLabel;
    pnlClient: TPanel;
    pnlButtons: TPanel;

    lblProjectType: TLabel;
    cbProjectType: TComboBox;
    lblProvider: TLabel;
    cbProvider: TComboBox;
    lblModel: TLabel;
    cbModel: TComboBox;
    lblLocalURL: TLabel;
    edtLocalURL: TEdit;
    chkSafeMode: TCheckBox;
    chkSimulationMode: TCheckBox;
    
    btnTestConnection: TButton;
    btnApply: TButton;
    btnCancel: TButton;

    procedure cbProviderChange(Sender: TObject);
    procedure btnTestConnectionClick(Sender: TObject);
    procedure btnApplyClick(Sender: TObject);
    procedure btnCancelClick(Sender: TObject);
    procedure InitializeUI;
  public
    constructor CreateCustom(
      AOwner: TComponent;
      AProject: TAIProject;
      AChatGPT: TCHATGPT;
      APipeline: TAIPipeline;
      ARegistry: TAIModelRegistry
    ); reintroduce;
  end;

implementation

{ TFormAIWizardConfig }

constructor TFormAIWizardConfig.CreateCustom(
  AOwner: TComponent;
  AProject: TAIProject;
  AChatGPT: TCHATGPT;
  APipeline: TAIPipeline;
  ARegistry: TAIModelRegistry
);
begin
  inherited CreateNew(AOwner);
  FProject := AProject;
  FChatGPT := AChatGPT;
  FPipeline := APipeline;
  FRegistry := ARegistry;

  InitializeUI;
end;

procedure TFormAIWizardConfig.InitializeUI;
var
  LTempProv: TStringList;
begin
  Caption := 'AI Project Configuration Wizard';
  Position := poScreenCenter;
  Width := 460;
  Height := 430;
  BorderStyle := bsDialog;

  // Header Panel
  pnlHeader := TPanel.Create(Self);
  pnlHeader.Parent := Self;
  pnlHeader.Align := alTop;
  pnlHeader.Height := 60;
  pnlHeader.Color := $007E231A; // Sleek Navy Blue
  pnlHeader.BevelOuter := bvNone;

  lblHeaderTitle := TLabel.Create(Self);
  lblHeaderTitle.Parent := pnlHeader;
  lblHeaderTitle.Align := alClient;
  lblHeaderTitle.Alignment := taCenter;
  lblHeaderTitle.Layout := tlCenter;
  lblHeaderTitle.Font.Name := 'Arial';
  lblHeaderTitle.Font.Size := 13;
  lblHeaderTitle.Font.Bold := True;
  lblHeaderTitle.Font.Color := clWhite;
  lblHeaderTitle.Caption := 'Configuração do Ciclo de IA Lazarus';

  // Bottom Buttons Panel
  pnlButtons := TPanel.Create(Self);
  pnlButtons.Parent := Self;
  pnlButtons.Align := alBottom;
  pnlButtons.Height := 50;
  pnlButtons.BevelOuter := bvNone;

  btnApply := TButton.Create(Self);
  btnApply.Parent := pnlButtons;
  btnApply.Width := 90;
  btnApply.Height := 30;
  btnApply.Left := 160;
  btnApply.Top := 10;
  btnApply.Caption := 'Aplicar';
  btnApply.OnClick := @btnApplyClick;

  btnCancel := TButton.Create(Self);
  btnCancel.Parent := pnlButtons;
  btnCancel.Width := 90;
  btnCancel.Height := 30;
  btnCancel.Left := 260;
  btnCancel.Top := 10;
  btnCancel.Caption := 'Cancelar';
  btnCancel.OnClick := @btnCancelClick;

  btnTestConnection := TButton.Create(Self);
  btnTestConnection.Parent := pnlButtons;
  btnTestConnection.Width := 130;
  btnTestConnection.Height := 30;
  btnTestConnection.Left := 15;
  btnTestConnection.Top := 10;
  btnTestConnection.Caption := 'Testar Conexão';
  btnTestConnection.OnClick := @btnTestConnectionClick;

  // Client Panel containing fields
  pnlClient := TPanel.Create(Self);
  pnlClient.Parent := Self;
  pnlClient.Align := alClient;
  pnlClient.BevelOuter := bvNone;
  pnlClient.BorderWidth := 15;

  // Project Type
  lblProjectType := TLabel.Create(Self);
  lblProjectType.Parent := pnlClient;
  lblProjectType.Left := 20;
  lblProjectType.Top := 20;
  lblProjectType.Caption := 'Tipo de Projeto de IA:';
  lblProjectType.Font.Bold := True;

  cbProjectType := TComboBox.Create(Self);
  cbProjectType.Parent := pnlClient;
  cbProjectType.Left := 20;
  cbProjectType.Top := 40;
  cbProjectType.Width := 400;
  cbProjectType.Style := csDropDownList;
  cbProjectType.Items.Add('chatbot');
  cbProjectType.Items.Add('classificador GraphMap');
  cbProjectType.Items.Add('pipeline textual');
  cbProjectType.Items.Add('pipeline documento');
  cbProjectType.Items.Add('agente seguro');
  cbProjectType.Items.Add('monitor industrial');
  cbProjectType.Items.Add('exportador de treinamento');
  cbProjectType.ItemIndex := 0;

  // Provider selection
  lblProvider := TLabel.Create(Self);
  lblProvider.Parent := pnlClient;
  lblProvider.Left := 20;
  lblProvider.Top := 80;
  lblProvider.Caption := 'Provedor / API:';
  lblProvider.Font.Bold := True;

  cbProvider := TComboBox.Create(Self);
  cbProvider.Parent := pnlClient;
  cbProvider.Left := 20;
  cbProvider.Top := 100;
  cbProvider.Width := 400;
  cbProvider.Style := csDropDownList;
  cbProvider.OnChange := @cbProviderChange;

  // Models Registry binding
  LTempProv := TStringList.Create;
  try
    if Assigned(FRegistry) then
      FRegistry.GetProviders(LTempProv)
    else
    begin
      LTempProv.Add('OpenAI');
      LTempProv.Add('Gemini');
      LTempProv.Add('Claude');
      LTempProv.Add('Local');
      LTempProv.Add('OpenRouter');
      LTempProv.Add('Cerebras');
    end;
    cbProvider.Items.Assign(LTempProv);
  finally
    LTempProv.Free;
  end;
  if cbProvider.Items.Count > 0 then
    cbProvider.ItemIndex := 0;

  // Model Selection
  lblModel := TLabel.Create(Self);
  lblModel.Parent := pnlClient;
  lblModel.Left := 20;
  lblModel.Top := 140;
  lblModel.Caption := 'Modelo de Linguagem:';
  lblModel.Font.Bold := True;

  cbModel := TComboBox.Create(Self);
  cbModel.Parent := pnlClient;
  cbModel.Left := 20;
  cbModel.Top := 160;
  cbModel.Width := 400;
  cbModel.Style := csDropDownList;

  cbProviderChange(nil);

  // Local URL for Ollama/Custom Local
  lblLocalURL := TLabel.Create(Self);
  lblLocalURL.Parent := pnlClient;
  lblLocalURL.Left := 20;
  lblLocalURL.Top := 200;
  lblLocalURL.Caption := 'Servidor Local IP/URL:';
  lblLocalURL.Font.Bold := True;

  edtLocalURL := TEdit.Create(Self);
  edtLocalURL.Parent := pnlClient;
  edtLocalURL.Left := 20;
  edtLocalURL.Top := 220;
  edtLocalURL.Width := 400;
  if Assigned(FChatGPT) then
    edtLocalURL.Text := FChatGPT.LocalIP
  else
    edtLocalURL.Text := 'http://localhost:11434';

  // Checkboxes for flags
  chkSafeMode := TCheckBox.Create(Self);
  chkSafeMode.Parent := pnlClient;
  chkSafeMode.Left := 20;
  chkSafeMode.Top := 265;
  chkSafeMode.Caption := 'Habilitar SafeMode (Prevenção de Escrita/Rede Externa)';
  chkSafeMode.Font.Bold := True;
  if Assigned(FProject) then
    chkSafeMode.Checked := FProject.SafeMode
  else
    chkSafeMode.Checked := False;

  chkSimulationMode := TCheckBox.Create(Self);
  chkSimulationMode.Parent := pnlClient;
  chkSimulationMode.Left := 20;
  chkSimulationMode.Top := 295;
  chkSimulationMode.Caption := 'Habilitar Modo Simulação (Offline mock responses)';
  chkSimulationMode.Font.Bold := True;
  if Assigned(FProject) then
    chkSimulationMode.Checked := FProject.SimulationMode
  else
    chkSimulationMode.Checked := False;
    
  // Pre-load from Project if assigned
  if Assigned(FProject) then
  begin
    if Assigned(FProject.Pipeline) then
    begin
      case FProject.Pipeline.Mode of
        pmTextLLM: cbProjectType.ItemIndex := 2;
        pmNumericML: cbProjectType.ItemIndex := 2;
        pmAgentAction: cbProjectType.ItemIndex := 4;
        pmDocumentGeneration: cbProjectType.ItemIndex := 3;
        pmIndustrialMonitor: cbProjectType.ItemIndex := 5;
        pmGraphMapClassification: cbProjectType.ItemIndex := 1;
      end;
    end;
  end;
end;

procedure TFormAIWizardConfig.cbProviderChange(Sender: TObject);
var
  LTempModels: TStringList;
begin
  LTempModels := TStringList.Create;
  try
    if cbProvider.ItemIndex >= 0 then
    begin
      if Assigned(FRegistry) then
        FRegistry.GetModels(cbProvider.Text, LTempModels)
      else
      begin
        if cbProvider.Text = 'OpenAI' then
        begin
          LTempModels.Add('gpt-4o-mini');
          LTempModels.Add('gpt-4o');
        end
        else if cbProvider.Text = 'Local' then
        begin
          LTempModels.Add('llama3.2:3b');
          LTempModels.Add('deepseek-r1:8b');
        end
        else
          LTempModels.Add('default_model');
      end;
      cbModel.Items.Assign(LTempModels);
      if cbModel.Items.Count > 0 then
        cbModel.ItemIndex := 0;
    end;
  finally
    LTempModels.Free;
  end;
end;

procedure TFormAIWizardConfig.btnTestConnectionClick(Sender: TObject);
var
  LTestComp: TCHATGPT;
  LResult: Boolean;
begin
  if not Assigned(FChatGPT) then
  begin
    ShowMessage('Nenhum componente TCHATGPT associado para testar.');
    Exit;
  end;

  LTestComp := TCHATGPT.Create(nil);
  try
    // Copy token to test component
    LTestComp.TOKEN := FChatGPT.TOKEN;
    LTestComp.LocalIP := edtLocalURL.Text;
    
    // Apply selected model from registry to test component
    if Assigned(FRegistry) and (cbModel.ItemIndex >= 0) then
      FRegistry.ApplyModel(cbModel.Text, LTestComp);
      
    if chkSimulationMode.Checked then
    begin
      ShowMessage('Simulado: Conexão bem-sucedida!');
      Exit;
    end;
    
    Screen.Cursor := crHourGlass;
    try
      LResult := LTestComp.SendQuestion('Olá, responda estritamente com OK se receber isso.');
      if LResult then
        ShowMessage('Conexão bem-sucedida! Resposta da IA: ' + LTestComp.Response)
      else
        ShowMessage('Falha na conexão: ' + LTestComp.LastError);
    finally
      Screen.Cursor := crDefault;
    end;
  finally
    LTestComp.Free;
  end;
end;

procedure TFormAIWizardConfig.btnApplyClick(Sender: TObject);
begin
  if cbModel.ItemIndex < 0 then
  begin
    ShowMessage('Selecione um modelo de IA antes de aplicar.');
    Exit;
  end;

  // Apply to ChatGPT
  if Assigned(FChatGPT) then
  begin
    FChatGPT.LocalIP := edtLocalURL.Text;
    if Assigned(FRegistry) then
      FRegistry.ApplyModel(cbModel.Text, FChatGPT);
  end;

  // Apply to Project
  if Assigned(FProject) then
  begin
    FProject.SafeMode := chkSafeMode.Checked;
    FProject.SimulationMode := chkSimulationMode.Checked;
    FProject.LocalURL := edtLocalURL.Text;
    
    if Assigned(FRegistry) and Assigned(FChatGPT) then
    begin
      FProject.DefaultProvider := FChatGPT.Provider;
      FProject.DefaultModel := FChatGPT.CustomModel;
    end;
    
    FProject.Initialize;
  end;

  // Apply to Pipeline mode
  if Assigned(FPipeline) then
  begin
    FPipeline.ChatGPT := FChatGPT;
    if cbProjectType.Text = 'chatbot' then FPipeline.Mode := pmTextLLM
    else if cbProjectType.Text = 'classificador GraphMap' then FPipeline.Mode := pmGraphMapClassification
    else if cbProjectType.Text = 'pipeline textual' then FPipeline.Mode := pmTextLLM
    else if cbProjectType.Text = 'pipeline documento' then FPipeline.Mode := pmDocumentGeneration
    else if cbProjectType.Text = 'agente seguro' then FPipeline.Mode := pmAgentAction
    else if cbProjectType.Text = 'monitor industrial' then FPipeline.Mode := pmIndustrialMonitor
    else if cbProjectType.Text = 'exportador de treinamento' then FPipeline.Mode := pmTextLLM;
  end;

  ModalResult := mrOk;
end;

procedure TFormAIWizardConfig.btnCancelClick(Sender: TObject);
begin
  ModalResult := mrCancel;
end;

end.
