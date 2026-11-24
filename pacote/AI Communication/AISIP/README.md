# SIP: cliente e servidor por eventos

Primeira implementação de `TAISIPServer` e `TAISIPClient` para Lazarus/FPC.
O pacote é `pacote/packages/openai_sip.lpk`, na paleta **AI Communication**.
As unidades de execução são Pascal sem dependência de LCL; a integração
SIP/SDP/RTP e G.711 usa uma pequena biblioteca C sobre PJSIP/PJMEDIA 2.17.

## Estado verificado em 24/11/2026

- Compilação dos componentes e da ponte em Linux x86_64 / FPC 3.2.2.
- Teste real de loopback em sockets UDP: registro Digest SHA-256, senha errada,
  autorização por evento, chamada entre dois ramais, PCM/RTP não silencioso
  nos dois sentidos, DTMF, ocupado (486), rota negada (403), desligamento
  propagado, cancelamento do registro e bloqueio de novo registro pelo evento.
- Ainda precisam de validação: DLL/compilação Windows, aparelhos e softphones
  externos, microfone/alto-falante e redes com NAT. Este teste não valida esses
  ambientes. Não foram produzidos executáveis Windows.

## Instalação e execução

1. Compile a ponte conforme `native/sip/README.md` e informe seu caminho em
   `RuntimeLibrary`. O componente informa erro se a biblioteca ou algum símbolo
   da ABI estiver ausente. Não existe simulação substituindo telefonia.
2. No Lazarus, abra/compile `openai_core.lpk` e `openai_sip.lpk`; instale o
   segundo pacote para mostrar os dois componentes na paleta.
3. Configure `Realm`, `BindAddress`, `SIPPort`, `RTPPort` e os eventos.
   `PublicAddress` é o endereço anunciado no SIP/SDP; deixe vazio para o PJSIP
   escolher o endereço da interface ou informe o IP acessível na sua LAN.
4. Chame `Start`. No cliente, chame também `RegisterAccount`.
5. Chame `Poll(0)` regularmente (exemplo: TTimer de 10 ms). Todos os componentes
   do mesmo processo compartilham o motor; um Poll processa a rede de todos.
   Crie, utilize e destrua todos no mesmo thread. Os eventos são executados
   nesse thread. Consultas demoradas nos eventos atrasam o processamento SIP.
6. Use `Stop` antes de finalizar. `Stop` solicitado em evento é adiado até
   retornar ao processamento normal; não destrua o componente dentro de eventos.

Configurações de rede e credenciais são aplicadas em `Start`; pare/inicie para
alterá-las. `Password` tem `stored False`, não é salva no formulário.

## Eventos que decidem as regras

| Evento do servidor | Decisão da aplicação |
|---|---|
| `OnAuthenticate` | Recebe usuário, realm e origem; devolve `Secret`, `Kind` e `Found`. A ponte valida o Digest. |
| `OnAuthorizeRegistration` | Depois de autenticar, devolve `Allow` para registrar/remover o ramal. |
| `OnAuthorizeCall` | Depois de autenticar, devolve `Allow` para iniciar a chamada. |
| `OnRouteCall` | Recebe identificador da chamada, origem e destino; escolhe negar, encaminhar ou atender localmente. |

Sem tratadores, as decisões são **negar**. `OnAuthenticate` não recebe a senha
em texto do telefone: a aplicação consulta sua própria credencial, em qualquer
banco ou serviço. `Kind` aceita senha em memória, HA1 MD5 ou HA1 SHA-256.
HA1 depende de usuário, realm e algoritmo; hash BCrypt não substitui HA1.
`DigestAlgorithm` é SHA-256 por padrão, com opção MD5 para interoperabilidade.
Nonces expiram, são vinculados à origem e o contador protege contra replay.

Exemplo de autenticação (substitua a consulta pela sua base):

```pascal
procedure TMinhaTela.Autenticar(Sender: TObject;
  const UserName, Realm, RemoteAddress: string; var Secret: string;
  var Kind: TAISIPCredentialKind; var Found: Boolean);
begin
  Found := ConsultarCredencial(UserName, Realm, Secret);
  Kind := skPassword;
end;
```

Para encaminhar, devolva `srRoute` e um ramal registrado em `Destination`.
Somente uma rota explicitamente autorizada pode devolver URI `sip:` direta.
`srAnswerLocally` gera `OnIncomingCall`, permitindo atendimento por sua
aplicação. A ponte atua como B2BUA e encaminha áudio e encerramento entre
as duas pernas da chamada. A primeira versão mantém um contato por ramal.

## Cliente, chamadas e áudio

`ServerURI` deve ser uma URI, por exemplo `sip:192.168.0.10:5060`. Defina
`UserName`, `Realm`, `Password` ou forneça as credenciais em
`OnCredentialsRequired` antes de iniciar.

Métodos compartilhados: `Call(Destination, CallID)`, `Ring`, `Answer`,
`Reject` (486 por padrão), `Hangup`, `SendDTMF` e `WriteAudio`.
Os identificadores são únicos durante a vida do motor e todas as ações
verificam a associação entre chamada e componente.

Notificações: `OnIncomingCall`, `OnCallStateChanged`, `OnDTMF`, `OnAudio`,
`OnAudioOverflow`, `OnError` e `OnLog`. Há também `OnRegistrationState` no
cliente e `OnRegistration`/`OnAuthenticationResult` no servidor.

`OnAudio` fornece cópia de PCM **mono, 16 bits com sinal, 8000 Hz**, com
160 amostras por quadro. `WriteAudio` recebe o mesmo formato e devolve o
número de amostras aceitas, ou valor negativo se a fila estiver cheia ou
a mídia indisponível. A aplicação deve reenviar depois quando houver
contrapressão. A fila de recepção é limitada e informa descarte pelo evento.

`UseSoundDevice=True` conecta a chamada ao microfone/alto-falante padrão do
PJSIP. Isso exige uma ponte compilada com suporte ao dispositivo de áudio;
o teste automático usa `False`. Os dispositivos de som são compartilhados
pelas instâncias do mesmo processo.

A conexão a STT/TTS fica disponível por PCM, mas a adaptação automática aos
componentes de voz por arquivo ainda não foi implementada. A primeira versão
usa IPv4/UDP em LAN. TLS/SRTP, NAT/ICE/TURN, operadora/PSTN, transferência,
conferência e codecs adicionais não integram o escopo validado.

## Exemplos e teste

- `pacote/samples/AI Communication/sip_server_demo/sip_server_demo.lpi`
- `pacote/samples/AI Communication/sip_client_demo/sip_client_demo.lpi`
- `tests/test_sip_loopback.lpr`

Os exemplos pedem a senha em execução, sem gravá-la. O servidor demonstra
consulta de ramais por evento; o ramal especial `9000` permite atendimento
local manual. Abra dois clientes com ramais diferentes para testar.
No exemplo visual, o campo de destino também serve para informar os dígitos
do botão DTMF. O exemplo acompanha uma chamada selecionada; o componente
oferece identificadores para aplicações que gerenciem várias.

```sh
python3 tests/run_sip_tests.py --bridge /caminho/libchatgpt_sip_bridge.so
```
