# TAIFrameProcessor

## Finalidade

`TAIFrameProcessor` representa o componente de processamento e preparação de frames de imagem dentro da aba **AI Vision**. Ele suporta redimensionamento geométrico, filtros de escala de cinza e a manipulação detalhada de canais RGB individuais, permitindo pré-processar imagens para OpenCV, YOLO, OCR e redes neurais.

## Unit

```pascal
pacote/AI Vision/aiframeprocessor.pas
```

## Pacote

```text
openai_vision.lpk
```

## Status

```text
Stable / Implementado
```

## Propriedades principais

| Propriedade | Descrição | Valor Padrão |
|---|---|---|
| `ScaleFactor` | Fator de escala previsto para redimensionamento geométrico | `1.0` |
| `Grayscale` | Converter imagem resultante para escala de cinza (após canais RGB) | `False` |
| `RGBChannelMode` | Modo de filtragem de canais RGB (`cmNone`, `cmExtractRed`, `cmKeepBlueOnly`, `cmSwapRB`, `cmCustom`, etc) | `cmNone` |
| `RedEnabled`, `GreenEnabled`, `BlueEnabled` | Ativa/Desativa o respectivo canal de cor (usado no modo `cmCustom`) | `True` |
| `RedGain`, `GreenGain`, `BlueGain` | Multiplicador de intensidade para ganho de brilho específico por canal | `1.0` |
| `RedOffset`, `GreenOffset`, `BlueOffset` | Deslocamento aditivo (offset) de intensidade por canal | `0` |
| `InvertRed`, `InvertGreen`, `InvertBlue` | Inverte a cor do respectivo canal (ex: `255 - R`) | `False` |

## Métodos principais

| Método | Descrição |
|---|---|
| `ProcessFrame(AFrame: TObject): TObject` | Recebe um frame e retorna o frame processado. Caso o objeto seja um `TBitmap`, executa as operações de redimensionamento e RGB. |
| `ProcessBitmap(ABitmap: TBitmap): TBitmap` | Método nativo para processamento direto de objetos bitmap. |

## Exemplo de Uso Customizado

```pascal
FrameProcessor1.RGBChannelMode := cmCustom;
FrameProcessor1.RedGain := 1.2;
FrameProcessor1.GreenGain := 1.0;
FrameProcessor1.BlueGain := 0.8;
FrameProcessor1.RedOffset := 10;
FrameProcessor1.InvertBlue := True;

ProcessedBitmap := FrameProcessor1.ProcessBitmap(OriginalBitmap);
```

## Ordem de Processamento

1. Crop (Recorte)
2. Resize (Redimensionamento por `ScaleFactor`)
3. RGB Channels (`ApplyRGBChannels`)
4. Grayscale (Conversão para Cinza se `Grayscale` estiver ativo)
