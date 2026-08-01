{ This file was automatically created by Lazarus. Do not edit!
  This source is only used to compile and install the package.
 }

unit openai_voice;

{$warn 5023 off : no warning about unused units}
interface

uses
  aivoicesynthesizer, aivoicerecognizer, soundfilters, LazarusPackageIntf;

implementation

procedure Register;
begin
  RegisterUnit('aivoicesynthesizer', @aivoicesynthesizer.Register);
  RegisterUnit('aivoicerecognizer', @aivoicerecognizer.Register);
  RegisterUnit('soundfilters', @soundfilters.Register);
end;

initialization
  RegisterPackage('openai_voice', @Register);
end.
