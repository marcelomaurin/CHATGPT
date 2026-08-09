# voice_assistant_demo

Fluxo integrado sem duplicar clientes ou capturadores:

`TAIAudioInput -> TAISpeechRecognizer -> TCHATGPT -> TAIVoiceClone -> WAV/player`

Configure `WHISPER_CLI`, `WHISPER_MODEL`, `AI_LLM_URL`, `AI_LLM_MODEL`,
`OPENAI_API_KEY` (quando exigida), `F5_PYTHON`, `F5_TTS_PATH`,
`F5_TTS_MODEL` e `VOICE_REFERENCE`. Para OpenAI direto, deixe `AI_LLM_URL`
vazio e informe `OPENAI_API_KEY`. Confirme o consentimento e identifique o
titular antes de gerar voz.

Troubleshooting: confirme que os executaveis/modelos existem; teste o WAV de
entrada no `speech_file_demo`; verifique o endpoint/modelo LLM; leia stderr do
F5-TTS; e confirme que a pasta `output` pode ser criada. **Cancelar** encaminha
cancelamento a STT, LLM e sintese. O sample nunca anuncia audio antes de o WAV
existir e ser validado.
