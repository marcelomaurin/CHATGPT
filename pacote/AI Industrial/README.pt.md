# 🏭 Documentação da Aba AI Industrial

> [!NOTE]
> Esta pasta contém a suíte de componentes do Lazarus sob a aba **AI Industrial**.

## Modbus, MQTT e Componentes de Automação Industrial.
Fornece conexões industriais com CLP (Profinet/Profibus), brokers IoT MQTT, comunicação Modbus e controle de impressoras térmicas Esc/POS.

### Referência Detalhada dos Componentes

| Componente | Descrição | Propriedades Importantes | Métodos Principais | Papel do Agente de IA |
|---|---|---|---|---|
| **TAIPOSPrinter** | Impressora Esc/POS térmica. | `DevicePath, Active` | `PrintText, PrintBarcode` | Emitir relatórios impressos e comprovantes em bobina de papel. |
| **TAIModbusClient** | Cliente Modbus industrial (TCP/RTU). | `IPAddress, Port, ProtocolType, DeviceName, BaudRate, Active` | `Connect, Disconnect, ReadHoldingRegisters, WriteSingleRegister` | Leitura de registradores sensores de temperatura, pressão e estado físico. |
| **TAIArduinoModbusPinMap** | Mapeador lógico de pinos de Arduino/ESP32 para Modbus. | `BoardType, ModbusClient, CommandMap, Pins, SlaveID, AutoConnect` | `Connect, Disconnect, SetPinMode, ReadPin, WritePin, SetPWM, ReadAnalog, SetupPins` | Fornecer uma interface lógica simplificada baseada em pinos (ex: D13, A0) mapeada para registradores Modbus. |
| **TAIModbusCommandMap** | Filtro de códigos de função Modbus permitidos/customizados. | `Commands, AllowCustomCommands, StrictValidation` | `IsValidFunctionCode, LoadDefaultModbusCommands, AddCustomCommand` | Validar e gerenciar códigos de função Modbus padrão e específicos do usuário. |
| **TAIMQTTClient** | Cliente de Rede IoT MQTT. | `Host, Port, Active` | `ConnectBroker, Publish, Subscribe` | Sincronizar telemetria IoT com brokers (ex: HiveMQ) sem travar a UI. |
| **TAIIndustrialBridge** | Ponte dinâmica Profinet/Profibus CLP. | `IPAddress, Rack, Slot, Active` | `ConnectBridge, ReadBytes, WriteBytes` | Controlar e ler estado físico de pontes automatizadas industriais (S7). |
| **TAI_Arm_robot** | Modelo de cinematica 3D para braco robotico. | `BaseX, BaseY, BaseZ, TargetX, TargetY, TargetZ, Tolerance, MaxIterations, UseLimits, Joints` | `AddJoint, ClearJoints, LoadSixAxisSample, ResetAngles, ForwardKinematics, SolveInverseKinematics, GetEndEffectorPosition` | Calcular os angulos dos servos a partir do alvo XYZ e exportar a configuracao mecanica do braco. |
| **TAI_Arm_robotViewer** | Visualizador 3D/isometrico do braco robotico. | `Arm, BackgroundColor, ArmColor, JointColor, GridColor, ShowGrid, ShowAxes, AutoFit, Scale, AzimuthDeg, ElevationDeg` | `Paint` | Desenhar o braco conforme a especificacao do componente de cinematica. |

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
