program promptbuilder_demo;
{$mode objfpc}{$H+}
{$codepage utf8}
uses {$IFDEF UNIX}cthreads,{$ENDIF} Classes, SysUtils, aibase, aipromptbuilder;
var Owner: TComponent; Input, Output: TAIBaseComponent; Builder: TAIPromptBuilder; Text: string;
begin
  Owner := TComponent.Create(nil);
  Builder := TAIPromptBuilder.Create(nil);
  try
    Input := TAIBaseComponent.Create(Owner);
    Input.Name := 'EntradaTexto'; Input.Category := ccInput;
    Input.Prompt := 'Recebe a pergunta digitada pelo usuário.';
    Output := TAIBaseComponent.Create(Owner);
    Output.Name := 'RespostaTexto'; Output.Category := ccOutput;
    Output.Prompt := 'Apresenta a resposta em texto.';
    Builder.Language := plPortuguese;
    Builder.OutputFormat := pofMarkdown;
    Text := Builder.BuildFromOwner(Owner);
    if Pos('EntradaTexto', Text) = 0 then raise Exception.Create('Componente ausente no prompt.');
    WriteLn(Text);
    Builder.OutputFormat := pofJSON;
    WriteLn(Builder.BuildFromComponents([Input, Output]));
    WriteLn('PASS: prompts Markdown e JSON gerados localmente.');
  finally Builder.Free; Owner.Free; end;
end.
