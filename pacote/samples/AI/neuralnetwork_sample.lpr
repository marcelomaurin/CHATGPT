program neuralnetwork_sample;

{$mode objfpc}{$H+}

uses
  Interfaces, SysUtils, Math, NeuralNetwork;

var
  FNet: TNeuralNetwork;
  DatasetInputs: TMatrix;
  DatasetTargets: TMatrix;
  TestInput: TArray;
  Prediction: TArray;
  FinalLoss: Double;
  I: Integer;
begin
  Writeln('=== Exemplo de Uso do Componente TNeuralNetwork ===');
  Writeln('Treinando a rede neural local no clássico problema lógico XOR...');
  Writeln;

  // Cria a rede neural sem proprietário (Owner = nil)
  FNet := TNeuralNetwork.Create(nil);
  try
    // 1. Inicializa rede com 2 Entradas, 4 neurônios Ocultos, 1 neurônio de Saída.
    // Taxa de aprendizado (Learning Rate) = 0.1
    FNet.Initialize(2, 4, 1, 0.1);
    
    // Escolhe a função de ativação Sigmoide
    FNet.ActivationType := atSigmoid;

    // 2. Define o Dataset XOR
    // XOR entradas: [0,0], [0,1], [1,0], [1,1]
    // XOR alvos correspondentes: [0], [1], [1], [0]
    SetLength(DatasetInputs, 4);
    SetLength(DatasetInputs[0], 2); DatasetInputs[0, 0] := 0; DatasetInputs[0, 1] := 0;
    SetLength(DatasetInputs[1], 2); DatasetInputs[1, 0] := 0; DatasetInputs[1, 1] := 1;
    SetLength(DatasetInputs[2], 2); DatasetInputs[2, 0] := 1; DatasetInputs[2, 1] := 0;
    SetLength(DatasetInputs[3], 2); DatasetInputs[3, 0] := 1; DatasetInputs[3, 1] := 1;

    SetLength(DatasetTargets, 4);
    SetLength(DatasetTargets[0], 1); DatasetTargets[0, 0] := 0;
    SetLength(DatasetTargets[1], 1); DatasetTargets[1, 0] := 1;
    SetLength(DatasetTargets[2], 1); DatasetTargets[2, 0] := 1;
    SetLength(DatasetTargets[3], 1); DatasetTargets[3, 0] := 0;

    Writeln('Iniciando treinamento de 5000 épocas...');
    
    // Executa o treinamento em lote com acompanhamento de perda
    FNet.TrainEpochs(DatasetInputs, DatasetTargets, 5000, FinalLoss);

    Writeln('Treino Concluído!');
    Writeln(Format('Erro Quadrático Médio Final (MSE Loss): %0.8f', [FinalLoss]));
    Writeln;

    // 3. Testando as predições após o treinamento
    Writeln('--- Predições da Rede Neural Treinada ---');
    SetLength(TestInput, 2);
    
    // Teste [0,0]
    TestInput[0] := 0; TestInput[1] := 0;
    Prediction := FNet.Predict(TestInput);
    Writeln(Format('XOR Input [0, 0] => Predição: %0.4f (Alvo: 0.00)', [Prediction[0]]));

    // Teste [0,1]
    TestInput[0] := 0; TestInput[1] := 1;
    Prediction := FNet.Predict(TestInput);
    Writeln(Format('XOR Input [0, 1] => Predição: %0.4f (Alvo: 1.00)', [Prediction[0]]));

    // Teste [1,0]
    TestInput[0] := 1; TestInput[1] := 0;
    Prediction := FNet.Predict(TestInput);
    Writeln(Format('XOR Input [1, 0] => Predição: %0.4f (Alvo: 1.00)', [Prediction[0]]));

    // Teste [1,1]
    TestInput[0] := 1; TestInput[1] := 1;
    Prediction := FNet.Predict(TestInput);
    Writeln(Format('XOR Input [1, 1] => Predição: %0.4f (Alvo: 0.00)', [Prediction[0]]));
    Writeln('----------------------------------------');

    // 4. Salva a rede em arquivo texto
    FNet.SaveNetwork('xor_network.net');
    Writeln;
    Writeln('Pesos e biases da rede salvos em "xor_network.net".');

  finally
    FNet.Free;
  end;

  Writeln;
  Writeln('Pressione [Enter] para sair.');
  Readln;
end.
