program mcp_demo;

{$mode objfpc}{$H+}
{$APPTYPE CONSOLE}

uses
  Interfaces, Classes, SysUtils, aitools, aimcp_transport, aimcp_client,
  aimcp_server, aimcp_types;

type
  TDemo = class
    procedure Sum(Sender: TObject; ACall: TAIToolCall; AResult: TAIToolResult);
  end;

procedure TDemo.Sum(Sender: TObject; ACall: TAIToolCall;
  AResult: TAIToolResult);
begin
  AResult.Success := True;
  AResult.Output := IntToStr(ACall.Arguments.Get('a', 0) +
    ACall.Arguments.Get('b', 0));
end;

var
  Demo: TDemo;
  Registry: TAIToolRegistry;
  Server: TAIMCPServer;
  Client: TAIMCPClient;
  TransportObject: TAIMCPInMemoryTransport;
  Transport: IAIMCPTransport;
  Tools: TAIMCPToolList;
  Output, Structured: string;
  IsError: Boolean;
begin
  Demo := TDemo.Create;
  Registry := TAIToolRegistry.Create(nil);
  Server := TAIMCPServer.Create(nil);
  Client := TAIMCPClient.Create(nil);
  Tools := TAIMCPToolList.Create;
  try
    Registry.RegisterTool('sum', 'Soma A e B',
      '{"type":"object","properties":{"a":{"type":"integer"},' +
      '"b":{"type":"integer"}},"required":["a","b"]}',
      toolRiskSafe, @Demo.Sum);
    Server.ToolRegistry := Registry;
    Server.AddTextResource('memory://welcome', 'welcome', 'Boas-vindas',
      'text/plain', 'Servidor MCP Lazarus ativo.');
    TransportObject := TAIMCPInMemoryTransport.Create;
    TransportObject.OnRequest := @Server.HandleTransportRequest;
    Transport := TransportObject;
    Client.Transport := Transport;
    Transport := nil;
    if not Client.Connect or not Client.Initialize then
      raise Exception.Create(Client.LastError);
    if not Client.ListTools(Tools) then raise Exception.Create(Client.LastError);
    Writeln('Servidor: ', Client.ServerName, ' / protocolo: ', Client.ProtocolVersion);
    Writeln('Tool descoberta: ', Tools.ToolAt(0).Name);
    if not Client.CallTool('sum', '{"a":19,"b":23}', Output, Structured,
      IsError) then raise Exception.Create(Client.LastError);
    Writeln('Somar(19, 23) = ', Output);
  finally
    Tools.Free;
    Client.Free;
    Server.Free;
    Registry.Free;
    Demo.Free;
  end;
end.
