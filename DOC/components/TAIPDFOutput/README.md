# TAIPDFOutput

## Finalidade

`TAIPDFOutput` gera arquivos PDF a partir de texto ou conteúdo estruturado.

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
| `FileName` | Caminho do PDF de saída |
| `Title` | Título do documento |
| `Author` | Autor |
| `Subject` | Assunto |
| `LastError` | Último erro |
| `LastResult` | Último resultado |

## Métodos principais

| Método | Descrição |
|---|---|
| `Generate` | Gera arquivo PDF |

## Exemplo

```pascal
procedure TForm1.Button1Click(Sender: TObject);
begin
  AIPDFOutput1.FileName := 'saida.pdf';
  AIPDFOutput1.Title := 'Relatório';

  if AIPDFOutput1.Generate('Texto do relatório') then
    ShowMessage('PDF gerado')
  else
    ShowMessage(AIPDFOutput1.LastError);
end;
```

## Observações

Verifique as dependências PDF usadas pelo pacote e teste fontes/acentuação no ambiente final.
