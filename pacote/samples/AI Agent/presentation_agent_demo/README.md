# Agente de apresentação e recursos didáticos

Cria um pacote didático próprio, associa conceitos e metadados de recurso, inicia a narrativa, responde a uma pergunta e retoma a apresentação. A saída é textual; não sintetiza áudio nem abre mídia. O recurso sem arquivo serve apenas como metadado demonstrativo.

## Compilar

Abra `presentation_agent_demo.lpi` no Lazarus com os pacotes `openai_agent`
e suas dependências instalados. Compile e execute como aplicação de console.

Também é possível compilar e verificar os nove exemplos sem reconstruir os
pacotes de design-time, a partir da raiz do repositório:

```text
python tests/run_missing_samples.py
```

Esse runner usa unidades reais da suíte e mantém binários e arquivos gerados
em uma pasta temporária. Não utiliza APIs externas nem abre microfone/browser.
