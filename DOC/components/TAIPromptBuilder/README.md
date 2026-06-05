# TAIPromptBuilder

## Finalidade

`TAIPromptBuilder` monta prompts padronizados para uso com LLMs, agentes e pipelines.

Use quando precisar organizar contexto, instruções, formato de resposta e conteúdo do usuário antes de enviar ao `TCHATGPT`.

## Unit

```pascal
pacote/IA/aipromptbuilder.pas
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
| `Prompt` | Descrição/orientação do componente |
| `SystemPrompt` | Instrução de sistema |
| `UserPrompt` | Texto principal do usuário |
| `Context` | Contexto complementar |
| `OutputFormat` | Formato esperado da resposta |
| `LastResult` | Prompt final montado |
| `LastError` | Último erro |

## Métodos principais

| Método | Descrição |
|---|---|
| `Build` | Monta o prompt final |
| `Clear` | Limpa campos temporários |

## Exemplo

```pascal
PromptBuilder1.SystemPrompt := 'Você é um revisor técnico.';
PromptBuilder1.Context := 'Projeto Lazarus com componentes IA.';
PromptBuilder1.UserPrompt := 'Revise este código.';
PromptBuilder1.OutputFormat := 'Resposta em tópicos.';

Memo1.Lines.Text := PromptBuilder1.Build;
```

## Observações

Padronizar prompts reduz respostas inconsistentes e melhora integração com agentes e pipelines.
