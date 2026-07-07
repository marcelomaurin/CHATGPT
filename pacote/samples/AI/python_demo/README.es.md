# Python Connector Demo (`python_demo`)

Documentación del sample **`python_demo`**, creado para demostrar el uso del componente **`TPythonConnector`** en aplicaciones Lazarus/Free Pascal.

## 🌐 Traducciones

| Idioma | Archivo |
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

## 1. Objetivo

Este ejemplo muestra cómo integrar un intérprete Python en una aplicación Lazarus usando **`TPythonConnector`**. El sample permite activar Python, ejecutar scripts, capturar la salida, evaluar expresiones e intercambiar variables entre Pascal y Python.

Es útil para validar si el runtime de Python está instalado o embebido correctamente antes de usar componentes más complejos de IA, visión computacional, audio o machine learning dentro del proyecto **CHATGPT**.

---

## 2. Qué demuestra este sample

- Selección de una biblioteca o ejecutable Python compatible con la arquitectura de la aplicación.
- Activación y desactivación del intérprete Python.
- Dos modos de ejecución:
  - **`pemDLL`**: carga `python3.dll`, `python312.dll`, `libpython3.so` o una biblioteca equivalente.
  - **`pemProcess`**: ejecuta Python como proceso externo persistente.
- Ejecución de scripts con **`ExecString`**.
- Captura de salida estándar y errores con **`LastOutput`** y **`LastError`**.
- Lectura y escritura de variables globales con **`GetVar`** y **`SetVar`**.
- Evaluación dinámica de expresiones con **`Eval`**.
- Informe de diagnóstico con arquitectura, versión, modo de ejecución, biblioteca cargada y etapa de falla.

---

## 3. Estructura del sample

```text
pacote/samples/AI/python_demo/
├── python_demo.lpi      # Proyecto Lazarus
├── python_demo.lpr      # Programa principal
├── main.pas             # Lógica del formulario e integración con TPythonConnector
├── main.lfm             # Definición visual del formulario
└── README.md            # Documentación en portugués
```

El proyecto depende de los paquetes **`LCL`** y **`openai_core`**.

---

## 4. Requisitos

### Lazarus / Free Pascal

- Lazarus instalado.
- Paquete **`openai_core`** disponible en la ruta del proyecto.
- Proyecto abierto desde **`python_demo.lpi`**.

### Python

El componente está configurado para aceptar Python **3.8 hasta 3.14**.

La arquitectura debe coincidir:

| Aplicación compilada | Python requerido |
|---|---|
| Windows 64 bits | Python 64 bits |
| Windows 32 bits | Python 32 bits |
| Linux 64 bits | `libpython`/`python3` 64 bits |
| Linux ARM/ARM64 | `libpython`/`python3` de la misma arquitectura |

Para el modo **DLL/SO**, instala también la biblioteca de desarrollo de Python cuando sea necesario.

Ejemplo en Debian/Ubuntu:

```bash
sudo apt install python3 python3-dev libpython3-dev
```

---

## 5. Cómo compilar

1. Abre Lazarus.
2. Abre el archivo:

```text
pacote/samples/AI/python_demo/python_demo.lpi
```

3. Compila con:

```text
Run > Build
```

o presiona:

```text
Ctrl + F9
```

4. Ejecuta el binario generado:

- Windows: `python_demo.exe`
- Linux: `python_demo`

---

## 6. Cómo usar

1. Selecciona una DLL, SO o ejecutable Python en la lista.
2. Mantén **Usar Proceso Externo** marcado para la primera prueba.
3. Haz clic en **Activar intérprete Python**.
4. Revisa el panel **Logs de Operaciones**.
5. Ejecuta el script predeterminado o escribe tu propio script en el memo.
6. Usa **SetVar**, **GetVar** y **Eval** para probar el intercambio de datos entre Pascal y Python.

---

## 7. Prueba rápida recomendada

### Script

Pega esto en el memo de script:

```python
x = 10
print("Hello from Python")
print("x =", x)
```

Haz clic en **Ejecutar Script en Python**.

### Leer una variable

En **Nombre Variable**, informa:

```text
x
```

Haz clic en **GetVar**.

Valor esperado:

```text
10
```

### Evaluar una expresión

En el campo de expresión, usa:

```python
x + 50
```

Resultado esperado:

```text
60
```

### Atención sobre `SetVar`

Actualmente, **`SetVar` guarda valores como string**. Si usas:

```text
Nombre: y
Valor: 10
```

usa esta expresión en Eval:

```python
int(y) + 50
```

en lugar de:

```python
y + 50
```

---

## 8. Modos de ejecución

### `pemProcess` — Proceso externo

Es el modo recomendado para empezar.

Ventajas:

- Aísla mejor Python del proceso Lazarus.
- Reduce bloqueos causados por conflictos de DLL/SO.
- Es un mejor punto de partida para bibliotecas pesadas como TensorFlow, OpenCV, Torch o Keras.
- Usa `python.exe`, `python3.exe`, `python3` u otro ejecutable encontrado en el sistema.

### `pemDLL` — Biblioteca dinámica

Carga Python directamente dentro del proceso de la aplicación.

Ventajas:

- Integración más directa con la API C de Python.
- Puede ser más rápido para llamadas simples.

Cuidados:

- La arquitectura debe coincidir exactamente.
- La biblioteca debe exportar las funciones obligatorias de la API C.
- Un fallo en la biblioteca Python puede cerrar el proceso Lazarus.

---

## 9. Diagnóstico

Al activar Python, el sample imprime un informe en el panel de logs con:

- sistema operativo detectado;
- arquitectura de Lazarus;
- modo de ejecución;
- ruta configurada;
- biblioteca o ejecutable cargado;
- versión de Python;
- compatibilidad de arquitectura;
- funciones obligatorias encontradas;
- última etapa de carga;
- último error, si existe.

Usa este informe antes de concluir que el componente falló. La mayoría de los problemas vienen de arquitectura incompatible, biblioteca ausente o Python fuera del PATH.

---

## 10. Problemas comunes

| Síntoma | Causa probable | Corrección |
|---|---|---|
| `Failed to load python3.dll` | Python no instalado, DLL ausente o arquitectura incorrecta | Instala Python con la misma arquitectura del ejecutable |
| `Failed to load libpython` | Falta el paquete de desarrollo en Linux | Instala `python3-dev`/`libpython3-dev` |
| Python activa, pero `GetVar` falla | Funciones opcionales de la API C no disponibles en modo DLL | Prueba con `pemProcess` |
| `y + 50` falla después de `SetVar` | `SetVar` inyecta string | Usa `int(y) + 50` o define `y = 10` en el script |
| No aparece salida | El script no usa `print` o falló la ejecución | Revisa `LastError` y el log |
| Funciona en terminal, pero no en Lazarus | PATH diferente dentro de la IDE | Usa la ruta absoluta de Python |

---

## 11. Buenas prácticas

- Prueba primero con **`pemProcess`**.
- Usa **`pemDLL`** solo cuando necesites integración directa con la API C.
- Mantén Python y Lazarus en la misma arquitectura.
- Para distribución, organiza el runtime Python dentro de la carpeta de la aplicación o en una subcarpeta `libs`.
- Copia siempre el informe de diagnóstico al reportar un error.
- Evita scripts largos directamente en el memo; crea pruebas cortas e incrementales.

---

## 12. Relación con el proyecto CHATGPT

Este sample valida el puente Lazarus ↔ Python. Prepara la base para otros componentes del proyecto que dependen de Python, como:

- clasificación de imágenes;
- modelos CNN;
- YOLO;
- OpenCV;
- detección facial;
- procesamiento de audio;
- bibliotecas de machine learning.

Antes de investigar errores en componentes de IA más complejos, ejecuta este sample para confirmar que Python carga correctamente.

---

## 13. Mejoras futuras sugeridas

- Agregar un botón para localizar manualmente `python.exe`, `python3`, DLL, SO o dylib.
- Mostrar claramente si el elemento seleccionado es ejecutable o biblioteca.
- Separar la interfaz en pestañas: Configuración, Script, Variables, Eval y Diagnóstico.
- Agregar botón **Copiar diagnóstico**.
- Guardar la última configuración usada.
- Validar previamente si el archivo seleccionado existe.
- Mostrar aviso cuando `SetVar` se use con valor numérico, explicando que será tratado como string.

---

## 14. Resumen

**`python_demo`** es la primera prueba recomendada para cualquier integración Python dentro del paquete CHATGPT. Si este sample activa el intérprete, ejecuta scripts, lee variables y evalúa expresiones, la base de integración Python está funcionando.