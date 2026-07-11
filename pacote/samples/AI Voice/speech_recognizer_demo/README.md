# Speech Recognizer Demo

| Field | Value |
|---|---|
| Package | openai_voice |
| Component area | AI Voice / AI Input |
| Sample type | GUI |
| Status | Beta |
| Main project file | speech_recognizer_demo.lpi |
| External dependencies | Whisper.cpp executable and model, Sherpa-ONNX library and model files, OpenAI or Azure credentials for online backends, real microphone or WAV input |

## Purpose

This demo shows real speech recognition with `TAISpeechRecognizer` and `TAIAudioInput`.

It follows the same sample layout used by the current `openai_voice` demos, but starts on the **Operation** tab and makes it explicit that there is no simulation mode.

The sample only reports success after a real WAV file is validated and the recognizer returns non-empty text.

## Components used

- TAISpeechRecognizer
- TAIAudioInput

## Required packages

- LCL
- openai_input
- openai_voice

## Interface

The demo contains five tabs:

- Operation
- Backends
- Configuration
- Result
- Log

## Operation tab

The Operation tab is the starting page.

It allows the user to:

- select a WAV file
- record a new WAV from the microphone
- use push-to-talk
- transcribe the current file
- cancel an ongoing action
- open the current file or folder

## Backends tab

The sample exposes four real backends:

- `offline.whispercpp`
- `offline.sherpaonnx`
- `online.openai`
- `online.azure`

Online backends require explicit consent before sending audio out of the machine.

## Configuration tab

This tab keeps the component configuration visible and editable:

- recording folder and file prefix
- sample rate and channel count
- duration limit
- Whisper.cpp executable and model settings
- Sherpa-ONNX library and model fields
- OpenAI and Azure credentials and endpoints

Credentials are not persisted by the sample.

## Result tab

The Result tab shows:

- the WAV file used
- the backend that ran
- validation status
- the recognized transcript
- extra result notes

Success is only shown when:

1. the WAV file is valid
2. the backend runs
3. the transcript returned by the recognizer is not empty

## Log tab

The Log tab records the full execution flow, including validation, consent checks, backend selection and cancellation.

## Safety notes

- There is no fake success path.
- Online backends are blocked until consent is checked.
- API tokens and keys are only kept in memory during the current session.
- Output is written locally as WAV and transcript text.

## Known limitations

- Whisper.cpp requires a compatible executable and model file.
- Sherpa-ONNX requires the native library and model files for the selected backend.
- OpenAI and Azure backends require internet access and valid credentials.
- Recording support depends on the platform and available audio backend.
