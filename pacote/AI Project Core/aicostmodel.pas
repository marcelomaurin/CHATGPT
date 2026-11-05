unit aicostmodel;

{ Lazarus AI Suite - AI Project Core
  Custos de tarefa no estilo do Microsoft Project (generico, sem LCL).

  - Custo de trabalho: horas de trabalho x taxa por hora.
  - Custo por uso: valor fixo cada vez que o recurso e usado numa tarefa
    (preparacao da maquina, deslocamento). Vence no inicio.
  - Material: quantidade x custo unitario.
  - Recurso de custo: valor informado na atribuicao (frete, servico).
  - Custo fixo da tarefa com acumulacao no inicio, rateada ou no fim.

  Acumulacao (quanto do valor ja "venceu" numa data):
    start     tudo no inicio da tarefa
    prorated  proporcional ao andamento da tarefa no tempo (0..1)
    end       tudo no termino
  O andamento e informado pelo chamador (que conhece o calendario); ha
  tambem uma versao linear por datas.

  Dinheiro: Double, duas casas so na exibicao. Leitura de texto aceita
  "1234,5", "1234.5", "R$ 1.234,50" e "1,234.50": quando ha ponto e virgula,
  o ultimo e o separador decimal; com um so tipo de separador, ele e o decimal,
  exceto ponto seguido de exatamente tres digitos repetidos ("1.500" ou
  "12.345.678"), que e milhar. Nao depende da configuracao regional. }

{$mode objfpc}{$H+}

interface

uses
  SysUtils, Math;

type
  TAICostAccrual = (acaStart, acaProrated, acaEnd);

  { custo de uma tarefa, separado por origem }
  TAICostBreakdown = record
    Work: Double;        // horas x taxa
    PerUse: Double;      // custo por uso dos recursos
    Material: Double;    // quantidade x custo unitario
    Resource: Double;    // recursos do tipo custo
    Fixed: Double;       // custo fixo da tarefa
  end;

function AICostAccrualName(A: TAICostAccrual): string;
function AITryCostAccrualFromName(const S: string; out A: TAICostAccrual): Boolean;
function AICostAccrualCaption(A: TAICostAccrual): string;

function AIWorkCost(AWorkMinutes: Int64; ARatePerHour: Double): Double;
function AIMaterialCost(AQuantity, AUnitCost: Double): Double;

procedure AIClearCost(var C: TAICostBreakdown);
procedure AIAddCost(var Total: TAICostBreakdown; const C: TAICostBreakdown);
function AICostTotal(const C: TAICostBreakdown): Double;

{ fracao do valor vencida para um andamento no tempo de 0 a 1 }
function AIAccruedFraction(A: TAICostAccrual; ATimeFraction: Double): Double;
{ mesma coisa, andamento linear entre inicio e termino (marco: tudo na data) }
function AIAccruedFractionAt(A: TAICostAccrual; AStart, AFinish, AAsOf: TDateTime): Double;

{ custo vencido de uma tarefa: trabalho, material e recurso de custo rateados,
  por uso no inicio e custo fixo pela acumulacao da tarefa }
function AICostToDate(const C: TAICostBreakdown; AFixedAccrual: TAICostAccrual;
  ATimeFraction: Double): Double;

function AIFormatMoney(V: Double; const ASymbol: string = 'R$'): string;
function AITryParseMoney(const S: string; out V: Double): Boolean;

implementation

const
  ACCRUAL_NAMES: array[TAICostAccrual] of string = ('start', 'prorated', 'end');
  ACCRUAL_CAPTIONS: array[TAICostAccrual] of string = ('No inicio', 'Rateado', 'No fim');

function AICostAccrualName(A: TAICostAccrual): string;
begin
  Result := ACCRUAL_NAMES[A];
end;

function AITryCostAccrualFromName(const S: string; out A: TAICostAccrual): Boolean;
var I: TAICostAccrual;
begin
  for I := Low(I) to High(I) do
    if SameText(Trim(S), ACCRUAL_NAMES[I]) then begin A := I; Exit(True); end;
  A := acaProrated;
  Result := False;
end;

function AICostAccrualCaption(A: TAICostAccrual): string;
begin
  Result := ACCRUAL_CAPTIONS[A];
end;

function AIWorkCost(AWorkMinutes: Int64; ARatePerHour: Double): Double;
begin
  if (AWorkMinutes <= 0) or (ARatePerHour <= 0) then Exit(0);
  Result := AWorkMinutes / 60 * ARatePerHour;
end;

function AIMaterialCost(AQuantity, AUnitCost: Double): Double;
begin
  if (AQuantity <= 0) or (AUnitCost <= 0) then Exit(0);
  Result := AQuantity * AUnitCost;
end;

procedure AIClearCost(var C: TAICostBreakdown);
begin
  C.Work := 0; C.PerUse := 0; C.Material := 0; C.Resource := 0; C.Fixed := 0;
end;

procedure AIAddCost(var Total: TAICostBreakdown; const C: TAICostBreakdown);
begin
  Total.Work := Total.Work + C.Work;
  Total.PerUse := Total.PerUse + C.PerUse;
  Total.Material := Total.Material + C.Material;
  Total.Resource := Total.Resource + C.Resource;
  Total.Fixed := Total.Fixed + C.Fixed;
end;

function AICostTotal(const C: TAICostBreakdown): Double;
begin
  Result := C.Work + C.PerUse + C.Material + C.Resource + C.Fixed;
end;

function AIAccruedFraction(A: TAICostAccrual; ATimeFraction: Double): Double;
begin
  if IsNan(ATimeFraction) then ATimeFraction := 0;
  ATimeFraction := EnsureRange(ATimeFraction, 0, 1);
  case A of
    acaStart: if ATimeFraction > 0 then Result := 1 else Result := 0;
    acaEnd: if ATimeFraction >= 1 then Result := 1 else Result := 0;
  else
    Result := ATimeFraction;
  end;
end;

function AIAccruedFractionAt(A: TAICostAccrual; AStart, AFinish, AAsOf: TDateTime): Double;
var F: Double;
begin
  if AFinish <= AStart then
  begin
    { marco ou tarefa sem duracao: tudo na data }
    if AAsOf >= AStart then Exit(1) else Exit(0);
  end;
  if AAsOf < AStart then F := 0
  else if AAsOf >= AFinish then F := 1
  else F := (AAsOf - AStart) / (AFinish - AStart);
  { "no inicio" vence assim que a tarefa comeca }
  if (A = acaStart) and (AAsOf >= AStart) then Exit(1);
  Result := AIAccruedFraction(A, F);
end;

function AICostToDate(const C: TAICostBreakdown; AFixedAccrual: TAICostAccrual;
  ATimeFraction: Double): Double;
begin
  Result := (C.Work + C.Material + C.Resource) * AIAccruedFraction(acaProrated, ATimeFraction) +
    C.PerUse * AIAccruedFraction(acaStart, ATimeFraction) +
    C.Fixed * AIAccruedFraction(AFixedAccrual, ATimeFraction);
end;

function AIFormatMoney(V: Double; const ASymbol: string): string;
var
  Cents: Int64;
  IntPart, Frac, S: string;
  I, N: Integer;
  Neg: Boolean;
begin
  Cents := Round(V * 100);
  Neg := Cents < 0;
  Cents := Abs(Cents);
  IntPart := IntToStr(Cents div 100);
  Frac := Format('%.2d', [Cents mod 100]);
  S := '';
  N := 0;
  for I := Length(IntPart) downto 1 do
  begin
    if (N > 0) and (N mod 3 = 0) then S := '.' + S;
    S := IntPart[I] + S;
    Inc(N);
  end;
  Result := S + ',' + Frac;
  if Neg then Result := '-' + Result;
  if ASymbol <> '' then Result := ASymbol + ' ' + Result;
end;

{ ponto como milhar: grupos de exatamente 3 digitos depois de cada ponto }
function DotsAreThousands(const S: string): Boolean;
var I, Digits: Integer; Seen: Boolean;
begin
  Seen := False;
  Digits := -1;
  for I := 1 to Length(S) do
    if S[I] = '.' then
    begin
      if Seen and (Digits <> 3) then Exit(False);
      Seen := True;
      Digits := 0;
    end
    else if Seen then Inc(Digits);
  Result := Seen and (Digits = 3) and (S[1] <> '.');
end;

function AITryParseMoney(const S: string; out V: Double): Boolean;
var
  T, Clean: string;
  I, LastDot, LastComma: Integer;
  FS: TFormatSettings;
  DecSep: Char;
  Neg: Boolean;
begin
  V := 0;
  T := '';
  for I := 1 to Length(S) do
    if S[I] in ['0'..'9', '.', ',', '-'] then T := T + S[I]
    else if not (S[I] in [' ', #9, 'R', 'r', '$', #194, #160]) then Exit(False);
  if T = '' then Exit(False);
  Neg := T[1] = '-';
  if Neg then Delete(T, 1, 1);
  if (T = '') or (Pos('-', T) > 0) then Exit(False);
  LastDot := 0; LastComma := 0;
  for I := 1 to Length(T) do
    if T[I] = '.' then LastDot := I
    else if T[I] = ',' then LastComma := I;
  if (LastDot > 0) and (LastComma > 0) then
  begin
    if LastDot > LastComma then DecSep := '.' else DecSep := ',';
  end
  else if LastComma > 0 then
  begin
    { virgula sozinha: decimal, a menos que haja mais de uma (milhar ingles) }
    if Pos(',', T) <> LastComma then DecSep := '.' else DecSep := ',';
  end
  else if (LastDot > 0) and DotsAreThousands(T) then
    DecSep := ','                               // "1.500" = mil e quinhentos
  else
    DecSep := '.';
  Clean := '';
  for I := 1 to Length(T) do
    if T[I] = DecSep then Clean := Clean + '.'
    else if T[I] in ['0'..'9'] then Clean := Clean + T[I];
  if (Clean = '') or (Clean = '.') then Exit(False);
  FS := DefaultFormatSettings;
  FS.DecimalSeparator := '.';
  FS.ThousandSeparator := #0;
  Result := TryStrToFloat(Clean, V, FS);
  if Result and Neg then V := -V;
end;

end.
