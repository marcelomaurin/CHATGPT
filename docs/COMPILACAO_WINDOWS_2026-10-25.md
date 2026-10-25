# Compilação nativa no Windows — 25/10/2026

**Resultado:** o Modbus corrigido da `main` compilou em Windows x64. Os três pacotes selecionados da `main`, os pacotes e demos de voz/impressão das branches e dois exemplos históricos também compilaram. Foram executadas **44 verificações de voz e 14 testes de impressão, sem falhas**.

O Chromium original permanece com erro de assinatura da API CEF e bloqueia três exemplos históricos. O ajuste local de cinco argumentos fez a unidade e o pacote `openai_input` da branch de pacotes compilarem no Windows. Esse ajuste não foi integrado aos fontes da `main` nesta rodada.

## 1. Execução e evidências

- [Execução nativa no GitHub Actions](https://github.com/marcelomaurin/CHATGPT/actions/runs/40222836007).
- [Job com instalação da toolchain e compilação](https://github.com/marcelomaurin/CHATGPT/actions/runs/40222836007/job/121257925761).
- [Artefato com resultados JSON, relatório, logs completos e executáveis](https://github.com/marcelomaurin/CHATGPT/actions/runs/40222836007/artifacts/12609618751).
- [Script exato utilizado](https://github.com/marcelomaurin/CHATGPT/blob/4cbbbe1ae2bfb73c5709bf1c3f32bd60df10dd3d/tools/ci/validate_windows_branches.py).
- [Workflow exato utilizado](https://github.com/marcelomaurin/CHATGPT/blob/4cbbbe1ae2bfb73c5709bf1c3f32bd60df10dd3d/.github/workflows/windows-branch-validation.yml).

O arquivo ZIP do artefato foi obtido e seu SHA-256 conferido:

```text
70f55c20f9790286cb093c6cbb30ea56fce28ec630e56fb9298b5aa1196791ae
```

O workflow terminou com `failure` porque registra também as quatro tentativas bloqueadas: Chromium original e três exemplos históricos. Os resultados individuais abaixo distinguem essas falhas das aprovações. O artefato foi publicado mesmo com a falha agregada e tem retenção configurada de 30 dias.

## 2. Ambiente e fontes

| Item | Valor confirmado nos logs |
| --- | --- |
| Runner | GitHub-hosted `windows-2025` |
| Compilador | Free Pascal 3.2.2, executável nativo Windows |
| CPU/OS do compilador | `x86_64` / `win64` |
| Lazarus | 3.0 |
| Widgetset LCL | `win32`, inclusive para os binários x64 |
| Perfil | Configuração Lazarus isolada para cada snapshot |

`sys.platform = win32` no relatório identifica a plataforma Windows do Python; o target do FPC foi confirmado separadamente como `x86_64-win64`. Os seis executáveis arquivados também tiveram os cabeçalhos inspecionados: assinatura PE válida e máquina `0x8664` (AMD64).

| Snapshot | Branch de origem | Commit compilado |
| --- | --- | --- |
| Main, incluindo a correção Modbus | `main` | `56034debfc03a322d4d75ba471dc90e25adb3b4c` |
| Voz | `feat/voice-provider-refactor` | `838d24158dab7fa19df0f565c83b000da77d3095` |
| Impressão | `fix/posprinter-real-protocols` | `d3682ea1bab4816555e74a720356e267e4cbfac0` |
| Entrada/Chromium | `fix/lazarus-packages-20260916` | `f8e335fba391c77556f7e1cbc6b1a8629d87b9a9` |
| Exemplos históricos | `codex/taidependencygraph` | `3affa4e6a01c2148e537aed4efdb6a2ee6d499b0` |

Dependências fixadas nos mesmos commits da rodada Linux:

| Dependência | Commit |
| --- | --- |
| CEF4Delphi | `84d5f7670056aed6753bf4dc855a5cb3e468fd60` |
| ZeosLib | `66c3ce219893fca03247d7653a0b140bd8011e27` |
| DCPcrypt | `14586ed66d15fd91530ed5dfaab8a8e4bb8959ff` |

As compilações Lazarus usaram `--ws=win32 --skip-dependencies --build-all`, com caminhos de fontes/units configurados. Os programas de teste e as unidades isoladas foram compilados diretamente com FPC. Os logs preservam os comandos completos, os caminhos e os diagnósticos.

## 3. Compilações aprovadas

| Snapshot | Alvo | Saída | Log no artefato |
| --- | --- | ---: | --- |
| Main | `pacote/AI Industrial/aimodbus.pas` corrigido | 0 | `logs/main-modbus-timeval-build.log` |
| Main | `openai_input.lpk` | 0 | `logs/main-openai_input.log` |
| Main | `openai_voice.lpk` | 0 | `logs/main-openai_voice.log` |
| Main | `openai_output.lpk` | 0 | `logs/main-openai_output.log` |
| Voz | `openai_voice.lpk` | 0 | `logs/voice-package.log` |
| Voz | `voice_remote_provider_demo.lpi` | 0 | `logs/voice-demo.log` |
| Voz | `tests/test_voice_providers.lpr` | 0 | `logs/voice-tests-build.log` |
| Impressão | `openai_output.lpk` | 0 | `logs/printer-package.log` |
| Impressão | `posprinter_demo.lpi` | 0 | `logs/printer-demo.log` |
| Impressão | `pacote/tests/test_openai_output.lpr` | 0 | `logs/printer-tests-build.log` |
| Entrada/Chromium | Unidade Chromium, após ajuste local explícito | 0 | `logs/chromium-local-compatibility-build.log` |
| Entrada/Chromium | `openai_input.lpk`, após o mesmo ajuste local | 0 | `logs/chromium-package-after-local-patch.log` |
| Histórico | `modelregistry_demo.lpi` | 0 | `logs/historical-modelregistry_demo.log` |
| Histórico | `promptbuilder_demo.lpi` | 0 | `logs/historical-promptbuilder_demo.log` |

Total: **14 compilações aprovadas em 18 tentativas**. Há avisos nos logs; aprovação de compilação não equivale a ausência de avisos.

A aprovação de `openai_input` da `main` não encerra a falta de publicação do Chromium: nesse snapshot, a unidade não faz parte do pacote (ERR-ENTREGA-002). Sua compilação direta foi verificada separadamente na branch de pacotes, primeiro com o fonte original e depois com o ajuste local indicado.

## 4. Testes executados no Windows

| Programa | Resultado | Log no artefato |
| --- | --- | --- |
| `test_voice_providers.exe` | 44 verificações; 44 aprovadas; 0 falhas; saída 0 | `logs/voice-tests-run.log` |
| `test_openai_output.exe --all --format=plain` | 14 testes; 0 erros; 0 falhas; saída 0 | `logs/printer-tests-run.log` |

Saídas finais conferidas:

```text
Tests Completed: 44 | Passed: 44 | Failed: 0

Number of run tests: 14
Number of errors:    0
Number of failures:  0
```

Voz: provedores, aliases, validações, armazenamento e recuperação do token de teste, backends e estado inicial/parada. A recuperação do token também passou no Windows. Backends provisórios continuam sendo testados como “não implementados”; essa aprovação não comprova síntese por provedores remotos.

Impressão: comandos ESC/POS, TSPL, EPL, ZPL, code page e regras de corte. Os testes verificam protocolos/bytes, sem imprimir em equipamento físico.

## 5. Bloqueios confirmados

| Alvo original | Saída | Diagnóstico |
| --- | ---: | --- |
| `aichromiumbrowser.pas` | 1 | Argumento 3 incompatível: `ShortInt`, esperado `ICefFrame` |
| `wizard_config_demo.lpi` | 2 | Mesmo erro Chromium/CEF |
| `training_exporter_demo.lpi` | 2 | Mesmo erro Chromium/CEF |
| `training_report_demo.lpi` | 2 | Mesmo erro Chromium/CEF |

Os quatro logs registram o erro na linha 1582 da unidade Chromium. Os três exemplos históricos não foram bloqueados pelo `TTimeVal` no Windows: chegaram à unidade Chromium.

Na cópia descartável da branch de pacotes foi aplicada exclusivamente a adaptação da chamada para a sobrecarga de cinco argumentos:

```pascal
FChromiumWindow.ChromiumBrowser.ExecuteJavaScript(
  AScript,
  FChromiumWindow.ChromiumBrowser.DefaultUrl,
  '',
  '',
  0
);
```

Após esse ajuste, unidade e pacote compilaram em Windows. Ele permanece uma validação local, sem integração no fonte da `main`. Os exemplos históricos foram compilados sem esse ajuste; sua aprovação completa continua pendente.

O erro do registro V4L2 (ERR-ENTREGA-009) permanece pendente no Linux. No Windows, a unidade seleciona por compilação condicional a implementação substituta para plataformas não Linux; compilar esse ramo não valida o registro nem a ABI V4L2.

## 6. Situação do Modbus e limites

A correção [`7cb0cb9`](https://github.com/marcelomaurin/CHATGPT/commit/7cb0cb9b2c3c77971fec14e1f3e509360cd10be6), incluída no snapshot `56034deb`, agora possui comprovação de compilação da unidade em **Linux x64 e Windows x64**. Windows usa `DWORD` em milissegundos; Linux usa `UnixType.TTimeVal` com segundos/microssegundos. ERR-ENTREGA-010 deixa de ter compilação Windows pendente.

Continuam fora desta rodada: Windows x86, execução interativa das interfaces, JavaScript em navegador CEF real, teste efetivo dos timeouts Modbus, serial/RS485, câmera, impressora e chamadas remotas de voz. A rodada também não certifica instalador completo, integração das branches, registro de todos os componentes na paleta ou execução geral da suíte Pascal (ERR-ENTREGA-001 a 007).

O [registro de erros](ERROS_PUBLICACAO_SAMPLES_TESTES.md) e o [relatório Linux/original](COMPILACAO_BRANCHES_2026-10-25.md) preservam a distinção entre correção no fonte, compilação e validação funcional.

## 7. Rodada posterior: catálogo de provedores/modelos

Após esta rodada, o componente TCHATGPT recebeu a atualização de provedores e modelos documentada em [PROVEDORES_MODELOS_CHATGPT_2026-10-25.md](PROVEDORES_MODELOS_CHATGPT_2026-10-25.md). Os fontes atualizados foram compilados e seu teste de contratos executado nativamente em Windows x64 e Linux x64: **631 verificações aprovadas em cada plataforma**, com saída 0 na compilação e nos testes.

O [job Windows dessa atualização](https://github.com/marcelomaurin/CHATGPT/actions/runs/40225794759/job/121266756829) utilizou FPC 3.2.2 e Lazarus 4.0. Trata-se de uma execução distinta dos pacotes e snapshots das seções anteriores; ela não encerra os bloqueios Chromium/V4L2 nem substitui testes funcionais das APIs.
