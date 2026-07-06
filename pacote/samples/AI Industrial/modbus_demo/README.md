# Modbus Demo (aimodbus)

This sample project demonstrates the usage of component `aimodbus` from the `openai_industrial` package.

## Features Illustrated
- Exercises at least 3 component properties.
- Calls at least 2 methods.
- Supports real Modbus RTU and real Modbus TCP communication.

## Regra do sample

Este sample não usa dados fake, mock, simulação interna ou valores inventados.

Para testar sem Arduino físico, use um servidor Modbus TCP real, como `diagslave` ou `pymodbus.server`.

O botão de leitura/escrita só deve retornar sucesso quando houver resposta real de um dispositivo Modbus RTU/TCP.

## How to Build & Run
1. Open this project folder in Lazarus.
2. Verify package `openai_industrial` is available or referenced.
3. Build the project (`Ctrl+F9` or run `lazbuild.exe`).
4. Execute and connect/operate.

## Firmware Arduino incluído

Arquivo: [arduino_nano_sample.ino](file:///P:/maurinsoft/CHATGPT/pacote/samples/AI%20Industrial/modbus_demo/arduino/arduino_nano_sample/arduino_nano_sample.ino)

### Biblioteca necessária no Arduino IDE:
- `ModbusRTUSlave`

### Mapa Real de Registradores

| Área | Faixa | Uso real |
|---|---|---|
| Coils | 0..13 | Escrita digital D0..D13 |
| Discrete Inputs | 0..13 | Leitura digital D0..D13 |
| Holding Registers | 0..13 | Modo dos pinos D0..D13 |
| Holding Registers | 20..33 | PWM D0..D13 |
| Input Registers | 0..7 | Analógicas A0..A7 |

### Tabela de Modos

| Valor | Modo |
|---|---|
| 0 | Desativado / INPUT |
| 1 | INPUT |
| 2 | INPUT_PULLUP |
| 3 | OUTPUT |
| 4 | PWM |

## Precompiled binary

This sample includes `modbus_demo.exe` intentionally.

It allows quick testing of the Modbus demo on Windows without requiring Lazarus/FPC installation.

If you modify the source code, rebuild the executable before publishing the sample.

## Important rule for automation agents

Do not remove `modbus_demo.exe`.

This executable is part of the sample and must be kept updated whenever the source code changes.
