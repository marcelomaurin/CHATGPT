# Backlog técnico — CHATGPT para Lazarus

Repositório: `marcelomaurin/CHATGPT`

## Labels sugeridas

* Prioridade: `priority:P0`, `priority:P1`, `priority:P2`
* Tipo: `type:bug`, `type:feature`, `type:refactor`, `type:test`, `type:docs`, `type:chore`
* Área: `area:ci`, `area:installer`, `area:packages`, `area:icons`, `area:rag`, `area:security`, `area:samples`, `area:release`
* Tamanho: `size:S`, `size:M`, `size:L`
* Plataforma: `platform:windows`, `platform:linux`

---

# Marco 1 — Recuperar o CI

## CHATGPT-001 — Remover dependência de LResources do núcleo FGX

Labels: `priority:P0`, `type:bug`, `area:packages`, `size:S`

Descrição:

A compilação do FGX falha porque `aidependencygraph.pas` passou a depender de `LResources`, unidade disponível no Lazarus, mas não no FPC puro.

Arquivos principais:

* `pacote/AI Graph/aidependencygraph.pas`
* Demais unidades FGX alteradas pelo gerador de ícones

Critérios de aceite:

* Nenhuma unidade de runtime FGX usa `LResources`.
* O código compila com FPC sem Lazarus instalado.
* O workflow FGX passa no Windows e no Linux.
* O registro visual continua disponível nos pacotes de design-time.

---

## CHATGPT-002 — Adicionar teste que impeça LResources nas unidades FGX

Labels: `priority:P0`, `type:test`, `area:ci`, `area:packages`, `size:S`

Depende de: `CHATGPT-001`

Descrição:

Criar uma verificação automática que falhe quando unidades destinadas ao FPC puro importarem APIs exclusivas do Lazarus.

Critérios de aceite:

* O teste percorre as unidades declaradas como FGX.
* O teste detecta `LResources`, `LCL`, `Forms`, `Controls` e dependências equivalentes não permitidas.
* A lista de exceções, se necessária, fica versionada.
* O teste é executado no workflow FGX.

---

## CHATGPT-003 — Impedir que o gerador de ícones altere unidades de runtime

Labels: `priority:P0`, `type:bug`, `area:icons`, `size:S`

Depende de: `CHATGPT-001`

Descrição:

Alterar `pacote/generate_all_icons.py` para gerar recursos e registros apenas em unidades de design-time.

Critérios de aceite:

* O script não insere `LResources` em unidades de runtime.
* Executar o script duas vezes não produz alterações adicionais.
* O script oferece modo `--check`, sem modificar arquivos.
* O CI executa o modo `--check`.

---

## CHATGPT-004 — Validar nomes e registros dos ícones

Labels: `priority:P0`, `type:test`, `area:icons`, `size:M`

Depende de: `CHATGPT-003`

Descrição:

Criar um validador que compare componentes registrados, recursos `.lrs` e ícones gerados.

Critérios de aceite:

* Detecta nomes de recurso duplicados, incluindo casos como `taiusb`.
* Detecta o mesmo `.lrs` incluído em múltiplas unidades.
* Detecta componentes registrados sem ícone.
* Detecta ícones sem componente correspondente.
* O relatório informa arquivo, recurso e componente envolvidos.

---

## CHATGPT-005 — Corrigir instalação do pacote runtime do Zeos no CI

Labels: `priority:P0`, `type:bug`, `area:ci`, `size:S`

Descrição:

O workflow de samples tenta usar `--add-package` e `--build-all` em `zcomponent.lpk`, embora o pacote recente seja somente runtime.

Critérios de aceite:

* O workflow utiliza a estratégia recomendada pela versão instalada do Zeos.
* A etapa do Zeos conclui no Linux.
* O workflow avança até a compilação dos samples.
* A versão ou referência do Zeos fica fixada no workflow ou manifesto.

---

## CHATGPT-006 — Preencher a dependência GLScene no manifesto

Labels: `priority:P0`, `type:bug`, `area:installer`, `size:S`

Descrição:

Completar a entrada do GLScene em `installer/dependencies.json`.

Critérios de aceite:

* A entrada contém repositório, referência fixada e caminho do pacote.
* O arquivo não depende exclusivamente de `GLSCENE_ROOT`.
* O manifesto continua permitindo uma instalação local personalizada.
* O formato passa pela validação JSON do instalador.

---

## CHATGPT-007 — Instalar GLScene automaticamente

Labels: `priority:P0`, `type:feature`, `area:installer`, `size:M`

Depende de: `CHATGPT-006`

Descrição:

Implementar download, checkout e instalação automática do GLScene no perfil `all`.

Critérios de aceite:

* Uma máquina limpa não precisa definir `GLSCENE_ROOT`.
* A versão instalada é reproduzível.
* Instalações repetidas são idempotentes.
* Falhas informam o repositório, a referência e o pacote que não pôde ser instalado.
* O CI comprova a instalação no Windows e no Linux.

---

## CHATGPT-008 — Instalar dcpcrypt antes do CEF4Delphi

Labels: `priority:P0`, `type:bug`, `area:installer`, `platform:windows`, `size:S`

Descrição:

Adicionar a dependência necessária para que os pacotes do CEF4Delphi sejam compilados.

Critérios de aceite:

* `dcpcrypt` está declarado no manifesto.
* A ordem de instalação coloca `dcpcrypt` antes do CEF4Delphi.
* A versão utilizada fica fixada.
* O pacote CEF4Delphi compila em ambiente Windows limpo.

---

## CHATGPT-009 — Configurar o caminho do FPC no instalador Windows

Labels: `priority:P0`, `type:bug`, `area:installer`, `platform:windows`, `size:S`

Descrição:

Evitar que o instalador dependa de uma configuração manual do `PATH`.

Critérios de aceite:

* O instalador localiza FPC e Lazarus automaticamente.
* O caminho pode ser sobrescrito por parâmetro.
* O instalador valida executáveis antes de iniciar a compilação.
* A mensagem de erro informa os caminhos pesquisados.

---

## CHATGPT-010 — Exigir Python 3 no install_components.bat

Labels: `priority:P0`, `type:bug`, `area:installer`, `platform:windows`, `size:S`

Descrição:

Incorporar de forma limpa a correção proposta no PR #10 e rejeitar Python 2.

Critérios de aceite:

* Prefere `py -3` quando disponível.
* Valida a versão antes de executar o instalador.
* Rejeita Python 2 com mensagem objetiva.
* Oferece parâmetro para indicar outro executável Python 3.
* Possui teste para ambientes com `py`, somente `python` e sem Python.

---

## CHATGPT-011 — Gerar relatório consolidado do instalador

Labels: `priority:P0`, `type:feature`, `area:installer`, `size:S`

Depende de: `CHATGPT-006`, `CHATGPT-008`, `CHATGPT-009`, `CHATGPT-010`

Critérios de aceite:

* Ao final, apresenta dependências instaladas, ignoradas e com erro.
* Mostra versões e caminhos detectados.
* Não imprime tokens, senhas ou outras credenciais.
* Retorna código de saída diferente de zero quando há falha obrigatória.

---

## CHATGPT-012 — Compilar todos os 25 pacotes no CI

Labels: `priority:P0`, `type:test`, `area:ci`, `area:packages`, `size:M`

Depende de: `CHATGPT-001`, `CHATGPT-005`, `CHATGPT-007`, `CHATGPT-008`

Critérios de aceite:

* O CI encontra os pacotes por manifesto, sem lista duplicada no workflow.
* Todos os 25 pacotes são compilados no Linux e no Windows.
* O relatório identifica cada pacote como aprovado, falhou ou ignorado.
* Um pacote obrigatório ignorado faz o workflow falhar.

---

## CHATGPT-013 — Criar inventário executável dos samples

Labels: `priority:P0`, `type:chore`, `area:samples`, `size:S`

Descrição:

Gerar a lista oficial de projetos de exemplo a partir dos arquivos `.lpi`.

Critérios de aceite:

* O inventário inclui todos os `.lpi` encontrados.
* Cada entrada informa plataforma, arquitetura e dependências especiais.
* Exclusões possuem motivo explícito.
* O validador falha quando um novo sample não está classificado.

---

## CHATGPT-014 — Compilar todos os samples suportados

Labels: `priority:P0`, `type:test`, `area:ci`, `area:samples`, `size:M`

Depende de: `CHATGPT-012`, `CHATGPT-013`

Critérios de aceite:

* O CI chega efetivamente à etapa de compilação dos samples.
* Cada projeto possui resultado individual.
* Samples dependentes de Windows são ignorados somente no Linux, e vice-versa.
* O resumo informa total encontrado, compilado, aprovado, falhou e ignorado.
* A documentação não usa números estáticos diferentes do relatório.

---

## CHATGPT-015 — Criar workflow exclusivo para testes automatizados

Labels: `priority:P0`, `type:test`, `area:ci`, `size:M`

Descrição:

Executar os testes existentes como uma etapa independente da compilação dos samples.

Critérios de aceite:

* Testes são descobertos por manifesto ou convenção documentada.
* O workflow roda em pull requests.
* Uma falha de teste bloqueia o workflow.
* O resultado inclui número de testes aprovados, falhos e ignorados.
* O workflow não exige tokens reais de provedores.

---

## CHATGPT-016 — Corrigir ou isolar o workflow MediaPipe

Labels: `priority:P0`, `type:bug`, `area:ci`, `size:M`

Descrição:

O workflow MediaPipe não possui execução verde conhecida.

Critérios de aceite:

* A causa atual da falha fica documentada no log.
* Dependências e versões ficam fixadas.
* O workflow passa em pelo menos uma plataforma suportada.
* Plataformas ainda não suportadas são marcadas como exclusão explícita.
* O workflow deixa de falhar por dependência ausente sem diagnóstico.

---

## CHATGPT-017 — Proteger a branch main

Labels: `priority:P0`, `type:chore`, `area:ci`, `size:S`

Depende de: `CHATGPT-012`, `CHATGPT-014`, `CHATGPT-015`

Critérios de aceite:

* Pull request passa a ser obrigatório.
* Compilação de pacotes, samples e testes são checks obrigatórios.
* Push direto e force push ficam desabilitados.
* Administradores seguem a mesma política ou a exceção fica documentada.

---

# Marco 2 — Higiene do repositório e release

## CHATGPT-018 — Remover artefatos compilados dos diretórios de samples

Labels: `priority:P1`, `type:chore`, `area:samples`, `size:M`

Descrição:

Remover do índice do Git executáveis, objetos e bibliotecas geradas durante a compilação.

Critérios de aceite:

* Nenhum `.exe`, `.o`, `.ppu`, `.a`, `.dll` ou equivalente gerado permanece nos samples.
* Código-fonte e arquivos necessários para compilação permanecem intactos.
* `.gitignore` cobre os diretórios e extensões removidos.
* Os samples continuam compilando após um clone limpo.
* Não realizar reescrita do histórico nesta issue.

---

## CHATGPT-019 — Corrigir os arquivos OpenCV que deveriam usar Git LFS

Labels: `priority:P1`, `type:bug`, `area:release`, `size:M`

Descrição:

Corrigir os quatro binários OpenCV que estão armazenados como blobs comuns apesar da configuração do Git LFS.

Critérios de aceite:

* Todos os binários definidos em `.gitattributes` são ponteiros LFS válidos.
* `git lfs fsck` passa.
* O clone com LFS recupera os binários.
* O clone sem LFS falha com diagnóstico claro durante a instalação.
* Não reescrever o histórico sem uma issue e aprovação separadas.

---

## CHATGPT-020 — Criar manifesto das dependências binárias

Labels: `priority:P1`, `type:chore`, `area:release`, `size:S`

Depende de: `CHATGPT-019`

Critérios de aceite:

* Cada binário possui origem, versão, licença, plataforma e checksum.
* O instalador valida os checksums.
* O CI rejeita binário sem entrada no manifesto.
* Licenças de redistribuição ficam documentadas.

---

## CHATGPT-021 — Gerar pacotes de release sem binários de desenvolvimento

Labels: `priority:P1`, `type:feature`, `area:release`, `size:M`

Depende de: `CHATGPT-018`, `CHATGPT-020`

Critérios de aceite:

* O workflow gera arquivos de release reproduzíveis.
* O pacote contém fontes, instalador e documentação necessários.
* Artefatos temporários dos samples não são incluídos.
* Checksums SHA-256 são publicados junto dos arquivos.
* O workflow pode ser executado por tag e manualmente.

---

## CHATGPT-022 — Definir versionamento e criar a primeira release verificável

Labels: `priority:P1`, `type:chore`, `area:release`, `size:S`

Depende de: `CHATGPT-017`, `CHATGPT-021`

Critérios de aceite:

* O projeto documenta Semantic Versioning ou outra política explícita.
* A versão possui changelog.
* A tag aponta para um commit com todos os checks obrigatórios verdes.
* A release contém artefatos e checksums gerados pelo CI.
* Não usar o rótulo “estável” sem atender aos critérios de maturidade.

---

# Marco 3 — Pacotes e documentação

## CHATGPT-023 — Criar inventário único de componentes

Labels: `priority:P1`, `type:chore`, `area:packages`, `size:M`

Descrição:

Eliminar as contagens divergentes entre README, matriz de componentes, recursos e pacotes.

Critérios de aceite:

* Um arquivo estruturado contém todos os componentes públicos.
* Cada entrada informa pacote, unidade, classe, categoria e status.
* Um script valida o inventário contra as chamadas `RegisterComponents`.
* Componentes duplicados ou ausentes fazem a validação falhar.
* README e matriz passam a consumir dados desse inventário.

---

## CHATGPT-024 — Atualizar README com métricas geradas

Labels: `priority:P1`, `type:docs`, `size:S`

Depende de: `CHATGPT-013`, `CHATGPT-023`

Critérios de aceite:

* Quantidade de pacotes, componentes e samples é gerada automaticamente.
* O README não afirma que 91 samples passam sem evidência atual do CI.
* A seção de instalação corresponde ao novo instalador.
* A data e o commit da última validação ficam visíveis.

---

## CHATGPT-025 — Definir níveis objetivos de maturidade

Labels: `priority:P1`, `type:docs`, `size:S`

Descrição:

Padronizar os termos experimental, alpha, beta e estável.

Critérios de aceite:

* Cada nível possui requisitos mínimos de compilação, testes e documentação.
* O status dos componentes vem do inventário único.
* “Compila” não é usado como sinônimo de “estável”.
* Componentes simulados ou incompletos não aparecem como estáveis.

---

## CHATGPT-026 — Separar funcionalidades de banco do openai_core

Labels: `priority:P1`, `type:refactor`, `area:packages`, `size:M`

Descrição:

Remover a dependência obrigatória do Zeos causada por `DBTokenList` e `GroupResponse`.

Critérios de aceite:

* O núcleo HTTP/JSON compila sem Zeos.
* Componentes dependentes de banco ficam em pacote separado.
* Projetos existentes recebem instrução de migração.
* Um sample mínimo comprova o uso do núcleo sem banco.
* Um sample comprova o uso do pacote adicional com Zeos.

---

## CHATGPT-027 — Criar infraestrutura comum para pacotes de design-time

Labels: `priority:P1`, `type:refactor`, `area:packages`, `size:M`

Descrição:

Criar um padrão único para registros de componentes, ícones e editores usados somente no Lazarus.

Critérios de aceite:

* Existe uma unidade comum de design-time.
* Unidades de runtime não importam `LResources`.
* O padrão é documentado com um pacote de exemplo.
* Há teste que compila o runtime com FPC puro.

---

## CHATGPT-028 — Migrar openai_graph para runtime e design-time separados

Labels: `priority:P1`, `type:refactor`, `area:packages`, `size:M`

Depende de: `CHATGPT-027`

Critérios de aceite:

* O runtime do graph compila sem Lazarus.
* O pacote design-time registra componentes e ícones.
* Projetos existentes continuam abrindo ou recebem instrução de migração.
* Os dois pacotes são compilados no CI.

---

## CHATGPT-029 — Migrar os demais pacotes para o padrão runtime/design-time

Labels: `priority:P1`, `type:refactor`, `area:packages`, `size:L`

Depende de: `CHATGPT-028`

Critérios de aceite:

* A migração é feita em pull requests separados por pacote ou grupo pequeno.
* Pacotes runtime não dependem da IDE.
* Pacotes design-time não são exigidos em aplicações finais.
* O CI valida todos os pacotes após cada migração.
* Um pacote de compatibilidade é mantido quando necessário.

---

## CHATGPT-030 — Reduzir dependências do openai_graph

Labels: `priority:P1`, `type:refactor`, `area:packages`, `size:M`

Depende de: `CHATGPT-028`

Descrição:

Separar o modelo de grafo das integrações com input, output e machine learning.

Critérios de aceite:

* O modelo e os algoritmos básicos ficam em um pacote mínimo.
* Integrações opcionais ficam em pacotes adaptadores.
* O pacote mínimo compila sem dependências de mídia.
* Os samples declaram apenas as integrações que realmente utilizam.

---

## CHATGPT-031 — Separar openai_aidbase em módulos independentes

Labels: `priority:P1`, `type:refactor`, `area:packages`, `size:M`

Depende de: `CHATGPT-030`

Critérios de aceite:

* Funcionalidades de graph e RAG podem ser usadas separadamente.
* O pacote antigo funciona como agregador temporário ou tem migração documentada.
* Não existe dependência circular.
* O CI testa as combinações mínimas de pacotes.

---

# Marco 4 — Evolução do RAG

## CHATGPT-032 — Integrar AddFile ao registro de extratores

Labels: `priority:P1`, `type:feature`, `area:rag`, `size:M`

Descrição:

Fazer `TAIRAG.AddFile` utilizar `TAIDocumentExtractorRegistry`.

Critérios de aceite:

* TXT continua funcionando.
* PDF, DOCX e XLSX usam seus extratores registrados.
* Arquivo sem extrator retorna erro explícito.
* O método não trata conteúdo binário como texto simples.
* Existem testes com um arquivo pequeno de cada formato.

---

## CHATGPT-033 — Fazer AddFolder usar as extensões dos extratores

Labels: `priority:P1`, `type:feature`, `area:rag`, `size:S`

Depende de: `CHATGPT-032`

Critérios de aceite:

* As extensões aceitas são derivadas do registro de extratores.
* A busca pode ser recursiva ou não recursiva por parâmetro.
* Arquivos ignorados entram no relatório.
* Erro em um arquivo não interrompe os demais quando configurado para continuar.

---

## CHATGPT-034 — Implementar tokenização Unicode para português

Labels: `priority:P1`, `type:bug`, `area:rag`, `size:M`

Descrição:

Substituir a tokenização limitada a ASCII em `airetrieval.pas`.

Critérios de aceite:

* Palavras como “ação”, “informação” e “João” são tokenizadas corretamente.
* A normalização de maiúsculas/minúsculas é consistente.
* A decisão sobre remoção de acentos fica documentada e testada.
* Os testes cobrem português, inglês, números e símbolos.
* Resultados BM25 não perdem palavras acentuadas.

---

## CHATGPT-035 — Adicionar metadados aos chunks

Labels: `priority:P1`, `type:feature`, `area:rag`, `size:M`

Depende de: `CHATGPT-032`

Critérios de aceite:

* Cada chunk guarda documento, posição inicial, posição final e índice.
* Quando disponível, guarda página, planilha ou seção.
* Os metadados aparecem nas citações ou no resultado da busca.
* O formato de persistência suporta os novos campos.

---

## CHATGPT-036 — Implementar chunking por limites semânticos

Labels: `priority:P1`, `type:feature`, `area:rag`, `size:M`

Depende de: `CHATGPT-035`

Critérios de aceite:

* Prioriza parágrafos, sentenças ou seções antes do corte por tamanho.
* Overlap não duplica conteúdo além do configurado.
* O algoritmo é determinístico.
* Há testes para textos curtos, longos, sem pontuação e com Unicode.
* Tamanho e overlap continuam configuráveis.

---

## CHATGPT-037 — Evitar corte no meio de chunks ao montar o contexto

Labels: `priority:P1`, `type:bug`, `area:rag`, `size:S`

Depende de: `CHATGPT-035`

Descrição:

Substituir o `Copy` bruto usado no limite do contexto.

Critérios de aceite:

* O orçamento é aplicado por chunk ou sentença completa.
* O retorno informa quais chunks foram incluídos e descartados.
* Nenhuma citação aponta para conteúdo ausente.
* O comportamento com orçamento insuficiente fica testado.

---

## CHATGPT-038 — Persistir e restaurar índices BM25 e vetorial

Labels: `priority:P1`, `type:bug`, `area:rag`, `size:M`

Descrição:

Garantir que `SaveIndex` e `LoadIndex` restaurem todos os mecanismos de busca.

Critérios de aceite:

* Salva versão do formato, chunks, metadados e configurações.
* Após carregar, BM25 e busca vetorial retornam os mesmos resultados básicos.
* Arquivos de formato antigo recebem migração ou erro orientativo.
* Índice corrompido não provoca leitura parcial silenciosa.
* Existem testes de ida e volta.

---

## CHATGPT-039 — Criar indexação assíncrona com progresso e cancelamento

Labels: `priority:P1`, `type:feature`, `area:rag`, `size:M`

Depende de: `CHATGPT-032`, `CHATGPT-038`

Critérios de aceite:

* A indexação não bloqueia a thread principal.
* Eventos informam arquivo atual, total e percentual.
* O usuário pode cancelar de forma segura.
* Arquivos já indexados e não alterados podem ser ignorados por hash.
* Uma falha isolada aparece no relatório final.

---

## CHATGPT-040 — Criar suíte de regressão e benchmark do RAG

Labels: `priority:P1`, `type:test`, `area:rag`, `size:M`

Depende de: `CHATGPT-034`, `CHATGPT-036`, `CHATGPT-038`, `CHATGPT-039`

Critérios de aceite:

* Testa graph, BM25, vector, hybrid RRF e reranker.
* Inclui consultas em português com acentos.
* Inclui persistência e recarga do índice.
* Inclui corpus sintético com pelo menos 200 documentos.
* Registra tempo, memória e qualidade básica da recuperação.
* Os limites aceitáveis ficam documentados.

---

# Marco 5 — Segurança e integridade

## CHATGPT-041 — Impedir serialização do token em arquivos LFM

Labels: `priority:P1`, `type:bug`, `area:security`, `size:S`

Descrição:

A propriedade `TCHATGPT.TOKEN` é publicada e pode ser gravada no formulário.

Critérios de aceite:

* Tokens não são serializados em `.lfm`.
* Projetos existentes que já possuem token recebem aviso ou migração segura.
* O token pode ser fornecido em runtime.
* O sample recomendado lê a credencial de variável de ambiente.
* Um teste verifica que o `.lfm` salvo não contém o token.

---

## CHATGPT-042 — Canonicalizar caminhos usados por ações de código-fonte

Labels: `priority:P1`, `type:bug`, `area:security`, `size:M`

Descrição:

Fortalecer `ResolveWorkspacePath` contra diferenças de caixa, `..`, symlinks e junctions.

Critérios de aceite:

* O caminho é resolvido de forma canônica antes da autorização.
* Linux mantém comparação sensível a maiúsculas/minúsculas.
* Windows usa a semântica apropriada da plataforma.
* Symlinks ou junctions que escapam do workspace são rejeitados.
* Há testes de traversal e prefixos semelhantes.

---

## CHATGPT-043 — Preservar encoding e finais de linha em alterações de fonte

Labels: `priority:P1`, `type:bug`, `area:security`, `size:M`

Critérios de aceite:

* Detecta e preserva BOM e encoding.
* Preserva LF ou CRLF.
* Não adiciona linha final quando ela não existia, salvo opção explícita.
* Alterar uma linha não reescreve o restante do arquivo.
* Os testes cobrem UTF-8, UTF-8 BOM e arquivos com CRLF.

---

## CHATGPT-044 — Manter rollback durável das alterações automáticas

Labels: `priority:P1`, `type:feature`, `area:security`, `size:M`

Depende de: `CHATGPT-043`

Critérios de aceite:

* O backup não é apagado antes da confirmação.
* O usuário pode visualizar o diff.
* Existe comando para aplicar e desfazer a alteração.
* Falha durante a escrita restaura o arquivo original.
* Opcionalmente pode usar um checkpoint Git quando o projeto já estiver versionado.

---

## CHATGPT-045 — Redigir credenciais dos logs e traces

Labels: `priority:P1`, `type:bug`, `area:security`, `size:S`

Critérios de aceite:

* Headers `Authorization` e chaves de API são mascarados.
* Parâmetros de URL usados como credencial também são mascarados.
* Mensagens de erro não incluem o token completo.
* O mascaramento não elimina informações necessárias ao diagnóstico.
* Testes verificam logs HTTP e traces de agentes.

---

# Marco 6 — Funcionalidades incompletas

## CHATGPT-046 — Tornar explícito o estado das integrações simuladas

Labels: `priority:P2`, `type:docs`, `type:bug`, `size:M`

Descrição:

Identificar integrações que atualmente simulam sucesso ou possuem implementação parcial, incluindo OpenCV, Chromium, Kinect e dicionários experimentais de banco.

Critérios de aceite:

* Operação não implementada retorna `NotSupported` ou erro equivalente.
* Nenhuma função apenas copia entrada para saída indicando sucesso de processamento.
* O status aparece no inventário de componentes.
* Os samples identificam claramente quando usam mock ou simulação.
* São abertas issues específicas para:

  * Processamento nativo OpenCV.
  * Leitura DOM e screenshot do Chromium.
  * Skeleton e áudio do Kinect.
  * Dicionários MySQL, Firebird, SQL Server e Oracle.
* O PR #2 de llama.cpp é reavaliado somente depois do CI principal estar verde, sem incorporar executáveis ou runtimes ao código-fonte.

---

# Ordem recomendada de execução

1. `CHATGPT-001` até `CHATGPT-017`: recuperar e proteger o CI.
2. `CHATGPT-018` até `CHATGPT-022`: limpar o repositório e preparar releases.
3. `CHATGPT-023` até `CHATGPT-031`: estabilizar pacotes e documentação.
4. `CHATGPT-041` até `CHATGPT-045`: corrigir segurança antes de ampliar automações.
5. `CHATGPT-032` até `CHATGPT-040`: evoluir e testar o RAG.
6. `CHATGPT-046`: transformar funcionalidades simuladas em trabalhos explícitos e rastreáveis.

# Critério global de conclusão

Uma tarefa somente deve ser encerrada quando:

* A implementação estiver acompanhada por teste ou validação automatizada.
* O CI relevante estiver verde.
* A documentação afetada estiver atualizada.
* Não forem adicionados binários compilados ao repositório.
* Nenhum teste depender de credenciais reais.
* O pull request citar a issue usando `Closes #<número>`.
