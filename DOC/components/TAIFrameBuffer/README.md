# TAIFrameBuffer

## Finalidade

`TAIFrameBuffer` mantém um buffer circular de frames para uso em processamento de vídeo, comparação de frames, detecção de movimento e pipelines de visão.

## Unit

```pascal
pacote/AI Vision/aiframebuffer.pas
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
| `Capacity` | Quantidade máxima de frames armazenados |
| `Count` | Quantidade atual de frames |
| `LastError` | Último erro registrado |
| `LastResult` | Último resultado textual |

## Métodos principais

| Método | Descrição |
|---|---|
| `AddFrame` | Adiciona frame ao buffer |
| `GetFrame` | Recupera frame por índice, conforme implementação |
| `GetLatestFrame` | Recupera o frame mais recente, quando disponível |
| `Clear` | Limpa o buffer |

## Exemplo

```pascal
procedure TForm1.Button1Click(Sender: TObject);
begin
  AIFrameBuffer1.Capacity := 10;
  AIFrameBuffer1.AddFrame(Image1.Picture.Bitmap);
end;
```

## Limitações

* Verifique se o componente copia o bitmap ou apenas guarda referência.
* Para processamento contínuo, cuide do consumo de memória.
