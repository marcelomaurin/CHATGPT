# Catálogo e aplicação de modelos

Lista o catálogo, registra um modelo local e aplica suas configurações a `TCHATGPT`. Não inicia servidor nem faz chamadas de rede.

## Compilar

Abra `modelregistry_demo.lpi` no Lazarus com os pacotes `openai_core`
e suas dependências instalados. Compile e execute como aplicação de console.

Também é possível compilar e verificar os nove exemplos sem reconstruir os
pacotes de design-time, a partir da raiz do repositório:

```text
python tests/run_missing_samples.py
```

Esse runner usa unidades reais da suíte e mantém binários e arquivos gerados
em uma pasta temporária. Não utiliza APIs externas nem abre microfone/browser.
