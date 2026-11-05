program wizard_config_demo;
{$mode objfpc}{$H+}
{$codepage utf8}
uses {$IFDEF UNIX}cthreads,{$ENDIF} Interfaces, Forms, Classes, SysUtils,
  chatgpt, aimodelregistry, aipromptbuilder, aiwizardconfig;
var Owner: TComponent; Chat: TCHATGPT; Registry: TAIModelRegistry;
    Builder: TAIPromptBuilder; Wizard: TAIWizardConfig;
begin
  Application.Initialize;
  Owner := TComponent.Create(nil);
  try
    Chat := TCHATGPT.Create(Owner); Chat.Name := 'ChatLocal';
    Registry := TAIModelRegistry.Create(Owner);
    Registry.RegisterModel('Local', 'wizard-sample-local', 'Modelo local do wizard',
      'http://127.0.0.1:11434/v1/chat/completions', 1024, 0.2,
      False, False, False, True, False);
    Builder := TAIPromptBuilder.Create(Owner);
    Wizard := TAIWizardConfig.Create(Owner);
    Wizard.ChatGPT := Chat; Wizard.ModelRegistry := Registry; Wizard.PromptBuilder := Builder;
    Wizard.ModelName := 'wizard-sample-local'; Wizard.ProjectType := 'chatbot';
    Wizard.SafeMode := True; Wizard.SimulationMode := True;
    Wizard.Apply;
    if not Wizard.LastSuccess then raise Exception.Create(Wizard.LastError);
    if not Wizard.TestConnection then raise Exception.Create(Wizard.LastError);
    WriteLn('Modelo: ', Chat.CustomModel);
    WriteLn('Teste simulado: ', Wizard.LastResult);
    if ParamStr(1) = '--visual' then Wizard.ConfigureVisual;
    WriteLn('PASS: configuração aplicada; nenhuma requisição enviada.');
  finally Owner.Free; end;
end.
