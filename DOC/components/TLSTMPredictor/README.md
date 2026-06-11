# TLSTMPredictor

## Finalidade

`TLSTMPredictor` integra previsão/sequência com modelo LSTM ao projeto Lazarus.

No estado atual, deve ser tratado como componente experimental dependente de Python/modelo externo.

## Unit

```pascal
pacote/IA/lstmpredictor.pas
```

## Pacote

```text
openai_core.lpk
```

## Status

```text
Experimental
```

## Propriedades principais

| Propriedade | Descrição |
|---|---|
| `ModelPath` | Caminho do modelo LSTM |
| `InputData` | Dados de entrada, conforme implementação |
| `LastError` | Último erro |
| `LastResult` | Resultado da previsão |

## Métodos principais

| Método | Descrição |
|---|---|
| `Predict` | Executa previsão conforme modelo configurado |
| `SelfTest` | Deve validar dependências, quando implementado |

## Exemplo

```pascal
procedure TForm1.Button1Click(Sender: TObject);
begin
  LSTMPredictor1.ModelPath := 'modelo_lstm.h5';

  if LSTMPredictor1.Predict then
    Memo1.Lines.Text := LSTMPredictor1.LastResult
  else
    ShowMessage(LSTMPredictor1.LastError);
end;
```

## Limitações

* Depende de modelo e backend externo.
* A estrutura dos dados de entrada precisa estar alinhada ao modelo treinado.
* Exige sample e validação antes de uso em produção.
