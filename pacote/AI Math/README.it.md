# 📐 Documentazione della Scheda AI Math

> [!NOTE]
> Questa cartella contiene la suite di componenti Lazarus sotto la scheda **AI Math**.

## Algebra Vettoriale e Matriciale ad Alta Velocità.
Implementa routine matematiche per l'elaborazione di tensori simili a NumPy di Python.

### Riferimento Dettagliato dei Componenti

| Componente | Descrizione | Proprietà Importanti | Metodi Principali | Ruolo dell'Agente di IA |
|---|---|---|---|---|
| **TNumPS** | Generatore e manipolatore di matrici e vettori. | `ThreadSafe` | `Zeros, Ones, Eye, MatMul, Sum, Mean, Std, Random` | Eseguire calcoli statistici pesanti e operazioni di algebra lineare per l'IA. |

### 💻 Esempio di Codice Lazarus (TNumPS)

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


### ⚡ Ponte di IA e Hardware
Ciascuno di questi componenti include una proprietà published `Prompt` che documenta in modo trasparente le proprie API interne per orientare gli Agenti IA (`TAIAgent`) autonomamente.
