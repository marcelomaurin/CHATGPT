program test_aitaskgraph;

{ Testes de console (sem LCL) de aitaskgraph (AI Project Core): vinculos
  FS/SS/FF/SF, latencia, recusa de ciclo com caminho, ordem topologica,
  cadeias, relacao em cadeia x paralelo e coluna Predecessoras.
  Compilar: fpc -Fu"../pacote/AI Project Core" test_aitaskgraph.lpr }

{$mode objfpc}{$H+}

uses
  Classes, SysUtils, aiprojectduration, aitaskgraph;

type
  TKnownIds = class
    Ids: TStringList;
    constructor Create(const AIds: array of string);
    destructor Destroy; override;
    function Exists(const AId: string): Boolean;
  end;

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

constructor TKnownIds.Create(const AIds: array of string);
var S: string;
begin
  Ids := TStringList.Create;
  Ids.CaseSensitive := False;
  for S in AIds do Ids.Add(S);
end;

destructor TKnownIds.Destroy;
begin
  Ids.Free;
  inherited Destroy;
end;

function TKnownIds.Exists(const AId: string): Boolean;
begin
  Result := Ids.IndexOf(AId) >= 0;
end;

function OrderValid(G: TAITaskGraph; const O: TAIIntArray): Boolean;
var Pos_: TAIIntArray; I: Integer; L: TAITaskLink;
begin
  Result := Length(O) = G.NodeCount;
  if not Result then Exit;
  SetLength(Pos_, G.NodeCount);
  for I := 0 to High(O) do Pos_[O[I]] := I;
  for I := 0 to G.LinkCount - 1 do
  begin
    L := G.Links[I];
    if Pos_[L.FromNode] >= Pos_[L.ToNode] then Exit(False);
  end;
end;

function Ids(G: TAITaskGraph; const A: TAIIntArray): string;
var I: Integer;
begin
  Result := '';
  for I := 0 to High(A) do
  begin
    if I > 0 then Result := Result + ',';
    Result := Result + G.NodeIds[A[I]];
  end;
end;

procedure TestBasics;
var G: TAITaskGraph; Err: string; L: Integer;
begin
  G := TAITaskGraph.Create;
  try
    G.AddNode('A'); G.AddNode('B'); G.AddNode('C'); G.AddNode('D');
    Check(G.NodeCount = 4, '4 nos');
    Check(G.IndexOfNode('c') = 2, 'busca sem diferenciar maiusculas');
    L := G.AddLink('A', 'B', atlFS, AINoLag, Err);
    Check(L = 0, 'A -> B');
    Check(G.AddLink('B', 'C', atlSS, AIMakeLag(120, aduHour), Err) = 1, 'B -> C II +2h');
    Check(G.AddLink('A', 'A', atlFS, AINoLag, Err) < 0, 'recusa auto-vinculo');
    Check(Pos('si mesma', Err) > 0, 'mensagem de auto-vinculo: ' + Err);
    Check(G.AddLink('A', 'B', atlSS, AINoLag, Err) < 0, 'recusa duplicado');
    Check(G.AddLink('A', 'X', atlFS, AINoLag, Err) < 0, 'recusa no inexistente');
    Check(G.AddLink('C', 'A', atlFS, AINoLag, Err) < 0, 'recusa ciclo');
    Check(Pos('C -> A -> B -> C', Err) > 0, 'caminho do ciclo: ' + Err);
    Check(G.LinkCount = 2, 'ciclo nao entra no grafo');
    Check(G.Relation('A', 'C') = atrPredecessor, 'A antes de C (em cadeia)');
    Check(G.Relation('C', 'A') = atrSuccessor, 'C depois de A');
    Check(G.Relation('A', 'D') = atrParallel, 'A e D em paralelo');
    Check(G.Relation('B', 'B') = atrSame, 'mesma tarefa');
    Check(Ids(G, G.TopologicalOrder) = 'A,B,C,D', 'ordem topologica deterministica');
    Check(Ids(G, G.AllSuccessors(0)) = 'B,C', 'todas as sucessoras de A');
    Check(Ids(G, G.AllPredecessors(2)) = 'A,B', 'todas as predecessoras de C');
    Check(Ids(G, G.SuccessorNodes(0)) = 'B', 'sucessora direta');
    Check(Ids(G, G.PredecessorNodes(2)) = 'B', 'predecessora direta');
    Check(G.ComponentCount = 2, 'duas cadeias: {A,B,C} e {D}');
    Check((G.ComponentOf(0) = G.ComponentOf(2)) and (G.ComponentOf(3) <> G.ComponentOf(0)), 'cadeia de cada no');
    Check(Ids(G, G.ComponentNodes(1)) = 'D', 'nos da segunda cadeia');
    Check(G.IndexOfLink('B', 'C') = 1, 'busca de vinculo');
    G.DeleteLink(0);
    Check((G.LinkCount = 1) and (G.Links[0].FromId = 'B'), 'excluir vinculo reindexa');
    Check(G.ComponentCount = 3, 'cadeias recalculadas: {A} {B,C} {D}');
    Check(G.AddLink('C', 'A', atlFS, AINoLag, Err) = 1, 'sem A -> B o vinculo C -> A e valido');
    Check(G.Links[1].ToNode = 0, 'indices dos nos no vinculo');
  finally
    G.Free;
  end;
end;

procedure TestRandom;
var
  G: TAITaskGraph;
  I, A, B, Added, Refused: Integer;
  Err: string;
  O: TAIIntArray;
  T0: QWord;
begin
  RandSeed := 20261020;
  G := TAITaskGraph.Create;
  try
    for I := 0 to 999 do G.AddNode('T-' + Format('%.4d', [I + 1]));
    Added := 0; Refused := 0;
    T0 := GetTickCount64;
    for I := 1 to 3000 do
    begin
      A := Random(1000); B := Random(1000);
      if G.AddLink(G.NodeIds[A], G.NodeIds[B], TAITaskLinkType(Random(4)), AINoLag, Err) >= 0 then
        Inc(Added)
      else Inc(Refused);
    end;
    O := G.TopologicalOrder;
    Check(OrderValid(G, O), 'ordem topologica valida com 1000 tarefas');
    Check((Added > 1000) and (Refused > 0), Format('aleatorio: %d aceitos, %d recusados', [Added, Refused]));
    Check(GetTickCount64 - T0 < 5000, 'tempo razoavel para 3000 tentativas');
  finally
    G.Free;
  end;
end;

procedure TestLag;
var L: TAITaskLag; Err: string;
begin
  Check(AITryParseLag('+2h', 480, 2400, L, Err) and (L.Minutes = 120) and (L.DisplayUnit = aduHour), '+2h');
  Check(AITryParseLag('-1d', 480, 2400, L, Err) and (L.Minutes = -480), 'antecipacao -1d');
  Check(AITryParseLag('24eh', 480, 2400, L, Err) and L.Elapsed and (L.Minutes = 1440), 'latencia decorrida (cura)');
  Check(AITryParseLag('-10%', 480, 2400, L, Err) and L.IsPercent and (L.Percent = -10), 'antecipacao -10%');
  Check(AILagMinutes(AIMakePercentLag(50), 960) = 480, '50% de 2d = 1d');
  Check(AITryParseLag('', 480, 2400, L, Err) and (L.Minutes = 0) and not L.IsPercent, 'sem latencia');
  Check(not AITryParseLag('+abc', 480, 2400, L, Err), 'recusa latencia invalida');
  Check(not AITryParseLag('10.5%', 480, 2400, L, Err), 'recusa % fracionaria');
  Check(AIFormatLag(AIMakeLag(-480, aduDay), 480, 2400) = '-1d', 'formata -1d');
  Check(AIFormatLag(AIMakeLag(1440, aduHour, True), 480, 2400) = '+24eh', 'formata +24eh');
  Check(AIFormatLag(AIMakePercentLag(25), 480, 2400) = '+25%', 'formata +25%');
  Check(AIFormatLag(AINoLag, 480, 2400) = '', 'sem latencia vazio');
  Check(AISameLag(AIMakeLag(60, aduHour), AIMakeLag(60, aduHour)) and
    not AISameLag(AIMakeLag(60, aduHour), AIMakePercentLag(60)), 'comparacao de latencias');
end;

procedure TestPredecessors;
var
  K: TKnownIds;
  Items: TAIPredecessorItems;
  Err, S: string;
  T: TAITaskLinkType;
  I: Integer;
begin
  K := TKnownIds.Create(['T-0003', 'T-0004', 'M-0012', 'T-0010', '7']);
  try
    Check(AITryParsePredecessors('T-0003TI+2h;T-0004II-10%; M-0012 ; 7', 480, 2400, @K.Exists, Items, Err),
      'coluna completa: ' + Err);
    Check(Length(Items) = 4, '4 predecessoras');
    Check((Items[0].Id = 'T-0003') and (Items[0].LinkType = atlFS) and (Items[0].Lag.Minutes = 120), 'T-0003TI+2h');
    Check((Items[1].Id = 'T-0004') and (Items[1].LinkType = atlSS) and (Items[1].Lag.Percent = -10), 'T-0004II-10%');
    Check((Items[2].Id = 'M-0012') and (Items[2].LinkType = atlFS) and (Items[2].Lag.Minutes = 0), 'ID sozinho = TI');
    Check(Items[3].Id = '7', 'ID numerico');
    Check(AITryParsePredecessors('t-0010ff, T-0003sf+1d', 480, 2400, @K.Exists, Items, Err) and
      (Items[0].Id = 't-0010') and (Items[0].LinkType = atlFF) and (Items[1].LinkType = atlSF),
      'virgula, minusculas e codigos em ingles: ' + Err);
    Check(not AITryParsePredecessors('T-0099', 480, 2400, @K.Exists, Items, Err) and (Pos('desconhecida', Err) > 0),
      'recusa ID desconhecido: ' + Err);
    Check(not AITryParsePredecessors('T-0003;T-0003TT', 480, 2400, @K.Exists, Items, Err) and (Pos('repetida', Err) > 0),
      'recusa repetida: ' + Err);
    Check(not AITryParsePredecessors('T-0003TI+xyz', 480, 2400, @K.Exists, Items, Err) and (Pos('latencia', Err) > 0),
      'recusa latencia invalida: ' + Err);
    Check(AITryParsePredecessors('', 480, 2400, @K.Exists, Items, Err) and (Length(Items) = 0), 'vazio = sem predecessoras');
    { sem lista de IDs: separa pelo codigo }
    Check(AITryParsePredecessors('ABCII+1h', 480, 2400, nil, Items, Err) and (Items[0].Id = 'ABC') and
      (Items[0].LinkType = atlSS), 'sem verificador de IDs');
    { ida e volta pela formatacao }
    Check(AITryParsePredecessors('T-0003TI+2h;T-0004II-10%;M-0012;T-0010TT-1ed', 480, 2400, @K.Exists, Items, Err), 'para formatar');
    S := '';
    for I := 0 to High(Items) do
    begin
      if I > 0 then S := S + ';';
      S := S + AIFormatPredecessor(Items[I], 480, 2400);
    end;
    Check(S = 'T-0003TI+2h;T-0004II-10%;M-0012;T-0010TT-1ed', 'formatacao: ' + S);
    Check(AIFormatPredecessor(Items[1], 480, 2400, False) = 'T-0004SS-10%', 'codigo em ingles');
    Check(AITryLinkTypeFromCode('it', T) and (T = atlSF) and not AITryLinkTypeFromCode('XX', T), 'codigos');
    Check(AILinkTypeCode(atlFF) = 'TT', 'codigo TT');
  finally
    K.Free;
  end;
end;

begin
  Passed := 0; Failed := 0;
  TestBasics;
  TestRandom;
  TestLag;
  TestPredecessors;
  if Failed = 0 then
    Writeln(Format('PASS: %d checks (vinculos, ciclo, ordem topologica, cadeias, latencia, predecessoras)', [Passed]))
  else
  begin
    Writeln(Format('FAIL: %d de %d checks', [Failed, Passed + Failed]));
    Halt(1);
  end;
end.
