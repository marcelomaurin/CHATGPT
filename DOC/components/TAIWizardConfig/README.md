# TAIWizardConfig

## Finalidade

`TAIWizardConfig` fornece uma estrutura de assistente de configuração para preparar projetos de IA em Lazarus.

Use para orientar configuração inicial de provedor, modelo, endpoint, chave de API e tipo de projeto.

## Unit

```pascal
pacote/IA/aiwizardconfig.pas
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
| `Prompt` | Orientação do componente |
| `LastError` | Último erro |
| `LastResult` | Último resultado |

## Métodos principais

| Método | Descrição |
|---|---|
| `Execute` | Executa o fluxo de configuração, quando disponível |
| `Clear` | Limpa estado/configuração temporária |

## Exemplo

```pascal
if AIWizardConfig1.Execute then
  ShowMessage('Configuração concluída')
else
  ShowMessage(AIWizardConfig1.LastError);
```

## Limitações

* Componente em evolução.
* Validar integração com formulário visual `frm_aiwizardconfig`.
