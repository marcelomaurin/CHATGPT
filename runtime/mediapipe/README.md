# MediaPipe Pose Runtime Binaries

Este diretório contém o manifesto de carregamento e as subpastas para o runtime do **MediaPipe Pose Detector**.

> [!IMPORTANT]
> **Suporte exclusivo a 64-bit:** este componente suporta apenas arquiteturas 64-bit (`windows-x86_64` e `linux-x86_64`). Em 32-bit o componente deve compilar, mas reportar indisponível.

## Regra oficial de nome da DLL/SO

A DLL/SO da bridge deve ter nome **versionado**. O nome versionado é obrigatório como padrão porque registra a versão da nossa bridge, a versão compatível do MediaPipe e a arquitetura do binário.

Nome oficial Windows x64 desta fase:

```text
ai_mediapipe_pose_bridge_v1_0_0_mp0_10_35_win64.dll
```

Significado:

```text
ai_mediapipe_pose_bridge  = bridge nativa de pose
v1_0_0                    = versão da bridge/API
mp0_10_35                 = MediaPipe compatível: 0.10.35
win64                     = Windows 64-bit
```

O nome `mp_pose_bridge.dll` é aceito apenas como **fallback legado** para builds antigos. Ele não deve ser usado como nome principal porque perde o controle de versão e aumenta o risco de carregar uma bridge incompatível.

## Estrutura recomendada de subpastas

```text
runtime/
  mediapipe/
    pose/
      mp_0_10_35/
        windows-x86_64/
          ai_mediapipe_pose_bridge_v1_0_0_mp0_10_35_win64.dll
          bridge_manifest.json
          models/
            pose_landmarker_lite.task
            pose_landmarker_full.task
            pose_landmarker_heavy.task
          deps/
            *.dll
        linux-x86_64/
          libai_mediapipe_pose_bridge_v1_0_0_mp0_10_35_linux64.so
          bridge_manifest.json
          models/
            pose_landmarker_lite.task
            pose_landmarker_full.task
            pose_landmarker_heavy.task
          deps/
            *.so
```

## Seleção manual no demo

O demo deve permitir selecionar diretamente o arquivo versionado. O usuário não deve precisar renomear a DLL para `mp_pose_bridge.dll`.

Exemplo correto:

```text
D:\projetos\maurinsoft\CHATGPT\pacote\samples\AI MediaPipe Vision\ai_mediapipe_pose_bridge_v1_0_0_mp0_10_35_win64.dll
```

## Modelos (.task)

No backend `SIM`, os modelos `.task` não são exigidos.

No backend `REAL`, os arquivos de modelo de pose do MediaPipe devem ser colocados na pasta `models/` correspondente ao runtime da arquitetura, por exemplo:

```text
runtime/mediapipe/pose/mp_0_10_35/windows-x86_64/models/pose_landmarker_full.task
runtime/mediapipe/pose/mp_0_10_35/linux-x86_64/models/pose_landmarker_full.task
```

Os modelos esperados são:

- `pose_landmarker_lite.task` — mais rápido, menor precisão.
- `pose_landmarker_full.task` — equilibrado, recomendado por padrão.
- `pose_landmarker_heavy.task` — maior precisão, maior uso de CPU/recursos.

Você pode baixar os modelos pré-treinados do MediaPipe diretamente da documentação oficial do Google MediaPipe.
