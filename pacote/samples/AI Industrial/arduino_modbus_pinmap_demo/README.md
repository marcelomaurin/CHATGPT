# Arduino Modbus PinMap Demo

> **Status:** Functional (Modbus RTU over Serial USB)

Este exemplo demonstra como utilizar o componente `TAIArduinoModbusPinMap` e o `TAIModbusCommandMap` para ler e escrever em pinos de placas Arduino (Nano, Uno, Mega) e ESP32 através do protocolo Modbus RTU (Serial).

O componente traduz chamadas lógicas de pinos para endereços Modbus (Holding Registers, endereçados a partir de 0).

## Estrutura de Registradores Modbus

*   **10..99:** Modo de Pinos (`ModeRegister`, onde 0 = Desabilitado, 1 = INPUT, 2 = INPUT_PULLUP, 3 = OUTPUT, 4 = PWM).
*   **50..139:** Valor Digital (`DigitalRegister`, valores 0 ou 1).
*   **100..179:** Leitura Analógica (`AnalogRegister`, valores 0..1023).
*   **150..239:** Valor PWM (`PWMRegister`, valores 0..255).
*   **240..329:** Pull Mode (`PullModeRegister`, onde 0 = None, 1 = PullUp, 2 = PullDown).
*   **330..419:** Polaridade (`PolarityRegister`, onde 0 = ActiveHigh, 1 = ActiveLow).
*   **420..509:** Tipo de Contato (`ContactTypeRegister`, onde 0 = None, 1 = NormallyOpen, 2 = NormallyClosed).

---

## Como Testar com Dispositivo Real

### Firmware do Arduino
Carregue o firmware de exemplo localizado em [arduino_modbus_pinmap_slave.ino](arduino_modbus_pinmap_slave/arduino_modbus_pinmap_slave.ino) no seu Arduino Nano/Uno antes de iniciar a comunicação.

### Exemplo no Windows (USB Serial / Modbus RTU)
*   **Serial Port:** `COM3` (ou a porta correspondente ao seu Arduino)
*   **Baud Rate:** `9600`
*   **Slave ID:** `1`

### Exemplo no Linux (USB Serial / Modbus RTU)
*   **Serial Port:** `/dev/ttyUSB0` (ou `/dev/ttyACM0`)
*   **Baud Rate:** `9600`
*   **Slave ID:** `1`
