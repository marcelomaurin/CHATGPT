# TAISIPVoiceAgent — conversa por telefone SIP

`TAISIPVoiceAgent` liga o áudio PCM de `TAISIPServer` ou `TAISIPClient` a um
backend de reconhecimento de fala, resposta da IA e síntese de voz.
O núcleo funciona em programas console e serviços Linux, sem LCL ou dispositivo
de som. O pacote opcional `pacote/packages/openai_sip_voice.lpk` registra o agente
e `TAISIPVoiceHTTPBackend` no Lazarus; seu backend HTTP depende de **libcurl**.

## Fluxo

1. A chamada autenticada é atendida pelo componente SIP.
2. Áudio G.711 é entregue em PCM mono, 16 bits, 8 kHz.
3. O detector de energia separa as falas pelo silêncio. Limiares e duração máxima
   são configuráveis; ruídos curtos e silêncio não geram requisições.
4. Um worker por turno envia WAV ao STT, texto e histórico à IA e a resposta ao TTS.
5. O WAV sintetizado é convertido para PCM de 8 kHz e enviado em quadros de 20 ms.

O processamento é por turnos: durante a geração e a reprodução da resposta, o
áudio recebido é descartado para evitar realimentação. Interrupção da resposta
pela fala do usuário (barge-in) e cancelamento de uma ação física já aceita pelo
servidor Casa não estão implementados.

## Uso console

Inclua `cthreads` como primeira unit em Linux. Configure os componentes antes de
iniciar e chame `Poll(10)` continuamente no thread principal:

```pascal
Backend := TAISIPVoiceHTTPBackend.Create(nil);
Agent := TAISIPVoiceAgent.Create(nil);
Agent.SIP := SIP;
Agent.Backend := Backend;
Backend.ReplyToken := GetEnvironmentVariable('CASA_SYSTEM_API_TOKEN');
Agent.Start;
if not SIP.Start then raise Exception.Create(SIP.LastError);
while Running do Agent.Poll(10);
Agent.Stop;
SIP.Stop;
Agent.Free;
Backend.Free;
```

`Agent.Start` assume temporariamente os eventos `OnIncomingCall`,
`OnCallStateChanged` e `OnAudio` do componente SIP e os restaura em `Stop`.
Autenticação, autorização e roteamento continuam definidos no SIP. O agente
**não concede permissões a ramais**. Em um servidor, encaminhe somente o ramal
da IA para `srAnswerLocally`. `AutoAnswer=True` atende essas chamadas.

Os eventos `OnTranscript`, `OnResponse`, `OnError`, `OnSessionStarted`,
`OnSessionEnded` e `OnAudioReady` são executados no thread que chama `Poll`.
O backend deve ser configurado antes de `Start` e liberado depois de `Stop`.
Implementações próprias de `TAISIPVoiceBackend` devem ser seguras para chamadas
concorrentes e impor timeouts às operações externas.

Também é possível alimentar PCM de outro transporte usando `BeginCall`,
`ReceiveAudio`, `Process` e `EndCall`, deixando `SIP=nil`.

## Serviços HTTP

| Etapa | Contrato |
|---|---|
| STT | POST `audio/wav`; JSON com `texto` ou `text` |
| Casa/JARVIS | POST com `comando`, `session_id`, `historico_mensagens` e `origem=SIP`; retorna `resposta` |
| LLM local compatível | `ReplyFormat=vrOpenAICompatible`, `Model`, endpoint `/v1/chat/completions`, `messages` |
| TTS | POST com `texto`, `speaker`, `reproduzir=false`; recebe WAV ou JSON com `audio_url` |
| Download TTS | Usa exclusivamente `AudioBaseURL` configurado e o nome seguro do WAV, sem seguir o host enviado pelo serviço |

Por padrão, STT usa `127.0.0.1:8092/transcribe`, TTS usa
`127.0.0.1:8097/falar` e `/audio/`, e a IA usa a API v1 do Casa.
Um token real deve ser fornecido em tempo de execução para a API Casa.
Para conversas com um LLM local independente, configure o formato compatível e
seu endpoint. Comandos de automação residencial devem passar pelo JARVIS e pelo
Command Bus do Casa; um chat genérico não aciona dispositivos.

O cliente verifica certificados TLS e nomes de host com libcurl, não segue
redirecionamentos, limita respostas a 8 MiB e aceita WAV PCM 8/16 bits mono/stereo
de 8 a 96 kHz. Modelos e DLLs/so de terceiros não são incluídos.

Uma chamada mantém no máximo 24 mensagens e 32 mil bytes de histórico.
Cada sessão recebe uma chave diferente; ao desligar, resultados em andamento
são descartados, inclusive se o ID da chamada for reutilizado. O limite de
workers também considera requisições de chamadas já desligadas que ainda estão
aguardando timeout. `Stop` aguarda esses workers para não liberar o backend em uso.

Texto vazio, erro HTTP, JSON inválido e o texto de demonstração do Parakeet do
Casa são tratados como indisponibilidade, não como fala de um morador.
Configure um motor STT real (por exemplo, a CLI real em `PARAKEET_CLI_BIN`);
o fallback demonstrativo não permite conversar.

## Validação

```sh
python3 tests/run_sip_voice_tests.py \
  --bridge "$PWD/native/sip/build/libchatgpt_sip_bridge.so"
```

Os testes verificam PCM/WAV, segmentação, limites, contexto por chamada,
cancelamento, HTTP e SIP/RTP local real. Serviços ASR/IA/TTS são **fixtures
sintéticas declaradas** nesses testes. Eles não validam qualidade de voz, modelos
instalados ou aparelhos físicos. Validado com FPC 3.2.2/PJSIP 2.17 em Linux x86_64.
A integração Windows e aparelhos físicos ainda exigem validação.

O serviço consumidor está em
[casa/clusters/voz/sip-agent](https://github.com/marcelomaurin/casa/tree/master/clusters/voz/sip-agent).
