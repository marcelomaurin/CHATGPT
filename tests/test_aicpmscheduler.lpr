program test_aicpmscheduler;

{ Testes de console (sem LCL) de aicpmscheduler (AI Project Core).
  Valores calculados a mao: calendario padrao (seg-sex 08-12 e 13-17) com os
  feriados do Brasil de 2026; projeto comeca segunda 26/10/2026 08:00.
  Compilar: fpc -Fu"../pacote/AI Project Core" test_aicpmscheduler.lpr }

{$mode objfpc}{$H+}

uses
  Classes, SysUtils, aiprojectduration, aitaskgraph, aiworkcalendar, aicpmscheduler;

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

procedure Dates(Sc: TAICPMScheduler; I: Integer; AStart, AFinish: TDateTime; const What: string);
var R: TAICPMResult;
begin
  R := Sc.Results[I];
  Check(SameT(R.Start, AStart) and SameT(R.Finish, AFinish),
    Format('%s: %s - %s, esperado %s - %s', [What, S(R.Start), S(R.Finish), S(AStart), S(AFinish)]));
end;

type
  TCase = class
    G: TAITaskGraph;
    Sc: TAICPMScheduler;
    constructor Create;
    destructor Destroy; override;
    function Add(const Id: string; Dur: Int64): Integer;
    function AddT(const T: TAICPMTask): Integer;
    procedure Link(const A, B: string; LT: TAITaskLinkType; const Lag: TAITaskLag);
    procedure Run;
    function HasWarning(Task: Integer; K: TAICPMWarningKind): Boolean;
  end;

constructor TCase.Create;
begin
  G := TAITaskGraph.Create;
  Sc := TAICPMScheduler.Create;
  Sc.ProjectCalendar := Cal;
  Sc.Graph := G;
  Sc.ProjectStart := DT(10, 26, 8, 0);
end;

destructor TCase.Destroy;
begin
  Sc.Free;
  G.Free;
  inherited Destroy;
end;

function TCase.AddT(const T: TAICPMTask): Integer;
begin
  G.AddNode(T.Id);
  Result := Sc.AddTask(T);
end;

function TCase.Add(const Id: string; Dur: Int64): Integer;
begin
  Result := AddT(AINewCPMTask(Id, Dur));
end;

procedure TCase.Link(const A, B: string; LT: TAITaskLinkType; const Lag: TAITaskLag);
var Err: string;
begin
  if G.AddLink(A, B, LT, Lag, Err) < 0 then raise Exception.Create(Err);
end;

procedure TCase.Run;
begin
  Sc.Run;
end;

function TCase.HasWarning(Task: Integer; K: TAICPMWarningKind): Boolean;
var I: Integer;
begin
  for I := 0 to Sc.WarningCount - 1 do
    if (Sc.Warnings[I].Task = Task) and (Sc.Warnings[I].Kind = K) then Exit(True);
  Result := False;
end;

procedure TestChain;
var C: TCase; A, B, Cc, D, W: Integer; R: TAICPMResult;
begin
  C := TCase.Create;
  try
    A := C.Add('A', 960); B := C.Add('B', 480); Cc := C.Add('C', 240);
    D := C.Add('D', 480); W := C.Add('W', 480);
    C.Link('A', 'B', atlFS, AINoLag);
    C.Link('B', 'C', atlFS, AINoLag);
    C.Link('W', 'C', atlFS, AINoLag);
    C.Run;
    Dates(C.Sc, A, DT(10, 26, 8, 0), DT(10, 27, 17, 0), 'A 2d');
    Dates(C.Sc, B, DT(10, 28, 8, 0), DT(10, 28, 17, 0), 'B comeca no dia seguinte 08:00');
    Dates(C.Sc, Cc, DT(10, 29, 8, 0), DT(10, 29, 12, 0), 'C 4h');
    Check(SameT(C.Sc.ProjectFinish, DT(10, 29, 12, 0)), 'termino do projeto 29/10 12:00');
    Check(C.Sc.Results[A].Critical and C.Sc.Results[B].Critical and C.Sc.Results[Cc].Critical, 'A, B e C criticas');
    Check(C.Sc.Results[A].TotalSlack = 0, 'margem de A zero');
    R := C.Sc.Results[D];
    Check(not R.Critical and (R.TotalSlack = 1200) and (R.FreeSlack = 1200), Format('D margem total/livre 1200: %d/%d', [R.TotalSlack, R.FreeSlack]));
    Check(SameT(R.LateStart, DT(10, 28, 13, 0)) and SameT(R.LateFinish, DT(10, 29, 12, 0)), 'D inicio/termino tarde: ' + S(R.LateStart) + ' ' + S(R.LateFinish));
    R := C.Sc.Results[W];
    Check((R.TotalSlack = 960) and (R.FreeSlack = 960), Format('W margem 960 (espera B): %d/%d', [R.TotalSlack, R.FreeSlack]));
    Check(C.Sc.WarningCount = 0, 'sem avisos');
  finally
    C.Free;
  end;
end;

procedure TestLinkTypes;
var C: TCase; E, F, G, J, K, P, M: Integer; T: TAICPMTask;
begin
  C := TCase.Create;
  try
    C.Add('A', 960);
    E := C.Add('E', 480); C.Link('A', 'E', atlSS, AIMakeLag(120, aduHour));
    F := C.Add('F', 480); C.Link('A', 'F', atlFF, AINoLag);
    G := C.Add('G', 480); C.Link('A', 'G', atlSF, AINoLag);
    J := C.Add('J', 960); C.Link('A', 'J', atlFS, AIMakeLag(960, aduDay));
    K := C.Add('K', 480); C.Link('A', 'K', atlFS, AIMakePercentLag(-50));
    T := AINewCPMTask('P', 14 * 60); T.Elapsed := True;
    P := C.AddT(T); C.Link('A', 'P', atlFS, AINoLag);
    M := C.Add('M', 0); C.Link('A', 'M', atlFS, AINoLag);
    C.Run;
    Dates(C.Sc, E, DT(10, 26, 10, 0), DT(10, 27, 10, 0), 'II +2h');
    Dates(C.Sc, F, DT(10, 27, 8, 0), DT(10, 27, 17, 0), 'TT termina junto com A');
    Dates(C.Sc, G, DT(10, 26, 8, 0), DT(10, 26, 17, 0), 'IT limitado ao inicio do projeto');
    Dates(C.Sc, J, DT(10, 30, 8, 0), DT(11, 3, 17, 0), 'TI +2d atravessa fim de semana e Finados');
    Dates(C.Sc, K, DT(10, 27, 8, 0), DT(10, 27, 17, 0), 'TI -50% (antecipacao de 1d)');
    Dates(C.Sc, P, DT(10, 27, 17, 0), DT(10, 28, 7, 0), 'impressao decorrida de 14 h atravessa a noite');
    Dates(C.Sc, M, DT(10, 27, 17, 0), DT(10, 27, 17, 0), 'marco no termino da predecessora');
    Check(C.Sc.Results[J].Critical, 'J define o fim do projeto');
  finally
    C.Free;
  end;
end;

procedure TestElapsedLag;
var C: TCase; H: Integer;
begin
  C := TCase.Create;
  try
    C.Add('A', 960);
    H := C.Add('H', 480);
    { cura de 24 h corridas depois de A }
    C.Link('A', 'H', atlFS, AIMakeLag(1440, aduHour, True));
    C.Run;
    Dates(C.Sc, H, DT(10, 29, 8, 0), DT(10, 29, 17, 0), 'latencia decorrida de 24 h');
  finally
    C.Free;
  end;
end;

procedure TestConstraints;
var C: TCase; A, D, Q, R_, Mf, Tt, U, V: Integer; T: TAICPMTask;
begin
  C := TCase.Create;
  try
    A := C.Add('A', 960);
    C.Add('B', 480); C.Link('A', 'B', atlFS, AINoLag);
    T := AINewCPMTask('D', 480); T.Constraint := actSNET; T.ConstraintDate := DT(10, 27, 8, 0);
    D := C.AddT(T);
    T := AINewCPMTask('Q', 480); T.Constraint := actMSO; T.ConstraintDate := DT(10, 26, 8, 0);
    Q := C.AddT(T); C.Link('A', 'Q', atlFS, AINoLag);
    T := AINewCPMTask('R', 480); T.Constraint := actFNET; T.ConstraintDate := DT(10, 28, 17, 0);
    R_ := C.AddT(T);
    T := AINewCPMTask('Mf', 240); T.Constraint := actMFO; T.ConstraintDate := DT(10, 28, 12, 0);
    Mf := C.AddT(T);
    T := AINewCPMTask('T', 480); T.Constraint := actSNLT; T.ConstraintDate := DT(10, 26, 8, 0);
    Tt := C.AddT(T); C.Link('A', 'T', atlFS, AINoLag);
    T := AINewCPMTask('U', 480); T.Manual := True; T.ManualStart := DT(10, 26, 8, 0);
    U := C.AddT(T); C.Link('A', 'U', atlFS, AINoLag);
    T := AINewCPMTask('V', 480); T.Constraint := actALAP;
    V := C.AddT(T);
    C.Run;
    Dates(C.Sc, D, DT(10, 27, 8, 0), DT(10, 27, 17, 0), 'SNET empurra');
    Dates(C.Sc, Q, DT(10, 26, 8, 0), DT(10, 26, 17, 0), 'MSO fixa o inicio');
    Check(C.HasWarning(Q, cwkConstraintConflict), 'MSO em conflito com o vinculo gera aviso');
    Dates(C.Sc, R_, DT(10, 28, 8, 0), DT(10, 28, 17, 0), 'FNET');
    Dates(C.Sc, Mf, DT(10, 28, 8, 0), DT(10, 28, 12, 0), 'MFO fixa o termino');
    Check(not C.HasWarning(Mf, cwkConstraintConflict), 'MFO sem vinculo nao conflita');
    Check(C.HasWarning(Tt, cwkLateConstraintMissed), 'SNLT nao atendido gera aviso');
    Dates(C.Sc, U, DT(10, 26, 8, 0), DT(10, 26, 17, 0), 'manual fica onde foi posto');
    Check(C.HasWarning(U, cwkManualConflict), 'manual em conflito gera aviso');
    { projeto termina 28/10 17:00 (B, R, T); V tem 2 dias de folga e vai para o fim }
    Check(SameT(C.Sc.ProjectFinish, DT(10, 28, 17, 0)), 'termino do projeto: ' + S(C.Sc.ProjectFinish));
    Dates(C.Sc, V, DT(10, 28, 8, 0), DT(10, 28, 17, 0), 'ALAP vai para o fim da folga');
    Check(SameT(C.Sc.Results[V].EarlyStart, DT(10, 26, 8, 0)), 'ALAP mantem o inicio cedo calculado');
    Check(C.Sc.Results[A].Critical, 'A critica');
  finally
    C.Free;
  end;
end;

procedure TestDeadline;
var C: TCase; A, B, Cc: Integer; T: TAICPMTask;
begin
  C := TCase.Create;
  try
    A := C.Add('A', 960); B := C.Add('B', 480);
    T := AINewCPMTask('C', 240); T.Deadline := DT(10, 28, 17, 0);
    Cc := C.AddT(T);
    C.Link('A', 'B', atlFS, AINoLag);
    C.Link('B', 'C', atlFS, AINoLag);
    C.Run;
    Dates(C.Sc, Cc, DT(10, 29, 8, 0), DT(10, 29, 12, 0), 'data limite nao move a tarefa');
    Check(C.HasWarning(Cc, cwkDeadlineMissed), 'aviso de data limite');
    Check(C.Sc.Results[Cc].TotalSlack = -240, Format('margem negativa de C: %d', [C.Sc.Results[Cc].TotalSlack]));
    Check(C.Sc.Results[B].TotalSlack = -240, Format('a margem negativa propaga: %d', [C.Sc.Results[B].TotalSlack]));
    Check(C.HasWarning(A, cwkNegativeSlack) and C.Sc.Results[A].Critical, 'A com margem negativa e critica');
    Check(C.Sc.Results[Cc].FreeSlack = 0, 'margem livre nunca negativa');
  finally
    C.Free;
  end;
end;

procedure TestSummary;
var C: TCase; Sm, A, B, Cc, Empty: Integer; T: TAICPMTask; Raised: Boolean;
begin
  C := TCase.Create;
  try
    T := AINewCPMTask('S', 0); T.IsSummary := True;
    Sm := C.AddT(T);
    T := AINewCPMTask('A', 960); T.Parent := Sm; A := C.AddT(T);
    T := AINewCPMTask('B', 480); T.Parent := Sm; B := C.AddT(T);
    Cc := C.Add('C', 480);
    T := AINewCPMTask('Vazio', 0); T.IsSummary := True; Empty := C.AddT(T);
    C.Link('A', 'B', atlFS, AINoLag);
    C.Link('B', 'C', atlFS, AINoLag);
    C.Run;
    Dates(C.Sc, Sm, DT(10, 26, 8, 0), DT(10, 28, 17, 0), 'resumo consolida as filhas');
    Check(C.Sc.Results[Sm].Critical, 'resumo critico');
    Dates(C.Sc, Cc, DT(10, 29, 8, 0), DT(10, 29, 17, 0), 'C depois do resumo');
    Dates(C.Sc, Empty, DT(10, 26, 8, 0), DT(10, 26, 8, 0), 'resumo vazio no inicio do projeto');
    Check(A + B >= 0, 'indices');
  finally
    C.Free;
  end;
  { erros de uso }
  C := TCase.Create;
  try
    T := AINewCPMTask('S', 0); T.IsSummary := True; C.AddT(T);
    C.Add('X', 60);
    C.Link('S', 'X', atlFS, AINoLag);
    Raised := False;
    try C.Run; except on EAICPMScheduler do Raised := True; end;
    Check(Raised, 'resumo com vinculo direto e recusado');
  finally
    C.Free;
  end;
  C := TCase.Create;
  try
    C.Add('X', 60);
    C.G.AddNode('sobrando');
    Raised := False;
    try C.Run; except on EAICPMScheduler do Raised := True; end;
    Check(Raised, 'grafo com mais nos que tarefas e recusado');
  finally
    C.Free;
  end;
end;

procedure TestLarge;
var C: TCase; I: Integer; T0: QWord; Err: string;
begin
  RandSeed := 7;
  C := TCase.Create;
  try
    for I := 0 to 1999 do C.Add('T' + IntToStr(I), 60 + Random(2000));
    for I := 1 to 4000 do
      C.G.AddLink(C.G.NodeIds[Random(1990)], C.G.NodeIds[1990 + Random(10)], TAITaskLinkType(Random(4)), AINoLag, Err);
    for I := 1 to 2000 do
      C.G.AddLink(C.G.NodeIds[Random(2000)], C.G.NodeIds[Random(2000)], atlFS, AINoLag, Err);
    T0 := GetTickCount64;
    C.Run;
    Check(GetTickCount64 - T0 < 2000, Format('2000 tarefas e %d vinculos em %d ms', [C.G.LinkCount, GetTickCount64 - T0]));
    Check(C.Sc.ProjectFinish > C.Sc.ProjectStart, 'projeto grande calculado');
  finally
    C.Free;
  end;
end;

begin
  Passed := 0; Failed := 0;
  Cal := TAIWorkCalendar.Create('padrao');
  try
    Cal.AddBrazilianHolidays(2026, 2027);
    TestChain;
    TestLinkTypes;
    TestElapsedLag;
    TestConstraints;
    TestDeadline;
    TestSummary;
    TestLarge;
  finally
    Cal.Free;
  end;
  if Failed = 0 then
    Writeln(Format('PASS: %d checks (cadeia, TI/II/TT/IT, latencias, restricoes, data limite, ALAP, manual, resumos, 2000 tarefas)', [Passed]))
  else
  begin
    Writeln(Format('FAIL: %d de %d checks', [Failed, Passed + Failed]));
    Halt(1);
  end;
end.
