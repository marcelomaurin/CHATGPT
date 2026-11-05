# Reconhecimento de voz pelo Chrome

Por padrão, inicia e encerra apenas a ponte HTTP local, sem abrir browser ou microfone. Use `--listen 60` para a demonstração real: abre Chrome, recebe textos por eventos e encerra após 60 segundos. A captura exige clicar em Iniciar na página e conceder permissão. O serviço de reconhecimento do Chrome pode exigir internet. Defina `CHROME_EXECUTABLE` com o caminho do Chrome se necessário, especialmente no Linux.

## Compilar

Abra `chrome_speech_demo.lpi` no Lazarus com os pacotes `openai_voice`
e suas dependências instalados. Compile e execute como aplicação de console.

Também é possível compilar e verificar os nove exemplos sem reconstruir os
pacotes de design-time, a partir da raiz do repositório:

```text
python tests/run_missing_samples.py
```

Esse runner usa unidades reais da suíte e mantém binários e arquivos gerados
em uma pasta temporária. Não utiliza APIs externas nem abre microfone/browser.
