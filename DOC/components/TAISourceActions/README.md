# TAISourceActions — ações seguras para manutenção de fontes

`aiagent_sourceactions.pas` fornece ações reutilizáveis para agentes que precisam ler, alterar, validar, compilar e, quando necessário, reverter mudanças em fontes dentro de um workspace controlado.

## Componentes

- `TAISourceReadAction` — lê um arquivo localizado dentro de `WorkspaceRoot`.
- `TAISourceReplaceAction` — substitui um trecho exato, com proteção de ocorrência única, preservação do conteúdo em bytes, backup opcional e verificação pós-escrita.
- `TAISourceRollbackAction` — restaura o backup criado pela ação de substituição.
- `TAIProjectBuildAction` — executa um builder previamente definido pelo host, por exemplo `lazbuild`.
- `TAITrustedProjectTestAction` — quando registrado pelo host, executa somente o runner de testes explicitamente autorizado pela aplicação.

## Segurança do workspace

Todas as ações de arquivo devem receber um `WorkspaceRoot`. O caminho solicitado é normalizado e precisa permanecer dentro dessa raiz. A implementação rejeita path traversal e segmentos de link simbólico/reparse que possam escapar do workspace.

Executáveis usados para build, teste ou verificação nunca devem ser escolhidos pelo LLM. Eles são definidos pela aplicação host através das propriedades do componente.

`ASimulate=True` valida a operação sem escrever arquivos nem iniciar processos externos.

## Substituição, backup e rollback

`TAISourceReplaceAction` usa por padrão `RequireUniqueMatch=True`. Assim, uma alteração só é aplicada quando o trecho procurado é encontrado de forma inequívoca.

As principais propriedades são:

- `KeepBackup` — mantém backup para restauração posterior;
- `VerifyAfterWrite` — roda um verificador configurado pelo host após a escrita;
- `VerifierExecutable` e `VerifierArguments` — definem o verificador confiável;
- `VerificationTimeoutMs` — limita o tempo da verificação.

Se a verificação pós-escrita falhar, a ação tenta restaurar automaticamente o conteúdo anterior. O host também pode registrar `TAISourceRollbackAction` para permitir rollback explícito.

A leitura e a escrita são feitas preservando os bytes do arquivo, evitando normalização involuntária de BOM, encoding ou finais de linha CRLF/LF.

## Saída de processos

A saída capturada de processos passa por redaction de padrões comuns de credenciais, incluindo cabeçalhos `Authorization`, tokens Bearer e valores como `api_key`, `apikey` e `token`.

Mesmo com essa proteção, o host não deve incluir segredos em argumentos de linha de comando quando isso puder ser evitado.

## Fluxo recomendado

1. Crie as ações e configure o mesmo `WorkspaceRoot` em todas elas.
2. Configure no host os executáveis confiáveis de build, teste e verificação.
3. Registre as ações no `TAIActionExecutor`.
4. Faça o Agent/ActionBuilder preparar o plano JSON.
5. Valide a política de aprovação humana antes de executar alterações destrutivas.
6. Execute o plano.
7. Inspecione `LastOutput`, `LastError`, diff e diagnóstico do compilador/teste.
8. Use rollback quando a validação falhar ou a alteração for rejeitada.

## Samples e testes

- `pacote/samples/AI Agent/source_fix_agent_demo/` mostra o registro das ações em um executor.
- `tests/test_aiagent_sourceactions.lpr` cobre cenários de segurança e preservação de arquivo, incluindo traversal, BOM/CRLF, rollback e falha do verificador.

O IDE ou aplicação que hospeda o Agent continua responsável por aprovação do usuário, apresentação de diff e escolha dos executáveis permitidos.
