# source_fix_agent_demo

Sample console Lazarus/Free Pascal mostrando como registrar ações reutilizáveis de manutenção de fontes no `TAIActionExecutor`.

O objetivo é servir de base para IDEs e agentes de correção de código sem permitir que o LLM escreva livremente fora do projeto.

## Ações demonstradas

O fluxo usa as ações de `aiagent_sourceactions.pas`:

- `read_source` — leitura de arquivo dentro do workspace;
- `replace_source` — substituição exata com proteção contra múltiplas ocorrências;
- `rollback_source` — restauração do backup anterior;
- build do projeto com executável configurado pelo host;
- teste/verificação usando somente executável confiável definido pela aplicação.

## Execução

Passe a raiz do projeto como argumento. O sample configura essa pasta como `WorkspaceRoot` e executa uma ação preparada contra um arquivo localizado dentro dela.

O mesmo padrão deve ser usado em um IDE:

1. definir `WorkspaceRoot`;
2. registrar as ações uma única vez;
3. deixar o orchestrator/action builder produzir o plano JSON;
4. apresentar o plano ou diff ao usuário quando a política exigir aprovação;
5. executar;
6. mostrar `LastOutput`, `LastError`, resultado de build/teste e eventual rollback.

## Garantias importantes

As ações rejeitam tentativa de escapar de `WorkspaceRoot`, incluindo path traversal e segmentos de symlink/reparse. A substituição preserva bytes, BOM, encoding e CRLF/LF. Quando `VerifyAfterWrite=True`, uma falha no verificador dispara restauração automática do arquivo anterior.

Saídas de processos passam por redaction de padrões comuns de credenciais. Ainda assim, não coloque tokens ou senhas em argumentos de linha de comando quando houver alternativa mais segura.

Para a referência completa, consulte `DOC/components/TAISourceActions/README.md`.
