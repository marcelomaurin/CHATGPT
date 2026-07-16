# 🏭 Documentation for AI Industrial Tab

> [!NOTE]
> This folder contains the Lazarus components suite under the **AI Industrial** tab.

## Modbus, MQTT and Industrial Automation Components.
Provides industrial PLC (Profinet/Profibus) bridges, IoT MQTT clients, Modbus registers monitoring, and Esc/POS thermal printers control.

### Detailed Component Reference

| Component | Description | Important Properties | Main Methods | AI Agent Role |
|---|---|---|---|---|
| **TAIPOSPrinter** | Esc/POS thermal receipt printer. | `DevicePath, Active` | `PrintText, PrintBarcode` | Print automated paper logs, barcodes and receipts. |
| **TAIModbusClient** | Industrial Modbus RTU/TCP Client. | `Host, Port, Mode, Active` | `ReadHoldingRegisters, WriteRegister` | Query physical registers from temperature and automated sensors. |
| **TAIMQTTClient** | IoT MQTT network client. | `Host, Port, Active` | `ConnectBroker, Publish, Subscribe` | Publish JSON sensor data asynchronously to public/private brokers. |
| **TAIIndustrialBridge** | CLP Profinet/Profibus bridge. | `IPAddress, Rack, Slot, Active` | `ConnectBridge, ReadBytes, WriteBytes` | Interface and trigger controls on physical PLC industrial automation links. |
| **TAI_Arm_robot** | 3D kinematics model for a robotic arm. | `BaseX, BaseY, BaseZ, TargetX, TargetY, TargetZ, Tolerance, MaxIterations, UseLimits, Joints` | `AddJoint, ClearJoints, LoadSixAxisSample, ResetAngles, ForwardKinematics, SolveInverseKinematics, GetEndEffectorPosition` | Calculate servo angles from an XYZ target and export the mechanical arm configuration. |
| **TAI_Arm_robotViewer** | 3D/isometric robotic arm viewer. | `Arm, BackgroundColor, ArmColor, JointColor, GridColor, ShowGrid, ShowAxes, AutoFit, Scale, AzimuthDeg, ElevationDeg` | `Paint` | Render the arm according to the kinematics component specification. |

### 💻 Lazarus Code Example (TAIPOSPrinter)

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


### ⚡ AI and Hardware Bridge
Each of these components features a published `Prompt` property that transparently documents its internal API to guide AI Agents (`TAIAgent`) autonomously!
