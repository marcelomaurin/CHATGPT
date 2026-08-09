program hybrid_retrieval_demo;

{$mode objfpc}{$H+}
{$APPTYPE CONSOLE}

uses
  Interfaces, Classes, SysUtils, aigraphmap, airetrieval, airag;

var
  Owner: TComponent;
  Graph: TAIGraphMap;
  Embedder: TAILocalEmbeddingProvider;
  Store: TAIVectorStore;
  VectorRetriever: TAIVectorRetriever;
  BM25: TAIBM25Retriever;
  RAG: TAIRAG;
  Results: TStringList;
  I: Integer;
  Item: TAIRetrievalResult;
begin
  Owner := TComponent.Create(nil);
  Results := TStringList.Create;
  try
    Graph := TAIGraphMap.Create(Owner);
    Embedder := TAILocalEmbeddingProvider.Create(Owner);
    Store := TAIVectorStore.Create(Owner);
    VectorRetriever := TAIVectorRetriever.Create(Owner);
    VectorRetriever.EmbeddingProvider := Embedder;
    VectorRetriever.VectorStore := Store;
    BM25 := TAIBM25Retriever.Create(Owner);
    RAG := TAIRAG.Create(Owner);
    RAG.GraphMap := Graph;
    RAG.VectorRetriever := VectorRetriever;
    RAG.BM25Retriever := BM25;
    RAG.RetrievalMode := rrmHybrid;
    RAG.TopK := 3;

    RAG.AddText('lazarus.txt',
      'Lazarus cria aplicativos nativos usando o compilador Free Pascal.');
    RAG.AddText('python.txt',
      'Python executa codigo por um interpretador e oferece ambientes virtuais.');
    RAG.AddText('postgresql.txt',
      'PostgreSQL e um banco relacional com transacoes e indices SQL.');
    if not RAG.BuildIndex then
      raise Exception.Create(RAG.LastError);
    if not RAG.Retrieve('Qual compilador o Lazarus usa?', Results) then
      raise Exception.Create(RAG.LastError);

    Writeln('Resultados combinados por Reciprocal Rank Fusion:');
    for I := 0 to Results.Count - 1 do
    begin
      Item := TAIRetrievalResult(Results.Objects[I]);
      Writeln(Format('%d. %s (%.5f): %s',
        [I + 1, Item.Source, Item.Score, Item.Text]));
    end;
  finally
    FreeRetrievalResults(Results);
    Results.Free;
    Owner.Free;
  end;
end.
