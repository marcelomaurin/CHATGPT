# 📄 Documentación de la Pestaña AI Output

> [!NOTE]
> Esta carpeta contiene la suite de componentes de Lazarus bajo la pestaña **AI Output**.

## Salida Estructurada de Resultados, Decisiones y Generación de Documentos.
Genera informes nativos elegantes de IA en múltiples formatos (.pdf, .docx, .xlsx, .txt) sin requisitos externos.

### Referencia Detallada de Componentes

| Componente | Descripción | Propiedades Importantes | Métodos Principales | Rol del Agente de IA |
|---|---|---|---|---|
| **TAIOutputData** | Procesador de decisiones y SoftMax. | `Classes, Probabilities` | `SoftMax, GetBestClassIndex, GetBestClassName` | Determinar la predicción de mayor probabilidad y formatear resultados estructurales. |
| **TAIPDFOutput** | Generador de documentos PDF nativo. | `FileName, Title, Author` | `StartDocument, AddPage, AddText, SavePDF` | Generar informes formales y documentos PDF listos para imprimir. |
| **TAIWordOutput** | Generador de informes Word (.docx) nativo. | `FileName, Title` | `AddHeading, AddParagraph, AddTable, SaveWord` | Exportar resúmenes de texto densos y tablas estructuradas compatibles con Word/LibreOffice. |
| **TAIExcelOutput** | Generador de hojas de cálculo Excel (.xlsx) nativo. | `FileName` | `SetCell, SaveExcel` | Exportar datos tabulares densos y métricas de rendimiento estadístico. |
| **TAITXTOutput** | Formateador de texto plano ASCII puro. | `FileName` | `AddLine, AddHeader, SaveText` | Generar registros de texto plano rápidos y livianos. |
| **TAIOutputDocs** | Suite unificada de salida de informes. | `Title, Author, Subject` | `AddParagraph, AddTable, SaveAll` | Generar todos los 4 formatos de documentos anteriores en una sola llamada de pipeline. |

### 💻 Ejemplo de Código Lazarus (TAIOutputData)

```pascal
var
  MyComponent: TAIOutputData;
begin
  MyComponent := TAIOutputData.Create(Self);
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
