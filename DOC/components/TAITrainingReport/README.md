# TAITrainingReport

## Finalidade

`TAITrainingReport` gera relatórios técnicos sobre dados de treinamento, classificadores ou execuções de modelos.

## Unit

```pascal
pacote/AI Graph/aitrainingreport.pas
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
| `Title` | Título do relatório |
| `OutputFile` | Arquivo de saída |
| `LastError` | Último erro |
| `LastResult` | Resultado textual |

## Métodos principais

| Método | Descrição |
|---|---|
| `Generate` | Gera relatório conforme dados configurados |
| `Clear` | Limpa estado interno, quando disponível |

## Exemplo

```pascal
procedure TForm1.Button1Click(Sender: TObject);
begin
  AITrainingReport1.Title := 'Relatório de Treinamento';
  AITrainingReport1.OutputFile := 'training_report.txt';

  if AITrainingReport1.Generate then
    ShowMessage('Relatório gerado')
  else
    ShowMessage(AITrainingReport1.LastError);
end;
```

## Limitações

* API experimental.
* Validar quais métricas são realmente calculadas pela implementação atual.
