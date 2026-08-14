# Action Builder Recovery Test Demo

Demo interativo para testar o **`TAIActionBuilderAgent`** com suporte a:
- Recuperação automática de saídas inválidas (`AutoRecoverInvalidInput`)
- Validação e reestruturação de ações (`BuildActionsWithRecovery` e `BuildActionsStrict`)
- Persistência padronizada de configurações no **AppData**

---

## ⚙️ Padrão de Configuração e Conexão LLM

A interface segue rigorosamente o padrão dos outros samples do framework:

1. **Provedor (`cbProvider`)**:
   - `OpenAI`
   - `OpenRouter`
   - `Cerebras`
   - `Local (Ollama)`
   - `Google Gemini`
   - `Anthropic Claude`
   - `DeepSeek`

2. **Modelo Sugerido (`cbModel`)**:
   - Atualizado dinamicamente de acordo com o provedor selecionado.

3. **Modelo Customizado (`edtCustomModel`)**:
   - Permite informar identificadores de modelos específicos.

4. **URL Local / IP (`edtLocalIP`)**:
   - Endereço para servidores locais (ex: `http://localhost:11434` para Ollama ou custom endpoints).

5. **Chave API / Token (`edtToken`)**:
   - Campo mascarado para inserção da chave de API.
   - Carregado automaticamente de `%APPDATA%` ou variáveis de ambiente (`OPENAI_API_KEY`, `CHATGPT_TOKEN`).

---

## 💾 Persistência em AppData

As configurações são salvas e carregadas automaticamente no caminho padrão:

- **Windows**: `%APPDATA%\Maurinsoft\ActionBuilderRecoveryTest\settings.ini`
- **Linux/macOS**: `~/.config/maurinsoft/action_builder_recovery_test/settings.ini`

### Parâmetros persistidos no `settings.ini`:
```ini
[LLM]
Provider=OpenAI
Model=gpt-4o-mini
CustomModel=
LocalIP=http://localhost:11434
Token=sk-...

[Agent]
AutoRecoverInvalidInput=1
```

---

## 🧪 Cenários de Teste

- **Cenário 1: Input Textual Confuso**: Demonstra a capacidade do agente em interpretar solicitações em texto livre e gerar a estrutura JSON de ações válida.
- **Cenário 2: Saída Inválida (Validação)**: Testa a rejeição e o fluxo de recuperação contra payloads sem ações.
- **Cenário 3: Teste Livre**: Permite ao usuário digitar comandos arbitrários e inspecionar a saída gerada e logs de recuperação.
