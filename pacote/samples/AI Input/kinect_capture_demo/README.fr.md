# kinect_capture_demo

Demo graphique pour valider la capture video couleur du Kinect avec `TAIKinectSensor`, `TAIKinectColorStream` et, en option, `TAIKinectDepthStream`.

## Objectif

Ce demo ouvre le capteur Kinect, demarre le flux couleur, affiche les images a l'ecran et journalise les evenements dans l'onglet **Log**. L'option **Depth** active aussi le flux de profondeur.

## Prerequis

- Windows.
- Kinect for Windows SDK/Runtime 1.8 installe.
- `Kinect10.dll` disponible sur le systeme.
- Application compilee avec la meme architecture que la DLL installee.
- Capteur Kinect connecte et libre.

## Utilisation

1. Lancez `kinect_capture_demo.exe`.
2. Gardez `Device` a `0` pour le backend SDK10.
3. Cochez **Depth** seulement pour tester la profondeur.
4. Cliquez sur **Conectar**.
5. Regardez l'image dans l'onglet **Video**.
6. Consultez les messages dans **Log**.
7. Cliquez sur **Desconectar** avant de fermer.

## Logs

Le demo ecrit dans `memLog` et lit le log interne du backend:

`%TEMP%\aikinect_sdk10_backend.log`

Ce log contient l'initialisation SDK, l'ouverture du flux, la capture des images, `LockRect`, `ReleaseFrame` et `NuiShutdown`.

## Depannage

- Si aucune image n'apparait, consultez **Log**.
- Si `NuiInitialize` echoue, verifiez qu'aucun autre programme n'utilise le Kinect.
- Si `Kinect10.dll` manque, reinstallez Runtime/SDK 1.8.
- Pour tester seulement la camera couleur, laissez **Depth** decoche.