unit aiworkcalendar;

{ Lazarus AI Suite - AI Project Core
  Calendario de trabalho para cronogramas (generico, sem LCL).

  - Expediente por dia da semana: lista de intervalos em minutos do dia
    (ex.: 08:00-12:00 e 13:00-17:00 = [480,720) e [780,1020)).
  - Excecoes por data (feriado, folga ou expediente diferente), com nome.
  - Feriados nacionais do Brasil: fixos e moveis pela Pascoa (Carnaval,
    Sexta-feira Santa, Corpus Christi), com opcao de incluir os pontos
    facultativos.
  - Aritmetica de minutos uteis: somar/subtrair, minutos entre duas datas,
    encaixar no expediente. Precisao de 1 minuto.
  - Convencao (igual ao Microsoft Project): uma tarefa que consome o
    expediente ate o fim termina no fim do intervalo (17:00), nao no inicio do
    proximo; e a sucessora comeca no proximo instante util (08:00 do dia
    seguinte).
  - JSON para gravar e ler o calendario no documento. }

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, DateUtils, fpjson;

type
  EAIWorkCalendar = class(Exception);

  TAIWorkInterval = record
    StartMin, EndMin: Integer;   // [StartMin, EndMin) em minutos do dia, 0..1440
  end;
  TAIWorkIntervals = array of TAIWorkInterval;

  TAICalendarException = record
    Day: Integer;                // Trunc(TDateTime)
    Name: string;
    Intervals: TAIWorkIntervals; // vazio = dia sem trabalho
  end;

  TAIWorkCalendar = class
  private
    FName: string;
    FWeek: array[1..7] of TAIWorkIntervals;   // DayOfWeek: 1 = domingo .. 7 = sabado
    FExceptions: array of TAICalendarException; // ordenado por Day
    function FindException(ADay: Integer; out Index: Integer): Boolean;
    function DayIntervals(ADay: Integer): TAIWorkIntervals;
    function HasAnyWorkingTime: Boolean;
  public
    constructor Create(const AName: string = 'padrao');
    procedure Assign(Source: TAIWorkCalendar);
    procedure Clear;
    { expediente }
    procedure SetWeekDay(ADayOfWeek: Integer; const AIntervals: array of Integer);
    function WeekDay(ADayOfWeek: Integer): TAIWorkIntervals;
    procedure SetStandard;    // seg-sex 08:00-12:00 e 13:00-17:00
    procedure Set24Hours;     // todos os dias, 24 h
    { excecoes }
    procedure AddException(ADate: TDateTime; const AName: string; const AIntervals: array of Integer);
    procedure AddHoliday(ADate: TDateTime; const AName: string);
    function RemoveException(ADate: TDateTime): Boolean;
    function ExceptionCount: Integer;
    function ExceptionAt(I: Integer): TAICalendarException;
    function ExceptionName(ADate: TDateTime): string;
    procedure AddBrazilianHolidays(AFromYear, AToYear: Integer; AIncludeOptional: Boolean = True);
    { consultas }
    function IsWorkingDay(ADate: TDateTime): Boolean;
    function WorkingMinutesOfDay(ADate: TDateTime): Integer;
    function IsWorkingTime(ADate: TDateTime): Boolean;
    { aritmetica }
    function SnapForward(ADate: TDateTime): TDateTime;
    function SnapBackward(ADate: TDateTime): TDateTime;
    function AddWorkingMinutes(ADate: TDateTime; AMinutes: Int64): TDateTime;
    function WorkingMinutesBetween(AFrom, ATo: TDateTime): Int64;
    { JSON }
    function ToJSON: TJSONObject;
    procedure FromJSON(O: TJSONObject);
    property Name: string read FName write FName;
  end;

function AIEasterSunday(AYear: Integer): TDateTime;
function AIMinuteToDateTime(AMinute: Int64): TDateTime;
function AIDateTimeToMinute(ADate: TDateTime): Int64;

implementation

const
  MAX_SEARCH_DAYS = 366 * 100;

function AIDateTimeToMinute(ADate: TDateTime): Int64;
begin
  Result := Round(ADate * 1440);
end;

function AIMinuteToDateTime(AMinute: Int64): TDateTime;
begin
  Result := AMinute / 1440;
end;

function AIEasterSunday(AYear: Integer): TDateTime;
var A, B, C, D, E, F, G, H, I, K, L, M, Month, Day: Integer;
begin
  { algoritmo de Meeus/Jones/Butcher (calendario gregoriano) }
  A := AYear mod 19;
  B := AYear div 100;
  C := AYear mod 100;
  D := B div 4;
  E := B mod 4;
  F := (B + 8) div 25;
  G := (B - F + 1) div 3;
  H := (19 * A + B - D - G + 15) mod 30;
  I := C div 4;
  K := C mod 4;
  L := (32 + 2 * E + 2 * I - H - K) mod 7;
  M := (A + 11 * H + 22 * L) div 451;
  Month := (H + L - 7 * M + 114) div 31;
  Day := ((H + L - 7 * M + 114) mod 31) + 1;
  Result := EncodeDate(AYear, Month, Day);
end;

function MakeIntervals(const A: array of Integer): TAIWorkIntervals;
var I: Integer;
begin
  Result := nil;
  if Odd(Length(A)) then
    raise EAIWorkCalendar.Create('intervalos devem vir em pares inicio/fim');
  SetLength(Result, Length(A) div 2);
  for I := 0 to High(Result) do
  begin
    Result[I].StartMin := A[2 * I];
    Result[I].EndMin := A[2 * I + 1];
    if (Result[I].StartMin < 0) or (Result[I].EndMin > 1440) or
       (Result[I].StartMin >= Result[I].EndMin) then
      raise EAIWorkCalendar.CreateFmt('intervalo invalido: %d-%d', [Result[I].StartMin, Result[I].EndMin]);
    if (I > 0) and (Result[I].StartMin < Result[I - 1].EndMin) then
      raise EAIWorkCalendar.Create('intervalos devem estar em ordem e sem sobreposicao');
  end;
end;

{ ---------------- TAIWorkCalendar ---------------- }

constructor TAIWorkCalendar.Create(const AName: string);
begin
  inherited Create;
  FName := AName;
  SetStandard;
end;

procedure TAIWorkCalendar.Assign(Source: TAIWorkCalendar);
var D, I: Integer;
begin
  FName := Source.FName;
  for D := 1 to 7 do FWeek[D] := Copy(Source.FWeek[D]);
  SetLength(FExceptions, Length(Source.FExceptions));
  for I := 0 to High(FExceptions) do
  begin
    FExceptions[I] := Source.FExceptions[I];
    FExceptions[I].Intervals := Copy(Source.FExceptions[I].Intervals);
  end;
end;

procedure TAIWorkCalendar.Clear;
var D: Integer;
begin
  for D := 1 to 7 do FWeek[D] := nil;
  FExceptions := nil;
end;

procedure TAIWorkCalendar.SetWeekDay(ADayOfWeek: Integer; const AIntervals: array of Integer);
begin
  if (ADayOfWeek < 1) or (ADayOfWeek > 7) then
    raise EAIWorkCalendar.CreateFmt('dia da semana invalido: %d (1 = domingo .. 7 = sabado)', [ADayOfWeek]);
  FWeek[ADayOfWeek] := MakeIntervals(AIntervals);
end;

function TAIWorkCalendar.WeekDay(ADayOfWeek: Integer): TAIWorkIntervals;
begin
  Result := Copy(FWeek[ADayOfWeek]);
end;

procedure TAIWorkCalendar.SetStandard;
var D: Integer;
begin
  Clear;
  for D := 2 to 6 do SetWeekDay(D, [480, 720, 780, 1020]);
end;

procedure TAIWorkCalendar.Set24Hours;
var D: Integer;
begin
  Clear;
  for D := 1 to 7 do SetWeekDay(D, [0, 1440]);
end;

function TAIWorkCalendar.FindException(ADay: Integer; out Index: Integer): Boolean;
var Lo, Hi, Mid: Integer;
begin
  Lo := 0; Hi := High(FExceptions);
  while Lo <= Hi do
  begin
    Mid := (Lo + Hi) div 2;
    if FExceptions[Mid].Day = ADay then begin Index := Mid; Exit(True); end;
    if FExceptions[Mid].Day < ADay then Lo := Mid + 1 else Hi := Mid - 1;
  end;
  Index := Lo;
  Result := False;
end;

procedure TAIWorkCalendar.AddException(ADate: TDateTime; const AName: string;
  const AIntervals: array of Integer);
var I, J, Day: Integer;
begin
  Day := Trunc(ADate);
  if FindException(Day, I) then
  begin
    { a ultima definicao vale; o nome acumula se for outro feriado no mesmo dia }
    if (AName <> '') and (Pos(AName, FExceptions[I].Name) = 0) then
      if FExceptions[I].Name = '' then FExceptions[I].Name := AName
      else FExceptions[I].Name := FExceptions[I].Name + ' / ' + AName;
    FExceptions[I].Intervals := MakeIntervals(AIntervals);
    Exit;
  end;
  SetLength(FExceptions, Length(FExceptions) + 1);
  for J := High(FExceptions) downto I + 1 do FExceptions[J] := FExceptions[J - 1];
  FExceptions[I].Day := Day;
  FExceptions[I].Name := AName;
  FExceptions[I].Intervals := MakeIntervals(AIntervals);
end;

procedure TAIWorkCalendar.AddHoliday(ADate: TDateTime; const AName: string);
begin
  AddException(ADate, AName, []);
end;

function TAIWorkCalendar.RemoveException(ADate: TDateTime): Boolean;
var I, J: Integer;
begin
  Result := FindException(Trunc(ADate), I);
  if not Result then Exit;
  for J := I to High(FExceptions) - 1 do FExceptions[J] := FExceptions[J + 1];
  SetLength(FExceptions, Length(FExceptions) - 1);
end;

function TAIWorkCalendar.ExceptionCount: Integer;
begin
  Result := Length(FExceptions);
end;

function TAIWorkCalendar.ExceptionAt(I: Integer): TAICalendarException;
begin
  Result := FExceptions[I];
end;

function TAIWorkCalendar.ExceptionName(ADate: TDateTime): string;
var I: Integer;
begin
  if FindException(Trunc(ADate), I) then Result := FExceptions[I].Name else Result := '';
end;

procedure TAIWorkCalendar.AddBrazilianHolidays(AFromYear, AToYear: Integer; AIncludeOptional: Boolean);
var Y: Integer; E: TDateTime;
begin
  for Y := AFromYear to AToYear do
  begin
    AddHoliday(EncodeDate(Y, 1, 1), 'Confraternizacao Universal');
    AddHoliday(EncodeDate(Y, 4, 21), 'Tiradentes');
    AddHoliday(EncodeDate(Y, 5, 1), 'Dia do Trabalho');
    AddHoliday(EncodeDate(Y, 9, 7), 'Independencia do Brasil');
    AddHoliday(EncodeDate(Y, 10, 12), 'Nossa Senhora Aparecida');
    AddHoliday(EncodeDate(Y, 11, 2), 'Finados');
    AddHoliday(EncodeDate(Y, 11, 15), 'Proclamacao da Republica');
    { feriado nacional desde a Lei 14.759/2023 }
    if Y >= 2024 then AddHoliday(EncodeDate(Y, 11, 20), 'Dia Nacional de Zumbi e da Consciencia Negra');
    AddHoliday(EncodeDate(Y, 12, 25), 'Natal');
    E := AIEasterSunday(Y);
    AddHoliday(E - 2, 'Sexta-feira Santa');
    if AIncludeOptional then
    begin
      { pontos facultativos nacionais, normalmente sem expediente }
      AddHoliday(E - 48, 'Carnaval (segunda-feira)');
      AddHoliday(E - 47, 'Carnaval (terca-feira)');
      AddHoliday(E + 60, 'Corpus Christi');
    end;
  end;
end;

function TAIWorkCalendar.DayIntervals(ADay: Integer): TAIWorkIntervals;
var I: Integer;
begin
  if FindException(ADay, I) then Exit(FExceptions[I].Intervals);
  Result := FWeek[DayOfWeek(ADay)];
end;

function TAIWorkCalendar.HasAnyWorkingTime: Boolean;
var D: Integer;
begin
  for D := 1 to 7 do
    if Length(FWeek[D]) > 0 then Exit(True);
  Result := False;
end;

function TAIWorkCalendar.IsWorkingDay(ADate: TDateTime): Boolean;
begin
  Result := Length(DayIntervals(Trunc(ADate))) > 0;
end;

function TAIWorkCalendar.WorkingMinutesOfDay(ADate: TDateTime): Integer;
var Iv: TAIWorkInterval;
begin
  Result := 0;
  for Iv in DayIntervals(Trunc(ADate)) do Inc(Result, Iv.EndMin - Iv.StartMin);
end;

procedure SplitMinute(T: TDateTime; out Day: Integer; out M: Integer);
var A: Int64;
begin
  A := AIDateTimeToMinute(T);
  Day := A div 1440;
  M := A mod 1440;
  if M < 0 then begin Inc(M, 1440); Dec(Day); end;
end;

function JoinMinute(Day: Integer; M: Integer): TDateTime;
begin
  Result := AIMinuteToDateTime(Int64(Day) * 1440 + M);
end;

function TAIWorkCalendar.IsWorkingTime(ADate: TDateTime): Boolean;
var Day, M: Integer; Iv: TAIWorkInterval;
begin
  SplitMinute(ADate, Day, M);
  for Iv in DayIntervals(Day) do
    if (M >= Iv.StartMin) and (M < Iv.EndMin) then Exit(True);
  Result := False;
end;

function TAIWorkCalendar.SnapForward(ADate: TDateTime): TDateTime;
var Day, M, N: Integer; Iv: TAIWorkInterval;
begin
  { dentro de um intervalo: fica; senao vai para o inicio do proximo }
  if not HasAnyWorkingTime then raise EAIWorkCalendar.Create('calendario "' + FName + '" sem expediente');
  SplitMinute(ADate, Day, M);
  for N := 0 to MAX_SEARCH_DAYS do
  begin
    for Iv in DayIntervals(Day) do
      if M < Iv.EndMin then
      begin
        if M < Iv.StartMin then M := Iv.StartMin;
        Exit(JoinMinute(Day, M));
      end;
    Inc(Day);
    M := 0;
  end;
  raise EAIWorkCalendar.Create('calendario "' + FName + '" sem expediente no periodo');
end;

function TAIWorkCalendar.SnapBackward(ADate: TDateTime): TDateTime;
var Day, M, N, K: Integer; Ivs: TAIWorkIntervals;
begin
  { no fim de um intervalo ou dentro dele: fica; senao vai para o fim do anterior }
  if not HasAnyWorkingTime then raise EAIWorkCalendar.Create('calendario "' + FName + '" sem expediente');
  SplitMinute(ADate, Day, M);
  if M = 0 then begin Dec(Day); M := 1440; end;
  for N := 0 to MAX_SEARCH_DAYS do
  begin
    Ivs := DayIntervals(Day);
    for K := High(Ivs) downto 0 do
      if M > Ivs[K].StartMin then
      begin
        if M > Ivs[K].EndMin then M := Ivs[K].EndMin;
        Exit(JoinMinute(Day, M));
      end;
    Dec(Day);
    M := 1440;
  end;
  raise EAIWorkCalendar.Create('calendario "' + FName + '" sem expediente no periodo');
end;

function TAIWorkCalendar.AddWorkingMinutes(ADate: TDateTime; AMinutes: Int64): TDateTime;
var
  Day, M, N, K, S, Avail: Integer;
  Left: Int64;
  Ivs: TAIWorkIntervals;
  Iv: TAIWorkInterval;
begin
  if AMinutes = 0 then Exit(ADate);
  if not HasAnyWorkingTime then raise EAIWorkCalendar.Create('calendario "' + FName + '" sem expediente');
  SplitMinute(ADate, Day, M);
  Left := Abs(AMinutes);
  if AMinutes > 0 then
  begin
    { para frente: termina no fim do intervalo quando consome tudo nele }
    for N := 0 to MAX_SEARCH_DAYS do
    begin
      for Iv in DayIntervals(Day) do
      begin
        if M >= Iv.EndMin then Continue;
        if M < Iv.StartMin then S := Iv.StartMin else S := M;
        Avail := Iv.EndMin - S;
        if Left <= Avail then Exit(JoinMinute(Day, S + Left));
        Dec(Left, Avail);
        M := Iv.EndMin;
      end;
      Inc(Day);
      M := 0;
    end;
  end
  else
  begin
    { para tras: termina no inicio do intervalo quando consome tudo nele }
    if M = 0 then begin Dec(Day); M := 1440; end;
    for N := 0 to MAX_SEARCH_DAYS do
    begin
      Ivs := DayIntervals(Day);
      for K := High(Ivs) downto 0 do
      begin
        if M <= Ivs[K].StartMin then Continue;
        if M > Ivs[K].EndMin then S := Ivs[K].EndMin else S := M;
        Avail := S - Ivs[K].StartMin;
        if Left <= Avail then Exit(JoinMinute(Day, S - Left));
        Dec(Left, Avail);
        M := Ivs[K].StartMin;
      end;
      Dec(Day);
      M := 1440;
    end;
  end;
  raise EAIWorkCalendar.Create('calendario "' + FName + '" sem expediente suficiente no periodo');
end;

function TAIWorkCalendar.WorkingMinutesBetween(AFrom, ATo: TDateTime): Int64;
var
  D1, M1, D2, M2, Day, A, B: Integer;
  Iv: TAIWorkInterval;
begin
  SplitMinute(AFrom, D1, M1);
  SplitMinute(ATo, D2, M2);
  if (Int64(D2) * 1440 + M2) < (Int64(D1) * 1440 + M1) then
    Exit(-WorkingMinutesBetween(ATo, AFrom));
  Result := 0;
  for Day := D1 to D2 do
    for Iv in DayIntervals(Day) do
    begin
      A := Iv.StartMin; B := Iv.EndMin;
      if (Day = D1) and (A < M1) then A := M1;
      if (Day = D2) and (B > M2) then B := M2;
      if B > A then Inc(Result, B - A);
    end;
end;

{ ---------------- JSON ---------------- }

function IntervalsToJSON(const Ivs: TAIWorkIntervals): TJSONArray;
var Iv: TAIWorkInterval;
begin
  Result := TJSONArray.Create;
  for Iv in Ivs do Result.Add(TJSONArray.Create([Iv.StartMin, Iv.EndMin]));
end;

function IntervalsFromJSON(A: TJSONArray; const Where: string): TAIWorkIntervals;
var Flat: array of Integer; I: Integer; P: TJSONData;
begin
  Flat := nil;
  if A = nil then Exit(nil);
  SetLength(Flat, A.Count * 2);
  for I := 0 to A.Count - 1 do
  begin
    P := A.Items[I];
    if (P.JSONType <> jtArray) or (TJSONArray(P).Count <> 2) or
       (TJSONArray(P).Items[0].JSONType <> jtNumber) or (TJSONArray(P).Items[1].JSONType <> jtNumber) then
      raise EAIWorkCalendar.CreateFmt('%s: intervalo %d deve ser [inicio, fim] em minutos', [Where, I + 1]);
    Flat[2 * I] := TJSONArray(P).Integers[0];
    Flat[2 * I + 1] := TJSONArray(P).Integers[1];
  end;
  Result := MakeIntervals(Flat);
end;

function TAIWorkCalendar.ToJSON: TJSONObject;
var W, E: TJSONArray; D, I: Integer; X: TJSONObject;
begin
  Result := TJSONObject.Create;
  Result.Add('name', FName);
  W := TJSONArray.Create;
  for D := 1 to 7 do W.Add(IntervalsToJSON(FWeek[D]));
  Result.Add('week', W);
  E := TJSONArray.Create;
  for I := 0 to High(FExceptions) do
  begin
    X := TJSONObject.Create;
    X.Add('date', FormatDateTime('yyyy"-"mm"-"dd', FExceptions[I].Day));
    X.Add('name', FExceptions[I].Name);
    X.Add('intervals', IntervalsToJSON(FExceptions[I].Intervals));
    E.Add(X);
  end;
  Result.Add('exceptions', E);
end;

procedure TAIWorkCalendar.FromJSON(O: TJSONObject);
var
  W, E, Ivs: TJSONArray;
  D, I: Integer;
  X: TJSONObject;
  S: string;
  Dt: TDateTime;
  NewWeek: array[1..7] of TAIWorkIntervals;
  NewName: string;
  { D e reaproveitado como indice da excecao depois do laco da semana }
  Tmp: TAIWorkCalendar;
  Data: TJSONData;
begin
  { le tudo num calendario temporario: erro no meio nao estraga este }
  Tmp := TAIWorkCalendar.Create;
  try
    Tmp.Clear;
    Data := O.Find('name');
    if (Data <> nil) and (Data.JSONType = jtString) then NewName := Data.AsString else NewName := FName;
    Data := O.Find('week');
    if (Data = nil) or (Data.JSONType <> jtArray) or (TJSONArray(Data).Count <> 7) then
      raise EAIWorkCalendar.Create('calendario: "week" deve ter 7 dias (domingo primeiro)');
    W := TJSONArray(Data);
    for D := 1 to 7 do
    begin
      if W.Items[D - 1].JSONType <> jtArray then
        raise EAIWorkCalendar.CreateFmt('calendario: dia %d da semana invalido', [D]);
      NewWeek[D] := IntervalsFromJSON(TJSONArray(W.Items[D - 1]), Format('dia %d', [D]));
    end;
    for D := 1 to 7 do Tmp.FWeek[D] := NewWeek[D];
    Data := O.Find('exceptions');
    if (Data <> nil) and (Data.JSONType = jtArray) then
    begin
      E := TJSONArray(Data);
      for I := 0 to E.Count - 1 do
      begin
        if E.Items[I].JSONType <> jtObject then
          raise EAIWorkCalendar.CreateFmt('calendario: excecao %d invalida', [I + 1]);
        X := TJSONObject(E.Items[I]);
        S := X.Get('date', '');
        if not TryEncodeDate(StrToIntDef(Copy(S, 1, 4), 0), StrToIntDef(Copy(S, 6, 2), 0),
          StrToIntDef(Copy(S, 9, 2), 0), Dt) or (Length(S) <> 10) then
          raise EAIWorkCalendar.CreateFmt('calendario: data invalida na excecao %d: "%s"', [I + 1, S]);
        Data := X.Find('intervals');
        if (Data <> nil) and (Data.JSONType = jtArray) then Ivs := TJSONArray(Data) else Ivs := nil;
        Tmp.AddException(Dt, X.Get('name', ''), []);
        Tmp.FindException(Trunc(Dt), D);
        Tmp.FExceptions[D].Intervals := IntervalsFromJSON(Ivs, 'excecao ' + S);
      end;
    end;
    Tmp.FName := NewName;
    Assign(Tmp);
  finally
    Tmp.Free;
  end;
end;

end.
