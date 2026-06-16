# 📐 Documentación de la Pestaña AI Math

> [!NOTE]
> Esta carpeta contiene la suite de componentes de Lazarus bajo la pestaña **AI Math**.

## Álgebra Vectorial y Matricial de Alta Velocidad.
Implementa rutinas matemáticas de procesamiento de tensores similares a la biblioteca NumPy de Python.

### Referencia Detallada de Componentes

| Componente | Descripción | Propiedades Importantes | Métodos Principales | Rol del Agente de IA |
|---|---|---|---|---|
| **TNumPS** | Generador y manipulador de matrices y vectores. | `ThreadSafe` | `Zeros, Ones, Eye, MatMul, Sum, Mean, Std, Random` | Realizar operaciones matemáticas pesadas y álgebra lineal para la IA. |

### 💻 Ejemplo de Código Lazarus (TNumPS)

```pascal
var
  MyComponent: TNumPS;
begin
  MyComponent := TNumPS.Create(Self);
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
