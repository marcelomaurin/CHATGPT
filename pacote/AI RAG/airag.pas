unit airag;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, LResources, aibase, chatgpt, aigraphmap, airagbridge;

type
  TAIRAGLogEvent = procedure(
    Sender: TObject;
    const AMessage: string
  ) of object;

  TAIRAGChunkEvent = procedure(
    Sender: TObject;
    const AChunkID: string;
    const ASource: string;
    const AText: string
  ) of object;

  TAIRAGRetrieveEvent = procedure(
    Sender: TObject;
    const AChunkID: string;
    const ASource: string;
    const AText: string;
    const AScore: Double;
    var AInclude: Boolean
  ) of object;

  TAIRAGPromptEvent = procedure(
    Sender: TObject;
    const AQuestion: string;
    const AContext: string;
    var APrompt: string
  ) of object;

  { TAIRAG }

  TAIRAG = class(TAIBaseComponent, IAIRAGProvider)
  private
    FChatGPT: TCHATGPT;
    FGraphMap: TAIGraphMap;

    FChunkSize: Integer;
    FChunkOverlap: Integer;
    FTopK: Integer;
    FMinimumScore: Double;
    FMaximumContextLength: Integer;

    FInstructions: string;
    FNoAnswerText: string;
    FSourcePrefix: string;

    FLastQuestion: string;
    FLastContext: string;
    FLastPrompt: string;
    FLastAnswer: string;
    FLastSources: TStringList;

    FReplaceExistingSource: Boolean;

    FOnBeforeIndex: TNotifyEvent;
    FOnAfterIndex: TNotifyEvent;
    FOnChunkCreated: TAIRAGChunkEvent;
    FOnBeforeRetrieve: TNotifyEvent;
    FOnAfterRetrieve: TNotifyEvent;
    FOnChunkRetrieved: TAIRAGRetrieveEvent;
    FOnContextBuilt: TAIRAGLogEvent;
    FOnBuildPrompt: TAIRAGPromptEvent;
    FOnBeforeGenerate: TNotifyEvent;
    FOnAfterGenerate: TNotifyEvent;
    FOnRAGLog: TAIRAGLogEvent;

    procedure SetChatGPT(AValue: TCHATGPT);
    procedure SetGraphMap(AValue: TAIGraphMap);
    procedure SetChunkSize(AValue: Integer);
    procedure SetChunkOverlap(AValue: Integer);
    procedure SetTopK(AValue: Integer);
    procedure SetMaximumContextLength(AValue: Integer);

    procedure DoLog(const AMessage: string);
    procedure ClearStringListObjects(AStrings: TStrings);
    procedure RemoveSourceChunks(const ASourceName: string);
    procedure FreeResultObjects(AStrings: TStrings);
    function NormalizeSourceName(const ASource: string): string;

    procedure SplitText(
      const AText: string;
      AChunks: TStrings
    );

    function ValidateComponents(ARequireChatGPT: Boolean): Boolean;

  protected
    procedure Notification(
      AComponent: TComponent;
      Operation: TOperation
    ); override;

  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    procedure Clear;

    function AddText(
      const ASource: string;
      const AText: string
    ): Integer;

    function AddFile(
      const AFileName: string
    ): Integer;

    function BuildIndex: Boolean;

    function FindChunkText(
      const AChunkID: string
    ): string;

    function ExtractSourceName(
      const AChunkID: string
    ): string;

    function Retrieve(
      const AQuestion: string;
      AResults: TStrings
    ): Boolean;

    function BuildContext(
      const AQuestion: string
    ): Boolean;

    function BuildPrompt(
      const AQuestion: string;
      const AContext: string
    ): string;

    function Ask(
      const AQuestion: string
    ): Boolean;

    function SaveIndex(
      const AGraphFile: string;
      const ATrainingFile: string
    ): Boolean;

    function LoadIndex(
      const AGraphFile: string;
      const ATrainingFile: string
    ): Boolean;

    // Interface IAIRAGProvider implementation
    function GetLastQuestion: string;
    function GetLastContext: string;
    function GetLastAnswer: string;
    function GetLastSources: TStrings;

    property LastQuestion: string read FLastQuestion;
    property LastContext: string read FLastContext;
    property LastPrompt: string read FLastPrompt;
    property LastAnswer: string read FLastAnswer;
    property LastSources: TStringList read FLastSources;

  published
    property ChatGPT: TCHATGPT
      read FChatGPT write SetChatGPT;

    property GraphMap: TAIGraphMap
      read FGraphMap write SetGraphMap;

    property ChunkSize: Integer
      read FChunkSize write SetChunkSize default 1200;

    property ChunkOverlap: Integer
      read FChunkOverlap write SetChunkOverlap default 150;

    property TopK: Integer
      read FTopK write SetTopK default 4;

    property MinimumScore: Double
      read FMinimumScore write FMinimumScore;

    property MaximumContextLength: Integer
      read FMaximumContextLength
      write SetMaximumContextLength default 12000;

    property Instructions: string
      read FInstructions write FInstructions;

    property NoAnswerText: string
      read FNoAnswerText write FNoAnswerText;

    property SourcePrefix: string
      read FSourcePrefix write FSourcePrefix;

    property ReplaceExistingSource: Boolean
      read FReplaceExistingSource write FReplaceExistingSource default True;

    property OnBeforeIndex: TNotifyEvent
      read FOnBeforeIndex write FOnBeforeIndex;

    property OnAfterIndex: TNotifyEvent
      read FOnAfterIndex write FOnAfterIndex;

    property OnChunkCreated: TAIRAGChunkEvent
      read FOnChunkCreated write FOnChunkCreated;

    property OnBeforeRetrieve: TNotifyEvent
      read FOnBeforeRetrieve write FOnBeforeRetrieve;

    property OnAfterRetrieve: TNotifyEvent
      read FOnAfterRetrieve write FOnAfterRetrieve;

    property OnChunkRetrieved: TAIRAGRetrieveEvent
      read FOnChunkRetrieved write FOnChunkRetrieved;

    property OnContextBuilt: TAIRAGLogEvent
      read FOnContextBuilt write FOnContextBuilt;

    property OnBuildPrompt: TAIRAGPromptEvent
      read FOnBuildPrompt write FOnBuildPrompt;

    property OnBeforeGenerate: TNotifyEvent
      read FOnBeforeGenerate write FOnBeforeGenerate;

    property OnAfterGenerate: TNotifyEvent
      read FOnAfterGenerate write FOnAfterGenerate;

    property OnRAGLog: TAIRAGLogEvent
      read FOnRAGLog write FOnRAGLog;
  end;

procedure Register;

implementation

type
  TRAGRetrievedChunk = class
  public
    ChunkID: string;
    Source: string;
    Text: string;
    Score: Double;
  end;

procedure Register;
begin
  RegisterComponents('AI RAG', [TAIRAG]);
end;

constructor TAIRAG.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FCategory := ccOther;
  FChatGPT := nil;
  FGraphMap := nil;
  FChunkSize := 1200;
  FChunkOverlap := 150;
  FTopK := 4;
  FMinimumScore := 0.0;
  FMaximumContextLength := 12000;
  FInstructions := 'Voce e um assistente especializado nos documentos fornecidos.';
  FNoAnswerText := 'Nao encontrei essa informacao na base de conhecimento.';
  FSourcePrefix := 'rag:';
  FLastQuestion := '';
  FLastContext := '';
  FLastPrompt := '';
  FLastAnswer := '';
  FLastSources := TStringList.Create;
  FReplaceExistingSource := True;
  FPrompt := 'TAIRAG indexes text chunks with TAIGraphMap and builds answer context for TCHATGPT.';
  ClearError;
end;

destructor TAIRAG.Destroy;
begin
  FreeAndNil(FLastSources);
  inherited Destroy;
end;

procedure TAIRAG.SetChatGPT(AValue: TCHATGPT);
begin
  if FChatGPT = AValue then
    Exit;

  FChatGPT := AValue;
  if Assigned(FChatGPT) then
    FChatGPT.FreeNotification(Self);
end;

procedure TAIRAG.SetGraphMap(AValue: TAIGraphMap);
begin
  if FGraphMap = AValue then
    Exit;

  FGraphMap := AValue;
  if Assigned(FGraphMap) then
    FGraphMap.FreeNotification(Self);
end;

procedure TAIRAG.SetChunkSize(AValue: Integer);
begin
  if AValue < 100 then
    AValue := 100
  else if AValue > 100000 then
    AValue := 100000;

  FChunkSize := AValue;
  if FChunkOverlap >= FChunkSize then
    FChunkOverlap := FChunkSize - 1;
  if FChunkOverlap < 0 then
    FChunkOverlap := 0;
end;

procedure TAIRAG.SetChunkOverlap(AValue: Integer);
begin
  if AValue < 0 then
    AValue := 0;
  if AValue >= FChunkSize then
    AValue := FChunkSize - 1;
  if AValue < 0 then
    AValue := 0;
  FChunkOverlap := AValue;
end;

procedure TAIRAG.SetTopK(AValue: Integer);
begin
  if AValue < 1 then
    AValue := 1
  else if AValue > 100 then
    AValue := 100;
  FTopK := AValue;
end;

procedure TAIRAG.SetMaximumContextLength(AValue: Integer);
begin
  if AValue < 1 then
    AValue := 1;
  FMaximumContextLength := AValue;
end;

procedure TAIRAG.DoLog(const AMessage: string);
begin
  if Assigned(FOnRAGLog) then
    FOnRAGLog(Self, AMessage);
end;

procedure TAIRAG.ClearStringListObjects(AStrings: TStrings);
var
  I: Integer;
begin
  if AStrings = nil then
    Exit;

  for I := 0 to AStrings.Count - 1 do
  begin
    if Assigned(AStrings.Objects[I]) then
      AStrings.Objects[I].Free;
  end;
  AStrings.Clear;
end;

procedure TAIRAG.RemoveSourceChunks(const ASourceName: string);
var
  I: Integer;
  Prefix: string;
begin
  if not Assigned(FGraphMap) then
    Exit;

  Prefix := FSourcePrefix + ASourceName + '#';
  for I := FGraphMap.Training.Count - 1 to 0 do
  begin
    if SameText(Copy(FGraphMap.Training[I].OutputCategory, 1, Length(Prefix)), Prefix) then
      FGraphMap.Training.Delete(I);
  end;
end;

procedure TAIRAG.FreeResultObjects(AStrings: TStrings);
var
  I: Integer;
begin
  if AStrings = nil then
    Exit;

  for I := 0 to AStrings.Count - 1 do
  begin
    if Assigned(AStrings.Objects[I]) then
      AStrings.Objects[I].Free;
  end;
end;

function TAIRAG.NormalizeSourceName(const ASource: string): string;
begin
  Result := Trim(ASource);
  if Result = '' then
    Result := 'documento';

  Result := StringReplace(Result, sLineBreak, '_', [rfReplaceAll]);
  Result := StringReplace(Result, #10, '_', [rfReplaceAll]);
  Result := StringReplace(Result, #13, '_', [rfReplaceAll]);
  Result := StringReplace(Result, #9, '_', [rfReplaceAll]);
  Result := StringReplace(Result, ' ', '_', [rfReplaceAll]);
  Result := StringReplace(Result, '=', '_', [rfReplaceAll]);
  Result := StringReplace(Result, '#', '_', [rfReplaceAll]);
  Result := StringReplace(Result, '\', '_', [rfReplaceAll]);
  Result := StringReplace(Result, '/', '_', [rfReplaceAll]);
  Result := StringReplace(Result, ':', '_', [rfReplaceAll]);
end;

procedure TAIRAG.SplitText(const AText: string; AChunks: TStrings);
var
  StartPos: Integer;
  Remaining: Integer;
  ChunkEnd: Integer;
  Slice: string;
  BreakPos: Integer;
  Chunk: string;
  NextStart: Integer;
begin
  if AChunks = nil then
    Exit;

  AChunks.Clear;
  if Trim(AText) = '' then
    Exit;

  if Length(AText) <= FChunkSize then
  begin
    AChunks.Add(Trim(AText));
    Exit;
  end;

  StartPos := 1;
  while StartPos <= Length(AText) do
  begin
    Remaining := Length(AText) - StartPos + 1;
    if Remaining <= FChunkSize then
      ChunkEnd := Length(AText)
    else
    begin
      ChunkEnd := StartPos + FChunkSize - 1;
      Slice := Copy(AText, StartPos, FChunkSize);
      BreakPos := LastDelimiter(#10#13, Slice);
      if BreakPos > 0 then
        ChunkEnd := StartPos + BreakPos - 1;
    end;

    if ChunkEnd < StartPos then
      ChunkEnd := StartPos + FChunkSize - 1;
    if ChunkEnd > Length(AText) then
      ChunkEnd := Length(AText);

    Chunk := Trim(Copy(AText, StartPos, ChunkEnd - StartPos + 1));
    if Chunk <> '' then
      AChunks.Add(Chunk);

    if ChunkEnd >= Length(AText) then
      Break;

    NextStart := ChunkEnd - FChunkOverlap + 1;
    if NextStart <= StartPos then
      NextStart := ChunkEnd + 1;
    if NextStart <= StartPos then
      Break;

    StartPos := NextStart;
  end;
end;

function TAIRAG.ValidateComponents(ARequireChatGPT: Boolean): Boolean;
begin
  Result := Assigned(FGraphMap);
  if not Result then
  begin
    SetError('Componente TAIGraphMap nao associado.');
    Exit(False);
  end;

  if ARequireChatGPT and not Assigned(FChatGPT) then
  begin
    SetError('Componente TCHATGPT nao associado.');
    Exit(False);
  end;
end;

procedure TAIRAG.Notification(AComponent: TComponent; Operation: TOperation);
begin
  inherited Notification(AComponent, Operation);

  if Operation = opRemove then
  begin
    if AComponent = FChatGPT then
      FChatGPT := nil;
    if AComponent = FGraphMap then
      FGraphMap := nil;
  end;
end;

procedure TAIRAG.Clear;
begin
  ClearError;
  if Assigned(FGraphMap) then
  begin
    FGraphMap.ClearTraining;
    FGraphMap.ClearGraph;
  end;

  FLastQuestion := '';
  FLastContext := '';
  FLastPrompt := '';
  FLastAnswer := '';
  FLastSources.Clear;
  FLastResult := '';
end;

function TAIRAG.AddText(const ASource: string; const AText: string): Integer;
var
  SourceName: string;
  Chunks: TStringList;
  I: Integer;
  ChunkID: string;
  Item: TAITrainingItem;
begin
  Result := 0;
  ClearError;

  if not ValidateComponents(False) then
    Exit;

  if Trim(AText) = '' then
    Exit;

  SourceName := NormalizeSourceName(ASource);
  if FReplaceExistingSource then
    RemoveSourceChunks(SourceName);

  Chunks := TStringList.Create;
  try
    SplitText(AText, Chunks);
    for I := 0 to Chunks.Count - 1 do
    begin
      ChunkID := FSourcePrefix + SourceName + '#' + Format('%.6d', [Result + 1]);
      Item := FGraphMap.Training.Add;
      Item.InputText := Chunks[I];
      Item.OutputCategory := ChunkID;
      Item.Weight := 1.0;
      Inc(Result);
      DoLog('Chunk criado: ' + ChunkID);
      if Assigned(FOnChunkCreated) then
        FOnChunkCreated(Self, ChunkID, SourceName, Chunks[I]);
    end;
  finally
    Chunks.Free;
  end;
end;

function TAIRAG.AddFile(const AFileName: string): Integer;
var
  LList: TStringList;
  Ext: string;
begin
  Result := 0;
  ClearError;

  if Trim(AFileName) = '' then
  begin
    SetError('Nome do arquivo vazio.');
    Exit;
  end;

  if not FileExists(AFileName) then
  begin
    SetError('Arquivo nao encontrado: ' + AFileName);
    Exit;
  end;

  Ext := LowerCase(ExtractFileExt(AFileName));
  if (Ext <> '.txt') and (Ext <> '.md') then
  begin
    SetError('Formato nao suportado: ' + Ext);
    Exit;
  end;

  LList := TStringList.Create;
  try
    LList.LoadFromFile(AFileName);
    Result := AddText(ExtractFileName(AFileName), LList.Text);
  finally
    LList.Free;
  end;
end;

function TAIRAG.BuildIndex: Boolean;
begin
  Result := False;
  ClearError;

  if not Assigned(FGraphMap) then
  begin
    SetError('Componente TAIGraphMap nao associado.');
    Exit;
  end;

  if FGraphMap.Training.Count = 0 then
  begin
    SetError('Nao ha textos treinados para indexacao.');
    Exit;
  end;

  if Assigned(FOnBeforeIndex) then
    FOnBeforeIndex(Self);

  try
    FGraphMap.Train;
    if Trim(FGraphMap.LastError) <> '' then
    begin
      SetError(FGraphMap.LastError);
      Exit;
    end;

    Result := FGraphMap.NodeCount > 0;
    if Result then
      FLastResult := 'Indice construído com sucesso.';
  finally
    if Assigned(FOnAfterIndex) then
      FOnAfterIndex(Self);
  end;
end;

function TAIRAG.FindChunkText(const AChunkID: string): string;
var
  I: Integer;
begin
  Result := '';
  if not Assigned(FGraphMap) then
    Exit;

  for I := 0 to FGraphMap.Training.Count - 1 do
  begin
    if SameText(FGraphMap.Training[I].OutputCategory, AChunkID) then
      Exit(FGraphMap.Training[I].InputText);
  end;
end;

function TAIRAG.ExtractSourceName(const AChunkID: string): string;
var
  Temp: string;
  P: Integer;
begin
  Result := '';
  Temp := AChunkID;
  if SameText(Copy(Temp, 1, Length(FSourcePrefix)), FSourcePrefix) then
    Delete(Temp, 1, Length(FSourcePrefix));

  P := Pos('#', Temp);
  if P > 0 then
    Result := Copy(Temp, 1, P - 1)
  else
    Result := Temp;
end;

function TAIRAG.Retrieve(const AQuestion: string; AResults: TStrings): Boolean;
var
  Ranking: TStringList;
  I: Integer;
  LCategory: string;
  ScoreText: string;
  Score: Double;
  ChunkText: string;
  Include: Boolean;
  Item: TRAGRetrievedChunk;
  SourceName: string;
begin
  Result := False;
  if AResults = nil then
    Exit;

  ClearStringListObjects(AResults);
  AResults.Clear;

  if Trim(AQuestion) = '' then
    Exit;

  if not ValidateComponents(False) then
    Exit;

  if FGraphMap.Training.Count = 0 then
    Exit;

  if Assigned(FOnBeforeRetrieve) then
    FOnBeforeRetrieve(Self);

  Ranking := TStringList.Create;
  try
    FGraphMap.PredictRanking(AQuestion, Ranking);
    for I := 0 to Ranking.Count - 1 do
    begin
      LCategory := Ranking.Names[I];
      if LCategory = '' then
        LCategory := Ranking[I];

      if Copy(LCategory, 1, Length(FSourcePrefix)) <> FSourcePrefix then
        Continue;

      ScoreText := Ranking.ValueFromIndex[I];
      Score := StrToFloatDef(ScoreText, 0.0);
      if Score < FMinimumScore then
        Continue;

      ChunkText := FindChunkText(LCategory);
      if Trim(ChunkText) = '' then
        Continue;

      Include := True;
      SourceName := ExtractSourceName(LCategory);
      if Assigned(FOnChunkRetrieved) then
        FOnChunkRetrieved(Self, LCategory, SourceName, ChunkText, Score, Include);
      if not Include then
        Continue;

      Item := TRAGRetrievedChunk.Create;
      Item.ChunkID := LCategory;
      Item.Source := SourceName;
      Item.Text := ChunkText;
      Item.Score := Score;
      AResults.AddObject(LCategory, Item);
      if AResults.Count >= FTopK then
        Break;
    end;

    Result := AResults.Count > 0;
  finally
    Ranking.Free;
    if Assigned(FOnAfterRetrieve) then
      FOnAfterRetrieve(Self);
  end;
end;

function TAIRAG.BuildContext(const AQuestion: string): Boolean;
var
  Results: TStringList;
  I: Integer;
  Item: TRAGRetrievedChunk;
  Block: string;
begin
  Result := False;
  FLastQuestion := AQuestion;
  FLastContext := '';
  FLastSources.Clear;

  if Trim(AQuestion) = '' then
    Exit;

  if not ValidateComponents(False) then
    Exit;

  Results := TStringList.Create;
  try
    if not Retrieve(AQuestion, Results) then
      Exit;

    for I := 0 to Results.Count - 1 do
    begin
      Item := TRAGRetrievedChunk(Results.Objects[I]);
      if not Assigned(Item) then
        Continue;

      Block := '[FONTE ' + IntToStr(FLastSources.Count + 1) + ']' + sLineBreak +
        'Identificacao: ' + Item.ChunkID + sLineBreak +
        'Fonte: ' + Item.Source + sLineBreak + sLineBreak +
        Item.Text;

      if (Length(FLastContext) > 0) then
        Block := sLineBreak + sLineBreak + Block;

      if Length(FLastContext) + Length(Block) > FMaximumContextLength then
        Break;

      FLastContext := FLastContext + Block;
      FLastSources.Add(Format('%s | %s | score=%.2f', [Item.Source, Item.ChunkID, Item.Score]));
      Result := True;
    end;

    if Result and Assigned(FOnContextBuilt) then
      FOnContextBuilt(Self, FLastContext);
  finally
    FreeResultObjects(Results);
    Results.Free;
  end;
end;

function TAIRAG.BuildPrompt(const AQuestion, AContext: string): string;
begin
  Result := FInstructions + sLineBreak + sLineBreak +
    'Utilize exclusivamente o contexto abaixo para responder.' + sLineBreak +
    'Caso a informacao nao esteja no contexto, responda: "' + FNoAnswerText + '".' + sLineBreak + sLineBreak +
    'CONTEXTO:' + sLineBreak +
    AContext + sLineBreak + sLineBreak +
    'PERGUNTA:' + sLineBreak +
    AQuestion;

  if Assigned(FOnBuildPrompt) then
    FOnBuildPrompt(Self, AQuestion, AContext, Result);
end;

function TAIRAG.Ask(const AQuestion: string): Boolean;
begin
  Result := False;
  ClearError;

  if Trim(AQuestion) = '' then
    Exit;

  if not ValidateComponents(True) then
    Exit;

  if Assigned(FOnBeforeGenerate) then
    FOnBeforeGenerate(Self);

  try
    if not BuildContext(AQuestion) or (Trim(FLastContext) = '') then
    begin
      FLastAnswer := FNoAnswerText;
      FLastResult := FLastAnswer;
      FLastSuccess := True;
      Result := True;
      Exit;
    end;

    FLastPrompt := BuildPrompt(AQuestion, FLastContext);
    if not FChatGPT.SendQuestion(FLastPrompt) then
    begin
      if Trim(FChatGPT.LastError) <> '' then
        SetError(FChatGPT.LastError)
      else
        SetError(FChatGPT.Response);
      Exit(False);
    end;

    FLastAnswer := FChatGPT.Response;
    FLastResult := FLastAnswer;
    FLastSuccess := True;
    Result := True;
  finally
    if Assigned(FOnAfterGenerate) then
      FOnAfterGenerate(Self);
  end;
end;

function TAIRAG.SaveIndex(const AGraphFile, ATrainingFile: string): Boolean;
begin
  Result := False;
  ClearError;

  if not Assigned(FGraphMap) then
  begin
    SetError('Componente TAIGraphMap nao associado.');
    Exit;
  end;

  try
    if ATrainingFile <> '' then
      FGraphMap.SaveTrainingToFile(ATrainingFile);
    if AGraphFile <> '' then
      FGraphMap.SaveGraphToFile(AGraphFile);
    Result := True;
  except
    on E: Exception do
      SetError(E.Message);
  end;
end;

function TAIRAG.LoadIndex(const AGraphFile, ATrainingFile: string): Boolean;
begin
  Result := False;
  ClearError;

  if not Assigned(FGraphMap) then
  begin
    SetError('Componente TAIGraphMap nao associado.');
    Exit;
  end;

  try
    if (ATrainingFile <> '') and FileExists(ATrainingFile) then
      FGraphMap.LoadTrainingFromFile(ATrainingFile);

    if (AGraphFile <> '') and FileExists(AGraphFile) then
      FGraphMap.LoadGraphFromFile(AGraphFile);

    Result := True;
  except
    on E: Exception do
      SetError(E.Message);
  end;
end;

function TAIRAG.GetLastQuestion: string;
begin
  Result := FLastQuestion;
end;

function TAIRAG.GetLastContext: string;
begin
  Result := FLastContext;
end;

function TAIRAG.GetLastAnswer: string;
begin
  Result := FLastAnswer;
end;

function TAIRAG.GetLastSources: TStrings;
begin
  Result := FLastSources;
end;

end.
