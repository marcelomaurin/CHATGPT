# TPythonConnector

## Finalidade

`TPythonConnector` integra aplicações Lazarus com scripts ou rotinas Python.

Pode operar por processo externo ou por DLL/SO Python, dependendo da configuração.

## Unit

```pascal
pacote/IA/pythonconnector.pas
```

## Pacote

```text
openai_core.lpk
```

## Status

```text
Experimental/Beta
```

## Propriedades principais

| Propriedade | Descrição |
|---|---|
| `ExecutionMode` | Modo de execução: processo ou DLL |
| `PythonPath` | Caminho do Python |
| `ScriptFile` | Script a ser executado |
| `LastError` | Último erro |
| `LastResult` | Último resultado |

## Métodos principais

| Método | Descrição |
|---|---|
| `SelfTest` | Testa ambiente Python |
| `Execute` | Executa script/comando conforme configuração |
| `StopExecution` | Solicita parada da execução |
| `GetDiagnosticReport` | Gera diagnóstico do ambiente |

## Exemplo

```pascal
procedure TForm1.Button1Click(Sender: TObject);
begin
  PythonConnector1.PythonPath := 'python';
  PythonConnector1.ScriptFile := 'teste.py';

  if PythonConnector1.SelfTest then
    ShowMessage('Python OK')
  else
    ShowMessage(PythonConnector1.LastError);
end;
```

## Recomendações

* Preferir execução por processo externo.
* Usar DLL/SO Python apenas em modo avançado.
* Validar arquitetura 32/64 bits e versão do Python.
* Registrar logs detalhados para diagnóstico.

## Limitações

Integração por DLL Python pode travar o processo se versão, arquitetura ou ambiente estiverem incompatíveis.
