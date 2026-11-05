# Chrome speech component

`TAIChromeSpeech` provides keyless Chrome Web Speech recognition to native applications. It does not use Google Cloud REST. Call Start, OpenBrowser, and periodically Poll on the UI thread. Subscribe to OnText/OnState; use SetPaused while speaking and Stop at shutdown. Chrome desktop 135+ and an explicit microphone permission are required. BrowserExecutable optionally selects an installed Chrome executable.

The source HTML is embedded in aichromespeech_page.inc. Keep both in sync. The page uses local Web Audio (100..7000 Hz), browser noise suppression, an energy gate, and a configurable silence interval before stopping a phrase. It passes the filtered MediaStreamTrack to SpeechRecognition.start(track). No microphone is opened before the user clicks Start.

TAISpeechFilter in aispeechfilter implements the equivalent band selection for interleaved PCM16 mono/stereo, independent channel state and background threshold estimation. Configure sample rate/channels before Filter. This does not remove speech-band background voices or guarantee recognition accuracy.

TAIVoiceRecognizer appends vreChromeWebSpeech without changing prior enum ordinals. TranscribeFile rejects this mode with an actionable error; use TAIChromeSpeech for live capture. For OpenAI, OpenAIToken takes precedence over ChatGPTToken, then OPENAI_API_KEY. Token properties are not streamed to Lazarus resources.

Tests: tests/test_chrome_speech.lpr, tests/test_openai_stt.lpr; run_openai_stt_checks.py and run_chrome_page_checks.js use local fixtures only. No live Google/OpenAI service or microphone accuracy has been validated by these fixtures.
