# TAIAvatar3D - Guia Principal do Avatar 3D
*Componente de Alto Nível para Avatares Inteligentes da Suíte CHATGPT*

## Finalidade

`TAIAvatar3D` é o componente mestre de alto nível responsável por orquestrar todos os subsistemas do avatar 3D:
- **Carregamento e Geometria:** `TAIModel3D` (`.glb`, `.gltf`).
- **Esqueleto Humanoide:** `TAISkeletonRig` e deformação por skinning.
- **Cinemática e Movimentos:** `TAIAvatarController`.
- **Biblioteca de Poses:** `TAIPoseLibrary`.
- **Reprodução de Animações:** `TAIAnimationSequence`.
- **Sincronização Labial (Lip-Sync):** `TAIAvatarLipSync` (amplitude do áudio e controle de mandíbula).
- **Regras Comportamentais:** `TAIAvatarBehavior` (cooldown contra spam de gestos e prioridades).
- **Integração de Voz e IA:** `TAIVoiceSynthesizer` e processamento de resposta estruturada `TAIAvatarResponse`.

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
Em Validação nos Samples / Pronto
```

## Propriedades Principais

| Propriedade | Tipo | Descrição |
|---|---|---|
| `ModelFile` | `string` | Caminho do arquivo `.glb` ou `.gltf` |
| `Active` | `Boolean` | Ativa ou pausa a atualização de frames do avatar |
| `State` | `TAIAvatarState` | Estado operacional atual (`avIdle`, `avListening`, `avThinking`, `avSpeaking`, `avActing`, `avSuccess`, `avError`) |
| `Emotion` | `TAIAvatarEmotion` | Emoção facial/postural (`aeNeutral`, `aeHappy`, `aeSad`, `aeConcerned`, `aeSurprised`, `aeThinking`, `aeConfused`, `aeConfident`, `aeExcited`) |
| `Gesture` | `TAIAvatarGesture` | Gesto ativo (`agNone`, `agWave`, `agNod`, `agShakeHead`, `agExplain`, `agPoint`, `agThink`, etc.) |
| `Quality` | `TAIAvatarQuality` | Qualidade gráfica (`aqLow`, `aqMedium`, `aqHigh`, `aqAuto`) |
| `ShowDebugPanel` | `Boolean` | Ativa informações de telemetria interna (FPS, juntas, estado, lipsync) |
| `FPS` | `Single` | Medição em tempo real da taxa de quadros por segundo |
| `BoneCount` | `Integer` | Total de ossos mapeados no esqueleto atual |
| `VoiceSynthesizer` | `TAIVoiceSynthesizer` | Referência opcional para sincronização labial automática com síntese de voz |

## Métodos Principais

| Método | Descrição |
|---|---|
| `LoadAvatar(const AFileName: string)` | Carrega modelo `.glb`, inicializa esqueleto, auto-mapeia juntas e prepara animações |
| `UnloadAvatar` | Libera com segurança texturas, vértices e estados de memória |
| `SetState(AState: TAIAvatarState)` | Altera o estado e dispara eventos correspondentes |
| `SetEmotion(AEmotion: TAIAvatarEmotion; AIntensity: Single)` | Ajusta a postura e expressão facial com intensidade configurável (`0.0` a `1.0`) |
| `PlayGesture(AGesture: TAIAvatarGesture; ADuration: Single)` | Executa animação dedicada ou fallback procedural |
| `CancelGesture` | Cancela gesto em andamento retornando suavemente à pose base |
| `LookAt(ATarget: TAIAvatarLookTarget)` | Direciona o olhar do avatar para o usuário, centro, esquerda, direita, cima ou baixo |
| `ApplyAgentResponse(const AResponse: TAIAvatarResponse)` | Aplica de uma vez texto falado, emoção, gesto, intensidade e alvo de olhar da IA |
| `ApplyAgentResponse(const AJSONText: string)` | Parser inteligente de resposta JSON com fallbacks seguros |
| `GetDebugInfoText: string` | Retorna resumo formatado do estado interno para depuração |
| `Update(DeltaTimeSec: Single)` | Atualiza ciclo de física, animações, lip-sync e skinning por frame |

## Exemplo de Uso Rápido

```pascal
// Carregamento simples
Avatar3D.LoadAvatar('meu_avatar.glb');

// Ativa fala e aceno simultâneos
Avatar3D.SetEmotion(aeHappy, 0.9);
Avatar3D.PlayGesture(agWave);
Avatar3D.SetState(avSpeaking);

// Processando retorno JSON do agente de IA
Avatar3D.ApplyAgentResponse('{"text":"Olá! Como posso ajudar você hoje?","emotion":"happy","gesture":"wave","intensity":0.8}');
```
