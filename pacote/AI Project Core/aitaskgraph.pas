unit aitaskgraph;

{ Lazarus AI Suite - AI Project Core
  Grafo de dependencias entre tarefas (generico, sem LCL).

  - Nos identificados por texto (ID da tarefa), na ordem de insercao.
  - Vinculos no estilo do Microsoft Project: FS/SS/FF/SF (em portugues
    TI/II/TT/IT), com latencia em duracao ou em % da predecessora; latencia
    negativa = antecipacao; latencia decorrida opcional.
  - Lista de adjacencia (sucessoras e predecessoras por no).
  - O grafo e sempre aciclico: AddLink recusa o vinculo que fecha um ciclo e
    devolve o caminho (A -> B -> C -> A) para a mensagem.
  - Ordem topologica deterministica (Kahn; empate pela ordem de insercao).
  - Componentes conexos (as "cadeias") e relacao entre duas tarefas:
    em cadeia (existe caminho) ou em paralelo (nao existe caminho).
  - Sintaxe da coluna Predecessoras: "T-0003TI+2h;T-0004II-10%;7".

  O grafo nao conhece datas: o calculo do cronograma (CPM) usa este grafo. }

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, aiprojectduration;

type
  EAITaskGraph = class(Exception);

  TAITaskLinkType = (atlFS, atlSS, atlFF, atlSF);

  TAITaskRelation = (atrSame, atrPredecessor, atrSuccessor, atrParallel);

  TAIIntArray = array of Integer;
  TAIStrArray = array of string;

  { latencia: em minutos (pode ser negativa) ou em % da duracao da predecessora }
  TAITaskLag = record
    Minutes: Int64;
    DisplayUnit: TAIDurationUnit;
    Elapsed: Boolean;
    IsPercent: Boolean;
    Percent: Integer;
  end;

  TAITaskLink = record
    FromId, ToId: string;
    FromNode, ToNode: Integer;
    LinkType: TAITaskLinkType;
    Lag: TAITaskLag;
    { dado livre do usuario (ex.: indice do vinculo no documento) }
    Tag: PtrInt;
  end;

  { uma entrada da coluna Predecessoras }
  TAIPredecessorItem = record
    Id: string;
    LinkType: TAITaskLinkType;
    Lag: TAITaskLag;
  end;
  TAIPredecessorItems = array of TAIPredecessorItem;

  { informa se um ID existe (ajuda a separar "T-0003" de "T" + "-0003") }
  TAIIdExistsFunc = function(const AId: string): Boolean of object;

  TAITaskGraph = class
  private
    FIds: TStringList;           // ordem de insercao
    FIndex: TStringList;         // ordenado, Objects = indice
    FLinks: array of TAITaskLink;
    FSucc, FPred: array of TAIIntArray;  // indices de vinculos
    FComp: TAIIntArray;
    FCompCount: Integer;
    FCompValid: Boolean;
    function GetNodeCount: Integer;
    function GetLinkCount: Integer;
    function GetLink(I: Integer): TAITaskLink;
    function GetNodeId(I: Integer): string;
    procedure BuildComponents;
    function PathBetween(AFrom, ATo: Integer): TAIIntArray;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Clear;
    function AddNode(const AId: string): Integer;
    function IndexOfNode(const AId: string): Integer;
    function HasNode(const AId: string): Boolean;
    { -1 e Err preenchido quando: no inexistente, auto-vinculo, duplicado ou ciclo }
    function AddLink(const AFromId, AToId: string; AType: TAITaskLinkType;
      const ALag: TAITaskLag; out Err: string; ATag: PtrInt = 0): Integer;
    function CanLink(const AFromId, AToId: string; out Err: string): Boolean;
    function IndexOfLink(const AFromId, AToId: string): Integer;
    procedure DeleteLink(I: Integer);
    function CyclePath(const AFromId, AToId: string): TAIStrArray;

    function Successors(ANode: Integer): TAIIntArray;    // indices de vinculos
    function Predecessors(ANode: Integer): TAIIntArray;  // indices de vinculos
    function SuccessorNodes(ANode: Integer): TAIIntArray;
    function PredecessorNodes(ANode: Integer): TAIIntArray;
    function TopologicalOrder: TAIIntArray;
    function Reaches(AFrom, ATo: Integer): Boolean;
    function Relation(const AId, BId: string): TAITaskRelation;
    function AllPredecessors(ANode: Integer): TAIIntArray;
    function AllSuccessors(ANode: Integer): TAIIntArray;

    { cadeias = componentes conexos sem considerar o sentido dos vinculos }
    function ComponentCount: Integer;
    function ComponentOf(ANode: Integer): Integer;
    function ComponentNodes(AComp: Integer): TAIIntArray;

    property NodeCount: Integer read GetNodeCount;
    property NodeIds[I: Integer]: string read GetNodeId;
    property LinkCount: Integer read GetLinkCount;
    property Links[I: Integer]: TAITaskLink read GetLink;
  end;

function AINoLag: TAITaskLag;
function AIMakeLag(AMinutes: Int64; AUnit: TAIDurationUnit = aduDay; AElapsed: Boolean = False): TAITaskLag;
function AIMakePercentLag(APercent: Integer): TAITaskLag;
function AISameLag(const A, B: TAITaskLag): Boolean;
function AILagMinutes(const ALag: TAITaskLag; PredecessorMinutes: Int64): Int64;

function AILinkTypeCode(T: TAITaskLinkType; Portuguese: Boolean = True): string;
function AITryLinkTypeFromCode(const S: string; out T: TAITaskLinkType): Boolean;

function AITryParseLag(const S: string; MinutesPerDay, MinutesPerWeek: Integer;
  out L: TAITaskLag; out Err: string): Boolean;
function AIFormatLag(const L: TAITaskLag; MinutesPerDay, MinutesPerWeek: Integer): string;

function AITryParsePredecessors(const S: string; MinutesPerDay, MinutesPerWeek: Integer;
  IdExists: TAIIdExistsFunc; out Items: TAIPredecessorItems; out Err: string): Boolean;
function AIFormatPredecessor(const Item: TAIPredecessorItem; MinutesPerDay, MinutesPerWeek: Integer;
  Portuguese: Boolean = True): string;

implementation

const
  CODES_PT: array[TAITaskLinkType] of string = ('TI', 'II', 'TT', 'IT');
  CODES_EN: array[TAITaskLinkType] of string = ('FS', 'SS', 'FF', 'SF');

{ ---------------- latencia ---------------- }

function AINoLag: TAITaskLag;
begin
  Result.Minutes := 0;
  Result.DisplayUnit := aduDay;
  Result.Elapsed := False;
  Result.IsPercent := False;
  Result.Percent := 0;
end;

function AIMakeLag(AMinutes: Int64; AUnit: TAIDurationUnit; AElapsed: Boolean): TAITaskLag;
begin
  Result := AINoLag;
  Result.Minutes := AMinutes;
  Result.DisplayUnit := AUnit;
  Result.Elapsed := AElapsed;
end;

function AIMakePercentLag(APercent: Integer): TAITaskLag;
begin
  Result := AINoLag;
  Result.IsPercent := True;
  Result.Percent := APercent;
end;

function AISameLag(const A, B: TAITaskLag): Boolean;
begin
  if A.IsPercent <> B.IsPercent then Exit(False);
  if A.IsPercent then Exit(A.Percent = B.Percent);
  Result := (A.Minutes = B.Minutes) and (A.DisplayUnit = B.DisplayUnit) and (A.Elapsed = B.Elapsed);
end;

function AILagMinutes(const ALag: TAITaskLag; PredecessorMinutes: Int64): Int64;
begin
  if ALag.IsPercent then
    Result := Round(PredecessorMinutes * ALag.Percent / 100)
  else
    Result := ALag.Minutes;
end;

function AILinkTypeCode(T: TAITaskLinkType; Portuguese: Boolean): string;
begin
  if Portuguese then Result := CODES_PT[T] else Result := CODES_EN[T];
end;

function AITryLinkTypeFromCode(const S: string; out T: TAITaskLinkType): Boolean;
var I: TAITaskLinkType; U: string;
begin
  U := UpperCase(Trim(S));
  for I := Low(I) to High(I) do
    if (U = CODES_PT[I]) or (U = CODES_EN[I]) then begin T := I; Exit(True); end;
  T := atlFS;
  Result := False;
end;

function AITryParseLag(const S: string; MinutesPerDay, MinutesPerWeek: Integer;
  out L: TAITaskLag; out Err: string): Boolean;
var
  T: string;
  Neg: Boolean;
  D: TAIDuration;
  P: Integer;
begin
  L := AINoLag;
  Err := '';
  T := StringReplace(Trim(S), ' ', '', [rfReplaceAll]);
  if T = '' then Exit(True);
  Neg := T[1] = '-';
  if T[1] in ['+', '-'] then Delete(T, 1, 1);
  if T = '' then
  begin
    Err := 'latencia sem valor: "' + S + '"';
    Exit(False);
  end;
  if T[Length(T)] = '%' then
  begin
    if not TryStrToInt(Copy(T, 1, Length(T) - 1), P) or (P > 100000) then
    begin
      Err := 'latencia em % invalida: "' + S + '" (use inteiro, ex.: -10%)';
      Exit(False);
    end;
    if Neg then P := -P;
    L := AIMakePercentLag(P);
    Exit(True);
  end;
  if not AITryParseDuration(T, MinutesPerDay, MinutesPerWeek, D, Err) then
  begin
    Err := 'latencia: ' + Err;
    Exit(False);
  end;
  L := AIMakeLag(D.Minutes, D.DisplayUnit, D.Elapsed);
  if Neg then L.Minutes := -L.Minutes;
  Result := True;
end;

function AIFormatLag(const L: TAITaskLag; MinutesPerDay, MinutesPerWeek: Integer): string;
var D: TAIDuration;
begin
  if L.IsPercent then
  begin
    if L.Percent = 0 then Exit('');
    if L.Percent > 0 then Result := '+' else Result := '-';
    Exit(Result + IntToStr(Abs(L.Percent)) + '%');
  end;
  if L.Minutes = 0 then Exit('');
  D := AIMakeDuration(Abs(L.Minutes), L.DisplayUnit, L.Elapsed);
  if L.Minutes > 0 then Result := '+' else Result := '-';
  Result := Result + AIFormatDuration(D, MinutesPerDay, MinutesPerWeek);
end;

{ ---------------- coluna Predecessoras ---------------- }

function ParseItem(const Raw: string; MinutesPerDay, MinutesPerWeek: Integer;
  IdExists: TAIIdExistsFunc; out Item: TAIPredecessorItem; out Err: string): Boolean;
var
  S, IdPart, Rest, LagErr: string;
  P: Integer;
  T: TAITaskLinkType;
  L: TAITaskLag;
  Found: Boolean;
begin
  Result := False;
  Err := '';
  S := Trim(Raw);
  Item.Id := S;
  Item.LinkType := atlFS;
  Item.Lag := AINoLag;
  { o item inteiro e um ID conhecido: TI sem latencia }
  if Assigned(IdExists) and IdExists(S) then Exit(True);
  { procura, da direita para a esquerda, "<codigo>[+|-latencia]" no fim }
  Found := False;
  for P := Length(S) - 1 downto 2 do
  begin
    if not AITryLinkTypeFromCode(Copy(S, P, 2), T) then Continue;
    Rest := Copy(S, P + 2, MaxInt);
    if (Rest <> '') and not (Rest[1] in ['+', '-']) then Continue;
    IdPart := Trim(Copy(S, 1, P - 1));
    if IdPart = '' then Continue;
    if Assigned(IdExists) and not IdExists(IdPart) then Continue;
    if not AITryParseLag(Rest, MinutesPerDay, MinutesPerWeek, L, LagErr) then
    begin
      Err := Format('"%s": %s', [S, LagErr]);
      Exit(False);
    end;
    Item.Id := IdPart;
    Item.LinkType := T;
    Item.Lag := L;
    Found := True;
    Break;
  end;
  if not Found then
  begin
    if Assigned(IdExists) then
    begin
      Err := Format('predecessora desconhecida: "%s"', [S]);
      Exit(False);
    end;
    Item.Id := S;
  end;
  Result := Item.Id <> '';
  if not Result then Err := 'predecessora vazia';
end;

function AITryParsePredecessors(const S: string; MinutesPerDay, MinutesPerWeek: Integer;
  IdExists: TAIIdExistsFunc; out Items: TAIPredecessorItems; out Err: string): Boolean;
var
  Parts: TStringList;
  I, J: Integer;
  Item: TAIPredecessorItem;
begin
  Items := nil;
  Err := '';
  Parts := TStringList.Create;
  try
    Parts.StrictDelimiter := True;
    Parts.Delimiter := ';';
    Parts.DelimitedText := StringReplace(S, ',', ';', [rfReplaceAll]);
    for I := 0 to Parts.Count - 1 do
    begin
      if Trim(Parts[I]) = '' then Continue;
      if not ParseItem(Parts[I], MinutesPerDay, MinutesPerWeek, IdExists, Item, Err) then
        Exit(False);
      for J := 0 to High(Items) do
        if SameText(Items[J].Id, Item.Id) then
        begin
          Err := Format('predecessora repetida: %s', [Item.Id]);
          Exit(False);
        end;
      SetLength(Items, Length(Items) + 1);
      Items[High(Items)] := Item;
    end;
  finally
    Parts.Free;
  end;
  Result := True;
end;

function AIFormatPredecessor(const Item: TAIPredecessorItem; MinutesPerDay, MinutesPerWeek: Integer;
  Portuguese: Boolean): string;
var Lag: string;
begin
  Lag := AIFormatLag(Item.Lag, MinutesPerDay, MinutesPerWeek);
  if (Item.LinkType = atlFS) and (Lag = '') then Exit(Item.Id);
  Result := Item.Id + AILinkTypeCode(Item.LinkType, Portuguese) + Lag;
end;

{ ---------------- TAITaskGraph ---------------- }

constructor TAITaskGraph.Create;
begin
  inherited Create;
  FIds := TStringList.Create;
  FIndex := TStringList.Create;
  FIndex.Sorted := True;
  FIndex.CaseSensitive := False;
  FIndex.Duplicates := dupError;
end;

destructor TAITaskGraph.Destroy;
begin
  FIds.Free;
  FIndex.Free;
  inherited Destroy;
end;

procedure TAITaskGraph.Clear;
begin
  FIds.Clear;
  FIndex.Clear;
  FLinks := nil;
  FSucc := nil;
  FPred := nil;
  FCompValid := False;
end;

function TAITaskGraph.GetNodeCount: Integer;
begin
  Result := FIds.Count;
end;

function TAITaskGraph.GetNodeId(I: Integer): string;
begin
  Result := FIds[I];
end;

function TAITaskGraph.GetLinkCount: Integer;
begin
  Result := Length(FLinks);
end;

function TAITaskGraph.GetLink(I: Integer): TAITaskLink;
begin
  if (I < 0) or (I > High(FLinks)) then
    raise EAITaskGraph.CreateFmt('vinculo inexistente: %d', [I]);
  Result := FLinks[I];
end;

function TAITaskGraph.AddNode(const AId: string): Integer;
var K: Integer;
begin
  if Trim(AId) = '' then raise EAITaskGraph.Create('no sem ID');
  if FIndex.Find(AId, K) then
    raise EAITaskGraph.CreateFmt('no repetido: %s', [AId]);
  Result := FIds.Add(AId);
  FIndex.AddObject(AId, TObject(PtrInt(Result)));
  SetLength(FSucc, Result + 1);
  SetLength(FPred, Result + 1);
  FCompValid := False;
end;

function TAITaskGraph.IndexOfNode(const AId: string): Integer;
var K: Integer;
begin
  if FIndex.Find(AId, K) then Result := PtrInt(FIndex.Objects[K]) else Result := -1;
end;

function TAITaskGraph.HasNode(const AId: string): Boolean;
begin
  Result := IndexOfNode(AId) >= 0;
end;

function TAITaskGraph.IndexOfLink(const AFromId, AToId: string): Integer;
var A, B, I: Integer;
begin
  A := IndexOfNode(AFromId);
  B := IndexOfNode(AToId);
  if (A >= 0) and (B >= 0) then
    for I in FSucc[A] do
      if FLinks[I].ToNode = B then Exit(I);
  Result := -1;
end;

function TAITaskGraph.PathBetween(AFrom, ATo: Integer): TAIIntArray;
var
  Prev: TAIIntArray;
  Queue: TAIIntArray;
  Head, N, L, M, K: Integer;
begin
  { busca em largura de AFrom ate ATo; devolve a sequencia de nos }
  Result := nil;
  SetLength(Prev, NodeCount);
  for K := 0 to High(Prev) do Prev[K] := -2;
  SetLength(Queue, NodeCount);
  Head := 0; N := 1;
  Queue[0] := AFrom;
  Prev[AFrom] := -1;
  while Head < N do
  begin
    K := Queue[Head]; Inc(Head);
    if K = ATo then Break;
    for L in FSucc[K] do
    begin
      M := FLinks[L].ToNode;
      if Prev[M] = -2 then
      begin
        Prev[M] := K;
        Queue[N] := M; Inc(N);
      end;
    end;
  end;
  if Prev[ATo] = -2 then Exit;
  K := ATo;
  while K <> -1 do
  begin
    SetLength(Result, Length(Result) + 1);
    Result[High(Result)] := K;
    K := Prev[K];
  end;
  { inverte }
  for K := 0 to High(Result) div 2 do
  begin
    M := Result[K];
    Result[K] := Result[High(Result) - K];
    Result[High(Result) - K] := M;
  end;
end;

function TAITaskGraph.Reaches(AFrom, ATo: Integer): Boolean;
begin
  Result := (AFrom = ATo) or (Length(PathBetween(AFrom, ATo)) > 0);
end;

function TAITaskGraph.CyclePath(const AFromId, AToId: string): TAIStrArray;
var A, B, I: Integer; P: TAIIntArray;
begin
  { ciclo que o vinculo AFrom -> ATo fecharia: caminho ATo ~> AFrom + AFrom -> ATo }
  Result := nil;
  A := IndexOfNode(AFromId);
  B := IndexOfNode(AToId);
  if (A < 0) or (B < 0) then Exit;
  if A = B then
  begin
    SetLength(Result, 2);
    Result[0] := FIds[A]; Result[1] := FIds[A];
    Exit;
  end;
  { P vai de B ate A; o ciclo e A -> B -> ... -> A }
  P := PathBetween(B, A);
  if Length(P) = 0 then Exit;
  SetLength(Result, Length(P) + 1);
  Result[0] := FIds[A];
  for I := 0 to High(P) do Result[I + 1] := FIds[P[I]];
end;

function JoinPath(const P: TAIStrArray): string;
var I: Integer;
begin
  Result := '';
  for I := 0 to High(P) do
  begin
    if I > 0 then Result := Result + ' -> ';
    Result := Result + P[I];
  end;
end;

function TAITaskGraph.CanLink(const AFromId, AToId: string; out Err: string): Boolean;
var A, B: Integer;
begin
  Err := '';
  A := IndexOfNode(AFromId);
  B := IndexOfNode(AToId);
  if A < 0 then Err := 'tarefa inexistente: ' + AFromId
  else if B < 0 then Err := 'tarefa inexistente: ' + AToId
  else if A = B then Err := Format('%s nao pode depender de si mesma', [AFromId])
  else if IndexOfLink(AFromId, AToId) >= 0 then
    Err := Format('ja existe vinculo de %s para %s', [AFromId, AToId])
  else if Reaches(B, A) then
    Err := Format('o vinculo %s -> %s fecharia o ciclo %s',
      [AFromId, AToId, JoinPath(CyclePath(AFromId, AToId))]);
  Result := Err = '';
end;

function TAITaskGraph.AddLink(const AFromId, AToId: string; AType: TAITaskLinkType;
  const ALag: TAITaskLag; out Err: string; ATag: PtrInt): Integer;
var A, B: Integer;
begin
  Result := -1;
  if not CanLink(AFromId, AToId, Err) then Exit;
  A := IndexOfNode(AFromId);
  B := IndexOfNode(AToId);
  Result := Length(FLinks);
  SetLength(FLinks, Result + 1);
  FLinks[Result].FromId := FIds[A];
  FLinks[Result].ToId := FIds[B];
  FLinks[Result].FromNode := A;
  FLinks[Result].ToNode := B;
  FLinks[Result].LinkType := AType;
  FLinks[Result].Lag := ALag;
  FLinks[Result].Tag := ATag;
  SetLength(FSucc[A], Length(FSucc[A]) + 1);
  FSucc[A][High(FSucc[A])] := Result;
  SetLength(FPred[B], Length(FPred[B]) + 1);
  FPred[B][High(FPred[B])] := Result;
  FCompValid := False;
end;

procedure TAITaskGraph.DeleteLink(I: Integer);
var
  K, N: Integer;
  Old: array of TAITaskLink;
begin
  if (I < 0) or (I > High(FLinks)) then
    raise EAITaskGraph.CreateFmt('vinculo inexistente: %d', [I]);
  { reconstroi a adjacencia: os indices dos vinculos seguintes mudam }
  Old := Copy(FLinks);
  FLinks := nil;
  for K := 0 to High(FSucc) do begin FSucc[K] := nil; FPred[K] := nil; end;
  for K := 0 to High(Old) do
  begin
    if K = I then Continue;
    N := Length(FLinks);
    SetLength(FLinks, N + 1);
    FLinks[N] := Old[K];
    SetLength(FSucc[Old[K].FromNode], Length(FSucc[Old[K].FromNode]) + 1);
    FSucc[Old[K].FromNode][High(FSucc[Old[K].FromNode])] := N;
    SetLength(FPred[Old[K].ToNode], Length(FPred[Old[K].ToNode]) + 1);
    FPred[Old[K].ToNode][High(FPred[Old[K].ToNode])] := N;
  end;
  FCompValid := False;
end;

function TAITaskGraph.Successors(ANode: Integer): TAIIntArray;
begin
  Result := Copy(FSucc[ANode]);
end;

function TAITaskGraph.Predecessors(ANode: Integer): TAIIntArray;
begin
  Result := Copy(FPred[ANode]);
end;

function TAITaskGraph.SuccessorNodes(ANode: Integer): TAIIntArray;
var I: Integer;
begin
  SetLength(Result, Length(FSucc[ANode]));
  for I := 0 to High(Result) do Result[I] := FLinks[FSucc[ANode][I]].ToNode;
end;

function TAITaskGraph.PredecessorNodes(ANode: Integer): TAIIntArray;
var I: Integer;
begin
  SetLength(Result, Length(FPred[ANode]));
  for I := 0 to High(Result) do Result[I] := FLinks[FPred[ANode][I]].FromNode;
end;

function TAITaskGraph.TopologicalOrder: TAIIntArray;
var
  InDeg, Heap: TAIIntArray;
  HN, I, K, M, C, P, T: Integer;

  procedure HeapPush(V: Integer);
  begin
    Heap[HN] := V;
    C := HN; Inc(HN);
    while C > 0 do
    begin
      P := (C - 1) div 2;
      if Heap[P] <= Heap[C] then Break;
      T := Heap[P]; Heap[P] := Heap[C]; Heap[C] := T;
      C := P;
    end;
  end;

  function HeapPop: Integer;
  begin
    Result := Heap[0];
    Dec(HN);
    Heap[0] := Heap[HN];
    P := 0;
    while True do
    begin
      C := 2 * P + 1;
      if C >= HN then Break;
      if (C + 1 < HN) and (Heap[C + 1] < Heap[C]) then Inc(C);
      if Heap[P] <= Heap[C] then Break;
      T := Heap[P]; Heap[P] := Heap[C]; Heap[C] := T;
      P := C;
    end;
  end;

begin
  { Kahn com fila de prioridade: empate pela ordem de insercao (deterministico) }
  SetLength(InDeg, NodeCount);
  SetLength(Heap, NodeCount);
  SetLength(Result, 0);
  HN := 0;
  for I := 0 to NodeCount - 1 do InDeg[I] := Length(FPred[I]);
  for I := 0 to NodeCount - 1 do
    if InDeg[I] = 0 then HeapPush(I);
  SetLength(Result, NodeCount);
  K := 0;
  while HN > 0 do
  begin
    I := HeapPop;
    Result[K] := I; Inc(K);
    for M in FSucc[I] do
    begin
      Dec(InDeg[FLinks[M].ToNode]);
      if InDeg[FLinks[M].ToNode] = 0 then HeapPush(FLinks[M].ToNode);
    end;
  end;
  if K <> NodeCount then
    raise EAITaskGraph.Create('grafo com ciclo (nao deveria ocorrer: AddLink recusa ciclos)');
end;

function TAITaskGraph.Relation(const AId, BId: string): TAITaskRelation;
var A, B: Integer;
begin
  A := IndexOfNode(AId);
  B := IndexOfNode(BId);
  if A < 0 then raise EAITaskGraph.CreateFmt('tarefa inexistente: %s', [AId]);
  if B < 0 then raise EAITaskGraph.CreateFmt('tarefa inexistente: %s', [BId]);
  if A = B then Exit(atrSame);
  if Reaches(A, B) then Exit(atrPredecessor);
  if Reaches(B, A) then Exit(atrSuccessor);
  Result := atrParallel;
end;

function Collect(const Adj: array of TAIIntArray; const Links: array of TAITaskLink;
  Start: Integer; Forward: Boolean; N: Integer): TAIIntArray;
var
  Seen: array of Boolean;
  Stack: TAIIntArray;
  SP, K, L, M: Integer;
begin
  Result := nil;
  SetLength(Seen, N);
  SetLength(Stack, N);
  SP := 0;
  Stack[SP] := Start; Inc(SP);
  Seen[Start] := True;
  while SP > 0 do
  begin
    Dec(SP); K := Stack[SP];
    for L in Adj[K] do
    begin
      if Forward then M := Links[L].ToNode else M := Links[L].FromNode;
      if not Seen[M] then
      begin
        Seen[M] := True;
        Stack[SP] := M; Inc(SP);
      end;
    end;
  end;
  for K := 0 to N - 1 do
    if Seen[K] and (K <> Start) then
    begin
      SetLength(Result, Length(Result) + 1);
      Result[High(Result)] := K;
    end;
end;

function TAITaskGraph.AllPredecessors(ANode: Integer): TAIIntArray;
begin
  Result := Collect(FPred, FLinks, ANode, False, NodeCount);
end;

function TAITaskGraph.AllSuccessors(ANode: Integer): TAIIntArray;
begin
  Result := Collect(FSucc, FLinks, ANode, True, NodeCount);
end;

procedure TAITaskGraph.BuildComponents;
var
  Parent, Map: TAIIntArray;
  I, R: Integer;

  function Find(X: Integer): Integer;
  begin
    while Parent[X] <> X do
    begin
      Parent[X] := Parent[Parent[X]];
      X := Parent[X];
    end;
    Result := X;
  end;

  procedure Union(A, B: Integer);
  var RA, RB: Integer;
  begin
    RA := Find(A); RB := Find(B);
    { a raiz e sempre o menor indice: numeracao estavel das cadeias }
    if RA < RB then Parent[RB] := RA
    else if RB < RA then Parent[RA] := RB;
  end;

begin
  SetLength(Parent, NodeCount);
  for I := 0 to NodeCount - 1 do Parent[I] := I;
  for I := 0 to High(FLinks) do Union(FLinks[I].FromNode, FLinks[I].ToNode);
  SetLength(Map, NodeCount);
  for I := 0 to NodeCount - 1 do Map[I] := -1;
  SetLength(FComp, NodeCount);
  FCompCount := 0;
  for I := 0 to NodeCount - 1 do
  begin
    R := Find(I);
    if Map[R] < 0 then
    begin
      Map[R] := FCompCount;
      Inc(FCompCount);
    end;
    FComp[I] := Map[R];
  end;
  FCompValid := True;
end;

function TAITaskGraph.ComponentCount: Integer;
begin
  if not FCompValid then BuildComponents;
  Result := FCompCount;
end;

function TAITaskGraph.ComponentOf(ANode: Integer): Integer;
begin
  if not FCompValid then BuildComponents;
  Result := FComp[ANode];
end;

function TAITaskGraph.ComponentNodes(AComp: Integer): TAIIntArray;
var I: Integer;
begin
  if not FCompValid then BuildComponents;
  Result := nil;
  for I := 0 to NodeCount - 1 do
    if FComp[I] = AComp then
    begin
      SetLength(Result, Length(Result) + 1);
      Result[High(Result)] := I;
    end;
end;

end.
