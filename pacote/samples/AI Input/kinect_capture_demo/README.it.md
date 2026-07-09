# kinect_capture_demo

Demo grafica per validare la cattura video a colori del Kinect usando `TAIKinectSensor`, `TAIKinectColorStream` e, opzionalmente, `TAIKinectDepthStream`.

## Obiettivo

Il demo apre il sensore Kinect, avvia lo stream colore, mostra i frame a schermo e registra gli eventi nella scheda **Log**. L'opzione **Depth** abilita anche lo stream di profondita.

## Requisiti

- Windows.
- Kinect for Windows SDK/Runtime 1.8 installato.
- `Kinect10.dll` disponibile nel sistema.
- Applicazione compilata per la stessa architettura della DLL installata.
- Sensore Kinect collegato e non usato da altri programmi.

## Uso

1. Avviare `kinect_capture_demo.exe`.
2. Lasciare `Device` su `0` per il backend SDK10.
3. Abilitare **Depth** solo per testare la profondita.
4. Fare clic su **Conectar**.
5. Guardare l'immagine nella scheda **Video**.
6. Controllare i messaggi nella scheda **Log**.
7. Fare clic su **Desconectar** prima di chiudere.

## Log

Il demo scrive eventi in `memLog` e legge il log interno del backend:

`%TEMP%\aikinect_sdk10_backend.log`

Il log include inizializzazione SDK, apertura stream, cattura frame, `LockRect`, `ReleaseFrame` e `NuiShutdown`.

## Risoluzione problemi

- Se non appare immagine, controllare **Log**.
- Se `NuiInitialize` fallisce, verificare che nessun altro programma usi il Kinect.
- Se manca `Kinect10.dll`, reinstallare Runtime/SDK 1.8.
- Per testare solo la camera colore, lasciare **Depth** disattivato.