# 🖼️ Documentazione della Scheda IA Image

> [!NOTE]
> Questa cartella contiene la suite di componenti Lazarus sotto la scheda **IA Image**.

## Visione Artificiale e Filtri Digitali di Immagine.
Filtri avanzati di preparazione matriciale delle immagini per l'elaborazione della visione neurale.

### Riferimento Dettagliato dei Componenti

| Componente | Descrizione | Proprietà Importanti | Metodi Principali | Ruolo dell'Agente di IA |
|---|---|---|---|---|
| **TAIImageFilters** | Filtro d'immagine matriciale digitale. | `FilterType (Sobel, Canny, Gaussian, Grayscale)` | `ApplyFilter(const AInputBmp, AOutputBmp: TBitmap): Boolean` | Pre-elaborare immagini e fotogrammi per migliorare la precisione del riconoscimento. |

### 💻 Esempio di Codice Lazarus (TAIImageFilters)

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


### ⚡ Ponte di IA e Hardware
Ciascuno di questi componenti include una proprietà published `Prompt` che documenta in modo trasparente le proprie API interne per orientare gli Agenti IA (`TAIAgent`) autonomamente.
