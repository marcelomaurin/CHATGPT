# AI Framework Graph Explorer

Aplicacao Lazarus que analisa o proprio repositorio da suite, constroi um grafo
factual de sua arquitetura e usa IA opcionalmente para interpretar os fatos.

## O que a interface entrega

- **Projeto:** escolhe a raiz e executa a analise completa.
- **Inventario:** arvore produzida pelo `TAIDiskTreeScanner` e contadores por tipo.
- **Pacotes:** pacotes `.lpk` e suas dependencias internas e externas.
- **Componentes:** componentes registrados, pacote de origem, paleta e samples que
  comprovadamente usam cada componente. Componentes sem sample aparecem como orfaos.
- **Samples:** projetos `.lpi`, componentes usados e resultado real do `lazbuild`.
  Um sample compilado pode ser aberto para validacao visual.
- **Analise IA:** recomendacoes geradas pelo `TCHATGPT` a partir do grafo pronto.
- **Setup:** tipo de provedor, modelo, endpoint, token, caminhos do `lazbuild` e
  do FPC e diretorio isolado de compilacao.
- **Log:** etapas e resultados `PASS`, `FAIL` e `SKIPPED`.
- **Relatorio final:** resumo e evidencias consolidadas em um arquivo TXT.
- **Historico:** snapshots comparaveis que denunciam componentes, pacotes ou
  samples desaparecidos e regressao de build.

## Pipeline em etapas

O botao **Analyze project** executa dez etapas visiveis e independentes:

1. Inventario do disco.
2. Pacotes e units.
3. Dependencias entre pacotes.
4. Tokenizacao Pascal e componentes.
5. Cobertura dos componentes por samples.
6. Validacao do grafo factual.
7. Compilacao dos samples.
8. Analise opcional por IA.
9. Relatorio factual final.
10. Relatorio de IA com `Where`, `What` e recomendacao.

Cada etapa termina como `PASS`, `FAIL`, `PARTIAL`, `CANCELLED` ou `SKIPPED`.
As opcoes **Compilar samples** e **Executar analise IA** permitem controlar as
duas etapas demoradas. Elas ficam habilitadas por padrao na interface.

## Separacao entre fatos e IA

A descoberta nao depende de rede nem token. Os parsers leem os `.lpk`, tokenizam
Pascal, localizam `uses`, classes e `RegisterComponents`, identificam os projetos
de sample e cruzam os identificadores encontrados. Esses fatos alimentam o
`TAIDependencyGraph` com evidencia de arquivo, linha e parser.

A IA nunca decide se um pacote, componente, dependencia ou sample existe. Ela
recebe somente um resumo do grafo factual validado e produz recomendacoes em uma
aba separada. Se o setup estiver em **Offline**, a etapa de IA fica `SKIPPED` e
todo o restante continua funcionando.

Os achados sao produzidos por regras deterministicas em `fgx_findings.pas`.
`Where`, `What`, tipo, severidade e causa-raiz ficam bloqueados. A IA recebe os
achados em lotes pequenos e preenche somente a recomendacao, isto e, o **How**.

## Setup

### IA

Provedores suportados pelo componente `TCHATGPT`:

- OpenAI
- OpenRouter
- Cerebras
- Ollama/local
- Google Gemini
- Anthropic Claude

O token, o modelo e o endpoint sao salvos somente quando o usuario pressiona
**Save setup**. O token fica no arquivo de configuracao do perfil do usuario e
nunca e gravado nos artefatos do repositorio.

### Toolchain Lazarus

Antes de compilar os samples, configure na mesma aba:

- **Lazarus directory:** diretorio de instalacao do Lazarus que contem o
  `lazbuild.exe` no Windows ou `lazbuild` no Linux.
- **FPC compiler:** caminho completo do `fpc.exe` usado pelo Lazarus.
- **Build output:** pasta externa onde as compilacoes de validacao serao geradas.

O botao **Auto-detect** procura uma instalacao local do Lazarus, inclusive em
`C:\lazarus`. O botao **Test toolchain** executa `fpc -iV` e
`lazbuild --version`; somente codigo de saida zero produz `PASS`. Use **Save
setup** para manter os caminhos no proximo uso. O arquivo
`framework_graph_explorer.ini` fica em `%APPDATA%\AIFrameworkGraphExplorer` no
Windows e em `~/.framework_graph_explorer` no Linux. No Linux, o arquivo recebe
permissao `0600`, limitada ao usuario atual.

## Compilar

Instale os pacotes da suite e execute:

```powershell
C:\lazarus\lazbuild.exe --build-all --ws=win32 --compiler=C:\lazarus\fpc\3.2.2\bin\i386-win32\fpc.exe framework_graph_explorer.lpi
```

O projeto requer `openai_core`, `openai_files`, `openai_graph` e `LCL`.

## Executar

Abra o executavel e selecione a raiz do repositorio. Tambem e possivel informar
a raiz na linha de comando para iniciar a analise automaticamente:

```powershell
framework_graph_explorer.exe D:\projetos\maurinsoft\CHATGPT
```

### Gate headless

Para CI ou automacao, use:

```powershell
framework_graph_explorer.exe --headless --root D:\projetos\maurinsoft\CHATGPT --no-ai
```

Opcoes:

- `--no-build`: pula a compilacao dos samples.
- `--ai`: solicita a analise por IA; sem token, a etapa fica `SKIPPED`.
- `--no-ai`: nunca acessa a rede.

Codigos de saida:

- `0`: grafo valido, sem build FAIL e sem regressao temporal.
- `1`: validacao, build ou comparacao temporal falhou.
- `2`: raiz invalida ou execucao cancelada.

## Artefatos

Depois da analise, a pasta do executavel recebe:

- `inventory.json`
- `factual_graph.json`
- `graph.dot`
- `graph.mmd`
- `framework_graph_report.txt`
- `DOC/fgx/history/<timestamp>.json`

Esses arquivos sao resultados de execucao e estao ignorados pelo Git.

O relatorio final inclui a situacao de cada etapa, contagens do grafo, todas as
dependencias de pacote, componentes orfaos, relacao componente/sample, resultado
de cada compilacao e a resposta da IA quando ela tiver sido executada. Se alguma
etapa opcional nao rodar, o resultado global aparece como `PARTIAL`, nunca como
`PASS` artificial.

## Limites honestos

- `PASS` em um sample significa que o `lazbuild` terminou com exit code zero.
- Samples GUI precisam ser abertos pelo botao para validacao visual; iniciar o
  processo e registrado como `ABERTO`, nao como teste automatizado de comportamento.
- O parser Pascal e conservador e nao substitui o compilador.
- Dependencias nao resolvidas sao mantidas como `external_dependency`.
- Nenhum achado remove arquivos. Desaparecimentos apenas geram evidencia e
  codigo de saida diferente de zero.
