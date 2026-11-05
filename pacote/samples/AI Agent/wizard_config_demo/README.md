# Configuração programática e visual do wizard

Demonstra `Apply` e `TestConnection` em modo simulado, sem API ou credenciais. Use `--visual` para abrir o diálogo real de configuração; esse modo precisa de ambiente gráfico. A simulação valida a configuração local, não a conectividade com um modelo.

## Compilar

Abra `wizard_config_demo.lpi` no Lazarus com os pacotes `openai_agent`, `openai_project`
e suas dependências instalados. Compile e execute como aplicação de console.
O modo visual opcional do wizard usa o widgetset padrão do Lazarus.

Também é possível compilar e verificar os nove exemplos sem reconstruir os
pacotes de design-time, a partir da raiz do repositório:

```text
python tests/run_missing_samples.py
```

Esse runner usa unidades reais da suíte e mantém binários e arquivos gerados
em uma pasta temporária. Não utiliza APIs externas nem abre microfone/browser.
