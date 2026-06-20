{ This file was automatically created by Lazarus. Do not edit!
  This source is only used to compile and install the package.
 }

unit openai_core;

{$warn 5023 off : no warning about unused units}
interface

uses
  funcoes, aibase, aiplatform, airuntimepaths, ailibraryloader, 
  aiprocessrunner, chatgpt, tokenizer, aicodeassistant, aipromptbuilder, 
  aimodelregistry, DBTokenList, GroupResponse, iaschedule, LazarusPackageIntf;

implementation

procedure Register;
begin
  RegisterUnit('chatgpt', @chatgpt.Register);
  RegisterUnit('tokenizer', @tokenizer.Register);
  RegisterUnit('aicodeassistant', @aicodeassistant.Register);
  RegisterUnit('aipromptbuilder', @aipromptbuilder.Register);
  RegisterUnit('aimodelregistry', @aimodelregistry.Register);
  RegisterUnit('DBTokenList', @DBTokenList.Register);
  RegisterUnit('GroupResponse', @GroupResponse.Register);
  RegisterUnit('iaschedule', @iaschedule.Register);
end;

initialization
  RegisterPackage('openai_core', @Register);
end.
