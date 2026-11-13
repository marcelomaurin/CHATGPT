unit NeuroGraphCore;

{$mode objfpc}{$H+}

interface

uses Classes, SysUtils, Math;

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

  { Directed sparse graph prototype. Node IDs are assigned by the caller. }
  TNeuroGraph = class
  private
    FEdges: array of TNGEdge;
    function Clamp01(const V: Single): Single;
  public
    procedure Link(const Source, Target: Integer; const Weight: Single);
    function Propagate(const Seeds: TNGActivations;
      const Decay: array of Single): TNGActivations;
    procedure Reinforce(const Source, Target: Integer;
      const Confidence, Relevance: Single;
      const LearningRate: Single = 0.1;
      const ForgetRate: Single = 0.001);
    function EdgeCount: Integer;
  end;

implementation

function TNeuroGraph.Clamp01(const V: Single): Single;
begin
  Result := Max(0.0, Min(1.0, V));
end;

function TNeuroGraph.EdgeCount: Integer;
begin
  Result := Length(FEdges);
end;

procedure TNeuroGraph.Link(const Source, Target: Integer; const Weight: Single);
var I: Integer;
begin
  for I := 0 to High(FEdges) do
    if (FEdges[I].Source = Source) and (FEdges[I].Target = Target) then
    begin
      FEdges[I].Weight := Clamp01(Weight);
      Exit;
    end;
  SetLength(FEdges, Length(FEdges) + 1);
  I := High(FEdges);
  FEdges[I].Source := Source;
  FEdges[I].Target := Target;
  FEdges[I].Weight := Clamp01(Weight);
end;

procedure TNeuroGraph.Reinforce(const Source, Target: Integer;
  const Confidence, Relevance, LearningRate, ForgetRate: Single);
var I: Integer; W: Single;
begin
  W := 0;
  for I := 0 to High(FEdges) do
    if (FEdges[I].Source = Source) and (FEdges[I].Target = Target) then
    begin
      W := FEdges[I].Weight;
      Break;
    end;
  Link(Source, Target, Clamp01((1-Clamp01(ForgetRate))*W +
    Clamp01(LearningRate)*Clamp01(Confidence)*Clamp01(Relevance)));
end;

function TNeuroGraph.Propagate(const Seeds: TNGActivations;
  const Decay: array of Single): TNGActivations;
var Frontier, Next: TNGActivations;
    D, I, J, K: Integer; Value: Single;
begin
  Frontier := Copy(Seeds, 0, Length(Seeds));
  Result := Copy(Seeds, 0, Length(Seeds));
  for D := 0 to Min(2, High(Decay)) do
  begin
    SetLength(Next, 0);
    for I := 0 to High(Frontier) do
      for J := 0 to High(FEdges) do
        if FEdges[J].Source = Frontier[I].Node then
        begin
          Value := Clamp01(Frontier[I].Signal *
            FEdges[J].Weight * Clamp01(Decay[D]));
          if Value <= 0 then Continue;
          K := 0;
          while (K < Length(Next)) and
            (Next[K].Node <> FEdges[J].Target) do Inc(K);
          if K = Length(Next) then
          begin
            SetLength(Next, K + 1);
            Next[K].Node := FEdges[J].Target;
            Next[K].Signal := 0;
          end;
          Next[K].Signal := Clamp01(Next[K].Signal + Value);
        end;
    Frontier := Next;
    for I := 0 to High(Next) do
    begin
      K := 0;
      while (K < Length(Result)) and
        (Result[K].Node <> Next[I].Node) do Inc(K);
      if K = Length(Result) then
      begin
        SetLength(Result, K + 1);
        Result[K] := Next[I];
      end
      else
        Result[K].Signal := Max(Result[K].Signal, Next[I].Signal);
    end;
  end;
end;

end.
