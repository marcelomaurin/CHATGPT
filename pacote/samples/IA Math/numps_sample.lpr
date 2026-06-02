program numps_sample;

{$mode objfpc}{$H+}

uses
  SysUtils, Classes, Math, numps;

var
  FNumPS: TNumPS;
  Arr: TArray;
  MatA, MatB, MatC: TMatrix;
  I, J: Integer;
begin
  Writeln('=== Exemplo de Uso do Componente TNumPS (NumPy em Pascal) ===');
  Writeln;

  FNumPS := TNumPS.Create(nil);
  try
    // 1. Zeros
    Writeln('1. Gerando matriz Zeros (2x3):');
    MatA := FNumPS.Zeros(2, 3);
    for I := 0 to High(MatA) do
    begin
      Write('  [');
      for J := 0 to High(MatA[I]) do
      begin
        Write(Format('%0.1f', [MatA[I, J]]));
        if J < High(MatA[I]) then Write(', ');
      end;
      Writeln(']');
    end;
    Writeln;

    // 2. LinSpace
    Writeln('2. Gerando LinSpace (0 a 1 em 5 passos):');
    Arr := FNumPS.LinSpace(0, 1, 5);
    Write('  [');
    for I := 0 to High(Arr) do
    begin
      Write(Format('%0.2f', [Arr[I]]));
      if I < High(Arr) then Write(', ');
    end;
    Writeln(']');
    Writeln;

    // 3. MatMul (Multiplicacao Matricial)
    Writeln('3. Multiplicacao de Matrizes (MatMul):');
    SetLength(MatA, 2, 2);
    MatA[0, 0] := 1; MatA[0, 1] := 2;
    MatA[1, 0] := 3; MatA[1, 1] := 4;

    SetLength(MatB, 2, 2);
    MatB[0, 0] := 5; MatB[0, 1] := 6;
    MatB[1, 0] := 7; MatB[1, 1] := 8;

    MatC := FNumPS.MatMul(MatA, MatB);
    Writeln('  MatA:');
    Writeln('    [1.0, 2.0]');
    Writeln('    [3.0, 4.0]');
    Writeln('  MatB:');
    Writeln('    [5.0, 6.0]');
    Writeln('    [7.0, 8.0]');
    Writeln('  Resultado MatMul:');
    for I := 0 to High(MatC) do
    begin
      Write('    [');
      for J := 0 to High(MatC[I]) do
      begin
        Write(Format('%0.1f', [MatC[I, J]]));
        if J < High(MatC[I]) then Write(', ');
      end;
      Writeln(']');
    end;
    Writeln;

    // 4. Estatisticas
    Writeln('4. Calculo de estatisticas em array [-1.5, 3.2, 5.8, 10.0]:');
    SetLength(Arr, 4);
    Arr[0] := -1.5; Arr[1] := 3.2; Arr[2] := 5.8; Arr[3] := 10.0;

    Writeln(Format('  Soma: %0.2f', [FNumPS.Sum(Arr)]));
    Writeln(Format('  Media: %0.2f', [FNumPS.Mean(Arr)]));
    Writeln(Format('  Desvio Padrao (Std): %0.2f', [FNumPS.Std(Arr)]));
    Writeln(Format('  Minimo: %0.2f no indice %d', [FNumPS.Min(Arr), FNumPS.ArgMin(Arr)]));
    Writeln(Format('  Maximo: %0.2f no indice %d', [FNumPS.Max(Arr), FNumPS.ArgMax(Arr)]));
    Writeln;

  finally
    FNumPS.Free;
  end;

  Writeln('Pressione [Enter] para sair.');
  Readln;
end.
