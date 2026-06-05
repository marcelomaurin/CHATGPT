# TCNNClassifier

## Finalidade

`TCNNClassifier` integra classificação de imagens por rede neural convolucional ao projeto Lazarus.

No estado atual, deve ser tratado como componente experimental dependente de Python/modelo externo.

## Unit

```pascal
pacote/IA/cnnclassifier.pas
```

## Pacote

```text
openai_python.lpk
```

## Status

```text
Experimental
```

## Propriedades principais

| Propriedade | Descrição |
|---|---|
| `ImagePath` | Imagem de entrada |
| `ModelPath` | Modelo de classificação |
| `LabelsPath` | Arquivo de rótulos, quando usado |
| `LastError` | Último erro |
| `LastResult` | Resultado da classificação |

## Métodos principais

| Método | Descrição |
|---|---|
| `Classify` | Executa classificação da imagem |
| `SelfTest` | Deve validar dependências, quando implementado |

## Exemplo

```pascal
procedure TForm1.Button1Click(Sender: TObject);
begin
  CNNClassifier1.ModelPath := 'modelo.h5';
  CNNClassifier1.ImagePath := 'imagem.jpg';

  if CNNClassifier1.Classify then
    Memo1.Lines.Text := CNNClassifier1.LastResult
  else
    ShowMessage(CNNClassifier1.LastError);
end;
```

## Limitações

* Depende de modelo externo e backend Python.
* Validar tamanho esperado da imagem, normalização e labels.
* Não deve ser tratado como componente estável sem sample e testes.
