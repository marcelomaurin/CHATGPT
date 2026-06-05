# TAIAgent

## Finalidade

`TAIAgent` orquestra decisões baseadas em LLM e pode selecionar ações estruturadas para executar tarefas.

Deve ser usado com cuidado porque agentes podem acionar recursos externos.

## Unit

```pascal
pacote/IA Agent/aiagent.pas
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
| `ChatGPT` | Componente LLM usado pelo agente |
| `Options` | Contexto e regras de decisão |
| `Safety` | Componente de segurança associado |
| `LastError` | Último erro |
| `LastResult` | Último resultado textual |

## Métodos principais

| Método | Descrição |
|---|---|
| `Run` | Executa decisão do agente |
| `RunText` | Executa agente a partir de entrada textual |

## Exemplo

```pascal
procedure TForm1.Button1Click(Sender: TObject);
begin
  AIAgent1.ChatGPT := ChatGPT1;
  AIAgent1.Safety := AIAgentSafety1;

  AIAgentSafety1.SimulationMode := True;
  AIAgentSafety1.ReadOnlyMode := True;

  if AIAgent1.RunText('Analise esta solicitação e sugira uma ação segura') then
    Memo1.Lines.Text := AIAgent1.LastResult
  else
    ShowMessage(AIAgent1.LastError);
end;
```

## Segurança

Use sempre `TAIAgentSafety` associado ao agente.

Recomendações:

* iniciar com `SimulationMode := True`;
* iniciar com `ReadOnlyMode := True`;
* não permitir escrita em arquivo, rede, e-mail ou industrial sem confirmação explícita;
* registrar logs de todas as decisões.

## Limitações

* API ainda experimental.
* Exige validação rigorosa antes de uso com ações reais.
