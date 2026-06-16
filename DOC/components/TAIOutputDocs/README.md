# TAIOutputDocs

## Finalidade

`TAIOutputDocs` centraliza geração de documentos a partir de texto ou resultados de IA.

Pode ser usado para gerar relatórios, respostas formatadas, registros de análise e exportações simples.

## Unit

```pascal
pacote/AI Output/aioutput_docs.pas
```

## Pacote

```text
openai_output.lpk
```

## Status

```text
Beta
```

## Propriedades principais

| Propriedade | Descrição |
|---|---|
| `Title` | Título do documento |
| `Author` | Autor do documento |
| `Subject` | Assunto do documento |
| `FileNamePDF` | Arquivo de saída PDF |
| `FileNameWord` | Arquivo de saída Word/compatível |
| `FileNameExcel` | Arquivo de saída Excel/compatível |
| `FileNameTXT` | Arquivo de saída TXT |
| `LastError` | Último erro |
| `LastResult` | Último resultado |

## Métodos principais

| Método | Descrição |
|---|---|
| `GeneratePDF` | Gera PDF |
| `GenerateWord` | Gera documento compatível com Word |
| `GenerateExcel` | Gera planilha/tabela compatível com Excel |
| `GenerateTXT` | Gera TXT |
| `GenerateAll` | Gera todos os formatos configurados |

## Exemplo

```pascal
procedure TForm1.Button1Click(Sender: TObject);
begin
  AIOutputDocs1.Title := 'Relatório de IA';
  AIOutputDocs1.Author := 'Sistema';
  AIOutputDocs1.FileNamePDF := 'relatorio.pdf';

  if AIOutputDocs1.GeneratePDF('Conteúdo gerado pela IA') then
    ShowMessage('PDF gerado')
  else
    ShowMessage(AIOutputDocs1.LastError);
end;
```

## Observações

* Verifique se Word/Excel são arquivos nativos ou HTML compatível com extensão `.docx`/`.xlsx`.
* Documente claramente o formato real gerado para evitar promessa incorreta.
