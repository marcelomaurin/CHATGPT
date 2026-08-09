# Async chat demo

Interface Lazarus para `TCHATGPT.SendQuestionAsync`, streaming SSE e cancelamento.
Selecione o provider, endpoint, modelo, token e `Temperature`, envie a pergunta e
acompanhe os estados `Connecting`, `Receiving`, `Completed`, `Cancelled` e
`Error`. Os eventos assíncronos são entregues na thread principal da aplicação.

O streaming incremental é implementado para APIs OpenAI-compatible, incluindo
OpenAI, llama.cpp, neural-api, Ollama, OpenRouter, Cerebras e DeepSeek.
