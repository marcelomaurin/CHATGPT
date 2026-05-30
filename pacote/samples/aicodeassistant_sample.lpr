program aicodeassistant_sample;

{$mode objfpc}{$H+}

uses
  SysUtils, Classes, chatgpt, aicodeassistant;

var
  FChatgpt: TCHATGPT;
  FAssistant: TAICodeAssistant;
  PascalCode: string;
begin
  Writeln('=== Exemplo de Uso do Componente TAICodeAssistant ===');
  Writeln;

  FChatgpt := TCHATGPT.Create(nil);
  FAssistant := TAICodeAssistant.Create(nil);
  try
    // 1. Configura as chaves e provedor padrão no conector FChatgpt
    FChatgpt.TOKEN := 'SUA_CHAVE_API_AQUI';
    FChatgpt.Provider := AIP_CLAUDE;
    FChatgpt.TipoChat := VCT_CLAUDE_35_SONNET;

    // 2. Associa o conector ao assistente de programação
    FAssistant.ChatGPT := FChatgpt;

    // Código Pascal redundante ou problemático para análise
    PascalCode :=
      'procedure TForm1.ProcessData;' + #13#10 +
      'var' + #13#10 +
      '  i, j: Integer;' + #13#10 +
      '  TempList: TStringList;' + #13#10 +
      'begin' + #13#10 +
      '  TempList := TStringList.Create;' + #13#10 +
      '  for i := 0 to 100 do' + #13#10 +
      '  begin' + #13#10 +
      '    TempList.Add(IntToStr(i));' + #13#10 +
      '  end;' + #13#10 +
      '  // Note que TempList nunca é liberada da memória (Vazamento!)' + #13#10 +
      'end;';

    Writeln('Código Pascal original para análise:');
    Writeln('----------------------------------------------------');
    Writeln(PascalCode);
    Writeln('----------------------------------------------------');
    Writeln;

    if FChatgpt.TOKEN = 'SUA_CHAVE_API_AQUI' then
    begin
      Writeln('Nota: Chave de API de teste detectada. Por favor, edite este arquivo e coloque');
      Writeln('uma chave real para efetuar chamadas de rede bem-sucedidas.');
      Writeln;
    end
    else
    begin
      // Executa auditoria em busca de vazamentos ou falhas
      Writeln('Solicitando análise de bugs da IA (FindBugs)...');
      Writeln;
      Writeln('--- Auditoria da IA ---');
      Writeln(FAssistant.FindBugs(PascalCode));
      Writeln('-----------------------');
      Writeln;

      // Solicita otimização estrutural
      Writeln('Solicitando otimização do código Pascal (OptimizeCode)...');
      Writeln;
      Writeln('--- Código Otimizado ---');
      Writeln(FAssistant.OptimizeCode(PascalCode));
      Writeln('------------------------');
    end;

  finally
    FAssistant.Free;
    FChatgpt.Free;
  end;

  Writeln;
  Writeln('Pressione [Enter] para sair.');
  Readln;
end.
