unit openai_sip;
{$warn 5023 off : no warning about unused units}
interface
uses aisip_types, aisip_native, aisip_base, aisip_client, aisip_server,
  aisip_register, LazarusPackageIntf;
implementation
procedure Register;
begin
  RegisterUnit('aisip_register', @aisip_register.Register);
end;
initialization
  RegisterPackage('openai_sip', @Register);
end.
