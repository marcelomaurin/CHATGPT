# 🏭 Documentazione della Scheda AI Industrial

> [!NOTE]
> Questa cartella contiene la suite di componenti Lazarus sotto la scheda **AI Industrial**.

## Componenti di automazione industriale Modbus, MQTT e PLC.
Fornisce ponti PLC industriali (Profinet/Profibus), client IoT MQTT, monitoraggio dei registri Modbus e controllo delle stampanti termiche Esc/POS.

### Riferimento Dettagliato dei Componenti

| Componente | Descrizione | Proprietà Importanti | Metodi Principali | Ruolo dell'Agente di IA |
|---|---|---|---|---|
| **TAIPOSPrinter** | Stampante termica per ricevute Esc/POS. | `DevicePath, Active` | `PrintText, PrintBarcode` | Stampare report cartacei, codici a barre e ricevute. |
| **TAIModbusClient** | Client Modbus industriale (TCP/RTU). | `Host, Port, Mode, Active` | `ReadHoldingRegisters, WriteRegister` | Interrogare registri di sensori fisici di temperatura e pressione. |
| **TAIMQTTClient** | Client di rete IoT MQTT. | `Host, Port, Active` | `ConnectBroker, Publish, Subscribe` | Sincronizzare dati sensoriali con server MQTT in background. |
| **TAIIndustrialBridge** | Ponte Profinet/Profibus per PLC. | `IPAddress, Rack, Slot, Active` | `ConnectBridge, ReadBytes, WriteBytes` | Controllare e leggere stati da controllori PLC industriali. |

### 💻 Esempio di Codice Lazarus (TAIPOSPrinter)

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


### ⚡ Ponte di IA e Hardware
Ciascuno di questi componenti include una proprietà published `Prompt` che documenta in modo trasparente le proprie API interne per orientare gli Agenti IA (`TAIAgent`) autonomamente.
