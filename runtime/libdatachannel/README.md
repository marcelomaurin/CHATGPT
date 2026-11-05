# libdatachannel runtime

Runtime nativo para o componente `TAIWebRTCClient`.

## Layout

- `runtime/libdatachannel/windows-x86_64/`
- `runtime/libdatachannel/linux-x86_64/`
- `runtime/libdatachannel/linux-aarch64/`

Os binários não são armazenados neste commit inicial. Distribuições/release devem incluir a biblioteca compartilhada e suas dependências, preservando a política do projeto de não instalar DLL/SO globalmente.

A propriedade `RuntimeLibrary` aceita o caminho completo da DLL/SO. Quando vazia, o loader tenta `datachannel.dll` no Windows ou `libdatachannel.so` no Linux.

Versão de referência na implementação inicial: libdatachannel 0.24.x.

## Escopo inicial

Esta etapa valida PeerConnection, SDP/ICE e DataChannel. Áudio/vídeo serão adicionados após a captura existente expor streaming contínuo apropriado para mídia em tempo real.
