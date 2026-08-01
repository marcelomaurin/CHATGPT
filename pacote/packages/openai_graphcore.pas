{ This file was automatically created by Lazarus. Do not edit!
  This source is only used to compile and install the package.
 }

unit openai_graphcore;

{$warn 5023 off : no warning about unused units}
interface

uses
  aidependencygraph, LazarusPackageIntf;

implementation

procedure Register;
begin
  RegisterUnit('aidependencygraph', @aidependencygraph.Register);
end;

initialization
  RegisterPackage('openai_graphcore', @Register);
end.
