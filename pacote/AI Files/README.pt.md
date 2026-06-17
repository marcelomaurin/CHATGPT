# 📁 Documentação da Aba AI Files

> [!NOTE]
> Esta pasta contém a suíte de componentes do Lazarus sob a aba **AI Files**.

## Escaneamento de Arquivos e Gerenciamento de Documentação.
Componentes para varredura de diretórios locais e gerenciamento estruturado de documentos (Groups/Subgroups) para indexação e RAG.

### Referência Detalhada dos Componentes

| Componente | Descrição | Propriedades Importantes | Métodos Principais | Papel do Agente de IA |
|---|---|---|---|---|
| **TAIDiskTreeScanner** | Escaneador de árvore de arquivos local. | `TargetFolder, ShowProgress, IncludeSubfolders` | `Scan, StopScan` | Varrer diretórios locais e indexar arquivos para preparação de datasets de IA. |
| **TAI_DOCFILESMANAGER** | Gerenciador físico de arquivos e documentações. | `StoragePath, Groups, AutoCreateDirs, AllowOverwrite, MaxGroupNameLength` | `Initialize, AddGrupo, AddSubGrupo, UploadSubGrupo, GetDocument, GetFullDocument` | Organizar arquivos de documentação locais para uso com RAG e treinamento. |

### 💻 Exemplo de Código Lazarus (TAIDiskTreeScanner)

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


### ⚡ Ponte de IA e Hardware
Cada um destes componentes possui uma propriedade published `Prompt` que documenta sua API interna de forma transparente para orientar Agentes de IA (`TAIAgent`) de forma automática!

## 📸 Capturas de Tela

### Demo do TAI_DOCFILESMANAGER
![Demo do TAI_DOCFILESMANAGER](../../screenshots/docfilesmanager_demo.jpg)
