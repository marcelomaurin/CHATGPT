program test_airesourceload;

{ Testes de console (sem LCL) de airesourceload (AI Project Core): carga,
  superalocacao e nivelamento. Calendario padrao (seg-sex 08-12 e 13-17);
  segunda 26/10/2026 08:00.
  Compilar: fpc -Fu"../pacote/AI Project Core" test_airesourceload.lpr }

{$mode objfpc}{$H+}

uses
  Classes, SysUtils, aiprojectduration, aitaskgraph, aiworkcalendar, aicpmscheduler,
  airesourceload;

var
  Passed, Failed: Integer;
  Cal: TAIWorkCalendar;

procedure Check(Cond: Boolean; const What: string);
begin
  if Cond then Inc(Passed)
  else
  begin
    Inc(Failed);
    Writeln('FALHOU: ', What);
  end;
end;

function DT(M, D, H, N: Word): TDateTime;
begin
  Result := EncodeDate(2026, M, D) + EncodeTime(H, N, 0, 0);
end;

function S(T: TDateTime): string;
begin
  Result := FormatDateTime('dd/mm hh:nn', T);
end;

function SameT(A, B: TDateTime): Boolean;
begin
  Result := Abs(A - B) < 0.5 / 1440;
end;

type
  TNames = class
    function Name(Task: Integer): string;
  end;

function TNames.Name(Task: Integer): string;
begin
  Result := 'T' + IntToStr(Task);
end;

var
  Names: TNames;

procedure TestLoad;
var
  L: TAIResourceLoad;
  M, P, Mat: Integer;
  Ov: TAIOverload;
begin
  L := TAIResourceLoad.Create;
  try
    L.OnTaskName := @Names.Name;
    M := L.AddResource(AINewResource('R-001', 'Ender-3', 1, arkWork, Cal));
    P := L.AddResource(AINewResource('R-002', 'Ana', 2, arkWork, Cal));
    Mat := L.AddResource(AINewResource('R-003', 'PLA', 0, arkMaterial));
    Check(L.IndexOfResource('r-002') = P, 'IndexOfResource sem caixa');
    Check(L.IndexOfResource('R-999') = -1, 'recurso inexistente');

    { sobreposicao parcial: 10-12 }
    L.AddAssignment(0, M, 1, DT(10, 26, 8, 0), DT(10, 26, 12, 0));
    L.AddAssignment(1, M, 1, DT(10, 26, 10, 0), DT(10, 26, 14, 0));
    L.Compute;
    Check(L.OverloadCount = 1, Format('uma superalocacao (%d)', [L.OverloadCount]));
    Ov := L.Overloads[0];
    Check((Ov.Resource = M) and SameT(Ov.Start, DT(10, 26, 10, 0)) and SameT(Ov.Finish, DT(10, 26, 12, 0)),
      'intervalo 10:00-12:00: ' + S(Ov.Start) + ' - ' + S(Ov.Finish));
    Check(Abs(Ov.Units - 2) < 1E-9, 'pico de 200%');
    Check(Length(Ov.Assignments) = 2, 'duas atribuicoes no conflito');
    Check(L.IsOverallocated(M) and not L.IsOverallocated(P), 'so a maquina superalocada');
    Check(L.AssignmentOverloaded(0) and L.AssignmentOverloaded(1), 'atribuicoes marcadas');
    Check(L.TaskOverloaded(1) and not L.TaskOverloaded(5), 'tarefa marcada');
    Check(Length(L.OverloadsOf(M)) = 1, 'OverloadsOf');
    Check(Pos('Ender-3 superalocado de 26/10/2026 10:00 a 26/10/2026 12:00: T0 e T1', L.OverloadMessage(0)) = 1,
      'mensagem: ' + L.OverloadMessage(0));
    Check(Pos('(200% de 100%)', L.OverloadMessage(0)) > 0, 'mensagem com unidades');

    { encostadas nao conflitam }
    L.ClearAssignments;
    L.AddAssignment(0, M, 1, DT(10, 26, 8, 0), DT(10, 26, 12, 0));
    L.AddAssignment(1, M, 1, DT(10, 26, 12, 0), DT(10, 26, 17, 0));
    L.Compute;
    Check(L.OverloadCount = 0, 'tarefas encostadas sem conflito');

    { sobreposicao so fora do expediente nao conta }
    L.ClearAssignments;
    L.AddAssignment(0, M, 1, DT(10, 26, 13, 0), DT(10, 27, 8, 0));
    L.AddAssignment(1, M, 1, DT(10, 26, 17, 0), DT(10, 27, 12, 0));
    L.Compute;
    Check(L.OverloadCount = 0, 'sobreposicao noturna sem conflito');

    { sem calendario (tempo corrido) a noite conta }
    L.Clear;
    M := L.AddResource(AINewResource('R-001', 'Forno', 1));
    L.AddAssignment(0, M, 1, DT(10, 26, 13, 0), DT(10, 27, 8, 0));
    L.AddAssignment(1, M, 1, DT(10, 26, 17, 0), DT(10, 27, 12, 0));
    L.Compute;
    Check(L.OverloadCount = 1, 'tempo corrido: conflito a noite');
    Check(L.AssignmentWork(0) = 19 * 60, 'trabalho corrido 19 h');

    { pessoa com 200%: duas ok, tres conflitam }
    L.Clear;
    M := L.AddResource(AINewResource('R-001', 'Ender-3', 1, arkWork, Cal));
    P := L.AddResource(AINewResource('R-002', 'Ana', 2, arkWork, Cal));
    Mat := L.AddResource(AINewResource('R-003', 'PLA', 0, arkMaterial));
    L.AddAssignment(0, P, 1, DT(10, 26, 8, 0), DT(10, 26, 17, 0));
    L.AddAssignment(1, P, 1, DT(10, 26, 8, 0), DT(10, 26, 17, 0));
    L.Compute;
    Check(L.OverloadCount = 0, 'duas tarefas em 200%');
    L.AddAssignment(2, P, 1, DT(10, 26, 13, 0), DT(10, 26, 15, 0));
    L.Compute;
    Check(L.OverloadCount = 1, 'tres tarefas em 200%');
    Check(Abs(L.Overloads[0].Units - 3) < 1E-9, 'pico 300%');
    Check(Abs(L.PeakUnits(P) - 3) < 1E-9, 'PeakUnits 3');
    Check(Length(L.Overloads[0].Assignments) = 3, 'tres no conflito');

    { material nunca superaloca }
    L.AddAssignment(0, Mat, 5, DT(10, 26, 8, 0), DT(10, 26, 17, 0));
    L.AddAssignment(1, Mat, 5, DT(10, 26, 8, 0), DT(10, 26, 17, 0));
    L.Compute;
    Check(not L.IsOverallocated(Mat), 'material sem superalocacao');

    { uma unica atribuicao acima do maximo }
    L.ClearAssignments;
    L.AddAssignment(0, M, 2, DT(10, 26, 8, 0), DT(10, 26, 10, 0));
    L.Compute;
    Check(L.OverloadCount = 1, 'uma atribuicao em 200% numa maquina');

    { intervalos com conjuntos diferentes ficam separados; o mesmo conjunto atravessa o almoco }
    L.ClearAssignments;
    L.AddAssignment(0, M, 1, DT(10, 26, 8, 0), DT(10, 26, 17, 0));
    L.AddAssignment(1, M, 1, DT(10, 26, 8, 0), DT(10, 26, 10, 0));
    L.AddAssignment(2, M, 1, DT(10, 26, 10, 0), DT(10, 26, 15, 0));
    L.Compute;
    Check(L.OverloadCount = 2, Format('dois conflitos (%d)', [L.OverloadCount]));
    if L.OverloadCount = 2 then
      Check(SameT(L.Overloads[1].Start, DT(10, 26, 10, 0)) and SameT(L.Overloads[1].Finish, DT(10, 26, 15, 0)),
        'segundo conflito 10-15 com almoco: ' + S(L.Overloads[1].Start) + ' - ' + S(L.Overloads[1].Finish));
    { mesmo conjunto atravessa a noite }
    L.ClearAssignments;
    L.AddAssignment(0, M, 1, DT(10, 26, 8, 0), DT(10, 27, 17, 0));
    L.AddAssignment(1, M, 1, DT(10, 26, 13, 0), DT(10, 27, 12, 0));
    L.Compute;
    Check(L.OverloadCount = 1, 'conflito atravessando a noite fica inteiro');
    if L.OverloadCount = 1 then
      Check(SameT(L.Overloads[0].Start, DT(10, 26, 13, 0)) and SameT(L.Overloads[0].Finish, DT(10, 27, 12, 0)),
        'conflito 26 13:00 - 27 12:00');

    { trabalho }
    L.ClearAssignments;
    L.AddAssignment(0, P, 1, DT(10, 26, 8, 0), DT(10, 26, 17, 0));
    L.AddAssignment(1, P, 0.5, DT(10, 27, 8, 0), DT(10, 27, 17, 0));
    Check(L.AssignmentWork(0) = 480, 'trabalho 8 h');
    Check(L.AssignmentWork(1) = 240, 'trabalho 50% = 4 h');
    Check(L.ResourceWork(P) = 720, 'trabalho do recurso 12 h');
    Check(Length(L.AssignmentsOf(P)) = 2, 'AssignmentsOf');
    Check(Length(L.AssignmentsOfTask(1)) = 1, 'AssignmentsOfTask');

    { validacoes }
    try
      L.AddAssignment(0, 99, 1, 0, 0);
      Check(False, 'recurso inexistente aceito');
    except
      on E: EAIResourceLoad do Check(True, '');
    end;
    try
      L.AddResource(AINewResource('X', 'X', -1));
      Check(False, 'maximo negativo aceito');
    except
      on E: EAIResourceLoad do Check(True, '');
    end;
    Check(AIUnitsPercent(0.5) = '50%', 'AIUnitsPercent');
  finally
    L.Free;
  end;
end;

type
  TLevelCase = class
    G: TAITaskGraph;
    Sc: TAICPMScheduler;
    L: TAIResourceLoad;
    Lv: TAIResourceLeveler;
    constructor Create;
    destructor Destroy; override;
    function Add(const Id: string; Dur: Int64): Integer;
    function AddT(const T: TAICPMTask): Integer;
    procedure Link(const A, B: string);
    procedure Assign(Task, Res: Integer; Units: Double = 1);
  end;

constructor TLevelCase.Create;
begin
  G := TAITaskGraph.Create;
  Sc := TAICPMScheduler.Create;
  Sc.ProjectCalendar := Cal;
  Sc.Graph := G;
  Sc.ProjectStart := DT(10, 26, 8, 0);
  L := TAIResourceLoad.Create;
  L.OnTaskName := @Names.Name;
  Lv := TAIResourceLeveler.Create(Sc, L);
end;

destructor TLevelCase.Destroy;
begin
  Lv.Free;
  L.Free;
  Sc.Free;
  G.Free;
  inherited Destroy;
end;

function TLevelCase.AddT(const T: TAICPMTask): Integer;
begin
  G.AddNode(T.Id);
  Result := Sc.AddTask(T);
end;

function TLevelCase.Add(const Id: string; Dur: Int64): Integer;
begin
  Result := AddT(AINewCPMTask(Id, Dur));
end;

procedure TLevelCase.Link(const A, B: string);
var Err: string;
begin
  if G.AddLink(A, B, atlFS, AINoLag, Err) < 0 then raise Exception.Create(Err);
end;

procedure TLevelCase.Assign(Task, Res: Integer; Units: Double);
begin
  L.AddAssignment(Task, Res, Units, 0, 0);
end;

procedure Dates(Sc: TAICPMScheduler; I: Integer; AStart, AFinish: TDateTime; const What: string);
var R: TAICPMResult;
begin
  R := Sc.Results[I];
  Check(SameT(R.Start, AStart) and SameT(R.Finish, AFinish),
    Format('%s: %s - %s, esperado %s - %s', [What, S(R.Start), S(R.Finish), S(AStart), S(AFinish)]));
end;

procedure TestLevelTwoPrints;
var C: TLevelCase; M, P1, P2, P3: Integer; T: TAICPMTask;
begin
  C := TLevelCase.Create;
  try
    M := C.L.AddResource(AINewResource('R-001', 'Ender-3', 1, arkWork, Cal));
    P1 := C.Add('P1', 480);
    P2 := C.Add('P2', 480);
    P3 := C.Add('P3', 240);
    C.Link('P2', 'P3');
    C.Assign(P1, M);
    C.Assign(P2, M);
    C.Sc.Run;
    Dates(C.Sc, P2, DT(10, 26, 8, 0), DT(10, 26, 17, 0), 'P2 antes de nivelar');
    Check(C.Lv.Level(AIDefaultLevelOptions), 'nivelamento resolve duas impressoes');
    Dates(C.Sc, P2, DT(10, 26, 8, 0), DT(10, 26, 17, 0), 'P2 critica (tem sucessora) fica');
    Dates(C.Sc, P1, DT(10, 27, 8, 0), DT(10, 27, 17, 0), 'P1 com margem vai para o dia seguinte');
    Check(C.Lv.DelayCount = 1, Format('uma tarefa atrasada (%d)', [C.Lv.DelayCount]));
    if C.Lv.DelayCount = 1 then
      Check((C.Lv.Delays[0].Task = P1) and SameT(C.Lv.LevelStartOf(P1), DT(10, 26, 17, 0)),
        'LevelStart de P1 = 26/10 17:00');
    Check(C.L.OverloadCount = 0, 'sem conflito depois de nivelar');
    Check(C.Lv.Iterations >= 1, 'iteracoes contadas');
    C.Lv.Clear;
    Dates(C.Sc, P1, DT(10, 26, 8, 0), DT(10, 26, 17, 0), 'limpar: P1 volta');
    Dates(C.Sc, P2, DT(10, 26, 8, 0), DT(10, 26, 17, 0), 'limpar: P2');
    Check(C.L.OverloadCount = 1, 'limpar: o conflito volta');
    Check(C.Lv.DelayCount = 0, 'limpar: sem atrasos');
    { prioridade vence a margem: P2 com prioridade baixa sai, e P3 vai junto }
    C.Lv.SetPriority(P2, 100);
    Check(C.Lv.Level(AIDefaultLevelOptions), 'nivelamento por prioridade');
    Dates(C.Sc, P1, DT(10, 26, 8, 0), DT(10, 26, 17, 0), 'P1 de maior prioridade fica');
    Dates(C.Sc, P2, DT(10, 27, 8, 0), DT(10, 27, 17, 0), 'P2 de menor prioridade sai');
    Dates(C.Sc, P3, DT(10, 28, 8, 0), DT(10, 28, 12, 0), 'P3 empurrada pela P2');
    C.Lv.SetPriority(P2, 500);
    { nao nivelar }
    C.Lv.Clear;
    C.Lv.SetDoNotLevel(P1, True);
    C.Lv.Level(AIDefaultLevelOptions);
    Dates(C.Sc, P1, DT(10, 26, 8, 0), DT(10, 26, 17, 0), 'P1 nao nivelar fica');
    Dates(C.Sc, P2, DT(10, 27, 8, 0), DT(10, 27, 17, 0), 'P2 sai');
    Dates(C.Sc, P3, DT(10, 28, 8, 0), DT(10, 28, 12, 0), 'P3 empurrada pela P2');
    { as duas fixas: nao resolve }
    C.Lv.Clear;
    C.Lv.SetDoNotLevel(P2, True);
    Check(not C.Lv.Level(AIDefaultLevelOptions), 'duas fixas nao resolvem');
    Check(C.Lv.UnresolvedCount = 1, 'um conflito sem solucao');
    if C.Lv.UnresolvedCount = 1 then
      Check(Pos('Ender-3 superalocado', C.Lv.Unresolved[0]) = 1, 'mensagem do conflito: ' + C.Lv.Unresolved[0]);
    T := C.Sc.Tasks[P1];
    Check(T.LevelStart = 0, 'tarefa fixa sem LevelStart');
  finally
    C.Free;
  end;
end;

procedure TestLevelManualAndSlack;
var C: TLevelCase; M, A, B, Cc: Integer; T: TAICPMTask; O: TAILevelOptions;
begin
  C := TLevelCase.Create;
  try
    M := C.L.AddResource(AINewResource('R-001', 'Laser', 1, arkWork, Cal));
    A := C.Add('A', 480);
    B := C.Add('B', 480);
    Cc := C.Add('C', 480);
    C.Link('B', 'C');
    C.Assign(A, M);
    C.Assign(Cc, M);
    { A tem margem de 1 dia; C e critica no segundo dia: nao ha conflito }
    C.Lv.Level(AIDefaultLevelOptions);
    Check(C.L.OverloadCount = 0, 'sem conflito');
    Check(C.Lv.DelayCount = 0, 'nada atrasado');
    { A com 2 dias passa a sobrepor C }
    C.Sc.Clear;
    C.G.Free;
    C.G := TAITaskGraph.Create;
    C.Sc.Graph := C.G;
    C.L.ClearAssignments;
    A := C.Add('A', 960);
    B := C.Add('B', 480);
    Cc := C.Add('C', 960);
    C.Link('B', 'C');
    C.Assign(A, M);
    C.Assign(Cc, M);
    O := AIDefaultLevelOptions;
    O.WithinSlack := True;
    Check(not C.Lv.Level(O), 'dentro da margem nao resolve');
    Dates(C.Sc, A, DT(10, 26, 8, 0), DT(10, 27, 17, 0), 'A fica (sem margem para sair)');
    Check(C.Lv.UnresolvedCount = 1, 'conflito sem solucao dentro da margem');
    Check(C.Lv.Level(AIDefaultLevelOptions), 'fora da margem resolve');
    Dates(C.Sc, Cc, DT(10, 27, 8, 0), DT(10, 28, 17, 0), 'C critica fica');
    Dates(C.Sc, A, DT(10, 29, 8, 0), DT(10, 30, 17, 0), 'A sai para depois de C');
    Check(SameT(C.Sc.ProjectFinish, DT(10, 30, 17, 0)), 'o projeto termina mais tarde');
    C.Lv.Clear;
    Check(SameT(C.Sc.ProjectFinish, DT(10, 28, 17, 0)), 'limpar: termino original');
  finally
    C.Free;
  end;
  { manual fica, a automatica sai }
  C := TLevelCase.Create;
  try
    M := C.L.AddResource(AINewResource('R-001', 'Torno', 1, arkWork, Cal));
    A := C.Add('A', 480);
    T := AINewCPMTask('B', 480);
    T.Manual := True;
    T.ManualStart := DT(10, 26, 8, 0);
    B := C.AddT(T);
    C.Assign(A, M);
    C.Assign(B, M);
    C.Lv.SetPriority(A, 1000);
    Check(C.Lv.Level(AIDefaultLevelOptions), 'manual: resolve movendo a automatica');
    Dates(C.Sc, B, DT(10, 26, 8, 0), DT(10, 26, 17, 0), 'manual fica');
    Dates(C.Sc, A, DT(10, 27, 8, 0), DT(10, 27, 17, 0), 'automatica sai mesmo com prioridade');
  finally
    C.Free;
  end;
end;

procedure TestLevelQueue;
var C: TLevelCase; M, P, I: Integer; Ids: array[0..2] of Integer;
begin
  { tres impressoes na mesma maquina viram fila }
  C := TLevelCase.Create;
  try
    M := C.L.AddResource(AINewResource('R-001', 'Ender-3', 1, arkWork, Cal));
    for I := 0 to 2 do
    begin
      Ids[I] := C.Add('P' + IntToStr(I), 480);
      C.Assign(Ids[I], M);
    end;
    Check(C.Lv.Level(AIDefaultLevelOptions), 'fila de tres');
    Dates(C.Sc, Ids[0], DT(10, 26, 8, 0), DT(10, 26, 17, 0), 'P0 dia 26');
    Dates(C.Sc, Ids[1], DT(10, 27, 8, 0), DT(10, 27, 17, 0), 'P1 dia 27');
    Dates(C.Sc, Ids[2], DT(10, 28, 8, 0), DT(10, 28, 17, 0), 'P2 dia 28');
  finally
    C.Free;
  end;
  { pessoa com 200%: duas no mesmo dia, a terceira depois }
  C := TLevelCase.Create;
  try
    P := C.L.AddResource(AINewResource('R-002', 'Ana', 2, arkWork, Cal));
    for I := 0 to 2 do
    begin
      Ids[I] := C.Add('T' + IntToStr(I), 480);
      C.Assign(Ids[I], P);
    end;
    Check(C.Lv.Level(AIDefaultLevelOptions), 'pessoa 200%');
    Dates(C.Sc, Ids[0], DT(10, 26, 8, 0), DT(10, 26, 17, 0), 'T0 dia 26');
    Dates(C.Sc, Ids[1], DT(10, 26, 8, 0), DT(10, 26, 17, 0), 'T1 dia 26');
    Dates(C.Sc, Ids[2], DT(10, 27, 8, 0), DT(10, 27, 17, 0), 'T2 dia 27');
  finally
    C.Free;
  end;
  { meio periodo: duas tarefas a 50% cabem juntas }
  C := TLevelCase.Create;
  try
    P := C.L.AddResource(AINewResource('R-002', 'Bruno', 1, arkWork, Cal));
    Ids[0] := C.Add('A', 480);
    Ids[1] := C.Add('B', 480);
    C.Assign(Ids[0], P, 0.5);
    C.Assign(Ids[1], P, 0.5);
    Check(C.Lv.Level(AIDefaultLevelOptions) and (C.Lv.DelayCount = 0), 'duas a 50% sem conflito');
  finally
    C.Free;
  end;
end;

procedure TestLevelLarge;
var C: TLevelCase; M, I: Integer; T0: QWord;
begin
  C := TLevelCase.Create;
  try
    M := C.L.AddResource(AINewResource('R-001', 'Router', 1, arkWork, Cal));
    for I := 0 to 39 do C.Assign(C.Add('X' + IntToStr(I), 240), M);
    T0 := GetTickCount64;
    Check(C.Lv.Level(AIDefaultLevelOptions), '40 tarefas na mesma maquina');
    Check(GetTickCount64 - T0 < 5000, Format('nivelar 40 tarefas em %d ms', [GetTickCount64 - T0]));
    { 40 x 4 h = 20 dias uteis }
    Check(C.Sc.ProjectFinish > DT(11, 20, 0, 0), 'fila de 20 dias: ' + S(C.Sc.ProjectFinish));
  finally
    C.Free;
  end;
end;

begin
  Passed := 0; Failed := 0;
  Names := TNames.Create;
  Cal := TAIWorkCalendar.Create('padrao');
  try
    Cal.AddBrazilianHolidays(2026, 2027);
    TestLoad;
    TestLevelTwoPrints;
    TestLevelManualAndSlack;
    TestLevelQueue;
    TestLevelLarge;
  finally
    Cal.Free;
    Names.Free;
  end;
  if Failed = 0 then
    Writeln(Format('PASS: %d checks (carga, superalocacao, calendario do recurso, nivelamento, prioridade, margem, manual, fila)', [Passed]))
  else
  begin
    Writeln(Format('FAIL: %d de %d checks', [Failed, Passed + Failed]));
    Halt(1);
  end;
end.
