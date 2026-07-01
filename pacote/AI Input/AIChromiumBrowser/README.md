# TAIChromiumBrowser

Componente visual para integração de navegação real do Chromium (CEF4Delphi) no Lazarus, habilitando automação e interação direta com o DOM (Document Object Model) via agentes cognitivos e código.

## Integração com Agentes Cognitivos

Este componente pode ser controlado dinamicamente pelas ações preparadas no executor de planos `TAIActionExecutor`.

Ações registradas prontas para uso:
- `BROWSER_NAVIGATE`: Navega até a URL especificada.
- `BROWSER_WAIT_SELECTOR`: Aguarda o surgimento de um seletor CSS no DOM.
- `BROWSER_READ_PAGE`: Captura o texto do body e lista tags DOM importantes (inputs, buttons, forms).
- `BROWSER_SET_VALUE`: Define o valor de um campo de formulário no DOM pelo seletor CSS e índice.
- `BROWSER_CLICK`: Simula o clique em um elemento DOM.
- `BROWSER_PRESS_ENTER`: Envia a tecla Enter em um campo de entrada.
- `BROWSER_SUBMIT_FORM`: Submete o formulário associado a um elemento.
- `BROWSER_SCREENSHOT`: Salva uma captura de tela em arquivo PNG.
