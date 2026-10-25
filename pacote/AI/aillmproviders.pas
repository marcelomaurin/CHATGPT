unit aillmproviders;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, fphttpclient;

type
  TAILLMProviderKind = (
    llmOpenAI,
    llmOpenAICompatible,
    llmLlamaCpp,
    llmNeuralAPI,
    llmGemini,
    llmClaude,
    llmDeepSeek,
    llmOpenRouter,
    llmCerebras,
    llmOllama,
    llmRunPod,
    llmGroq,
    llmMistral,
    llmXAI,
    llmQwen
  );

  TAILLMProviderConfig = record
    Endpoint: string;
    Token: string;
    Model: string;
    SystemPrompt: string;
    UserPrompt: string;
    OpenRouterTitle: string;
    OpenRouterSite: string;
    Timeout: Integer;
    MaxTokens: Integer;
    Temperature: Double;
    Stream: Boolean;
  end;

  TAILLMStreamDataEvent = procedure(Sender: TObject; const AData: string) of object;

  IAILLMProvider = interface
    ['{ED7F4C25-7C10-4765-96A6-5E833642A783}']
    function GetProviderID: string;
    function GetProviderName: string;
    function GetDefaultEndpoint: string;
    function GetLastError: string;
    function GetLastRawResponse: string;
    function SupportsStreaming: Boolean;
    function SupportsTemperature: Boolean;
    function BuildEndpoint(const AConfig: TAILLMProviderConfig): string;
    function BuildRequest(const AConfig: TAILLMProviderConfig): string;
    procedure BuildHeaders(const AConfig: TAILLMProviderConfig; AHeaders: TStrings);
    function ParseResponse(const ARawResponse: string): string;
    function Send(const AConfig: TAILLMProviderConfig;
      const AOnStreamData: TAILLMStreamDataEvent; out AAnswer: string): Boolean;
    procedure Cancel;
  end;

  { TAILLMProviderBase }

  TAILLMProviderBase = class(TInterfacedObject, IAILLMProvider)
  private
    FProviderID: string;
    FProviderName: string;
    FDefaultEndpoint: string;
    FLastError: string;
    FLastRawResponse: string;
    FActiveHTTP: TFPHttpClient;
    FCancelled: Boolean;
    FLock: TRTLCriticalSection;
    function IsCancelled: Boolean;
    procedure SetActiveHTTP(AHTTP: TFPHttpClient);
  protected
    procedure SetProviderIdentity(const AID, AName, AEndpoint: string);
    function ParseOpenAIResponse(const ARawResponse: string): string;
    function ParseOpenAIStreamDelta(const AData: string): string;
    function EnsureEndpoint(const AEndpoint, ARoute: string): string;
    procedure SetLastError(const AMessage: string);
  public
    constructor Create; virtual;
    destructor Destroy; override;
    function GetProviderID: string;
    function GetProviderName: string;
    function GetDefaultEndpoint: string;
    function GetLastError: string;
    function GetLastRawResponse: string;
    function SupportsStreaming: Boolean; virtual;
    function SupportsTemperature: Boolean; virtual;
    function BuildEndpoint(const AConfig: TAILLMProviderConfig): string; virtual;
    function BuildRequest(const AConfig: TAILLMProviderConfig): string; virtual;
    procedure BuildHeaders(const AConfig: TAILLMProviderConfig;
      AHeaders: TStrings); virtual;
    function ParseResponse(const ARawResponse: string): string; virtual;
    function Send(const AConfig: TAILLMProviderConfig;
      const AOnStreamData: TAILLMStreamDataEvent; out AAnswer: string): Boolean; virtual;
    procedure Cancel; virtual;
  end;

  TAILLMOpenAICompatibleProvider = class(TAILLMProviderBase)
  public
    constructor Create; override;
  end;

  TAILLMHostedCompatibleProvider = class(TAILLMOpenAICompatibleProvider)
  public
    constructor CreateHosted(const AID, AName, AEndpoint: string);
  end;

  TAILLMOpenAIProvider = class(TAILLMOpenAICompatibleProvider)
  public
    constructor Create; override;
  end;

  TAILLMLlamaCppProvider = class(TAILLMOpenAICompatibleProvider)
  public
    constructor Create; override;
  end;

  TAILLMNeuralAPIProvider = class(TAILLMOpenAICompatibleProvider)
  public
    constructor Create; override;
  end;

  TAILLMDeepSeekProvider = class(TAILLMOpenAICompatibleProvider)
  public
    constructor Create; override;
  end;

  TAILLMOpenRouterProvider = class(TAILLMOpenAICompatibleProvider)
  public
    constructor Create; override;
    procedure BuildHeaders(const AConfig: TAILLMProviderConfig;
      AHeaders: TStrings); override;
  end;

  TAILLMCerebrasProvider = class(TAILLMOpenAICompatibleProvider)
  public
    constructor Create; override;
  end;

  TAILLMOllamaProvider = class(TAILLMOpenAICompatibleProvider)
  public
    constructor Create; override;
  end;

  TAILLMGeminiProvider = class(TAILLMProviderBase)
  public
    constructor Create; override;
    function BuildEndpoint(const AConfig: TAILLMProviderConfig): string; override;
    function BuildRequest(const AConfig: TAILLMProviderConfig): string; override;
    procedure BuildHeaders(const AConfig: TAILLMProviderConfig;
      AHeaders: TStrings); override;
    function ParseResponse(const ARawResponse: string): string; override;
    function SupportsStreaming: Boolean; override;
  end;

  TAILLMClaudeProvider = class(TAILLMProviderBase)
  public
    constructor Create; override;
    function BuildRequest(const AConfig: TAILLMProviderConfig): string; override;
    procedure BuildHeaders(const AConfig: TAILLMProviderConfig;
      AHeaders: TStrings); override;
    function ParseResponse(const ARawResponse: string): string; override;
    function SupportsStreaming: Boolean; override;
  end;

  TAILLMProviderFactory = class
  public
    class function CreateProvider(AKind: TAILLMProviderKind): IAILLMProvider; static;
    class function KindFromName(const AName: string): TAILLMProviderKind; static;
  end;

procedure InitAILLMProviderConfig(out AConfig: TAILLMProviderConfig);
function AILLMProviderKindName(AKind: TAILLMProviderKind): string;

implementation

uses
  fpjson, jsonparser, opensslsockets;

type
  TAILLMStreamingResponseStream = class(TMemoryStream)
  private
    FPending: string;
    FAnswer: string;
    FOnData: TAILLMStreamDataEvent;
    FSender: TObject;
    FProvider: TAILLMProviderBase;
    procedure ProcessLine(const ALine: string);
  public
    constructor Create(AProvider: TAILLMProviderBase; ASender: TObject;
      const AOnData: TAILLMStreamDataEvent);
    function Write(const Buffer; Count: Longint): Longint; override;
    procedure Finish;
    function RawResponse: string;
    property Answer: string read FAnswer;
  end;

procedure InitAILLMProviderConfig(out AConfig: TAILLMProviderConfig);
begin
  FillChar(AConfig, SizeOf(AConfig), 0);
  AConfig.Timeout := 120000;
  AConfig.MaxTokens := 1000;
  AConfig.Temperature := 0.7;
end;

function AILLMProviderKindName(AKind: TAILLMProviderKind): string;
begin
  case AKind of
    llmOpenAI: Result := 'OpenAI';
    llmOpenAICompatible: Result := 'OpenAI-compatible';
    llmLlamaCpp: Result := 'llama.cpp';
    llmNeuralAPI: Result := 'neural-api';
    llmGemini: Result := 'Google Gemini';
    llmClaude: Result := 'Anthropic Claude';
    llmDeepSeek: Result := 'DeepSeek';
    llmOpenRouter: Result := 'OpenRouter';
    llmCerebras: Result := 'Cerebras';
    llmOllama: Result := 'Ollama';
    llmRunPod: Result := 'RunPod';
    llmGroq: Result := 'Groq';
    llmMistral: Result := 'Mistral';
    llmXAI: Result := 'xAI';
    llmQwen: Result := 'Qwen';
  end;
end;

function JSONStringAtPath(AData: TJSONData; const APath: string): string;
var
  LData: TJSONData;
begin
  Result := '';
  if AData = nil then
    Exit;
  LData := AData.FindPath(APath);
  if (LData <> nil) and (LData.JSONType = jtString) then
    Result := LData.AsString;
end;

function ParseJSONPath(const ARawResponse, APath: string): string;
var
  LData: TJSONData;
begin
  Result := '';
  try
    LData := GetJSON(ARawResponse);
    try
      Result := JSONStringAtPath(LData, APath);
    finally
      LData.Free;
    end;
  except
    Result := '';
  end;
end;

function ParseAPIError(const ARawResponse: string): string;
begin
  Result := ParseJSONPath(ARawResponse, 'error.message');
  if Result = '' then
    Result := Trim(ARawResponse);
end;

{ TAILLMStreamingResponseStream }

constructor TAILLMStreamingResponseStream.Create(AProvider: TAILLMProviderBase;
  ASender: TObject; const AOnData: TAILLMStreamDataEvent);
begin
  inherited Create;
  FProvider := AProvider;
  FSender := ASender;
  FOnData := AOnData;
end;

procedure TAILLMStreamingResponseStream.ProcessLine(const ALine: string);
var
  LLine, LDelta: string;
begin
  LLine := Trim(ALine);
  if Pos('data:', LowerCase(LLine)) <> 1 then
    Exit;
  LLine := Trim(Copy(LLine, 6, MaxInt));
  if (LLine = '') or SameText(LLine, '[DONE]') then
    Exit;
  LDelta := FProvider.ParseOpenAIStreamDelta(LLine);
  if LDelta = '' then
    Exit;
  FAnswer := FAnswer + LDelta;
  if Assigned(FOnData) then
    FOnData(FSender, LDelta);
end;

function TAILLMStreamingResponseStream.Write(const Buffer; Count: Longint): Longint;
var
  LChunk, LLine: string;
  LPos: SizeInt;
begin
  Result := inherited Write(Buffer, Count);
  if Count <= 0 then
    Exit;
  SetString(LChunk, PChar(@Buffer), Count);
  FPending := FPending + LChunk;
  repeat
    LPos := Pos(#10, FPending);
    if LPos = 0 then
      Break;
    LLine := Copy(FPending, 1, LPos - 1);
    Delete(FPending, 1, LPos);
    ProcessLine(LLine);
  until False;
end;

procedure TAILLMStreamingResponseStream.Finish;
begin
  if FPending <> '' then
  begin
    ProcessLine(FPending);
    FPending := '';
  end;
end;

function TAILLMStreamingResponseStream.RawResponse: string;
begin
  SetLength(Result, Size);
  if Size > 0 then
  begin
    Position := 0;
    ReadBuffer(Result[1], Size);
  end;
end;

{ TAILLMProviderBase }

constructor TAILLMProviderBase.Create;
begin
  inherited Create;
  InitCriticalSection(FLock);
end;

destructor TAILLMProviderBase.Destroy;
begin
  Cancel;
  DoneCriticalSection(FLock);
  inherited Destroy;
end;

procedure TAILLMProviderBase.SetProviderIdentity(const AID, AName,
  AEndpoint: string);
begin
  FProviderID := AID;
  FProviderName := AName;
  FDefaultEndpoint := AEndpoint;
end;

function TAILLMProviderBase.GetProviderID: string;
begin
  Result := FProviderID;
end;

function TAILLMProviderBase.GetProviderName: string;
begin
  Result := FProviderName;
end;

function TAILLMProviderBase.GetDefaultEndpoint: string;
begin
  Result := FDefaultEndpoint;
end;

function TAILLMProviderBase.GetLastError: string;
begin
  Result := FLastError;
end;

function TAILLMProviderBase.GetLastRawResponse: string;
begin
  Result := FLastRawResponse;
end;

procedure TAILLMProviderBase.SetLastError(const AMessage: string);
begin
  FLastError := AMessage;
end;

function TAILLMProviderBase.SupportsStreaming: Boolean;
begin
  Result := True;
end;

function TAILLMProviderBase.SupportsTemperature: Boolean;
begin
  Result := True;
end;

function TAILLMProviderBase.EnsureEndpoint(const AEndpoint,
  ARoute: string): string;
begin
  Result := Trim(AEndpoint);
  if Result = '' then
    Result := FDefaultEndpoint;
  if (Pos('/v1/chat/completions', LowerCase(Result)) > 0) or
     (Pos('/v1/messages', LowerCase(Result)) > 0) or
     (Pos(':generatecontent', LowerCase(Result)) > 0) then
    Exit;
  while (Result <> '') and (Result[Length(Result)] = '/') do
    Delete(Result, Length(Result), 1);
  if (Copy(Result, Length(Result) - 2, 3) = '/v1') and
     (Copy(ARoute, 1, 4) = '/v1/') then
    Result := Result + Copy(ARoute, 4, MaxInt)
  else
    Result := Result + ARoute;
end;

function TAILLMProviderBase.BuildEndpoint(
  const AConfig: TAILLMProviderConfig): string;
begin
  Result := EnsureEndpoint(AConfig.Endpoint, '/v1/chat/completions');
end;

function TAILLMProviderBase.BuildRequest(
  const AConfig: TAILLMProviderConfig): string;
var
  LRoot, LMessage: TJSONObject;
  LMessages: TJSONArray;
  LReasoningOpenAI: Boolean;
begin
  LReasoningOpenAI := (GetProviderID = 'openai') and
    ((Pos('gpt-5', LowerCase(AConfig.Model)) = 1) or
     (Pos('gpt-6', LowerCase(AConfig.Model)) = 1) or
     (Pos('o1', LowerCase(AConfig.Model)) = 1) or
     (Pos('o3', LowerCase(AConfig.Model)) = 1) or
     (Pos('o4', LowerCase(AConfig.Model)) = 1));
  LRoot := TJSONObject.Create;
  try
    LRoot.Add('model', AConfig.Model);
    if AConfig.MaxTokens > 0 then
      if LReasoningOpenAI then
        LRoot.Add('max_completion_tokens', AConfig.MaxTokens)
      else
        LRoot.Add('max_tokens', AConfig.MaxTokens);
    if SupportsTemperature and not LReasoningOpenAI then
      LRoot.Add('temperature', AConfig.Temperature);
    if AConfig.Stream and SupportsStreaming then
      LRoot.Add('stream', True);
    LMessages := TJSONArray.Create;
    LRoot.Add('messages', LMessages);
    if Trim(AConfig.SystemPrompt) <> '' then
    begin
      LMessage := TJSONObject.Create;
      LMessage.Add('role', 'system');
      LMessage.Add('content', AConfig.SystemPrompt);
      LMessages.Add(LMessage);
    end;
    LMessage := TJSONObject.Create;
    LMessage.Add('role', 'user');
    LMessage.Add('content', AConfig.UserPrompt);
    LMessages.Add(LMessage);
    Result := LRoot.AsJSON;
  finally
    LRoot.Free;
  end;
end;

procedure TAILLMProviderBase.BuildHeaders(
  const AConfig: TAILLMProviderConfig; AHeaders: TStrings);
begin
  if AHeaders = nil then
    Exit;
  AHeaders.Clear;
  AHeaders.Values['Content-Type'] := 'application/json';
  if AConfig.Stream and SupportsStreaming then
    AHeaders.Values['Accept'] := 'text/event-stream'
  else
    AHeaders.Values['Accept'] := 'application/json';
  AHeaders.Values['Connection'] := 'close';
  if Trim(AConfig.Token) <> '' then
    AHeaders.Values['Authorization'] := 'Bearer ' + AConfig.Token;
end;

function TAILLMProviderBase.ParseOpenAIResponse(
  const ARawResponse: string): string;
begin
  Result := ParseJSONPath(ARawResponse, 'choices[0].message.content');
end;

function TAILLMProviderBase.ParseOpenAIStreamDelta(
  const AData: string): string;
begin
  Result := ParseJSONPath(AData, 'choices[0].delta.content');
end;

function TAILLMProviderBase.ParseResponse(const ARawResponse: string): string;
begin
  Result := ParseOpenAIResponse(ARawResponse);
end;

procedure TAILLMProviderBase.SetActiveHTTP(AHTTP: TFPHttpClient);
begin
  EnterCriticalSection(FLock);
  try
    FActiveHTTP := AHTTP;
  finally
    LeaveCriticalSection(FLock);
  end;
end;

function TAILLMProviderBase.IsCancelled: Boolean;
begin
  EnterCriticalSection(FLock);
  try
    Result := FCancelled;
  finally
    LeaveCriticalSection(FLock);
  end;
end;

function TAILLMProviderBase.Send(const AConfig: TAILLMProviderConfig;
  const AOnStreamData: TAILLMStreamDataEvent; out AAnswer: string): Boolean;
var
  LHTTP: TFPHttpClient;
  LBody: TStringStream;
  LResponse: TAILLMStreamingResponseStream;
  LHeaders: TStringList;
  LEndpoint, LPayload: string;
  I, LAttempt, LAttempts: Integer;
begin
  Result := False;
  AAnswer := '';
  FLastError := '';
  FLastRawResponse := '';
  EnterCriticalSection(FLock);
  try
    FCancelled := False;
  finally
    LeaveCriticalSection(FLock);
  end;
  LEndpoint := BuildEndpoint(AConfig);
  if (Pos('WORKSPACE_ID', UpperCase(LEndpoint)) > 0) or
     (Pos('ENDPOINT_ID', UpperCase(LEndpoint)) > 0) then
  begin
    FLastError := 'Configure URL com o identificador real do workspace/endpoint de ' + GetProviderName + '.';
    Exit;
  end;
  LPayload := BuildRequest(AConfig);
  if AConfig.Stream and SupportsStreaming then
    LAttempts := 1
  else
    LAttempts := 2;
  for LAttempt := 1 to LAttempts do
  begin
    if IsCancelled then
      Break;
    LHTTP := TFPHttpClient.Create(nil);
    LBody := TStringStream.Create(LPayload);
    LResponse := TAILLMStreamingResponseStream.Create(Self, Self, AOnStreamData);
    LHeaders := TStringList.Create;
    try
      SetActiveHTTP(LHTTP);
      if AConfig.Timeout > 0 then
      begin
        if AConfig.Timeout < 1000 then
        begin
          LHTTP.ConnectTimeout := AConfig.Timeout * 1000;
          LHTTP.IOTimeout := AConfig.Timeout * 1000;
        end
        else
        begin
          LHTTP.ConnectTimeout := AConfig.Timeout;
          LHTTP.IOTimeout := AConfig.Timeout;
        end;
      end
      else
      begin
        LHTTP.ConnectTimeout := 15000;
        LHTTP.IOTimeout := 30000;
      end;
      BuildHeaders(AConfig, LHeaders);
      for I := 0 to LHeaders.Count - 1 do
        if LHeaders.Names[I] <> '' then
          LHTTP.AddHeader(LHeaders.Names[I], LHeaders.ValueFromIndex[I]);
      LHTTP.RequestBody := LBody;
      try
        LHTTP.Post(LEndpoint, LResponse);
        LResponse.Finish;
        FLastRawResponse := LResponse.RawResponse;
        AAnswer := LResponse.Answer;
        if AAnswer = '' then
          AAnswer := ParseResponse(FLastRawResponse);
        Result := Trim(AAnswer) <> '';
        if not Result then
        begin
          FLastError := ParseAPIError(FLastRawResponse);
          if FLastError = '' then
            FLastError := 'Resposta vazia da API.';
        end;
        Break;
      except
        on E: Exception do
        begin
          if IsCancelled then
            FLastError := 'Requisicao cancelada.'
          else
            FLastError := 'Erro HTTP na requisicao AI: ' + E.Message;
          if (LAttempt < LAttempts) and (not IsCancelled) then
            Sleep(300);
        end;
      end;
    finally
      SetActiveHTTP(nil);
      LHTTP.RequestBody := nil;
      LHeaders.Free;
      LResponse.Free;
      LBody.Free;
      LHTTP.Free;
    end;
  end;
end;

procedure TAILLMProviderBase.Cancel;
begin
  EnterCriticalSection(FLock);
  try
    FCancelled := True;
    if FActiveHTTP <> nil then
      FActiveHTTP.Terminate;
  finally
    LeaveCriticalSection(FLock);
  end;
end;

{ OpenAI-compatible providers }

constructor TAILLMOpenAICompatibleProvider.Create;
begin
  inherited Create;
  SetProviderIdentity('openai-compatible', 'OpenAI-compatible',
    'http://localhost:8000/v1/chat/completions');
end;

constructor TAILLMHostedCompatibleProvider.CreateHosted(
  const AID, AName, AEndpoint: string);
begin
  inherited Create;
  SetProviderIdentity(AID, AName, AEndpoint);
end;

constructor TAILLMOpenAIProvider.Create;
begin
  inherited Create;
  SetProviderIdentity('openai', 'OpenAI',
    'https://api.openai.com/v1/chat/completions');
end;

constructor TAILLMLlamaCppProvider.Create;
begin
  inherited Create;
  SetProviderIdentity('llama.cpp', 'llama.cpp',
    'http://localhost:8080/v1/chat/completions');
end;

constructor TAILLMNeuralAPIProvider.Create;
begin
  inherited Create;
  SetProviderIdentity('neural-api', 'neural-api',
    'http://localhost:8000/v1/chat/completions');
end;

constructor TAILLMDeepSeekProvider.Create;
begin
  inherited Create;
  SetProviderIdentity('deepseek', 'DeepSeek',
    'https://api.deepseek.com/v1/chat/completions');
end;

constructor TAILLMOpenRouterProvider.Create;
begin
  inherited Create;
  SetProviderIdentity('openrouter', 'OpenRouter',
    'https://openrouter.ai/api/v1/chat/completions');
end;

procedure TAILLMOpenRouterProvider.BuildHeaders(
  const AConfig: TAILLMProviderConfig; AHeaders: TStrings);
begin
  inherited BuildHeaders(AConfig, AHeaders);
  if Trim(AConfig.OpenRouterTitle) <> '' then
    AHeaders.Values['X-Title'] := AConfig.OpenRouterTitle;
  if Trim(AConfig.OpenRouterSite) <> '' then
    AHeaders.Values['HTTP-Referer'] := AConfig.OpenRouterSite;
end;

constructor TAILLMCerebrasProvider.Create;
begin
  inherited Create;
  SetProviderIdentity('cerebras', 'Cerebras',
    'https://api.cerebras.ai/v1/chat/completions');
end;

constructor TAILLMOllamaProvider.Create;
begin
  inherited Create;
  SetProviderIdentity('ollama', 'Ollama',
    'http://localhost:11434/v1/chat/completions');
end;

{ Gemini }

constructor TAILLMGeminiProvider.Create;
begin
  inherited Create;
  SetProviderIdentity('gemini', 'Google Gemini',
    'https://generativelanguage.googleapis.com/v1beta/models/');
end;

function TAILLMGeminiProvider.BuildEndpoint(
  const AConfig: TAILLMProviderConfig): string;
var
  LBase: string;
begin
  LBase := Trim(AConfig.Endpoint);
  if LBase = '' then
    LBase := GetDefaultEndpoint;
  if Pos(':generatecontent', LowerCase(LBase)) = 0 then
  begin
    while (LBase <> '') and (LBase[Length(LBase)] = '/') do
      Delete(LBase, Length(LBase), 1);
    if Pos('/models', LowerCase(LBase)) = 0 then
      LBase := LBase + '/v1beta/models';
    LBase := LBase + '/' + AConfig.Model + ':generateContent';
  end;
  if (Trim(AConfig.Token) <> '') and (Pos('key=', LowerCase(LBase)) = 0) then
  begin
    if Pos('?', LBase) > 0 then
      LBase := LBase + '&key=' + AConfig.Token
    else
      LBase := LBase + '?key=' + AConfig.Token;
  end;
  Result := LBase;
end;

function TAILLMGeminiProvider.BuildRequest(
  const AConfig: TAILLMProviderConfig): string;
var
  LRoot, LContent, LPart, LGeneration, LSystem: TJSONObject;
  LContents, LParts, LSystemParts: TJSONArray;
begin
  LRoot := TJSONObject.Create;
  try
    LContents := TJSONArray.Create;
    LRoot.Add('contents', LContents);
    LContent := TJSONObject.Create;
    LContents.Add(LContent);
    LParts := TJSONArray.Create;
    LContent.Add('parts', LParts);
    LPart := TJSONObject.Create;
    LPart.Add('text', AConfig.UserPrompt);
    LParts.Add(LPart);
    if Trim(AConfig.SystemPrompt) <> '' then
    begin
      LSystem := TJSONObject.Create;
      LRoot.Add('system_instruction', LSystem);
      LSystemParts := TJSONArray.Create;
      LSystem.Add('parts', LSystemParts);
      LPart := TJSONObject.Create;
      LPart.Add('text', AConfig.SystemPrompt);
      LSystemParts.Add(LPart);
    end;
    LGeneration := TJSONObject.Create;
    LRoot.Add('generationConfig', LGeneration);
    if AConfig.MaxTokens > 0 then
      LGeneration.Add('maxOutputTokens', AConfig.MaxTokens);
    LGeneration.Add('temperature', AConfig.Temperature);
    Result := LRoot.AsJSON;
  finally
    LRoot.Free;
  end;
end;

procedure TAILLMGeminiProvider.BuildHeaders(
  const AConfig: TAILLMProviderConfig; AHeaders: TStrings);
begin
  inherited BuildHeaders(AConfig, AHeaders);
  AHeaders.Values['Authorization'] := '';
  if AHeaders.IndexOfName('Authorization') >= 0 then
    AHeaders.Delete(AHeaders.IndexOfName('Authorization'));
end;

function TAILLMGeminiProvider.ParseResponse(
  const ARawResponse: string): string;
var
  Data, Parts, Part: TJSONData;
  I: Integer;
begin
  Result := '';
  Data := nil;
  try
    Data := GetJSON(ARawResponse);
    Parts := Data.FindPath('candidates[0].content.parts');
    if (Parts <> nil) and (Parts.JSONType = jtArray) then
      for I := 0 to Parts.Count - 1 do
      begin
        Part := Parts.Items[I];
        if (Part.JSONType = jtObject) and not TJSONObject(Part).Get('thought', False) then
          Result := Result + TJSONObject(Part).Get('text', '');
      end;
  except
    Result := '';
  end;
  Data.Free;
end;

function TAILLMGeminiProvider.SupportsStreaming: Boolean;
begin
  Result := False;
end;

{ Claude }

constructor TAILLMClaudeProvider.Create;
begin
  inherited Create;
  SetProviderIdentity('claude', 'Anthropic Claude',
    'https://api.anthropic.com/v1/messages');
end;

function TAILLMClaudeProvider.BuildRequest(
  const AConfig: TAILLMProviderConfig): string;
var
  LRoot, LMessage: TJSONObject;
  LMessages: TJSONArray;
begin
  LRoot := TJSONObject.Create;
  try
    LRoot.Add('model', AConfig.Model);
    LRoot.Add('max_tokens', AConfig.MaxTokens);
    // New Claude models reject sampling parameters. Keep them for legacy IDs.
    if (Pos('claude-3-', AConfig.Model) = 1) or
       (Pos('claude-sonnet-4-5', AConfig.Model) = 1) or
       (Pos('claude-haiku-4-5', AConfig.Model) = 1) or
       (Pos('claude-opus-4-6', AConfig.Model) = 1) then
      LRoot.Add('temperature', AConfig.Temperature);
    if Trim(AConfig.SystemPrompt) <> '' then
      LRoot.Add('system', AConfig.SystemPrompt);
    LMessages := TJSONArray.Create;
    LRoot.Add('messages', LMessages);
    LMessage := TJSONObject.Create;
    LMessage.Add('role', 'user');
    LMessage.Add('content', AConfig.UserPrompt);
    LMessages.Add(LMessage);
    Result := LRoot.AsJSON;
  finally
    LRoot.Free;
  end;
end;

procedure TAILLMClaudeProvider.BuildHeaders(
  const AConfig: TAILLMProviderConfig; AHeaders: TStrings);
begin
  inherited BuildHeaders(AConfig, AHeaders);
  if AHeaders.IndexOfName('Authorization') >= 0 then
    AHeaders.Delete(AHeaders.IndexOfName('Authorization'));
  AHeaders.Values['x-api-key'] := AConfig.Token;
  AHeaders.Values['anthropic-version'] := '2023-06-01';
end;

function TAILLMClaudeProvider.ParseResponse(
  const ARawResponse: string): string;
var
  Data, Content, Block: TJSONData;
  I: Integer;
begin
  Result := '';
  Data := nil;
  try
    Data := GetJSON(ARawResponse);
    Content := Data.FindPath('content');
    if (Content <> nil) and (Content.JSONType = jtArray) then
      for I := 0 to Content.Count - 1 do
      begin
        Block := Content.Items[I];
        if (Block.JSONType = jtObject) and
           (TJSONObject(Block).Get('type', '') = 'text') then
          Result := Result + TJSONObject(Block).Get('text', '');
      end;
  except
    Result := '';
  end;
  Data.Free;
end;

function TAILLMClaudeProvider.SupportsStreaming: Boolean;
begin
  Result := False;
end;

{ Factory }

class function TAILLMProviderFactory.CreateProvider(
  AKind: TAILLMProviderKind): IAILLMProvider;
begin
  case AKind of
    llmOpenAI: Result := TAILLMOpenAIProvider.Create;
    llmOpenAICompatible: Result := TAILLMOpenAICompatibleProvider.Create;
    llmLlamaCpp: Result := TAILLMLlamaCppProvider.Create;
    llmNeuralAPI: Result := TAILLMNeuralAPIProvider.Create;
    llmGemini: Result := TAILLMGeminiProvider.Create;
    llmClaude: Result := TAILLMClaudeProvider.Create;
    llmDeepSeek: Result := TAILLMDeepSeekProvider.Create;
    llmOpenRouter: Result := TAILLMOpenRouterProvider.Create;
    llmCerebras: Result := TAILLMCerebrasProvider.Create;
    llmOllama: Result := TAILLMOllamaProvider.Create;
    llmRunPod: Result := TAILLMHostedCompatibleProvider.CreateHosted('runpod', 'RunPod',
      'https://api.runpod.ai/v2/ENDPOINT_ID/openai/v1/chat/completions');
    llmGroq: Result := TAILLMHostedCompatibleProvider.CreateHosted('groq', 'Groq',
      'https://api.groq.com/openai/v1/chat/completions');
    llmMistral: Result := TAILLMHostedCompatibleProvider.CreateHosted('mistral', 'Mistral',
      'https://api.mistral.ai/v1/chat/completions');
    llmXAI: Result := TAILLMHostedCompatibleProvider.CreateHosted('xai', 'xAI',
      'https://api.x.ai/v1/chat/completions');
    llmQwen: Result := TAILLMHostedCompatibleProvider.CreateHosted('qwen', 'Qwen',
      'https://WORKSPACE_ID.ap-southeast-1.maas.aliyuncs.com/compatible-mode/v1/chat/completions');
  else
    Result := TAILLMOpenAIProvider.Create;
  end;
end;

class function TAILLMProviderFactory.KindFromName(
  const AName: string): TAILLMProviderKind;
var
  LName: string;
begin
  LName := LowerCase(Trim(AName));
  if (LName = 'openai-compatible') or (LName = 'compatible') then
    Result := llmOpenAICompatible
  else if (LName = 'llama.cpp') or (LName = 'llamacpp') then
    Result := llmLlamaCpp
  else if (LName = 'neural-api') or (LName = 'neuralapi') then
    Result := llmNeuralAPI
  else if (LName = 'gemini') or (LName = 'google gemini') then
    Result := llmGemini
  else if (LName = 'claude') or (LName = 'anthropic') or (LName = 'anthropic claude') then
    Result := llmClaude
  else if (LName = 'deepseek') or (LName = 'deepseek direct') then
    Result := llmDeepSeek
  else if LName = 'openrouter' then
    Result := llmOpenRouter
  else if LName = 'cerebras' then
    Result := llmCerebras
  else if (LName = 'ollama') or (LName = 'local') or (LName = 'local (ollama / llama.cpp)') then
    Result := llmOllama
  else if LName = 'runpod' then Result := llmRunPod
  else if LName = 'groq' then Result := llmGroq
  else if LName = 'mistral' then Result := llmMistral
  else if (LName = 'xai') or (LName = 'grok') then Result := llmXAI
  else if (LName = 'qwen') or (LName = 'alibaba') or (LName = 'dashscope') then Result := llmQwen
  else
    Result := llmOpenAI;
end;

end.
