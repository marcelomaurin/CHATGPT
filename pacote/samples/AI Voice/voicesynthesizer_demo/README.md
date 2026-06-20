# Voice Synthesizer Demo (voicesynthesizer_demo)

![Voice Synthesizer Demo Screenshot](../../../../screenshots/voicesynthesizer_demo.jpg)

Este exemplo demonstra o uso do componente **`TAIVoiceSynthesizer`**, um sintetizador de voz nativo, puro e multiplataforma de alta performance para Lazarus/Delphi.

---

## 🚀 Funcionalidades

1. **Escolha de Sintetizador**: Caixa de listagem para selecionar dinamicamente a tecnologia desejada:
   * **SAPI (Windows)**: Comunicação direta com a API nativa da Microsoft via COM/ActiveX.
   * **eSpeak**: Ligação dinâmica e direta de alta performance com a biblioteca C eSpeak (`libespeak` / `espeak-ng`).
2. **Escolha de Voz/Narrador**: Caixa de listagem preenchida dinamicamente em tempo real com todas as vozes (narradores) atualmente instaladas no seu sistema operacional para a engine selecionada.
3. **Controle Fino de Volume**: Barra deslizante (TrackBar) regulando a intensidade da voz de `0` a `100%`.
4. **Controle de Velocidade (Rate)**: Barra deslizante regulando o ritmo da fala de `-10` a `10`.
5. **Reprodução Assíncrona**: CheckBox para ligar a execução assíncrona. Quando selecionada, a fala roda em thread secundária, impedindo que a interface gráfica (UI) do aplicativo trave.
6. **Logs em Tempo Real**: Histórico detalhado registrando comandos COM, inicializações de bibliotecas e tempos de resposta.

---

## 🛠️ Como Funciona

* **No Windows (SAPI)**: Utiliza a tecnologia COM Automation instanciando o objeto `SAPI.SpVoice` e obtendo sua coleção de tokens de vozes através do método `GetVoices`.
* **No Linux/Windows (eSpeak)**: Carrega dinamicamente a biblioteca compartilhada via `DynLibs`, usando a função de API `espeak_ListVoices` para recuperar a lista de narradores.

O componente gerencia inteligentemente o escopo e o tempo de vida do objeto COM para garantir que narrações assíncronas rodem em threads segundas sem sofrer garbage collection precoce do sistema operacional.

---

## 💻 Como Compilar e Executar

1. Abra o arquivo **`voicesynthesizer_demo.lpi`** no Lazarus IDE.
2. Certifique-se de que o pacote `openai_core.lpk` está instalado na sua IDE.
3. No menu principal, clique em **Run > Run** (ou pressione `F9`).
4. **Linux**: Certifique-se de ter o `libespeak-ng.so` ou `libespeak.so` instalado (`sudo apt install libespeak-ng1`).
