# Speaker signature: testes e amostras

Componente: `pacote/AI Input/AIAudio/aispeakersignature.pas`.
Este primeiro módulo recebe vetores de características acústicas (embeddings) e
decide se a fala pertence ao locutor da sessão. **Não extrai embeddings de WAV
e não identifica vozes reais ainda.** Os limiares iniciais são ilustrativos,
não calibrados. Casos inconclusivos são aceitos; casos claramente diferentes
são bloqueados. A referência só muda após `Reset`.

Teste sintético, sem áudio:
```sh
fpc -Fu"pacote/AI Input/AIAudio" tests/test_speaker_signature.lpr
./tests/test_speaker_signature
```

## Próximo teste com vozes reais
1. Obter gravações de pelo menos três locutores com licença de reutilização
   explícita (por exemplo, subconjunto autorizado do Common Voice), guardar
   URL, licença, consentimento e atribuição. Não baixar vozes aleatórias da
   internet nem reutilizar gravações sem autorização.
2. Dividir por locutor em amostra de referência e amostras de validação,
   com variação de frase, ruído e microfone; normalizar WAV PCM mono 16 kHz.
3. Integrar extrator de embeddings de locutor compatível com Windows,
   Linux e Android; medir falsos aceites, falsas rejeições e inconclusivos.
4. Calibrar limiares com dados separados do conjunto de teste e registrar
   métricas reproduzíveis.
5. Reutilizar o mesmo extrator/modelo nos dois ambientes; o módulo Pascal
   de decisão pode ser compartilhado via biblioteca nativa no Android ou
   portar exatamente sua lógica, com testes de equivalência.

**Estado:** infraestrutura e testes sintéticos adicionados; nenhum WAV real,
modelo biométrico, APK ou teste de compilação validado nesta alteração.
