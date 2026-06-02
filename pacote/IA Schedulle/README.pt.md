# 📅 Documentação da Aba IA Schedulle

> [!NOTE]
> Esta pasta contém a suíte de componentes do Lazarus sob a aba **IA Schedulle**.

## Agendamento Automatizado e Linha de Tempo Neural.
Componentes para gerenciamento inteligente de tarefas periódicas baseadas em tempo cron e relógios.

### Referência Detalhada dos Componentes

| Componente | Descrição | Propriedades Importantes | Métodos Principais | Papel do Agente de IA |
|---|---|---|---|---|
| **TIASchedule** | Agendador de cronogramas. | `CronExpression, MaxIterations` | `ScheduleTask, CancelTask` | Gerenciar gatilhos de tempo para atividades do agente IA. |

### 💻 Exemplo de Código Lazarus (TIASchedule)

```pascal
var
  MyComponent: TIASchedule;
begin
  MyComponent := TIASchedule.Create(Self);
  try
    // Configuration properties
    // MyComponent.Property := Value;
    
    // Execute call
    // MyComponent.ExecuteMethod;
  finally
    MyComponent.Free;
  end;
end;
```


### ⚡ Ponte de IA e Hardware
Cada um destes componentes possui uma propriedade published `Prompt` que documenta sua API interna de forma transparente para orientar Agentes de IA (`TAIAgent`) de forma automática!
