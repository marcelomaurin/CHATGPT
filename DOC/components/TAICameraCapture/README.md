# TAICameraCapture

## Finalidade

`TAICameraCapture` captura frames de câmera/webcam em aplicações Lazarus.

No estado atual, a implementação funcional usa **Windows VFW** via `avicap32.dll`.

## Unit

```pascal
pacote/AI Vision/aicameracapture.pas
```

## Pacote

```text
openai_vision.lpk
```

## Status

```text
Beta parcial
```

## Aba na IDE

```text
AI Vision
```

## Backends

| Backend | Status | Observação |
|---|---|---|
| `cbAuto` | Beta no Windows | Usa Windows VFW quando disponível |
| `cbWindowsVFW` | Beta no Windows | Captura via `avicap32.dll` |
| `cbNativeStub` | Stub | Backend nativo genérico ainda não implementado |

No Linux, a versão atual retorna erro de plataforma não suportada.

## Propriedades principais

| Propriedade | Descrição |
|---|---|
| `CameraIndex` | Índice da câmera |
| `Width` | Largura da captura |
| `Height` | Altura da captura |
| `FPS` | FPS configurado |
| `Backend` | Backend de captura |
| `PreviewHandle` | Handle do controle/painel usado para preview VFW |
| `PreviewEnabled` | Ativa/desativa preview |
| `TempFolder` | Pasta temporária para frames |
| `AutoDeleteTempFiles` | Apaga frames temporários antigos |
| `CaptureInterval` | Intervalo de captura por timer |
| `MaxCameraScan` | Quantidade máxima de câmeras a buscar |
| `Active` | Indica se a captura está ativa |
| `LastFrameFile` | Último frame salvo em arquivo |

## Eventos

| Evento | Descrição |
|---|---|
| `OnFrame` | Disparado quando um frame é capturado |
| `OnError` | Disparado em erro |
| `OnStateChange` | Disparado quando o estado ativo/inativo muda |

## Métodos principais

| Método | Descrição |
|---|---|
| `StartCapture` | Inicializa a captura |
| `StopCapture` | Finaliza a captura |
| `QueryFrame` | Captura um frame e salva em arquivo temporário |
| `CaptureToFile` | Captura diretamente para arquivo |
| `CaptureToImage` | Captura e carrega em um `TImage` |
| `SelfTest` | Testa conexão e captura de frame |
| `ListAvailableCameras` | Lista câmeras VFW disponíveis no Windows |

## Exemplo mínimo

```pascal
procedure TForm1.ButtonStartClick(Sender: TObject);
begin
  AICameraCapture1.Backend := cbWindowsVFW;
  AICameraCapture1.CameraIndex := 0;
  AICameraCapture1.Width := 640;
  AICameraCapture1.Height := 480;
  AICameraCapture1.PreviewEnabled := True;
  AICameraCapture1.PreviewHandle := PanelPreview.Handle;

  if not AICameraCapture1.StartCapture then
    ShowMessage(AICameraCapture1.LastError);
end;

procedure TForm1.ButtonCaptureClick(Sender: TObject);
begin
  if AICameraCapture1.CaptureToImage(Image1) then
    ShowMessage('Frame capturado: ' + AICameraCapture1.LastFrameFile)
  else
    ShowMessage(AICameraCapture1.LastError);
end;
```

## Limitações

* Captura real disponível apenas no Windows nesta versão.
* Linux ainda precisa backend próprio.
* O preview exige `PreviewHandle` quando `PreviewEnabled = True`.
* O componente salva frames como arquivos temporários BMP.
