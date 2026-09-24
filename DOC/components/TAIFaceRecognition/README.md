# TAIFaceRecognition

## Visão Geral

`TAIFaceRecognition` é o componente de alto nível da suíte **Lazarus AI Suite** responsável por transformar a detecção de rostos em **reconhecimento e verificação de identidade**.

Ele atua como uma fachada integrada que orquestra componentes existentes sem duplicá-los:
- **`TYOLO`**: Detecta a face e extrai os keypoints/landmarks geométricos.
- **`TFaceDetection`**: Fallback para localização rápida de face via Haar Cascade (OpenCV).
- **`TAIFaceTracker`**: Acompanha a região da face em quadros subsequentes por template matching nativo, reduzindo inferências pesadas de IA.
- **`TAIFaceRegistry`**: Gerencia a base de identidades registradas (`TAIFaceProfile`).
- **`TAIFaceDescriptorBuilder`**: Normaliza escala e rotação e constrói o vetor descritor geométrico.
- **`TAIFaceMatcher`**: Executa a comparação de similaridade de cosseno, validação de threshold e detecção de ambiguidade.

---

## Papel dos Componentes de Visão

É fundamental compreender as responsabilidades de cada componente na biblioteca:

| Componente | Papel | O que faz |
|---|---|---|
| `TFaceDetection` | **Detector** | *Encontra* a presença e bounding box de faces (OpenCV Haar Cascade). Não identifica a pessoa. |
| `TAIFaceTracker` | **Tracker** | *Acompanha* a região da face de frame em frame por correlação nativa (SAD). Não identifica a pessoa. |
| `TYOLO` | **Extrator** | Localiza a face e extrai pontos de referência (olhos, nariz, boca). |
| `TAIFaceRecognition` | **Identificador** | *Identifica* quem é a pessoa através da comparação do descritor com a base de perfis cadastrados. |

---

## Limitações da Primeira Versão (Importante)

> [!WARNING]
> O reconhecimento nesta primeira versão baseia-se na **geometria de landmarks faciais normalizados** (distâncias interoculares, proporção nariz-boca, inclinação e coordenadas relativas ao bounding box), extraídos por modelos YOLO faciais com keypoints.
> **Esta abordagem não equivale a modelos de embeddings profundos (ArcFace / FaceNet)** e destina-se a ambientes controlados e bases com poucos perfis cadastrados.
> A arquitetura inclui a interface `IAIFaceDescriptorProvider`, permitindo plugar ArcFace/FaceNet no futuro sem quebrar o Registry ou o Matcher.

---

## Configuração de Calibração e Threshold

O threshold de matching **não é fixo em 0.80**:

- **`MatchThreshold: Double`** (Padrão: `0.82`): Define o valor mínimo de similaridade de cosseno para classificar uma detecção como `fmsMatched`. Valores inferiores a esse limiar retornam `fmsUnknown`. Recomenda-se calibrar entre `0.78` e `0.88` de acordo com a iluminação e resolução da câmera.
- **`AmbiguityMargin: Double`** (Padrão: `0.05`): Se os dois melhores perfis tiverem similaridades superiores ao threshold e a diferença entre eles for menor que a margem, o sistema retorna `fmsAmbiguous`, prevenindo falsos reconhecimentos entre indivíduos parecidos.

---

## Estados e Eventos

O componente gerencia estados distintos:
- `detected`: Há uma face presente no frame.
- `tracked`: A região está sendo acompanhada pelo tracker.
- `recognized`: Houve correspondência confiável com um perfil cadastrado.

### Eventos:
- `OnFaceDetected(Sender: TObject; const AFaceRect: TRect; Confidence: Double)`
- `OnFaceRecognized(Sender: TObject; const AResult: TFaceMatchResult)`
- `OnFaceUnknown(Sender: TObject; const AResult: TFaceMatchResult)`
- `OnFaceAmbiguous(Sender: TObject; const AResult: TFaceMatchResult)`
- `OnFaceLost(Sender: TObject)`

---

## Diretrizes de Segurança da Biblioteca
1. **Não registra imagens desconhecidas automaticamente**: rostos desconhecidos (`fmsUnknown`) nunca são persistidos sozinhos.
2. **Não executa regras de negócio nem gatilhos**: o campo `Triggers` no `TAIFaceProfile` armazena apenas dados; a aplicação consumidora (como o `Assistente`) é quem decide como acioná-los.
