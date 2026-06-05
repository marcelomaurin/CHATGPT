# TAIFaceTracker

## Finalidade

`TAIFaceTracker` rastreia uma região/template dentro de um `TBitmap` usando template matching nativo por SAD.

Apesar do nome, no estado atual ele **não é um detector facial semântico**. Ele acompanha uma região visual definida como template.

## Unit

```pascal
pacote/AI Vision/aifacetracker.pas
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
Beta técnico
```

## Propriedades principais

| Propriedade | Descrição |
|---|---|
| `SearchRadius` | Raio de busca ao redor da última posição conhecida |
| `MatchThreshold` | Diferença média máxima aceita para considerar match |
| `LastX` | Última posição X rastreada |
| `LastY` | Última posição Y rastreada |
| `LastWidth` | Largura do template |
| `LastHeight` | Altura do template |
| `LastError` | Último erro registrado |
| `LastResult` | Último resultado textual |

## Métodos principais

| Método | Descrição |
|---|---|
| `SetTemplateFromBitmap` | Define o template a partir de uma região de um `TBitmap` |
| `TrackInBitmap` | Procura o template dentro de um novo `TBitmap` |
| `TrackFace` | Método compatível que aceita `TObject`, esperando um `TBitmap` |
| `ClearTemplate` | Remove o template atual |

## Exemplo

```pascal
procedure TForm1.ButtonSetTemplateClick(Sender: TObject);
begin
  if not AIFaceTracker1.SetTemplateFromBitmap(Image1.Picture.Bitmap, 100, 80, 120, 120) then
    ShowMessage(AIFaceTracker1.LastError);
end;

procedure TForm1.ButtonTrackClick(Sender: TObject);
var
  X, Y: Integer;
begin
  if AIFaceTracker1.TrackInBitmap(Image2.Picture.Bitmap, X, Y) then
    ShowMessage(Format('Template encontrado em X=%d Y=%d', [X, Y]))
  else
    ShowMessage(AIFaceTracker1.LastError);
end;
```

## Limitações

* Não identifica rosto automaticamente.
* Não usa cascade, DNN ou OpenCV.
* Rastreia similaridade de pixels por template matching/SAD.
* Pode falhar com mudança forte de iluminação, escala, rotação ou oclusão.
