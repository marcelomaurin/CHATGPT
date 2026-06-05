# TAIFrameProcessor

## Finalidade

`TAIFrameProcessor` representa a estrutura inicial para processamento de frames dentro da aba **AI Vision**.

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
Experimental / quase-placeholder
```

## Propriedades principais

| Propriedade | Descrição |
|---|---|
| `ScaleFactor` | Fator de escala previsto para redimensionamento |
| `Grayscale` | Indica se deveria converter para escala de cinza |
| `Prompt` | Descrição do componente |
| `LastError` | Último erro registrado |
| `LastResult` | Último resultado textual |

## Métodos principais

| Método | Descrição |
|---|---|
| `ProcessFrame` | Recebe um frame e retorna o frame processado. Atualmente retorna o próprio objeto recebido |

## Exemplo

```pascal
procedure TForm1.Button1Click(Sender: TObject);
var
  Frame, Processed: TObject;
begin
  Frame := TObject.Create;
  try
    AIFrameProcessor1.ScaleFactor := 1.0;
    AIFrameProcessor1.Grayscale := True;

    Processed := AIFrameProcessor1.ProcessFrame(Frame);

    if Processed <> nil then
      ShowMessage('Frame processado. Atenção: processamento real ainda não implementado.');
  finally
    Frame.Free;
  end;
end;
```

## Limitações

* Ainda não processa imagem real.
* Não trabalha com `TBitmap`, matriz OpenCV ou frame estruturado.
* Deve ser evoluído para usar `TAIOpenCV` ou outro backend real.
