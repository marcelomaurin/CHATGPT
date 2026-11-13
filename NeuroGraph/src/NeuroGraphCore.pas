unit NeuroGraphCore;

{$mode objfpc}{$H+}

interface

uses Classes, SysUtils, Math;

const
  NG_MAX_WEIGHT = 16.0;

type
  TNGEdge = record
    Source, Target: Integer;
    Weight: Single;
  end;
  TNGActivation = record
    Node: Integer;
    Signal: Single;
  end;
  TNGActivations = array of TNGActivation;

  { Directed sparse graph with O(out-degree) adjacency index and inhibitory weights. }
  TNeuroGraph = class
  private
    FEdges: array of TNGEdge;
    FAdjHead: array of Integer;
    FAdjNext: array of Integer;
    FAllowInhibitory: Boolean;
    function Clamp01(const V: Single): Single; inline;
    function ClampWeight(const V: Single): Single; inline;
    procedure EnsureNodeCapacity(const MaxNodeID: Integer);
    function FindEdgeIndex(const Source, Target: Integer): Integer;
  public
    constructor Create(const AllowInhibitory: Boolean = False);
    procedure Clear;
    procedure Link(const Source, Target: Integer; const Weight: Single);
    function Propagate(const Seeds: TNGActivations;
      const Decay: array of Single): TNGActivations;
    procedure Reinforce(const Source, Target: Integer;
      const Confidence, Relevance: Single;
      const LearningRate: Single = 0.1;
      const ForgetRate: Single = 0.001);
    function EdgeCount: Integer;
    property AllowInhibitory: Boolean read FAllowInhibitory write FAllowInhibitory;
  end;

implementation

constructor TNeuroGraph.Create(const AllowInhibitory: Boolean);
begin
  inherited Create;
  FAllowInhibitory := AllowInhibitory;
end;

procedure TNeuroGraph.Clear;
begin
  SetLength(FEdges, 0);
  SetLength(FAdjHead, 0);
  SetLength(FAdjNext, 0);
end;

function TNeuroGraph.Clamp01(const V: Single): Single;
begin
  Result := Max(0.0, Min(1.0, V));
end;

function TNeuroGraph.ClampWeight(const V: Single): Single;
begin
  if FAllowInhibitory then
    Result := Max(-NG_MAX_WEIGHT, Min(NG_MAX_WEIGHT, V))
  else
    Result := Clamp01(V);
end;

procedure TNeuroGraph.EnsureNodeCapacity(const MaxNodeID: Integer);
var
  OldLen, NewLen, I: Integer;
begin
  if MaxNodeID < Length(FAdjHead) then Exit;
  OldLen := Length(FAdjHead);
  NewLen := Max(MaxNodeID + 1, Max(64, OldLen * 2));
  SetLength(FAdjHead, NewLen);
  for I := OldLen to NewLen - 1 do
    FAdjHead[I] := -1;
end;

function TNeuroGraph.FindEdgeIndex(const Source, Target: Integer): Integer;
var
  EdgeIdx: Integer;
begin
  if (Source < 0) or (Source >= Length(FAdjHead)) then Exit(-1);
  EdgeIdx := FAdjHead[Source];
  while EdgeIdx >= 0 do
  begin
    if FEdges[EdgeIdx].Target = Target then
      Exit(EdgeIdx);
    EdgeIdx := FAdjNext[EdgeIdx];
  end;
  Result := -1;
end;

function TNeuroGraph.EdgeCount: Integer;
begin
  Result := Length(FEdges);
end;

procedure TNeuroGraph.Link(const Source, Target: Integer; const Weight: Single);
var
  Idx: Integer;
begin
  if (Source < 0) or (Target < 0) then Exit;
  EnsureNodeCapacity(Max(Source, Target));
  Idx := FindEdgeIndex(Source, Target);
  if Idx >= 0 then
  begin
    FEdges[Idx].Weight := ClampWeight(Weight);
    Exit;
  end;
  Idx := Length(FEdges);
  SetLength(FEdges, Idx + 1);
  SetLength(FAdjNext, Idx + 1);
  FEdges[Idx].Source := Source;
  FEdges[Idx].Target := Target;
  FEdges[Idx].Weight := ClampWeight(Weight);
  FAdjNext[Idx] := FAdjHead[Source];
  FAdjHead[Source] := Idx;
end;

procedure TNeuroGraph.Reinforce(const Source, Target: Integer;
  const Confidence, Relevance, LearningRate, ForgetRate: Single);
var
  Idx: Integer;
  W: Single;
begin
  W := 0;
  Idx := FindEdgeIndex(Source, Target);
  if Idx >= 0 then
    W := FEdges[Idx].Weight;
  Link(Source, Target, ClampWeight((1 - Clamp01(ForgetRate)) * W +
    Clamp01(LearningRate) * Clamp01(Confidence) * Relevance));
end;

function TNeuroGraph.Propagate(const Seeds: TNGActivations;
  const Decay: array of Single): TNGActivations;
var
  Frontier, Next: TNGActivations;
  NextPos, ResPos: array of Integer;
  D, I, EdgeIdx, SrcNode, TgtNode, PosIdx, MaxNode: Integer;
  DecayVal, Delta, Combined: Single;
begin
  Frontier := Copy(Seeds, 0, Length(Seeds));
  Result := Copy(Seeds, 0, Length(Seeds));
  MaxNode := Length(FAdjHead) - 1;
  for I := 0 to High(Seeds) do
    if Seeds[I].Node > MaxNode then
      MaxNode := Seeds[I].Node;
  if MaxNode < 0 then Exit;

  SetLength(NextPos, MaxNode + 1);
  SetLength(ResPos, MaxNode + 1);
  for I := 0 to MaxNode do
  begin
    NextPos[I] := -1;
    ResPos[I] := -1;
  end;
  for I := 0 to High(Result) do
    if (Result[I].Node >= 0) and (Result[I].Node <= MaxNode) then
      ResPos[Result[I].Node] := I;

  for D := 0 to Min(2, High(Decay)) do
  begin
    DecayVal := Clamp01(Decay[D]);
    if DecayVal <= 0 then Continue;
    for I := 0 to High(Next) do
      if (Next[I].Node >= 0) and (Next[I].Node <= MaxNode) then
        NextPos[Next[I].Node] := -1;
    SetLength(Next, 0);

    for I := 0 to High(Frontier) do
    begin
      SrcNode := Frontier[I].Node;
      if (SrcNode < 0) or (SrcNode >= Length(FAdjHead)) then Continue;
      EdgeIdx := FAdjHead[SrcNode];
      while EdgeIdx >= 0 do
      begin
        TgtNode := FEdges[EdgeIdx].Target;
        Delta := Frontier[I].Signal * FEdges[EdgeIdx].Weight * DecayVal;
        if FAllowInhibitory or (Delta > 0) then
        begin
          PosIdx := NextPos[TgtNode];
          if PosIdx < 0 then
          begin
            PosIdx := Length(Next);
            SetLength(Next, PosIdx + 1);
            Next[PosIdx].Node := TgtNode;
            Next[PosIdx].Signal := 0;
            NextPos[TgtNode] := PosIdx;
          end;
          Next[PosIdx].Signal := Next[PosIdx].Signal + Delta;
        end;
        EdgeIdx := FAdjNext[EdgeIdx];
      end;
    end;

    { Apply post-accumulation clamping and merge into Result in O(1) per active target }
    SetLength(Frontier, 0);
    for I := 0 to High(Next) do
    begin
      Combined := Clamp01(Next[I].Signal);
      Next[I].Signal := Combined;
      if Combined <= 0 then Continue;
      SetLength(Frontier, Length(Frontier) + 1);
      Frontier[High(Frontier)] := Next[I];

      TgtNode := Next[I].Node;
      PosIdx := ResPos[TgtNode];
      if PosIdx < 0 then
      begin
        PosIdx := Length(Result);
        SetLength(Result, PosIdx + 1);
        Result[PosIdx] := Next[I];
        ResPos[TgtNode] := PosIdx;
      end
      else
        Result[PosIdx].Signal := Max(Result[PosIdx].Signal, Combined);
    end;
  end;
end;

end.
