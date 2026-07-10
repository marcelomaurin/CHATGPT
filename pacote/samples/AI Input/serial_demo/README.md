# Terminal Serial Simplificado

Este sample implementa um terminal serial simplificado com
`TAISerialModem` para comunicação e `TAIListSerialDevices` para enumeração de
portas.

## Recursos

- Seleção da porta serial e do baud rate por caixas de seleção.
- Envio de texto livre com CR+LF opcional.
- Recepção contínua de dados por polling.
- Log RX/TX com timestamp.
- Eventos `OnConnect`, `OnDisconnect`, `OnRXReceive` e `OnTXSend`.

## Plataformas suportadas

- Windows (x86 e x64)
- Linux (x64 e ARM, incluindo Raspberry Pi)
- macOS (Intel e Apple Silicon)

## Permissões no Linux

O usuário normalmente precisa pertencer ao grupo `dialout`:

```bash
sudo usermod -aG dialout $USER
```

Encerre a sessão e entre novamente depois de alterar os grupos do usuário.

## Teste rápido

É possível testar a transmissão e recepção com um jumper entre os pinos TX e
RX do adaptador serial. O texto enviado aparecerá no log como `TX =>` e o eco
recebido aparecerá como `RX <=`.

O sample mantém `ProbeOpenable` desabilitado durante a enumeração. Ativá-lo
pode alternar o sinal DTR e reiniciar placas Arduino Uno ou Nano.

## Compilação

1. Abra `serial_demo.lpi` no Lazarus.
2. Verifique se o pacote `openai_input` está disponível.
3. Compile com `Ctrl+F9` ou usando `lazbuild`.
