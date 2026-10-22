# Pendências — identificação de locutor por assinatura vocal

Estado em 22/10/2026: **experimental**. O componente `pacote/AI Input/AIAudio/aispeakersignature.pas` implementa somente a política de aceitação de embeddings fornecidos externamente; não extrai características de gravações reais.

## Implementação
- [ ] Selecionar e integrar um extrator real de embeddings de locutor, com modelo e licenças documentados.
- [ ] Capturar e segmentar áudio PCM/WAV com controle de qualidade, VAD e tratamento de ruído.
- [ ] Expor API reutilizável no pacote de áudio para iniciar sessão, comparar fala e encerrar sessão.
- [ ] Manter primeira assinatura válida como referência; não atualizar referência com falas inconclusivas.
- [ ] Aceitar comparação inconclusiva; rejeitar apenas locutor diferente com confiança suficiente.
- [ ] Implementar encerramento por comando e tempo de inatividade configurável.
- [ ] Integrar mesma lógica e mesmo modelo no Android e no Lazarus, verificando equivalência dos resultados.

## Programa de validação
- [ ] Criar programa de teste capaz de carregar WAV de referência e WAV de comparação.
- [ ] Obter amostras reais de múltiplos locutores com licença de reutilização e origem documentadas; não usar gravações sem autorização.
- [ ] Incluir amostras da mesma pessoa com frases diferentes e de pessoas diferentes com frases iguais.
- [ ] Testar áudio curto, silêncio, ruído, microfones diferentes e assinaturas inválidas.
- [ ] Exibir pontuação de similaridade, limiares, decisão (igual/diferente/inconclusivo) e aceite/rejeição.
- [ ] Medir falsa aceitação, falsa rejeição e proporção de inconclusivos; calibrar limiares em dados separados do teste.
- [ ] Automatizar testes e registrar resultados reproduzíveis.

## Qualidade e integração
- [ ] Compilar o componente e executar `tests/test_speaker_signature.lpr` em Free Pascal.
- [ ] Testar Windows/Linux e a biblioteca ou porta Android.
- [ ] Integrar com o Assistente Android remoto e o aplicativo Lazarus.
- [ ] Documentar privacidade, armazenamento temporário e descarte das assinaturas vocais.
- [ ] Só declarar pronto após testes de integração e validação com áudio real.

Referências: PR #19 e `pacote/samples/AI Audio/speaker_signature_demo/README.md`.
