unit aisip_register;
{$mode objfpc}{$H+}
interface
procedure Register;
implementation
uses Classes, LResources, aisip_client, aisip_server;
procedure Register;
begin
  RegisterComponents('AI Communication', [TAISIPServer, TAISIPClient]);
end;
initialization
  {$I openai_sip_paletteicons.lrs}
end.
