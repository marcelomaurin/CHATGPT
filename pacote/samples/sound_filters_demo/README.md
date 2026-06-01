# Audio Sound Filters Demo (sound_filters_demo)

Este exemplo demonstra o uso dos filtros de processamento de sinais analógicos e multiplexadores de RF incluídos na aba **`IA Filtros Sonoros`** da paleta de componentes do Lazarus, implementados em **Pascal puro** de alta performance.

---

## 🚀 Filtros e Multiplexadores Demonstrados

1. **Filtro Passa-Baixa (LowPass)**: Filtro IIR suavizando frequências de forma simples e responsiva.
2. **Filtro Passa-Alta (HighPass)**: Filtro IIR eliminando baixas frequências.
3. **Média Móvel (Average)**: Filtro digital baseado em janela deslizante para atenuação de flutuações rápidas.
4. **FDM Multiplexing**: Modulação AM-DSB-SC com portadoras deslocadas em frequência.
5. **TDM Multiplexing**: Fatiamento temporal de quadros intercalados.
6. **CDM Multiplexing**: CDMA usando códigos ortogonais Walsh-Hadamard.
7. **OFDM Multiplexing**: Modulação ortogonal profunda baseada em Radix-2 Cooley-Tukey IFFT/FFT e prefixos cíclicos.

---

## 💻 Como Compilar e Executar

1. Abra o arquivo **`sound_filters_demo.lpi`** no Lazarus IDE.
2. No menu principal, clique em **Run > Run** (ou pressione `F9`).
3. Ajuste as frequências de amostragem, configure as portadoras e execute a demodulação interativa em tempo real.
