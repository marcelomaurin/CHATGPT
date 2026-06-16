# TAIOutputData

## Finalidade

`TAIOutputData` representa uma saída estruturada para resultados produzidos por IA, pipelines ou componentes auxiliares.

Use para centralizar texto, JSON, listas ou dados processados antes de enviar para documentos, UI, arquivos ou integrações.

## Unit

```pascal
pacote/AI Output/aioutput.pas
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
| `Prompt` | Descrição do componente para IA/agentes |
| `LastError` | Último erro |
| `LastResult` | Último resultado textual |

## Métodos principais

| Método | Descrição |
|---|---|
| `Clear` | Limpa estado ou saída |
| `SetOutput` | Define conteúdo de saída, conforme implementação |
| `AsText` | Retorna saída em texto, quando disponível |

## Exemplo

```pascal
procedure TForm1.Button1Click(Sender: TObject);
begin
  AIOutputData1.LastResult := ChatGPT1.SendQuestion('Resuma o chamado técnico.');
  Memo1.Lines.Text := AIOutputData1.LastResult;
end;
```

## Observações

Use `TAIOutputDocs` quando precisar gerar arquivos PDF, TXT, Word compatível ou Excel compatível.
