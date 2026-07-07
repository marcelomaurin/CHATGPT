# AIKinect

Componentes Lazarus para integrar o sensor Microsoft Kinect v1 (Xbox 360) ao ecossistema da suíte.

## Componentes

- **TAIKinectSensor**: Componente hub para controle de conexão, inclinação do motor (tilt), cor de LED e leitura do acelerômetro.
- **TAIKinectColorStream**: Fluxo de vídeo RGB ou IR.
- **TAIKinectDepthStream**: Fluxo de profundidade em mm com exportação de nuvem de pontos para formato PLY.
- **TAIKinectSkeleton**: Rastreamento de esqueleto (20 articulações).
- **TAIKinectAudio**: Gravação de áudio do array de microfones e detecção da direção de voz (beamforming).

## Dependências

O carregamento das bibliotecas nativas é dinâmico:
- **Windows**: `freenect.dll` (OpenKinect) ou `Kinect10.dll` (Microsoft Kinect SDK 1.8).
- **Linux**: `libfreenect.so` ou `libfreenect.so.0.5`.

Se as bibliotecas ou o sensor não estiverem conectados, os componentes operam em modo simulação de forma limpa sem interromper a execução do programa principal.
