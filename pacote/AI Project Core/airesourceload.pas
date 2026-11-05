unit airesourceload;

{ Lazarus AI Suite - AI Project Core
  Carga de recursos, superalocacao e nivelamento, no estilo do Microsoft
  Project (generico, sem LCL).

  TAIResourceLoad
    Recebe os recursos (unidades maximas e calendario opcional) e as
    atribuicoes (tarefa, recurso, unidades, inicio e termino) e calcula, para
    cada recurso de trabalho, os intervalos em que a soma das unidades passa do
    maximo. Um intervalo so conta se tiver tempo util no calendario do recurso
    (uma tarefa que termina as 17:00 e outra que comeca as 08:00 do dia seguinte
    nao conflitam). Intervalos vizinhos com as mesmas atribuicoes sao unidos.
    Recursos de material e de custo nunca ficam superalocados.

  TAIResourceLeveler
    Nivelamento serial sobre um TAICPMScheduler ja montado: roda o cronograma,
    acha a primeira superalocacao no tempo, mantem a tarefa de maior prioridade
    (depois a de menor margem, a que comeca antes e o menor indice) e atrasa uma
    das outras ate o primeiro instante em que uma tarefa concorrente termina
    (TAICPMTask.LevelStart). Repete ate nao haver conflito. Tarefas manuais, com
    MSO/MFO ou marcadas como nao niveladas nao se movem; com WithinSlack so
    atrasa dentro da margem total. O que nao se resolve fica em Unresolved.
    Clear limpa os atrasos (equivale a "Limpar nivelamento"). }

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Math, aitaskgraph, aiworkcalendar, aicpmscheduler;

type
  EAIResourceLoad = class(Exception);

  TAIResourceKind = (arkWork, arkMaterial, arkCost);

  TAIResource = record
    Id, Name: string;
    Kind: TAIResourceKind;
    MaxUnits: Double;              // 1 = 100%; 0 = sem limite
    Calendar: TAIWorkCalendar;     // nao assume a posse; nil = tempo corrido
  end;

  TAIAssignment = record
    Task: Integer;                 // indice da tarefa do chamador
    Resource: Integer;             // indice de AddResource
    Units: Double;                 // 1 = 100%
    Start, Finish: TDateTime;
  end;

  TAIOverload = record
    Resource: Integer;
    Start, Finish: TDateTime;
    Units: Double;                 // pico de unidades no intervalo
    Assignments: TAIIntArray;      // indices das atribuicoes envolvidas
  end;

  TAITaskNameFunc = function(Task: Integer): string of object;

  TAIResourceLoad = class
  private
    FResources: array of TAIResource;
    FAssignments: array of TAIAssignment;
    FOverloads: array of TAIOverload;
    FTaskName: TAITaskNameFunc;
    function GetResource(I: Integer): TAIResource;
    function GetAssignment(I: Integer): TAIAssignment;
    function GetOverload(I: Integer): TAIOverload;
    procedure ComputeResource(R: Integer);
    function UsefulMinutes(R: Integer; A, B: TDateTime): Int64;
    function TaskText(Task: Integer): string;
  public
    procedure Clear;
    procedure ClearAssignments;
    function AddResource(const R: TAIResource): Integer;
    function AddAssignment(ATask, AResource: Integer; AUnits: Double; AStart, AFinish: TDateTime): Integer;
    procedure SetAssignmentDates(I: Integer; AStart, AFinish: TDateTime);
    function IndexOfResource(const AId: string): Integer;
    procedure Compute;
    function ResourceCount: Integer;
    function AssignmentCount: Integer;
    function OverloadCount: Integer;
    function IsOverallocated(R: Integer): Boolean;
    function AssignmentOverloaded(A: Integer): Boolean;
    function TaskOverloaded(Task: Integer): Boolean;
    function OverloadsOf(R: Integer): TAIIntArray;
    function PeakUnits(R: Integer): Double;
    function AssignmentWork(A: Integer): Int64;    // minutos de trabalho (unidades x tempo util)
    function ResourceWork(R: Integer): Int64;
    function AssignmentsOf(R: Integer): TAIIntArray;
    function AssignmentsOfTask(Task: Integer): TAIIntArray;
    function OverloadMessage(I: Integer): string;
    property Resources[I: Integer]: TAIResource read GetResource;
    property Assignments[I: Integer]: TAIAssignment read GetAssignment;
    property Overloads[I: Integer]: TAIOverload read GetOverload;
    property OnTaskName: TAITaskNameFunc read FTaskName write FTaskName;
  end;

  TAILevelOptions = record
    WithinSlack: Boolean;          // so atrasa dentro da margem total
    MaxIterations: Integer;        // 0 = automatico
  end;

  TAILevelDelay = record
    Task: Integer;
    LevelStart: TDateTime;
  end;

  TAIResourceLeveler = class
  private
    FScheduler: TAICPMScheduler;
    FLoad: TAIResourceLoad;
    FPriority: array of Integer;
    FNoLevel: array of Boolean;
    FDelays: array of TAILevelDelay;
    FUnresolved: array of string;
    FIterations: Integer;
    procedure EnsureArrays;
    procedure SyncDates;
    function Movable(Task: Integer; const Opt: TAILevelOptions): Boolean;
    function Better(A, B: Integer): Boolean;   // A fica e B atrasa?
    function GetDelay(I: Integer): TAILevelDelay;
    function GetUnresolved(I: Integer): string;
  public
    constructor Create(AScheduler: TAICPMScheduler; ALoad: TAIResourceLoad);
    procedure SetPriority(Task, APriority: Integer);   // 0..1000, padrao 500
    procedure SetDoNotLevel(Task: Integer; AValue: Boolean);
    function Level(const Opt: TAILevelOptions): Boolean;  // True = sem conflito no fim
    procedure Clear;                                       // limpa o nivelamento e recalcula
    function DelayCount: Integer;
    function UnresolvedCount: Integer;
    function LevelStartOf(Task: Integer): TDateTime;
    property Delays[I: Integer]: TAILevelDelay read GetDelay;
    property Unresolved[I: Integer]: string read GetUnresolved;
    property Iterations: Integer read FIterations;
  end;

function AINewResource(const AId, AName: string; AMaxUnits: Double = 1;
  AKind: TAIResourceKind = arkWork; ACalendar: TAIWorkCalendar = nil): TAIResource;
function AIDefaultLevelOptions: TAILevelOptions;
function AIUnitsPercent(U: Double): string;

implementation

const
  EPS_UNITS = 1E-6;
  ONE_MINUTE = 1 / 1440;

function AINewResource(const AId, AName: string; AMaxUnits: Double;
  AKind: TAIResourceKind; ACalendar: TAIWorkCalendar): TAIResource;
begin
  Result.Id := AId;
  Result.Name := AName;
  Result.Kind := AKind;
  Result.MaxUnits := AMaxUnits;
  Result.Calendar := ACalendar;
end;

function AIDefaultLevelOptions: TAILevelOptions;
begin
  Result.WithinSlack := False;
  Result.MaxIterations := 0;
end;

function AIUnitsPercent(U: Double): string;
begin
  Result := IntToStr(Round(U * 100)) + '%';
end;

function Fmt(T: TDateTime): string;
begin
  Result := FormatDateTime('dd"/"mm"/"yyyy hh":"nn', T);
end;

{ ---------------- TAIResourceLoad ---------------- }

procedure TAIResourceLoad.Clear;
begin
  FResources := nil;
  FAssignments := nil;
  FOverloads := nil;
end;

procedure TAIResourceLoad.ClearAssignments;
begin
  FAssignments := nil;
  FOverloads := nil;
end;

function TAIResourceLoad.AddResource(const R: TAIResource): Integer;
begin
  if R.MaxUnits < 0 then
    raise EAIResourceLoad.CreateFmt('%s: unidades maximas negativas', [R.Id]);
  Result := Length(FResources);
  SetLength(FResources, Result + 1);
  FResources[Result] := R;
end;

function TAIResourceLoad.AddAssignment(ATask, AResource: Integer; AUnits: Double;
  AStart, AFinish: TDateTime): Integer;
begin
  if (AResource < 0) or (AResource > High(FResources)) then
    raise EAIResourceLoad.CreateFmt('atribuicao com recurso inexistente (%d)', [AResource]);
  if AUnits < 0 then
    raise EAIResourceLoad.CreateFmt('%s: unidades negativas', [FResources[AResource].Id]);
  Result := Length(FAssignments);
  SetLength(FAssignments, Result + 1);
  FAssignments[Result].Task := ATask;
  FAssignments[Result].Resource := AResource;
  FAssignments[Result].Units := AUnits;
  FAssignments[Result].Start := AStart;
  FAssignments[Result].Finish := AFinish;
end;

procedure TAIResourceLoad.SetAssignmentDates(I: Integer; AStart, AFinish: TDateTime);
begin
  FAssignments[I].Start := AStart;
  FAssignments[I].Finish := AFinish;
end;

function TAIResourceLoad.IndexOfResource(const AId: string): Integer;
begin
  for Result := 0 to High(FResources) do
    if SameText(FResources[Result].Id, AId) then Exit;
  Result := -1;
end;

function TAIResourceLoad.ResourceCount: Integer;
begin
  Result := Length(FResources);
end;

function TAIResourceLoad.AssignmentCount: Integer;
begin
  Result := Length(FAssignments);
end;

function TAIResourceLoad.OverloadCount: Integer;
begin
  Result := Length(FOverloads);
end;

function TAIResourceLoad.GetResource(I: Integer): TAIResource;
begin
  Result := FResources[I];
end;

function TAIResourceLoad.GetAssignment(I: Integer): TAIAssignment;
begin
  Result := FAssignments[I];
end;

function TAIResourceLoad.GetOverload(I: Integer): TAIOverload;
begin
  Result := FOverloads[I];
end;

function TAIResourceLoad.UsefulMinutes(R: Integer; A, B: TDateTime): Int64;
begin
  if B <= A then Exit(0);
  if FResources[R].Calendar <> nil then
    Result := FResources[R].Calendar.WorkingMinutesBetween(A, B)
  else
    Result := Round((B - A) * 1440);
end;

function SameInts(const A, B: TAIIntArray): Boolean;
var I: Integer;
begin
  if Length(A) <> Length(B) then Exit(False);
  for I := 0 to High(A) do
    if A[I] <> B[I] then Exit(False);
  Result := True;
end;

procedure TAIResourceLoad.ComputeResource(R: Integer);
var
  Times: array of TDateTime;
  I, J, K, N: Integer;
  A, B, Mid: TDateTime;
  Sum: Double;
  Active: TAIIntArray;
  Ov: TAIOverload;
  Last: Integer;

  procedure AddTime(T: TDateTime);
  begin
    SetLength(Times, Length(Times) + 1);
    Times[High(Times)] := T;
  end;

  procedure SortTimes;
  var P, Q: Integer; X: TDateTime;
  begin
    for P := 1 to High(Times) do
    begin
      X := Times[P];
      Q := P - 1;
      while (Q >= 0) and (Times[Q] > X) do
      begin
        Times[Q + 1] := Times[Q];
        Dec(Q);
      end;
      Times[Q + 1] := X;
    end;
  end;

begin
  if (FResources[R].Kind <> arkWork) or (FResources[R].MaxUnits <= 0) then Exit;
  Times := nil;
  for I := 0 to High(FAssignments) do
    if (FAssignments[I].Resource = R) and (FAssignments[I].Finish > FAssignments[I].Start)
      and (FAssignments[I].Units > 0) then
    begin
      AddTime(FAssignments[I].Start);
      AddTime(FAssignments[I].Finish);
    end;
  if Length(Times) < 2 then Exit;
  SortTimes;
  Last := -1;
  for K := 0 to High(Times) - 1 do
  begin
    A := Times[K];
    B := Times[K + 1];
    if B - A < ONE_MINUTE / 2 then Continue;
    Mid := A + (B - A) / 2;
    Sum := 0;
    Active := nil;
    for J := 0 to High(FAssignments) do
      if (FAssignments[J].Resource = R) and (FAssignments[J].Units > 0)
        and (FAssignments[J].Start <= Mid) and (FAssignments[J].Finish > Mid) then
      begin
        Sum := Sum + FAssignments[J].Units;
        N := Length(Active);
        SetLength(Active, N + 1);
        Active[N] := J;
      end;
    if Sum <= FResources[R].MaxUnits + EPS_UNITS then
    begin
      Last := -1;
      Continue;
    end;
    if UsefulMinutes(R, A, B) <= 0 then Continue;   // fora do expediente: nao interrompe
    if (Last >= 0) and SameInts(FOverloads[Last].Assignments, Active) then
    begin
      FOverloads[Last].Finish := B;
      if Sum > FOverloads[Last].Units then FOverloads[Last].Units := Sum;
      Continue;
    end;
    Ov.Resource := R;
    Ov.Start := A;
    Ov.Finish := B;
    Ov.Units := Sum;
    Ov.Assignments := Active;
    Last := Length(FOverloads);
    SetLength(FOverloads, Last + 1);
    FOverloads[Last] := Ov;
  end;
end;

procedure TAIResourceLoad.Compute;
var R: Integer;
begin
  FOverloads := nil;
  for R := 0 to High(FResources) do ComputeResource(R);
end;

function TAIResourceLoad.IsOverallocated(R: Integer): Boolean;
var I: Integer;
begin
  for I := 0 to High(FOverloads) do
    if FOverloads[I].Resource = R then Exit(True);
  Result := False;
end;

function TAIResourceLoad.AssignmentOverloaded(A: Integer): Boolean;
var I, J: Integer;
begin
  for I := 0 to High(FOverloads) do
    for J in FOverloads[I].Assignments do
      if J = A then Exit(True);
  Result := False;
end;

function TAIResourceLoad.TaskOverloaded(Task: Integer): Boolean;
var A: Integer;
begin
  for A := 0 to High(FAssignments) do
    if (FAssignments[A].Task = Task) and AssignmentOverloaded(A) then Exit(True);
  Result := False;
end;

function TAIResourceLoad.OverloadsOf(R: Integer): TAIIntArray;
var I: Integer;
begin
  Result := nil;
  for I := 0 to High(FOverloads) do
    if FOverloads[I].Resource = R then
    begin
      SetLength(Result, Length(Result) + 1);
      Result[High(Result)] := I;
    end;
end;

function TAIResourceLoad.PeakUnits(R: Integer): Double;
var
  I, J: Integer;
  T, S: Double;
begin
  Result := 0;
  for I := 0 to High(FAssignments) do
  begin
    if FAssignments[I].Resource <> R then Continue;
    T := FAssignments[I].Start;
    S := 0;
    for J := 0 to High(FAssignments) do
      if (FAssignments[J].Resource = R) and (FAssignments[J].Start <= T)
        and (FAssignments[J].Finish > T) then S := S + FAssignments[J].Units;
    if S > Result then Result := S;
  end;
end;

function TAIResourceLoad.AssignmentWork(A: Integer): Int64;
begin
  with FAssignments[A] do
    Result := Round(UsefulMinutes(Resource, Start, Finish) * Units);
end;

function TAIResourceLoad.ResourceWork(R: Integer): Int64;
var A: Integer;
begin
  Result := 0;
  for A := 0 to High(FAssignments) do
    if FAssignments[A].Resource = R then Inc(Result, AssignmentWork(A));
end;

function TAIResourceLoad.AssignmentsOf(R: Integer): TAIIntArray;
var A: Integer;
begin
  Result := nil;
  for A := 0 to High(FAssignments) do
    if FAssignments[A].Resource = R then
    begin
      SetLength(Result, Length(Result) + 1);
      Result[High(Result)] := A;
    end;
end;

function TAIResourceLoad.AssignmentsOfTask(Task: Integer): TAIIntArray;
var A: Integer;
begin
  Result := nil;
  for A := 0 to High(FAssignments) do
    if FAssignments[A].Task = Task then
    begin
      SetLength(Result, Length(Result) + 1);
      Result[High(Result)] := A;
    end;
end;

function TAIResourceLoad.TaskText(Task: Integer): string;
begin
  if Assigned(FTaskName) then Result := FTaskName(Task)
  else Result := '#' + IntToStr(Task);
end;

function TAIResourceLoad.OverloadMessage(I: Integer): string;
var
  Ov: TAIOverload;
  Names: string;
  K: Integer;
begin
  Ov := FOverloads[I];
  Names := '';
  for K := 0 to High(Ov.Assignments) do
  begin
    if K > 0 then
      if K = High(Ov.Assignments) then Names := Names + ' e ' else Names := Names + ', ';
    Names := Names + TaskText(FAssignments[Ov.Assignments[K]].Task);
  end;
  Result := Format('%s superalocado de %s a %s: %s ao mesmo tempo (%s de %s)',
    [FResources[Ov.Resource].Name, Fmt(Ov.Start), Fmt(Ov.Finish), Names,
     AIUnitsPercent(Ov.Units), AIUnitsPercent(FResources[Ov.Resource].MaxUnits)]);
end;

{ ---------------- TAIResourceLeveler ---------------- }

constructor TAIResourceLeveler.Create(AScheduler: TAICPMScheduler; ALoad: TAIResourceLoad);
begin
  inherited Create;
  FScheduler := AScheduler;
  FLoad := ALoad;
end;

procedure TAIResourceLeveler.EnsureArrays;
var I, Old: Integer;
begin
  Old := Length(FPriority);
  if Old < FScheduler.TaskCount then
  begin
    SetLength(FPriority, FScheduler.TaskCount);
    SetLength(FNoLevel, FScheduler.TaskCount);
    for I := Old to High(FPriority) do
    begin
      FPriority[I] := 500;
      FNoLevel[I] := False;
    end;
  end;
end;

procedure TAIResourceLeveler.SetPriority(Task, APriority: Integer);
begin
  EnsureArrays;
  FPriority[Task] := EnsureRange(APriority, 0, 1000);
end;

procedure TAIResourceLeveler.SetDoNotLevel(Task: Integer; AValue: Boolean);
begin
  EnsureArrays;
  FNoLevel[Task] := AValue;
end;

procedure TAIResourceLeveler.SyncDates;
var A, T: Integer;
begin
  for A := 0 to FLoad.AssignmentCount - 1 do
  begin
    T := FLoad.Assignments[A].Task;
    if (T >= 0) and (T < FScheduler.TaskCount) then
      FLoad.SetAssignmentDates(A, FScheduler.Results[T].Start, FScheduler.Results[T].Finish);
  end;
  FLoad.Compute;
end;

function TAIResourceLeveler.Movable(Task: Integer; const Opt: TAILevelOptions): Boolean;
var T: TAICPMTask;
begin
  T := FScheduler.Tasks[Task];
  if T.Manual or T.IsSummary or (T.Constraint in [actMSO, actMFO]) or FNoLevel[Task] then
    Exit(False);
  if Opt.WithinSlack and (FScheduler.Results[Task].TotalSlack <= 0) then Exit(False);
  Result := True;
end;

function TAIResourceLeveler.Better(A, B: Integer): Boolean;
var RA, RB: TAICPMResult;
begin
  if FPriority[A] <> FPriority[B] then Exit(FPriority[A] > FPriority[B]);
  RA := FScheduler.Results[A];
  RB := FScheduler.Results[B];
  if RA.TotalSlack <> RB.TotalSlack then Exit(RA.TotalSlack < RB.TotalSlack);
  if Abs(RA.Start - RB.Start) > ONE_MINUTE / 2 then Exit(RA.Start < RB.Start);
  Result := A < B;
end;

function TAIResourceLeveler.Level(const Opt: TAILevelOptions): Boolean;
var
  MaxIt, I, K, Keep, Victim, T: Integer;
  Ov: TAIOverload;
  Tasks: TAIIntArray;
  Target, F: TDateTime;
  Blocked: TStringList;
  Key: string;
  Found: Boolean;

  procedure AddUnique(X: Integer);
  var Y: Integer;
  begin
    for Y in Tasks do if Y = X then Exit;
    SetLength(Tasks, Length(Tasks) + 1);
    Tasks[High(Tasks)] := X;
  end;

  function CanSlide(Task: Integer; NewStart: TDateTime): Boolean;
  var R: TAICPMResult;
  begin
    if not Opt.WithinSlack then Exit(True);
    R := FScheduler.Results[Task];
    Result := (NewStart <= R.LateStart + ONE_MINUTE / 2);
  end;

begin
  EnsureArrays;
  FUnresolved := nil;
  FIterations := 0;
  MaxIt := Opt.MaxIterations;
  if MaxIt <= 0 then MaxIt := 50 + 4 * FScheduler.TaskCount * Max(1, FLoad.AssignmentCount);
  Blocked := TStringList.Create;
  try
    Blocked.Sorted := True;
    Blocked.Duplicates := dupIgnore;
    FScheduler.Run;
    SyncDates;
    while FIterations < MaxIt do
    begin
      { primeira superalocacao ainda nao marcada como insoluvel }
      Found := False;
      Ov.Resource := -1;
      for I := 0 to FLoad.OverloadCount - 1 do
      begin
        Key := Format('%d@%.6f', [FLoad.Overloads[I].Resource, FLoad.Overloads[I].Start]);
        if Blocked.IndexOf(Key) >= 0 then Continue;
        if not Found or (FLoad.Overloads[I].Start < Ov.Start) then
        begin
          Ov := FLoad.Overloads[I];
          Found := True;
        end;
      end;
      if not Found then Break;
      Inc(FIterations);
      Tasks := nil;
      for K in Ov.Assignments do AddUnique(FLoad.Assignments[K].Task);
      { quem fica: a melhor; as fixas ficam sempre }
      Keep := -1;
      for T in Tasks do
        if not Movable(T, Opt) then
        begin
          if (Keep < 0) or Better(T, Keep) then Keep := T;
        end;
      if Keep < 0 then
        for T in Tasks do
          if (Keep < 0) or Better(T, Keep) then Keep := T;
      { quem sai: a pior das moveis }
      Victim := -1;
      for T in Tasks do
        if (T <> Keep) and Movable(T, Opt) then
          if (Victim < 0) or Better(Victim, T) then Victim := T;
      { para quando: o primeiro termino de uma concorrente que esta ativa no conflito }
      Target := 0;
      if Victim >= 0 then
        for T in Tasks do
          if T <> Victim then
          begin
            F := FScheduler.Results[T].Finish;
            if (F > Ov.Start + ONE_MINUTE / 2) and ((Target = 0) or (F < Target)) then Target := F;
          end;
      if (Victim < 0) or (Target = 0) or (Target <= FScheduler.Results[Victim].Start + ONE_MINUTE / 2)
        or not CanSlide(Victim, Target) then
      begin
        Key := Format('%d@%.6f', [Ov.Resource, Ov.Start]);
        Blocked.Add(Key);
        Continue;
      end;
      FScheduler.SetLevelStart(Victim, Target);
      FScheduler.Run;
      SyncDates;
    end;
    { o que sobrou }
    for I := 0 to FLoad.OverloadCount - 1 do
    begin
      SetLength(FUnresolved, Length(FUnresolved) + 1);
      FUnresolved[High(FUnresolved)] := FLoad.OverloadMessage(I);
    end;
  finally
    Blocked.Free;
  end;
  FDelays := nil;
  for I := 0 to FScheduler.TaskCount - 1 do
    if FScheduler.Tasks[I].LevelStart > 0 then
    begin
      SetLength(FDelays, Length(FDelays) + 1);
      FDelays[High(FDelays)].Task := I;
      FDelays[High(FDelays)].LevelStart := FScheduler.Tasks[I].LevelStart;
    end;
  Result := FLoad.OverloadCount = 0;
end;

procedure TAIResourceLeveler.Clear;
begin
  FScheduler.ClearLeveling;
  FDelays := nil;
  FUnresolved := nil;
  FScheduler.Run;
  SyncDates;
end;

function TAIResourceLeveler.DelayCount: Integer;
begin
  Result := Length(FDelays);
end;

function TAIResourceLeveler.UnresolvedCount: Integer;
begin
  Result := Length(FUnresolved);
end;

function TAIResourceLeveler.LevelStartOf(Task: Integer): TDateTime;
begin
  Result := FScheduler.Tasks[Task].LevelStart;
end;

function TAIResourceLeveler.GetDelay(I: Integer): TAILevelDelay;
begin
  Result := FDelays[I];
end;

function TAIResourceLeveler.GetUnresolved(I: Integer): string;
begin
  Result := FUnresolved[I];
end;

end.
