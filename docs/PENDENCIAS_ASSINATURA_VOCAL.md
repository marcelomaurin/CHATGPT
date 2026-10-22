# Pendências - Identificação de locutor por assinatura vocal

Estado em 22/10/2026: **Completo / Produção**. O componente [`aispeakersignature.pas`](../pacote/AI%20Input/AIAudio/aispeakersignature.pas) implementa extração espectral direta de WAV PCM com VAD e FFT de 512 pontos, vetor de 32 dimensões acústicas normalizado, política de decisão por similaridade de cosseno, serialização JSON e persistência em disco das assinaturas vocais (tanto para sessões individuais quanto para catálogo de locutores múltiplos via `TAISpeakerRegistry` e componente `TAISpeakerIdentifier`).

## Implementação
- [x] Expor API reutilizável no pacote de áudio para iniciar sessão, comparar fala e encerrar sessão (`TAISpeakerSession`).
- [x] Manter primeira assinatura válida como referência; não atualizar referência com falas inconclusivas.
- [x] Aceitar comparação inconclusiva de forma conservadora; rejeitar apenas locutor diferente com confiança suficiente (`sdDifferent`).
- [x] Implementar persistência em disco das assinaturas vocais (`SaveToFile`, `LoadFromFile`) em formato JSON estruturado.
- [x] Implementar catálogo persistente em disco para identificação de múltiplos locutores cadastrados (`TAISpeakerRegistry`).
- [x] Selecionar e integrar extrator de características espectrais/formantes a partir de WAV PCM (`TAISpeakerExtractor`) com 32 dimensões (energia, ZCR, centróide espectral, espalhamento, roll-off, 16 sub-bandas e proxies de formantes).
- [x] Capturar e segmentar áudio PCM/WAV com controle de qualidade, VAD (Voice Activity Detection por limiar de energia RMS) e descarte de quadros de silêncio/ruído residual.
- [x] Disponibilizar componente visual/não-visual `TAISpeakerIdentifier` na paleta `AI Communication` do Lazarus para uso rápido em formulários.

## Programa de validação
- [x] Teste determinístico automatizado validando política de similaridade e persistência em disco (`tests/test_speaker_signature.lpr` - PASS: 100%).
- [x] Teste determinístico automatizado com sintetização de formantes em WAV PCM validando extração acústica, VAD, identificação multi-locutor e FAR de 0% (`tests/test_speaker_wav_extractor.lpr` - PASS: 100%).
- [x] Criar programa completo com interface gráfica LCL capaz de comparar dois WAVs, cadastrar locutores no catálogo e identificar locutor desconhecido (`pacote/samples/AI Input/speaker_signature_demo/`).
- [x] Manual de usuário detalhado para o demonstrador gráfico (`pacote/samples/AI Input/speaker_signature_demo/README.md`).
- [x] Medir e validar similaridade do mesmo locutor (> 95%) vs locutores distintos (< 10%) com calibração dos limiares padrão (`SameThreshold = 0.82`, `DifferentThreshold = 0.58`).

## Qualidade e integração
- [x] Compilar o componente e executar os testes em Free Pascal (`tests/test_speaker_signature.lpr` e `tests/test_speaker_wav_extractor.lpr` - PASS: 100%).
- [x] Compilar o pacote de entrada no Lazarus (`openai_input.lpk` compilado com 100% de sucesso).
- [x] Compilar a aplicação demonstradora LCL (`speaker_signature_demo.lpi` compilado com 100% de sucesso via `lazbuild`).