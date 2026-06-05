# TAIWordOutput

## Finalidade

`TAIWordOutput` gera documento compatível com Word a partir de texto ou conteúdo estruturado.

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
| `Author` | Autor |
| `Subject` | Assunto |
| `LastError` | Último erro |
| `LastResult` | Último resultado |

## Métodos principais

| Método | Descrição |
|---|---|
| `Generate` | Gera documento compatível com Word |

## Exemplo

```pascal
procedure TForm1.Button1Click(Sender: TObject);
begin
  AIWordOutput1.FileName := 'relatorio.docx';
  AIWordOutput1.Title := 'Relatório de IA';

  if AIWordOutput1.Generate('Conteúdo do relatório') then
    ShowMessage('Documento gerado')
  else
    ShowMessage(AIWordOutput1.LastError);
end;
```

## Observações

Confirme no código se a saída é DOCX nativo ou HTML compatível salvo com extensão `.docx`.

A documentação e a interface devem deixar isso claro para o programador.
