{ This file was automatically created by Lazarus. Do not edit!
  This source is only used to compile and install the package.
 }

unit openai_core;

{$warn 5023 off : no warning about unused units}
interface

uses
  funcoes, aibase, aiplatform, airuntimepaths, ailibraryloader, 
  aiprocessrunner, chatgpt, tokenizer, aicodeassistant, aipromptbuilder, 
  aimodelregistry, aiwizardconfig, frm_aiwizardconfig, DBTokenList, 
  GroupResponse, iaschedule, aiproject, aipipeline, pythonconnector, 
  facedetection, yolodetect, cnnclassifier, lstmpredictor, aipythonruntime, 
  LazarusPackageIntf;

implementation

procedure Register;
begin
  RegisterUnit('chatgpt', @chatgpt.Register);
  RegisterUnit('tokenizer', @tokenizer.Register);
  RegisterUnit('aicodeassistant', @aicodeassistant.Register);
  RegisterUnit('aipromptbuilder', @aipromptbuilder.Register);
  RegisterUnit('aimodelregistry', @aimodelregistry.Register);
  RegisterUnit('aiwizardconfig', @aiwizardconfig.Register);
  RegisterUnit('DBTokenList', @DBTokenList.Register);
  RegisterUnit('GroupResponse', @GroupResponse.Register);
  RegisterUnit('iaschedule', @iaschedule.Register);
  RegisterUnit('aiproject', @aiproject.Register);
  RegisterUnit('aipipeline', @aipipeline.Register);
  RegisterUnit('pythonconnector', @pythonconnector.Register);
  RegisterUnit('facedetection', @facedetection.Register);
  RegisterUnit('yolodetect', @yolodetect.Register);
  RegisterUnit('cnnclassifier', @cnnclassifier.Register);
  RegisterUnit('lstmpredictor', @lstmpredictor.Register);
  RegisterUnit('aipythonruntime', @aipythonruntime.Register);
end;

initialization
  RegisterPackage('openai_core', @Register);
end.
