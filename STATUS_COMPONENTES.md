# Status e Maturidade dos Componentes - Lazarus AI Suite

Este documento descreve o estado atual de maturidade, a categoria operacional e observações cruciais sobre os componentes da suíte de Inteligência Artificial do Lazarus.

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
| **TAIMQTTClient** | `ccInput` | Experimental | Cliente leve IoT baseada em MQTT para publicação e recebimento de tópicos em tempo real com thread dedicada. |
| **TAIIndustrialBridge**| `ccInput`| Experimental | Ponte de baixo nível para integração com PLCs Siemens/Profinet/Profibus. |
| **TAIVoiceSynthesizer**| `ccOutput`| Experimental | Sintetizador de voz de texto para fala (usando APIs nativas do SO). |

## Compatibilidade de Formatos Documentais

> [!IMPORTANT]
> Os componentes **TAIWordOutput** e **TAIExcelOutput** geram arquivos utilizando extensões nativas `.docx` e `.xlsx`. Entretanto, a estrutura interna dos dados gravados é formatada em **HTML/XML compatível**.
> Isso garante que os aplicativos de escritório (Microsoft Office, LibreOffice e Google Docs) consigam abrir e renderizar os arquivos com formatação, tabelas e estilos sem a necessidade de incluir bibliotecas nativas pesadas no executável Lazarus.
