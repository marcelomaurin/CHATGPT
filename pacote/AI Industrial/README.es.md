# 🏭 Documentación de la Pestaña AI Industrial

> [!NOTE]
> Esta carpeta contiene la suite de componentes de Lazarus bajo la pestaña **AI Industrial**.

## Componentes de automatización industrial Modbus, MQTT y PLC.
Proporciona puentes PLC industriales (Profinet/Profibus), clientes IoT MQTT, monitoreo de registros Modbus y control de impresoras térmicas Esc/POS.

### Referencia Detallada de Componentes

| Componente | Descripción | Propiedades Importantes | Métodos Principales | Rol del Agente de IA |
|---|---|---|---|---|
| **TAIPOSPrinter** | Impresora térmica de recibos Esc/POS. | `DevicePath, Active` | `PrintText, PrintBarcode` | Imprimir registros de papel automáticos, códigos de barras y recibos. |
| **TAIModbusClient** | Cliente Modbus industrial (TCP/RTU). | `Host, Port, Mode, Active` | `ReadHoldingRegisters, WriteRegister` | Consultar registros físicos de sensores de temperatura y presión. |
| **TAIMQTTClient** | Cliente de red IoT MQTT. | `Host, Port, Active` | `ConnectBroker, Publish, Subscribe` | Sincronizar telemetría IoT con brokers (ej. HiveMQ) de forma asíncrona. |
| **TAIIndustrialBridge** | Puente Profinet/Profibus de PLC. | `IPAddress, Rack, Slot, Active` | `ConnectBridge, ReadBytes, WriteBytes` | Interconectar y leer estados físicos de autómatas industriales. |

### 💻 Ejemplo de Código Lazarus (TAIPOSPrinter)

```pascal
var
  MyComponent: TAIPOSPrinter;
begin
  MyComponent := TAIPOSPrinter.Create(Self);
  try
    // Configuration properties
    // MyComponent.Property := Value;
    
    // Execute call
    // MyComponent.ExecuteMethod;
  finally
    MyComponent.Free;
  end;
end;
```


### ⚡ Puente de IA y Hardware
Cada uno de estos componentes cuenta con una propiedad published `Prompt` que documenta de forma transparente su API interna para guiar a Agentes de IA (`TAIAgent`) de manera autónoma.
