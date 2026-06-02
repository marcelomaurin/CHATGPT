# Changelog - Lazarus AI Suite

Todas as alterações relevantes para a suíte de componentes Lazarus AI Suite serão registradas neste arquivo.

## [1.7.0] - 2026-06-02

### Adicionado
- **TAIBaseComponent**: Nova classe base comum (`aibase.pas`) que unifica logs estruturados (`OnLog`, `TAILogLevel`, `TAILogEvent`), versão global da suíte (`AI_SUITE_VERSION`) e propriedades comuns de controle de erro (`Prompt`, `LastError`, `LastResult`, `LastSuccess`).
- **TAIGraphMap**: Novo componente de classificação textual local e explicável baseado em grafo ponderado de tokens (IA local leve, sem necessidade de LLM ou GPU externos).
- **TAIProject**: Novo componente coordenador de projetos de IA, permitindo carregar e salvar definições de forma segura e gerenciar modos de simulação.
- **TAIPipeline**: Novo componente para orquestrar esteiras operacionais e conectar percepção a modelos e a geradores de documentos. Suporta classificação local usando `TAIGraphMap` com o modo `pmGraphMapClassification`.
- **TAIPromptBuilder**: Varrimento inteligente de componentes e formulários com suporte a idiomas (Português, Inglês, Espanhol) e múltiplos formatos de saída (Text, Markdown, JSON).
- **TAIAgentSafety**: Camada de proteção física para agentes autônomos com normalização estrita de diretórios, fallbacks de portas de rede (como HTTPS para 443) e confirmações de ações com o evento `OnConfirmAction`.
- **aiagent_executors.pas**: Novo módulo contendo executores modulares desacoplados (`TAIAgentDocsExecutor`, `TAIAgentNetworkExecutor`, `TAIAgentIndustrialExecutor`, `TAIAgentMessagingExecutor`, `TAIAgentHardwareExecutor`) para processar ações físicas solicitadas pelo Agente.

### Modificado
- `TAIAgent` agora herda de `TAIBaseComponent` e armazena os detalhes da sua última tomada de decisão no novo objeto encapsulado `TAIAgentDecision`.
- Refatorado `TAIAgentResourceItem.Execute` para utilizar o despachante de executores modulares em vez de manter uma lógica monolítica gigante.
- Refatorado `TAIModbusClient`, `TAIMQTTClient` e `TAIIndustrialBridge` para herdar de `TAIBaseComponent`.
- `TAIMQTTClient` agora armazena os campos `LastTopic` e `LastPayload` ao receber mensagens de tópicos subscritos.
- Melhorada a injeção RTTI de propriedades em recursos de agentes com suporte a listas de segurança de propriedades permitidas (`AllowedProperties`) e bloqueadas (`BlockedProperties`), além de suportar tipos enums e inteiros longos de 64 bits (`Int64`).

### Corrigido
- Corrigido vazamento potencial de API Keys no `TAIProject.SaveToFile` criando a propriedade `SaveToken` desativada por padrão.
- Corrigida validação de caminho seguro no `TAIAgentSafety` prevenindo desvio com comparação prefixada estrita.
- Corrigido check de objeto `Action` nulo no método `RunAgent` da classe `TAIPipeline` para evitar falhas de Access Violation.
- Corrigido trecho de instrução de idioma misto no prompt do Agente (`entre las listadas` alterado para `entre as listadas`).
