# Pendências — Identificação de locutor por assinatura vocal

Estado em 22/10/2026: **Beta**. O componente [`aispeakersignature.pas`](../pacote/AI%20Input/AIAudio/aispeakersignature.pas) implementa a política de decisão por similaridade de cosseno, serialização JSON e persistência em disco das assinaturas vocais (tanto para sessões individuais quanto para catálogo de locutores múltiplos via `TAISpeakerRegistry`).

## Implementação
- [x] Expor API reutilizável no pacote de áudio para iniciar sessão, comparar fala e encerrar sessão (`TAISpeakerSession`).
- [x] Manter primeira assinatura válida como referência; não atualizar referência com falas inconclusivas.
- [x] Aceitar comparação inconclusiva de forma conservadora; rejeitar apenas locutor diferente com confiança suficiente (`sdDifferent`).
- [x] Implementar persistência em disco das assinaturas vocais (`SaveToFile`, `LoadFromFile`) em formato JSON estruturado.
- [x] Implementar catálogo persistente em disco para identificação de múltiplos locutores cadastrados (`TAISpeakerRegistry`).
- [ ] Selecionar e integrar um extrator de embeddings de locutor a partir de WAV PCM/microfone (ex: Sherpa-ONNX / ECAPA-TDNN).
- [ ] Capturar e segmentar áudio PCM/WAV com controle de qualidade, VAD e tratamento de ruído.
- [ ] Integrar mesma lógica e mesmo modelo no Android e no Lazarus, verificando equivalência dos resultados.

## Programa de validação
- [x] Teste determinístico automatizado validando política de similaridade e persistência em disco (`tests/test_speaker_signature.lpr`).
- [ ] Criar programa com interface gráfica (LCL) capaz de carregar WAV de referência e WAV de comparação.
- [ ] Obter amostras reais de múltiplos locutores com licença de reutilização e origem documentadas (ex: Common Voice).
- [ ] Medir falsa aceitação (FAR), falsa rejeição (FRR) e proporção de inconclusivos; calibrar limiares.

## Qualidade e integração
- [x] Compilar o componente e executar `tests/test_speaker_signature.lpr` em Free Pascal (PASS: 100%).
- [x] Compilar o pacote de entrada no Lazarus (`openai_input.lpk`).
- [ ] Integrar com o Assistente Android remoto e o aplicativo Lazarus.