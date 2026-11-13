# Experimento contextual v7 — 13/11/2026

## Problema e alteração

A v6 selecionava memórias de perguntas semelhantes e reconstruía transições locais das respostas associadas. Seu calibrador alterava razão de ativação, limiar, temperatura e cobertura lexical; não ajustava as conexões por erro de previsão do próximo token.

A v7 implementa um grafo de características de entrada e de estado com arestas aprendidas, positivas ou inibitórias, para tokens de saída. A cada passo, a distribuição é `softmax(W^T x_t)`. As características ativas incluem tokens e posições da pergunta, pares ordenados de entrada, tokens de até três interações anteriores, os dois últimos tokens emitidos, posição de saída e conjunções genéricas da entrada com o token anterior. Não há regras gramaticais ou nomes das entidades codificados no motor.

Um estado recorrente mantém ativações dos tokens emitidos: `h_(t+1) = 0,65 h_t + one_hot(y_t)`, com poda de ativações menores que 0,001. Esse decaimento é fixo; as arestas que usam o estado para prever a saída são aprendidas. Trata-se de um modelo log-linear recorrente de características, não de uma rede recorrente profunda com matriz interna aprendida.

O treinamento usa entropia cruzada com o prefixo correto, atualizações Adam, 180 épocas, taxa 0,05 e regularização L2 0,0001. Há 685.548 pesos alterados antes da poda; 111.816 arestas com módulo pelo menos 0,005 são preservadas para inferência e serialização. A perda por token no treino passou de 4,9345 para 0,0398. Isso mede ajuste ao treino, não generalização.

## Protocolo e comparação

O conjunto foi escrito e congelado antes do ajuste: 156 exemplos de treino, 117 de validação e 54 de teste. Os exemplos originais da v6 formam a parte factual; perguntas novas foram escritas para o teste. A parte de composição usa oito entidades fictícias com cores aprendidas. As sete respostas compostas de teste não ocorrem como respostas completas no treino, mas cada fato individual ocorre. O teste não exige inventar informações sobre sujeitos nunca apresentados.

Há também perguntas idênticas cujo significado depende de uma interação anterior. Os conjuntos não compartilham a mesma combinação `(pergunta, contexto)`. Perguntas de assuntos desconhecidos verificam abstenção, separadamente de paráfrases e combinações de fatos conhecidos.

Ambas as versões recebem os mesmos exemplos. A v6 concatena histórico e pergunta, pois não dispõe de estado de conversa. Ela recebe 300 configurações de validação: razões `[0,72; 0,82; 0,92; 0,99]`, limiares `[0; 0,45; 0,65; 0,9; 1,2]`, temperaturas `[0,25; 0,6; 1]` e coberturas `[0; 0,3; 0,6; 0,8; 1]`. A política escolhida foi razão 0,99, limiar 1,2, temperatura 1 e cobertura 0,3. Assim, a comparação não usa apenas os filtros antigos, inadequados ao corpus ampliado.

A v7 avalia sete limites de confiança somente na validação e fixa 0,1. Seus pesos e sua política não foram modificados após observar o teste. A comparação inicial com os filtros antigos da v6 foi substituída pela comparação recalibrada; os resultados da v7 permaneceram 51/54.

| Categoria de teste | v6 recalibrada | v7 |
| --- | ---: | ---: |
| Paráfrases | 29/31 | 30/31 |
| Contexto | 0/8 | 8/8 |
| Composições | 0/7 | 7/7 |
| Abstenções corretas | 8/8 | 6/8 |
| Decisões corretas | 37/54 | 51/54 |

O ganho é de 14 decisões corretas nesse conjunto, acompanhado de piora na abstenção. A v7 recusa indevidamente `pode explicar a ideia de um animal` e responde `o coração movimenta o sangue` às perguntas sobre plutônio e titânio. Esses erros estão integralmente preservados em `results/evaluation.json`. O protótipo não deve ser tratado como uma fonte factual confiável.

## Persistência e reprodução

O arquivo de pesos usa formato próprio `NGCTX007`, esquema 1, cabeçalho, metadados de vocabulário e características, arestas `(uint32, uint32, float32)` em little endian e checksum SHA-256. A gravação é atômica; a leitura valida versão, tamanho, checksum, limites dos índices, duplicatas e pesos finitos. O arquivo não armazena exemplos completos para recuperação. A memória de conversa fica em JSON separado, limitada e vinculada ao hash do modelo; geração não faz autoaprendizado.

- Dataset SHA-256: `0c1d4c33380a38dd88d047eb7d6d6c53ed7c552c34b7c937c50a7122f16e81f8`.
- Pesos SHA-256: `a77a91d88063b25a98b517d48607b3ef6c2f6174b80f319fb05a189e6952402f`.
- Modelo publicado: 1.520.134 bytes.
- Ambiente medido: Python 3.12.14, Linux x86_64.
- Pico de RAM do processo do experimento: 89.056 KiB, incluindo treinamento e comparação.
- Mediana por pergunta na inferência v7: aproximadamente 0,40 ms neste host; não é uma medição no Raspberry Pi.
- Nove testes unitários passaram; inferência adicional foi executada com `python3 -S`, sem carregar bibliotecas de terceiros.

Esses resultados justificam continuar a pesquisa. Não demonstram entendimento geral de português, resposta a fatos nunca ensinados, segurança contra entradas fora do domínio ou compatibilidade com Lazarus. A serialização usa float32, não pesos de um bit. As unidades Pascal ainda não leem este formato, e a topologia pode crescer bastante com corpora maiores.

## Próxima etapa fundamentada

Melhorar a detecção de assunto desconhecido e repetir a avaliação com um novo teste reservado antes de aumentar o corpus ou portar o modelo. Como os erros deste teste já são conhecidos, qualquer alteração orientada por eles deve tratar este conjunto como desenvolvimento e reservar perguntas novas para a próxima avaliação final.
