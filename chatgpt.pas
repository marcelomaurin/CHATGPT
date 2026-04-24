unit chatgpt;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, LazUTF8, fpjson, jsonparser,
  fphttpclient, opensslsockets, funcoes;

const
  CHATGPT_LIB_VERSION = '1.3';

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
    VCT_CUSTOM
  );

  TAIProvider = (
    AIP_OPENAI,
    AIP_OPENROUTER,
    AIP_CEREBRAS
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

    function RequestJson(const LURL, token, ASK: WideString): WideString;
    function PegaMensagem(const JSON: WideString): WideString;
    function GetEndpoint: WideString;
    function GetModelName: WideString;
    procedure AddProviderHeaders(AHTTP: TFPHttpClient);
  public
    property TOKEN: WideString read FToken write FToken;
    property Question: WideString read FQuestion;
    property Response: WideString read FResponse write FResponse;
    property Dev: WideString read FDev write FDev;
    property TipoChat: TVersionChat read FTipoChat write FTipoChat;
    property Provider: TAIProvider read FProvider write FProvider;
    property CustomModel: WideString read FCustomModel write FCustomModel;

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
  else
    Result := 'https://api.openai.com/v1/chat/completions';
  end;
end;

function TCHATGPT.GetModelName: WideString;
begin
  // Cerebras usa modelo proprio da API dela
  // Se CustomModel for informado, usa ele
  // Senao, usa o default do exemplo informado: llama3.1-8b
  if FProvider = AIP_CEREBRAS then
  begin
    if Trim(FCustomModel) <> '' then
      Exit(Trim(FCustomModel))
    else
      //Exit('llama3.1-8b');
      Exit('qwen-3-235b-a22b-instruct-2507');
  end;

  // Para outros providers, se for custom, usa custom
  if (FTipoChat = VCT_CUSTOM) and (Trim(FCustomModel) <> '') then
    Exit(Trim(FCustomModel));

  case FTipoChat of
    VCT_GPT35TURBO:    Result := 'gpt-3.5-turbo';
    VCT_GPT40:         Result := 'gpt-4';
    VCT_GPT40_TURBO:   Result := 'gpt-4-turbo-preview';
    VCT_GPT4o:         Result := 'gpt-4o';
    VCT_GPTo3_mini:    Result := 'gpt-o3-mini';
    VCT_GPT41:         Result := 'gpt-4.1';
    VCT_GPT41_MINI:    Result := 'gpt-4.1-mini';
    VCT_GPT5:          Result := 'gpt-5';
    VCT_CUSTOM:        Result := Trim(FCustomModel);
  else
    Result := 'gpt-4.1-mini';
  end;
end;

procedure TCHATGPT.AddProviderHeaders(AHTTP: TFPHttpClient);
begin
  if AHTTP = nil then
    Exit;

  AHTTP.AddHeader('Content-Type', 'application/json');
  AHTTP.AddHeader('Accept', 'application/json');
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

    mSys := TJSONObject.Create;
    mSys.Add('role', 'system');
    mSys.Add('content', FDev);
    msgs.Add(mSys);

    mUser := TJSONObject.Create;
    mUser.Add('role', 'user');
    mUser.Add('content', ASK);
    msgs.Add(mUser);

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
    ClienteHTTP.IOTimeout := 60000;
    ClienteHTTP.ConnectTimeout := 60000;
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
begin
  Result := False;
  FQuestion := ASK;
  LURL := GetEndpoint;
  AUX := RequestJson(LURL, FToken, ASK);
  FLastJSON := AUX;

  if Pos('"error"', LowerCase(AUX)) > 0 then
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
  FTipoChat := VCT_GPT41_MINI;
  FProvider := AIP_OPENAI;
  FDev := 'Você é um assistente.';
  FParams := TStringList.Create;
  FCustomModel := '';
  FOpenRouterTitle := '';
  FOpenRouterSite := '';
  FLastJSON := '';
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
  else
    Result := 'OpenAI';
  end;
end;

function TCHATGPT.VersaoBiblioteca: WideString;
begin
  Result := CHATGPT_LIB_VERSION;
end;

end.
