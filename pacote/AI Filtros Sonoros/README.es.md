# 🎵 Documentación de la Pestaña AI Filtros Sonoros

> [!NOTE]
> Esta carpeta contiene la suite de componentes de Lazarus bajo la pestaña **AI Filtros Sonoros**.

## Procesamiento de Señales de Audio y Filtros Digitales.
Módulo para la transformación de frecuencias sonoras y la aplicación de filtros lineales rápidos.

### Referencia Detallada de Componentes

| Componente | Descripción | Propiedades Importantes | Métodos Principales | Rol del Agente de IA |
|---|---|---|---|---|
| **TAISoundFilters** | Procesador de señales de sonido. | `FilterType (LowPass, HighPass, BandPass), CutoffFrequency` | `ApplyFilter(const AInputWav, AOutputWav: string): Boolean` | Limpiar ruidos de fondo y ajustar frecuencias de grabaciones obtenidas de micrófonos. |

### 💻 Ejemplo de Código Lazarus (TAISoundFilters)

```pascal
var
  MyComponent: TAISoundFilters;
begin
  MyComponent := TAISoundFilters.Create(Self);
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
