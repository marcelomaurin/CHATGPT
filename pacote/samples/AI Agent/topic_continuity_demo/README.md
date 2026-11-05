# Continuidade, correção e retomada de assunto

Executa um diálogo local com correção de número de boleto, mudança de projeto e retomada de assunto. Exibe decisão, motivo, prompt contextualizado e pilha de tópicos. Os dados são fictícios.

## Compilar

Abra `topic_continuity_demo.lpi` no Lazarus com os pacotes `openai_agent`
e suas dependências instalados. Compile e execute como aplicação de console.

Também é possível compilar e verificar os nove exemplos sem reconstruir os
pacotes de design-time, a partir da raiz do repositório:

```text
python tests/run_missing_samples.py
```

Esse runner usa unidades reais da suíte e mantém binários e arquivos gerados
em uma pasta temporária. Não utiliza APIs externas nem abre microfone/browser.
