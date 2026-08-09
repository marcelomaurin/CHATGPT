# MCP sum demo

Cria um `TAIMCPServer` e um `TAIMCPClient` no mesmo processo, conectados por
`TAIMCPInMemoryTransport`. O cliente negocia o protocolo, descobre a tool
`sum` por `tools/list` e executa `Somar(19, 23)` por `tools/call`.

O transporte em memória permite validar o protocolo sem processo ou serviço
externo. Consulte `AI MCP/README.md` para o escopo suportado e limitações.
