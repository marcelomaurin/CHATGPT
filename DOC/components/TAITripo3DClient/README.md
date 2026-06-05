# TAITripo3DClient

## Finalidade

`TAITripo3DClient` representa a integração com serviço externo de geração de modelos 3D, como Tripo3D.

## Unit

```pascal
pacote/AI Graphic/aitripo3dclient.pas
```

## Pacote

```text
openai_graphic.lpk
```

## Status

```text
Experimental
```

## Propriedades principais

| Propriedade | Descrição |
|---|---|
| `ApiKey` | Chave da API externa |
| `BaseURL` | Endpoint do serviço |
| `InputImage` | Imagem de entrada, quando usada |
| `Prompt` | Texto de orientação, quando suportado |
| `OutputFile` | Arquivo 3D de saída |
| `LastError` | Último erro |
| `LastResult` | Último resultado |

## Métodos principais

| Método | Descrição |
|---|---|
| `GenerateFromImage` | Solicita geração 3D a partir de imagem |
| `GenerateFromText` | Solicita geração 3D a partir de texto, se suportado |
| `DownloadResult` | Baixa arquivo 3D resultante |

## Exemplo

```pascal
procedure TForm1.Button1Click(Sender: TObject);
begin
  AITripo3DClient1.ApiKey := 'SUA_CHAVE';
  AITripo3DClient1.InputImage := 'foto_objeto.jpg';

  if AITripo3DClient1.GenerateFromImage then
    ShowMessage(AITripo3DClient1.LastResult)
  else
    ShowMessage(AITripo3DClient1.LastError);
end;
```

## Limitações

* Depende de API externa, custos, limites e termos do provedor.
* Validar a API oficial antes de uso em produção.
* A implementação pode mudar conforme mudanças do serviço externo.
