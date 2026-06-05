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
- CHATGPT-AI-runtime-linux-x64.zip
- CHATGPT-AI-runtime-linux-arm64.zip
- CHATGPT-AI-runtime-linux-armhf.zip
- SHA256SUMS.txt
