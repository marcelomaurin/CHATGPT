# Componente `TAICameraCapture`

O componente `TAICameraCapture` permite a captura de imagens e frames de vídeo a partir de câmeras e webcams físicas em aplicações Lazarus / Free Pascal nativamente, **sem qualquer dependência de Python ou OpenCV**.

No Windows, a captura é realizada chamando APIs nativas do sistema operacional via Video for Windows (`avicap32.dll`).

---

## 1. Status de Maturidade

*   **Status Atual**: `Experimental`
*   **Release Target**: Próxima versão estável (com transição para `Beta` após validação de gravação contínua).

---

## 2. Dependências e Instalação

O componente é **100% puro Lazarus / Free Pascal**. Não requer nenhuma biblioteca ou instalador externo:
- **Windows**: Usa `avicap32.dll` (nativa do Windows).
- **Linux/macOS**: Compila com segurança em stubs controlados (suporte nativo planejado para V4L2/AVFoundation em fases futuras).

---

## 3. Propriedades Principais

| Propriedade | Tipo | Valor Padrão | Descrição |
|---|---|---|---|
| `CameraIndex` | `Integer` | `0` | Índice do driver de câmera no sistema (0 = webcam padrão, 1 = secundária, etc.). |
| `Width` | `Integer` | `640` | Largura da resolução de captura. |
| `Height` | `Integer` | `480` | Altura da resolução de captura. |
| `FPS` | `Integer` | `30` | Taxa de quadros por segundo desejada. |
| `Backend` | `TAICameraBackend` | `cbAuto` | Backend de captura (`cbAuto`, `cbWindowsVFW` ou `cbNativeStub`). |
| `PreviewHandle` | `THandle` | `0` | Handle de um controle visual (ex: `PanelPreview.Handle`) onde o vídeo será renderizado em tempo real. |
| `PreviewEnabled` | `Boolean` | `True` | Se ativado, desenha o preview ao vivo diretamente no `PreviewHandle`. |
| `TempFolder` | `string` | `''` | Pasta para gravar frames temporários. Se vazia, usa a pasta Temp do sistema. |
| `AutoDeleteTempFiles` | `Boolean` | `True` | Se ativado, limpa automaticamente os arquivos de frames antigos gerados na pasta Temp. |
| `CaptureInterval` | `Integer` | `100` | Intervalo em milissegundos para capturas periódicas do timer interno. |
| `MaxCameraScan` | `Integer` | `5` | Limite superior para escanear índices de câmeras no sistema. |
| `Active` | `Boolean` | `False` | *(Apenas leitura)* Indica se a captura está ligada. |
| `LastFrameFile` | `string` | `''` | *(Apenas leitura)* Caminho completo do último frame temporário capturado. |

---

## 4. Métodos Públicos

*   `function StartCapture: Boolean;`
    Inicia a câmera e ativa o preview visual no controle definido por `PreviewHandle`. Retorna `True` se a câmera foi aberta.
*   `procedure StopCapture;`
    Para a captura e fecha a webcam física.
*   `function QueryFrame: Boolean;`
    Captura o frame atual da câmera, salva-o como um arquivo Bitmap (`.bmp`) temporário e dispara o evento `OnFrame`.
*   `function CaptureToFile(const AFileName: string): Boolean;`
    Salva o frame atual como Bitmap diretamente no caminho indicado por `AFileName`.
*   `function CaptureToImage(AImage: TImage): Boolean;`
    Gera um frame e o carrega diretamente dentro do controle visual `TImage` especificado.
*   `function SelfTest: Boolean;`
    Verifica a compatibilidade de plataforma e tenta conectar e obter um frame de teste.
*   `function ListAvailableCameras: TStringList;`
    Retorna uma lista contendo índice e descrição dos drivers de câmera encontrados no sistema.

---

## 5. Eventos

*   `property OnFrame: TAIFrameEvent`
    `procedure(Sender: TObject; const AFrameFile: string)`
    Disparado a cada frame capturado pelo timer interno.
*   `property OnError: TAICameraErrorEvent`
    `procedure(Sender: TObject; const AError: string)`
    Disparado quando ocorrem erros de conexão ou captura.
*   `property OnStateChange: TAICameraStateEvent`
    `procedure(Sender: TObject; AActive: Boolean)`
    Disparado quando o estado de captura muda (`Active` altera).

---

## 6. Exemplo Básico de Uso

```pascal
procedure TForm1.FormCreate(Sender: TObject);
begin
  Camera1.CameraIndex := 0;
  Camera1.Width := 640;
  Camera1.Height := 480;
  // Define o painel onde o preview ao vivo será renderizado nativamente pelo Windows
  Camera1.PreviewHandle := PanelPreview.Handle;
  Camera1.PreviewEnabled := True;
end;

procedure TForm1.btnStartClick(Sender: TObject);
begin
  if not Camera1.StartCapture then
    ShowMessage('Falha ao abrir câmera: ' + Camera1.LastError);
end;

procedure TForm1.btnCaptureClick(Sender: TObject);
begin
  // Tira uma foto e exibe no componente TImage lateral
  Camera1.CaptureToImage(ImageCaptured);
end;

procedure TForm1.btnStopClick(Sender: TObject);
begin
  Camera1.StopCapture;
end;
```
