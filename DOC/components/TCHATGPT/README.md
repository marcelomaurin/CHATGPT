# TCHATGPT

## Finalidade

`TCHATGPT` é o componente principal para comunicação com provedores de LLM e servidores locais compatíveis com APIs de chat.

Use este componente para enviar perguntas, receber respostas e integrar IA generativa a aplicações Lazarus.

## Unit

```pascal
pacote/AI/chatgpt.pas
```

## Pacote

```text
openai_core.lpk
```

## Status

```text
Beta
```

## Propriedades principais

| Propriedade | Descrição |
|---|---|
| `Provider` | Define o provedor de IA |
| `ApiKey` | Chave de API quando necessária |
| `Model` / `CustomModel` | Modelo usado na requisição |
| `BaseURL` | Endpoint customizado ou local |
| `LastJSON` | Última resposta JSON recebida |
| `LastURL` | Última URL usada |
| `LastError` | Último erro |
| `LastResult` | Última resposta textual |

## Métodos principais

| Método | Descrição |
|---|---|
| `SendQuestion` | Envia pergunta e retorna texto |
| `PegaMensagem` | Processa a resposta retornada pelo provedor |
| `GetEndpoint` | Resolve endpoint conforme provedor |
| `GetModelName` | Resolve nome do modelo |

## Exemplo

```pascal
procedure TForm1.Button1Click(Sender: TObject);
begin
  ChatGPT1.Provider := AIP_LOCAL;
  ChatGPT1.BaseURL := 'http://localhost:11434/v1/chat/completions';
  ChatGPT1.CustomModel := 'llama3.2:3b';

  Memo1.Lines.Text := ChatGPT1.SendQuestion('Explique redes neurais em poucas linhas.');

  if ChatGPT1.LastError <> '' then
    ShowMessage(ChatGPT1.LastError);
end;
```

## Observações

* Para provedores externos, proteja a chave de API.
* Para modelos locais, valide endpoint, porta e modelo.
* O componente ainda deve evoluir para execução assíncrona, streaming e providers desacoplados.
