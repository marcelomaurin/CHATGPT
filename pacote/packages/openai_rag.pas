{ This file was automatically created by Lazarus. Do not edit!
  This source is only used to compile and install the package.
 }

unit openai_rag;

{$warn 5023 off : no warning about unused units}
interface

uses
  airag, LazarusPackageIntf;

implementation

procedure Register;
begin
  RegisterUnit('airag', @airag.Register);
end;

initialization
  RegisterPackage('openai_rag', @Register);
end.
