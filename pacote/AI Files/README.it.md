# 📁 Documentazione della Scheda AI Files

> [!NOTE]
> Questa cartella contiene la suite di componenti Lazarus sotto la scheda **AI Files**.

## Scansione File e Gestione Documentale.
Componenti per la scansione di directory locali e la gestione strutturata dei documenti (Groups/Subgroups) per indicizzazione e RAG.

### Riferimento Dettagliato dei Componenti

| Componente | Descrizione | Proprietà Importanti | Metodi Principali | Ruolo dell'Agente di IA |
|---|---|---|---|---|
| **TAIDiskTreeScanner** | Scansionatore locale dell'albero dei file. | `TargetFolder, ShowProgress, IncludeSubfolders` | `Scan, StopScan` | Scansionare le directory locali e indicizzare i file per preparare i dataset di IA. |
| **TAI_DOCFILESMANAGER** | Gestore fisico di file e documenti. | `StoragePath, Groups, AutoCreateDirs, AllowOverwrite, MaxGroupNameLength` | `Initialize, AddGrupo, AddSubGrupo, UploadSubGrupo, GetDocument, GetFullDocument` | Organizzare i file di documentazione locali per l'uso con RAG e addestramento. |

### 💻 Esempio di Codice Lazarus (TAIDiskTreeScanner)

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


### ⚡ Ponte di IA e Hardware
Ciascuno di questi componenti include una proprietà published `Prompt` che documenta in modo trasparente le proprie API interne per orientare gli Agenti IA (`TAIAgent`) autonomamente.
