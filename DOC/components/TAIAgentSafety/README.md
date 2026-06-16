# TAIAgentSafety

## Finalidade

`TAIAgentSafety` define regras de segurança para agentes, bloqueando ou permitindo ações sensíveis.

## Unit

```pascal
pacote/AI Agent/aiagentsafety.pas
```

## Pacote

```text
openai_agent.lpk
```

## Status

```text
Beta
```

## Propriedades principais

| Propriedade | Descrição |
|---|---|
| `ReadOnlyMode` | Impede ações de escrita quando ativo |
| `SimulationMode` | Executa decisões em modo simulado |
| `AllowFileWrite` | Permite escrita em arquivos |
| `AllowNetwork` | Permite acesso de rede |
| `AllowIndustrialWrite` | Permite escrita industrial |
| `AllowEmailSend` | Permite envio de e-mail |
| `LastError` | Último erro |
| `LastResult` | Último resultado |

## Métodos principais

| Método | Descrição |
|---|---|
| `CanExecuteAction` | Verifica se uma ação pode ser executada conforme regras de segurança |

## Exemplo

```pascal
procedure TForm1.FormCreate(Sender: TObject);
begin
  AIAgentSafety1.ReadOnlyMode := True;
  AIAgentSafety1.SimulationMode := True;
  AIAgentSafety1.AllowFileWrite := False;
  AIAgentSafety1.AllowNetwork := False;
  AIAgentSafety1.AllowIndustrialWrite := False;
  AIAgentSafety1.AllowEmailSend := False;
end;
```

## Observações

Este componente deve ser associado a `TAIAgent` sempre que o agente puder decidir ações sobre recursos externos.
