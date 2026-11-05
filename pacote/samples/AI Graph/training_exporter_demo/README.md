# Exportação de dataset de treinamento

Cria um dataset de duas categorias, valida os registros e exporta CSV e JSONL. Aceita a pasta de saída como primeiro argumento; padrão: `output/`. Usa arquivos de exemplo próprios, sem dados pessoais.

## Compilar

Abra `training_exporter_demo.lpi` no Lazarus com os pacotes `openai_graph`
e suas dependências instalados. Compile e execute como aplicação de console.

Também é possível compilar e verificar os nove exemplos sem reconstruir os
pacotes de design-time, a partir da raiz do repositório:

```text
python tests/run_missing_samples.py
```

Esse runner usa unidades reais da suíte e mantém binários e arquivos gerados
em uma pasta temporária. Não utiliza APIs externas nem abre microfone/browser.
