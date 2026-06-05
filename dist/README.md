# Distribution

This folder contains scripts and notes for building architecture-specific runtime ZIP packages.

Generated artifacts must be written to:

```text
dist/output/
```

The output folder is ignored by Git.

Final ZIP files must be published as GitHub Release assets.

Expected release assets:

- CHATGPT-AI-runtime-windows-x64.zip
- CHATGPT-AI-runtime-windows7-x86.zip
- CHATGPT-AI-runtime-windows7-x64.zip
- CHATGPT-AI-runtime-linux-x64.zip
- CHATGPT-AI-runtime-linux-arm64.zip
- CHATGPT-AI-runtime-linux-armhf.zip
- SHA256SUMS.txt

## Legacy Windows 7

Windows 7 packages are special legacy builds. They must use a Python 3.8.x runtime and must not be mixed with the modern Windows x64 runtime package.
