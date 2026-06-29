# AI Agent Minimal Demo

Este sample demonstra o uso básico do componente `TAIAgent`.

## Objetivo

Mostrar como configurar um agente simples que recebe uma entrada de texto, consulta um LLM e escolhe uma ação permitida.

## Componentes usados

- `TCHATGPT`
- `TAIAgent`
- `TAIAgentOptions`
- `TAIAgentAction`

## O que o sample faz

- Define um prompt de sistema
- Define perguntas/diretrizes
- Define contexto
- Define ações permitidas
- Define parâmetros esperados
- Executa o agente
- Mostra a ação escolhida, os parâmetros e a justificativa

## O que o sample não faz

- Não envia e-mail
- Não chama API
- Não grava arquivos
- Não usa WhatsApp/SMS
- Não executa automação externa

## Fluxo

Usuário -> TAIAgent -> LLM -> JSON -> Ação escolhida -> Resultado na tela

## Como executar

1. Abra `agent_demo.lpi` no Lazarus.
2. Configure o provedor, modelo e token.
3. Clique em `Executar Agente`.
4. Veja o resultado na tela.
