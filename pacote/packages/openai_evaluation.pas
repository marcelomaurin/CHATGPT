{ This file was automatically created by Lazarus. Do not edit!
  This source is only used to compile and install the package.
 }

unit openai_evaluation;

{$warn 5023 off : no warning about unused units}
interface

uses
  aievaluation, LazarusPackageIntf;

implementation

procedure Register;
begin
  RegisterUnit('aievaluation', @aievaluation.Register);
end;

initialization
  RegisterPackage('openai_evaluation', @Register);
end.
