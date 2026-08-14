# Política de Proteção da Branch Main (CHATGPT-017)

## Regras de Proteção

1. **Pull Requests Obrigatórios**:
   - Todo código novo ou alteração deve ser submetido via Pull Request para a branch `main`.
   - Push direto e force push (`git push --force`) na branch `main` são bloqueados.

2. **Status Checks Obrigatórios**:
   - `fgx-core` (Linux e Windows)
   - `packages` (Installer + all packages no Linux e Windows)
   - `unit-and-guards` (Validação de unidades FPC, ícones e inventário de samples)
   - `samples` (Compilação dos samples suportados)

3. **Critérios de Aprovação**:
   - Todos os checks automatizados devem estar verdes.
   - Não devem ser adicionados binários compilados (`.exe`, `.o`, `.ppu`, `.dll`, `.so`) ao repositório de código-fonte.
   - O PR deve referenciar a issue correspondente usando `Closes #<número>` ou `Fixes #<número>`.
