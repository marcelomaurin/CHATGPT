# TAINativeImageFilter

## Finalidade

`TAINativeImageFilter` aplica filtros simples de imagem diretamente em `TBitmap`/`TLazIntfImage`, sem Python e sem OpenCV.

## Unit

```pascal
pacote/AI Vision/ainativeimagefilter.pas
```

## Pacote

```text
openai_vision.lpk
```

## Aba na IDE

```text
AI Native Vision
```

## Status

```text
Beta
```

## Filtros suportados

```pascal
niftNone
niftGray
niftThreshold
niftInvert
niftResize
niftBlurBox
```

## Propriedades principais

| Propriedade | Descrição |
|---|---|
| `FilterType` | Tipo de filtro aplicado |
| `ThresholdValue` | Valor do limiar para threshold |
| `ResizeWidth` | Largura de saída no resize |
| `ResizeHeight` | Altura de saída no resize |
| `LastError` | Último erro registrado |
| `LastResult` | Último resultado textual |

## Métodos principais

| Método | Descrição |
|---|---|
| `ApplyToBitmap` | Aplica filtro diretamente em um `TBitmap` |
| `ApplyFile` | Carrega arquivo de entrada, aplica filtro e salva saída |
| `ConvertToGray` | Converte `TLazIntfImage` para cinza |
| `ApplyThreshold` | Aplica limiarização |
| `InvertColors` | Inverte cores |
| `ResizeBitmap` | Redimensiona imagem |
| `BlurBox` | Aplica blur simples 3x3 |

## Exemplo

```pascal
procedure TForm1.Button1Click(Sender: TObject);
begin
  AINativeImageFilter1.FilterType := niftGray;

  if AINativeImageFilter1.ApplyFile('entrada.bmp', 'saida_gray.bmp') then
    ShowMessage('Imagem processada')
  else
    ShowMessage(AINativeImageFilter1.LastError);
end;
```

## Limitações

* Filtros simples, não substitui OpenCV.
* Resize usa abordagem simples, adequada para demonstração e processamento leve.
* Para operações avançadas, use `TAIOpenCV`.
