# Sample: agent_task_memory_action_demo

## Traduções disponíveis

- [Português](README.md)
- [English](README.en.md)
- [Français](README.fr.md)
- [日本語](README.ja.md)
- [Deutsch](README.de.md)
- [Русский](README.ru.md)
- [中文](README.zh.md)
- [Español](README.es.md)
- [Italiano](README.it.md)
- [العربية](README.ar.md)

---

Este sample demonstra um fluxo multiagente orientado por tarefas, com memória de execução, planejamento via LLM, processamento cognitivo, automação real de navegador Chromium, preparação de ações e envio de e-mail.

A ideia central é transformar um prompt livre do usuário em uma sequência auditável de tarefas. Cada tarefa possui ID, ordem, tipo, descrição, agente responsável, ação sugerida, dependência, parâmetros, status e resultado. O usuário pode executar uma tarefa individualmente ou executar o plano inteiro.

---

## Objetivo do sample

O objetivo principal é mostrar como os componentes do pacote **AI Agent** podem trabalhar juntos para resolver uma solicitação composta, por exemplo:

1. Abrir um site real no Chromium.
2. Capturar o conteúdo textual da página.
3. Criar tarefas intermediárias usando LLM.
4. Processar cognitivamente o conteúdo capturado.
5. Gerar um resumo profissional.
6. Copiar o resultado para a área de resultado do formulário.
7. Preparar o corpo do e-mail.
8. Enviar o e-mail usando `TAIEmailClient`, mediante confirmação do usuário.
9. Registrar todo o caminho no mapa de memória.

Esse sample não é apenas uma tela de teste. Ele é uma demonstração prática de orquestração entre agentes, ações reais, memória de execução e automação de interface web.

---

## Prompt usado no cenário padrão

O cenário padrão carregado pelo sample é:

```text
Entre no site https://maurinsoft.com.br/wp/sobre-nos/ pegue meu curriculo na pagina e crie um resumo profissional. Mande este resumo profissional e mande para o email marcelomaurinmartins@gmail.com. Não grave arquivo. Não gere TXT, DOCX ou Word. Copie o texto do resumo diretamente no corpo do e-mail.
```

O botão de cenário do navegador também carrega uma variação equivalente:

```text
Entre no site https://maurinsoft.com.br/wp/sobre-nos/ pegue meu curriculo, analise e crie um resumo e mande para marcelomaurinmartins@gmail.com. Não grave arquivo. Não gere TXT, DOCX ou Word. Copie o texto do resumo diretamente no corpo do e-mail.
```

O prompt força um fluxo importante: **o resumo deve ser copiado diretamente no corpo do e-mail**, sem criar arquivo TXT, DOCX ou Word.

---

## Como o fluxo funciona

### 1. Entrada do usuário

Na aba **Prompt**, o usuário informa:

- provedor de IA;
- modelo;
- token;
- base URL;
- prompt principal.

O sample suporta configuração para provedor OpenAI e também para endpoint local compatível com `/v1/chat/completions`.

### 2. Detecção de URL

O método `ExtractURLFromPrompt` localiza a primeira URL presente no prompt. Quando encontra uma URL, o sample inicializa o Chromium e navega para a página real.

### 3. Captura inicial da página

Depois que a navegação termina, o sample chama o `TAIChromiumBrowser` para capturar o texto do seletor `body`.

O texto capturado é armazenado em variáveis e contexto de execução, como:

- `FCapturedWebText`;
- `browser.last_text`;
- `browser.last_result_text`.

Esse conteúdo real é incluído no contexto enviado ao LLM para reduzir invenções e melhorar o planejamento.

### 4. Classificação do pedido

O `TAIClassifierAgent` recebe o prompt original e o conteúdo capturado. Ele classifica a solicitação e registra a etapa no `TAIAgentMemoryMap`.

### 5. Planejamento de tarefas

O `FTaskPlannerAgent`, baseado em `TAIDecisionAgent`, transforma a solicitação em uma lista JSON de tarefas.

O JSON esperado segue a estrutura:

```json
{
  "tasks": [
    {
      "id": "T001",
      "order": 1,
      "type": "browser",
      "description": "Navegar até a página informada",
      "agent": "task_processor_agent",
      "suggested_action": "BROWSER_NAVIGATE",
      "depends_on": "",
      "parameters": {
        "url": "https://exemplo.com"
      }
    }
  ]
}
```

Cada tarefa pode ser de navegador, conteúdo ou ação. O método `LoadTasksFromPlannerJSON` interpreta esse JSON, normaliza as dependências e preenche o grid de tarefas.

### 6. Normalização do plano

Após carregar as tarefas, o sample executa rotinas de segurança e consistência:

- normaliza IDs;
- ordena tarefas;
- reconstrói dependências lineares quando necessário;
- garante destinatário de e-mail;
- cria captura após submissão quando necessário;
- evita ações fora da lista permitida;
- converte ações de resumo em tarefas cognitivas quando aplicável.

### 7. Execução de tarefas

Ao executar uma tarefa, o sample verifica:

- se a tarefa está cancelada;
- se está em processamento;
- se suas dependências foram concluídas;
- se os parâmetros mínimos estão presentes.

Tarefas `BROWSER_*` são executadas diretamente pelo `TAIActionExecutor`, sem passar pelo `ActionBuilderAgent`, para evitar que o LLM troque indevidamente a ação planejada.

Tarefas cognitivas são processadas pelo `FTaskProcessorAgent`, que gera o resultado textual. No cenário do currículo, esse resultado é publicado como resumo para uso posterior no e-mail.

### 8. Preparação de ações

Quando a tarefa possui uma ação operacional, o sample monta um plano de ação JSON. Em ações diretas como `SEND_EMAIL`, `CREATE_TEXT_DOCUMENT` ou `REGISTER_RESULT`, o plano pode ser criado de forma determinística com `BuildSingleActionJSON`.

Quando necessário, o `TAIActionBuilderAgent` usa `BuildActionsWithRecovery` para converter a saída cognitiva em parâmetros operacionais válidos.

### 9. Execução real pelo executor

O `TAIActionExecutor` executa ações reais registradas no sample. Ele recebe os eventos:

- `OnBeforeActionExecute`;
- `OnAfterActionExecute`;
- `OnBeforePreparedAction`;
- `OnAfterPreparedAction`.

Esses eventos validam parâmetros, inicializam Chromium, aguardam DOM, atualizam contexto, substituem placeholders e registram logs.

### 10. Resultado final

O resumo gerado deve aparecer em:

- `memConteudoCurriculo`, na área **Resultado em Texto**;
- `memCorpoEmail`, no corpo do e-mail;
- `last_summary_text`, no contexto de execução;
- `last_text_content`, no contexto de execução.

O e-mail só deve ser enviado com corpo real, não com tags como `<resumo_gerado>`, `[EMAIL]` ou texto genérico.

---

## Componentes usados

### `TCHATGPT`

Componente base de comunicação com o modelo de IA. Ele recebe token, modelo, provider e URL do endpoint. No sample, é compartilhado entre classificador, planejador, processador e builder.

### `TAIAgentMemoryMap`

Registra o caminho completo da execução. Cada agente cria uma etapa no mapa com entrada recebida, análise, explicação, ação tomada, perguntas internas, saída e perda de informação detectada.

### `TAIClassifierAgent`

Classifica o prompt inicial e ajuda o fluxo a entender o tipo de solicitação. Usa `TCHATGPT` e publica sua etapa no mapa de memória.

### `TAIDecisionAgent` como `FTaskPlannerAgent`

Usado para transformar o prompt em tarefas. O método principal no fluxo é `DecideAsTaskList`.

### `TAIDecisionAgent` como `FTaskProcessorAgent`

Usado para processar uma tarefa específica. Em tarefas cognitivas, ele gera o conteúdo final, como o resumo profissional do currículo.

### `TAIActionBuilderAgent`

Converte resultados cognitivos em ações operacionais estruturadas. O método `BuildActionsWithRecovery` ajuda a recuperar respostas inválidas ou incompletas retornadas pelo LLM.

### `TAIActionExecutor`

Executa ações preparadas. No sample, ele registra ações customizadas e ações de browser. Também mantém o `ExecutionContext`, usado para transportar resultados entre etapas.

### `TAICustomAgentAction`

Classe base usada pelas ações customizadas do sample: `TSampleCreateTextAction`, `TSampleSendEmailAction` e `TSampleRegisterResultAction`.

### `TAIEmailClient`

Responsável pelo envio real de e-mail via SMTP. O sample lê host, porta, usuário e senha da tela. O envio real exige confirmação manual do usuário antes de chamar `SendEmail`.

### `TAIChromiumBrowser`

Componente visual de automação Chromium. É usado para navegar, capturar texto da página, ler DOM e executar ações interativas.

### `TChromiumWindow`

Janela Chromium usada pelo `TAIChromiumBrowser` para renderização e navegação real.

### Ações de browser

O sample registra várias ações reais de browser no executor:

- `TAIBrowserNavigateAction` → `BROWSER_NAVIGATE`;
- `TAIBrowserWaitSelectorAction` → `BROWSER_WAIT_SELECTOR`;
- `TAIBrowserReadPageAction` → `BROWSER_READ_PAGE`;
- `TAIBrowserDOMListAction` → `BROWSER_DOM_LIST`;
- `TAIBrowserCaptureTextAction` → `BROWSER_CAPTURE_TEXT`;
- `TAIBrowserSetValueAction` → `BROWSER_SET_VALUE`;
- `TAIBrowserFocusAction` → `BROWSER_FOCUS`;
- `TAIBrowserClickAction` → `BROWSER_CLICK`;
- `TAIBrowserPressEnterAction` → `BROWSER_PRESS_ENTER`;
- `TAIBrowserSubmitFormAction` → `BROWSER_SUBMIT_FORM`;
- `TAIBrowserScreenshotAction` → `BROWSER_SCREENSHOT`.

---

## Abas da interface

- **Prompt**: entrada principal e configuração do provedor.
- **Tarefas**: lista de tarefas planejadas pelo LLM.
- **Agente**: auditoria da etapa atual.
- **Mapa de Memória**: histórico estruturado do fluxo.
- **Resultado**: texto gerado e dados do e-mail.
- **Log**: rastreamento cronológico da execução.
- **Navegador Chromium**: navegador real usado para abrir páginas e capturar conteúdo.

---

## Contexto de execução

O `FActionExecutor.ExecutionContext` funciona como memória operacional compartilhada entre ações. Alguns nomes importantes:

- `browser.last_dom_kind`;
- `browser.last_dom_selector`;
- `browser.last_dom_json`;
- `browser.last_text`;
- `browser.last_result_text`;
- `last_text_content`;
- `last_summary_text`;
- `last_text_filename`.

Esse contexto evita que uma tarefa perca o resultado da tarefa anterior. Depois da captura do `body`, a tarefa de resumo pode usar `browser.last_result_text`; depois do resumo, o envio de e-mail pode usar `last_summary_text`.

---

## Exemplo de plano esperado para o prompt padrão

```json
{
  "tasks": [
    {
      "id": "T001",
      "order": 1,
      "type": "browser",
      "description": "Navegar até a página do currículo",
      "agent": "task_processor_agent",
      "suggested_action": "BROWSER_NAVIGATE",
      "depends_on": "",
      "parameters": {
        "url": "https://maurinsoft.com.br/wp/sobre-nos/"
      }
    },
    {
      "id": "T002",
      "order": 2,
      "type": "browser",
      "description": "Capturar o texto da página",
      "agent": "task_processor_agent",
      "suggested_action": "BROWSER_READ_PAGE",
      "depends_on": "T001",
      "parameters": {
        "selector": "body"
      }
    },
    {
      "id": "T003",
      "order": 3,
      "type": "content",
      "description": "Gerar resumo profissional do currículo capturado",
      "agent": "task_processor_agent",
      "suggested_action": "",
      "depends_on": "T002",
      "parameters": {
        "instruction": "Gerar resumo profissional a partir do conteúdo capturado."
      }
    },
    {
      "id": "T004",
      "order": 4,
      "type": "action",
      "description": "Enviar o resumo por e-mail",
      "agent": "email_agent",
      "suggested_action": "SEND_EMAIL",
      "depends_on": "T003",
      "parameters": {
        "to": "marcelomaurinmartins@gmail.com",
        "subject": "Resumo do Currículo",
        "body": "<resumo_gerado>"
      }
    }
  ]
}
```

O loader deve substituir placeholders como `<resumo_gerado>` pelo resumo real publicado no contexto.

---

## Fluxo resumido do pipeline

```text
Prompt
  -> TAIClassifierAgent.Classify
  -> TAIDecisionAgent.DecideAsTaskList
  -> LoadTasksFromPlannerJSON
  -> Grid de tarefas
  -> TaskProcessorAgent.ProcessTask
  -> ActionBuilderAgent.BuildActionsWithRecovery, quando necessário
  -> ActionExecutor.ExecutePreparedActionsReal
  -> Browser / E-mail / Resultado
  -> MemoryMap / Log
```

---

## Segurança e validações

O sample bloqueia destinatário vazio ou placeholder, corpo de e-mail vazio, corpo com placeholder, ações desconhecidas e parâmetros mínimos ausentes. O envio real exige confirmação manual. A automação de navegador valida URL, seletor, valor de input e aguarda carregamento de página e retorno assíncrono do DOM.

---

## Resultado esperado

Ao executar o cenário padrão corretamente, o usuário deve ver tarefas geradas, navegação real no Chromium, conteúdo da página capturado, resumo profissional exibido em **Resultado em Texto**, corpo do e-mail preenchido com o mesmo resumo, log detalhado e mapa de memória com a trilha dos agentes.

O ponto mais importante do cenário é que o e-mail deve receber o **resumo real gerado**, não uma tag de marcação como `<resumo_gerado>` nem um texto genérico.
