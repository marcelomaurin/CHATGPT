# Lazarus AI Suite — Aba `AI Project`

A pasta **AI Project** reúne componentes para representar projetos, tarefas, armazenamento e especificações que podem ser consumidos por agentes e ferramentas da suíte CHATGPT.

## Componentes principais

- `TAIProject` — objeto central do projeto;
- `TAIProjectTasks` — lista e organização de tarefas;
- `TAIProjectStorage` — persistência/estrutura de dados do projeto;
- `TAIProjectSpecification` — especificação associada ao projeto.

Os samples `Demo_AI_Project` e `project_tasklist_ai_demo` demonstram o uso básico desses componentes.

## Integração com Agent

AI Project pode ser combinado com `TAIAgent` para transformar tarefas e especificações em ações planejadas. A execução deve continuar passando pelas políticas e pelo executor do Agent; o objeto de projeto não deve, por si só, executar comandos arbitrários.

## Framework Graph Explorer

O sample `pacote/samples/AI Project/framework_graph_explorer/` combina componentes de Project, Graph e Files para analisar a estrutura de um repositório/projeto e produzir um grafo factual.

Esse tipo de análise é útil para inventariar units, dependências, packages e samples antes de propor alterações automáticas.

## Pipeline

Integrações envolvendo `TAIPipeline` devem ser tratadas separadamente do núcleo de Project. Se um sample de pipeline falhar por dependência externa ou design-time, isso não rebaixa automaticamente os componentes básicos `TAIProject`, `TAIProjectTasks`, `TAIProjectStorage` e `TAIProjectSpecification` que possuam sample dedicado compilando.

Consulte `pacote/COMPONENT_STATUS.md` para o status atualizado.

## Boas práticas

- mantenha caminhos de projeto relativos quando possível;
- não persista credenciais dentro de arquivos de projeto;
- diferencie tarefas descritivas de ações executáveis;
- faça aprovação humana para ações destrutivas ou alterações de fonte quando a política exigir;
- use AI Files/Graph para inventário e AI Agent para execução controlada.

## Idiomas

- [Português](README.pt.md)
- [English](README.en.md)
- [Español](README.es.md)
- [Français](README.fr.md)
- [Italiano](README.it.md)
- [العربية](README.ar.md)

As traduções devem manter os mesmos nomes de classes, samples e limitações técnicas desta página.
