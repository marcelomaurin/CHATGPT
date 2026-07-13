# TAIDependencyGraph

## Finalidade

`TAIDependencyGraph` é o núcleo factual da futura camada `TAIDependencyGraph` da suíte.

Ele mantém nós e arestas tipados, exige evidência em nós e arestas factuais, separa arestas inferidas em coleção própria e exporta o grafo para JSON, DOT e Mermaid.

## O que não faz

`TAIDependencyGraph` não treina modelos, não classifica texto, não inventa símbolos ausentes e não mistura fato com hipótese.

## Unit

```pascal
pacote/AI Graph/aidependencygraph.pas
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
| `NodeCount` | `Integer` | Quantidade de nós factuais |
| `EdgeCount` | `Integer` | Quantidade de arestas factuais |
| `Validated` | `Boolean` | Indica se a última validação factual passou |
| `LastError` | `string` | Último erro explícito |

## Métodos principais

| Método | Descrição |
|---|---|
| `AddNode` | Adiciona um nó factual com evidência obrigatória |
| `AddEdge` | Adiciona uma aresta factual com `Kind = factual` |
| `AddInferredEdge` | Registra uma hipótese em coleção separada |
| `FindNode` | Localiza nó por ID estável |
| `Clear` | Limpa o grafo |
| `Validate` | Verifica arestas quebradas, ausência de evidência, auto-arestas e órfãos |
| `CountNodesOfType` | Conta nós por tipo |
| `CountEdgesOfType` | Conta arestas factuais por tipo |
| `SaveToJSON` | Exporta JSON factual com seção separada de inferência |
| `LoadFromJSON` | Carrega JSON factual e rejeita arquivos vazios, inválidos ou inconsistentes |
| `SaveToDOT` | Exporta GraphViz DOT |
| `SaveToMermaid` | Exporta Mermaid |

## Exemplo

```pascal
var
  G: TAIDependencyGraph;
  Ev: TAIDependencyEvidence;
begin
  G := TAIDependencyGraph.Create(nil);
  try
    Ev := MakeAIDependencyEvidence('pacote/packages/openai_core.lpk', 0, 'fgx_lpk');
    G.AddNode('package:openai_core', 'package', 'openai_core', 'pacote/packages/openai_core.lpk', Ev);
    G.AddNode('unit:chatgpt', 'unit', 'chatgpt', 'pacote/AI/chatgpt.pas', Ev);
    G.AddEdge('package:openai_core', 'unit:chatgpt', 'contains', Ev);
    G.Validate;
    G.SaveToJSON('grafo.json');
  finally
    G.Free;
  end;
end;
```

## Limitações conhecidas

* A validação factual considera apenas arestas factuais.
* A coleção `InferredEdges` é separada por design e não entra como fato.
* O componente exige evidência explícita; entradas vazias devem ser rejeitadas ou marcadas como inválidas.
* O visualizer atual continua acoplado ao `TAIGraphMap`; a projeção estrutural depende do adaptador.
