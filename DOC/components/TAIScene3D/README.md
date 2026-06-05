# TAIScene3D

## Finalidade

`TAIScene3D` representa uma cena 3D para organizar modelos, objetos, câmera e visualização.

## Unit

```pascal
pacote/AI Graphic/aiscene3d.pas
```

## Pacote

```text
openai_graphic.lpk
```

## Status

```text
Experimental
```

## Propriedades principais

| Propriedade | Descrição |
|---|---|
| `Prompt` | Descrição da cena |
| `BackgroundColor` | Cor de fundo, quando disponível |
| `CameraPosition` | Posição da câmera, quando disponível |
| `LastError` | Último erro |
| `LastResult` | Último resultado |

## Métodos principais

| Método | Descrição |
|---|---|
| `AddObject` | Adiciona objeto à cena |
| `Clear` | Limpa a cena |
| `Render` | Renderiza a cena, quando suportado |

## Exemplo

```pascal
procedure TForm1.Button1Click(Sender: TObject);
begin
  AIScene3D1.Prompt := 'Cena 3D de demonstração';
  AIScene3D1.Clear;
end;
```

## Limitações

* API ainda experimental.
* Validar suporte real de renderização e objetos antes de uso em produção.
