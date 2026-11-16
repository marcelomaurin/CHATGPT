# NeuroGraph v8 Native — 100% Free Pascal / Lazarus (Zero Python)

Este projeto implementa o **treinamento completo, camadas ocultas não-lineares (Deep MLP com ativação SiLU), persistência binária (`.ngs`), aferição de benchmarks e chat interativo** do **NeuroGraph** inteiramente em **Free Pascal / Lazarus nativo (`x86_64` / `ARM64`)**, sem qualquer dependência de Python, NumPy, SciPy ou DLLs externas.

---

## 1. Arquitetura Híbrida (Wide & Deep Residual TokenGraph v8)

A equação central em [`src/NeuroGraphEngine.pas`](../src/NeuroGraphEngine.pas) combina dois ramos treinados conjuntamente via **Backpropagation + AdamW** na CPU:

$$\text{Logits}(y_t \mid x) = \underbrace{x \cdot W_{\text{sparse}}}_{\text{Ramo Wide (Grafo Direto)}} + \underbrace{\text{SiLU}\!\left(\text{SiLU}(x_{\text{base}} \cdot W_1 + b_1) \cdot W_2 + b_2\right) \cdot W_{\text{out}}}_{\text{Ramo Deep (Camadas Ocultas Não-Lineares)}}$$

1. **Ramo Wide (Memória Associativa Direta):**
   - Preserva arestas esparsas direcionadas (`Feature -> Token`) para retenção imediata de fatos específicos, nomes próprios e transições diretas.
2. **Ramo Deep (Camadas Ocultas Não-Lineares $H_1 \to H_2$ com ativação $\text{SiLU}(u) = \frac{u}{1 + e^{-u}}$):**
   - Projeta as *features* atômicas da pergunta, morfologia (`stem4`, `stem5`), pares de conceitos (`cpair`), atenção de cobertura (`pending`) e histórico de diálogo em um espaço contínuo denso.
   - Resolve problemas **não-lineares inseparáveis** (como o **XOR Contextual / Polissemia**, onde o sentido da resposta se inverte conforme a combinação de dois fatores do contexto).

---

## 2. Estrutura de Arquivos

- [`../src/NeuroGraphEngine.pas`](../src/NeuroGraphEngine.pas): Motor completo em Pascal puro (`TNGDeepEngine`, `TNGSession`, tokenizador UTF-8 português, extrator morfológico, otimizador AdamW + Backpropagation, avaliador F1/EM e serializador `.ngs`).
- [`../src/NeuroGraphCore.pas`](../src/NeuroGraphCore.pas): Grafo esparso direcionado (`TNeuroGraph`) + classe `TNGDeepMLP` para camadas ocultas genéricas em CPU.
- [`neurograph_native.lpi`](neurograph_native.lpi) / [`neurograph_native.lpr`](neurograph_native.lpr) / [`unative.pas`](unative.pas): Aplicação Desktop Lazarus (GUI + CLI) para treinar, conversar e aferir modelos sem Python.
- [`compilar.bat`](compilar.bat): Script de compilação direta via `lazbuild`.

---

## 3. Como Compilar e Executar

### Compilar no Lazarus
```bat
C:\lazarus\lazbuild.exe --build-all NeuroGraph\lazarus_pure\neurograph_native.lpi
```

### Executar a Interface Gráfica (Studio + Player + Benchmark Nativo)
```bat
NeuroGraph\lazarus_pure\neurograph_native.exe
```

### Executar via Linha de Comando (CLI)
```powershell
# Auto-teste completo (Treina na CPU, avalia Holdout 54Q, testa XOR e responde pergunta):
.\NeuroGraph\lazarus_pure\neurograph_native.exe --self-test "--ask=descreva luma e nino" | Out-String
```
