# Audio Capture Demo

| Field | Value |
|---|---|
| Package | openai_voice |
| Component area | AI Input / AI Voice |
| Sample type | GUI |
| Status | Beta |
| Main project file | audio_capture_demo.lpi |
| External dependencies | Windows MCI or Linux ALSA arecord |

## Purpose

This demo shows how to capture real audio from the system microphone using `TAIAudioInput`.

There is no simulation mode.

## Components used

- TAIAudioInput

## Required packages

- LCL
- openai_voice

## What the demo does

The demo records real audio from the default microphone and saves it as a WAV file.

## Interface

The demo contains four tabs:

- Configuration
- Recording
- Result
- Log

## Configuration tab

Allows the user to select sample rate, channels, duration limit and output WAV file.

## Recording tab

Allows the user to start and stop real audio recording.

## Result tab

Shows the generated WAV file, file size and validation result.

## Log tab

Shows real execution logs.

## Safety notes

The demo records from the default system input device.

The generated WAV file is saved locally.

## Known limitations

Windows uses the native MCI waveaudio backend.

Linux requires `arecord` from ALSA utilities.

The demo records from the default input device only.
