# AI Input — Lazarus AI Suite

This package (`openai_input.lpk`) provides input and capture components for the Lazarus AI Suite.

## Components

| Component | Unit | Description |
|-----------|------|-------------|
| [`TAICaptureSource`](TAICaptureSource.md) | `aicapturesource.pas` | Unified capture source: local camera, IP snapshot, screen, file |
| `TAIInputData` | `aiinput.pas` | Numerical data input and normalization |
| `TAIAudioInput` | `aiaudio.pas` | Microphone / audio file capture |
| `TAIWebAPIServer` | `aiwebserver.pas` | Embedded REST/HTTP server |
| `TAISocketTCP` / `TAISocketUDP` | `aisockets.pas` | TCP and UDP networking |
| `TAISerialModem` | `aiserial.pas` | Serial port / modem communication |
| `TAIEmailClient` | `aiemail.pas` | SMTP/POP3 email client |
| `TAIMessenger` | `aimessenger.pas` | WhatsApp and SMS gateway |
| `TAIChromiumBrowser` | `aichromiumbrowser.pas` | Embedded Chromium browser |

## Sample

`samples/AI Input/capture_source_demo/` — demonstrates all `TAICaptureSource` modes.

## Migration from v1.8.x

| Old Component | Replaced By | Mode |
|---|---|---|
| `TAICameraInput` | `TAICaptureSource` | `cskCameraLocal` |
| `TAICFTVIP` | `TAICaptureSource` | `cskCameraIPSnapshot` |
| `TAIOSInputCapture` | `TAICaptureSource` | `cskScreen` |