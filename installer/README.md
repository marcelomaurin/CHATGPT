# CHATGPT-AI Installers

Esta pasta contém os instaladores offline por plataforma/arquitetura.

Os instaladores são responsáveis por:

1. validar sistema operacional e arquitetura;
2. criar a pasta de instalação;
3. copiar runtime Python e bibliotecas nativas quando existirem no pacote ZIP;
4. gerar `chatgpt_ai_runtime.ini`;
5. localizar `lazbuild`;
6. instalar pacotes Lazarus;
7. executar verificação final.

## Importante

Os ZIPs finais não devem ser commitados no Git comum. Eles devem ser publicados em GitHub Releases.

## Plataformas

- `windows-x64`
- `linux-x64`
- `linux-arm64`
- `linux-armhf`
