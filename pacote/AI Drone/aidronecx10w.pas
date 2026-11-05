unit aidronecx10w;

{ TAIDroneCX10W
  -------------
  Quadricóptero Cheerson CX-10W.

  O CX-10W usa o mesmo protocolo Wi-Fi do FQ777-954 (mesmo módulo de rádio e
  câmera): IP 172.16.10.1, três conexões TCP 8888 com os mesmos pacotes
  mágicos, vídeo H.264 pela terceira conexão e comando UDP 8895 a cada 50 ms:
    [0] $CC [1] rolagem [2] arfagem [3] aceleração [4] guinada
    [5] sinalizadores [6] XOR dos bytes 1..5 [7] $33
  Por isso este componente é um TAIDroneFQ777 com outro nome de modelo:
  toda a lógica (linhas separadas de controle e vídeo, trava da aceleração,
  centralização por tempo e corte ao desconectar) é a mesma.

  Uso: igual ao TAIDroneFQ777 (Connect, SetSticks, Neutral, OnVideoData
  ligado a um TAIH264Decoder). }

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, aidronefq777, LResources;

const
  CX10W_DEFAULT_HOST = FQ777_DEFAULT_HOST;
  CX10W_DEFAULT_TCP_PORT = FQ777_DEFAULT_TCP_PORT;
  CX10W_DEFAULT_UDP_PORT = FQ777_DEFAULT_UDP_PORT;
  CX10W_VIDEO_WIDTH = FQ777_VIDEO_WIDTH;
  CX10W_VIDEO_HEIGHT = FQ777_VIDEO_HEIGHT;

type

  { TAIDroneCX10W }

  TAIDroneCX10W = class(TAIDroneFQ777)
  protected
    function ModelName: string; override;
  public
    constructor Create(AOwner: TComponent); override;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('AI Drone', [TAIDroneCX10W]);
end;

{ TAIDroneCX10W }

constructor TAIDroneCX10W.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  Prompt := 'Component TAIDroneCX10W controls the Cheerson CX-10W Wi-Fi quadcopter ' +
    '(same protocol as TAIDroneFQ777: host 172.16.10.1, TCP 8888 handshake and H.264 video, ' +
    'UDP 8895 commands every 50 ms). Methods: Connect, Disconnect, SetSticks(Roll, Pitch, Yaw: -1..1; ' +
    'Throttle: 0..1), Neutral. Properties: Flags (byte 5), StickTimeoutMs, ThrottleArmLock, ' +
    'CutThrottleOnDisconnect, VideoEnabled. Events: OnVideoData (raw H.264, network thread; feed a ' +
    'TAIH264Decoder), OnStatus, OnError, OnStateChange.';
end;

function TAIDroneCX10W.ModelName: string;
begin
  Result := 'Cheerson CX-10W';
end;

initialization
  {$I aidronecx10w_icon.lrs}

end.
