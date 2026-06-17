# 📁 Documentation for AI Files Tab

> [!NOTE]
> This folder contains the Lazarus components suite under the **AI Files** tab.

## File Scanning and Documentation Management.
Components for local directory scanning and structured document management (Groups/Subgroups) for indexing and RAG.

### Detailed Component Reference

| Component | Description | Important Properties | Main Methods | AI Agent Role |
|---|---|---|---|---|
| **TAIDiskTreeScanner** | Local file tree scanner. | `TargetFolder, ShowProgress, IncludeSubfolders` | `Scan, StopScan` | Scan local directories and index files to prepare AI datasets. |
| **TAI_DOCFILESMANAGER** | Physical document and file manager. | `StoragePath, Groups, AutoCreateDirs, AllowOverwrite, MaxGroupNameLength` | `Initialize, AddGrupo, AddSubGrupo, UploadSubGrupo, GetDocument, GetFullDocument` | Organize local documentation files for RAG and training. |

### 💻 Lazarus Code Example (TAIDiskTreeScanner)

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


### ⚡ AI and Hardware Bridge
Each of these components features a published `Prompt` property that transparently documents its internal API to guide AI Agents (`TAIAgent`) autonomously!

## 📸 Screenshots

### TAI_DOCFILESMANAGER Demo
![TAI_DOCFILESMANAGER Demo](../../screenshots/docfilesmanager_demo.jpg)
