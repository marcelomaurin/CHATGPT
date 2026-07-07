# AIUSB

Componente Lazarus para listar dispositivos USB e detectar conexão/desconexão.

## Recursos

- Lista dispositivos USB.
- Lê VID/PID.
- Lê fabricante.
- Lê produto.
- Lê número serial quando disponível.
- Detecta conexão.
- Detecta desconexão.
- Suporta AutoRefresh.

## Eventos

- OnDeviceConnected
- OnDeviceDisconnected
- OnDeviceChanged
- OnBeforeRefresh
- OnAfterRefresh
- OnError

## Plataformas

- Windows
- Linux

## Observações

No Windows, a primeira versão usa consulta WMI.
No Linux, a leitura é feita por `/sys/bus/usb/devices`.
