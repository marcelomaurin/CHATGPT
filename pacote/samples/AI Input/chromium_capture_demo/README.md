# Chromium Google Search Demo

This demo shows how to use `TAIChromiumBrowser` from the `openai_input` package to perform a practical web automation task:
**Lazarus controla o campo de pesquisa do Google dentro do Chromium.**

The component is based on CEF4Delphi `TChromiumWindow`.

## Features

- **Google Search Automation**: Open Google, locate the search field dynamically in the DOM, fill it, and submit the search using real DOM events.
- Initialize Chromium
- Navigate to a real URL
- Go back, Go forward, Reload
- Execute JavaScript
- Advanced DOM manipulation (Wait for CSS selector, Click CSS selector, Set input value)
- Get DOM HTML

## Requirements

- Lazarus / Free Pascal
- openai_input package
- CEF4Delphi installed
- CEF binaries available for the target platform

## Important

This demo does not use simulation mode.
This demo does not use TIpHtmlPanel.
This demo does not fetch HTML with TFPHTTPClient.
All rendering and JavaScript execution is performed by a real embedded Chromium browser instance.
