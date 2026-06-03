unit aigraphmap;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpjson, jsonparser, LResources, aibase, LazUTF8;

type
  TAIErrorEvent = procedure(Sender: TObject; const AError: string) of object;
  TTokenizedEvent = procedure(Sender: TObject; ATokens: TStrings) of object;

  { TAITrainingItem }

  TAITrainingItem = class(TCollectionItem)
  private
    FInputText: string;
    FOutputCategory: string;
    FWeight: Double;
  published
    property InputText: string read FInputText write FInputText;
    property OutputCategory: string read FOutputCategory write FOutputCategory;
    property Weight: Double read FWeight write FWeight;
  end;

  { TAITrainingCollection }

  TAITrainingCollection = class(TOwnedCollection)
  private
    function GetItem(Index: Integer): TAITrainingItem;
    procedure SetItem(Index: Integer; AValue: TAITrainingItem);
  public
    constructor Create(AOwner: TPersistent);
    function Add: TAITrainingItem;
    property Items[Index: Integer]: TAITrainingItem read GetItem write SetItem; default;
  end;

  { TAITokenizer }

  TAITokenizer = class(TComponent)
  public
    function Tokenize(const AText: string): TStrings; virtual; abstract;
  end;

  { TAIBaseTrainingExporter }

  TAIBaseTrainingExporter = class(TAIBaseComponent)
  public
    procedure ExportData(ATraining: TAITrainingCollection); virtual; abstract;
    procedure ImportData(ATraining: TAITrainingCollection); virtual; abstract;
  end;

  { TAIGraphNodeType }

  TAIGraphNodeType = (ntToken, ntCategory);

  { TAIGraphNode }

  TAIGraphNode = class
  public
    Id: Integer;
    Text: string;
    NodeType: TAIGraphNodeType;
    Weight: Double;
    HitCount: Integer;
    constructor Create(AId: Integer; const AText: string; AType: TAIGraphNodeType);
  end;

  { TAIGraphEdge }

  TAIGraphEdge = class
  public
    FromNodeId: Integer;
    ToNodeId: Integer;
    Weight: Double;
    HitCount: Integer;
    constructor Create(AFrom, ATo: Integer; AWeight: Double);
  end;

  { TScoreItem }

  TScoreItem = class
  public
    Category: string;
    Score: Double;
    constructor Create(const ACat: string; AScore: Double);
  end;

  { TAIGraphMap }

  TAIGraphMap = class(TAIBaseComponent)
  private
    FTraining: TAITrainingCollection;
    
    // External Tokenizer
    FTokenizer: TAITokenizer;
    
    // Tokenizer configurations
    FLowerCaseTokens: Boolean;
    FRemoveAccents: Boolean;
    FRemoveStopWords: Boolean;
    FMinTokenLength: Integer;
    FTokenDelimiterChars: string;
    FStopWords: TStrings;
    FUniqueTokensPerText: Boolean;
    
    // Graph weight configurations
    FWindowSize: Integer;
    FTokenEdgeWeight: Double;
    FCategoryEdgeWeight: Double;
    FRepetitionBoost: Double;
    FUseTokenSequenceEdges: Boolean;
    FUseTokenCategoryEdges: Boolean;
    FAutoClearBeforeTrain: Boolean;
    
    // Prediction configurations
    FUseGraphDepthSearch: Boolean;
    FMaxDepth: Integer;
    FDepthDecay: Double;
    FMinimumScore: Double;
    FUnknownCategoryName: string;
    FNormalizeScores: Boolean;
    
    // Advanced features
    FSynonyms: TStrings;
    FNegativeRelations: TStrings;
    FLastMatchedTokens: TStrings;
    
    // State
    FLastCategory: string;
    FLastRanking: TStrings;
    FLastExplanation: TStrings;
    FNodeCount: Integer;
    FEdgeCount: Integer;
    
    // Internal Graph Lists & Performance Indices
    FNodes: TList;
    FEdges: TList;
    FNodeCounter: Integer;
    FNodeIndex: TStringList;
    FNodeIdIndex: TStringList;
    FEdgeIndex: TStringList;
    
    // Events
    FOnBeforeTrain: TNotifyEvent;
    FOnAfterTrain: TNotifyEvent;
    FOnBeforePredict: TNotifyEvent;
    FOnAfterPredict: TNotifyEvent;
    FOnTokenized: TTokenizedEvent;
    FOnGraphChanged: TNotifyEvent;
    FOnError: TAIErrorEvent;
    
    function CreateNode(const AText: string; AType: TAIGraphNodeType): TAIGraphNode;
    function CreateEdge(AFromId, AToId: Integer; AWeight: Double): TAIGraphEdge;
    
    procedure TraverseGraph(
      ANodeId: Integer;
      ACurrentDepth: Integer;
      ACurrentFactor: Double;
      AScores: TStringList;
      AVisited: TList
    );
    procedure DoError(const AError: string);
    procedure SetStopWords(AValue: TStrings);
    procedure SetSynonyms(AValue: TStrings);
    procedure SetNegativeRelations(AValue: TStrings);
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    
    function FindNode(const AText: string; AType: TAIGraphNodeType): TAIGraphNode;
    function FindNodeById(AId: Integer): TAIGraphNode;
    function FindEdge(AFromId, AToId: Integer): TAIGraphEdge;

    procedure ClearGraph;
    procedure ClearTraining;
    
    function Tokenize(const AText: string): TStrings;
    procedure TokenizeToStrings(const AText: string; AOutList: TStrings);
    
    procedure Train;
    procedure TrainItem(const AInput, ACategory: string; AWeight: Double);
    
    function Predict(const AText: string): string;
    procedure PredictRanking(const AText: string; AResultList: TStrings);
    procedure ExplainPrediction(const AText: string; AExplanation: TStrings);
    
    procedure SaveGraphToFile(const AFileName: string);
    procedure LoadGraphFromFile(const AFileName: string);
    
    procedure SaveTrainingToFile(const AFileName: string);
    procedure LoadTrainingFromFile(const AFileName: string);
    
    procedure ExportToGraphViz(const AFileName: string);
    
    // New evaluation & export methods
    function Evaluate(ATestData: TAITrainingCollection): Double;
    procedure ConfusionMatrix(ATestData: TAITrainingCollection; AResult: TStrings);
    procedure SaveGraphAsDOT(const AFileName: string);
    procedure SaveGraphAsGEXF(const AFileName: string);
    procedure SaveGraphAsCSV(const ANodeFile, AEdgeFile: string);
    procedure ExportTraining(AExporter: TAIBaseTrainingExporter);
    procedure ImportTraining(AExporter: TAIBaseTrainingExporter);
    
    property NodeCount: Integer read FNodeCount;
    property EdgeCount: Integer read FEdgeCount;
    property Nodes: TList read FNodes;
    property Edges: TList read FEdges;
  published
    property Training: TAITrainingCollection read FTraining write FTraining;
    
    // External modules
    property Tokenizer: TAITokenizer read FTokenizer write FTokenizer;
    
    // Tokenizer
    property LowerCaseTokens: Boolean read FLowerCaseTokens write FLowerCaseTokens default True;
    property RemoveAccents: Boolean read FRemoveAccents write FRemoveAccents default True;
    property RemoveStopWords: Boolean read FRemoveStopWords write FRemoveStopWords default True;
    property MinTokenLength: Integer read FMinTokenLength write FMinTokenLength default 3;
    property TokenDelimiterChars: string read FTokenDelimiterChars write FTokenDelimiterChars;
    property StopWords: TStrings read FStopWords write SetStopWords;
    property UniqueTokensPerText: Boolean read FUniqueTokensPerText write FUniqueTokensPerText default True;
    
    // Graph Weights
    property WindowSize: Integer read FWindowSize write FWindowSize default 2;
    property TokenEdgeWeight: Double read FTokenEdgeWeight write FTokenEdgeWeight;
    property CategoryEdgeWeight: Double read FCategoryEdgeWeight write FCategoryEdgeWeight;
    property RepetitionBoost: Double read FRepetitionBoost write FRepetitionBoost;
    property UseTokenSequenceEdges: Boolean read FUseTokenSequenceEdges write FUseTokenSequenceEdges default True;
    property UseTokenCategoryEdges: Boolean read FUseTokenCategoryEdges write FUseTokenCategoryEdges default True;
    property AutoClearBeforeTrain: Boolean read FAutoClearBeforeTrain write FAutoClearBeforeTrain default True;
    
    // Search & Predict
    property UseGraphDepthSearch: Boolean read FUseGraphDepthSearch write FUseGraphDepthSearch default True;
    property MaxDepth: Integer read FMaxDepth write FMaxDepth default 2;
    property DepthDecay: Double read FDepthDecay write FDepthDecay;
    property MinimumScore: Double read FMinimumScore write FMinimumScore;
    property UnknownCategoryName: string read FUnknownCategoryName write FUnknownCategoryName;
    property NormalizeScores: Boolean read FNormalizeScores write FNormalizeScores default True;
    
    // Advanced features
    property Synonyms: TStrings read FSynonyms write SetSynonyms;
    property NegativeRelations: TStrings read FNegativeRelations write SetNegativeRelations;
    property LastMatchedTokens: TStrings read FLastMatchedTokens;
    property Category default ccModel;
    
    // Read-Only Status properties
    property LastCategory: string read FLastCategory;
    property LastRanking: TStrings read FLastRanking;
    property LastExplanation: TStrings read FLastExplanation;
    
    // Events
    property OnBeforeTrain: TNotifyEvent read FOnBeforeTrain write FOnBeforeTrain;
    property OnAfterTrain: TNotifyEvent read FOnAfterTrain write FOnAfterTrain;
    property OnBeforePredict: TNotifyEvent read FOnBeforePredict write FOnBeforePredict;
    property OnAfterPredict: TNotifyEvent read FOnAfterPredict write FOnAfterPredict;
    property OnTokenized: TTokenizedEvent read FOnTokenized write FOnTokenized;
    property OnGraphChanged: TNotifyEvent read FOnGraphChanged write FOnGraphChanged;
    property OnError: TAIErrorEvent read FOnError write FOnError;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('AI Graphic', [TAIGraphMap]);
end;

function RemoveAccentsStr(const AText: string): string;
begin
  Result := AText;
  Result := StringReplace(Result, 'á', 'a', [rfReplaceAll]);
  Result := StringReplace(Result, 'à', 'a', [rfReplaceAll]);
  Result := StringReplace(Result, 'â', 'a', [rfReplaceAll]);
  Result := StringReplace(Result, 'ã', 'a', [rfReplaceAll]);
  Result := StringReplace(Result, 'ä', 'a', [rfReplaceAll]);
  Result := StringReplace(Result, 'é', 'e', [rfReplaceAll]);
  Result := StringReplace(Result, 'è', 'e', [rfReplaceAll]);
  Result := StringReplace(Result, 'ê', 'e', [rfReplaceAll]);
  Result := StringReplace(Result, 'í', 'i', [rfReplaceAll]);
  Result := StringReplace(Result, 'ì', 'i', [rfReplaceAll]);
  Result := StringReplace(Result, 'î', 'i', [rfReplaceAll]);
  Result := StringReplace(Result, 'ï', 'i', [rfReplaceAll]);
  Result := StringReplace(Result, 'ó', 'o', [rfReplaceAll]);
  Result := StringReplace(Result, 'ò', 'o', [rfReplaceAll]);
  Result := StringReplace(Result, 'ô', 'o', [rfReplaceAll]);
  Result := StringReplace(Result, 'õ', 'o', [rfReplaceAll]);
  Result := StringReplace(Result, 'ö', 'o', [rfReplaceAll]);
  Result := StringReplace(Result, 'ú', 'u', [rfReplaceAll]);
  Result := StringReplace(Result, 'ù', 'u', [rfReplaceAll]);
  Result := StringReplace(Result, 'û', 'u', [rfReplaceAll]);
  Result := StringReplace(Result, 'ü', 'u', [rfReplaceAll]);
  Result := StringReplace(Result, 'ç', 'c', [rfReplaceAll]);
  Result := StringReplace(Result, 'Á', 'A', [rfReplaceAll]);
  Result := StringReplace(Result, 'À', 'A', [rfReplaceAll]);
  Result := StringReplace(Result, 'Â', 'A', [rfReplaceAll]);
  Result := StringReplace(Result, 'Ã', 'A', [rfReplaceAll]);
  Result := StringReplace(Result, 'Ä', 'A', [rfReplaceAll]);
  Result := StringReplace(Result, 'É', 'E', [rfReplaceAll]);
  Result := StringReplace(Result, 'È', 'E', [rfReplaceAll]);
  Result := StringReplace(Result, 'Ê', 'E', [rfReplaceAll]);
  Result := StringReplace(Result, 'Í', 'I', [rfReplaceAll]);
  Result := StringReplace(Result, 'Ì', 'I', [rfReplaceAll]);
  Result := StringReplace(Result, 'Î', 'I', [rfReplaceAll]);
  Result := StringReplace(Result, 'Ï', 'I', [rfReplaceAll]);
  Result := StringReplace(Result, 'Ó', 'O', [rfReplaceAll]);
  Result := StringReplace(Result, 'Ò', 'O', [rfReplaceAll]);
  Result := StringReplace(Result, 'Ô', 'O', [rfReplaceAll]);
  Result := StringReplace(Result, 'Õ', 'O', [rfReplaceAll]);
  Result := StringReplace(Result, 'Ö', 'O', [rfReplaceAll]);
  Result := StringReplace(Result, 'Ú', 'U', [rfReplaceAll]);
  Result := StringReplace(Result, 'Ù', 'U', [rfReplaceAll]);
  Result := StringReplace(Result, 'Û', 'U', [rfReplaceAll]);
  Result := StringReplace(Result, 'Ü', 'U', [rfReplaceAll]);
  Result := StringReplace(Result, 'Ç', 'C', [rfReplaceAll]);
end;

procedure SortScoreItems(AList: TList);
var
  i, j: Integer;
  Temp: TScoreItem;
begin
  for i := 0 to AList.Count - 2 do
  begin
    for j := i + 1 to AList.Count - 1 do
    begin
      if TScoreItem(AList[j]).Score > TScoreItem(AList[i]).Score then
      begin
        Temp := TScoreItem(AList[i]);
        AList[i] := AList[j];
        AList[j] := Temp;
      end;
    end;
  end;
end;

{ TAITrainingCollection }

constructor TAITrainingCollection.Create(AOwner: TPersistent);
begin
  inherited Create(AOwner, TAITrainingItem);
end;

function TAITrainingCollection.Add: TAITrainingItem;
begin
  Result := TAITrainingItem(inherited Add);
end;

function TAITrainingCollection.GetItem(Index: Integer): TAITrainingItem;
begin
  Result := TAITrainingItem(inherited GetItem(Index));
end;

procedure TAITrainingCollection.SetItem(Index: Integer; AValue: TAITrainingItem);
begin
  inherited SetItem(Index, AValue);
end;

{ TAIGraphNode }

constructor TAIGraphNode.Create(AId: Integer; const AText: string; AType: TAIGraphNodeType);
begin
  inherited Create;
  Id := AId;
  Text := AText;
  NodeType := AType;
  Weight := 0.0;
  HitCount := 0;
end;

{ TAIGraphEdge }

constructor TAIGraphEdge.Create(AFrom, ATo: Integer; AWeight: Double);
begin
  inherited Create;
  FromNodeId := AFrom;
  ToNodeId := ATo;
  Weight := AWeight;
  HitCount := 1;
end;

{ TScoreItem }

constructor TScoreItem.Create(const ACat: string; AScore: Double);
begin
  inherited Create;
  Category := ACat;
  Score := AScore;
end;

{ TAIGraphMap }

constructor TAIGraphMap.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FCategory := ccModel;
  FPrompt := 'Component TAIGraphMap creates a weighted token graph for explainable text classification. It tokenizes input texts, creates token nodes and category nodes, connects them with weighted edges, trains from InputText and OutputCategory pairs, saves and loads the graph as JSON, and predicts the closest output category for a new text with a ranked percentage list.';
  
  FNodes := TList.Create;
  FEdges := TList.Create;
  FNodeCounter := 0;
  FNodeCount := 0;
  FEdgeCount := 0;
  
  FNodeIndex := TStringList.Create;
  FNodeIndex.Sorted := True;
  FNodeIndex.Duplicates := dupError;
  
  FNodeIdIndex := TStringList.Create;
  FNodeIdIndex.Sorted := True;
  FNodeIdIndex.Duplicates := dupError;
  
  FEdgeIndex := TStringList.Create;
  FEdgeIndex.Sorted := True;
  FEdgeIndex.Duplicates := dupError;
  
  FTokenizer := nil;
  
  FTraining := TAITrainingCollection.Create(Self);
  
  FStopWords := TStringList.Create;
  FStopWords.Add('a');
  FStopWords.Add('o');
  FStopWords.Add('as');
  FStopWords.Add('os');
  FStopWords.Add('um');
  FStopWords.Add('uma');
  FStopWords.Add('de');
  FStopWords.Add('do');
  FStopWords.Add('da');
  FStopWords.Add('dos');
  FStopWords.Add('das');
  FStopWords.Add('e');
  FStopWords.Add('em');
  FStopWords.Add('com');
  FStopWords.Add('para');
  FStopWords.Add('por');
  FStopWords.Add('ao');
  FStopWords.Add('na');
  FStopWords.Add('no');
  FStopWords.Add('que');
  FStopWords.Add('se');
  FStopWords.Add('nao');
  FStopWords.Add('não');
  
  FSynonyms := TStringList.Create;
  FNegativeRelations := TStringList.Create;
  FLastMatchedTokens := TStringList.Create;
  
  FLastRanking := TStringList.Create;
  FLastExplanation := TStringList.Create;
  FLastCategory := '';
  
  FLowerCaseTokens := True;
  FRemoveAccents := True;
  FRemoveStopWords := True;
  FMinTokenLength := 3;
  FTokenDelimiterChars := ' ,;.:!?()[]{}''"/\@#$*&^%-_+=';
  FUniqueTokensPerText := True;
  
  FWindowSize := 2;
  FTokenEdgeWeight := 1.0;
  FCategoryEdgeWeight := 2.0;
  FRepetitionBoost := 1.0;
  FUseTokenSequenceEdges := True;
  FUseTokenCategoryEdges := True;
  FAutoClearBeforeTrain := True;
  
  FUseGraphDepthSearch := True;
  FMaxDepth := 2;
  FDepthDecay := 0.5;
  FMinimumScore := 0.01;
  FUnknownCategoryName := 'unknown';
  FNormalizeScores := True;
  
  ClearError;
end;

destructor TAIGraphMap.Destroy;
begin
  ClearGraph;
  FNodes.Free;
  FEdges.Free;
  FNodeIndex.Free;
  FNodeIdIndex.Free;
  FEdgeIndex.Free;
  FTraining.Free;
  FStopWords.Free;
  FSynonyms.Free;
  FNegativeRelations.Free;
  FLastMatchedTokens.Free;
  FLastRanking.Free;
  FLastExplanation.Free;
  inherited Destroy;
end;

procedure TAIGraphMap.ClearGraph;
var
  i: Integer;
begin
  for i := 0 to FNodes.Count - 1 do
    TAIGraphNode(FNodes[i]).Free;
  FNodes.Clear;
  
  for i := 0 to FEdges.Count - 1 do
    TAIGraphEdge(FEdges[i]).Free;
  FEdges.Clear;
  
  FNodeIndex.Clear;
  FNodeIdIndex.Clear;
  FEdgeIndex.Clear;
  
  FNodeCounter := 0;
  FNodeCount := 0;
  FEdgeCount := 0;
  if Assigned(FOnGraphChanged) then
    FOnGraphChanged(Self);
end;

procedure TAIGraphMap.ClearTraining;
begin
  FTraining.Clear;
end;

function TAIGraphMap.FindNode(const AText: string; AType: TAIGraphNodeType): TAIGraphNode;
var
  LKey: string;
  LIdx: Integer;
begin
  Result := nil;
  LKey := AText + '|' + IntToStr(Ord(AType));
  if FNodeIndex.Find(LKey, LIdx) then
    Result := TAIGraphNode(FNodeIndex.Objects[LIdx]);
end;

function TAIGraphMap.FindNodeById(AId: Integer): TAIGraphNode;
var
  LKey: string;
  LIdx: Integer;
begin
  Result := nil;
  LKey := IntToStr(AId);
  if FNodeIdIndex.Find(LKey, LIdx) then
    Result := TAIGraphNode(FNodeIdIndex.Objects[LIdx]);
end;

function TAIGraphMap.FindEdge(AFromId, AToId: Integer): TAIGraphEdge;
var
  LKey: string;
  LIdx: Integer;
begin
  Result := nil;
  LKey := IntToStr(AFromId) + '_' + IntToStr(AToId);
  if FEdgeIndex.Find(LKey, LIdx) then
    Result := TAIGraphEdge(FEdgeIndex.Objects[LIdx]);
end;

function TAIGraphMap.CreateNode(const AText: string; AType: TAIGraphNodeType): TAIGraphNode;
begin
  Inc(FNodeCounter);
  Result := TAIGraphNode.Create(FNodeCounter, AText, AType);
  FNodes.Add(Result);
  FNodeCount := FNodes.Count;
  
  FNodeIndex.AddObject(AText + '|' + IntToStr(Ord(AType)), Result);
  FNodeIdIndex.AddObject(IntToStr(Result.Id), Result);
  
  if Assigned(FOnGraphChanged) then
    FOnGraphChanged(Self);
end;

function TAIGraphMap.CreateEdge(AFromId, AToId: Integer; AWeight: Double): TAIGraphEdge;
begin
  Result := TAIGraphEdge.Create(AFromId, AToId, AWeight);
  FEdges.Add(Result);
  FEdgeCount := FEdges.Count;
  
  FEdgeIndex.AddObject(IntToStr(AFromId) + '_' + IntToStr(AToId), Result);
  
  if Assigned(FOnGraphChanged) then
    FOnGraphChanged(Self);
end;

procedure TAIGraphMap.TokenizeToStrings(const AText: string; AOutList: TStrings);
var
  LText: string;
  LWords: TStringList;
  i: Integer;
  LWord: string;
  LDelims: string;
  LCurrentWord: string;
  LSyn: string;
  LTempTokens: TStrings;
begin
  AOutList.Clear;
  if Trim(AText) = '' then Exit;
  
  if Assigned(FTokenizer) then
  begin
    LTempTokens := FTokenizer.Tokenize(AText);
    try
      AOutList.Assign(LTempTokens);
    finally
      LTempTokens.Free;
    end;
    if Assigned(FOnTokenized) then
      FOnTokenized(Self, AOutList);
    Exit;
  end;
  
  LText := AText;
  if FLowerCaseTokens then
    LText := UTF8LowerCase(LText);
  
  if FRemoveAccents then
    LText := RemoveAccentsStr(LText);
    
  LWords := TStringList.Create;
  try
    LDelims := FTokenDelimiterChars;
    if LDelims = '' then
      LDelims := ' ,;.:!?()[]{}''"/\@#$*&^%-_+=';
      
    LCurrentWord := '';
    for i := 1 to Length(LText) do
    begin
      if Pos(LText[i], LDelims) > 0 then
      begin
        if LCurrentWord <> '' then
        begin
          LWords.Add(LCurrentWord);
          LCurrentWord := '';
        end;
      end
      else
      begin
        LCurrentWord := LCurrentWord + LText[i];
      end;
    end;
    if LCurrentWord <> '' then
      LWords.Add(LCurrentWord);
      
    for i := 0 to LWords.Count - 1 do
    begin
      LWord := Trim(LWords[i]);
      if Length(LWord) < FMinTokenLength then
        Continue;
        
      if FRemoveStopWords and (FStopWords.IndexOf(LWord) >= 0) then
        Continue;
        
      // Synonyms mapping
      if FSynonyms.Count > 0 then
      begin
        LSyn := FSynonyms.Values[LWord];
        if LSyn <> '' then
          LWord := LSyn;
      end;
        
      if FUniqueTokensPerText and (AOutList.IndexOf(LWord) >= 0) then
        Continue;
        
      AOutList.Add(LWord);
    end;
  finally
    LWords.Free;
  end;
  
  if Assigned(FOnTokenized) then
    FOnTokenized(Self, AOutList);
end;

function TAIGraphMap.Tokenize(const AText: string): TStrings;
begin
  if Assigned(FTokenizer) then
    Result := FTokenizer.Tokenize(AText)
  else
  begin
    Result := TStringList.Create;
    TokenizeToStrings(AText, Result);
  end;
end;

procedure TAIGraphMap.Train;
var
  i: Integer;
  LItem: TAITrainingItem;
begin
  ClearError;
  Log(llInfo, 'Starting TAIGraphMap training cycle.');
  
  if Assigned(FOnBeforeTrain) then
    FOnBeforeTrain(Self);
    
  if FAutoClearBeforeTrain then
    ClearGraph;
    
  try
    for i := 0 to FTraining.Count - 1 do
    begin
      LItem := FTraining.Items[i];
      TrainItem(LItem.InputText, LItem.OutputCategory, LItem.Weight);
    end;
    
    FLastResult := 'Training completed. Nodes: ' + IntToStr(FNodeCount) + ', Edges: ' + IntToStr(FEdgeCount);
    FLastSuccess := True;
    Log(llInfo, FLastResult);
  except
    on E: Exception do
    begin
      DoError('Training failed: ' + E.Message);
    end;
  end;
  
  if Assigned(FOnAfterTrain) then
    FOnAfterTrain(Self);
end;

procedure TAIGraphMap.TrainItem(const AInput, ACategory: string; AWeight: Double);
var
  LTokens: TStrings;
  LCatNode: TAIGraphNode;
  LTokenNodes: array of TAIGraphNode;
  LNode: TAIGraphNode;
  LEdge: TAIGraphEdge;
  i, j: Integer;
  LTokenText: string;
begin
  if Trim(AInput) = '' then Exit;
  if Trim(ACategory) = '' then Exit;

  LTokens := Tokenize(AInput);
  try
    if LTokens.Count = 0 then Exit;

    LCatNode := FindNode(ACategory, ntCategory);
    if not Assigned(LCatNode) then
      LCatNode := CreateNode(ACategory, ntCategory);
    LCatNode.HitCount := LCatNode.HitCount + 1;
    LCatNode.Weight := LCatNode.Weight + AWeight;

    SetLength(LTokenNodes, LTokens.Count);
    for i := 0 to LTokens.Count - 1 do
    begin
      LTokenText := LTokens[i];
      LNode := FindNode(LTokenText, ntToken);
      if not Assigned(LNode) then
        LNode := CreateNode(LTokenText, ntToken);
      LNode.HitCount := LNode.HitCount + 1;
      LNode.Weight := LNode.Weight + AWeight;
      LTokenNodes[i] := LNode;

      if FUseTokenCategoryEdges then
      begin
        LEdge := FindEdge(LNode.Id, LCatNode.Id);
        if Assigned(LEdge) then
        begin
          LEdge.HitCount := LEdge.HitCount + 1;
          LEdge.Weight := LEdge.Weight + (FCategoryEdgeWeight * AWeight * FRepetitionBoost);
        end
        else
        begin
          LEdge := CreateEdge(LNode.Id, LCatNode.Id, FCategoryEdgeWeight * AWeight);
        end;
      end;
    end;

    if FUseTokenSequenceEdges and (LTokens.Count > 1) then
    begin
      for i := 0 to LTokens.Count - 1 do
      begin
        for j := i + 1 to i + FWindowSize do
        begin
          if j >= LTokens.Count then Break;
          
          LEdge := FindEdge(LTokenNodes[i].Id, LTokenNodes[j].Id);
          if Assigned(LEdge) then
          begin
            LEdge.HitCount := LEdge.HitCount + 1;
            LEdge.Weight := LEdge.Weight + (FTokenEdgeWeight * AWeight * FRepetitionBoost);
          end
          else
          begin
            LEdge := CreateEdge(LTokenNodes[i].Id, LTokenNodes[j].Id, FTokenEdgeWeight * AWeight);
          end;
        end;
      end;
    end;

  finally
    LTokens.Free;
  end;
end;

procedure TAIGraphMap.TraverseGraph(
  ANodeId: Integer;
  ACurrentDepth: Integer;
  ACurrentFactor: Double;
  AScores: TStringList;
  AVisited: TList
);
var
  i: Integer;
  LEdge: TAIGraphEdge;
  LTargetNode: TAIGraphNode;
  LTempIdx: Integer;
  LWeightContrib: Double;
  LPrevScore: Double;
begin
  if ACurrentDepth > FMaxDepth then Exit;
  if AVisited.IndexOf(Pointer(ANodeId)) >= 0 then Exit;

  AVisited.Add(Pointer(ANodeId));
  try
    for i := 0 to FEdges.Count - 1 do
    begin
      LEdge := TAIGraphEdge(FEdges[i]);
      if LEdge.FromNodeId = ANodeId then
      begin
        LTargetNode := FindNodeById(LEdge.ToNodeId);
        if Assigned(LTargetNode) then
        begin
          if LTargetNode.NodeType = ntCategory then
          begin
            LWeightContrib := LEdge.Weight * ACurrentFactor;
            LTempIdx := AScores.IndexOfName(LTargetNode.Text);
            if LTempIdx >= 0 then
            begin
              LPrevScore := StrToFloatDef(AScores.ValueFromIndex[LTempIdx], 0.0);
              AScores.Strings[LTempIdx] := LTargetNode.Text + '=' + FloatToStr(LPrevScore + LWeightContrib);
            end
            else
            begin
              AScores.Add(LTargetNode.Text + '=' + FloatToStr(LWeightContrib));
            end;
          end
          else if LTargetNode.NodeType = ntToken then
          begin
            TraverseGraph(
              LTargetNode.Id,
              ACurrentDepth + 1,
              ACurrentFactor * FDepthDecay,
              AScores,
              AVisited
            );
          end;
        end;
      end;
    end;
  finally
    AVisited.Remove(Pointer(ANodeId));
  end;
end;

procedure TAIGraphMap.PredictRanking(const AText: string; AResultList: TStrings);
var
  LTokens: TStrings;
  LScores: TStringList;
  LVisited: TList;
  i, j: Integer;
  LNode: TAIGraphNode;
  LSum, LPrevScore: Double;
  LScoreItems: TList;
  LScoreItem: TScoreItem;
  LScoreVal: Double;
  LPercent: Double;
  LVal, LLine, LNegToken, LNegCat: string;
  LSepIdx, LTempIdx: Integer;
begin
  AResultList.Clear;
  FLastMatchedTokens.Clear;
  ClearError;
  
  if FNodes.Count = 0 then
  begin
    DoError('Grafo está vazio. Treine ou carregue um grafo antes de realizar predições.');
    Exit;
  end;
  
  if Trim(AText) = '' then Exit;

  LTokens := Tokenize(AText);
  try
    if LTokens.Count = 0 then Exit;

    // Check matched tokens
    for i := 0 to LTokens.Count - 1 do
    begin
      LNode := FindNode(LTokens[i], ntToken);
      if Assigned(LNode) then
        FLastMatchedTokens.Add(LTokens[i]);
    end;

    LScores := TStringList.Create;
    LVisited := TList.Create;
    try
      for i := 0 to LTokens.Count - 1 do
      begin
        LNode := FindNode(LTokens[i], ntToken);
        if Assigned(LNode) then
        begin
          LVisited.Clear;
          if FUseGraphDepthSearch then
            TraverseGraph(LNode.Id, 0, 1.0, LScores, LVisited)
          else
          begin
            j := FMaxDepth;
            FMaxDepth := 0;
            try
              TraverseGraph(LNode.Id, 0, 1.0, LScores, LVisited);
            finally
              FMaxDepth := j;
            end;
          end;
        end;
      end;

      // Apply NegativeRelations
      if (FNegativeRelations.Count > 0) and (LScores.Count > 0) then
      begin
        for i := 0 to LTokens.Count - 1 do
        begin
          LVal := FNegativeRelations.Values[LTokens[i]];
          if LVal <> '' then
          begin
            LTempIdx := LScores.IndexOfName(LVal);
            if LTempIdx >= 0 then
            begin
              LPrevScore := StrToFloatDef(LScores.ValueFromIndex[LTempIdx], 0.0);
              LScores.Strings[LTempIdx] := LVal + '=' + FloatToStr(LPrevScore - FCategoryEdgeWeight);
            end;
          end;
          
          for j := 0 to FNegativeRelations.Count - 1 do
          begin
            LLine := FNegativeRelations[j];
            LSepIdx := Pos('!=', LLine);
            if LSepIdx > 0 then
            begin
              LNegToken := Trim(Copy(LLine, 1, LSepIdx - 1));
              LNegCat := Trim(Copy(LLine, LSepIdx + 2, Length(LLine)));
              if (LNegToken = LTokens[i]) and (LNegCat <> '') then
              begin
                LTempIdx := LScores.IndexOfName(LNegCat);
                if LTempIdx >= 0 then
                begin
                  LPrevScore := StrToFloatDef(LScores.ValueFromIndex[LTempIdx], 0.0);
                  LScores.Strings[LTempIdx] := LNegCat + '=' + FloatToStr(LPrevScore - FCategoryEdgeWeight);
                end;
              end;
            end;
          end;
        end;
      end;

      if LScores.Count = 0 then Exit;

      LSum := 0.0;
      for i := 0 to LScores.Count - 1 do
      begin
        LScoreVal := StrToFloatDef(LScores.ValueFromIndex[i], 0.0);
        if LScoreVal < 0.0 then LScoreVal := 0.0; // clamp negative scores to 0 for sum
        LSum := LSum + LScoreVal;
      end;

      LScoreItems := TList.Create;
      try
        for i := 0 to LScores.Count - 1 do
        begin
          LScoreVal := StrToFloatDef(LScores.ValueFromIndex[i], 0.0);
          if LScoreVal < 0.0 then LScoreVal := 0.0;
          
          if FNormalizeScores and (LSum > 0.0) then
            LPercent := (LScoreVal / LSum) * 100.0
          else
            LPercent := LScoreVal;
            
          LScoreItems.Add(TScoreItem.Create(LScores.Names[i], LPercent));
        end;

        SortScoreItems(LScoreItems);

        for i := 0 to LScoreItems.Count - 1 do
        begin
          LScoreItem := TScoreItem(LScoreItems[i]);
          AResultList.Add(LScoreItem.Category + '=' + FormatFloat('0.00', LScoreItem.Score));
        end;
      finally
        for i := 0 to LScoreItems.Count - 1 do
          TScoreItem(LScoreItems[i]).Free;
        LScoreItems.Free;
      end;

    finally
      LVisited.Free;
      LScores.Free;
    end;

  finally
    LTokens.Free;
  end;
end;

function TAIGraphMap.Predict(const AText: string): string;
var
  LRanking: TStringList;
  LBestCat: string;
  LBestScoreStr: string;
  LBestScore: Double;
begin
  Result := FUnknownCategoryName;
  FLastCategory := FUnknownCategoryName;
  FLastRanking.Clear;
  FLastExplanation.Clear;
  ClearError;
  
  if FNodes.Count = 0 then
  begin
    DoError('Grafo está vazio. Treine ou carregue um grafo antes de realizar predições.');
    Exit;
  end;
  
  if Assigned(FOnBeforePredict) then
    FOnBeforePredict(Self);
    
  LRanking := TStringList.Create;
  try
    PredictRanking(AText, LRanking);
    FLastRanking.Assign(LRanking);
    
    if LRanking.Count > 0 then
    begin
      LBestCat := LRanking.Names[0];
      LBestScoreStr := LRanking.ValueFromIndex[0];
      LBestScore := StrToFloatDef(LBestScoreStr, 0.0);
      
      if LBestScore >= FMinimumScore then
      begin
        Result := LBestCat;
        FLastCategory := LBestCat;
      end;
    end;
  finally
    LRanking.Free;
  end;
  
  FLastResult := FLastCategory;
  FLastSuccess := (FLastCategory <> FUnknownCategoryName);
  ExplainPrediction(AText, FLastExplanation);
  
  if Assigned(FOnAfterPredict) then
    FOnAfterPredict(Self);
end;

procedure TAIGraphMap.ExplainPrediction(const AText: string; AExplanation: TStrings);
var
  LTokens: TStrings;
  i: Integer;
  LNode: TAIGraphNode;
  
  procedure TraceExplainPath(
    ANodeId: Integer;
    ACurrentDepth: Integer;
    ACurrentFactor: Double;
    const APathStr: string;
    AVisited: TList
  );
  var
    K: Integer;
    LSubEdge: TAIGraphEdge;
    LSubTarget: TAIGraphNode;
    LNewPath: string;
    LNodeText: string;
  begin
    if ACurrentDepth > FMaxDepth then Exit;
    if AVisited.IndexOf(Pointer(ANodeId)) >= 0 then Exit;
    
    AVisited.Add(Pointer(ANodeId));
    try
      LNodeText := FindNodeById(ANodeId).Text;
      if APathStr = '' then
        LNewPath := LNodeText
      else
        LNewPath := APathStr + ' -> ' + LNodeText;
        
      for K := 0 to FEdges.Count - 1 do
      begin
        LSubEdge := TAIGraphEdge(FEdges[K]);
        if LSubEdge.FromNodeId = ANodeId then
        begin
          LSubTarget := FindNodeById(LSubEdge.ToNodeId);
          if Assigned(LSubTarget) then
          begin
            if LSubTarget.NodeType = ntCategory then
            begin
              AExplanation.Add(Format('  %s -> %s (Peso: %s, Profundidade: %d, Contribuição: %s)', [
                LNewPath,
                LSubTarget.Text,
                FormatFloat('0.00', LSubEdge.Weight),
                ACurrentDepth,
                FormatFloat('0.00', LSubEdge.Weight * ACurrentFactor)
              ]));
            end
            else if LSubTarget.NodeType = ntToken then
            begin
              TraceExplainPath(
                LSubTarget.Id,
                ACurrentDepth + 1,
                ACurrentFactor * FDepthDecay,
                LNewPath,
                AVisited
              );
            end;
          end;
        end;
      end;
    finally
      AVisited.Remove(Pointer(ANodeId));
    end;
  end;
  
var
  LVisited: TList;
begin
  AExplanation.Clear;
  AExplanation.Add('Texto analisado:');
  AExplanation.Add(AText);
  AExplanation.Add('');
  
  LTokens := Tokenize(AText);
  try
    AExplanation.Add('Tokens usados:');
    for i := 0 to LTokens.Count - 1 do
      AExplanation.Add(LTokens[i]);
    AExplanation.Add('');
    
    AExplanation.Add('Tokens correspondentes encontrados no Grafo:');
    for i := 0 to FLastMatchedTokens.Count - 1 do
      AExplanation.Add(FLastMatchedTokens[i]);
    AExplanation.Add('');
    
    AExplanation.Add('Categoria escolhida:');
    AExplanation.Add(FLastCategory);
    AExplanation.Add('');
    
    AExplanation.Add('Evidências e Caminhos de Decisão:');
    if FNodes.Count > 0 then
    begin
      LVisited := TList.Create;
      try
        for i := 0 to LTokens.Count - 1 do
        begin
          LNode := FindNode(LTokens[i], ntToken);
          if Assigned(LNode) then
          begin
            LVisited.Clear;
            TraceExplainPath(LNode.Id, 0, 1.0, '', LVisited);
          end;
        end;
      finally
        LVisited.Free;
      end;
    end;
    
    AExplanation.Add('');
    AExplanation.Add('Ranking:');
    for i := 0 to FLastRanking.Count - 1 do
      AExplanation.Add(FLastRanking[i]);
  finally
    LTokens.Free;
  end;
end;

procedure TAIGraphMap.SaveGraphToFile(const AFileName: string);
var
  LObj, LNodeObj, LEdgeObj, LSettingsObj: TJSONObject;
  LNodesArr, LEdgesArr, LStopWordsArr, LSynonymsArr, LNegRelArr: TJSONArray;
  i: Integer;
  LNode: TAIGraphNode;
  LEdge: TAIGraphEdge;
  LList: TStringList;
begin
  ClearError;
  LObj := TJSONObject.Create;
  LList := TStringList.Create;
  try
    LObj.Add('version', '1.0');
    
    // Save Settings
    LSettingsObj := TJSONObject.Create;
    LObj.Add('settings', LSettingsObj);
    LSettingsObj.Add('lowerCaseTokens', FLowerCaseTokens);
    LSettingsObj.Add('removeAccents', FRemoveAccents);
    LSettingsObj.Add('removeStopWords', FRemoveStopWords);
    LSettingsObj.Add('minTokenLength', FMinTokenLength);
    LSettingsObj.Add('windowSize', FWindowSize);
    LSettingsObj.Add('tokenEdgeWeight', FTokenEdgeWeight);
    LSettingsObj.Add('categoryEdgeWeight', FCategoryEdgeWeight);
    LSettingsObj.Add('repetitionBoost', FRepetitionBoost);
    LSettingsObj.Add('useTokenSequenceEdges', FUseTokenSequenceEdges);
    LSettingsObj.Add('useTokenCategoryEdges', FUseTokenCategoryEdges);
    LSettingsObj.Add('autoClearBeforeTrain', FAutoClearBeforeTrain);
    LSettingsObj.Add('useGraphDepthSearch', FUseGraphDepthSearch);
    LSettingsObj.Add('maxDepth', FMaxDepth);
    LSettingsObj.Add('depthDecay', FDepthDecay);
    LSettingsObj.Add('minimumScore', FMinimumScore);
    LSettingsObj.Add('unknownCategoryName', FUnknownCategoryName);
    LSettingsObj.Add('normalizeScores', FNormalizeScores);
    
    // StopWords
    LStopWordsArr := TJSONArray.Create;
    LSettingsObj.Add('stopWords', LStopWordsArr);
    for i := 0 to FStopWords.Count - 1 do
      LStopWordsArr.Add(FStopWords[i]);
      
    // Synonyms
    LSynonymsArr := TJSONArray.Create;
    LSettingsObj.Add('synonyms', LSynonymsArr);
    for i := 0 to FSynonyms.Count - 1 do
      LSynonymsArr.Add(FSynonyms[i]);
      
    // NegativeRelations
    LNegRelArr := TJSONArray.Create;
    LSettingsObj.Add('negativeRelations', LNegRelArr);
    for i := 0 to FNegativeRelations.Count - 1 do
      LNegRelArr.Add(FNegativeRelations[i]);
    
    LNodesArr := TJSONArray.Create;
    LObj.Add('nodes', LNodesArr);
    for i := 0 to FNodes.Count - 1 do
    begin
      LNode := TAIGraphNode(FNodes[i]);
      LNodeObj := TJSONObject.Create;
      LNodeObj.Add('id', LNode.Id);
      LNodeObj.Add('text', LNode.Text);
      if LNode.NodeType = ntToken then
        LNodeObj.Add('type', 'token')
      else
        LNodeObj.Add('type', 'category');
      LNodeObj.Add('weight', LNode.Weight);
      LNodeObj.Add('hitCount', LNode.HitCount);
      LNodesArr.Add(LNodeObj);
    end;
    
    LEdgesArr := TJSONArray.Create;
    LObj.Add('edges', LEdgesArr);
    for i := 0 to FEdges.Count - 1 do
    begin
      LEdge := TAIGraphEdge(FEdges[i]);
      LEdgeObj := TJSONObject.Create;
      LEdgeObj.Add('from', LEdge.FromNodeId);
      LEdgeObj.Add('to', LEdge.ToNodeId);
      LEdgeObj.Add('weight', LEdge.Weight);
      LEdgeObj.Add('hitCount', LEdge.HitCount);
      LEdgesArr.Add(LEdgeObj);
    end;
    
    LList.Text := LObj.AsJSON;
    LList.SaveToFile(AFileName);
    Log(llInfo, 'Saved graph to file: ' + AFileName);
  finally
    LList.Free;
    LObj.Free;
  end;
end;

procedure TAIGraphMap.LoadGraphFromFile(const AFileName: string);
var
  LList: TStringList;
  LData: TJSONData;
  LObj, LNodeObj, LEdgeObj, LSettingsObj: TJSONObject;
  LNodesArr, LEdgesArr, LStopWordsArr, LSynonymsArr, LNegRelArr: TJSONArray;
  i: Integer;
  LNode: TAIGraphNode;
  LEdge: TAIGraphEdge;
  LTypeStr: string;
begin
  ClearGraph;
  ClearError;
  if not FileExists(AFileName) then
  begin
    DoError('File does not exist: ' + AFileName);
    Exit;
  end;
    
  LList := TStringList.Create;
  try
    LList.LoadFromFile(AFileName);
    LData := GetJSON(LList.Text);
    try
      if LData.JSONType = jtObject then
      begin
        LObj := TJSONObject(LData);
        
        // Load Settings if present
        if LObj.Find('settings') <> nil then
        begin
          LSettingsObj := LObj.Objects['settings'];
          if Assigned(LSettingsObj) then
          begin
            if LSettingsObj.Find('lowerCaseTokens') <> nil then
              FLowerCaseTokens := LSettingsObj.Booleans['lowerCaseTokens'];
            if LSettingsObj.Find('removeAccents') <> nil then
              FRemoveAccents := LSettingsObj.Booleans['removeAccents'];
            if LSettingsObj.Find('removeStopWords') <> nil then
              FRemoveStopWords := LSettingsObj.Booleans['removeStopWords'];
            if LSettingsObj.Find('minTokenLength') <> nil then
              FMinTokenLength := LSettingsObj.Integers['minTokenLength'];
            if LSettingsObj.Find('windowSize') <> nil then
              FWindowSize := LSettingsObj.Integers['windowSize'];
            if LSettingsObj.Find('tokenEdgeWeight') <> nil then
              FTokenEdgeWeight := LSettingsObj.Floats['tokenEdgeWeight'];
            if LSettingsObj.Find('categoryEdgeWeight') <> nil then
              FCategoryEdgeWeight := LSettingsObj.Floats['categoryEdgeWeight'];
            if LSettingsObj.Find('repetitionBoost') <> nil then
              FRepetitionBoost := LSettingsObj.Floats['repetitionBoost'];
            if LSettingsObj.Find('useTokenSequenceEdges') <> nil then
              FUseTokenSequenceEdges := LSettingsObj.Booleans['useTokenSequenceEdges'];
            if LSettingsObj.Find('useTokenCategoryEdges') <> nil then
              FUseTokenCategoryEdges := LSettingsObj.Booleans['useTokenCategoryEdges'];
            if LSettingsObj.Find('autoClearBeforeTrain') <> nil then
              FAutoClearBeforeTrain := LSettingsObj.Booleans['autoClearBeforeTrain'];
            if LSettingsObj.Find('useGraphDepthSearch') <> nil then
              FUseGraphDepthSearch := LSettingsObj.Booleans['useGraphDepthSearch'];
            if LSettingsObj.Find('maxDepth') <> nil then
              FMaxDepth := LSettingsObj.Integers['maxDepth'];
            if LSettingsObj.Find('depthDecay') <> nil then
              FDepthDecay := LSettingsObj.Floats['depthDecay'];
            if LSettingsObj.Find('minimumScore') <> nil then
              FMinimumScore := LSettingsObj.Floats['minimumScore'];
            if LSettingsObj.Find('unknownCategoryName') <> nil then
              FUnknownCategoryName := LSettingsObj.Strings['unknownCategoryName'];
            if LSettingsObj.Find('normalizeScores') <> nil then
              FNormalizeScores := LSettingsObj.Booleans['normalizeScores'];
              
            // StopWords
            if LSettingsObj.Find('stopWords') <> nil then
            begin
              LStopWordsArr := LSettingsObj.Arrays['stopWords'];
              FStopWords.Clear;
              for i := 0 to LStopWordsArr.Count - 1 do
                FStopWords.Add(LStopWordsArr.Strings[i]);
            end;
            
            // Synonyms
            if LSettingsObj.Find('synonyms') <> nil then
            begin
              LSynonymsArr := LSettingsObj.Arrays['synonyms'];
              FSynonyms.Clear;
              for i := 0 to LSynonymsArr.Count - 1 do
                FSynonyms.Add(LSynonymsArr.Strings[i]);
            end;
            
            // NegativeRelations
            if LSettingsObj.Find('negativeRelations') <> nil then
            begin
              LNegRelArr := LSettingsObj.Arrays['negativeRelations'];
              FNegativeRelations.Clear;
              for i := 0 to LNegRelArr.Count - 1 do
                FNegativeRelations.Add(LNegRelArr.Strings[i]);
            end;
          end;
        end;
        
        LNodesArr := LObj.Arrays['nodes'];
        for i := 0 to LNodesArr.Count - 1 do
        begin
          LNodeObj := LNodesArr.Objects[i];
          LTypeStr := LNodeObj.Strings['type'];
          
          LNode := TAIGraphNode.Create(
            LNodeObj.Integers['id'],
            LNodeObj.Strings['text'],
            ntToken
          );
          if LTypeStr = 'category' then
            LNode.NodeType := ntCategory;
            
          LNode.Weight := LNodeObj.Floats['weight'];
          LNode.HitCount := LNodeObj.Integers['hitCount'];
          FNodes.Add(LNode);
          
          FNodeIndex.AddObject(LNode.Text + '|' + IntToStr(Ord(LNode.NodeType)), LNode);
          FNodeIdIndex.AddObject(IntToStr(LNode.Id), LNode);
          
          if LNode.Id > FNodeCounter then
            FNodeCounter := LNode.Id;
        end;
        
        LEdgesArr := LObj.Arrays['edges'];
        for i := 0 to LEdgesArr.Count - 1 do
        begin
          LEdgeObj := LEdgesArr.Objects[i];
          LEdge := TAIGraphEdge.Create(
            LEdgeObj.Integers['from'],
            LEdgeObj.Integers['to'],
            LEdgeObj.Floats['weight']
          );
          LEdge.HitCount := LEdgeObj.Integers['hitCount'];
          FEdges.Add(LEdge);
          
          FEdgeIndex.AddObject(IntToStr(LEdge.FromNodeId) + '_' + IntToStr(LEdge.ToNodeId), LEdge);
        end;
      end;
    finally
      LData.Free;
    end;
    Log(llInfo, 'Loaded graph from file: ' + AFileName);
  finally
    LList.Free;
  end;
  FNodeCount := FNodes.Count;
  FEdgeCount := FEdges.Count;
  if Assigned(FOnGraphChanged) then
    FOnGraphChanged(Self);
end;

procedure TAIGraphMap.SaveTrainingToFile(const AFileName: string);
var
  LObj, LItemObj: TJSONObject;
  LArr: TJSONArray;
  LList: TStringList;
  i: Integer;
  LItem: TAITrainingItem;
begin
  ClearError;
  LObj := TJSONObject.Create;
  LList := TStringList.Create;
  try
    LArr := TJSONArray.Create;
    LObj.Add('training', LArr);
    for i := 0 to FTraining.Count - 1 do
    begin
      LItem := FTraining.Items[i];
      LItemObj := TJSONObject.Create;
      LItemObj.Add('inputText', LItem.InputText);
      LItemObj.Add('outputCategory', LItem.OutputCategory);
      LItemObj.Add('weight', LItem.Weight);
      LArr.Add(LItemObj);
    end;
    LList.Text := LObj.AsJSON;
    LList.SaveToFile(AFileName);
    Log(llInfo, 'Saved training data to file: ' + AFileName);
  finally
    LList.Free;
    LObj.Free;
  end;
end;

procedure TAIGraphMap.LoadTrainingFromFile(const AFileName: string);
var
  LList: TStringList;
  LData: TJSONData;
  LObj, LItemObj: TJSONObject;
  LArr: TJSONArray;
  i: Integer;
  LItem: TAITrainingItem;
begin
  ClearTraining;
  ClearError;
  if not FileExists(AFileName) then
  begin
    DoError('File does not exist: ' + AFileName);
    Exit;
  end;
    
  LList := TStringList.Create;
  try
    LList.LoadFromFile(AFileName);
    LData := GetJSON(LList.Text);
    try
      if LData.JSONType = jtObject then
      begin
        LObj := TJSONObject(LData);
        LArr := LObj.Arrays['training'];
        for i := 0 to LArr.Count - 1 do
        begin
          LItemObj := LArr.Objects[i];
          LItem := FTraining.Add;
          LItem.InputText := LItemObj.Strings['inputText'];
          LItem.OutputCategory := LItemObj.Strings['outputCategory'];
          LItem.Weight := LItemObj.Floats['weight'];
        end;
      end;
    finally
      LData.Free;
    end;
    Log(llInfo, 'Loaded training data from file: ' + AFileName);
  finally
    LList.Free;
  end;
end;

procedure TAIGraphMap.ExportToGraphViz(const AFileName: string);
var
  LList: TStringList;
  i: Integer;
  LNode: TAIGraphNode;
  LEdge: TAIGraphEdge;
  LNodeStyle: string;
begin
  ClearError;
  LList := TStringList.Create;
  try
    try
      LList.Add('digraph TAIGraphMap {');
      LList.Add('  rankdir=LR;');
      LList.Add('  node [style=filled, fontname="Arial"];');
      
      for i := 0 to FNodes.Count - 1 do
      begin
        LNode := TAIGraphNode(FNodes[i]);
        if LNode.NodeType = ntCategory then
          LNodeStyle := 'shape=doublecircle, fillcolor="#FFD2D2", color="#FF0000"'
        else
          LNodeStyle := 'shape=box, fillcolor="#D2E8FF", color="#0066CC"';
          
        LList.Add(Format('  n%d [%s, label="%s\n(Weight: %s, Hits: %d)"];', [
          LNode.Id,
          LNodeStyle,
          LNode.Text,
          FormatFloat('0.00', LNode.Weight),
          LNode.HitCount
        ]));
      end;
      
      LList.Add('');
      
      for i := 0 to FEdges.Count - 1 do
      begin
        LEdge := TAIGraphEdge(FEdges[i]);
        LList.Add(Format('  n%d -> n%d [label="%s", weight="%s"];', [
          LEdge.FromNodeId,
          LEdge.ToNodeId,
          FormatFloat('0.00', LEdge.Weight),
          FormatFloat('0.00', LEdge.Weight)
        ]));
      end;
      
      LList.Add('}');
      LList.SaveToFile(AFileName);
      Log(llInfo, 'Exported graph to GraphViz DOT: ' + AFileName);
    except
      on E: Exception do
        DoError('GraphViz Export failed: ' + E.Message);
    end;
  finally
    LList.Free;
  end;
end;

function TAIGraphMap.Evaluate(ATestData: TAITrainingCollection): Double;
var
  i: Integer;
  LCorrect: Integer;
  LTotal: Integer;
  LItem: TAITrainingItem;
  LPredicted: string;
begin
  Result := 0.0;
  ClearError;
  if not Assigned(ATestData) or (ATestData.Count = 0) then Exit;
  
  LCorrect := 0;
  LTotal := ATestData.Count;
  for i := 0 to LTotal - 1 do
  begin
    LItem := ATestData.Items[i];
    LPredicted := Predict(LItem.InputText);
    if LPredicted = LItem.OutputCategory then
      Inc(LCorrect);
  end;
  
  Result := (LCorrect / LTotal) * 100.0;
end;

procedure TAIGraphMap.ConfusionMatrix(ATestData: TAITrainingCollection; AResult: TStrings);
var
  i, LIdx: Integer;
  LItem: TAITrainingItem;
  LPredicted: string;
  LExpected: string;
  LKey: string;
  LCount: Integer;
  LMatrix: TStringList;
  LParts: TStringList;
begin
  AResult.Clear;
  ClearError;
  if not Assigned(ATestData) or (ATestData.Count = 0) then Exit;
  
  LMatrix := TStringList.Create;
  LParts := TStringList.Create;
  try
    LMatrix.Sorted := True;
    LMatrix.Duplicates := dupIgnore;
    
    for i := 0 to ATestData.Count - 1 do
    begin
      LItem := ATestData.Items[i];
      LExpected := LItem.OutputCategory;
      LPredicted := Predict(LItem.InputText);
      LKey := LExpected + ';' + LPredicted;
      
      LIdx := LMatrix.IndexOfName(LKey);
      if LIdx >= 0 then
      begin
        LCount := StrToIntDef(LMatrix.ValueFromIndex[LIdx], 0) + 1;
        LMatrix.Strings[LIdx] := LKey + '=' + IntToStr(LCount);
      end
      else
      begin
        LMatrix.Add(LKey + '=1');
      end;
    end;
    
    for i := 0 to LMatrix.Count - 1 do
    begin
      LKey := LMatrix.Names[i];
      LCount := StrToIntDef(LMatrix.ValueFromIndex[i], 0);
      
      LParts.Clear;
      ExtractStrings([';'], [], PChar(LKey), LParts);
      if LParts.Count >= 2 then
      begin
        AResult.Add(Format('Esperado=%s;Previsto=%s;Qtd=%d', [
          LParts[0], LParts[1], LCount
        ]));
      end;
    end;
  finally
    LParts.Free;
    LMatrix.Free;
  end;
end;

procedure TAIGraphMap.SaveGraphAsDOT(const AFileName: string);
begin
  ExportToGraphViz(AFileName);
end;

procedure TAIGraphMap.SaveGraphAsGEXF(const AFileName: string);
var
  LList: TStringList;
  i: Integer;
  LNode: TAIGraphNode;
  LEdge: TAIGraphEdge;
  LType: string;
  LText: string;
begin
  ClearError;
  LList := TStringList.Create;
  try
    try
      LList.Add('<?xml version="1.0" encoding="UTF-8"?>');
      LList.Add('<gexf xmlns="http://www.gexf.net/1.2draft" version="1.2">');
      LList.Add('  <graph mode="static" defaultedgetype="directed">');
      LList.Add('    <attributes class="node" mode="static">');
      LList.Add('      <attribute id="0" title="type" type="string"/>');
      LList.Add('      <attribute id="1" title="weight" type="double"/>');
      LList.Add('      <attribute id="2" title="hitCount" type="integer"/>');
      LList.Add('    </attributes>');
      LList.Add('    <nodes>');
      
      for i := 0 to FNodes.Count - 1 do
      begin
        LNode := TAIGraphNode(FNodes[i]);
        if LNode.NodeType = ntToken then LType := 'token' else LType := 'category';
        
        LText := LNode.Text;
        LText := StringReplace(LText, '&', '&amp;', [rfReplaceAll]);
        LText := StringReplace(LText, '<', '&lt;', [rfReplaceAll]);
        LText := StringReplace(LText, '>', '&gt;', [rfReplaceAll]);
        LText := StringReplace(LText, '"', '&quot;', [rfReplaceAll]);
        LText := StringReplace(LText, '''', '&apos;', [rfReplaceAll]);
        
        LList.Add(Format('      <node id="%d" label="%s">', [LNode.Id, LText]));
        LList.Add('        <attvalues>');
        LList.Add(Format('          <attvalue for="0" value="%s"/>', [LType]));
        LList.Add(Format('          <attvalue for="1" value="%s"/>', [FloatToStr(LNode.Weight)]));
        LList.Add(Format('          <attvalue for="2" value="%d"/>', [LNode.HitCount]));
        LList.Add('        </attvalues>');
        LList.Add('      </node>');
      end;
      LList.Add('    </nodes>');
      
      LList.Add('    <edges>');
      for i := 0 to FEdges.Count - 1 do
      begin
        LEdge := TAIGraphEdge(FEdges[i]);
        LList.Add(Format('      <edge id="%d" source="%d" target="%d" weight="%s"/>', [
          i, LEdge.FromNodeId, LEdge.ToNodeId, FloatToStr(LEdge.Weight)
        ]));
      end;
      LList.Add('    </edges>');
      LList.Add('  </graph>');
      LList.Add('</gexf>');
      
      LList.SaveToFile(AFileName);
      Log(llInfo, 'Saved GEXF graph to: ' + AFileName);
    except
      on E: Exception do
        DoError('GEXF Export failed: ' + E.Message);
    end;
  finally
    LList.Free;
  end;
end;

procedure TAIGraphMap.SaveGraphAsCSV(const ANodeFile, AEdgeFile: string);
var
  LNodesList, LEdgesList: TStringList;
  i: Integer;
  LNode: TAIGraphNode;
  LEdge: TAIGraphEdge;
  LType: string;
begin
  ClearError;
  LNodesList := TStringList.Create;
  LEdgesList := TStringList.Create;
  try
    try
      LNodesList.Add('id;text;type;weight;hitCount');
      for i := 0 to FNodes.Count - 1 do
      begin
        LNode := TAIGraphNode(FNodes[i]);
        if LNode.NodeType = ntToken then LType := 'token' else LType := 'category';
        LNodesList.Add(Format('%d;%s;%s;%s;%d', [
          LNode.Id, LNode.Text, LType, FloatToStr(LNode.Weight), LNode.HitCount
        ]));
      end;
      
      LEdgesList.Add('fromNodeId;toNodeId;weight;hitCount');
      for i := 0 to FEdges.Count - 1 do
      begin
        LEdge := TAIGraphEdge(FEdges[i]);
        LEdgesList.Add(Format('%d;%d;%s;%d', [
          LEdge.FromNodeId, LEdge.ToNodeId, FloatToStr(LEdge.Weight), LEdge.HitCount
        ]));
      end;
      
      LNodesList.SaveToFile(ANodeFile);
      LEdgesList.SaveToFile(AEdgeFile);
      Log(llInfo, 'Saved graph to CSV nodes/edges files.');
    except
      on E: Exception do
        DoError('CSV Export failed: ' + E.Message);
    end;
  finally
    LNodesList.Free;
    LEdgesList.Free;
  end;
end;

procedure TAIGraphMap.ExportTraining(AExporter: TAIBaseTrainingExporter);
begin
  if Assigned(AExporter) then
    AExporter.ExportData(FTraining)
  else
    DoError('Exporter is not assigned.');
end;

procedure TAIGraphMap.ImportTraining(AExporter: TAIBaseTrainingExporter);
begin
  if Assigned(AExporter) then
  begin
    ClearTraining;
    AExporter.ImportData(FTraining);
    if FAutoClearBeforeTrain then
      ClearGraph;
  end
  else
    DoError('Exporter is not assigned.');
end;

procedure TAIGraphMap.DoError(const AError: string);
begin
  SetError(AError);
  if Assigned(FOnError) then
    FOnError(Self, AError);
end;

procedure TAIGraphMap.SetStopWords(AValue: TStrings);
begin
  FStopWords.Assign(AValue);
end;

procedure TAIGraphMap.SetSynonyms(AValue: TStrings);
begin
  FSynonyms.Assign(AValue);
end;

procedure TAIGraphMap.SetNegativeRelations(AValue: TStrings);
begin
  FNegativeRelations.Assign(AValue);
end;

end.
