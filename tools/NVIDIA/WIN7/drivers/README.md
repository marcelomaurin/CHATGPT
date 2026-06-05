# Drivers NVIDIA — Windows 7 / GTX 1070

Coloque nesta pasta, localmente, o instalador do driver NVIDIA para **GeForce GTX 1070 / Windows 7 64-bit**.

## Download oficial

Use a página oficial:

```text
https://www.nvidia.com/Download/index.aspx
```

Configuração sugerida na busca:

```text
Product Type: GeForce
Product Series: GeForce 10 Series
Product: GeForce GTX 1070
Operating System: Windows 7 64-bit
Download Type: Game Ready Driver ou Studio Driver
Language: Português (Brazil) ou English (US)
```

## Instalação recomendada

1. Baixe o driver pelo site oficial.
2. Salve o instalador nesta pasta localmente.
3. Execute como administrador.
4. Escolha instalação personalizada, se desejar remover componentes desnecessários.
5. Reinicie o Windows.
6. Rode:

```bat
nvidia-smi
```

## Não versionar instaladores

Não subir arquivos como:

```text
*.exe
*.msi
*.zip
```

Motivos:

* licença proprietária;
* tamanho grande;
* risco de arquivo desatualizado;
* integridade deve vir do fornecedor oficial.
