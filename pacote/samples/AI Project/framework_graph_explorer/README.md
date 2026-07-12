# AI Framework Graph Explorer — Núcleo Factual (M1–M2)

Implementação do recorte da **seção 16** da especificação: a primeira sessão,
entregue como **binário de console**.

## Por que console, e por que sem os pacotes `openai_*`

A especificação original faz o sample GUI depender de **seis pacotes** da suíte
(`openai_core`, `files`, `project`, `graph`, `agent`, `output`) — e a própria
tarefa **G001** admite que ainda não se sabe se eles compilam.

Este núcleo inverte a ordem:

- **Zero dependência** de `openai_*`, zero LCL. Só FPC (`fcl-xml`, `fpjson`, `fgl`).
- Compila com um comando `fpc`, sem instalar pacote na IDE.
- Roda hoje, contra o repositório real, e **produz o dado que decide o que cortar**.

Quando os fatos estiverem de pé, isto vira `TAIDependencyGraph` (em `openai_graph`)
e os parsers migram para `openai_files`. O sample GUI passa a ser uma **casca** em
volta de lógica já provada — em vez de nascer acoplado a seis pacotes não validados.

É o princípio nº 2 da própria especificação: **fato antes de inferência**.

## Compilar

```bash
mkdir -p build/units
fpc -Mobjfpc -Sh -O2 -Sew -Fusrc -FUbuild/units -obuild/fgxcli src/fgxcli.lpr
```

`-Sew` faz warnings virarem erro. Compila limpo em FPC 3.2.2.

## Rodar

```bash
./build/fgxcli <raiz-do-repositorio> [pasta-de-saida]
./build/fgxcli . output          # contra o próprio CHATGPT
```

Exit code `0` = grafo validado (PASS). `1` = FAIL. Sem sucesso artificial.

## O que já faz

| Tarefa | Item |
|---|---|
| G009–G011 | Varredura recursiva, exclusão de `lib`/`bin`/`.git`/`dist`, classificação por extensão |
| G012 | `inventory.json` |
| G015 | Parser determinista de `.lpk` (Name, Type, Files, UnitName, HasRegisterProc, RequiredPkgs) |
| G026 | LPK corrompido vira `partial` com motivo registrado — o pipeline **não para** |
| G028–G031 | Grafo genérico: IDs estáveis, dedupe, evidência e atributos por nó/aresta |
| G032/G033/G037 | Nós de `package` / `unit` / `external_dependency`; arestas `contains` e `requires_package` |
| G040 | Validação: arestas quebradas, sem evidência, auto-arestas, órfãos → PASS/FAIL |
| G043 | `graph.dot` (GraphViz) |
| — | `factual_graph.json` |
| E2 | Caminhos de nós e evidências relativos à raiz |
| E3–E5 | `uses`, classes públicas e `RegisterComponents`, sem aceitar texto de comentários/diretivas como fato |
| E6 | Nós `component` e arestas `declares`/`registers` com arquivo e linha |
| E7–E8 | Projetos em `pacote/samples/` e `demonstrated_by` somente com identificador comprovado |
| E9 | `stability_report.json`: componentes sem sample, units sem uso de entrada e dependências por pacote |

**Nenhum nó ou aresta existe sem evidência** (arquivo + parser de origem). A
validação rejeita o grafo se houver. A camada de IA não escreve aqui — o tipo
`Kind` é fixado em `factual` no `AddEdge`.

## Limites deliberados

- O parser é conservador e não substitui um compilador Pascal completo.
- Referências de unit não resolvidas são registradas como `unresolved`; nunca são
  promovidas a units internas sem evidência.
- Uso em sample é associação estática por identificador em `.pas`, `.lpr` ou
  `.lfm`; o relatório declara a possibilidade de falso positivo/negativo.
- Não gera IA, GUI, memória, PDF ou Word.

## Saídas

- `inventory.json`
- `factual_graph.json`
- `graph.dot`
- `stability_report.json`

## Fixtures

`fixtures/repo/` contém 3 LPK válidos, 1 **deliberadamente corrompido** e um
`lib/` que deve ser ignorado. É o teste do G026 e do G008.

Resultado esperado: 13 nós, 15 arestas, 1 pacote `partial`, validação **PASS**.

## CI

`.github/workflows/fgx-core.yml` compila em Ubuntu e Windows, roda contra a
fixture e contra o repositório real, e publica o grafo como artefato.

Este é o item que faltava: a partir dele, **qualquer pessoa sabe se o núcleo
compila hoje** — sem abrir o Lazarus.
