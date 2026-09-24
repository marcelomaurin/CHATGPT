# TAIVoiceSynthesizer

O **`TAIVoiceSynthesizer`** é o componente unificado de síntese de voz (Text-to-Speech) da suíte **TCHATGPT** para Lazarus e Free Pascal. Ele suporta tanto motores locais nativos do sistema operacional quanto provedores remotos de alta fidelidade em nuvem ou servidores locais compatíveis.

---

## 1. Motores Locais vs Provedores Remotos

O componente unifica a arquitetura em duas camadas complementares:

### Motores Locais (`Engine`)
- **`seSystemDefault`**: Utiliza o motor padrão do sistema operacional (SAPI no Windows, eSpeak no Linux).
- **`seSAPI`**: Microsoft Speech API (Windows SAPI 5.x via COM/OLE).
- **`seEspeak`**: eSpeak / eSpeak-NG carregado dinamicamente via DLL (`.dll`) ou biblioteca compartilhada (`.so`).
- **`seOpenAI`**: Modo legado mantido para compatibilidade total (redireciona internamente para o provedor `vpOpenAI`).

### Provedores Remotos (`Provider`)
Definidos pelo tipo `TAIVoiceProvider`:
- **`vpNone`**: Nenhum provedor remoto ativo; utiliza os motores locais (`SAPI` ou `eSpeak`).
- **`vpOpenAI`**: API oficial de Speech da OpenAI (`/v1/audio/speech`).
- **`vpOpenAICompatible`**: Servidores terceiros compatíveis com o endpoint `/v1/audio/speech` (LocalAI, vLLM, Ollama, LM Studio, RunPod).
- **`vpCustomHTTP`**: Servidores HTTP de TTS personalizados.
- **`vpGoogle`**, **`vpAzure`**, **`vpElevenLabs`**: Stubs preparados para expansões futuras (emitem erro explícito `Provider not implemented`).

---

## 2. Propriedades Principais

### Configurações de API & Provedor
| Propriedade | Tipo | Descrição |
|---|---|---|
| `Provider` | `TAIVoiceProvider` | Provedor de voz ativo (`vpNone`, `vpOpenAI`, etc.) |
| `APIToken` | `string` | Chave de autenticação Bearer para o provedor remoto |
| `Model` | `string` | Nome do modelo TTS (ex.: `gpt-4o-mini-tts`, `tts-1`, `tts-1-hd`) |
| `Endpoint` | `string` | URL do serviço TTS (padrão: `https://api.openai.com/v1/audio/speech`) |
| `RemoteVoice` | `string` | Identificador da voz remota (ex.: `alloy`, `echo`, `fable`, `onyx`, `nova`, `shimmer`) |
| `Language` | `string` | Código de idioma (ex.: `pt-BR`, `en-US`, `es-ES`, etc.) |
| `OutputFormat` | `string` | Formato de áudio retornado (`mp3`, `wav`, `opus`, `aac`, `flac`) |
| `OutputFile` | `string` | Caminho do arquivo de áudio de saída gerado |
| `Speed` | `Double` | Velocidade da fala remota (`0.25` a `4.0`, padrão `1.0`) |
| `RemoteTimeoutMS` | `Integer` | Timeout das requisições remotas em milissegundos (padrão: `30000`) |
| `MaxRetries` | `Integer` | Tentativas de retry para falhas de rede transitórias (padrão: `1`) |

### Cache e Fallback
| Propriedade | Tipo | Descrição |
|---|---|---|
| `EnableCache` | `Boolean` | Quando True, armazena em disco o áudio sintetizado indexado por hash MD5 de parâmetros |
| `CacheDir` | `string` | Diretório de armazenamento do cache local de áudio |
| `EnableFallback` | `Boolean` | Se a síntese remota falhar, faz fallback automático para motor local |
| `FallbackEngine` | `TSpeechEngine` | Motor local a ser acionado em caso de fallback (`seSystemDefault`, `seSAPI`, `seEspeak`) |

### Reprodução de Áudio e Estado
| Propriedade | Tipo | Descrição |
|---|---|---|
| `AutoPlay` | `Boolean` | Quando True, reproduz automaticamente o áudio sintetizado |
| `AudioPlayer` | `TAIAudioPlayer` | Instância customizada de player; se nula, cria player interno automático |
| `State` | `TAIVoiceState` | Estado atual (`vsIdle`, `vsSynthesizing`, `vsPlaying`, `vsStopping`, `vsError`) |
| `AudioLevel` | `Single` | Nível/amplitude aproximada de áudio para animações de boca (lip-sync) |
| `LastUsage` | `TAIVoiceUsage` | Métricas da última síntese (caracteres, latência, sucesso, fallback) |

---

## 3. Ciclo de Vida e Eventos

O componente segue um fluxo estrito e desacoplado:

```text
Say(Texto)
   │
   ├── (Se Remoto)
   │     │
   │     ├── OnSynthesisStart  (vsSynthesizing)
   │     │      ↓
   │     │   Verificação de Cache / Chamada HTTP
   │     │      ↓
   │     ├── OnSynthesisEnd
   │     │      ↓
   │     ├── OnSpeechStart     (vsPlaying)
   │     │      ↓
   │     │   Reprodução do áudio pelo TAIAudioPlayer
   │     │      ↓
   │     └── OnSpeechEnd       (vsIdle)
   │
   └── (Se Local - SAPI/eSpeak)
         │
         ├── OnSpeechStart     (vsPlaying)
         │      ↓
         │   Síntese direta SAPI/eSpeak
         │      ↓
         └── OnSpeechEnd       (vsIdle)
```

---

## 4. Segurança de Credenciais (`TVoiceCredentialStore`)

Para evitar que tokens de APIs remotas sejam armazenados em texto simples em arquivos `.ini` ou `.cfg`, a unit `aivoicecredentialstore.pas` oferece a classe utilitária `TVoiceCredentialStore`:
- No Windows: Utiliza **DPAPI** do sistema operacional (`CryptProtectData`/`CryptUnprotectData`).
- Em outros sistemas ou como fallback: Cifra reversível com assinatura de integridade.
- Migração legada: Reconhece e migra tokens antigos transparentemente.

---

## 5. Exemplo de Código

```pascal
var
  Synth: TAIVoiceSynthesizer;
begin
  Synth := TAIVoiceSynthesizer.Create(Self);
  try
    // Configura Provedor OpenAI
    Synth.Provider := vpOpenAI;
    Synth.APIToken := 'sk-...';
    Synth.Model := 'gpt-4o-mini-tts';
    Synth.RemoteVoice := 'alloy';
    Synth.Language := 'pt-BR';
    Synth.Speed := 1.0;
    Synth.EnableFallback := True;
    Synth.FallbackEngine := seSAPI;

    // Falar texto
    Synth.Say('Olá, sou o Professor Virtual da FATEC!');
  finally
    Synth.Free;
  end;
end;
```
