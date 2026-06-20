# Voice Synthesizer Complete Demo

| Field | Value |
|---|---|
| Package | openai_voice |
| Component area | AI Voice |
| Sample type | GUI |
| Status | Beta |
| Main project file | voice_synthesizer_complete_demo.lpi |
| External dependencies | OpenAI API token for cloud voice, SAPI on Windows or eSpeak/eSpeak-NG for local voice |

## Purpose

This sample demonstrates real text-to-speech synthesis using `TAIVoiceSynthesizer`.

It supports two real synthesis modes:

- Local System Voice
- OpenAI Voice API

This sample does not include simulation mode.

## Components used

- TAIVoiceSynthesizer

## Required packages

- openai_core
- openai_voice
- LCL

## OpenAI Voice API

The OpenAI mode uses the `/v1/audio/speech` endpoint.

The configuration tab allows the user to select:

- API token
- model
- voice
- language
- output format
- speed
- output file

## Language

The selected language is included in the OpenAI speech instructions.

Examples:

- en-US
- pt-BR
- es-ES
- fr-FR

## How to use

1. Open the demo in Lazarus.
2. Go to the Configuration tab.
3. Select `OpenAI Voice API`.
4. Enter your OpenAI API token.
5. Select model, voice, language and output format.
6. Go to the Speech tab.
7. Type the text.
8. Click `Generate Speech`.
9. Go to the Output tab.
10. Click `Play Audio`.

## Safety notes

The API token is not stored permanently by the demo.

The generated audio file is saved locally.

## Known limitations

Local voice support depends on the operating system.

OpenAI Voice API mode requires internet access and a valid API token.

Available voices and models may change according to OpenAI API availability.
