# TAIModel3D

## Finalidade

`TAIModel3D` representa a estrutura de dados de malha (mesh), geometria, materiais PBR e pesos de skinning de um modelo 3D carregado pelo subsistema gráfico da suíte CHATGPT.

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
Em Validação nos Samples / Pronto
```

## Formatos Suportados (Tarefas 11 e 12)

* **`.glb` (glTF 2.0 Binary):** Cabeçalho binário, chunk JSON, chunk BIN, bufferViews, accessors, materiais PBR, pesos de juntas e animações em arquivo único empacotado.
* **`.gltf` (glTF 2.0 JSON):** Definições de cenas, nós, malhas e buffers externos.
* **`.stl` (Stereolithography):** Malhas geométricas estáticas ASCII e binárias.

## Propriedades Principais

| Propriedade | Descrição |
|---|---|
| `VerticesCount` | Quantidade total de vértices carregados |
| `FacesCount` | Quantidade total de faces triangulares |
| `HasSkinning` | Indica se o modelo contém juntas e pesos (`JOINTS_0`, `WEIGHTS_0`) para deformação por esqueleto |
| `MaterialsCount` | Quantidade de materiais PBR identificados |
| `BoundingBox` | Caixa delimitadora tridimensional calculada |

## Métodos Principais

| Método | Descrição |
|---|---|
| `LoadFromFile(const AFileName: string)` | Detecta automaticamente a extensão (`.glb`, `.gltf`, `.stl`) e carrega o modelo com seus buffers binários |
| `ApplySkinning(ASkeleton: TAISkeletonRig)` | Executa deformação por skinning nos vértices usando as matrizes de juntas calculadas pelo esqueleto |
| `ResetSkinning` | Restaura a malha para a pose de referência (bind pose) |
| `Clear` | Libera buffers de memória, vértices e faces carregadas |

## Exemplo de Carregamento GLB com Skinning

```pascal
procedure TForm1.LoadCharacter;
begin
  AIModel3D1.LoadFromFile('avatar_humanoide.glb');
  if AIModel3D1.HasSkinning then
  begin
    AISkeletonRig1.AutoMapHumanoidBones;
    AIModel3D1.ApplySkinning(AISkeletonRig1);
  end;
end;
```
