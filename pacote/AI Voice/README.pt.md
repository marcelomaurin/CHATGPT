# Documentação do pacote AI Voice

O pacote `openai_voice` reúne captura, reconhecimento de fala, clonagem e
síntese de voz. O fluxo novo reutiliza `TAIAudioInput`; não existe uma segunda
implementação de gravação de microfone.

## Componentes

| Componente | Responsabilidade | API principal |
|---|---|---|
| `TAISpeechRecognizer` | Orquestra um engine STT e, opcionalmente, `TAIAudioInput`. | `TranscribeFile`, `StartListening`, `StopListening`, `Cancel` |
| `TAIWhisperProcessEngine` | Executa `whisper-cli`, valida executável/modelo e captura saída/erro/exit code. | `LoadModel`, `TranscribeFile`, `Cancel` |
| `TAIVoiceClone` | Perfil autorizado, estado, eventos e validação do WAV gerado. | `CreateVoice`, `Synthesize`, `Cancel` |
| `TAIF5TTSProcessEngine` | Executa Python/F5-TTS e valida a saída. | `CreateVoice`, `Synthesize`, `Cancel` |
| `TAIVoiceAssistant` | Compõe STT -> `TCHATGPT` -> clonagem/síntese. | `ProcessText`, `ProcessAudioFile`, `StartListening`, `StopListeningAndRespond` |
| `TAIAudioPlayer` | Reproduz WAV validado usando a infraestrutura do sistema. | `PlayWav`, `Stop` |
| `TAIVoiceSynthesizer` | TTS tradicional já existente. | `Speak` |

Os contratos `IAISpeechRecognitionEngine` e `IAIVoiceCloneEngine` permitem
trocar Whisper e F5-TTS por outros backends sem alterar os componentes de alto
nível. `Engine`, `AudioInput`, `Recognizer`, `ChatGPT` e `VoiceClone` usam
`FreeNotification`; associá-los não transfere ownership.

## Reconhecimento com Whisper

Configure `TAIWhisperProcessEngine.ExecutablePath` e
`TAISpeechRecognizer.ModelPath`. Os samples aceitam `WHISPER_CLI` e
`WHISPER_MODEL`. `Language`, `UseGPU` e `Threads` são encaminhados ao engine.

Estados: `ssStopped`, `ssListening`, `ssProcessing` e `ssError`. Resultados e
falhas ficam em `LastText`, `LastError`, `State` e `Busy`. Eventos:
`OnStart`, `OnText`, `OnPartialText`, `OnError` e `OnFinish`.

Com `Continuous=True`, o WAV capturado é dividido em blocos de
`ChunkDurationSeconds`, processado em fila e combinado removendo a sobreposição
de palavras entre blocos. O processamento continua síncrono; aplicações GUI
podem executá-lo em worker thread e entregar atualizações à thread principal.

## Clonagem de voz com F5-TTS

Configure `TAIF5TTSProcessEngine.PythonPath`, `F5TTSPath` e, quando aplicável,
`ModelPath`. Os samples aceitam `F5_PYTHON`, `F5_TTS_PATH` e `F5_TTS_MODEL`.
`TAIVoiceClone` expõe `ReferenceAudio`, `VoiceID`, `OutputFile`, `Language`,
`UseGPU`, `ModelPath`, `LastOutputFile`, `LastError`, `State` e `Busy`.

Os eventos são `OnStart`, `OnProgress`, `OnError` e `OnFinish`. Sucesso só é
informado depois que o processo termina com exit code zero e o WAV existe, é
não vazio e tem cabeçalho válido.

### Consentimento e segurança

`RequireConsent=True` é o padrão. Nesse modo, `ConsentConfirmed` precisa ser
verdadeiro e `VoiceOwner` deve identificar o titular ou a pessoa autorizada.
Use apenas gravações próprias ou licenciadas e registre a autorização no seu
sistema. Desativar `RequireConsent` é uma decisão explícita do aplicativo host;
o pacote não grava dados pessoais nem envia arquivos por conta própria.

## Assistente integrado

`TAIVoiceAssistant` reaproveita os três componentes existentes e propaga
cancelamento para todos eles. Os estados são `vasIdle`, `vasListening`,
`vasRecognizing`, `vasThinking`, `vasSpeaking`, `vasCancelled` e `vasError`.
Os eventos `OnRecognized`, `OnResponse`, `OnAudioReady` e `OnStage` permitem
atualizar a interface e manter histórico. O áudio só é anunciado em
`OnAudioReady` depois da validação do arquivo.

## Samples e teste

- `samples/AI Voice/speech_file_demo`: WAV -> Whisper -> texto.
- `samples/AI Voice/speech_microphone_demo`: microfone -> WAV -> blocos -> texto.
- `samples/AI Voice/voice_clone_demo`: referência autorizada -> F5-TTS -> WAV/player.
- `samples/AI Voice/voice_assistant_demo`: microfone/STT -> LLM -> voz -> player.
- `tests/voice_pipeline_test`: engines falsos e servidor LLM local, sem depender
  de modelo, chave ou hardware externo.

Consulte o README de cada sample para variáveis de ambiente e troubleshooting.
