# TAIProject

## Finalidade

`TAIProject` representa a estrutura lógica de um projeto de IA dentro da suíte.

Use para organizar nome, descrição, componentes relacionados e metadados de um projeto IA em aplicações Lazarus.

## Unit

```pascal
pacote/IA/aiproject.pas
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
| `Prompt` | Descrição orientativa |
| `LastError` | Último erro |
| `LastResult` | Último resultado |

## Métodos principais

| Método | Descrição |
|---|---|
| `Clear` | Limpa estado do projeto, quando implementado |
| `Load` | Carrega dados do projeto, quando implementado |
| `Save` | Salva dados do projeto, quando implementado |

## Exemplo

```pascal
AIProject1.Prompt := 'Projeto de classificação de chamados com IA.';
```

## Limitações

* API ainda em evolução.
* Deve ser usada como estrutura de organização, não como motor de IA.
