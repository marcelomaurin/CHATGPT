# 🤖 Documentación de la Pestaña AI Agent

> [!NOTE]
> Esta carpeta contiene la suite de componentes de Lazarus bajo la pestaña **AI Agent**.

## Agentes Inteligentes Autónomos y Toma de Decisiones.
Estructura de orquestación cognitiva que planifica acciones y mapea salidas físicas utilizando RTTI dinámico.

### Referencia Detallada de Componentes

| Componente | Descripción | Propiedades Importantes | Métodos Principales | Rol del Agente de IA |
|---|---|---|---|---|
| **TAIAgent** | Cerebro del Agente cognitivo. | `ChatGPT, Options, Action, SystemPrompt` | `Execute(const AInputData: string): Boolean` | Analizar telemetría y planificar acciones autónomas. |
| **TAIAgentResource** | Repositorio de dispositivos y hardware vinculados. | `Resources (Collection)` | `FindResource(const AName: string): TAIAgentResourceItem` | Mapear canales físicos (correo, redes, sensores) para la IA. |
| **TAIAgentOutput** | Disparador automático de canales de salida. | `Action, Resource, Mappings` | `ExecuteAction(const AActionName: string; AParams: TStrings): Boolean` | Conectar la decisión lógica de la IA con la ejecución de hardware. |

### 💻 Ejemplo de Código Lazarus (TAIAgent)

```pascal
var
  MyComponent: TAIAgent;
begin
  MyComponent := TAIAgent.Create(Self);
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
