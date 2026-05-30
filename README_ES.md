# TCHATGPT — Componente Lazarus para Integración con APIs de IA

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

Componente visual para Free Pascal / Lazarus que permite enviar preguntas y recibir respuestas de múltiples proveedores de IA, incluyendo **OpenAI (ChatGPT)**, **OpenRouter**, **Cerebras** y **modelos locales a través de Ollama**.

## Características

- ✅ Soporte para múltiples proveedores (OpenAI, OpenRouter, Cerebras, Ollama/Local)
- ✅ Selección de modelo por enum o nombre personalizado
- ✅ Comunicación a través de HTTPS con `TFPHttpClient` (sin dependencias de Indy)
- ✅ Instalación como componente en la paleta de Lazarus (pestaña **IA**)
- ✅ Componentes auxiliares incluidos: `TNeuralNetwork` y `TTokenList`
- ✅ Licencia GPL v3

---

## Inicio Rápido

```pascal
uses chatgpt;

var
  FChatgpt: TCHATGPT;
begin
  FChatgpt := TCHATGPT.Create(nil);
  try
    FChatgpt.TOKEN := 'sk-TU_CLAVE_AQUI';
    FChatgpt.Provider := AIP_OPENAI;       // OpenAI, OpenRouter, Cerebras o Local
    FChatgpt.TipoChat := VCT_GPT4o;        // Modelo deseado
    FChatgpt.MaxTokens := 4096;            // Límite de tokens en la respuesta

    if FChatgpt.SendQuestion('¿Cuál es la capital de España?') then
      ShowMessage(FChatgpt.Response)
    else
      ShowMessage('Error: ' + FChatgpt.Response);
  finally
    FChatgpt.Free;
  end;
end;
```

---

## Proveedores Soportados

| Proveedor | Enum | Endpoint | Token Requerido |
|---|---|---|---|
| OpenAI | `AIP_OPENAI` | `api.openai.com` | Sí |
| OpenRouter | `AIP_OPENROUTER` | `openrouter.ai` | Sí |
| Cerebras | `AIP_CEREBRAS` | `api.cerebras.ai` | Sí |
| Local (Ollama) | `AIP_LOCAL` | `localhost:11434` | No |

---

## Modelos Disponibles

### OpenAI
| Enum | Modelo de API |
|---|---|
| `VCT_GPT35TURBO` | `gpt-3.5-turbo` |
| `VCT_GPT40` | `gpt-4` |
| `VCT_GPT40_TURBO` | `gpt-4-turbo-preview` |
| `VCT_GPT4o` | `gpt-4o` |
| `VCT_GPTo3_mini` | `o3-mini` |
| `VCT_GPT41` | `gpt-4.1` |
| `VCT_GPT41_MINI` | `gpt-4.1-mini` |
| `VCT_GPT5` | `gpt-5` |

### Ollama / Local
| Enum | Modelo |
|---|---|
| `VCT_LLAMA32_3B` | `llama3.2:3b` |
| `VCT_QWEN25_15B` | `qwen2.5:1.5b` |
| `VCT_DEEPSEEK_R1_15B` | `deepseek-r1:1.5b` |
| `VCT_DEEPSEEK_R1_8B` | `deepseek-r1:8b` |
| `VCT_DEEPSEEK_R1_14B` | `deepseek-r1:14b` |
| `VCT_DEEPSEEK_R1_70B` | `deepseek-r1:70b` |

> Para usar cualquier otro modelo, defina `FChatgpt.CustomModel := 'nombre-del-modelo';`

---

## Propiedades

| Propiedad | Tipo | Descripción |
|---|---|---|
| `TOKEN` | `WideString` | Clave API del proveedor |
| `Provider` | `TAIProvider` | Proveedor de IA (OpenAI, OpenRouter, Cerebras, Local) |
| `TipoChat` | `TVersionChat` | Modelo de IA seleccionado |
| `CustomModel` | `WideString` | Nombre del modelo personalizado (sobrescribe TipoChat) |
| `LocalIP` | `WideString` | URL del servidor local de Ollama (por defecto: `http://localhost:11434`) |
| `MaxTokens` | `Integer` | Límite de tokens en la respuesta (por defecto: 4096) |
| `Dev` | `WideString` | Prompt del sistema (por defecto: "Você é um assistente.") |
| `Response` | `WideString` | Respuesta a la última pregunta |
| `Question` | `WideString` | Última pregunta enviada (solo lectura) |
| `LastJSON` | `WideString` | JSON crudo de la última respuesta (solo lectura) |
| `OpenRouterTitle` | `WideString` | Título de la aplicación (encabezado para OpenRouter) |
| `OpenRouterSite` | `WideString` | URL del sitio (encabezado HTTP-Referer para OpenRouter) |

---

## Ejemplo con Ollama Local

```pascal
FChatgpt := TCHATGPT.Create(nil);
try
  FChatgpt.Provider := AIP_LOCAL;
  FChatgpt.TipoChat := VCT_DEEPSEEK_R1_8B;
  FChatgpt.LocalIP := 'http://192.168.1.100:11434';  // IP del Servidor

  if FChatgpt.SendQuestion('Explica el concepto de recursividad.') then
    Memo1.Text := FChatgpt.Response;
finally
  FChatgpt.Free;
end;
```

---

## Instalación del Paquete en Lazarus

1. En Lazarus IDE, vaya a **Paquete > Abrir archivo de paquete (.lpk)**
2. Navegue a la carpeta `pacote/` y seleccione **`openai.lpk`**
3. Haga clic en **Compilar** para compilar el paquete
4. Haga clic en **Usar > Instalar** — Lazarus solicitará reconstruir la IDE
5. Después de reiniciar, los componentes estarán disponibles en la pestaña **IA** de la paleta de componentes:
   - `TCHATGPT`
   - `TNeuralNetwork`
   - `TTokenList`

---

## Requisitos de Bibliotecas (Windows)

Para que la comunicación HTTPS funcione en Windows, las siguientes DLLs de OpenSSL deben ser accesibles para la aplicación:

- `libcrypto-1_1.dll`
- `libssl-1_1.dll`
- `libssl-1_1-x64.dll` (64 bits)

**Recomendación:** Copie estas DLLs en la **misma carpeta del ejecutable de su aplicación** (no en `System32`).

Las DLLs se incluyen en la raíz de este repositorio para su conveniencia.

---

## Estructura del Proyecto

```
CHATGPT/
├── chatgpt.pas           # Componente principal TCHATGPT
├── funcoes.pas           # Funciones auxiliares
├── pacote/
│   ├── openai.lpk        # Paquete de Lazarus para la instalación
│   ├── chatgpt.pas       # Copia sincronizada del componente
│   ├── neuralnetwork.pas  # Componente TNeuralNetwork (red neuronal simple)
│   ├── tokenizer.pas     # Componente TTokenList (tokenizador auxiliar)
│   └── funcoes.pas       # Copia sincronizada de funciones auxiliares
├── demo/
│   ├── demo1.lpr         # Aplicación de demostración
│   └── main.pas          # Formulario principal de la demostración
├── tools/
│   └── script/           # Scripts de soporte (tokenizador en Python)
├── dicionario/           # Diccionario PT-BR
├── LICENSE               # Licencia GPL v3
└── README.md             # Documentación en portugués
```

---

## Aplicación de Demostración

Una aplicación de demostración completa está disponible en la carpeta `demo/`. Para ejecutarla:

1. Abra `demo/demo1.lpi` en Lazarus
2. Compile y ejecute
3. Introduzca su clave API en el campo correspondiente
4. Escriba su pregunta y haga clic en **Submit** o presione **Enter**

---

## Aviso Importante

El uso de proveedores en la nube como OpenAI, OpenRouter o Cerebras requiere una **suscripción activa** y créditos disponibles. El uso con **Ollama local** no requiere ninguna clave API.

---

## Referencias

- [Documentación de la API de OpenAI](https://platform.openai.com/docs/)
- [OpenRouter](https://openrouter.ai/)
- [Ollama](https://ollama.ai/)
- [Cerebras](https://www.cerebras.ai/)
- [Diccionario de Palabras PT-BR](https://github.com/j0aoarthur/Palavras-PT-BR)

---

## Licencia

Este proyecto está licenciado bajo la [Licencia Pública General de GNU v3.0](LICENSE).
