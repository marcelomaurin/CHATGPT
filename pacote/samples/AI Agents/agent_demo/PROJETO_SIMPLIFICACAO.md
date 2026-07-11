# Projeto Simplificado — Correção do `agent_demo`

## Objetivo

Reduzir o `agent_demo` ao mínimo necessário para demonstrar o uso do componente `TAIAgent`.

A ideia deste sample é **mostrar o uso do componente**, não criar uma aplicação completa.

O sample deve mostrar apenas:

1. Configurar o `TCHATGPT`.
2. Configurar o `TAIAgent`.
3. Configurar `TAIAgentOptions`.
4. Configurar `TAIAgentAction`.
5. Definir ações permitidas.
6. Enviar uma instrução do usuário.
7. Receber a decisão estruturada do agente.
8. Exibir na tela:
   - ação escolhida;
   - parâmetros retornados;
   - justificativa;
   - erro, se houver.

---

## Escopo mínimo

### Componentes que devem permanecer

```text
TCHATGPT
TAIAgent
TAIAgentOptions
TAIAgentAction
```

### Componentes que devem sair deste sample

```text
TAIAgentResource
TAIAgentOutput
TAIAgentSafety
Web API
WhatsApp
SMS
TCP
UDP
Escrita real de arquivos
Cenários complexos
Dashboard
Tema visual sofisticado
```

Esses recursos podem ser demonstrados futuramente em outros samples, por exemplo:

```text
agent_resource_demo
agent_output_demo
agent_safety_demo
```

O `agent_demo` principal deve ser pequeno, direto e didático.

---

## Funcionamento esperado

O sample terá um único cenário:

```text
Triagem simples de chamado técnico
```

Exemplo de entrada do usuário:

```text
O computador da recepção não liga e precisa de atendimento urgente.
```

O agente deve escolher uma ação entre:

```text
OPEN_TICKET
SEND_EMAIL
IGNORE
```

E retornar parâmetros como:

```text
priority=alta
category=manutencao
reason=Computador da recepção não liga.
```

O sample apenas mostra o resultado na tela.

Não deve abrir OS real.  
Não deve mandar e-mail.  
Não deve gravar arquivo.  
Não deve chamar API.

---

## Interface mínima

A tela deve conter somente os elementos necessários para demonstrar o componente.

### Configuração do LLM

```text
Provider
Model
Token
Endpoint Local
```

### Entrada e configuração do agente

```text
Memo Entrada do Usuário
Memo System Prompt
Memo Perguntas/Diretrizes
Memo Contexto
Memo Ações Permitidas
Memo Parâmetros Esperados
Botão Executar Agente
```

### Resultado

```text
Memo Resultado
Memo Erro
```

Exemplo de resultado esperado:

```text
Ação escolhida: OPEN_TICKET

Parâmetros:
priority=alta
category=manutencao
reason=Computador da recepção não liga.

Justificativa:
A solicitação descreve uma falha de equipamento que impede o trabalho da recepção.
```

---

# Tarefas pequenas para o bot

## Tarefa 1 — Corrigir dependência do projeto

### Arquivo

```text
pacote/samples/AI Agent/agent_demo/agent_demo.lpi
```

### Ação

Adicionar o pacote:

```xml
<Item>
  <PackageName Value="openai_agent"/>
</Item>
```

Manter:

```xml
<Item>
  <PackageName Value="openai_core"/>
</Item>
<Item>
  <PackageName Value="LCL"/>
</Item>
```

Não adicionar `openai_input` nem `openai_output` neste sample simplificado.

### Critério de aceite

```text
O projeto deve compilar declarando corretamente o pacote openai_agent.
```

---

## Tarefa 2 — Remover componentes avançados do `main.pas`

### Arquivo

```text
pacote/samples/AI Agent/agent_demo/main.pas
```

### Ação

Remover campos como:

```pascal
FAIAgentResource: TAIAgentResource;
FAIAgentOutput: TAIAgentOutput;
```

Remover qualquer criação de recursos como:

```text
Stark_Email_System
Stark_File_Writer
Stark_WhatsApp_Alert
Stark_Mainframe_API
```

Remover mappings de output:

```pascal
FAIAgentOutput.Mappings.Add
```

### Critério de aceite

```text
O sample deve compilar usando apenas TCHATGPT, TAIAgent, TAIAgentOptions e TAIAgentAction.
```

---

## Tarefa 3 — Remover tema J.A.R.V.I.S./Stark

### Arquivo

```text
pacote/samples/AI Agent/agent_demo/main.pas
```

### Ação

Remover textos:

```text
J.A.R.V.I.S.
Tony Stark
Stark
Reator Arc
Mainframe
```

Substituir por termos técnicos e genéricos:

```text
AI Agent Demo
Agente de Triagem
Triagem de Chamado
```

### Critério de aceite

```text
O sample deve parecer técnico, genérico e reutilizável.
```

---

## Tarefa 4 — Criar configuração simples do agente

### Arquivo

```text
pacote/samples/AI Agent/agent_demo/main.pas
```

### Ação

No `FormCreate`, manter somente a criação básica:

```pascal
FChatGPT := TCHATGPT.Create(Self);
FAIAgent := TAIAgent.Create(Self);
FAIAgentOptions := TAIAgentOptions.Create(Self);
FAIAgentAction := TAIAgentAction.Create(Self);

FAIAgent.ChatGPT := FChatGPT;
FAIAgent.Options := FAIAgentOptions;
FAIAgent.Action := FAIAgentAction;
FAIAgentAction.OnExecuteAction := @OnAgentExecuteAction;
```

### Critério de aceite

```text
O agente deve estar ligado ao TCHATGPT, às opções e às ações.
```

---

## Tarefa 5 — Criar cenário único de triagem

### Arquivo

```text
pacote/samples/AI Agent/agent_demo/main.pas
```

### Ação

Criar método:

```pascal
procedure TfrmAgentDemo.LoadDefaultScenario;
begin
  memSystemPrompt.Text :=
    'Você é um agente de triagem de chamados técnicos. ' +
    'Analise a solicitação do usuário e escolha uma ação permitida.';

  memQuestions.Clear;
  memQuestions.Lines.Add('Identifique se a solicitação exige abertura de chamado.');
  memQuestions.Lines.Add('Classifique a prioridade como baixa, media ou alta.');
  memQuestions.Lines.Add('Explique brevemente o motivo da decisão.');

  memContext.Text :=
    'Ambiente de demonstração. Nenhuma ação real será executada.';

  memAllowedActions.Clear;
  memAllowedActions.Lines.Add('OPEN_TICKET');
  memAllowedActions.Lines.Add('SEND_EMAIL');
  memAllowedActions.Lines.Add('IGNORE');

  memParameterDefs.Clear;
  memParameterDefs.Lines.Add('priority: baixa, media ou alta');
  memParameterDefs.Lines.Add('category: manutencao, suporte, infraestrutura ou outro');
  memParameterDefs.Lines.Add('reason: resumo da justificativa');

  memUserInput.Text :=
    'O computador da recepção não liga e precisa de atendimento urgente.';
end;
```

### Critério de aceite

```text
Ao abrir o sample, ele deve trazer um exemplo pronto para executar.
```

---

## Tarefa 6 — Implementar botão Executar

### Arquivo

```text
pacote/samples/AI Agent/agent_demo/main.pas
```

### Ação

Criar ou simplificar:

```pascal
procedure TfrmAgentDemo.btnExecuteClick(Sender: TObject);
var
  Cmd: string;
  OK: Boolean;
begin
  Cmd := Trim(memUserInput.Text);

  if Cmd = '' then
  begin
    ShowMessage('Informe uma solicitação para o agente analisar.');
    Exit;
  end;

  memResult.Clear;
  memError.Clear;

  ConfigureChatGPTFromUI;

  FAIAgent.SystemPrompt := memSystemPrompt.Text;
  FAIAgentOptions.Questions.Assign(memQuestions.Lines);
  FAIAgentOptions.Context := memContext.Text;
  FAIAgentAction.AllowedActions.Assign(memAllowedActions.Lines);
  FAIAgentAction.ParameterDefinitions.Assign(memParameterDefs.Lines);

  OK := FAIAgent.Execute(Cmd);

  if OK then
    ShowAgentResult
  else
    memError.Text := FAIAgent.LastError;
end;
```

### Critério de aceite

```text
Ao clicar em Executar, o agente deve retornar ação, parâmetros e justificativa.
```

---

## Tarefa 7 — Implementar evento da ação apenas como log

### Arquivo

```text
pacote/samples/AI Agent/agent_demo/main.pas
```

### Ação

Criar:

```pascal
procedure TfrmAgentDemo.OnAgentExecuteAction(
  Sender: TObject;
  const AActionName: string;
  AParams: TStrings
);
begin
  memResult.Lines.Add('Evento OnExecuteAction disparado.');
  memResult.Lines.Add('Ação: ' + AActionName);
  memResult.Lines.Add('');
end;
```

### Observação importante

Esse evento não deve executar recurso real.

Ele serve apenas para demonstrar que o componente disparou a ação.

### Critério de aceite

```text
O evento deve aparecer no log, mas sem enviar e-mail, gravar arquivo ou chamar API.
```

---

## Tarefa 8 — Criar método para mostrar resultado

### Arquivo

```text
pacote/samples/AI Agent/agent_demo/main.pas
```

### Ação

Criar:

```pascal
procedure TfrmAgentDemo.ShowAgentResult;
begin
  memResult.Lines.Add('Ação escolhida: ' + FAIAgentAction.SelectedAction);
  memResult.Lines.Add('');
  memResult.Lines.Add('Parâmetros:');
  memResult.Lines.Add(FAIAgentAction.SelectedParameters.Text);
  memResult.Lines.Add('');
  memResult.Lines.Add('Justificativa:');
  memResult.Lines.Add(FAIAgent.LastRationale);
end;
```

### Critério de aceite

```text
O resultado deve ficar claro para quem está estudando o componente.
```

---

## Tarefa 9 — Validar configuração mínima do LLM

### Arquivo

```text
pacote/samples/AI Agent/agent_demo/main.pas
```

### Ação

Antes de executar o agente, validar:

```text
Provider selecionado
Model selecionado
Token preenchido, quando necessário
Endpoint local preenchido, quando provider for local
```

### Critério de aceite

```text
Se faltar configuração, mostrar mensagem simples e não chamar o LLM.
```

---

## Tarefa 10 — Simplificar README

### Arquivo

```text
pacote/samples/AI Agent/agent_demo/README.md
```

### Ação

Reescrever o README com foco didático.

Estrutura sugerida:

```markdown
# AI Agent Demo

Este sample demonstra o uso básico do componente `TAIAgent`.

## O que ele mostra

- Como ligar `TCHATGPT` ao `TAIAgent`
- Como configurar `TAIAgentOptions`
- Como configurar `TAIAgentAction`
- Como definir ações permitidas
- Como executar o agente
- Como ler a ação escolhida, parâmetros e justificativa

## O que ele não faz

- Não envia e-mail real
- Não chama API real
- Não grava arquivos
- Não usa WhatsApp/SMS
- Não executa automação externa

## Fluxo

Usuário -> TAIAgent -> LLM -> JSON -> Ação escolhida -> Log na tela

## Como executar

1. Abrir `agent_demo.lpi` no Lazarus.
2. Configurar provider, modelo e token.
3. Clicar em Executar.
4. Ver a ação escolhida pelo agente.
```

### Critério de aceite

```text
README deve explicar o sample simples, sem prometer recursos externos.
```

---

# O que não implementar neste sample

Não implementar:

```text
modo real
modo simulado
TAIAgentOutput
TAIAgentResource
TAIAgentSafety
Web API
SMTP
WhatsApp
SMS
TCP
UDP
persistência em arquivo
criação real de OS
abas complexas
dashboard
tema visual escuro sofisticado
cenários múltiplos
```

Esses itens aumentam a complexidade e devem ficar para outros samples.

---

# Resultado final esperado

O `agent_demo` deve ser um exemplo pequeno e direto:

```text
Entrada do usuário
     ↓
TAIAgent
     ↓
LLM
     ↓
JSON estruturado
     ↓
TAIAgentAction.SelectedAction
TAIAgentAction.SelectedParameters
TAIAgent.LastRationale
     ↓
Resultado exibido na tela
```

O sample deve ensinar o componente, não criar uma aplicação.
