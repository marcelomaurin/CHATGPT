# TAIOpenCV

## Finalidade

`TAIOpenCV` integra aplicações Lazarus com OpenCV por meio de um worker Python.

Ele permite processar imagens com filtros básicos e obter metadados técnicos da imagem.

## Unit

```pascal
pacote/AI Vision/aiopencv.pas
```

## Pacote

```text
openai_vision.lpk
```

## Status

```text
Beta
```

## Dependências

```bash
pip install opencv-python numpy
```

Worker usado:

```text
pacote/python/aiopencv_worker.py
```

## Propriedades principais

| Propriedade | Descrição |
|---|---|
| `Backend` | Backend usado; recomendado `ocvPythonProcess` |
| `PythonPath` | Caminho do executável Python |
| `WorkerScript` | Caminho do worker Python |
| `InputFile` | Arquivo de imagem de entrada |
| `OutputFile` | Arquivo de imagem de saída |
| `FilterType` | Filtro aplicado |
| `BlurKernelSize` | Kernel do blur |
| `ThresholdValue` | Valor do threshold |
| `CannyThreshold1` | Limiar inferior do Canny |
| `CannyThreshold2` | Limiar superior do Canny |
| `ResizeWidth` | Largura do resize |
| `ResizeHeight` | Altura do resize |
| `LastImageWidth` | Largura da última imagem lida/processada |
| `LastImageHeight` | Altura da última imagem lida/processada |
| `LastChannels` | Quantidade de canais |

## Métodos principais

| Método | Descrição |
|---|---|
| `SelfTest` | Verifica se Python/OpenCV estão disponíveis |
| `LoadLibraries` | Valida backend e dependências |
| `GetImageInfo` | Lê largura, altura e canais |
| `ProcessFile` | Processa imagem de entrada e salva saída |
| `ApplyFilter` | Processa usando `InputFile` e `OutputFile` |
| `Clear` | Limpa estado do componente |

## Filtros atuais

```text
None, Gray, Blur, Canny, Threshold, Resize
```

## Exemplo

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

## Sample

```text
pacote/samples/AI Vision/opencv_filter_demo/
```

## Limitações

* Backend Native DLL ainda não está implementado.
* Depende de Python e OpenCV instalado.
* Ainda não substitui OpenCV completo.
