unit chatgpt;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, LazUTF8, fpjson, jsonparser,
  fphttpclient, opensslsockets, LResources, aibase;

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
    AIP_DEEPSEEK     // 6 - DeepSeek Direct API
  );

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
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    function SendQuestion(ASK: WideString): Boolean;
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

    // Opcionais para OpenRouter
    property OpenRouterTitle: WideString read FOpenRouterTitle write FOpenRouterTitle;
    property OpenRouterSite: WideString read FOpenRouterSite write FOpenRouterSite;

    property LastJSON: WideString read FLastJSON;
    property LastURL: WideString read FLastURL;
  end;

function GetAIProviderName(AProvider: TAIProvider): string;
function GetAIProviderFromIndex(AIndex: Integer): TAIProvider;
function GetDefaultEndpointForProvider(AProvider: TAIProvider): string;
procedure GetAIProviderList(AOutList: TStrings);
procedure GetAIModelListForProvider(AProvider: TAIProvider; AOutList: TStrings);

procedure Register;

implementation

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
begin
  if AOutList = nil then Exit;
  AOutList.Clear;
  case AProvider of
    AIP_OPENAI:
    begin
      AOutList.Add('gpt-4o-mini');
      AOutList.Add('gpt-4o');
      AOutList.Add('o3-mini');
      AOutList.Add('o1');
      AOutList.Add('o1-mini');
      AOutList.Add('gpt-4-turbo');
      AOutList.Add('gpt-3.5-turbo');
    end;

    AIP_DEEPSEEK:
    begin
      AOutList.Add('deepseek-chat');
      AOutList.Add('deepseek-reasoner');
    end;

    AIP_GEMINI:
    begin
      AOutList.Add('gemini-2.0-flash');
      AOutList.Add('gemini-1.5-pro');
      AOutList.Add('gemini-1.5-flash');
    end;

    AIP_CLAUDE:
    begin
      AOutList.Add('claude-3-5-sonnet-20241022');
      AOutList.Add('claude-3-5-haiku-20241022');
      AOutList.Add('claude-3-opus-20240229');
    end;

    AIP_OPENROUTER:
    begin
      AOutList.Add('meta-llama/llama-3.3-70b-instruct:free');
      AOutList.Add('deepseek/deepseek-r1:free');
      AOutList.Add('google/gemma-2-9b-it:free');
      AOutList.Add('meta-llama/llama-3.2-3b-instruct:free');
    end;

    AIP_CEREBRAS:
    begin
      AOutList.Add('llama3.1-8b');
      AOutList.Add('llama3.1-70b');
      AOutList.Add('qwen-3-235b-a22b-instruct-2507');
    end;

    AIP_LOCAL:
    begin
      AOutList.Add('llama3.2:3b');
      AOutList.Add('deepseek-r1:1.5b');
      AOutList.Add('deepseek-r1:8b');
      AOutList.Add('deepseek-r1:14b');
      AOutList.Add('qwen2.5:1.5b');
    end;
  end;
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

  FParams := TStringList.Create;
  FPrompt := 'TCHATGPT e o componente principal para comunicacao com OpenAI ChatGPT, OpenRouter, Cerebras, DeepSeek, Google Gemini, Claude e Ollama local.';
  ClearError;
end;

destructor TCHATGPT.Destroy;
begin
  FParams.Free;
  inherited Destroy;
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
  HTTP: TFPHttpClient;
  JSONPayload: string;
  RawResponse: string;
  Endpoint: string;
begin
  Result := False;
  ClearError;
  FQuestion := ASK;
  FResponse := '';
  FLastJSON := '';
  FLastURL := '';

  if (FProvider <> AIP_LOCAL) and (FProvider <> AIP_GEMINI) and (Trim(FToken) = '') then
  begin
    SetError('Token de API nao configurado.');
    Exit;
  end;

  Endpoint := GetEndpoint;
  FLastURL := Endpoint;

  JSONPayload := UTF8Encode(MontaJson);
  FLastJSON := UTF8ToUTF16(JSONPayload);

  HTTP := TFPHttpClient.Create(nil);
  try
    AddProviderHeaders(HTTP);
    HTTP.RequestBody := TStringStream.Create(JSONPayload);
    try
      try
        RawResponse := HTTP.Post(Endpoint);
        FResponse := PegaMensagem(UTF8ToUTF16(RawResponse));
        Result := Trim(FResponse) <> '';
        FLastSuccess := Result;
        if not Result then
          SetError('Resposta vazia da API: ' + RawResponse);
      except
        on E: Exception do
        begin
          SetError('Erro HTTP na requisicao AI: ' + E.Message);
          Result := False;
        end;
      end;
    finally
      HTTP.RequestBody.Free;
    end;
  finally
    HTTP.Free;
  end;
end;

procedure TCHATGPT.Cancel;
begin
  // Operacao cancelada
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

end.
