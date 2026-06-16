# TAIDatasetAnalyzer

## Finalidade

`TAIDatasetAnalyzer` analisa a qualidade de datasets usados em treinamento, classificação ou processamento por IA.

## Unit

```pascal
pacote/AI Graph/aidatasetanalyzer.pas
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
| `InputFile` | Dataset de entrada |
| `LastError` | Último erro |
| `LastResult` | Resultado da análise |

## Métodos principais

| Método | Descrição |
|---|---|
| `Analyze` | Analisa o dataset configurado |
| `Clear` | Limpa estado interno, quando disponível |

## Exemplo

```pascal
procedure TForm1.Button1Click(Sender: TObject);
begin
  AIDatasetAnalyzer1.InputFile := 'dataset.json';

  if AIDatasetAnalyzer1.Analyze then
    Memo1.Lines.Text := AIDatasetAnalyzer1.LastResult
  else
    ShowMessage(AIDatasetAnalyzer1.LastError);
end;
```

## Limitações

* API experimental.
* Validar formatos de dataset suportados pela implementação atual.
