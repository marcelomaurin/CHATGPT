# TAICameraCapture

## Finalidade

`TAICameraCapture` representa a estrutura inicial para captura de frames de câmera dentro da aba **AI Vision**.

## Unit

```pascal
pacote/AI Vision/aicameracapture.pas
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
| `CameraIndex` | Índice da câmera a ser usada |
| `Active` | Ativa ou desativa a captura |
| `Prompt` | Descrição do componente para agentes/IA |
| `LastError` | Último erro registrado |
| `LastResult` | Último resultado textual |

## Métodos principais

| Método | Descrição |
|---|---|
| `StartCapture` | Marca a captura como ativa |
| `StopCapture` | Marca a captura como inativa |
| `QueryFrame` | Retorna um objeto de frame. Atualmente não captura imagem real |

## Exemplo

```pascal
procedure TForm1.Button1Click(Sender: TObject);
var
  Frame: TObject;
begin
  AICameraCapture1.CameraIndex := 0;
  AICameraCapture1.StartCapture;

  Frame := AICameraCapture1.QueryFrame;
  try
    if Frame <> nil then
      ShowMessage('Frame retornado. Atenção: placeholder, não é frame real ainda.');
  finally
    Frame.Free;
  end;
end;
```

## Limitações

* O componente ainda não captura imagem real da câmera.
* `QueryFrame` retorna objeto genérico, não bitmap/frame OpenCV.
* Deve ser tratado como estrutura inicial para integração futura com câmera real.
