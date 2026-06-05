# TTokenList

## Finalidade

`TTokenList` é um componente utilitário para tokenização simples de texto.

Use em classificações simples, pré-processamento textual e demonstrações didáticas.

## Unit

```pascal
pacote/IA/tokenizer.pas
```

## Pacote

```text
openai_core.lpk
```

## Status

```text
Beta/Legacy
```

## Propriedades principais

| Propriedade | Descrição |
|---|---|
| `Prompt` | Descrição do componente |
| `Tokens` | Lista interna de tokens, conforme implementação |

## Métodos principais

| Método | Descrição |
|---|---|
| `LoadFromFile` | Carrega lista de tokens |
| `Encode` | Converte texto para sequência de tokens/índices |
| `Decode` | Converte tokens/índices para texto, quando suportado |

## Exemplo

```pascal
var
  S: string;
begin
  TokenList1.LoadFromFile('tokens.json');
  S := TokenList1.Encode('texto de teste');
  ShowMessage(S);
end;
```

## Limitações

* Tokenização simples.
* Não equivale a tokenizadores modernos como BPE, SentencePiece ou tokenizer oficial de LLMs.
* Para novos recursos, considerar evoluir para um `TAITokenizer` padronizado.
