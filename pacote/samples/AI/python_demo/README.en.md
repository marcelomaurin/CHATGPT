# Python Connector Demo (`python_demo`)

Documentation for the **`python_demo`** sample, created to demonstrate the **`TPythonConnector`** component in Lazarus/Free Pascal applications.

## 🌐 Translations

| Language | File |
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

## 1. Purpose

This example shows how to integrate a Python interpreter into a Lazarus application using **`TPythonConnector`**. The sample can activate Python, execute scripts, capture output, evaluate expressions, and exchange variables between Pascal and Python.

It is useful for validating that the Python runtime is correctly installed or embedded before using more complex AI, computer vision, audio, or machine learning components in the **CHATGPT** project.

---

## 2. What this sample demonstrates

- Selection of a Python library or executable compatible with the application architecture.
- Activation and deactivation of the Python interpreter.
- Two execution modes:
  - **`pemDLL`**: loads `python3.dll`, `python312.dll`, `libpython3.so`, or an equivalent library.
  - **`pemProcess`**: runs Python as a persistent external process.
- Script execution through **`ExecString`**.
- Standard output and error capture through **`LastOutput`** and **`LastError`**.
- Reading and writing global variables with **`GetVar`** and **`SetVar`**.
- Dynamic expression evaluation through **`Eval`**.
- Diagnostic report with architecture, version, execution mode, loaded library, and failing step.

---

## 3. Sample structure

```text
pacote/samples/AI/python_demo/
├── python_demo.lpi      # Lazarus project
├── python_demo.lpr      # Main program
├── main.pas             # Form logic and TPythonConnector integration
├── main.lfm             # Visual form definition
└── README.md            # Portuguese documentation
```

The project depends on the **`LCL`** and **`openai_core`** packages.

---

## 4. Requirements

### Lazarus / Free Pascal

- Lazarus installed.
- The **`openai_core`** package available in the project path.
- Open the project through **`python_demo.lpi`**.

### Python

The component is configured to accept Python **3.8 to 3.14**.

The architecture must match:

| Compiled application | Required Python |
|---|---|
| Windows 64-bit | 64-bit Python |
| Windows 32-bit | 32-bit Python |
| Linux 64-bit | 64-bit `libpython`/`python3` |
| Linux ARM/ARM64 | `libpython`/`python3` with the same architecture |

For **DLL/SO** mode, install the Python development library when required.

Example on Debian/Ubuntu:

```bash
sudo apt install python3 python3-dev libpython3-dev
```

---

## 5. How to build

1. Open Lazarus.
2. Open this project file:

```text
pacote/samples/AI/python_demo/python_demo.lpi
```

3. Build it with:

```text
Run > Build
```

or press:

```text
Ctrl + F9
```

4. Run the generated binary:

- Windows: `python_demo.exe`
- Linux: `python_demo`

---

## 6. How to use

1. Select a Python DLL, SO, or executable from the list.
2. Keep **Use External Process** checked for the first test.
3. Click **Activate Python interpreter**.
4. Check the **Operation Logs** panel.
5. Run the default script or write your own script in the memo.
6. Use **SetVar**, **GetVar**, and **Eval** to test data exchange between Pascal and Python.

---

## 7. Recommended quick test

### Script

Paste this into the script memo:

```python
x = 10
print("Hello from Python")
print("x =", x)
```

Click **Execute Script in Python**.

### Read a variable

In **Variable Name**, enter:

```text
x
```

Click **GetVar**.

Expected value:

```text
10
```

### Evaluate an expression

In the expression field, use:

```python
x + 50
```

Expected result:

```text
60
```

### Important note about `SetVar`

Currently, **`SetVar` stores values as strings**. If you use:

```text
Name: y
Value: 10
```

use this expression in Eval:

```python
int(y) + 50
```

instead of:

```python
y + 50
```

---

## 8. Execution modes

### `pemProcess` — External process

Recommended for first tests.

Advantages:

- Better isolation between Python and the Lazarus process.
- Reduces crashes caused by DLL/SO conflicts.
- Better starting point for heavy libraries such as TensorFlow, OpenCV, Torch, or Keras.
- Uses `python.exe`, `python3.exe`, `python3`, or another executable found in the system.

### `pemDLL` — Dynamic library

Loads Python directly inside the application process.

Advantages:

- More direct integration with the Python C API.
- Can be faster for simple calls.

Warnings:

- The architecture must match exactly.
- The library must export the required C API functions.
- A Python library failure can crash the Lazarus process.

---

## 9. Diagnostics

When Python is activated, the sample prints a diagnostic report in the logs panel with:

- detected operating system;
- Lazarus architecture;
- execution mode;
- configured path;
- loaded library or executable;
- Python version;
- architecture compatibility;
- required functions found;
- last loading step;
- last error, when available.

Use this report before assuming the component is broken. Most issues are caused by architecture mismatch, missing libraries, or Python not being available in PATH.

---

## 10. Common problems

| Symptom | Likely cause | Fix |
|---|---|---|
| `Failed to load python3.dll` | Python is not installed, DLL is missing, or architecture is wrong | Install Python with the same architecture as the executable |
| `Failed to load libpython` | Development package missing on Linux | Install `python3-dev`/`libpython3-dev` |
| Python activates but `GetVar` fails | Optional Python C API functions unavailable in DLL mode | Test with `pemProcess` |
| `y + 50` fails after `SetVar` | `SetVar` injects a string | Use `int(y) + 50` or define `y = 10` in the script |
| No output appears | Script does not call `print` or execution failed | Check `LastError` and the log |
| Works in terminal but not in Lazarus | PATH differs inside the IDE environment | Use the absolute Python path |

---

## 11. Best practices

- Test with **`pemProcess`** first.
- Use **`pemDLL`** only when direct C API integration is required.
- Keep Python and Lazarus on the same architecture.
- For distribution, place the Python runtime inside the application folder or a `libs` subfolder.
- Always copy the diagnostic report when reporting an issue.
- Avoid long scripts directly in the memo; prefer short incremental tests.

---

## 12. Relation to the CHATGPT project

This sample validates the Lazarus ↔ Python bridge. It prepares the foundation for other Python-based project components, such as:

- image classification;
- CNN models;
- YOLO;
- OpenCV;
- face detection;
- audio processing;
- machine learning libraries.

Before investigating bugs in more complex AI components, run this sample to confirm that Python is loading correctly.

---

## 13. Suggested future improvements

- Add a button to manually locate `python.exe`, `python3`, DLL, SO, or dylib files.
- Clearly show whether the selected item is an executable or a library.
- Split the interface into tabs: Configuration, Script, Variables, Eval, and Diagnostics.
- Add a **Copy diagnostics** button.
- Save the last used configuration.
- Validate whether the selected file exists before activation.
- Show a warning when `SetVar` is used with numeric input, explaining that the value is treated as a string.

---

## 14. Summary

**`python_demo`** is the recommended first test for any Python integration inside the CHATGPT package. If this sample activates the interpreter, executes scripts, reads variables, and evaluates expressions, the Python integration base is working.