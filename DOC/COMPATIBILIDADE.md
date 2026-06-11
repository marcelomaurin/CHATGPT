# Compatibilidade por Plataforma

Esta matriz registra a compatibilidade planejada e o estado de validação por sistema operacional e arquitetura.

## Plataformas alvo

| Plataforma | Arquitetura | Perfil | Status |
|---|---|---|---|
| Windows moderno | x86 | windows-x86 | Planejado |
| Windows moderno | x64 | windows-x64 | Suportado |
| Windows 7 legado | x86 | windows7-x86 | Experimental legado |
| Windows 7 legado | x64 | windows7-x64 | Experimental legado |
| Linux | x64 | linux-x64 | Suportado |
| Raspberry / Linux | ARM64 | linux-arm64 | Experimental |
| Raspberry / Linux | ARMHF | linux-armhf | Experimental |

## Pacotes

| Pacote | Win x86 | Win x64 | Win7 x86 | Win7 x64 | Linux x64 | ARM64 | ARMHF | Observação |
|---|---|---|---|---|---|---|---|---|
| openai_core | Planejado | Sim | Planejado | Planejado | Sim | Provável | Provável | Pascal/FPC, base comum (e componentes de integração Python) |
| openai_ml | Planejado | Sim | Planejado | Planejado | Sim | Provável | Provável | Pascal puro, limitado por CPU/RAM |
| openai_graph | Planejado | Sim | Planejado | Planejado | Sim | Provável | Provável | Pascal puro |
| openai_output | Planejado | Sim | Planejado | Planejado | Sim | Provável | Provável | PDF/TXT tendem a ser portáveis |
| openai_vision | Parcial | Parcial | Parcial | Parcial | Parcial | Experimental | Experimental | OpenCV via Python e visão nativa parcial |
| openai_industrial | Planejado | Sim | Planejado | Planejado | Sim | Provável | Provável | Serial/sockets dependem do ambiente |
| openai_graphic | Experimental | Experimental | Experimental | Experimental | Experimental | Experimental | Experimental | Depende de backend gráfico |
| openai_agent | Experimental | Experimental | Experimental | Experimental | Experimental | Experimental | Experimental | Requer segurança e limites |

## Componentes Python

Todos os componentes Python devem usar `TAIPythonRuntime`.

| Componente | Runtime necessário | ARM/Raspberry | Observação |
|---|---|---|---|
| TAIPythonRuntime | Sim | Sim | Resolve Python, workers, libs e paths |
| TPythonConnector | Sim | Experimental | Deve ser ajustado para usar runtime central |
| TAIOpenCV | Sim | Experimental | Já preparado para usar TAIPythonRuntime |
| TYoloDetect | Sim | Experimental | Modelos podem ser pesados no Raspberry |
| TFaceDetection | Sim | Experimental | Depende de backend externo |
| TCNNClassifier | Sim | Experimental | Depende de modelo e libs Python |
| TLSTMPredictor | Sim | Experimental | Depende de modelo e libs Python |

## Componentes Vision nativos

| Componente | Windows | Linux x64 | ARM/Raspberry | Observação |
|---|---|---|---|---|
| TAICameraCapture | Parcial | Pendente | Pendente | Windows VFW existe; Linux precisa V4L2/libcamera |
| TAINativeImageFilter | Provável | Provável | Provável | Deve ser Pascal puro |
| TAIImageInfo | Provável | Provável | Provável | Deve ser Pascal puro |
| TAIFrameBuffer | Provável | Provável | Provável | Memória pode limitar ARM |
| TAIMotionTracker | Provável | Provável | Provável | Depende de tamanho dos frames |
| TAIFrameDiff | Provável | Provável | Provável | Depende de tamanho dos frames |
| TAIFaceTracker | Experimental | Experimental | Experimental | Rastreamento por template, não detector semântico |

## Regras de portabilidade

1. Nenhum componente deve assumir Windows como padrão.
2. Nenhum caminho deve usar separador fixo.
3. Componentes Python devem usar `TAIPythonRuntime`.
4. Processos externos devem usar `TAIProcessRunner` ou equivalente com timeout.
5. Bibliotecas nativas devem ser resolvidas por plataforma e arquitetura.
6. Funções não suportadas devem retornar erro claro, não travar.
7. ARM64 e ARMHF devem ser validados separadamente.
8. Raspberry deve começar pelo perfil lite antes do vision.
