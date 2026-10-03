# Componentes Marlin e serial virtual

Implementacao nova, aditiva: nenhum componente anterior foi modificado.
O pacote Lazarus `pacote/packages/openai_marlin.lpk` registra quatro componentes.
O parser e o simulador podem ser compilados sem LCL, sem rede e sem hardware.

## Componentes

* `TAIGCodeParser`: leitura independente de locale; palavras compactas,
  comentarios `;` e `(...)`, numeros de linha e checksum XOR. Limite de 1024 bytes.
* `TAIMarlinSimulator`: impressora cartesiana ideal, uma ferramenta, eventos de
  movimento, respostas e estado. Nao cria Forms, nao desenha e nao usa IA generativa.
* `TAIMarlinSerialDevice`: composicao do simulador com o `TAISerialModem` existente.
  Reutiliza esse componente sem modificar sua implementacao.
* `TAIVirtualSerialPair`: administra pares com um `setupc.exe` do com0com ja
  instalado. Reutiliza `TAIProcessRunner`; argumentos separados, limite de tempo,
  rejeicao de nomes invalidos/duplicados e verificacao posterior pelo backend.

## Execucao e eventos

Crie `TAIMarlinSimulator.Create(Owner)`, associe `OnResponse`, `OnMotion` e
`OnStateChanged`. Passe dados fragmentados para `Receive(Bytes)` ou uma linha
sem terminador para `SubmitLine(Line)`. Chame `Advance(Seconds)` periodicamente.
O componente nao inicia threads ou timers. Todos os eventos ocorrem na thread
chamadora. Nao chame `Advance` novamente dentro de um callback, nao destrua o
componente dentro dele e encaminhe novas entradas no proximo ciclo.

`Advance(0.02)` representa 20 ms simulados; aumentar o passo acelera a simulacao.
Cada chamada aceita 0..3600 segundos finitos. Pause/Resume sao controles locais,
nao comandos SD M24/M25. Durante pausa, temperatura e tempo continuam evoluindo.

`State.Position` e `OnMotion` fornecem coordenadas **fisicas em mm**.
G92 altera o deslocamento logico; M114 apresenta coordenadas logicas.
`OnMotion` informa inicio, fim e filamento depositado naquele intervalo.
A recuperacao de retracao e descontada antes da contagem de material.
Extrusao parada tambem produz material; a aplicacao deve distinguir purga de
extrusao em deslocamento. No intervalo que termina de recuperar uma retracao,
nem todo o percurso necessariamente recebe material. Nao ha malha ou largura
de trilha pronta: a geometria de deposicao pertence a aplicacao 3D.

Reset limpa a fila, posicoes, contadores e temperaturas e emite `start`.
Volume inicial: 220 x 220 x 250 mm, alteravel com `SetBuildVolume` quando ocioso.

## Subconjunto implementado

| Comandos | Comportamento |
| --- | --- |
| G0/G1 | Movimento linear X/Y/Z/E e feed F, interpolacao por tempo |
| G4 | Espera P em ms ou S em segundos |
| G20/G21 | Polegadas / milimetros |
| G28 | Home ideal instantaneo, todos ou X/Y/Z selecionados |
| G90/G91 | Absoluto / relativo, inclusive redefinicao do modo E |
| G92 | Deslocamentos logicos X/Y/Z/E |
| M17, M18, M84 | Estado dos motores; sem parametros de timeout/eixos |
| M82/M83 | Modo absoluto / relativo da extrusora |
| M104/M140 | Alvos de temperatura do bico / mesa |
| M109/M190 | Espera de temperatura; S espera aquecimento, R tambem resfriamento |
| M105 | Temperaturas atuais e alvos |
| M106/M107 | Ventilador unico |
| M108 | Interrompe espera de temperatura |
| M110 | Reinicia sequencia de linhas; usa N interno quando informado |
| M112 | Emergencia imediata, limpa fila e desliga aquecimento; exige Reset local |
| M114/M115/M119 | Posicao, identificacao explicita como simulador, fins de curso ideais |
| M220/M221 | Percentual de velocidade / fluxo para movimentos seguintes |
| M302 | Temperatura minima de extrusao (S) ou permissao de extrusao fria (P) |
| M400 | Barreira: confirma depois dos movimentos anteriores |
| T0 | Ferramenta unica |

Temperatura ambiente: 25 C; bico aquece 3 C/s e resfria 1 C/s;
mesa aquece 0,8 C/s e resfria 0,3 C/s. Sao modelos lineares para testes,
nao modelos termicos de uma impressora real. Alvos limitados a 300/130 C.
Extrusao positiva abaixo de 170 C e recusada por padrao (M302 altera).
G0/G1 fora do volume ou com feed invalido sao recusados sem movimento parcial.

## Protocolo e limites

* Respostas terminam em LF. Linhas CR, LF ou CRLF sao aceitas na entrada.
* Linhas numeradas exigem checksum correto e sequencia; erros pedem `Resend:n`.
* Fila maxima de 128 comandos; uma linha recusada por lotacao nao consome seu N.
* O `ok` dos movimentos/esperas e emitido na conclusao, nao na entrada do planner.
  Isso suporta hosts sequenciais, mas nao reproduz a vazao do planner real.
* M105/M108/M110/M114/M115 sao imediatos. M112 precede fila e verificacao de sequencia.
* Erros de execucao emitem `Error:...` seguido de `ok` para consumir a linha;
  nao significam execucao bem-sucedida. Erros de transporte pedem reenvio.
* Comandos/parametros nao suportados sao recusados. Nao declarar compatibilidade
  total com Marlin. Nao ha G2/G3, aceleracao, jerk, PID, SD, EEPROM, nivelamento,
  M117/M118 com texto, multiplos extrusores, subcodigos ou notacao exponencial.
* Nao ha simulacao de colisao, gravidade, deformacao ou adesao do filamento.

## Serial e Windows

Use `Device.Open('COM42',115200)` e `Device.Poll(0.02)` no timer da aplicacao.
O host externo abre a outra ponta, por exemplo COM41. Reserve os handlers
`Serial.OnRXReceive` e `Simulator.OnResponse` ao adaptador; observe trafego por
`Device.OnTraffic`. Eventos de movimento/estado do simulador continuam disponiveis.
Falha de escrita fecha a conexao e pausa a simulacao; nao ha retry automatico de
bytes parcialmente escritos. Abertura nova reinicia a impressora simulada.

O par deve existir antes de Open. Configure `Pair.SetupExecutable` com o caminho
do `setupc.exe`, consulte `ListPairs` e invoque `CreatePair('COM41','COM42')`
explicitamente. Pode exigir execucao elevada, conforme o driver instalado.
O componente nao instala driver, nao eleva privilegios automaticamente e nao
desativa verificacao de assinatura. Nao emula enumeracao USB/VID/PID.
Sucesso do backend confirma registro no com0com; ainda e necessario verificar
se o driver carregou e se ambas as portas abrem com `TAIListSerialDevices`/serial.
Em outros sistemas este backend informa que nao e suportado.

## Validacao

Execute `tests/run_marlin_tests.ps1`. Define FpcPath/LazarusRoot se necessario.
O script compila os tres programas em uma pasta temporaria exclusiva.
Os testes abrangem parsing, locale com virgula, movimentos, coordenadas, extrusao,
temperaturas, emergencia, checksum, sequencia/reenvio, filas, limites e o backend
virtual falso, alem da construcao/destruicao do adaptador serial.
Nao abrem portas reais e nao instalam drivers. O teste COM ponta a ponta depende
do driver instalado e permanece necessario no ambiente de destino.

Exemplo console: `pacote/samples/AI Simulation/marlin_console/marlin_console.lpr`.
Recebe G-code por stdin, emite respostas por stdout e avanca em passos de 20 ms,
sem esperar tempo real. Compilar com os caminhos `AI Simulation/Marlin` e `AI`.

Referencias de protocolo:
https://marlinfw.org/docs/gcode/G090.html
https://marlinfw.org/docs/gcode/M110.html
https://marlinfw.org/docs/gcode/M109.html
Backend: https://com0com.sourceforge.net/
