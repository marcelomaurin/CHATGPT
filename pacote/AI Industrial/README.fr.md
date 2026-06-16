# 🏭 Documentation de l'onglet AI Industrial

> [!NOTE]
> Ce dossier contient la suite de composants Lazarus sous l'onglet **AI Industrial**.

## Composants d'automatisation industrielle Modbus, MQTT et PLC.
Fournit des ponts PLC industriels (Profinet/Profibus), des clients IoT MQTT, la surveillance des registres Modbus et le contrôle des imprimantes thermiques Esc/POS.

### Référence Détaillée des Composants

| Composant | Description | Propriétés Importantes | Méthodes Principales | Rôle de l'Agent d'IA |
|---|---|---|---|---|
| **TAIPOSPrinter** | Imprimante de reçus thermique Esc/POS. | `DevicePath, Active` | `PrintText, PrintBarcode` | Imprimer des reçus, des codes-barres et des tickets. |
| **TAIModbusClient** | Client Modbus industriel (TCP/RTU). | `Host, Port, Mode, Active` | `ReadHoldingRegisters, WriteRegister` | Interroger des registres physiques de capteurs thermiques et pressions. |
| **TAIMQTTClient** | Client réseau IoT MQTT. | `Host, Port, Active` | `ConnectBroker, Publish, Subscribe` | Synchroniser la télémétrie IoT avec des serveurs MQTT de façon asynchrone. |
| **TAIIndustrialBridge** | Pont Profinet/Profibus automate PLC. | `IPAddress, Rack, Slot, Active` | `ConnectBridge, ReadBytes, WriteBytes` | Interfacer et déclencher des contrôles sur automates industriels. |

### 💻 Exemple de Code Lazarus (TAIPOSPrinter)

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


### ⚡ Pont d'IA et de Matériel
Chacun de ces composants intègre une propriété published `Prompt` documentant de manière transparente son API interne pour guider les agents d'IA (`TAIAgent`) de façon autonome.
