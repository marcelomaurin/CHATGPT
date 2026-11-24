# SIP Client Demo

Abra `sip_client_demo.lpi` no Lazarus. Compile a ponte conforme
`native/sip/README.md` e informe o caminho DLL/SO no formulário. Defina o
servidor (`sip:IP:5060`), realm, ramal e senha. Clique **Iniciar** para
registrar. Ligue para o outro ramal e use **Atender**, **Recusar** ou
**Encerrar**. Os eventos estão no arquivo compartilhado
`../sip_common/sip_demo_main.pas`.

O microfone exige runtime com som; desmarque a opção para processar PCM na
aplicação. Credenciais não são salvas. A compilação Windows e o som físico
ainda precisam de validação. Referência completa: `pacote/AI Communication/AISIP/README.md`.
