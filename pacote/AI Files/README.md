# 📁 Lazarus AI Suite — Aba `AI Files`

A pasta **AI Files** contém componentes para inventário de diretórios, varredura de arquivos e organização documental usada por recursos de RAG, datasets e análise estrutural de projetos.

## Componentes principais

- `TAIDiskTreeScanner` — percorre uma árvore de diretórios e produz uma representação estruturada dos arquivos encontrados;
- `TAI_DOCFILESMANAGER` — gerencia documentos e metadados usados por fluxos da suíte.

Consulte `pacote/COMPONENT_STATUS.md` para o estado de compilação e os samples associados.

## Uso com RAG

AI Files é responsável pela descoberta/organização dos arquivos. A extração, chunking, indexação e retrieval pertencem à área **AI RAG**.

O fluxo recomendado é separar responsabilidades:

1. AI Files localiza e organiza os documentos;
2. AI RAG extrai e divide o conteúdo;
3. o índice é construído;
4. o retriever seleciona os trechos relevantes;
5. `TCHATGPT` ou `TAIAgent` usa o contexto recuperado.

Veja `pacote/AI RAG/README.md` e `pacote/samples/AI RAG/rag_file_indexing_demo/`.

## Uso com análise de projetos

O sample `pacote/samples/AI Project/framework_graph_explorer/` combina `TAIDiskTreeScanner` com componentes de Graph/Project para mapear a estrutura real de um projeto antes de produzir análises ou tarefas automáticas.

## Segurança

Ao receber caminhos provenientes de IA ou de entrada do usuário, a aplicação host deve definir claramente a raiz permitida. Não use uma varredura de disco irrestrita como mecanismo de alteração de fontes.

Para agentes que precisam modificar arquivos, use as ações específicas de `aiagent_sourceactions.pas`, que aplicam confinamento a `WorkspaceRoot`, validação de caminho, backup e rollback.

## Compatibilidade

A enumeração de diretórios e arquivos é multiplataforma, mas nomes, permissões, links simbólicos, caminhos de rede e encoding podem variar entre Windows e Linux. O código consumidor deve tratar arquivos inacessíveis e diretórios ausentes como erros controlados.

## Idiomas

- [Português](README.pt.md)
- [English](README.en.md)
- [Español](README.es.md)
- [Français](README.fr.md)
- [Italiano](README.it.md)
- [العربية](README.ar.md)

As traduções devem manter os mesmos limites entre AI Files, AI RAG e AI Agent descritos nesta página.
