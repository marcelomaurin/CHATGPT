# CHATGPT Lazarus Suite Installer

Wizard gráfico para instalar os packages do projeto `marcelomaurin/CHATGPT`.

## Fluxo

1. Boas-vindas.
2. Detecta Lazarus e FPC.
3. Detecta a plataforma ativa (`i386`/`x86_64`, `win32`/`win64`).
4. Lê `pacote/packages/openai_*.lpk`.
5. Lê `RequiredPkgs` e calcula a ordem interna por ordenação topológica.
6. Verifica pré-requisitos externos conhecidos pela configuração do Lazarus.
7. Localiza packages CHATGPT instalados anteriormente.
8. Faz backup de `environmentoptions.xml`.
9. Remove somente entradas `openai_*` da lista `StaticAutoInstallPackages`.
10. Limpa caches `lib` da suíte.
11. Compila todos os packages usando `lazbuild --cpu=... --os=...`.
12. Registra os packages com `--add-package`.
13. Recompila a IDE uma única vez.
14. Verifica se os packages solicitados aparecem na configuração final.

## Compilar o instalador no Windows

64 bits:

```bat
build_installer.bat Release64
```

Saída esperada:

```text
Installer_64.exe
```

32 bits:

```bat
build_installer.bat Release32
```

Saída esperada:

```text
Installer_32.exe
```

## Local recomendado dentro do repositório

Copie a pasta deste projeto para:

```text
tools/installer/
```

O executável deve ficar dentro dessa pasta. O mecanismo usa como padrão o repositório localizado dois níveis acima; o caminho pode ser alterado na tela Ambiente.

## Observação importante

A remoção usa backup do `environmentoptions.xml` antes de alterar `StaticAutoInstallPackages`, pois o `lazbuild` possui `--add-package`, mas não oferece um comando simétrico `--remove-package`.

Antes de distribuir, teste com uma instalação Lazarus 32 bits e outra 64 bits.

## Samples

O wizard também pode compilar todos os projetos `.lpi` abaixo de:

```text
pacote/samples/
```

A compilação usa a mesma arquitetura detectada para Lazarus/FPC:

```text
i386/win32  -> 32 bits
x86_64/win64 -> 64 bits
```

O instalador registra o resultado de cada sample na tela final.

## Documentação

O wizard valida:

```text
README.md
INSTALL.md
ReadMe.txt
pacote/COMPONENT_STATUS.md
pacote/DOC/
```

Quando a opção de documentação está habilitada, também copia a documentação para:

```text
installed_content/docs/
```

ao lado do instalador.

Isso permite distribuir um pacote de instalação contendo executável + documentação local.

## Atualização antes da instalação

Na primeira etapa do wizard existe a opção:

```text
Verificar e baixar atualizações do GitHub antes de instalar
```

Quando habilitada:

1. o instalador detecta o `git`;
2. confirma que a pasta é um clone Git;
3. executa `git fetch origin main`;
4. compara `HEAD` com `origin/main`;
5. se houver atualização, pergunta ao usuário se deseja baixar;
6. se confirmado, executa `git pull --ff-only origin main`;
7. somente depois continua a instalação.

### Proteção de alterações locais

Se `git status --porcelain` indicar arquivos modificados, o instalador **não executa pull** automaticamente.

Ele informa ao usuário que existem alterações locais e pergunta se deseja continuar a instalação usando a versão local.

O instalador nunca executa automaticamente:

```text
git reset --hard
git clean -fd
git stash
```

Assim ele não apaga trabalho local.
