program llm_model_catalog_test;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}cthreads,{$ENDIF}
  Classes, SysUtils, IniFiles, fpjson, jsonparser,
  chatgpt, aillmmodelcatalog, aillmproviders, aimodelregistry;

var
  Checks: Integer = 0;

procedure Check(OK: Boolean; const Description: string);
begin
  Inc(Checks);
  if not OK then
    raise Exception.Create('FAIL: ' + Description);
end;

procedure TestCatalogAndRegistry;
var
  Registry: TAIModelRegistry;
  Client: TCHATGPT;
  Models, Seen: TStringList;
  Info, Found: TAILLMModelInfo;
  P, Parsed: TAIProvider;
  I, J: Integer;
  Key, FileName: string;
begin
  Check(Ord(AIP_NEURAL_API) = 9, 'legacy provider ordinal');
  Check(Ord(VCT_CUSTOM) = 36, 'legacy custom model ordinal');
  Check(Ord(VCT_GPT5) = 11, 'legacy GPT-5 ordinal');
  Registry := TAIModelRegistry.Create(nil);
  Client := TCHATGPT.Create(nil);
  Models := TStringList.Create;
  Seen := TStringList.Create;
  FileName := GetTempFileName(GetTempDir, 'catalog');
  try
    for I := 0 to AILLMModelCount - 1 do
    begin
      Check(GetAILLMModelInfo(I, Info), 'catalog index ' + IntToStr(I));
      Key := LowerCase(Info.Provider + '/' + Info.InternalName);
      Check(Seen.IndexOf(Key) < 0, 'duplicate model ' + Key);
      Seen.Add(Key);
      Check(TryGetAIProviderFromName(Info.Provider, P), 'provider ' + Info.Provider);
      if not Info.IsLegacy then
      begin
        Registry.ApplyModel(Info.FriendlyName, Client);
        Check(Registry.LastSuccess, 'apply ' + Info.FriendlyName);
        Check(Client.Provider = P, 'registry provider ' + Key);
        Check(Client.TipoModelo = Info.InternalName, 'model preserved ' + Key);
      end;
    end;
    Check(not GetAILLMModelInfo(AILLMModelCount, Info), 'catalog upper bound');
    for P := Low(TAIProvider) to High(TAIProvider) do
    begin
      GetAIModelListForProvider(P, Models);
      Check(Models.Count > 0, 'non-empty provider catalog ' + GetAIProviderName(P));
      for J := 0 to Models.Count - 1 do
      begin
        Check(FindAILLMModel(GetAIProviderCatalogName(P), Models[J], Found), 'model lookup');
        Check(not Found.IsLegacy, 'legacy model hidden');
      end;
      Client.Provider := P;
      Client.CustomModel := Models[0];
      Client.URL := GetDefaultEndpointForProvider(P);
      Check(Client.SaveToIni(FileName), 'save provider');
      Client.Provider := AIP_OPENAI;
      Check(Client.LoadFromIni(FileName), 'reload provider');
      Check(Client.Provider = P, 'provider persisted ' + GetAIProviderName(P));
    end;
    Check(TryGetAIProviderFromName('Ollama', Parsed) and (Parsed = AIP_LOCAL), 'Ollama alias');
    Check(TryGetAIProviderFromName('Anthropic', Parsed) and (Parsed = AIP_CLAUDE), 'Anthropic alias');
    Check(TryGetAIProviderFromName('DashScope', Parsed) and (Parsed = AIP_QWEN), 'DashScope alias');
    Registry.SaveToFile(FileName);
    Registry.LoadFromFile(FileName);
    Check(Registry.Models.Count = AILLMModelCount, 'registry JSON round trip');
    Registry.GetModels('Claude', Models);
    Check(Models.IndexOf('Claude 3.5 Sonnet (Anthropic)') < 0, 'legacy flag persisted');
    Client.URL := 'https://previous.invalid/v1/chat/completions';
    Registry.ApplyModel('Gemini 3.8 Flash', Client);
    Check(Client.URL = '', 'switch to Gemini clears previous endpoint');
    Client.Provider := AIP_OPENAI;
    for I := 0 to 2 do
    begin
      case I of
        0: Client.CustomModel := 'gpt-4.1';
        1: Client.CustomModel := 'gpt-4.1-mini';
        2: Client.CustomModel := 'gpt-5';
      end;
      Check(Client.TipoModelo = Client.CustomModel, 'valid model must not be rewritten');
    end;
    Client.CustomModel := '';
    Client.TipoChat := VCT_GPT41;
    Check(Client.TipoModelo = 'gpt-4.1', 'legacy enum uses the selected GPT-4.1');
  finally
    DeleteFile(FileName);
    Seen.Free;
    Models.Free;
    Client.Free;
    Registry.Free;
  end;
end;

procedure TestRequestFormats;
var
  Backend: IAILLMProvider;
  Config: TAILLMProviderConfig;
  Data: TJSONData;
  Answer: string;
begin
  InitAILLMProviderConfig(Config);
  Config.UserPrompt := 'Teste sem chamada remota';
  Config.Model := 'gpt-6.1-sol';
  Config.MaxTokens := 8192;
  Backend := TAILLMProviderFactory.CreateProvider(llmOpenAI);
  Data := GetJSON(Backend.BuildRequest(Config));
  try
    Check(Data.FindPath('max_completion_tokens').AsInteger = 8192, 'reasoning token budget');
    Check(Data.FindPath('max_tokens') = nil, 'no legacy token field for reasoning');
    Check(Data.FindPath('temperature') = nil, 'no unsupported reasoning temperature');
  finally Data.Free; end;
  Config.Model := 'gpt-4o-mini';
  Data := GetJSON(Backend.BuildRequest(Config));
  try
    Check(Data.FindPath('max_tokens') <> nil, 'legacy OpenAI token field retained');
    Check(Data.FindPath('temperature') <> nil, 'legacy OpenAI temperature retained');
  finally Data.Free; end;
  Backend := TAILLMProviderFactory.CreateProvider(llmClaude);
  Config.Model := 'claude-sonnet-5-5';
  Data := GetJSON(Backend.BuildRequest(Config));
  try Check(Data.FindPath('temperature') = nil, 'current Claude omits temperature');
  finally Data.Free; end;
  Check(Backend.ParseResponse('{"content":[{"type":"thinking","thinking":"private"},' +
    '{"type":"text","text":"Ola "},{"type":"text","text":"Marcelo"}]}') = 'Ola Marcelo',
    'Claude text following reasoning blocks');
  Check(Backend.ParseResponse('invalid') = '', 'malformed Claude response');
  Backend := TAILLMProviderFactory.CreateProvider(llmGemini);
  Check(Backend.ParseResponse('{"candidates":[{"content":{"parts":[' +
    '{"thought":true,"text":"private"},{"text":"Ola "},{"text":"Marcelo"}]}}]}') = 'Ola Marcelo',
    'Gemini ignores thought and joins text parts');
  Check(Backend.ParseResponse('invalid') = '', 'malformed Gemini response');
  Backend := TAILLMProviderFactory.CreateProvider(llmGroq);
  Config.Endpoint := 'https://api.groq.com/openai/v1';
  Check(Backend.BuildEndpoint(Config) = 'https://api.groq.com/openai/v1/chat/completions',
    'no duplicated v1 in Groq base URL');
  Backend := TAILLMProviderFactory.CreateProvider(llmQwen);
  Config.Endpoint := '';
  Check(not Backend.Send(Config, nil, Answer), 'Qwen placeholder fails before network');
  Check(Pos('workspace', Backend.GetLastError) > 0, 'workspace configuration error');
  Backend := TAILLMProviderFactory.CreateProvider(llmRunPod);
  Check(not Backend.Send(Config, nil, Answer), 'RunPod placeholder fails before network');
  Check(TAILLMProviderFactory.KindFromName('RunPod') = llmRunPod, 'RunPod factory route');
  Check(TAILLMProviderFactory.KindFromName('xAI') = llmXAI, 'xAI factory route');
end;

begin
  try
    TestCatalogAndRegistry;
    TestRequestFormats;
    WriteLn('LLM catalog: ', Checks, ' checks passed; ', AILLMModelCount,
      ' entries; ', Ord(High(TAIProvider)) + 1, ' providers.');
  except
    on E: Exception do
    begin
      WriteLn(E.Message);
      Halt(1);
    end;
  end;
end.
