program aivoicesynthesizer_sample;

{$mode objfpc}{$H+}

uses
  SysUtils, Classes, aivoicesynthesizer;

var
  FVoice: TAIVoiceSynthesizer;
  InputText: string;
begin
  Writeln('=== Exemplo de Uso do Componente TAIVoiceSynthesizer ===');
  Writeln;

  // Cria o componente sem proprietário (Owner = nil)
  FVoice := TAIVoiceSynthesizer.Create(nil);
  try
    // Configura propriedades padrões
    FVoice.Volume := 100;
    FVoice.Rate := 0; // Taxa de fala padrão
    FVoice.Asynchronous := False; // Síncrono para o console esperar o áudio concluir

    Writeln('Sistemas Operacionais Suportados:');
    Writeln(' - Windows (SAPI nativo)');
    Writeln(' - Linux (eSpeak / eSpeak-NG nativo)');
    Writeln;

    // Pergunta qual texto falar
    Writeln('Digite a frase que você deseja sintetizar em voz:');
    Write('> ');
    Readln(InputText);

    if Trim(InputText) = '' then
      InputText := 'Olá! Este é um teste de sintetização de voz do componente T A I Voice Synthesizer!';

    Writeln;
    Writeln('Sintetizando: "', InputText, '"...');
    
    // Executa a sintetização de voz
    FVoice.Say(InputText);

    if FVoice.LastError <> '' then
    begin
      Writeln('Erro na sintetização:');
      Writeln(FVoice.LastError);
    end
    else
    begin
      Writeln('Sintetização concluída com sucesso!');
    end;

  finally
    FVoice.Free;
  end;

  Writeln;
  Writeln('Pressione [Enter] para sair.');
  Readln;
end.
