# Python Connector Demo (`python_demo`)

यह दस्तावेज़ **`python_demo`** sample के लिए है। यह sample Lazarus/Free Pascal applications में **`TPythonConnector`** component का उपयोग दिखाता है।

## 🌐 अनुवाद

| भाषा | फ़ाइल |
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

## 1. उद्देश्य

यह example दिखाता है कि **`TPythonConnector`** का उपयोग करके Lazarus application में Python interpreter कैसे जोड़ा जा सकता है। यह sample Python को activate करने, scripts चलाने, output capture करने, expressions evaluate करने और Pascal तथा Python के बीच variables exchange करने की सुविधा देता है।

**CHATGPT** project में AI, computer vision, audio या machine learning जैसे अधिक जटिल components इस्तेमाल करने से पहले यह verify करने के लिए उपयोगी है कि Python runtime सही तरीके से installed या embedded है।

---

## 2. यह sample क्या दिखाता है

- application architecture के अनुसार compatible Python library या executable चुनना।
- Python interpreter को activate/deactivate करना।
- दो execution modes:
  - **`pemDLL`**: `python3.dll`, `python312.dll`, `libpython3.so` या equivalent library load करता है।
  - **`pemProcess`**: Python को persistent external process के रूप में चलाता है।
- **`ExecString`** से scripts execute करना।
- **`LastOutput`** और **`LastError`** से stdout/stderr capture करना।
- **`GetVar`** और **`SetVar`** से global variables पढ़ना और लिखना।
- **`Eval`** से dynamic expressions evaluate करना।
- architecture, version, execution mode, loaded library और failure step वाला diagnostic report।

---

## 3. Sample structure

```text
pacote/samples/AI/python_demo/
├── python_demo.lpi      # Lazarus project
├── python_demo.lpr      # main program
├── main.pas             # form logic और TPythonConnector integration
├── main.lfm             # visual form definition
└── README.md            # Portuguese documentation
```

Project **`LCL`** और **`openai_core`** packages पर निर्भर करता है।

---

## 4. Requirements

### Lazarus / Free Pascal

- Lazarus installed होना चाहिए।
- **`openai_core`** package project path में उपलब्ध होना चाहिए।
- Project को **`python_demo.lpi`** से खोलें।

### Python

Component Python **3.8 से 3.14** तक accept करने के लिए configured है।

Architecture match होनी चाहिए:

| Compiled application | Required Python |
|---|---|
| Windows 64-bit | 64-bit Python |
| Windows 32-bit | 32-bit Python |
| Linux 64-bit | 64-bit `libpython`/`python3` |
| Linux ARM/ARM64 | same architecture वाला `libpython`/`python3` |

**DLL/SO** mode के लिए ज़रूरत पड़ने पर Python development library install करें।

Debian/Ubuntu example:

```bash
sudo apt install python3 python3-dev libpython3-dev
```

---

## 5. Build कैसे करें

1. Lazarus खोलें।
2. यह file खोलें:

```text
pacote/samples/AI/python_demo/python_demo.lpi
```

3. Build करें:

```text
Run > Build
```

या दबाएँ:

```text
Ctrl + F9
```

4. Generated binary चलाएँ:

- Windows: `python_demo.exe`
- Linux: `python_demo`

---

## 6. उपयोग कैसे करें

1. List से Python DLL, SO या executable चुनें।
2. पहले test के लिए **Use External Process** checked रखें।
3. **Activate Python interpreter** पर click करें।
4. Logs panel देखें।
5. Default script चलाएँ या memo में अपना script लिखें।
6. **SetVar**, **GetVar** और **Eval** से Pascal और Python के बीच data exchange test करें।

---

## 7. Recommended quick test

### Script

Script memo में paste करें:

```python
x = 10
print("Hello from Python")
print("x =", x)
```

Script execute करें।

### Variable पढ़ना

**Variable Name** field में लिखें:

```text
x
```

**GetVar** दबाएँ।

Expected value:

```text
10
```

### Expression evaluate करना

Expression field में लिखें:

```python
x + 50
```

Expected result:

```text
60
```

### `SetVar` के बारे में महत्वपूर्ण बात

अभी **`SetVar` values को string के रूप में store करता है**। अगर आप उपयोग करते हैं:

```text
Name: y
Value: 10
```

तो Eval में यह लिखें:

```python
int(y) + 50
```

इसके बजाय:

```python
y + 50
```

---

## 8. Execution modes

### `pemProcess` — External process

पहले test के लिए recommended mode है।

Advantages:

- Python को Lazarus process से बेहतर isolate करता है।
- DLL/SO conflict से crash की संभावना कम करता है।
- TensorFlow, OpenCV, Torch या Keras जैसी heavy libraries के साथ शुरू करने के लिए बेहतर है।
- `python.exe`, `python3.exe`, `python3` या system में मिले executable का उपयोग करता है।

### `pemDLL` — Dynamic library

Python को application process के अंदर direct load करता है।

Advantages:

- Python C API के साथ direct integration।
- Simple calls में तेज़ हो सकता है।

Warnings:

- Architecture बिल्कुल match होनी चाहिए।
- Library में required C API functions export होने चाहिए।
- Python library की failure Lazarus process को crash कर सकती है।

---

## 9. Diagnostics

Python activate करते समय sample logs panel में diagnostic report दिखाता है:

- detected operating system;
- Lazarus architecture;
- execution mode;
- configured path;
- loaded library या executable;
- Python version;
- architecture compatibility;
- required functions;
- last loading step;
- last error.

Component को broken मानने से पहले यह report देखें। अधिकतर errors architecture mismatch, missing library या PATH में Python न मिलने से होते हैं।

---

## 10. Common problems

| Symptom | Likely cause | Fix |
|---|---|---|
| `Failed to load python3.dll` | Python installed नहीं है, DLL missing है या architecture गलत है | executable जैसी architecture वाला Python install करें |
| `Failed to load libpython` | Linux में development package missing है | `python3-dev`/`libpython3-dev` install करें |
| Python activate होता है, पर `GetVar` fail होता है | DLL mode में optional Python C API functions missing हैं | `pemProcess` test करें |
| `SetVar` के बाद `y + 50` fail होता है | `SetVar` string inject करता है | `int(y) + 50` use करें या script में `y = 10` define करें |
| Output नहीं आता | script में `print` नहीं है या execution fail हुआ | `LastError` और log देखें |
| terminal में चलता है, Lazarus में नहीं | IDE का PATH अलग है | Python का absolute path दें |

---

## 11. Best practices

- सबसे पहले **`pemProcess`** test करें।
- **`pemDLL`** तभी use करें जब direct C API integration चाहिए।
- Python और Lazarus की architecture समान रखें।
- Distribution के लिए Python runtime को application folder या `libs` subfolder में रखें।
- Error report करते समय diagnostic report copy करें।
- memo में बहुत लंबे scripts न रखें; छोटे incremental tests करें।

---

## 12. CHATGPT project से संबंध

यह sample Lazarus ↔ Python bridge validate करता है। यह उन components के लिए base है जो Python पर निर्भर हैं, जैसे:

- image classification;
- CNN models;
- YOLO;
- OpenCV;
- face detection;
- audio processing;
- machine learning libraries.

Complex AI component में error खोजने से पहले इस sample से confirm करें कि Python सही तरह load हो रहा है।

---

## 13. Suggested future improvements

- `python.exe`, `python3`, DLL, SO या dylib manually locate करने के लिए button जोड़ना।
- Selected item executable है या library, यह साफ दिखाना।
- Interface को tabs में बाँटना: Configuration, Script, Variables, Eval और Diagnostics।
- **Copy diagnostics** button जोड़ना।
- Last used configuration save करना।
- Activation से पहले selected file exists है या नहीं validate करना।
- `SetVar` numeric value के साथ use होने पर warning दिखाना कि value string मानी जाएगी।

---

## 14. Summary

**`python_demo`** CHATGPT package में किसी भी Python integration के लिए recommended first test है। अगर यह sample interpreter activate करता है, scripts execute करता है, variables पढ़ता है और expressions evaluate करता है, तो Python integration base काम कर रहा है।