# TAIModel3D

## Finalidade

`TAIModel3D` representa a estrutura de dados de um modelo 3D carregado pelo pacote gráfico.

## Unit

```pascal
pacote/AI Graphic/aimodel3d.pas
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
| `FileName` | Arquivo de origem do modelo |
| `VertexCount` | Quantidade de vértices, quando disponível |
| `FaceCount` | Quantidade de faces, quando disponível |
| `BoundingBox` | Caixa delimitadora, quando disponível |

## Métodos principais

| Método | Descrição |
|---|---|
| `LoadFromFile` | Carrega modelo 3D |
| `Clear` | Limpa dados do modelo |
| `CalculateBounds` | Calcula limites do modelo |

## Exemplo

```pascal
procedure TForm1.Button1Click(Sender: TObject);
begin
  AIModel3D1.LoadFromFile('peca.stl');
  ShowMessage('Modelo carregado');
end;
```

## Limitações

* Validar formatos realmente suportados pela implementação atual.
* Não substitui uma biblioteca CAD completa.
