# Vídeo ao vivo no Windows

Esta demo transmite vídeo contínuo da câmera para o painel usando `TAIWindowsVideoPreview`, do pacote `openai_vision`. Não usa captura periódica de fotos, arquivos temporários, Python ou OpenCV para a transmissão.

## Como usar

1. Abra `camera_capture_windows_demo.lpi` no Lazarus, compile e execute.
2. Escolha a câmera pelo nome. Use **Atualizar** após conectar ou desconectar um dispositivo.
3. Clique em **Iniciar vídeo**. A tela mostra o nome da câmera aberta e a resolução real negociada com ela, em pixels.
4. Clique em **Parar vídeo** para liberar a câmera e escolher outro dispositivo. Fechar a janela também encerra a transmissão.

A resolução exibida é a do vídeo recebido, não o tamanho do painel. A imagem acompanha o redimensionamento da janela mantendo sua proporção.

## Implementação

A enumeração e a abertura usam o mesmo identificador DirectShow (moniker), evitando a mistura de índices DirectShow e VFW. O fluxo de preview é conectado diretamente ao renderizador de vídeo do Windows; não há temporizador de captura de imagens. A implementação VFW legada continua disponível para os outros componentes.

`TAIWindowsVideoPreview` deve ser criado, utilizado e destruído na mesma thread da interface. O painel precisa continuar válido até `Stop` ou a destruição do objeto. A transmissão usa o formato padrão negociado pela câmera. Câmeras ocupadas por outro aplicativo podem não abrir; o detalhe aparece no registro da demo.

## Validação

Compilação Win32 com Free Pascal 3.2.2. A lista reconheceu USB CAMERA e OBS Virtual Camera. O vídeo contínuo da USB CAMERA foi exibido em 1920 × 1080, com confirmação visual e do usuário.
