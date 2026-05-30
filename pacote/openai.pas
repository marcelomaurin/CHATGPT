{ This file was automatically created by Lazarus. Do not edit!
  This source is only used to compile and install the package.
 }

unit openai;

{$warn 5023 off : no warning about unused units}
interface

uses
  funcoes, chatgpt, NeuralNetwork, tokenizer, aicodeassistant, aidatasetgenerator, pythonconnector, LazarusPackageIntf;

implementation

procedure Register;
begin
  RegisterUnit('chatgpt', @chatgpt.Register);
  RegisterUnit('NeuralNetwork', @NeuralNetwork.Register);
  RegisterUnit('tokenizer', @tokenizer.Register);
  RegisterUnit('aicodeassistant', @aicodeassistant.Register);
  RegisterUnit('aidatasetgenerator', @aidatasetgenerator.Register);
  RegisterUnit('pythonconnector', @pythonconnector.Register);
end;

initialization
  RegisterPackage('openai', @Register);
end.
