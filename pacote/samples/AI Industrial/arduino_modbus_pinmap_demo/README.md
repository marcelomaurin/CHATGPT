# Arduino Modbus PinMap Demo

Este exemplo demonstra como utilizar o componente `TAIArduinoModbusPinMap` para ler e escrever em pinos de placas Arduino (Nano, Uno, Mega) através do protocolo Modbus TCP ou RTU (Serial).

## Estrutura de Registradores Modbus

O componente traduz chamadas lógicas de pinos para os seguintes endereços Modbus (Holding Registers, endereçados a partir de 0):

*   **10..31** (40011..40032): Modo dos pinos (0=Desabilitado, 1=INPUT, 2=INPUT_PULLUP, 3=OUTPUT, 4=PWM)
*   **50..71** (40051..40072): Valor digital dos pinos (0 ou 1)
*   **100..115** (40101..40116): Leitura analógica (0..1023)
*   **150..171** (40151..40172): Valor PWM dos pinos (0..255)

## Como Compilar & Executar

1. Abra este projeto `.lpi` no Lazarus.
2. Certifique-se de que o pacote `openai_industrial` está instalado/compilado.
3. Pressione `F9` para compilar e executar o exemplo.
