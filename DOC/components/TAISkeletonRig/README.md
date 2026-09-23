# TAISkeletonRig

## Finalidade

`TAISkeletonRig` gerencia a hierarquia de juntas (bones/joints), transformações locais e mundiais, cinemática direta (FK), importação de esqueletos de arquivos 3D (`.glb`, `.gltf`, `.bvh`, `.dae`) e mapeamento padronizado de ossos humanoides (`TAIHumanoidBone`).

## Unit

```pascal
pacote/AI Graphic/aiskeletonrig.pas
```

## Pacote

```text
openai_graphic.lpk
```

## Status

```text
Em Validação nos Samples / Pronto
```

## Mapeamento Humanoide Padronizado (Tarefas 8, 9 e 10)

Para evitar strings soltas e dependência de convenções de nomes específicas de modeladores, o componente padroniza o acesso via o enum `TAIHumanoidBone` (`hbHips`, `hbSpine`, `hbChest`, `hbNeck`, `hbHead`, `hbJaw`, `hbLeftEye`, `hbRightEye`, `hbLeftArm`, `hbRightArm`, etc.).

### Métodos de Mapeamento:

| Método | Descrição |
|---|---|
| `MapBone(AHumanoidBone: TAIHumanoidBone; const AModelBoneName: string)` | Mapeia explicitamente um osso humanoide padrão para o nome real de junta no modelo 3D |
| `AutoMapHumanoidBones` | Mapeia automaticamente todas as juntas suportadas identificando padrões comuns (Mixamo, VRM, Blender, CMU, Biped) |
| `FindHumanoidBone(AHumanoidBone: TAIHumanoidBone; out AJointIndex: Integer): Boolean` | Localiza o índice da junta correspondente no rig de forma segura sem access violation |
| `HasHumanoidBone(AHumanoidBone: TAIHumanoidBone): Boolean` | Retorna `True` se o osso especificado existir no rig atual |
| `ValidateHumanoidRig(out AMissingBones: TStrings): Boolean` | Valida se os ossos fundamentais (cabeça, coluna, braços e pernas) estão presentes |

## Cinemática e Rotações

| Método | Descrição |
|---|---|
| `SetBoneRotation(const ABoneName: string; const AX, AY, AZ: Double)` | Aplica rotação em graus para o osso especificado |
| `RotateBone(const ABoneName: string; const Angle: Double)` | Rotaciona um osso em torno de seu eixo local |
| `UpdateFK` | Propaga recursivamente as transformações hierárquicas da raiz até as extremidades |
| `GetJointCount: Integer` | Retorna o total de juntas no esqueleto |
