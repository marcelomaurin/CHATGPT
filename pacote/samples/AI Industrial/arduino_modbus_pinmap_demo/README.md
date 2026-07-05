# Arduino Modbus PinMap Demo

> **Status:** Experimental / Incomplete

Este exemplo demonstra como utilizar o componente `TAIArduinoModbusPinMap` para ler e escrever em pinos de placas Arduino (Nano, Uno, Mega) e ESP32 através do protocolo Modbus TCP ou RTU (Serial).

O componente traduz chamadas lógicas de pinos para endereços Modbus (Holding Registers, endereçados a partir de 0).

## Estrutura de Registradores Modbus por Placa

### 1. Arduino Nano / Uno
*   **Modo de Pinos (digital):** `10..29` (Holding Registers `40011` a `40030`, onde 0 = Desabilitado, 1 = INPUT, 2 = INPUT_PULLUP, 3 = OUTPUT, 4 = PWM).
*   **Valor Digital:** `50..69` (Holding Registers `40051` a `40070`, valores 0 ou 1).
*   **Leitura Analógica:** `100..107` (Holding Registers `40101` a `40108`, valores 0..1023).
*   **Valor PWM:** `150..171` (Holding Registers `40151` a `40172`, valores 0..255).
*   *Nota: Pinos D0 e D1 são reservados para comunicação Serial USB. Pinos A6 e A7 são apenas entradas analógicas no Nano.*

### 2. Arduino Mega
*   **Modo de Pinos (digital):** `10..63` (Holding Registers `40011` a `40064`).
*   **Valor Digital:** `50..103` (Holding Registers `40051` a `40104`).
*   **Modo de Pinos (analógico):** `64..79` (Holding Registers `40065` a `40080`).
*   **Valor Digital (analógico):** `104..119` (Holding Registers `40105` a `40120`).
*   **Leitura Analógica:** `100..115` (Holding Registers `40101` a `40116`).

### 3. ESP32 (NodeMCU)
*   **Modo de Pinos (digital):** `10 + PinNumber`
*   **Valor Digital:** `50 + PinNumber`
*   **Leitura Analógica:** `100 + CanalADC` (0..5)
*   **Valor PWM:** `150 + PinNumber`

---

## Como Testar com Dispositivo Real

### Firmware do Arduino
Carregue o firmware de exemplo localizado em [arduino_modbus_pinmap_slave.ino](arduino_modbus_pinmap_slave/arduino_modbus_pinmap_slave.ino) no seu Arduino Nano/Uno antes de iniciar a comunicação.

### Exemplo no Windows (USB Serial / Modbus RTU)
*   **Protocolo:** Modbus RTU
*   **Serial Port:** `COM3` (ou a porta correspondente ao seu Arduino)
*   **Baud Rate:** `9600`
*   **Slave ID:** `1`

### Exemplo no Linux (USB Serial / Modbus RTU)
*   **Protocolo:** Modbus RTU
*   **Serial Port:** `/dev/ttyUSB0` (ou `/dev/ttyACM0`)
*   **Baud Rate:** `9600`
*   **Slave ID:** `1`
