{ This file was automatically created by Lazarus. Do not edit!
  This source is only used to compile and install the package.
 }

unit openai_mcp;

{$warn 5023 off : no warning about unused units}
interface

uses
  aimcp, aimcp_types, aimcp_transport, aimcp_client, aimcp_server,
  aimcp_agent, LazarusPackageIntf;

implementation

procedure Register;
begin
  RegisterUnit('aimcp', @aimcp.Register);
end;

initialization
  RegisterPackage('openai_mcp', @Register);
end.
