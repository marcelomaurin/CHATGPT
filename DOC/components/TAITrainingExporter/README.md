# TAITrainingExporter

## Finalidade

`TAITrainingExporter` exporta dados preparados para treinamento, validação ou uso posterior em ferramentas externas.

## Unit

```pascal
pacote/IA Graph/aitrainingexporter.pas
```

## Pacote

```text
openai_graph.lpk
```

## Status

```text
Experimental
```

## Propriedades principais

| Propriedade | Descrição |
|---|---|
| `OutputFile` | Arquivo de saída |
| `Format` | Formato de exportação, conforme implementação |
| `LastError` | Último erro |
| `LastResult` | Último resultado |

## Métodos principais

| Método | Descrição |
|---|---|
| `Export` | Exporta os dados configurados |
| `Clear` | Limpa estado interno, quando disponível |

## Exemplo

```pascal
procedure TForm1.Button1Click(Sender: TObject);
begin
  AITrainingExporter1.OutputFile := 'dataset.json';

  if AITrainingExporter1.Export then
    ShowMessage('Exportado')
  else
    ShowMessage(AITrainingExporter1.LastError);
end;
```

## Limitações

* API em evolução.
* Validar formatos realmente suportados pela implementação atual.
