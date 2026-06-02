# 📅 Documentación de la Pestaña IA Schedulle

> [!NOTE]
> Esta carpeta contiene la suite de componentes de Lazarus bajo la pestaña **IA Schedulle**.

## Programación Automatizada y Línea de Tiempo Neural.
Componentes para la gestión inteligente de tareas periódicas basadas en cronómetros y expresiones cron.

### Referencia Detallada de Componentes

| Componente | Descripción | Propiedades Importantes | Métodos Principales | Rol del Agente de IA |
|---|---|---|---|---|
| **TIASchedule** | Programador de cronogramas. | `CronExpression, MaxIterations` | `ScheduleTask, CancelTask` | Gestionar activadores de tiempo para las tareas del agente de IA. |

### 💻 Ejemplo de Código Lazarus (TIASchedule)

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


### ⚡ Puente de IA y Hardware
Cada uno de estos componentes cuenta con una propiedad published `Prompt` que documenta de forma transparente su API interna para guiar a Agentes de IA (`TAIAgent`) de manera autónoma.
