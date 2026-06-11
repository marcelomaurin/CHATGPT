# 🏭 Documentação da Aba IA Industrial

> [!NOTE]
> Esta pasta contém a suíte de componentes do Lazarus sob a aba **IA Industrial**.

## Modbus, MQTT e Componentes de Automação Industrial.
Fornece conexões industriais com CLP (Profinet/Profibus), brokers IoT MQTT, comunicação Modbus e controle de impressoras térmicas Esc/POS.

### Referência Detalhada dos Componentes

| Componente | Descrição | Propriedades Importantes | Métodos Principais | Papel do Agente de IA |
|---|---|---|---|---|
| **TAIPOSPrinter** | Impressora Esc/POS térmica. | `DevicePath, Active` | `PrintText, PrintBarcode` | Emitir relatórios impressos e comprovantes em bobina de papel. |
| **TAIModbusClient** | Cliente Modbus industrial (TCP/RTU). | `Host, Port, Mode, Active` | `ReadHoldingRegisters, WriteRegister` | Leitura de registradores sensores de temperatura, pressão e estado físico. |
| **TAIMQTTClient** | Cliente de Rede IoT MQTT. | `Host, Port, Active` | `ConnectBroker, Publish, Subscribe` | Sincronizar telemetria IoT com brokers (ex: HiveMQ) sem travar a UI. |
| **TAIIndustrialBridge** | Ponte dinâmica Profinet/Profibus CLP. | `IPAddress, Rack, Slot, Active` | `ConnectBridge, ReadBytes, WriteBytes` | Controlar e ler estado físico de pontes automatizadas industriais (S7). |

### 💻 Exemplo de Código Lazarus (TAIPOSPrinter)

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


### ⚡ Ponte de IA e Hardware
Cada um destes componentes possui uma propriedade published `Prompt` que documenta sua API interna de forma transparente para orientar Agentes de IA (`TAIAgent`) de forma automática!
