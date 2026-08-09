program llm_provider_streaming_test;

{$mode objfpc}{$H+}

uses
  Interfaces, Classes, SysUtils, Windows, fpjson, jsonparser,
  aillmproviders, chatgpt;

type
  TEventProbe = class
  public
    MainThreadID: TThreadID;
    EventCount: Integer;
    Sequence: string;
    procedure StreamStart(Sender: TObject);
    procedure StreamData(Sender: TObject; const AData: WideString);
    procedure StreamEnd(Sender: TObject);
    procedure Complete(Sender: TObject; ASuccess: Boolean);
    procedure StateChange(Sender: TObject; AState: TAILLMRequestState);
  end;

procedure Fail(const AMessage: string);
begin
  Writeln(StdErr, 'FAIL: ', AMessage);
  Halt(1);
end;

procedure Check(ACondition: Boolean; const AMessage: string);
begin
  if not ACondition then
    Fail(AMessage);
end;

procedure CheckMainThread(const AProbe: TEventProbe);
begin
  Check(GetCurrentThreadID = AProbe.MainThreadID,
    'callback assincrono fora da thread principal');
end;

procedure TEventProbe.StreamStart(Sender: TObject);
begin
  CheckMainThread(Self);
  Inc(EventCount);
  Sequence := Sequence + 'start>';
end;

procedure TEventProbe.StreamData(Sender: TObject; const AData: WideString);
begin
  CheckMainThread(Self);
  Check(AData <> '', 'evento de streaming vazio');
  Inc(EventCount);
  Sequence := Sequence + 'data>';
end;

procedure TEventProbe.StreamEnd(Sender: TObject);
begin
  CheckMainThread(Self);
  Inc(EventCount);
  Sequence := Sequence + 'end>';
end;

procedure TEventProbe.Complete(Sender: TObject; ASuccess: Boolean);
begin
  CheckMainThread(Self);
  Inc(EventCount);
  Sequence := Sequence + 'complete>';
end;

procedure TEventProbe.StateChange(Sender: TObject; AState: TAILLMRequestState);
begin
  CheckMainThread(Self);
end;

procedure TestProviderContracts;
const
  Kinds: array[0..9] of TAILLMProviderKind = (
    llmOpenAI, llmOpenAICompatible, llmLlamaCpp, llmNeuralAPI,
    llmGemini, llmClaude, llmDeepSeek, llmOpenRouter, llmCerebras,
    llmOllama
  );
var
  I: Integer;
  P: IAILLMProvider;
  C: TAILLMProviderConfig;
  H: TStringList;
  J: TJSONData;
  Payload: string;
begin
  InitAILLMProviderConfig(C);
  C.Model := 'test-model';
  C.UserPrompt := 'ola';
  C.SystemPrompt := 'sistema';
  C.Token := 'secret';
  for I := Low(Kinds) to High(Kinds) do
  begin
    P := TAILLMProviderFactory.CreateProvider(Kinds[I]);
    Check(P <> nil, 'factory retornou nil');
    Check(P.GetProviderID <> '', 'provider sem identificador');
    Check(P.BuildEndpoint(C) <> '', 'provider sem endpoint');
    Payload := P.BuildRequest(C);
    J := GetJSON(Payload);
    J.Free;
    H := TStringList.Create;
    try
      P.BuildHeaders(C, H);
      Check(H.IndexOfName('Content-Type') >= 0, 'Content-Type ausente');
    finally
      H.Free;
    end;
  end;

  P := TAILLMProviderFactory.CreateProvider(llmOpenAI);
  C.Temperature := 0.2;
  J := GetJSON(P.BuildRequest(C));
  try
    Check(Abs(J.FindPath('temperature').AsFloat - 0.2) < 0.0001,
      'Temperature 0.2 ausente do request');
  finally
    J.Free;
  end;
  C.Temperature := 1.4;
  J := GetJSON(P.BuildRequest(C));
  try
    Check(Abs(J.FindPath('temperature').AsFloat - 1.4) < 0.0001,
      'Temperature 1.4 ausente do request');
  finally
    J.Free;
  end;
  Check(P.ParseResponse('{"choices":[{"message":{"content":"openai-ok"}}]}') =
    'openai-ok', 'parser OpenAI');
  P := TAILLMProviderFactory.CreateProvider(llmGemini);
  Check(P.ParseResponse('{"candidates":[{"content":{"parts":[{"text":"gemini-ok"}]}}]}') =
    'gemini-ok', 'parser Gemini');
  P := TAILLMProviderFactory.CreateProvider(llmClaude);
  Check(P.ParseResponse('{"content":[{"type":"text","text":"claude-ok"}]}') =
    'claude-ok', 'parser Claude');
end;

procedure WaitForRequest(AChat: TCHATGPT; ATimeoutMS: QWord);
var
  Started: QWord;
begin
  Started := GetTickCount64;
  repeat
    CheckSynchronize(20);
    Sleep(5);
    if GetTickCount64 - Started > ATimeoutMS then
      Fail('timeout aguardando requisicao assincrona');
  until not AChat.Busy;
  CheckSynchronize(20);
end;

procedure TestHTTPFlow(const AEndpoint: string);
var
  Chat: TCHATGPT;
  Probe: TEventProbe;
  Started: QWord;
  J: TJSONData;
begin
  Chat := TCHATGPT.Create(nil);
  Probe := TEventProbe.Create;
  try
    Probe.MainThreadID := GetCurrentThreadID;
    Chat.Provider := AIP_OPENAI_COMPATIBLE;
    Chat.URL := AEndpoint;
    Chat.CustomModel := 'mock-model';
    Chat.Temperature := 0.35;
    Chat.Timeout := 5000;
    Chat.OnStreamStart := @Probe.StreamStart;
    Chat.OnStreamData := @Probe.StreamData;
    Chat.OnStreamEnd := @Probe.StreamEnd;
    Chat.OnRequestComplete := @Probe.Complete;
    Chat.OnStateChange := @Probe.StateChange;

    Chat.Streaming := False;
    Check(Chat.SendQuestion('sync'), 'SendQuestion sincrono: ' + Chat.LastError);
    Check(Chat.Response = 'mock-sync', 'resposta sincrona inesperada');
    J := GetJSON(UTF8Encode(Chat.LastJSON));
    try
      Check(Abs(J.FindPath('temperature').AsFloat - 0.35) < 0.0001,
        'Temperature nao propagada por TCHATGPT');
    finally
      J.Free;
    end;

    Probe.Sequence := '';
    Chat.Streaming := True;
    Check(Chat.SendQuestionAsync('stream'), 'nao iniciou streaming async');
    WaitForRequest(Chat, 5000);
    Check(Chat.RequestState = lrsCompleted, 'estado final do streaming');
    Check(Chat.Response = 'ola mundo', 'resposta SSE incremental inesperada');
    Check(Pos('start>', Probe.Sequence) = 1, 'OnStreamStart fora de ordem');
    Check(Pos('data>', Probe.Sequence) > 0, 'OnStreamData ausente');
    Check(Pos('end>complete>', Probe.Sequence) > 0,
      'OnStreamEnd/Complete fora de ordem');

    Chat.Streaming := True;
    Check(Chat.SendQuestionAsync('slow'), 'nao iniciou request cancelavel');
    Started := GetTickCount64;
    while GetTickCount64 - Started < 250 do
    begin
      CheckSynchronize(20);
      Sleep(5);
    end;
    Chat.Cancel;
    WaitForRequest(Chat, 5000);
    Check(Chat.RequestState = lrsCancelled, 'Cancel nao resultou em Cancelled');

    Chat.Streaming := False;
    Check(Chat.SendQuestionAsync('reuse'), 'componente nao reutilizavel apos Cancel');
    WaitForRequest(Chat, 5000);
    Check(Chat.RequestState = lrsCompleted, 'requisicao apos Cancel falhou');
    Check(Chat.Response = 'mock-sync', 'resposta apos reutilizacao inesperada');
  finally
    Probe.Free;
    Chat.Free;
  end;
end;

var
  Endpoint: string;
begin
  TestProviderContracts;
  Endpoint := SysUtils.GetEnvironmentVariable('MOCK_LLM_ENDPOINT');
  if Endpoint <> '' then
    TestHTTPFlow(Endpoint);
  Writeln('llm_provider_streaming_test: PASS');
end.
