unit aiagent;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, chatgpt, fpjson, jsonparser;

type
  TAIAgentAction = class;
  TAIAgentOptions = class;

  { TAgentActionEvent }
  TAgentActionEvent = procedure(Sender: TObject; const AActionName: string; AParams: TStrings) of object;

  { TAIAgentOptions }

  TAIAgentOptions = class(TComponent)
  private
    FQuestions: TStrings;
    FContext: string;
    FAction: TAIAgentAction;
    procedure SetQuestions(AValue: TStrings);
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  published
    property Questions: TStrings read FQuestions write SetQuestions;
    property Context: string read FContext write FContext;
    property Action: TAIAgentAction read FAction write FAction;
  end;

  { TAIAgentAction }

  TAIAgentAction = class(TComponent)
  private
    FAllowedActions: TStrings;
    FParameterDefinitions: TStrings;
    FSelectedAction: string;
    FSelectedParameters: TStrings;
    FOnExecuteAction: TAgentActionEvent;
    procedure SetAllowedActions(AValue: TStrings);
    procedure SetParameterDefinitions(AValue: TStrings);
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure ClearSelection;
    function GetParamValue(const AName: string): string;
    procedure TriggerAction(const AActionName: string; AParams: TStrings);
  published
    property AllowedActions: TStrings read FAllowedActions write SetAllowedActions;
    property ParameterDefinitions: TStrings read FParameterDefinitions write SetParameterDefinitions;
    property SelectedAction: string read FSelectedAction write FSelectedAction;
    property SelectedParameters: TStrings read FSelectedParameters write FSelectedParameters;
    property OnExecuteAction: TAgentActionEvent read FOnExecuteAction write FOnExecuteAction;
  end;

  { TAIAgent }

  TAIAgent = class(TComponent)
  private
    FChatGPT: TCHATGPT;
    FOptions: TAIAgentOptions;
    FAction: TAIAgentAction;
    FSystemPrompt: string;
    FLastError: string;
    FLastRationale: string;
    FOnActionTriggered: TAgentActionEvent;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    function Execute(const AInputData: string): Boolean;
  published
    property ChatGPT: TCHATGPT read FChatGPT write FChatGPT;
    property Options: TAIAgentOptions read FOptions write FOptions;
    property Action: TAIAgentAction read FAction write FAction;
    property SystemPrompt: string read FSystemPrompt write FSystemPrompt;
    property LastError: string read FLastError;
    property LastRationale: string read FLastRationale;
    property OnActionTriggered: TAgentActionEvent read FOnActionTriggered write FOnActionTriggered;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('IA Agent', [TAIAgent, TAIAgentOptions, TAIAgentAction]);
end;

{ TAIAgentOptions }

constructor TAIAgentOptions.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FQuestions := TStringList.Create;
  FContext := '';
  FAction := nil;
end;

destructor TAIAgentOptions.Destroy;
begin
  FQuestions.Free;
  inherited Destroy;
end;

procedure TAIAgentOptions.SetQuestions(AValue: TStrings);
begin
  FQuestions.Assign(AValue);
end;

{ TAIAgentAction }

constructor TAIAgentAction.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FAllowedActions := TStringList.Create;
  FParameterDefinitions := TStringList.Create;
  FSelectedAction := '';
  FSelectedParameters := TStringList.Create;
  FOnExecuteAction := nil;
end;

destructor TAIAgentAction.Destroy;
begin
  FAllowedActions.Free;
  FParameterDefinitions.Free;
  FSelectedParameters.Free;
  inherited Destroy;
end;

procedure TAIAgentAction.SetAllowedActions(AValue: TStrings);
begin
  FAllowedActions.Assign(AValue);
end;

procedure TAIAgentAction.SetParameterDefinitions(AValue: TStrings);
begin
  FParameterDefinitions.Assign(AValue);
end;

procedure TAIAgentAction.ClearSelection;
begin
  FSelectedAction := '';
  FSelectedParameters.Clear;
end;

function TAIAgentAction.GetParamValue(const AName: string): string;
begin
  Result := FSelectedParameters.Values[AName];
end;

procedure TAIAgentAction.TriggerAction(const AActionName: string; AParams: TStrings);
begin
  if Assigned(FOnExecuteAction) then
    FOnExecuteAction(Self, AActionName, AParams);
end;

{ TAIAgent }

constructor TAIAgent.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FChatGPT := nil;
  FOptions := nil;
  FAction := nil;
  FSystemPrompt := '';
  FLastError := '';
  FLastRationale := '';
  FOnActionTriggered := nil;
end;

destructor TAIAgent.Destroy;
begin
  inherited Destroy;
end;

function TAIAgent.Execute(const AInputData: string): Boolean;
var
  Prompt: string;
  QuestionsText: string;
  ActionsText: string;
  ParamsText: string;
  I: Integer;
  JSONData: TJSONData;
  JSONObject: TJSONObject;
  JSONParams: TJSONObject;
  ActionName: string;
  ParamName: string;
  ParamValue: string;
begin
  Result := False;
  FLastError := '';
  FLastRationale := '';

  if not Assigned(FChatGPT) then
  begin
    FLastError := 'Componente TCHATGPT não está associado ao Agente.';
    Exit;
  end;

  // Build questions/directs list
  QuestionsText := '';
  if Assigned(FOptions) and Assigned(FOptions.Questions) then
  begin
    for I := 0 to FOptions.Questions.Count - 1 do
      QuestionsText := QuestionsText + ' - ' + FOptions.Questions[I] + sLineBreak;
  end;

  // Build actions list and params
  ActionsText := '';
  ParamsText := '';
  if Assigned(FAction) then
  begin
    if Assigned(FAction.AllowedActions) then
    begin
      for I := 0 to FAction.AllowedActions.Count - 1 do
        ActionsText := ActionsText + ' - ' + FAction.AllowedActions[I] + sLineBreak;
    end;
    if Assigned(FAction.ParameterDefinitions) then
    begin
      for I := 0 to FAction.ParameterDefinitions.Count - 1 do
        ParamsText := ParamsText + ' - ' + FAction.ParameterDefinitions[I] + sLineBreak;
    end;
  end;

  // 1. Build detailed Agent System instructions
  Prompt := 'Você é um Agente Inteligente Autônomo.' + sLineBreak;
  if FSystemPrompt <> '' then
    Prompt := Prompt + FSystemPrompt + sLineBreak;

  Prompt := Prompt + sLineBreak + '=== DADOS DE ENTRADA A ANALISAR ===' + sLineBreak;
  Prompt := Prompt + AInputData + sLineBreak;

  if QuestionsText <> '' then
  begin
    Prompt := Prompt + sLineBreak + '=== PERGUNTAS E DIRETRIZES DE ANÁLISE ===' + sLineBreak;
    Prompt := Prompt + QuestionsText;
  end;

  if (FOptions <> nil) and (FOptions.Context <> '') then
  begin
    Prompt := Prompt + sLineBreak + '=== CONTEXTO ADICIONAL ===' + sLineBreak;
    Prompt := Prompt + FOptions.Context + sLineBreak;
  end;

  Prompt := Prompt + sLineBreak + '=== AÇÕES DISPONÍVEIS NO MUNDO EXTERNO ===' + sLineBreak;
  if ActionsText <> '' then
    Prompt := Prompt + ActionsText
  else
    Prompt := Prompt + ' - Nenhuma ação permitida (retorne ação vazia)' + sLineBreak;

  if ParamsText <> '' then
  begin
    Prompt := Prompt + sLineBreak + '=== DIRETRIZES DE PARÂMETROS PARA AS AÇÕES ===' + sLineBreak;
    Prompt := Prompt + ParamsText;
  end;

  Prompt := Prompt + sLineBreak + '=== INSTRUÇÕES CRÍTICAS DE RETORNO ===' + sLineBreak;
  Prompt := Prompt + 'Você DEVE analisar os dados e decidir por exatamente UMA ação aplicável entre as listadas.' + sLineBreak;
  Prompt := Prompt + 'Você DEVE fornecer exatamente os parâmetros definidos correspondentes a essa ação.' + sLineBreak;
  Prompt := Prompt + 'Você DEVE retornar a sua resposta EXCLUSIVAMENTE em formato JSON, sem crases, blocos de markdown ou outro texto envolvente. O JSON deve seguir precisamente esta estrutura:' + sLineBreak;
  Prompt := Prompt + '{' + sLineBreak;
  Prompt := Prompt + '  "action": "nome_da_acao_escolhida",' + sLineBreak;
  Prompt := Prompt + '  "parameters": {' + sLineBreak;
  Prompt := Prompt + '    "nome_parametro1": "valor1",' + sLineBreak;
  Prompt := Prompt + '    "nome_parametro2": "valor2"' + sLineBreak;
  Prompt := Prompt + '  },' + sLineBreak;
  Prompt := Prompt + '  "rationale": "sua justificativa e raciocínio analítico aqui"' + sLineBreak;
  Prompt := Prompt + '}' + sLineBreak;

  // Send to ChatGPT conector
  if not FChatGPT.SendQuestion(Prompt) then
  begin
    FLastError := 'Falha na requisição ao ChatGPT: ' + FChatGPT.Response;
    Exit;
  end;

  // Parse JSON
  try
    JSONData := GetJSON(FChatGPT.Response);
    try
      if JSONData.JSONType = jtObject then
      begin
        JSONObject := TJSONObject(JSONData);
        
        ActionName := '';
        if JSONObject.IndexOfName('action') >= 0 then
          ActionName := JSONObject.Strings['action'];
        
        if JSONObject.IndexOfName('rationale') >= 0 then
          FLastRationale := JSONObject.Strings['rationale'];

        if Assigned(FAction) then
        begin
          FAction.SelectedAction := ActionName;
          FAction.SelectedParameters.Clear;

          if JSONObject.IndexOfName('parameters') >= 0 then
          begin
            JSONParams := JSONObject.Objects['parameters'];
            if Assigned(JSONParams) then
            begin
              for I := 0 to JSONParams.Count - 1 do
              begin
                ParamName := JSONParams.Names[I];
                ParamValue := JSONParams.Items[I].AsString;
                FAction.SelectedParameters.Add(ParamName + '=' + ParamValue);
              end;
            end;
          end;

          // Trigger callbacks
          FAction.TriggerAction(ActionName, FAction.SelectedParameters);
          if Assigned(FOnActionTriggered) then
            FOnActionTriggered(Self, ActionName, FAction.SelectedParameters);
        end;
        
        Result := True;
      end
      else
      begin
        FLastError := 'Resposta retornada não é um objeto JSON válido. Resposta: ' + FChatGPT.Response;
      end;
    finally
      JSONData.Free;
    end;
  except
    on E: Exception do
      FLastError := 'Erro ao fazer parsing do retorno JSON do Agente: ' + E.Message + ' | Resposta: ' + FChatGPT.Response;
  end;
end;

end.
