# Disk Tree AI Dataset Demo

Este demo demonstra o uso do componente `TAIDiskTreeScanner` para navegação, varredura, pesquisa e preparação de datasets para inteligência artificial de forma assíncrona.

## Recursos demonstrados

- **Lista Volumes**: Carrega dinamicamente os volumes de disco ativos no Windows (`C:\`, `D:\`, etc.) ou os pontos de montagem principais no Linux (`/`, `/home`, etc.).
- **Scan Branch**: Lista os diretórios e arquivos presentes no ramo atual selecionado (sem recursão).
- **Scan Recursive**: Realiza uma leitura completa e recursiva a partir da pasta selecionada.
- **Find File / Find Dir**: Busca arquivos ou pastas pelo nome ou trecho correspondente de forma assíncrona.
- **Find Ext**: Busca arquivos pela extensão selecionada.
- **Geração de Inventário para IA**: Analisa os arquivos e gera uma classificação sugerida baseada no nome do diretório pai (ideal para preparação de datasets de classificação).
- **Exportação de Dados**: Salva o inventário em formato estruturado JSON, CSV ou TXT.
- **Cancelamento**: Permite interromper qualquer operação de varredura ou indexação longa de forma segura através do botão *Cancel*.

## Requisitos

- Lazarus
- Free Pascal
- Nenhuma dependência externa de Python ou OpenCV (100% nativo FPC/LCL).
