unit aicpmscheduler;

{ Lazarus AI Suite - AI Project Core
  Cronograma pelo metodo do caminho critico (CPM), no estilo do Microsoft
  Project (generico, sem LCL).

  Entrada: tarefas (duracao em minutos, calendario, restricao, data limite,
  modo manual, resumo/pai) + TAITaskGraph com os vinculos (o no I e a tarefa I)
  + calendarios TAIWorkCalendar.

  Calculo:
  1. Ida, na ordem topologica: inicio mais cedo = maior exigencia entre as
     predecessoras (TI: termino + latencia; II: inicio + latencia; TT/IT
     convertem a exigencia sobre o termino em exigencia sobre o inicio) e as
     restricoes (SNET, FNET empurram; MSO, MFO fixam com aviso de conflito).
     Inicio encaixado no expediente; termino = inicio + duracao util (termina
     no fim do intervalo, 17:00). Duracao decorrida usa 24 h e nao encaixa.
  2. Termino do projeto = maior termino.
  3. Volta, na ordem inversa: termino mais tarde = menor exigencia das
     sucessoras, das restricoes SNLT/FNLT e da data limite.
  4. Margem total = minutos uteis entre inicio cedo e inicio tarde (negativa
     quando uma data limite ou restricao nao e atendida); margem livre = quanto
     a tarefa atrasa sem atrasar nenhuma sucessora. Critica = margem total <=
     limiar.
  5. ALAP: a tarefa vai para o fim da margem livre (nao atrasa sucessoras).
  6. Resumos consolidam as filhas (menor inicio, maior termino, menor margem).
  7. LevelStart (nivelamento de recursos, ver airesourceload) e um "nao iniciar
     antes de" extra, que so atrasa a tarefa.

  Latencia: em minutos uteis do calendario do projeto, decorrida (24 h) ou em
  % da duracao da predecessora. Cada aviso diz a tarefa e o problema. }

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Math, aitaskgraph, aiworkcalendar;

type
  EAICPMScheduler = class(Exception);

  TAIConstraintType = (actASAP, actALAP, actSNET, actSNLT, actFNET, actFNLT, actMSO, actMFO);

  TAICPMTask = record
    Id: string;
    Duration: Int64;            // minutos uteis (ou corridos, se Elapsed)
    Elapsed: Boolean;
    Calendar: Integer;          // indice de AddCalendar; -1 = calendario do projeto
    Constraint: TAIConstraintType;
    ConstraintDate: TDateTime;
    Deadline: TDateTime;        // 0 = sem data limite
    Manual: Boolean;
    ManualStart, ManualFinish: TDateTime;   // termino 0 = inicio + duracao
    Parent: Integer;            // -1 = sem resumo pai
    IsSummary: Boolean;
    LevelStart: TDateTime;      // 0 = sem atraso de nivelamento (inicio nao antes de)
  end;

  TAICPMResult = record
    EarlyStart, EarlyFinish, LateStart, LateFinish: TDateTime;
    Start, Finish: TDateTime;
    TotalSlack, FreeSlack: Int64;
    Critical: Boolean;
  end;

  TAICPMWarningKind = (cwkConstraintConflict, cwkManualConflict, cwkDeadlineMissed,
    cwkLateConstraintMissed, cwkNegativeSlack);

  TAICPMWarning = record
    Task: Integer;
    Kind: TAICPMWarningKind;
    Message: string;
  end;

  TAICPMScheduler = class
  private
    FTasks: array of TAICPMTask;
    FResults: array of TAICPMResult;
    FWarnings: array of TAICPMWarning;
    FCalendars: array of TAIWorkCalendar;
    FProjectCalendar: TAIWorkCalendar;
    FElapsedCalendar: TAIWorkCalendar;
    FGraph: TAITaskGraph;
    FProjectStart, FProjectFinish: TDateTime;
    FCriticalSlack: Int64;
    function Cal(I: Integer): TAIWorkCalendar;
    function AddDur(I: Integer; T: TDateTime; M: Int64): TDateTime;
    function Between(I: Integer; A, B: TDateTime): Int64;
    function Shift(T: TDateTime; const L: TAITaskLink; Sign: Integer): TDateTime;
    procedure Warn(I: Integer; K: TAICPMWarningKind; const Msg: string);
    function Fmt(T: TDateTime): string;
    procedure Forward_(const Order: TAIIntArray);
    procedure Backward(const Order: TAIIntArray);
    procedure Slack;
    procedure Rollup;
    function GetResult(I: Integer): TAICPMResult;
    function GetTask(I: Integer): TAICPMTask;
    function GetWarning(I: Integer): TAICPMWarning;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Clear;
    function AddCalendar(C: TAIWorkCalendar): Integer;   // nao assume a posse
    function AddTask(const T: TAICPMTask): Integer;
    procedure SetLevelStart(I: Integer; T: TDateTime);
    procedure ClearLeveling;
    procedure Run;
    function TaskCount: Integer;
    function WarningCount: Integer;
    property ProjectStart: TDateTime read FProjectStart write FProjectStart;
    property ProjectFinish: TDateTime read FProjectFinish;
    property ProjectCalendar: TAIWorkCalendar read FProjectCalendar write FProjectCalendar;
    property Graph: TAITaskGraph read FGraph write FGraph;
    property CriticalSlack: Int64 read FCriticalSlack write FCriticalSlack;
    property Tasks[I: Integer]: TAICPMTask read GetTask;
    property Results[I: Integer]: TAICPMResult read GetResult;
    property Warnings[I: Integer]: TAICPMWarning read GetWarning;
  end;

function AINewCPMTask(const AId: string; ADuration: Int64): TAICPMTask;
function AIConstraintCode(C: TAIConstraintType): string;
function AITryConstraintFromCode(const S: string; out C: TAIConstraintType): Boolean;

implementation

const
  CONSTRAINT_CODES: array[TAIConstraintType] of string = ('ASAP', 'ALAP', 'SNET',
    'SNLT', 'FNET', 'FNLT', 'MSO', 'MFO');

function AIConstraintCode(C: TAIConstraintType): string;
begin
  Result := CONSTRAINT_CODES[C];
end;

function AITryConstraintFromCode(const S: string; out C: TAIConstraintType): Boolean;
var I: TAIConstraintType;
begin
  for I := Low(I) to High(I) do
    if SameText(Trim(S), CONSTRAINT_CODES[I]) then begin C := I; Exit(True); end;
  C := actASAP;
  Result := False;
end;

function AINewCPMTask(const AId: string; ADuration: Int64): TAICPMTask;
begin
  Result.Id := AId;
  Result.Duration := ADuration;
  Result.Elapsed := False;
  Result.Calendar := -1;
  Result.Constraint := actASAP;
  Result.ConstraintDate := 0;
  Result.Deadline := 0;
  Result.Manual := False;
  Result.ManualStart := 0;
  Result.ManualFinish := 0;
  Result.Parent := -1;
  Result.IsSummary := False;
  Result.LevelStart := 0;
end;

{ ---------------- TAICPMScheduler ---------------- }

constructor TAICPMScheduler.Create;
begin
  inherited Create;
  FElapsedCalendar := TAIWorkCalendar.Create('24h');
  FElapsedCalendar.Set24Hours;
end;

destructor TAICPMScheduler.Destroy;
begin
  FElapsedCalendar.Free;
  inherited Destroy;
end;

procedure TAICPMScheduler.Clear;
begin
  FTasks := nil;
  FResults := nil;
  FWarnings := nil;
  FCalendars := nil;
end;

function TAICPMScheduler.AddCalendar(C: TAIWorkCalendar): Integer;
begin
  Result := Length(FCalendars);
  SetLength(FCalendars, Result + 1);
  FCalendars[Result] := C;
end;

function TAICPMScheduler.AddTask(const T: TAICPMTask): Integer;
begin
  Result := Length(FTasks);
  SetLength(FTasks, Result + 1);
  FTasks[Result] := T;
end;

procedure TAICPMScheduler.SetLevelStart(I: Integer; T: TDateTime);
begin
  FTasks[I].LevelStart := T;
end;

procedure TAICPMScheduler.ClearLeveling;
var I: Integer;
begin
  for I := 0 to High(FTasks) do FTasks[I].LevelStart := 0;
end;

function TAICPMScheduler.TaskCount: Integer;
begin
  Result := Length(FTasks);
end;

function TAICPMScheduler.WarningCount: Integer;
begin
  Result := Length(FWarnings);
end;

function TAICPMScheduler.GetResult(I: Integer): TAICPMResult;
begin
  Result := FResults[I];
end;

function TAICPMScheduler.GetTask(I: Integer): TAICPMTask;
begin
  Result := FTasks[I];
end;

function TAICPMScheduler.GetWarning(I: Integer): TAICPMWarning;
begin
  Result := FWarnings[I];
end;

function TAICPMScheduler.Cal(I: Integer): TAIWorkCalendar;
begin
  if FTasks[I].Elapsed then Exit(FElapsedCalendar);
  if (FTasks[I].Calendar >= 0) and (FTasks[I].Calendar <= High(FCalendars)) then
    Result := FCalendars[FTasks[I].Calendar]
  else
    Result := FProjectCalendar;
end;

function TAICPMScheduler.AddDur(I: Integer; T: TDateTime; M: Int64): TDateTime;
begin
  Result := Cal(I).AddWorkingMinutes(T, M);
end;

function TAICPMScheduler.Between(I: Integer; A, B: TDateTime): Int64;
begin
  Result := Cal(I).WorkingMinutesBetween(A, B);
end;

function TAICPMScheduler.Shift(T: TDateTime; const L: TAITaskLink; Sign: Integer): TDateTime;
var M: Int64;
begin
  M := AILagMinutes(L.Lag, FTasks[L.FromNode].Duration) * Sign;
  if M = 0 then Exit(T);
  if L.Lag.Elapsed then Result := T + M / 1440
  else Result := FProjectCalendar.AddWorkingMinutes(T, M);
end;

procedure TAICPMScheduler.Warn(I: Integer; K: TAICPMWarningKind; const Msg: string);
begin
  SetLength(FWarnings, Length(FWarnings) + 1);
  FWarnings[High(FWarnings)].Task := I;
  FWarnings[High(FWarnings)].Kind := K;
  FWarnings[High(FWarnings)].Message := Msg;
end;

function TAICPMScheduler.Fmt(T: TDateTime): string;
begin
  Result := FormatDateTime('dd"/"mm"/"yyyy hh":"nn', T);
end;

procedure TAICPMScheduler.Forward_(const Order: TAIIntArray);
var
  I, L: Integer;
  T: TAICPMTask;
  ES, Need, C: TDateTime;
  Lk: TAITaskLink;
  HasLinks: Boolean;
begin
  for I in Order do
  begin
    T := FTasks[I];
    if T.IsSummary then Continue;
    { exigencia dos vinculos sobre o inicio }
    Need := FProjectStart;
    HasLinks := False;
    for L in FGraph.Predecessors(I) do
    begin
      Lk := FGraph.Links[L];
      HasLinks := True;
      case Lk.LinkType of
        atlFS: C := Shift(FResults[Lk.FromNode].EarlyFinish, Lk, 1);
        atlSS: C := Shift(FResults[Lk.FromNode].EarlyStart, Lk, 1);
        atlFF: C := AddDur(I, Shift(FResults[Lk.FromNode].EarlyFinish, Lk, 1), -T.Duration);
        atlSF: C := AddDur(I, Shift(FResults[Lk.FromNode].EarlyStart, Lk, 1), -T.Duration);
      end;
      if C > Need then Need := C;
    end;
    ES := Need;
    if T.Manual then
    begin
      if HasLinks and (Need > T.ManualStart + 0.5 / 1440) then
        Warn(I, cwkManualConflict, Format('%s (manual) comeca em %s, mas os vinculos pedem %s',
          [T.Id, Fmt(T.ManualStart), Fmt(Need)]));
      ES := T.ManualStart;
      FResults[I].EarlyStart := ES;
      if T.ManualFinish > 0 then FResults[I].EarlyFinish := T.ManualFinish
      else FResults[I].EarlyFinish := AddDur(I, ES, T.Duration);
      Continue;
    end;
    case T.Constraint of
      actSNET: if T.ConstraintDate > ES then ES := T.ConstraintDate;
      actFNET:
        begin
          C := AddDur(I, Cal(I).SnapBackward(T.ConstraintDate), -T.Duration);
          if C > ES then ES := C;
        end;
      actMSO:
        begin
          if HasLinks and (Need > T.ConstraintDate + 0.5 / 1440) then
            Warn(I, cwkConstraintConflict, Format('%s deve iniciar em %s, mas os vinculos pedem %s',
              [T.Id, Fmt(T.ConstraintDate), Fmt(Need)]));
          ES := T.ConstraintDate;
        end;
      actMFO:
        begin
          C := AddDur(I, Cal(I).SnapBackward(T.ConstraintDate), -T.Duration);
          if HasLinks and (Need > C + 0.5 / 1440) then
            Warn(I, cwkConstraintConflict, Format('%s deve terminar em %s, mas os vinculos pedem inicio em %s',
              [T.Id, Fmt(T.ConstraintDate), Fmt(Need)]));
          ES := C;
        end;
    end;
    { atraso de nivelamento: so empurra (MSO/MFO ficam onde estao) }
    if (T.LevelStart > ES) and not (T.Constraint in [actMSO, actMFO]) then ES := T.LevelStart;
    { encaixa no expediente; marco e decorrida ficam no instante exato }
    if (T.Duration > 0) and not T.Elapsed then ES := Cal(I).SnapForward(ES);
    FResults[I].EarlyStart := ES;
    if T.Duration = 0 then FResults[I].EarlyFinish := ES
    else FResults[I].EarlyFinish := AddDur(I, ES, T.Duration);
  end;
end;

procedure TAICPMScheduler.Backward(const Order: TAIIntArray);
var
  K, I, L: Integer;
  T: TAICPMTask;
  LF, C: TDateTime;
  Lk: TAITaskLink;
begin
  for K := High(Order) downto 0 do
  begin
    I := Order[K];
    T := FTasks[I];
    if T.IsSummary then Continue;
    LF := FProjectFinish;
    for L in FGraph.Successors(I) do
    begin
      Lk := FGraph.Links[L];
      case Lk.LinkType of
        atlFS: C := Shift(FResults[Lk.ToNode].LateStart, Lk, -1);
        atlSS: C := AddDur(I, Shift(FResults[Lk.ToNode].LateStart, Lk, -1), T.Duration);
        atlFF: C := Shift(FResults[Lk.ToNode].LateFinish, Lk, -1);
        atlSF: C := AddDur(I, Shift(FResults[Lk.ToNode].LateFinish, Lk, -1), T.Duration);
      end;
      if C < LF then LF := C;
    end;
    case T.Constraint of
      actFNLT: if T.ConstraintDate < LF then LF := T.ConstraintDate;
      actSNLT:
        begin
          C := AddDur(I, T.ConstraintDate, T.Duration);
          if C < LF then LF := C;
        end;
    end;
    if (T.Deadline > 0) and (T.Deadline < LF) then LF := T.Deadline;
    if T.Manual or (T.Constraint in [actMSO, actMFO]) then
    begin
      { datas fixas: nao ha folga para tras }
      FResults[I].LateStart := FResults[I].EarlyStart;
      FResults[I].LateFinish := FResults[I].EarlyFinish;
      if LF < FResults[I].EarlyFinish - 0.5 / 1440 then
      begin
        FResults[I].LateFinish := LF;
        if T.Duration = 0 then FResults[I].LateStart := LF
        else FResults[I].LateStart := AddDur(I, LF, -T.Duration);
      end;
      Continue;
    end;
    if (T.Duration > 0) and not T.Elapsed then LF := Cal(I).SnapBackward(LF);
    FResults[I].LateFinish := LF;
    if T.Duration = 0 then FResults[I].LateStart := LF
    else FResults[I].LateStart := AddDur(I, LF, -T.Duration);
  end;
end;

procedure TAICPMScheduler.Slack;
var
  I, L: Integer;
  T: TAICPMTask;
  R: TAICPMResult;
  Lk: TAITaskLink;
  F, C: Int64;
  HasSucc: Boolean;
begin
  for I := 0 to High(FTasks) do
  begin
    T := FTasks[I];
    if T.IsSummary then Continue;
    R := FResults[I];
    R.TotalSlack := Between(I, R.EarlyStart, R.LateStart);
    { margem livre: quanto atrasa sem atrasar o inicio cedo das sucessoras }
    F := High(Int64);
    HasSucc := False;
    for L in FGraph.Successors(I) do
    begin
      Lk := FGraph.Links[L];
      HasSucc := True;
      case Lk.LinkType of
        atlFS: C := Between(I, Shift(R.EarlyFinish, Lk, 1), FResults[Lk.ToNode].EarlyStart);
        atlSS: C := Between(I, Shift(R.EarlyStart, Lk, 1), FResults[Lk.ToNode].EarlyStart);
        atlFF: C := Between(I, Shift(R.EarlyFinish, Lk, 1), FResults[Lk.ToNode].EarlyFinish);
        atlSF: C := Between(I, Shift(R.EarlyStart, Lk, 1), FResults[Lk.ToNode].EarlyFinish);
      end;
      if C < F then F := C;
    end;
    if not HasSucc or (F > R.TotalSlack) then F := R.TotalSlack;
    if F < 0 then F := 0;
    R.FreeSlack := F;
    R.Critical := R.TotalSlack <= FCriticalSlack;
    { datas exibidas }
    R.Start := R.EarlyStart;
    R.Finish := R.EarlyFinish;
    if (T.Constraint = actALAP) and not T.Manual and (F > 0) then
    begin
      R.Start := AddDur(I, R.EarlyStart, F);
      if (T.Duration > 0) and not T.Elapsed then R.Start := Cal(I).SnapForward(R.Start);
      if T.Duration = 0 then R.Finish := R.Start else R.Finish := AddDur(I, R.Start, T.Duration);
    end;
    FResults[I] := R;
    { avisos de atraso }
    if (T.Deadline > 0) and (R.Finish > T.Deadline + 0.5 / 1440) then
      Warn(I, cwkDeadlineMissed, Format('%s termina em %s, depois da data limite %s',
        [T.Id, Fmt(R.Finish), Fmt(T.Deadline)]));
    if (T.Constraint = actSNLT) and (R.Start > T.ConstraintDate + 0.5 / 1440) then
      Warn(I, cwkLateConstraintMissed, Format('%s deveria iniciar ate %s e inicia em %s',
        [T.Id, Fmt(T.ConstraintDate), Fmt(R.Start)]));
    if (T.Constraint = actFNLT) and (R.Finish > T.ConstraintDate + 0.5 / 1440) then
      Warn(I, cwkLateConstraintMissed, Format('%s deveria terminar ate %s e termina em %s',
        [T.Id, Fmt(T.ConstraintDate), Fmt(R.Finish)]));
    if R.TotalSlack < 0 then
      Warn(I, cwkNegativeSlack, Format('%s tem margem negativa de %d min (o cronograma nao fecha)',
        [T.Id, -R.TotalSlack]));
  end;
end;

procedure TAICPMScheduler.Rollup;
var
  I, P: Integer;
  Seen: array of Boolean;
  R: TAICPMResult;
begin
  SetLength(Seen, Length(FTasks));
  { as filhas vem depois do pai (ordem de topicos): de tras para frente }
  for I := High(FTasks) downto 0 do
  begin
    P := FTasks[I].Parent;
    if (P < 0) or (P > High(FTasks)) then Continue;
    if FTasks[I].IsSummary and not Seen[I] then Continue;
    R := FResults[I];
    if not Seen[P] then
    begin
      FResults[P] := R;
      Seen[P] := True;
    end
    else
    begin
      if R.EarlyStart < FResults[P].EarlyStart then FResults[P].EarlyStart := R.EarlyStart;
      if R.EarlyFinish > FResults[P].EarlyFinish then FResults[P].EarlyFinish := R.EarlyFinish;
      if R.LateStart < FResults[P].LateStart then FResults[P].LateStart := R.LateStart;
      if R.LateFinish > FResults[P].LateFinish then FResults[P].LateFinish := R.LateFinish;
      if R.Start < FResults[P].Start then FResults[P].Start := R.Start;
      if R.Finish > FResults[P].Finish then FResults[P].Finish := R.Finish;
      if R.TotalSlack < FResults[P].TotalSlack then FResults[P].TotalSlack := R.TotalSlack;
      if R.FreeSlack < FResults[P].FreeSlack then FResults[P].FreeSlack := R.FreeSlack;
    end;
    FResults[P].Critical := FResults[P].TotalSlack <= FCriticalSlack;
  end;
  { resumo sem filhas: fica no inicio do projeto }
  for I := 0 to High(FTasks) do
    if FTasks[I].IsSummary and not Seen[I] then
    begin
      FillChar(FResults[I], SizeOf(FResults[I]), 0);
      FResults[I].EarlyStart := FProjectStart; FResults[I].EarlyFinish := FProjectStart;
      FResults[I].LateStart := FProjectStart; FResults[I].LateFinish := FProjectStart;
      FResults[I].Start := FProjectStart; FResults[I].Finish := FProjectStart;
    end;
end;

procedure TAICPMScheduler.Run;
var
  Order: TAIIntArray;
  I: Integer;
begin
  if FProjectCalendar = nil then raise EAICPMScheduler.Create('cronograma sem calendario do projeto');
  if FGraph = nil then raise EAICPMScheduler.Create('cronograma sem grafo de vinculos');
  if FGraph.NodeCount <> Length(FTasks) then
    raise EAICPMScheduler.CreateFmt('o grafo tem %d nos e o cronograma %d tarefas', [FGraph.NodeCount, Length(FTasks)]);
  for I := 0 to High(FTasks) do
  begin
    if FTasks[I].Duration < 0 then
      raise EAICPMScheduler.CreateFmt('%s: duracao negativa', [FTasks[I].Id]);
    if FTasks[I].IsSummary and ((Length(FGraph.Predecessors(I)) > 0) or (Length(FGraph.Successors(I)) > 0)) then
      raise EAICPMScheduler.CreateFmt('%s: resumo com vinculo direto (expanda para as subtarefas)', [FTasks[I].Id]);
  end;
  FWarnings := nil;
  SetLength(FResults, Length(FTasks));
  if Length(FTasks) > 0 then FillChar(FResults[0], SizeOf(TAICPMResult) * Length(FResults), 0);
  { o projeto comeca no primeiro instante util }
  FProjectStart := FProjectCalendar.SnapForward(FProjectStart);
  Order := FGraph.TopologicalOrder;
  Forward_(Order);
  FProjectFinish := FProjectStart;
  for I := 0 to High(FTasks) do
    if not FTasks[I].IsSummary and (FResults[I].EarlyFinish > FProjectFinish) then
      FProjectFinish := FResults[I].EarlyFinish;
  Backward(Order);
  Slack;
  Rollup;
end;

end.
