unit airetrieval;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Math, Contnrs, fpjson, jsonparser, fphttpclient,
  opensslsockets, aibase, chatgpt, aigraphmap;

type
  TAIDoubleArray = array of Double;

  TAIRetrievalResult = class
  public
    ChunkID: string;
    Source: string;
    Text: string;
    Score: Double;
    function Clone: TAIRetrievalResult;
  end;

  IAIRetriever = interface
    ['{C3BEB2A8-B116-4EE5-8173-289E10E35650}']
    function Retrieve(const AQuery: string; ATopK: Integer;
      AResults: TStrings): Boolean;
    function GetLastError: string;
  end;

  IAIEmbeddingProvider = interface
    ['{6B1992B3-6BE8-4C53-AFB7-D113B3F891AA}']
    function Embed(const AText: string; out AVector: TAIDoubleArray): Boolean;
    function GetDimension: Integer;
    function GetLastError: string;
  end;

  IAIReranker = interface
    ['{31674425-FD80-4814-80E1-88F206CE6815}']
    function Rerank(const AQuery: string; AResults: TStrings;
      ATopK: Integer): Boolean;
    function GetLastError: string;
  end;

  TRAGRetrievalMode = (rrmGraph, rrmVector, rrmBM25, rrmHybrid);

  TAIEmbeddingProvider = class(TAIBaseComponent, IAIEmbeddingProvider)
  protected
    FDimension: Integer;
  public
    constructor Create(AOwner: TComponent); override;
    function Embed(const AText: string; out AVector: TAIDoubleArray): Boolean; virtual; abstract;
    function GetDimension: Integer;
    function GetLastError: string;
  published
    property Dimension: Integer read FDimension write FDimension default 128;
  end;

  TAILocalEmbeddingProvider = class(TAIEmbeddingProvider)
  public
    function Embed(const AText: string; out AVector: TAIDoubleArray): Boolean; override;
  end;

  TAIOpenAIEmbeddingProvider = class(TAIEmbeddingProvider)
  private
    FToken: string;
    FEndpoint: string;
    FModel: string;
    FTimeout: Integer;
  public
    constructor Create(AOwner: TComponent); override;
    function Embed(const AText: string; out AVector: TAIDoubleArray): Boolean; override;
  published
    property Token: string read FToken write FToken;
    property Endpoint: string read FEndpoint write FEndpoint;
    property Model: string read FModel write FModel;
    property Timeout: Integer read FTimeout write FTimeout default 120000;
  end;

  TAIVectorDocument = class
  public
    ChunkID: string;
    Source: string;
    Text: string;
    Vector: TAIDoubleArray;
  end;

  TAIVectorStore = class(TAIBaseComponent)
  private
    FDocuments: TObjectList;
    function GetCount: Integer;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure Clear;
    procedure Add(const AChunkID, ASource, AText: string;
      const AVector: TAIDoubleArray);
    function Search(const AVector: TAIDoubleArray; ATopK: Integer;
      AResults: TStrings): Boolean;
    function Find(const AChunkID: string): TAIVectorDocument;
    property Count: Integer read GetCount;
  end;

  TAIGraphMapRetriever = class(TAIBaseComponent, IAIRetriever)
  private
    FGraphMap: TAIGraphMap;
    FSourcePrefix: string;
    procedure SetGraphMap(AValue: TAIGraphMap);
    function FindText(const AChunkID: string): string;
    function SourceFromID(const AChunkID: string): string;
  protected
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
  public
    constructor Create(AOwner: TComponent); override;
    function Retrieve(const AQuery: string; ATopK: Integer;
      AResults: TStrings): Boolean;
    function GetLastError: string;
  published
    property GraphMap: TAIGraphMap read FGraphMap write SetGraphMap;
    property SourcePrefix: string read FSourcePrefix write FSourcePrefix;
  end;

  TAIVectorRetriever = class(TAIBaseComponent, IAIRetriever)
  private
    FEmbeddingProvider: TAIEmbeddingProvider;
    FVectorStore: TAIVectorStore;
    procedure SetEmbeddingProvider(AValue: TAIEmbeddingProvider);
    procedure SetVectorStore(AValue: TAIVectorStore);
  protected
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
  public
    function AddDocument(const AChunkID, ASource, AText: string): Boolean;
    function Retrieve(const AQuery: string; ATopK: Integer;
      AResults: TStrings): Boolean;
    function GetLastError: string;
  published
    property EmbeddingProvider: TAIEmbeddingProvider read FEmbeddingProvider write SetEmbeddingProvider;
    property VectorStore: TAIVectorStore read FVectorStore write SetVectorStore;
  end;

  TAIBM25Retriever = class(TAIBaseComponent, IAIRetriever)
  private
    FDocuments: TObjectList;
    FK1: Double;
    FB: Double;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure Clear;
    procedure AddDocument(const AChunkID, ASource, AText: string);
    function Retrieve(const AQuery: string; ATopK: Integer;
      AResults: TStrings): Boolean;
    function GetLastError: string;
  published
    property K1: Double read FK1 write FK1;
    property B: Double read FB write FB;
  end;

  TAIRankFusion = class
  public
    class procedure FuseRRF(const ALists: array of TStrings;
      ARankConstant, ATopK: Integer; AResults: TStrings); static;
  end;

  TAILLMReranker = class(TAIBaseComponent, IAIReranker)
  private
    FChatGPT: TCHATGPT;
    procedure SetChatGPT(AValue: TCHATGPT);
  protected
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
  public
    function Rerank(const AQuery: string; AResults: TStrings;
      ATopK: Integer): Boolean;
    function GetLastError: string;
  published
    property ChatGPT: TCHATGPT read FChatGPT write SetChatGPT;
  end;

function CosineSimilarity(const A, B: TAIDoubleArray): Double;
procedure FreeRetrievalResults(AResults: TStrings);
procedure ApplyTokenBudget(AResults: TStrings; AMaxTokens: Integer);
procedure Register;

implementation

type
  TBM25Document = class
  public
    ChunkID: string;
    Source: string;
    Text: string;
    Terms: TStringList;
    TermCount: Integer;
    constructor Create;
    destructor Destroy; override;
  end;

function RetrievalSort(List: TStringList; Index1, Index2: Integer): Integer;
var
  A, B: TAIRetrievalResult;
begin
  A := TAIRetrievalResult(List.Objects[Index1]);
  B := TAIRetrievalResult(List.Objects[Index2]);
  if A.Score > B.Score then Result := -1
  else if A.Score < B.Score then Result := 1
  else Result := CompareText(A.ChunkID, B.ChunkID);
end;

procedure SortResults(AResults: TStrings);
begin
  if AResults is TStringList then
    TStringList(AResults).CustomSort(@RetrievalSort);
end;

procedure TrimResults(AResults: TStrings; ATopK: Integer);
begin
  if ATopK <= 0 then Exit;
  while AResults.Count > ATopK do
  begin
    AResults.Objects[AResults.Count - 1].Free;
    AResults.Delete(AResults.Count - 1);
  end;
end;

function Tokenize(const AText: string): TStringList;
var
  I: Integer;
  Token: string;
  C: Char;
begin
  Result := TStringList.Create;
  Result.CaseSensitive := False;
  Token := '';
  for I := 1 to Length(AText) do
  begin
    C := AText[I];
    if C in ['a'..'z', 'A'..'Z', '0'..'9', '_'] then
      Token := Token + LowerCase(C)
    else if Token <> '' then
    begin
      Result.Add(Token);
      Token := '';
    end;
  end;
  if Token <> '' then Result.Add(Token);
end;

function HashToken(const S: string): Cardinal;
var
  I: Integer;
begin
  Result := 2166136261;
  for I := 1 to Length(S) do
  begin
    Result := Result xor Ord(S[I]);
    Result := Result * 16777619;
  end;
end;

function CosineSimilarity(const A, B: TAIDoubleArray): Double;
var
  I, N: Integer;
  Dot, NA, NB: Double;
begin
  N := Min(Length(A), Length(B));
  Dot := 0; NA := 0; NB := 0;
  for I := 0 to N - 1 do
  begin
    Dot := Dot + A[I] * B[I];
    NA := NA + Sqr(A[I]);
    NB := NB + Sqr(B[I]);
  end;
  if (NA <= 0) or (NB <= 0) then Exit(0);
  Result := Dot / (Sqrt(NA) * Sqrt(NB));
end;

procedure FreeRetrievalResults(AResults: TStrings);
var
  I: Integer;
begin
  if AResults = nil then Exit;
  for I := 0 to AResults.Count - 1 do AResults.Objects[I].Free;
  AResults.Clear;
end;

procedure ApplyTokenBudget(AResults: TStrings; AMaxTokens: Integer);
var
  I, Used, Estimate: Integer;
begin
  if (AResults = nil) or (AMaxTokens <= 0) then Exit;
  Used := 0;
  I := 0;
  while I < AResults.Count do
  begin
    Estimate := Max(1, Length(TAIRetrievalResult(AResults.Objects[I]).Text) div 4);
    if Used + Estimate > AMaxTokens then
    begin
      AResults.Objects[I].Free;
      AResults.Delete(I);
    end
    else
    begin
      Inc(Used, Estimate);
      Inc(I);
    end;
  end;
end;

function TAIRetrievalResult.Clone: TAIRetrievalResult;
begin
  Result := TAIRetrievalResult.Create;
  Result.ChunkID := ChunkID;
  Result.Source := Source;
  Result.Text := Text;
  Result.Score := Score;
end;

{ Embeddings }

constructor TAIEmbeddingProvider.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FDimension := 128;
  FCategory := ccModel;
end;

function TAIEmbeddingProvider.GetDimension: Integer;
begin
  Result := FDimension;
end;

function TAIEmbeddingProvider.GetLastError: string;
begin
  Result := FLastError;
end;

function TAILocalEmbeddingProvider.Embed(const AText: string;
  out AVector: TAIDoubleArray): Boolean;
var
  Tokens: TStringList;
  I, Index: Integer;
  Norm: Double;
begin
  ClearError;
  SetLength(AVector, Max(8, FDimension));
  Tokens := Tokenize(AText);
  try
    for I := 0 to Tokens.Count - 1 do
    begin
      Index := HashToken(Tokens[I]) mod Length(AVector);
      AVector[Index] := AVector[Index] + 1;
    end;
  finally
    Tokens.Free;
  end;
  Norm := 0;
  for I := 0 to High(AVector) do Norm := Norm + Sqr(AVector[I]);
  Norm := Sqrt(Norm);
  if Norm > 0 then for I := 0 to High(AVector) do AVector[I] := AVector[I] / Norm;
  Result := Length(AVector) > 0;
  FLastSuccess := Result;
end;

constructor TAIOpenAIEmbeddingProvider.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FEndpoint := 'https://api.openai.com/v1/embeddings';
  FModel := 'text-embedding-3-small';
  FTimeout := 120000;
end;

function TAIOpenAIEmbeddingProvider.Embed(const AText: string;
  out AVector: TAIDoubleArray): Boolean;
var
  HTTP: TFPHttpClient;
  Root: TJSONObject;
  Body: TStringStream;
  Raw: string;
  Data, VectorData: TJSONData;
  Arr: TJSONArray;
  I: Integer;
begin
  Result := False;
  SetLength(AVector, 0);
  ClearError;
  Root := TJSONObject.Create;
  try
    Root.Add('model', FModel);
    Root.Add('input', AText);
    Body := TStringStream.Create(Root.AsJSON);
  finally
    Root.Free;
  end;
  HTTP := TFPHttpClient.Create(nil);
  try
    HTTP.ConnectTimeout := FTimeout;
    HTTP.IOTimeout := FTimeout;
    HTTP.AddHeader('Content-Type', 'application/json');
    if FToken <> '' then HTTP.AddHeader('Authorization', 'Bearer ' + FToken);
    HTTP.RequestBody := Body;
    try
      Raw := HTTP.Post(FEndpoint);
      Data := GetJSON(Raw);
      try
        VectorData := Data.FindPath('data[0].embedding');
        if (VectorData = nil) or (VectorData.JSONType <> jtArray) then
          raise Exception.Create('Resposta de embeddings sem data[0].embedding.');
        Arr := TJSONArray(VectorData);
        SetLength(AVector, Arr.Count);
        for I := 0 to Arr.Count - 1 do AVector[I] := Arr.Floats[I];
        FDimension := Length(AVector);
        Result := FDimension > 0;
      finally
        Data.Free;
      end;
    except
      on E: Exception do SetError(E.Message);
    end;
  finally
    HTTP.RequestBody := nil;
    Body.Free;
    HTTP.Free;
  end;
  FLastSuccess := Result;
end;

{ Vector store }

constructor TAIVectorStore.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FDocuments := TObjectList.Create(True);
end;

destructor TAIVectorStore.Destroy;
begin
  FDocuments.Free;
  inherited Destroy;
end;

procedure TAIVectorStore.Clear;
begin
  FDocuments.Clear;
end;

function TAIVectorStore.GetCount: Integer;
begin
  Result := FDocuments.Count;
end;

function TAIVectorStore.Find(const AChunkID: string): TAIVectorDocument;
var
  I: Integer;
begin
  for I := 0 to FDocuments.Count - 1 do
    if SameText(TAIVectorDocument(FDocuments[I]).ChunkID, AChunkID) then
      Exit(TAIVectorDocument(FDocuments[I]));
  Result := nil;
end;

procedure TAIVectorStore.Add(const AChunkID, ASource, AText: string;
  const AVector: TAIDoubleArray);
var
  Doc: TAIVectorDocument;
begin
  Doc := Find(AChunkID);
  if Doc = nil then
  begin
    Doc := TAIVectorDocument.Create;
    FDocuments.Add(Doc);
  end;
  Doc.ChunkID := AChunkID;
  Doc.Source := ASource;
  Doc.Text := AText;
  Doc.Vector := Copy(AVector, 0, Length(AVector));
end;

function TAIVectorStore.Search(const AVector: TAIDoubleArray; ATopK: Integer;
  AResults: TStrings): Boolean;
var
  I: Integer;
  Doc: TAIVectorDocument;
  Item: TAIRetrievalResult;
begin
  FreeRetrievalResults(AResults);
  for I := 0 to FDocuments.Count - 1 do
  begin
    Doc := TAIVectorDocument(FDocuments[I]);
    Item := TAIRetrievalResult.Create;
    Item.ChunkID := Doc.ChunkID;
    Item.Source := Doc.Source;
    Item.Text := Doc.Text;
    Item.Score := CosineSimilarity(AVector, Doc.Vector);
    AResults.AddObject(Item.ChunkID, Item);
  end;
  SortResults(AResults);
  TrimResults(AResults, ATopK);
  Result := AResults.Count > 0;
end;

{ Graph adapter }

constructor TAIGraphMapRetriever.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FSourcePrefix := 'rag:';
end;

procedure TAIGraphMapRetriever.SetGraphMap(AValue: TAIGraphMap);
begin
  if FGraphMap = AValue then Exit;
  if FGraphMap <> nil then FGraphMap.RemoveFreeNotification(Self);
  FGraphMap := AValue;
  if FGraphMap <> nil then FGraphMap.FreeNotification(Self);
end;

procedure TAIGraphMapRetriever.Notification(AComponent: TComponent;
  Operation: TOperation);
begin
  inherited Notification(AComponent, Operation);
  if (Operation = opRemove) and (AComponent = FGraphMap) then FGraphMap := nil;
end;

function TAIGraphMapRetriever.FindText(const AChunkID: string): string;
var
  I: Integer;
begin
  Result := '';
  if FGraphMap = nil then Exit;
  for I := 0 to FGraphMap.Training.Count - 1 do
    if SameText(FGraphMap.Training[I].OutputCategory, AChunkID) then
      Exit(FGraphMap.Training[I].InputText);
end;

function TAIGraphMapRetriever.SourceFromID(const AChunkID: string): string;
var
  P: Integer;
begin
  Result := AChunkID;
  if SameText(Copy(Result, 1, Length(FSourcePrefix)), FSourcePrefix) then
    Delete(Result, 1, Length(FSourcePrefix));
  P := Pos('#', Result);
  if P > 0 then Result := Copy(Result, 1, P - 1);
end;

function TAIGraphMapRetriever.Retrieve(const AQuery: string; ATopK: Integer;
  AResults: TStrings): Boolean;
var
  Ranking: TStringList;
  I: Integer;
  Item: TAIRetrievalResult;
begin
  Result := False;
  FreeRetrievalResults(AResults);
  if FGraphMap = nil then begin SetError('GraphMap nao associado.'); Exit; end;
  Ranking := TStringList.Create;
  try
    FGraphMap.PredictRanking(AQuery, Ranking);
    for I := 0 to Ranking.Count - 1 do
    begin
      if (ATopK > 0) and (AResults.Count >= ATopK) then Break;
      if not SameText(Copy(Ranking.Names[I], 1, Length(FSourcePrefix)), FSourcePrefix) then Continue;
      Item := TAIRetrievalResult.Create;
      Item.ChunkID := Ranking.Names[I];
      Item.Source := SourceFromID(Item.ChunkID);
      Item.Text := FindText(Item.ChunkID);
      Item.Score := StrToFloatDef(StringReplace(Ranking.ValueFromIndex[I], ',', '.', [rfReplaceAll]), 0);
      if Item.Text = '' then Item.Free else AResults.AddObject(Item.ChunkID, Item);
    end;
    Result := AResults.Count > 0;
  finally
    Ranking.Free;
  end;
  FLastSuccess := Result;
end;

function TAIGraphMapRetriever.GetLastError: string;
begin
  Result := FLastError;
end;

{ Vector retriever }

procedure TAIVectorRetriever.SetEmbeddingProvider(AValue: TAIEmbeddingProvider);
begin
  if FEmbeddingProvider = AValue then Exit;
  if FEmbeddingProvider <> nil then FEmbeddingProvider.RemoveFreeNotification(Self);
  FEmbeddingProvider := AValue;
  if FEmbeddingProvider <> nil then FEmbeddingProvider.FreeNotification(Self);
end;

procedure TAIVectorRetriever.SetVectorStore(AValue: TAIVectorStore);
begin
  if FVectorStore = AValue then Exit;
  if FVectorStore <> nil then FVectorStore.RemoveFreeNotification(Self);
  FVectorStore := AValue;
  if FVectorStore <> nil then FVectorStore.FreeNotification(Self);
end;

procedure TAIVectorRetriever.Notification(AComponent: TComponent;
  Operation: TOperation);
begin
  inherited Notification(AComponent, Operation);
  if Operation = opRemove then
  begin
    if AComponent = FEmbeddingProvider then FEmbeddingProvider := nil;
    if AComponent = FVectorStore then FVectorStore := nil;
  end;
end;

function TAIVectorRetriever.AddDocument(const AChunkID, ASource,
  AText: string): Boolean;
var
  Vector: TAIDoubleArray;
begin
  Result := (FEmbeddingProvider <> nil) and (FVectorStore <> nil) and
    FEmbeddingProvider.Embed(AText, Vector);
  if Result then FVectorStore.Add(AChunkID, ASource, AText, Vector)
  else SetError('EmbeddingProvider/VectorStore invalido ou embedding falhou.');
end;

function TAIVectorRetriever.Retrieve(const AQuery: string; ATopK: Integer;
  AResults: TStrings): Boolean;
var
  Vector: TAIDoubleArray;
begin
  Result := False;
  if (FEmbeddingProvider = nil) or (FVectorStore = nil) then
  begin SetError('EmbeddingProvider/VectorStore nao associado.'); Exit; end;
  if not FEmbeddingProvider.Embed(AQuery, Vector) then
  begin SetError(FEmbeddingProvider.LastError); Exit; end;
  Result := FVectorStore.Search(Vector, ATopK, AResults);
  FLastSuccess := Result;
end;

function TAIVectorRetriever.GetLastError: string;
begin
  Result := FLastError;
end;

{ BM25 }

constructor TBM25Document.Create;
begin
  Terms := TStringList.Create;
  Terms.CaseSensitive := False;
  Terms.NameValueSeparator := '=';
end;

destructor TBM25Document.Destroy;
begin
  Terms.Free;
  inherited Destroy;
end;

constructor TAIBM25Retriever.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FDocuments := TObjectList.Create(True);
  FK1 := 1.5;
  FB := 0.75;
end;

destructor TAIBM25Retriever.Destroy;
begin
  FDocuments.Free;
  inherited Destroy;
end;

procedure TAIBM25Retriever.Clear;
begin
  FDocuments.Clear;
end;

procedure TAIBM25Retriever.AddDocument(const AChunkID, ASource, AText: string);
var
  Doc: TBM25Document;
  Tokens: TStringList;
  I, Count: Integer;
begin
  Doc := TBM25Document.Create;
  Doc.ChunkID := AChunkID; Doc.Source := ASource; Doc.Text := AText;
  Tokens := Tokenize(AText);
  try
    Doc.TermCount := Tokens.Count;
    for I := 0 to Tokens.Count - 1 do
    begin
      Count := StrToIntDef(Doc.Terms.Values[Tokens[I]], 0) + 1;
      Doc.Terms.Values[Tokens[I]] := IntToStr(Count);
    end;
  finally
    Tokens.Free;
  end;
  FDocuments.Add(Doc);
end;

function TAIBM25Retriever.Retrieve(const AQuery: string; ATopK: Integer;
  AResults: TStrings): Boolean;
var
  Query: TStringList;
  I, J, K, DF, TF: Integer;
  AvgDL, IDF, Denom, Score: Double;
  Doc, Other: TBM25Document;
  Item: TAIRetrievalResult;
begin
  FreeRetrievalResults(AResults);
  if FDocuments.Count = 0 then begin SetError('Indice BM25 vazio.'); Exit(False); end;
  AvgDL := 0;
  for I := 0 to FDocuments.Count - 1 do AvgDL := AvgDL + TBM25Document(FDocuments[I]).TermCount;
  AvgDL := AvgDL / FDocuments.Count;
  Query := Tokenize(AQuery);
  try
    for I := 0 to FDocuments.Count - 1 do
    begin
      Doc := TBM25Document(FDocuments[I]);
      Score := 0;
      for J := 0 to Query.Count - 1 do
      begin
        TF := StrToIntDef(Doc.Terms.Values[Query[J]], 0);
        if TF = 0 then Continue;
        DF := 0;
        for K := 0 to FDocuments.Count - 1 do
        begin
          Other := TBM25Document(FDocuments[K]);
          if StrToIntDef(Other.Terms.Values[Query[J]], 0) > 0 then Inc(DF);
        end;
        IDF := Ln(1 + (FDocuments.Count - DF + 0.5) / (DF + 0.5));
        Denom := TF + FK1 * (1 - FB + FB * Doc.TermCount / Max(1, AvgDL));
        Score := Score + IDF * (TF * (FK1 + 1)) / Denom;
      end;
      if Score > 0 then
      begin
        Item := TAIRetrievalResult.Create;
        Item.ChunkID := Doc.ChunkID; Item.Source := Doc.Source;
        Item.Text := Doc.Text; Item.Score := Score;
        AResults.AddObject(Item.ChunkID, Item);
      end;
    end;
  finally
    Query.Free;
  end;
  SortResults(AResults);
  TrimResults(AResults, ATopK);
  Result := AResults.Count > 0;
  FLastSuccess := Result;
end;

function TAIBM25Retriever.GetLastError: string;
begin
  Result := FLastError;
end;

{ Rank fusion }

class procedure TAIRankFusion.FuseRRF(const ALists: array of TStrings;
  ARankConstant, ATopK: Integer; AResults: TStrings);
var
  Map: TStringList;
  L, I, Idx: Integer;
  Src, Acc: TAIRetrievalResult;
begin
  FreeRetrievalResults(AResults);
  Map := TStringList.Create;
  try
    Map.CaseSensitive := False;
    for L := Low(ALists) to High(ALists) do
      if ALists[L] <> nil then
        for I := 0 to ALists[L].Count - 1 do
        begin
          Src := TAIRetrievalResult(ALists[L].Objects[I]);
          Idx := Map.IndexOf(Src.ChunkID);
          if Idx < 0 then
          begin
            Acc := Src.Clone;
            Acc.Score := 0;
            Map.AddObject(Acc.ChunkID, Acc);
          end
          else Acc := TAIRetrievalResult(Map.Objects[Idx]);
          Acc.Score := Acc.Score + 1.0 / (Max(1, ARankConstant) + I + 1);
        end;
    for I := 0 to Map.Count - 1 do
      AResults.AddObject(Map[I], TAIRetrievalResult(Map.Objects[I]).Clone);
    SortResults(AResults);
    TrimResults(AResults, ATopK);
  finally
    for I := 0 to Map.Count - 1 do Map.Objects[I].Free;
    Map.Free;
  end;
end;

{ LLM reranker }

procedure TAILLMReranker.SetChatGPT(AValue: TCHATGPT);
begin
  if FChatGPT = AValue then Exit;
  if FChatGPT <> nil then FChatGPT.RemoveFreeNotification(Self);
  FChatGPT := AValue;
  if FChatGPT <> nil then FChatGPT.FreeNotification(Self);
end;

procedure TAILLMReranker.Notification(AComponent: TComponent;
  Operation: TOperation);
begin
  inherited Notification(AComponent, Operation);
  if (Operation = opRemove) and (AComponent = FChatGPT) then FChatGPT := nil;
end;

function TAILLMReranker.Rerank(const AQuery: string; AResults: TStrings;
  ATopK: Integer): Boolean;
var
  I: Integer;
  Item: TAIRetrievalResult;
  LPrompt, Answer: string;
begin
  Result := False;
  if FChatGPT = nil then begin SetError('ChatGPT nao associado ao reranker.'); Exit; end;
  for I := 0 to AResults.Count - 1 do
  begin
    Item := TAIRetrievalResult(AResults.Objects[I]);
    LPrompt := 'Avalie a relevancia do trecho para a pergunta em um numero de 0 a 1. ' +
      'Responda somente o numero.' + LineEnding + 'Pergunta: ' + AQuery +
      LineEnding + 'Trecho: ' + Item.Text;
    if FChatGPT.SendQuestion(LPrompt) then
    begin
      Answer := StringReplace(Trim(UTF8Encode(FChatGPT.Response)), ',', '.', [rfReplaceAll]);
      Item.Score := StrToFloatDef(Answer, Item.Score);
    end;
  end;
  SortResults(AResults);
  TrimResults(AResults, ATopK);
  Result := AResults.Count > 0;
  FLastSuccess := Result;
end;

function TAILLMReranker.GetLastError: string;
begin
  Result := FLastError;
end;

procedure Register;
begin
  RegisterComponents('AI RAG', [
    TAILocalEmbeddingProvider,
    TAIOpenAIEmbeddingProvider,
    TAIVectorStore,
    TAIVectorRetriever,
    TAIGraphMapRetriever,
    TAIBM25Retriever,
    TAILLMReranker
  ]);
end;

initialization
  RegisterClasses([
    TAILocalEmbeddingProvider,
    TAIOpenAIEmbeddingProvider,
    TAIVectorStore,
    TAIVectorRetriever,
    TAIGraphMapRetriever,
    TAIBM25Retriever,
    TAILLMReranker
  ]);

end.
