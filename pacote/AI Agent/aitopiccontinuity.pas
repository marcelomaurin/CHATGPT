unit aitopiccontinuity;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Math;

type
  { Decisões de continuidade de tarefa }
  TAIContinuityDecision = (
    cdContinue,       // Continua o assunto/tarefa atual
    cdNewTopic,       // Inicia um assunto novo (empilha o anterior)
    cdResumeTopic,    // Retoma um assunto anterior pausado na pilha
    cdCorrection,     // Corrige uma informação/entidade anterior
    cdFinishTask,     // Encerra a tarefa atual e limpa memória operacional
    cdClarification   // Pedido de esclarecimento devido à ambiguidade
  );

  { Status do tópico na pilha de contextos }
  TAITopicStatus = (
    tsActive,
    tsPaused,
    tsCompleted
  );

  { Marcadores linguísticos discursivos }
  TAILinguisticMarker = (
    lmNone,
    lmShift,        // Mudança ("mudando de assunto", "outro assunto")
    lmResume,       // Retomada ("voltando ao", "como estávamos falando")
    lmCorrection,   // Correção ("não, o boleto x", "ops, na verdade")
    lmFinish,       // Encerramento ("obrigado, era só isso", "pode fechar")
    lmContinue      // Continuação explícita ("e também", "além disso")
  );

  TDoubleArray = array of Double;

  { Representação de uma entidade extraída }
  TAIEntityItem = class
  private
    FCategory: string;       // ex: 'empresa', 'documento', 'projeto', 'valor', 'data', 'termo'
    FValue: string;          // ex: 'Coderp', '12345', 'Hemacias', 'R$ 150'
    FNormalizedValue: string;
  public
    constructor Create(const ACategory, AValue: string);
    property Category: string read FCategory write FCategory;
    property Value: string read FValue write FValue;
    property NormalizedValue: string read FNormalizedValue write FNormalizedValue;
  end;

  { Lista e rastreador de entidades }
  TAIEntityList = class
  private
    FItems: TFPList;
    function GetItem(AIndex: Integer): TAIEntityItem;
    function GetCount: Integer;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Clear;
    function Add(const ACategory, AValue: string): TAIEntityItem;
    function FindByCategory(const ACategory: string): TAIEntityItem;
    function HasValue(const AValue: string): Boolean;
    procedure CopyFrom(ASource: TAIEntityList);
    function ToSummaryString: string;

    property Items[AIndex: Integer]: TAIEntityItem read GetItem; default;
    property Count: Integer read GetCount;
  end;

  { Tópico individual com histórico e entidades }
  TAITopicItem = class
  private
    FID: string;
    FTitle: string;
    FGoal: string;
    FStatus: TAITopicStatus;
    FEntities: TAIEntityList;
    FUtterances: TStringList;
    FCentroidVector: TDoubleArray;
    FCreatedAt: TDateTime;
    FLastActiveAt: TDateTime;
    FInteractionCount: Integer;
  public
    constructor Create(const AID, ATitle, AGoal: string);
    destructor Destroy; override;
    procedure AddUtterance(const AText: string; const AIsUser: Boolean = True);
    procedure UpdateEntity(const ACategory, ANewValue: string);
    function FormatSummary: string;

    property ID: string read FID write FID;
    property Title: string read FTitle write FTitle;
    property Goal: string read FGoal write FGoal;
    property Status: TAITopicStatus read FStatus write FStatus;
    property Entities: TAIEntityList read FEntities;
    property Utterances: TStringList read FUtterances;
    property CentroidVector: TDoubleArray read FCentroidVector write FCentroidVector;
    property CreatedAt: TDateTime read FCreatedAt;
    property LastActiveAt: TDateTime read FLastActiveAt write FLastActiveAt;
    property InteractionCount: Integer read FInteractionCount write FInteractionCount;
  end;

  { Motor de similaridade semântica puro em Pascal (TF-IDF N-Gram + Cosseno) }
  TOnComputeEmbeddingEvent = procedure(const AText: string; out AVector: TDoubleArray) of object;

  TAISemanticEngine = class
  private
    FStopwords: TStringList;
    FOnComputeEmbedding: TOnComputeEmbeddingEvent;
    procedure InitStopwords;
    function CleanText(const AText: string): string;
    function ExtractTokens(const AText: string): TStringList;
  public
    constructor Create;
    destructor Destroy; override;
    function ComputeVector(const AText: string): TDoubleArray;
    function CosineSimilarity(const V1, V2: TDoubleArray): Double;
    function TextSimilarity(const Text1, Text2: string): Double;
    procedure UpdateCentroid(var Centroid: TDoubleArray; const NewVec: TDoubleArray; Weight: Double = 0.3);

    property OnComputeEmbedding: TOnComputeEmbeddingEvent read FOnComputeEmbedding write FOnComputeEmbedding;
  end;

  { Analisador de regras linguísticas discursivas }
  TAILinguisticRuleEngine = class
  private
    FKnownProjects: TStringList;
    function ContainsPattern(const AText, APattern: string): Boolean;
  public
    constructor Create;
    destructor Destroy; override;
    function Analyze(const AText: string; out AMarker: TAILinguisticMarker;
      out AConfidence: Double; out AMatchedSnippet, AReferencedTarget: string): Boolean;
    procedure RegisterKnownEntityName(const AName: string);
  end;

  { Extrator de entidades estruturadas e comparador }
  TAIEntityTracker = class
  private
    FKnownEntities: TStringList; // Chave=Nome, Valor=Categoria
  public
    constructor Create;
    destructor Destroy; override;
    procedure RegisterKnownEntity(const AName, ACategory: string);
    function ExtractEntities(const AText: string): TAIEntityList;
    function CompareEntities(const AUtteranceList, ATopicList: TAIEntityList;
      out AConflictDetected: Boolean;
      out AConflictingCat, AConflictingOld, AConflictingNew: string): Double;
  end;

  { Pilha gerenciadora de tópicos (Topic Stack) }
  TAITopicStack = class
  private
    FActiveTopic: TAITopicItem;
    FPausedTopics: TFPList;
    FCompletedTopics: TFPList;
    FMaxStackDepth: Integer;
    FNextID: Integer;
    function GenerateTopicID: string;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Clear;
    function PushTopic(const ATitle, AGoal: string): TAITopicItem;
    function PauseActiveTopic: Boolean;
    function ResumeTopic(AIndex: Integer): TAITopicItem;
    function ResumeTopicByID(const AID: string): TAITopicItem;
    function CompleteActiveTopic: TAITopicItem;
    function GetPausedCount: Integer;
    function GetPausedTopic(AIndex: Integer): TAITopicItem;
    function GetCompletedCount: Integer;
    function GetCompletedTopic(AIndex: Integer): TAITopicItem;
    function FindBestPausedMatch(const AUtterance: string; ASemanticEngine: TAISemanticEngine;
      out BestSimilarity: Double): TAITopicItem;

    property ActiveTopic: TAITopicItem read FActiveTopic write FActiveTopic;
    property MaxStackDepth: Integer read FMaxStackDepth write FMaxStackDepth default 10;
  end;

  { Eventos do classificador }
  TOnTopicChangedEvent = procedure(Sender: TObject; AOldTopic, ANewTopic: TAITopicItem) of object;
  TOnTopicResumedEvent = procedure(Sender: TObject; AResumedTopic: TAITopicItem) of object;
  TOnEntityCorrectedEvent = procedure(Sender: TObject; const ACategory, AOldVal, ANewVal: string) of object;
  TOnTaskCompletedEvent = procedure(Sender: TObject; ACompletedTopic: TAITopicItem) of object;
  TOnClarificationNeededEvent = procedure(Sender: TObject; const AQuestion: string) of object;
  TOnDecisionEvent = procedure(Sender: TObject; ADecision: TAIContinuityDecision; AScore: Double; const AReason: string) of object;

  { Componente Lazarus reutilizável: TAITopicContinuityClassifier }
  TAITopicContinuityClassifier = class(TComponent)
  private
    FTopicStack: TAITopicStack;
    FSemanticEngine: TAISemanticEngine;
    FLinguisticEngine: TAILinguisticRuleEngine;
    FEntityTracker: TAIEntityTracker;

    // Pesos da fórmula contextual
    FWeightSemantic: Double;     // Padrão 0.30
    FWeightCoherence: Double;    // Padrão 0.25
    FWeightEntity: Double;       // Padrão 0.25
    FWeightLinguistic: Double;   // Padrão 0.20

    // Limiares
    FContinueThreshold: Double;  // Padrão 0.55
    FNewTopicThreshold: Double;  // Padrão 0.35
    FResumeThreshold: Double;    // Padrão 0.60
    FAutoManageStack: Boolean;   // Padrão True

    // Último resultado
    FLastDecision: TAIContinuityDecision;
    FLastScore: Double;
    FLastReason: string;

    // Eventos
    FOnTopicChanged: TOnTopicChangedEvent;
    FOnTopicResumed: TOnTopicResumedEvent;
    FOnEntityCorrected: TOnEntityCorrectedEvent;
    FOnTaskCompleted: TOnTaskCompletedEvent;
    FOnClarificationNeeded: TOnClarificationNeededEvent;
    FOnDecision: TOnDecisionEvent;

    function GetActiveTopic: TAITopicItem;
    function InferTitleFromText(const AText: string; AEntities: TAIEntityList): string;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    { Classificação e Decisão }
    function ClassifyContinuity(const AUtterance: string;
      out ADecision: TAIContinuityDecision;
      out AScore: Double;
      out AReason: string): Boolean;

    { Processamento de alto nível: classifica, gerencia pilha e monta prompt contextualizado }
    function ProcessUtterance(const AUtterance: string;
      out ADecision: TAIContinuityDecision;
      out AEnrichedPrompt: string): Boolean;

    { Gravação da resposta gerada pela IA no tópico ativo }
    procedure RecordAIResponse(const AResponse: string);

    { Registro de entidades conhecidas (empresas, projetos, documentos) }
    procedure RegisterKnownEntity(const AName, ACategory: string);
    procedure SetActiveTopic(const ATitle, AGoal: string);
    function BuildTopicScopedContext(AMaxUtterances: Integer = 6): string;
    function FormatStackSummary: string;
    procedure Reset;
    procedure Clear;

    property TopicStack: TAITopicStack read FTopicStack;
    property SemanticEngine: TAISemanticEngine read FSemanticEngine;
    property LinguisticEngine: TAILinguisticRuleEngine read FLinguisticEngine;
    property EntityTracker: TAIEntityTracker read FEntityTracker;
    property ActiveTopic: TAITopicItem read GetActiveTopic;
    property LastDecision: TAIContinuityDecision read FLastDecision;
    property LastScore: Double read FLastScore;
    property LastReason: string read FLastReason;
  published
    property WeightSemantic: Double read FWeightSemantic write FWeightSemantic;
    property WeightCoherence: Double read FWeightCoherence write FWeightCoherence;
    property WeightEntity: Double read FWeightEntity write FWeightEntity;
    property WeightLinguistic: Double read FWeightLinguistic write FWeightLinguistic;
    property ContinueThreshold: Double read FContinueThreshold write FContinueThreshold;
    property NewTopicThreshold: Double read FNewTopicThreshold write FNewTopicThreshold;
    property ResumeThreshold: Double read FResumeThreshold write FResumeThreshold;
    property AutoManageStack: Boolean read FAutoManageStack write FAutoManageStack default True;

    property OnTopicChanged: TOnTopicChangedEvent read FOnTopicChanged write FOnTopicChanged;
    property OnTopicResumed: TOnTopicResumedEvent read FOnTopicResumed write FOnTopicResumed;
    property OnEntityCorrected: TOnEntityCorrectedEvent read FOnEntityCorrected write FOnEntityCorrected;
    property OnTaskCompleted: TOnTaskCompletedEvent read FOnTaskCompleted write FOnTaskCompleted;
    property OnClarificationNeeded: TOnClarificationNeededEvent read FOnClarificationNeeded write FOnClarificationNeeded;
    property OnDecision: TOnDecisionEvent read FOnDecision write FOnDecision;
  end;

procedure Register;

implementation
uses LResources;


procedure Register;
begin
  RegisterComponents('OpenAI Agent', [TAITopicContinuityClassifier]);
end;

{ Funções utilitárias }

function NormalizeStr(const S: string): string;
var
  Low: string;
begin
  Low := LowerCase(S);
  Low := StringReplace(Low, 'á', 'a', [rfReplaceAll]);
  Low := StringReplace(Low, 'à', 'a', [rfReplaceAll]);
  Low := StringReplace(Low, 'ã', 'a', [rfReplaceAll]);
  Low := StringReplace(Low, 'â', 'a', [rfReplaceAll]);
  Low := StringReplace(Low, 'ä', 'a', [rfReplaceAll]);
  Low := StringReplace(Low, 'é', 'e', [rfReplaceAll]);
  Low := StringReplace(Low, 'è', 'e', [rfReplaceAll]);
  Low := StringReplace(Low, 'ê', 'e', [rfReplaceAll]);
  Low := StringReplace(Low, 'ë', 'e', [rfReplaceAll]);
  Low := StringReplace(Low, 'í', 'i', [rfReplaceAll]);
  Low := StringReplace(Low, 'ì', 'i', [rfReplaceAll]);
  Low := StringReplace(Low, 'î', 'i', [rfReplaceAll]);
  Low := StringReplace(Low, 'ï', 'i', [rfReplaceAll]);
  Low := StringReplace(Low, 'ó', 'o', [rfReplaceAll]);
  Low := StringReplace(Low, 'ò', 'o', [rfReplaceAll]);
  Low := StringReplace(Low, 'õ', 'o', [rfReplaceAll]);
  Low := StringReplace(Low, 'ô', 'o', [rfReplaceAll]);
  Low := StringReplace(Low, 'ö', 'o', [rfReplaceAll]);
  Low := StringReplace(Low, 'ú', 'u', [rfReplaceAll]);
  Low := StringReplace(Low, 'ù', 'u', [rfReplaceAll]);
  Low := StringReplace(Low, 'û', 'u', [rfReplaceAll]);
  Low := StringReplace(Low, 'ü', 'u', [rfReplaceAll]);
  Low := StringReplace(Low, 'ç', 'c', [rfReplaceAll]);
  Result := Low;
end;

{ TAIEntityItem }

constructor TAIEntityItem.Create(const ACategory, AValue: string);
begin
  inherited Create;
  FCategory := Trim(ACategory);
  FValue := Trim(AValue);
  FNormalizedValue := NormalizeStr(FValue);
end;

{ TAIEntityList }

constructor TAIEntityList.Create;
begin
  inherited Create;
  FItems := TFPList.Create;
end;

destructor TAIEntityList.Destroy;
begin
  Clear;
  FItems.Free;
  inherited Destroy;
end;

procedure TAIEntityList.Clear;
var
  I: Integer;
begin
  for I := 0 to FItems.Count - 1 do
    TAIEntityItem(FItems[I]).Free;
  FItems.Clear;
end;

function TAIEntityList.GetItem(AIndex: Integer): TAIEntityItem;
begin
  if (AIndex >= 0) and (AIndex < FItems.Count) then
    Result := TAIEntityItem(FItems[AIndex])
  else
    Result := nil;
end;

function TAIEntityList.GetCount: Integer;
begin
  Result := FItems.Count;
end;

function TAIEntityList.Add(const ACategory, AValue: string): TAIEntityItem;
var
  Existing: TAIEntityItem;
begin
  Existing := FindByCategory(ACategory);
  if Assigned(Existing) then
  begin
    Existing.Value := AValue;
    Existing.NormalizedValue := NormalizeStr(AValue);
    Result := Existing;
    Exit;
  end;

  Result := TAIEntityItem.Create(ACategory, AValue);
  FItems.Add(Result);
end;

function TAIEntityList.FindByCategory(const ACategory: string): TAIEntityItem;
var
  I: Integer;
  NormCat: string;
begin
  Result := nil;
  NormCat := NormalizeStr(ACategory);
  for I := 0 to FItems.Count - 1 do
  begin
    if NormalizeStr(Items[I].Category) = NormCat then
    begin
      Result := Items[I];
      Exit;
    end;
  end;
end;

function TAIEntityList.HasValue(const AValue: string): Boolean;
var
  I: Integer;
  NormVal: string;
begin
  Result := False;
  NormVal := NormalizeStr(AValue);
  for I := 0 to FItems.Count - 1 do
  begin
    if Items[I].NormalizedValue = NormVal then
    begin
      Result := True;
      Exit;
    end;
  end;
end;

procedure TAIEntityList.CopyFrom(ASource: TAIEntityList);
var
  I: Integer;
begin
  Clear;
  if Assigned(ASource) then
  begin
    for I := 0 to ASource.Count - 1 do
      Add(ASource[I].Category, ASource[I].Value);
  end;
end;

function TAIEntityList.ToSummaryString: string;
var
  I: Integer;
begin
  Result := '';
  for I := 0 to FItems.Count - 1 do
  begin
    if Result <> '' then
      Result := Result + ', ';
    Result := Result + Items[I].Category + ': ' + Items[I].Value;
  end;
end;

{ TAITopicItem }

constructor TAITopicItem.Create(const AID, ATitle, AGoal: string);
begin
  inherited Create;
  FID := AID;
  FTitle := ATitle;
  FGoal := AGoal;
  FStatus := tsActive;
  FEntities := TAIEntityList.Create;
  FUtterances := TStringList.Create;
  FCreatedAt := Now;
  FLastActiveAt := Now;
  FInteractionCount := 0;
  SetLength(FCentroidVector, 0);
end;

destructor TAITopicItem.Destroy;
begin
  FEntities.Free;
  FUtterances.Free;
  inherited Destroy;
end;

procedure TAITopicItem.AddUtterance(const AText: string; const AIsUser: Boolean);
var
  Prefix: string;
begin
  if AIsUser then
    Prefix := 'Usuário: '
  else
    Prefix := 'Assistente: ';
  FUtterances.Add(Prefix + Trim(AText));
  FLastActiveAt := Now;
  Inc(FInteractionCount);
end;

procedure TAITopicItem.UpdateEntity(const ACategory, ANewValue: string);
begin
  FEntities.Add(ACategory, ANewValue);
  FLastActiveAt := Now;
end;

function TAITopicItem.FormatSummary: string;
begin
  Result := Format('[%s] %s', [FID, FTitle]);
  if Trim(FGoal) <> '' then
    Result := Result + ' (Objetivo: ' + FGoal + ')';
  if FEntities.Count > 0 then
    Result := Result + ' {Entidades: ' + FEntities.ToSummaryString + '}';
end;

{ TAISemanticEngine }

constructor TAISemanticEngine.Create;
begin
  inherited Create;
  FStopwords := TStringList.Create;
  FStopwords.Sorted := True;
  FStopwords.Duplicates := dupIgnore;
  InitStopwords;
end;

destructor TAISemanticEngine.Destroy;
begin
  FStopwords.Free;
  inherited Destroy;
end;

procedure TAISemanticEngine.InitStopwords;
begin
  FStopwords.CommaText := 'a,ao,aos,as,ate,com,da,das,de,dela,delas,dele,deles,do,dos,e,ela,elas,ele,eles,em,entre,era,essa,essas,esse,esses,esta,estas,este,estes,eu,foi,ja,lhe,lhes,mais,mas,me,mesmo,meu,meus,minha,minhas,na,nas,no,nos,nossa,nossas,nosso,nossos,o,os,ou,para,pela,pelas,pelo,pelos,por,que';
end;

function TAISemanticEngine.CleanText(const AText: string): string;
var
  I: Integer;
  Norm: string;
  C: Char;
begin
  Norm := NormalizeStr(AText);
  Result := '';
  for I := 1 to Length(Norm) do
  begin
    C := Norm[I];
    if C in ['a'..'z', '0'..'9'] then
      Result := Result + C
    else
      Result := Result + ' ';
  end;
end;

function TAISemanticEngine.ExtractTokens(const AText: string): TStringList;
var
  Cleaned, CurToken: string;
  I: Integer;
begin
  Result := TStringList.Create;
  Result.Sorted := True;
  Result.Duplicates := dupAccept;

  Cleaned := CleanText(AText);
  CurToken := '';
  for I := 1 to Length(Cleaned) do
  begin
    if Cleaned[I] <> ' ' then
      CurToken := CurToken + Cleaned[I]
    else
    begin
      if (CurToken <> '') and (FStopwords.IndexOf(CurToken) < 0) and (Length(CurToken) >= 2) then
        Result.Add(CurToken);
      CurToken := '';
    end;
  end;
  if (CurToken <> '') and (FStopwords.IndexOf(CurToken) < 0) and (Length(CurToken) >= 2) then
    Result.Add(CurToken);
end;

function HashTokenToBucket(const S: string; BucketCount: Integer): Integer;
var
  I: Integer;
  H: Cardinal;
begin
  H := 5381;
  for I := 1 to Length(S) do
    H := Cardinal(((QWord(H) shl 5) + H + Byte(S[I])) and QWord($FFFFFFFF));
  Result := H mod Cardinal(BucketCount);
end;

function TAISemanticEngine.ComputeVector(const AText: string): TDoubleArray;
const
  Dim = 64; // Dimensões do espaço vetorial determinístico
var
  Tokens: TStringList;
  I, B: Integer;
  T, Sub: string;
  Norm: Double;
begin
  if Assigned(FOnComputeEmbedding) then
  begin
    FOnComputeEmbedding(AText, Result);
    if Length(Result) > 0 then Exit;
  end;

  SetLength(Result, Dim);
  for I := 0 to Dim - 1 do
    Result[I] := 0.0;

  Tokens := ExtractTokens(AText);
  try
    if Tokens.Count = 0 then Exit;

    for I := 0 to Tokens.Count - 1 do
    begin
      T := Tokens[I];
      // Palavra inteira
      B := HashTokenToBucket(T, Dim);
      Result[B] := Result[B] + 1.5;

      // Subpalavras / Trigramas para tolerância morfológica
      if Length(T) >= 4 then
      begin
        Sub := Copy(T, 1, 3);
        B := HashTokenToBucket(Sub, Dim);
        Result[B] := Result[B] + 0.5;

        Sub := Copy(T, Length(T) - 2, 3);
        B := HashTokenToBucket(Sub, Dim);
        Result[B] := Result[B] + 0.5;
      end;
    end;

    // Normalização L2
    Norm := 0.0;
    for I := 0 to Dim - 1 do
      Norm := Norm + Sqr(Result[I]);

    if Norm > 0.000001 then
    begin
      Norm := Sqrt(Norm);
      for I := 0 to Dim - 1 do
        Result[I] := Result[I] / Norm;
    end;
  finally
    Tokens.Free;
  end;
end;

function TAISemanticEngine.CosineSimilarity(const V1, V2: TDoubleArray): Double;
var
  I, Len: Integer;
  Dot, Norm1, Norm2: Double;
begin
  Result := 0.0;
  Len := Min(Length(V1), Length(V2));
  if Len = 0 then Exit;

  Dot := 0.0;
  Norm1 := 0.0;
  Norm2 := 0.0;

  for I := 0 to Len - 1 do
  begin
    Dot := Dot + (V1[I] * V2[I]);
    Norm1 := Norm1 + Sqr(V1[I]);
    Norm2 := Norm2 + Sqr(V2[I]);
  end;

  if (Norm1 > 0.000001) and (Norm2 > 0.000001) then
  begin
    Result := Dot / (Sqrt(Norm1) * Sqrt(Norm2));
    if Result < 0.0 then Result := 0.0;
    if Result > 1.0 then Result := 1.0;
  end;
end;

function TAISemanticEngine.TextSimilarity(const Text1, Text2: string): Double;
var
  V1, V2: TDoubleArray;
begin
  V1 := ComputeVector(Text1);
  V2 := ComputeVector(Text2);
  Result := CosineSimilarity(V1, V2);
end;

procedure TAISemanticEngine.UpdateCentroid(var Centroid: TDoubleArray; const NewVec: TDoubleArray; Weight: Double);
var
  I, Len: Integer;
  Norm: Double;
begin
  if Length(Centroid) = 0 then
  begin
    Centroid := Copy(NewVec, 0, Length(NewVec));
    Exit;
  end;

  Len := Min(Length(Centroid), Length(NewVec));
  for I := 0 to Len - 1 do
    Centroid[I] := ((1.0 - Weight) * Centroid[I]) + (Weight * NewVec[I]);

  Norm := 0.0;
  for I := 0 to Len - 1 do
    Norm := Norm + Sqr(Centroid[I]);

  if Norm > 0.000001 then
  begin
    Norm := Sqrt(Norm);
    for I := 0 to Len - 1 do
      Centroid[I] := Centroid[I] / Norm;
  end;
end;

{ TAILinguisticRuleEngine }

constructor TAILinguisticRuleEngine.Create;
begin
  inherited Create;
  FKnownProjects := TStringList.Create;
  FKnownProjects.Sorted := True;
  FKnownProjects.Duplicates := dupIgnore;
end;

destructor TAILinguisticRuleEngine.Destroy;
begin
  FKnownProjects.Free;
  inherited Destroy;
end;

procedure TAILinguisticRuleEngine.RegisterKnownEntityName(const AName: string);
begin
  if Trim(AName) <> '' then
    FKnownProjects.Add(NormalizeStr(Trim(AName)));
end;

function TAILinguisticRuleEngine.ContainsPattern(const AText, APattern: string): Boolean;
begin
  Result := Pos(NormalizeStr(APattern), NormalizeStr(AText)) > 0;
end;

function TAILinguisticRuleEngine.Analyze(const AText: string;
  out AMarker: TAILinguisticMarker;
  out AConfidence: Double;
  out AMatchedSnippet, AReferencedTarget: string): Boolean;
var
  Norm: string;
  I: Integer;
begin
  Result := True;
  AMarker := lmNone;
  AConfidence := 0.0;
  AMatchedSnippet := '';
  AReferencedTarget := '';

  Norm := NormalizeStr(Trim(AText));
  if Norm = '' then Exit;

  // 1. Marcadores de Encerramento (Finalização da tarefa)
  if ContainsPattern(Norm, 'obrigado, era so isso') or ContainsPattern(Norm, 'era so isso') or
     ContainsPattern(Norm, 'por hoje e so') or ContainsPattern(Norm, 'pode encerrar') or
     ContainsPattern(Norm, 'finalizar tarefa') or ContainsPattern(Norm, 'pode fechar') or
     ContainsPattern(Norm, 'valeu, era isso') or ContainsPattern(Norm, 'valeu, terminou') or
     ContainsPattern(Norm, 'concluir tarefa') or (Norm = 'obrigado') or (Norm = 'tchau') or
     ContainsPattern(Norm, 'resolvido, obrigado') or ContainsPattern(Norm, 'cancelar tarefa') then
  begin
    AMarker := lmFinish;
    AConfidence := 0.95;
    AMatchedSnippet := 'encerramento detectado';
    Exit;
  end;

  // 2. Marcadores de Correção de Dado/Entidade
  if (Copy(Norm, 1, 4) = 'nao,') or (Copy(Norm, 1, 5) = 'nao ') or
     (Copy(Norm, 1, 4) = 'ops,') or (Copy(Norm, 1, 4) = 'opa,') or
     ContainsPattern(Norm, 'errei,') or ContainsPattern(Norm, 'errei ') or
     ContainsPattern(Norm, 'quis dizer') or ContainsPattern(Norm, 'na verdade') or
     ContainsPattern(Norm, 'corrigindo') or ContainsPattern(Norm, 'nao era esse') or
     ContainsPattern(Norm, 'nao era isso') or ContainsPattern(Norm, 'troquei o') or
     ContainsPattern(Norm, 'desculpe, e') then
  begin
    AMarker := lmCorrection;
    AConfidence := 0.90;
    AMatchedSnippet := 'correcao detectada';
    Exit;
  end;

  // 3. Marcadores de Mudança Explícita de Assunto (Ruptura)
  if ContainsPattern(Norm, 'mudando de assunto') or ContainsPattern(Norm, 'mudando de conversa') or
     ContainsPattern(Norm, 'trocando de assunto') or ContainsPattern(Norm, 'outro assunto') or
     ContainsPattern(Norm, 'outra coisa') or ContainsPattern(Norm, 'deixa isso pra la') or
     ContainsPattern(Norm, 'deixa pra la') or ContainsPattern(Norm, 'esquece isso') or
     ContainsPattern(Norm, 'vamos falar de outra coisa') or ContainsPattern(Norm, 'agora sobre') or
     ContainsPattern(Norm, 'nova duvida') then
  begin
    AMarker := lmShift;
    AConfidence := 0.95;
    AMatchedSnippet := 'mudanca de assunto';
    Exit;
  end;

  // 4. Marcadores de Retomada de Contexto Passado
  if ContainsPattern(Norm, 'voltando a') or ContainsPattern(Norm, 'voltando ao') or
     ContainsPattern(Norm, 'voltando para') or ContainsPattern(Norm, 'voltando pro') or
     ContainsPattern(Norm, 'como estavamos falando') or ContainsPattern(Norm, 'sobre o que falamos antes') or
     ContainsPattern(Norm, 'retomando o') or ContainsPattern(Norm, 'retomando') or
     ContainsPattern(Norm, 'vamos voltar ao') or ContainsPattern(Norm, 'lembra do') or
     ContainsPattern(Norm, 'lembra daquele') or ContainsPattern(Norm, 'e sobre o primeiro assunto') then
  begin
    AMarker := lmResume;
    AConfidence := 0.90;
    AMatchedSnippet := 'retomada de assunto';

    // Tenta identificar o alvo da retomada contra entidades conhecidas
    for I := 0 to FKnownProjects.Count - 1 do
    begin
      if Pos(FKnownProjects[I], Norm) > 0 then
      begin
        AReferencedTarget := FKnownProjects[I];
        Break;
      end;
    end;
    Exit;
  end;

  // 5. Marcadores de Continuação Explícita, Anáfora e Perguntas de Acompanhamento
  if ContainsPattern(Norm, 'e tambem') or ContainsPattern(Norm, 'alem disso') or
     ContainsPattern(Norm, 'e quanto a') or ContainsPattern(Norm, 'mais uma coisa') or
     ContainsPattern(Norm, 'o que mais') or ContainsPattern(Norm, 'e depois') or
     ContainsPattern(Norm, 'qual o proximo passo') or ContainsPattern(Norm, 'como faco') or
     ContainsPattern(Norm, 'dele') or ContainsPattern(Norm, 'dela') or
     ContainsPattern(Norm, 'disso') or ContainsPattern(Norm, 'nisso') or
     ContainsPattern(Norm, 'nele') or ContainsPattern(Norm, 'nela') or
     ContainsPattern(Norm, 'posso pagar') or ContainsPattern(Norm, 'qual o valor') or
     ContainsPattern(Norm, 'qual e o valor') or ContainsPattern(Norm, 'quanto custa') or
     ContainsPattern(Norm, 'onde pago') or ContainsPattern(Norm, 'como pagar') or
     (Copy(Norm, 1, 2) = 'e ') or (Copy(Norm, 1, 4) = 'qual') or (Copy(Norm, 1, 4) = 'como') then
  begin
    AMarker := lmContinue;
    AConfidence := 0.85;
    AMatchedSnippet := 'marcador de continuidade / anafora';
    Exit;
  end;
end;

{ TAIEntityTracker }

constructor TAIEntityTracker.Create;
begin
  inherited Create;
  FKnownEntities := TStringList.Create;
  FKnownEntities.Sorted := True;
  FKnownEntities.Duplicates := dupIgnore;
end;

destructor TAIEntityTracker.Destroy;
begin
  FKnownEntities.Free;
  inherited Destroy;
end;

procedure TAIEntityTracker.RegisterKnownEntity(const AName, ACategory: string);
begin
  if Trim(AName) <> '' then
    FKnownEntities.Values[NormalizeStr(Trim(AName))] := Trim(ACategory);
end;

function TAIEntityTracker.ExtractEntities(const AText: string): TAIEntityList;
var
  Norm, Raw, Digits, Token: string;
  I, J: Integer;
  KnownCat: string;
begin
  Result := TAIEntityList.Create;
  Raw := Trim(AText);
  Norm := NormalizeStr(Raw);
  if Norm = '' then Exit;

  // 1. Extração de Documentos / Protocolos / Boletos por números contínuos (ex: 5 dígitos ou mais)
  Digits := '';
  for I := 1 to Length(Raw) do
  begin
    if Raw[I] in ['0'..'9'] then
      Digits := Digits + Raw[I]
    else
    begin
      if Length(Digits) >= 5 then
        Result.Add('documento', Digits);
      Digits := '';
    end;
  end;
  if Length(Digits) >= 5 then
    Result.Add('documento', Digits);

  // 2. Extração de Valores Monetários
  if (Pos('r$', Norm) > 0) or (Pos('reais', Norm) > 0) or (Pos('$', Norm) > 0) then
  begin
    // Localiza fragmento numérico associado
    for I := 1 to Length(Raw) do
    begin
      if (Raw[I] = '$') or ((I < Length(Raw)) and (Raw[I] = 'R') and (Raw[I+1] = '$')) then
      begin
        Token := '';
        J := I + 1;
        if (J <= Length(Raw)) and (Raw[J] = '$') then Inc(J);
        while (J <= Length(Raw)) and (Raw[J] in ['0'..'9', ',', '.', ' ']) do
        begin
          Token := Token + Raw[J];
          Inc(J);
        end;
        if Trim(Token) <> '' then
          Result.Add('valor', Trim(Token));
        Break;
      end;
    end;
  end;

  // 3. Reconhecimento de entidades cadastradas previamente (Projetos, Empresas, etc.)
  for I := 0 to FKnownEntities.Count - 1 do
  begin
    Token := FKnownEntities.Names[I];
    if (Token <> '') and (Pos(Token, Norm) > 0) then
    begin
      KnownCat := FKnownEntities.ValueFromIndex[I];
      if KnownCat = '' then KnownCat := 'entidade';
      Result.Add(KnownCat, Token);
    end;
  end;

  // 4. Detecção genérica de menções comuns
  if (Pos('boleto', Norm) > 0) and (Result.FindByCategory('documento') = nil) then
    Result.Add('tipo_tarefa', 'boleto');
  if (Pos('relatorio', Norm) > 0) and (Result.FindByCategory('tipo_tarefa') = nil) then
    Result.Add('tipo_tarefa', 'relatorio');
  if (Pos('contrato', Norm) > 0) and (Result.FindByCategory('tipo_tarefa') = nil) then
    Result.Add('tipo_tarefa', 'contrato');
end;

function TAIEntityTracker.CompareEntities(const AUtteranceList, ATopicList: TAIEntityList;
  out AConflictDetected: Boolean;
  out AConflictingCat, AConflictingOld, AConflictingNew: string): Double;
var
  I: Integer;
  UtterItem, TopicItem: TAIEntityItem;
  Matches, Conflicts, TotalCompared: Integer;
begin
  AConflictDetected := False;
  AConflictingCat := '';
  AConflictingOld := '';
  AConflictingNew := '';

  if (AUtteranceList = nil) or (ATopicList = nil) or
     ((AUtteranceList.Count = 0) and (ATopicList.Count = 0)) then
  begin
    Result := 0.5; // Neutro: nenhuma entidade em foco
    Exit;
  end;

  if (AUtteranceList.Count = 0) and (ATopicList.Count > 0) then
  begin
    Result := 0.85; // Continua sem especificar nova entidade (herda o contexto ativo)
    Exit;
  end;

  Matches := 0;
  Conflicts := 0;
  TotalCompared := 0;

  for I := 0 to AUtteranceList.Count - 1 do
  begin
    UtterItem := AUtteranceList[I];
    TopicItem := ATopicList.FindByCategory(UtterItem.Category);
    if Assigned(TopicItem) then
    begin
      Inc(TotalCompared);
      if TopicItem.NormalizedValue = UtterItem.NormalizedValue then
        Inc(Matches)
      else
      begin
        // Conflito de entidade da mesma categoria! (ex: Empresa A vs Empresa B, Boleto 1 vs Boleto 2)
        Inc(Conflicts);
        AConflictDetected := True;
        AConflictingCat := UtterItem.Category;
        AConflictingOld := TopicItem.Value;
        AConflictingNew := UtterItem.Value;
      end;
    end;
  end;

  if Conflicts > 0 then
    Result := 0.0 // Conflito direto zera o escore de entidade
  else if Matches > 0 then
    Result := 1.0 // Sobreposição total
  else
    Result := 0.35; // Nova entidade sem colisão direta
end;

{ TAITopicStack }

constructor TAITopicStack.Create;
begin
  inherited Create;
  FPausedTopics := TFPList.Create;
  FCompletedTopics := TFPList.Create;
  FMaxStackDepth := 10;
  FNextID := 0;
  FActiveTopic := nil;
end;

destructor TAITopicStack.Destroy;
begin
  Clear;
  FPausedTopics.Free;
  FCompletedTopics.Free;
  inherited Destroy;
end;

procedure TAITopicStack.Clear;
var
  I: Integer;
begin
  if Assigned(FActiveTopic) then
  begin
    FActiveTopic.Free;
    FActiveTopic := nil;
  end;

  for I := 0 to FPausedTopics.Count - 1 do
    TAITopicItem(FPausedTopics[I]).Free;
  FPausedTopics.Clear;

  for I := 0 to FCompletedTopics.Count - 1 do
    TAITopicItem(FCompletedTopics[I]).Free;
  FCompletedTopics.Clear;
end;

function TAITopicStack.GenerateTopicID: string;
begin
  Inc(FNextID);
  Result := 'topico-' + IntToStr(FNextID);
end;

function TAITopicStack.PushTopic(const ATitle, AGoal: string): TAITopicItem;
begin
  if Assigned(FActiveTopic) then
    PauseActiveTopic;

  Result := TAITopicItem.Create(GenerateTopicID, ATitle, AGoal);
  FActiveTopic := Result;
end;

function TAITopicStack.PauseActiveTopic: Boolean;
begin
  Result := False;
  if Assigned(FActiveTopic) then
  begin
    FActiveTopic.Status := tsPaused;
    FPausedTopics.Insert(0, FActiveTopic); // Adiciona no topo da pilha (LIFO)
    while FPausedTopics.Count > FMaxStackDepth do
    begin
      TAITopicItem(FPausedTopics[FPausedTopics.Count - 1]).Free;
      FPausedTopics.Delete(FPausedTopics.Count - 1);
    end;
    FActiveTopic := nil;
    Result := True;
  end;
end;

function TAITopicStack.ResumeTopic(AIndex: Integer): TAITopicItem;
begin
  Result := nil;
  if (AIndex >= 0) and (AIndex < FPausedTopics.Count) then
  begin
    if Assigned(FActiveTopic) then
      PauseActiveTopic;

    Result := TAITopicItem(FPausedTopics[AIndex]);
    FPausedTopics.Delete(AIndex);
    Result.Status := tsActive;
    Result.LastActiveAt := Now;
    FActiveTopic := Result;
  end;
end;

function TAITopicStack.ResumeTopicByID(const AID: string): TAITopicItem;
var
  I: Integer;
begin
  Result := nil;
  for I := 0 to FPausedTopics.Count - 1 do
  begin
    if TAITopicItem(FPausedTopics[I]).ID = AID then
    begin
      Result := ResumeTopic(I);
      Exit;
    end;
  end;
end;

function TAITopicStack.CompleteActiveTopic: TAITopicItem;
begin
  Result := nil;
  if Assigned(FActiveTopic) then
  begin
    Result := FActiveTopic;
    Result.Status := tsCompleted;
    Result.LastActiveAt := Now;
    FCompletedTopics.Insert(0, Result);
    FActiveTopic := nil;
  end;
end;

function TAITopicStack.GetPausedCount: Integer;
begin
  Result := FPausedTopics.Count;
end;

function TAITopicStack.GetPausedTopic(AIndex: Integer): TAITopicItem;
begin
  if (AIndex >= 0) and (AIndex < FPausedTopics.Count) then
    Result := TAITopicItem(FPausedTopics[AIndex])
  else
    Result := nil;
end;

function TAITopicStack.GetCompletedCount: Integer;
begin
  Result := FCompletedTopics.Count;
end;

function TAITopicStack.GetCompletedTopic(AIndex: Integer): TAITopicItem;
begin
  if (AIndex >= 0) and (AIndex < FCompletedTopics.Count) then
    Result := TAITopicItem(FCompletedTopics[AIndex])
  else
    Result := nil;
end;

function TAITopicStack.FindBestPausedMatch(const AUtterance: string;
  ASemanticEngine: TAISemanticEngine; out BestSimilarity: Double): TAITopicItem;
var
  I: Integer;
  Topic: TAITopicItem;
  SimTitle, SimHistory, Sim: Double;
  UttVec: TDoubleArray;
begin
  BestSimilarity := 0.0;
  Result := nil;
  if (FPausedTopics.Count = 0) or (ASemanticEngine = nil) then Exit;

  UttVec := ASemanticEngine.ComputeVector(AUtterance);

  for I := 0 to FPausedTopics.Count - 1 do
  begin
    Topic := TAITopicItem(FPausedTopics[I]);
    SimTitle := ASemanticEngine.CosineSimilarity(UttVec, ASemanticEngine.ComputeVector(Topic.Title + ' ' + Topic.Goal + ' ' + Topic.Entities.ToSummaryString));
    if Length(Topic.CentroidVector) > 0 then
      SimHistory := ASemanticEngine.CosineSimilarity(UttVec, Topic.CentroidVector)
    else
      SimHistory := 0.0;

    Sim := Max(SimTitle, SimHistory);
    if Sim > BestSimilarity then
    begin
      BestSimilarity := Sim;
      Result := Topic;
    end;
  end;
end;

{ TAITopicContinuityClassifier }

constructor TAITopicContinuityClassifier.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FTopicStack := TAITopicStack.Create;
  FSemanticEngine := TAISemanticEngine.Create;
  FLinguisticEngine := TAILinguisticRuleEngine.Create;
  FEntityTracker := TAIEntityTracker.Create;

  // Calibração dos pesos conforme especificação:
  // P = 0,30*S + 0,25*C + 0,25*E + 0,20*I
  FWeightSemantic := 0.30;
  FWeightCoherence := 0.25;
  FWeightEntity := 0.25;
  FWeightLinguistic := 0.20;

  FContinueThreshold := 0.55;
  FNewTopicThreshold := 0.35;
  FResumeThreshold := 0.60;
  FAutoManageStack := True;

  FLastDecision := cdContinue;
  FLastScore := 1.0;
  FLastReason := '';
end;

destructor TAITopicContinuityClassifier.Destroy;
begin
  FTopicStack.Free;
  FSemanticEngine.Free;
  FLinguisticEngine.Free;
  FEntityTracker.Free;
  inherited Destroy;
end;

function TAITopicContinuityClassifier.GetActiveTopic: TAITopicItem;
begin
  Result := FTopicStack.ActiveTopic;
end;

procedure TAITopicContinuityClassifier.RegisterKnownEntity(const AName, ACategory: string);
begin
  FEntityTracker.RegisterKnownEntity(AName, ACategory);
  FLinguisticEngine.RegisterKnownEntityName(AName);
end;

procedure TAITopicContinuityClassifier.SetActiveTopic(const ATitle, AGoal: string);
begin
  FTopicStack.PushTopic(ATitle, AGoal);
end;

function TAITopicContinuityClassifier.InferTitleFromText(const AText: string; AEntities: TAIEntityList): string;
var
  Cleaned: string;
begin
  Cleaned := Trim(AText);
  if Length(Cleaned) > 45 then
    Result := Copy(Cleaned, 1, 45) + '...'
  else if Cleaned <> '' then
    Result := Cleaned
  else if Assigned(AEntities) and (AEntities.Count > 0) then
    Result := AEntities.ToSummaryString
  else
    Result := 'Assunto Geral';
end;

function TAITopicContinuityClassifier.ClassifyContinuity(const AUtterance: string;
  out ADecision: TAIContinuityDecision;
  out AScore: Double;
  out AReason: string): Boolean;
var
  Marker: TAILinguisticMarker;
  LingConfidence, LingIndicator: Double;
  MatchedSnippet, RefTarget: string;
  UtteranceEntities: TAIEntityList;
  EntityScore: Double;
  ConflictDetected: Boolean;
  ConfCat, ConfOld, ConfNew: string;
  SemanticSim, CoherenceSim, PScore: Double;
  Active: TAITopicItem;
  PausedMatch: TAITopicItem;
  PausedSim: Double;
  UttVec: TDoubleArray;
begin
  Result := True;
  Active := FTopicStack.ActiveTopic;

  // 1. Análise Linguística Determinística
  FLinguisticEngine.Analyze(AUtterance, Marker, LingConfidence, MatchedSnippet, RefTarget);

  // Mapeia o indicador linguístico (0.0 a 1.0)
  case Marker of
    lmContinue:   LingIndicator := 1.0;
    lmNone:       LingIndicator := 0.5;
    lmCorrection: LingIndicator := 0.75;
    lmResume:     LingIndicator := 0.25;
    lmShift:      LingIndicator := 0.0;
    lmFinish:     LingIndicator := 0.05;
    else          LingIndicator := 0.5;
  end;

  // 2. Extração e Comparação de Entidades
  UtteranceEntities := FEntityTracker.ExtractEntities(AUtterance);
  try
    if Assigned(Active) then
    begin
      EntityScore := FEntityTracker.CompareEntities(
        UtteranceEntities, Active.Entities,
        ConflictDetected, ConfCat, ConfOld, ConfNew
      );
    end
    else
    begin
      EntityScore := 0.5;
      ConflictDetected := False;
    end;

    // 3. Similaridade Semântica e Coerência de Objetivo
    UttVec := FSemanticEngine.ComputeVector(AUtterance);
    if Assigned(Active) then
    begin
      if Length(Active.CentroidVector) > 0 then
        SemanticSim := FSemanticEngine.CosineSimilarity(UttVec, Active.CentroidVector)
      else
        SemanticSim := FSemanticEngine.CosineSimilarity(UttVec, FSemanticEngine.ComputeVector(Active.Title));

      if Trim(Active.Goal) <> '' then
        CoherenceSim := FSemanticEngine.CosineSimilarity(UttVec, FSemanticEngine.ComputeVector(Active.Goal))
      else
        CoherenceSim := SemanticSim;
    end
    else
    begin
      SemanticSim := 0.5;
      CoherenceSim := 0.5;
    end;

    // 4. Checagem de Regras de Alta Prioridade
    // 4.1 Encerramento explícito
    if Marker = lmFinish then
    begin
      ADecision := cdFinishTask;
      AScore := 1.0;
      AReason := 'Marcador linguístico explícito de encerramento de tarefa';
      FLastDecision := ADecision;
      FLastScore := AScore;
      FLastReason := AReason;
      Exit;
    end;

    // 4.2 Correção explícita ou colisão de entidade
    if (Marker = lmCorrection) or (ConflictDetected and Assigned(Active)) then
    begin
      ADecision := cdCorrection;
      AScore := 0.95;
      if ConflictDetected then
        AReason := Format('Correção de entidade [%s]: de "%s" para "%s"', [ConfCat, ConfOld, ConfNew])
      else
        AReason := 'Marcador de correção linguística detectado';
      FLastDecision := ADecision;
      FLastScore := AScore;
      FLastReason := AReason;
      Exit;
    end;

    // 4.3 Retomada explícita por marcador ou busca na pilha de pausados
    if FTopicStack.GetPausedCount > 0 then
    begin
      PausedMatch := FTopicStack.FindBestPausedMatch(AUtterance, FSemanticEngine, PausedSim);
      if (Marker = lmResume) or (PausedSim >= FResumeThreshold) then
      begin
        ADecision := cdResumeTopic;
        AScore := PausedSim;
        AReason := Format('Retomada do tópico pausado "%s" (similaridade %.2f)', [PausedMatch.Title, PausedSim]);
        FLastDecision := ADecision;
        FLastScore := AScore;
        FLastReason := AReason;
        Exit;
      end;
    end;

    // 4.4 Ruptura explícita
    if Marker = lmShift then
    begin
      ADecision := cdNewTopic;
      AScore := 0.10;
      AReason := 'Marcador explícito de mudança de assunto';
      FLastDecision := ADecision;
      FLastScore := AScore;
      FLastReason := AReason;
      Exit;
    end;

    // 5. Se não houver tópico ativo ainda, inicia o primeiro
    if not Assigned(Active) then
    begin
      ADecision := cdNewTopic;
      AScore := 1.0;
      AReason := 'Início de conversa / Primeiro tópico';
      FLastDecision := ADecision;
      FLastScore := AScore;
      FLastReason := AReason;
      Exit;
    end;

    // 6. Cálculo da Fórmula Contextual Ponderada
    // P = 0,30*S + 0,25*C + 0,25*E + 0,20*I
    PScore := (FWeightSemantic * SemanticSim) +
              (FWeightCoherence * CoherenceSim) +
              (FWeightEntity * EntityScore) +
              (FWeightLinguistic * LingIndicator);

    AScore := PScore;

    // 7. Decisão pelos Limiares (Thresholds)
    if PScore >= FContinueThreshold then
    begin
      ADecision := cdContinue;
      AReason := Format('Continuação de tarefa confirmada (escore %.2f >= %.2f)', [PScore, FContinueThreshold]);
    end
    else if PScore < FNewTopicThreshold then
    begin
      ADecision := cdNewTopic;
      AReason := Format('Mudança de tópico detectada por baixo escore contextual (escore %.2f < %.2f)', [PScore, FNewTopicThreshold]);
    end
    else
    begin
      // Região intermediária (0.35 .. 0.55): verifica se há ambiguidade
      if (UtteranceEntities.Count = 0) and (Active.Entities.Count > 1) and
         ((Pos('esse', NormalizeStr(AUtterance)) > 0) or (Pos('aquele', NormalizeStr(AUtterance)) > 0)) then
      begin
        ADecision := cdClarification;
        AReason := 'Ambiguidade de referência detectada em região intermediária';
      end
      else
      begin
        // Default amigável na região intermediária
        ADecision := cdContinue;
        AReason := Format('Continuação contextual provável (escore moderado %.2f)', [PScore]);
      end;
    end;

    FLastDecision := ADecision;
    FLastScore := AScore;
    FLastReason := AReason;
  finally
    UtteranceEntities.Free;
  end;
end;

function TAITopicContinuityClassifier.ProcessUtterance(const AUtterance: string;
  out ADecision: TAIContinuityDecision;
  out AEnrichedPrompt: string): Boolean;
var
  Score: Double;
  Reason: string;
  OldTopic, ResumedTopic: TAITopicItem;
  PausedSim: Double;
  UtterEntities: TAIEntityList;
  I: Integer;
  NewTitle: string;
  UttVec: TDoubleArray;
begin
  Result := ClassifyContinuity(AUtterance, ADecision, Score, Reason);

  if Assigned(FOnDecision) then
    FOnDecision(Self, ADecision, Score, Reason);

  if FAutoManageStack then
  begin
    case ADecision of
      cdNewTopic:
      begin
        OldTopic := FTopicStack.ActiveTopic;
        UtterEntities := FEntityTracker.ExtractEntities(AUtterance);
        try
          NewTitle := InferTitleFromText(AUtterance, UtterEntities);
          FTopicStack.PushTopic(NewTitle, AUtterance);
          for I := 0 to UtterEntities.Count - 1 do
            FTopicStack.ActiveTopic.Entities.Add(UtterEntities[I].Category, UtterEntities[I].Value);

          UttVec := FSemanticEngine.ComputeVector(AUtterance);
          FTopicStack.ActiveTopic.CentroidVector := UttVec;
          FTopicStack.ActiveTopic.AddUtterance(AUtterance, True);

          if Assigned(FOnTopicChanged) then
            FOnTopicChanged(Self, OldTopic, FTopicStack.ActiveTopic);
        finally
          UtterEntities.Free;
        end;
      end;

      cdResumeTopic:
      begin
        ResumedTopic := FTopicStack.FindBestPausedMatch(AUtterance, FSemanticEngine, PausedSim);
        if Assigned(ResumedTopic) then
        begin
          FTopicStack.ResumeTopicByID(ResumedTopic.ID);
          FTopicStack.ActiveTopic.AddUtterance(AUtterance, True);
          UttVec := FSemanticEngine.ComputeVector(AUtterance);
          FSemanticEngine.UpdateCentroid(FTopicStack.ActiveTopic.FCentroidVector, UttVec, 0.25);

          if Assigned(FOnTopicResumed) then
            FOnTopicResumed(Self, FTopicStack.ActiveTopic);
        end;
      end;

      cdCorrection:
      begin
        if Assigned(FTopicStack.ActiveTopic) then
        begin
          UtterEntities := FEntityTracker.ExtractEntities(AUtterance);
          try
            for I := 0 to UtterEntities.Count - 1 do
            begin
              FTopicStack.ActiveTopic.UpdateEntity(UtterEntities[I].Category, UtterEntities[I].Value);
              if Assigned(FOnEntityCorrected) then
                FOnEntityCorrected(Self, UtterEntities[I].Category, '', UtterEntities[I].Value);
            end;
            FTopicStack.ActiveTopic.AddUtterance(AUtterance, True);
          finally
            UtterEntities.Free;
          end;
        end;
      end;

      cdFinishTask:
      begin
        if Assigned(FTopicStack.ActiveTopic) then
        begin
          FTopicStack.ActiveTopic.AddUtterance(AUtterance, True);
          OldTopic := FTopicStack.CompleteActiveTopic;
          if Assigned(FOnTaskCompleted) then
            FOnTaskCompleted(Self, OldTopic);
        end;
      end;

      cdContinue:
      begin
        if Assigned(FTopicStack.ActiveTopic) then
        begin
          UtterEntities := FEntityTracker.ExtractEntities(AUtterance);
          try
            for I := 0 to UtterEntities.Count - 1 do
              FTopicStack.ActiveTopic.Entities.Add(UtterEntities[I].Category, UtterEntities[I].Value);
          finally
            UtterEntities.Free;
          end;

          FTopicStack.ActiveTopic.AddUtterance(AUtterance, True);
          UttVec := FSemanticEngine.ComputeVector(AUtterance);
          FSemanticEngine.UpdateCentroid(FTopicStack.ActiveTopic.FCentroidVector, UttVec, 0.25);
        end;
      end;

      cdClarification:
      begin
        if Assigned(FOnClarificationNeeded) then
          FOnClarificationNeeded(Self, 'Poderia esclarecer a qual item você está se referindo?');
      end;
    end;
  end;

  // Monta o prompt enriquecido com escopo estrito da tarefa ativa
  AEnrichedPrompt := BuildTopicScopedContext(6);
  if AEnrichedPrompt <> '' then
    AEnrichedPrompt := AEnrichedPrompt + sLineBreak + 'Usuário: ' + Trim(AUtterance)
  else
    AEnrichedPrompt := Trim(AUtterance);
end;

procedure TAITopicContinuityClassifier.RecordAIResponse(const AResponse: string);
var
  RespVec: TDoubleArray;
begin
  if Assigned(FTopicStack.ActiveTopic) and (Trim(AResponse) <> '') then
  begin
    FTopicStack.ActiveTopic.AddUtterance(AResponse, False);
    RespVec := FSemanticEngine.ComputeVector(AResponse);
    FSemanticEngine.UpdateCentroid(FTopicStack.ActiveTopic.FCentroidVector, RespVec, 0.20);
  end;
end;

function TAITopicContinuityClassifier.BuildTopicScopedContext(AMaxUtterances: Integer): string;
var
  SB: TStringList;
  Active: TAITopicItem;
  I, StartIdx: Integer;
begin
  Active := FTopicStack.ActiveTopic;
  if not Assigned(Active) then
  begin
    Result := '';
    Exit;
  end;

  SB := TStringList.Create;
  try
    SB.Add(Format('[Contexto Ativo da Tarefa: %s]', [Active.Title]));
    if Trim(Active.Goal) <> '' then
      SB.Add('Objetivo em andamento: ' + Active.Goal);

    if Active.Entities.Count > 0 then
      SB.Add('Entidades em foco: ' + Active.Entities.ToSummaryString);

    if Active.Utterances.Count > 0 then
    begin
      SB.Add('Histórico focado da tarefa:');
      StartIdx := Max(0, Active.Utterances.Count - AMaxUtterances);
      for I := StartIdx to Active.Utterances.Count - 1 do
        SB.Add('  ' + Active.Utterances[I]);
    end;

    Result := SB.Text;
  finally
    SB.Free;
  end;
end;

function TAITopicContinuityClassifier.FormatStackSummary: string;
var
  SB: TStringList;
  I: Integer;
begin
  SB := TStringList.Create;
  try
    if Assigned(FTopicStack.ActiveTopic) then
      SB.Add('Tópico Ativo: ' + FTopicStack.ActiveTopic.FormatSummary)
    else
      SB.Add('Tópico Ativo: [Nenhum]');

    if FTopicStack.GetPausedCount > 0 then
    begin
      SB.Add(Format('Tópicos Pausados na Pilha (%d):', [FTopicStack.GetPausedCount]));
      for I := 0 to FTopicStack.GetPausedCount - 1 do
        SB.Add('  - ' + FTopicStack.GetPausedTopic(I).FormatSummary);
    end;

    if FTopicStack.GetCompletedCount > 0 then
    begin
      SB.Add(Format('Tarefas Concluídas (%d):', [FTopicStack.GetCompletedCount]));
      for I := 0 to FTopicStack.GetCompletedCount - 1 do
        SB.Add('  - ' + FTopicStack.GetCompletedTopic(I).FormatSummary);
    end;

    Result := SB.Text;
  finally
    SB.Free;
  end;
end;

procedure TAITopicContinuityClassifier.Reset;
begin
  FTopicStack.Clear;
  FLastDecision := cdContinue;
  FLastScore := 1.0;
  FLastReason := '';
end;

procedure TAITopicContinuityClassifier.Clear;
begin
  Reset;
end;

initialization
  {$I aitopiccontinuity_icon.lrs}

end.
