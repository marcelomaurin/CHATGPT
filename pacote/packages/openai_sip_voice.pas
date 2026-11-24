unit openai_sip_voice;
{$warn 5023 off : no warning about unused units}
interface
uses aisipvoiceaudio, aisipvoiceagent, aisipvoicehttp, aisipvoice_register, LazarusPackageIntf;
implementation
procedure Register;
begin RegisterUnit('aisipvoice_register', @aisipvoice_register.Register); end;
initialization
  RegisterPackage('openai_sip_voice', @Register);
end.
