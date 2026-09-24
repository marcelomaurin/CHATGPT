{ This file was automatically created by Lazarus. Do not edit!
  This source is only used to compile and install the package.
 }

unit openai_wizard;

{$warn 5023 off : no warning about unused units}
interface

uses
  aiwizardconfig, frm_aiwizardconfig, LazarusPackageIntf;

implementation

procedure Register;
begin
  RegisterUnit('aiwizardconfig', @aiwizardconfig.Register);
end;

initialization
  RegisterPackage('openai_wizard', @Register);
end.
