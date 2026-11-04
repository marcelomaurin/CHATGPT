# AI Video (`openai_video`)

## TAIH264Decoder

Decodifica um fluxo H.264 bruto (Anexo B, códigos de início `00 00 00 01`) em quadros `TBitmap`. Serve para qualquer fonte: drones Wi-Fi, câmeras IP, arquivos `.h264`.

- `Feed(Buffer, Tamanho)` pode ser chamado de qualquer linha; inicia o decodificador sozinho na primeira chamada.
- `OnFrame` chega na linha principal e sempre traz o quadro mais recente: se a interface atrasar, quadros intermediários são descartados em vez de acumular atraso.
- `Width`/`Height` definem o tamanho do quadro entregue.
- `RecordFileName` grava o fluxo recebido (`.h264`, reproduzível no ffplay/VLC).

A decodificação usa um processo **ffmpeg** em segundo plano, procurado em `FFmpegPath`, na pasta do executável (ou subpasta `ffmpeg`) e no `PATH`. No Windows, coloque o `ffmpeg.exe` ao lado do programa.

Depende apenas de `openai_core`.
