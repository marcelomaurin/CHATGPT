# Correção do Chromium — 25/10/2026

## Problema e alteração

O componente `TAIChromiumBrowser` não compilava com o CEF4Delphi fixado no manifesto. A chamada JavaScript passava `0` no terceiro argumento, posição em que uma sobrecarga espera um `ICefFrame`.

A correção utiliza a sobrecarga de cinco argumentos:

```pascal
FChromiumWindow.ChromiumBrowser.ExecuteJavaScript(
  AScript,
  FChromiumWindow.ChromiumBrowser.DefaultUrl,
  '',
  '',
  0
);
```

No CEF4Delphi `84d5f7670056aed6753bf4dc855a5cb3e468fd60`, nomes e identificadores vazios levam à seleção de `Browser.MainFrame`. A chamada continua assíncrona; compilar não comprova a execução de JavaScript.

Também foram corrigidos dois bloqueios do demonstrador interno `AIChromiumBrowser_Test`: chamada ao método removido `GoogleSearch` e recurso `.res` ausente. A pesquisa Google fica no exemplo, que monta uma URL com `EncodeURLElement` e chama `Navigate`; nenhuma automação de site foi acrescentada ao componente.

## Verificação

- A unidade corrigida compilou localmente em Linux x64, FPC 3.2.2/Lazarus 3.0.
- O exemplo principal `chromium_capture_demo` também gerou executável Linux após resolver a referência local à biblioteca compartilhada X11.
- Os dois demonstradores e a unidade compilaram em runners nativos Windows x64 e Linux x64 pelo workflow `.github/workflows/chromium-compile.yml`.
- O executor usa CEF4Delphi, DCPcrypt e ZeosLib nos commits declarados em `installer/dependencies.json`, com perfis Lazarus isolados e `--skip-dependencies --build-all`.
- A rotina `tools/ci/compile_chromium.py` preserva logs, resultados individuais e executáveis em artefatos.

Os três projetos históricos (`wizard_config_demo`, `training_exporter_demo`, `training_report_demo`) são recompilados sobre `3affa4e6a01c2148e537aed4efdb6a2ee6d499b0`, com somente os fontes corrigidos de Chromium e Modbus sobrepostos. Essas tentativas são diagnósticas: o relatório mostra seus códigos de saída, mas elas não ocultam nem invalidam o resultado dos alvos atuais. No Linux, o bloqueio V4L2 já registrado ainda pode ser encontrado na cadeia.

Inicialização do CEF, JavaScript no frame principal, associação dos controles visuais e captura de páginas não foram exercitados. O pacote de entrada da main ainda não publica o Chromium automaticamente (ERR-ENTREGA-002); esta rodada compila a unidade explicitamente.

## Arquivos

- `pacote/AI Input/AIChromiumBrowser/aichromiumbrowser.pas`.
- `pacote/AI Input/AIChromiumBrowser/aichromiumbrowser_test_main.pas`.
- `pacote/AI Input/AIChromiumBrowser/AIChromiumBrowser_Test.res`.
- `tools/ci/compile_chromium.py`.
- `.github/workflows/chromium-compile.yml`.

O [registro de erros](ERROS_PUBLICACAO_SAMPLES_TESTES.md) acompanha ERR-ENTREGA-008 e o novo ERR-ENTREGA-011. A correção de registro/ABI V4L2 (ERR-ENTREGA-009) permanece fora desta alteração.

## Resultados remotos confirmados

Correção publicada em [9e62673](https://github.com/marcelomaurin/CHATGPT/commit/9e626737094110eac5be825e91185537a6b76d9d). O ajuste [0cc8a8b](https://github.com/marcelomaurin/CHATGPT/commit/0cc8a8bcc3931cfb6d648a525dedbea805daff56) altera somente o comando de registro de pacotes do executor para compatibilidade com Lazarus 3/4; os fontes do componente e dos demonstradores são iguais entre as rodadas.

| Plataforma | Ambiente | Evidência |
| --- | --- | --- |
| Linux x64 | FPC 3.2.2; Lazarus 3.0; widgetset nogui | [Job Linux](https://github.com/marcelomaurin/CHATGPT/actions/runs/40232556368/job/121287186870) |
| Windows x64 | FPC 3.2.2; Lazarus 4.0; widgetset win32 | [Job Windows](https://github.com/marcelomaurin/CHATGPT/actions/runs/40232944522/job/121288359824) |

| Alvo | Linux x64 | Windows x64 |
| --- | --- | --- |
| Unidade Chromium | Compilou (0) | Compilou (0) |
| chromium_capture_demo | Compilou (0) | Compilou (0) |
| AIChromiumBrowser_Test | Compilou (0) | Compilou (0) |
| wizard_config_demo (histórico) | Bloqueado por V4L2 (2) | Compilou (0) |
| training_exporter_demo (histórico) | Bloqueado por V4L2 (2) | Compilou (0) |
| training_report_demo (histórico) | Bloqueado por V4L2 (2) | Compilou (0) |

A rodada Windows aprovou as seis compilações. No Linux, os três alvos atuais compilaram; os três históricos ultrapassaram o erro Chromium e pararam em `aicamera_v4l2.pas(175,11)`, com `Syntax error, "(" expected but ":" found`, conforme ERR-ENTREGA-009. O workflow distingue alvos atuais obrigatórios e tentativas históricas diagnósticas; seu resultado não representa aprovação dos históricos Linux.

### Artefatos e reprodução

- [Linux: relatório, JSON, logs e executáveis](https://github.com/marcelomaurin/CHATGPT/actions/runs/40232556368/artifacts/12613154172).
- [Windows: relatório, JSON, logs e executáveis](https://github.com/marcelomaurin/CHATGPT/actions/runs/40232944522/artifacts/12614025716).
- [Executor versionado](https://github.com/marcelomaurin/CHATGPT/blob/0cc8a8bcc3931cfb6d648a525dedbea805daff56/tools/ci/compile_chromium.py).

Os artefatos têm retenção de 30 dias. Os resultados identificam os commits das dependências, target, comandos e os hashes dos dois fontes sobrepostos aos exemplos históricos. As sobreposições não representam integração desses exemplos à main. Avisos de compilação continuam nos logs; saída 0 não significa compilação sem avisos.

A primeira tentativa Windows desta rodada parou antes de compilar, porque Lazarus 4 rejeitou a forma `--add-package-link=arquivo`. O executor foi ajustado para `--add-package-link arquivo`; o job Windows acima confirma preparação e compilação concluídas. Essa falha da preparação não foi apresentada como erro do fonte Chromium.
