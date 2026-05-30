{ This file was automatically created by Lazarus. Do not edit!
  This source is only used to compile and install the package.
 }

unit openai;

{$warn 5023 off : no warning about unused units}
interface

uses
  funcoes, chatgpt, NeuralNetwork, tokenizer, aicodeassistant, aidatasetgenerator, pythonconnector, facedetection, yolodetect, perceptron, sommap, cnnclassifier, lstmpredictor, soundfilters, LazarusPackageIntf;

implementation

procedure Register;
begin
  RegisterUnit('chatgpt', @chatgpt.Register);
  RegisterUnit('NeuralNetwork', @NeuralNetwork.Register);
  RegisterUnit('tokenizer', @tokenizer.Register);
  RegisterUnit('aicodeassistant', @aicodeassistant.Register);
  RegisterUnit('aidatasetgenerator', @aidatasetgenerator.Register);
  RegisterUnit('pythonconnector', @pythonconnector.Register);
  RegisterUnit('facedetection', @facedetection.Register);
  RegisterUnit('yolodetect', @yolodetect.Register);
  RegisterUnit('perceptron', @perceptron.Register);
  RegisterUnit('sommap', @sommap.Register);
  RegisterUnit('cnnclassifier', @cnnclassifier.Register);
  RegisterUnit('lstmpredictor', @lstmpredictor.Register);
  RegisterUnit('soundfilters', @soundfilters.Register);
end;

initialization
  RegisterPackage('openai', @Register);
end.
