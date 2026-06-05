# TAI3DModelViewer

## Finalidade

`TAI3DModelViewer` é um visualizador básico de modelos 3D para Lazarus.

Pode ser usado para carregar, visualizar, rotacionar e inspecionar modelos em aplicações desktop.

## Unit

```pascal
pacote/AI Graphic/ai3dmodelviewer.pas
```

## Pacote

```text
openai_graphic.lpk
```

## Status

```text
Beta/Experimental
```

## Propriedades principais

| Propriedade | Descrição |
|---|---|
| `ModelFile` | Caminho do modelo carregado |
| `Zoom` | Fator de zoom |
| `RotationX` | Rotação no eixo X |
| `RotationY` | Rotação no eixo Y |
| `RotationZ` | Rotação no eixo Z |
| `ViewMode` | Modo de visualização, quando disponível |

## Métodos principais

| Método | Descrição |
|---|---|
| `LoadFromFile` | Carrega modelo 3D |
| `Clear` | Limpa modelo atual |
| `ResetView` | Restaura visualização padrão |
| `SaveScreenshot` | Salva imagem da visualização, quando suportado |

## Exemplo

```pascal
procedure TForm1.Button1Click(Sender: TObject);
begin
  AI3DModelViewer1.LoadFromFile('modelo.stl');
  AI3DModelViewer1.Zoom := 1.2;
end;
```

## Limitações

* Viewer básico, não substitui Blender, CAD ou engine 3D completa.
* Recursos dependem do formato suportado pela implementação atual.
