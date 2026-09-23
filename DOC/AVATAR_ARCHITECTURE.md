# Arquitetura do Subsistema de Avatar 3D (CHATGPT AI Suite)

Este documento estabelece a arquitetura, responsabilidades e dependências do subsistema de **Avatar 3D** da suíte de componentes `CHATGPT`.

---

## 1. Visão Geral da Arquitetura

O subsistema é organizado em camadas desacopladas com responsabilidades bem definidas, permitindo desde a manipulação de baixo nível de malhas e ossos até o controle comportamental de alto nível orientado a agentes de IA.

```
┌─────────────────────────────────────────────────────────────┐
│                    CAMADA DE APLICAÇÃO                      │
│                  (Assistente / Lazarus App)                 │
└──────────────────────────────┬──────────────────────────────┘
                               │
┌──────────────────────────────▼──────────────────────────────┐
│                        TAIAvatar3D                          │
│               (Componente Integrador de Alto Nível)          │
│                                                             │
│  • Gerencia ciclo de vida (LoadAvatar / UnloadAvatar)       │
│  • Coordena Controller, Rig, Model, LipSync e Visualização  │
│  • Expõe Estado, Emoção, Gesto e Eventos                    │
└──────┬───────────────────────┬───────────────────────┬──────┘
       │                       │                       │
┌──────▼──────────────┐ ┌──────▼──────────────┐ ┌──────▼──────┐
│ TAIAvatarController │ │  TAIAvatarLipSync   │ │ TAI3DModel  │
│ (Lógica & Movimento)│ │(Sincronia de Voz/   │ │   Viewer    │
│                     │ │      Mandíbula)     │ │ (Render LCL)│
│ • State Machine     │ │                     │ └─────────────┘
│ • Procedural Motion │ │ • Amplitude Audio   │
│ • Auto-Idle / Blink │ │ • Suavização Exp.   │
│ • LookAt / Clamps   │ │ • Detecção Silêncio │
└──────┬──────────────┘ └─────────────────────┘
       │
┌──────▼──────────────┐ ┌─────────────────────┐
│   TAIPoseLibrary    │ │TAIAnimationSequence │
│ (Poses & Blending)  │ │ (Canais, Slerp,     │
│                     │ │       Fila)         │
└──────┬──────────────┘ └──────┬──────────────┘
       │                       │
┌──────▼───────────────────────▼──────────────┐
│                TAISkeletonRig               │
│        (Esqueleto, Hierarquia FK, Bones)    │
│                                             │
│ • TAIHumanoidBone (Mapeamento Padronizado)  │
│ • Transformações Globais & Matrizes Skinning│
└──────────────────────┬──────────────────────┘
                       │
┌──────────────────────▼──────────────────────┐
│                  TAIModel3D                 │
│      (Malha 3D, Vértices, glTF 2.0 / GLB)   │
│                                             │
│ • Accessors, Buffers, Primitives            │
│ • JOINTS_0 & WEIGHTS_0                      │
│ • Materiais PBR & Texturas                  │
└─────────────────────────────────────────────┘
```

---

## 2. Responsabilidades dos Componentes

### 2.1 `TAIAvatar3D` (`aiavatar3d.pas`) — Alto Nível
- **Responsabilidade:** Fachada unificada do avatar. Coordena modelo, esqueleto, controlador, animações e sincronia labial.
- **Não faz:** Não realiza cálculos matemáticos de cinemática nem parseia arquivos brutos diretamente.

### 2.2 `TAIAvatarController` (`aiavatarcontroller.pas`) — Controlador Cognitivo/Motor
- **Responsabilidade:** Máquina de estados (`TAIAvatarState`), aplicação de emoções (`TAIAvatarEmotion`), execução de gestos (`TAIAvatarGesture`), animações procedurais de respiração, auto-blink e direção do olhar (`LookAt`).
- **Não faz:** Não renderiza gráficos na tela (desacoplado de OpenGL/LCL).

### 2.3 `TAISkeletonRig` (`aiskeletonrig.pas`) — Esqueleto e Cinemática
- **Responsabilidade:** Representa a hierarquia de juntas (Forward Kinematics), armazena posições e rotações relativas/globais, calcula matrizes de skinning e mapeia nomes de ossos para o padrão `TAIHumanoidBone`.
- **Não faz:** Não decide quando gesticular ou piscar.

### 2.4 `TAIPoseLibrary` (`aiposelibrary.pas`) — Biblioteca de Poses
- **Responsabilidade:** Armazena poses estáticas pré-definidas (Neutral, Listening, Thinking, etc.) e interpola pesos de rotação com blending (`0.0..1.0`).

### 2.5 `TAIAnimationSequence` (`aianimationsequence.pas`) — Player de Animações
- **Responsabilidade:** Amostragem de curvas de animação glTF (translação, rotação com quaternion/slerp, escala), controle de velocidade, loop e blending entre animações.

### 2.6 `TAIModel3D` (`aimodel3d.pas`) — Carregador de Geometria
- **Responsabilidade:** Leitura e representação em memória de arquivos 3D (STL, glTF 2.0, GLB), incluindo vértices, normais, coordenadas UV, índices, materiais e dados de deformação (joints e weights).

### 2.7 `TAIAvatarLipSync` (`aiavatarlipsync.pas`) — Sincronia Labial
- **Responsabilidade:** Modulação da abertura do osso da mandíbula (`hbJaw`) baseada no sinal de amplitude de áudio da voz sintetizada (`TAIVoiceSynthesizer`), com filtro de suavização e detecção de pausas.

---

## 3. Fluxo de Execução Típico

1. **Carregamento:**
   `TAIAvatar3D.LoadAvatar('personagem.glb')`
   -> `TAIModel3D` carrega geometria, materiais e skins.
   -> `TAISkeletonRig` constrói a árvore de ossos e valida rig humanoide (`ValidateHumanoidRig`).
   -> `TAIAvatarController` ativa `AutoIdle` e `AutoBlink`.

2. **Interação com IA:**
   - Usuário envia pergunta -> Avatar transiciona para `avListening`.
   - Agente processa -> Avatar transiciona para `avThinking` e executa gesto sutil de reflexão.
   - Resposta inicia -> Avatar transiciona para `avSpeaking`, ativa `LipSync`, aplica emoção indicada pela IA e executa gesto explicativo (`agExplain` / `agNod`).
   - Resposta finaliza -> Avatar retorna suavemente para `avIdle`.
