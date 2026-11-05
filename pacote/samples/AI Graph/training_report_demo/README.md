# Relatório de treinamento e classificação

Treina um pequeno grafo e gera um relatório textual com estatísticas e previsões. Aceita a pasta de saída como primeiro argumento; padrão: `output/`. Os resultados ilustram apenas o dataset mínimo do exemplo.

## Compilar

Abra `training_report_demo.lpi` no Lazarus com os pacotes `openai_graph`
e suas dependências instalados. Compile e execute como aplicação de console.

Também é possível compilar e verificar os nove exemplos sem reconstruir os
pacotes de design-time, a partir da raiz do repositório:

```text
python tests/run_missing_samples.py
```

Esse runner usa unidades reais da suíte e mantém binários e arquivos gerados
em uma pasta temporária. Não utiliza APIs externas nem abre microfone/browser.
