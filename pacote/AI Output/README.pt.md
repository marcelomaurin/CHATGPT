# 📄 Documentação da Aba AI Output

> [!NOTE]
> Esta pasta contém a suíte de componentes do Lazarus sob a aba **AI Output**.

## Saída Estruturada de Resultados, Decisões e Geração de Documentos.
Gera relatórios nativos elegantes de IA em múltiplos formatos (.pdf, .docx, .xlsx, .txt) sem requisições externas.

### Referência Detalhada dos Componentes

| Componente | Descrição | Propriedades Importantes | Métodos Principais | Papel do Agente de IA |
|---|---|---|---|---|
| **TAIOutputData** | Decisor e ativador SoftMax. | `Classes, Probabilities` | `SoftMax, GetBestClassIndex, GetBestClassName` | Determinar a classe mais provável de saída e formatar resultados analíticos. |
| **TAIPDFOutput** | Gerador de documentos PDF nativo. | `FileName, Title, Author` | `StartDocument, AddPage, AddText, SavePDF` | Gerar relatórios formais e certificados em PDF prontos para impressão. |
| **TAIWordOutput** | Gerador de relatórios Word (.docx) nativo. | `FileName, Title` | `AddHeading, AddParagraph, AddTable, SaveWord` | Exportar resumos textuais e tabelas estruturadas compatíveis com Office/LibreOffice. |
| **TAIExcelOutput** | Gerador de planilhas Excel (.xlsx) nativo. | `FileName` | `SetCell, SaveExcel` | Exportar dados tabulares densos, métricas estatísticas e históricos de predição. |
| **TAITXTOutput** | Exportador de texto tabulado ASCII puro. | `FileName` | `AddLine, AddHeader, SaveText` | Gerar resumos leves em texto plano para logs rápidos ou envio por SMS. |
| **TAIOutputDocs** | Suite unificada de saída de relatórios. | `Title, Author, Subject` | `AddParagraph, AddTable, SaveAll` | Gerar todos os 4 formatos de documentos anteriores em uma única chamada de pipeline. |

### 💻 Exemplo de Código Lazarus (TAIOutputData)

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


### ⚡ Ponte de IA e Hardware
Cada um destes componentes possui uma propriedade published `Prompt` que documenta sua API interna de forma transparente para orientar Agentes de IA (`TAIAgent`) de forma automática!
