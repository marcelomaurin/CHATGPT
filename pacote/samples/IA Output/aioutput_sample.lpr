program aioutput_sample;

{$mode objfpc}{$H+}

uses
  SysUtils, Classes, aioutput;

var
  FAIOutput: TAIOutputData;
  Logits: TArray;
  I: Integer;
begin
  Writeln('=== Exemplo de Uso do Componente TAIOutputData (Ativacao SoftMax e Decisao) ===');
  Writeln;

  FAIOutput := TAIOutputData.Create(nil);
  try
    Writeln('=== ORIENTACAO DE IA (PROMPT) ===');
    Writeln(FAIOutput.Prompt);
    Writeln('=================================');
    Writeln;

    // 1. Configurar classes e pontuacoes brutas (Logits)
    Writeln('1. Configurando Classes e Logits brutos de classificacao:');
    
    FAIOutput.Classes.Add('Cachorro');
    FAIOutput.Classes.Add('Gato');
    FAIOutput.Classes.Add('Passaro');

    SetLength(Logits, 3);
    Logits[0] := 2.0;  // Score bruto para Cachorro
    Logits[1] := 1.0;  // Score bruto para Gato
    Logits[2] := 0.1;  // Score bruto para Passaro

    FAIOutput.Probabilities := Logits;

    for I := 0 to FAIOutput.Classes.Count - 1 do
      Writeln(Format('  - %s: Logit = %0.1f', [FAIOutput.Classes[I], FAIOutput.Probabilities[I]]));
    Writeln;

    // 2. Executar SoftMax
    Writeln('2. Aplicando a ativacao SoftMax probabilistica:');
    FAIOutput.SoftMax;

    for I := 0 to FAIOutput.Classes.Count - 1 do
      Writeln(Format('  - %s: Probabilidade = %0.2f%%', [FAIOutput.Classes[I], FAIOutput.Probabilities[I] * 100.0]));
    Writeln;

    // 3. Obter Decisao Final
    Writeln('3. Resolucao da Decisao de Maior Probabilidade:');
    Writeln(Format('  - Indice predito: %d', [FAIOutput.GetBestClassIndex]));
    Writeln(Format('  - Classe predita: %s', [FAIOutput.GetBestClassName]));
    Writeln('  - Formatacao de Resultado: ', FAIOutput.ClassificationResult);
    Writeln;

  finally
    FAIOutput.Free;
  end;

  Writeln('Pressione [Enter] para sair.');
  Readln;
end.
