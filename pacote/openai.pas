{ This file was automatically created by Lazarus. Do not edit!
  This source is only used to compile and install the package.
 }

unit openai;

{$warn 5023 off : no warning about unused units}
interface

uses
  funcoes, chatgpt, NeuralNetwork, tokenizer, aicodeassistant, 
  aidatasetgenerator, pythonconnector, facedetection, yolodetect, perceptron, 
  sommap, cnnclassifier, lstmpredictor, soundfilters, imagefilters, 
  iaschedule, aivoicesynthesizer, aiagent, numps, aiinput, aicamera, aiaudio, 
  aiwebserver, aisockets, aiserial, aiposprinter, aicftvip, aimodbus, aimqtt, 
  aiemail, aimessenger, aiindustrial, aichromiumbrowser, aioscapture, 
  aioutput, aioutput_docs, aiproject, aipipeline, aipromptbuilder, aigraphmap, 
  aibase, aiagentsafety, aiagent_executors, LazarusPackageIntf;

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
  RegisterUnit('imagefilters', @imagefilters.Register);
  RegisterUnit('iaschedule', @iaschedule.Register);
  RegisterUnit('aivoicesynthesizer', @aivoicesynthesizer.Register);
  RegisterUnit('aiagent', @aiagent.Register);
  RegisterUnit('numps', @numps.Register);
  RegisterUnit('aiinput', @aiinput.Register);
  RegisterUnit('aicamera', @aicamera.Register);
  RegisterUnit('aiaudio', @aiaudio.Register);
  RegisterUnit('aiwebserver', @aiwebserver.Register);
  RegisterUnit('aisockets', @aisockets.Register);
  RegisterUnit('aiserial', @aiserial.Register);
  RegisterUnit('aiposprinter', @aiposprinter.Register);
  RegisterUnit('aicftvip', @aicftvip.Register);
  RegisterUnit('aimodbus', @aimodbus.Register);
  RegisterUnit('aimqtt', @aimqtt.Register);
  RegisterUnit('aiemail', @aiemail.Register);
  RegisterUnit('aimessenger', @aimessenger.Register);
  RegisterUnit('aiindustrial', @aiindustrial.Register);
  RegisterUnit('aichromiumbrowser', @aichromiumbrowser.Register);
  RegisterUnit('aioscapture', @aioscapture.Register);
  RegisterUnit('aioutput', @aioutput.Register);
  RegisterUnit('aioutput_docs', @aioutput_docs.Register);
  RegisterUnit('aiproject', @aiproject.Register);
  RegisterUnit('aipipeline', @aipipeline.Register);
  RegisterUnit('aipromptbuilder', @aipromptbuilder.Register);
  RegisterUnit('aigraphmap', @aigraphmap.Register);
  RegisterUnit('aiagentsafety', @aiagentsafety.Register);
end;

initialization
  RegisterPackage('openai', @Register);
end.
