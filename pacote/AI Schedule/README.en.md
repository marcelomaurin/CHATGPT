# 📅 Documentation for AI Schedule Tab

> [!NOTE]
> This folder contains the Lazarus components suite under the **AI Schedule** tab.

## Automated Scheduling and Neural Timeline.
Components for intelligent cron-based periodic task management and timers.

### Detailed Component Reference

| Component | Description | Important Properties | Main Methods | AI Agent Role |
|---|---|---|---|---|
| **TIASchedule** | Chronogram scheduler and manager. | `CronExpression, MaxIterations` | `ScheduleTask, CancelTask` | Manage background execution timers and triggers for the AI agent. |

### 💻 Lazarus Code Example (TIASchedule)

```pascal
var
  MyComponent: TIASchedule;
begin
  MyComponent := TIASchedule.Create(Self);
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
