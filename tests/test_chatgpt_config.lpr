program test_chatgpt_config;
{$mode objfpc}{$H+}
uses Classes, SysUtils, IniFiles, TypInfo, chatgpt;

procedure Check(Condition: Boolean; const MessageText: string);
begin
  if not Condition then raise Exception.Create(MessageText);
end;

var
  C, Loaded: TCHATGPT;
  P: TAIProvider;
  Ini: TIniFile;
  FileName: string;
  ID: TGUID;
begin
  CreateGUID(ID);
  FileName := IncludeTrailingPathDelimiter(GetTempDir(False)) +
    'chatgpt-config-' + GUIDToString(ID) + '.ini';
  C := TCHATGPT.Create(nil);
  Loaded := TCHATGPT.Create(nil);
  try
    C.TOKEN := 'fixture-secret-never-persist';
    Check(not IsStoredProp(C, GetPropInfo(C, 'TOKEN')),
      'TOKEN must not be serialized into Lazarus forms.');
    for P := Low(TAIProvider) to High(TAIProvider) do
    begin
      C.Provider := P;
      Check(C.SaveToIni(FileName), 'Save failed.');
      Loaded.Provider := AIP_OPENAI;
      Check(Loaded.LoadFromIni(FileName), 'Load failed.');
      Check(Loaded.Provider = P, 'Provider changed: ' + GetAIProviderName(P));
    end;

    Ini := TIniFile.Create(FileName);
    try
      Check(not Ini.ValueExists('LLM', 'Token'), 'Token was persisted.');
      Ini.WriteString('LLM', 'Token', 'legacy-secret');
      Ini.WriteString('LLM', 'APIKey', 'legacy-api-key');
    finally Ini.Free; end;
    Loaded.TOKEN := 'runtime-secret';
    Loaded.LoadFromIni(FileName);
    Check(Loaded.TOKEN = 'runtime-secret', 'Legacy INI overwrote runtime credential.');
    Loaded.SaveToIni(FileName);
    Ini := TIniFile.Create(FileName);
    try
      Check(not Ini.ValueExists('LLM', 'Token'), 'Legacy Token was not removed.');
      Check(not Ini.ValueExists('LLM', 'APIKey'), 'Legacy APIKey was not removed.');
    finally Ini.Free; end;
    WriteLn('PASS: all ten providers round-trip; credentials stay out of INI/forms.');
  finally
    C.Free;
    Loaded.Free;
    DeleteFile(FileName);
  end;
end.
