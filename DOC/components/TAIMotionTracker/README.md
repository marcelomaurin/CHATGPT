# TAIMotionTracker

## Finalidade

`TAIMotionTracker` detecta movimento comparando dois frames/imagens em `TBitmap`.

A estratégia atual é 100% nativa em Lazarus/Free Pascal: calcula luminância por pixel, compara diferenças acima de um threshold e determina o percentual de movimento.

## Unit

```pascal
pacote/AI Vision/aimotiontracker.pas
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

## Propriedades principais

| Propriedade | Descrição |
|---|---|
| `Threshold` | Diferença mínima de luminância para contar pixel alterado |
| `MinMotionPercent` | Percentual mínimo de pixels alterados para considerar movimento |
| `MotionPercent` | Percentual calculado na última análise |
| `LastMotionDetected` | Resultado booleano da última análise |
| `LastDifferencePixels` | Quantidade de pixels considerados diferentes |
| `LastError` | Último erro registrado |
| `LastResult` | Último resultado textual |

## Métodos principais

| Método | Descrição |
|---|---|
| `DetectMotion` | Compara dois `TBitmap` |
| `DetectMotionFromFiles` | Carrega dois arquivos de imagem e compara |
| `GetMotionPercent` | Retorna o percentual de movimento calculado |

## Exemplo

```pascal
procedure TForm1.Button1Click(Sender: TObject);
begin
  AIMotionTracker1.Threshold := 15;
  AIMotionTracker1.MinMotionPercent := 1.5;

  if AIMotionTracker1.DetectMotionFromFiles('frame1.bmp', 'frame2.bmp') then
    ShowMessage('Movimento detectado: ' + FloatToStr(AIMotionTracker1.MotionPercent) + '%')
  else
    ShowMessage('Sem movimento relevante ou erro: ' + AIMotionTracker1.LastError);
end;
```

## Limitações

* As imagens precisam ter o mesmo tamanho.
* A técnica é simples e sensível a iluminação.
* Não faz tracking de objeto; apenas diferença global de frames.
* Para vídeo contínuo, combine com `TAIFrameBuffer` ou captura por câmera.
