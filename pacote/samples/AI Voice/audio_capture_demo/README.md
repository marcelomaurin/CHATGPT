# Audio Capture Demo (aiaudio)

Este é um projeto de demonstração com interface gráfica (GUI) desenvolvido em Lazarus que demonstra o uso do componente `TAIAudioInput` da unidade `aiaudio` (integrante do pacote da suíte de IA).

O projeto ilustra a captura de áudio a partir de dispositivos físicos de entrada de som ou em modo de simulação, salvando o resultado em um arquivo de áudio WAV.

## 🛠️ Recursos Ilustrados

O projeto configura e exercita os seguintes aspectos do componente `TAIAudioInput`:

### Propriedades Utilizadas
* **`SampleRate`**: Define a taxa de amostragem do áudio capturado (configurado como `16000` Hz).
* **`Channels`**: Define o número de canais de áudio (configurado como `1` - Mono).
* **`Recording`**: Propriedade booleana de leitura para verificar se a gravação de áudio está ativa no momento.

### Métodos Chamados
* **`StartRecord(const AFileName: string)`**: Inicia a gravação física ou simulada de áudio, salvando os dados no arquivo especificado (padrão: `voice_rec.wav`).
* **`StopRecord`**: Interrompe a gravação e finaliza a gravação do arquivo de áudio.

## ⚙️ Interface e Funcionalidades

A aplicação GUI oferece:
1. **Configuração de Arquivo de Saída**: Campo interativo para definir o nome do arquivo wave (padrão: `voice_rec.wav`).
2. **Modo de Simulação (`chkSimulation`)**:
   - **Ativo (Padrão)**: Executa o fluxo lógico simulando a gravação de áudio sem exigir uma placa de som ou microfone conectado. Ideal para testes rápidos ou ambientes sem hardware de entrada de áudio.
   - **Inativo**: Tenta conectar ao driver de som físico para iniciar uma gravação real utilizando o microfone padrão do sistema operacional.
3. **Log de Eventos**: Área visual de terminal (`TMemo`) que acompanha todas as etapas do processo, propriedades configuradas e status detalhado da operação.

## 🚀 Como Compilar e Executar

1. Abra o arquivo do projeto `audio_capture_demo.lpi` no Lazarus.
2. Certifique-se de que os pacotes necessários estão instalados e referenciados no Lazarus (especialmente o pacote contendo `aiaudio` e `aibase`).
3. Compile o projeto pressionando `Ctrl + F9` ou execute-o (`F9`).
4. Utilize a interface visual para testar o comportamento em modo Simulação ou Real.
