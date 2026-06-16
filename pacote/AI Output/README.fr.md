# 📄 Documentation de l'onglet AI Output

> [!NOTE]
> Ce dossier contient la suite de composants Lazarus sous l'onglet **AI Output**.

## Sortie Structurée de Résultats, Traitement Décisionnel et Génération de Documents.
Génère d'élégants rapports d'IA natifs dans plusieurs formats (.pdf, .docx, .xlsx, .txt) sans dépendances externes.

### Référence Détaillée des Composants

| Composant | Description | Propriétés Importantes | Méthodes Principales | Rôle de l'Agent d'IA |
|---|---|---|---|---|
| **TAIOutputData** | Processeur de décision et activation SoftMax. | `Classes, Probabilities` | `SoftMax, GetBestClassIndex, GetBestClassName` | Déterminer la prédiction la plus probable et formater les résultats analytiques. |
| **TAIPDFOutput** | Générateur de documents PDF natif. | `FileName, Title, Author` | `StartDocument, AddPage, AddText, SavePDF` | Générer des rapports formels et des documents PDF imprimables. |
| **TAIWordOutput** | Générateur de rapports Word (.docx) natif. | `FileName, Title` | `AddHeading, AddParagraph, AddTable, SaveWord` | Exporter des résumés textuels et des tableaux structurés compatibles MS Word. |
| **TAIExcelOutput** | Générateur de feuilles de calcul Excel (.xlsx) natif. | `FileName` | `SetCell, SaveExcel` | Exporter des données tabulaires denses, des statistiques et métriques. |
| **TAITXTOutput** | Formateur de texte ASCII brut. | `FileName` | `AddLine, AddHeader, SaveText` | Générer des résumés légers en texte brut pour les fichiers de log. |
| **TAIOutputDocs** | Suite de sortie de documents unifiée. | `Title, Author, Subject` | `AddParagraph, AddTable, SaveAll` | Générer les quatre formats de documents simultanément dans un seul flux de pipeline. |

### 💻 Exemple de Code Lazarus (TAIOutputData)

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


### ⚡ Pont d'IA et de Matériel
Chacun de ces composants intègre une propriété published `Prompt` documentant de manière transparente son API interne pour guider les agents d'IA (`TAIAgent`) de façon autonome.
