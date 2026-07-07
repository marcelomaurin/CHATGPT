# Python Connector Demo (`python_demo`)

本文档介绍 **`python_demo`** 示例。该示例用于演示如何在 Lazarus/Free Pascal 应用中使用 **`TPythonConnector`** 组件。

## 🌐 翻译

| 语言 | 文件 |
|---|---|
| Português | `README.md` |
| English | `README.en.md` |
| Español | `README.es.md` |
| العربية | `README.ar.md` |
| Italiano | `README.it.md` |
| 日本語 | `README.ja.md` |
| 中文 | `README.zh.md` |
| Русский | `README.ru.md` |
| हिन्दी | `README.hi.md` |

---

## 1. 目标

本示例展示如何使用 **`TPythonConnector`** 将 Python 解释器集成到 Lazarus 应用中。它可以激活 Python、执行脚本、捕获输出、计算表达式，并在 Pascal 与 Python 之间交换变量。

在 **CHATGPT** 项目中使用更复杂的 AI、计算机视觉、音频或机器学习组件之前，可以先用本示例验证 Python runtime 是否正确安装或嵌入。

---

## 2. 本示例演示的内容

- 根据应用程序架构选择兼容的 Python 库或可执行文件。
- 激活和停用 Python 解释器。
- 两种执行模式：
  - **`pemDLL`**：加载 `python3.dll`、`python312.dll`、`libpython3.so` 或等效库。
  - **`pemProcess`**：将 Python 作为持久外部进程运行。
- 使用 **`ExecString`** 执行脚本。
- 通过 **`LastOutput`** 和 **`LastError`** 捕获标准输出和错误。
- 使用 **`GetVar`** 和 **`SetVar`** 读写全局变量。
- 使用 **`Eval`** 动态计算表达式。
- 输出诊断报告，包括架构、版本、执行模式、已加载库和失败步骤。

---

## 3. 示例结构

```text
pacote/samples/AI/python_demo/
├── python_demo.lpi      # Lazarus 项目
├── python_demo.lpr      # 主程序
├── main.pas             # 窗体逻辑以及与 TPythonConnector 的集成
├── main.lfm             # 可视化窗体定义
└── README.md            # 葡萄牙语文档
```

该项目依赖 **`LCL`** 和 **`openai_core`** 包。

---

## 4. 要求

### Lazarus / Free Pascal

- 已安装 Lazarus。
- 项目路径中可以访问 **`openai_core`** 包。
- 通过 **`python_demo.lpi`** 打开项目。

### Python

组件配置为支持 Python **3.8 到 3.14**。

架构必须匹配：

| 编译后的应用 | 所需 Python |
|---|---|
| Windows 64-bit | 64-bit Python |
| Windows 32-bit | 32-bit Python |
| Linux 64-bit | 64-bit `libpython`/`python3` |
| Linux ARM/ARM64 | 相同架构的 `libpython`/`python3` |

如果使用 **DLL/SO** 模式，必要时还需要安装 Python 开发库。

Debian/Ubuntu 示例：

```bash
sudo apt install python3 python3-dev libpython3-dev
```

---

## 5. 如何编译

1. 打开 Lazarus。
2. 打开文件：

```text
pacote/samples/AI/python_demo/python_demo.lpi
```

3. 使用以下菜单编译：

```text
Run > Build
```

或按：

```text
Ctrl + F9
```

4. 运行生成的二进制文件：

- Windows: `python_demo.exe`
- Linux: `python_demo`

---

## 6. 如何使用

1. 从列表中选择 Python DLL、SO 或可执行文件。
2. 第一次测试建议保持 **Use External Process** 选中。
3. 点击 **Activate Python interpreter**。
4. 查看日志面板。
5. 执行默认脚本，或在 memo 中编写自己的脚本。
6. 使用 **SetVar**、**GetVar** 和 **Eval** 测试 Pascal 与 Python 之间的数据交换。

---

## 7. 推荐快速测试

### 脚本

将以下内容粘贴到脚本 memo：

```python
x = 10
print("Hello from Python")
print("x =", x)
```

点击执行脚本按钮。

### 读取变量

在 **Variable Name** 中输入：

```text
x
```

点击 **GetVar**。

期望值：

```text
10
```

### 计算表达式

在表达式字段中使用：

```python
x + 50
```

期望结果：

```text
60
```

### 关于 `SetVar` 的注意事项

当前 **`SetVar` 会把值保存为字符串**。如果使用：

```text
Name: y
Value: 10
```

请在 Eval 中使用：

```python
int(y) + 50
```

而不是：

```python
y + 50
```

---

## 8. 执行模式

### `pemProcess` — 外部进程

这是推荐的初始测试模式。

优点：

- 更好地隔离 Python 与 Lazarus 进程。
- 减少 DLL/SO 冲突造成的崩溃。
- 更适合初步测试 TensorFlow、OpenCV、Torch、Keras 等大型库。
- 使用系统中找到的 `python.exe`、`python3.exe`、`python3` 或其他可执行文件。

### `pemDLL` — 动态库

将 Python 直接加载到应用进程中。

优点：

- 与 Python C API 的集成更直接。
- 对简单调用可能更快。

注意：

- 架构必须完全一致。
- 库必须导出必需的 C API 函数。
- Python 库错误可能导致 Lazarus 进程崩溃。

---

## 9. 诊断

激活 Python 时，示例会在日志面板输出诊断报告，包括：

- 检测到的操作系统；
- Lazarus 架构；
- 执行模式；
- 配置路径；
- 已加载的库或可执行文件；
- Python 版本；
- 架构兼容性；
- 找到的必需函数；
- 最后加载步骤；
- 最后错误。

在判断组件本身有问题之前，请先查看该报告。大多数问题来自架构不匹配、库缺失或 Python 不在 PATH 中。

---

## 10. 常见问题

| 现象 | 可能原因 | 解决方法 |
|---|---|---|
| `Failed to load python3.dll` | 未安装 Python、DLL 缺失或架构错误 | 安装与可执行文件同架构的 Python |
| `Failed to load libpython` | Linux 缺少开发包 | 安装 `python3-dev`/`libpython3-dev` |
| Python 已激活但 `GetVar` 失败 | DLL 模式下缺少可选 C API 函数 | 尝试 `pemProcess` |
| `SetVar` 后 `y + 50` 失败 | `SetVar` 注入的是字符串 | 使用 `int(y) + 50` 或在脚本中定义 `y = 10` |
| 没有输出 | 脚本没有调用 `print` 或执行失败 | 检查 `LastError` 和日志 |
| 终端中正常，Lazarus 中失败 | IDE 环境中的 PATH 不同 | 使用 Python 的绝对路径 |

---

## 11. 最佳实践

- 首先使用 **`pemProcess`** 测试。
- 只有在需要直接集成 C API 时才使用 **`pemDLL`**。
- 保持 Python 与 Lazarus 的架构一致。
- 分发时，将 Python runtime 放在应用目录或 `libs` 子目录中。
- 报告错误时始终复制诊断报告。
- 避免在 memo 中直接写很长的脚本；建议使用短小的增量测试。

---

## 12. 与 CHATGPT 项目的关系

本示例用于验证 Lazarus ↔ Python 桥接。它为依赖 Python 的其他组件提供基础，例如：

- 图像分类；
- CNN 模型；
- YOLO；
- OpenCV；
- 人脸检测；
- 音频处理；
- 机器学习库。

在排查更复杂的 AI 组件错误之前，请先运行本示例确认 Python 能正确加载。

---

## 13. 建议的后续改进

- 添加按钮手动选择 `python.exe`、`python3`、DLL、SO 或 dylib。
- 明确显示所选项目是可执行文件还是库。
- 将界面拆分为：配置、脚本、变量、Eval、诊断等标签页。
- 添加 **复制诊断** 按钮。
- 保存上次使用的配置。
- 在激活前验证所选文件是否存在。
- 当 `SetVar` 输入数字时显示提示，说明该值会被当作字符串。

---

## 14. 总结

**`python_demo`** 是 CHATGPT 包中任何 Python 集成的推荐首个测试。如果该示例可以激活解释器、执行脚本、读取变量并计算表达式，说明 Python 集成基础已经正常工作。