# Kinect Perception Demo (SDK 1.8 + Camada Semântica)

Este sample demonstra a camada semântica `TAIKinectPerception` sobre o hardware Kinect v1 (Xbox 360 / Windows v1), transformando o fluxo físico de esqueletos e profundidade em eventos semânticos de alto nível para o `TAIConversationOrchestrator` e para o **Professor Virtual**.

## O que a demonstração faz

1. **Abstração Semântica Sem Custo de LLM**: A taxa de 30 FPS do Kinect é processada localmente em Pascal, enviando apenas transições semânticas e payloads compactos em JSON (`person_entered`, `gesture_detected`, `person_left`, etc.).
2. **Classificação Temporal de Gestos**:
   - `kgRaiseRightHand` e `kgRaiseLeftHand` (pergunta/interação do aluno)
   - `kgRaiseBothHands`
   - `kgPointLeft`, `kgPointRight`, `kgPointCenter` (apontamento de slides/objetos)
   - `kgWave` (saudação ao entrar)
   - `kgOpenArms` (abraço / receptividade)
3. **Simulador Embutido**: Permite testar todos os 8 cenários sem precisar de hardware físico conectado.
4. **Inspeção de Payload JSON**: Exibe em tempo real o exato JSON consumido pela IA.

## Compilação

Abra `kinect_perception_demo.lpi` no Lazarus ou compile via linha de comando:

```bash
lazbuild "P:\maurinsoft\CHATGPT\pacote\samples\AI Input\kinect_perception_demo\kinect_perception_demo.lpi"
```
