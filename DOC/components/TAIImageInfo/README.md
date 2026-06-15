# TAIImageInfo

## Finalidade

`TAIImageInfo` extrai informações técnicas e metadados de imagens de forma nativa em Lazarus/Free Pascal, sem depender de Python, OpenCV ou DLLs externas.

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
| `Width` | Largura da imagem em pixels |
| `Height` | Altura da imagem em pixels |
| `PixelCount` | Quantidade total de pixels (`Width * Height`) |
| `FileName` | Nome do arquivo de imagem carregado |
| `FileExists` | Indica se o arquivo correspondente existe no disco |
| `FileSizeBytes` | Tamanho do arquivo em bytes |
| `Extension` | Extensão do arquivo de imagem (ex: `.png`) |
| `FormatName` | Formato da imagem detectado (ex: `PNG`, `JPEG`, `BMP`) |
| `AspectRatio` | Proporção da imagem (`Width / Height`) |
| `MegaPixels` | Resolução da imagem em Megapixels |
| `Orientation` | Orientação da imagem (`ioSquare`, `ioLandscape`, `ioPortrait`) |
| `IsLoaded` | Indica se as informações foram carregadas com sucesso |
| `SourceKind` | Tipo de origem carregada (`iskNone`, `iskFile`, `iskBitmap`, `iskPicture`) |

## Métodos principais

| Método | Descrição |
|---|---|
| `ClearInfo` | Limpa todas as informações e erros do componente |
| `LoadInfoFromFile` | Carrega e analisa metadados a partir de um arquivo físico |
| `LoadInfoFromBitmap` | Extrai informações a partir de um objeto `TBitmap` |
| `LoadInfoFromPicture` | Extrai informações a partir de um objeto `TPicture` |
| `AsText` | Retorna um relatório textual formatado |
| `AsJSON` | Retorna as propriedades serializadas em JSON válido |
| `GetDiagnosticReport` | Retorna o relatório textual de diagnóstico |
| `OrientationAsString` | Retorna a orientação como string |
| `SourceKindAsString` | Retorna a origem como string |

## Exemplo

```pascal
procedure TForm1.Button1Click(Sender: TObject);
begin
  if AIImageInfo1.LoadInfoFromFile('imagem.png') then
  begin
    Memo1.Lines.Text := AIImageInfo1.AsText;
    ShowMessage('JSON: ' + AIImageInfo1.AsJSON);
  end
  else
    ShowMessage(AIImageInfo1.LastError);
end;
```

## Limitações

* Focado em metadados técnicos estruturais rápidos.
* Não processa pixels ou altera a imagem.
