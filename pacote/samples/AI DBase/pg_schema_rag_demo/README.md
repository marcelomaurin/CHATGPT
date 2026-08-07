# PostgreSQL Schema RAG Demo (`pg_schema_rag_demo`)

Demonstração de **RAG sobre o esquema de um banco PostgreSQL**: em vez de despejar o dicionário de dados inteiro no prompt, o sample indexa cada tabela como um documento, recupera apenas as tabelas relevantes para a pergunta e envia só essas para a IA gerar o SQL.

Combina `TAIPostgreSQLDictionary` (extração de metadados), `TAIGraphMap` + `TAIRAG` (indexação e recuperação), `TCHATGPT` (geração) e ZeosLib (acesso).

## Por que isso existe

O sample `ai_sqlite_query_assistant_demo` já faz text-to-SQL, mas injeta `Dictionary.AsAIPrompt` **inteiro** no prompt. Isso funciona no banco de demonstração dele (7 tabelas) e se torna inviável em qualquer base de produção — estoura a janela de contexto e degrada a precisão do modelo.

Aqui o prompt cresce com o **Top K**, não com o tamanho do banco. Uma base de 700 tabelas gera o mesmo tamanho de prompt que uma de 20.

## Componentes utilizados

| Componente | Papel |
|---|---|
| `TAIPostgreSQLDictionary` | Lê tabelas, colunas, PKs, FKs, índices e views do catálogo |
| `TAIGraphMap` | Motor de indexação e ranqueamento por grafo de tokens |
| `TAIRAG` | Fatiamento, treino do índice, recuperação com score e persistência |
| `TCHATGPT` | Geração do SQL a partir do esquema recuperado |
| `TZConnection` / `TZQuery` / `TDataSource` / `TDBGrid` | Conexão e exibição do resultado |

## Não requer alteração no core

Este sample funciona com o repositório **como está hoje**. Nenhuma tarefa da Fase 0 do `TAIDBRAG` é pré-requisito.

Isso foi conseguido nomeando as fontes com **ponto** (`public.clientes`) em vez de barra (`schema/public.clientes`). `TAIRAG.NormalizeSourceName` aplica `ExtractFileName` no nome recebido, o que descartaria tudo antes de uma barra — mas um ponto atravessa intacto.

Quando a Fase 0 for aplicada, a nomenclatura hierárquica passa a ser possível e este sample continua funcionando sem mudança.

## Pré-requisitos

- **Lazarus 3.x / FPC 3.2.2**
- **ZeosLib** (`zcomponent`) instalado na IDE
- Pacotes do repositório instalados: `openai_core`, `openai_graph`, `openai_rag`, `openai_aidbase`
- **PostgreSQL 9.5+** acessível
- **Alvo x86_64** (definido no `.lpi`). O grafo é residente em memória; 32 bits limita desnecessariamente.
- **OpenSSL 3.x** no PATH ou na pasta do executável, para as chamadas HTTPS aos provedores de IA. As DLLs **não** são versionadas neste diretório.
- Biblioteca cliente do PostgreSQL (`libpq`) visível para o Zeos.

## Base de demonstração

```
createdb rag_demo
psql -d rag_demo -f sql/demo_schema.sql
```

O script cria 7 tabelas com nomes de coluna **deliberadamente abreviados** (`rz`, `dt_ref`, `vl_tot`, `mun_id`) e carrega o significado nos `COMMENT ON`. É esse o cenário que prova o valor do RAG de esquema: a pergunta *"faturamento por competência"* não casa com a string `dt_ref`, mas casa com o comentário `'Data de competência do faturamento, mês de referência contábil'`.

## Como usar

1. **Aba 1 — Conexão.** Preencha host, porta, database, usuário e senha. Use *Testar Conexão* e depois *Conectar*.
2. **Aba 2 — Dicionário.** Clique em *Gerar Dicionário de Dados*. A lista mostra as tabelas; clicar em uma exibe o texto exato que vai virar chunk.
3. **Aba 3 — Índice RAG.** Clique em *Construir Índice de Esquema*. Salve em disco se quiser reaproveitar.
4. **Aba 5 — Configuração IA.** Escolha provedor, informe a chave e o modelo.
5. **Aba 4 — Consulta.** Digite a pergunta.
   - *Recuperar Tabelas* mostra o que o RAG selecionou e com que score — **use este botão sozinho primeiro**, ele não gasta chamada de IA e é o melhor diagnóstico de qualidade.
   - *Gerar SQL com IA* monta o prompt só com as tabelas recuperadas.
   - *Executar SQL* valida, pede confirmação e executa.

### Perguntas de teste sugeridas

| Pergunta | Tabelas que devem ser recuperadas |
|---|---|
| Qual o faturamento por competência? | `notas_fiscais` |
| Quais clientes estão em Ribeirão Preto? | `clientes`, `municipios` |
| Quanto cada vendedor vendeu? | `notas_fiscais`, `vendedores` |
| Quais produtos da família Bebidas foram vendidos? | `produtos`, `fam_prod`, `itens_nf` |
| Qual o limite de crédito dos clientes inativos? | `clientes` |

## Detalhes de implementação

### Comentários do banco

`TAIPostgreSQLDictionary` **não preenche** o campo `Description` de tabelas, colunas e views — atribui string vazia. Como o comentário é o melhor sinal semântico para a recuperação, o sample busca os comentários por conta própria em `pg_class` / `pg_attribute` e os injeta no dicionário já carregado (método `EnriquecerComComentarios`, controlado pelo checkbox da aba 2).

Isso é um contorno, não a solução definitiva. A correção no componente é a tarefa **F0-13/14/15** do plano da Fase 0.

### Ligações explícitas entre tabelas

Quando várias tabelas são recuperadas, o prompt recebe um bloco `LIGACOES ENTRE AS TABELAS ACIMA:` com os pares de colunas de cada FK que conecta duas tabelas selecionadas. O modelo erra muito menos o `JOIN` quando o par vem escrito, em vez de precisar deduzi-lo dos nomes.

### Segurança

Este sample executa SQL produzido por um modelo de linguagem. As defesas implementadas:

1. **Validação léxica** — o comando precisa começar com `SELECT` ou `WITH`; palavras-chave de escrita e DDL são rejeitadas por comparação de palavra inteira (para que uma coluna chamada `created_at` não dispare a proibição de `CREATE`); múltiplos comandos e comentários SQL são bloqueados.
2. **Confirmação obrigatória** — o SQL é exibido e precisa ser aprovado antes de rodar.
3. **`SET statement_timeout = 30000`** antes de cada execução.
4. **SQL editável** — o memo permite revisar e corrigir antes de executar.

> **Use uma role somente-leitura do PostgreSQL.** A validação em código é defesa secundária. A defesa primária é a permissão no banco.

### Persistência

- Configurações: `GetAppConfigDir(False)` + `pg_schema_rag_demo.ini`
  - Windows: `C:\Users\<usuário>\AppData\Local\pg_schema_rag_demo\`
  - Linux: `~/.config/pg_schema_rag_demo/`
- A senha do banco **só é gravada** se o checkbox correspondente estiver marcado. Mesmo assim, fica em texto plano — é um sample.
- Índice: `.bin` (grafo) + `.json` (chunks), via `TAIRAG.SaveIndex`.

> O índice reflete o esquema no momento em que foi salvo. Se o DDL mudou depois, gere o dicionário e reconstrua.

## Limitações conhecidas

- `TAIDBDataDictionary.Tables.FindTable` localiza por nome de tabela **sem** o esquema. Bases com o mesmo nome de tabela em esquemas diferentes podem casar errado no enriquecimento de comentários. Mantenha um esquema por vez no campo *Schema*.
- Toda a recuperação e a chamada de IA rodam na thread principal. A UI mostra ampulheta e desabilita os botões, mas fica bloqueada durante a chamada.
- Só o RAG de **esquema** está implementado aqui. O RAG de **conteúdo** (linhas viram chunks) faz parte da especificação do `TAIDBRAG` e não está neste sample.
- Sem modo simulado, mock ou dado fictício em nenhum caminho de código.
