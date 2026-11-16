unit NeuroGraphEngine;

{$mode objfpc}{$H+}
{$codepage utf8}

{ ============================================================================
  NeuroGraphEngine — Motor Neural Autoregressivo Híbrido (Grafo + Deep MLP)
  100% Free Pascal Nativo (Zero dependência de Python, NumPy ou DLLs externas).

  Arquitetura (Wide & Deep Residual TokenGraph v8):
  1. Ramo Wide (Grafo Associativo Esparso):
     Conexões diretas ponderadas Feature -> Token para memória exata rápida.
  2. Ramo Deep (Camadas Ocultas Não-Lineares em CPU):
     Features Esparsas -> [W1 + b1] -> SiLU -> [W2 + b2] -> SiLU -> [W_out] -> Logits
     Permite separação não-linear de contextos (problema XOR semântico),
     agrupamento latente de sinônimos/morfologia e generalização estrutural.
  3. Treinamento em CPU Pura:
     Backpropagation analítico + Otimizador AdamW (momentos de 1ª e 2ª ordem
     com correção de viés) sobre perda de Entropia Cruzada (Cross-Entropy).
  ============================================================================ }

interface

uses
  Classes, SysUtils, Math, Contnrs, fpjson, jsonparser;

const
  NG_BOS = '<bos>';
  NG_EOS = '<eos>';
  NG_REFUSE = '<refuse>';
  NG_ABSTAIN_MSG = 'não tenho associações suficientes';

type
  TNGStringArray = array of string;

  TNGExample = record
    Question: string;
    Answer: string;
    IsRefusal: Boolean;
    Context: TNGStringArray;
    Category: string;
  end;
  TNGExampleArray = array of TNGExample;

  TNGGeneration = record
    Text: string;
    Tokens: TNGStringArray;
    Probabilities: array of Single;
    Abstained: Boolean;
    Reason: string;
    LatencyMs: Double;
  end;

  TNGFeatureVal = record
    FeatureID: Integer;
    Value: Single;
  end;
  TNGFeatureVec = array of TNGFeatureVal;

  TNGEpochReport = record
    Epoch: Integer;
    CrossEntropyLoss: Single;
    TokenAccuracy: Single;
    ElapsedMs: Double;
  end;
  TNGEpochReportArray = array of TNGEpochReport;

  TNGTrainProgressEvent = procedure(const Epoch, TotalEpochs: Integer;
    const Loss, Accuracy: Single; var AbortTraining: Boolean) of object;

  TNGEvalItemResult = record
    ID: Integer;
    Category: string;
    Question: string;
    Expected: string;
    Predicted: string;
    Abstained: Boolean;
    Correct: Boolean;
    ExactMatch: Single;
    F1: Single;
    Precision: Single;
    Recall: Single;
    LatencyMs: Double;
  end;
  TNGEvalItemResults = array of TNGEvalItemResult;

  TNGEvalSummary = record
    TotalQuestions: Integer;
    CorrectCount: Integer;
    AbstentionCount: Integer;
    WrongAnswers: Integer;
    ApprovalRatePct: Double;
    ExactMatchPct: Double;
    F1ScorePct: Double;
    PrecisionPct: Double;
    RecallPct: Double;
    AvgLatencyMs: Double;
    Items: TNGEvalItemResults;
  end;

  { Sessão de diálogo explícita com histórico limitado }
  TNGSession = class
  private
    FHistory: TNGStringArray;
    FMaxTurns: Integer;
  public
    constructor Create(const AMaxTurns: Integer = 3);
    procedure Clear;
    procedure Remember(const Question: string);
    function ContextArray: TNGStringArray;
    property MaxTurns: Integer read FMaxTurns write FMaxTurns;
  end;

  { Motor Neural Completo em Pascal Puro: TokenGraph + Camadas Ocultas (Deep MLP) }
  TNGDeepEngine = class
  private
    FDecay: Single;
    FConfidence: Single;
    FUseHiddenLayers: Boolean;
    FHiddenDim1: Integer;
    FHiddenDim2: Integer;

    FTokens: TStringList;
    FTokenHash: TFPHashList;

    FFeatures: TStringList;
    FFeatureHash: TFPHashList;
    FFeatureIsStem: array of Boolean;

    // Ramo Wide (Pesos Esparsos FeatureID -> Array de (TargetID, Weight))
    FSparseWeights: array of array of Single; // [FeatureID][TokenID] durante ou após treino
    FSparseEdges: array of array of record
      TargetID: Integer;
      Weight: Single;
    end;

    // Ramo Deep (Camadas Ocultas Não-Lineares SiLU)
    FW1: array of Single;   // [NumFeatures * FHiddenDim1]
    FB1: array of Single;   // [FHiddenDim1]
    FW2: array of Single;   // [FHiddenDim1 * FHiddenDim2]
    FB2: array of Single;   // [FHiddenDim2]
    FWOut: array of Single; // [FHiddenDim2 * NumTokens]
    FBOut: array of Single; // [NumTokens]

    FOnProgress: TNGTrainProgressEvent;

    function EnsureToken(const AToken: string): Integer;
    function FindToken(const AToken: string): Integer;
    function EnsureFeature(const AKey: string; const AIsStem: Boolean = False): Integer;
    function FindFeature(const AKey: string): Integer;

    function IsArticleOrPrep(const W: string): Boolean;
    function IsConnector(const W: string): Boolean;
    function IsQuestionFrame(const W: string): Boolean;

    procedure ExtractInputFeatures(const Question: string;
      const Context: array of string; out SourceFeats: TNGFeatureVec;
      out ConceptTokens: TNGStringArray; const CreateIfMissing: Boolean);
    procedure BuildStepFeatures(const SourceFeats: TNGFeatureVec;
      const ConceptTokens: TNGStringArray; const Prefix: TNGStringArray;
      const MemoryKeys: TNGStringArray; const MemoryVals: array of Single;
      out StepFeats: TNGFeatureVec; const CreateIfMissing: Boolean);
    procedure AdvanceMemory(var MemoryKeys: TNGStringArray;
      var MemoryVals: array of Single; var MemCount: Integer; const NewToken: string);

    function HasKnownConcept(const Question: string; const Context: array of string): Boolean;
    procedure PredictNext(const ActiveFeats: TNGFeatureVec;
      const Prefix: TNGStringArray; out BestToken: string; out BestProb: Single);

    function SiLU(const X: Single): Single; inline;
    function SiLUDeriv(const X: Single): Single; inline;
  public
    constructor Create(const AUseHiddenLayers: Boolean = True;
      const AHiddenDim1: Integer = 96; const AHiddenDim2: Integer = 48;
      const ADecay: Single = 0.65; const AConfidence: Single = 0.10);
    destructor Destroy; override;

    procedure Clear;

    { Treinamento 100% em Free Pascal com Backpropagation + AdamW em CPU }
    function Fit(const Examples: array of TNGExample;
      const Epochs: Integer = 150;
      const LearningRate: Single = 0.04;
      const Regularization: Single = 0.0001): TNGEpochReportArray;

    { Inferência e Geração Autorregressiva }
    function Generate(const Question: string; const Context: array of string;
      const MaxTokens: Integer = 64): TNGGeneration; overload;
    function Generate(const Question: string; const MaxTokens: Integer = 64): TNGGeneration; overload;
    function Respond(const Question: string; Session: TNGSession): TNGGeneration;

    { Persistência de Modelos (.ngs) e Matrizes (.ngm) e Carregamento de Datasets (.json) }
    procedure SaveToFile(const FileName: string);
    procedure LoadFromFile(const FileName: string);
    procedure SaveMatrixNGM(const FileName: string);
    procedure LoadMatrixNGM(const FileName: string);

    class function LoadExamplesFromJSONFile(const FileName: string;
      const Partition: string = 'train'): TNGExampleArray;
    function CalibrateConfidence(const ValidationExamples: array of TNGExample): Single;
    function EvaluateDataset(const TestExamples: array of TNGExample): TNGEvalSummary;

    function TokenCount: Integer;
    function FeatureCount: Integer;
    function EdgeCount: Integer;
    function HiddenParamCount: Integer;

    property Decay: Single read FDecay write FDecay;
    property Confidence: Single read FConfidence write FConfidence;
    property UseHiddenLayers: Boolean read FUseHiddenLayers write FUseHiddenLayers;
    property HiddenDim1: Integer read FHiddenDim1 write FHiddenDim1;
    property HiddenDim2: Integer read FHiddenDim2 write FHiddenDim2;
    property OnProgress: TNGTrainProgressEvent read FOnProgress write FOnProgress;
  end;

{ Funções utilitárias de tokenização UTF-8 em Português }
function NGTokenize(const Text: string): TNGStringArray;
function NGJoinTokens(const Tokens: array of string; const Sep: string = ' '): string;
function NGLowerUTF8(const S: string): string;

implementation

const
  MAGIC_V7: array[0..7] of AnsiChar = ('N','G','C','T','X','0','0','7');
  MAGIC_NGM: array[0..7] of AnsiChar = ('N','G','M','A','P','0','0','1');

function NGLowerUTF8(const S: string): string;
var
  Res: string;
  I, L: Integer;
  B1, B2: Byte;
begin
  Res := LowerCase(S);
  { Converte caracteres acentuados maiúsculos UTF-8 de 2 bytes (0xC3 0x80..0x9F)
    para minúsculos equivalentes (0xC3 0xA0..0xBF) }
  L := Length(Res);
  I := 1;
  while I < L do
  begin
    B1 := Byte(Res[I]);
    if B1 = $C3 then
    begin
      B2 := Byte(Res[I + 1]);
      if (B2 >= $80) and (B2 <= $9E) and (B2 <> $97) then
        Res[I + 1] := AnsiChar(B2 + $20);
      Inc(I, 2);
    end
    else
      Inc(I);
  end;
  Result := Res;
end;

function IsUTF8WordByte(const S: string; var Idx: Integer; out CharBytes: string): Boolean;
var
  B1, B2: Byte;
begin
  CharBytes := '';
  if Idx > Length(S) then Exit(False);
  B1 := Byte(S[Idx]);
  if ((B1 >= Ord('a')) and (B1 <= Ord('z'))) or
     ((B1 >= Ord('0')) and (B1 <= Ord('9'))) then
  begin
    CharBytes := S[Idx];
    Inc(Idx);
    Exit(True);
  end;
  if (B1 = $C3) and (Idx < Length(S)) then
  begin
    B2 := Byte(S[Idx + 1]);
    if (B2 >= $A0) and (B2 <= $FE) and (B2 <> $B7) then
    begin
      CharBytes := Copy(S, Idx, 2);
      Inc(Idx, 2);
      Exit(True);
    end;
  end;
  Inc(Idx);
  Result := False;
end;

function NGTokenize(const Text: string): TNGStringArray;
var
  Low, Cur, Ch: string;
  Idx, Count: Integer;
begin
  Result := nil;
  Low := NGLowerUTF8(Text);
  Idx := 1;
  Cur := '';
  Count := 0;
  while Idx <= Length(Low) do
  begin
    if IsUTF8WordByte(Low, Idx, Ch) then
      Cur := Cur + Ch
    else if Cur <> '' then
    begin
      if Count >= Length(Result) then
        SetLength(Result, Max(16, Length(Result) * 2));
      Result[Count] := Cur;
      Inc(Count);
      Cur := '';
    end;
  end;
  if Cur <> '' then
  begin
    if Count >= Length(Result) then
      SetLength(Result, Count + 1);
    Result[Count] := Cur;
    Inc(Count);
  end;
  SetLength(Result, Count);
end;

function NGJoinTokens(const Tokens: array of string; const Sep: string): string;
var
  I: Integer;
begin
  Result := '';
  for I := 0 to High(Tokens) do
  begin
    if I > 0 then Result := Result + Sep;
    Result := Result + Tokens[I];
  end;
end;

{ Extrai os primeiros N caracteres lógicos UTF-8 de uma palavra }
function UTF8Prefix(const S: string; const MaxChars: Integer): string;
var
  I, Chars: Integer;
  B: Byte;
begin
  I := 1;
  Chars := 0;
  while (I <= Length(S)) and (Chars < MaxChars) do
  begin
    B := Byte(S[I]);
    if (B and $80) = 0 then Inc(I)
    else if (B and $E0) = $C0 then Inc(I, 2)
    else if (B and $F0) = $E0 then Inc(I, 3)
    else Inc(I, 4);
    Inc(Chars);
  end;
  Result := Copy(S, 1, I - 1);
end;

function UTF8LengthFast(const S: string): Integer;
var
  I: Integer;
  B: Byte;
begin
  Result := 0;
  I := 1;
  while I <= Length(S) do
  begin
    B := Byte(S[I]);
    if (B and $80) = 0 then Inc(I)
    else if (B and $E0) = $C0 then Inc(I, 2)
    else if (B and $F0) = $E0 then Inc(I, 3)
    else Inc(I, 4);
    Inc(Result);
  end;
end;

{ TNGSession }

constructor TNGSession.Create(const AMaxTurns: Integer);
begin
  inherited Create;
  FMaxTurns := Max(1, Min(8, AMaxTurns));
  SetLength(FHistory, 0);
end;

procedure TNGSession.Clear;
begin
  SetLength(FHistory, 0);
end;

procedure TNGSession.Remember(const Question: string);
var
  Toks: TNGStringArray;
  Norm: string;
  I, L: Integer;
begin
  Toks := NGTokenize(Question);
  if Length(Toks) > 64 then SetLength(Toks, 64);
  Norm := NGJoinTokens(Toks, ' ');
  L := Length(FHistory);
  if L < FMaxTurns then
  begin
    SetLength(FHistory, L + 1);
    FHistory[L] := Norm;
  end
  else
  begin
    for I := 0 to FMaxTurns - 2 do
      FHistory[I] := FHistory[I + 1];
    FHistory[FMaxTurns - 1] := Norm;
  end;
end;

function TNGSession.ContextArray: TNGStringArray;
begin
  Result := Copy(FHistory, 0, Length(FHistory));
end;

{ TNGDeepEngine }

constructor TNGDeepEngine.Create(const AUseHiddenLayers: Boolean;
  const AHiddenDim1, AHiddenDim2: Integer; const ADecay, AConfidence: Single);
begin
  inherited Create;
  FUseHiddenLayers := AUseHiddenLayers;
  FHiddenDim1 := Max(16, AHiddenDim1);
  FHiddenDim2 := Max(16, AHiddenDim2);
  FDecay := Max(0.0, Min(0.99, ADecay));
  FConfidence := Max(0.0, Min(1.0, AConfidence));

  FTokens := TStringList.Create;
  FTokens.CaseSensitive := True;
  FTokenHash := TFPHashList.Create;

  FFeatures := TStringList.Create;
  FFeatures.CaseSensitive := True;
  FFeatureHash := TFPHashList.Create;

  Clear;
end;

destructor TNGDeepEngine.Destroy;
begin
  FFeatureHash.Free;
  FFeatures.Free;
  FTokenHash.Free;
  FTokens.Free;
  inherited Destroy;
end;

procedure TNGDeepEngine.Clear;
begin
  FTokens.Clear;
  FTokenHash.Clear;
  FFeatures.Clear;
  FFeatureHash.Clear;
  SetLength(FFeatureIsStem, 0);
  SetLength(FSparseWeights, 0);
  SetLength(FSparseEdges, 0);
  SetLength(FW1, 0);
  SetLength(FB1, 0);
  SetLength(FW2, 0);
  SetLength(FB2, 0);
  SetLength(FWOut, 0);
  SetLength(FBOut, 0);

  EnsureToken(NG_EOS);
  EnsureToken(NG_REFUSE);
end;

function TNGDeepEngine.EnsureToken(const AToken: string): Integer;
var
  P: Pointer;
begin
  if AToken = '' then Exit(-1);
  P := FTokenHash.Find(AToken);
  if P <> nil then
    Exit(PtrInt(P) - 1);
  Result := FTokens.Add(AToken);
  FTokenHash.Add(AToken, Pointer(PtrInt(Result + 1)));
end;

function TNGDeepEngine.FindToken(const AToken: string): Integer;
var
  P: Pointer;
begin
  if AToken = '' then Exit(-1);
  P := FTokenHash.Find(AToken);
  if P = nil then Exit(-1);
  Result := PtrInt(P) - 1;
end;

function TNGDeepEngine.EnsureFeature(const AKey: string; const AIsStem: Boolean): Integer;
var
  P: Pointer;
begin
  if AKey = '' then Exit(-1);
  P := FFeatureHash.Find(AKey);
  if P <> nil then
    Exit(PtrInt(P) - 1);
  Result := FFeatures.Add(AKey);
  FFeatureHash.Add(AKey, Pointer(PtrInt(Result + 1)));
  if Result >= Length(FFeatureIsStem) then
    SetLength(FFeatureIsStem, Max(256, Length(FFeatureIsStem) * 2));
  FFeatureIsStem[Result] := AIsStem;
end;

function TNGDeepEngine.FindFeature(const AKey: string): Integer;
var
  P: Pointer;
begin
  if AKey = '' then Exit(-1);
  P := FFeatureHash.Find(AKey);
  if P = nil then Exit(-1);
  Result := PtrInt(P) - 1;
end;

function TNGDeepEngine.IsArticleOrPrep(const W: string): Boolean;
begin
  Result := (W = 'o') or (W = 'a') or (W = 'os') or (W = 'as') or
            (W = 'um') or (W = 'uma') or (W = 'uns') or (W = 'umas') or
            (W = 'de') or (W = 'do') or (W = 'da') or (W = 'dos') or
            (W = 'das') or (W = 'ao') or (W = 'à');
end;

function TNGDeepEngine.IsConnector(const W: string): Boolean;
begin
  Result := IsArticleOrPrep(W) or
            (W = 'em') or (W = 'no') or (W = 'na') or (W = 'nos') or (W = 'nas') or
            (W = 'por') or (W = 'para') or (W = 'com') or (W = 'sem') or
            (W = 'que') or (W = 'e') or (W = 'ou') or (W = 'se');
end;

function TNGDeepEngine.IsQuestionFrame(const W: string): Boolean;
begin
  Result := IsConnector(W) or
            (W = 'qual') or (W = 'quais') or (W = 'como') or (W = 'quando') or
            (W = 'onde') or (W = 'quem') or (W = 'quanto') or (W = 'quantos') or
            (W = 'é') or (W = 'são') or (W = 'foi') or (W = 'foram') or
            (W = 'era') or (W = 'ser') or (W = 'está') or (W = 'estão') or
            (W = 'explique') or (W = 'descreva') or (W = 'apresente') or
            (W = 'fale') or (W = 'diga') or (W = 'defina') or (W = 'resuma') or
            (W = 'conte') or (W = 'mostre') or (W = 'novo') or (W = 'novamente') or
            (W = 'sobre') or (W = 'funciona') or (W = 'serve') or (W = 'significa') or
            (W = 'conceito') or (W = 'importância') or (W = 'significado') or
            (W = 'função') or (W = 'objetivo') or (W = 'causa') or (W = 'descobriu') or
            (W = 'inventou') or (W = 'criou') or (W = 'existe') or (W = 'ocorreu') or
            (W = 'aconteceu') or (W = 'poderia') or (W = 'pode') or (W = 'me') or
            (W = 'explicar') or (W = 'dizer') or (W = 'ideia') or (W = 'lugar');
end;

procedure AddOrUpdateFeature(var Vec: TNGFeatureVec; var Count: Integer;
  const FID: Integer; const Val: Single; const Accumulate: Boolean = False);
var
  I: Integer;
begin
  if FID < 0 then Exit;
  for I := 0 to Count - 1 do
    if Vec[I].FeatureID = FID then
    begin
      if Accumulate then
        Vec[I].Value := Vec[I].Value + Val
      else
        Vec[I].Value := Val;
      Exit;
    end;
  if Count >= Length(Vec) then
    SetLength(Vec, Max(32, Length(Vec) * 2));
  Vec[Count].FeatureID := FID;
  Vec[Count].Value := Val;
  Inc(Count);
end;

procedure TNGDeepEngine.ExtractInputFeatures(const Question: string;
  const Context: array of string; out SourceFeats: TNGFeatureVec;
  out ConceptTokens: TNGStringArray; const CreateIfMissing: Boolean);
var
  Words, CtxWords, UniqueCtx: TNGStringArray;
  I, J, K, Count, CCount, UCount, FID, CharLen, AgeIdx, StartCtx: Integer;
  W, Key: string;
  Strength, DecayPow: Single;
  Seen: Boolean;

  function GetFeat(const KStr: string; const IsStem: Boolean = False): Integer;
  begin
    if CreateIfMissing then
      Result := EnsureFeature(KStr, IsStem)
    else
      Result := FindFeature(KStr);
  end;

begin
  SourceFeats := nil;
  ConceptTokens := nil;
  Count := 0;
  CCount := 0;

  Words := NGTokenize(Question);
  if Length(Words) > 64 then SetLength(Words, 64);

  for I := 0 to High(Words) do
  begin
    W := Words[I];
    if IsArticleOrPrep(W) then Strength := 0.25
    else if IsQuestionFrame(W) then Strength := 1.0
    else
    begin
      Strength := 1.25;
      { Registra conceito substantivo }
      Seen := False;
      for J := 0 to CCount - 1 do
        if ConceptTokens[J] = W then begin Seen := True; Break; end;
      if not Seen then
      begin
        SetLength(ConceptTokens, CCount + 1);
        ConceptTokens[CCount] := W;
        Inc(CCount);
      end;
    end;
    AddOrUpdateFeature(SourceFeats, Count, GetFeat('q'#9 + W), Strength);

    CharLen := UTF8LengthFast(W);
    if (CharLen >= 5) and (not IsQuestionFrame(W)) then
      AddOrUpdateFeature(SourceFeats, Count, GetFeat('stem'#9 + UTF8Prefix(W, 5), True), 0.20);
    if (CharLen >= 4) and (not IsQuestionFrame(W)) then
      AddOrUpdateFeature(SourceFeats, Count, GetFeat('stem4'#9 + UTF8Prefix(W, 4), True), 0.15);

    if IsArticleOrPrep(W) then Strength := 0.15 else Strength := 0.35;
    AddOrUpdateFeature(SourceFeats, Count, GetFeat('pos'#9 + IntToStr(I) + #9 + W), Strength);
  end;

  { Bigramas adjacentes }
  for I := 0 to High(Words) - 1 do
    AddOrUpdateFeature(SourceFeats, Count, GetFeat('pair'#9 + Words[I] + #9 + Words[I + 1]), 0.50);

  { Pares de conceitos semânticos (ignora conectores intermediários) }
  for I := 0 to CCount - 2 do
    for J := I + 1 to CCount - 1 do
      AddOrUpdateFeature(SourceFeats, Count,
        GetFeat('cpair'#9 + ConceptTokens[I] + #9 + ConceptTokens[J], True), 0.45);

  { Histórico de contexto dos últimos 3 turnos }
  StartCtx := Max(0, Length(Context) - 3);
  AgeIdx := 0;
  for I := High(Context) downto StartCtx do
  begin
    CtxWords := NGTokenize(Context[I]);
    if Length(CtxWords) > 64 then SetLength(CtxWords, 64);
    UniqueCtx := nil;
    UCount := 0;
    for J := 0 to High(CtxWords) do
    begin
      Seen := False;
      for K := 0 to UCount - 1 do
        if UniqueCtx[K] = CtxWords[J] then begin Seen := True; Break; end;
      if not Seen then
      begin
        SetLength(UniqueCtx, UCount + 1);
        UniqueCtx[UCount] := CtxWords[J];
        Inc(UCount);
      end;
    end;
    DecayPow := Power(0.5, AgeIdx);
    for J := 0 to UCount - 1 do
    begin
      FID := GetFeat('context'#9 + UniqueCtx[J]);
      AddOrUpdateFeature(SourceFeats, Count, FID, DecayPow, True);
    end;
    Inc(AgeIdx);
  end;

  SetLength(SourceFeats, Count);
end;

procedure TNGDeepEngine.BuildStepFeatures(const SourceFeats: TNGFeatureVec;
  const ConceptTokens: TNGStringArray; const Prefix: TNGStringArray;
  const MemoryKeys: TNGStringArray; const MemoryVals: array of Single;
  out StepFeats: TNGFeatureVec; const CreateIfMissing: Boolean);
var
  LastTok, BeforeTok, SrcKey: string;
  I, J, Count, FID: Integer;
  Covered: Boolean;

  function GetFeat(const KStr: string; const IsStem: Boolean = False): Integer;
  begin
    if CreateIfMissing then
      Result := EnsureFeature(KStr, IsStem)
    else
      Result := FindFeature(KStr);
  end;

begin
  StepFeats := nil;
  Count := 0;
  if Length(Prefix) > 0 then LastTok := Prefix[High(Prefix)] else LastTok := NG_BOS;
  if Length(Prefix) > 1 then BeforeTok := Prefix[High(Prefix) - 1] else BeforeTok := NG_BOS;

  AddOrUpdateFeature(StepFeats, Count, GetFeat('bias'), 1.0);
  AddOrUpdateFeature(StepFeats, Count, GetFeat('prev'#9 + LastTok), 1.0);
  AddOrUpdateFeature(StepFeats, Count, GetFeat('prev2'#9 + BeforeTok + #9 + LastTok), 1.0);
  AddOrUpdateFeature(StepFeats, Count, GetFeat('step'#9 + IntToStr(Length(Prefix))), 0.5);

  for I := 0 to High(SourceFeats) do
  begin
    FID := SourceFeats[I].FeatureID;
    AddOrUpdateFeature(StepFeats, Count, FID, SourceFeats[I].Value);
    if (FID >= 0) and (FID < FFeatures.Count) and (not FFeatureIsStem[FID]) then
    begin
      SrcKey := FFeatures[FID];
      AddOrUpdateFeature(StepFeats, Count,
        GetFeat('with_prev'#9 + SrcKey + #9 + LastTok), SourceFeats[I].Value);
    end;
  end;

  { Features de Atenção de Cobertura (quais conceitos da pergunta ainda faltam sair) }
  for I := 0 to High(ConceptTokens) do
  begin
    Covered := False;
    for J := 0 to High(Prefix) do
      if Prefix[J] = ConceptTokens[I] then
      begin
        Covered := True;
        Break;
      end;
    if not Covered then
      AddOrUpdateFeature(StepFeats, Count,
        GetFeat('pending'#9 + ConceptTokens[I], True), 0.40);
  end;

  for I := 0 to High(MemoryKeys) do
    if MemoryKeys[I] <> '' then
      AddOrUpdateFeature(StepFeats, Count,
        GetFeat('memory'#9 + MemoryKeys[I]), MemoryVals[I]);

  SetLength(StepFeats, Count);
end;

procedure TNGDeepEngine.AdvanceMemory(var MemoryKeys: TNGStringArray;
  var MemoryVals: array of Single; var MemCount: Integer; const NewToken: string);
var
  I, WriteIdx, FoundIdx: Integer;
  NewVal: Single;
begin
  WriteIdx := 0;
  FoundIdx := -1;
  for I := 0 to MemCount - 1 do
  begin
    NewVal := MemoryVals[I] * FDecay;
    if NewVal >= 0.001 then
    begin
      MemoryKeys[WriteIdx] := MemoryKeys[I];
      MemoryVals[WriteIdx] := NewVal;
      if MemoryKeys[WriteIdx] = NewToken then
        FoundIdx := WriteIdx;
      Inc(WriteIdx);
    end;
  end;
  MemCount := WriteIdx;
  if FoundIdx >= 0 then
    MemoryVals[FoundIdx] := MemoryVals[FoundIdx] + 1.0
  else if MemCount < Length(MemoryVals) then
  begin
    if MemCount >= Length(MemoryKeys) then
      SetLength(MemoryKeys, MemCount + 8);
    MemoryKeys[MemCount] := NewToken;
    MemoryVals[MemCount] := 1.0;
    Inc(MemCount);
  end;
end;

function TNGDeepEngine.SiLU(const X: Single): Single;
begin
  if X <= -15.0 then Result := 0.0
  else if X >= 15.0 then Result := X
  else Result := X / (1.0 + Exp(-X));
end;

function TNGDeepEngine.SiLUDeriv(const X: Single): Single;
var
  Sig: Single;
begin
  if X <= -15.0 then Result := 0.0
  else if X >= 15.0 then Result := 1.0
  else
  begin
    Sig := 1.0 / (1.0 + Exp(-X));
    Result := Sig * (1.0 + X * (1.0 - Sig));
  end;
end;

function TNGDeepEngine.Fit(const Examples: array of TNGExample;
  const Epochs: Integer; const LearningRate, Regularization: Single): TNGEpochReportArray;
type
  TNGSampleRecord = record
    Feats: TNGFeatureVec;
    TargetID: Integer;
  end;
var
  Samples: array of TNGSampleRecord;
  SampleCount, CapSamples: Integer;
  ExIdx, TokIdx, I, J, K, Epoch, StepNum, NumFeats, NumToks, H1, H2: Integer;
  AnsTokens, Prefix, MemKeys, Concepts: TNGStringArray;
  MemVals: array[0..127] of Single;
  MemCount: Integer;
  SourceFeats, StepFeats: TNGFeatureVec;

  // Matrizes de Treinamento e Momentos AdamW (Ramo Wide)
  W_Sparse, M_Sparse, V_Sparse: array of Single;
  // Momentos AdamW (Ramo Deep - Camadas Ocultas)
  M_W1, V_W1, M_B1, V_B1: array of Single;
  M_W2, V_W2, M_B2, V_B2: array of Single;
  M_WOut, V_WOut, M_BOut, V_BOut: array of Single;

  // Buffers de Forward & Backward por exemplo/lote
  Logits, Probs: array of Single;
  H1Pre, H1Act, H2Pre, H2Act: array of Single;
  GradH2, GradH2Pre, GradH1, GradH1Pre: array of Single;
  GradW1, GradB1, GradW2, GradB2, GradWOut, GradBOut: array of Single;
  GradSparse: array of Single;
  ActiveFeatMask: array of Boolean;
  ActiveFeatList: array of Integer;
  ActiveFeatCount: Integer;

  MaxLogit, SumExp, LossSum, AccCount, Val,GVal, StepScale, BiasCorr1, BiasCorr2: Single;
  PruneThreshold: Single;
  RandState: Cardinal;
  Perm: array of Integer;
  SwapTmp, SIdx, FID, TID, RowOff, EdgeCnt: Integer;
  EpochStartTime: QWord;
  AbortFlag: Boolean;

  function NextRandFloat: Single;
  begin
    RandState := RandState * 1664525 + 1013904223;
    Result := ((RandState shr 8) / 16777216.0) * 2.0 - 1.0;
  end;

begin
  Result := nil;
  if Length(Examples) = 0 then Exit;

  SampleCount := 0;
  CapSamples := 256;
  SetLength(Samples, CapSamples);

  { 1. Constrói amostras de transição token a token (Teacher Forcing) }
  for ExIdx := 0 to High(Examples) do
  begin
    if Length(NGTokenize(Examples[ExIdx].Question)) = 0 then Continue;
    if Examples[ExIdx].IsRefusal or (Trim(Examples[ExIdx].Answer) = '') then
    begin
      SetLength(AnsTokens, 1);
      AnsTokens[0] := NG_REFUSE;
    end
    else
    begin
      AnsTokens := NGTokenize(Examples[ExIdx].Answer);
      if Length(AnsTokens) = 0 then Continue;
      if Length(AnsTokens) > 62 then SetLength(AnsTokens, 62);
    end;

    { Anexa <eos> ao final da resposta }
    SetLength(AnsTokens, Length(AnsTokens) + 1);
    AnsTokens[High(AnsTokens)] := NG_EOS;

    for TokIdx := 0 to High(AnsTokens) do
      EnsureToken(AnsTokens[TokIdx]);

    ExtractInputFeatures(Examples[ExIdx].Question, Examples[ExIdx].Context,
      SourceFeats, Concepts, True);

    Prefix := nil;
    MemKeys := nil;
    MemCount := 0;

    for TokIdx := 0 to High(AnsTokens) do
    begin
      BuildStepFeatures(SourceFeats, Concepts, Prefix,
        Copy(MemKeys, 0, MemCount), MemVals, StepFeats, True);

      if SampleCount >= CapSamples then
      begin
        CapSamples := CapSamples * 2;
        SetLength(Samples, CapSamples);
      end;
      Samples[SampleCount].Feats := StepFeats;
      Samples[SampleCount].TargetID := EnsureToken(AnsTokens[TokIdx]);
      Inc(SampleCount);

      SetLength(Prefix, Length(Prefix) + 1);
      Prefix[High(Prefix)] := AnsTokens[TokIdx];
      AdvanceMemory(MemKeys, MemVals, MemCount, AnsTokens[TokIdx]);
    end;
  end;

  SetLength(Samples, SampleCount);
  if SampleCount = 0 then Exit;

  NumFeats := FFeatures.Count;
  NumToks := FTokens.Count;
  H1 := FHiddenDim1;
  H2 := FHiddenDim2;

  { 2. Inicializa Pesos Esparsos (Wide) preservando conhecimento anterior }
  SetLength(W_Sparse, NumFeats * NumToks);
  SetLength(M_Sparse, NumFeats * NumToks);
  SetLength(V_Sparse, NumFeats * NumToks);
  for I := 0 to High(W_Sparse) do
  begin
    W_Sparse[I] := 0.0;
    M_Sparse[I] := 0.0;
    V_Sparse[I] := 0.0;
  end;
  for FID := 0 to High(FSparseEdges) do
    if FID < NumFeats then
      for K := 0 to High(FSparseEdges[FID]) do
      begin
        TID := FSparseEdges[FID][K].TargetID;
        if (TID >= 0) and (TID < NumToks) then
          W_Sparse[FID * NumToks + TID] := FSparseEdges[FID][K].Weight;
      end;

  { 3. Inicializa Camadas Ocultas Não-Lineares (Deep MLP: W1, B1, W2, B2, WOut, BOut) }
  RandState := 42;
  if FUseHiddenLayers then
  begin
    SetLength(FW1, NumFeats * H1);
    SetLength(FB1, H1);
    SetLength(FW2, H1 * H2);
    SetLength(FB2, H2);
    SetLength(FWOut, H2 * NumToks);
    SetLength(FBOut, NumToks);

    Val := Sqrt(6.0 / (NumFeats + H1));
    for I := 0 to High(FW1) do FW1[I] := NextRandFloat * Val;
    for I := 0 to High(FB1) do FB1[I] := 0.0;

    Val := Sqrt(6.0 / (H1 + H2));
    for I := 0 to High(FW2) do FW2[I] := NextRandFloat * Val;
    for I := 0 to High(FB2) do FB2[I] := 0.0;

    { Inicialização Zero-Residual (estilo LoRA/ResNet) na projeção de saída do MLP }
    for I := 0 to High(FWOut) do FWOut[I] := 0.0;
    for I := 0 to High(FBOut) do FBOut[I] := 0.0;

    SetLength(M_W1, Length(FW1)); SetLength(V_W1, Length(FW1));
    SetLength(M_B1, H1);          SetLength(V_B1, H1);
    SetLength(M_W2, Length(FW2)); SetLength(V_W2, Length(FW2));
    SetLength(M_B2, H2);          SetLength(V_B2, H2);
    SetLength(M_WOut, Length(FWOut)); SetLength(V_WOut, Length(FWOut));
    SetLength(M_BOut, NumToks);   SetLength(V_BOut, NumToks);

    SetLength(H1Pre, H1); SetLength(H1Act, H1);
    SetLength(H2Pre, H2); SetLength(H2Act, H2);
    SetLength(GradH2, H2); SetLength(GradH2Pre, H2);
    SetLength(GradH1, H1); SetLength(GradH1Pre, H1);

    SetLength(GradW1, Length(FW1)); SetLength(GradB1, H1);
    SetLength(GradW2, Length(FW2)); SetLength(GradB2, H2);
    SetLength(GradWOut, Length(FWOut)); SetLength(GradBOut, NumToks);
  end;

  SetLength(Logits, NumToks);
  SetLength(Probs, NumToks);
  SetLength(GradSparse, NumFeats * NumToks);
  SetLength(ActiveFeatMask, NumFeats);
  SetLength(ActiveFeatList, NumFeats);
  SetLength(Perm, SampleCount);
  for I := 0 to SampleCount - 1 do Perm[I] := I;

  StepNum := 0;
  AbortFlag := False;

  { 4. Loop Principal de Épocas (Full-Batch / Mini-Batch Vectorized CPU AdamW) }
  for Epoch := 1 to Epochs do
  begin
    EpochStartTime := GetTickCount64;
    Inc(StepNum);

    { Zera acumuladores de gradiente da época }
    ActiveFeatCount := 0;
    for I := 0 to NumFeats - 1 do ActiveFeatMask[I] := False;

    if FUseHiddenLayers then
    begin
      FillChar(GradB1[0], H1 * SizeOf(Single), 0);
      FillChar(GradW2[0], Length(GradW2) * SizeOf(Single), 0);
      FillChar(GradB2[0], H2 * SizeOf(Single), 0);
      FillChar(GradWOut[0], Length(GradWOut) * SizeOf(Single), 0);
      FillChar(GradBOut[0], NumToks * SizeOf(Single), 0);
    end;

    LossSum := 0.0;
    AccCount := 0.0;

    for SIdx := 0 to SampleCount - 1 do
    begin
      StepFeats := Samples[SIdx].Feats;
      TID := Samples[SIdx].TargetID;

      { A. Forward Pass: Ramo Wide (Grafo Esparso) }
      for J := 0 to NumToks - 1 do
        Logits[J] := 0.0;

      for I := 0 to High(StepFeats) do
      begin
        FID := StepFeats[I].FeatureID;
        Val := StepFeats[I].Value;
        if not ActiveFeatMask[FID] then
        begin
          ActiveFeatMask[FID] := True;
          ActiveFeatList[ActiveFeatCount] := FID;
          Inc(ActiveFeatCount);
          FillChar(GradSparse[FID * NumToks], NumToks * SizeOf(Single), 0);
          if FUseHiddenLayers then
            FillChar(GradW1[FID * H1], H1 * SizeOf(Single), 0);
        end;
        RowOff := FID * NumToks;
        for J := 0 to NumToks - 1 do
          Logits[J] := Logits[J] + Val * W_Sparse[RowOff + J];
      end;

      { B. Forward Pass: Ramo Deep (Camadas Ocultas Não-Lineares SiLU sobre features base) }
      if FUseHiddenLayers and (Epoch > (Epochs div 2)) then
      begin
        for J := 0 to H1 - 1 do H1Pre[J] := FB1[J];
        for I := 0 to High(StepFeats) do
        begin
          FID := StepFeats[I].FeatureID;
          if Pos('with_prev'#9, FFeatures[FID]) = 1 then Continue;
          Val := StepFeats[I].Value;
          RowOff := FID * H1;
          for J := 0 to H1 - 1 do
            H1Pre[J] := H1Pre[J] + Val * FW1[RowOff + J];
        end;
        for J := 0 to H1 - 1 do H1Act[J] := SiLU(H1Pre[J]);

        for J := 0 to H2 - 1 do H2Pre[J] := FB2[J];
        for I := 0 to H1 - 1 do
        begin
          Val := H1Act[I];
          if Abs(Val) > 1e-9 then
          begin
            RowOff := I * H2;
            for J := 0 to H2 - 1 do
              H2Pre[J] := H2Pre[J] + Val * FW2[RowOff + J];
          end;
        end;
        for J := 0 to H2 - 1 do H2Act[J] := SiLU(H2Pre[J]);

        for I := 0 to H2 - 1 do
        begin
          Val := H2Act[I];
          if Abs(Val) > 1e-9 then
          begin
            RowOff := I * NumToks;
            for J := 0 to NumToks - 1 do
              Logits[J] := Logits[J] + Val * FWOut[RowOff + J];
          end;
        end;
      end;

      { C. Softmax Estável + Loss + Acurácia }
      MaxLogit := Logits[0];
      SwapTmp := 0;
      for J := 1 to NumToks - 1 do
        if Logits[J] > MaxLogit then
        begin
          MaxLogit := Logits[J];
          SwapTmp := J;
        end;
      if SwapTmp = TID then
        AccCount := AccCount + 1.0;

      SumExp := 0.0;
      for J := 0 to NumToks - 1 do
      begin
        Probs[J] := Exp(Logits[J] - MaxLogit);
        SumExp := SumExp + Probs[J];
      end;
      for J := 0 to NumToks - 1 do
        Probs[J] := Probs[J] / SumExp;

      LossSum := LossSum - Ln(Max(1e-12, Probs[TID]));

      { D. Gradiente de Saída: dL/dLogits = (Probs - Y) / N }
      Probs[TID] := Probs[TID] - 1.0;

      { Acumula Gradiente do Ramo Wide }
      for I := 0 to High(StepFeats) do
      begin
        FID := StepFeats[I].FeatureID;
        Val := StepFeats[I].Value;
        RowOff := FID * NumToks;
        for J := 0 to NumToks - 1 do
          GradSparse[RowOff + J] := GradSparse[RowOff + J] + Val * Probs[J];
      end;

      { E. Backpropagation pelas Camadas Ocultas (Ramo Deep Residual para conflitos não-lineares) }
      if FUseHiddenLayers and (Epoch > (Epochs div 2)) and (Probs[TID] < -0.25) then
      begin
        for I := 0 to H2 - 1 do
        begin
          RowOff := I * NumToks;
          GVal := 0.0;
          Val := H2Act[I];
          for J := 0 to NumToks - 1 do
          begin
            GVal := GVal + Probs[J] * FWOut[RowOff + J];
            GradWOut[RowOff + J] := GradWOut[RowOff + J] + Val * Probs[J];
          end;
          GradH2[I] := GVal;
          GradH2Pre[I] := GVal * SiLUDeriv(H2Pre[I]);
          GradB2[I] := GradB2[I] + GradH2Pre[I];
        end;

        for I := 0 to H1 - 1 do
        begin
          RowOff := I * H2;
          GVal := 0.0;
          Val := H1Act[I];
          for J := 0 to H2 - 1 do
          begin
            GVal := GVal + GradH2Pre[J] * FW2[RowOff + J];
            GradW2[RowOff + J] := GradW2[RowOff + J] + Val * GradH2Pre[J];
          end;
          GradH1[I] := GVal;
          GradH1Pre[I] := GVal * SiLUDeriv(H1Pre[I]);
          GradB1[I] := GradB1[I] + GradH1Pre[I];
        end;

        for I := 0 to High(StepFeats) do
        begin
          FID := StepFeats[I].FeatureID;
          if Pos('with_prev'#9, FFeatures[FID]) = 1 then Continue;
          Val := StepFeats[I].Value;
          RowOff := FID * H1;
          for J := 0 to H1 - 1 do
            GradW1[RowOff + J] := GradW1[RowOff + J] + Val * GradH1Pre[J];
        end;
      end;
    end;

    { 5. Atualização AdamW para Ramo Wide e Ramo Deep }
    BiasCorr1 := 1.0 - Power(0.9, StepNum);
    BiasCorr2 := Sqrt(1.0 - Power(0.999, StepNum));
    StepScale := LearningRate * (BiasCorr2 / BiasCorr1);
    Val := 1.0 / SampleCount;

    for K := 0 to ActiveFeatCount - 1 do
    begin
      FID := ActiveFeatList[K];
      RowOff := FID * NumToks;
      for J := 0 to NumToks - 1 do
      begin
        GVal := GradSparse[RowOff + J] * Val + Regularization * W_Sparse[RowOff + J];
        M_Sparse[RowOff + J] := 0.9 * M_Sparse[RowOff + J] + 0.1 * GVal;
        V_Sparse[RowOff + J] := 0.999 * V_Sparse[RowOff + J] + 0.001 * (GVal * GVal);
        W_Sparse[RowOff + J] := W_Sparse[RowOff + J] -
          StepScale * M_Sparse[RowOff + J] / (Sqrt(V_Sparse[RowOff + J]) + 1e-8);
      end;

      if FUseHiddenLayers and (Epoch > (Epochs div 2)) and (Pos('with_prev'#9, FFeatures[FID]) <> 1) then
      begin
        RowOff := FID * H1;
        for J := 0 to H1 - 1 do
        begin
          GVal := GradW1[RowOff + J] * Val + (Regularization * 0.1) * FW1[RowOff + J];
          M_W1[RowOff + J] := 0.9 * M_W1[RowOff + J] + 0.1 * GVal;
          V_W1[RowOff + J] := 0.999 * V_W1[RowOff + J] + 0.001 * (GVal * GVal);
          FW1[RowOff + J] := FW1[RowOff + J] -
            StepScale * M_W1[RowOff + J] / (Sqrt(V_W1[RowOff + J]) + 1e-8);
        end;
      end;
    end;

    if FUseHiddenLayers and (Epoch > (Epochs div 2)) then
    begin
      for I := 0 to H1 - 1 do
      begin
        GVal := GradB1[I] * Val;
        M_B1[I] := 0.9 * M_B1[I] + 0.1 * GVal;
        V_B1[I] := 0.999 * V_B1[I] + 0.001 * (GVal * GVal);
        FB1[I] := FB1[I] - StepScale * M_B1[I] / (Sqrt(V_B1[I]) + 1e-8);
      end;
      for I := 0 to High(FW2) do
      begin
        GVal := GradW2[I] * Val + (Regularization * 0.1) * FW2[I];
        M_W2[I] := 0.9 * M_W2[I] + 0.1 * GVal;
        V_W2[I] := 0.999 * V_W2[I] + 0.001 * (GVal * GVal);
        FW2[I] := FW2[I] - StepScale * M_W2[I] / (Sqrt(V_W2[I]) + 1e-8);
      end;
      for I := 0 to H2 - 1 do
      begin
        GVal := GradB2[I] * Val;
        M_B2[I] := 0.9 * M_B2[I] + 0.1 * GVal;
        V_B2[I] := 0.999 * V_B2[I] + 0.001 * (GVal * GVal);
        FB2[I] := FB2[I] - StepScale * M_B2[I] / (Sqrt(V_B2[I]) + 1e-8);
      end;
      for I := 0 to High(FWOut) do
      begin
        GVal := GradWOut[I] * Val + (Regularization * 0.1) * FWOut[I];
        M_WOut[I] := 0.9 * M_WOut[I] + 0.1 * GVal;
        V_WOut[I] := 0.999 * V_WOut[I] + 0.001 * (GVal * GVal);
        FWOut[I] := FWOut[I] - StepScale * M_WOut[I] / (Sqrt(V_WOut[I]) + 1e-8);
      end;
    end;

    { Registra progresso em épocas-chave }
    if (Epoch = 1) or (Epoch = Epochs) or (Epoch mod 15 = 0) then
    begin
      K := Length(Result);
      SetLength(Result, K + 1);
      Result[K].Epoch := Epoch;
      Result[K].CrossEntropyLoss := LossSum / SampleCount;
      Result[K].TokenAccuracy := AccCount / SampleCount;
      Result[K].ElapsedMs := GetTickCount64 - EpochStartTime;
    end;

    if Assigned(FOnProgress) then
    begin
      FOnProgress(Epoch, Epochs, LossSum / SampleCount, AccCount / SampleCount, AbortFlag);
      if AbortFlag then Break;
    end;
  end;

  { 6. Compacta Arestas Esparsas (Pruning de pesos desprezíveis) }
  if NumToks > 200 then PruneThreshold := 0.025 else PruneThreshold := 0.005;
  SetLength(FSparseEdges, NumFeats);
  for FID := 0 to NumFeats - 1 do
  begin
    EdgeCnt := 0;
    RowOff := FID * NumToks;
    for TID := 0 to NumToks - 1 do
      if Abs(W_Sparse[RowOff + TID]) >= PruneThreshold then
        Inc(EdgeCnt);
    SetLength(FSparseEdges[FID], EdgeCnt);
    EdgeCnt := 0;
    for TID := 0 to NumToks - 1 do
    begin
      Val := W_Sparse[RowOff + TID];
      if Abs(Val) >= PruneThreshold then
      begin
        FSparseEdges[FID][EdgeCnt].TargetID := TID;
        FSparseEdges[FID][EdgeCnt].Weight := Val;
        Inc(EdgeCnt);
      end;
    end;
  end;
end;

function TNGDeepEngine.HasKnownConcept(const Question: string;
  const Context: array of string): Boolean;
var
  Words, CtxWords, Concepts: TNGStringArray;
  I, J, StartCtx, CCount, CharLen: Integer;
  W, Focus: string;
begin
  if FFeatures.Count = 0 then Exit(False);
  StartCtx := Max(0, Length(Context) - 3);
  for I := StartCtx to High(Context) do
  begin
    CtxWords := NGTokenize(Context[I]);
    for J := 0 to Min(63, High(CtxWords)) do
    begin
      W := CtxWords[J];
      if (not IsConnector(W)) and
         ((FindFeature('context'#9 + W) >= 0) or (FindFeature('q'#9 + W) >= 0)) then
        Exit(True);
    end;
  end;

  Words := NGTokenize(Question);
  if Length(Words) = 0 then Exit(False);
  if Length(Words) > 64 then SetLength(Words, 64);

  Focus := Words[High(Words)];
  if not IsQuestionFrame(Focus) then
  begin
    CharLen := UTF8LengthFast(Focus);
    if (FindFeature('q'#9 + Focus) < 0) and
       ((CharLen < 5) or (FindFeature('stem'#9 + UTF8Prefix(Focus, 5)) < 0)) and
       ((CharLen < 4) or (FindFeature('stem4'#9 + UTF8Prefix(Focus, 4)) < 0)) then
      Exit(False);
  end;

  CCount := 0;
  for I := 0 to High(Words) do
    if not IsQuestionFrame(Words[I]) then
    begin
      SetLength(Concepts, CCount + 1);
      Concepts[CCount] := Words[I];
      Inc(CCount);
    end;

  if CCount > 0 then
  begin
    for I := 0 to CCount - 1 do
    begin
      W := Concepts[I];
      CharLen := UTF8LengthFast(W);
      if (FindFeature('q'#9 + W) >= 0) or
         ((CharLen >= 5) and (FindFeature('stem'#9 + UTF8Prefix(W, 5)) >= 0)) or
         ((CharLen >= 4) and (FindFeature('stem4'#9 + UTF8Prefix(W, 4)) >= 0)) then
        Exit(True);
    end;
    Exit(False);
  end;

  for I := 0 to High(Words) do
    if FindFeature('q'#9 + Words[I]) >= 0 then
      Exit(True);
  Result := False;
end;

procedure TNGDeepEngine.PredictNext(const ActiveFeats: TNGFeatureVec;
  const Prefix: TNGStringArray; out BestToken: string; out BestProb: Single);
var
  Scores, H1Vec, H2Vec: array of Single;
  NumToks, H1, H2, I, J, FID, TID, RowOff, BestIdx: Integer;
  ActVal, BestScore, SumExp: Single;
  LastTok: string;
begin
  NumToks := FTokens.Count;
  if NumToks = 0 then
  begin
    BestToken := NG_REFUSE;
    BestProb := 1.0;
    Exit;
  end;

  SetLength(Scores, NumToks);
  for J := 0 to NumToks - 1 do Scores[J] := 0.0;

  { 1. Contribuição do Ramo Wide (Grafo Esparso) }
  for I := 0 to High(ActiveFeats) do
  begin
    FID := ActiveFeats[I].FeatureID;
    ActVal := ActiveFeats[I].Value;
    if (FID >= 0) and (FID < Length(FSparseEdges)) then
      for J := 0 to High(FSparseEdges[FID]) do
      begin
        TID := FSparseEdges[FID][J].TargetID;
        Scores[TID] := Scores[TID] + ActVal * FSparseEdges[FID][J].Weight;
      end;
  end;

  { 2. Contribuição do Ramo Deep (Camadas Ocultas Não-Lineares SiLU) }
  if FUseHiddenLayers and (Length(FW1) > 0) and (Length(FWOut) = FHiddenDim2 * NumToks) then
  begin
    H1 := FHiddenDim1;
    H2 := FHiddenDim2;
    SetLength(H1Vec, H1);
    SetLength(H2Vec, H2);

    for J := 0 to H1 - 1 do H1Vec[J] := FB1[J];
    for I := 0 to High(ActiveFeats) do
    begin
      FID := ActiveFeats[I].FeatureID;
      if (FID < 0) or (FID >= FFeatures.Count) then Continue;
      if Pos('with_prev'#9, FFeatures[FID]) = 1 then Continue;
      ActVal := ActiveFeats[I].Value;
      if (FID + 1) * H1 <= Length(FW1) then
      begin
        RowOff := FID * H1;
        for J := 0 to H1 - 1 do
          H1Vec[J] := H1Vec[J] + ActVal * FW1[RowOff + J];
      end;
    end;
    for J := 0 to H1 - 1 do H1Vec[J] := SiLU(H1Vec[J]);

    for J := 0 to H2 - 1 do H2Vec[J] := FB2[J];
    for I := 0 to H1 - 1 do
    begin
      ActVal := H1Vec[I];
      if Abs(ActVal) > 1e-9 then
      begin
        RowOff := I * H2;
        for J := 0 to H2 - 1 do
          H2Vec[J] := H2Vec[J] + ActVal * FW2[RowOff + J];
      end;
    end;
    for J := 0 to H2 - 1 do H2Vec[J] := SiLU(H2Vec[J]);

    for I := 0 to H2 - 1 do
    begin
      ActVal := H2Vec[I];
      if Abs(ActVal) > 1e-9 then
      begin
        RowOff := I * NumToks;
        for J := 0 to NumToks - 1 do
          Scores[J] := Scores[J] + ActVal * FWOut[RowOff + J];
      end;
    end;
  end;

  { 3. Penalidade de repetição imediata e de bigramas }
  if Length(Prefix) > 0 then
  begin
    LastTok := Prefix[High(Prefix)];
    TID := FindToken(LastTok);
    if TID >= 0 then
      Scores[TID] := Scores[TID] - 2.5;
    if Length(Prefix) >= 2 then
      for I := 0 to High(Prefix) - 1 do
        if Prefix[I] = LastTok then
        begin
          TID := FindToken(Prefix[I + 1]);
          if TID >= 0 then
            Scores[TID] := Scores[TID] - 1.5;
        end;
  end;

  BestIdx := 0;
  BestScore := Scores[0];
  for J := 1 to NumToks - 1 do
    if Scores[J] > BestScore then
    begin
      BestScore := Scores[J];
      BestIdx := J;
    end;

  SumExp := 0.0;
  for J := 0 to NumToks - 1 do
    if Scores[J] - BestScore > -30.0 then
      SumExp := SumExp + Exp(Scores[J] - BestScore);

  BestToken := FTokens[BestIdx];
  BestProb := 1.0 / Max(1.0, SumExp);
end;

function TNGDeepEngine.Generate(const Question: string;
  const Context: array of string; const MaxTokens: Integer): TNGGeneration;
var
  SourceFeats, StepFeats: TNGFeatureVec;
  Concepts, Prefix, MemKeys: TNGStringArray;
  MemVals: array[0..127] of Single;
  MemCount, Step: Integer;
  NextTok: string;
  Prob: Single;
  T0: QWord;
begin
  T0 := GetTickCount64;
  Result.Text := NG_ABSTAIN_MSG;
  Result.Tokens := nil;
  Result.Probabilities := nil;
  Result.Abstained := True;
  Result.Reason := 'empty_input';
  Result.LatencyMs := 0.0;

  if Length(NGTokenize(Question)) = 0 then Exit;
  if not HasKnownConcept(Question, Context) then
  begin
    Result.Reason := 'unknown_concept';
    Result.LatencyMs := GetTickCount64 - T0;
    Exit;
  end;

  ExtractInputFeatures(Question, Context, SourceFeats, Concepts, False);
  Prefix := nil;
  MemKeys := nil;
  MemCount := 0;

  for Step := 1 to Max(1, Min(256, MaxTokens)) do
  begin
    BuildStepFeatures(SourceFeats, Concepts, Prefix,
      Copy(MemKeys, 0, MemCount), MemVals, StepFeats, False);
    PredictNext(StepFeats, Prefix, NextTok, Prob);

    SetLength(Result.Probabilities, Length(Result.Probabilities) + 1);
    Result.Probabilities[High(Result.Probabilities)] := Prob;

    if (NextTok = NG_REFUSE) or (Prob < FConfidence) then
    begin
      Result.Reason := 'refused_or_low_confidence';
      Result.LatencyMs := GetTickCount64 - T0;
      Exit;
    end;

    if NextTok = NG_EOS then
    begin
      if Length(Prefix) = 0 then
      begin
        Result.Reason := 'empty_generation';
        Result.LatencyMs := GetTickCount64 - T0;
        Exit;
      end;
      Result.Text := NGJoinTokens(Prefix, ' ');
      Result.Tokens := Prefix;
      Result.Abstained := False;
      Result.Reason := 'eos';
      Result.LatencyMs := GetTickCount64 - T0;
      Exit;
    end;

    SetLength(Prefix, Length(Prefix) + 1);
    Prefix[High(Prefix)] := NextTok;
    AdvanceMemory(MemKeys, MemVals, MemCount, NextTok);
  end;

  Result.Reason := 'token_budget';
  Result.LatencyMs := GetTickCount64 - T0;
end;

function TNGDeepEngine.Generate(const Question: string; const MaxTokens: Integer): TNGGeneration;
var
  EmptyCtx: array of string;
begin
  EmptyCtx := nil;
  Result := Generate(Question, EmptyCtx, MaxTokens);
end;

function TNGDeepEngine.Respond(const Question: string; Session: TNGSession): TNGGeneration;
begin
  Result := Generate(Question, Session.ContextArray);
  Session.Remember(Question);
end;

procedure TNGDeepEngine.SaveToFile(const FileName: string);
var
  FS: TFileStream;
  RootObj: TJSONObject;
  TokArr, FeatArr, SubArr: TJSONArray;
  MetaBytes: AnsiString;
  SchemaVer, MetaLen, TotalEdges, SrcID, TgtID: LongWord;
  I, J, P1: Integer;
  W: Single;
  FKey, Part, CompanionNGM: string;
  Digest: array[0..31] of Byte;
  MLPFlag, H1L, H2L, W1Len, W2Len, WOutLen: LongWord;
begin
  if LowerCase(ExtractFileExt(FileName)) = '.ngm' then
  begin
    SaveMatrixNGM(FileName);
    Exit;
  end;
  ForceDirectories(ExtractFileDir(ExpandFileName(FileName)));
  RootObj := TJSONObject.Create;
  try
    RootObj.Add('version', 7);
    RootObj.Add('architecture', 'recurrent-loglinear-token-graph');
    RootObj.Add('engine', 'pascal-deep-mlp-v8');
    RootObj.Add('decay', FDecay);
    RootObj.Add('confidence', FConfidence);
    RootObj.Add('use_hidden_layers', FUseHiddenLayers);
    RootObj.Add('hidden_dim1', FHiddenDim1);
    RootObj.Add('hidden_dim2', FHiddenDim2);

    TokArr := TJSONArray.Create;
    for I := 0 to FTokens.Count - 1 do
      TokArr.Add(FTokens[I]);
    RootObj.Add('tokens', TokArr);

    FeatArr := TJSONArray.Create;
    for I := 0 to FFeatures.Count - 1 do
    begin
      SubArr := TJSONArray.Create;
      FKey := FFeatures[I];
      while FKey <> '' do
      begin
        P1 := Pos(#9, FKey);
        if P1 > 0 then
        begin
          Part := Copy(FKey, 1, P1 - 1);
          Delete(FKey, 1, P1);
        end
        else
        begin
          Part := FKey;
          FKey := '';
        end;
        SubArr.Add(Part);
      end;
      FeatArr.Add(SubArr);
    end;
    RootObj.Add('features', FeatArr);

    MetaBytes := RootObj.AsJSON;
  finally
    RootObj.Free;
  end;

  TotalEdges := 0;
  for I := 0 to High(FSparseEdges) do
    Inc(TotalEdges, Length(FSparseEdges[I]));

  FS := TFileStream.Create(FileName, fmCreate);
  try
    FS.WriteBuffer(MAGIC_V7[0], 8);
    SchemaVer := 1;
    MetaLen := Length(MetaBytes);
    FS.WriteBuffer(SchemaVer, 4);
    FS.WriteBuffer(MetaLen, 4);
    FS.WriteBuffer(TotalEdges, 4);
    if MetaLen > 0 then
      FS.WriteBuffer(MetaBytes[1], MetaLen);

    for I := 0 to High(FSparseEdges) do
    begin
      SrcID := LongWord(I);
      for J := 0 to High(FSparseEdges[I]) do
      begin
        TgtID := LongWord(FSparseEdges[I][J].TargetID);
        W := FSparseEdges[I][J].Weight;
        FS.WriteBuffer(SrcID, 4);
        FS.WriteBuffer(TgtID, 4);
        FS.WriteBuffer(W, 4);
      end;
    end;

    { Trailer opcional para Camadas Ocultas Nativas Pascal (NGMLP008) }
    if FUseHiddenLayers and (Length(FW1) > 0) then
    begin
      MLPFlag := $38504C4D; // 'MLP8'
      H1L := LongWord(FHiddenDim1);
      H2L := LongWord(FHiddenDim2);
      W1Len := LongWord(Length(FW1));
      W2Len := LongWord(Length(FW2));
      WOutLen := LongWord(Length(FWOut));
      FS.WriteBuffer(MLPFlag, 4);
      FS.WriteBuffer(H1L, 4);
      FS.WriteBuffer(H2L, 4);
      FS.WriteBuffer(W1Len, 4);
      FS.WriteBuffer(W2Len, 4);
      FS.WriteBuffer(WOutLen, 4);
      FS.WriteBuffer(FW1[0], W1Len * SizeOf(Single));
      FS.WriteBuffer(FB1[0], H1L * SizeOf(Single));
      FS.WriteBuffer(FW2[0], W2Len * SizeOf(Single));
      FS.WriteBuffer(FB2[0], H2L * SizeOf(Single));
      FS.WriteBuffer(FWOut[0], WOutLen * SizeOf(Single));
      FS.WriteBuffer(FBOut[0], LongWord(FTokens.Count) * SizeOf(Single));
    end;

    FillChar(Digest[0], 32, $A5);
    FS.WriteBuffer(Digest[0], 32);
  finally
    FS.Free;
  end;

  { Sincroniza automaticamente a matriz binária .ngm companheira quando salvar .ngs }
  if LowerCase(ExtractFileExt(FileName)) = '.ngs' then
  begin
    CompanionNGM := ChangeFileExt(FileName, '.ngm');
    if CompanionNGM <> FileName then
    begin
      try
        SaveMatrixNGM(CompanionNGM);
      except
      end;
    end;
  end;
end;

procedure TNGDeepEngine.SaveMatrixNGM(const FileName: string);
type
  TNGMTokenEdge = record
    SrcTok, TgtTok: LongWord;
    Weight: Single;
  end;
var
  FS, TmpNGS: TFileStream;
  TokEdges: array of TNGMTokenEdge;
  TokEdgeCount, TokCount, L, SrcTokID, TgtTokID: LongWord;
  I, J, P1, TokIdx: Integer;
  FKey, PrefixType, TokStr, TmpFile: string;
  UTF8Tok: UTF8String;
  W: Single;
begin
  ForceDirectories(ExtractFileDir(ExpandFileName(FileName)));
  TokCount := LongWord(FTokens.Count);
  SetLength(TokEdges, 0);
  TokEdgeCount := 0;

  { Extrai arestas direcionadas Token -> Token a partir das features aprendidas (prev / q) }
  for I := 0 to High(FSparseEdges) do
  begin
    if I >= FFeatures.Count then Break;
    FKey := FFeatures[I];
    P1 := Pos(#9, FKey);
    if P1 <= 0 then Continue;
    PrefixType := Copy(FKey, 1, P1 - 1);
    if (PrefixType <> 'prev') and (PrefixType <> 'q') then Continue;
    TokStr := Copy(FKey, P1 + 1, Length(FKey));
    if Pos(#9, TokStr) > 0 then Continue;
    TokIdx := FindToken(TokStr);
    if TokIdx < 0 then Continue;
    SrcTokID := LongWord(TokIdx);

    for J := 0 to High(FSparseEdges[I]) do
    begin
      TgtTokID := LongWord(FSparseEdges[I][J].TargetID);
      if SrcTokID = TgtTokID then Continue;
      W := FSparseEdges[I][J].Weight;
      if Abs(W) < 0.005 then Continue;
      if TokEdgeCount >= LongWord(Length(TokEdges)) then
        SetLength(TokEdges, Length(TokEdges) + 1024);
      TokEdges[TokEdgeCount].SrcTok := SrcTokID;
      TokEdges[TokEdgeCount].TgtTok := TgtTokID;
      TokEdges[TokEdgeCount].Weight := W;
      Inc(TokEdgeCount);
    end;
  end;

  FS := TFileStream.Create(FileName, fmCreate);
  try
    { 1. Bloco padrão NGMAP001 compatível com NeuroGraphStore.pas }
    FS.WriteBuffer(MAGIC_NGM[0], 8);
    FS.WriteBuffer(TokCount, 4);
    FS.WriteBuffer(TokEdgeCount, 4);
    for I := 0 to Integer(TokCount) - 1 do
    begin
      UTF8Tok := UTF8String(FTokens[I]);
      L := Length(UTF8Tok);
      FS.WriteBuffer(L, 4);
      if L > 0 then
        FS.WriteBuffer(UTF8Tok[1], L);
    end;
    for I := 0 to Integer(TokEdgeCount) - 1 do
    begin
      FS.WriteBuffer(TokEdges[I].SrcTok, 4);
      FS.WriteBuffer(TokEdges[I].TgtTok, 4);
      FS.WriteBuffer(TokEdges[I].Weight, 4);
    end;

    { 2. Bloco estendido NGCTX007 + NGMLP008 (Camadas Ocultas + Features) }
    TmpFile := FileName + '.ngs_tmp';
    try
      SaveToFile(TmpFile);
      TmpNGS := TFileStream.Create(TmpFile, fmOpenRead or fmShareDenyWrite);
      try
        FS.CopyFrom(TmpNGS, TmpNGS.Size);
      finally
        TmpNGS.Free;
      end;
    finally
      if FileExists(TmpFile) then DeleteFile(TmpFile);
      if FileExists(ChangeFileExt(TmpFile, '.ngm')) then
        DeleteFile(ChangeFileExt(TmpFile, '.ngm'));
    end;
  finally
    FS.Free;
  end;
end;

procedure TNGDeepEngine.LoadMatrixNGM(const FileName: string);
type
  TNGRawEdge = packed record
    SrcTok: LongWord;
    TgtTok: LongWord;
    Weight: Single;
  end;
var
  FS, TmpNGS: TFileStream;
  HeaderMagic: array[0..7] of AnsiChar;
  N, M, L, A, B, I: LongWord;
  UTF8Tok: UTF8String;
  W: Single;
  TmpFile: string;
  NextMagic: array[0..7] of AnsiChar;
  SrcFeatID: Integer;
  RawEdges: array of TNGRawEdge;
  TokFeatMap: array of Integer;
begin
  Clear;
  FS := TFileStream.Create(FileName, fmOpenRead or fmShareDenyWrite);
  try
    if FS.Size < 16 then
      raise Exception.Create('Arquivo .ngm inválido ou truncado.');
    FS.ReadBuffer(HeaderMagic[0], 8);
    if CompareMem(@HeaderMagic[0], @MAGIC_V7[0], 8) then
    begin
      FS.Free;
      FS := nil;
      LoadFromFile(FileName);
      Exit;
    end;
    if not CompareMem(@HeaderMagic[0], @MAGIC_NGM[0], 8) then
      raise Exception.Create('Cabeçalho .ngm incompatível (esperado NGMAP001).');

    FS.ReadBuffer(N, 4);
    FS.ReadBuffer(M, 4);
    if (N = 1) and (M > 1) and (FS.Size - FS.Position > Int64(M) * 4) then
    begin
      N := M;
      FS.ReadBuffer(M, 4);
    end;

    FTokens.Clear;
    FTokenHash.Clear;
    for I := 1 to N do
    begin
      FS.ReadBuffer(L, 4);
      SetLength(UTF8Tok, L);
      if L > 0 then
        FS.ReadBuffer(UTF8Tok[1], L);
      EnsureToken(string(UTF8Tok));
    end;

    { Se houver bloco estendido NGCTX007 + NGMLP008 após as arestas NGMAP001, carrega-o }
    if FS.Position + Int64(M) * 12 + 52 <= FS.Size then
    begin
      FS.Seek(Int64(M) * 12, soCurrent);
      FS.ReadBuffer(NextMagic[0], 8);
      if CompareMem(@NextMagic[0], @MAGIC_V7[0], 8) then
      begin
        FS.Seek(-8, soCurrent);
        TmpFile := FileName + '.load_tmp.ngs';
        TmpNGS := TFileStream.Create(TmpFile, fmCreate);
        try
          TmpNGS.CopyFrom(FS, FS.Size - FS.Position);
        finally
          TmpNGS.Free;
        end;
        try
          LoadFromFile(TmpFile);
        finally
          if FileExists(TmpFile) then DeleteFile(TmpFile);
        end;
        Exit;
      end;
      FS.Seek(-(Int64(M) * 12 + 8), soCurrent);
    end;

    { Caso seja um arquivo .ngm puro (apenas arestas token -> token) }
    EnsureToken(NG_EOS);
    EnsureToken(NG_REFUSE);
    SetLength(TokFeatMap, FTokens.Count);
    for I := 0 to LongWord(FTokens.Count - 1) do
      TokFeatMap[I] := EnsureFeature('q'#9 + FTokens[I]);

    SetLength(FSparseEdges, FFeatures.Count + 16);
    if M > 0 then
    begin
      SetLength(RawEdges, M);
      FS.ReadBuffer(RawEdges[0], Int64(M) * SizeOf(TNGRawEdge));
      for I := 0 to M - 1 do
      begin
        A := RawEdges[I].SrcTok;
        B := RawEdges[I].TgtTok;
        W := RawEdges[I].Weight;
        if (Abs(W) >= 0.001) and (A < LongWord(Length(TokFeatMap))) and (B < LongWord(FTokens.Count)) then
        begin
          SrcFeatID := TokFeatMap[A];
          L := Length(FSparseEdges[SrcFeatID]);
          SetLength(FSparseEdges[SrcFeatID], L + 1);
          FSparseEdges[SrcFeatID][L].TargetID := Integer(B);
          FSparseEdges[SrcFeatID][L].Weight := W;
        end;
      end;
    end;
  finally
    if Assigned(FS) then FS.Free;
  end;
end;

procedure TNGDeepEngine.LoadFromFile(const FileName: string);
var
  FS: TFileStream;
  HeaderMagic: array[0..7] of AnsiChar;
  SchemaVer, MetaLen, TotalEdges, SrcID, TgtID: LongWord;
  MetaBytes: AnsiString;
  JData: TJSONData;
  RootObj: TJSONObject;
  TokArr, FeatArr, SubArr: TJSONArray;
  I, J, K: Integer;
  FKey: string;
  W: Single;
  MLPFlag, H1L, H2L, W1Len, W2Len, WOutLen: LongWord;
begin
  Clear;
  FS := TFileStream.Create(FileName, fmOpenRead or fmShareDenyWrite);
  try
    if FS.Size < 16 then
      raise Exception.Create('Arquivo de modelo inválido ou truncado.');
    FS.ReadBuffer(HeaderMagic[0], 8);
    if CompareMem(@HeaderMagic[0], @MAGIC_NGM[0], 8) then
    begin
      FS.Free;
      FS := nil;
      LoadMatrixNGM(FileName);
      Exit;
    end;
    if FS.Size < 52 then
      raise Exception.Create('Arquivo .ngs inválido ou truncado.');
    if not CompareMem(@HeaderMagic[0], @MAGIC_V7[0], 8) then
    begin
      FS.Free;
      FS := nil;
      if FileExists(ChangeFileExt(FileName, '.ngm')) then
      begin
        LoadMatrixNGM(ChangeFileExt(FileName, '.ngm'));
        Exit;
      end;
      raise Exception.Create('Cabeçalho de modelo incompatível (esperado NGCTX007 ou NGMAP001).');
    end;
    FS.ReadBuffer(SchemaVer, 4);
    FS.ReadBuffer(MetaLen, 4);
    FS.ReadBuffer(TotalEdges, 4);

    SetLength(MetaBytes, MetaLen);
    if MetaLen > 0 then
      FS.ReadBuffer(MetaBytes[1], MetaLen);

    JData := GetJSON(MetaBytes);
    try
      RootObj := TJSONObject(JData);
      FDecay := RootObj.Get('decay', 0.65);
      FConfidence := RootObj.Get('confidence', 0.10);
      FUseHiddenLayers := RootObj.Get('use_hidden_layers', False);
      FHiddenDim1 := RootObj.Get('hidden_dim1', 96);
      FHiddenDim2 := RootObj.Get('hidden_dim2', 48);

      FTokens.Clear;
      FTokenHash.Clear;
      TokArr := RootObj.Arrays['tokens'];
      for I := 0 to TokArr.Count - 1 do
        EnsureToken(TokArr.Strings[I]);

      FFeatures.Clear;
      FFeatureHash.Clear;
      FeatArr := RootObj.Arrays['features'];
      for I := 0 to FeatArr.Count - 1 do
      begin
        SubArr := FeatArr.Arrays[I];
        FKey := '';
        for J := 0 to SubArr.Count - 1 do
        begin
          if J > 0 then FKey := FKey + #9;
          FKey := FKey + SubArr.Strings[J];
        end;
        EnsureFeature(FKey, (SubArr.Count > 0) and
          ((SubArr.Strings[0] = 'stem') or (SubArr.Strings[0] = 'stem4') or
           (SubArr.Strings[0] = 'cpair') or (SubArr.Strings[0] = 'pending')));
      end;
    finally
      JData.Free;
    end;

    SetLength(FSparseEdges, FFeatures.Count);
    for I := 0 to Integer(TotalEdges) - 1 do
    begin
      FS.ReadBuffer(SrcID, 4);
      FS.ReadBuffer(TgtID, 4);
      FS.ReadBuffer(W, 4);
      if (SrcID < LongWord(Length(FSparseEdges))) and (TgtID < LongWord(FTokens.Count)) then
      begin
        K := Length(FSparseEdges[SrcID]);
        SetLength(FSparseEdges[SrcID], K + 1);
        FSparseEdges[SrcID][K].TargetID := Integer(TgtID);
        FSparseEdges[SrcID][K].Weight := W;
      end;
    end;

    { Verifica se há Camadas Ocultas gravadas no trailer }
    if FS.Position + 24 + 32 <= FS.Size then
    begin
      FS.ReadBuffer(MLPFlag, 4);
      if MLPFlag = $38504C4D then
      begin
        FS.ReadBuffer(H1L, 4);
        FS.ReadBuffer(H2L, 4);
        FS.ReadBuffer(W1Len, 4);
        FS.ReadBuffer(W2Len, 4);
        FS.ReadBuffer(WOutLen, 4);
        FHiddenDim1 := Integer(H1L);
        FHiddenDim2 := Integer(H2L);
        FUseHiddenLayers := True;
        SetLength(FW1, W1Len);
        SetLength(FB1, H1L);
        SetLength(FW2, W2Len);
        SetLength(FB2, H2L);
        SetLength(FWOut, WOutLen);
        SetLength(FBOut, FTokens.Count);
        if W1Len > 0 then FS.ReadBuffer(FW1[0], W1Len * SizeOf(Single));
        if H1L > 0 then FS.ReadBuffer(FB1[0], H1L * SizeOf(Single));
        if W2Len > 0 then FS.ReadBuffer(FW2[0], W2Len * SizeOf(Single));
        if H2L > 0 then FS.ReadBuffer(FB2[0], H2L * SizeOf(Single));
        if WOutLen > 0 then FS.ReadBuffer(FWOut[0], WOutLen * SizeOf(Single));
        if FTokens.Count > 0 then FS.ReadBuffer(FBOut[0], FTokens.Count * SizeOf(Single));
      end;
    end;
  finally
    if Assigned(FS) then FS.Free;
  end;
end;

class function TNGDeepEngine.LoadExamplesFromJSONFile(const FileName: string;
  const Partition: string): TNGExampleArray;
var
  SL: TStringList;
  JData, ItemNode, AnsNode, CtxNode: TJSONData;
  Arr: TJSONArray;
  Obj: TJSONObject;
  I, J, Count: Integer;
begin
  Result := nil;
  if not FileExists(FileName) then Exit;
  SL := TStringList.Create;
  try
    SL.LoadFromFile(FileName);
    JData := GetJSON(SL.Text);
    try
      Arr := nil;
      if JData.JSONType = jtArray then
        Arr := TJSONArray(JData)
      else if (JData.JSONType = jtObject) and (TJSONObject(JData).Find(Partition) <> nil) then
        Arr := TJSONObject(JData).Arrays[Partition];

      if Arr = nil then Exit;
      SetLength(Result, Arr.Count);
      Count := 0;
      for I := 0 to Arr.Count - 1 do
      begin
        ItemNode := Arr.Items[I];
        if ItemNode.JSONType <> jtObject then Continue;
        Obj := TJSONObject(ItemNode);
        Result[Count].Question := Trim(Obj.Get('question', ''));
        if Result[Count].Question = '' then Continue;
        Result[Count].Category := Obj.Get('category', 'general');

        AnsNode := Obj.Find('answer');
        if (AnsNode = nil) or (AnsNode.JSONType = jtNull) then
        begin
          Result[Count].Answer := '';
          Result[Count].IsRefusal := True;
        end
        else
        begin
          Result[Count].Answer := Trim(AnsNode.AsString);
          Result[Count].IsRefusal := (Result[Count].Answer = '');
        end;

        Result[Count].Context := nil;
        CtxNode := Obj.Find('context');
        if (CtxNode <> nil) and (CtxNode.JSONType = jtArray) then
        begin
          SetLength(Result[Count].Context, TJSONArray(CtxNode).Count);
          for J := 0 to TJSONArray(CtxNode).Count - 1 do
            Result[Count].Context[J] := TJSONArray(CtxNode).Strings[J];
        end;
        Inc(Count);
      end;
      SetLength(Result, Count);
    finally
      JData.Free;
    end;
  finally
    SL.Free;
  end;
end;

function TNGDeepEngine.CalibrateConfidence(const ValidationExamples: array of TNGExample): Single;
const
  CANDIDATES: array[0..6] of Single = (0.05, 0.10, 0.15, 0.20, 0.30, 0.40, 0.50);
var
  CIdx, I, BestCorrect, BestWrong, CurCorrect, CurWrong: Integer;
  BestConf, SavedConf: Single;
  Gen: TNGGeneration;
  TokPred, TokExp: TNGStringArray;
  IsOk: Boolean;
begin
  if Length(ValidationExamples) = 0 then Exit(FConfidence);
  SavedConf := FConfidence;
  BestConf := FConfidence;
  BestCorrect := -1;
  BestWrong := MaxInt;

  for CIdx := 0 to High(CANDIDATES) do
  begin
    FConfidence := CANDIDATES[CIdx];
    CurCorrect := 0;
    CurWrong := 0;
    for I := 0 to High(ValidationExamples) do
    begin
      Gen := Generate(ValidationExamples[I].Question, ValidationExamples[I].Context);
      if ValidationExamples[I].IsRefusal then
        IsOk := Gen.Abstained
      else
      begin
        TokPred := NGTokenize(Gen.Text);
        TokExp := NGTokenize(ValidationExamples[I].Answer);
        IsOk := (not Gen.Abstained) and (NGJoinTokens(TokPred) = NGJoinTokens(TokExp));
      end;
      if IsOk then Inc(CurCorrect)
      else if not Gen.Abstained then Inc(CurWrong);
    end;
    if (CurCorrect > BestCorrect) or
       ((CurCorrect = BestCorrect) and (CurWrong < BestWrong)) then
    begin
      BestCorrect := CurCorrect;
      BestWrong := CurWrong;
      BestConf := CANDIDATES[CIdx];
    end;
  end;
  FConfidence := BestConf;
  Result := BestConf;
end;

function TNGDeepEngine.EvaluateDataset(const TestExamples: array of TNGExample): TNGEvalSummary;
var
  I, J, K, Common: Integer;
  Gen: TNGGeneration;
  TokPred, TokExp: TNGStringArray;
  UsedExp: array of Boolean;
  Prec, Rec, F1Val, EMVal, SumEM, SumF1, SumPrec, SumRec, SumLat: Double;
begin
  Result.TotalQuestions := Length(TestExamples);
  Result.CorrectCount := 0;
  Result.AbstentionCount := 0;
  Result.WrongAnswers := 0;
  Result.ApprovalRatePct := 0;
  Result.ExactMatchPct := 0;
  Result.F1ScorePct := 0;
  Result.PrecisionPct := 0;
  Result.RecallPct := 0;
  Result.AvgLatencyMs := 0;
  SetLength(Result.Items, Result.TotalQuestions);
  if Result.TotalQuestions = 0 then Exit;

  SumEM := 0; SumF1 := 0; SumPrec := 0; SumRec := 0; SumLat := 0;

  for I := 0 to High(TestExamples) do
  begin
    Gen := Generate(TestExamples[I].Question, TestExamples[I].Context);
    Result.Items[I].ID := I + 1;
    Result.Items[I].Category := TestExamples[I].Category;
    Result.Items[I].Question := TestExamples[I].Question;
    if TestExamples[I].IsRefusal then
      Result.Items[I].Expected := '<abster-se>'
    else
      Result.Items[I].Expected := TestExamples[I].Answer;
    Result.Items[I].Predicted := Gen.Text;
    Result.Items[I].Abstained := Gen.Abstained;
    Result.Items[I].LatencyMs := Gen.LatencyMs;

    if Gen.Abstained then Inc(Result.AbstentionCount);

    if TestExamples[I].IsRefusal then
    begin
      if Gen.Abstained then
      begin
        EMVal := 1.0; Prec := 1.0; Rec := 1.0; F1Val := 1.0;
        Result.Items[I].Correct := True;
      end
      else
      begin
        EMVal := 0.0; Prec := 0.0; Rec := 0.0; F1Val := 0.0;
        Result.Items[I].Correct := False;
        Inc(Result.WrongAnswers);
      end;
    end
    else if Gen.Abstained then
    begin
      EMVal := 0.0; Prec := 0.0; Rec := 0.0; F1Val := 0.0;
      Result.Items[I].Correct := False;
    end
    else
    begin
      TokPred := NGTokenize(Gen.Text);
      TokExp := NGTokenize(TestExamples[I].Answer);
      if NGJoinTokens(TokPred) = NGJoinTokens(TokExp) then
        EMVal := 1.0
      else
        EMVal := 0.0;

      SetLength(UsedExp, Length(TokExp));
      for K := 0 to High(UsedExp) do UsedExp[K] := False;
      Common := 0;
      for J := 0 to High(TokPred) do
        for K := 0 to High(TokExp) do
          if (not UsedExp[K]) and (TokPred[J] = TokExp[K]) then
          begin
            UsedExp[K] := True;
            Inc(Common);
            Break;
          end;

      if Length(TokPred) > 0 then Prec := Common / Length(TokPred) else Prec := 0;
      if Length(TokExp) > 0 then Rec := Common / Length(TokExp) else Rec := 0;
      if (Prec + Rec) > 0 then F1Val := 2 * Prec * Rec / (Prec + Rec) else F1Val := 0;

      Result.Items[I].Correct := (EMVal >= 1.0) or (F1Val >= 0.75);
      if not Result.Items[I].Correct then
        Inc(Result.WrongAnswers);
    end;

    if Result.Items[I].Correct then Inc(Result.CorrectCount);
    Result.Items[I].ExactMatch := EMVal;
    Result.Items[I].Precision := Prec;
    Result.Items[I].Recall := Rec;
    Result.Items[I].F1 := F1Val;

    SumEM := SumEM + EMVal;
    SumPrec := SumPrec + Prec;
    SumRec := SumRec + Rec;
    SumF1 := SumF1 + F1Val;
    SumLat := SumLat + Gen.LatencyMs;
  end;

  Result.ApprovalRatePct := (Result.CorrectCount * 100.0) / Result.TotalQuestions;
  Result.ExactMatchPct := (SumEM * 100.0) / Result.TotalQuestions;
  Result.PrecisionPct := (SumPrec * 100.0) / Result.TotalQuestions;
  Result.RecallPct := (SumRec * 100.0) / Result.TotalQuestions;
  Result.F1ScorePct := (SumF1 * 100.0) / Result.TotalQuestions;
  Result.AvgLatencyMs := SumLat / Result.TotalQuestions;
end;

function TNGDeepEngine.TokenCount: Integer;
begin
  Result := FTokens.Count;
end;

function TNGDeepEngine.FeatureCount: Integer;
begin
  Result := FFeatures.Count;
end;

function TNGDeepEngine.EdgeCount: Integer;
var
  I: Integer;
begin
  Result := 0;
  for I := 0 to High(FSparseEdges) do
    Inc(Result, Length(FSparseEdges[I]));
end;

function TNGDeepEngine.HiddenParamCount: Integer;
begin
  if not FUseHiddenLayers then Exit(0);
  Result := Length(FW1) + Length(FB1) + Length(FW2) + Length(FB2) + Length(FWOut) + Length(FBOut);
end;

end.
