# Continuidade — Áudio contínuo, VAD e integração

Atualizado em 28/09/2026.

## Objetivo

Evoluir o pacote CHATGPT para fornecer captura contínua de microfone reutilizável por aplicações como o projeto Assistente, sem colocar regras específicas da aplicação dentro dos componentes.

Fluxo pretendido:

`microfone -> captura -> filtros -> VAD -> segmentação -> WAV final -> STT`

O agente, memória, RAG e TTS pertencem às camadas superiores e não devem ser incorporados ao componente de captura/VAD.

## O que foi implementado

### TAIAudioInput
Arquivo: `pacote/AI Input/AIAudio/aiaudio.pas`.

O componente continua compatível com `StartRecord` e `StopRecord`. Foi acrescentado monitoramento durante a gravação por `OnAudioLevel`, com `MonitorInterval`. No Windows a implementação atual utiliza o backend MCI/waveaudio. O objetivo do evento é fornecer nível normalizado ao VAD sem transferir lógica do Assistente para o componente.

Commit principal: `e41d215331e84a3a2efbb2cf381a4f2a9aae1fd2`.

### TAIContinuousListener
Arquivo: `pacote/AI Input/AIAudio/aicontinuouslistener.pas`.

Novo componente responsável pela escuta contínua e segmentação. Possui estados `lsIdle`, `lsListening`, `lsSpeech`, `lsSilence`, `lsPaused` e `lsError`.

Parâmetros principais:
- `VoiceThreshold`
- `SilenceTimeoutMs`
- `MinSpeechMs`
- `MaxSpeechMs`
- `PreRollMs`
- `EchoSuppressionEnabled`
- `SelfAudioCorrelationThreshold`

Eventos principais:
- `OnSpeechReady`: entrega o WAV após considerar encerrada a fala.
- `OnStateChange`: informa o estado da escuta.
- `OnError`: informa falha do listener.

O listener conecta `TAIAudioInput.OnAudioLevel` ao VAD. Quando detecta voz, acompanha as pausas. Uma pausa curta não deve finalizar a frase; silêncio maior que `SilenceTimeoutMs`, respeitando `MinSpeechMs`, finaliza o segmento. `MaxSpeechMs` impede segmentos indefinidos. Após finalizar, valida o WAV, dispara `OnSpeechReady` e inicia o próximo segmento.

Commits principais:
- criação: `42c4507a8285d8f5ca9b4b82558c62b3a2c9fe31`
- ligação com `TAIAudioInput`: `e19a6b9e0683885c97da78629c46dca7a8c67a61`

## Componentes existentes que devem ser reaproveitados

Não recriar funcionalidades já existentes:
- `TAIAudioInput`: captura.
- `TAIVoiceRecognizer`: STT.
- pacote `AI Filtros Sonoros`: filtros existentes devem ser usados no tratamento do sinal.
- `TAIAgentMemoryMap`: memória de conversa.
- componentes AI Agent: orquestração/agentes.
- AI RAG/`airetrieval.pas`: recuperação documental.
- componentes de avatar (`TAIAvatar3D`, lip-sync, behavior/controller): etapas posteriores.

## Limitações conhecidas

1. As alterações ainda precisam ser compiladas e validadas em Lazarus/Free Pascal.
2. O monitoramento em tempo real implementado nesta etapa é voltado ao Windows/MCI. Linux/ALSA ainda necessita backend de streaming/nível apropriado.
3. `PreRollMs` está exposto, mas o pre-roll real de amostras ainda precisa ser implementado para preservar áudio imediatamente anterior à detecção de voz.
4. `EchoSuppressionEnabled` e `SelfAudioCorrelationThreshold` estão configuráveis, mas a supressão/correlação real com o áudio do TTS ainda precisa ser implementada/validada.
5. Os filtros existentes precisam ser conectados ao caminho real de análise/captura; não criar filtros duplicados.
6. Validar se o nível fornecido pelo backend MCI é confiável em todas as máquinas/dispositivos. Se não for, implementar captura PCM/streaming adequada em vez de simular VAD.

## Tarefas pendentes para o próximo agente

- [ ] Compilar o pacote CHATGPT e corrigir incompatibilidades de Free Pascal/Lazarus encontradas.
- [ ] Testar `TAIAudioInput` + `TAIContinuousListener` com microfone real no Windows.
- [ ] Confirmar que pausas curtas entre palavras não encerram o segmento.
- [ ] Confirmar que `SilenceTimeoutMs` encerra corretamente a fala.
- [ ] Implementar/validar pre-roll real.
- [ ] Integrar os filtros sonoros existentes antes da decisão do VAD.
- [ ] Implementar/validar supressão de eco/self-audio para impedir que TTS seja reconhecido como usuário.
- [ ] Implementar backend equivalente para Linux/ALSA.
- [ ] Adicionar testes/demonstração do fluxo contínuo no pacote.

## Regra obrigatória de manutenção desta lista

**Ao concluir uma tarefa pendente, APAGUE a tarefa concluída desta seção. Não marque apenas como concluída.** A lista deve conter somente trabalho que ainda falta fazer. Se uma implementação revelar nova pendência, acrescente-a com descrição objetiva.

Antes de alterar arquitetura, procure primeiro componentes equivalentes no repositório para evitar duplicação.
