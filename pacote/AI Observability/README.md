# AI Observability

`TAITrace` agrega uma operacao inteira sob um `TraceID`, com spans, timestamps,
eventos, duracao, erro e metadados JSON exportaveis. `TCHATGPT`, `TAIRAG`,
`TAIAgent` e `TAIToolRegistry` aceitam o mesmo componente na propriedade
`Trace`, propagando o identificador ao longo do fluxo.

Por padrao `IncludeSensitiveContent=False`: prompts, respostas e argumentos de
tools nao entram no trace. Metricas operacionais (provedor, modelo, tempos,
contagens, scores e fontes) continuam disponiveis. Habilite conteudo sensivel
somente em ambiente controlado.
