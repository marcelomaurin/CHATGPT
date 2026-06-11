# TYoloDetect

## Finalidade

`TYoloDetect` integra detecção de objetos baseada em YOLO ao projeto Lazarus.

No estado atual, deve ser tratado como componente experimental dependente de Python, modelos externos e arquivos de configuração/pesos.

## Unit

```pascal
pacote/IA/yolodetect.pas
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
| `ModelPath` | Caminho do modelo YOLO, quando disponível |
| `ImagePath` | Imagem de entrada |
| `ConfidenceThreshold` | Confiança mínima |
| `LastError` | Último erro |
| `LastResult` | Resultado da detecção |

## Métodos principais

| Método | Descrição |
|---|---|
| `Detect` | Executa detecção de objetos conforme backend disponível |
| `SelfTest` | Deve validar dependências, quando implementado |

## Exemplo

```pascal
procedure TForm1.Button1Click(Sender: TObject);
begin
  YoloDetect1.ModelPath := 'modelo.onnx';
  YoloDetect1.ImagePath := 'imagem.jpg';
  YoloDetect1.ConfidenceThreshold := 0.50;

  if YoloDetect1.Detect then
    Memo1.Lines.Text := YoloDetect1.LastResult
  else
    ShowMessage(YoloDetect1.LastError);
end;
```

## Limitações

* Depende de backend e modelo externo.
* Validar caminho do modelo, formato e dependências Python antes de uso.
* Ainda não deve ser tratado como componente estável.
