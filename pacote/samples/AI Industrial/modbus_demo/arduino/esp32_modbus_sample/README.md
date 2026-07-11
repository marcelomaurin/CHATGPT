# ESP32 Modbus Sample

This sketch follows the same Modbus register pattern used by the Arduino Nano sample, but mapped to safe ESP32 GPIOs.

## File

- `esp32_modbus_sample.ino`

## Library

- `ModbusRTUSlave`

## Register map

| Area | Range | Use |
|---|---|---|
| Coils | 0..13 | Digital write on the mapped GPIOs |
| Discrete Inputs | 0..13 | Digital read on the mapped GPIOs |
| Holding Registers | 0..13 | Mode of each GPIO slot |
| Holding Registers | 20..33 | PWM value of each GPIO slot |
| Input Registers | 0..5 | ADC1 analog inputs |
| Input Registers | 6..7 | Reserved / returns 0 on common WROOM boards |

## Mode table

| Value | Mode |
|---|---|
| 0 | Disabled / INPUT |
| 1 | INPUT |
| 2 | INPUT_PULLUP |
| 3 | OUTPUT |
| 4 | PWM |

## Notes

- The sketch uses `Serial` so it can be tested through the USB serial interface.
- If you want an external RS485 transceiver, switch `ModbusRTUSlave modbus(Serial);` to `Serial2` and configure the UART pins in `setup()`.
- The PWM path uses the Arduino-ESP32 core `analogWrite()` API.
