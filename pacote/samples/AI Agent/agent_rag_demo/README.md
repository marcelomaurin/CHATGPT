# agent_rag_demo

Sample console que demonstra o fluxo `TAIAgent -> TAIRAG -> TAIGraphMap ->
TCHATGPT`. O programa cria uma base pequena em memoria, recupera contexto e
fontes e envia o prompt enriquecido ao provider configurado.

## Dependencias

- Lazarus/FPC com os packages `openai_agent` e `openai_rag` instalados.
- Acesso ao provider escolhido. Para `local`, um servidor OpenAI-compatible
  deve estar disponivel.

## Configuracao

Defina as variaveis de ambiente antes de executar:

- `AI_PROVIDER`: `openai` (padrao), `openrouter`, `gemini`, `claude`,
  `deepseek` ou `local`.
- `AI_API_KEY`: token do provider; pode ficar vazio para um servidor local que
  nao exige autenticacao.
- `AI_MODEL`: modelo customizado opcional.
- `AI_ENDPOINT`: endpoint customizado opcional.

Exemplo no PowerShell:

```powershell
$env:AI_PROVIDER = 'local'
$env:AI_MODEL = 'llama3.2:3b'
$env:AI_ENDPOINT = 'http://localhost:11434/v1/chat/completions'
.\agent_rag_demo.exe 'Como o RAG recupera contexto?'
```

## Resultado esperado

Em caso de sucesso, o sample imprime a pergunta, o contexto recuperado, as
fontes e o JSON retornado ao Agent. Falhas de indexacao, RAG ou provider sao
impressas com o prefixo `ERRO` e resultam em exit code diferente de zero.
