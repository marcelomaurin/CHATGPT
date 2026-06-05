# TAIAvatar3D

## Finalidade

`TAIAvatar3D` representa estrutura inicial para controle ou visualização de avatar 3D.

## Unit

```pascal
pacote/AI Graphic/aiavatar3d.pas
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
| `Prompt` | Descrição/orientação do avatar |
| `ModelFile` | Arquivo do modelo do avatar, quando disponível |
| `Pose` | Pose ou estado do avatar, quando suportado |
| `LastError` | Último erro |
| `LastResult` | Último resultado |

## Métodos principais

| Método | Descrição |
|---|---|
| `LoadAvatar` | Carrega avatar, quando implementado |
| `SetPose` | Define pose do avatar, quando implementado |
| `Reset` | Restaura estado padrão |

## Exemplo

```pascal
procedure TForm1.Button1Click(Sender: TObject);
begin
  AIAvatar3D1.Prompt := 'Avatar técnico para atendimento';
  ShowMessage('Avatar configurado. Verifique suporte real da implementação atual.');
end;
```

## Limitações

* API ainda experimental.
* Validar recursos reais antes de documentar como funcional.
