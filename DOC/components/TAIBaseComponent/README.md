# TAIBaseComponent

## Finalidade

`TAIBaseComponent` é a classe base comum para componentes de IA não visuais da suíte.

Use esta classe como base para novos componentes que precisam de `Prompt`, log, erro e resultado padronizados.

## Unit

```pascal
pacote/AI/aibase.pas
```

## Pacote

```text
openai_core.lpk
```

## Status

```text
Stable
```

## Propriedades principais

| Propriedade | Tipo | Descrição |
|---|---|---|
| `Prompt` | `string` | Descrição orientativa do componente para IA/agentes |
| `LastError` | `string` | Último erro registrado |
| `LastResult` | `string` | Último resultado textual |
| `LastSuccess` | `Boolean` | Indica se a última operação teve sucesso |
| `Category` | `TAIComponentCategory` | Categoria lógica do componente |
| `OnLog` | evento | Evento para mensagens de log |

## Métodos importantes

| Método | Descrição |
|---|---|
| `ClearError` | Limpa o estado de erro |
| `SetError` | Registra erro e marca `LastSuccess := False` |
| `Log` | Envia mensagem para `OnLog`, se atribuído |

## Exemplo

```pascal
procedure TMeuComponente.Executar;
begin
  ClearError;
  try
    LastResult := 'Processado com sucesso';
    LastSuccess := True;
    Log(llInfo, LastResult);
  except
    on E: Exception do
      SetError(E.Message);
  end;
end;
```

## Observações

Novos componentes devem herdar de `TAIBaseComponent` sempre que possível para manter padronização de erro, log e documentação via `Prompt`.
