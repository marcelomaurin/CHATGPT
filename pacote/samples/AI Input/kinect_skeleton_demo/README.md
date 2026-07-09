# kinect_skeleton_demo

Demo Lazarus para testar o rastreamento de esqueleto do Kinect v1/Xbox 360 pelo backend Kinect SDK 1.8 do pacote `openai_input`.

## Requisitos

- Windows com Kinect for Windows SDK/Runtime 1.8 instalado.
- Kinect v1/Xbox 360 conectado por USB.
- Fonte externa do Kinect conectada. Sem a fonte 12V, o SDK pode abrir video, mas recusar skeleton.
- Pessoa a aproximadamente 1,8 m a 2,5 m do sensor para o primeiro rastreamento.

## Uso

1. Abra `kinect_skeleton_demo.lpi` no Lazarus ou compile com `lazbuild kinect_skeleton_demo.lpi`.
2. Execute o demo e clique em **Conectar**.
3. Deixe **Vídeo de fundo** marcado para sobrepor o esqueleto ao RGB.
4. Use **Modo sentado** antes de conectar quando quiser rastrear a parte superior do corpo.
5. Ajuste **Suavização** antes de conectar para reduzir tremor das juntas.
6. Clique em **Exportar pose** para salvar a pose atual em JSON.

## Formato do JSON

O arquivo exportado segue o padrão:

```json
{
  "createdAt": "2026-07-09 12:00:00",
  "bodies": [
    {
      "trackingId": 1,
      "joints": [
        {
          "joint": "kjHead",
          "x": 0.1,
          "y": 1.2,
          "z": 2.0,
          "screenX": 320,
          "screenY": 120,
          "state": "tracked"
        }
      ]
    }
  ]
}
```

Cada corpo contém 20 juntas na mesma ordem do SDK NUI.

## Roteiro de teste

1. Conecte o sensor sem pessoa na frente: o video deve aparecer e `Corpos: 0` deve permanecer no painel.
2. Fique a cerca de 2 m: o esqueleto deve aparecer sobre o corpo, acompanhando o movimento com baixa latência.
3. Ative **Modo sentado**, reconecte e sente-se: o rastreamento deve focar a parte superior do corpo.
4. Clique em **Exportar pose**: o JSON deve abrir em qualquer validador e conter 20 juntas por corpo.
5. Desconecte e reconecte o Kinect: o demo não deve travar.