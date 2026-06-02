# 🖼️ Documentación de la Pestaña IA Image

> [!NOTE]
> Esta carpeta contiene la suite de componentes de Lazarus bajo la pestaña **IA Image**.

## Visión Computacional y Filtros Digitales de Imagen.
Filtros avanzados de preparación matricial de imágenes para procesamiento neural de visión.

### Referencia Detallada de Componentes

| Componente | Descripción | Propiedades Importantes | Métodos Principales | Rol del Agente de IA |
|---|---|---|---|---|
| **TAIImageFilters** | Filtro de imagen matricial digital. | `FilterType (Sobel, Canny, Gaussian, Grayscale)` | `ApplyFilter(const AInputBmp, AOutputBmp: TBitmap): Boolean` | Preprocesar imágenes y cuadros de cámara para mejorar las tasas de reconocimiento. |

### 💻 Ejemplo de Código Lazarus (TAIImageFilters)

```pascal
var
  MyComponent: TAIImageFilters;
begin
  MyComponent := TAIImageFilters.Create(Self);
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
