# TAICameraCapture Demo Application

Este projeto demonstra o uso do componente `TAICameraCapture` para realizar captura de imagens de webcam/câmera real usando Python e OpenCV.

## Pré-requisitos

Para rodar esta demonstração, certifique-se de ter instalado o Python 3 e as seguintes bibliotecas no seu ambiente:

```bash
pip install opencv-python numpy
```

## Como compilar e executar

Você pode abrir o projeto `camera_capture_demo.lpi` no Lazarus e pressionar `F9` para compilar e executar, ou compilar via terminal usando `lazbuild`:

```powershell
C:\lazarus\lazbuild.exe camera_capture_demo.lpi
```

## Funcionalidades demonstradas

1. **Listar Câmeras**: Escaneia as portas e índices disponíveis na máquina e atualiza o ComboBox.
2. **Iniciar Captura**: Abre a câmera indicada, define largura/altura/FPS e liga a captura contínua.
3. **Parar Captura**: Para a captura e desliga a câmera.
4. **Capturar Frame Único**: Solicita um único frame da webcam à API e exibe o preview.
5. **Salvar Frame**: Salva o frame atual capturado em um arquivo PNG/JPG à sua escolha.
