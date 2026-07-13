# TAIGraphStructuralAdapter

## Finalidade

`TAIGraphStructuralAdapter` projeta um `TAIDependencyGraph` para um `TAIGraphMap` compatível com o `TAIGraphVisualizer` já existente.

Ele é um adaptador, não uma refatoração do visualizer.

## O que não faz

O adaptador não altera `TAIGraphVisualizer`, não reescreve o formato de exportação e não substitui o grafo factual.

## Unit

```pascal
pacote/AI Graph/aigraphstructuraladapter.pas
```

## Pacote

```text
openai_graph.lpk
```

## Status

```text
Beta
```

## Propriedades principais

| Propriedade | Tipo | Descrição |
|---|---|---|
| `DependencyGraph` | `TAIDependencyGraph` | Grafo factual de entrada |
| `GraphMap` | `TAIGraphMap` | Projeção pronta para o visualizer |
| `LastError` | `string` | Último erro explícito |

## Métodos principais

| Método | Descrição |
|---|---|
| `Refresh` | Recria a projeção `TAIGraphMap` a partir do grafo factual |
| `AttachToVisualizer` | Associa a projeção ao `TAIGraphVisualizer` atual |

## Exemplo

```pascal
var
  G: TAIDependencyGraph;
  Adapter: TAIGraphStructuralAdapter;
begin
  G := TAIDependencyGraph.Create(nil);
  Adapter := TAIGraphStructuralAdapter.Create(nil);
  try
    Adapter.DependencyGraph := G;
    Adapter.Refresh;
    // Visualizer.GraphMap := Adapter.GraphMap;
  finally
    Adapter.Free;
    G.Free;
  end;
end;
```

## Limitações conhecidas

* A projeção depende da semântica atual de `TAIGraphMap`.
* A conversão preserva a estrutura dirigida, mas não substitui um grafo nativo genérico no visualizer.
* O adaptador precisa de um `TAIDependencyGraph` válido e factual para gerar saída útil.
