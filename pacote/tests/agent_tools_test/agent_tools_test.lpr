program agent_tools_test;

{$mode objfpc}{$H+}
{$APPTYPE CONSOLE}

uses
  Interfaces, Classes, SysUtils, fpjson, jsonparser, aitools, aiagent,
  aiagentsafety;

type
  TToolHost = class
  public
    Approve: Boolean;
    Confirmations: Integer;
    DangerousExecutions: Integer;
    procedure SumTool(Sender: TObject; ACall: TAIToolCall;
      AResult: TAIToolResult);
    procedure DeleteTool(Sender: TObject; ACall: TAIToolCall;
      AResult: TAIToolResult);
    procedure ConfirmTool(Sender: TObject; ATool: TAITool;
      ACall: TAIToolCall; var AApproved: Boolean);
  end;

procedure Fail(const AMessage: string);
begin
  Writeln(StdErr, 'FAIL: ', AMessage);
  Halt(1);
end;

procedure Check(ACondition: Boolean; const AMessage: string);
begin
  if not ACondition then Fail(AMessage);
end;

procedure TToolHost.SumTool(Sender: TObject; ACall: TAIToolCall;
  AResult: TAIToolResult);
var
  A, B, Total: Integer;
begin
  A := ACall.Arguments.Get('a', 0);
  B := ACall.Arguments.Get('b', 0);
  Total := A + B;
  AResult.Success := True;
  AResult.Output := IntToStr(Total);
  AResult.SetDataJSON(Format('{"total":%d}', [Total]));
end;

procedure TToolHost.DeleteTool(Sender: TObject; ACall: TAIToolCall;
  AResult: TAIToolResult);
begin
  Inc(DangerousExecutions);
  AResult.Success := True;
  AResult.Output := 'simulated delete: ' + ACall.Arguments.Get('target', '');
end;

procedure TToolHost.ConfirmTool(Sender: TObject; ATool: TAITool;
  ACall: TAIToolCall; var AApproved: Boolean);
begin
  Inc(Confirmations);
  AApproved := Approve;
end;

const
  SumSchema = '{"type":"object","properties":{"a":{"type":"integer"},' +
    '"b":{"type":"integer"}},"required":["a","b"]}';
  DeleteSchema = '{"type":"object","properties":{"target":{"type":"string"}},' +
    '"required":["target"]}';
var
  Registry, TempRegistry: TAIToolRegistry;
  Agent: TAIAgent;
  Safety: TAIAgentSafety;
  Host: TToolHost;
  Call: TAIToolCall;
  ToolResult: TAIToolResult;
  Tool, Duplicate: TAITool;
  ResultJSON, Err: string;
  Parsed: TJSONData;
begin
  Host := TToolHost.Create;
  Registry := TAIToolRegistry.Create(nil);
  Agent := TAIAgent.Create(nil);
  Safety := TAIAgentSafety.Create(nil);
  Call := TAIToolCall.Create;
  ToolResult := TAIToolResult.Create;
  try
    Tool := Registry.RegisterTool('sum', 'Soma dois inteiros', SumSchema,
      toolRiskSafe, @Host.SumTool);
    Check(Tool <> nil, 'nao registrou tool segura');
    Check(Registry.RegisterTool('delete_record', 'Exclui registro', DeleteSchema,
      toolRiskDelete, @Host.DeleteTool) <> nil, 'nao registrou tool perigosa');
    Check(Registry.Count = 2, 'enumeracao de tools incorreta');
    Check(Registry.FindTool('SUM') = Tool, 'busca de tool nao e case-insensitive');
    Check(Pos('inputSchema', Registry.ToolsJSON) > 0,
      'serializacao da lista de tools sem schema');

    Duplicate := Registry.RegisterTool('sum', 'duplicada', '{}', toolRiskSafe,
      @Host.SumTool);
    Check(Duplicate = nil, 'registry aceitou nome duplicado');
    Check(Pos('duplicada', LowerCase(Registry.LastError)) > 0,
      'erro de duplicidade nao foi informado');

    Check(Call.ParseJSON('{"id":"call-1","tool":"sum","arguments":{"a":2,"b":5}}', Err),
      'parser de ToolCall falhou: ' + Err);
    Check(Registry.Execute(Call, ToolResult), 'tool segura falhou: ' + ToolResult.ErrorText);
    Check(ToolResult.Output = '7', 'resultado da soma incorreto');
    Check(ToolResult.CallID = 'call-1', 'CallID nao propagado');
    Parsed := GetJSON(ToolResult.ToJSON);
    Parsed.Free;

    Check(Call.ParseJSON('{"id":"bad","tool":"sum","arguments":{"a":2}}', Err),
      'parser rejeitou chamada sintaticamente valida');
    Check(not Registry.Execute(Call, ToolResult),
      'schema aceitou argumento obrigatorio ausente');
    Check(Pos('b', ToolResult.ErrorText) > 0, 'erro de schema nao identifica argumento');

    Check(Call.ParseJSON('{"id":"bad-type","tool":"sum","arguments":{"a":"2","b":5}}', Err),
      'parser rejeitou chamada de tipo invalido antes da validacao');
    Check(not Registry.Execute(Call, ToolResult), 'schema aceitou tipo incorreto');

    Check(Call.ParseJSON('{"id":"danger-1","tool":"delete_record",' +
      '"arguments":{"target":"registro-1"}}', Err), 'parser da tool perigosa falhou');
    Registry.OnConfirmTool := @Host.ConfirmTool;
    Host.Approve := False;
    Check(not Registry.Execute(Call, ToolResult), 'tool perigosa executou sem aprovacao');
    Check(Host.DangerousExecutions = 0, 'handler perigoso foi chamado antes da aprovacao');
    Host.Approve := True;
    Check(Registry.Execute(Call, ToolResult), 'tool aprovada nao executou');
    Check(Host.DangerousExecutions = 1, 'handler perigoso nao executou uma vez');
    Check(Host.Confirmations = 2, 'evento de confirmacao nao ocorreu em ambas tentativas');

    Registry.FindTool('delete_record').Policy := toolPolicyBlock;
    Check(not Registry.Execute(Call, ToolResult), 'politica por tool nao bloqueou');
    Check(Host.DangerousExecutions = 1, 'tool bloqueada chamou o handler');
    Registry.FindTool('delete_record').Policy := toolPolicyInherit;

    Agent.ToolRegistry := Registry;
    Safety.RequireConfirmation := False;
    Safety.ReadOnlyMode := False;
    Safety.AllowedActions.Add('sum');
    Agent.Safety := Safety;
    Check(Agent.ExecuteToolJSON('{"id":"agent-1","tool":"sum",' +
      '"arguments":{"a":10,"b":15}}', ResultJSON),
      'Agent nao executou tool registrada: ' + Agent.LastError);
    Parsed := GetJSON(ResultJSON);
    try
      Check(Parsed.FindPath('success').AsBoolean, 'ToolResult JSON do Agent sem success');
      Check(Parsed.FindPath('output').AsString = '25', 'ToolResult JSON do Agent incorreto');
    finally
      Parsed.Free;
    end;

    Check(not Agent.ExecuteToolJSON('{"id":"agent-2","tool":"delete_record",' +
      '"arguments":{"target":"x"}}', ResultJSON),
      'Safety do Agent nao bloqueou tool fora da allowlist');

    Check(Call.ParseJSON('{"id":"openai-1","function":{"name":"sum",' +
      '"arguments":"{\"a\":3,\"b\":4}"}}', Err),
      'parser de function tool-call falhou: ' + Err);
    Check(Call.Arguments.Get('a', 0) = 3, 'arguments JSON-string nao foi convertido');

    TempRegistry := TAIToolRegistry.Create(nil);
    Agent.ToolRegistry := TempRegistry;
    TempRegistry.Free;
    Check(Agent.ToolRegistry = nil, 'FreeNotification do ToolRegistry falhou');
  finally
    ToolResult.Free;
    Call.Free;
    Safety.Free;
    Agent.Free;
    Registry.Free;
    Host.Free;
  end;
  Writeln('PASS: ToolCall -> safety/policy -> confirmation -> handler -> ToolResult');
end.
