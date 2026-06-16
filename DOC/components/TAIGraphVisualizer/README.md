# TAIGraphVisualizer

## Finalidade

`TAIGraphVisualizer` exporta ou prepara visualização de grafos gerados por componentes da suíte.

## Unit

```pascal
pacote/AI Graph/aigraphvisualizer.pas
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
| `LastResult` | Resultado textual |

## Métodos principais

| Método | Descrição |
|---|---|
| `Export` | Exporta grafo para formato suportado |
| `Clear` | Limpa estado interno, quando disponível |

## Exemplo

```pascal
procedure TForm1.Button1Click(Sender: TObject);
begin
  AIGraphVisualizer1.OutputFile := 'grafo.dot';

  if AIGraphVisualizer1.Export then
    ShowMessage('Grafo exportado')
  else
    ShowMessage(AIGraphVisualizer1.LastError);
end;
```

## Limitações

* API experimental.
* Validar formatos suportados antes de uso real.
