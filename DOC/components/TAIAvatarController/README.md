# TAIAvatarController

## Finalidade

`TAIAvatarController` é o controlador de movimento, estados e animações do avatar 3D. Ele conecta o esqueleto (`TAISkeletonRig`), a biblioteca de poses (`TAIPoseLibrary`) e o player de animações (`TAIAnimationSequence`), fornecendo fallbacks procedurais completos caso o modelo não disponha de animações prontas.

## Unit

```pascal
pacote/AI Graphic/aiavatarcontroller.pas
```

## Pacote

```text
openai_graphic.lpk
```

## Status

```text
Em Validação nos Samples / Pronto
```

## Principais Recursos

1. **Controle de Estados (`SetState`):**
   - `avIdle`, `avListening`, `avThinking`, `avSpeaking`, `avActing`, `avSuccess`, `avError`.
2. **Expressão Emocional (`SetEmotion`):**
   - `aeNeutral`, `aeHappy`, `aeSad`, `aeConcerned`, `aeSurprised`, `aeThinking`, `aeConfused`, `aeConfident`, `aeExcited`.
   - Aplica poses e blend shapes com controle de intensidade (`0.0` a `1.0`).
3. **Gestos e Fallbacks Procedurais (`PlayGesture`):**
   - Caso o modelo não tenha animações pré-gravadas no `.glb`, o controlador sintetiza movimentos matemáticos procedurais dos ossos em tempo real:
     - `agWave`: eleva o braço, dobra o cotovelo e oscila o punho suavemente.
     - `agNod`: inclina a cabeça verticalmente em confirmação.
     - `agShakeHead`: rotaciona a cabeça horizontalmente em negação.
     - `agExplain`: abre os braços e gesticula com as mãos.
     - `agThink`: inclina a cabeça e eleva a mão em direção ao queixo.
4. **Respiração Auto-Idle:**
   - Movimentação sinusoidal contínua e sutil do peitoral (`hbChest` / `hbSpine`) para evitar aspecto congelado/robótico.
5. **Auto-Blink e Olhar (`LookAt`):**
   - Piscar de olhos em intervalos variáveis aleatórios e controle angular seguro de rotação da cabeça e olhos (`LookAt`).
