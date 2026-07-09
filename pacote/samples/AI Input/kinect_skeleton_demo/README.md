# kinect_skeleton_demo

Demo Lazarus para testar o rastreamento de esqueleto do Kinect v1/Xbox 360 pelo backend Kinect SDK 1.8 do pacote `openai_input`.

## Requisitos

- Windows com Kinect for Windows SDK/Runtime 1.8 instalado.
- Kinect v1/Xbox 360 conectado por USB.
- Fonte externa 12V obrigatória; sem ela o vídeo pode abrir, mas o skeleton pode falhar.
- Distância recomendada de 1,2 m a 3,5 m para corpo inteiro. Em modo sentado, mantenha pelo menos 0,8 m.
- Pessoa de frente para o sensor, com cabeça e tronco visíveis; para corpo inteiro, deixe o corpo todo no quadro.
- Evite luz solar direta ou reflexos fortes na cena, pois o IR do Kinect pode saturar.
- Aguarde 1 a 2 segundos para o SDK fechar o rastreamento após a pessoa entrar no quadro.

## Uso

1. Abra `kinect_skeleton_demo.lpi` no Lazarus ou compile com `lazbuild kinect_skeleton_demo.lpi`.
2. Execute o demo e clique em **Conectar**.
3. Deixe **Vídeo de fundo** marcado para sobrepor o esqueleto ao RGB.
4. **Modo sentado** vem ativo por padrão; desmarque antes de conectar se quiser tentar rastreamento de corpo inteiro.
5. Ajuste **Suavização** antes de conectar para reduzir tremor das juntas.
6. Quando uma pose completa for identificada, o demo salva uma foto automaticamente em `captures\pose_*.bmp`, com pontos, ossos e nomes das partes capturadas.
7. Clique em **Exportar pose** para salvar a pose atual em JSON.

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

1. Conecte o sensor sem pessoa na frente: o vídeo deve aparecer e `Corpos: 0` deve permanecer no painel.
2. Fique a cerca de 2 m: o esqueleto deve aparecer sobre o corpo, acompanhando o movimento com baixa latência, e uma foto deve ser salva em `captures`.
3. Ative **Modo sentado**, reconecte e sente-se: o rastreamento deve focar a parte superior do corpo.
4. Clique em **Exportar pose**: o JSON deve abrir em qualquer validador e conter 20 juntas por corpo.
5. Desconecte e reconecte o Kinect: o demo não deve travar.
