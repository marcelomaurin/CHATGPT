# TAIFaceRecognition

## Visão Geral

`TAIFaceRecognition` é o componente de alto nível da suíte **Lazarus AI Suite** responsável por transformar a detecção de rostos em **reconhecimento e verificação de identidade** robustos.

Ele atua como uma fachada integrada que orquestra componentes especializados sem duplicar responsabilidades:

```text
YOLO detecta
FaceTracker acompanha
Descriptor representa
Matcher compara
Registry armazena
TAIFaceRecognition coordena
```

### Papel dos Componentes de Visão

| Componente | Papel | O que faz |
|---|---|---|
| `TYOLO` | **Detector / Extrator** | Detecta a presença da face e extrai os keypoints/landmarks geométricos (olhos, nariz, boca). |
| `TAIFaceTracker` | **Tracker** | Acompanha a região visual da face em quadros subsequentes por correlação visual nativa (SAD), reduzindo inferências YOLO. **Não gera identidade.** |
| `TAIFaceDescriptorBuilder` | **Descriptor** | Valida a qualidade dos landmarks, normaliza escala e rotação e constrói o vetor geométrico invariante. |
| `TAIFaceMatcher` | **Matcher** | Compara vetores por similaridade de cosseno, avalia thresholds e detecta ambiguidade entre múltiplos candidatos. |
| `TAIFaceRegistry` | **Registry** | Armazena e serializa a base de identidades conhecidas (`TAIFaceProfile`) em arquivos JSON (`format_version: 1`). |
| `TAIFaceRecognition` | **Coordenador** | Orquestra a captura, validação de classe facial, tracking temporal, múltiplas confirmações e cooldown de eventos. |

---

## Regra Fundamental de Classes Faciais: `person != face`

> [!IMPORTANT]
> Em modelos YOLO gerais (como COCO), a classe `person` representa o **corpo inteiro** de um indivíduo e não possui keypoints faciais adequados para reconhecimento.
> Portanto:
> - `person` **NÃO** é aceito como face.
> - O cadastro e o reconhecimento filtram estritamente classes faciais (`FaceClassName = 'face'`, aliases em `FaceClasses: TStrings`).
> - Objetos não faciais (como cadeiras, animais ou corpos inteiros) são descartados sem gerar erro técnico.
> - Se uma cena contiver apenas um cachorro ou objeto, o retorno é `Result = True`, `Length(AResults) = 0` e mensagem informativa `"Nenhuma face encontrada"`.

---

## Validação Semântica de Landmarks e Qualidade

O descritor facial exige landmarks válidos com confiança mínima:
- **`MinKeyPointConfidence`** (Padrão: `0.35`): Landmarks de olhos, nariz ou boca com confiança individual abaixo deste limite causam rejeição da amostra.
- **Validação Semântica**: Verifica se os índices configurados em `TYoloKeyPointMapping` (olho esquerdo/direito, nariz, boca esquerda/direita) existem no modelo. Landmarks ausentes **não são substituídos por geometria estimada** no pipeline de identidade.
- **Limiares de Qualidade Separados**:
  - `EnrollmentQualityThreshold` (Padrão: `0.70`): Cadastro mais rigoroso para assegurar que fotos de baixa qualidade não entrem na base.
  - `RecognitionQualityThreshold` (Padrão: `0.50`): Limiar de operação em runtime para acomodar variações de iluminação e movimento da câmera.

---

## Estabilidade Temporal, Rastreamento e Cooldown

Para evitar falsos disparos causados por um único frame ruidoso, o componente adota confirmação temporal:

- **`RequiredConfirmations`** (Padrão: `3`): O evento `OnFaceRecognized` é disparado somente após a mesma identidade ser detectada consecutivamente na janela de confirmação (`ConfirmationWindowMs`, padrão `2000 ms`).
- **Reset por Mudança de Identidade**: Se a identidade oscilar entre frames (ex: Marcelo -> Maria -> Marcelo), a contagem de confirmação é reiniciada.
- **`RecognitionCooldownMs`** (Padrão: `30000 ms`): Uma vez reconhecida uma pessoa, o evento não é redisparado a cada frame enquanto o mesmo rosto continuar em cena.
- **`FaceLostTimeoutMs`** (Padrão: `2000 ms`): Se o rosto sumir momentaneamente por falha de iluminação ou oclusão rápida, o estado só passa para `frsLost` (disparando `OnFaceLost`) após o timeout.
- **`ProcessFrame(ABitmap, out AResults)`**: Método otimizado para vídeo contínuo. Alterna automaticamente entre `TAIFaceTracker` e reinferência periódica via `TYOLO` (`YoloRefreshIntervalMs = 1500 ms`).

---

## Ambiguidade e Diagnóstico de Candidatos

O registro de resultado `TFaceMatchResult` preserva o melhor e o segundo melhor candidato:
- `ProfileID`, `ProfileName`, `Score` (Melhor correspondência)
- `SecondProfileID`, `SecondProfileName`, `SecondScore` (Segundo melhor candidato)
- Se ambos superarem o threshold e a diferença for menor que `AmbiguityMargin`, o status retornado é `fmsAmbiguous`, permitindo calibração visual em ferramentas de demonstração.

---

## Diretrizes de Arquitetura e Segurança
1. **Não registra imagens desconhecidas automaticamente**: rostos desconhecidos (`fmsUnknown`) nunca são persistidos sozinhos.
2. **Não executa regras de negócio nem gatilhos**: o campo `Triggers` no `TAIFaceProfile` armazena apenas dados; a aplicação consumidora (como o `Assistente`) é quem decide como acioná-los.
3. **Limites de Perfis**: O limite de perfis (ex: 10 pessoas) pertence à camada de aplicação (`Assistente`), mantendo a biblioteca flexível.
