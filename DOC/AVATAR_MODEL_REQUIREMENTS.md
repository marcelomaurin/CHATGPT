# Requisitos de Modelagem e Especificação de Avatares 3D (glTF 2.0 / GLB)
*Documento Técnico do Subsistema 3D da Suíte CHATGPT (Tarefas 110 e 111)*

Este documento especifica os requisitos formais de topologia, esqueleto humanoide (rigging), materiais PBR e nomenclatura de animações para compatibilidade total com os componentes `TAIModel3D`, `TAISkeletonRig`, `TAIAvatarController` e `TAIAvatar3D`.

---

## 1. Formato de Arquivo Recomendado
- **Formato Primário:** Arquivo binário **glTF 2.0 (`.glb`)**.
- **Formato Secundário:** **glTF separado (`.gltf` + `.bin` + texturas)**.
- **Estrutura interna:** Vértices, normais, coordenadas UV, pesos de juntas (`JOINTS_0`, `WEIGHTS_0`) e texturas empacotadas em um único arquivo binário `.glb` para simplificar a distribuição.

---

## 2. Esqueleto Humanoide Padronizado (`TAIHumanoidBone`)

Para permitir retargeting, animações procedurais e sincronização labial (lip-sync), o modelo deve conter os seguintes ossos essenciais (com seus nomes comuns suportados pelo auto-mapper):

| Identificador Canônico | Função / Região | Aliases Suportados no glTF / Mixamo / VRM |
|---|---|---|
| `hbHips` | Raiz da pelve / centro de massa | `Hips`, `Pelvis`, `mixamorig:Hips`, `J_Bip_C_Hips`, `root` |
| `hbSpine` | Coluna lombar / torácica | `Spine`, `Spine1`, `mixamorig:Spine`, `J_Bip_C_Spine` |
| `hbChest` | Caixa torácica / peitoral | `Chest`, `Spine2`, `mixamorig:Spine1`, `mixamorig:Spine2` |
| `hbNeck` | Pescoço | `Neck`, `mixamorig:Neck`, `J_Bip_C_Neck` |
| `hbHead` | Cabeça (orientação e olhar) | `Head`, `mixamorig:Head`, `J_Bip_C_Head` |
| `hbJaw` | Mandíbula (Lip-Sync amplitude) | `Jaw`, `Mouth`, `mixamorig:Jaw`, `J_Bip_C_Jaw` |
| `hbLeftEye` | Olho Esquerdo (Look-At) | `LeftEye`, `Eye_L`, `Eye.L`, `mixamorig:LeftEye` |
| `hbRightEye` | Olho Direito (Look-At) | `RightEye`, `Eye_R`, `Eye.R`, `mixamorig:RightEye` |
| `hbLeftShoulder` | Ombro Esquerdo | `LeftShoulder`, `Shoulder.L`, `mixamorig:LeftShoulder` |
| `hbLeftUpperArm` | Braço Superior Esquerdo | `LeftArm`, `LeftUpperArm`, `Arm.L`, `mixamorig:LeftArm` |
| `hbLeftLowerArm` | Antebraço Esquerdo | `LeftForeArm`, `ForeArm.L`, `mixamorig:LeftForeArm` |
| `hbLeftHand` | Mão Esquerda | `LeftHand`, `Hand.L`, `mixamorig:LeftHand` |
| `hbRightShoulder` | Ombro Direito | `RightShoulder`, `Shoulder.R`, `mixamorig:RightShoulder` |
| `hbRightUpperArm` | Braço Superior Direito | `RightArm`, `RightUpperArm`, `Arm.R`, `mixamorig:RightArm` |
| `hbRightLowerArm` | Antebraço Direito | `RightForeArm`, `ForeArm.R`, `mixamorig:RightForeArm` |
| `hbRightHand` | Mão Direita | `RightHand`, `Hand.R`, `mixamorig:RightHand` |
| `hbLeftUpperLeg` | Coxa Esquerda | `LeftUpLeg`, `UpLeg.L`, `mixamorig:LeftUpLeg` |
| `hbLeftLowerLeg` | Perna Esquerda | `LeftLeg`, `Leg.L`, `mixamorig:LeftLeg` |
| `hbLeftFoot` | Pé Esquerdo | `LeftFoot`, `Foot.L`, `mixamorig:LeftFoot` |
| `hbRightUpperLeg` | Coxa Direita | `RightUpLeg`, `UpLeg.R`, `mixamorig:RightUpLeg` |
| `hbRightLowerLeg` | Perna Direita | `RightLeg`, `Leg.R`, `mixamorig:RightLeg` |
| `hbRightFoot` | Pé Direito | `RightFoot`, `Foot.R`, `mixamorig:RightFoot` |

### Fallbacks em Caso de Ausência de Ossos:
1. **Sem Mandíbula (`hbJaw`):** O `TAIAvatarLipSync` desativa suavemente o lip-sync físico sem gerar erro.
2. **Sem Olhos (`hbLeftEye`, `hbRightEye`):** O comando `LookAt` direciona a rotação suave da cabeça (`hbHead`).
3. **Rig Parcial:** `TAISkeletonRig.ValidateHumanoidRig` emite advertências e ativa movimentações procedurais parciais.

---

## 3. Nomes Padrão de Animação e Aliases (Tarefa 111)

Ao exportar clipes de animação embutidos no `.glb`, utilize a convenção abaixo para que o `TAIAnimationSequence` e o `TAIAvatarController` os executem sem necessidade de configuração manual:

| Ação Canônica | Nomes e Aliases Reconhecidos Automaticamente | Descrição / Uso |
|---|---|---|
| **`Idle`** | `Idle`, `Idle_01`, `Stand`, `Espera`, `Breathing` | Respiração padrão, loop infinito |
| **`Wave`** | `Wave`, `Wave_Hand`, `Hello`, `Aceno`, `Cumprimento` | Aceno de mão ao iniciar interação |
| **`Nod`** | `Nod`, `Agree`, `Sim`, `Concorda` | Movimento de cabeça afirmando |
| **`ShakeHead`**| `ShakeHead`, `Disagree`, `Nao`, `Recusa` | Movimento de cabeça negando |
| **`Explain`** | `Explain`, `Talking`, `Talk_01`, `Gesticulate` | Gestos de explicação durante a fala |
| **`Think`** | `Think`, `Thinking`, `Pensa`, `Duvida` | Postura pensativa ao aguardar IA |
| **`Shrug`** | `Shrug`, `Ombros`, `DontKnow` | Dar de ombros (dúvida ou incerteza) |
| **`Celebrate`**| `Celebrate`, `Cheer`, `Happy_Win`, `Vitoria` | Comemoração e feedback de sucesso |

---

## 4. Configuração por Modelo (`avatar_profile.json`)

Para modelos com nomenclatura customizada ou necessidades especiais de mapeamento, utilize um arquivo de perfil JSON adjacente ao modelo:

```json
{
  "name": "AvatarPro",
  "model": "meu_personagem.glb",
  "description": "Avatar humanoide corporativo com blendshapes e rig completo",
  "quality": "high",
  "bones": {
    "hbHead": "Bone_Head",
    "hbJaw": "Bone_MouthLower",
    "hbSpine": "Bone_Spine01",
    "hbChest": "Bone_Chest02"
  },
  "animations": {
    "idle": "anim_idle_standing",
    "wave": "anim_friendly_wave",
    "nod": "anim_affirmation_nod"
  }
}
```
