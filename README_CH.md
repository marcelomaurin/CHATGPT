# TCHATGPT — Lazarus / Free Pascal AI Component Suite

🌍 **Languages / 语言**

* [Português (PT-BR)](README.md)
* [English (EN)](README_EN.md)
* [Español (ES)](README_ES.md)
* [Français (FR)](README_FR.md)
* [Italiano (IT)](README_IT.md)
* [العربية (AR)](README_AR.md)
* [中文 (ZH-CN)](README_ZH.md)

---

[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)
[![Lazarus](https://img.shields.io/badge/Lazarus-3.x-orange.svg)](https://www.lazarus-ide.org/)
[![Free Pascal](https://img.shields.io/badge/Free%20Pascal-FPC-blue.svg)](https://www.freepascal.org/)
[![Status](https://img.shields.io/badge/status-in%20development-yellow.svg)]()

---

## 项目概述

**TCHATGPT** 是一个面向 **Lazarus / Free Pascal** 的开源组件套件，包含可视化组件和非可视化组件，旨在帮助开发者将人工智能能力集成到桌面应用、工业系统、教育软件和企业级系统中。

本项目提供用于连接 LLM 服务商、本地模型、数据处理、机器学习、语音合成、图像处理、智能代理、图结构、输入输出通道等功能的组件，同时也包含用于计算机视觉和 3D 图形资源的实验性组件。

> 本项目应被理解为一个 **面向 Lazarus 应用的 AI 集成组件套件**，而不是一个用于替代专业训练框架、MLOps 平台或大规模模型部署基础设施的完整 AI 平台。

---

## 项目目标

本项目的主要目标是让 Lazarus / Free Pascal 开发者能够以简单、可复用、组件化的方式，为自己的系统加入人工智能能力。

该组件套件主要面向以下场景：

* 构建生成式 AI 助手；
* 集成 LLM API；
* 通过兼容服务器使用本地模型；
* 生成和分析数据集；
* 简单文本分类；
* 基于智能代理的自动化；
* 文本转语音；
* 基础图像处理；
* 数字音频滤波；
* 与设备、传感器和外部通道集成；
* 在 Lazarus 中快速构建 AI 应用原型。

---

## 当前项目状态

本项目仍处于积极开发阶段，不同组件具有不同的成熟度和稳定性。

### 相对成熟的组件

* `TCHATGPT`
* `TAIBaseComponent`
* `TNeuralNetwork`
* `TTokenList`
* `TAICodeAssistant`
* `TAIDatasetGenerator`
* `TAIVoiceSynthesizer`
* 图像滤波组件
* 音频滤波组件
* 图结构与数据集相关组件

### 实验性或持续演进中的组件

* Python 集成；
* CNN、YOLO、LSTM 和 SOM 组件；
* 自主智能代理组件；
* 高级输入与输出组件；
* OpenCV 组件；
* 3D 可视化；
* Tripo3D 集成；
* 工业、摄像头、音频、浏览器、MQTT、Modbus 和 CCTV 相关组件。

---

## 组件面板分类

该包会将组件安装到 Lazarus 的组件面板中，并按功能领域进行组织。

---

## AI Core

用于生成式 AI、机器学习和项目基础支持的核心组件。

### `TCHATGPT`

生成式 AI 服务商的主要连接组件。

它允许应用程序发送提示词、配置服务商、选择模型并接收结构化响应。

计划支持或已经支持的服务商包括：

* OpenAI；
* Google Gemini；
* Anthropic Claude；
* OpenRouter；
* Cerebras；
* 兼容 `/v1/chat/completions` 的本地服务器；
* Ollama 或类似本地服务。

### `TNeuralNetwork`

使用 Pascal 实现的简单多层神经网络。

可用于：

* 创建本地神经网络；
* 配置输入层、隐藏层和输出层；
* 按 epoch 训练；
* 计算损失；
* 保存和加载模型。

### `TTokenList`

用于基础文本分词的辅助组件。

可用于：

* 分类；
* 文本分析；
* 预处理；
* 决策图；
* 数据集准备。

### `TAICodeAssistant`

基于 LLM 的代码助手组件。

可用于：

* 代码审查；
* 提出改进建议；
* 生成注释；
* 解释代码片段；
* 辅助测试；
* 转换或文档化程序例程。

### `TAIDatasetGenerator`

用于训练、微调或本地分类的数据集生成组件。

支持或计划支持以下结构：

* CSV；
* JSON；
* JSONL；
* 用于本地训练的输入和输出矩阵。

### `TAIModelRegistry`

模型、服务商、endpoint 和参数的集中注册组件。

可用于组织：

* 模型名称；
* 服务商；
* endpoint；
* temperature；
* token 限制；
* 默认参数。

### `TAIWizardConfig`

用于新 AI 项目的配置向导组件。

可用于准备以下类型的项目：

* chatbot；
* 分类器；
* pipeline；
* agent；
* 技术助手。

---

## AI Sound Filters

用于数字信号处理和音频滤波的组件。

### `TLowPassFilter`

一阶 IIR 低通滤波器。

用于平滑快速变化并减少高频噪声。

### `THighPassFilter`

一阶 IIR 高通滤波器。

用于移除低频分量、偏移量或 DC 噪声。

### `TAverageFilter`

移动平均滤波器。

用于简单的信号平滑处理。

### `TFDMMultiplexer`

频分复用组件。

可用于模拟不同频段中的多个通道。

### `TTDMMultiplexer`

时分复用组件。

可用于通过时间片交错多个通道。

### `TCDMMultiplexer`

CDM/CDMA 复用组件。

使用正交码分离信号。

### `TOFDMMultiplexer`

使用 FFT/IFFT 的 OFDM 复用组件。

适用于通信领域的学习、研究和仿真。

---

## AI Image

用于基础图像处理的组件。

### `TGrayscaleFilter`

将图像转换为灰度图。

### `TNegativeFilter`

应用颜色反转。

### `TBrightnessContrastFilter`

调整亮度和对比度。

### `TBinarizationFilter`

应用阈值处理，生成黑白图像。

### `TBlurFilter`

通过卷积执行图像平滑。

### `TSharpenFilter`

使用卷积核增强图像锐度。

### `TSobelFilter`

使用 Sobel 算子检测边缘。

### `TErosionDilationFilter`

执行腐蚀和膨胀等形态学操作。

---

## AI Schedule

用于任务组织、持久化和依赖管理的组件。

### `TJSONGroupStorage`

用于按组保存 JSON 数据的组件。

可用于：

* 保存配置；
* 持久化参数；
* 存储文本；
* 按组组织数据。

### `TIASchedule`

带依赖控制的任务管理组件。

可用于建模：

* 父任务；
* 子任务；
* 依赖关系；
* 就绪状态；
* 简单执行控制。

---

## AI Voice

用于语音合成的组件。

### `TAIVoiceSynthesizer`

Text-to-Speech 组件。

在 Windows 上可使用 SAPI。
在 Linux 上可使用 eSpeak/eSpeak-NG。

主要功能：

* 朗读文本；
* 调整音量；
* 调整语速；
* 列出可用语音；
* 异步执行；
* 与桌面应用集成。

---

## AI Agent

用于智能代理和结构化决策的组件。

### `TAIAgent`

智能代理的编排组件。

可用于向 LLM 发送指令、解释结构化响应并协调动作。

### `TAIAgentOptions`

存储上下文、问题、指令和分析规则。

### `TAIAgentAction`

定义智能代理允许执行的动作。

可配置：

* 可用动作；
* 预期参数；
* 执行回调。

### `TAIAgentResource`

表示可由智能代理触发的外部资源。

示例：

* 文件；
* 电子邮件；
* HTTP；
* SMS；
* WhatsApp；
* TCP/UDP；
* Web APIs。

### `TAIAgentOutput`

将智能代理的决策连接到真实系统资源的输出层。

---

## AI Graph

用于数据结构化、图结构和数据集处理的组件。

### `TAIGraphMap`

基于 token 的加权图分类与分析组件。

可用于：

* 文本分类；
* 概念分组；
* 术语之间的关系；
* 简单主题分析。

### `TAITrainingExporter`

训练数据导出组件。

计划支持或已经支持的格式包括：

* CSV；
* JSON；
* JSONL；
* ARFF；
* 数值向量。

### `TAIDatasetAnalyzer`

数据集质量分析组件。

可检测：

* 空类别；
* 重复样本；
* 类别不平衡；
* 过短文本；
* 过长文本。

### `TAITrainingReport`

训练技术报告生成组件。

可记录：

* 准确率；
* 错误；
* 损失；
* token 数量；
* 平均置信度；
* 数据集统计信息。

### `TAIGraphVisualizer`

图结构导出与可视化组件。

计划支持或已经支持的格式包括：

* DOT / GraphViz；
* Mermaid；
* 可视化 JSON。

---

## AI Input

用于数据输入和外部来源集成的组件。

该分类集中于信息捕获、通信以及与设备或系统集成的组件。

计划支持或正在开发的组件：

* 摄像头；
* 音频；
* Web 服务器；
* sockets；
* 串口通信；
* POS 打印机；
* CCTV/IP；
* Modbus；
* MQTT；
* 电子邮件；
* 消息通道；
* 操作系统捕获；
* 嵌入式浏览器；
* 工业输入。

> 此分类中的部分组件可能需要外部库、驱动程序、操作系统权限或额外服务。

---

## AI Output

用于数据输出、文档生成和外部目标集成的组件。

计划支持或正在开发的资源：

* 文档生成；
* 响应导出；
* 结构化输出；
* 外部通道集成；
* 自动化响应。

---

## AI Vision

用于计算机视觉的组件。

计划支持或正在开发的组件：

* OpenCV；
* 摄像头采集；
* 帧处理；
* 人脸跟踪；
* 运动跟踪；
* 图像分类；
* 目标检测。

> 在组件具备完整演示、依赖文档和集成测试之前，该领域应被视为实验性功能。

---

## AI Graphic

与 AI、仿真和可视化相关的图形与 3D 组件。

计划支持或正在开发的组件：

* 2D/3D 场景；
* 训练环境；
* 物理仿真器；
* 虚拟传感器；
* 奖励函数；
* 3D 模型可视化；
* 骨骼绑定；
* avatar 控制器；
* 姿态库；
* 动画序列；
* 3D 模型生成集成。

### `TAI3DModelViewer`

3D 模型查看器。

目标：

* 加载 3D 模型；
* 显示网格；
* 旋转；
* 放大；
* 缩小；
* 在实体、线框和点模式之间切换。

### `TAITripo3DClient`

用于与外部 3D 模型生成服务集成的客户端组件。

目标：

* 从文本生成模型；
* 从图像生成模型；
* 从多张图像生成模型；
* 下载生成的 3D 模型。

> 与外部服务的集成必须根据所使用服务商的官方 API 文档进行验证。

---

## 在 Lazarus 中安装包

1. 打开 Lazarus。
2. 进入 **Package > Open Package File (.lpk)**。
3. 选择文件 `pacote/openai.lpk`。
4. 点击 **Compile**。
5. 然后点击 **Use > Install**。
6. Lazarus 将要求重新构建 IDE。
7. 重启后，组件将出现在组件面板中。

---

## LLM 服务商

| 服务商                         | Enum             | 类型           |
| --------------------------- | ---------------- | ------------ |
| OpenAI                      | `AIP_OPENAI`     | 外部 API       |
| OpenRouter                  | `AIP_OPENROUTER` | 外部 API / 聚合器 |
| Cerebras                    | `AIP_CEREBRAS`   | 外部 API       |
| Google Gemini               | `AIP_GEMINI`     | 外部 API       |
| Anthropic Claude            | `AIP_CLAUDE`     | 外部 API       |
| Local / Ollama / compatible | `AIP_LOCAL`      | 本地服务器        |

> 模型名称、限制、价格和可用性可能会因服务商而变化。请始终查阅所使用服务的官方文档。

---

## 系统要求

### 主要环境

* Lazarus 3.x 或更高版本；
* 兼容版本的 Free Pascal；
* Windows 或 Linux；
* `openai.lpk` 包；
* 使用外部服务商时需要互联网连接；
* 使用离线模型时需要配置本地服务器。

### Windows

对于 HTTPS 通信，可能需要与应用程序架构兼容的 OpenSSL DLL 文件。

请检查目录 `pacote/lib/`。

建议将所需 DLL 文件复制到最终可执行文件所在的同一目录。

### Linux

根据所使用的组件，可能需要额外安装以下软件包：

* OpenSSL；
* eSpeak/eSpeak-NG；
* libpython；
* 摄像头或音频库；
* 计算机视觉相关库。

具体需求可能因组件而异。

---

## Screenshots

> 以下图片展示了已经测试或正在开发的功能。
> 新组件可能尚未具备完整的可视化演示。

### CNN Demo

![CNN Demo](screenshots/cnn_demo.jpg)

图像分类演示。

### Math Input / Output Demo

![Math Input Output Demo](screenshots/math_input_output_demo.jpg)

数学组件演示。

### Python Connector Demo

![Python Demo](screenshots/python_demo.jpg)

Python 集成演示。

### SOM Demo

![SOM Demo](screenshots/som_demo.jpg)

自组织映射演示。

### Sound Filters Demo

![Sound Filters](screenshots/sound_filters.jpg)

音频滤波演示。

### Voice Synthesizer Demo

![Voice Synthesizer](screenshots/voicesynthesizer.jpg)

语音合成演示。

---

## 已知限制

本项目仍在开发中，包含不同稳定级别的组件。

当前已知或预期限制：

* 部分组件仍可能处于实验阶段；
* 并非所有组件都有完整演示；
* 外部集成依赖第三方 API；
* 计算机视觉组件可能需要外部库；
* Python 组件依赖兼容版本和架构；
* 在生产环境使用前应验证每个组件；
* 自动化测试和持续集成仍需扩展。

---

## Roadmap

### 短期

* 审查组件文档；
* 将组件面板分类名称统一为英文；
* 区分稳定组件和实验组件；
* 为每个组件添加最小演示；
* 验证包在 Windows 和 Linux 上的编译；
* 修复 README 与源代码之间的不一致。

### 中期

* 创建自动化测试；
* 使用 `lazbuild` 创建构建 pipeline；
* 创建版本化 release；
* 文档化外部依赖；
* 改进错误处理；
* 创建使用 LLM、语音、图像和智能代理的真实演示。

### 长期

* 创建项目模板；
* 创建 AI 配置可视化助手；
* 巩固 OpenCV 组件；
* 巩固 3D 组件；
* 改进本地模型集成；
* 通过安全控制增强智能代理；
* 创建面向生产使用的完整文档。

---

## 本项目适合谁？

本项目适合：

* Lazarus 开发者；
* Free Pascal 开发者；
* 教师和学生；
* 桌面 AI 项目；
* 本地自动化；
* 企业遗留系统；
* 教育应用；
* AI 原型项目；
* AI 与设备集成；
* 需要 AI 但不希望将整个代码库迁移到 Python 或 JavaScript 的系统。

---

## 本项目目前不适合谁？

在当前阶段，本项目尚不能替代：

* 完整的 machine learning 框架；
* MLOps 平台；
* 企业级训练 pipeline；
* 专业模型部署服务；
* PyTorch、TensorFlow、scikit-learn 或完整 OpenCV 等专业库；
* 企业级 AI 基础设施。

---

## 贡献

欢迎贡献。

优先贡献方向：

* bug 修复；
* 功能演示；
* 文档；
* 自动化测试；
* Windows/Linux 兼容性；
* 图标和 screenshots；
* 组件验证；
* 错误处理改进；
* 与 AI 服务商集成；
* 为每个 Lazarus 组件分类提供 demo。

---

## License

本项目使用 **GNU General Public License v3.0** 许可证。

请查看 `LICENSE` 文件。

---

## Notice

本项目使用或集成外部 AI 服务。
使用这些服务可能涉及费用、API 限制、服务商政策以及向第三方传输数据。

在生产环境使用前：

* 阅读服务商条款；
* 保护 API keys；
* 未经授权不要发送敏感数据；
* 验证安全性、隐私和合规性；
* 在真实环境中测试组件行为。

---

## 结论

**TCHATGPT** 是一个有潜力将 AI 资源带入 Lazarus / Free Pascal 生态系统的组件套件。

它的核心价值在于为传统应用和现代 AI 资源之间提供实用桥梁，使桌面、工业、教育和企业系统能够以组件化方式集成 LLM、语音、图像、图结构、自动化和本地模型。

该项目仍在演进中，但已经具备成为 Lazarus AI 组件开源参考项目的重要基础。
