# Provedores e modelos do componente TCHATGPT

**Atualização:** 25/10/2026. **Versão do componente:** 1.8.

O componente passa a disponibilizar **15 opções de provedor/servidor**. O catálogo contém **92 registros: 53 sugestões e 39 registros históricos**, identificados por `IsLegacy`. A seleção cobre os principais serviços de API e os servidores locais já utilizados pelo projeto; não representa um ranking de participação de mercado.

## Lista atualizada

| Provedor/servidor | Modelos ou configuração disponíveis |
| --- | --- |
| OpenAI | `gpt-6-luna`, `gpt-6-sol`, `gpt-6-astra`, `gpt-6.1-sol`; compatibilidade explícita com `gpt-4.1` e `gpt-4.1-mini` |
| Google Gemini | `gemini-3.8-flash`, `gemini-4-argon`, `gemini-3.5-flash-lite`, `gemini-3.1-pro-preview` |
| Anthropic Claude | `claude-sonnet-5-5`, `claude-opus-5-5`, `claude-haiku-5-5`, `claude-fable-5-1` |
| DeepSeek | `deepseek-flash`, `deepseek-v4-pro` |
| Groq | `openai/gpt-oss-120b`, `openai/gpt-oss-20b`, `llama-3.3-70b-versatile`, `llama-3.1-8b-instant` |
| Mistral | `mistral-small-2603`, `mistral-medium-3-5`, `mistral-large-4` (Public Preview) |
| xAI | `grok-4.7` |
| Qwen / Alibaba Cloud Model Studio | `qwen3.8-max`, `qwen3.7-plus`, `qwen3.8-flash` |
| Cerebras | `gpt-oss-120b`, `qwen-3.8-27b` |
| OpenRouter | `openrouter/free`, `openrouter/auto` |
| Local / Ollama | Acrescentados `qwen3:8b`, `qwen3:4b`, `gemma3:4b`, `gemma3:12b`, `gpt-oss:20b`; preservadas nove opções locais anteriores |
| RunPod | ID do modelo servido pelo endpoint vLLM/OpenAI-compatible, configurado em `CustomModel` |
| OpenAI-compatible | ID configurável do modelo servido pela URL informada |
| llama.cpp | ID/alias configurado no servidor; preservadas as opções anteriores e `custom-model` |
| neural-api | `default` ou ID configurado no servidor |

Os IDs são próprios de cada serviço: `openai/gpt-oss-120b` (Groq), `gpt-oss-120b` (Cerebras) e `gpt-oss:20b` (Ollama) não são intercambiáveis. Acesso por conta, região, cotas, planos e disponibilidade do provedor precisam ser conferidos no serviço. Os modelos locais precisam estar instalados e caber no hardware utilizado.

`MaxTokens` no catálogo é o orçamento inicial de saída utilizado pela biblioteca, não o tamanho total da janela de contexto. As marcações de visão, ferramentas e fine-tuning descrevem capacidades do modelo; não acrescentam automaticamente chamadas de ferramentas ou envio de imagens à API pública do componente. O adaptador atual de chat continua enviando texto.

## Alterações nos fontes

- `pacote/AI/aillmmodelcatalog.pas`: catálogo compartilhado, data de verificação, registros atuais e indicação `IsLegacy`. Os 58 índices anteriores foram preservados; as novas entradas foram acrescentadas ao final.
- `pacote/AI/chatgpt.pas`: opções Groq, Mistral, xAI, Qwen e RunPod no enum de provedores, nomes, endpoints, lista de modelos e roteamento. Novos valores de enum foram acrescentados depois dos antigos para preservar seus ordinais.
- `pacote/AI/aillmproviders.pas`: factory e backends compatíveis para os novos provedores; tratamento dos parâmetros de raciocínio OpenAI e dos blocos de texto de Claude/Gemini.
- `pacote/AI/aimodelregistry.pas`: aplicação do provedor correto, persistência de `IsLegacy`, filtragem das sugestões e limpeza da URL anterior quando se troca para um modelo que usa endpoint padrão próprio.

Foi corrigida a substituição silenciosa de `gpt-4.1`, `gpt-4.1-mini` e `gpt-5` por `gpt-4o-mini`. `CustomModel` preserva o ID informado; apenas o erro histórico de digitação `openai-4.1-mini` é normalizado para `gpt-4.1-mini`. Os enums correspondentes a GPT-4.1/GPT-5 também mantêm o modelo selecionado.

Em OpenAI, as famílias GPT-5/GPT-6 e os modelos de raciocínio o1/o3/o4 usam `max_completion_tokens` e não enviam `temperature`. A rota utilizada continua sendo Chat Completions para texto. Ferramentas dos modelos GPT-6 exigem outra integração via Responses e não são implementadas por esta atualização.

Nos modelos Claude atuais, o adaptador omite o parâmetro de amostragem não aceito e extrai todos os blocos `text`, sem confundir blocos de raciocínio com a resposta. Gemini ignora partes marcadas como `thought` e reúne as partes de texto públicas.

## Como selecionar

As aplicações que chamam `GetAIProviderList` e `GetAIModelListForProvider` recebem a lista atualizada ao recompilar a biblioteca. `TAIModelRegistry.GetModels` também filtra os itens históricos. A presença de `IsLegacy` não significa que todos esses modelos estejam desligados: indica itens anteriores ou não sugeridos nesta revisão, mantidos para compatibilidade.

```pascal
Registry.ApplyModel('Claude Sonnet 5.5', ChatGPT1);
ChatGPT1.TOKEN := MinhaChave;
ChatGPT1.SendQuestion('Explique este projeto.');
```

Para escolher por ID diretamente:

```pascal
ChatGPT1.Provider := AIP_GROQ;
ChatGPT1.URL := GetDefaultEndpointForProvider(AIP_GROQ);
ChatGPT1.TipoChat := VCT_CUSTOM;
ChatGPT1.CustomModel := 'openai/gpt-oss-120b';
ChatGPT1.TOKEN := MinhaChaveGroq;
```

Qwen utiliza uma URL vinculada ao workspace e à região. Substitua `WORKSPACE_ID` pelo identificador real em `URL`; para RunPod, configure o identificador real de `ENDPOINT_ID` e o modelo servido. A biblioteca rejeita esses marcadores antes de fazer uma requisição. URLs base terminadas em `/v1` não recebem um segundo `/v1` ao completar a rota.

Para consultar opções históricas explicitamente:

```pascal
GetAILLMModelsForProvider('Claude', Lista, True);
```

Os arquivos INI existentes continuam aceitos. A leitura de nomes agora usa a mesma resolução de provedores do catálogo, incluindo aliases como `Ollama`, `Anthropic` e `DashScope`. O arquivo `dicionario/models_registry.json` é um registro separado de modelos NLP/SpaCy; não é a fonte da lista de provedores LLM e não foi convertido em catálogo de chat.

## Verificação

Teste: `pacote/tests/llm_model_catalog_test/llm_model_catalog_test.lpr`.

```console
python tools/ci/run_llm_catalog_tests.py
```

Foram aprovadas localmente **631 verificações em Linux x64 com FPC 3.2.2**. Os testes verificam integridade do catálogo e seleção por provedor, aplicação no componente, preservação de IDs/ordinais, INI/JSON, compatibilidade dos corpos JSON, respostas com raciocínio e rejeição de placeholders sem acesso à rede.

O workflow `.github/workflows/llm-model-catalog.yml` executa o mesmo teste em Linux x64 e Windows x64. A compilação e a execução nativas foram confirmadas nas duas plataformas:

| Plataforma | FPC / Lazarus | Compilação | Testes | Evidência |
| --- | --- | ---: | --- | --- |
| Linux x64, Ubuntu 24.04 | 3.2.2 / 3.0 | saída 0 | 631 verificações aprovadas; saída 0 | [Job Linux](https://github.com/marcelomaurin/CHATGPT/actions/runs/40225163142/job/121264865429) |
| Windows x64, Windows 2025 | 3.2.2 / 4.0 | saída 0 | 631 verificações aprovadas; saída 0 | [Job Windows](https://github.com/marcelomaurin/CHATGPT/actions/runs/40225794759/job/121266756829) |

Os fontes da atualização foram publicados em [`586d9fd`](https://github.com/marcelomaurin/CHATGPT/commit/586d9fdb4597da21441c6da8bba903a0fce079f2). O teste Linux usou esse commit; o teste Windows usou [`423bfb5`](https://github.com/marcelomaurin/CHATGPT/commit/423bfb5ab373dc70d553d9d4f10580f8e186b626), que altera somente a instalação da toolchain no workflow. Os fontes e o programa de teste são idênticos entre esses commits.

O primeiro instalador Windows 3.0 demorou antes de alcançar a compilação. A rodada concluída utilizou Chocolatey com Lazarus `4.0.0` fixado e FPC `3.2.2`, sob limite de tempo explícito para instalação.

Logs, metadados e executáveis: [artefato Linux](https://github.com/marcelomaurin/CHATGPT/actions/runs/40225163142/artifacts/12610971844) e [artefato Windows](https://github.com/marcelomaurin/CHATGPT/actions/runs/40225794759/artifacts/12611342222). Esses contratos não utilizam chaves, créditos, hardware nem comprovam chamadas reais às APIs. Eles também não representam a execução geral dos demais testes Pascal ou a homologação das interfaces gráficas.

A [compilação Windows anterior](COMPILACAO_WINDOWS_2026-10-25.md) confirmou o Modbus corrigido, os pacotes selecionados e os testes das branches de voz/impressão. Os bloqueios do Chromium e os demais [erros de entrega](ERROS_PUBLICACAO_SAMPLES_TESTES.md) permanecem registrados separadamente.

## Fontes oficiais consultadas em 25/10/2026

- [OpenAI: modelos](https://developers.openai.com/api/docs/models), [GPT-6.1 Sol](https://developers.openai.com/api/docs/models/gpt-6.1-sol) e [parâmetros GPT-6](https://developers.openai.com/api/docs/guides/latest-model).
- [Anthropic: modelos](https://platform.claude.com/docs/en/models/overview), [API Messages](https://platform.claude.com/docs/en/api/messages/create) e [descontinuações](https://platform.claude.com/docs/en/about-claude/model-deprecations).
- [Google: catálogo Gemini API](https://ai.google.dev/gemini-api/docs/models).
- [DeepSeek: modelos atuais](https://api-docs.deepseek.com/quick_start/pricing/).
- [Groq: modelos suportados](https://console.groq.com/docs/models).
- [Mistral Small 4](https://docs.mistral.ai/models/mistral-small-4-0-26-03), [Medium 3.5](https://docs.mistral.ai/models/mistral-medium-3-5-26-04) e [Large 4](https://docs.mistral.ai/models/mistral-large-4-0).
- [xAI: modelos](https://docs.x.ai/developers/models) e [Chat Completions](https://docs.x.ai/developers/model-capabilities/legacy/chat-completions).
- [Alibaba: modelos](https://www.alibabacloud.com/help/en/model-studio/models) e [URLs e API compatível](https://www.alibabacloud.com/help/en/model-studio/compatibility-of-openai-with-dashscope).
- [Cerebras: catálogo e IDs](https://inference-docs.cerebras.ai/models/overview).
- [OpenRouter Free Router](https://openrouter.ai/docs/guides/routing/routers/free-router) e [Auto Router](https://openrouter.ai/docs/guides/routing/routers/auto-router).
- [Ollama Qwen3](https://ollama.com/library/qwen3), [Gemma3](https://ollama.com/library/gemma3) e [GPT-OSS](https://ollama.com/library/gpt-oss).
