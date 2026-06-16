# TAIAgentExecutor

## Finalidade

`TAIAgentExecutor` representa a camada de execução de ações decididas por agentes.

Ele deve ser usado como ponto de integração entre uma decisão estruturada do `TAIAgent` e uma ação real ou simulada no sistema.

## Unit

```pascal
pacote/AI Agent/aiagent_executors.pas
```

## Pacote

```text
openai_agent.lpk
```

## Status

```text
Experimental
```

## Propriedades principais

| Propriedade | Descrição |
|---|---|
| `Prompt` | Descrição do executor para uso por agentes |
| `LastError` | Último erro |
| `LastResult` | Último resultado |

## Métodos principais

| Método | Descrição |
|---|---|
| `Execute` | Executa ou simula uma ação conforme implementação |
| `CanExecute` | Verifica se a ação pode ser executada |

## Exemplo

```pascal
procedure TForm1.Button1Click(Sender: TObject);
begin
  if AIAgentSafety1.SimulationMode then
    ShowMessage('Executando apenas em modo simulado.');

  // A execução real deve validar permissões antes de qualquer ação.
end;
```

## Segurança

Antes de executar qualquer ação real, valide:

* `TAIAgentSafety` associado;
* modo simulação;
* permissão de arquivo, rede, e-mail ou industrial;
* confirmação do usuário quando necessário.

## Limitações

* API ainda experimental.
* Não deve executar ações sensíveis sem segurança explícita.
