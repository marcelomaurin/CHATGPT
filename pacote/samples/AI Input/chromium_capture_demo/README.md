# Chromium Capture Demo

This demo shows how to use `TAIChromiumBrowser` from the `openai_input` package.

The component is based on CEF4Delphi `TChromiumWindow`.

## Features

- Initialize Chromium
- Navigate to a real URL
- Go back
- Go forward
- Reload
- Execute JavaScript
- Wait for CSS selector
- Click CSS selector
- Set input value
- Get DOM HTML
- Save screenshot, when supported by the component

## Requirements

- Lazarus / Free Pascal
- openai_input package
- CEF4Delphi installed
- CEF binaries available for the target platform

## Important

This demo does not use simulation mode.
This demo does not use TIpHtmlPanel.
This demo does not fetch HTML with TFPHTTPClient.
