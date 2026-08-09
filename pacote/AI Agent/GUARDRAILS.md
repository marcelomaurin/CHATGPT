# Guardrails

`aiguardrails.pas` define `TAIGuardrail`, regras de entrada, saída e tools e o
pipeline `TAIGuardrailSet`. Cada regra retorna decisão estruturada: permitir,
bloquear ou substituir o conteúdo, acompanhada do nome da regra e motivo.

`TAIAgent` aplica guardrails antes do envio ao LLM, depois da resposta e antes
de executar uma tool. A política específica da tool continua sendo aplicada
pelo `TAIToolRegistry`; assim, confirmação e guardrail são camadas
independentes. O padrão sem regras preserva compatibilidade.

Os callbacks são síncronos e devem ser thread-safe quando o mesmo conjunto for
compartilhado. Evite registrar conteúdo sensível no motivo. Veja
`samples/AI Agent/guardrail_demo` e `tests/evaluation_guardrails_test`.
