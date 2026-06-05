# TAIMotionTracker

## Finalidade

`TAIMotionTracker` representa a estrutura inicial para detecção de movimento entre dois frames.

## Unit

```pascal
pacote/AI Vision/aimotiontracker.pas
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
| `Sensitivity` | Sensibilidade prevista para detecção |
| `Prompt` | Descrição do componente |
| `LastError` | Último erro registrado |
| `LastResult` | Último resultado textual |

## Métodos principais

| Método | Descrição |
|---|---|
| `DetectMotion` | Compara dois frames. Atualmente sempre retorna `False` |

## Exemplo

```pascal
procedure TForm1.Button1Click(Sender: TObject);
begin
  AIMotionTracker1.Sensitivity := 10;

  if AIMotionTracker1.DetectMotion(nil, nil) then
    ShowMessage('Movimento detectado')
  else
    ShowMessage('Movimento não detectado. Atualmente este componente ainda é placeholder.');
end;
```

## Limitações

* Não compara pixels nem frames reais no estado atual.
* `DetectMotion` sempre retorna `False`.
* Deve ser integrado futuramente com frames reais, `TBitmap` ou `TAIOpenCV`.
