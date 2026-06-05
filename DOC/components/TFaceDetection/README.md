# TFaceDetection

## Finalidade

`TFaceDetection` integra detecção facial baseada em backend externo/Python ao projeto Lazarus.

## Unit

```pascal
pacote/IA/facedetection.pas
```

## Pacote

```text
openai_python.lpk
```

## Status

```text
Experimental
```

## Propriedades principais

| Propriedade | Descrição |
|---|---|
| `ImagePath` | Imagem de entrada |
| `ModelPath` | Modelo/classificador usado, quando disponível |
| `LastError` | Último erro |
| `LastResult` | Resultado da detecção |

## Métodos principais

| Método | Descrição |
|---|---|
| `DetectFaces` | Executa detecção facial |
| `SelfTest` | Deve validar dependências, quando implementado |

## Exemplo

```pascal
procedure TForm1.Button1Click(Sender: TObject);
begin
  FaceDetection1.ImagePath := 'foto.jpg';

  if FaceDetection1.DetectFaces then
    Memo1.Lines.Text := FaceDetection1.LastResult
  else
    ShowMessage(FaceDetection1.LastError);
end;
```

## Limitações

* Experimental.
* Validar dependências e backend antes de uso.
* Para a aba `AI Vision`, o `TAIFaceTracker` ainda é placeholder separado deste componente.
