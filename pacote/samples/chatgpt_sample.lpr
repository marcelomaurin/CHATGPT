program chatgpt_sample;

{$mode objfpc}{$H+}

uses
  SysUtils, Classes, chatgpt;

var
  FChatgpt: TCHATGPT;
  QuestionText: string;
begin
  Writeln('=== Exemplo de Uso do Componente TCHATGPT ===');
  Writeln;

  // Cria o componente sem proprietário (Owner = nil)
  FChatgpt := TCHATGPT.Create(nil);
  try
    // 1. Configurando o Provedor (exemplo com Google Gemini)
    // Para testar, substitua pela sua chave e altere o provider/modelo conforme desejado.
    FChatgpt.TOKEN := 'SUA_CHAVE_GEMINI_AQUI';
    FChatgpt.Provider := AIP_GEMINI;
    FChatgpt.TipoChat := VCT_GEMINI_25_FLASH;
    FChatgpt.MaxTokens := 1024;
    FChatgpt.Dev := 'Você é um assistente de desenvolvimento sênior da comunidade Delphi/Lazarus.';

    Writeln('Provedor Selecionado: ', FChatgpt.ProviderName);
    Writeln('Modelo Selecionado  : ', FChatgpt.TipoModelo);
    Writeln;

    // Pergunta de exemplo
    QuestionText := 'Escreva uma rotina simples em Pascal para calcular o Fatorial de um número.';
    Writeln('Enviando pergunta: "', QuestionText, '"...');
    Writeln;

    // Envia a pergunta.
    // Nota: Lembre-se de fornecer um Token de API válido na linha FChatgpt.TOKEN.
    if FChatgpt.TOKEN = 'SUA_CHAVE_GEMINI_AQUI' then
    begin
      Writeln('Nota: Chave de API de teste detectada. Por favor, edite este arquivo e coloque');
      Writeln('uma chave real para efetuar chamadas de rede bem-sucedidas.');
      Writeln;
    end
    else
    begin
      if FChatgpt.SendQuestion(QuestionText) then
      begin
        Writeln('--- Resposta da IA ---');
        Writeln(FChatgpt.Response);
        Writeln('----------------------');
      end
      else
      begin
        Writeln('Falha ao obter resposta!');
        Writeln('Log Completo do Erro: ', FChatgpt.Response);
      end;
    end;

  finally
    FChatgpt.Free;
  end;

  Writeln;
  Writeln('Pressione [Enter] para sair.');
  Readln;
end.
