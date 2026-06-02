program aiinput_sample;

{$mode objfpc}{$H+}

uses
  SysUtils, Classes, aiinput;

var
  FAIInput: TAIInputData;
  I: Integer;
begin
  Writeln('=== Exemplo de Uso do Componente TAIInputData (Entrada e Normalizacao) ===');
  Writeln;

  FAIInput := TAIInputData.Create(nil);
  try
    // 1. Carregar valores a partir de string delimitada
    Writeln('1. Carregando dados flutuantes brutas a partir de string:');
    FAIInput.LoadFromString('150.0, 300.0, 75.0, 600.0, 450.0', ',');
    
    Write('  Valores Carregados: [');
    for I := 0 to FAIInput.GetLength - 1 do
    begin
      Write(Format('%0.1f', [FAIInput.RawData[I]]));
      if I < FAIInput.GetLength - 1 then Write(', ');
    end;
    Writeln(']');
    Writeln;

    // 2. Normalizacao
    Writeln('2. Aplicando Normalizacao Linear para a faixa [0.0, 1.0]:');
    FAIInput.MinRange := 0.0;
    FAIInput.MaxRange := 1.0;
    FAIInput.Normalize;

    Write('  Valores Normalizados: [');
    for I := 0 to FAIInput.GetLength - 1 do
    begin
      Write(Format('%0.4f', [FAIInput.NormalizedData[I]]));
      if I < FAIInput.GetLength - 1 then Write(', ');
    end;
    Writeln(']');
    Writeln;

    // 3. Desnormalizacao
    Writeln('3. Desnormalizando para conferir os dados originais:');
    FAIInput.Denormalize;

    Write('  Valores Desnormalizados: [');
    for I := 0 to FAIInput.GetLength - 1 do
    begin
      Write(Format('%0.1f', [FAIInput.RawData[I]]));
      if I < FAIInput.GetLength - 1 then Write(', ');
    end;
    Writeln(']');
    Writeln;

  finally
    FAIInput.Free;
  end;

  Writeln('Pressione [Enter] para sair.');
  Readln;
end.
