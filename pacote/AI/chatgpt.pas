unit chatgpt;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, LazUTF8, fpjson, jsonparser,
  fphttpclient, opensslsockets, LResources, aibase, aillmproviders,
  aillmmodelcatalog, aitracebridge;

const
  CHATGPT_LIB_VERSION = '1.7';

type
  TVersionChat = (
    VCT_GPT35TURBO,
    VCT_GPT40,
    VCT_GPT40_TURBO,
    VCT_GPT4o,
    VCT_GPT4O_MINI,
    VCT_GPTo3_mini,
    VCT_GPTo1,
    VCT_GPTo1_mini,
    VCT_GPTo1_preview,
    VCT_GPT41,
    VCT_GPT41_MINI,
    VCT_GPT5,

    // DeepSeek Direct Models
    VCT_DEEPSEEK_CHAT,
    VCT_DEEPSEEK_REASONER,

    // Modelos locais / Ollama (Totalmente Gratuitos)
    VCT_LLAMA32_3B,
    VCT_QWEN25_15B,
    VCT_DEEPSEEK_R1_15B,
    VCT_DEEPSEEK_R1_8B,
    VCT_DEEPSEEK_R1_14B,
    VCT_DEEPSEEK_R1_70B,

    // Gemini (Google) - Possuem cotas de uso gratuitas
    VCT_GEMINI_15_FLASH,
    VCT_GEMINI_15_PRO,
    VCT_GEMINI_20_FLASH,
    VCT_GEMINI_25_FLASH,
    VCT_GEMINI_25_PRO,

    // Anthropic Claude
    VCT_CLAUDE_35_SONNET,
    VCT_CLAUDE_35_HAIKU,
    VCT_CLAUDE_3_OPUS,

    // Modelos Gratuitos via OpenRouter
    VCT_OPENROUTER_LLAMA3_8B_FREE,
    VCT_OPENROUTER_GEMMA2_9B_FREE,
    VCT_OPENROUTER_DEEPSEEK_R1_FREE,
    VCT_OPENROUTER_LLAMA32_3B_FREE,

    // Modelos locais DeepSeek R1 específicos do usuário
    VCT_DEEPSEEK_R1_1_5b,
    VCT_DEEPSEEK_R1_7b,

    VCT_CUSTOM
  );

  TAIProvider = (
    AIP_OPENAI,      // 0
    AIP_OPENROUTER,  // 1
    AIP_CEREBRAS,    // 2
    AIP_LOCAL,       // 3 - llama.cpp / Ollama local
    AIP_GEMINI,      // 4 - Google Gemini
    AIP_CLAUDE,      // 5 - Anthropic Claude
    AIP_DEEPSEEK,    // 6 - DeepSeek Direct API
    AIP_OPENAI_COMPATIBLE, // 7 - API configuravel /v1/chat/completions
    AIP_LLAMA_CPP,   // 8 - servidor llama.cpp
    AIP_NEURAL_API   // 9 - servidor neural-api
  );

  TAILLMRequestState = (
    lrsIdle,
    lrsConnecting,
    lrsReceiving,
    lrsCompleted,
    lrsCancelled,
    lrsError
  );

  TAILLMStreamNotifyEvent = procedure(Sender: TObject) of object;
  TAILLMStreamDataEvent = procedure(Sender: TObject;
    const AData: WideString) of object;
  TAILLMRequestStateEvent = procedure(Sender: TObject;
    AState: TAILLMRequestState) of object;
  TAILLMRequestCompleteEvent = procedure(Sender: TObject;
    ASuccess: Boolean) of object;
  TAILLMRequestErrorEvent = procedure(Sender: TObject;
    const AMessage: WideString) of object;

  { TCHATGPT }

  TCHATGPT = class(TAIBaseComponent)
  private
    FToken           : WideString;
    FQuestion        : WideString;
    FResponse        : WideString;
    FDev             : WideString;
    FTipoChat        : TVersionChat;
    FProvider        : TAIProvider;
    FParams          : TStrings;
    FCustomModel     : WideString;
    FOpenRouterTitle : WideString;
    FOpenRouterSite  : WideString;
    FLastJSON        : WideString;
    FMaxTokens       : Integer;
    FLocalIP         : WideString;
    FLastURL         : WideString;
    FURL             : WideString;
    FTemperature     : Double;
    FTimeout         : Integer;
    FStreaming       : Boolean;
    FRequestState    : TAILLMRequestState;
    FOnStreamStart   : TAILLMStreamNotifyEvent;
    FOnStreamData    : TAILLMStreamDataEvent;
    FOnStreamEnd     : TAILLMStreamNotifyEvent;
    FOnStateChange   : TAILLMRequestStateEvent;
    FOnRequestComplete: TAILLMRequestCompleteEvent;
    FOnRequestError  : TAILLMRequestErrorEvent;
    FActiveProvider  : IAILLMProvider;
    FWorker          : TThread;
    FCancelRequested : Boolean;
    FDestroying      : Boolean;
    FRequestLock     : TRTLCriticalSection;
    FTrace           : TComponent;
    FActiveTraceSpanID: string;
    FLastTraceID     : string;

    procedure SetToken(const AValue: WideString);
    procedure SetTipoChat(const AValue: TVersionChat);
    function MontaJson: WideString;
    function PegaMensagem(const JSON: WideString): WideString;
    function GetEndpoint: WideString;
    function GetModelName: WideString;
    procedure AddProviderHeaders(AHTTP: TFPHttpClient);
    function MontaURLChatLocal(const AServidor: WideString): WideString;
    function GetDev: WideString;
    procedure SetDev(const AValue: WideString);
    procedure SetTemperature(const AValue: Double);
    function ProviderKind: TAILLMProviderKind;
    procedure BuildProviderConfig(out AConfig: TAILLMProviderConfig;
      const AQuestion: WideString);
    procedure SetActiveProvider(const AProvider: IAILLMProvider);
    function GetActiveProvider: IAILLMProvider;
    procedure SetRequestState(AState: TAILLMRequestState);
    function GetBusy: Boolean;
    procedure DirectStreamData(Sender: TObject; const AData: string);
    procedure CleanupWorker;
    procedure SetTrace(AValue: TComponent);
    procedure BeginLLMTrace;
    procedure EndLLMTrace(ASuccess: Boolean; const AError, ARawResponse: string);
  protected
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    function SendQuestion(ASK: WideString): Boolean;
    function SendQuestionAsync(ASK: WideString): Boolean;
    procedure Cancel;
    function TipoModelo: WideString;
    function ProviderName: WideString;
    function VersaoBiblioteca: WideString;
  published
    property TOKEN: WideString read FToken write FToken;
    property Question: WideString read FQuestion;
    property Response: WideString read FResponse write FResponse;
    property Dev: WideString read GetDev write SetDev;
    property TipoChat: TVersionChat read FTipoChat write FTipoChat;
    property Provider: TAIProvider read FProvider write FProvider;
    property CustomModel: WideString read FCustomModel write FCustomModel;
    property LocalIP: WideString read FLocalIP write FLocalIP;
    property MaxTokens: Integer read FMaxTokens write FMaxTokens;
    property Temperature: Double read FTemperature write SetTemperature;
    property URL: WideString read FURL write FURL;
    property Timeout: Integer read FTimeout write FTimeout;
    property Streaming: Boolean read FStreaming write FStreaming default False;
    property RequestState: TAILLMRequestState read FRequestState;
    property Busy: Boolean read GetBusy;
    property Trace: TComponent read FTrace write SetTrace;
    property LastTraceID: string read FLastTraceID;

    // Opcionais para OpenRouter
    property OpenRouterTitle: WideString read FOpenRouterTitle write FOpenRouterTitle;
    property OpenRouterSite: WideString read FOpenRouterSite write FOpenRouterSite;

    property LastJSON: WideString read FLastJSON;
    property LastURL: WideString read FLastURL;
    property OnStreamStart: TAILLMStreamNotifyEvent read FOnStreamStart write FOnStreamStart;
    property OnStreamData: TAILLMStreamDataEvent read FOnStreamData write FOnStreamData;
    property OnStreamEnd: TAILLMStreamNotifyEvent read FOnStreamEnd write FOnStreamEnd;
    property OnStateChange: TAILLMRequestStateEvent read FOnStateChange write FOnStateChange;
    property OnRequestComplete: TAILLMRequestCompleteEvent read FOnRequestComplete write FOnRequestComplete;
    property OnRequestError: TAILLMRequestErrorEvent read FOnRequestError write FOnRequestError;
  end;

function GetAIProviderName(AProvider: TAIProvider): string;
function GetAIProviderFromIndex(AIndex: Integer): TAIProvider;
function GetDefaultEndpointForProvider(AProvider: TAIProvider): string;
procedure GetAIProviderList(AOutList: TStrings);
procedure GetAIModelListForProvider(AProvider: TAIProvider; AOutList: TStrings);

procedure Register;

implementation

type
  { TCHATGPTWorker }

  TCHATGPTWorker = class(TThread)
  private
    FOwner: TCHATGPT;
    FProvider: IAILLMProvider;
    FConfig: TAILLMProviderConfig;
    FAnswer: string;
    FData: string;
    FSuccess: Boolean;
    FError: string;
    FCancelled: Boolean;
    procedure SyncStart;
    procedure SyncData;
    procedure QueueFinish;
    procedure ProviderData(Sender: TObject; const AData: string);
  protected
    procedure Execute; override;
  public
    constructor Create(AOwner: TCHATGPT; const AProvider: IAILLMProvider;
      const AConfig: TAILLMProviderConfig);
  end;

constructor TCHATGPTWorker.Create(AOwner: TCHATGPT;
  const AProvider: IAILLMProvider; const AConfig: TAILLMProviderConfig);
begin
  inherited Create(True);
  FreeOnTerminate := False;
  FOwner := AOwner;
  FProvider := AProvider;
  FConfig := AConfig;
end;

procedure TCHATGPTWorker.SyncStart;
begin
  if (FOwner = nil) or FOwner.FDestroying then
    Exit;
  FOwner.SetRequestState(lrsConnecting);
  if FConfig.Stream and Assigned(FOwner.FOnStreamStart) then
    FOwner.FOnStreamStart(FOwner);
end;

procedure TCHATGPTWorker.ProviderData(Sender: TObject; const AData: string);
begin
  FData := AData;
  Synchronize(@SyncData);
end;

procedure TCHATGPTWorker.SyncData;
begin
  if (FOwner = nil) or FOwner.FDestroying then
    Exit;
  FOwner.SetRequestState(lrsReceiving);
  FOwner.FResponse := FOwner.FResponse + UTF8ToUTF16(FData);
  if Assigned(FOwner.FOnStreamData) then
    FOwner.FOnStreamData(FOwner, UTF8ToUTF16(FData));
end;

procedure TCHATGPTWorker.QueueFinish;
begin
  if (FOwner = nil) or FOwner.FDestroying then
    Exit;
  FOwner.FResponse := UTF8ToUTF16(FAnswer);
  FOwner.FLastResult := FAnswer;
  FOwner.FLastSuccess := FSuccess;
  FOwner.EndLLMTrace(FSuccess and (not FCancelled), FError,
    FProvider.GetLastRawResponse);
  FOwner.SetActiveProvider(nil);
  if FCancelled or FOwner.FCancelRequested then
  begin
    FOwner.SetRequestState(lrsCancelled);
    FOwner.FLastError := 'Requisicao cancelada.';
  end
  else if FSuccess then
    FOwner.SetRequestState(lrsCompleted)
  else
  begin
    FOwner.SetRequestState(lrsError);
    FOwner.SetError(FError);
  end;
  if FConfig.Stream and Assigned(FOwner.FOnStreamEnd) then
    FOwner.FOnStreamEnd(FOwner);
  if (not FSuccess) and (not FCancelled) and Assigned(FOwner.FOnRequestError) then
    FOwner.FOnRequestError(FOwner, UTF8ToUTF16(FError));
  if Assigned(FOwner.FOnRequestComplete) then
    FOwner.FOnRequestComplete(FOwner, FSuccess and (not FCancelled));
end;

procedure TCHATGPTWorker.Execute;
begin
  Synchronize(@SyncStart);
  if Terminated then
  begin
    FCancelled := True;
    TThread.Queue(Self, @QueueFinish);
    Exit;
  end;
  try
    FSuccess := FProvider.Send(FConfig, @ProviderData, FAnswer);
    FError := FProvider.GetLastError;
    FCancelled := Pos('cancelad', LowerCase(FError)) > 0;
  except
    on E: Exception do
    begin
      FSuccess := False;
      FError := E.Message;
    end;
  end;
  TThread.Queue(Self, @QueueFinish);
end;

procedure Register;
begin
  RegisterComponents('AI', [TCHATGPT]);
end;

function GetAIProviderName(AProvider: TAIProvider): string;
begin
  case AProvider of
    AIP_OPENAI:     Result := 'OpenAI';
    AIP_OPENROUTER: Result := 'OpenRouter';
    AIP_CEREBRAS:   Result := 'Cerebras';
    AIP_LOCAL:      Result := 'Local (Ollama / llama.cpp)';
    AIP_GEMINI:     Result := 'Google Gemini';
    AIP_CLAUDE:     Result := 'Anthropic Claude';
    AIP_DEEPSEEK:   Result := 'DeepSeek Direct';
    AIP_OPENAI_COMPATIBLE: Result := 'OpenAI-compatible';
    AIP_LLAMA_CPP:  Result := 'llama.cpp';
    AIP_NEURAL_API: Result := 'neural-api';
  else
    Result := 'OpenAI';
  end;
end;

function GetDefaultEndpointForProvider(AProvider: TAIProvider): string;
begin
  case AProvider of
    AIP_OPENAI:     Result := 'https://api.openai.com/v1/chat/completions';
    AIP_OPENROUTER: Result := 'https://openrouter.ai/api/v1/chat/completions';
    AIP_CEREBRAS:   Result := 'https://api.cerebras.ai/v1/chat/completions';
    AIP_DEEPSEEK:   Result := 'https://api.deepseek.com/v1/chat/completions';
    AIP_GEMINI:     Result := 'https://generativelanguage.googleapis.com/v1beta/models/';
    AIP_CLAUDE:     Result := 'https://api.anthropic.com/v1/messages';
    AIP_LOCAL:      Result := 'http://localhost:11434/v1/chat/completions';
    AIP_OPENAI_COMPATIBLE: Result := 'http://localhost:8000/v1/chat/completions';
    AIP_LLAMA_CPP:  Result := 'http://localhost:8080/v1/chat/completions';
    AIP_NEURAL_API: Result := 'http://localhost:8000/v1/chat/completions';
  else
    Result := 'https://api.openai.com/v1/chat/completions';
  end;
end;

function GetAIProviderFromIndex(AIndex: Integer): TAIProvider;
begin
  if (AIndex >= Ord(Low(TAIProvider))) and (AIndex <= Ord(High(TAIProvider))) then
    Result := TAIProvider(AIndex)
  else
    Result := AIP_OPENAI;
end;

procedure GetAIProviderList(AOutList: TStrings);
var
  P: TAIProvider;
begin
  if AOutList = nil then Exit;
  AOutList.Clear;
  for P := Low(TAIProvider) to High(TAIProvider) do
    AOutList.Add(GetAIProviderName(P));
end;

procedure GetAIModelListForProvider(AProvider: TAIProvider; AOutList: TStrings);
var
  LProvider: string;
begin
  if AOutList = nil then Exit;
  case AProvider of
    AIP_OPENAI: LProvider := 'OpenAI';
    AIP_OPENROUTER: LProvider := 'OpenRouter';
    AIP_CEREBRAS: LProvider := 'Cerebras';
    AIP_LOCAL: LProvider := 'Local';
    AIP_GEMINI: LProvider := 'Gemini';
    AIP_CLAUDE: LProvider := 'Claude';
    AIP_DEEPSEEK: LProvider := 'DeepSeek';
    AIP_OPENAI_COMPATIBLE: LProvider := 'OpenAI-compatible';
    AIP_LLAMA_CPP: LProvider := 'llama.cpp';
    AIP_NEURAL_API: LProvider := 'neural-api';
  else
    LProvider := 'OpenAI';
  end;
  GetAILLMModelsForProvider(LProvider, AOutList);
end;

function JsonEscape(const S: WideString): WideString;
var
  R: WideString;
begin
  R := StringReplace(S, '\', '\\', [rfReplaceAll]);
  R := StringReplace(R, '"', '\"', [rfReplaceAll]);
  R := StringReplace(R, #8, '\b', [rfReplaceAll]);
  R := StringReplace(R, #9, '\t', [rfReplaceAll]);
  R := StringReplace(R, #10, '\n', [rfReplaceAll]);
  R := StringReplace(R, #12, '\f', [rfReplaceAll]);
  R := StringReplace(R, #13, '\r', [rfReplaceAll]);
  Result := R;
end;

constructor TCHATGPT.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  InitCriticalSection(FRequestLock);
  FCategory := ccModel;
  FToken := '';
  FQuestion := '';
  FResponse := '';
  FDev := '';
  FTipoChat := VCT_GPT4O_MINI;
  FProvider := AIP_OPENAI;
  FCustomModel := '';
  FOpenRouterTitle := 'Pascal AI Component';
  FOpenRouterSite := '';
  FLastJSON := '';
  FMaxTokens := 1000;
  FLocalIP := 'http://localhost:11434';
  FLastURL := '';
  FURL := '';
  FTemperature := 0.7;
  FTimeout := 120000; // 120 segundos por padrao
  FStreaming := False;
  FRequestState := lrsIdle;
  FWorker := nil;
  FCancelRequested := False;
  FDestroying := False;
  FTrace := nil;
  FActiveTraceSpanID := '';
  FLastTraceID := '';

  FParams := TStringList.Create;
  FPrompt := 'TCHATGPT e o componente principal para comunicacao com OpenAI ChatGPT, OpenRouter, Cerebras, DeepSeek, Google Gemini, Claude e Ollama local.';
  ClearError;
end;

destructor TCHATGPT.Destroy;
begin
  FDestroying := True;
  Cancel;
  if FWorker <> nil then
  begin
    FWorker.Terminate;
    FWorker.WaitFor;
    TThread.RemoveQueuedEvents(FWorker);
    FreeAndNil(FWorker);
  end;
  SetActiveProvider(nil);
  FParams.Free;
  DoneCriticalSection(FRequestLock);
  inherited Destroy;
end;

procedure TCHATGPT.SetTrace(AValue: TComponent);
begin
  if FTrace = AValue then Exit;
  if Assigned(FTrace) then FTrace.RemoveFreeNotification(Self);
  FTrace := AValue;
  if Assigned(FTrace) then FTrace.FreeNotification(Self);
end;

procedure TCHATGPT.Notification(AComponent: TComponent; Operation: TOperation);
begin
  inherited Notification(AComponent, Operation);
  if (Operation = opRemove) and (AComponent = FTrace) then FTrace := nil;
end;

procedure TCHATGPT.BeginLLMTrace;
var Obj: TJSONObject;
begin
  FActiveTraceSpanID := '';
  if not Assigned(FTrace) then Exit;
  Obj := TJSONObject.Create;
  try
    Obj.Add('provider', UTF16ToUTF8(ProviderName));
    Obj.Add('model', UTF16ToUTF8(GetModelName));
    Obj.Add('question_chars', Length(FQuestion));
    Obj.Add('streaming', FStreaming);
    if AITraceAllowsSensitiveContent(FTrace) then
      Obj.Add('question', UTF16ToUTF8(FQuestion));
    FActiveTraceSpanID := AITraceBegin(FTrace, 'llm', 'SendQuestion', '',
      Obj.AsJSON);
    FLastTraceID := AITraceID(FTrace);
  finally Obj.Free; end;
end;

procedure TCHATGPT.EndLLMTrace(ASuccess: Boolean; const AError,
  ARawResponse: string);
var
  Obj: TJSONObject;
  Data, TokenData: TJSONData;
  PromptTokens, CompletionTokens, TotalTokens: Int64;
  TokensAvailable: Boolean;
begin
  if FActiveTraceSpanID = '' then Exit;
  PromptTokens := 0;
  CompletionTokens := 0;
  TotalTokens := 0;
  TokensAvailable := False;
  Data := nil;
  if Trim(ARawResponse) <> '' then
    try
      Data := GetJSON(ARawResponse);
      TokenData := Data.FindPath('usage.prompt_tokens');
      if Assigned(TokenData) then begin PromptTokens := TokenData.AsInt64; TokensAvailable := True; end;
      TokenData := Data.FindPath('usage.completion_tokens');
      if Assigned(TokenData) then begin CompletionTokens := TokenData.AsInt64; TokensAvailable := True; end;
      TokenData := Data.FindPath('usage.total_tokens');
      if Assigned(TokenData) then begin TotalTokens := TokenData.AsInt64; TokensAvailable := True; end;
    except
      FreeAndNil(Data);
      TokensAvailable := False;
    end;
  Obj := TJSONObject.Create;
  try
    Obj.Add('success', ASuccess);
    Obj.Add('provider', UTF16ToUTF8(ProviderName));
    Obj.Add('model', UTF16ToUTF8(GetModelName));
    Obj.Add('response_chars', Length(FResponse));
    Obj.Add('tokens_available', TokensAvailable);
    if TokensAvailable then
    begin
      Obj.Add('prompt_tokens', PromptTokens);
      Obj.Add('completion_tokens', CompletionTokens);
      Obj.Add('total_tokens', TotalTokens);
    end;
    if AITraceAllowsSensitiveContent(FTrace) then
      Obj.Add('response', UTF16ToUTF8(FResponse));
    AITraceEnd(FTrace, FActiveTraceSpanID, AError, Obj.AsJSON);
  finally
    Obj.Free;
    Data.Free;
    FActiveTraceSpanID := '';
  end;
end;

function TCHATGPT.ProviderKind: TAILLMProviderKind;
begin
  case FProvider of
    AIP_OPENAI: Result := llmOpenAI;
    AIP_OPENROUTER: Result := llmOpenRouter;
    AIP_CEREBRAS: Result := llmCerebras;
    AIP_LOCAL: Result := llmOllama;
    AIP_GEMINI: Result := llmGemini;
    AIP_CLAUDE: Result := llmClaude;
    AIP_DEEPSEEK: Result := llmDeepSeek;
    AIP_OPENAI_COMPATIBLE: Result := llmOpenAICompatible;
    AIP_LLAMA_CPP: Result := llmLlamaCpp;
    AIP_NEURAL_API: Result := llmNeuralAPI;
  else
    Result := llmOpenAI;
  end;
end;

procedure TCHATGPT.BuildProviderConfig(out AConfig: TAILLMProviderConfig;
  const AQuestion: WideString);
begin
  InitAILLMProviderConfig(AConfig);
  AConfig.Endpoint := UTF8Encode(FURL);
  if (FProvider = AIP_LOCAL) and (Trim(FURL) = '') then
    AConfig.Endpoint := UTF8Encode(MontaURLChatLocal(FLocalIP));
  AConfig.Token := UTF8Encode(FToken);
  AConfig.Model := UTF8Encode(GetModelName);
  AConfig.SystemPrompt := UTF8Encode(FDev);
  AConfig.UserPrompt := UTF8Encode(AQuestion);
  AConfig.OpenRouterTitle := UTF8Encode(FOpenRouterTitle);
  AConfig.OpenRouterSite := UTF8Encode(FOpenRouterSite);
  AConfig.Timeout := FTimeout;
  AConfig.MaxTokens := FMaxTokens;
  AConfig.Temperature := FTemperature;
  AConfig.Stream := FStreaming;
end;

procedure TCHATGPT.SetActiveProvider(const AProvider: IAILLMProvider);
begin
  EnterCriticalSection(FRequestLock);
  try
    FActiveProvider := AProvider;
  finally
    LeaveCriticalSection(FRequestLock);
  end;
end;

function TCHATGPT.GetActiveProvider: IAILLMProvider;
begin
  EnterCriticalSection(FRequestLock);
  try
    Result := FActiveProvider;
  finally
    LeaveCriticalSection(FRequestLock);
  end;
end;

procedure TCHATGPT.SetRequestState(AState: TAILLMRequestState);
begin
  if FRequestState = AState then
    Exit;
  FRequestState := AState;
  if Assigned(FOnStateChange) then
    FOnStateChange(Self, AState);
end;

function TCHATGPT.GetBusy: Boolean;
begin
  Result := FRequestState in [lrsConnecting, lrsReceiving];
end;

procedure TCHATGPT.DirectStreamData(Sender: TObject; const AData: string);
begin
  SetRequestState(lrsReceiving);
  FResponse := FResponse + UTF8ToUTF16(AData);
  if Assigned(FOnStreamData) then
    FOnStreamData(Self, UTF8ToUTF16(AData));
end;

procedure TCHATGPT.CleanupWorker;
begin
  if (FWorker <> nil) and (not GetBusy) then
  begin
    FWorker.WaitFor;
    TThread.RemoveQueuedEvents(FWorker);
    FreeAndNil(FWorker);
  end;
end;

function TCHATGPT.GetDev: WideString;
begin
  Result := FDev;
end;

procedure TCHATGPT.SetToken(const AValue: WideString);
begin
  FToken := Trim(AValue);
end;

procedure TCHATGPT.SetTipoChat(const AValue: TVersionChat);
begin
  FTipoChat := AValue;
end;

procedure TCHATGPT.SetDev(const AValue: WideString);
begin
  FDev := AValue;
end;

procedure TCHATGPT.SetTemperature(const AValue: Double);
begin
  if AValue < 0.0 then
    FTemperature := 0.0
  else if AValue > 2.0 then
    FTemperature := 2.0
  else
    FTemperature := AValue;
end;

function TCHATGPT.MontaURLChatLocal(const AServidor: WideString): WideString;
var
  S: WideString;
begin
  S := Trim(AServidor);
  if S = '' then
    S := 'http://localhost:11434';

  if Copy(S, Length(S), 1) = '/' then
    Delete(S, Length(S), 1);

  Result := S + '/v1/chat/completions';
end;

function TCHATGPT.PegaMensagem(const JSON: WideString): WideString;
var
  CleanJSON: WideString;
  Data: TJSONData;
  JsonObject, MessageObject: TJSONObject;
  ChoicesArray: TJSONArray;
  ContentData: TJSONData;
  Parser: TJSONParser;
begin
  CleanJSON := StringReplace(JSON, '#$0A', '', [rfReplaceAll]);
  Result := '';

  if FProvider = AIP_CLAUDE then
  begin
    Parser := TJSONParser.Create(CleanJSON);
    try
      try
        Data := Parser.Parse;
        try
          if Data.JSONType = jtObject then
          begin
            JsonObject := TJSONObject(Data);
            if JsonObject.Find('content', ChoicesArray) then
            begin
              if (ChoicesArray <> nil) and (ChoicesArray.Count > 0) then
              begin
                if ChoicesArray.Items[0].JSONType = jtObject then
                begin
                  ContentData := ChoicesArray.Objects[0].Find('text');
                  if (ContentData <> nil) and (ContentData.JSONType = jtString) then
                    Result := UTF8ToUTF16(ContentData.AsString);
                end;
              end;
            end;
          end;
        finally
          Data.Free;
        end;
      except
        Result := '';
      end;
    finally
      Parser.Free;
    end;
    Exit;
  end;

  if FProvider = AIP_GEMINI then
  begin
    Parser := TJSONParser.Create(CleanJSON);
    try
      try
        Data := Parser.Parse;
        try
          if Data.JSONType = jtObject then
          begin
            JsonObject := TJSONObject(Data);
            if JsonObject.Find('candidates', ChoicesArray) then
            begin
              if (ChoicesArray <> nil) and (ChoicesArray.Count > 0) then
              begin
                if ChoicesArray.Items[0].JSONType = jtObject then
                begin
                  MessageObject := ChoicesArray.Objects[0].Find('content') as TJSONObject;
                  if MessageObject <> nil then
                  begin
                    if MessageObject.Find('parts', ChoicesArray) then
                    begin
                      if (ChoicesArray <> nil) and (ChoicesArray.Count > 0) then
                      begin
                        if ChoicesArray.Items[0].JSONType = jtObject then
                        begin
                          ContentData := ChoicesArray.Objects[0].Find('text');
                          if (ContentData <> nil) and (ContentData.JSONType = jtString) then
                            Result := UTF8ToUTF16(ContentData.AsString);
                        end;
                      end;
                    end;
                  end;
                end;
              end;
            end;
          end;
        finally
          Data.Free;
        end;
      except
        Result := '';
      end;
    finally
      Parser.Free;
    end;
    Exit;
  end;

  Parser := TJSONParser.Create(CleanJSON);
  try
    try
      Data := Parser.Parse;
      try
        if Data.JSONType = jtObject then
        begin
          JsonObject := TJSONObject(Data);
          if JsonObject.Find('choices', ChoicesArray) then
          begin
            if (ChoicesArray <> nil) and (ChoicesArray.Count > 0) then
            begin
              if ChoicesArray.Items[0].JSONType = jtObject then
              begin
                MessageObject := ChoicesArray.Objects[0].FindPath('message') as TJSONObject;
                if MessageObject <> nil then
                begin
                  ContentData := MessageObject.Find('content');
                  if (ContentData <> nil) and (ContentData.JSONType = jtString) then
                    Result := UTF8ToUTF16(ContentData.AsString);
                end;
              end;
            end;
          end;
        end;
      finally
        Data.Free;
      end;
    except
      Result := '';
    end;
  finally
    Parser.Free;
  end;
end;

function TCHATGPT.GetEndpoint: WideString;
var
  CleanURL: WideString;
begin
  CleanURL := Trim(FURL);
  if CleanURL <> '' then
  begin
    Result := CleanURL;
    // Se a URL fornecida não tiver a rota específica de completions/messages/generateContent, anexa automaticamente a rota do provedor
    if (Pos('/v1/chat/completions', Result) = 0) and
       (Pos('/messages', Result) = 0) and
       (Pos('/generateContent', Result) = 0) and
       (Pos('/v1/completions', Result) = 0) then
    begin
      if Copy(Result, Length(Result), 1) = '/' then
        Delete(Result, Length(Result), 1);

      if FProvider = AIP_CLAUDE then
        Result := Result + '/v1/messages'
      else if FProvider = AIP_GEMINI then
        Result := Result + '/v1beta/models/' + GetModelName + ':generateContent?key=' + FToken
      else
        Result := Result + '/v1/chat/completions';
    end;
    Exit;
  end;

  case FProvider of
    AIP_OPENAI:
      Result := 'https://api.openai.com/v1/chat/completions';

    AIP_OPENROUTER:
      Result := 'https://openrouter.ai/api/v1/chat/completions';

    AIP_CEREBRAS:
      Result := 'https://api.cerebras.ai/v1/chat/completions';

    AIP_DEEPSEEK:
      Result := 'https://api.deepseek.com/v1/chat/completions';

    AIP_GEMINI:
      Result := 'https://generativelanguage.googleapis.com/v1beta/models/' + GetModelName + ':generateContent?key=' + FToken;

    AIP_CLAUDE:
      Result := 'https://api.anthropic.com/v1/messages';

    AIP_LOCAL:
      Result := MontaURLChatLocal(FLocalIP);
  else
    Result := 'https://api.openai.com/v1/chat/completions';
  end;
end;

function TCHATGPT.GetModelName: WideString;
begin
  if Trim(FCustomModel) <> '' then
    Exit(Trim(FCustomModel));

  if FProvider = AIP_LOCAL then
  begin
    case FTipoChat of
      VCT_LLAMA32_3B:       Result := 'llama3.2:3b';
      VCT_QWEN25_15B:       Result := 'qwen2.5:1.5b';
      VCT_DEEPSEEK_R1_15B:  Result := 'deepseek-r1:1.5b';
      VCT_DEEPSEEK_R1_8B:   Result := 'deepseek-r1:8b';
      VCT_DEEPSEEK_R1_14B:  Result := 'deepseek-r1:14b';
      VCT_DEEPSEEK_R1_70B:  Result := 'deepseek-r1:70b';
      VCT_DEEPSEEK_R1_1_5b: Result := 'deepseek_r1:1_5b';
      VCT_DEEPSEEK_R1_7b:   Result := 'deepseek_r1:7b';
    else
      Result := 'llama3.2:3b';
    end;
    Exit;
  end;

  if FProvider = AIP_CEREBRAS then
    Exit('qwen-3-235b-a22b-instruct-2507');

  if FProvider = AIP_DEEPSEEK then
  begin
    case FTipoChat of
      VCT_DEEPSEEK_CHAT:     Result := 'deepseek-chat';
      VCT_DEEPSEEK_REASONER: Result := 'deepseek-reasoner';
    else
      Result := 'deepseek-chat';
    end;
    Exit;
  end;

  if FProvider = AIP_OPENROUTER then
  begin
    case FTipoChat of
      VCT_OPENROUTER_LLAMA3_8B_FREE:   Result := 'meta-llama/llama-3-8b-instruct:free';
      VCT_OPENROUTER_GEMMA2_9B_FREE:   Result := 'google/gemma-2-9b-it:free';
      VCT_OPENROUTER_DEEPSEEK_R1_FREE:  Result := 'deepseek/deepseek-r1:free';
      VCT_OPENROUTER_LLAMA32_3B_FREE:  Result := 'meta-llama/llama-3.2-3b-instruct:free';
    else
      Result := 'google/gemma-2-9b-it:free';
    end;
    Exit;
  end;

  if FProvider = AIP_GEMINI then
  begin
    case FTipoChat of
      VCT_GEMINI_15_FLASH: Result := 'gemini-2.0-flash';
      VCT_GEMINI_15_PRO:   Result := 'gemini-1.5-pro';
      VCT_GEMINI_20_FLASH: Result := 'gemini-2.0-flash';
      VCT_GEMINI_25_FLASH: Result := 'gemini-2.0-flash';
      VCT_GEMINI_25_PRO:   Result := 'gemini-1.5-pro';
    else
      Result := 'gemini-2.0-flash';
    end;
    Exit;
  end;

  if FProvider = AIP_CLAUDE then
  begin
    case FTipoChat of
      VCT_CLAUDE_35_SONNET: Result := 'claude-3-5-sonnet-20241022';
      VCT_CLAUDE_35_HAIKU:  Result := 'claude-3-5-haiku-20241022';
      VCT_CLAUDE_3_OPUS:    Result := 'claude-3-opus-20240229';
    else
      Result := 'claude-3-5-sonnet-20241022';
    end;
    Exit;
  end;

  case FTipoChat of
    VCT_GPT35TURBO:    Result := 'gpt-3.5-turbo';
    VCT_GPT40:         Result := 'gpt-4';
    VCT_GPT40_TURBO:   Result := 'gpt-4-turbo';
    VCT_GPT4o:         Result := 'gpt-4o';
    VCT_GPT4O_MINI:    Result := 'gpt-4o-mini';
    VCT_GPTo3_mini:    Result := 'o3-mini';
    VCT_GPTo1:         Result := 'o1';
    VCT_GPTo1_mini:    Result := 'o1-mini';
    VCT_GPTo1_preview: Result := 'o1-preview';
    VCT_GPT41:         Result := 'gpt-4.1';
    VCT_GPT41_MINI:    Result := 'gpt-4.1-mini';
    VCT_GPT5:          Result := 'gpt-5';
    VCT_CUSTOM:        Result := Trim(FCustomModel);
  else
    Result := 'gpt-4o-mini';
  end;
end;

procedure TCHATGPT.AddProviderHeaders(AHTTP: TFPHttpClient);
begin
  if AHTTP = nil then
    Exit;

  AHTTP.AddHeader('Content-Type', 'application/json');
  AHTTP.AddHeader('Accept', 'application/json');
  AHTTP.AddHeader('Connection', 'close');

  if (FProvider = AIP_LOCAL) or (FProvider = AIP_GEMINI) then
    Exit;

  if FProvider = AIP_CLAUDE then
  begin
    AHTTP.AddHeader('x-api-key', FToken);
    AHTTP.AddHeader('anthropic-version', '2023-06-01');
    Exit;
  end;

  if Trim(FToken) <> '' then
    AHTTP.AddHeader('Authorization', 'Bearer ' + FToken);

  if FProvider = AIP_OPENROUTER then
  begin
    if Trim(FOpenRouterTitle) <> '' then
      AHTTP.AddHeader('X-Title', FOpenRouterTitle);
    if Trim(FOpenRouterSite) <> '' then
      AHTTP.AddHeader('HTTP-Referer', FOpenRouterSite);
  end;
end;

function TCHATGPT.MontaJson: WideString;
var
  SysPrompt, UserPrompt: WideString;
begin
  UserPrompt := JsonEscape(FQuestion);

  if FProvider = AIP_CLAUDE then
  begin
    Result := '{"model":"' + GetModelName + '","max_tokens":' + IntToStr(FMaxTokens);
    if Trim(FDev) <> '' then
    begin
      SysPrompt := JsonEscape(FDev);
      Result := Result + ',"system":"' + SysPrompt + '"';
    end;
    Result := Result + ',"messages":[{"role":"user","content":"' + UserPrompt + '"}]}';
    Exit;
  end;

  if FProvider = AIP_GEMINI then
  begin
    Result := '{"contents":[{"parts":[{"text":"' + UserPrompt + '"}]}]';
    if Trim(FDev) <> '' then
    begin
      SysPrompt := JsonEscape(FDev);
      Result := Result + ',"system_instruction":{"parts":[{"text":"' + SysPrompt + '"}]}';
    end;
    Result := Result + '}';
    Exit;
  end;

  Result := '{"model":"' + GetModelName + '"';
  if FMaxTokens > 0 then
    Result := Result + ',"max_tokens":' + IntToStr(FMaxTokens);

  Result := Result + ',"messages":[';
  if Trim(FDev) <> '' then
  begin
    SysPrompt := JsonEscape(FDev);
    Result := Result + '{"role":"system","content":"' + SysPrompt + '"},';
  end;
  Result := Result + '{"role":"user","content":"' + UserPrompt + '"}]}';
end;

function TCHATGPT.SendQuestion(ASK: WideString): Boolean;
var
  LConfig: TAILLMProviderConfig;
  LProvider: IAILLMProvider;
  LAnswer: string;
begin
  Result := False;
  if GetBusy then
  begin
    SetError('Ja existe uma requisicao AI em andamento.');
    Exit;
  end;
  CleanupWorker;
  ClearError;
  FCancelRequested := False;
  FQuestion := ASK;
  FResponse := '';
  FLastJSON := '';
  FLastURL := '';
  BuildProviderConfig(LConfig, ASK);
  LProvider := TAILLMProviderFactory.CreateProvider(ProviderKind);
  SetActiveProvider(LProvider);
  FLastURL := UTF8ToUTF16(LProvider.BuildEndpoint(LConfig));
  FLastJSON := UTF8ToUTF16(LProvider.BuildRequest(LConfig));
  BeginLLMTrace;
  SetRequestState(lrsConnecting);
  if FStreaming and Assigned(FOnStreamStart) then
    FOnStreamStart(Self);
  try
    Result := LProvider.Send(LConfig, @DirectStreamData, LAnswer);
    FResponse := UTF8ToUTF16(LAnswer);
    FLastResult := LAnswer;
    FLastSuccess := Result;
    if FCancelRequested or (Pos('cancelad', LowerCase(LProvider.GetLastError)) > 0) then
    begin
      Result := False;
      FLastSuccess := False;
      FLastError := 'Requisicao cancelada.';
      SetRequestState(lrsCancelled);
    end
    else if Result then
      SetRequestState(lrsCompleted)
    else
    begin
      SetError(LProvider.GetLastError);
      SetRequestState(lrsError);
      if Assigned(FOnRequestError) then
        FOnRequestError(Self, UTF8ToUTF16(FLastError));
    end;
  finally
    EndLLMTrace(Result, FLastError, LProvider.GetLastRawResponse);
    SetActiveProvider(nil);
    if FStreaming and Assigned(FOnStreamEnd) then
      FOnStreamEnd(Self);
    if Assigned(FOnRequestComplete) then
      FOnRequestComplete(Self, Result);
  end;
end;

function TCHATGPT.SendQuestionAsync(ASK: WideString): Boolean;
var
  LConfig: TAILLMProviderConfig;
  LProvider: IAILLMProvider;
begin
  Result := False;
  if GetBusy then
  begin
    SetError('Ja existe uma requisicao AI em andamento.');
    Exit;
  end;
  CleanupWorker;
  ClearError;
  FCancelRequested := False;
  FQuestion := ASK;
  FResponse := '';
  FLastJSON := '';
  FLastURL := '';
  BuildProviderConfig(LConfig, ASK);
  LProvider := TAILLMProviderFactory.CreateProvider(ProviderKind);
  SetActiveProvider(LProvider);
  FLastURL := UTF8ToUTF16(LProvider.BuildEndpoint(LConfig));
  FLastJSON := UTF8ToUTF16(LProvider.BuildRequest(LConfig));
  BeginLLMTrace;
  SetRequestState(lrsConnecting);
  FWorker := TCHATGPTWorker.Create(Self, LProvider, LConfig);
  FWorker.Start;
  Result := True;
end;

procedure TCHATGPT.Cancel;
var
  LProvider: IAILLMProvider;
begin
  FCancelRequested := True;
  LProvider := GetActiveProvider;
  if LProvider <> nil then
    LProvider.Cancel;
  if FWorker <> nil then
    FWorker.Terminate;
end;

function TCHATGPT.TipoModelo: WideString;
begin
  Result := GetModelName;
end;

function TCHATGPT.ProviderName: WideString;
begin
  Result := GetAIProviderName(FProvider);
end;

function TCHATGPT.VersaoBiblioteca: WideString;
begin
  Result := CHATGPT_LIB_VERSION;
end;

initialization
  {$I chatgpt_icon.lrs}

end.
