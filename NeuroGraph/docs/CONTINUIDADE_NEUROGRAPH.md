# Continuidade do NeuroGraph — 13/11/2026

Este documento reúne as decisões e o estado do trabalho discutido em 12 e 13/11/2026. É uma síntese técnica do contexto disponível, não uma transcrição integral dos áudios. Leia este arquivo antes de continuar a implementação.

## Objetivo e decisões do usuário

Construir uma IA leve em português, com tokens como nós, conexões direcionadas ponderadas, ativação contextual e geração de respostas token por token. Priorizar pesos aprendidos e contexto, sem selecionar respostas completas prontas nem codificar regras gramaticais específicas para simular aprendizado.

O assistente deve executar a calibração e entregar resultados testados. Separar treino, validação e perguntas inéditas de teste desde o início. Preservar código, pesos, decisões, resultados e falhas para retomar o trabalho. A meta posterior é integrar o núcleo à biblioteca CHATGPT em Lazarus/Free Pascal e executar no Raspberry Pi 4 com 4 GB.

A prioridade aceita em 13/11 foi trabalhar nos pesos e na geração contextual, com testes inéditos, antes do port para outras plataformas. O pedido atual é transferir as informações e materiais desse trabalho para o projeto CHATGPT.

## Histórico preservado

- `../history/2026-11-12/`: conteúdo integral do pacote original de continuidade, incluindo JSON de decisões, scripts v2 a v6 e pesos. Os arquivos foram copiados sem alteração.
- `relational_holdout_20261113.md` e `../tests/relational_holdout_20261113.py`: experimento noturno de propagação relacional. Com dois saltos, recupera 15/15 fatos conhecidos, acerta 0/5 sujeitos reservados e se abstém em 10/10 relações ausentes. Usa triplas estruturadas; não mede entendimento de perguntas em português. Não ajustou os pesos da v6.
- `contextual_v7_20261113.md` e `../experiments/contextual_v7/`: etapa posterior com aprendizado de pesos para prever o próximo token, geração autoregressiva, contexto persistente, modelo binário e avaliação publicada.

A informação inicial de que não houve melhora refere-se ao teste noturno. A v7 é um experimento posterior, com outro protocolo. Seus resultados não podem ser comparados diretamente aos 15/15 e 0/5 do teste relacional.

## Estado medido da v7

Modelo linear de características recorrentes; não é uma RNN profunda nem um LLM geral. Treino com 156 exemplos, validação com 117 e teste separado com 54. A linha de base v6 recebeu os mesmos dados e calibração própria na validação.

| Categoria de teste | v6 recalibrada | v7 |
| --- | ---: | ---: |
| Paráfrases | 29/31 | 30/31 |
| Contexto | 0/8 | 8/8 |
| Composições de fatos conhecidos | 0/7 | 7/7 |
| Abstenções corretas | 8/8 | 6/8 |
| Total | 37/54 | 51/54 |

Esses números constam do relatório e de `../experiments/contextual_v7/results/evaluation.json`. A v7 melhora nesse conjunto pequeno, mas piora na abstenção. Produz resposta indevida sobre plutônio e titânio e recusa uma paráfrase válida. Não foi demonstrada compreensão geral de português nem capacidade de responder fatos nunca ensinados.

Os pesos `NGCTX007` têm 1.520.134 bytes, com 111.816 conexões float32. Não são pesos de um bit e não são compatíveis com o formato antigo nem com o leitor Pascal atual. A inferência Python usa a biblioteca padrão; o treinamento requer as dependências descritas no experimento. As medidas de tempo e RAM publicadas são de Linux x86_64, não do Raspberry Pi.

## Próximo trabalho, em ordem

1. Reservar um novo conjunto final de perguntas antes de alterar o modelo; o teste v7 já observado passa a ser desenvolvimento se orientar ajustes.
2. Melhorar a detecção de assuntos desconhecidos e reduzir respostas indevidas, acompanhando a cobertura e a abstenção para não mascarar regressões.
3. Ampliar o corpus em português com proveniência e controle de qualidade; avaliar novas paráfrases, contexto e combinações de fatos conhecidos sem vazamento.
4. Comparar com a v7 publicada e a v6; registrar parâmetros, sementes, hashes, acertos, falhas, latência, RAM e crescimento das conexões.
5. Após demonstrar avanço, implementar leitura do formato e inferência em Free Pascal, integrar aos componentes CHATGPT e criar demonstração Lazarus.
6. Compilar e medir no Raspberry Pi 4 de 4 GB. Não declarar essas etapas concluídas antes dos testes no ambiente correspondente.

Não há autorização técnica para reforçar automaticamente toda resposta gerada: o protótipo atual não altera pesos durante a conversa. Aprendizado incremental deve ter supervisão e regressão para evitar reforço de erros.

## Reprodução

A partir da raiz do repositório:

```sh
python3 NeuroGraph/tests/relational_holdout_20261113.py
cd NeuroGraph/experiments/contextual_v7
python3 -m unittest -v test_model.py
python3 -S ask.py "descreva luma e nino"
```

A resposta esperada do último comando é `luma é azul e nino é verde`. Para reproduzir o treinamento, seguir o README do experimento e instalar `requirements-training.txt`.

## Localização e limite de acesso

Repositório: https://github.com/marcelomaurin/CHATGPT . Clone informado pelo usuário: `C:\projetos\maurinsoft\CHATGPT`. Nesta sessão o acesso verificado é à cópia Linux do repositório; gravar e publicar nela não atualiza automaticamente a pasta Windows. Depois de publicar, sincronizar o clone Windows com `git pull --ff-only origin main`, preservando eventuais alterações locais.

Não foram transferidos assuntos pessoais ou de outros projetos: o escopo deste registro é o NeuroGraph. Horário de término e execução contínua do agente noturno foram mencionados na conversa, mas não foram auditados neste registro; os resultados técnicos preservados estão no script e relatório correspondentes.
