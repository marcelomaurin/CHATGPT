{ This file was automatically created by Lazarus. Do not edit!
  This source is only used to compile and install the package.
 }

unit openai_ml;

{$warn 5023 off : no warning about unused units}
interface

uses
  NeuralNetwork, perceptron, sommap, aidatasetgenerator, MatrizComponent, 
  numps, LazarusPackageIntf;

implementation

procedure Register;
begin
  RegisterUnit('NeuralNetwork', @NeuralNetwork.Register);
  RegisterUnit('perceptron', @perceptron.Register);
  RegisterUnit('sommap', @sommap.Register);
  RegisterUnit('aidatasetgenerator', @aidatasetgenerator.Register);
  RegisterUnit('MatrizComponent', @MatrizComponent.Register);
  RegisterUnit('numps', @numps.Register);
end;

initialization
  RegisterPackage('openai_ml', @Register);
end.
