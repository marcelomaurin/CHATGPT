{ This unit was automatically created by Lazarus. Do not edit!
  This source is only used to compile and install the package.
 }

unit openai_integration;

{$warn 5023 off : no warning about unused units}
interface

uses
  aiagent_executors, aipipeline, LazarusPackageIntf;

implementation

procedure Register;
begin
  RegisterUnit('aipipeline', @aipipeline.Register);
end;

initialization
  RegisterPackage('openai_integration', @Register);
end.
