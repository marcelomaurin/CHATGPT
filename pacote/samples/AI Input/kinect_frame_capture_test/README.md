# Kinect Frame Capture Test

Teste de console para validar o backend Kinect SDK10 sem interface grafica.

Ao executar, o programa tenta abrir o Kinect v1 pelo SDK 1.8, iniciar o stream colorido, aguardar um frame por ate 15 segundos e salvar:

- `capture_output/captured_color_frame.bmp`
- `capture_output/kinect_frame_capture_test.log`

Use este teste para diferenciar falha no backend de falha na UI do `kinect_capture_demo`.