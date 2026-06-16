# 📁 Documentación de la Pestaña AI Files

> [!NOTE]
> Esta carpeta contiene la suite de componentes de Lazarus bajo la pestaña **AI Files**.

## Escaneo de Archivos y Gestión de Documentación.
Componentes para el escaneo de directorios locales y la gestión estructurada de documentos (Groups/Subgroups) para indexación y RAG.

### Referencia Detallada de Componentes

| Componente | Descripción | Propiedades Importantes | Métodos Principales | Rol del Agente de IA |
|---|---|---|---|---|
| **TAIDiskTreeScanner** | Escáner de árbol de archivos local. | `TargetFolder, ShowProgress, IncludeSubfolders` | `Scan, StopScan` | Escanear directorios locales e indexar archivos para preparar datasets de IA. |
| **TAI_DOCFILESMANAGER** | Gestor físico de archivos y documentaciones. | `StoragePath, Groups, AutoCreateDirs, AllowOverwrite, MaxGroupNameLength` | `Initialize, AddGrupo, AddSubGrupo, UploadSubGrupo, GetDocument, GetFullDocument` | Organizar archivos de documentación locales para su uso con RAG y entrenamiento. |

### 💻 Ejemplo de Código Lazarus (TAIDiskTreeScanner)

```pascal
var
  MyComponent: TAIDiskTreeScanner;
begin
  MyComponent := TAIDiskTreeScanner.Create(Self);
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
