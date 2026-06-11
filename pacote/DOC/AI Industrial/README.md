# AI Industrial — Lazarus AI Suite

This package (`openai_industrial.lpk`) provides components for industrial automation, IoT protocols, and hardware integration.

## Components

| Component | Unit | Description |
|-----------|------|-------------|
| `TAIPOSPrinter` | `aiposprinter.pas` | Thermal POS printer (EscPOS) support |
| `TAIModbusClient` | `aimodbus.pas` | Modbus TCP/RTU client protocol |
| `TAIMQTTClient` | `aimqtt.pas` | IoT MQTT network client |
| `TAIIndustrialBridge` | `aiindustrial.pas` | Profinet/Profibus PLC bridge (Siemens S7, etc.) |

## Requirements

- Depends on `openai_core` and `openai_input`.
