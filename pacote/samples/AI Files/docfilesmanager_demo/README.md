# AI_DOCFILESMANAGER Demo

![AI_DOCFILESMANAGER Demo Screenshot](../../../../screenshots/docfilesmanager_demo.jpg)

Este exemplo demonstra o uso do componente `AI_DOCFILESMANAGER` no pacote **CHATGPT**.

## Objetivo

Organizar documentos em uma estrutura física de três níveis:

```text
StoragePath / Grupo / SubGrupo / Arquivo
```

O componente armazena as definições no arquivo manifest interno `docfilesmanager.json`.

## Funcionalidades demonstradas

- **Inicialização**: validação de permissões de leitura/escrita e criação da pasta base.
- **Grupos**: criar, excluir, listar e verificar a existência de grupos.
- **Subgrupos**: gerenciar pastas de subgrupos vinculadas a grupos.
- **Arquivos**: fazer upload de arquivos locais, carregá-los para um destino, listá-los e excluí-los.
- **GetDocument / GetFullDocument**: obter o nome ou caminho absoluto e seguro de um arquivo de documentação.
- **Segurança**: proteção contra ataques de Path Traversal (bloqueio de `..` e caminhos relativos maliciosos fora do StoragePath).

## Como testar

1. Compile e execute o projeto `docfilesmanager_demo.lpi`.
2. Configure um diretório em **Storage Path** (ou mantenha o padrão `.\storage_docs`).
3. Clique em **Initialize**.
4. Crie um grupo digitando o nome (ex: `BancoDados`) e clicando no botão **+** (Add Grupo).
5. Selecione o grupo criado na lista, digite um nome de subgrupo (ex: `PostgreSQL`) e clique em **+** (Add SubGrupo).
6. Selecione o subgrupo criado, clique em **Upload File** para enviar um arquivo de teste.
7. Use **Get Document** e **Get Full Document** no arquivo selecionado para ver o retorno de caminhos.
8. Verifique as mensagens e operações detalhadas no painel de **Log**.
