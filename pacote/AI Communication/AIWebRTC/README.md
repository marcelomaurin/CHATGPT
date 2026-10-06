# AI WebRTC

Integração WebRTC nativa para Lazarus/Free Pascal usando a API C da libdatachannel.

## Primeira etapa implementada

- carregamento dinâmico do runtime;
- criação de PeerConnection;
- callbacks de SDP, ICE e estado;
- DataChannel local e remoto;
- envio/recepção de mensagens;
- STUN configurável;
- nenhuma dependência rígida de SFU.

## Captura existente

Vídeo deve reutilizar `TAICaptureSource`. Os backends VFW/V4L2 existentes não devem ser duplicados.

O `TAIAudioInput` atual grava WAV (MCI/arecord) e ainda não expõe PCM contínuo por callback. A integração de áudio WebRTC exige primeiro uma extensão de streaming compatível, preservando a API existente.

## Próximas etapas

1. demo Lazarus <-> navegador por DataChannel;
2. resolução automática do caminho do runtime pelo mecanismo central da suíte;
3. streaming PCM no `TAIAudioInput`;
4. Opus;
5. frames do `TAICaptureSource` para pipeline de vídeo;
6. VP8/H.264;
7. tracks de mídia e teste com SFU.
