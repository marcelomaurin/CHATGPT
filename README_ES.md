# TCHATGPT — Suite de Componentes de IA para Lazarus

🌍 **Idiomas / Languages:**
*   [Português (PT)](README.md)
*   [English (EN)](README_EN.md)
*   [Español (ES)](README_ES.md)
*   [Français (FR)](README_FR.md)
*   [Italiano (IT)](README_IT.md)
*   [العربية (AR)](README_AR.md)

---

[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)
[![Lazarus](https://img.shields.io/badge/Lazarus-3.x-orange.svg)](https://www.lazarus-ide.org/)

Una suite completa de componentes visuales y no visuales para Free Pascal / Lazarus diseñada para integrar **IA generativa y aprendizaje automático (Machine Learning)** de forma nativa en sus aplicaciones. Soporta **OpenAI (ChatGPT)**, **Google Gemini**, **Anthropic Claude**, **OpenRouter**, **Cerebras**, **modelos locales a través de Ollama** y redes neuronales locales.

---

## 📦 Componentes Incluidos en el Paquete

La suite instala en la paleta de componentes de Lazarus (pestaña **IA**) las siguientes herramientas:

### 1. `TCHATGPT` (Conector de APIs de IA)
El motor principal para LLMs. Permite enviar preguntas y recibir respuestas estructuradas de proveedores globales o locales.
- **Proveedores Soportados**: OpenAI, Gemini, Claude, OpenRouter, Cerebras y Ollama/Local.
- **Características**: Control de Max Tokens, System/Developer Prompts, temperatura y modelos personalizados.

### 2. `TNeuralNetwork` (Red Neural Multicapa)
Un Perceptrón Multicapa (MLP) escrito en **Pascal puro**, lo que permite crear y entrenar modelos de red neural localmente sin dependencias externas.
- **Funciones de Activación Integradas**: Sigmoide (`atSigmoid`), ReLU (`atReLU`), Tanh (`atTanh`) y Personalizada (`atCustom` a través de eventos).
- **Entrenamiento por Épocas**: El método `TrainEpochs` entrena el modelo a partir de una matriz de dataset y calcula la pérdida por error cuadrático medio (MSE Loss).
- **Persistencia**: Guarda y carga rápidamente pesos y sesgos (`SaveNetwork` / `LoadNetwork`).

### 3. `TAICodeAssistant` (Asistente de Código)
Un asistente virtual orientado a desarrolladores. Se asocia con el componente `TCHATGPT` configurado para automatizar tareas comunes de programación:
- **`OptimizeCode(ACode)`**: Optimiza el rendimiento y legibilidad de rutinas.
- **`FindBugs(ACode)`**: Busca errores lógicos, fugas y sugiere correcciones.
- **`DocumentCode(ACode)`**: Añade comentarios XML/Javadoc estructurados.
- **`GenerateUnitTests(ACode)`**: Escribe pruebas unitarias exhaustivas utilizando marcos como `FPCUnit`.
- **`TranslateCode(ACode, De, Para)`**: Traduce códigos entre lenguajes (por ejemplo, C# a Pascal).
- **`ExplainCode(ACode)`**: Explica el funcionamiento de un algoritmo paso a paso.

### 4. `TAIDatasetGenerator` (Generador de Datasets de Entrenamiento)
Un facilitador para la preparación de datos. Ayuda a generar archivos para Fine-Tuning de LLMs o conjuntos de datos para la red neural local:
- **Fine-Tuning**: Exporta conversaciones en el formato estándar **JSONL** (JSON Lines) aceptado por OpenAI y Ollama.
- **Integración de Red Neural**: Exporta datos en **CSV** y carga archivos CSV delimitados directamente a matrices de entrada y salida (`TMatrix`) compatibles con `TNeuralNetwork.TrainEpochs`.

### 5. `TTokenList` (Tokenizador auxiliar)
Utilidad para analizar y contar cadenas en listas estructuradas de tokens.

---

## Inicio Rápido (Asistente de Código)

```pascal
uses chatgpt, aicodeassistant;

var
  FChatgpt: TCHATGPT;
  FAssistant: TAICodeAssistant;
  CodigoOptimizado: string;
begin
  FChatgpt := TCHATGPT.Create(nil);
  FAssistant := TAICodeAssistant.Create(nil);
  try
    FChatgpt.TOKEN := 'sk-TU_CLAVE_AQUI';
    FChatgpt.Provider := AIP_CLAUDE;          // Configura Anthropic Claude
    FChatgpt.TipoChat := VCT_CLAUDE_35_SONNET;
    
    FAssistant.ChatGPT := FChatgpt; // Asocia el conector de IA
    
    CodigoOptimizado := FAssistant.OptimizeCode('procedure TForm1.Click; begin i := i + 1; end;');
    ShowMessage(CodigoOptimizado);
  finally
    FAssistant.Free;
    FChatgpt.Free;
  end;
end;
```

---

## Entrenamiento Local (`TNeuralNetwork` & `TAIDatasetGenerator`)

```pascal
var
  FNet: TNeuralNetwork;
  FGen: TAIDatasetGenerator;
  Inputs, Targets: TMatrix;
  Loss: Double;
begin
  FNet := TNeuralNetwork.Create(nil);
  FGen := TAIDatasetGenerator.Create(nil);
  try
    // Carga datos de entrenamiento directamente desde un archivo CSV
    FGen.LoadFromCSV('datos.csv', Inputs, Targets, 2, 1); // 2 Entradas, 1 Salida

    // Inicializa la red neural: 2 Entradas, 4 Ocultas, 1 Salida, Learning Rate = 0.05
    FNet.Initialize(2, 4, 1, 0.05);
    FNet.ActivationType := atSigmoid;

    // Ejecuta el bucle de entrenamiento sobre el dataset por 1000 épocas
    FNet.TrainEpochs(Inputs, Targets, 1000, Loss);
    ShowMessage(Format('¡Entrenamiento completado! Pérdida MSE Final: %0.6f', [Loss]));

    FNet.SaveNetwork('modelo.net');
  finally
    FGen.Free;
    FNet.Free;
  end;
end;
```

---

## Proveedores Soportados (LLMs)

| Proveedor | Enum | Endpoint | Token Requerido |
|---|---|---|---|
| OpenAI | `AIP_OPENAI` | `api.openai.com` | Sí |
| OpenRouter | `AIP_OPENROUTER` | `openrouter.ai` | Sí |
| Cerebras | `AIP_CEREBRAS` | `api.cerebras.ai` | Sí |
| Google Gemini | `AIP_GEMINI` | `generativelanguage.googleapis.com` | Sí |
| Anthropic Claude | `AIP_CLAUDE` | `api.anthropic.com` | Sí |
| Local (Ollama) | `AIP_LOCAL` | `localhost:11434` | No |

---

## Instalación del Paquete en Lazarus

1. En Lazarus IDE, vaya a **Paquete > Abrir archivo de paquete (.lpk)**
2. Navegue a la carpeta `pacote/` y seleccione **`openai.lpk`**
3. Haga clic en **Compilar** para compilar el paquete
4. Haga clic en **Usar > Instalar** — Lazarus solicitará reconstruir la IDE
5. Después de reiniciar, los 5 componentes estarán disponibles en la pestaña **IA** de la paleta de componentes.

---

## Requisitos de Bibliotecas (Windows)

Para que la comunicación HTTPS funcione en Windows, las DLLs de OpenSSL adecuadas para la arquitectura de su aplicación (32-bit o 64-bit) deben estar accesibles. La suite ya incluye las DLLs en la carpeta `pacote/lib/`:

*   **Aplicaciones de 32-bit (i386-win32)**: `pacote/lib/i386-win32/`
    - `libcrypto-1_1.dll`, `libssl-1_1.dll`
*   **Aplicaciones de 64-bit (x86_64-win64)**: `pacote/lib/x86_64-win64/`
    - `libcrypto.dll`, `libssl-1_1-x64.dll`

**Recomendación:** Copie las DLLs de la carpeta `lib/` correspondiente a la **misma carpeta de su ejecutable compilado**.

---

## Licencia

Este proyecto está licenciado bajo la [Licencia Pública General de GNU v3.0](LICENSE).
