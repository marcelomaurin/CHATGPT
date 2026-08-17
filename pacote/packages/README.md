# Pacotes Lazarus da suíte CHATGPT

Esta pasta concentra os pacotes `.lpk` usados para instalar a suíte no Lazarus/Free Pascal.

## Regra geral

Prefira os pacotes modulares `openai_*.lpk`. Cada pacote deve declarar apenas as dependências realmente necessárias e manter separadas as units de runtime das units usadas exclusivamente para registro visual no IDE.

Uma unit que contém apenas `Register`, ícones de paleta ou integração com o IDE deve ficar no lado design-time. Código usado pela aplicação final deve permanecer no runtime.

## Instalação

A instalação recomendada é feita pelos scripts/instalador do repositório, que resolvem a ordem dos pacotes e as dependências externas antes de chamar `lazbuild`.

Consulte:

- `INSTALL.md` na raiz do repositório;
- `installer/common/install_suite.py` para a lógica compartilhada de instalação;
- `tools/installer/README.md` para o instalador gráfico;
- `pacote/COMPONENT_STATUS.md` para o estado dos componentes e samples.

## Dependências externas

Alguns pacotes usam bibliotecas externas, como ZeosLib, DCPcrypt, CEF4Delphi e GLScene/LZScene. A versão utilizada pelo instalador deve vir do manifesto de dependências do projeto, e não de uma versão arbitrária encontrada no sistema.

Não adicione caminhos absolutos locais aos `.lpk`.

## Compatibilidade

O projeto é orientado a Lazarus/Free Pascal e possui código para Windows e Linux. A simples compilação de um pacote não comprova que hardware, DLLs, bibliotecas nativas, modelos ou APIs externas estejam disponíveis no runtime da máquina final.

Ao adicionar um pacote ou alterar dependências:

1. compile o pacote diretamente com `lazbuild`;
2. compile os packages que dependem dele;
3. compile os samples associados;
4. mantenha o CI sem dependências implícitas da configuração local do Lazarus;
5. atualize a documentação do pacote e o status dos samples quando houver mudança funcional.

## Runtime x design-time

Evite dependências de `LResources`, `LazarusPackageIntf` ou units de registro dentro do código que precisa compilar em runtime/headless. Recursos de paleta e `Register` devem ficar em units próprias quando possível.

Essa separação reduz falhas em CI, aplicações console, serviços e builds que não carregam a IDE Lazarus.
