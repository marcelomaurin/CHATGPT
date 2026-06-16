# TAICodeAssistant

## Finalidade

`TAICodeAssistant` auxilia na análise, explicação, revisão e geração de código usando um componente LLM associado.

## Unit

```pascal
pacote/AI/aicodeassistant.pas
```

## Pacote

```text
openai_core.lpk
```

## Status

```text
Beta
```

## Propriedades principais

| Propriedade | Descrição |
|---|---|
| `Prompt` | Orientação padrão do assistente |
| `ChatGPT` | Componente LLM usado para responder |
| `LastError` | Último erro |
| `LastResult` | Última resposta |

## Métodos principais

| Método | Descrição |
|---|---|
| `ExplainCode` | Explica trecho de código |
| `ReviewCode` | Faz revisão técnica |
| `GenerateCode` | Gera código a partir de instrução |
| `DocumentCode` | Gera documentação/comentários |

## Exemplo

```pascal
CodeAssistant1.ChatGPT := ChatGPT1;
MemoResultado.Lines.Text := CodeAssistant1.ExplainCode(MemoCodigo.Lines.Text);
```

## Limitações

* A qualidade depende do provedor/modelo configurado no `TCHATGPT`.
* Código gerado deve sempre ser revisado e testado pelo programador.
