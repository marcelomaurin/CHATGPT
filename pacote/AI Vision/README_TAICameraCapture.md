# Componente `TAICameraCapture`

O componente `TAICameraCapture` permite a captura de imagens e frames de vídeo a partir de câmeras e webcams físicas em aplicações Lazarus / Free Pascal, utilizando inicialmente uma ponte externa com Python e OpenCV.

---

## 1. Status de Maturidade

*   **Status Atual**: `Experimental`
*   **Release Target**: Próxima versão estável (com transição para `Beta` após validação de gravação contínua).

---

## 2. Dependências e Instalação

O componente requer um interpretador Python 3 no caminho do sistema com as seguintes dependências instaladas:

```bash
pip install opencv-python numpy
```

---

## 3. Propriedades Principais

| Propriedade | Tipo | Valor Padrão | Descrição |
|---|---|---|---|
| `CameraIndex` | `Integer` | `0` | Índice da câmera no sistema (0 = webcam padrão, 1 = secundária, etc.). |
| `Width` | `Integer` | `640` | Largura da resolução de captura desejada. |
| `Height` | `Integer` | `480` | Altura da resolução de captura desejada. |
| `FPS` | `Integer` | `30` | Taxa de quadros por segundo desejada. |
| `Backend` | `TAICameraBackend` | `cbOpenCVPython` | Backend de captura (`cbOpenCVPython` ou `cbNativeStub`). |
| `AutoDeleteTempFiles` | `Boolean` | `True` | Se ativado, limpa automaticamente arquivos temporários de frames antigos da pasta Temp. |
| `CaptureInterval` | `Integer` | `100` | Intervalo em milissegundos para captura automática e disparo do evento `OnFrame`. |
| `MaxCameraScan` | `Integer` | `5` | Limite de busca de índices de câmera ao listar. |
| `PythonPath` | `string` | `'python'` | Caminho ou nome do executável Python. |
| `ScriptPath` | `string` | *(auto)* | Caminho para o script auxiliar `camera_capture.py`. |
| `Active` | `Boolean` | `False` | *(Apenas leitura)* Indica se a captura automática está rodando. |
| `LastFrameFile` | `string` | `''` | *(Apenas leitura)* Caminho completo do último frame temporário capturado. |

---

## 4. Métodos Públicos

*   `function StartCapture: Boolean;`
    Inicia a câmera e ativa o timer interno para disparar capturas contínuas. Retorna `True` se a câmera foi aberta de verdade.
*   `procedure StopCapture;`
    Para a captura contínua e libera a câmera.
*   `function QueryFrame: Boolean;`
    Captura um único frame e salva-o em um arquivo temporário PNG. Atualiza `LastFrameFile` e dispara o evento `OnFrame`.
*   `function CaptureToFile(const AFileName: string): Boolean;`
    Captura um frame e salva-o diretamente no caminho especificado por `AFileName`.
*   `function CaptureToImage(AImage: TImage): Boolean;`
    Captura um frame e o carrega no componente visual `TImage` informado.
*   `function SelfTest: Boolean;`
    Verifica a presença do Python, bibliotecas necessárias e se a câmera correspondente ao `CameraIndex` responde.
*   `function ListAvailableCameras: TStringList;`
    Retorna uma lista simples no formato `0 - Camera disponível` contendo todas as câmeras válidas no sistema de 0 até `MaxCameraScan`.

---

## 5. Eventos

*   `property OnFrame: TAIFrameEvent`
    `procedure(Sender: TObject; const AFrameFile: string)`
    Disparado a cada novo frame capturado pelo timer interno.
*   `property OnError: TAICameraErrorEvent`
    `procedure(Sender: TObject; const AError: string)`
    Disparado quando ocorre um erro de abertura de câmera ou chamada ao interpretador Python.
*   `property OnStateChange: TAICameraStateEvent`
    `procedure(Sender: TObject; AActive: Boolean)`
    Disparado quando o estado de captura muda (`Active` altera).

---

## 6. Exemplo Básico de Uso

```pascal
var
  Camera: TAICameraCapture;
  
procedure TForm1.FormCreate(Sender: TObject);
begin
  Camera := TAICameraCapture.Create(Self);
  Camera.OnFrame := @OnCameraFrame;
  Camera.OnError := @OnCameraError;
end;

procedure TForm1.btnStartClick(Sender: TObject);
begin
  Camera.CameraIndex := 0;
  Camera.Width := 640;
  Camera.Height := 480;
  if not Camera.StartCapture then
    ShowMessage('Erro: ' + Camera.LastError);
end;

procedure TForm1.btnStopClick(Sender: TObject);
begin
  Camera.StopCapture;
end;

procedure TForm1.OnCameraFrame(Sender: TObject; const AFrameFile: string);
begin
  // Atualiza visualização na tela
  Image1.Picture.LoadFromFile(AFrameFile);
end;

procedure TForm1.OnCameraError(Sender: TObject; const AError: string);
begin
  ShowMessage('Erro na Câmera: ' + AError);
end;
```

---

## 7. Limitações e Problemas Comuns

1.  **Atraso na Captura Contínua (Overhead de Processo)**: Nesta versão inicial (`Experimental`), cada captura inicia um pequeno processo Python para obter o frame, o que pode limitar a taxa real de quadros em PCs mais lentos. O uso de `CaptureInterval` em 100ms (~10 FPS) é recomendado para manter estabilidade.
2.  **Travamento de Porta/Câmera**: Se a aplicação for fechada abruptamente sem chamar `StopCapture`, o processo Python pode demorar alguns segundos para fechar e liberar o recurso de hardware da webcam.
