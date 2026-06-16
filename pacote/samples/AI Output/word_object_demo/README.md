# TAIWordDocument Demo — Manipulação Real de DOCX via OpenXML

Este sample demonstra a geração, carregamento, edição e salvamento real de arquivos `.docx` usando a especificação OpenXML / WordprocessingML.

## Características do Componente

* **Nativo**: Não usa Microsoft Word (sem dependências COM/OLE).
* **Independente**: Não usa LibreOffice.
* **Real**: Não usa HTML disfarçado de DOCX (gera o pacote compactado ZIP correto contendo arquivos XML válidos).

## Detalhes Técnicos

* **Componente**: `TAIWordDocument`
* **Unit**: `aiworddocument.pas`
* **Pacote**: `openai_output.lpk`
* **Status**: Experimental/Beta
* **Dependências**: FPC/Lazarus padrão (`Zipper`, `DOM`, `XMLRead`, `XMLWrite`)
