# speech_microphone_demo

Reusa `TAIAudioInput` para gravar o microfone em WAV e
`TAISpeechRecognizer` para transcrever. Configure `WHISPER_CLI` e
`WHISPER_MODEL`. O modo continuo divide o WAV ao parar, processa a fila e
mostra parcial/final separadamente. No Linux, `arecord` deve estar instalado.
