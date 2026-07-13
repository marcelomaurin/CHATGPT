# Lazarus AI Suite - Package Index

Esta pasta reúne os pacotes modulares, samples, documentação e utilitários da suíte Lazarus AI.
O objetivo é manter a instalação previsível: cada área fica isolada, mas continua integrável com o `openai_core`.

## Estrutura

```text
pacote/
  AI/                 # núcleo e utilitários gerais
  AI Agent/           # agentes, tarefas e automação
  AI Agents/          # variação/legado de agentes
  AI DBase/           # dicionários e metadados de bancos
  AI Files/           # scanner e gerenciamento de arquivos
  AI Filtros Sonoros/ # filtros sonoros
  AI Graph/           # grafos, datasets e relatórios
  AI Graphic/         # 3D, avatar e cena
  AI Hardware/        # CPU, memória, GPU, disco, SO, tarefas e impressoras
  AI Image/           # filtros simples de imagem
  AI Industrial/      # Modbus, MQTT e integrações industriais
  AI Input/           # entrada de dados e integração com dispositivos
  AI Math/            # matemática, matrizes e estatística
  AI Output/          # documentos, relatórios e saídas
  AI Project/         # gestão de projetos, tarefas e pipelines
  AI Schedule/        # agenda e programação
  AI Simulation/      # simulação 2D
  AI Vision/          # visão computacional
  AI Voice/           # voz, áudio e síntese
  DOC/                # documentação técnica
  packages/           # pacotes Lazarus
  python/             # workers e scripts auxiliares
  samples/            # demonstrações
```

## Pacotes recomendados

| Pacote | Função | Observação |
|---|---|---|
| `openai_core.lpk` | Base comum da suíte, prompt builder, modelos e infraestrutura principal. | Essencial |
| `openai_hardware.lpk` | Componentes de CPU, memória, GPU, disco, sistema operacional, tarefas e impressoras. | Recuperado |
| `openai_dbase.lpk` | `TAIDBase`, memória local, histórico e dataset básico em banco. | Recuperado |
| `openai_aidbase.lpk` | Dicionários de metadados de banco e exportadores. | Recuperado |
| `openai_ml.lpk` | Matrizes, estatística e aprendizado simples. | Opcional |
| `openai_files.lpk` | Scanner de diretórios e gerenciamento físico de arquivos. | Opcional |
| `openai_output.lpk` | Saídas, documentos e relatórios. | Opcional |
| `openai_input.lpk` | Entrada de dados e integrações de captura. | Opcional |
| `openai_python.lpk` | Integração com runtime Python. | Opcional |
| `openai_image.lpk` | Filtros de imagem nativos. | Opcional |
| `openai_graph.lpk` | Grafos, análise e relatórios. | Opcional |
| `openai_graphic.lpk` | Visualização 3D e cenas. | Opcional |
| `openai_vision.lpk` | Visão computacional e backends de câmera. | Opcional |
| `openai_voice.lpk` | Áudio, voz e filtros sonoros. | Opcional |
| `openai_simulation.lpk` | Simulação e comportamento em grade. | Opcional |
| `openai_project.lpk` | Ferramentas de projeto, tarefas e pipeline. | Opcional |
| `openai_agent.lpk` | Agentes, regras, segurança e automação. | Beta |
| `openai_industrial.lpk` | Integrações industriais. | Experimental |

## Dependências externas

- `openai_core` depende de `zcomponent` e `turbopoweripro`.
- `openai_input` depende de `cef4delphi_lazarus`.
- `openai_dbase` e `openai_aidbase` dependem de `zcomponent`.
- Alguns módulos de visão, Python e industrial podem exigir bibliotecas externas adicionais no sistema.

## Ordem de instalação sugerida

1. Dependências externas: `zcomponent`, `turbopoweripro`, `cef4delphi_lazarus`
2. `packages/openai_core.lpk`
3. `packages/openai_hardware.lpk`
4. `packages/openai_dbase.lpk`
5. `packages/openai_aidbase.lpk`
6. `packages/openai_ml.lpk`
7. `packages/openai_files.lpk`
8. `packages/openai_output.lpk`
9. `packages/openai_input.lpk`
10. `packages/openai_python.lpk`
11. `packages/openai_image.lpk`
12. `packages/openai_graph.lpk`
13. `packages/openai_graphic.lpk`
14. `packages/openai_vision.lpk`
15. `packages/openai_voice.lpk`
16. `packages/openai_simulation.lpk`
17. `packages/openai_project.lpk`
18. `packages/openai_agent.lpk`
19. `packages/openai_industrial.lpk`

## Samples

Os samples ficam em `samples/` e servem como prova de uso real dos componentes.
Os diretórios mais úteis hoje incluem:

- `samples/AI Hardware/`
- `samples/AI DBase/`
- `samples/AI Files/`
- `samples/AI Graph/`
- `samples/AI Input/`
- `samples/AI Project/`
- `samples/AI Vision/`
- `samples/AI Voice/`

## Observações

- A suíte está organizada em pacotes menores para facilitar recuperação, compilação e manutenção.
- Quando algo estiver faltando em um runner, o problema normalmente é dependência externa ou ordem de instalação.
- Use este índice como porta de entrada para a instalação modular da suíte.
