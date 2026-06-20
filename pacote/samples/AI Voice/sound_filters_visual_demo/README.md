# Sound Filters Visual Demo

![Sound Filters Visual Demo](../../../../screenshots/sound_filters_visual_demo.jpg)

| Field | Value |
|---|---|
| Package | openai_voice |
| Component area | AI Voice / Sound Filters |
| Sample type | GUI |
| Status | Beta |
| Main project file | sound_filters_visual_demo.lpi |
| External dependencies | No external dependencies |

## Purpose

This sample demonstrates real signal processing using the sound filter components.

It does not use simulation mode.

## Components used

- TLowPassFilter
- THighPassFilter
- TAverageFilter

## Required packages

- LCL
- openai_voice

## Interface

The demo contains four tabs:

- Signal
- Filters
- Result
- Log

## Signal tab

Generates a real in-memory test signal composed of a base sine wave plus high-frequency noise.

## Filters tab

Applies one real filter to the generated signal:

- Low-pass
- High-pass
- Moving average

## Result tab

Displays the input and filtered signals as waveforms and shows numeric metrics.

## Log tab

Shows real execution logs.

## Safety notes

This sample does not read or write real audio devices.

It only processes numeric sample arrays in memory.

## Known limitations

This demo does not load WAV files yet.

This demo does not play audio yet.

The visual waveform is intended for demonstration and debugging of the filter components.
