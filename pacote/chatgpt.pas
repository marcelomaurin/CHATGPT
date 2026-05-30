unit chatgpt;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, LazUTF8, fpjson, jsonparser,
  fphttpclient, opensslsockets;

const
  CHATGPT_LIB_VERSION = '1.6';

type
  TVersionChat = (
    VCT_GPT35TURBO,
    VCT_GPT40,
    VCT_GPT40_TURBO,
    VCT_GPT4o,
    VCT_GPTo3_mini,
    VCT_GPT41,
    VCT_GPT41_MINI,
    VCT_GPT5,

    // Modelos locais / Ollama
    VCT_LLAMA32_3B,
    VCT_QWEN25_15B,
    VCT_DEEPSEEK_R1_15B,
    VCT_DEEPSEEK_R1_8B,
    VCT_DEEPSEEK_R1_14B,
    VCT_DEEPSEEK_R1_70B,

    VCT_CUSTOM
  );

  TAIProvider = (
    AIP_OPENAI,      // 0
    AIP_OPENROUTER, // 1
    AIP_CEREBRAS,   // 2
    AIP_LOCAL       // 3 - llama.cpp / Ollama local
  );

  { TCHATGPT }

  TCHATGPT = class(TComponent)
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

    function RequestJson(const LURL, token, ASK: WideString): WideString;
    function PegaMensagem(const JSON: WideString): WideString;
    function GetEndpoint: WideString;
    function GetModelName: WideString;
    function MontaURLChatLocal(const AServidor: WideString): WideString;
    procedure AddProviderHeaders(AHTTP: TFPHttpClient);
  public

    property TOKEN: WideString read FToken write FToken;
    property Question: WideString read FQuestion;
    property Response: WideString read FResponse write FResponse;
    property Dev: WideString read FDev write FDev;
    property TipoChat: TVersionChat read FTipoChat write FTipoChat;
    property Provider: TAIProvider read FProvider write FProvider;
    property CustomModel: WideString read FCustomModel write FCustomModel;
    property LocalIP: WideString read FLocalIP write FLocalIP;
    property MaxTokens: Integer read FMaxTokens write FMaxTokens;

    // Opcionais para OpenRouter
    property OpenRouterTitle: WideString read FOpenRouterTitle write FOpenRouterTitle;
    property OpenRouterSite: WideString read FOpenRouterSite write FOpenRouterSite;

    property LastJSON: WideString read FLastJSON;

    function SendQuestion(ASK: WideString): Boolean;
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    function TipoModelo: WideString;
    function ProviderName: WideString;
    function VersaoBiblioteca: WideString;
  end;

procedure Register;

implementation

function JsonEscape(const S: WideString): WideString;
var
  R: WideString;
begin
  R := StringReplace(S, '\', '\\', [rfReplaceAll]);
  R := StringReplace(R, '"', '\"', [rfReplaceAll]);
  R := StringReplace(R, #13#10, '\n', [rfReplaceAll]);
  R := StringReplace(R, #10, '\n', [rfReplaceAll]);
  R := StringReplace(R, #13, '\n', [rfReplaceAll]);
  Result := R;
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
                    Result := ContentData.AsString;
                end;
              end;
            end;
          end;
        end;
      finally
        Data.Free;
      end;
    except
      // Falha silenciosa no parser retorna a mensagem bruta
      Result := '';
    end;
  finally
    Parser.Free;
  end;
end;

function TCHATGPT.GetEndpoint: WideString;
begin
  case FProvider of
    AIP_OPENAI:
      Result := 'https://api.openai.com/v1/chat/completions';

    AIP_OPENROUTER:
      Result := 'https://openrouter.ai/api/v1/chat/completions';

    AIP_CEREBRAS:
      Result := 'https://api.cerebras.ai/v1/chat/completions';

    AIP_LOCAL:
      Result := MontaURLChatLocal(FLocalIP);
  else
    Result := 'https://api.openai.com/v1/chat/completions';
  end;
end;

function TCHATGPT.GetModelName: WideString;
begin
  // Se informou modelo customizado, respeita sempre.
  if Trim(FCustomModel) <> '' then
    Exit(Trim(FCustomModel));

  // Local / Ollama — mapeia enums específicos
  if FProvider = AIP_LOCAL then
  begin
    case FTipoChat of
      VCT_LLAMA32_3B:       Result := 'llama3.2:3b';
      VCT_QWEN25_15B:       Result := 'qwen2.5:1.5b';
      VCT_DEEPSEEK_R1_15B:  Result := 'deepseek-r1:1.5b';
      VCT_DEEPSEEK_R1_8B:   Result := 'deepseek-r1:8b';
      VCT_DEEPSEEK_R1_14B:  Result := 'deepseek-r1:14b';
      VCT_DEEPSEEK_R1_70B:  Result := 'deepseek-r1:70b';
    else
      Result := 'llama3.2:3b';
    end;
    Exit;
  end;

  // Cerebras
  if FProvider = AIP_CEREBRAS then
  begin
    Exit('qwen-3-235b-a22b-instruct-2507');
  end;

  // OpenRouter
  if FProvider = AIP_OPENROUTER then
  begin
    Exit('google/gemma-2-9b-it:free');
  end;

  // OpenAI
  case FTipoChat of
    VCT_GPT35TURBO:    Result := 'gpt-3.5-turbo';
    VCT_GPT40:         Result := 'gpt-4';
    VCT_GPT40_TURBO:   Result := 'gpt-4-turbo-preview';
    VCT_GPT4o:         Result := 'gpt-4o';
    VCT_GPTo3_mini:    Result := 'o3-mini';
    VCT_GPT41:         Result := 'gpt-4.1';
    VCT_GPT41_MINI:    Result := 'gpt-4.1-mini';
    VCT_GPT5:          Result := 'gpt-5';
    VCT_CUSTOM:        Result := Trim(FCustomModel);
  else
    Result := 'gpt-4o';
  end;
end;

procedure TCHATGPT.AddProviderHeaders(AHTTP: TFPHttpClient);
begin
  if AHTTP = nil then
    Exit;

  AHTTP.AddHeader('Content-Type', 'application/json');
  AHTTP.AddHeader('Accept', 'application/json');

  // Local / llama.cpp não necessita de Bearer Token por padrão
  if FProvider = AIP_LOCAL then
    Exit;

  if Trim(FToken) <> '' then
    AHTTP.AddHeader('Authorization', 'Bearer ' + FToken);

  if FProvider = AIP_OPENROUTER then
  begin
    if Trim(FOpenRouterSite) <> '' then
      AHTTP.AddHeader('HTTP-Referer', FOpenRouterSite);

    if Trim(FOpenRouterTitle) <> '' then
      AHTTP.AddHeader('X-OpenRouter-Title', FOpenRouterTitle);
  end;
end;

function TCHATGPT.RequestJson(const LURL, token, ASK: WideString): WideString;
var
  ClienteHTTP: TFPHttpClient;
  BodyStream: TStringStream;
  root, mSys, mUser: TJSONObject;
  msgs: TJSONArray;
  payload: UTF8String;
begin
  root := TJSONObject.Create;
  try
    root.Add('model', GetModelName);

    msgs := TJSONArray.Create;
    root.Add('messages', msgs);

    if Trim(FDev) <> '' then
    begin
      mSys := TJSONObject.Create;
      mSys.Add('role', 'system');
      mSys.Add('content', FDev);
      msgs.Add(mSys);
    end;

    mUser := TJSONObject.Create;
    mUser.Add('role', 'user');
    mUser.Add('content', ASK);
    msgs.Add(mUser);

    root.Add('temperature', 0.7);
    if FMaxTokens > 0 then
      root.Add('max_tokens', FMaxTokens);

    payload := UTF8Encode(root.AsJSON);
  finally
    root.Free;
  end;

  ClienteHTTP := TFPHttpClient.Create(nil);
  BodyStream := TStringStream.Create(payload);
  try
    AddProviderHeaders(ClienteHTTP);

    ClienteHTTP.AllowRedirect := True;
    ClienteHTTP.KeepConnection := True;

    if FProvider = AIP_LOCAL then
    begin
      ClienteHTTP.IOTimeout := 1500000;
      ClienteHTTP.ConnectTimeout := 1500000;
    end
    else
    begin
      ClienteHTTP.IOTimeout := 60000;
      ClienteHTTP.ConnectTimeout := 60000;
    end;

    ClienteHTTP.RequestBody := BodyStream;

    try
      Result := ClienteHTTP.Post(LURL);
    except
      on E: Exception do
        Result := Format('{"error":{"message":"%s"}}',
          [StringReplace(E.Message, '"', '\"', [rfReplaceAll])]);
    end;
  finally
    BodyStream.Free;
    ClienteHTTP.Free;
  end;
end;

function TCHATGPT.SendQuestion(ASK: WideString): Boolean;
var
  LURL, AUX: WideString;
  ErrorParser: TJSONParser;
  ErrorData: TJSONData;
  ErrorObj: TJSONObject;
  HasError: Boolean;
begin
  Result := False;
  FQuestion := ASK;

  try
    LURL := GetEndpoint;
  except
    on E: Exception do
    begin
      FResponse := Format('{"error":{"message":"%s"}}',
        [StringReplace(E.Message, '"', '\"', [rfReplaceAll])]);
      FLastJSON := FResponse;
      Exit(False);
    end;
  end;

  AUX := RequestJson(LURL, FToken, ASK);
  FLastJSON := AUX;

  // Verifica erro no JSON retornado por parse estruturado
  HasError := False;
  ErrorParser := TJSONParser.Create(AUX);
  try
    try
      ErrorData := ErrorParser.Parse;
      try
        if (ErrorData.JSONType = jtObject) then
        begin
          ErrorObj := TJSONObject(ErrorData);
          if ErrorObj.IndexOfName('error') >= 0 then
            HasError := True;
        end;
      finally
        ErrorData.Free;
      end;
    except
      // Se não conseguir parsear, não é erro de API
      HasError := False;
    end;
  finally
    ErrorParser.Free;
  end;

  if HasError then
  begin
    FResponse := AUX;
    Exit(False);
  end;

  try
    FResponse := PegaMensagem(AUX);
    Result := (Trim(FResponse) <> '');

    if not Result then
      FResponse := AUX;
  except
    FResponse := AUX;
    Result := False;
  end;
end;

constructor TCHATGPT.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FProvider := AIP_OPENAI;
  FTipoChat := VCT_GPT4o;

  FDev := 'Você é um assistente.';
  FParams := TStringList.Create;
  FCustomModel := '';
  FOpenRouterTitle := '';
  FOpenRouterSite := '';
  FLastJSON := '';
  FLocalIP := 'http://localhost:11434';
  FMaxTokens := 4096;
end;

destructor TCHATGPT.Destroy;
begin
  FParams.Free;
  inherited;
end;

function TCHATGPT.TipoModelo: WideString;
begin
  Result := '"' + GetModelName + '"';
end;

function TCHATGPT.ProviderName: WideString;
begin
  case FProvider of
    AIP_OPENAI:     Result := 'OpenAI';
    AIP_OPENROUTER: Result := 'OpenRouter';
    AIP_CEREBRAS:   Result := 'Cerebras';
    AIP_LOCAL:      Result := 'Local';
  else
    Result := 'OpenAI';
  end;
end;

function TCHATGPT.VersaoBiblioteca: WideString;
begin
  Result := CHATGPT_LIB_VERSION;
end;

procedure Register;
begin
  RegisterComponents('IA', [TCHATGPT]);
end;

end.
