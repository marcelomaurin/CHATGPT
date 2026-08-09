unit aimcp;

{$mode objfpc}{$H+}

interface

uses
  Classes, LResources, aimcp_client, aimcp_server, aimcp_agent;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('AI MCP', [TAIMCPClient, TAIMCPServer,
    TAIMCPToolRegistryBridge]);
end;

end.
