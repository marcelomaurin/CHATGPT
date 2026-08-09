program observability_test;

{$mode objfpc}{$H+}
{$APPTYPE CONSOLE}

uses
  Interfaces, Classes, SysUtils, fpjson, jsonparser, aitrace, aitracebridge,
  aitools, aiagent, aiguardrails, airag, aigraphmap, chatgpt;

type
  TToolHost = class
  public
    procedure Echo(Sender: TObject; ACall: TAIToolCall; AResult: TAIToolResult);
  end;

procedure Fail(const AMessage: string);
begin Writeln(StdErr, 'FAIL: ', AMessage); Halt(1); end;

procedure Check(ACondition: Boolean; const AMessage: string);
begin if not ACondition then Fail(AMessage); end;

procedure TToolHost.Echo(Sender: TObject; ACall: TAIToolCall;
  AResult: TAIToolResult);
begin
  AResult.Success := True;
  AResult.Output := ACall.Arguments.Get('value', '');
end;

var
  Trace: TAITrace;
  Registry: TAIToolRegistry;
  Host: TToolHost;
  Call: TAIToolCall;
  ToolResult: TAIToolResult;
  Agent: TAIAgent;
  Guard: TAIInputGuardrail;
  RAG: TAIRAG;
  Graph: TAIGraphMap;
  Results: TStringList;
  Chat: TCHATGPT;
  SpanID, Err, Raw, Endpoint: string;
  Parsed: TJSONData;
  I: Integer;
begin
  Trace := TAITrace.Create(nil);
  Registry := TAIToolRegistry.Create(nil);
  Host := TToolHost.Create;
  Call := TAIToolCall.Create;
  ToolResult := TAIToolResult.Create;
  Agent := TAIAgent.Create(nil);
  Guard := TAIInputGuardrail.Create(nil);
  RAG := TAIRAG.Create(nil);
  Graph := TAIGraphMap.Create(nil);
  Results := TStringList.Create;
  Chat := TCHATGPT.Create(nil);
  try
    Trace.StartTrace('trace-observability-test');
    SpanID := Trace.BeginSpan('workflow', 'manual', '', '{"phase":"start"}');
    Trace.AddEvent(SpanID, 'checkpoint', '{"step":1}');
    Trace.EndSpan(SpanID, '', '{"success":true}');
    Check((Trace.Count = 1) and (Trace[0].StartedAt > 0) and
      (Trace[0].EndedAt > 0) and (Trace[0].Events.Count = 1),
      'contrato de span/timestamp/evento falhou');

    Registry.Trace := Trace;
    Registry.RegisterTool('echo', 'eco',
      '{"type":"object","properties":{"value":{"type":"string"}},"required":["value"]}',
      toolRiskSafe, @Host.Echo);
    Check(Call.ParseJSON('{"id":"tool-1","tool":"echo","arguments":{"value":"segredo-tool"}}', Err), Err);
    Check(Registry.Execute(Call, ToolResult), ToolResult.ErrorText);
    Check(Registry.LastTraceID = Trace.TraceID, 'TraceID nao propagou para Tool');

    Guard.BlockedPatterns.Add('bloquear');
    Agent.Trace := Trace;
    Agent.InputGuardrail := Guard;
    Check(not Agent.Execute('bloquear pergunta-secreta'),
      'Agent deveria bloquear entrada');
    Check(Agent.LastTraceID = Trace.TraceID, 'TraceID nao propagou para Agent');

    RAG.Trace := Trace;
    RAG.GraphMap := Graph;
    RAG.AddText('doc.txt', 'Lazarus usa Free Pascal para criar aplicativos.');
    Check(RAG.BuildIndex, 'indice RAG falhou: ' + RAG.LastError);
    Check(RAG.Retrieve('Lazarus Free Pascal', Results),
      'retrieve RAG falhou: ' + RAG.LastError);
    Check(RAG.LastTraceID = Trace.TraceID, 'TraceID nao propagou para RAG');
    for I := 0 to Results.Count - 1 do Results.Objects[I].Free;
    Results.Clear;

    Endpoint := ParamStr(1);
    if Endpoint <> '' then
    begin
      Chat.Trace := Trace;
      Chat.Provider := AIP_OPENAI_COMPATIBLE;
      Chat.URL := Endpoint;
      Chat.CustomModel := 'mock-model';
      Chat.Timeout := 5000;
      Check(Chat.SendQuestion('pergunta-secreta'),
        'LLM mock falhou: ' + Chat.LastError);
      Check(Chat.LastTraceID = Trace.TraceID, 'TraceID nao propagou para LLM');
    end;

    Raw := Trace.ToJSON;
    Parsed := GetJSON(Raw);
    try
      Check(Parsed.FindPath('trace_id').AsString = 'trace-observability-test',
        'JSON sem TraceID');
    finally Parsed.Free; end;
    Check(Pos('segredo-tool', Raw) = 0, 'argumento sensivel vazou no trace');
    Check(Pos('pergunta-secreta', Raw) = 0, 'prompt sensivel vazou no trace');
    Check((Pos('"top_k"', Raw) > 0) and (Pos('"scores"', Raw) > 0) and
      (Pos('doc.txt', Raw) > 0), 'metricas RAG ausentes');
    Check(Pos('"provider"', Raw) > 0, 'metrica de provider LLM ausente');
    if Endpoint <> '' then
      Check((Pos('"total_tokens"', Raw) > 0) and
        (Pos('"tokens_available"', Raw) > 0), 'tokens reais do LLM ausentes');
    Check(Trace.Count >= 4, 'spans ponta a ponta insuficientes');
  finally
    Chat.Free;
    Results.Free;
    Graph.Free;
    RAG.Free;
    Guard.Free;
    Agent.Free;
    ToolResult.Free;
    Call.Free;
    Host.Free;
    Registry.Free;
    Trace.Free;
  end;
  Writeln('PASS: TraceID + spans + LLM/RAG/Agent/Tool metrics + privacy');
end.
