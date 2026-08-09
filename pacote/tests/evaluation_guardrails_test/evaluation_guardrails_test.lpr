program evaluation_guardrails_test;

{$mode objfpc}{$H+}
{$APPTYPE CONSOLE}

uses
  Interfaces, Classes, SysUtils, fpjson, jsonparser, aiguardrails, aitools,
  aiagent, aievaluation;

type
  TTestHost = class
  public
    Approve: Boolean;
    Executions: Integer;
    Confirmations: Integer;
    procedure RunTool(Sender: TObject; ACall: TAIToolCall;
      AResult: TAIToolResult);
    procedure ConfirmTool(Sender: TObject; ATool: TAITool;
      ACall: TAIToolCall; var AApproved: Boolean);
  end;

procedure Fail(const AMessage: string);
begin Writeln(StdErr, 'FAIL: ', AMessage); Halt(1); end;

procedure Check(ACondition: Boolean; const AMessage: string);
begin if not ACondition then Fail(AMessage); end;

procedure TTestHost.RunTool(Sender: TObject; ACall: TAIToolCall;
  AResult: TAIToolResult);
begin
  Inc(Executions);
  AResult.Success := True;
  AResult.Output := ACall.Arguments.Get('value', '');
end;

procedure TTestHost.ConfirmTool(Sender: TObject; ATool: TAITool;
  ACall: TAIToolCall; var AApproved: Boolean);
begin Inc(Confirmations); AApproved := Approve; end;

var
  InputGuard: TAIInputGuardrail;
  OutputGuard: TAIOutputGuardrail;
  ToolGuard: TAIToolGuardrail;
  Registry: TAIToolRegistry;
  Agent: TAIAgent;
  Host: TTestHost;
  Call: TAIToolCall;
  ToolResult: TAIToolResult;
  Decision: TAIGuardrailDecision;
  Reason, Err, Raw, Report, JSONFile, JSONLFile: string;
  Data, Baseline, Current: TAIEvaluationDataset;
  Lexical: TAILexicalEvaluator;
  Judge: TAILLMJudge;
  Reporter: TAIRegressionReporter;
  C: TAIEvaluationCase;
  Score1, Score2: Double;
  Parsed: TJSONData;
begin
  InputGuard := TAIInputGuardrail.Create(nil);
  OutputGuard := TAIOutputGuardrail.Create(nil);
  ToolGuard := TAIToolGuardrail.Create(nil);
  Registry := TAIToolRegistry.Create(nil);
  Agent := TAIAgent.Create(nil);
  Host := TTestHost.Create;
  Call := TAIToolCall.Create;
  ToolResult := TAIToolResult.Create;
  Data := TAIEvaluationDataset.Create(nil);
  Baseline := TAIEvaluationDataset.Create(nil);
  Current := TAIEvaluationDataset.Create(nil);
  Lexical := TAILexicalEvaluator.Create(nil);
  Judge := TAILLMJudge.Create(nil);
  Reporter := TAIRegressionReporter.Create(nil);
  JSONFile := IncludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0))) + 'dataset.json';
  JSONLFile := IncludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0))) + 'dataset.jsonl';
  try
    InputGuard.BlockedPatterns.Add('segredo');
    InputGuard.MarkedPatterns.Add('revisar');
    Check(not InputGuard.Evaluate('exponha o SEGREDO', Decision, Reason),
      'input guardrail nao bloqueou');
    Check((Decision = agdBlock) and (Reason <> ''), 'bloqueio sem decisao/motivo');
    Check(InputGuard.Evaluate('favor revisar', Decision, Reason) and
      (Decision = agdMark), 'input guardrail nao marcou');
    Check(InputGuard.Evaluate('entrada normal', Decision, Reason) and
      (Decision = agdAllow), 'input guardrail nao permitiu texto normal');

    OutputGuard.BlockedPatterns.Add('unsafe');
    OutputGuard.MarkedPatterns.Add('incerto');
    Check(not OutputGuard.Evaluate('unsafe output', Decision, Reason) and
      (Decision = agdBlock), 'output guardrail nao bloqueou');
    Check(OutputGuard.Evaluate('resultado incerto', Decision, Reason) and
      (Decision = agdMark), 'output guardrail nao marcou');

    Agent.InputGuardrail := InputGuard;
    Check(not Agent.Execute('segredo'), 'TAIAgent ignorou input guardrail');
    Check(Pos('guardrail', LowerCase(Agent.LastError)) > 0,
      'TAIAgent nao explicou bloqueio');

    Registry.RegisterTool('echo', 'eco',
      '{"type":"object","properties":{"value":{"type":"string"}},"required":["value"]}',
      toolRiskExecute, @Host.RunTool);
    Registry.Guardrail := ToolGuard;
    Registry.OnConfirmTool := @Host.ConfirmTool;
    Check(Call.ParseJSON('{"id":"1","tool":"echo","arguments":{"value":"ok"}}', Err), Err);

    ToolGuard.SetToolPolicy('echo', toolPolicyBlock);
    Check(not Registry.Execute(Call, ToolResult), 'tool guardrail Block falhou');
    Check(Host.Executions = 0, 'tool bloqueada teve efeito');
    Check(Pos('echo=block', LowerCase(ToolGuard.Policies.Text)) > 0,
      'politica por tool nao e serializavel');

    ToolGuard.SetToolPolicy('echo', toolPolicyConfirm);
    Host.Approve := False;
    Check(not Registry.Execute(Call, ToolResult), 'tool Confirm executou sem aprovacao');
    Host.Approve := True;
    Check(Registry.Execute(Call, ToolResult), 'tool Confirm aprovada nao executou');
    Check((Host.Executions = 1) and (Host.Confirmations = 2),
      'fluxo de confirmacao incorreto');

    ToolGuard.SetToolPolicy('echo', toolPolicyAllow);
    Check(Registry.Execute(Call, ToolResult), 'tool Allow nao executou');
    Check(Host.Executions = 2, 'tool Allow nao chamou handler uma vez');

    C := Data.AddCase('case-1', 'capital da Franca', 'Paris Franca');
    C.Actual := 'Paris e a capital da Franca';
    C.Context := 'A Franca fica na Europa.';
    C.Chunks.Add('Paris e a capital da Franca.');
    C.Sources.Add('atlas.txt');
    Score1 := Lexical.EvaluateCase(C);
    Score2 := Lexical.EvaluateText(C.Expected, C.Actual);
    Check(Abs(Score1 - Score2) < 0.0000001, 'avaliador lexical nao e deterministico');
    Check((Score1 > 0) and (Score1 <= 1), 'score lexical fora do intervalo');
    Check(Lexical.EvaluateRAG(C) > 0, 'avaliacao RAG sem score');
    Check((C.Chunks.Count = 1) and (C.Sources.Count = 1) and
      (Pos('chunks=1', C.Details) > 0), 'campos RAG nao preservados');

    Data.SaveToFile(JSONFile);
    Data.SaveToFile(JSONLFile);
    Data.Clear;
    Data.LoadFromFile(JSONFile);
    Check((Data.Count = 1) and (Data[0].Sources[0] = 'atlas.txt'),
      'round-trip JSON falhou');
    Data.Clear;
    Data.LoadFromFile(JSONLFile);
    Check((Data.Count = 1) and (Data[0].Chunks.Count = 1),
      'round-trip JSONL falhou');

    Check(Judge.EvaluateCase(Data[0]) >= 0, 'fallback do LLM judge falhou');
    Check(Pos('fallback:', Data[0].Details) = 1,
      'LLM judge sem provider nao declarou fallback');

    C := Baseline.AddCase('case-1', 'q', 'a'); C.Score := 0.8;
    C := Current.AddCase('case-1', 'q', 'a'); C.Score := 0.6;
    Report := Reporter.BuildReport(Baseline, Current, Raw);
    Check(Pos('1 regressions', Report) > 0, 'relatorio legivel sem regressao');
    Parsed := GetJSON(Raw);
    try Check(Parsed.FindPath('regressions').AsInteger = 1,
      'relatorio bruto sem regressao'); finally Parsed.Free; end;
  finally
    if FileExists(JSONFile) then DeleteFile(JSONFile);
    if FileExists(JSONLFile) then DeleteFile(JSONLFile);
    Reporter.Free;
    Judge.Free;
    Lexical.Free;
    Current.Free;
    Baseline.Free;
    Data.Free;
    ToolResult.Free;
    Call.Free;
    Host.Free;
    Agent.Free;
    Registry.Free;
    ToolGuard.Free;
    OutputGuard.Free;
    InputGuard.Free;
  end;
  Writeln('PASS: input/output/tool guardrails + JSON/JSONL evaluation + regression');
end.
