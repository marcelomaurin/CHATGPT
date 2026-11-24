unit aisipvoice_register;
{$mode objfpc}{$H+}
interface
procedure Register;
implementation
uses Classes, LResources, aisipvoiceagent, aisipvoicehttp;
procedure Register;
begin RegisterComponents('AI Agents', [TAISIPVoiceAgent, TAISIPVoiceHTTPBackend]); end;
initialization
  {$I openai_sip_voice_paletteicons.lrs}
end.
