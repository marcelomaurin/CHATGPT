# Windows 7 Legacy x86 Installer

Target: Windows 7 32 bit.

Status: legacy / special support.

Recommended Python line: Python 3.8.x 32 bit.

Reason: Python 3.9 and newer are not suitable for Windows 7 legacy installer packages. The Windows 7 runtime line must be isolated from the modern Windows runtime.

Final release asset name:

```text
CHATGPT-AI-runtime-windows7-x86.zip
```

Rules:

- do not use the modern Windows x64 runtime;
- do not require global Python;
- include a bundled Python 3.8.x 32 bit runtime in the release ZIP;
- keep this package separated from Windows 10/11 builds;
- install into a legacy-specific folder;
- mark all Python integrations as legacy tested only.

Default install path:

```text
C:/CHATGPT-AI-Win7
```

Important limitation:

This package exists to support installed legacy equipment. It should not be treated as the recommended runtime for new deployments.
