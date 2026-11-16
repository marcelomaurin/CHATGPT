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
  TNGFloatArray = array of Single;

  TNGActivationKind = (ngActReLU, ngActSiLU, ngActGELU, ngActTanh);

  { Dense non-linear hidden layer optimized for CPU cache (row-major flat weights). }
  TNGHiddenLayer = record
    InputDim: Integer;
    OutputDim: Integer;
    Weights: TNGFloatArray; // InputDim * OutputDim
    Biases: TNGFloatArray;  // OutputDim
    Activation: TNGActivationKind;
    LastPreAct: TNGFloatArray;
    LastPostAct: TNGFloatArray;
  end;

  { Multi-layer non-linear neural network (MLP) with sparse input projection and CPU backpropagation. }
  TNGDeepMLP = class
  private
    FLayers: array of TNGHiddenLayer;
    FOutputWeights: TNGFloatArray; // LastHiddenDim * NumClasses
    FOutputBiases: TNGFloatArray;  // NumClasses
    FInputDim: Integer;
    FNumClasses: Integer;
    function ApplyActivation(const X: Single; const Kind: TNGActivationKind): Single; inline;
    function ApplyActivationDerivative(const PreX: Single; const Kind: TNGActivationKind): Single; inline;
  public
    constructor Create(const AInputDim: Integer; const AHiddenDims: array of Integer;
      const ANumClasses: Integer; const AActivation: TNGActivationKind = ngActSiLU);
    procedure InitXavier(const Seed: Integer = 42);
    function ForwardSparse(const ActiveFeatures: TNGActivations): TNGFloatArray;
    function TrainStepSparse(const ActiveFeatures: TNGActivations;
      const TargetClass: Integer; const LearningRate: Single = 0.02;
      const WeightDecay: Single = 0.0001): Single;
    function LayerCount: Integer;
    property InputDim: Integer read FInputDim;
    property NumClasses: Integer read FNumClasses;
  end;

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

{ TNGDeepMLP }

constructor TNGDeepMLP.Create(const AInputDim: Integer;
  const AHiddenDims: array of Integer; const ANumClasses: Integer;
  const AActivation: TNGActivationKind);
var
  I, InD, OutD: Integer;
begin
  inherited Create;
  FInputDim := Max(1, AInputDim);
  FNumClasses := Max(2, ANumClasses);
  SetLength(FLayers, Length(AHiddenDims));
  InD := FInputDim;
  for I := 0 to High(AHiddenDims) do
  begin
    OutD := Max(4, AHiddenDims[I]);
    FLayers[I].InputDim := InD;
    FLayers[I].OutputDim := OutD;
    FLayers[I].Activation := AActivation;
    SetLength(FLayers[I].Weights, InD * OutD);
    SetLength(FLayers[I].Biases, OutD);
    SetLength(FLayers[I].LastPreAct, OutD);
    SetLength(FLayers[I].LastPostAct, OutD);
    InD := OutD;
  end;
  SetLength(FOutputWeights, InD * FNumClasses);
  SetLength(FOutputBiases, FNumClasses);
  InitXavier(42);
end;

function TNGDeepMLP.LayerCount: Integer;
begin
  Result := Length(FLayers);
end;

procedure TNGDeepMLP.InitXavier(const Seed: Integer);
var
  L, I: Integer;
  Scale: Single;
  State: Cardinal;

  function NextRandUniform: Single;
  begin
    State := State * 1664525 + 1013904223;
    Result := ( (State shr 8) / 16777216.0 ) * 2.0 - 1.0;
  end;

begin
  State := Cardinal(Seed);
  for L := 0 to High(FLayers) do
  begin
    Scale := Sqrt(6.0 / (FLayers[L].InputDim + FLayers[L].OutputDim));
    for I := 0 to High(FLayers[L].Weights) do
      FLayers[L].Weights[I] := NextRandUniform * Scale;
    for I := 0 to High(FLayers[L].Biases) do
      FLayers[L].Biases[I] := 0.0;
  end;
  if Length(FLayers) > 0 then
    Scale := Sqrt(6.0 / (FLayers[High(FLayers)].OutputDim + FNumClasses))
  else
    Scale := Sqrt(6.0 / (FInputDim + FNumClasses));
  for I := 0 to High(FOutputWeights) do
    FOutputWeights[I] := NextRandUniform * Scale;
  for I := 0 to High(FOutputBiases) do
    FOutputBiases[I] := 0.0;
end;

function TNGDeepMLP.ApplyActivation(const X: Single; const Kind: TNGActivationKind): Single;
var
  Sig: Single;
begin
  case Kind of
    ngActReLU:
      if X > 0 then Result := X else Result := 0.0;
    ngActSiLU:
      begin
        if X < -15.0 then Result := 0.0
        else if X > 15.0 then Result := X
        else
        begin
          Sig := 1.0 / (1.0 + Exp(-X));
          Result := X * Sig;
        end;
      end;
    ngActGELU:
      begin
        if X < -10.0 then Result := 0.0
        else if X > 10.0 then Result := X
        else
          Result := X * (1.0 / (1.0 + Exp(-1.702 * X)));
      end;
    ngActTanh:
      Result := Tanh(X);
  else
    Result := X;
  end;
end;

function TNGDeepMLP.ApplyActivationDerivative(const PreX: Single; const Kind: TNGActivationKind): Single;
var
  Sig, T: Single;
begin
  case Kind of
    ngActReLU:
      if PreX > 0 then Result := 1.0 else Result := 0.0;
    ngActSiLU:
      begin
        if PreX < -15.0 then Result := 0.0
        else if PreX > 15.0 then Result := 1.0
        else
        begin
          Sig := 1.0 / (1.0 + Exp(-PreX));
          Result := Sig * (1.0 + PreX * (1.0 - Sig));
        end;
      end;
    ngActGELU:
      begin
        if PreX < -10.0 then Result := 0.0
        else if PreX > 10.0 then Result := 1.0
        else
        begin
          Sig := 1.0 / (1.0 + Exp(-1.702 * PreX));
          Result := Sig + 1.702 * PreX * Sig * (1.0 - Sig);
        end;
      end;
    ngActTanh:
      begin
        T := Tanh(PreX);
        Result := 1.0 - T * T;
      end;
  else
    Result := 1.0;
  end;
end;

function TNGDeepMLP.ForwardSparse(const ActiveFeatures: TNGActivations): TNGFloatArray;
var
  L, I, J, FeatNode, OutDim, InDim, RowOffset: Integer;
  FeatVal, Acc: Single;
  PrevAct: TNGFloatArray;
begin
  Result := nil;
  if Length(FLayers) = 0 then
  begin
    SetLength(Result, FNumClasses);
    for J := 0 to FNumClasses - 1 do
      Result[J] := FOutputBiases[J];
    for I := 0 to High(ActiveFeatures) do
    begin
      FeatNode := ActiveFeatures[I].Node;
      if (FeatNode >= 0) and (FeatNode < FInputDim) then
      begin
        FeatVal := ActiveFeatures[I].Signal;
        RowOffset := FeatNode * FNumClasses;
        for J := 0 to FNumClasses - 1 do
          Result[J] := Result[J] + FeatVal * FOutputWeights[RowOffset + J];
      end;
    end;
    Exit;
  end;

  { Layer 0: Sparse-to-Dense projection }
  OutDim := FLayers[0].OutputDim;
  for J := 0 to OutDim - 1 do
    FLayers[0].LastPreAct[J] := FLayers[0].Biases[J];

  for I := 0 to High(ActiveFeatures) do
  begin
    FeatNode := ActiveFeatures[I].Node;
    if (FeatNode >= 0) and (FeatNode < FLayers[0].InputDim) then
    begin
      FeatVal := ActiveFeatures[I].Signal;
      RowOffset := FeatNode * OutDim;
      for J := 0 to OutDim - 1 do
        FLayers[0].LastPreAct[J] := FLayers[0].LastPreAct[J] + FeatVal * FLayers[0].Weights[RowOffset + J];
    end;
  end;

  for J := 0 to OutDim - 1 do
    FLayers[0].LastPostAct[J] := ApplyActivation(FLayers[0].LastPreAct[J], FLayers[0].Activation);

  { Subsequent Hidden Layers (Dense-to-Dense) }
  for L := 1 to High(FLayers) do
  begin
    InDim := FLayers[L].InputDim;
    OutDim := FLayers[L].OutputDim;
    PrevAct := FLayers[L - 1].LastPostAct;
    for J := 0 to OutDim - 1 do
      FLayers[L].LastPreAct[J] := FLayers[L].Biases[J];
    for I := 0 to InDim - 1 do
    begin
      FeatVal := PrevAct[I];
      if Abs(FeatVal) > 1e-9 then
      begin
        RowOffset := I * OutDim;
        for J := 0 to OutDim - 1 do
          FLayers[L].LastPreAct[J] := FLayers[L].LastPreAct[J] + FeatVal * FLayers[L].Weights[RowOffset + J];
      end;
    end;
    for J := 0 to OutDim - 1 do
      FLayers[L].LastPostAct[J] := ApplyActivation(FLayers[L].LastPreAct[J], FLayers[L].Activation);
  end;

  { Output Layer }
  PrevAct := FLayers[High(FLayers)].LastPostAct;
  InDim := Length(PrevAct);
  SetLength(Result, FNumClasses);
  for J := 0 to FNumClasses - 1 do
    Result[J] := FOutputBiases[J];
  for I := 0 to InDim - 1 do
  begin
    FeatVal := PrevAct[I];
    RowOffset := I * FNumClasses;
    for J := 0 to FNumClasses - 1 do
      Result[J] := Result[J] + FeatVal * FOutputWeights[RowOffset + J];
  end;
end;

function TNGDeepMLP.TrainStepSparse(const ActiveFeatures: TNGActivations;
  const TargetClass: Integer; const LearningRate, WeightDecay: Single): Single;
var
  Logits, Probs, GradHidden, NextGradHidden, LastAct: TNGFloatArray;
  MaxLogit, SumExp, Loss, GradVal, FeatVal: Single;
  L, I, J, InDim, OutDim, RowOffset, FeatNode: Integer;
begin
  if (TargetClass < 0) or (TargetClass >= FNumClasses) then Exit(0.0);
  Logits := ForwardSparse(ActiveFeatures);

  { Numerically stable Softmax }
  MaxLogit := Logits[0];
  for J := 1 to FNumClasses - 1 do
    if Logits[J] > MaxLogit then MaxLogit := Logits[J];

  SetLength(Probs, FNumClasses);
  SumExp := 0.0;
  for J := 0 to FNumClasses - 1 do
  begin
    Probs[J] := Exp(Logits[J] - MaxLogit);
    SumExp := SumExp + Probs[J];
  end;
  for J := 0 to FNumClasses - 1 do
    Probs[J] := Probs[J] / SumExp;

  Loss := -Ln(Max(1e-12, Probs[TargetClass]));
  Result := Loss;

  { dL/dLogits = Probs - OneHot(TargetClass) }
  Probs[TargetClass] := Probs[TargetClass] - 1.0;

  if Length(FLayers) = 0 then
  begin
    for J := 0 to FNumClasses - 1 do
      FOutputBiases[J] := FOutputBiases[J] - LearningRate * Probs[J];
    for I := 0 to High(ActiveFeatures) do
    begin
      FeatNode := ActiveFeatures[I].Node;
      if (FeatNode >= 0) and (FeatNode < FInputDim) then
      begin
        FeatVal := ActiveFeatures[I].Signal;
        RowOffset := FeatNode * FNumClasses;
        for J := 0 to FNumClasses - 1 do
          FOutputWeights[RowOffset + J] := FOutputWeights[RowOffset + J] * (1.0 - LearningRate * WeightDecay)
            - LearningRate * FeatVal * Probs[J];
      end;
    end;
    Exit;
  end;

  { Backprop through Output Layer }
  LastAct := FLayers[High(FLayers)].LastPostAct;
  InDim := Length(LastAct);
  SetLength(GradHidden, InDim);
  for I := 0 to InDim - 1 do
  begin
    RowOffset := I * FNumClasses;
    GradVal := 0.0;
    FeatVal := LastAct[I];
    for J := 0 to FNumClasses - 1 do
    begin
      GradVal := GradVal + Probs[J] * FOutputWeights[RowOffset + J];
      FOutputWeights[RowOffset + J] := FOutputWeights[RowOffset + J] * (1.0 - LearningRate * WeightDecay)
        - LearningRate * FeatVal * Probs[J];
    end;
    GradHidden[I] := GradVal;
  end;
  for J := 0 to FNumClasses - 1 do
    FOutputBiases[J] := FOutputBiases[J] - LearningRate * Probs[J];

  { Backprop through Hidden Layers L down to 1 }
  for L := High(FLayers) downto 1 do
  begin
    OutDim := FLayers[L].OutputDim;
    InDim := FLayers[L].InputDim;
    for J := 0 to OutDim - 1 do
    begin
      GradHidden[J] := GradHidden[J] * ApplyActivationDerivative(FLayers[L].LastPreAct[J], FLayers[L].Activation);
      FLayers[L].Biases[J] := FLayers[L].Biases[J] - LearningRate * GradHidden[J];
    end;

    SetLength(NextGradHidden, InDim);
    LastAct := FLayers[L - 1].LastPostAct;
    for I := 0 to InDim - 1 do
    begin
      RowOffset := I * OutDim;
      GradVal := 0.0;
      FeatVal := LastAct[I];
      for J := 0 to OutDim - 1 do
      begin
        GradVal := GradVal + GradHidden[J] * FLayers[L].Weights[RowOffset + J];
        FLayers[L].Weights[RowOffset + J] := FLayers[L].Weights[RowOffset + J] * (1.0 - LearningRate * WeightDecay)
          - LearningRate * FeatVal * GradHidden[J];
      end;
      NextGradHidden[I] := GradVal;
    end;
    GradHidden := NextGradHidden;
  end;

  { Backprop through Layer 0 (Sparse Input) }
  OutDim := FLayers[0].OutputDim;
  for J := 0 to OutDim - 1 do
  begin
    GradHidden[J] := GradHidden[J] * ApplyActivationDerivative(FLayers[0].LastPreAct[J], FLayers[0].Activation);
    FLayers[0].Biases[J] := FLayers[0].Biases[J] - LearningRate * GradHidden[J];
  end;
  for I := 0 to High(ActiveFeatures) do
  begin
    FeatNode := ActiveFeatures[I].Node;
    if (FeatNode >= 0) and (FeatNode < FLayers[0].InputDim) then
    begin
      FeatVal := ActiveFeatures[I].Signal;
      RowOffset := FeatNode * OutDim;
      for J := 0 to OutDim - 1 do
        FLayers[0].Weights[RowOffset + J] := FLayers[0].Weights[RowOffset + J] * (1.0 - LearningRate * WeightDecay)
          - LearningRate * FeatVal * GradHidden[J];
    end;
  end;
end;

end.
