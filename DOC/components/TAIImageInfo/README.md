# TAIImageInfo

## Finalidade

`TAIImageInfo` extrai informações técnicas, metadados e marcas d'água em metadados a partir de imagens de forma nativa em Lazarus/Free Pascal, sem depender de Python, OpenCV ou DLLs externas.

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
| `HasMetadata` | Indica se a imagem contém metadados associados |
| `Title`, `Author`, `Artist`, `Creator`, `Copyright`, `Description`, `Comment`, `Software` | Campos de metadados interpretados automaticamente |
| `HasWatermarkInfo` | Indica se há informações de marca d'água ou direitos nos metadados |
| `WatermarkText` | Conteúdo da marca d'água encontrada |

## Métodos principais

| Método | Descrição |
|---|---|
| `ClearInfo` | Limpa todas as informações e erros do componente |
| `LoadInfoFromFile` | Carrega e analisa metadados a partir de um arquivo físico, incluindo EXIF, XMP, IPTC e comentários |
| `LoadInfoFromBitmap` | Extrai informações básicas a partir de um objeto `TBitmap` |
| `LoadInfoFromPicture` | Extrai informações básicas a partir de um objeto `TPicture` |
| `LoadMetadataFromFile` | Executa a extração exclusiva de metadados estruturais |
| `AsText` | Retorna um relatório textual formatado detalhado |
| `AsJSON` | Retorna as propriedades serializadas em JSON válido |
| `GetDiagnosticReport` | Retorna o relatório textual de diagnóstico |

## Exemplo

```pascal
procedure TForm1.Button1Click(Sender: TObject);
begin
  if AIImageInfo1.LoadInfoFromFile('imagem.png') then
  begin
    Memo1.Lines.Text := AIImageInfo1.AsText;
    if AIImageInfo1.HasWatermarkInfo then
      ShowMessage('Marca d''água: ' + AIImageInfo1.WatermarkText);
  end
  else
    ShowMessage(AIImageInfo1.LastError);
end;
```

## Limitações

* Focado em metadados técnicos estruturais rápidos.
* Detecção de marca d'água em metadados (Copyright, Autor, Comentário, etc.). Não realiza análise de pixel (marca d'água visual).
