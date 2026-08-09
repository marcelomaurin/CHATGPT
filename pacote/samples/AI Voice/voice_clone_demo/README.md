# voice_clone_demo

Configure `F5_PYTHON`, `F5_TTS_PATH` e opcionalmente `F5_TTS_MODEL`.
Selecione uma referencia WAV, informe o titular, confirme o consentimento,
digite o texto e clique **Gerar**. O sample somente habilita a reproducao
depois de `TAIVoiceClone` confirmar um WAV existente e nao vazio. O processo e
sincrono; use um engine assincrono em aplicacoes que nao possam bloquear a UI.

Use apenas vozes para as quais exista autorizacao explicita. O componente usa
`RequireConsent=True` por padrao e bloqueia a operacao sem essa confirmacao.
