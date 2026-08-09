program mcp_protocol_test;

{$mode objfpc}{$H+}
{$APPTYPE CONSOLE}

uses
  Interfaces, Classes, SysUtils, fpjson, jsonparser, aitools, aiagent,
  aimcp_types, aimcp_transport, aimcp_client, aimcp_server, aimcp_agent;

type
  TToolHost = class
    procedure Sum(Sender: TObject; ACall: TAIToolCall; AResult: TAIToolResult);
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

procedure TToolHost.Sum(Sender: TObject; ACall: TAIToolCall;
  AResult: TAIToolResult);
var Total: Integer;
begin
  Total := ACall.Arguments.Get('a', 0) + ACall.Arguments.Get('b', 0);
  AResult.Success := True;
  AResult.Output := IntToStr(Total);
  AResult.SetDataJSON(Format('{"total":%d}', [Total]));
end;

const
  SumSchema = '{"type":"object","properties":{"a":{"type":"integer"},' +
    '"b":{"type":"integer"}},"required":["a","b"]}';
var
  Host: TToolHost;
  ServerRegistry, RemoteRegistry: TAIToolRegistry;
  Server: TAIMCPServer;
  Client: TAIMCPClient;
  Bridge: TAIMCPToolRegistryBridge;
  Agent: TAIAgent;
  TransportObject: TAIMCPInMemoryTransport;
  Transport: IAIMCPTransport;
  Tools: TAIMCPToolList;
  Resources: TAIMCPResourceList;
  Output, Structured, Text, MimeType, AgentJSON, Raw: string;
  IsError: Boolean;
  Data: TJSONData;
begin
  Host := TToolHost.Create;
  ServerRegistry := TAIToolRegistry.Create(nil);
  RemoteRegistry := TAIToolRegistry.Create(nil);
  Server := TAIMCPServer.Create(nil);
  Client := TAIMCPClient.Create(nil);
  Bridge := TAIMCPToolRegistryBridge.Create(nil);
  Agent := TAIAgent.Create(nil);
  Tools := TAIMCPToolList.Create;
  Resources := TAIMCPResourceList.Create;
  try
    Check(ServerRegistry.RegisterTool('sum', 'Soma dois inteiros', SumSchema,
      toolRiskSafe, @Host.Sum) <> nil, 'tool sum nao registrada no servidor');
    Server.ToolRegistry := ServerRegistry;
    Server.ServerName := 'mcp-test-server';
    Server.AddTextResource('memory://guide', 'guide', 'Guia de teste',
      'text/plain', 'MCP no Lazarus funciona.');

    TransportObject := TAIMCPInMemoryTransport.Create;
    TransportObject.OnRequest := @Server.HandleTransportRequest;
    Transport := TransportObject;
    Client.Transport := Transport;
    Transport := nil;
    Check(Client.Connect, 'cliente nao conectou: ' + Client.LastError);
    Check(Client.Initialize, 'initialize falhou: ' + Client.LastError);
    Check(Client.ProtocolVersion = AIMCP_PROTOCOL_VERSION, 'versao MCP inesperada');
    Check(Client.ServerName = 'mcp-test-server', 'serverInfo nao convertido');

    Check(Client.ListTools(Tools), 'tools/list falhou: ' + Client.LastError);
    Check(Tools.Count = 1, 'tools/list nao retornou uma tool');
    Check(Tools.ToolAt(0).Name = 'sum', 'tool remota incorreta');
    Check(Pos('required', Tools.ToolAt(0).InputSchema) > 0, 'inputSchema perdido');

    Check(Client.CallTool('sum', '{"a":20,"b":22}', Output, Structured,
      IsError), 'tools/call falhou: ' + Client.LastError);
    Check(not IsError, 'tools/call marcou erro');
    Check(Output = '42', 'resultado tools/call incorreto');
    Data := GetJSON(Structured);
    try Check(Data.FindPath('total').AsInteger = 42, 'structuredContent incorreto');
    finally Data.Free; end;

    Check(Client.ListResources(Resources), 'resources/list falhou: ' + Client.LastError);
    Check(Resources.Count = 1, 'resources/list incorreto');
    Check(Resources.ResourceAt(0).URI = 'memory://guide', 'URI do resource incorreto');
    Check(Client.ReadResource('memory://guide', Text, MimeType),
      'resources/read falhou: ' + Client.LastError);
    Check(Text = 'MCP no Lazarus funciona.', 'texto do resource incorreto');
    Check(MimeType = 'text/plain', 'mimeType do resource incorreto');
    Check(not Client.ReadResource('memory://missing', Text, MimeType),
      'resource inexistente nao retornou erro');
    Check(Client.LastMCPError.Code = -32002, 'erro estruturado de resource perdido');

    Raw := Server.HandleRequest('{"jsonrpc":"2.0","id":"x","method":"unknown","params":{}}');
    Data := GetJSON(Raw);
    try Check(Data.FindPath('error.code').AsInteger = -32601, 'Method not found incorreto');
    finally Data.Free; end;

    Bridge.Client := Client;
    Bridge.Registry := RemoteRegistry;
    Check(Bridge.Refresh, 'bridge MCP falhou: ' + Bridge.LastError);
    Check(RemoteRegistry.Count = 1, 'bridge nao refletiu tools remotas');
    Check(Bridge.Refresh, 'segundo Refresh falhou');
    Check(RemoteRegistry.Count = 1, 'Refresh duplicou proxies');
    Agent.ToolRegistry := RemoteRegistry;
    Check(not Agent.ExecuteToolJSON('{"id":"agent-denied","tool":"sum",' +
      '"arguments":{"a":4,"b":5}}', AgentJSON),
      'proxy MCP desconhecido executou sem confirmacao');
    RemoteRegistry.ExecutePolicy := toolPolicyAllow;
    Check(Agent.ExecuteToolJSON('{"id":"agent-ok","tool":"sum",' +
      '"arguments":{"a":14,"b":16}}', AgentJSON),
      'Agent nao executou tool MCP: ' + Agent.LastError);
    Data := GetJSON(AgentJSON);
    try Check(Data.FindPath('output').AsString = '30', 'resultado MCP via Agent incorreto');
    finally Data.Free; end;

    Bridge.Free;
    Bridge := nil;
    Check(RemoteRegistry.Count = 0, 'destruir bridge nao removeu proxies MCP');
  finally
    Resources.Free;
    Tools.Free;
    Agent.Free;
    Bridge.Free;
    Client.Free;
    Server.Free;
    RemoteRegistry.Free;
    ServerRegistry.Free;
    Host.Free;
  end;
  Writeln('PASS: MCP initialize, tools/list, tools/call, resources/list/read, errors and Agent bridge');
end.
