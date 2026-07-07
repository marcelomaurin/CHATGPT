# Status e Maturidade dos Componentes - Lazarus AI Suite

Este documento descreve o estado atual de maturidade, a categoria operacional e observações cruciais sobre os componentes da suíte de Inteligência Artificial do Lazarus.

> [!WARNING]
> **Restrição de Arquitetura (64-bit Only)**: O processamento de Visão Computacional (especialmente a bridge do MediaPipe em `TAIHumanPoseDetector`) suporta exclusivamente plataformas de **64-bit** (Windows 64-bit e Linux 64-bit). Em plataformas de 32-bit, o componente é compilado com sucesso mas reporta-se indisponível (`Available = False`) em tempo de execução para evitar quebras no build da suíte.

| Componente | Categoria | Status | Observação / Compatibilidade |
| :--- | :--- | :--- | :--- |
| **TCHATGPT** | `ccModel` | Beta/Estável | Conector principal para APIs compatíveis com OpenAI. Estável para envio de mensagens e integração de modelos. |
| **TAIGraphMap** | `ccModel` | Beta | Classificador textual local e explicável baseado em mapa de grafos ponderado de tokens. |
| **TAIProject** | `ccProject` | Beta | Coordenador central de projetos de IA. Permite carregar e salvar configurações em JSON, omitindo tokens/senhas por padrão para segurança de chaves. |
| **TAIPipeline** | `ccOther` | Beta | Gerenciador de esteiras integrando Entrada (Input), Redes Neurais (ML) e Saída (Output). Suporta execução de agentes, relatórios e monitoramento de telemetria industrial. |
| **TAIPromptBuilder**| `ccOther` | Beta | Construtor de prompts que varre formulários e componentes. Suporta múltiplos idiomas (Português, Inglês, Espanhol), múltiplos formatos de saída (Texto, Markdown estruturado, JSON) e inspeção de propriedades via RTTI. |
| **TAIAgentSafety** | `ccSafety` | Beta | Camada de segurança estrita. Valida caminhos (prevenindo Directory Traversal e checando prefixos normalizados), domínios, portas e ações. Implementa confirmação interativa de ação (`OnConfirmAction`). |
| **TAIAgent** | `ccAction` | Experimental | Agente autônomo baseado em decisões. Delega execuções de recursos a executores modulares externos (`aiagent_executors.pas`) e valida dados injetados via RTTI. |
| **TAIOutputDocs** | `ccOutput` | Beta | Gerador unificado de relatórios nos formatos PDF, Word, Excel e TXT. |
| **TAIPDFOutput** | `ccOutput` | Beta | Gera documentos nativos no formato PDF através do pacote FCL-PDF. |
| **TAIWordOutput** | `ccOutput` | Beta | Gera arquivos `.docx`. **Nota de Compatibilidade:** O arquivo gerado é estruturado em HTML compatível com Microsoft Word/LibreOffice Writer para formatação rica sem dependências complexas. |
| **TAIExcelOutput** | `ccOutput` | Beta | Gera planilhas `.xlsx`. **Nota de Compatibilidade:** As planilhas geradas utilizam marcação XML/HTML perfeitamente compatível e interpretável pelo Excel/LibreOffice Calc. |
| **TAITXTOutput** | `ccOutput` | Beta | Geração de arquivos de texto plano simplificados. |
| **TAIModbusClient** | `ccInput` | Experimental | Cliente para comunicação industrial Modbus (TCP/RTU). Permite monitorar registradores físicos. |
| **TAIUSB** / **TAIListUSBDevices** | `ccInput` | Beta | Lista e monitora a conexão de dispositivos USB locais. Utiliza consulta nativa ao registro no Windows para compatibilidade total e SysFS no Linux. |
| **TAIKinectSensor** | `ccInput` | Experimental | Componente hub para conectar o sensor Microsoft Kinect v1 (Xbox 360). Controla motor de inclinação, LED e acelerômetro. |
| **TAIKinectColorStream** | `ccInput` | Experimental | Fluxo de vídeo RGB/IR em tempo real do sensor Kinect. |
| **TAIKinectDepthStream** | `ccInput` | Experimental | Fluxo de profundidade em milímetros com exportador PLY de nuvem de pontos do Kinect. |
| **TAIKinectSkeleton** | `ccInput` | Experimental | Stub para rastreamento de esqueleto corporal do Kinect. |
| **TAIKinectAudio** | `ccInput` | Experimental | Stub para captura de áudio e beamforming (direção de som) do Kinect. |
| **TAIMQTTClient** | `ccInput` | Experimental | Cliente leve IoT baseada em MQTT para publicação e recebimento de tópicos em tempo real com thread dedicada. |
| **TAIIndustrialBridge**| `ccInput`| Experimental | Ponte de baixo nível para integração com PLCs Siemens/Profinet/Profibus. |
| **TAIVoiceSynthesizer**| `ccOutput`| Experimental | Sintetizador de voz de texto para fala (usando APIs nativas do SO). |
| **TAIHumanPoseDetector**| `ccVision`| Estável (64-bit) | Detector de pose corporal real integrado (MediaPipe 0.10.35). Pipeline nativo (Lazarus → DLL → Python Worker) completo e validado, com 33 landmarks corporais reais e simulação integrada. Totalmente funcional com zero vazamento de memória. Disponível apenas em 64-bit. |
| **TAIDiskTreeScanner** | `ccFiles` | Beta | Escaneador assíncrono de árvore de diretórios local para datasets. |
| **TAI_DOCFILESMANAGER** | `ccFiles` | Beta | Gerenciador físico de arquivos e documentações locais (AI Files). |
| **TGrayscaleFilter** | `ccImage` | Estável | Filtro de imagem nativo para escala de cinza. |
| **TNegativeFilter** | `ccImage` | Estável | Filtro de imagem nativo para inversão de cores. |
| **TBrightnessContrastFilter**| `ccImage` | Estável | Filtro de imagem nativo para ajuste de brilho e contraste. |
| **TBinarizationFilter**| `ccImage` | Estável | Filtro de imagem nativo para binarização/limiarização. |
| **TBlurFilter** | `ccImage` | Estável | Filtro de imagem nativo para desfoque. |
| **TSharpenFilter** | `ccImage` | Estável | Filtro de imagem nativo para nitidez. |
| **TSobelFilter** | `ccImage` | Estável | Filtro de imagem nativo para detecção de bordas Sobel. |
| **TErosionDilationFilter**| `ccImage` | Estável | Filtros morfológicos nativos de erosão e dilatação. |
| **TAIPostgreSQLDictionary** | `ccDBase` | Beta | Gerador de dicionário de metadados de bancos PostgreSQL para prompts de IA. |
| **TAISQLiteDictionary** | `ccDBase` | Beta | Gerador de dicionário de metadados de bancos SQLite para prompts de IA. |

## Compatibilidade de Formatos Documentais

> [!IMPORTANT]
> Os componentes **TAIWordOutput** e **TAIExcelOutput** geram arquivos utilizando extensões nativas `.docx` e `.xlsx`. Entretanto, a estrutura interna dos dados gravados é formatada em **HTML/XML compatível**.
> Isso garante que os aplicativos de escritório (Microsoft Office, LibreOffice e Google Docs) consigam abrir e renderizar os arquivos com formatação, tabelas e estilos sem a necessidade de incluir bibliotecas nativas pesadas no executável Lazarus.
