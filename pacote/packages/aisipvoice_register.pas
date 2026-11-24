unit aisipvoice_register;
{$mode objfpc}{$H+}
interface
procedure Register;
implementation
uses Classes, aisipvoiceagent, aisipvoicehttp;
procedure Register;
begin RegisterComponents('AI Agents', [TAISIPVoiceAgent, TAISIPVoiceHTTPBackend]); end;
end.
