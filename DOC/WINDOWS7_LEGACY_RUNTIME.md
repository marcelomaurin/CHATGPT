# Windows 7 Legacy Runtime

O Windows 7 deve ser tratado como uma linha separada de distribuição da Lazarus AI Suite.

## Motivo

Ainda existem equipamentos legados em operação, especialmente em ambientes industriais, laboratoriais, hospitalares e administrativos.

Esses equipamentos não devem usar o mesmo instalador do Windows moderno.

## Linha Python recomendada

Use Python 3.8.x para os pacotes Windows 7.

Python 3.9 ou superior não deve ser usado como base para o instalador legado do Windows 7.

## Pacotes previstos

```text
CHATGPT-AI-runtime-windows7-x86.zip
CHATGPT-AI-runtime-windows7-x64.zip
```

## Estrutura no repositório

```text
installer/windows7-x86/
installer/windows7-x64/
runtime/requirements/requirements-win7-core.txt
runtime/requirements/requirements-win7-vision.txt
runtime/templates/chatgpt_ai_runtime.windows7-x86.ini
runtime/templates/chatgpt_ai_runtime.windows7-x64.ini
```

## Caminho padrão

```text
C:/CHATGPT-AI-Win7
```

## Regras

- não depender do Python global;
- não misturar com runtime Windows 10/11;
- empacotar Python 3.8.x por arquitetura;
- validar separadamente x86 e x64;
- documentar quais componentes foram testados;
- tratar OpenCV, NumPy e Pillow com versões conservadoras;
- publicar os ZIPs apenas em GitHub Releases.

## Limitações

Essa linha existe para manter equipamentos legados em funcionamento.

Ela não deve ser tratada como plataforma recomendada para novos projetos.
