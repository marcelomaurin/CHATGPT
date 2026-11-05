# TAIJoystick

Componente de entrada da biblioteca CHATGPT, derivado de `TAIBaseComponent`.
Windows: Xbox 360 e outros controles XInput; fallback WinMM para joysticks
genericos reconhecidos pelo Windows. Nao precisa de uma DLL redistribuida:
XInput e carregado do diretorio de sistema, com fallback entre as versoes.
Em outros sistemas, a unidade compila e retorna desconectado; ainda nao ha
backend nativo nesses sistemas.

```pascal
Joystick := TAIJoystick.Create(Owner);
Joystick.DeviceID := ''; // automatico
if Joystick.Poll then
  WriteLn(Joystick.State.DeviceName);
```

Chame `Poll` na thread principal (por exemplo, a cada 50 ms). A enumeracao e
atualizada a cada segundo; `RefreshDevices` forca uma atualizacao. `Devices`
fornece nomes e IDs para selecao manual (`xinput:0` ou `winmm:0`). No modo
automatico o controle atual permanece selecionado ate ser desconectado;
na descoberta, XInput tem prioridade. A selecao manual nao troca para outro
controle quando o escolhido e desconectado. Um Xbox pode aparecer tambem
na lista WinMM; prefira sua entrada XInput para gatilhos independentes.

`State.Axes[0..5]` fornece valores normalizados. No XInput: analogico
esquerdo X/Y, direito X/Y, gatilhos LT/RT (0..1). Y positivo aponta para
cima; o backend WinMM inverte Y para manter a convencao. No WinMM: X/Y/Z/R/U/V,
conforme os eixos informados pelo driver. `Controls[1..32]` sao botoes; no
XInput: A=1, B=2, X=3, Y=4, LB=5, RB=6, Back=7, Start=8, cliques dos
analogicos=9/10, direcional=11..14. LT=33 e RT=34 indicam gatilho acima
de 25%; no WinMM estes dois controles virtuais nao estao disponiveis.

O componente apenas le o controle: nao envia comandos para equipamentos.
A aplicacao consumidora deve tratar zona morta, foco, reconexao, estados
de execucao e cancelamento. Testes deterministas podem substituir
`ReadDevice` e `ScanDevices`, sem um joystick fisico.

Validacao: compilacao Windows/FPC 3.2.2; testes de normalizacao, selecao,
desconexao/reconexao e integracao no MultiCNC. Validacao com hardware fisico
ainda pendente.

Referencias de API:
- https://learn.microsoft.com/en-us/windows/win32/api/xinput/ns-xinput-xinput_gamepad
- https://learn.microsoft.com/en-us/windows/win32/api/joystickapi/nf-joystickapi-joygetposex
