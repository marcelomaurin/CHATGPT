# TAIExcelOutput

## Finalidade

`TAIExcelOutput` gera saída compatível com Excel para dados tabulares, listas ou relatórios simples.

## Unit

```pascal
pacote/IA Output/aioutput_docs.pas
```

## Pacote

```text
openai_output.lpk
```

## Status

```text
Beta/Compatível
```

## Propriedades principais

| Propriedade | Descrição |
|---|---|
| `FileName` | Arquivo de saída |
| `Title` | Título |
| `LastError` | Último erro |
| `LastResult` | Último resultado |

## Métodos principais

| Método | Descrição |
|---|---|
| `Generate` | Gera saída compatível com Excel |

## Exemplo

```pascal
procedure TForm1.Button1Click(Sender: TObject);
begin
  AIExcelOutput1.FileName := 'dados.xlsx';

  if AIExcelOutput1.Generate('Coluna1;Coluna2' + LineEnding + 'A;B') then
    ShowMessage('Planilha gerada')
  else
    ShowMessage(AIExcelOutput1.LastError);
end;
```

## Observações

Confirme no código se a saída é XLSX nativo ou HTML/CSV compatível salvo com extensão `.xlsx`.
