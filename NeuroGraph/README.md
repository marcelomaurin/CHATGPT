# NeuroGraph — protótipo Lazarus / Free Pascal

Módulo experimental do framework CHATGPT para investigar uma arquitetura híbrida de rede neural compacta e grafo associativo direcionado, com execução em Linux/ARM64 (Raspberry Pi 4 GB).

## Requisitos de arquitetura (discussão inicial)

- Tokens de entrada acionam uma única consulta ao grafo por interação.
- Propagação direcionada por no máximo três saltos, com atenuação por nível e pesos das arestas.
- A rede neural recebe os tokens originais e as ativações associativas ponderadas.
- Os tokens **de saída** da rede são candidatos a criar/reforçar relações no grafo, disponíveis apenas na próxima interação.
- Aprendizado incremental, conexões provisórias e confirmação para reduzir reforço de erros.
- Preservar ordem, papéis e contexto; conexões por coocorrência não são, por si, compreensão semântica.
- Medir consumo de RAM, latência, qualidade das respostas e crescimento do grafo; meta de operar no Raspberry Pi com 4 GB.

## Organização planejada

- `src/`: unidades Free Pascal para tokens, grafo esparso, propagação e atualização.
- `demo/`: aplicação de teste Lazarus.
- `tests/`: testes de direção, atenuação, persistência e aprendizado.
- `docs/`: especificação matemática e experimentos.

## Algoritmo inicial

1. Tokenizar a entrada preservando posições.
2. Ativar nós correspondentes e propagar por até três níveis com pesos e decaimento.
3. Selecionar ativações relevantes com orçamento de CPU/memória.
4. Reprocessar uma vez na rede neural compacta e gerar saída.
5. Propor atualizações de arestas direcionadas a partir dos tokens gerados, com confiança e validação.

Peso candidato: `w' = clamp((1 - lambda)*w + eta*ai*aj*confianca*relevancia, 0, 1)`.

**Estado:** especificação inicial; ainda não há motor neural funcional nem comprovação de compreensão de português. Implementar e validar por etapas.

## Integração

Reutilizar componentes existentes do repositório CHATGPT sempre que forem compatíveis; não duplicar bibliotecas compartilhadas. Manter o módulo isolado e compilável no Lazarus/FPC.
