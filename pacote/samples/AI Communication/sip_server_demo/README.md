# SIP Server Demo

Abra `sip_server_demo.lpi` no Lazarus e configure o runtime DLL/SO, bind IP,
realm, ramais permitidos separados por vírgula e uma senha de teste em memória.
Clique **Iniciar**. Configure dois clientes com o mesmo servidor/realm/senha
e ramais diferentes, por exemplo 1001 e 1002.

`../sip_common/sip_demo_main.pas` mostra os eventos de autenticação,
autorização e roteamento. Substitua a consulta de lista pela sua base.
O ramal 9000 permite atendimento manual na própria aplicação servidor.
Referência completa: `pacote/AI Communication/AISIP/README.md`.
