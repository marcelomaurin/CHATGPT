# 📁 Documentation de l'onglet AI Files

> [!NOTE]
> Ce dossier contient la suite de composants Lazarus sous l'onglet **AI Files**.

## Scan de Fichiers et Gestion Documentaire.
Composants pour l'analyse de répertoires locaux et la gestion structurée des documents (Groups/Subgroups) pour l'indexation et le RAG.

### Référence Détaillée des Composants

| Composant | Description | Propriétés Importantes | Méthodes Principales | Rôle de l'Agent d'IA |
|---|---|---|---|---|
| **TAIDiskTreeScanner** | Scanner local d'arborescence de fichiers. | `TargetFolder, ShowProgress, IncludeSubfolders` | `Scan, StopScan` | Scanner les répertoires locaux et indexer les fichiers pour préparer les jeux de données IA. |
| **TAI_DOCFILESMANAGER** | Gestionnaire physique de fichiers et de documents. | `StoragePath, Groups, AutoCreateDirs, AllowOverwrite, MaxGroupNameLength` | `Initialize, AddGrupo, AddSubGrupo, UploadSubGrupo, GetDocument, GetFullDocument` | Organiser les fichiers de documentation locaux pour le RAG et l'entraînement. |

### 💻 Exemple de Code Lazarus (TAIDiskTreeScanner)

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


### ⚡ Pont d'IA et de Matériel
Chacun de ces composants intègre une propriété published `Prompt` documentant de manière transparente son API interne pour guider les agents d'IA (`TAIAgent`) de façon autonome.
