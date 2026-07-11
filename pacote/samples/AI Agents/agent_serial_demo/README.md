# Agent Serial Demo

Sample visual do `TAIAgentSerial` com configuração completa da LLM, memória de
sessão e controle serial real sob confirmação do usuário.

Todos os componentes visuais e não-visuais estão declarados em design-time no
`main.lfm`: `TCHATGPT`, `TAISerialModem`, `TAIListSerialDevices`,
`TAIAgentSerial` e `TAIAgentMemoryMap`.

## Abas

### Configuração

Permite escolher todas as opções principais do `TCHATGPT`, incluindo provider,
modelo, token, URL, servidor local, máximo de tokens, instruções Dev e campos
do OpenRouter. Também permite selecionar porta e baud rate e testar a LLM.

As opções de porta e baud **não conectam o equipamento**. Ao clicar em
**Iniciar**, elas são registradas no `TAIAgentMemoryMap` para que a LLM possa
usá-las nas conversas seguintes. A conexão, o envio e a leitura são solicitados
pelo `TAIAgentSerial` somente quando necessários e após confirmação.

### Conversa

Mostra o histórico, ações e dados RX. Digite o prompt na parte inferior e
pressione Enter. Cada pergunta e resposta é registrada no MemoryMap e o
contexto acumulado é enviado ao agente.

## Convenção MAN

O firmware deve responder ao comando `MAN` com seus comandos suportados. Por
exemplo:

```text
MAN
LEDON  - acende o LED
LEDOFF - apaga o LED
TEMP?  - retorna a temperatura
```

O contexto inicial instrui a LLM a consultar `MAN` sempre que ainda não souber
operar o equipamento.

Exemplos de prompts:

- `conecte na porta configurada`
- `descubra os comandos do equipamento`
- `acenda o LED`
- `qual a temperatura?`

## Requisitos e segurança

- Lazarus com os pacotes `openai_core`, `openai_input` e `openai_agent`
  instalados na IDE.
- Token válido para o provider escolhido, exceto servidor local.
- No Linux, o usuário normalmente deve pertencer ao grupo `dialout`.
- As chamadas a provedores externos podem ter custo.
- Prompts, contexto e dados seriais podem ser enviados ao provedor; não use
  informações sensíveis.
- Não existe modo de simulação. Toda ação autorizada opera a serial real.

O diretório `arduino_mega_led_agent` contém um firmware de exemplo para Arduino
Mega com os comandos `LEDON`, `LEDOFF` e `MAN` no pino 13.
