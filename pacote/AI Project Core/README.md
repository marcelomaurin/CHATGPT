# Lazarus AI Suite — `AI Project Core`

Pacote `openai_project_core` (somente FCL, sem LCL): núcleo leve de projetos, que compila no
console e serve de base tanto para os componentes visuais da aba **AI Project** quanto para
aplicações externas (por exemplo, o MultiProject da MultiSuite).

## Units

| Unit | O que oferece |
|---|---|
| `aiproject_core` | `TAIProject`, `TAIProjectStorage`, `TAIProjectTasks`, `TAITaskActions`: projeto/tarefas/revisões serializáveis em JSON |
| `aiprojectduration` | `TAIDuration`: duração no estilo do Microsoft Project (`30min`, `4h`, `2d`, `1sem`, decorrida `14eh`, estimada `4h?`), em minutos inteiros, sem depender da configuração regional |
| `aitaskgraph` | `TAITaskGraph`: grafo de tarefas com vínculos FS/SS/FF/SF (TI/II/TT/IT) e latência em duração ou %, recusa de ciclo com o caminho, ordem topológica determinística, cadeias (componentes conexos), relação em cadeia × em paralelo e a sintaxe da coluna Predecessoras (`T-0003TI+2h;T-0004II-10%`) |
| `aiundohistory` | `TAIUndoHistory`: desfazer/refazer por fotos do documento, com alterações aninhadas virando um único passo, limite de passos e suspensão durante a restauração |
| `aijsonutils` | Leitura tipada de campos com erro claro (`EAIJSONFormat`), `AIJSONMergeKnown` (gravar preservando campos desconhecidos e a ordem das chaves), datas ISO 8601 e `AISaveTextFileAtomic` (grava `.tmp`, valida e substitui) |

## Testes

```bash
cd tests
fpc -Fu"../pacote/AI Project Core" test_aiprojectcore_utils.lpr
./test_aiprojectcore_utils
fpc -Fu"../pacote/AI Project Core" test_aitaskgraph.lpr
./test_aitaskgraph
```

## Boas práticas

- Durações sempre em minutos inteiros. A unidade digitada serve só para exibição.
- Documentos versionados: leia com `AIJSON*` e grave com `AIJSONMergeKnown` sobre o objeto
  lido, para não perder campos de versões mais novas.
- Não persista credenciais em arquivos de projeto.
