program test_aitasktype;

{ Testes de console (sem LCL) de aitasktype (AI Project Core): tipo de tarefa
  (duracao, unidades ou trabalho fixo), empenho e Trabalho = Duracao x Unidades.
  Compilar: fpc -Fu"../pacote/AI Project Core" test_aitasktype.lpr }

{$mode objfpc}{$H+}

uses
  SysUtils, aitasktype;

var
  Passed, Failed: Integer;

procedure Check(Cond: Boolean; const What: string);
begin
  if Cond then Inc(Passed)
  else
  begin
    Inc(Failed);
    Writeln('FALHOU: ', What);
  end;
end;

function Near(A, B: Double; Tol: Double = 0.005): Boolean;
begin
  Result := Abs(A - B) <= Tol;
end;

procedure TestTaskTypeCore;
var R: TAITaskTypeResult; T: TAITaskType;
begin
  Check(AIWorkOf(480, 1.5) = 720, 'trabalho = duracao x unidades');
  Check(AIWorkOf(480, 0) = 0, 'sem unidades nao ha trabalho');
  Check(AITryTaskTypeFromName('fixed_work', T) and (T = attFixedWork), 'nome do tipo');
  Check(not AITryTaskTypeFromName('fixo', T), 'tipo desconhecido recusado');
  Check(AIIsEffortDriven(attFixedWork, False), 'trabalho fixo e sempre pelo empenho');
  { duracao muda }
  R := AIOnDurationChange(attFixedUnits, 480, 960, 1);
  Check(R.Ok and (R.Duration = 960) and Near(R.UnitScale, 1) and (R.Work = 960), 'unidades fixas: duracao dobra o trabalho');
  R := AIOnDurationChange(attFixedDuration, 480, 960, 1);
  Check(R.Ok and Near(R.UnitScale, 1) and (R.Work = 960), 'duracao fixa: trabalho acompanha');
  R := AIOnDurationChange(attFixedWork, 480, 960, 1);
  Check(R.Ok and Near(R.UnitScale, 0.5) and (R.Work = 480), 'trabalho fixo: unidades caem a metade');
  R := AIOnDurationChange(attFixedWork, 480, 0, 1);
  Check(not R.Ok, 'trabalho fixo nao aceita duracao zero com recurso');
  R := AIOnDurationChange(attFixedWork, 480, 960, 0);
  Check(R.Ok and Near(R.UnitScale, 1) and (R.Work = 0), 'sem recurso a duracao muda livre');
  { trabalho digitado }
  R := AIOnWorkChange(attFixedUnits, 480, 2, 1920);
  Check(R.Ok and (R.Duration = 960) and Near(R.UnitScale, 1), 'unidades fixas: trabalho muda a duracao');
  R := AIOnWorkChange(attFixedDuration, 480, 1, 240);
  Check(R.Ok and (R.Duration = 480) and Near(R.UnitScale, 0.5) and (R.Work = 240), 'duracao fixa: trabalho muda as unidades');
  R := AIOnWorkChange(attFixedWork, 480, 1, 0);
  Check(R.Ok and (R.Duration = 0), 'trabalho zero zera a duracao');
  R := AIOnWorkChange(attFixedWork, 480, 0, 600);
  Check(not R.Ok and (Pos('atribua', R.Error) > 0), 'trabalho sem recurso recusado');
  { recursos incluidos (empenho) }
  R := AIOnUnitsChange(attFixedUnits, True, True, 960, 1, 2);
  Check(R.Ok and (R.Duration = 480) and (R.Work = 960), 'empenho, unidades fixas: dois recursos na metade do tempo');
  R := AIOnUnitsChange(attFixedDuration, True, True, 960, 1, 2);
  Check(R.Ok and (R.Duration = 960) and Near(R.UnitScale, 0.5) and (R.Work = 960), 'empenho, duracao fixa: unidades redistribuidas');
  R := AIOnUnitsChange(attFixedUnits, False, True, 960, 1, 2);
  Check(R.Ok and (R.Duration = 960) and (R.Work = 1920), 'sem empenho: incluir recurso soma trabalho');
  R := AIOnUnitsChange(attFixedWork, False, True, 960, 2, 1);
  Check(R.Ok and (R.Duration = 1920), 'trabalho fixo: retirar recurso alonga');
  { unidades de quem ja estava }
  R := AIOnUnitsChange(attFixedUnits, False, False, 960, 1, 0.5);
  Check(R.Ok and (R.Duration = 1920), 'unidades fixas: meio periodo dobra a duracao');
  R := AIOnUnitsChange(attFixedDuration, True, False, 960, 1, 0.5);
  Check(R.Ok and (R.Duration = 960) and (R.Work = 480), 'duracao fixa: unidades mudam o trabalho');
  R := AIOnUnitsChange(attFixedWork, True, True, 960, 0, 1);
  Check(R.Ok and (R.Duration = 960), 'primeira atribuicao nao mexe na duracao');
end;
begin
  Passed := 0; Failed := 0;
  TestTaskTypeCore;
  if Failed = 0 then
    Writeln(Format('PASS: %d checks (duracao, trabalho e unidades nos tres tipos, empenho)', [Passed]))
  else
  begin
    Writeln(Format('FAIL: %d de %d checks', [Failed, Passed + Failed]));
    Halt(1);
  end;
end.
