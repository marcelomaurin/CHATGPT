# OpenCV Runtime — Fontes públicas e compatibilidade

## Objetivo

Definir como o projeto deve usar fontes públicas confiáveis para montar o runtime OpenCV, mantendo compatibilidade com Windows 7, Windows atual, Linux x64, Linux ARM64 e Linux ARMHF.

## Regra principal

O projeto pode usar binários públicos do OpenCV quando forem confiáveis, licenciados e compatíveis com a plataforma alvo.

Quando não houver binário público adequado, o runtime deve ser gerado por build controlada a partir do código-fonte oficial do OpenCV.

## Windows 7

Windows 7 é requisito explícito.

O bot não deve assumir que a versão mais nova do OpenCV funciona no Windows 7.

Para Windows, devem existir pacotes separados para:

```text
windows-x86-win7
windows-x64-win7
```

A pasta final continua sendo:

```text
runtime/opencv/windows/x86/bin/
runtime/opencv/windows/x64/bin/
```

Mas o arquivo `VERSION.txt` deve indicar se a build foi validada em Windows 7.

## Fontes públicas permitidas

O bot pode usar:

```text
OpenCV official releases
OpenCV official source code
OpenCV contrib source code somente se necessário
```

Prioridade:

```text
1. Release pública oficial compatível
2. Build controlada do código-fonte oficial
3. Build própria por CI/Docker/VM
```

Não usar sites aleatórios de DLL.

Não copiar DLL/SO diretamente de pastas do sistema como origem final do projeto.

## Bridge obrigatória

O runtime nativo real deve conter uma bridge do projeto:

```text
Windows: aiopencv_bridge.dll
Linux: libaiopencv_bridge.so
```

A bridge deve expor uma interface C simples para o Lazarus/Free Pascal.

O Lazarus deve carregar a bridge, e a bridge deve chamar o OpenCV.

## Funções mínimas da bridge

```text
aiopencv_version
aiopencv_image_info
aiopencv_gray
aiopencv_blur
aiopencv_canny
aiopencv_threshold
aiopencv_resize
aiopencv_last_error
```

## Estrutura final esperada

```text
runtime/opencv/windows/x86/bin/
runtime/opencv/windows/x64/bin/
runtime/opencv/linux/x64/lib/
runtime/opencv/linux/arm64/lib/
runtime/opencv/linux/armhf/lib/
```

Cada pasta deve conter:

```text
bridge do projeto
biblioteca OpenCV correspondente
VERSION.txt
CHECKSUMS.txt
LICENSES/
```

## VERSION.txt obrigatório

Cada pacote deve informar:

```text
OpenCV version
Bridge version
Operating system
Architecture
Windows 7 compatible
Minimum Windows version
Compiler
Runtime dependency
Build date
Binary names
Source/build origin
License notes
```

## CHECKSUMS.txt obrigatório

Cada pacote deve listar SHA256 dos binários incluídos.

## Critérios de aceite

O runtime será aceito quando:

```text
1. Não houver DLL/SO falsa
2. A origem dos binários estiver documentada
3. A licença estiver incluída
4. Windows 7 estiver explicitamente tratado
5. x86 e x64 estiverem separados
6. Linux x64, ARM64 e ARMHF estiverem separados
7. A bridge existir para cada plataforma suportada
8. VERSION.txt existir
9. CHECKSUMS.txt existir
10. O TAIOpenCV conseguir localizar bridge + OpenCV pelo runtime do projeto
```

## Observação

Usar binário público é permitido para acelerar o projeto, principalmente no Windows.

Mas a compatibilidade com Windows 7 tem prioridade sobre usar a versão mais nova.
