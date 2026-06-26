# Project TaskList AI Demo

Este sample demonstra o uso de componentes do pacote **AI Project** da Lazarus AI Suite para criar um fluxo simples de planejamento de projeto com apoio de LLM.

O objetivo atual deste sample é mostrar, de forma prática, como um formulário Lazarus pode:

1. configurar um provedor/modelo de IA;
2. coletar dados básicos de um projeto;
3. pedir ao LLM uma especificação inicial em JSON;
4. pedir ao LLM a geração de tarefas técnicas;
5. armazenar o estado do projeto em `ProjectData`;
6. exibir tarefas em grid, status e JSON/log;
7. salvar e carregar o arquivo `.aiproj.json`.

> Observação importante: este README descreve o que o sample faz **hoje**. Ele não descreve uma versão ideal futura do demo.

---

## Objetivo real do sample

O `project_tasklist_ai_demo` é uma prova de conceito de integração entre:

- um formulário Lazarus;
- o componente `TCHATGPT`;
- o componente central `TAIProject`;
- componentes auxiliares do pacote `AI Project`;
- uma estrutura JSON de projeto mantida em `AIProject1.ProjectData`.

Ele ainda não é um gerenciador completo de projetos. Também não é, nesta versão, um demo limpo apenas de componentes encapsulados. Parte importante da lógica de prompt, validação e integração de JSON ainda está implementada no `main.pas`.

---

## Fluxo implementado atualmente

### 1. Configuração da IA

Na aba **Config IA**, o usuário seleciona:

- provedor;
- modelo;
- token;
- endpoint/local URL;
- versão de IA do componente `TCHATGPT`.

Ao clicar em **Aplicar Configuração**, o formulário preenche `AIProjectLLMConfig1`, aplica a configuração em `AIProject1` e também atualiza diretamente o componente `ChatGPT1`.

O botão **Testar IA** envia uma pergunta simples para `ChatGPT1` e espera uma resposta do LLM.

### 2. Cadastro básico do projeto

Na aba **Projeto**, o usuário informa:

- nome do projeto;
- descrição/objetivo;
- restrições;
- entregáveis esperados.

Essas informações são copiadas para propriedades de `AIProject1`, como `ProjectName`, `Goal`, `Constraints` e `ExpectedDeliverables`.

### 3. Geração de especificação com IA

O botão **Gerar Descrição Elaborada (IA)** executa o fluxo de especificação.

Na implementação atual, o prompt é montado no próprio `main.pas`, enviado por `ChatGPT1.SendQuestion`, interpretado como JSON e integrado em `AIProject1.ProjectData`.

A estrutura esperada é:

```json
{
  "project": {
    "name": "...",
    "description": "...",
    "goal": "...",
    "context": "...",
    "scope": "...",
    "constraints": "...",
    "expected_deliverables": "..."
  },
  "agile_documents": {
    "business_vision": "...",
    "functional_requirements": [],
    "non_functional_requirements": [],
    "stakeholders": [],
    "risk_map": [],
    "epics": [],
    "user_stories": []
  }
}
```

A documentação gerada é integrada em `ProjectData.project` e `ProjectData.agile_documents`.

### 4. Geração de tarefas com IA

O botão **Gerar Tarefas com IA** envia ao LLM o JSON atual do projeto e solicita uma lista de tarefas técnicas.

A estrutura esperada é:

```json
{
  "planning": {
    "tasks": [
      {
        "id": "T001",
        "epic_id": "E001",
        "title": "...",
        "description": "...",
        "long_description": "...",
        "acceptance_criteria": "...",
        "priority": "alta",
        "status": "draft",
        "dependency_type": "serial",
        "dependencies": [],
        "can_run_in_parallel": false,
        "estimated_hours": {
          "intern": 8,
          "junior": 6,
          "mid_level": 4,
          "senior": 2
        },
        "suggested_skill_level": "mid_level",
        "assigned_skill_level": "mid_level",
        "assigned_to": "DEV",
        "responsible_profile": "DEV",
        "planned_start_date": "2026-06-26",
        "planned_end_date": "2026-06-27",
        "estimated_duration_days": 1,
        "progress_percent": 0,
        "deliverable": "...",
        "notes": "...",
        "revision_created": 1,
        "revision_updated": 1
      }
    ]
  }
}
```

Após validar a resposta, o sample substitui `ProjectData.planning.tasks` pelas tarefas retornadas e chama `AIProjectTasks1.RecalculateEstimates`.

### 5. Exibição das tarefas

A aba **Tarefas** usa:

- `TAIProjectStatusPanel` para resumo de status;
- `TAIProjectTaskGrid` para listar as tarefas;
- `MemoTaskDescription` para mostrar a descrição longa da tarefa selecionada.

Ao selecionar uma linha no grid, o sample busca a tarefa pelo ID e mostra `long_description` ou `description` no memo.

### 6. JSON e log

A aba **JSON/Log** exibe:

- o JSON completo de `AIProject1.ProjectData`;
- mensagens de log do fluxo executado;
- respostas originais do LLM em caso de erro de parsing ou validação.

### 7. Salvar e carregar projeto

O botão **Salvar Projeto** usa `AIProjectStorage1.SaveProjectToFile` para salvar o arquivo:

```text
project_tasklist_demo.aiproj.json
```

O botão **Carregar Projeto** usa `AIProjectStorage1.LoadProjectFromFile` para carregar o mesmo arquivo.

Na versão atual, salvar e carregar também usam chamadas auxiliares ao LLM para validação/resumo. Isso é comportamento atual do sample, mas não é obrigatório para persistência do projeto.

---

## Componentes realmente integrados no fluxo atual

### `TCHATGPT` / `ChatGPT1`

É o componente efetivamente usado para comunicação com o LLM.

O sample chama diretamente:

```pascal
ChatGPT1.SendQuestion(APrompt)
```

Esse componente é usado em:

- teste de conexão;
- geração de especificação;
- geração de tarefas;
- geração de tarefa adicional;
- geração de resumo;
- geração de relatório textual;
- validação/exportação JSON;
- validação antes de salvar;
- confirmação de limpeza.

### `TAIProject` / `AIProject1`

É o componente central do sample.

Ele mantém a estrutura principal em:

```pascal
AIProject1.ProjectData
```

O sample usa `AIProject1` para armazenar:

- dados do projeto;
- documentos ágeis em `agile_documents`;
- lista de tarefas em `planning.tasks`;
- configuração básica de projeto;
- estado serializável do `.aiproj.json`.

Também é chamado:

```pascal
AIProject1.EnsureProjectStructure;
```

para garantir que a estrutura JSON mínima exista.

### `TAIProjectLLMConfig` / `AIProjectLLMConfig1`

Usado para receber os dados da aba **Config IA** e aplicar configuração em `AIProject1` e `ChatGPT1`.

O sample usa:

```pascal
AIProjectLLMConfig1.ApplyToProject;
```

Além disso, o formulário ainda atualiza diretamente algumas propriedades de `ChatGPT1`, como modelo, token, endpoint e tipo de chat.

### `TAIProjectStorage` / `AIProjectStorage1`

Usado para persistência do projeto.

Métodos usados:

```pascal
AIProjectStorage1.SaveProjectToFile(...)
AIProjectStorage1.LoadProjectFromFile(...)
```

O componente está realmente integrado ao fluxo de salvar e carregar.

### `TAIProjectTasks` / `AIProjectTasks1`

Usado para trabalhar com as tarefas já armazenadas em `ProjectData`.

Na versão atual, ele é usado principalmente para:

```pascal
AIProjectTasks1.RecalculateEstimates;
AIProjectTasks1.TaskLongDescription[TaskID];
```

A geração das tarefas ainda é feita pelo `main.pas`, com prompt manual enviado ao `ChatGPT1`.

### `TAIProjectSpecification` / `AIProjectSpecification1`

O componente está presente no formulário e vinculado a `AIProject1`.

Porém, na versão atual do sample, a geração da especificação não chama diretamente um método público do componente. O fluxo de especificação é feito no `main.pas`, usando prompt manual, parsing manual e integração manual no `ProjectData`.

Portanto, este componente está **presente e conectado**, mas **não é o executor principal do fluxo atual**.

### `TAIProjectTaskGrid` / `TaskGrid1`

Componente visual realmente integrado.

Usado para exibir `ProjectData.planning.tasks` em formato de grid.

O formulário chama:

```pascal
TaskGrid1.LoadTasks;
```

### `TAIProjectStatusPanel` / `StatusPanel1`

Componente visual realmente integrado.

Usado para atualizar o painel de status com base no projeto atual.

O formulário chama:

```pascal
StatusPanel1.RefreshStatus;
```

### `TAITaskActions` / `AITaskActions1`

O componente está presente no formulário e vinculado ao projeto.

Na versão atual, ele não é uma parte central do fluxo visual demonstrado. Não há uma aba ou painel completo de ações de tarefa exposto ao usuário neste sample.

### `TAIProjectDescription` / `AIProjectDescription1`

O componente está presente e vinculado ao projeto.

Na versão atual do sample, ele não é usado diretamente pelo fluxo principal de geração de especificação ou tarefas.

---

## Componentes presentes ou citados, mas não demonstrados completamente

### Agentes

A documentação anterior dizia que agentes haviam sido removidos do sample. No estado atual do projeto, a remoção ainda não está completa.

Ainda existem no sample:

- aba `Agent`;
- `TAIAgentManagerFrame`;
- referências a units de agentes;
- botões e métodos relacionados a geração de agentes;
- dependência do pacote `openai_agent` no `.lpi`.

Portanto, agentes estão **parcialmente presentes**, mas o fluxo principal do sample continua sendo geração de especificação e tarefas.

### Gantt e Timeline

O README anterior descrevia abas de Gantt e Timeline como parte do fluxo principal.

Na versão atual do sample, essas abas ainda não estão demonstradas de forma completa na interface principal.

O componente `TAIProjectGantt` aparece declarado no `main.pas`, mas a tela atual não apresenta uma aba Gantt completa integrada ao fluxo. Também não há aba Timeline completa no formulário atual.

### Relatórios

O sample possui botões e métodos para resumo, relatório de tarefas, relatório de agentes, exportação Markdown e exportação JSON.

Na versão atual, esses relatórios são gerados por chamadas ao LLM no próprio formulário, e não por um fluxo visual completo baseado em `TAIProjectReports`.

---

## Arquivo gerado

O sample salva o projeto no arquivo fixo:

```text
project_tasklist_demo.aiproj.json
```

Esse arquivo contém o JSON completo do projeto, incluindo:

- `project`;
- `agile_documents`;
- `planning.tasks`;
- demais estruturas garantidas por `AIProject1.EnsureProjectStructure`.

---

## Como executar o fluxo atual

1. Abra `project_tasklist_ai_demo.lpi` no Lazarus.
2. Compile e execute.
3. Acesse a aba **Config IA**.
4. Selecione o provedor e o modelo.
5. Informe token ou endpoint, conforme o provedor.
6. Clique em **Aplicar Configuração**.
7. Clique em **Testar IA** para validar a comunicação.
8. Vá para a aba **Projeto**.
9. Preencha nome, objetivo, restrições e entregáveis.
10. Gere a especificação usando o botão **Gerar Descrição Elaborada (IA)**, disponível atualmente na aba **Tarefas**.
11. Gere as tarefas usando **Gerar Tarefas com IA**.
12. Confira o resultado na aba **Tarefas**.
13. Confira o JSON e logs na aba **JSON/Log**.
14. Salve o projeto com **Salvar Projeto**.
15. Carregue novamente com **Carregar Projeto**.

---

## Limitações conhecidas desta versão

- O formulário ainda concentra muita lógica de prompt, parsing e validação JSON.
- `TAIProjectSpecification` está conectado, mas o fluxo atual de especificação ainda é executado manualmente pelo `main.pas`.
- `TAIProjectTasks` é usado para recalcular e consultar tarefas, mas a geração das tarefas ainda é feita no formulário.
- Agentes ainda aparecem parcialmente no sample, embora não sejam o foco principal do demo.
- Gantt e Timeline ainda não estão expostos em abas completas no formulário.
- Exportação Markdown e validação JSON ainda usam chamadas ao LLM, em vez de usar exclusivamente componentes de relatório/exportação.
- Salvar, carregar e limpar ainda têm chamadas auxiliares ao LLM, embora essas operações possam ser locais.
- O arquivo salvo usa nome fixo `project_tasklist_demo.aiproj.json`.

---

## Escopo real desta versão

Este sample deve ser entendido como uma demonstração prática de integração inicial entre `TCHATGPT`, `TAIProject`, `TAIProjectLLMConfig`, `TAIProjectStorage`, `TAIProjectTasks`, `TAIProjectTaskGrid` e `TAIProjectStatusPanel`.

Ele ainda não deve ser tratado como exemplo final de arquitetura ideal do pacote `AI Project`.
