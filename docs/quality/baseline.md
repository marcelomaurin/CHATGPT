# Baseline de qualidade do projeto CHATGPT

Este documento registra a baseline factual usada pelo plano de estabilização. Os
números abaixo pertencem ao snapshot auditado; eles não são metas de produto e
não devem ser atualizados silenciosamente quando o `main` avançar.

## Snapshot auditado

| Campo | Valor medido |
| --- | --- |
| Repositório | `marcelomaurin/CHATGPT` |
| Branch nominal | `main` |
| Commit | `6d8983618e500edd60a95dc79006e6687b5ac078` |
| Data do diagnóstico | 15 de agosto de 2026 |
| Workflows presentes | 5 |

## Toolchains observadas

### Ambiente local de verificação

| Ferramenta | Versão/target observado | Comando usado |
| --- | --- | --- |
| Python | 3.12.6 | `python --version` |
| Lazarus/lazbuild | 4.4 | `C:\lazarus\lazbuild.exe --version` |
| Free Pascal | 3.2.2, `i386-win32` | `C:\lazarus\fpc\3.2.2\bin\i386-win32\fpc.exe -iV`, `-iTP` e `-iTO` |

Essas versões descrevem a máquina de verificação, não uma exigência do projeto.
O snapshot documenta como requisito público apenas Lazarus 3.x ou mais recente
e um FPC compatível em `INSTALL.md`.

### Toolchains declaradas pelo CI

| Workflow/contexto | Declaração no snapshot | Situação factual |
| --- | --- | --- |
| `unit-tests.yml` | Python 3.11 via `actions/setup-python@v5` | Python possui linha de versão; Lazarus/FPC não são instalados nesse workflow |
| `fgx-core.yml`, Windows | `gcarreno/setup-lazarus@v3.4.1`, Lazarus 4.4 | Lazarus está fixado; a versão do FPC fornecida pela action não é declarada no repositório |
| `fgx-core.yml`, Linux | `apt-get install fpc` em `ubuntu-latest` | versão flutuante do repositório da imagem |
| `package-baseline.yml` | `apt-get install lazarus` ou `choco install lazarus` em runners `*-latest` | Lazarus/FPC não estão fixados |
| `samples-linux-x64.yml` | Lazarus/FPC via `apt` em `ubuntu-24.04` | imagem do SO está definida; versões dos pacotes não estão fixadas |

Uma versão não declarada é registrada como **não fixada**, e não inferida a
partir de uma execução histórica.

## Workflows analisados

| Workflow | Plataformas | Responsabilidade observada |
| --- | --- | --- |
| `fgx-core.yml` | Linux e Windows | compilar e executar o núcleo factual FGX com FPC |
| `mp_pose_bridge_ci.yml` | Linux e Windows | compilar o bridge C/C++ simulado e executar smoke test C |
| `package-baseline.yml` | Linux e Windows | validar o manifesto, o instalador, os pacotes e os ícones |
| `samples-linux-x64.yml` | Linux x64 | registrar dependências/pacotes e compilar exemplos |
| `unit-tests.yml` | Linux e Windows | executar guards Python; não compila os programas Pascal de teste |

Esta tabela descreve a configuração versionada. Ela não afirma que uma execução
remota específica estava verde.

## Inventário medido

| Item | Quantidade | Definição usada |
| --- | ---: | --- |
| Pacotes do projeto | 26 | entradas únicas de `profiles.all`, correspondentes a `pacote/packages/*.lpk` |
| Dependências externas | 4 | entradas de `dependencies` em `installer/dependencies.json` |
| Componentes registrados | 226 | nomes de classe únicos encontrados por `tests/ci_validate_icons.py` |
| Recursos de ícone declarados | 226 | nomes únicos em chamadas `LazarusResources.Add` |
| Includes de `.lrs` | 170 | nomes únicos incluídos pelas units Pascal |
| Exemplos no inventário | 131 | entradas de `tests/samples_inventory.json`, todas com status `active` |
| Exemplos Windows + Linux | 78 | entradas cujo campo `platforms` contém `windows` e `linux` |
| Exemplos somente Windows | 53 | entradas cujo campo `platforms` contém somente `windows` |
| Projetos `.lpi` rastreados sob `pacote/samples` | 130 | arquivos retornados por `git ls-files` |
| Projetos descobertos pelo scanner do snapshot | 129 | `.lpi` após a regra que ignora qualquer segmento chamado `backup` |
| Programas Pascal nos diretórios canônicos de teste | 31 | `.lpr` sob `tests/` e `pacote/tests/` |
| Teste Pascal localizado dentro de um exemplo | 1 | `agent_serial_discovery_tests.lpr`, contado separadamente |

O total canônico de 31 programas é composto por 19 arquivos em `tests/` e 12 em
`pacote/tests/`. O arquivo de teste localizado em um exemplo não é ocultado: ele
fica fora desse total e deverá receber classificação explícita no inventário de
testes.

### Divergência conhecida no inventário de exemplos

No commit auditado, o guard de exemplos termina com código diferente de zero.
O inventário contém duas entradas que o scanner não descobre:

- `pacote/samples/AI Agent/action_builder_recovery_test/backup/action_builder_recovery_test.lpi` não existe no snapshot;
- `pacote/samples/AI Hardware/hardware_system_manager_demo/backup/hardware_system_manager_demo.lpi` existe, mas é excluído pela regra de `backup`.

Portanto, 131 é a quantidade declarada no inventário, e não uma afirmação de que
131 projetos válidos seriam compilados.

## Comandos de reprodução

Execute em um checkout limpo que contenha o commit auditado:

```console
git clone https://github.com/marcelomaurin/CHATGPT.git
cd CHATGPT
git checkout --detach 6d8983618e500edd60a95dc79006e6687b5ac078
git rev-parse HEAD
```

Registre a toolchain realmente resolvida no ambiente:

```console
python --version
lazbuild --version
fpc -iV
fpc -iTP
fpc -iTO
```

Valide pacotes, componentes e recursos:

```console
python installer/common/verify_manifest.py
python tests/ci_validate_icons.py
```

As saídas esperadas no snapshot incluem `26 pacotes`, `226` componentes, `226`
recursos e `170` includes de recursos.

Calcule o inventário e sua distribuição por plataforma:

```console
python -c "import collections,json,pathlib; x=json.loads(pathlib.Path('tests/samples_inventory.json').read_text(encoding='utf-8')); print('total=',len(x)); print(collections.Counter('+'.join(v['platforms']) for v in x.values()))"
python -c "import pathlib,subprocess; p=subprocess.check_output(['git','ls-files'],text=True).splitlines(); s=[x for x in p if x.startswith('pacote/samples/') and x.lower().endswith('.lpi')]; print('lpi_rastreados=',len(s)); print('descobertos=',sum('backup' not in pathlib.PurePosixPath(x).parts for x in s))"
python tests/ci_validate_samples.py
```

As duas primeiras linhas devem informar, respectivamente, 131 entradas
(`78 windows+linux`, `53 windows`) e `130/129` projetos. O último comando deve
falhar no snapshot e listar os dois caminhos documentados acima; esse erro é o
estado anterior a ser corrigido pelas `TASK-004` e `TASK-005`.

Conte os programas Pascal de teste e os workflows:

```console
python -c "import subprocess; p=subprocess.check_output(['git','ls-files'],text=True).splitlines(); print(sum(x.lower().endswith('.lpr') and (x.startswith('tests/') or x.startswith('pacote/tests/')) for x in p))"
python -c "import pathlib; print(*sorted(p.name for p in pathlib.Path('.github/workflows').glob('*.yml')),sep='\n')"
```

Os resultados esperados são 31 programas nos diretórios canônicos e os cinco
workflows listados neste documento.

## Fatos e metas

| Área | Fato desta baseline | Meta de estabilização |
| --- | --- | --- |
| Pacotes | 26 pacotes declarados e rastreados | manter manifesto, arquivos e documentação sincronizados, sem meta numérica manual |
| Componentes | 226 componentes registrados | todo componente registrado deve possuir recurso válido; a quantidade pode evoluir |
| Exemplos | inventário 131, arquivos 130, scanner 129; guard falha | inventário e descoberta devem concordar e cada exemplo deve ter plataforma explícita |
| Testes Pascal | 31 programas canônicos não são executados por `unit-tests.yml` | catalogar, compilar e executar 100% das entradas aplicáveis |
| Toolchains | parte das versões é flutuante | versões e política de atualização devem ser explícitas e reproduzíveis |

Metas nunca devem substituir estes valores históricos. Quando uma tarefa alterar
o inventário, o novo estado deve ser medido em seu próprio commit e comparado com
esta baseline pelos mesmos comandos.
