# AI Drone (`openai_drone`)

Protocolos de drones Wi-Fi. Cada componente atende **uma marca e um modelo**; os pacotes de inicialização e o formato dos comandos não são intercambiáveis entre drones.

| Componente | Drone | Situação |
|---|---|---|
| `TAIDroneFQ777` | FQ777-954 | Beta |

## TAIDroneFQ777

Portado do aplicativo [fq777-954-chrome-app](https://github.com/marcelomaurin/fq777-954-chrome-app), com as correções abaixo.

**Rede do drone:** IP `172.16.10.1`, TCP `8888` (inicialização e vídeo), UDP `8895` (comandos).

**Sequência:** três conexões TCP com pacotes mágicos (controle; vídeo 1 com 1A e 1B; vídeo 2, por onde chega o H.264 de 720×576) e, a cada 50 ms, o pacote UDP:

| Byte | 0 | 1 | 2 | 3 | 4 | 5 | 6 | 7 |
|---|---|---|---|---|---|---|---|---|
| Conteúdo | `$CC` | rolagem | arfagem | aceleração | guinada | sinalizadores | XOR 1..5 | `$33` |

Eixos 0..255 com centro 127 (0 = esquerda/trás); aceleração 0 = motores parados.

**Correções em relação ao aplicativo original**

- A arfagem era calculada com `(2 - eixo + 1) * 127`, que transborda o byte e deixava o centro em 125 e os extremos quase iguais; agora é proporcional e centrada em 127.
- O vídeo nunca era exibido: a busca por códigos de início parava no primeiro de cada bloco e não atravessava blocos. Agora o fluxo é sincronizado no primeiro `00 00 00 01`, as respostas `ITd` de 106 bytes são descartadas e o restante segue intacto para o decodificador.
- Controle e vídeo rodam em linhas separadas: queda ou reconexão do vídeo não interrompe os comandos de voo.
- Segurança: aceleração começa em zero; se a aplicação parar de atualizar os comandos por `StickTimeoutMs`, rolagem/arfagem/guinada voltam ao centro; ao desconectar, envia comandos com aceleração zero (`CutThrottleOnDisconnect`).

**Uso**

```pascal
Drone.OnVideoData := @DroneVideo;   // linha de rede
Decoder.Width := FQ777_VIDEO_WIDTH; Decoder.Height := FQ777_VIDEO_HEIGHT;
Decoder.OnFrame := @MostraQuadro;   // linha principal
Drone.Connect;

procedure TForm1.DroneVideo(Sender: TObject; AData: PByte; ACount: Integer);
begin
  Decoder.Feed(AData^, ACount);
end;

// num temporizador, a partir do joystick:
Drone.SetSticks(Rolagem, Arfagem, Guinada, Aceleracao);
```

O byte de sinalizadores (5) fica em 0, como no aplicativo de referência; o significado dos bits não é documentado para este modelo.

Depende de `openai_core` e `openai_input` (usa `TAISocketTCP`/`TAISocketUDP`). Para exibir o vídeo, use `TAIH264Decoder` do pacote `openai_video`.
