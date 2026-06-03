# TCHATGPT — AI Component Suite for Lazarus / Free Pascal

🌍 **Languages / Idiomas**

* [Português (PT-BR)](README.md)
* [English (EN)](README_EN.md)
* [Español (ES)](README_ES.md)
* [Français (FR)](README_FR.md)
* [Italiano (IT)](README_IT.md)
* [العربية (AR)](README_AR.md)

---

[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)
[![Lazarus](https://img.shields.io/badge/Lazarus-3.x-orange.svg)](https://www.lazarus-ide.org/)
[![Free Pascal](https://img.shields.io/badge/Free%20Pascal-FPC-blue.svg)](https://www.freepascal.org/)
[![Status](https://img.shields.io/badge/status-in%20development-yellow.svg)]()

---

## Visão Geral

**TCHATGPT** é uma suíte open source de componentes visuais e não visuais para **Lazarus / Free Pascal**, criada para facilitar a integração de recursos de Inteligência Artificial em aplicações desktop, industriais, educacionais e corporativas.

O projeto oferece componentes para conexão com provedores de LLM, modelos locais, processamento de dados, aprendizado de máquina, voz, imagem, agentes, grafos, entrada e saída de informações, além de componentes experimentais para visão computacional e recursos gráficos 3D.

> Este projeto deve ser entendido como uma **suíte de componentes para integração de IA em aplicações Lazarus**, e não como uma plataforma completa de IA pronta para substituir frameworks especializados de treinamento, MLOps ou implantação em larga escala.

---

## Objetivo do Projeto

O objetivo principal é permitir que desenvolvedores Lazarus / Free Pascal consigam incorporar IA em seus sistemas de forma simples, reutilizável e componentizada.

A suíte busca atender cenários como:

* criação de assistentes com IA generativa;
* integração com APIs de LLM;
* uso de modelos locais via servidores compatíveis;
* geração e análise de datasets;
* classificação simples de textos;
* automação com agentes;
* síntese de voz;
* processamento básico de imagens;
* filtros digitais de som;
* integração com dispositivos, sensores e canais externos;
* prototipação de aplicações com IA em Lazarus.

---

## Estado Atual do Projeto

O projeto está em desenvolvimento ativo e possui componentes em diferentes níveis de maturidade.

### Componentes mais consolidados

* `TCHATGPT`
* `TAIBaseComponent`
* `TNeuralNetwork`
* `TTokenList`
* `TAICodeAssistant`
* `TAIDatasetGenerator`
* `TAIVoiceSynthesizer`
* filtros de imagem
* filtros sonoros
* componentes de grafo e dataset

### Componentes experimentais ou em evolução

* integração com Python;
* componentes CNN, YOLO, LSTM e SOM;
* componentes de agentes autônomos;
* componentes de entrada e saída avançados;
* componentes OpenCV;
* visualização 3D;
* integração com Tripo3D;
* componentes industriais, câmera, áudio, browser, MQTT, Modbus e CFTV.

---

## Abas de Componentes do Pacote

O pacote instala componentes na paleta do Lazarus, organizados por área funcional.

---

## AI Core

Componentes principais de IA generativa, machine learning e suporte ao projeto.

### `TCHATGPT`

Conector principal para provedores de IA generativa.

Permite enviar perguntas, configurar provedores, escolher modelos e receber respostas estruturadas.

Provedores previstos:

* OpenAI;
* Google Gemini;
* Anthropic Claude;
* OpenRouter;
* Cerebras;
* servidor local compatível com `/v1/chat/completions`;
* Ollama ou serviços locais similares.

### `TNeuralNetwork`

Rede neural multicamadas simples implementada em Pascal.

Permite:

* criar redes locais;
* configurar entradas, camadas ocultas e saídas;
* treinar por épocas;
* calcular erro;
* salvar e carregar modelo.

### `TTokenList`

Componente utilitário para tokenização simples de texto.

Pode ser usado em:

* classificação;
* análise textual;
* pré-processamento;
* grafos de decisão;
* preparação de datasets.

### `TAICodeAssistant`

Assistente de código baseado em LLM.

Pode ser usado para:

* revisar código;
* sugerir melhorias;
* gerar comentários;
* explicar trechos de código;
* auxiliar em testes;
* converter ou documentar rotinas.

### `TAIDatasetGenerator`

Gerador de datasets para uso em treinamento, fine-tuning ou classificação local.

Suporta geração ou manipulação de estruturas como:

* CSV;
* JSON;
* JSONL;
* matrizes de entrada e saída para treinamento local.

### `TAIModelRegistry`

Registro central de modelos, provedores, endpoints e parâmetros.

Permite organizar:

* nome do modelo;
* provedor;
* endpoint;
* temperatura;
* limite de tokens;
* parâmetros padrão.

### `TAIWizardConfig`

Assistente de configuração para novos projetos de IA.

Pode ser usado para preparar projetos como:

* chatbot;
* classificador;
* pipeline;
* agente;
* assistente técnico.

---

## AI Sound Filters

Componentes para processamento digital de sinais e filtros sonoros.

### `TLowPassFilter`

Filtro passa-baixa IIR de primeira ordem.

Usado para suavizar variações rápidas e reduzir ruídos de alta frequência.

### `THighPassFilter`

Filtro passa-alta IIR de primeira ordem.

Usado para remover componentes de baixa frequência, offset ou ruído DC.

### `TAverageFilter`

Filtro de média móvel.

Usado para suavização simples de sinais.

### `TFDMMultiplexer`

Multiplexador por divisão de frequência.

Permite simular canais em frequências diferentes.

### `TTDMMultiplexer`

Multiplexador por divisão de tempo.

Permite intercalar canais por janelas temporais.

### `TCDMMultiplexer`

Multiplexador CDM/CDMA.

Usa códigos ortogonais para separar sinais.

### `TOFDMMultiplexer`

Multiplexador OFDM com uso de FFT/IFFT.

Indicado para estudos e simulações de telecomunicações.

---

## AI Image

Componentes para processamento básico de imagens.

### `TGrayscaleFilter`

Converte imagem para escala de cinza.

### `TNegativeFilter`

Aplica inversão de cores.

### `TBrightnessContrastFilter`

Ajusta brilho e contraste.

### `TBinarizationFilter`

Aplica limiarização para imagem preto e branco.

### `TBlurFilter`

Aplica suavização por convolução.

### `TSharpenFilter`

Realça nitidez por kernel de convolução.

### `TSobelFilter`

Detecta bordas por operador Sobel.

### `TErosionDilationFilter`

Executa operações morfológicas de erosão e dilatação.

---

## AI Schedule

Componentes para organização, persistência e dependência de tarefas.

### `TJSONGroupStorage`

Componente para armazenamento de dados em JSON agrupado.

Pode ser usado para:

* salvar configurações;
* persistir parâmetros;
* armazenar textos;
* organizar dados por grupo.

### `TIASchedule`

Gerenciador de tarefas com dependências.

Permite modelar:

* tarefa pai;
* tarefa filha;
* dependências;
* estado de prontidão;
* controle simples de execução.

---

## AI Voice

Componentes de sintetização de voz.

### `TAIVoiceSynthesizer`

Componente de Text-to-Speech.

No Windows, pode usar SAPI.
No Linux, pode usar eSpeak/eSpeak-NG.

Principais recursos:

* falar texto;
* ajustar volume;
* ajustar velocidade;
* listar vozes disponíveis;
* execução assíncrona;
* integração com aplicações desktop.

---

## AI Agent

Componentes para agentes inteligentes e tomada de decisão estruturada.

### `TAIAgent`

Componente orquestrador do agente.

Permite enviar instruções para um LLM, interpretar respostas estruturadas e coordenar ações.

### `TAIAgentOptions`

Armazena contexto, perguntas, diretrizes e regras de análise.

### `TAIAgentAction`

Define ações permitidas para o agente.

Permite configurar:

* ações disponíveis;
* parâmetros esperados;
* callbacks de execução.

### `TAIAgentResource`

Representa recursos externos que podem ser acionados pelo agente.

Exemplos:

* arquivos;
* e-mail;
* HTTP;
* SMS;
* WhatsApp;
* TCP/UDP;
* Web APIs.

### `TAIAgentOutput`

Camada de saída que conecta decisões do agente com recursos reais do sistema.

---

## AI Graph

Componentes para estruturação de dados, grafos e datasets.

### `TAIGraphMap`

Grafo ponderado para classificação e análise baseada em tokens.

Pode ser usado em:

* classificação textual;
* agrupamento de conceitos;
* relação entre termos;
* análise simples de tópicos.

### `TAITrainingExporter`

Exportador de dados para treinamento.

Formatos previstos:

* CSV;
* JSON;
* JSONL;
* ARFF;
* vetores numéricos.

### `TAIDatasetAnalyzer`

Analisador de qualidade de dataset.

Pode detectar:

* categorias vazias;
* duplicidade;
* desequilíbrio de classes;
* textos muito curtos;
* textos muito longos.

### `TAITrainingReport`

Gerador de relatórios técnicos de treinamento.

Pode registrar:

* acurácia;
* erro;
* perda;
* quantidade de tokens;
* confiança média;
* estatísticas do dataset.

### `TAIGraphVisualizer`

Exportador e visualizador de grafos.

Formatos previstos:

* DOT / GraphViz;
* Mermaid;
* JSON de visualização.

---

## AI Input

Componentes para entrada de dados e integração com fontes externas.

Esta aba concentra componentes voltados à captura de informações, comunicação e integração com dispositivos ou sistemas.

Componentes previstos ou em evolução:

* câmera;
* áudio;
* servidor web;
* sockets;
* serial;
* impressora POS;
* CFTV/IP;
* Modbus;
* MQTT;
* e-mail;
* mensageria;
* captura de sistema operacional;
* browser embutido;
* entradas industriais.

> Alguns componentes desta aba podem depender de bibliotecas externas, drivers, permissões do sistema operacional ou serviços adicionais.

---

## AI Output

Componentes para saída de dados, geração de documentos e integração com destinos externos.

Recursos previstos:

* geração de documentos;
* exportação de respostas;
* saída estruturada;
* integração com canais externos;
* automação de respostas.

---

## AI Vision

Componentes para visão computacional.

Componentes previstos ou em evolução:

* OpenCV;
* captura de câmera;
* processamento de frames;
* rastreamento facial;
* rastreamento de movimento;
* classificação por imagem;
* detecção de objetos.

> Esta área deve ser tratada como experimental até que os componentes possuam demonstrações completas, dependências documentadas e testes de integração.

---

## AI Graphic

Componentes gráficos e 3D relacionados a IA, simulação e visualização.

Componentes previstos ou em evolução:

* cena 2D/3D;
* ambiente de treinamento;
* simulador físico;
* sensores virtuais;
* função de recompensa;
* visualização de modelos 3D;
* rig de esqueleto;
* controle de avatar;
* biblioteca de poses;
* sequência de animação;
* integração com geração de modelos 3D.

### `TAI3DModelViewer`

Visualizador de modelos 3D.

Objetivo:

* carregar modelos 3D;
* visualizar malhas;
* rotacionar;
* ampliar;
* reduzir;
* alternar modo sólido, aramado ou pontos.

### `TAITripo3DClient`

Cliente para integração com serviço externo de geração de modelos 3D.

Objetivo:

* gerar modelo a partir de texto;
* gerar modelo a partir de imagem;
* gerar modelo a partir de múltiplas imagens;
* baixar o modelo resultante em formato 3D.

> A integração com serviços externos deve ser validada conforme a API oficial do provedor utilizado.

---

## Instalação do Pacote no Lazarus

1. Abra o Lazarus.
2. Acesse **Package > Open Package File (.lpk)**.
3. Selecione o arquivo `pacote/openai.lpk`.
4. Clique em **Compile**.
5. Depois clique em **Use > Install**.
6. O Lazarus solicitará a recompilação da IDE.
7. Após reiniciar, os componentes aparecerão na paleta.

---

## Provedores de LLM

| Provedor                    | Enum             | Tipo                    |
| --------------------------- | ---------------- | ----------------------- |
| OpenAI                      | `AIP_OPENAI`     | API externa             |
| OpenRouter                  | `AIP_OPENROUTER` | API externa / agregador |
| Cerebras                    | `AIP_CEREBRAS`   | API externa             |
| Google Gemini               | `AIP_GEMINI`     | API externa             |
| Anthropic Claude            | `AIP_CLAUDE`     | API externa             |
| Local / Ollama / compatível | `AIP_LOCAL`      | Servidor local          |

> Os nomes de modelos, limites, custos e disponibilidade podem mudar conforme cada provedor. Sempre confira a documentação oficial do serviço utilizado.

---

## Requisitos

### Ambiente principal

* Lazarus 3.x ou superior;
* Free Pascal compatível;
* Windows ou Linux;
* pacote `openai.lpk`;
* conexão com internet para provedores externos;
* servidor local configurado para modelos offline, quando aplicável.

### Windows

Para comunicação HTTPS, podem ser necessárias DLLs OpenSSL compatíveis com a arquitetura da aplicação.

Verifique a pasta `pacote/lib/`.

Recomenda-se copiar as DLLs necessárias para a mesma pasta do executável final.

### Linux

Dependendo dos componentes utilizados, podem ser necessários pacotes adicionais, como:

* OpenSSL;
* eSpeak/eSpeak-NG;
* libpython;
* bibliotecas de câmera ou áudio;
* bibliotecas específicas para visão computacional.

Os requisitos podem variar conforme o componente usado.

---

## Screenshots

> As imagens abaixo demonstram recursos já testados ou em desenvolvimento.
> Componentes novos podem ainda não possuir demonstrações visuais completas.

### CNN Demo

![CNN Demo](screenshots/cnn_demo.jpg)

Demonstração de classificação de imagem.

### Math Input / Output Demo

![Math Input Output Demo](screenshots/math_input_output_demo.jpg)

Demonstração de componentes matemáticos.

### Python Connector Demo

![Python Demo](screenshots/python_demo.jpg)

Demonstração de integração com Python.

### SOM Demo

![SOM Demo](screenshots/som_demo.jpg)

Demonstração de mapa auto-organizável.

### Sound Filters Demo

![Sound Filters](screenshots/sound_filters.jpg)

Demonstração de filtros sonoros.

### Voice Synthesizer Demo

![Voice Synthesizer](screenshots/voicesynthesizer.jpg)

Demonstração de sintetização de voz.

---

## Limitações Conhecidas

O projeto ainda está em desenvolvimento e possui componentes em diferentes níveis de estabilidade.

Limitações atuais esperadas:

* alguns componentes podem estar em fase experimental;
* nem todos os componentes possuem demonstrações completas;
* integrações externas dependem de APIs de terceiros;
* componentes de visão computacional podem exigir bibliotecas externas;
* componentes Python dependem de versão e arquitetura compatíveis;
* ainda é recomendado validar cada componente antes de uso em produção;
* testes automatizados e integração contínua devem ser ampliados.

---

## Roadmap

### Curto prazo

* revisar documentação dos componentes;
* padronizar nomes das abas em inglês;
* separar componentes estáveis e experimentais;
* adicionar demonstrações mínimas para cada componente;
* validar compilação do pacote em Windows e Linux;
* corrigir inconsistências entre README e código.

### Médio prazo

* criar testes automatizados;
* criar pipeline com `lazbuild`;
* criar releases versionadas;
* documentar dependências externas;
* melhorar tratamento de erros;
* criar demonstrações reais de uso com LLM, voz, imagem e agentes.

### Longo prazo

* criar templates de projetos;
* criar assistente visual para configuração de IA;
* consolidar componentes OpenCV;
* consolidar componentes 3D;
* melhorar integração com modelos locais;
* evoluir agentes com controle de segurança;
* criar documentação completa para uso em produção.

---

## Para quem este projeto é indicado?

Este projeto é indicado para:

* desenvolvedores Lazarus;
* desenvolvedores Free Pascal;
* professores e estudantes;
* projetos desktop com IA;
* automação local;
* sistemas corporativos legados;
* aplicações educacionais;
* protótipos de IA;
* integração de IA com dispositivos;
* sistemas que precisam usar IA sem migrar toda a base para Python ou JavaScript.

---

## Para quem este projeto ainda não é indicado?

Neste momento, o projeto ainda não substitui:

* frameworks completos de machine learning;
* plataformas de MLOps;
* pipelines corporativos de treinamento;
* serviços profissionais de deploy de modelos;
* bibliotecas especializadas como PyTorch, TensorFlow, scikit-learn ou OpenCV completo;
* infraestrutura de IA em escala empresarial.

---

## Contribuindo

Contribuições são bem-vindas.

Áreas prioritárias para contribuição:

* correção de bugs;
* demonstrações funcionais;
* documentação;
* testes automatizados;
* compatibilidade Windows/Linux;
* ícones e screenshots;
* validação de componentes;
* melhorias em tratamento de erros;
* integração com provedores de IA;
* demos para cada aba do Lazarus.

---

## Licença

Este projeto está licenciado sob a **GNU General Public License v3.0**.

Consulte o arquivo `LICENSE`.

---

## Aviso

Este projeto utiliza ou integra serviços externos de IA.
O uso desses serviços pode envolver custos, limites de API, políticas próprias e envio de dados para terceiros.

Antes de usar em produção:

* revise os termos do provedor;
* proteja suas chaves de API;
* não envie dados sensíveis sem autorização;
* valide segurança, privacidade e conformidade;
* teste o comportamento do componente no ambiente real.

---

## Conclusão

O **TCHATGPT** é uma suíte promissora para levar recursos de IA ao ecossistema Lazarus / Free Pascal.

Seu maior valor está em oferecer uma ponte prática entre aplicações tradicionais e recursos modernos de IA, permitindo que sistemas desktop, industriais, educacionais e corporativos possam incorporar LLMs, voz, imagem, grafos, automação e modelos locais de forma componentizada.

O projeto ainda está em evolução, mas já possui uma base importante para se tornar uma referência open source em componentes de IA para Lazarus.
