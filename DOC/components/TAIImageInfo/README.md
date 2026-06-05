# TAIImageInfo

## Finalidade

`TAIImageInfo` extrai informações básicas de imagens de forma nativa em Lazarus/Free Pascal.

## Unit

```pascal
pacote/AI Vision/aiimageinfo.pas
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
| `FileName` | Arquivo de imagem analisado, quando aplicável |
| `Width` | Largura da imagem |
| `Height` | Altura da imagem |
| `PixelCount` | Total de pixels |
| `LastError` | Último erro registrado |
| `LastResult` | Resultado textual da análise |

## Métodos principais

| Método | Descrição |
|---|---|
| `LoadFromFile` | Carrega e analisa arquivo de imagem |
| `AnalyzeBitmap` | Analisa um `TBitmap`, quando disponível |
| `Clear` | Limpa estado interno, quando disponível |

## Exemplo

```pascal
procedure TForm1.Button1Click(Sender: TObject);
begin
  if AIImageInfo1.LoadFromFile('imagem.bmp') then
    ShowMessage(Format('%dx%d', [AIImageInfo1.Width, AIImageInfo1.Height]))
  else
    ShowMessage(AIImageInfo1.LastError);
end;
```

## Limitações

* Focado em metadados simples.
* Não substitui análise avançada de imagem.
