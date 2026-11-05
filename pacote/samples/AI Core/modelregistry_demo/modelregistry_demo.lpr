program modelregistry_demo;
{$mode objfpc}{$H+}
{$codepage utf8}
uses {$IFDEF UNIX}cthreads,{$ENDIF} Classes, SysUtils, aimodelregistry, chatgpt;
var Registry: TAIModelRegistry; Chat: TCHATGPT; Providers: TStringList; I: Integer;
begin
  Registry := TAIModelRegistry.Create(nil);
  Chat := TCHATGPT.Create(nil);
  Providers := TStringList.Create;
  try
    Registry.GetProviders(Providers);
    WriteLn('Modelos disponíveis no catálogo: ', Registry.Models.Count);
    for I := 0 to Providers.Count - 1 do WriteLn('  Provedor: ', Providers[I]);
    Registry.RegisterModel('Local', 'sample-local-model', 'Modelo local de exemplo',
      'http://127.0.0.1:11434/v1/chat/completions', 2048, 0.3,
      False, False, False, True, False);
    Registry.ApplyModel('sample-local-model', Chat);
    if not Registry.LastSuccess then raise Exception.Create(Registry.LastError);
    if Chat.CustomModel <> 'sample-local-model' then raise Exception.Create('Modelo não aplicado.');
    WriteLn('Selecionado: ', Chat.CustomModel, ' / ', Chat.ProviderName);
    WriteLn('Endpoint: ', Chat.URL);
    WriteLn('PASS: configuração aplicada sem enviar requisições.');
  finally Providers.Free; Chat.Free; Registry.Free; end;
end.
