unit aiagent;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, chatgpt, fpjson, jsonparser, fphttpclient, TypInfo,
  aibase, aiagentsafety,
  // AI Input components
  aiaudio, aiwebserver, aisockets, aiserial, aiposprinter,
  aimodbus, aimqtt, aiemail, aimessenger, aiindustrial, aichromiumbrowser,
  aicapturesource, aiinput,
  // AI Output components
  aioutput, aioutput_docs, LResources, aiagent_executors;

type
  TAIAgentAction = class;
  TAIAgentOptions = class;
  TAIAgentResource = class;

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

  { TAIAgentDecision }

  TAIAgentDecision = class
  public
    ActionName: string;
    Parameters: TStrings;
    Rationale: string;
    RawJSON: string;
    constructor Create;
    destructor Destroy; override;
  end;

  { TAIAgent }

  TAIAgent = class(TAIBaseComponent)
  private
    FChatGPT: TCHATGPT;
    FOptions: TAIAgentOptions;
    FAction: TAIAgentAction;
    FResource: TAIAgentResource;
    FSystemPrompt: string;
    FLastRationale: string;
    FOnActionTriggered: TAgentActionEvent;
    FMemory: TStrings;
    FMaxMemoryLimit: Integer;
    FMaxRetries: Integer;
    FSafety: TAIAgentSafety;
    FLastDecision: TAIAgentDecision;
    procedure SetMemory(AValue: TStrings);
    procedure SetSafety(AValue: TAIAgentSafety);
  protected
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    function Execute(const AInputData: string): Boolean;
    procedure ClearMemory;
  published
    property ChatGPT: TCHATGPT read FChatGPT write FChatGPT;
    property Options: TAIAgentOptions read FOptions write FOptions;
    property Action: TAIAgentAction read FAction write FAction;
    property Resource: TAIAgentResource read FResource write FResource;
    property Safety: TAIAgentSafety read FSafety write SetSafety;
    property SystemPrompt: string read FSystemPrompt write FSystemPrompt;
    property LastRationale: string read FLastRationale;
    property Memory: TStrings read FMemory write SetMemory;
    property MaxMemoryLimit: Integer read FMaxMemoryLimit write FMaxMemoryLimit;
    property MaxRetries: Integer read FMaxRetries write FMaxRetries;
    property OnActionTriggered: TAgentActionEvent read FOnActionTriggered write FOnActionTriggered;
    property LastDecision: TAIAgentDecision read FLastDecision;
  end;

  { TAIAgentResource }

  TAIAgentResourceType = (
    artEmail,
    artFile,
    artWhatsApp,
    artSMS,
    artTCP,
    artUDP,
    artWebAPI,
    artCustom
  );

  TAIAgentResourceItem = class(TCollectionItem)
  private
    FName: string;
    FResourceType: TAIAgentResourceType;
    FHost: string;
    FPort: Integer;
    FSender: string;
    FRecipient: string;
    FSubject: string;
    FFilePath: string;
    FAPIUrl: string;
    FHeaders: TStrings;
    FConfig: TStrings;
    FComponent: TComponent;
    FAllowedProperties: TStrings;
    FBlockedProperties: TStrings;
    procedure SetHeaders(AValue: TStrings);
    procedure SetConfig(AValue: TStrings);
    procedure SetComponent(AValue: TComponent);
    procedure SetAllowedProperties(AValue: TStrings);
    procedure SetBlockedProperties(AValue: TStrings);
  public
    constructor Create(ACollection: TCollection); override;
    destructor Destroy; override;
    function Execute(const AData: string; AParams: TStrings; out ALog: string): Boolean;
  published
    property Name: string read FName write FName;
    property ResourceType: TAIAgentResourceType read FResourceType write FResourceType;
    property Host: string read FHost write FHost;
    property Port: Integer read FPort write FPort;
    property Sender: string read FSender write FSender;
    property Recipient: string read FRecipient write FRecipient;
    property Subject: string read FSubject write FSubject;
    property FilePath: string read FFilePath write FFilePath;
    property APIUrl: string read FAPIUrl write FAPIUrl;
    property Headers: TStrings read FHeaders write SetHeaders;
    property Config: TStrings read FConfig write SetConfig;
    property Component: TComponent read FComponent write SetComponent;
    property AllowedProperties: TStrings read FAllowedProperties write SetAllowedProperties;
    property BlockedProperties: TStrings read FBlockedProperties write SetBlockedProperties;
  end;

  { TAIAgentResourceCollection }

  TAIAgentResourceCollection = class(TCollection)
  private
    FOwnerComponent: TComponent;
    function GetItem(Index: Integer): TAIAgentResourceItem;
    procedure SetItem(Index: Integer; Value: TAIAgentResourceItem);
  protected
    function GetOwner: TPersistent; override;
  public
    constructor Create(AOwner: TComponent);
    function Add: TAIAgentResourceItem;
    property Items[Index: Integer]: TAIAgentResourceItem read GetItem write SetItem; default;
  end;

  TAIAgentResource = class(TComponent)
  private
    FResources: TAIAgentResourceCollection;
    procedure SetResources(AValue: TAIAgentResourceCollection);
  protected
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    function FindResource(const AName: string): TAIAgentResourceItem;
  published
    property Resources: TAIAgentResourceCollection read FResources write SetResources;
  end;

  { TAIAgentOutputMapping }

  TAIAgentOutputMapping = class(TCollectionItem)
  private
    FActionName: string;
    FResourceName: string;
  published
    property ActionName: string read FActionName write FActionName;
    property ResourceName: string read FResourceName write FResourceName;
  end;

  { TAIAgentOutputMappingCollection }

  TAIAgentOutputMappingCollection = class(TCollection)
  private
    FOwnerComponent: TComponent;
    function GetItem(Index: Integer): TAIAgentOutputMapping;
    procedure SetItem(Index: Integer; Value: TAIAgentOutputMapping);
  protected
    function GetOwner: TPersistent; override;
  public
    constructor Create(AOwner: TComponent);
    function Add: TAIAgentOutputMapping;
    property Items[Index: Integer]: TAIAgentOutputMapping read GetItem write SetItem; default;
  end;

  { TAIAgentOutputEvent }
  TAIAgentOutputEvent = procedure(Sender: TObject; const AActionName: string; const AResourceName: string; const ALog: string; ASuccess: Boolean) of object;

  { TAIAgentOutput }

  TAIAgentOutput = class(TComponent)
  private
    FAction: TAIAgentAction;
    FResource: TAIAgentResource;
    FMappings: TAIAgentOutputMappingCollection;
    FOnOutputExecuted: TAIAgentOutputEvent;
    FLastExecutionLog: string;
    FPrevOnExecuteAction: TAgentActionEvent;
    FIsHooked: Boolean;
    procedure SetMappings(AValue: TAIAgentOutputMappingCollection);
    procedure SetAction(AValue: TAIAgentAction);
    procedure SetResource(AValue: TAIAgentResource);
    procedure HookAction;
    procedure UnhookAction;
    procedure DoExecuteAction(Sender: TObject; const AActionName: string; AParams: TStrings);
  protected
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    function ExecuteAction(const AActionName: string; AParams: TStrings): Boolean; reintroduce;
  published
    property Action: TAIAgentAction read FAction write SetAction;
    property Resource: TAIAgentResource read FResource write SetResource;
    property Mappings: TAIAgentOutputMappingCollection read FMappings write SetMappings;
    property LastExecutionLog: string read FLastExecutionLog write FLastExecutionLog;
    property OnOutputExecuted: TAIAgentOutputEvent read FOnOutputExecuted write FOnOutputExecuted;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('AI Agents', [TAIAgent, TAIAgentOptions, TAIAgentAction, TAIAgentResource, TAIAgentOutput]);
end;

{ TAIAgentDecision }

constructor TAIAgentDecision.Create;
begin
  inherited Create;
  Parameters := TStringList.Create;
  ActionName := '';
  Rationale := '';
  RawJSON := '';
end;

destructor TAIAgentDecision.Destroy;
begin
  Parameters.Free;
  inherited Destroy;
end;

function GetPropString(AComponent: TComponent; const APropName: string): string;
var
  PropInfo: PPropInfo;
begin
  Result := '';
  if not Assigned(AComponent) then Exit;
  PropInfo := GetPropInfo(AComponent, APropName);
  if PropInfo <> nil then
    Result := GetStrProp(AComponent, PropInfo);
end;

procedure SetPropValueByName(AComponent: TComponent; const APropName: string; const AValue: string);
var
  PropInfo: PPropInfo;
begin
  if not Assigned(AComponent) then Exit;
  PropInfo := GetPropInfo(AComponent, APropName);
  if PropInfo = nil then Exit;
  
  case PropInfo^.PropType^.Kind of
    tkInteger: SetOrdProp(AComponent, PropInfo, StrToIntDef(AValue, 0));
    tkBool: SetOrdProp(AComponent, PropInfo, Ord(SameText(AValue, 'True') or (AValue = '1')));
    tkFloat: SetFloatProp(AComponent, PropInfo, StrToFloatDef(AValue, 0.0));
    tkAString, tkUString, tkSString: SetStrProp(AComponent, PropInfo, AValue);
  end;
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
  FCategory := ccAction;
  FChatGPT := nil;
  FOptions := nil;
  FAction := nil;
  FResource := nil;
  FSystemPrompt := '';
  FLastRationale := '';
  FMemory := TStringList.Create;
  FMaxMemoryLimit := 20;
  FMaxRetries := 3;
  FOnActionTriggered := nil;
  FSafety := nil;
  FLastDecision := TAIAgentDecision.Create;
end;

destructor TAIAgent.Destroy;
begin
  FMemory.Free;
  FLastDecision.Free;
  inherited Destroy;
end;

procedure TAIAgent.SetMemory(AValue: TStrings);
begin
  FMemory.Assign(AValue);
end;

procedure TAIAgent.SetSafety(AValue: TAIAgentSafety);
begin
  if FSafety <> AValue then
  begin
    FSafety := AValue;
    if FSafety <> nil then
      FSafety.FreeNotification(Self);
  end;
end;

procedure TAIAgent.Notification(AComponent: TComponent; Operation: TOperation);
begin
  inherited Notification(AComponent, Operation);
  if Operation = opRemove then
  begin
    if AComponent = FChatGPT then FChatGPT := nil;
    if AComponent = FOptions then FOptions := nil;
    if AComponent = FAction then FAction := nil;
    if AComponent = FResource then FResource := nil;
    if AComponent = FSafety then FSafety := nil;
  end;
end;

procedure TAIAgent.ClearMemory;
begin
  FMemory.Clear;
end;

function TAIAgent.Execute(const AInputData: string): Boolean;
var
  LPrompt: string;
  QuestionsText: string;
  ActionsText: string;
  ParamsText: string;
  MemoryText: string;
  I: Integer;
  JSONData: TJSONData;
  JSONObject: TJSONObject;
  JSONParams: TJSONObject;
  ActionName: string;
  ParamName: string;
  ParamValue: string;
  RetryCount: Integer;
  ParsedSuccessfully: Boolean;
  CurrentPrompt: string;
  CompPrompt: string;
  Err: string;
begin
  Result := False;
  ClearError;
  FLastRationale := '';
  
  FLastDecision.ActionName := '';
  FLastDecision.Parameters.Clear;
  FLastDecision.Rationale := '';
  FLastDecision.RawJSON := '';

  if not Assigned(FChatGPT) then
  begin
    SetError('Componente TCHATGPT não está associado ao Agente.');
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

  // Build memory text
  MemoryText := '';
  if FMemory.Count > 0 then
  begin
    MemoryText := sLineBreak + '=== HISTÓRICO DE MENSAGENS ANTERIORES (MEMÓRIA CONVERSACIONAL) ===' + sLineBreak;
    for I := 0 to FMemory.Count - 1 do
      MemoryText := MemoryText + FMemory[I] + sLineBreak;
  end;

  // 1. Build detailed Agent System instructions
  LPrompt := 'Você é um Agente Inteligente Autônomo.' + sLineBreak;
  if FSystemPrompt <> '' then
    LPrompt := LPrompt + FSystemPrompt + sLineBreak;

  LPrompt := LPrompt + sLineBreak + '=== DADOS DE ENTRADA A ANALISAR ===' + sLineBreak;
  LPrompt := LPrompt + AInputData + sLineBreak;

  if MemoryText <> '' then
    LPrompt := LPrompt + MemoryText;

  if QuestionsText <> '' then
  begin
    LPrompt := LPrompt + sLineBreak + '=== PERGUNTAS E DIRETRIZES DE ANÁLISE ===' + sLineBreak;
    LPrompt := LPrompt + QuestionsText;
  end;

  if (FOptions <> nil) and (FOptions.Context <> '') then
  begin
    LPrompt := LPrompt + sLineBreak + '=== CONTEXTO ADICIONAL ===' + sLineBreak;
    LPrompt := LPrompt + FOptions.Context + sLineBreak;
  end;

  LPrompt := LPrompt + sLineBreak + '=== AÇÕES DISPONÍVEIS NO MUNDO EXTERNO ===' + sLineBreak;
  if ActionsText <> '' then
    LPrompt := LPrompt + ActionsText
  else
    LPrompt := LPrompt + ' - Nenhuma ação permitida (retorne ação vazia)' + sLineBreak;

  if ParamsText <> '' then
  begin
    LPrompt := LPrompt + sLineBreak + '=== DIRETRIZES DE PARÂMETROS PARA AS AÇÕES ===' + sLineBreak;
    LPrompt := LPrompt + ParamsText;
  end;

  // Build and append resources and their prompts
  if Assigned(FResource) and (FResource.Resources.Count > 0) then
  begin
    LPrompt := LPrompt + sLineBreak + '=== RECURSOS E DISPOSITIVOS FÍSICOS DISPONÍVEIS (IA INPUT / IA OUTPUT) ===' + sLineBreak;
    for I := 0 to FResource.Resources.Count - 1 do
    begin
      LPrompt := LPrompt + 'Recurso: "' + FResource.Resources[I].Name + '"' + sLineBreak;
      if Assigned(FResource.Resources[I].Component) then
      begin
        CompPrompt := GetPropString(FResource.Resources[I].Component, 'Prompt');
        if CompPrompt <> '' then
          LPrompt := LPrompt + '  Orientação de IA: ' + CompPrompt + sLineBreak
        else
          LPrompt := LPrompt + '  Orientação de IA: Componente conectado ' + FResource.Resources[I].Component.ClassName + sLineBreak;
      end
      else
        LPrompt := LPrompt + '  Tipo Físico: ' + GetEnumName(TypeInfo(TAIAgentResourceType), Ord(FResource.Resources[I].ResourceType)) + sLineBreak;
        
      LPrompt := LPrompt + '  Configuração Padrão:' + sLineBreak;
      if FResource.Resources[I].Recipient <> '' then LPrompt := LPrompt + '    Recipient: ' + FResource.Resources[I].Recipient + sLineBreak;
      if FResource.Resources[I].Sender <> '' then LPrompt := LPrompt + '    Sender: ' + FResource.Resources[I].Sender + sLineBreak;
      if FResource.Resources[I].Subject <> '' then LPrompt := LPrompt + '    Subject: ' + FResource.Resources[I].Subject + sLineBreak;
      if FResource.Resources[I].Host <> '' then LPrompt := LPrompt + '    Host: ' + FResource.Resources[I].Host + sLineBreak;
      if FResource.Resources[I].Port <> 0 then LPrompt := LPrompt + '    Port: ' + IntToStr(FResource.Resources[I].Port) + sLineBreak;
      if FResource.Resources[I].FilePath <> '' then LPrompt := LPrompt + '    FilePath: ' + FResource.Resources[I].FilePath + sLineBreak;
      if FResource.Resources[I].APIUrl <> '' then LPrompt := LPrompt + '    APIUrl: ' + FResource.Resources[I].APIUrl + sLineBreak;
      LPrompt := LPrompt + sLineBreak;
    end;
    
    LPrompt := LPrompt + 'Você pode definir ou alterar qualquer um destes parâmetros em sua resposta JSON na seção "parameters".' + sLineBreak;
  end;

  LPrompt := LPrompt + sLineBreak + '=== INSTRUÇÕES CRÍTICAS DE RETORNO ===' + sLineBreak;
  LPrompt := LPrompt + 'Você DEVE analisar os dados e decidir por exatamente UMA ação aplicável entre as listadas.' + sLineBreak;
  LPrompt := LPrompt + 'Você DEVE fornecer exatamente os parâmetros definidos correspondentes a essa ação.' + sLineBreak;
  LPrompt := LPrompt + 'Você DEVE retornar a sua resposta EXCLUSIVAMENTE em formato JSON, sem crases, blocos de markdown ou outro texto envolvente. O JSON deve seguir precisamente esta estrutura:' + sLineBreak;
  LPrompt := LPrompt + '{' + sLineBreak;
  LPrompt := LPrompt + '  "action": "nome_da_acao_escolhida",' + sLineBreak;
  LPrompt := LPrompt + '  "parameters": {' + sLineBreak;
  LPrompt := LPrompt + '    "nome_parametro1": "valor1",' + sLineBreak;
  LPrompt := LPrompt + '    "nome_parametro2": "valor2"' + sLineBreak;
  LPrompt := LPrompt + '  },' + sLineBreak;
  LPrompt := LPrompt + '  "rationale": "sua justificativa e raciocínio analítico aqui"' + sLineBreak;
  LPrompt := LPrompt + '}' + sLineBreak;

  RetryCount := 0;
  ParsedSuccessfully := False;
  CurrentPrompt := LPrompt;

  // 2. Execute Loop with Self-Correction / Critic
  while (RetryCount < FMaxRetries) and not ParsedSuccessfully do
  begin
    if not FChatGPT.SendQuestion(CurrentPrompt) then
    begin
      SetError('Falha na requisição ao ChatGPT: ' + FChatGPT.Response);
      Inc(RetryCount);
      Continue;
    end;

    // Parse JSON Response
    try
      JSONData := GetJSON(FChatGPT.Response);
      try
        if JSONData.JSONType = jtObject then
        begin
          JSONObject := TJSONObject(JSONData);
          
          ActionName := '';
          if JSONObject.IndexOfName('action') >= 0 then
            ActionName := JSONObject.Strings['action'];
          
          // Validate Action Name against Allowed Actions
          if Assigned(FAction) and (FAction.AllowedActions.Count > 0) and (ActionName <> '') then
          begin
            if FAction.AllowedActions.IndexOf(ActionName) < 0 then
            begin
              // Action is not in allowed list! Trigger retry loop with correction warning
              CurrentPrompt := LPrompt + sLineBreak + sLineBreak +
                               'WARNING: Você retornou a ação "' + ActionName + '" na tentativa anterior, o que NÃO é permitido.' + sLineBreak +
                               'As ÚNICAS ações permitidas são:' + sLineBreak + ActionsText + sLineBreak +
                               'Por favor, refaça sua análise e selecione estritamente uma ação válida listada acima em formato JSON.';
              Inc(RetryCount);
              Continue;
            end;
          end;

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

            // Security Validation Layer
            if Assigned(FSafety) then
            begin
              if not FSafety.ValidateAction(ActionName, FAction.SelectedParameters, Err) then
              begin
                SetError(Err);
                Exit(False);
              end;
            end;

            // Trigger callbacks
            FAction.TriggerAction(ActionName, FAction.SelectedParameters);
            if Assigned(FOnActionTriggered) then
              FOnActionTriggered(Self, ActionName, FAction.SelectedParameters);
          end;
          
          // Populate LastDecision
          FLastDecision.ActionName := ActionName;
          if Assigned(FAction) then
            FLastDecision.Parameters.Assign(FAction.SelectedParameters)
          else
            FLastDecision.Parameters.Clear;
          FLastDecision.Rationale := FLastRationale;
          FLastDecision.RawJSON := FChatGPT.Response;

          // Add to short-term Memory
          FMemory.Add('User: ' + AInputData);
          FMemory.Add('Jarvis: Action=' + ActionName + ' | Rationale=' + FLastRationale);
          
          // Check memory limit
          while FMemory.Count > FMaxMemoryLimit do
            FMemory.Delete(0);

          ParsedSuccessfully := True;
          Result := True;
        end
        else
        begin
          CurrentPrompt := LPrompt + sLineBreak + sLineBreak +
                           'WARNING: A resposta anterior não foi um objeto JSON válido.' + sLineBreak +
                           'Por favor, retorne a resposta estritamente formatada no JSON correto.';
          Inc(RetryCount);
        end;
      finally
        JSONData.Free;
      end;
    except
      on E: Exception do
      begin
        SetError('Erro no parser: ' + E.Message + ' | Tentativa: ' + IntToStr(RetryCount + 1));
        CurrentPrompt := LPrompt + sLineBreak + sLineBreak +
                         'WARNING: Ocorreu um erro no parsing do JSON retornado: ' + E.Message + sLineBreak +
                         'Por favor, certifique-se de retornar EXCLUSIVAMENTE o JSON estruturado correto, sem blocos de código markdown ou crases.';
        Inc(RetryCount);
      end;
    end;
  end;

  if not ParsedSuccessfully and (FLastError = '') then
    SetError('Excedeu o número máximo de tentativas de auto-correção do Agente.');
end;

{ TAIAgentResourceItem }

constructor TAIAgentResourceItem.Create(ACollection: TCollection);
begin
  inherited Create(ACollection);
  FResourceType := artEmail;
  FPort := 0;
  FHeaders := TStringList.Create;
  FConfig := TStringList.Create;
  FComponent := nil;
  FAllowedProperties := TStringList.Create;
  FBlockedProperties := TStringList.Create;
  FBlockedProperties.Add('Token');
  FBlockedProperties.Add('Password');
  FBlockedProperties.Add('APIKey');
  FBlockedProperties.Add('Secret');
  FBlockedProperties.Add('PrivateKey');
  FBlockedProperties.Add('LibraryPath');
end;

destructor TAIAgentResourceItem.Destroy;
begin
  FHeaders.Free;
  FConfig.Free;
  FAllowedProperties.Free;
  FBlockedProperties.Free;
  inherited Destroy;
end;

procedure TAIAgentResourceItem.SetHeaders(AValue: TStrings);
begin
  FHeaders.Assign(AValue);
end;

procedure TAIAgentResourceItem.SetConfig(AValue: TStrings);
begin
  FConfig.Assign(AValue);
end;

procedure TAIAgentResourceItem.SetAllowedProperties(AValue: TStrings);
begin
  FAllowedProperties.Assign(AValue);
end;

procedure TAIAgentResourceItem.SetBlockedProperties(AValue: TStrings);
begin
  FBlockedProperties.Assign(AValue);
end;



procedure TAIAgentResourceItem.SetComponent(AValue: TComponent);
var
  Coll: TAIAgentResourceCollection;
begin
  if FComponent <> AValue then
  begin
    FComponent := AValue;
    if (FComponent <> nil) and (Collection is TAIAgentResourceCollection) then
    begin
      Coll := TAIAgentResourceCollection(Collection);
      if Assigned(Coll.FOwnerComponent) then
        FComponent.FreeNotification(Coll.FOwnerComponent);
    end;
  end;
end;

function TAIAgentResourceItem.Execute(const AData: string; AParams: TStrings; out ALog: string): Boolean;
var
  HTTPClient: TFPHttpClient;
  RequestBodyStream: TStringStream;
  ResponseText: string;
  I: Integer;
  VRecipient: string;
  VSender: string;
  VSubject: string;
  VFilePath: string;
  VHost: string;
  VPort: Integer;
  VAPIUrl: string;
  VKey, VVal: string;
  CompPrompt: string;
begin
  Result := False;
  ALog := '';
  
  if Assigned(FComponent) then
  begin
    // 1. Injetar parâmetros resolvidos pela IA nas propriedades correspondentes do componente via RTTI
    if Assigned(AParams) then
    begin
      for I := 0 to AParams.Count - 1 do
      begin
        VKey := AParams.Names[I];
        VVal := AParams.ValueFromIndex[I];
        if VKey <> '' then
        begin
          if FBlockedProperties.IndexOf(VKey) >= 0 then Continue;
          if (FAllowedProperties.Count > 0) and (FAllowedProperties.IndexOf(VKey) < 0) then Continue;
          SetPropValueByName(FComponent, VKey, VVal);
        end;
      end;
    end;

    // 2. Despachar a execução com tipagem forte para a suite AI Input / AI Output via Executores
    if DispatchResourceExecution(FComponent, AData, AParams, ALog) then
    begin
      Result := True;
      Exit;
    end;

    // Fallback para componentes customizados com propriedade Prompt
    CompPrompt := GetPropString(FComponent, 'Prompt');
    if CompPrompt <> '' then
    begin
      ALog := 'Componente customizado "' + FComponent.ClassName + '" executado. Prompt: ' + CompPrompt;
      Result := True;
      Exit;
    end;
  end;

  // Bloco de Fallback legado caso não haja Componente associado
  VRecipient := FRecipient;
  if AParams.Values['recipient'] <> '' then VRecipient := AParams.Values['recipient'];
  
  VSender := FSender;
  if AParams.Values['sender'] <> '' then VSender := AParams.Values['sender'];
  
  VSubject := FSubject;
  if AParams.Values['subject'] <> '' then VSubject := AParams.Values['subject'];
  
  VFilePath := FFilePath;
  if AParams.Values['file_path'] <> '' then VFilePath := AParams.Values['file_path'];

  VHost := FHost;
  if AParams.Values['host'] <> '' then VHost := AParams.Values['host'];

  VPort := FPort;
  if AParams.Values['port'] <> '' then VPort := StrToIntDef(AParams.Values['port'], FPort);

  VAPIUrl := FAPIUrl;
  if AParams.Values['api_url'] <> '' then VAPIUrl := AParams.Values['api_url'];

  case FResourceType of
    artEmail:
      begin
        ALog := Format('[E-MAIL ENVIADO]' + sLineBreak +
                       'Para: %s' + sLineBreak +
                       'De: %s' + sLineBreak +
                       'Assunto: %s' + sLineBreak +
                       'Conteúdo: %s' + sLineBreak +
                       'Parâmetros: %s',
                       [VRecipient, VSender, VSubject, AData, AParams.Text]);
        Result := True;
      end;
      
    artFile:
      begin
        if VFilePath = '' then
        begin
          ALog := 'Erro: FilePath não especificado para escrita de arquivo.';
          Exit;
        end;
        try
          with TStringList.Create do
          try
            Add('--- AGENT RESOURCE FILE WRITE ---');
            Add('Timestamp: ' + DateTimeToStr(Now));
            Add('Data/Rationale: ' + AData);
            Add('Parameters:');
            Add(AParams.Text);
            SaveToFile(VFilePath);
            ALog := 'Gravado no arquivo "' + VFilePath + '" com sucesso.';
            Result := True;
          finally
            Free;
          end;
        except
          on E: Exception do
          begin
            ALog := 'Falha ao salvar arquivo em ' + VFilePath + ': ' + E.Message;
            Result := False;
          end;
        end;
      end;
      
    artWhatsApp:
      begin
        ALog := Format('[WHATSAPP ENVIADO]' + sLineBreak +
                       'Para: %s' + sLineBreak +
                       'Mensagem: %s' + sLineBreak +
                       'Parâmetros: %s',
                       [VRecipient, AData, AParams.Text]);
        Result := True;
      end;
      
    artSMS:
      begin
        ALog := Format('[SMS ENVIADO]' + sLineBreak +
                       'Para: %s' + sLineBreak +
                       'Mensagem: %s',
                       [VRecipient, AData]);
        Result := True;
      end;
      
    artTCP:
      begin
        ALog := Format('[PACOTE TCP ENVIADO]' + sLineBreak +
                       'Host: %s:%d' + sLineBreak +
                       'Payload: %s',
                       [VHost, VPort, AData]);
        Result := True;
      end;
      
    artUDP:
      begin
        ALog := Format('[PACOTE UDP ENVIADO]' + sLineBreak +
                       'Host: %s:%d' + sLineBreak +
                       'Payload: %s',
                       [VHost, VPort, AData]);
        Result := True;
      end;
      
    artWebAPI:
      begin
        if VAPIUrl = '' then
        begin
          ALog := 'Erro: APIUrl não especificada para execução Web API.';
          Exit;
        end;
        try
          HTTPClient := TFPHttpClient.Create(nil);
          RequestBodyStream := TStringStream.Create(AData);
          try
            HTTPClient.AllowRedirect := True;
            HTTPClient.IOTimeout := 15000;
            HTTPClient.ConnectTimeout := 15000;
            HTTPClient.RequestBody := RequestBodyStream;
            
            for I := 0 to FHeaders.Count - 1 do
              HTTPClient.AddHeader(FHeaders.Names[I], FHeaders.ValueFromIndex[I]);
            
            ResponseText := HTTPClient.Post(VAPIUrl);
            ALog := 'Web API executada com sucesso. Resposta: ' + ResponseText;
            Result := True;
          finally
            RequestBodyStream.Free;
            HTTPClient.Free;
          end;
        except
          on E: Exception do
          begin
            ALog := 'Falha ao executar Web API em ' + VAPIUrl + ': ' + E.Message;
            Result := False;
          end;
        end;
      end;
      
    artCustom:
      begin
        ALog := Format('[RECURSO CUSTOMIZADO EXECUTADO]' + sLineBreak +
                       'Recurso: %s' + sLineBreak +
                       'Dados: %s' + sLineBreak +
                       'Parâmetros: %s',
                       [FName, AData, AParams.Text]);
        Result := True;
      end;
  end;
end;

{ TAIAgentResourceCollection }

constructor TAIAgentResourceCollection.Create(AOwner: TComponent);
begin
  inherited Create(TAIAgentResourceItem);
  FOwnerComponent := AOwner;
end;

function TAIAgentResourceCollection.GetItem(Index: Integer): TAIAgentResourceItem;
begin
  Result := TAIAgentResourceItem(inherited GetItem(Index));
end;

procedure TAIAgentResourceCollection.SetItem(Index: Integer; Value: TAIAgentResourceItem);
begin
  inherited SetItem(Index, Value);
end;

function TAIAgentResourceCollection.GetOwner: TPersistent;
begin
  Result := FOwnerComponent;
end;

function TAIAgentResourceCollection.Add: TAIAgentResourceItem;
begin
  Result := TAIAgentResourceItem(inherited Add);
end;

{ TAIAgentResource }

constructor TAIAgentResource.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FResources := TAIAgentResourceCollection.Create(Self);
end;

destructor TAIAgentResource.Destroy;
begin
  FResources.Free;
  inherited Destroy;
end;

procedure TAIAgentResource.SetResources(AValue: TAIAgentResourceCollection);
begin
  FResources.Assign(AValue);
end;

procedure TAIAgentResource.Notification(AComponent: TComponent; Operation: TOperation);
var
  I: Integer;
begin
  inherited Notification(AComponent, Operation);
  if Operation = opRemove then
  begin
    for I := 0 to FResources.Count - 1 do
    begin
      if FResources[I].Component = AComponent then
        FResources[I].Component := nil;
    end;
  end;
end;

function TAIAgentResource.FindResource(const AName: string): TAIAgentResourceItem;
var
  I: Integer;
begin
  Result := nil;
  for I := 0 to FResources.Count - 1 do
  begin
    if CompareText(FResources[I].Name, AName) = 0 then
    begin
      Result := FResources[I];
      Exit;
    end;
  end;
end;

{ TAIAgentOutputMappingCollection }

constructor TAIAgentOutputMappingCollection.Create(AOwner: TComponent);
begin
  inherited Create(TAIAgentOutputMapping);
  FOwnerComponent := AOwner;
end;

function TAIAgentOutputMappingCollection.GetItem(Index: Integer): TAIAgentOutputMapping;
begin
  Result := TAIAgentOutputMapping(inherited GetItem(Index));
end;

procedure TAIAgentOutputMappingCollection.SetItem(Index: Integer; Value: TAIAgentOutputMapping);
begin
  inherited SetItem(Index, Value);
end;

function TAIAgentOutputMappingCollection.GetOwner: TPersistent;
begin
  Result := FOwnerComponent;
end;

function TAIAgentOutputMappingCollection.Add: TAIAgentOutputMapping;
begin
  Result := TAIAgentOutputMapping(inherited Add);
end;

{ TAIAgentOutput }

constructor TAIAgentOutput.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FAction := nil;
  FResource := nil;
  FIsHooked := False;
  FPrevOnExecuteAction := nil;
  FMappings := TAIAgentOutputMappingCollection.Create(Self);
  FLastExecutionLog := '';
end;

destructor TAIAgentOutput.Destroy;
begin
  UnhookAction;
  FMappings.Free;
  inherited Destroy;
end;

procedure TAIAgentOutput.SetMappings(AValue: TAIAgentOutputMappingCollection);
begin
  FMappings.Assign(AValue);
end;

procedure TAIAgentOutput.SetAction(AValue: TAIAgentAction);
begin
  if FAction <> AValue then
  begin
    UnhookAction;
    FAction := AValue;
    if FAction <> nil then
    begin
      FAction.FreeNotification(Self);
      HookAction;
    end;
  end;
end;

procedure TAIAgentOutput.SetResource(AValue: TAIAgentResource);
begin
  if FResource <> AValue then
  begin
    FResource := AValue;
    if FResource <> nil then
      FResource.FreeNotification(Self);
  end;
end;

procedure TAIAgentOutput.HookAction;
begin
  if (FAction <> nil) and not FIsHooked then
  begin
    FPrevOnExecuteAction := FAction.OnExecuteAction;
    FAction.OnExecuteAction := @DoExecuteAction;
    FIsHooked := True;
  end;
end;

procedure TAIAgentOutput.UnhookAction;
begin
  if (FAction <> nil) and FIsHooked then
  begin
    if TMethod(FAction.OnExecuteAction).Code = TMethod(@DoExecuteAction).Code then
      FAction.OnExecuteAction := FPrevOnExecuteAction;
    FIsHooked := False;
    FPrevOnExecuteAction := nil;
  end;
end;

procedure TAIAgentOutput.DoExecuteAction(Sender: TObject; const AActionName: string; AParams: TStrings);
begin
  ExecuteAction(AActionName, AParams);
  if Assigned(FPrevOnExecuteAction) then
    FPrevOnExecuteAction(Sender, AActionName, AParams);
end;

function TAIAgentOutput.ExecuteAction(const AActionName: string; AParams: TStrings): Boolean;
var
  I: Integer;
  MappedResName: string;
  ResItem: TAIAgentResourceItem;
  DataText: string;
  AgentOwner: TAIAgent;
  Success: Boolean;
  LogMsg: string;
begin
  Result := False;
  FLastExecutionLog := '';
  MappedResName := '';
  
  if FResource = nil then
  begin
    FLastExecutionLog := 'Erro: TAIAgentResource não associado.';
    Exit;
  end;

  // Find mapping
  for I := 0 to FMappings.Count - 1 do
  begin
    if CompareText(FMappings[I].ActionName, AActionName) = 0 then
    begin
      MappedResName := FMappings[I].ResourceName;
      Break;
    end;
  end;

  if MappedResName = '' then
  begin
    FLastExecutionLog := Format('Ação "%s" não possui mapeamento de recurso configurado.', [AActionName]);
    Exit;
  end;

  // Find Resource
  ResItem := FResource.FindResource(MappedResName);
  if ResItem = nil then
  begin
    FLastExecutionLog := Format('Recurso "%s" mapeado para a ação "%s" não foi encontrado.', [MappedResName, AActionName]);
    Exit;
  end;

  // Find the rationale data
  DataText := 'Ação disparada por IA.';
  if (FAction <> nil) and (FAction.Owner <> nil) then
  begin
    for I := 0 to FAction.Owner.ComponentCount - 1 do
    begin
      if FAction.Owner.Components[I] is TAIAgent then
      begin
        AgentOwner := TAIAgent(FAction.Owner.Components[I]);
        if AgentOwner.Action = FAction then
        begin
          DataText := AgentOwner.LastRationale;
          Break;
        end;
      end;
    end;
  end;

  // Execute
  Success := ResItem.Execute(DataText, AParams, LogMsg);
  FLastExecutionLog := LogMsg;
  Result := Success;

  // Trigger event
  if Assigned(FOnOutputExecuted) then
    FOnOutputExecuted(Self, AActionName, MappedResName, LogMsg, Success);
end;

procedure TAIAgentOutput.Notification(AComponent: TComponent; Operation: TOperation);
begin
  inherited Notification(AComponent, Operation);
  if Operation = opRemove then
  begin
    if AComponent = FAction then
    begin
      UnhookAction;
      FAction := nil;
    end;
    if AComponent = FResource then
      FResource := nil;
  end;
end;

initialization
  {$I aiagent_icon.lrs}

end.
