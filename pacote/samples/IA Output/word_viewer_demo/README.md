# TAIWordViewer Demo — Visualização de DOCX em TPanel

Este sample demonstra a visualização e renderização nativa de arquivos `.docx` reais dentro de um painel `TPanel` da LCL (Lazarus).

## Características do Componente

* **Visualização Nativa**: Renderiza parágrafos, runs, formatação básica, imagens e tabelas diretamente no painel.
* **Scroll & Zoom**: Área de rolagem automática criada internamente com suporte a Zoom de 25% a 300%.
* **Independência**: Sem uso de Microsoft Word, LibreOffice, COM/OLE ou Python.

## Detalhes Técnicos

* **Componente**: `TAIWordViewer`
* **Unit**: `aiwordviewer.pas`
* **Pacote**: `openai_output.lpk`
* **Status**: Experimental/Beta
* **Dependências**: FPC/Lazarus padrão e `TAIWordDocument` para leitura de dados
