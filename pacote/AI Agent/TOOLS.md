# Tools do Agent

`aitools.pas` fornece um fluxo controlado para chamadas de ferramentas:

```text
TAIToolCall -> TAIAgentSafety -> TAIToolRegistry -> confirmação/política
            -> handler TAITool -> TAIToolResult
```

## Tipos

- `TAITool`: `Name`, `Description`, `ParametersSchema`, `Risk`, `Policy` e
  `OnExecute`.
- `TAIToolCall`: `CallID`, `ToolName` e objeto JSON `Arguments`. Aceita tanto
  o formato `{id, tool, arguments}` quanto `{id, function:{name,arguments}}`.
- `TAIToolResult`: resultado estruturado com `Success`, `ErrorText`, `Output`
  e `Data` JSON, preservando `CallID`.
- `TAIToolRegistry`: registra, localiza, enumera, valida e executa tools. Os
  nomes são únicos sem distinção de maiúsculas/minúsculas; quando `AddTool`
  retorna `True`, o registry assume o ownership da instância.

`ParametersSchema` usa o subconjunto necessário de JSON Schema: objeto
`properties`, `required` e tipos `string`, `number`, `integer`, `boolean`,
`object`, `array` e `null`.

## Política de segurança

Cada tool informa um risco: `Safe`, `Read`, `Update`, `Delete`, `Execute`,
`Email` ou `Filesystem`. Tools seguras/de leitura são permitidas por padrão;
as demais exigem `OnConfirmTool`. O registry permite configurar cada categoria
como `Allow`, `Confirm` ou `Block`, e `TAITool.Policy` pode sobrescrever a regra
para uma ferramenta específica.

Quando a execução passa por `TAIAgent.ExecuteToolCall` ou
`ExecuteToolJSON`, a chamada também é validada pelo `TAIAgentSafety` associado.
Uma confirmação ausente equivale a rejeição; nenhuma operação sensível é
executada silenciosamente.

Veja `samples/AI Agent/tool_call_demo` para uma soma segura e uma operação de
exclusão que é primeiro rejeitada e depois aprovada.
