# LLM provider demo

Exemplo console do contrato `IAILLMProvider`, da `TAILLMProviderFactory` e do
catálogo central `aillmmodelcatalog`. Ele não faz chamadas externas: lista os
providers, monta um payload OpenAI-compatible com `Temperature` e mostra os
modelos OpenAI registrados.

Compile com `lazbuild llm_provider_demo.lpi`.
