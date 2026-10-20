unit aiprojectduration;

{ Lazarus AI Suite - AI Project Core
  Duracao de tarefas no estilo do Microsoft Project (generico, sem LCL).

  Internamente: minutos inteiros (Int64). A unidade digitada fica guardada so
  para exibir de volta como o usuario escreveu.

  Sintaxe aceita (sem diferenciar maiusculas; espacos ignorados):
    30min  4h  2d  1sem          duracao util (dia e semana pelo calendario)
    30emin 14eh 2ed 1esem        duracao decorrida (dia = 24 h, semana = 7 d)
    sufixo '?'                   estimada ("4h?")
    "1,5d" ou "1.5d"             ponto ou virgula decimal, sem depender da
                                 configuracao regional
    "3"                          sem unidade = dias
  Sinonimos: m/min/minuto(s), h/hr/hora(s), d/dia(s)/day(s),
             w/wk/sem/semana(s)/week(s). }

{$mode objfpc}{$H+}

interface

uses
  SysUtils, Math;

type
  TAIDurationUnit = (aduMinute, aduHour, aduDay, aduWeek);

  TAIDuration = record
    Minutes: Int64;
    DisplayUnit: TAIDurationUnit;
    Elapsed: Boolean;
    Estimated: Boolean;
  end;

const
  AI_DEFAULT_MINUTES_PER_DAY = 480;    // 8 h
  AI_DEFAULT_MINUTES_PER_WEEK = 2400;  // 40 h

function AIMakeDuration(AMinutes: Int64; AUnit: TAIDurationUnit = aduDay;
  AElapsed: Boolean = False; AEstimated: Boolean = False): TAIDuration;
function AITryParseDuration(const S: string; MinutesPerDay, MinutesPerWeek: Integer;
  out D: TAIDuration; out Err: string): Boolean;
function AIFormatDuration(const D: TAIDuration; MinutesPerDay, MinutesPerWeek: Integer): string;
function AIDurationUnitMinutes(U: TAIDurationUnit; Elapsed: Boolean;
  MinutesPerDay, MinutesPerWeek: Integer): Int64;
function AIDurationUnitName(U: TAIDurationUnit): string;
function AITryDurationUnitFromName(const S: string; out U: TAIDurationUnit): Boolean;
function AISameDuration(const A, B: TAIDuration): Boolean;

implementation

const
  UNIT_NAMES: array[TAIDurationUnit] of string = ('min', 'h', 'd', 'sem');

var
  DotFS: TFormatSettings;

function AIDurationUnitName(U: TAIDurationUnit): string;
begin
  Result := UNIT_NAMES[U];
end;

function AITryDurationUnitFromName(const S: string; out U: TAIDurationUnit): Boolean;
var I: TAIDurationUnit;
begin
  for I := Low(I) to High(I) do
    if SameText(S, UNIT_NAMES[I]) then begin U := I; Exit(True); end;
  U := aduDay;
  Result := False;
end;

function AIMakeDuration(AMinutes: Int64; AUnit: TAIDurationUnit; AElapsed,
  AEstimated: Boolean): TAIDuration;
begin
  Result.Minutes := AMinutes;
  Result.DisplayUnit := AUnit;
  Result.Elapsed := AElapsed;
  Result.Estimated := AEstimated;
end;

function AISameDuration(const A, B: TAIDuration): Boolean;
begin
  Result := (A.Minutes = B.Minutes) and (A.DisplayUnit = B.DisplayUnit) and
    (A.Elapsed = B.Elapsed) and (A.Estimated = B.Estimated);
end;

function AIDurationUnitMinutes(U: TAIDurationUnit; Elapsed: Boolean;
  MinutesPerDay, MinutesPerWeek: Integer): Int64;
begin
  case U of
    aduMinute: Result := 1;
    aduHour: Result := 60;
    aduDay: if Elapsed then Result := 24 * 60 else Result := MinutesPerDay;
    aduWeek: if Elapsed then Result := 7 * 24 * 60 else Result := MinutesPerWeek;
  else
    Result := 1;
  end;
end;

function TryUnitWord(const W: string; out U: TAIDurationUnit): Boolean;
begin
  Result := True;
  if (W = 'm') or (W = 'min') or (W = 'mins') or (W = 'minuto') or (W = 'minutos') or
     (W = 'minute') or (W = 'minutes') then U := aduMinute
  else if (W = 'h') or (W = 'hr') or (W = 'hrs') or (W = 'hora') or (W = 'horas') or
     (W = 'hour') or (W = 'hours') then U := aduHour
  else if (W = '') or (W = 'd') or (W = 'dia') or (W = 'dias') or (W = 'day') or
     (W = 'days') then U := aduDay
  else if (W = 'w') or (W = 'wk') or (W = 'sem') or (W = 'semana') or (W = 'semanas') or
     (W = 'week') or (W = 'weeks') then U := aduWeek
  else Result := False;
end;

function AITryParseDuration(const S: string; MinutesPerDay, MinutesPerWeek: Integer;
  out D: TAIDuration; out Err: string): Boolean;
var
  T, NumPart, Word: string;
  I: Integer;
  V: Double;
  U: TAIDurationUnit;
  Elapsed, Estimated: Boolean;
begin
  Result := False;
  Err := '';
  D := AIMakeDuration(0);
  if (MinutesPerDay <= 0) or (MinutesPerWeek <= 0) then
  begin
    Err := 'calendario sem horas de trabalho';
    Exit;
  end;
  T := LowerCase(StringReplace(Trim(S), ' ', '', [rfReplaceAll]));
  Estimated := (T <> '') and (T[Length(T)] = '?');
  if Estimated then Delete(T, Length(T), 1);
  if T = '' then
  begin
    Err := 'duracao vazia';
    Exit;
  end;
  I := 1;
  while (I <= Length(T)) and (T[I] in ['0'..'9', '.', ',']) do Inc(I);
  NumPart := StringReplace(Copy(T, 1, I - 1), ',', '.', [rfReplaceAll]);
  Word := Copy(T, I, MaxInt);
  if NumPart = '' then
  begin
    Err := 'duracao sem numero: "' + S + '"';
    Exit;
  end;
  if not TryStrToFloat(NumPart, V, DotFS) then
  begin
    Err := 'numero invalido na duracao: "' + S + '"';
    Exit;
  end;
  Elapsed := False;
  if not TryUnitWord(Word, U) then
  begin
    { prefixo "e" = decorrida (eh, ed, emin, esem, ew) }
    if (Length(Word) > 1) and (Word[1] = 'e') and TryUnitWord(Copy(Word, 2, MaxInt), U) then
      Elapsed := True
    else
    begin
      Err := 'unidade desconhecida na duracao: "' + S +
        '" (use min, h, d ou sem; prefixo e = decorrida)';
      Exit;
    end;
  end;
  if (V < 0) or (V > 1e7) then
  begin
    Err := 'duracao fora da faixa: "' + S + '"';
    Exit;
  end;
  D.Minutes := Round(V * AIDurationUnitMinutes(U, Elapsed, MinutesPerDay, MinutesPerWeek));
  D.DisplayUnit := U;
  D.Elapsed := Elapsed;
  D.Estimated := Estimated;
  Result := True;
end;

function AIFormatDuration(const D: TAIDuration; MinutesPerDay, MinutesPerWeek: Integer): string;
var
  Per: Int64;
begin
  if (MinutesPerDay <= 0) or (MinutesPerWeek <= 0) then
  begin
    MinutesPerDay := AI_DEFAULT_MINUTES_PER_DAY;
    MinutesPerWeek := AI_DEFAULT_MINUTES_PER_WEEK;
  end;
  Per := AIDurationUnitMinutes(D.DisplayUnit, D.Elapsed, MinutesPerDay, MinutesPerWeek);
  { ate 2 casas, sem zeros a direita: 1.5d, 2d, 0.25h }
  Result := FormatFloat('0.##', RoundTo(D.Minutes / Per, -2), DotFS);
  if D.Elapsed then Result := Result + 'e';
  Result := Result + UNIT_NAMES[D.DisplayUnit];
  if D.Estimated then Result := Result + '?';
end;

initialization
  DotFS := DefaultFormatSettings;
  DotFS.DecimalSeparator := '.';
  DotFS.ThousandSeparator := #0;

end.
