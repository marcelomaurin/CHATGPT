# Windows x64 Manifest

Project: CHATGPT-AI
Package: runtime-installer
Platform: Windows
Architecture: x64
Default install path: `C:/CHATGPT-AI`
Status: supported

## Lazarus packages

- openai_core.lpk
- openai_vision.lpk
- openai_ml.lpk
- openai_llamacpp.lpk (optional, Windows x86_64)

## Notes

- Final ZIP assets must be published in GitHub Releases.
- Expanded Python runtimes and DLL bundles must not be committed to the repository.
- `openai_core` remains independently installable. The llama.cpp package is
  selected explicitly with `install_components.bat llamacpp` or as part of
  `all`.
