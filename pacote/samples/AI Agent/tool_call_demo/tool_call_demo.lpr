program tool_call_demo;

{$mode objfpc}{$H+}
{$APPTYPE CONSOLE}

uses
  Interfaces, Classes, SysUtils, aitools, aiagent;

type
  TDemo = class
  public
    ApproveDangerous: Boolean;
    procedure Sum(Sender: TObject; ACall: TAIToolCall; AResult: TAIToolResult);
    procedure Delete(Sender: TObject; ACall: TAIToolCall; AResult: TAIToolResult);
    procedure Confirm(Sender: TObject; ATool: TAITool; ACall: TAIToolCall;
      var AApproved: Boolean);
  end;

procedure TDemo.Sum(Sender: TObject; ACall: TAIToolCall;
  AResult: TAIToolResult);
begin
  AResult.Success := True;
  AResult.Output := IntToStr(ACall.Arguments.Get('a', 0) +
    ACall.Arguments.Get('b', 0));
end;

procedure TDemo.Delete(Sender: TObject; ACall: TAIToolCall;
  AResult: TAIToolResult);
begin
  AResult.Success := True;
  AResult.Output := 'Exclusao demonstrativa autorizada para ' +
    ACall.Arguments.Get('target', '');
end;

procedure TDemo.Confirm(Sender: TObject; ATool: TAITool;
  ACall: TAIToolCall; var AApproved: Boolean);
begin
  AApproved := ApproveDangerous;
  Writeln('Confirmacao solicitada para ', ATool.Name, ': ',
    BoolToStr(AApproved, True));
end;

var
  Demo: TDemo;
  Registry: TAIToolRegistry;
  Agent: TAIAgent;
  ResultJSON: string;
begin
  Demo := TDemo.Create;
  Registry := TAIToolRegistry.Create(nil);
  Agent := TAIAgent.Create(nil);
  try
    Registry.RegisterTool('sum', 'Soma dois inteiros',
      '{"type":"object","properties":{"a":{"type":"integer"},' +
      '"b":{"type":"integer"}},"required":["a","b"]}',
      toolRiskSafe, @Demo.Sum);
    Registry.RegisterTool('delete_record', 'Operacao sensivel demonstrativa',
      '{"type":"object","properties":{"target":{"type":"string"}},' +
      '"required":["target"]}', toolRiskDelete, @Demo.Delete);
    Registry.OnConfirmTool := @Demo.Confirm;
    Agent.ToolRegistry := Registry;

    Agent.ExecuteToolJSON('{"id":"1","tool":"sum",' +
      '"arguments":{"a":20,"b":22}}', ResultJSON);
    Writeln('Tool segura: ', ResultJSON);

    Demo.ApproveDangerous := False;
    Agent.ExecuteToolJSON('{"id":"2","tool":"delete_record",' +
      '"arguments":{"target":"cliente-10"}}', ResultJSON);
    Writeln('Sem aprovacao: ', ResultJSON);

    Demo.ApproveDangerous := True;
    Agent.ExecuteToolJSON('{"id":"3","tool":"delete_record",' +
      '"arguments":{"target":"cliente-10"}}', ResultJSON);
    Writeln('Com aprovacao: ', ResultJSON);
  finally
    Agent.Free;
    Registry.Free;
    Demo.Free;
  end;
end.
