# Ponte nativa SIP / PJMEDIA

Fonte GPL-3.0-or-later. Depende do PJSIP/PJMEDIA **2.17**, disponibilizado
sob GPL-2.0-or-later ou licença alternativa. As bibliotecas de terceiros
continuam sujeitas às respectivas licenças. O repositório CHATGPT usa GPLv3.

## Linux

Compile o PJSIP em uma pasta externa ao repositório. Requer compilador C/C++,
make, pkg-config e desenvolvimento do OpenSSL. Para áudio local em Linux,
instale também os cabeçalhos ALSA antes de configurar o PJSIP.

```sh
git clone --depth 1 --branch 2.17 https://github.com/pjsip/pjproject.git
cd pjproject
printf '#define PJSUA_MAX_CALLS 32\n#define PJSUA_MAX_ACC 32\n#define PJSUA_MAX_CONF_PORTS 128\n' > pjlib/include/pj/config_site.h
./configure --prefix="$PWD/install" --disable-video --disable-libwebrtc --disable-opencore-amr --disable-silk --disable-speex-aec --disable-speex-codec --disable-ilbc-codec --disable-g722-codec --disable-libyuv --disable-ffmpeg CFLAGS='-O2 -fPIC' CXXFLAGS='-O2 -fPIC'
make dep
make -j4
make install
```

Para uma compilação de teste sem microfone/alto-falante, acrescente
`--disable-sound` a `configure`; o RTP e os eventos PCM continuam funcionais.

De volta ao CHATGPT:

```sh
make -C native/sip PJ_PKG_PATH=/caminho/pjproject/install/lib/pkgconfig
python3 tests/run_sip_tests.py --bridge "$PWD/native/sip/build/libchatgpt_sip_bridge.so"
```

Saída: `native/sip/build/libchatgpt_sip_bridge.so`. Informe seu caminho
absoluto em `RuntimeLibrary` ou instale no caminho de bibliotecas do sistema.
O código usa G.711 PCMU/PCMA; o relógio PCM é de 8 kHz / 20 ms.

## Windows

A interface Pascal e a ABI C possuem nomes de DLL e tipos compatíveis com
Windows, mas a DLL Windows ainda não foi compilada/validada nesta entrega.
É necessário compilar PJSIP e a ponte para a mesma arquitetura do programa
Lazarus e disponibilizar as dependências correspondentes. Não use a `.so`
Linux como runtime Windows. A validação automática feita aqui é Linux x86_64.

## ABI e ciclo de vida

`chatgpt_sip_bridge.h` é a interface pública, espelhada em `aisip_native.pas`.
O loader confere versão da ABI e todos os símbolos antes de iniciar o motor.
Os contextos compartilham PJSUA por processo. A aplicação faz Poll, e a
ponte entrega cópias do áudio por filas limitadas; não chama Pascal no thread
do relógio de áudio. As portas PJMEDIA usam group locks para sobreviver à
remoção assíncrona da conferência.

`ASIP_TRACE=1` habilita rastreamento local de diagnóstico sem log de mensagens
SIP completas. Deixe desabilitado no uso normal.
