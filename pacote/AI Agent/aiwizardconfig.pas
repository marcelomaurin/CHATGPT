unit aiwizardconfig;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Controls, aibase, chatgpt, aiproject, aipipeline, aimodelregistry, aipromptbuilder, frm_aiwizardconfig, fpjson, jsonparser, LResources;

type
  { TAIWizardConfig }

  TAIWizardConfig = class(TAIBaseComponent)
  private
    FProject: TAIProject;
    FChatGPT: TCHATGPT;
    FPipeline: TAIPipeline;
    FModelRegistry: TAIModelRegistry;
    FPromptBuilder: TAIPromptBuilder;
    
    FProjectType: string;
    FProviderName: string;
    FModelName: string;
    FLocalURL: string;
    FSafeMode: Boolean;
    FSimulationMode: Boolean;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    
    procedure ConfigureVisual;
    procedure Apply;
    function TestConnection: Boolean;
    
    procedure SaveToFile(const AFileName: string);
    procedure LoadFromFile(const AFileName: string);
  published
    property Project: TAIProject read FProject write FProject;
    property ChatGPT: TCHATGPT read FChatGPT write FChatGPT;
    property Pipeline: TAIPipeline read FPipeline write FPipeline;
    property ModelRegistry: TAIModelRegistry read FModelRegistry write FModelRegistry;
    property PromptBuilder: TAIPromptBuilder read FPromptBuilder write FPromptBuilder;
    
    property ProjectType: string read FProjectType write FProjectType;
    property ProviderName: string read FProviderName write FProviderName;
    property ModelName: string read FModelName write FModelName;
    property LocalURL: string read FLocalURL write FLocalURL;
    property SafeMode: Boolean read FSafeMode write FSafeMode default False;
    property SimulationMode: Boolean read FSimulationMode write FSimulationMode default False;
    property Category default ccOther;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('AI Core', [TAIWizardConfig]);
end;

{ TAIWizardConfig }

constructor TAIWizardConfig.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FCategory := ccOther;
  FPrompt := 'Component TAIWizardConfig orchestrates the initial setup and configuration details for an AI Project. It binds TAIProject, TCHATGPT, TAIPipeline, TAIModelRegistry, and TAIPromptBuilder, providing a dialog-based interface or automated initialization for specific AI tasks.';
  
  FProjectType := 'chatbot';
  FProviderName := 'OpenAI';
  FModelName := 'gpt-4o-mini';
  FLocalURL := 'http://localhost:11434';
  FSafeMode := False;
  FSimulationMode := False;
  
  FProject := nil;
  FChatGPT := nil;
  FPipeline := nil;
  FModelRegistry := nil;
  FPromptBuilder := nil;
  ClearError;
end;

destructor TAIWizardConfig.Destroy;
begin
  inherited Destroy;
end;

procedure TAIWizardConfig.ConfigureVisual;
var
  Frm: TFormAIWizardConfig;
begin
  ClearError;
  Log(llInfo, 'Abrindo diálogo de configuração visual.');
  Frm := TFormAIWizardConfig.CreateCustom(nil, FProject, FChatGPT, FPipeline, FModelRegistry);
  try
    if Frm.ShowModal = mrOk then
    begin
      // Update our properties from the ones set in the dialog
      if Assigned(FProject) then
      begin
        FSafeMode := FProject.SafeMode;
        FSimulationMode := FProject.SimulationMode;
        FLocalURL := FProject.LocalURL;
      end;
      if Assigned(FChatGPT) then
      begin
        FModelName := FChatGPT.CustomModel;
        FProviderName := FChatGPT.ProviderName;
      end;
      FLastResult := 'Configurações aplicadas via assistente visual.';
      FLastSuccess := True;
      Log(llInfo, FLastResult);
    end
    else
    begin
      FLastResult := 'Configuração cancelada pelo usuário.';
      Log(llInfo, FLastResult);
    end;
  finally
    Frm.Free;
  end;
end;

procedure TAIWizardConfig.Apply;
var
  BasePrompt: string;
begin
  ClearError;
  Log(llInfo, 'Aplicando configurações do Wizard de forma programática.');
  
  // Validate basic requirements
  if not Assigned(FChatGPT) then
  begin
    SetError('ChatGPT component must be assigned.');
    Exit;
  end;
  
  // Set ChatGPT parameters
  FChatGPT.LocalIP := FLocalURL;
  if Assigned(FModelRegistry) then
  begin
    FModelRegistry.ApplyModel(FModelName, FChatGPT);
  end;
  
  // Generate System Prompt
  BasePrompt := '';
  if FProjectType = 'chatbot' then BasePrompt := 'Você é um chatbot assistente de conversação geral.'
  else if FProjectType = 'classificador GraphMap' then BasePrompt := 'Você é um classificador estruturado baseado em grafo de tokens.'
  else if FProjectType = 'pipeline textual' then BasePrompt := 'Você é o processador de texto central de um pipeline de processamento.'
  else if FProjectType = 'pipeline documento' then BasePrompt := 'Você é um gerador e formatador de relatórios e documentos executivos.'
  else if FProjectType = 'agente seguro' then BasePrompt := 'Você é um agente autônomo com diretrizes estritas de segurança (Safe Mode ativo).'
  else if FProjectType = 'monitor industrial' then BasePrompt := 'Você é um monitor industrial analisando telemetrias em tempo real.'
  else if FProjectType = 'exportador de treinamento' then BasePrompt := 'Você é um analisador e organizador de datasets para treinamento de modelos.';
  
  if Assigned(FPromptBuilder) then
  begin
    // Generate prompt from available owner components as context
    if Assigned(Owner) then
      BasePrompt := BasePrompt + sLineBreak + FPromptBuilder.BuildFromOwner(Owner);
  end;
  
  FChatGPT.Dev := BasePrompt;
  
  // Apply to Project
  if Assigned(FProject) then
  begin
    FProject.ChatGPT := FChatGPT;
    FProject.SafeMode := FSafeMode;
    FProject.SimulationMode := FSimulationMode;
    FProject.LocalURL := FLocalURL;
    FProject.DefaultProvider := FChatGPT.Provider;
    FProject.DefaultModel := FChatGPT.CustomModel;
    FProject.Initialize;
  end;
  
  // Apply to Pipeline
  if Assigned(FPipeline) then
  begin
    FPipeline.ChatGPT := FChatGPT;
    if FProjectType = 'chatbot' then FPipeline.Mode := pmTextLLM
    else if FProjectType = 'classificador GraphMap' then FPipeline.Mode := pmGraphMapClassification
    else if FProjectType = 'pipeline textual' then FPipeline.Mode := pmTextLLM
    else if FProjectType = 'pipeline documento' then FPipeline.Mode := pmDocumentGeneration
    else if FProjectType = 'agente seguro' then FPipeline.Mode := pmAgentAction
    else if FProjectType = 'monitor industrial' then FPipeline.Mode := pmIndustrialMonitor
    else if FProjectType = 'exportador de treinamento' then FPipeline.Mode := pmTextLLM;
  end;
  
  FLastResult := 'Configurações do Wizard aplicadas com sucesso.';
  FLastSuccess := True;
  Log(llInfo, FLastResult);
end;

function TAIWizardConfig.TestConnection: Boolean;
begin
  Result := False;
  ClearError;
  if not Assigned(FChatGPT) then
  begin
    SetError('ChatGPT component must be assigned for connection testing.');
    Exit;
  end;
  
  Log(llInfo, 'Testando conexão através do ChatGPT.');
  if FSimulationMode then
  begin
    FLastResult := 'Simulado: Conexão bem-sucedida!';
    FLastSuccess := True;
    Log(llInfo, FLastResult);
    Result := True;
    Exit;
  end;
  
  // Apply settings to ensure updated state
  Apply;
  
  Result := FChatGPT.SendQuestion('Olá. Responda estritamente com OK se receber isto.');
  if Result then
  begin
    FLastResult := 'Conexão bem-sucedida. Resposta: ' + FChatGPT.Response;
    FLastSuccess := True;
    Log(llInfo, FLastResult);
  end
  else
  begin
    SetError('Falha no teste de conexão: ' + FChatGPT.LastError);
  end;
end;

procedure TAIWizardConfig.SaveToFile(const AFileName: string);
var
  LRoot: TJSONObject;
  LList: TStringList;
begin
  ClearError;
  LRoot := TJSONObject.Create;
  LList := TStringList.Create;
  try
    LRoot.Add('projectType', FProjectType);
    LRoot.Add('providerName', FProviderName);
    LRoot.Add('modelName', FModelName);
    LRoot.Add('localURL', FLocalURL);
    LRoot.Add('safeMode', FSafeMode);
    LRoot.Add('simulationMode', FSimulationMode);
    
    LList.Text := LRoot.AsJSON;
    LList.SaveToFile(AFileName);
    
    FLastResult := 'Configurações salvas em: ' + AFileName;
    FLastSuccess := True;
    Log(llInfo, FLastResult);
  finally
    LList.Free;
    LRoot.Free;
  end;
end;

procedure TAIWizardConfig.LoadFromFile(const AFileName: string);
var
  LList: TStringList;
  LData: TJSONData;
  LRoot: TJSONObject;
begin
  ClearError;
  if not FileExists(AFileName) then
  begin
    SetError('Arquivo não existe: ' + AFileName);
    Exit;
  end;
  
  LList := TStringList.Create;
  try
    LList.LoadFromFile(AFileName);
    LData := GetJSON(LList.Text);
    try
      if LData.JSONType = jtObject then
      begin
        LRoot := TJSONObject(LData);
        if LRoot.IndexOfName('projectType') >= 0 then FProjectType := LRoot.Strings['projectType'];
        if LRoot.IndexOfName('providerName') >= 0 then FProviderName := LRoot.Strings['providerName'];
        if LRoot.IndexOfName('modelName') >= 0 then FModelName := LRoot.Strings['modelName'];
        if LRoot.IndexOfName('localURL') >= 0 then FLocalURL := LRoot.Strings['localURL'];
        if LRoot.IndexOfName('safeMode') >= 0 then FSafeMode := LRoot.Booleans['safeMode'];
        if LRoot.IndexOfName('simulationMode') >= 0 then FSimulationMode := LRoot.Booleans['simulationMode'];
        
        // Auto-apply loaded settings
        Apply;
        
        FLastResult := 'Configurações carregadas de: ' + AFileName;
        FLastSuccess := True;
        Log(llInfo, FLastResult);
      end;
    finally
      LData.Free;
    end;
  finally
    LList.Free;
  end;
end;

initialization
  {$I aiwizardconfig_icon.lrs}

end.
