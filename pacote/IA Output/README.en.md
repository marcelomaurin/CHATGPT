# 📄 Documentation for IA Output Tab

> [!NOTE]
> This folder contains the Lazarus components suite under the **IA Output** tab.

## Structured Output, Decision Processing and Document Generation.
Generates elegant native AI reports in multiple formats (.pdf, .docx, .xlsx, .txt) without external dependencies.

### Detailed Component Reference

| Component | Description | Important Properties | Main Methods | AI Agent Role |
|---|---|---|---|---|
| **TAIOutputData** | Decision maker and SoftMax activator. | `Classes, Probabilities` | `SoftMax, GetBestClassIndex, GetBestClassName` | Determine the highest probability prediction and format structural classification results. |
| **TAIPDFOutput** | Native PDF document generator. | `FileName, Title, Author` | `StartDocument, AddPage, AddText, SavePDF` | Generate formal reports and printable PDF documents. |
| **TAIWordOutput** | Native Word (.docx) report generator. | `FileName, Title` | `AddHeading, AddParagraph, AddTable, SaveWord` | Export text-rich summaries and tables fully compatible with MS Word. |
| **TAIExcelOutput** | Native Excel (.xlsx) spreadsheet generator. | `FileName` | `SetCell, SaveExcel` | Export tabular predictive data, statistics and metrics. |
| **TAITXTOutput** | Plain ASCII text formatter. | `FileName` | `AddLine, AddHeader, SaveText` | Generate light plain-text file logs. |
| **TAIOutputDocs** | Unified document exporter. | `Title, Author, Subject` | `AddParagraph, AddTable, SaveAll` | Generate all four document formats simultaneously in a single pipeline stream. |

### 💻 Lazarus Code Example (TAIOutputData)

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


### ⚡ AI and Hardware Bridge
Each of these components features a published `Prompt` property that transparently documents its internal API to guide AI Agents (`TAIAgent`) autonomously!
