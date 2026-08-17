# Documentação Técnica — Lazarus AI Suite

Esta pasta contém a documentação técnica da suíte CHATGPT para Lazarus/Free Pascal. Ela complementa o `README.md`, o `INSTALL.md`, os READMEs de cada pasta em `pacote/` e os samples.

## Onde procurar cada informação

| Área | Caminho | Conteúdo |
|---|---|---|
| Visão geral | [`../README.md`](../README.md) | Objetivo da suíte, pacotes e estado geral |
| Instalação | [`../INSTALL.md`](../INSTALL.md) | Instalação e dependências |
| Componentes | [`components/`](components/) | Referência individual por componente |
| Pacotes Lazarus | [`../pacote/packages/README.md`](../pacote/packages/README.md) | Organização dos `.lpk`, dependências e runtime/design-time |
| Status | [`../pacote/COMPONENT_STATUS.md`](../pacote/COMPONENT_STATUS.md) | Maturidade e evidências por sample |
| Samples | [`../pacote/samples/`](../pacote/samples/) | Projetos executáveis de demonstração |
| RAG | [`../pacote/AI RAG/README.md`](../pacote/AI%20RAG/README.md) | Indexação, retrieval, BM25, vetores e Agent + RAG |
| Agent | [`../pacote/AI Agent/README.pt.md`](../pacote/AI%20Agent/README.pt.md) | Agentes, tools, graph, guardrails e source actions |
| Source actions | [`components/TAISourceActions/README.md`](components/TAISourceActions/README.md) | Alteração segura de fontes, build, verificação e rollback |
| Runtime | [`RUNTIME_ARCHITECTURE.md`](RUNTIME_ARCHITECTURE.md) | Organização de runtimes nativos |
| Runtime Linux ARM | [`RUNTIME_LINUX_ARM.md`](RUNTIME_LINUX_ARM.md) | Particularidades ARM |
| Runtime Ubuntu x64 | [`RUNTIME_UBUNTU_X64.md`](RUNTIME_UBUNTU_X64.md) | Particularidades Linux x64 |
| OpenCV | [`OPENCV_RUNTIME_SPEC.md`](OPENCV_RUNTIME_SPEC.md) | Contrato de runtime OpenCV |
| Compatibilidade | [`COMPATIBILIDADE.md`](COMPATIBILIDADE.md) | Plataformas e restrições |

## Referência por componente

Cada componente documentado deve possuir:

```text
DOC/components/<NomeDoComponente>/README.md
```

A referência deve informar, quando aplicável:

- finalidade;
- package Lazarus;
- unit de origem;
- status de maturidade;
- propriedades principais;
- métodos principais;
- dependências externas;
- sample de referência;
- limitações de plataforma/runtime;
- exemplo mínimo de uso.

O índice `DOC/components/README.md` deve ser usado como catálogo dos componentes já documentados.

## Áreas principais

### Core e projeto

Inclui `TCHATGPT`, base de componentes, prompts, registro de modelos, projeto, tasks, storage e pipeline.

### Agent

Inclui `TAIAgent`, classifier, decision, action builder, executor, memory map, tools, graph, safety/guardrails e ações de manutenção de fontes.

As ações de fontes devem permanecer confinadas a `WorkspaceRoot`; executáveis de build/teste/verificação são escolhidos pela aplicação host, nunca pelo LLM.

### RAG

Inclui `TAIRAG`, `IAIRAGProvider`, recuperação por grafo, BM25, vetores, rank fusion e reranking. A documentação deve distinguir claramente índice em memória de persistência durável.

### Input, Vision e Voice

Componentes ligados a dispositivos, câmera, OpenCV, serial, USB, rede, áudio e voz dependem do runtime real da plataforma. Um sample compilando não comprova automaticamente a presença de DLLs, drivers, dispositivos ou serviços externos.

### Output

Inclui saída textual, JSON, PDF, Word/OpenXML, Excel e viewers.

### Graph, ML e Simulation

Inclui grafos, datasets, redes neurais, matemática e componentes de simulação.

### Graphic / 3D

Inclui visualização 3D, cenas, avatares, esqueleto, física e integrações externas de geração de modelo.

## Regra para status

A documentação não deve declarar um componente como totalmente funcional apenas porque ele está registrado na paleta ou porque um projeto compilou. Diferencie:

- compilação do package;
- compilação do sample;
- execução em runtime;
- validação com hardware/API/modelo externo.

Use `pacote/COMPONENT_STATUS.md` como fonte central de status e atualize-o quando a evidência mudar.

## Runtime x design-time

Units que existem apenas para `Register`, ícones de paleta ou integração com o IDE devem ficar separadas do runtime sempre que possível. Essa regra evita que aplicações console, serviços e CI dependam desnecessariamente de `LazarusPackageIntf`, `LResources` ou outras units de design-time.

## Segurança e credenciais

Tokens, chaves e senhas não devem ser gravados em samples, `.lfm`, documentação ou arquivos versionados. Componentes com propriedades de credencial devem preferir configuração em runtime e `stored False` quando a propriedade não deve ser serializada.

## Manutenção desta documentação

Ao alterar uma unit pública, faça a revisão nesta ordem:

1. README da pasta do componente em `pacote/`;
2. `DOC/components/<Componente>/README.md`;
3. sample relacionado;
4. `pacote/COMPONENT_STATUS.md` se houver mudança de maturidade;
5. `README.md`/`INSTALL.md` quando a alteração afetar instalação ou arquitetura geral.

Documentos históricos e especificações antigas devem ser claramente marcados como históricos quando não representarem mais o comportamento atual.
