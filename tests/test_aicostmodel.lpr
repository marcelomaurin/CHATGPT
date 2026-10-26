program test_aicostmodel;

{ Testes de console (sem LCL) de aicostmodel (AI Project Core): custo de
  trabalho e material, acumulacao no inicio, rateada e no fim, e dinheiro em texto.
  Compilar: fpc -Fu"../pacote/AI Project Core" test_aicostmodel.lpr }

{$mode objfpc}{$H+}

uses
  SysUtils, aicostmodel;

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

procedure TestCostCore;
var C: TAICostBreakdown; V: Double; A: TAICostAccrual;
begin
  Check(Near(AIWorkCost(90, 60), 90), '1 h 30 a R$ 60/h = R$ 90');
  Check(AIWorkCost(90, -1) = 0, 'taxa negativa vale zero');
  Check(Near(AIMaterialCost(0.12, 120), 14.4), '0,12 kg a R$ 120/kg');
  Check(AITryCostAccrualFromName('end', A) and (A = acaEnd), 'acumulacao no fim');
  Check(Near(AIAccruedFraction(acaStart, 0.01), 1) and Near(AIAccruedFraction(acaStart, 0), 0), 'no inicio');
  Check(Near(AIAccruedFraction(acaEnd, 0.99), 0) and Near(AIAccruedFraction(acaEnd, 1), 1), 'no fim');
  Check(Near(AIAccruedFraction(acaProrated, 0.25), 0.25), 'rateado');
  Check(Near(AIAccruedFractionAt(acaProrated, 10, 14, 11), 0.25), 'rateado por datas');
  Check(Near(AIAccruedFractionAt(acaEnd, 10, 10, 10), 1), 'marco vence na data');
  AIClearCost(C);
  C.Work := 100; C.PerUse := 10; C.Fixed := 50;
  Check(Near(AICostTotal(C), 160), 'total por origem');
  Check(Near(AICostToDate(C, acaEnd, 0.5), 50 + 10), 'vencido na metade: trabalho rateado, uso no inicio');
  Check(AIFormatMoney(1234.5) = 'R$ 1.234,50', 'formato R$: ' + AIFormatMoney(1234.5));
  Check(AIFormatMoney(-0.5, '') = '-0,50', 'negativo sem simbolo');
  Check(AIFormatMoney(1000000) = 'R$ 1.000.000,00', 'milhoes');
  Check(AITryParseMoney('R$ 1.234,50', V) and Near(V, 1234.5), 'le R$ 1.234,50');
  Check(AITryParseMoney('1,234.50', V) and Near(V, 1234.5), 'le 1,234.50');
  Check(AITryParseMoney('12,5', V) and Near(V, 12.5), 'le 12,5');
  Check(AITryParseMoney('12.5', V) and Near(V, 12.5), 'le 12.5');
  Check(AITryParseMoney('1.500', V) and Near(V, 1500), 'le 1.500 como milhar');
  Check(AITryParseMoney('150', V) and Near(V, 150), 'le inteiro');
  Check(not AITryParseMoney('doze', V), 'texto recusado');
  Check(not AITryParseMoney('', V), 'vazio recusado');
end;
begin
  Passed := 0; Failed := 0;
  TestCostCore;
  if Failed = 0 then
    Writeln(Format('PASS: %d checks (trabalho, material, acumulacao, formato e leitura de R$)', [Passed]))
  else
  begin
    Writeln(Format('FAIL: %d de %d checks', [Failed, Passed + Failed]));
    Halt(1);
  end;
end.
