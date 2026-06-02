program aidatasetgenerator_sample;

{$mode objfpc}{$H+}

uses
  SysUtils, NeuralNetwork, aidatasetgenerator;

var
  FGen: TAIDatasetGenerator;
  Inputs: TMatrix;
  Targets: TMatrix;
  I, J: Integer;
begin
  Writeln('=== Exemplo de Uso do Componente TAIDatasetGenerator ===');
  Writeln;

  // Cria o componente sem proprietário (Owner = nil)
  FGen := TAIDatasetGenerator.Create(nil);
  try
    // 1. Populando dados em memória para exportar
    Writeln('Adicionando linhas de dados de treino na memória...');
    FGen.AddDataRow('Qual o comando de compilação do FPC?', 'O comando básico é fpc arquivo.pas');
    FGen.AddDataRow('Como instalo pacote no Lazarus?', 'Menu Package > Open Package File (.lpk), Compile e Install.');
    FGen.AddDataRow('Qual a extensão de pacotes Lazarus?', 'A extensão de pacotes do Lazarus é .lpk');
    Writeln;

    // 2. Exportando para JSONL (Utilizado no Fine-Tuning de LLMs globais)
    Writeln('Exportando dados para o formato de fine-tuning "dataset.jsonl"...');
    FGen.SaveAsJSONL('dataset.jsonl');
    Writeln('Concluído! Arquivo "dataset.jsonl" gerado com sucesso.');
    Writeln;

    // 3. Salvando dados tabulares simples em formato CSV
    Writeln('Exportando dados genéricos para formato delimitado "dataset.csv"...');
    FGen.SaveAsCSV('dataset.csv');
    Writeln('Concluído! Arquivo "dataset.csv" gerado com sucesso.');
    Writeln;

    // 4. Simulando a geração de um arquivo CSV numérico para alimentar a Rede Neural local
    Writeln('Criando um arquivo CSV de dados numéricos "dados_treino.csv" (ex: lógica XOR)...');
    AssignFile(Output, 'dados_treino.csv');
    Rewrite(Output);
    try
      Writeln(Output, 'input1;input2;target1'); // Cabeçalho
      Writeln(Output, '0;0;0');
      Writeln(Output, '0;1;1');
      Writeln(Output, '1;0;1');
      Writeln(Output, '1;1;0');
    finally
      CloseFile(Output);
    end;
    Writeln('Arquivo "dados_treino.csv" gerado.');
    Writeln;

    // 5. Carregando dados numéricos do CSV direto para as matrizes TMatrix
    Writeln('Efetuando parse do CSV direto para as matrizes TMatrix de treinamento...');
    FGen.LoadFromCSV('dados_treino.csv', Inputs, Targets, 2, 1); // 2 colunas de entrada, 1 coluna de saída

    Writeln('Parse Concluído com Sucesso!');
    Writeln('Linhas carregadas: ', Length(Inputs));
    Writeln;

    Writeln('--- Dados Carregados do CSV para as Matrizes (Visualização) ---');
    for I := 0 to High(Inputs) do
    begin
      Write('Linha ', I + 1, ' => Entrada: [');
      for J := 0 to High(Inputs[I]) do
      begin
        Write(Inputs[I, J]:0:0);
        if J < High(Inputs[I]) then Write(', ');
      end;
      Write('] | Alvo (Target): [');
      for J := 0 to High(Targets[I]) do
      begin
        Write(Targets[I, J]:0:0);
        if J < High(Targets[I]) then Write(', ');
      end;
      Writeln(']');
    end;
    Writeln('--------------------------------------------------------------');
    Writeln;
    Writeln('Essas matrizes podem ser enviadas diretamente para a rede neural:');
    Writeln('  FNet.TrainEpochs(Inputs, Targets, 1000, Loss);');

  finally
    FGen.Free;
  end;

  Writeln;
  Writeln('Pressione [Enter] para sair.');
  Readln;
end.
