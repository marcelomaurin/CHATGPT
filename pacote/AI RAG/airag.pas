unit airag;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, chatgpt, aigraphmap, aibase, LResources;

type

  { TAIRAG }

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
    const AScore: Double
  ) of object;

  TAIRAGPromptEvent = procedure(
    Sender: TObject;
    const AQuestion: string;
    const AContext: string;
    var APrompt: string
  ) of object;

  TAIRAGLogEvent = procedure(
    Sender: TObject;
    const AMessage: string
  ) of object;

  TAIRAG = class(TAIBaseComponent)
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

    function AddFolder(
      const AFolderPath: string;
      ARecursive: Boolean = True;
      const AFileExtensions: string = '.txt;.md;.pas;.py;.json;.csv;.xml;.html;.log'
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
      const AGraphFileName: string;
      const ATrainingFileName: string = ''
    ): Boolean;

    function LoadIndex(
      const AGraphFileName: string;
      const ATrainingFileName: string = ''
    ): Boolean;

    property LastQuestion: string read FLastQuestion;
    property LastContext: string read FLastContext;
    property LastPrompt: string read FLastPrompt;
    property LastAnswer: string read FLastAnswer;
    property LastSources: TStringList read FLastSources;

  published
    property ChatGPT: TCHATGPT read FChatGPT write SetChatGPT;
    property GraphMap: TAIGraphMap read FGraphMap write SetGraphMap;

    property ChunkSize: Integer read FChunkSize write SetChunkSize default 1200;
    property ChunkOverlap: Integer read FChunkOverlap write SetChunkOverlap default 150;

    property TopK: Integer read FTopK write SetTopK default 4;
    property MinimumScore: Double read FMinimumScore write FMinimumScore;
    property MaximumContextLength: Integer read FMaximumContextLength write SetMaximumContextLength default 12000;

    property Instructions: string read FInstructions write FInstructions;
    property NoAnswerText: string read FNoAnswerText write FNoAnswerText;
    property SourcePrefix: string read FSourcePrefix write FSourcePrefix;
    property ReplaceExistingSource: Boolean read FReplaceExistingSource write FReplaceExistingSource default True;

    property OnBeforeIndex: TNotifyEvent read FOnBeforeIndex write FOnBeforeIndex;
    property OnAfterIndex: TNotifyEvent read FOnAfterIndex write FOnAfterIndex;
    property OnChunkCreated: TAIRAGChunkEvent read FOnChunkCreated write FOnChunkCreated;
    property OnBeforeRetrieve: TNotifyEvent read FOnBeforeRetrieve write FOnBeforeRetrieve;
    property OnAfterRetrieve: TNotifyEvent read FOnAfterRetrieve write FOnAfterRetrieve;
    property OnChunkRetrieved: TAIRAGRetrieveEvent read FOnChunkRetrieved write FOnChunkRetrieved;
    property OnContextBuilt: TAIRAGLogEvent read FOnContextBuilt write FOnContextBuilt;
    property OnBuildPrompt: TAIRAGPromptEvent read FOnBuildPrompt write FOnBuildPrompt;
    property OnBeforeGenerate: TNotifyEvent read FOnBeforeGenerate write FOnBeforeGenerate;
    property OnAfterGenerate: TNotifyEvent read FOnAfterGenerate write FOnAfterGenerate;
    property OnRAGLog: TAIRAGLogEvent read FOnRAGLog write FOnRAGLog;
  end;

type
  TRAGRetrievedChunk = class
  public
    ChunkID: string;
    Source: string;
    Text: string;
    Score: Double;
  end;

procedure Register;

implementation

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
  FPrompt := 'TAIRAG realiza fatiamento, indexacao relacional e geracao de respostas com fontes.';
  ClearError;
end;

destructor TAIRAG.Destroy;
begin
  FLastSources.Free;
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
  if AValue < 50 then
    AValue := 50;
  FChunkSize := AValue;
  if FChunkOverlap >= FChunkSize then
    FChunkOverlap := FChunkSize div 4;
end;

procedure TAIRAG.SetChunkOverlap(AValue: Integer);
begin
  if AValue < 0 then
    AValue := 0;
  if AValue >= FChunkSize then
    AValue := FChunkSize div 4;
  FChunkOverlap := AValue;
end;

procedure TAIRAG.SetTopK(AValue: Integer);
begin
  if AValue < 1 then
    AValue := 1;
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
  if FGraphMap.Training.Count = 0 then
    Exit;

  Prefix := FSourcePrefix + ASourceName + '#';
  for I := FGraphMap.Training.Count - 1 downto 0 do
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
  AStrings.Clear;
end;

function TAIRAG.NormalizeSourceName(const ASource: string): string;
var
  S: string;
begin
  S := ExtractFileName(ASource);
  if S = '' then
    S := ASource;
  S := StringReplace(S, ' ', '_', [rfReplaceAll]);
  S := StringReplace(S, ':', '_', [rfReplaceAll]);
  S := StringReplace(S, '#', '_', [rfReplaceAll]);
  Result := LowerCase(S);
end;

procedure TAIRAG.SplitText(const AText: string; AChunks: TStrings);
var
  StartPos, NextStart, ChunkEnd, BreakPos, I: Integer;
  Chunk: string;
  Delim: Char;
begin
  if AChunks = nil then
    Exit;

  AChunks.Clear;
  if Trim(AText) = '' then
    Exit;

  StartPos := 1;
  while StartPos <= Length(AText) do
  begin
    ChunkEnd := StartPos + FChunkSize - 1;
    if ChunkEnd >= Length(AText) then
      ChunkEnd := Length(AText)
    else
    begin
      BreakPos := 0;
      for Delim in [#10, '.', '!', '?', ';'] do
      begin
        for I := ChunkEnd downto StartPos + (FChunkSize div 2) do
        begin
          if AText[I] = Delim then
          begin
            BreakPos := I;
            Break;
          end;
        end;
        if BreakPos > 0 then
          Break;
      end;

      if BreakPos > 0 then
        ChunkEnd := BreakPos;
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
    DoLog('[ERRO COMPONENTE] Componente TAIGraphMap não associado.');
    Exit(False);
  end;

  if ARequireChatGPT and not Assigned(FChatGPT) then
  begin
    SetError('Componente TCHATGPT nao associado.');
    DoLog('[ERRO COMPONENTE] Componente TCHATGPT não associado.');
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
  DoLog('Base RAG e estado do grafo limpos.');
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
  begin
    DoLog('[ERRO ADDTEXT] Componentes inválidos: ' + FLastError);
    Exit;
  end;

  if Trim(AText) = '' then
  begin
    DoLog('[AVISO ADDTEXT] O texto fornecido para "' + ASource + '" está em branco.');
    Exit;
  end;

  SourceName := NormalizeSourceName(ASource);
  if FReplaceExistingSource then
    RemoveSourceChunks(SourceName);

  Chunks := TStringList.Create;
  try
    SplitText(AText, Chunks);
    DoLog(Format('Texto "%s" (tamanho: %d bytes) fatiado em %d chunks.', [ASource, Length(AText), Chunks.Count]));

    for I := 0 to Chunks.Count - 1 do
    begin
      ChunkID := FSourcePrefix + SourceName + '#' + Format('%.6d', [Result + 1]);
      Item := FGraphMap.Training.Add;
      Item.InputText := Chunks[I];
      Item.OutputCategory := ChunkID;
      Item.Weight := 1.0;
      Inc(Result);
      DoLog(Format('  -> Chunk #%d criado [%s] (%d caracteres)', [Result, ChunkID, Length(Chunks[I])]));
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
  FullFilePath: string;
begin
  Result := 0;
  ClearError;

  if Trim(AFileName) = '' then
  begin
    SetError('Nome do arquivo vazio.');
    DoLog('[ERRO ADDFILE] Nome do arquivo vazio.');
    Exit;
  end;

  FullFilePath := ExpandFileName(AFileName);
  if not FileExists(FullFilePath) then
    FullFilePath := AFileName;

  if not FileExists(FullFilePath) then
  begin
    SetError('Arquivo nao encontrado: ' + AFileName);
    DoLog('[ERRO ADDFILE] Arquivo não encontrado no disco: ' + AFileName);
    Exit;
  end;

  LList := TStringList.Create;
  try
    try
      LList.LoadFromFile(FullFilePath);
      DoLog(Format('Lendo arquivo: %s (%d linhas, %d caracteres)', [ExtractFileName(FullFilePath), LList.Count, Length(LList.Text)]));
      Result := AddText(ExtractFileName(FullFilePath), LList.Text);
      if Result = 0 then
        DoLog('[AVISO ADDFILE] O arquivo ' + ExtractFileName(FullFilePath) + ' resultou em 0 chunks no RAG.');
    except
      on E: Exception do
      begin
        SetError('Erro ao ler arquivo ' + FullFilePath + ': ' + E.Message);
        DoLog('[EXCEÇÃO ADDFILE] Falha ao ler ' + ExtractFileName(FullFilePath) + ': ' + E.Message);
        Result := 0;
      end;
    end;
  finally
    LList.Free;
  end;
end;

function TAIRAG.AddFolder(const AFolderPath: string; ARecursive: Boolean; const AFileExtensions: string): Integer;
var
  ExtList: TStringList;
  TargetDir: string;

  procedure ParseExtensions(const AInput: string);
  var
    S, Token: string;
    P: Integer;
  begin
    ExtList.Clear;
    S := Trim(AInput);
    if (S = '') or (S = '*') or (S = '*.*') then Exit;

    S := StringReplace(S, ',', ';', [rfReplaceAll]);
    S := StringReplace(S, ' ', ';', [rfReplaceAll]);

    while S <> '' do
    begin
      P := Pos(';', S);
      if P > 0 then
      begin
        Token := Trim(Copy(S, 1, P - 1));
        Delete(S, 1, P);
      end
      else
      begin
        Token := Trim(S);
        S := '';
      end;

      if Token <> '' then
      begin
        Token := LowerCase(Token);
        if Token[1] <> '.' then
          Token := '.' + Token;
        if ExtList.IndexOf(Token) < 0 then
          ExtList.Add(Token);
      end;
    end;
  end;

  procedure ScanDir(const ADir: string);
  var
    SearchRec: TSearchRec;
    FilePath, Ext: string;
    I, ChunksAdded: Integer;
    Match: Boolean;
  begin
    if not DirectoryExists(ADir) then
    begin
      DoLog('[AVISO VARREDURA] Subdiretório não existe: ' + ADir);
      Exit;
    end;

    if FindFirst(IncludeTrailingPathDelimiter(ADir) + '*.*', faAnyFile, SearchRec) = 0 then
    begin
      try
        repeat
          if (SearchRec.Name <> '.') and (SearchRec.Name <> '..') then
          begin
            FilePath := IncludeTrailingPathDelimiter(ADir) + SearchRec.Name;
            if (SearchRec.Attr and faDirectory) <> 0 then
            begin
              if ARecursive then
                ScanDir(FilePath);
            end
            else
            begin
              Ext := LowerCase(ExtractFileExt(SearchRec.Name));
              Match := False;
              if ExtList.Count = 0 then
                Match := True
              else
              begin
                for I := 0 to ExtList.Count - 1 do
                begin
                  if SameText(Ext, ExtList[I]) then
                  begin
                    Match := True;
                    Break;
                  end;
                end;
              end;

              if Match then
              begin
                DoLog(Format('Encontrado arquivo correspondente: %s (%d bytes)', [SearchRec.Name, SearchRec.Size]));
                ChunksAdded := AddFile(FilePath);
                if ChunksAdded > 0 then
                  Inc(Result)
                else
                  DoLog('[AVISO VARREDURA] Arquivo ignorado ou gerou 0 chunks: ' + SearchRec.Name);
              end;
            end;
          end;
        until FindNext(SearchRec) <> 0;
      finally
        FindClose(SearchRec);
      end;
    end;
  end;

begin
  Result := 0;
  ClearError;

  TargetDir := ExpandFileName(AFolderPath);
  if not DirectoryExists(TargetDir) then
    TargetDir := AFolderPath;

  if not DirectoryExists(TargetDir) then
  begin
    SetError('Diretorio nao encontrado: ' + AFolderPath);
    DoLog('[ERRO VARREDURA] Diretório não encontrado: ' + AFolderPath);
    Exit(0);
  end;

  ExtList := TStringList.Create;
  try
    ParseExtensions(AFileExtensions);
    DoLog('Iniciando varredura na pasta: ' + TargetDir);
    DoLog('Filtros de extensão ativos: ' + ExtList.CommaText);
    ScanDir(TargetDir);
    DoLog(Format('Varredura concluída: %d arquivos aceitos (%d chunks no total em Training.Count).', [Result, FGraphMap.Training.Count]));
  finally
    ExtList.Free;
  end;
end;

function TAIRAG.BuildIndex: Boolean;
begin
  Result := False;
  ClearError;

  if not Assigned(FGraphMap) then
  begin
    SetError('Componente TAIGraphMap nao associado.');
    DoLog('[ERRO BUILDINDEX] Componente TAIGraphMap não associado ao TAIRAG.');
    Exit;
  end;

  if FGraphMap.Training.Count = 0 then
  begin
    SetError('Nao ha textos treinados para indexacao.');
    DoLog('[ERRO BUILDINDEX] FGraphMap.Training.Count é 0. Nenhum documento foi adicionado.');
    Exit;
  end;

  DoLog(Format('Iniciando treinamento do Grafo com %d itens de treino...', [FGraphMap.Training.Count]));
  if Assigned(FOnBeforeIndex) then
    FOnBeforeIndex(Self);

  try
    FGraphMap.Train;
    if Trim(FGraphMap.LastError) <> '' then
    begin
      SetError('Erro ao treinar grafo: ' + FGraphMap.LastError);
      DoLog('[ERRO GRAFO] ' + FGraphMap.LastError);
      Exit;
    end;

    Result := True;
    FLastSuccess := True;
    DoLog(Format('Índice RAG construído com SUCESSO. Grafo treinado com %d nós e %d arestas.', [FGraphMap.NodeCount, FGraphMap.EdgeCount]));
    if Assigned(FOnAfterIndex) then
      FOnAfterIndex(Self);
  except
    on E: Exception do
    begin
      SetError('Erro na construcao do indice: ' + E.Message);
      DoLog('[EXCEÇÃO BUILDINDEX] ' + E.Message);
      Result := False;
    end;
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
    begin
      Result := FGraphMap.Training[I].InputText;
      Exit;
    end;
  end;
end;

function TAIRAG.ExtractSourceName(const AChunkID: string): string;
var
  S: string;
  HashPos: Integer;
begin
  Result := AChunkID;
  S := AChunkID;
  if SameText(Copy(S, 1, Length(FSourcePrefix)), FSourcePrefix) then
    Delete(S, 1, Length(FSourcePrefix));

  HashPos := Pos('#', S);
  if HashPos > 0 then
    Result := Copy(S, 1, HashPos - 1)
  else
    Result := S;
end;

function TAIRAG.Retrieve(const AQuestion: string; AResults: TStrings): Boolean;
var
  PredictionList: TStringList;
  I, EqualPos: Integer;
  RawLine, ChunkID, ScoreStr, ChunkText, SrcName: string;
  Score: Double;
  Item: TRAGRetrievedChunk;
begin
  Result := False;
  ClearError;

  if AResults = nil then
  begin
    SetError('StringList de resultados nao instanciada.');
    DoLog('[ERRO RETRIEVE] StringList de resultados nula.');
    Exit;
  end;

  FreeResultObjects(AResults);
  if not ValidateComponents(False) then
  begin
    DoLog('[ERRO RETRIEVE] Componentes inválidos: ' + FLastError);
    Exit;
  end;

  if Trim(AQuestion) = '' then
  begin
    SetError('Pergunta em branco.');
    DoLog('[AVISO RETRIEVE] Pergunta fornecida está em branco.');
    Exit;
  end;

  DoLog('Pesquisando pergunta no Grafo RAG: "' + AQuestion + '"');
  if Assigned(FOnBeforeRetrieve) then
    FOnBeforeRetrieve(Self);

  PredictionList := TStringList.Create;
  try
    FGraphMap.PredictRanking(AQuestion, PredictionList);
    DoLog(Format('Grafo retornou %d categorias de ranking para a pergunta.', [PredictionList.Count]));

    for I := 0 to PredictionList.Count - 1 do
    begin
      if AResults.Count >= FTopK then
        Break;

      RawLine := PredictionList[I];
      ChunkID := PredictionList.Names[I];
      if ChunkID = '' then
      begin
        EqualPos := Pos('=', RawLine);
        if EqualPos > 0 then
        begin
          ChunkID := Copy(RawLine, 1, EqualPos - 1);
          ScoreStr := Copy(RawLine, EqualPos + 1, Length(RawLine));
        end
        else
        begin
          ChunkID := RawLine;
          ScoreStr := '0';
        end;
      end
      else
        ScoreStr := PredictionList.ValueFromIndex[I];

      ScoreStr := StringReplace(ScoreStr, ',', '.', [rfReplaceAll]);
      Score := StrToFloatDef(ScoreStr, 0.0);

      if not SameText(Copy(ChunkID, 1, Length(FSourcePrefix)), FSourcePrefix) then
        Continue;

      DoLog(Format('  Ranking #%d: Categoria "%s" | Score: %.2f', [I + 1, ChunkID, Score]));

      if Score < FMinimumScore then
      begin
        DoLog(Format('  -> Ignorado por score (%.2f < MinimumScore %.2f)', [Score, FMinimumScore]));
        Continue;
      end;

      ChunkText := FindChunkText(ChunkID);
      if ChunkText = '' then
      begin
        DoLog('  -> AVISO: ChunkText não encontrado no treinamento para ' + ChunkID);
        Continue;
      end;

      SrcName := ExtractSourceName(ChunkID);

      Item := TRAGRetrievedChunk.Create;
      Item.ChunkID := ChunkID;
      Item.Source := SrcName;
      Item.Text := ChunkText;
      Item.Score := Score;

      AResults.AddObject(ChunkID, Item);
      DoLog(Format('  -> Chunk "%s" aceito no contexto (Score: %.2f).', [ChunkID, Score]));

      if Assigned(FOnChunkRetrieved) then
        FOnChunkRetrieved(Self, ChunkID, SrcName, ChunkText, Score);
    end;

    Result := AResults.Count > 0;
    FLastSuccess := Result;
    if Result then
      DoLog(Format('Retrieve concluído: %d trechos selecionados para a resposta.', [AResults.Count]))
    else
      DoLog('[AVISO RETRIEVE] Nenhum trecho atendeu aos critérios de similaridade para a pergunta.');

    if Assigned(FOnAfterRetrieve) then
      FOnAfterRetrieve(Self);
  finally
    PredictionList.Free;
  end;
end;

function TAIRAG.BuildContext(const AQuestion: string): Boolean;
var
  Results: TStringList;
  I: Integer;
  Item: TRAGRetrievedChunk;
  ContextBlock, SourceLine: string;
begin
  Result := False;
  ClearError;
  FLastQuestion := AQuestion;
  FLastContext := '';
  FLastSources.Clear;

  Results := TStringList.Create;
  try
    if not Retrieve(AQuestion, Results) then
    begin
      FLastContext := '';
      Exit(False);
    end;

    ContextBlock := '';
    for I := 0 to Results.Count - 1 do
    begin
      Item := TRAGRetrievedChunk(Results.Objects[I]);
      if Item = nil then
        Continue;

      SourceLine := Format('[FONTE %d: %s (Chunk: %s, Score: %.2f)]', [I + 1, Item.Source, Item.ChunkID, Item.Score]);
      if FLastSources.IndexOf(Item.Source) < 0 then
        FLastSources.Add(Item.Source);

      if ContextBlock <> '' then
        ContextBlock := ContextBlock + sLineBreak + sLineBreak;

      ContextBlock := ContextBlock + SourceLine + sLineBreak + Item.Text;

      if Length(ContextBlock) >= FMaximumContextLength then
      begin
        ContextBlock := Copy(ContextBlock, 1, FMaximumContextLength);
        Break;
      end;
    end;

    FLastContext := ContextBlock;
    Result := FLastContext <> '';
    FLastSuccess := Result;
    DoLog('Contexto RAG construido.');
    if Assigned(FOnContextBuilt) then
      FOnContextBuilt(Self, FLastContext);
  finally
    FreeResultObjects(Results);
    Results.Free;
  end;
end;

function TAIRAG.BuildPrompt(const AQuestion: string; const AContext: string): string;
begin
  Result := FInstructions + sLineBreak + sLineBreak +
    'Sua resposta deve ser estritamente baseada no contexto de documentos fornecido abaixo.' + sLineBreak +
    'Se a informação não estiver presente no contexto, responda: "' + FNoAnswerText + '"' + sLineBreak + sLineBreak +
    '=== INICIO DO CONTEXTO DE DOCUMENTOS ===' + sLineBreak +
    AContext + sLineBreak +
    '=== FIM DO CONTEXTO DE DOCUMENTOS ===' + sLineBreak + sLineBreak +
    'Pergunta do Usuário: ' + AQuestion;

  FLastPrompt := Result;
  if Assigned(FOnBuildPrompt) then
    FOnBuildPrompt(Self, AQuestion, AContext, Result);
end;

function TAIRAG.Ask(const AQuestion: string): Boolean;
var
  FullPrompt: string;
begin
  Result := False;
  ClearError;
  FLastAnswer := '';

  DoLog('========== INICIANDO CONSULTA RAG ==========');
  DoLog('Pergunta: "' + AQuestion + '"');

  if not ValidateComponents(True) then
  begin
    DoLog('[ERRO ASK] Componentes não validados: ' + FLastError);
    Exit;
  end;

  // Auto constroi o indice se o grafo ainda nao foi treinado
  if (FGraphMap.NodeCount = 0) and (FGraphMap.Training.Count > 0) then
  begin
    DoLog('Grafo nao treinado detectado. Gerando indice RAG automaticamente...');
    if not BuildIndex then
    begin
      DoLog('[ERRO ASK] Falha ao construir o índice automaticamente.');
      Exit(False);
    end;
  end;

  if FGraphMap.Training.Count = 0 then
  begin
    SetError('Nenhum documento foi adicionado para busca RAG. Adicione arquivos ou varra uma pasta primeiro.');
    DoLog('[ERRO ASK] FGraphMap.Training.Count é 0. Nenhum documento indexado.');
    Exit(False);
  end;

  if not BuildContext(AQuestion) then
  begin
    FLastAnswer := FNoAnswerText;
    FLastResult := FNoAnswerText;
    DoLog('[AVISO ASK] Nenhum contexto relevante encontrado para a pergunta. Retornando resposta padrão.');
    Result := True;
    Exit;
  end;

  FullPrompt := BuildPrompt(AQuestion, FLastContext);
  DoLog('Prompt RAG construído com sucesso (' + IntToStr(Length(FullPrompt)) + ' caracteres). Enviando ao TCHATGPT...');

  if Assigned(FOnBeforeGenerate) then
    FOnBeforeGenerate(Self);

  try
    FChatGPT.Prompt := FullPrompt;
    if FChatGPT.SendQuestion(FullPrompt) then
    begin
      FLastAnswer := FChatGPT.Response;
      if FLastAnswer = '' then
        FLastAnswer := FChatGPT.LastResult;
      FLastResult := FLastAnswer;
      Result := True;
      FLastSuccess := True;
      DoLog('========== RESPOSTA RAG GERADA COM SUCESSO ==========');
      DoLog('Resposta da IA:' + sLineBreak + FLastAnswer);
      if Assigned(FOnAfterGenerate) then
        FOnAfterGenerate(Self);
    end
    else
    begin
      SetError('Erro no componente TCHATGPT: ' + FChatGPT.LastError);
      DoLog('[ERRO TCHATGPT] ' + FChatGPT.LastError);
      Result := False;
    end;
  except
    on E: Exception do
    begin
      SetError('Erro ao gerar resposta RAG: ' + E.Message);
      DoLog('[EXCEÇÃO ASK] ' + E.Message);
      Result := False;
    end;
  end;
end;

function TAIRAG.SaveIndex(const AGraphFileName: string; const ATrainingFileName: string): Boolean;
var
  TrainFile: string;
begin
  Result := False;
  ClearError;

  if not Assigned(FGraphMap) then
  begin
    SetError('Componente TAIGraphMap nao associado.');
    DoLog('[ERRO SAVEINDEX] Componente TAIGraphMap não associado.');
    Exit;
  end;

  try
    FGraphMap.SaveGraphToFile(AGraphFileName);

    TrainFile := ATrainingFileName;
    if TrainFile = '' then
      TrainFile := ChangeFileExt(AGraphFileName, '.json');

    FGraphMap.SaveTrainingToFile(TrainFile);

    Result := True;
    FLastSuccess := True;
    DoLog('Índice RAG e grafo salvos com sucesso em: ' + AGraphFileName);
  except
    on E: Exception do
    begin
      SetError('Erro ao salvar indice RAG: ' + E.Message);
      DoLog('[EXCEÇÃO SAVEINDEX] ' + E.Message);
      Result := False;
    end;
  end;
end;

function TAIRAG.LoadIndex(const AGraphFileName: string; const ATrainingFileName: string): Boolean;
var
  TrainFile: string;
begin
  Result := False;
  ClearError;

  if not Assigned(FGraphMap) then
  begin
    SetError('Componente TAIGraphMap nao associado.');
    DoLog('[ERRO LOADINDEX] Componente TAIGraphMap não associado.');
    Exit;
  end;

  try
    TrainFile := ATrainingFileName;
    if TrainFile = '' then
      TrainFile := ChangeFileExt(AGraphFileName, '.json');

    if FileExists(TrainFile) then
      FGraphMap.LoadTrainingFromFile(TrainFile);

    if FileExists(AGraphFileName) then
      FGraphMap.LoadGraphFromFile(AGraphFileName);

    Result := True;
    FLastSuccess := True;
    DoLog('Índice RAG e grafo carregados com sucesso de: ' + AGraphFileName);
  except
    on E: Exception do
    begin
      SetError('Erro ao carregar indice RAG: ' + E.Message);
      DoLog('[EXCEÇÃO LOADINDEX] ' + E.Message);
      Result := False;
    end;
  end;
end;

end.
