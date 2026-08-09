# Tool call demo

Exemplo sem serviço externo que registra:

- `sum`: tool segura, executada imediatamente;
- `delete_record`: tool sensível, sujeita à política `Confirm`.

O programa executa três chamadas: soma, exclusão rejeitada e exclusão aprovada.
O resultado sempre retorna JSON estruturado com `call_id`, `tool`, `success`,
`output`, `error` e `data`.
