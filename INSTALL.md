# Installation Guide - TCHATGPT

This document describes the recommended installation process for the **TCHATGPT** component suite in **Lazarus / Free Pascal**.

> Recommended for new projects: install the modular packages from `pacote/packages/` instead of using the legacy wrapper `pacote/openai.lpk`.

---

## 1. Requirements

### Required

- Lazarus 3.x or newer
- Free Pascal compatible with the Lazarus version used
- Git, if cloning the repository

### Optional, depending on the component

- OpenSSL libraries for HTTPS/API access
- Python 3 for Python-based components
- Python packages such as `numpy`, `opencv-python`, `requests` or model-specific libraries
- Windows SAPI or Linux eSpeak/eSpeak-NG for voice components
- Camera/audio/serial permissions depending on the operating system

---

## 2. Downloading the project

Clone the repository:

```bash
git clone https://github.com/marcelomaurin/CHATGPT.git
```

Enter the project directory:

```bash
cd CHATGPT
```

Or download the ZIP file from GitHub and extract it to a local directory.

---

## 3. Recommended package installation order

Open Lazarus and install the packages in this order.

### Step 1 - Install the core package first

In Lazarus:

```text
Package > Open Package File (.lpk)
```

Open:

```text
pacote/packages/openai_core.lpk
```

Then click:

```text
Compile > Install
```

When Lazarus asks to rebuild the IDE, confirm.

### Step 2 - Install only the packages you need

After installing `openai_core.lpk`, install the optional packages required by your project:

```text
pacote/packages/openai_ml.lpk
pacote/packages/openai_graph.lpk
pacote/packages/openai_output.lpk
pacote/packages/openai_input.lpk
pacote/packages/openai_python.lpk
pacote/packages/openai_vision.lpk
pacote/packages/openai_image.lpk
pacote/packages/openai_voice.lpk
pacote/packages/openai_industrial.lpk
pacote/packages/openai_graphic.lpk
pacote/packages/openai_agent.lpk
```

Recommended order:

```text
1. openai_core.lpk
2. openai_ml.lpk
3. openai_graph.lpk
4. openai_output.lpk
5. openai_input.lpk
6. openai_python.lpk
7. openai_vision.lpk
8. openai_image.lpk
9. openai_voice.lpk
10. openai_industrial.lpk
11. openai_graphic.lpk
12. openai_agent.lpk
```

---

## 4. Legacy installation

The old package still exists:

```text
pacote/openai.lpk
```

Use it only for compatibility with older projects.

For new applications, use the modular packages under:

```text
pacote/packages/
```

---

## 5. Windows installation notes

### OpenSSL

Some API/HTTPS components may need OpenSSL DLLs.

Keep the required DLLs in one of these locations:

```text
same directory as the application executable
same directory as the Lazarus IDE executable, during design/test
system PATH directory
```

The exact DLL names depend on the Indy/OpenSSL version used by the application.

### Python-based components

For components that use Python, the Python architecture must match the application architecture:

```text
32-bit Lazarus/application -> 32-bit Python
64-bit Lazarus/application -> 64-bit Python
```

Typical packages:

```bash
pip install numpy requests opencv-python
```

Some older Windows versions may require special Python builds and older compatible packages.
When targeting Windows 7, validate the Python version and package compatibility before distributing the application.

---

## 6. Linux installation notes

Install Lazarus and Free Pascal using your distribution package manager or official Lazarus packages.

For Debian/Ubuntu-based systems, typical dependencies may include:

```bash
sudo apt update
sudo apt install lazarus fpc git openssl espeak-ng python3 python3-pip
```

For Python-based components:

```bash
python3 -m pip install numpy requests opencv-python
```

For serial, camera and audio access, the user may need permissions:

```bash
sudo usermod -aG dialout $USER
sudo usermod -aG video $USER
sudo usermod -aG audio $USER
```

After changing groups, log out and log in again.

---

## 7. Raspberry Pi / ARM notes

The pure Lazarus / Free Pascal components should be preferred for ARM/Raspberry Pi.

When using Python-based components, verify:

- Python version available for the device;
- wheel/package availability for ARM;
- camera/audio permissions;
- performance limitations of the board;
- whether the component depends on x86/x64 native libraries.

For best compatibility on Raspberry Pi, prioritize:

```text
openai_core
openai_ml
openai_graph
openai_output
openai_input
openai_image
```

Use Python, OpenCV, vision and heavy model components only after validating the environment.

---

## 8. Validating the installation

After installing the desired packages:

1. Restart Lazarus.
2. Create a new test application.
3. Check if the AI component tabs appear in the component palette.
4. Open one of the samples/examples from the repository.
5. Compile the sample.
6. Test a basic component first, preferably from `openai_core`.

---

## 9. Common problems

### Package not found

Check if the path is correct and if the repository was fully downloaded.

### Unit not found

Check if the required package was installed before the dependent package.
Install `openai_core.lpk` first.

### HTTPS/API error

Check OpenSSL libraries and API configuration.

### Python DLL error on Windows

Check if Python is installed and if the architecture matches the application.

### Camera/audio/serial error on Linux

Check user permissions and device groups.

---

## 10. Recommended production approach

For production applications:

- install only the packages required by the application;
- avoid experimental packages unless needed;
- check `pacote/COMPONENT_STATUS.md` before adopting a component;
- keep external DLLs/libraries documented with the application;
- test separately on Windows, Linux, ARM, x86 and x64 when targeting multiple platforms.

---

## 11. Related documentation

Main README:

```text
README.md
```

Plain text quick reference:

```text
ReadMe.txt
```

Component maturity matrix:

```text
pacote/COMPONENT_STATUS.md
```
