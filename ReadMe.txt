TCHATGPT - AI Component Suite for Lazarus / Free Pascal
======================================================

Repository:
https://github.com/marcelomaurin/CHATGPT

Author:
Marcelo Maurin Martins

Overview
--------
TCHATGPT is an open source suite of visual and non-visual components for
Lazarus / Free Pascal. The goal is to make it easier to add Artificial
Intelligence features to desktop, industrial, educational and corporate
applications.

The project includes components for:

- LLM / ChatGPT provider integration;
- local and remote AI model access;
- prompt construction and pipeline organization;
- text processing and tokenization support;
- graph-based AI utilities;
- simple machine learning helpers;
- voice and audio processing;
- image processing and computer vision;
- input/output integration;
- industrial communication;
- agent-oriented automation;
- 3D and graphic visualization experiments.

Project status
--------------
This project is under active development. Components may have different
maturity levels: stable, beta, experimental, placeholder or deprecated.

Before using a component in production, check the component status matrix:

  pacote/COMPONENT_STATUS.md

Recommended package structure
-----------------------------
The modern package structure is modular and is located under:

  pacote/packages/

Recommended base package:

  pacote/packages/openai_core.lpk

Optional packages include:

  pacote/packages/openai_ml.lpk
  pacote/packages/openai_graph.lpk
  pacote/packages/openai_vision.lpk
  pacote/packages/openai_image.lpk
  pacote/packages/openai_voice.lpk
  pacote/packages/openai_input.lpk
  pacote/packages/openai_output.lpk
  pacote/packages/openai_industrial.lpk
  pacote/packages/openai_graphic.lpk
  pacote/packages/openai_agent.lpk

Legacy package
--------------
The old package still exists for compatibility:

  pacote/openai.lpk

For new projects, prefer the modular packages from pacote/packages/.
The legacy package should be treated only as a compatibility wrapper.

Installation
------------
See the installation guide:

  INSTALL.md

Basic installation summary:

1. Install Lazarus 3.x and Free Pascal.
2. Clone or download this repository.
3. Open Lazarus.
4. Go to Package > Open Package File (.lpk).
5. Open and install pacote/packages/openai_core.lpk first.
6. Install only the additional packages needed by your project.
7. Rebuild the Lazarus IDE when requested.
8. Open the samples/examples to validate the installation.

External dependencies
---------------------
Some components are pure Lazarus / Free Pascal. Others may require external
runtime dependencies depending on the feature being used.

Common optional dependencies:

- OpenSSL DLLs / libraries for HTTPS access;
- Python 3 for Python-based AI integrations;
- Python packages such as numpy, opencv-python or model-specific libraries;
- Windows SAPI or Linux eSpeak/eSpeak-NG for voice resources;
- platform-specific camera, serial, socket or industrial libraries.

Windows notes
-------------
On Windows, keep required DLLs next to the application executable when needed,
especially OpenSSL libraries used by Indy/HTTPS components.

For Python-based components, the Python architecture must match the compiled
application architecture:

- 32-bit application -> 32-bit Python;
- 64-bit application -> 64-bit Python.

Linux notes
-----------
On Linux, verify library packages, permissions and device access when using
camera, audio, serial ports or industrial communication.

Typical checks:

  sudo usermod -aG dialout $USER
  sudo usermod -aG video $USER
  sudo usermod -aG audio $USER

After changing groups, log out and log in again.

License
-------
This project is distributed under the GPLv3 license, unless a specific file
states otherwise.

Notes
-----
This ReadMe.txt is a plain text quick reference. The main project documentation
is maintained in README.md and related translated README files.
