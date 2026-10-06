# WebRTC DataChannel Demo

Demo de diagnóstico Lazarus ↔ Lazarus para o componente `TAIWebRTCClient`.

## Fluxo
1. Abra duas instâncias.
2. Clique **Conectar** nas duas.
3. Em A, clique **Criar Offer**; copie o SDP para B e aplique como `offer`.
4. Em B, clique **Criar Answer**; copie o SDP para A e aplique como `answer`.
5. Troque também os candidatos ICE exibidos (a API `AddRemoteCandidate` está disponível; a próxima revisão da UI automatiza a importação).
6. Aguarde estado conectado/DataChannel aberto e envie texto nos dois sentidos.

O runtime é procurado automaticamente em `runtime/libdatachannel/<plataforma>/`. `RuntimeLibrary` continua permitindo override manual.

> Este exemplo é propositalmente diagnóstico. A sinalização automática por WebSocket/HTTP será uma camada separada.
