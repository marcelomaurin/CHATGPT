# 🖼️ Documentação da Aba AI Image

> [!NOTE]
> Esta pasta contém a suíte de componentes do Lazarus sob a aba **AI Image**.

## Visão Computacional e Filtros Digitais de Imagem.
Filtros avançados de preparação matricial de imagens para processamento neural de visão.

### Referência Detalhada dos Componentes

| Componente | Descrição | Propriedades Importantes | Métodos Principais | Papel do Agente de IA |
|---|---|---|---|---|
| **TAIImageFilters** | Filtro digital matricial de imagem. | `FilterType (Sobel, Canny, Gaussian, Grayscale)` | `ApplyFilter(const AInputBmp, AOutputBmp: TBitmap): Boolean` | Pré-processar imagens e frames de câmeras para melhorar taxas de reconhecimento. |

### 💻 Exemplo de Código Lazarus (TAIImageFilters)

```pascal
var
  MyComponent: TAIImageFilters;
begin
  MyComponent := TAIImageFilters.Create(Self);
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
