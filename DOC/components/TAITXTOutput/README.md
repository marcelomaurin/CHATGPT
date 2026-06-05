# TAITXTOutput

## Finalidade

`TAITXTOutput` gera arquivos de texto simples a partir de conteúdo produzido por IA ou pelo sistema.

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
Stable/Beta
```

## Propriedades principais

| Propriedade | Descrição |
|---|---|
| `FileName` | Caminho do arquivo TXT |
| `LastError` | Último erro |
| `LastResult` | Último resultado |

## Métodos principais

| Método | Descrição |
|---|---|
| `Generate` | Gera arquivo TXT |

## Exemplo

```pascal
procedure TForm1.Button1Click(Sender: TObject);
begin
  AITXTOutput1.FileName := 'saida.txt';

  if AITXTOutput1.Generate(Memo1.Lines.Text) then
    ShowMessage('TXT gerado')
  else
    ShowMessage(AITXTOutput1.LastError);
end;
```

## Observações

É o formato de saída mais simples e recomendado para testes iniciais.
