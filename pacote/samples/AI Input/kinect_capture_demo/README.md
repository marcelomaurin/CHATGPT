# Kinect Capture Demo

## Descricao

Demo em Lazarus/Free Pascal que conecta a um sensor Kinect e exibe o stream de video colorido em tempo real usando os componentes `TAIKinectSensor` e `TAIKinectColorStream` do pacote `openai_input`.

## Requisitos

- Lazarus 4.4 ou superior.
- Free Pascal 3.2 ou superior.
- Pacote `openai_input` instalado na IDE.
- Sensor Kinect conectado via USB.
- Drivers do Kinect instalados no sistema operacional: Kinect SDK no Windows ou libfreenect no Linux, conforme o backend selecionado pelo componente `TAIKinectSensor`.

## Como compilar

Abra `kinect_capture_demo.lpi` no Lazarus e pressione F9, ou compile pela linha de comando:

```bash
lazbuild kinect_capture_demo.lpi
```

## Como usar

Clique em "Conectar" para abrir o dispositivo selecionado e iniciar o stream. A imagem colorida aparece no painel direito. Use "Desconectar" para encerrar a captura. Marque "Depth" antes de conectar para exibir tambem o stream de profundidade, quando o backend do Kinect oferecer suporte.

## Estrutura de arquivos

- `kinect_capture_demo.lpi`: arquivo de projeto Lazarus com pacotes e modos de build.
- `kinect_capture_demo.lpr`: ponto de entrada da aplicacao.
- `main.lfm`: definicao visual do formulario principal.
- `main.pas`: logica de conexao, streams, status, FPS e tratamento de erros.
