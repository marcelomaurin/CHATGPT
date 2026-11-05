# AI Drone (`openai_drone`)

Protocolos de drones Wi-Fi. Cada componente atende **uma marca e um modelo**; os pacotes de inicialização e o formato dos comandos não são intercambiáveis entre drones.

| Componente | Drone | Situação |
|---|---|---|
| `TAIDroneFQ777` | FQ777-954 | Beta |
| `TAIDroneCX10W` | Cheerson CX-10W | Beta |
| `TAIDroneMavlink` | ArduPilot / PX4 (MAVLink), com missões por GPS | Beta |
| `TAIDroneTello` | DJI/Ryze Tello (SDK em texto) | Beta |
| `TAIDroneESPDrone` | ESP-Drone da Espressif / OpenDrone (CRTP) | Beta |
| `TAIDroneARDrone` | Parrot AR.Drone 2.0 | Beta |
| `TAIDroneCDP` | Drone ESP32 com o firmware do Cockpit Drone (CDP v1) | Beta |

Todos herdam de `TAIDroneBase` (`aidronebase.pas`), que entrega `OnStatus`, `OnError`, `OnStateChange` e `OnTelemetry` na linha principal (a rede roda em linhas próprias e nunca bloqueia a tela) e chama `OnVideoData` na linha de rede, com o H.264 pronto para o `TAIH264Decoder`.

Regras comuns de segurança: manche no centro ao conectar; se a aplicação parar de chamar `SetSticks` por `StickTimeoutMs` (500 ms), o drone volta a pairar ou a aceleração vai a zero; ao desconectar, o componente pousa ou zera a aceleração.

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

Com `ThrottleArmLock` (padrão ligado), a aceleração fica travada em zero depois de conectar até o manche descer ao mínimo, evitando decolagem se o joystick estiver acelerado.

## TAIDroneCX10W

O Cheerson CX-10W usa o mesmo protocolo do FQ777-954 (mesmo módulo Wi-Fi): o componente herda de `TAIDroneFQ777` e muda apenas o nome do modelo nas mensagens. Vídeo H.264 de 720×576.

## TAIDroneMavlink

Controladoras ArduPilot (ArduCopter) e PX4 por MAVLink em UDP (`Host`, padrão `192.168.4.1`, `Port` 14550). Recebe MAVLink v1 e v2 (inclusive cargas truncadas) e envia v1.

- **Telemetria** (`Telemetry`): ligação, piloto automático, armado, modo (`ModeText`), GPS (`GpsText`, tipo de fixo, satélites, HDOP), posição, altitude relativa, rumo, velocidade, bateria, item atual e alcançado da missão e ponto de partida.
- **Manche:** `SetSticks(Rolagem, Arfagem, Guinada: -1..1; Aceleração: 0..1)` vira `MANUAL_CONTROL`; é suprimido automaticamente em modos autônomos (missão, RTL, pouso), para não brigar com a rota.
- **Missões:** `BuildMission` monta a missão a partir dos pontos (decolagem, velocidade por trecho, ação final: voltar à partida, pousar ou pairar no último ponto; no ArduPilot o item 0 é a partida). `UploadMission` envia com o protocolo de missão e repetições; `MissionState` informa envio, aceite ou falha (`MissionMessage`). `StartMission` (ArduPilot: GUIDED, armar, `MISSION_START`; PX4: modo missão e armar), `PauseMission`, `ResumeMission`, `ReturnToLaunch` e `Land`.

## TAIDroneTello

SDK em texto da Ryze. Rede do drone: `192.168.10.1`; comandos em UDP 8889 (`command`, `takeoff`, `land`, `emergency`, `streamon`), telemetria em UDP 8890 (`State`: bateria, altura, atitude, velocidades, temperatura) e vídeo H.264 de 960×720 em UDP 11111.

`SetSticks(Rolagem, Arfagem, Guinada, Subida: -1..1)` vira `rc a b c d` a cada 50 ms (zero = pairar). `TakeOff` (recusado com bateria abaixo de 15%), `Land`, `Emergency`, `SendCommandText` para outros comandos do SDK. O componente volta a entrar no modo SDK se o drone parar de responder. Com `LandOnDisconnect`, pousa ao desconectar.

## TAIDroneESPDrone

ESP-Drone da Espressif e derivados ("OpenDrone") com firmware Crazyflie: pacotes CRTP em UDP. Drone em `192.168.43.42`, porta 2390; o aplicativo escuta na porta 2399 (`LocalPort`).

Pacote de comando: cabeçalho `0x3C` (porta 3, canal 0), rolagem e arfagem em graus (`MaxAngle`, padrão 20), guinada em graus/s (`MaxYawRate`, 120) como `float32`, aceleração `uint16` 0..60000 (`MaxThrust`) e soma simples dos bytes. A arfagem segue com o sinal invertido, como no cflib. O firmware só aceita aceleração depois de receber zero; o componente mantém a aceleração travada até o manche descer ao mínimo (`ThrustUnlocked`) e `Stop` trava de novo.

## TAIDroneARDrone

Parrot AR.Drone 2.0. Rede do drone: `192.168.1.1`; comandos AT em UDP 5556 a cada 30 ms, telemetria (navdata) em UDP 5554 no modo "demo", vídeo PaVE/H.264 de 640×360 em TCP 5555 (os cabeçalhos PaVE são removidos antes de `OnVideoData`).

`SetSticks(Rolagem, Arfagem, Guinada, Subida: -1..1)` multiplicados por `Sensitivity` (0,5); `TakeOff` (recusado em emergência ou com bateria baixa), `Land`, `Hover`, `Emergency` (corta os motores; se já estiver em emergência, rearma), `FlatTrim` (calibração no chão) e `Configure` (`AT*CONFIG` com confirmação). `Navdata`: estado, bateria, atitude, altitude e velocidades.

## TAIDroneCDP

Drone ESP32 com o firmware do projeto [cockpit_drone](https://github.com/marcelomaurin/cockpit_drone) (`firmware/esp32_drone`), protocolo CDP v1 em UDP 4210, drone em `192.168.4.1`.

Pacote: `'C' 'D'`, versão, tipo, sequência (u16), dados e CRC-16/CCITT-FALSE. Controle (`0x01`) a cada 30 ms com rolagem/arfagem/guinada −1000..1000, aceleração 0..1000 e os sinalizadores de armar e corte; calibração (`0x02`); telemetria (`0x81`) com estado, bateria em mV, atitude, aceleração aplicada, sinal Wi-Fi, frequência do laço e alertas.

`Arm` (o firmware exige aceleração no mínimo e o drone nivelado), `Disarm`, `Cut` (desliga os motores na hora), `Calibrate`. Ao desconectar, desarma e zera a aceleração.

## Dependências

Depende de `openai_core` e `openai_input` (usa `TAISocketTCP`/`TAISocketUDP`; `TAISocketUDP.SendBufferTo` e `ReceiveBuffer` foram acrescentados para estes componentes). Para exibir o vídeo, use `TAIH264Decoder` do pacote `openai_video`.
