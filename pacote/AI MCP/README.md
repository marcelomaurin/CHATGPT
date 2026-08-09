# OpenAI MCP package

`openai_mcp` implementa um subconjunto interoperável do Model Context Protocol
sobre JSON-RPC 2.0, negociando a revisão `2025-11-25`:

- lifecycle: `initialize`;
- tools: `tools/list` e `tools/call`;
- resources: `resources/list` e `resources/read`;
- tipos separados para Tool, Resource, Prompt, Request, Response e Error;
- ponte temporária de tools remotas para `TAIToolRegistry`/`TAIAgent`.

## Transporte

O pacote define `IAIMCPTransport`. Esta primeira versão inclui
`TAIMCPInMemoryTransport`, adequado para testes, aplicações embutidas e
comunicação Client/Server no mesmo processo. Streamable HTTP, STDIO,
autorização, notificações, paginação, prompts e subscriptions ainda não são
implementados. A lógica do protocolo não depende do transporte, então esses
drivers podem ser adicionados sem alterar Client/Server.

## Segurança

Tools MCP sem annotations são importadas pelo bridge como risco `Execute` e
exigem confirmação pela política padrão do `TAIToolRegistry`. `readOnlyHint` e
`destructiveHint` são usados quando informados. `Refresh` remove proxies antigos
antes de refletir a lista atual, evitando cópias permanentes desnecessárias.

Veja `samples/AI MCP/mcp_demo` para servidor, cliente, tool `sum`, resource e
execução da tool remota pelo `TAIAgent`.
