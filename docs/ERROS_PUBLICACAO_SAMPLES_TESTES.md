# Erros de publicação, samples e testes

- **Data do levantamento:** 25/10/2026.
- **Repositório:** `marcelomaurin/CHATGPT`.
- **Branch analisada:** `main`.
- **Commit dos fontes analisados:** `1e19b9dec93386e822694893b6a3784b11398142`.
- **Estado dos erros abaixo:** **ABERTO**.
- **Escopo deste registro:** documentar os erros encontrados nos fontes, pacotes, registros de componentes, inventários e automação. As correções permanecem pendentes.

Os links de evidência apontam para o commit analisado, para preservar a reprodução mesmo quando a branch avançar. A [baseline histórica de qualidade](quality/baseline.md) descreve outro snapshot; seus números não foram usados como números atuais.

## 1. Resumo dos erros

| ID | Prioridade | Erro confirmado | Situação |
| --- | --- | --- | --- |
| ERR-ENTREGA-001 | Alta | Pacotes Marlin e WebRTC ausentes de `profiles.all` | Aberto; verificador do manifesto reprovado |
| ERR-ENTREGA-002 | Alta | `TAIChromiumBrowser` com registro no fonte, fora dos pacotes de distribuição | Aberto; análise de fonte e registro |
| ERR-ENTREGA-003 | Alta | `TAISpeakerIdentifier` com registro no fonte, fora dos pacotes de distribuição | Aberto; análise de fonte e registro |
| ERR-ENTREGA-004 | Média | Oito projetos de exemplo fora do inventário | Aberto; verificador de samples reprovado |
| ERR-ENTREGA-005 | Média | Exemplo console Marlin ignorado pela descoberta e compilação automáticas de samples | Aberto; análise dos scanners e do projeto |
| ERR-ENTREGA-006 | Alta | Unidade runtime de ações de código importa recursos de design-time | Aberto; verificador de fronteiras reprovado |
| ERR-ENTREGA-007 | Alta | Falta execução geral dos testes Pascal existentes na CI | Aberto; análise dos workflows e executores |
| ERR-ENTREGA-008 | Alta | Chamada JavaScript do Chromium incompatível com o CEF declarado | Aberto no Git; ajuste compilado somente na cópia local |
| ERR-ENTREGA-009 | Alta | Registro variante V4L2 com sintaxe inválida | Aberto; bloqueia openai_input em Linux |
| ERR-ENTREGA-010 | Alta | Tipo TTimeVal ausente na compilação Unix do Modbus | Aberto; bloqueia três exemplos históricos |

**Critério de prioridade:** alta para bloqueio da validação, distribuição incompleta ou ausência de execução geral dos testes; média para lacunas de descoberta/classificação de exemplos.

## 2. Erros de publicação dos componentes

### ERR-ENTREGA-001 — Marlin e WebRTC fora do perfil de instalação completo

**Estado:** aberto. **Prioridade:** alta.

**Evidência:**

- Existem **28 arquivos `.lpk`** em `pacote/packages/`.
- O perfil `profiles.all` contém **26 pacotes**.
- Estão ausentes `openai_marlin` e `openai_webrtc`, cujos arquivos existem no repositório.
- Fontes: [manifesto de dependências](https://github.com/marcelomaurin/CHATGPT/blob/1e19b9dec93386e822694893b6a3784b11398142/installer/dependencies.json#L95), [pacote Marlin](https://github.com/marcelomaurin/CHATGPT/blob/1e19b9dec93386e822694893b6a3784b11398142/pacote/packages/openai_marlin.lpk) e [pacote WebRTC](https://github.com/marcelomaurin/CHATGPT/blob/1e19b9dec93386e822694893b6a3784b11398142/pacote/packages/openai_webrtc.lpk).
- [process_packages](https://github.com/marcelomaurin/CHATGPT/blob/1e19b9dec93386e822694893b6a3784b11398142/installer/common/install_suite.py#L279) compara os pacotes presentes com o perfil completo e retorna falha quando encontra essa diferença.

**Impacto:** o perfil completo não representa todos os pacotes publicados no Git e sua verificação é reprovada. A presença dos fontes não assegura sua entrega pelo instalador.

**Reprodução, a partir da raiz do repositório:**

```console
python3 installer/common/verify_manifest.py
```

Resultado reproduzido, com **código de saída 1**:

```text
[ERRO] somente no Git: ['openai_marlin', 'openai_webrtc']; somente no manifesto: []
```

**Critério de encerramento:**

- [ ] Incluir os pacotes no perfil completo, com ordem e dependências corretas.
- [ ] Obter aprovação do verificador do manifesto.
- [ ] Compilar e validar a instalação dos pacotes nas plataformas efetivamente suportadas.

### ERR-ENTREGA-002 — TAIChromiumBrowser não integrado aos pacotes

**Estado:** aberto. **Prioridade:** alta.

**Evidência:**

- [aichromiumbrowser.pas](https://github.com/marcelomaurin/CHATGPT/blob/1e19b9dec93386e822694893b6a3784b11398142/pacote/AI%20Input/AIChromiumBrowser/aichromiumbrowser.pas#L366) declara `RegisterComponents('AI Communication', [TAIChromiumBrowser])`.
- A unidade não está na lista de arquivos de nenhum dos 28 pacotes `.lpk` analisados.
- [registro de openai_input](https://github.com/marcelomaurin/CHATGPT/blob/1e19b9dec93386e822694893b6a3784b11398142/pacote/packages/openai_input.pas) não chama seu `Register`.
- O [fonte do exemplo Chromium](https://github.com/marcelomaurin/CHATGPT/blob/1e19b9dec93386e822694893b6a3784b11398142/pacote/samples/AI%20Input/chromium_capture_demo/main.pas#L7) usa `aichromiumbrowser` e declara uma instância de `TAIChromiumBrowser`.

**Impacto:** existe implementação e declaração de registro, mas falta o caminho de publicação pelo pacote para disponibilizar automaticamente o componente na paleta. O exemplo depende dessa unidade. A compilação do exemplo em instalação limpa ainda precisa ser verificada.

**Critério de encerramento:**

- [ ] Definir o pacote responsável pelo componente e declarar suas dependências CEF.
- [ ] Incluir a unidade no `.lpk` e efetivar a chamada de registro no pacote.
- [ ] Confirmar o componente na paleta de uma instalação limpa do Lazarus.
- [ ] Compilar e executar o exemplo Chromium com o runtime correspondente.

### ERR-ENTREGA-003 — TAISpeakerIdentifier não integrado aos pacotes

**Estado:** aberto. **Prioridade:** alta.

**Evidência:**

- [aispeakersignature.pas](https://github.com/marcelomaurin/CHATGPT/blob/1e19b9dec93386e822694893b6a3784b11398142/pacote/AI%20Input/AIAudio/aispeakersignature.pas#L145) declara `RegisterComponents('AI Communication', [TAISpeakerIdentifier])`.
- Essa unidade não está na lista de arquivos de nenhum dos 28 pacotes `.lpk` analisados.
- [registro de openai_input](https://github.com/marcelomaurin/CHATGPT/blob/1e19b9dec93386e822694893b6a3784b11398142/pacote/packages/openai_input.pas) não chama seu `Register`.
- O [projeto de demonstração](https://github.com/marcelomaurin/CHATGPT/blob/1e19b9dec93386e822694893b6a3784b11398142/pacote/samples/AI%20Input/speaker_signature_demo/speaker_signature_demo.lpi) acrescenta diretamente `AI Input/AIAudio` a `OtherUnitFiles`. Esse acesso ao fonte permite usar a unidade sem comprovar sua publicação na paleta pelo pacote.

**Divergência documental associada:** [PENDENCIAS_ASSINATURA_VOCAL.md](https://github.com/marcelomaurin/CHATGPT/blob/1e19b9dec93386e822694893b6a3784b11398142/docs/PENDENCIAS_ASSINATURA_VOCAL.md) declara em 22/10/2026 o estado “CONCLUÍDO / PRODUÇÃO (100% FEITO)” e a integração na paleta/pacote. A integração de distribuição deve ser reaberta conforme os arquivos atuais de pacote. Os testes funcionais históricos citados nesse documento não foram reexecutados neste levantamento.

**Impacto:** o componente pode ser usado pelo fonte diretamente, mas não é publicado automaticamente pela instalação dos pacotes analisados.

**Critério de encerramento:**

- [ ] Incluir a unidade e sua chamada de registro no pacote responsável.
- [ ] Confirmar a publicação na paleta em instalação limpa.
- [ ] Validar a compilação do demo utilizando o pacote corretamente configurado.
- [ ] Alinhar o estado da documentação de assinatura vocal à validação da integração.

## 3. Erros de samples

### ERR-ENTREGA-004 — Oito exemplos existentes não classificados

**Estado:** aberto. **Prioridade:** média.

Foram encontrados **137 projetos `.lpi`** sob `pacote/samples/`, aplicando a regra do scanner que exclui diretórios chamados `backup`. O [inventário de samples](https://github.com/marcelomaurin/CHATGPT/blob/1e19b9dec93386e822694893b6a3784b11398142/tests/samples_inventory.json) contém **129 entradas**.

Os oito projetos abaixo **existem nos fontes**, mas não constam no inventário:

| Projeto | Fonte |
| --- | --- |
| `webrtc_datachannel_demo` | [AI Communication/webrtc_datachannel_demo/webrtc_datachannel_demo.lpi](https://github.com/marcelomaurin/CHATGPT/blob/1e19b9dec93386e822694893b6a3784b11398142/pacote/samples/AI%20Communication/webrtc_datachannel_demo/webrtc_datachannel_demo.lpi) |
| `avatar_agent_demo` | [AI Graphic/avatar_agent_demo/avatar_agent_demo.lpi](https://github.com/marcelomaurin/CHATGPT/blob/1e19b9dec93386e822694893b6a3784b11398142/pacote/samples/AI%20Graphic/avatar_agent_demo/avatar_agent_demo.lpi) |
| `avatar_basic_demo` | [AI Graphic/avatar_basic_demo/avatar_basic_demo.lpi](https://github.com/marcelomaurin/CHATGPT/blob/1e19b9dec93386e822694893b6a3784b11398142/pacote/samples/AI%20Graphic/avatar_basic_demo/avatar_basic_demo.lpi) |
| `avatar_full_demo` | [AI Graphic/avatar_full_demo/avatar_full_demo.lpi](https://github.com/marcelomaurin/CHATGPT/blob/1e19b9dec93386e822694893b6a3784b11398142/pacote/samples/AI%20Graphic/avatar_full_demo/avatar_full_demo.lpi) |
| `avatar_voice_demo` | [AI Graphic/avatar_voice_demo/avatar_voice_demo.lpi](https://github.com/marcelomaurin/CHATGPT/blob/1e19b9dec93386e822694893b6a3784b11398142/pacote/samples/AI%20Graphic/avatar_voice_demo/avatar_voice_demo.lpi) |
| `kinect_perception_demo` | [AI Input/kinect_perception_demo/kinect_perception_demo.lpi](https://github.com/marcelomaurin/CHATGPT/blob/1e19b9dec93386e822694893b6a3784b11398142/pacote/samples/AI%20Input/kinect_perception_demo/kinect_perception_demo.lpi) |
| `speaker_signature_demo` | [AI Input/speaker_signature_demo/speaker_signature_demo.lpi](https://github.com/marcelomaurin/CHATGPT/blob/1e19b9dec93386e822694893b6a3784b11398142/pacote/samples/AI%20Input/speaker_signature_demo/speaker_signature_demo.lpi) |
| `face_recognition_demo` | [AI Vision/face_recognition_demo/face_recognition_demo.lpi](https://github.com/marcelomaurin/CHATGPT/blob/1e19b9dec93386e822694893b6a3784b11398142/pacote/samples/AI%20Vision/face_recognition_demo/face_recognition_demo.lpi) |

**Impacto:** o verificador de inventário reprova a divergência. O executor [compile_all_samples.py](https://github.com/marcelomaurin/CHATGPT/blob/1e19b9dec93386e822694893b6a3784b11398142/tests/compile_all_samples.py), que usa esse inventário, não seleciona os oito projetos ausentes. O script Linux que varre os arquivos `.lpi` diretamente possui outro mecanismo de seleção; não se deve generalizar a omissão para ambos os executores.

**Reprodução:**

```console
python3 tests/ci_validate_samples.py
```

Resultado reproduzido, com **código de saída 1**:

```text
[ERRO] Samples novos no disco não classificados no inventário (8):
```

A lista emitida pelo comando corresponde aos oito projetos da tabela.

**Critério de encerramento:**

- [ ] Classificar os oito projetos, conferindo plataforma, dependências e requisitos de execução.
- [ ] Obter aprovação do verificador de inventário.
- [ ] Compilar os exemplos nas plataformas declaradas e registrar os resultados.

### ERR-ENTREGA-005 — Sample console Marlin fora da automação

**Estado:** aberto. **Prioridade:** média.

**Evidência:**

- Existe [marlin_console.lpr](https://github.com/marcelomaurin/CHATGPT/blob/1e19b9dec93386e822694893b6a3784b11398142/pacote/samples/AI%20Simulation/marlin_console/marlin_console.lpr), com leitura de comandos da entrada padrão e execução do simulador.
- Não há `marlin_console.lpi` correspondente.
- [scanner do inventário](https://github.com/marcelomaurin/CHATGPT/blob/1e19b9dec93386e822694893b6a3784b11398142/tests/ci_validate_samples.py#L16) descobre somente `*.lpi`.
- [executor baseado no inventário](https://github.com/marcelomaurin/CHATGPT/blob/1e19b9dec93386e822694893b6a3784b11398142/tests/compile_all_samples.py) e [compilador de samples Linux](https://github.com/marcelomaurin/CHATGPT/blob/1e19b9dec93386e822694893b6a3784b11398142/tools/ci/compile_samples_linux_x64.sh) não oferecem uma rota de descoberta/compilação desse programa console.

**Impacto:** o exemplo existe, mas sua existência e compilação não ficam cobertas pela automação atual de samples.

**Critério de encerramento:**

- [ ] Incluir o programa em uma rota explícita para exemplos console FPC, ou fornecer um projeto Lazarus válido para ele.
- [ ] Garantir que a compilação desse exemplo seja executada pela automação e que falhas produzam resultado reprovado.
- [ ] Adicionar uma execução determinística de demonstração, com entrada e saída esperadas documentadas.

## 4. Erros nas ferramentas e na execução de testes

### ERR-ENTREGA-006 — Recursos Lazarus em unidade runtime bloqueiam a validação

**Estado:** aberto. **Prioridade:** alta.

**Evidência:**

- [aiagent_sourceactions.pas](https://github.com/marcelomaurin/CHATGPT/blob/1e19b9dec93386e822694893b6a3784b11398142/pacote/AI%20Agent/aiagent_sourceactions.pas#L9) importa `LResources`.
- A mesma unidade inclui `aiagent_sourceactions_icon.lrs` em `initialization`, na linha 670 do snapshot.
- A unidade pertence à lista `RUNTIME_UNITS` de [validate_runtime_units.py](https://github.com/marcelomaurin/CHATGPT/blob/1e19b9dec93386e822694893b6a3784b11398142/tools/ci/validate_runtime_units.py), que exige a separação desses recursos.
- Existe [unidade separada de registro](https://github.com/marcelomaurin/CHATGPT/blob/1e19b9dec93386e822694893b6a3784b11398142/pacote/AI%20Agent/aiagent_sourceactions_register.pas) para a integração de design-time.

**Reprodução:**

```console
python3 tools/ci/validate_runtime_units.py
```

Resultado reproduzido, com **código de saída 1**:

```text
[PASS] pacote/AI/aibase.pas
[PASS] pacote/AI Agent/aiagent_actions.pas
[FAIL] pacote/AI Agent/aiagent_sourceactions.pas
       design-time unit 'lresources' imported by runtime
       .lrs resource included by runtime

2 boundary violation(s).
```

**Impacto confirmado na CI do commit analisado:**

- [Unit & Guard Tests — execução de 22/10/2026](https://github.com/marcelomaurin/CHATGPT/actions/runs/39807578621): falha na validação de fronteiras; as verificações seguintes de ícones e inventário foram ignoradas.
- [FGX Core — execução de 22/10/2026](https://github.com/marcelomaurin/CHATGPT/actions/runs/39807578424): falha na mesma validação; compilação e execução dos testes FGX foram ignoradas.
- [Samples Linux x64 — execução de 22/10/2026](https://github.com/marcelomaurin/CHATGPT/actions/runs/39807578350): falha antes da resolução/compilação dos pacotes e da compilação dos samples; essas etapas ficaram com estado `skipped`.

Esses resultados demonstram bloqueio das etapas, não falha de compilação dos exemplos que não chegaram a ser compilados.

**Critério de encerramento:**

- [ ] Separar os recursos de paleta/design-time da unidade runtime, preservando a funcionalidade das ações.
- [ ] Obter aprovação do verificador de fronteiras.
- [ ] Reexecutar a CI e conferir os resultados das etapas que estavam bloqueadas.

### ERR-ENTREGA-007 — Suíte Pascal sem execução geral na CI

**Estado:** aberto. **Prioridade:** alta.

**Evidência:**

- [unit-tests.yml](https://github.com/marcelomaurin/CHATGPT/blob/1e19b9dec93386e822694893b6a3784b11398142/.github/workflows/unit-tests.yml) prepara Python e executa verificadores estruturais; não instala FPC/Lazarus nem compila/executa os programas Pascal de teste.
- Existem programas de teste em `tests/` e `pacote/tests/`, incluindo [assinatura vocal](https://github.com/marcelomaurin/CHATGPT/blob/1e19b9dec93386e822694893b6a3784b11398142/tests/test_speaker_signature.lpr), [Marlin](https://github.com/marcelomaurin/CHATGPT/blob/1e19b9dec93386e822694893b6a3784b11398142/tests/test_marlin_components.lpr), [streaming LLM](https://github.com/marcelomaurin/CHATGPT/blob/1e19b9dec93386e822694893b6a3784b11398142/pacote/tests/llm_provider_streaming_test/llm_provider_streaming_test.lpr), [MCP](https://github.com/marcelomaurin/CHATGPT/blob/1e19b9dec93386e822694893b6a3784b11398142/pacote/tests/mcp_protocol_test/mcp_protocol_test.lpr) e [pipeline de voz](https://github.com/marcelomaurin/CHATGPT/blob/1e19b9dec93386e822694893b6a3784b11398142/pacote/tests/voice_pipeline_test/voice_pipeline_test.lpr).
- [run_marlin_tests.ps1](https://github.com/marcelomaurin/CHATGPT/blob/1e19b9dec93386e822694893b6a3784b11398142/tests/run_marlin_tests.ps1) compila e executa três testes Marlin/serial localmente, mas não é chamado pelos workflows analisados.
- A análise dos **seis workflows** do snapshot não identificou uma execução geral desses diretórios de teste.
- Há execuções específicas já previstas para testes do núcleo FGX e smoke test C do bridge MediaPipe. Compilar samples é outra atividade e não substitui executar os testes de comportamento.

**Impacto:** a configuração atual permite que testes existentes fiquem sem execução automática e sem resultados agregados por plataforma. O nome “Unit Tests” não representa uma execução geral da suíte Pascal.

**Critério de encerramento:**

- [ ] Definir um inventário de programas de teste, com plataformas e dependências.
- [ ] Implementar uma rota que compile e execute os testes suportados e retorne falha se algum reprovar.
- [ ] Integrar essa rota à CI, com relatório individual e agregado.
- [ ] Declarar explicitamente testes dependentes de hardware, serviços ou runtimes; registrar os casos não executados e o motivo.

## 5. Ordem sugerida de correção

1. **ERR-ENTREGA-006:** liberar a validação de fronteiras que bloqueia etapas posteriores.
2. **ERR-ENTREGA-001:** alinhar o perfil completo do instalador aos pacotes existentes.
3. **ERR-ENTREGA-002 e 003:** completar a publicação dos componentes na paleta e conferir suas dependências.
4. **ERR-ENTREGA-004 e 005:** incluir os exemplos ausentes das rotas de inventário/compilação.
5. **ERR-ENTREGA-007:** integrar a execução geral dos testes Pascal e consolidar os resultados.

## 6. Verificação realizada e limites

| Verificação | Resultado |
| --- | --- |
| Cruzamento dos 28 pacotes `.lpk` com seus arquivos de registro e a árvore versionada | Listas de arquivos existentes; chamadas `RegisterUnit` conferem com os sinalizadores `HasRegisterProc` declarados nos pacotes |
| Conferência dos fontes de Chromium e assinatura vocal | Declarações de registro encontradas, unidades fora das listas dos pacotes |
| Conferência dos 137 projetos `.lpi` e do inventário de 129 entradas | Oito projetos ausentes do inventário |
| `verify_manifest.py` | Reprovado: Marlin e WebRTC ausentes |
| `ci_validate_samples.py` | Reprovado: oito exemplos sem classificação |
| `validate_runtime_units.py` | Reprovado: duas violações em uma unidade |
| Consulta dos resultados remotos da CI do commit analisado | Bloqueios e etapas ignoradas confirmados conforme ERR-ENTREGA-006 |

Os três verificadores foram executados sobre os arquivos do snapshot obtidos do GitHub; não foi realizada uma compilação completa da biblioteca, uma instalação limpa do Lazarus nem a execução geral dos programas Pascal neste levantamento. Este registro não representa uma contagem exaustiva de componentes sem exemplo ou sem teste funcional.

Para encerrar cada erro, registrar neste documento o commit da correção, os comandos executados, a plataforma e o resultado efetivamente obtido.

## 7. Erros confirmados pela compilação das branches em 25/10/2026

O [relatório da rodada de compilação](COMPILACAO_BRANCHES_2026-10-25.md) registra os commits, toolchain, alvos, comandos e resultados. Foram aprovadas 44 verificações de voz e 14 casos FPCUnit de impressão; os sete erros anteriores continuam sujeitos aos seus critérios de encerramento.

### ERR-ENTREGA-008 — Chamada JavaScript incompatível com CEF4Delphi

**Estado:** aberto no código versionado. **Prioridade:** alta.

- **Fonte:** [aichromiumbrowser.pas:1578](https://github.com/marcelomaurin/CHATGPT/blob/f8e335fba391c77556f7e1cbc6b1a8629d87b9a9/pacote/AI%20Input/AIChromiumBrowser/aichromiumbrowser.pas#L1578).
- **Ambiente:** FPC 3.2.2, Linux x86_64; CEF4Delphi `84d5f7670056aed6753bf4dc855a5cb3e468fd60`, conforme manifesto.
- **Erro:** `Incompatible type for arg no. 3: Got "ShortInt", expected "ICefFrame"`, na linha 1582.
- **Causa observada:** a chamada `ExecuteJavaScript(AScript, DefaultUrl, 0)` não corresponde à API do CEF declarado.
- **Impacto:** a unidade do navegador não compila nesse conjunto de fontes/dependências.
- **Verificação adicional:** a unidade compilou na cópia local usando a sobrecarga de cinco argumentos `(AScript, DefaultUrl, '', '', 0)`, que seleciona o frame principal conforme implementação do CEF. Essa adaptação não foi aplicada às branches remotas nem à `main`.
- **Critério de encerramento:** versionar a adaptação compatível, recompilar a unidade/pacote e validar execução de JavaScript no frame esperado.

### ERR-ENTREGA-009 — Registro variante V4L2 impede compilar openai_input

**Estado:** aberto. **Prioridade:** alta.

- **Fonte:** [aicamera_v4l2.pas:159](https://github.com/marcelomaurin/CHATGPT/blob/f8e335fba391c77556f7e1cbc6b1a8629d87b9a9/pacote/AI%20Vision/aicamera_v4l2.pas#L159).
- **Reprodução:** compilação de `pacote/packages/openai_input.lpk` da branch `fix/lazarus-packages-20260916` com FPC 3.2.2/Lazarus 3.0, Linux x86_64.
- **Erro:** `Syntax error, "(" expected but ":" found`, na linha 175.
- **Causa observada:** campos comuns (`length`, `reserved2`, `request_fd`) aparecem após a parte variante `case Integer of` do registro `v4l2_buffer`.
- **Impacto:** o pacote completo de entrada permanece sem compilar, inclusive após contornar localmente ERR-ENTREGA-008.
- **Critério de encerramento:** corrigir a organização do registro/union, conferir seu tamanho e offsets contra a ABI V4L2 dos targets suportados, e recompilar o pacote. A validação de câmera real permanece necessária.

### ERR-ENTREGA-010 — TTimeVal ausente na compilação Unix do Modbus

**Estado:** aberto. **Prioridade:** alta.

- **Fonte:** [aimodbus.pas:245](https://github.com/marcelomaurin/CHATGPT/blob/3affa4e6a01c2148e537aed4efdb6a2ee6d499b0/pacote/AI%20Industrial/aimodbus.pas#L245).
- **Reprodução:** compilação de `wizard_config_demo`, `training_exporter_demo` e `training_report_demo` no commit `3affa4e6a01c2148e537aed4efdb6a2ee6d499b0`, FPC 3.2.2/Lazarus 3.0, Linux x86_64.
- **Erros:** `Identifier not found "TTimeVal"` e `Error in type definition` na linha 245; `Illegal qualifier` nas linhas 268 e 269.
- **Impacto:** os três exemplos históricos param na unidade Modbus de sua cadeia de dependências e não geram executáveis.
- **Critério de encerramento:** disponibilizar o tipo Unix adequado para os timeouts de socket e suas referências, recompilar os três projetos e validar a configuração de timeout.

As unidades dos três erros possuem blobs idênticos às unidades da `main` auditada anteriormente. O relatório detalha essa conferência e distingue os builds das branches da integração completa na `main`.
