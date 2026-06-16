# 📐 Documentação da Aba AI Math

> [!NOTE]
> Esta pasta contém a suíte de componentes do Lazarus sob a aba **AI Math**.

## Álgebra Vetorial e Matricial de Alta Velocidade.
Implementa rotinas matemáticas de processamento de tensores semelhantes ao NumPy do Python.

### Referência Detalhada dos Componentes

| Componente | Descrição | Propriedades Importantes | Métodos Principais | Papel do Agente de IA |
|---|---|---|---|---|
| **TNumPS** | Gerador e manipulador de matrizes e vetores. | `ThreadSafe` | `Zeros, Ones, Eye, MatMul, Sum, Mean, Std, Random` | Realizar operações matemáticas pesadas e álgebra linear para IA. |

### 💻 Exemplo de Código Lazarus (TNumPS)

```pascal
var
  MyComponent: TNumPS;
begin
  MyComponent := TNumPS.Create(Self);
  try
    // Configuration properties
    // MyComponent.Property := Value;
    
    // Execute call
    // MyComponent.ExecuteMethod;
  finally
    MyComponent.Free;
  end;
end;
```


### ⚡ Ponte de IA e Hardware
Cada um destes componentes possui uma propriedade published `Prompt` que documenta sua API interna de forma transparente para orientar Agentes de IA (`TAIAgent`) de forma automática!
