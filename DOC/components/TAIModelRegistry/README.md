# TAIModelRegistry

## Finalidade

`TAIModelRegistry` organiza modelos, provedores, endpoints e parâmetros padrão para uso por componentes de IA.

Use quando a aplicação precisar manter uma lista central de modelos disponíveis.

## Unit

```pascal
pacote/IA/aimodelregistry.pas
```

## Pacote

```text
openai_core.lpk
```

## Status

```text
Experimental
```

## Propriedades principais

| Propriedade | Descrição |
|---|---|
| `Prompt` | Descrição do componente |
| `LastError` | Último erro |
| `LastResult` | Último resultado |

## Métodos principais

| Método | Descrição |
|---|---|
| `AddModel` | Adiciona modelo ao registro |
| `FindModel` | Localiza modelo por nome/chave |
| `Clear` | Limpa o registro |

## Exemplo

```pascal
ModelRegistry1.AddModel('local-llama', 'local', 'llama3.2:3b', 'http://localhost:11434/v1/chat/completions');
```

## Limitações

* API ainda pode mudar.
* Deve ser validado junto com `TCHATGPT` e `TAIWizardConfig`.
