# Sessões e memória isoladas por pessoa

Usa duas pessoas fictícias para mostrar históricos separados, memória de interesse e seleção do interlocutor ativo. A ativação é explícita: não exige câmera ou reconhecimento facial.

## Compilar

Abra `person_session_demo.lpi` no Lazarus com os pacotes `openai_agent`
e suas dependências instalados. Compile e execute como aplicação de console.

Também é possível compilar e verificar os nove exemplos sem reconstruir os
pacotes de design-time, a partir da raiz do repositório:

```text
python tests/run_missing_samples.py
```

Esse runner usa unidades reais da suíte e mantém binários e arquivos gerados
em uma pasta temporária. Não utiliza APIs externas nem abre microfone/browser.
