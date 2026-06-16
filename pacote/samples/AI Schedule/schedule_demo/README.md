# IA Tasks Schedule Demo (schedule_demo)

Este exemplo demonstra o uso dos componentes **`TIASchedule`** e **`TJSONGroupStorage`**, projetados para gerenciamento persistente, hierarquia de tarefas encadeadas e resolução inteligente de dependências em tempo real.

---

## 🚀 Funcionalidades

1. **Persistência Automática em JSON**: Salvamento e carregamento automático de grupos de dados estruturados em arquivos texto JSON.
2. **Gerenciamento de Dependências**: Adicione tarefas e defina dependências encadeadas (ex: "Tarefa B" depende que a "Tarefa A" esteja concluída).
3. **Resolução de Status**: O componente analisa automaticamente a árvore de dependências para calcular em tempo real se uma tarefa está pronta para execução (`IsReady`).
4. **Persistência Completa de Coleção**: Suporte total a carregamento e salvamento de coleções sem perda de dados na IDE do Lazarus.

---

## 💻 Como Compilar e Executar

1. Abra o arquivo **`schedule_demo.lpi`** no Lazarus IDE.
2. No menu principal, clique em **Run > Run** (ou pressione `F9`).
3. Adicione tarefas interativamente e controle suas interdependências e estados de execução na tela.
