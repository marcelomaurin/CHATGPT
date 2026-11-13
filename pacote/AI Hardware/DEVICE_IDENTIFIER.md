# TAIDeviceIdentifier

Componente Windows do pacote openai_hardware, paleta AI Hardware.
Refresh enumera dispositivos presentes. Devices fornece DeviceID (instancia PnP),
HardwareID, VendorID, ProductID, Description, DeviceClass, Port e Kind.

Tipos: Arduino Mega, Arduino Uno, ESP32, ESP8266, RS485, Serial, Mouse,
Keyboard, Webcam e Others. VID/PID ou descricao indicam o tipo quando explicitos.
CH340/CP210x/FTDI nao identificam sozinhos a placa ou a interface RS485.

## Confirmacao pela saida do firmware

ConfirmSerialFirmware(Port, TimeoutMs=3000) abre exclusivamente em 115200 8N1,
le o banner inicial ou telemetria e retorna Confirmed, Kind, Line e Detail.
Nao solicita reset, altera baud temporariamente e preserva DTR/RTS.
Restaura a configuracao da porta e fecha o handle ao terminar.
A abertura da porta pode reiniciar placas que possuem auto-reset no driver.
Depois de 1200 ms sem confirmacao, envia somente INFO CR LF, consulta de
identificacao implementada no firmware ESP32. Nao envia comandos de motor,
START ou STOP. A janela de leitura e limitada e a escrita tem timeout de 200 ms.

Assinaturas dos firmwares do amortecedor:
- ESP32: # LEITOR_ESP32 FW=... ADC=HX711
- ESP32 parado/sem HX711: INFO FW=... ADC=HX711 SPS=... STREAM=... SEQ=... SAT=... TMO=...
- ESP32 em execucao: tres linhas LC=<seq>,<t_us>,<raw> numericamente validas.
- Mega: # Analisador de Amortecedor v... - Bezerra Suspensoes
- Mega em execucao: tres linhas POS=<seq>,<t_us>,<adc>,<mm> validas ou duas
  linhas de status com [ATUADOR], [BOTOEIRA] e [MOTORCMD].

TAIFirmwareParser aceita blocos parciais e CR/LF, limita ruido e retém a linha
usada na confirmacao. Mensagens genericas OK, PONG, Sistema iniciado nao confirmam o modelo/firmware. Line tambem informa a ultima linha desconhecida.

AIResolveConfirmedSerialRoles exige confirmacao do firmware para Mega/ESP32,
mesmo quando o VID ou ID salvo sugerem outro tipo. IDs salvos desempataram
multiplos dispositivos confirmados; um unico firmware confirmado pode corrigir
um vinculo antigo. Porta 3 exige confirmacao pela consulta Modbus de status descrita abaixo.

## Uso no amortecedor

Configuracoes > Serial > Auto Ajuste executa a leitura em uma thread, exibe as
linhas de confirmacao e preenche somente resultados unicos. Portas ocupadas sao
reportadas sem interromper a aquisicao; desconecte-a antes de repetir a busca.
Somente Salvar persiste os numeros COM e DEVICEID1/2/3 em amortecedor.cfg.
Selecao manual continua disponivel para firmwares antigos e adaptadores RS485.
IDs de placas sem numero serial podem mudar ao trocar a tomada USB.

Testes de classificacao/associacao: amortecedor/tests/testdevices.lpr.
Testes de banners, telemetria, fragmentacao, ruido e decisao confirmada:
amortecedor/tests/testfirmware.lpr (54 verificacoes).
Compile com fpc usando -Fu para esta pasta e -FU/-FE para uma pasta temporaria.

API Windows de enumeracao:
https://learn.microsoft.com/en-us/windows/win32/api/setupapi/nf-setupapi-setupdigetdeviceregistrypropertyw

## Balanca legada com CH9102

Na instalacao do amortecedor, VID_1A86&PID_55D4 identifica o conversor CH9102
informado pelo operador. AIIsCH9102 destaca esse candidato; o Auto Ajuste le
esses candidatos primeiro. O conversor sozinho nao confirma o microcontrolador.
Tres linhas numericas Peso: <valor> (ou PESO=) confirmam a balanca/porta 2,
assim como LC= ou o banner ESP32. A linha recebida aparece no diagnostico.
O formato legado e compativel com a aquisicao existente. IDs salvos continuam
desempatando multiplas balancas confirmadas.

## Confirmacao do motor RS485 via CH340

AIIsCH340 reconhece o VID_1A86&PID_7523 observado na instalacao. Apos identificar
Mega e balanca pela saida, o Auto Ajuste consulta somente os CH340 restantes,
dispositivos descritos como RS485 ou o ID salvo da porta 3 ainda nao confirmado.
ConfirmRS485Status usa 9600 8N1, slave 1, funcao 03, registro $3000, quantidade 1.
Valida endereco, funcao, tamanho, CRC e status Frente/Reverso/Parado da resposta.
Nao envia partida, parada ou escrita de parametros. Preserva DTR/RTS e restaura
a configuracao da porta. Portas ocupadas nao sao desconectadas.
Somente uma resposta valida confirma a porta 3. Multiplos inversores confirmados
exigem o ID salvo para desempate. Sem resposta, o candidato permanece pendente;
verifique alimentacao do inversor, cabo A/B e os parametros de comunicacao.

Revisao 080-r5: o amortecedor habilita AllowCH9102Fallback. Sem saida serial, um unico CH9102 seleciona a porta 2 pelo ID, sem marcar a telemetria como confirmada. Com varios CH9102, exige ID salvo para desempate. Firmware confirmado de outro tipo impede a escolha. O modo generico do componente mantem confirmacao obrigatoria por padrao.

Revisao 080-r6: o amortecedor habilita AllowRemainingCH340Fallback. Depois de confirmar o Mega, exclui as portas do Mega, da balanca e de outros controladores conhecidos. O unico CH340 restante seleciona a porta 3; com varios candidatos, somente o ID salvo desempata. A selecao por exclusao nao afirma que o inversor respondeu. O resultado Modbus continua exibido separadamente. O modo generico mantem essa regra desativada por padrao.
