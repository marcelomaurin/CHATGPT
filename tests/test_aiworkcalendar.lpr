program test_aiworkcalendar;

{ Testes de console (sem LCL) de aiworkcalendar (AI Project Core): Pascoa e
  feriados do Brasil, expediente padrao e 24 h, encaixe no expediente, somar e
  subtrair minutos uteis, minutos entre datas e JSON.
  Compilar: fpc -Fu"../pacote/AI Project Core" test_aiworkcalendar.lpr }

{$mode objfpc}{$H+}

uses
  Classes, SysUtils, DateUtils, fpjson, jsonparser, aiworkcalendar;

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

function DT(Y, M, D, H, N: Word): TDateTime;
begin
  Result := EncodeDate(Y, M, D) + EncodeTime(H, N, 0, 0);
end;

function S(T: TDateTime): string;
begin
  Result := FormatDateTime('yyyy-mm-dd hh:nn', T);
end;

procedure Same(A, B: TDateTime; const What: string);
begin
  Check(Abs(A - B) < 0.5 / 1440, What + ': ' + S(A) + ' esperado ' + S(B));
end;

procedure TestEaster;
begin
  Check(SameDate(AIEasterSunday(2024), EncodeDate(2024, 3, 31)), 'Pascoa 2024');
  Check(SameDate(AIEasterSunday(2025), EncodeDate(2025, 4, 20)), 'Pascoa 2025');
  Check(SameDate(AIEasterSunday(2026), EncodeDate(2026, 4, 5)), 'Pascoa 2026');
  Check(SameDate(AIEasterSunday(2027), EncodeDate(2027, 3, 28)), 'Pascoa 2027');
end;

procedure TestHolidays;
var C: TAIWorkCalendar;
begin
  C := TAIWorkCalendar.Create('padrao');
  try
    C.AddBrazilianHolidays(2026, 2027);
    Check(not C.IsWorkingDay(EncodeDate(2026, 11, 2)), 'Finados 2026 (segunda)');
    Check(C.ExceptionName(EncodeDate(2026, 11, 2)) = 'Finados', 'nome do feriado');
    Check(not C.IsWorkingDay(EncodeDate(2026, 11, 20)), 'Consciencia Negra 2026 (sexta)');
    Check(not C.IsWorkingDay(EncodeDate(2026, 2, 16)) and not C.IsWorkingDay(EncodeDate(2026, 2, 17)), 'Carnaval 2026');
    Check(not C.IsWorkingDay(EncodeDate(2026, 4, 3)), 'Sexta-feira Santa 2026');
    Check(not C.IsWorkingDay(EncodeDate(2026, 6, 4)), 'Corpus Christi 2026');
    Check(not C.IsWorkingDay(EncodeDate(2027, 5, 27)), 'Corpus Christi 2027');
    Check(C.IsWorkingDay(EncodeDate(2026, 10, 26)), 'segunda comum');
    Check(not C.IsWorkingDay(EncodeDate(2026, 10, 31)), 'sabado');
    Check(C.ExceptionCount = 2 * 13, '13 feriados por ano com pontos facultativos');
    Check(C.RemoveException(EncodeDate(2026, 6, 4)) and C.IsWorkingDay(EncodeDate(2026, 6, 4)), 'remover Corpus Christi');
  finally
    C.Free;
  end;
  C := TAIWorkCalendar.Create;
  try
    C.AddBrazilianHolidays(2023, 2023, False);
    Check(C.IsWorkingDay(EncodeDate(2023, 11, 20)), 'Consciencia Negra nao era nacional em 2023');
    Check(C.IsWorkingDay(EncodeDate(2023, 2, 20)), 'sem pontos facultativos: Carnaval trabalha');
    Check(C.ExceptionCount = 9, '9 feriados em 2023 sem facultativos');
  finally
    C.Free;
  end;
end;

procedure TestArithmetic;
var C: TAIWorkCalendar;
begin
  C := TAIWorkCalendar.Create('padrao');
  try
    C.AddBrazilianHolidays(2026, 2026);
    Check(C.WorkingMinutesOfDay(EncodeDate(2026, 10, 26)) = 480, '8 h por dia');
    Check(C.IsWorkingTime(DT(2026, 10, 26, 8, 0)) and not C.IsWorkingTime(DT(2026, 10, 26, 12, 30)), 'expediente e almoco');
    Same(C.SnapForward(DT(2026, 10, 26, 7, 0)), DT(2026, 10, 26, 8, 0), 'antes do expediente');
    Same(C.SnapForward(DT(2026, 10, 26, 12, 15)), DT(2026, 10, 26, 13, 0), 'no almoco');
    Same(C.SnapForward(DT(2026, 10, 26, 17, 0)), DT(2026, 10, 27, 8, 0), 'fim do dia vai para o dia seguinte');
    Same(C.SnapForward(DT(2026, 10, 30, 18, 0)), DT(2026, 11, 3, 8, 0), 'sexta a noite pula fim de semana e Finados');
    Same(C.SnapForward(DT(2026, 10, 26, 9, 30)), DT(2026, 10, 26, 9, 30), 'dentro do expediente fica');
    Same(C.SnapBackward(DT(2026, 10, 27, 8, 0)), DT(2026, 10, 26, 17, 0), 'inicio do dia volta para o fim do anterior');
    Same(C.SnapBackward(DT(2026, 10, 26, 12, 30)), DT(2026, 10, 26, 12, 0), 'almoco volta para 12:00');
    Same(C.SnapBackward(DT(2026, 10, 26, 17, 0)), DT(2026, 10, 26, 17, 0), 'fim do intervalo fica');
    Same(C.AddWorkingMinutes(DT(2026, 10, 26, 8, 0), 480), DT(2026, 10, 26, 17, 0), '1 dia termina 17:00 do mesmo dia');
    Same(C.AddWorkingMinutes(DT(2026, 10, 26, 8, 0), 240), DT(2026, 10, 26, 12, 0), '4 h termina 12:00');
    Same(C.AddWorkingMinutes(DT(2026, 10, 26, 8, 0), 300), DT(2026, 10, 26, 14, 0), '5 h atravessa o almoco');
    Same(C.AddWorkingMinutes(DT(2026, 10, 26, 8, 0), 5 * 480), DT(2026, 10, 30, 17, 0), '5 dias = sexta 17:00');
    Same(C.AddWorkingMinutes(DT(2026, 10, 26, 8, 0), 6 * 480), DT(2026, 11, 3, 17, 0), '6 dias pula fim de semana e Finados');
    Same(C.AddWorkingMinutes(DT(2026, 10, 26, 7, 0), 60), DT(2026, 10, 26, 9, 0), 'comeca no expediente');
    Same(C.AddWorkingMinutes(DT(2026, 10, 26, 17, 0), -480), DT(2026, 10, 26, 8, 0), 'subtrair 1 dia');
    Same(C.AddWorkingMinutes(DT(2026, 11, 3, 8, 0), -60), DT(2026, 10, 30, 16, 0), 'subtrair atravessa Finados e fim de semana');
    Same(C.AddWorkingMinutes(DT(2026, 10, 26, 14, 0), -300), DT(2026, 10, 26, 8, 0), 'subtrair atravessa o almoco');
    Same(C.AddWorkingMinutes(DT(2026, 10, 26, 9, 0), 0), DT(2026, 10, 26, 9, 0), 'zero nao move');
    Check(C.WorkingMinutesBetween(DT(2026, 10, 26, 8, 0), DT(2026, 10, 30, 17, 0)) = 2400, 'semana inteira = 2400 min');
    Check(C.WorkingMinutesBetween(DT(2026, 10, 30, 8, 0), DT(2026, 11, 3, 17, 0)) = 960, 'sexta + terca (Finados no meio)');
    Check(C.WorkingMinutesBetween(DT(2026, 10, 26, 17, 0), DT(2026, 10, 26, 8, 0)) = -480, 'negativo quando invertido');
    Check(C.WorkingMinutesBetween(DT(2026, 10, 26, 11, 0), DT(2026, 10, 26, 14, 0)) = 120, 'parcial com almoco');
  finally
    C.Free;
  end;
end;

procedure Test24h;
var C: TAIWorkCalendar;
begin
  C := TAIWorkCalendar.Create('24h');
  try
    C.Set24Hours;
    Same(C.AddWorkingMinutes(DT(2026, 10, 30, 20, 0), 14 * 60), DT(2026, 10, 31, 10, 0), 'impressao de 14 h atravessa a noite');
    Same(C.SnapForward(DT(2026, 10, 31, 3, 0)), DT(2026, 10, 31, 3, 0), '24 h: sempre expediente');
    Check(C.WorkingMinutesBetween(DT(2026, 10, 30, 0, 0), DT(2026, 11, 2, 0, 0)) = 3 * 1440, '3 dias corridos');
    { manutencao da maquina como excecao: 6 h de parada no domingo }
    C.AddException(EncodeDate(2026, 11, 1), 'Manutencao', [360, 1440]);
    Same(C.AddWorkingMinutes(DT(2026, 10, 31, 23, 0), 120), DT(2026, 11, 1, 7, 0), 'maquina parada ate 06:00');
  finally
    C.Free;
  end;
end;

procedure TestErrorsAndJSON;
var C, D: TAIWorkCalendar; O: TJSONObject; Raised: Boolean; Txt: string;
begin
  C := TAIWorkCalendar.Create('vazio');
  try
    C.Clear;
    Raised := False;
    try C.AddWorkingMinutes(DT(2026, 1, 1, 8, 0), 60); except on EAIWorkCalendar do Raised := True; end;
    Check(Raised, 'calendario sem expediente levanta EAIWorkCalendar');
    Raised := False;
    try C.SetWeekDay(2, [600, 500]); except on EAIWorkCalendar do Raised := True; end;
    Check(Raised, 'intervalo invertido recusado');
    Raised := False;
    try C.SetWeekDay(2, [480, 720, 700, 800]); except on EAIWorkCalendar do Raised := True; end;
    Check(Raised, 'intervalos sobrepostos recusados');
    Raised := False;
    try C.SetWeekDay(8, []); except on EAIWorkCalendar do Raised := True; end;
    Check(Raised, 'dia da semana invalido');
  finally
    C.Free;
  end;
  C := TAIWorkCalendar.Create('oficina');
  D := TAIWorkCalendar.Create('outro');
  try
    C.SetWeekDay(7, [480, 720]);   // sabado de manha
    C.AddBrazilianHolidays(2026, 2026);
    C.AddException(EncodeDate(2026, 12, 24), 'Vespera de Natal', [480, 720]);
    O := C.ToJSON;
    try
      Txt := O.AsJSON;
      D.FromJSON(O);
    finally
      O.Free;
    end;
    Check(D.Name = 'oficina', 'nome lido');
    Check(D.WorkingMinutesOfDay(EncodeDate(2026, 10, 31)) = 240, 'sabado de manha lido');
    Check(not D.IsWorkingDay(EncodeDate(2026, 11, 2)), 'feriado lido');
    Check(D.WorkingMinutesOfDay(EncodeDate(2026, 12, 24)) = 240, 'excecao com meio expediente lida');
    Check(D.ExceptionCount = C.ExceptionCount, 'mesmo numero de excecoes');
    O := D.ToJSON;
    try
      Check(O.AsJSON = Txt, 'ida e volta do JSON identica');
    finally
      O.Free;
    end;
    { JSON invalido nao estraga o calendario }
    O := TJSONObject(GetJSON('{"name":"x","week":[[],[],[]]}'));
    try
      Raised := False;
      try D.FromJSON(O); except on EAIWorkCalendar do Raised := True; end;
      Check(Raised and (D.Name = 'oficina') and not D.IsWorkingDay(EncodeDate(2026, 11, 2)), 'JSON invalido recusado sem alterar');
    finally
      O.Free;
    end;
  finally
    C.Free;
    D.Free;
  end;
end;

begin
  Passed := 0; Failed := 0;
  TestEaster;
  TestHolidays;
  TestArithmetic;
  Test24h;
  TestErrorsAndJSON;
  if Failed = 0 then
    Writeln(Format('PASS: %d checks (Pascoa, feriados BR, expediente, minutos uteis, 24 h, JSON)', [Passed]))
  else
  begin
    Writeln(Format('FAIL: %d de %d checks', [Failed, Passed + Failed]));
    Halt(1);
  end;
end.
