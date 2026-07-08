# 📄 Documentation de l'onglet `AI Output`

> [!NOTE]
> Ce dossier contient les composants Lazarus chargés de transformer les sorties d'IA en résultats exploitables : classification, rapports, documents, feuilles de calcul, texte et commandes d'impression.

L'onglet **AI Output** représente la couche de sortie du projet. Il n'exécute pas directement les modèles d'IA ; il organise, formate, exporte ou envoie les résultats produits par d'autres composants.

---

## Objectif

Fournir des composants pour :

- normaliser les probabilités et les résultats de classification ;
- générer des rapports en PDF, DOCX, XLSX et TXT ;
- créer, charger, modifier et enregistrer des documents Word/OpenXML ;
- prévisualiser des documents Word sur un canvas Lazarus ;
- envoyer de vraies commandes à des imprimantes POS, thermiques et d'étiquettes.

---

## Composants principaux

| Composant | Unité | Description | Propriétés importantes | Méthodes principales |
|---|---|---|---|---|
| **TAIOutputData** | `aioutput.pas` | Traite les probabilités et les résultats de classification. | `Classes`, `Probabilities`, `ClassificationResult` | `SoftMax`, `GetBestClassIndex`, `GetBestClassName`, `UpdateResult` |
| **TAIPDFOutput** | `aioutput_docs.pas` | Génère des documents PDF natifs avec `fpPDF`. | `FileName`, `Title`, `Author`, `Subject` | `StartDocument`, `AddPage`, `AddText`, `SavePDF` |
| **TAIWordOutput** | `aioutput_docs.pas` | Génère une sortie compatible Word/HTML. | `FileName`, `Title` | `AddHeading`, `AddParagraph`, `AddTable`, `SaveWord` |
| **TAIExcelOutput** | `aioutput_docs.pas` | Génère une sortie tabulaire compatible Excel. | `FileName` | `SetCell`, `SaveExcel` |
| **TAITXTOutput** | `aioutput_docs.pas` | Exporte du texte brut. | `FileName` | `AddLine`, `AddHeader`, `Clear`, `SaveText` |
| **TAIOutputDocs** | `aioutput_docs.pas` | Centralise plusieurs formats de documents. | `FileNamePDF`, `FileNameWord`, `FileNameExcel`, `FileNameTXT`, `Title`, `Author`, `Subject` | `AddHeading`, `AddParagraph`, `AddTable`, `SetCell`, `SaveAll` |
| **TAIWordDocument** | `aiworddocument.pas` | Crée, ouvre, modifie et enregistre des fichiers DOCX avec OpenXML. | `FileName`, `Title`, `Author`, `Subject`, `PreserveUnsupportedXml` | `NewDocument`, `LoadFromFile`, `SaveToFile`, `AddParagraph`, `AddImage`, `AddTable`, `ReplaceText`, `SetVariable`, `ApplyVariables` |
| **TAIWordLayoutEngine** | `aiwordviewer.pas` | Construit le modèle visuel des pages d'un document Word. | `Pages`, `Zoom`, `DPI` | `BuildLayout`, `Clear` |
| **TAIWordRenderEngine** | `aiwordviewer.pas` | Rend les pages, paragraphes, images et tableaux sur `TCanvas`. | — | `RenderPage`, `RenderParagraph`, `RenderImage`, `RenderTable` |
| **TAIPOSPrinter** | `aiposprinter.pas` | Envoie des commandes brutes aux imprimantes POS, thermiques et d'étiquettes. | `InterfaceType`, `PrinterModel`, `Protocol`, `DeviceName`, `Host`, `Port`, `SerialBaud`, `Active`, `LastError` | `OpenConnection`, `CloseConnection`, `PrintTextLine`, `PrintBarcode`, `PrintQRCode`, `CutPaper`, `OpenDrawer`, `Beep` |

---

## Impression : concepts corrects

L'impression doit séparer trois concepts différents.

| Concept | Signification | Exemples |
|---|---|---|
| **Langage d'imprimante** | Commandes comprises par le firmware. | ESC/POS, ZPL, TSPL/TSPL2, EPL/EPL2 |
| **Transport** | Chemin utilisé pour envoyer les octets. | Série, TCP 9100, USB raw, spooler, fichier |
| **Mode de rendu** | Manière de produire le contenu avant l'envoi. | Commandes brutes ou canvas du système d'exploitation |

`Native OS` **n'est pas un protocole d'imprimante**. Il représente l'impression via le système d'exploitation, par exemple avec `Printer.Canvas` de Lazarus.

---

## Langages d'impression

| Langage | Usage correct | Observations |
|---|---|---|
| **ESC/POS** | Imprimantes thermiques de reçus/POS. | Texte, QR Code, codes-barres, tiroir-caisse et coupe papier. |
| **ZPL** | Imprimantes d'étiquettes Zebra ou compatibles. | L'étiquette commence généralement par `^XA` et se termine par `^XZ`. |
| **TSPL/TSPL2** | Imprimantes d'étiquettes TSC ou compatibles. | Utilise `SIZE`, `GAP`, `CLS`, `TEXT`, `BARCODE`, `QRCODE`, `PRINT`. |
| **EPL/EPL2** | Anciennes imprimantes Eltron/Zebra. | À conserver comme expérimental jusqu'à validation du modèle. |
| **Native OS** | Spooler/canvas du système d'exploitation. | Ne doit pas envoyer directement des commandes ESC/POS/ZPL/TSPL. |

---

## Recommandations pour `TAIPOSPrinter`

- Séparer langage, transport et mode de rendu.
- `OpenConnection` doit ouvrir la connexion, pas démarrer un document.
- Séparer `CutPaper` de `PrintLabel`.
- Générer des octets (`TBytes`), pas des chaînes ordinaires.
- Afficher de vraies erreurs lorsque la connexion ou l'envoi échoue.
- Ne jamais signaler un succès si aucune commande n'a été générée ou envoyée.

Modèle recommandé :

```pascal
TPrinterLanguage = (plEscPos, plZpl, plTspl, plEpl);
TPrinterTransport = (ptSerial, ptTcp9100, ptFile, ptWindowsRawSpooler, ptCupsRaw);
TPrinterRenderMode = (rmRawCommand, rmNativeCanvas);
```

---

## Exemple associé

```text
pacote/samples/AI Output/posprinter_demo
```

Le demo doit évoluer de `Simulation Mode` vers :

```text
Preview only
```

Comportement attendu :

- `Preview only = True` : générer de vraies commandes et les afficher en texte/hex.
- `Preview only = False` : générer les mêmes commandes et les envoyer au transport sélectionné.
- Ne jamais afficher un succès si aucune commande n'a été envoyée.

---

## Pont IA et matériel

Les composants de **AI Output** utilisent la propriété published `Prompt` pour documenter leur API interne. Cela permet aux agents (`TAIAgent`) de comprendre quelles propriétés configurer et quelles méthodes exécuter.
