program test_aiprojectcore_utils;

{ Testes de console (sem LCL) das units genericas do AI Project Core:
  aiprojectduration, aiundohistory e aijsonutils.
  Compilar: fpc -Fu"../pacote/AI Project Core" test_aiprojectcore_utils.lpr }

{$mode objfpc}{$H+}

uses
  Classes, SysUtils, fpjson, aiprojectduration, aiundohistory, aijsonutils;

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

function Dur(const S: string; out D: TAIDuration): Boolean;
var Err: string;
begin
  Result := AITryParseDuration(S, 480, 2400, D, Err);
end;

procedure TestDuration;
var D: TAIDuration; Err: string; Keep: Char;
begin
  Check(Dur('30min', D) and (D.Minutes = 30) and (D.DisplayUnit = aduMinute), '30min');
  Check(Dur('4h', D) and (D.Minutes = 240) and (D.DisplayUnit = aduHour), '4h');
  Check(Dur('2d', D) and (D.Minutes = 960) and not D.Elapsed, '2d = 2 x 8 h');
  Check(Dur('1sem', D) and (D.Minutes = 2400), '1sem = 40 h');
  Check(Dur('14eh', D) and (D.Minutes = 840) and D.Elapsed, '14eh decorrida');
  Check(Dur('2ed', D) and (D.Minutes = 2880) and D.Elapsed, '2ed = 48 h');
  Check(Dur('1esem', D) and (D.Minutes = 7 * 1440) and D.Elapsed, '1esem = 7 dias corridos');
  Check(Dur('4h?', D) and D.Estimated and (D.Minutes = 240), '4h? estimada');
  Check(Dur('3', D) and (D.Minutes = 1440) and (D.DisplayUnit = aduDay), 'sem unidade = dias');
  Check(Dur('1,5d', D) and (D.Minutes = 720), 'virgula decimal');
  Check(Dur(' 1.5 D ', D) and (D.Minutes = 720), 'ponto, espacos e maiusculas');
  Check(Dur('2 hours', D) and (D.Minutes = 120), 'sinonimo em ingles');
  Check(not Dur('abc', D), 'recusa texto');
  Check(not Dur('3x', D), 'recusa unidade desconhecida');
  Check(not Dur('', D), 'recusa vazio');
  Check(not AITryParseDuration('2d', 0, 2400, D, Err), 'recusa calendario sem horas');
  Check(AIFormatDuration(AIMakeDuration(720, aduDay), 480, 2400) = '1.5d', 'formata 1.5d');
  Check(AIFormatDuration(AIMakeDuration(840, aduHour, True), 480, 2400) = '14eh', 'formata 14eh');
  Check(AIFormatDuration(AIMakeDuration(240, aduHour, False, True), 480, 2400) = '4h?', 'formata 4h?');
  Check(AIFormatDuration(AIMakeDuration(0, aduDay), 480, 2400) = '0d', 'formata marco 0d');
  { regional com virgula nao muda a saida }
  Keep := DefaultFormatSettings.DecimalSeparator;
  DefaultFormatSettings.DecimalSeparator := ',';
  try
    Check(AIFormatDuration(AIMakeDuration(720, aduDay), 480, 2400) = '1.5d', 'formata com regional virgula');
    Check(Dur('1.5d', D) and (D.Minutes = 720), 'le ponto com regional virgula');
  finally
    DefaultFormatSettings.DecimalSeparator := Keep;
  end;
  { ida e volta pela formatacao }
  Check(Dur(AIFormatDuration(AIMakeDuration(90, aduHour), 480, 2400), D) and (D.Minutes = 90), 'ida e volta 1.5h');
end;

procedure TestUndo;
var H: TAIUndoHistory; Doc: string;
begin
  H := TAIUndoHistory.Create(3);
  try
    Doc := 'v0';
    Check(not H.CanUndo, 'historico vazio');
    H.BeginChange('A', Doc); Doc := 'v1'; Check(H.EndChange, 'fim de A');
    H.BeginChange('B', Doc);
    Check(not H.BeginChange('B interno', Doc), 'aninhado nao grava foto');
    Doc := 'v2';
    Check(not H.EndChange, 'fim interno nao fecha');
    Check(H.EndChange, 'fim externo fecha');
    Check(H.UndoCount = 2, 'dois passos');
    Check(H.UndoDescription = 'B', 'descricao do topo');
    Doc := H.Undo(Doc); Check(Doc = 'v1', 'desfaz B');
    Check(H.CanRedo and (H.RedoDescription = 'B'), 'pode refazer B');
    Doc := H.Undo(Doc); Check(Doc = 'v0', 'desfaz A');
    Doc := H.Redo(Doc); Check(Doc = 'v1', 'refaz A');
    H.BeginChange('C', Doc); Doc := 'v3'; H.EndChange;
    Check(not H.CanRedo, 'alteracao nova limpa refazer');
    H.BeginChange('D', Doc); Doc := 'v4'; H.EndChange;
    H.BeginChange('E', Doc); Doc := 'v5'; H.EndChange;
    Check(H.UndoCount = 3, 'limite de 3 passos');
    H.Suspend;
    Check(not H.BeginChange('X', Doc), 'suspenso nao grava');
    H.EndChange;
    H.Resume;
    Check(H.UndoCount = 3, 'suspenso nao altera contagem');
    H.BeginChange('F', Doc);
    Check(not H.CanUndo, 'nao desfaz no meio de uma alteracao');
    H.EndChange;
  finally
    H.Free;
  end;
end;

procedure TestJSON;
var
  Orig, Known, M: TJSONObject;
  D: TDateTime;
  S, Tmp: string;
  Raised: Boolean;
begin
  Orig := AIJSONParseObject('{"a":1,"extra":{"x":true},"nested":{"k":1,"future":"f"},"b":"old"}');
  try
    Known := AIJSONParseObject('{"b":"new","a":2,"nested":{"k":5},"c":[1]}');
    M := AIJSONMergeKnown(Orig, Known);
    try
      Check(M.AsJSON = '{ "a" : 2, "extra" : { "x" : true }, "nested" : { "k" : 5, "future" : "f" }, "b" : "new", "c" : [1] }',
        'mescla preserva ordem e campos desconhecidos: ' + M.AsJSON);
    finally
      M.Free;
    end;
  finally
    Orig.Free;
  end;
  Known := AIJSONParseObject('{"z":1}');
  M := AIJSONMergeKnown(nil, Known);
  Check(M = Known, 'sem original devolve o proprio objeto');
  M.Free;

  M := AIJSONParseObject('{"s":"t","n":5,"b":false,"o":{},"a":[],"x":null,"bad":[1]}');
  try
    Check(AIJSONStr(M, 's') = 't', 'texto');
    Check(AIJSONStr(M, 'falta', 'p') = 'p', 'texto padrao');
    Check(AIJSONStr(M, 'x', 'p') = 'p', 'null usa padrao');
    Check(AIJSONInt64(M, 'n', 0) = 5, 'numero');
    Check(not AIJSONBool(M, 'b', True), 'booleano');
    Check(AIJSONObj(M, 'o') <> nil, 'objeto');
    Check(AIJSONArr(M, 'a') <> nil, 'lista');
    Raised := False;
    try AIJSONStr(M, 'bad'); except on EAIJSONFormat do Raised := True; end;
    Check(Raised, 'lista no lugar de texto levanta EAIJSONFormat');
    Raised := False;
    try AIJSONInt64(M, 's', 0); except on EAIJSONFormat do Raised := True; end;
    Check(Raised, 'texto no lugar de numero levanta EAIJSONFormat');
  finally
    M.Free;
  end;
  Raised := False;
  try AIJSONParseObject('[1,2]'); except on EAIJSONFormat do Raised := True; end;
  Check(Raised, 'lista na raiz recusada');
  Raised := False;
  try AIJSONParseObject('{quebrado'); except on EAIJSONFormat do Raised := True; end;
  Check(Raised, 'JSON quebrado recusado');

  Check(AITryISOToDate('2026-10-26T08:30:00', D) and (AIDateToISO(D) = '2026-10-26T08:30:00'), 'data ISO ida e volta');
  Check(AITryISOToDate('2026-10-26', D) and (AIDateToISO(D) = '2026-10-26T00:00:00'), 'so data');
  Check(AITryISOToDate('', D) and (D = 0) and (AIDateToISO(0) = ''), 'data vazia');
  Check(not AITryISOToDate('26/10/2026', D), 'recusa formato brasileiro');
  Check(not AITryISOToDate('2026-02-30', D), 'recusa data inexistente');

  Tmp := GetTempDir(False) + 'aiprojectcore_atomic_test.json';
  if FileExists(Tmp) then DeleteFile(Tmp);
  AISaveTextFileAtomic(Tmp, '{"v":1}', nil);
  AISaveTextFileAtomic(Tmp, '{"v":2}', nil);
  S := AIReadTextFile(Tmp);
  Check(S = '{"v":2}', 'gravacao atomica substitui');
  Check(not FileExists(Tmp + '.tmp') and not FileExists(Tmp + '.bak'), 'sem .tmp/.bak depois de gravar');
  DeleteFile(Tmp);
end;

begin
  Passed := 0; Failed := 0;
  TestDuration;
  TestUndo;
  TestJSON;
  if Failed = 0 then
    Writeln(Format('PASS: %d checks (duracao, desfazer, JSON, datas, gravacao atomica)', [Passed]))
  else
  begin
    Writeln(Format('FAIL: %d de %d checks', [Failed, Passed + Failed]));
    Halt(1);
  end;
end.
