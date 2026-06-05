# TAIFrameDiff

## Finalidade

`TAIFrameDiff` gera uma imagem de diferença absoluta entre dois frames/imagens.

Ele é útil para visualizar variações entre quadros, apoiar detecção de movimento e depuração de pipelines de visão.

## Unit

```pascal
pacote/AI Vision/aiframediff.pas
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
| `LastError` | Último erro registrado |
| `LastResult` | Último resultado textual |

## Métodos principais

| Método | Descrição |
|---|---|
| `BuildDiff` | Gera diferença entre dois `TBitmap`, conforme implementação |
| `BuildDiffFromFiles` | Gera diferença entre dois arquivos, quando disponível |
| `SaveDiff` | Salva a imagem de diferença, quando disponível |

## Exemplo

```pascal
procedure TForm1.Button1Click(Sender: TObject);
begin
  if AIFrameDiff1.BuildDiffFromFiles('frame1.bmp', 'frame2.bmp', 'diff.bmp') then
    ShowMessage('Diferença gerada')
  else
    ShowMessage(AIFrameDiff1.LastError);
end;
```

## Limitações

* As imagens devem ter dimensões compatíveis.
* Este componente gera diferença visual; para decisão booleana de movimento use `TAIMotionTracker`.
