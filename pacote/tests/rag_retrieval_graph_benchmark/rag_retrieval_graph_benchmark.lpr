program rag_retrieval_graph_benchmark;

{$mode objfpc}{$H+}
{$APPTYPE CONSOLE}

uses
  Interfaces, Classes, SysUtils, aigraphmap, airetrieval, airag;

procedure Fail(const AMessage: string);
begin
  Writeln(StdErr, 'FAIL: ', AMessage);
  Halt(1);
end;

procedure Check(ACondition: Boolean; const AMessage: string);
begin
  if not ACondition then Fail(AMessage);
end;

function ResultAt(AResults: TStrings; AIndex: Integer): TAIRetrievalResult;
begin
  Result := TAIRetrievalResult(AResults.Objects[AIndex]);
end;

procedure CheckAdjacency(AGraph: TAIGraphMap; const AStage: string);
var
  I, IndexedEdges: Integer;
  Node: TAIGraphNode;
begin
  IndexedEdges := 0;
  for I := 0 to AGraph.Nodes.Count - 1 do
  begin
    Node := TAIGraphNode(AGraph.Nodes[I]);
    Inc(IndexedEdges, AGraph.AdjacentEdgeCount(Node.Id));
  end;
  Check(IndexedEdges = AGraph.EdgeCount,
    Format('%s: indice de adjacencia tem %d arestas, grafo tem %d',
      [AStage, IndexedEdges, AGraph.EdgeCount]));
end;

procedure AddResult(AResults: TStrings; const AID, AText: string;
  AScore: Double);
var
  Item: TAIRetrievalResult;
begin
  Item := TAIRetrievalResult.Create;
  Item.ChunkID := AID;
  Item.Source := 'budget';
  Item.Text := AText;
  Item.Score := AScore;
  AResults.AddObject(AID, Item);
end;

procedure TestRetrievalAndIndices;
var
  Owner: TComponent;
  Graph, LoadedGraph, TieGraph: TAIGraphMap;
  Embedder: TAILocalEmbeddingProvider;
  Store: TAIVectorStore;
  VectorRetriever: TAIVectorRetriever;
  BM25: TAIBM25Retriever;
  RAG: TAIRAG;
  Results, Ranking: TStringList;
  V1, V2, V3: TAIDoubleArray;
  TempFile, FirstRanking: string;
  I: Integer;
begin
  Owner := TComponent.Create(nil);
  Results := TStringList.Create;
  Ranking := TStringList.Create;
  TempFile := IncludeTrailingPathDelimiter(GetTempDir(False)) +
    'chatgpt_graph_index_' + IntToStr(GetTickCount64) + '.json';
  try
    Graph := TAIGraphMap.Create(Owner);
    LoadedGraph := TAIGraphMap.Create(Owner);
    TieGraph := TAIGraphMap.Create(Owner);
    Embedder := TAILocalEmbeddingProvider.Create(Owner);
    Embedder.Dimension := 64;
    Store := TAIVectorStore.Create(Owner);
    VectorRetriever := TAIVectorRetriever.Create(Owner);
    VectorRetriever.EmbeddingProvider := Embedder;
    VectorRetriever.VectorStore := Store;
    BM25 := TAIBM25Retriever.Create(Owner);
    RAG := TAIRAG.Create(Owner);
    RAG.GraphMap := Graph;
    RAG.VectorRetriever := VectorRetriever;
    RAG.BM25Retriever := BM25;
    RAG.ChunkSize := 400;
    RAG.ChunkOverlap := 40;
    RAG.TopK := 3;

    Check(Embedder.Embed('lazarus free pascal componentes visuais', V1),
      'embedding local falhou');
    Check(Embedder.Embed('lazarus free pascal componentes visuais', V2),
      'segundo embedding local falhou');
    Check(Embedder.Embed('receita cozinha massa tomate', V3),
      'terceiro embedding local falhou');
    Check(Length(V1) = 64, 'dimensao configurada do embedding nao respeitada');
    Check(CosineSimilarity(V1, V2) > 0.9999,
      'embedding deterministico nao e identico');
    Check(CosineSimilarity(V1, V3) < CosineSimilarity(V1, V2),
      'similaridade cosseno nao distingue textos');

    Check(RAG.AddText('pascal.txt',
      'Lazarus utiliza o compilador Free Pascal para criar aplicativos nativos. ' +
      'Componentes visuais podem ser instalados em pacotes LPK.') = 1,
      'documento Pascal nao foi adicionado');
    Check(RAG.AddText('python.txt',
      'Python usa interpretador e bibliotecas de ciencia de dados. ' +
      'Ambientes virtuais isolam dependencias do projeto.') = 1,
      'documento Python nao foi adicionado');
    Check(RAG.AddText('database.txt',
      'PostgreSQL armazena dados relacionais e oferece indices SQL. ' +
      'Transacoes preservam consistencia dos registros.') = 1,
      'documento de banco nao foi adicionado');
    Check(Store.Count = 3, 'vector store nao recebeu os chunks do RAG');
    Check(RAG.BuildIndex, 'BuildIndex falhou: ' + RAG.LastError);
    Check(Graph.NodeCount > 0, 'grafo sem nos apos BuildIndex');
    Check(Graph.EdgeCount > 0, 'grafo sem arestas apos BuildIndex');
    CheckAdjacency(Graph, 'apos treino');

    Check(VectorRetriever.Retrieve('compilador pascal lazarus', 2, Results),
      'busca vetorial falhou');
    Check(Pos('pascal', LowerCase(ResultAt(Results, 0).Source)) > 0,
      'busca vetorial nao priorizou o documento Pascal');
    FreeRetrievalResults(Results);

    Check(BM25.Retrieve('compilador free pascal lazarus', 2, Results),
      'busca BM25 falhou');
    Check(Pos('pascal', LowerCase(ResultAt(Results, 0).Source)) > 0,
      'BM25 nao priorizou o documento Pascal');
    FreeRetrievalResults(Results);

    RAG.RetrievalMode := rrmHybrid;
    RAG.ContextTokenBudget := 300;
    Check(RAG.Retrieve('Qual compilador e usado pelo Lazarus?', Results),
      'recuperacao hibrida falhou: ' + RAG.LastError);
    Check(Results.Count > 0, 'RRF hibrido nao retornou resultados');
    Check(Pos('Free Pascal', ResultAt(Results, 0).Text) > 0,
      'RRF hibrido nao colocou o contexto esperado no topo');
    FreeRetrievalResults(Results);

    AddResult(Results, 'a', StringOfChar('a', 80), 1.0);
    AddResult(Results, 'b', StringOfChar('b', 80), 0.5);
    ApplyTokenBudget(Results, 25);
    Check(Results.Count = 1, 'orcamento de tokens nao limitou o contexto');
    FreeRetrievalResults(Results);

    RAG.ReindexChunks;
    Check(Pos('Lazarus', RAG.FindChunkText('rag:pascal.txt#000001')) > 0,
      'indice de chunk nao resolveu o texto');

    Graph.SaveGraphToFile(TempFile);
    LoadedGraph.LoadGraphFromFile(TempFile);
    Check(LoadedGraph.EdgeCount = Graph.EdgeCount,
      'persistencia alterou a quantidade de arestas');
    CheckAdjacency(LoadedGraph, 'apos recarga');

    TieGraph.TrainItem('mesmos tokens compartilhados', 'categoria_b', 1.0);
    TieGraph.TrainItem('mesmos tokens compartilhados', 'categoria_a', 1.0);
    TieGraph.PredictRanking('mesmos tokens compartilhados', Ranking);
    Check(Ranking.Count = 2, 'ranking de empate incompleto');
    FirstRanking := Ranking.Text;
    for I := 1 to 50 do
    begin
      Ranking.Clear;
      TieGraph.PredictRanking('mesmos tokens compartilhados', Ranking);
      Check(Ranking.Text = FirstRanking, 'ranking nao deterministico');
    end;
    Check(Pos('categoria_a=', Ranking[0]) = 1,
      'desempate alfabetico deterministico nao aplicado');
  finally
    FreeRetrievalResults(Results);
    Ranking.Free;
    Results.Free;
    Owner.Free;
    if FileExists(TempFile) then DeleteFile(TempFile);
  end;
end;

procedure RunGraphBenchmark;
const
  DocumentCount = 40;
  QueryCount = 100;
var
  Graph: TAIGraphMap;
  Ranking: TStringList;
  I: Integer;
  Started, Elapsed: QWord;
  QueriesPerSecond: Double;
begin
  Graph := TAIGraphMap.Create(nil);
  Ranking := TStringList.Create;
  try
    for I := 0 to DocumentCount - 1 do
      Graph.TrainItem(Format('termo%d grupo%d linguagem pascal componente',
        [I, I mod 25]), Format('categoria_%.4d', [I]), 1.0);
    CheckAdjacency(Graph, 'benchmark');
    Started := GetTickCount64;
    for I := 0 to QueryCount - 1 do
    begin
      Ranking.Clear;
      Graph.PredictRanking(Format('termo%d linguagem pascal',
        [I mod DocumentCount]), Ranking);
      Check(Ranking.Count > 0, 'benchmark produziu ranking vazio');
    end;
    Elapsed := GetTickCount64 - Started;
    if Elapsed = 0 then Elapsed := 1;
    QueriesPerSecond := QueryCount * 1000.0 / Elapsed;
    Writeln(Format('BENCHMARK graph nodes=%d edges=%d queries=%d elapsed_ms=%d qps=%.2f',
      [Graph.NodeCount, Graph.EdgeCount, QueryCount, Elapsed, QueriesPerSecond]));
  finally
    Ranking.Free;
    Graph.Free;
  end;
end;

begin
  TestRetrievalAndIndices;
  RunGraphBenchmark;
  Writeln('PASS: embeddings, vector store, BM25, RRF, token budget, chunk/adjacency indices, persistence and deterministic ranking');
end.
