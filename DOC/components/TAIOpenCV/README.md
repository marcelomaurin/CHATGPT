# TAIOpenCV

## Finalidade

`TAIOpenCV` integra aplicações Lazarus com OpenCV usando dois modos de backend:

1. `ocvPythonProcess`: processamento real via worker Python.
2. `ocvNativeDLL`: localização e carregamento de DLL/SO nativa OpenCV.

Ele permite processar imagens com filtros básicos, obter metadados técnicos da imagem e testar a disponibilidade do runtime OpenCV.

---

## Unit

```pascal
pacote/AI Vision/aiopencv.pas
```

Unit auxiliar de runtime nativo:

```pascal
pacote/AI Vision/aiopencvruntime.pas
```

---

## Pacote

```text
openai_vision.lpk
```

---

## Status

```text
Beta
```

---

## Backends

| Backend | Status | Descrição |
|---|---|---|
| `ocvPythonProcess` | Funcional/Beta | Usa `pacote/python/aiopencv_worker.py` para processar imagens com OpenCV Python |
| `ocvNativeDLL` | Parcial/Experimental | Localiza e carrega `opencv_world*.dll` ou `libopencv_world.so*`; processamento real nativo ainda não está implementado |

---

## Dependências do backend Python

```bash
pip install opencv-python numpy
```

Worker usado:

```text
pacote/python/aiopencv_worker.py
```

---

## Runtime nativo OpenCV

O backend `ocvNativeDLL` usa a unit:

```text
pacote/AI Vision/aiopencvruntime.pas
```

Essa unit procura primeiro o runtime OpenCV versionado no próprio projeto:

```text
runtime/opencv/windows/x86/bin/
runtime/opencv/windows/x64/bin/
runtime/opencv/linux/x64/lib/
runtime/opencv/linux/arm64/lib/
runtime/opencv/linux/armhf/lib/
```

No Windows, procura:

```text
opencv_world*.dll
```

No Linux, procura:

```text
libopencv_world.so*
```

A busca considera sistema operacional, arquitetura do processo, manifesto `runtime/opencv/manifest.json`, maior versão disponível e fallback controlado.

---

## Propriedades principais

| Propriedade | Descrição |
|---|---|
| `Backend` | Backend usado: `ocvPythonProcess` ou `ocvNativeDLL` |
| `Runtime` | Runtime Python associado, quando usado |
| `PythonPath` | Caminho do executável Python |
| `WorkerScript` | Caminho do worker Python |
| `TimeoutMs` | Timeout de execução do worker/processo |
| `InputFile` | Arquivo de imagem de entrada |
| `OutputFile` | Arquivo de imagem de saída |
| `FilterType` | Filtro aplicado |
| `BlurKernelSize` | Kernel do blur |
| `ThresholdValue` | Valor do threshold |
| `CannyThreshold1` | Limiar inferior do Canny |
| `CannyThreshold2` | Limiar superior do Canny |
| `ResizeWidth` | Largura do resize |
| `ResizeHeight` | Altura do resize |
| `LibraryLoaded` | Indica se a biblioteca OpenCV foi carregada |
| `Version` | Versão detectada/reportada |
| `LastImageWidth` | Largura da última imagem lida/processada |
| `LastImageHeight` | Altura da última imagem lida/processada |
| `LastChannels` | Quantidade de canais |
| `AutoSave` | Exige arquivo de saída quando processa |
| `OverwriteOutput` | Permite sobrescrever saída existente |
| `UseBundledRuntime` | Prioriza runtime OpenCV dentro do projeto |
| `OpenCVLibraryPath` | Caminho manual da DLL/SO |
| `OpenCVLibraryName` | Nome manual da DLL/SO |
| `AutoDetectLibrary` | Mantido para detecção automática de biblioteca |
| `ResolvedLibraryPath` | Caminho final da biblioteca nativa resolvida |

---

## Eventos

| Evento | Descrição |
|---|---|
| `OnBeforeProcess` | Chamado antes do processamento |
| `OnAfterProcess` | Chamado após o processamento |
| `OnImageProcessed` | Chamado quando uma imagem é processada com sucesso |
| `OnOpenCVError` | Chamado quando ocorre erro específico do OpenCV |
| `OnLog` | Herdado de `TAIBaseComponent`, registra logs técnicos |

---

## Métodos principais

| Método | Descrição |
|---|---|
| `SelfTest` | Verifica disponibilidade do backend selecionado |
| `LoadLibraries` | Localiza e carrega biblioteca nativa quando `Backend = ocvNativeDLL` |
| `GetImageInfo` | Lê largura, altura e canais usando backend Python |
| `ProcessFile` | Processa imagem de entrada e salva saída |
| `ApplyFilter` | Processa usando `InputFile` e `OutputFile` |
| `Clear` | Limpa estado do componente |

---

## Filtros atuais

```text
None, Gray, Blur, Canny, Threshold, Resize
```

Os filtros são executados de forma real pelo backend `ocvPythonProcess`.

---

## Exemplo com backend Python

```pascal
procedure TForm1.Button1Click(Sender: TObject);
begin
  AIOpenCV1.Backend := ocvPythonProcess;
  AIOpenCV1.FilterType := ocvfCanny;
  AIOpenCV1.CannyThreshold1 := 100;
  AIOpenCV1.CannyThreshold2 := 200;

  if AIOpenCV1.ProcessFile('entrada.jpg', 'saida_canny.jpg') then
    ShowMessage(AIOpenCV1.LastResult)
  else
    ShowMessage(AIOpenCV1.LastError);
end;
```

---

## Exemplo com runtime nativo

```pascal
procedure TForm1.Button1Click(Sender: TObject);
begin
  AIOpenCV1.Backend := ocvNativeDLL;
  AIOpenCV1.UseBundledRuntime := True;

  if AIOpenCV1.LoadLibraries then
    ShowMessage('OpenCV nativo carregado: ' + AIOpenCV1.ResolvedLibraryPath)
  else
    ShowMessage(AIOpenCV1.LastError);
end;
```

---

## Samples

```text
pacote/samples/AI Vision/opencv_filter_demo/
pacote/samples/AI Vision/opencv_image_real_demo/
```

---

## Limitações atuais

* `ocvPythonProcess` é o backend recomendado para processamento real de imagem.
* `ocvNativeDLL` atualmente localiza e carrega a DLL/SO, mas o processamento real nativo ainda não chama funções OpenCV.
* No fluxo nativo atual, `ProcessFile` executa uma etapa simulada/cópia de arquivo.
* O runtime nativo precisa de DLL/SO compatível com sistema operacional e arquitetura do processo.
* Ainda não substitui a API completa do OpenCV.
