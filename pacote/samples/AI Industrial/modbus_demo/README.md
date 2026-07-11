# Modbus Demo (aimodbus)

This sample project demonstrates the usage of component `aimodbus` from the `openai_industrial` package.

## Features Illustrated
- Exercises at least 3 component properties.
- Calls at least 2 methods.
- Supports real Modbus RTU and real Modbus TCP communication.

## Regra do sample

This sample does not use fake data, mocks, internal simulation, or invented values.

To test without a physical Arduino, use a real Modbus TCP server such as `diagslave` or `pymodbus.server`.

The read/write button should only return success when there is a real response from a Modbus RTU/TCP device.

## How to Build & Run
1. Open this project folder in Lazarus.
2. Verify package `openai_industrial` is available or referenced.
3. Build the project (`Ctrl+F9` or run `lazbuild.exe`).
4. Execute and connect/operate.

## Firmware Arduino included

The sample now includes two firmware options:

- [Arduino Nano sample](arduino/arduino_nano_sample/arduino_nano_sample.ino)
- [ESP32 sample](arduino/esp32_modbus_sample/esp32_modbus_sample.ino)

### Arduino Nano

Library required in the Arduino IDE:

- `ModbusRTUSlave`

Register map:

| Area | Range | Real use |
|---|---|---|
| Coils | 0..13 | Digital write D0..D13 |
| Discrete Inputs | 0..13 | Digital read D0..D13 |
| Holding Registers | 0..13 | Pin mode D0..D13 |
| Holding Registers | 20..33 | PWM D0..D13 |
| Input Registers | 0..7 | Analog A0..A7 |

Mode table:

| Value | Mode |
|---|---|
| 0 | Disabled / INPUT |
| 1 | INPUT |
| 2 | INPUT_PULLUP |
| 3 | OUTPUT |
| 4 | PWM |

### ESP32

Library required in the Arduino IDE:

- `ModbusRTUSlave`

Register map:

| Area | Range | Real use |
|---|---|---|
| Coils | 0..13 | Digital write on mapped ESP32 GPIOs |
| Discrete Inputs | 0..13 | Digital read on mapped ESP32 GPIOs |
| Holding Registers | 0..13 | GPIO mode slots |
| Holding Registers | 20..33 | PWM for each GPIO slot |
| Input Registers | 0..5 | ADC1 analog inputs |
| Input Registers | 6..7 | Reserved on common WROOM boards |

Mode table:

| Value | Mode |
|---|---|
| 0 | Disabled / INPUT |
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
