# Agent Serial Demo — Arduino Mega

Exemplo real do `TAIAgentSerial` controlando o LED integrado do Arduino Mega,
no pino digital 13.

## Fluxo

1. Grave `arduino_mega_led_agent.ino` no Arduino Mega.
2. O firmware trabalha em `115200` baud e aceita `LEDON`, `LEDOFF` e `MAN`.
3. Ao conectar, o sample envia `MAN` automaticamente.
4. O firmware devolve seu manual entre `MAN-BEGIN` e `MAN-END`.
5. O sample coloca esse manual em `TAIAgentSerial.SystemPrompt`.
6. A LLM combina o manual fornecido pelo firmware com o prompt do usuário.
7. Quando necessário, ela solicita uma ação `send` com `LEDON` ou `LEDOFF`.
8. O usuário precisa confirmar a ação antes do envio real ao Arduino.

Exemplos de prompts:

- `acenda o LED do Arduino`
- `apague o LED`
- `qual é o pino controlado por este firmware?`
- `explique quais comandos o dispositivo aceita`

O botão **Ler MAN** permite recarregar as instruções do firmware. O agente é
bloqueado até que um manual válido seja recebido, evitando inventar comandos.

## Segurança e configuração

- Não existe modo de simulação: ações autorizadas operam o hardware real.
- Cada ação do agente pede confirmação por padrão.
- Selecione a porta do Arduino Mega e mantenha `115200` baud.
- Configure um provedor LLM e sua chave, ou use um servidor local compatível.
- Não envie credenciais ou dados sensíveis ao firmware ou à LLM.
- No Linux, o usuário normalmente deve pertencer ao grupo `dialout`.
