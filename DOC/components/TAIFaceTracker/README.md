# TAIFaceTracker

## Finalidade

`TAIFaceTracker` representa a estrutura inicial para detecção/rastreamento facial dentro da aba **AI Vision**.

## Unit

```pascal
pacote/AI Vision/aifacetracker.pas
```

## Pacote

```text
openai_vision.lpk
```

## Status

```text
Placeholder
```

## Propriedades principais

| Propriedade | Descrição |
|---|---|
| `CascadeClassifierPath` | Caminho previsto para classificador cascade |
| `Prompt` | Descrição do componente |
| `LastError` | Último erro registrado |
| `LastResult` | Último resultado textual |

## Métodos principais

| Método | Descrição |
|---|---|
| `TrackFace` | Recebe um frame e retorna coordenadas de face. Atualmente sempre retorna `False` |

## Exemplo

```pascal
procedure TForm1.Button1Click(Sender: TObject);
var
  X, Y, W, H: Integer;
begin
  AIFaceTracker1.CascadeClassifierPath := 'haarcascade_frontalface_default.xml';

  if AIFaceTracker1.TrackFace(nil, X, Y, W, H) then
    ShowMessage(Format('Face: %d,%d %dx%d', [X, Y, W, H]))
  else
    ShowMessage('Nenhuma face detectada. Atualmente este componente ainda é placeholder.');
end;
```

## Limitações

* Não realiza detecção facial real no estado atual.
* `TrackFace` sempre retorna `False`.
* Deve ser integrado futuramente com OpenCV, DNN ou outro backend real.
