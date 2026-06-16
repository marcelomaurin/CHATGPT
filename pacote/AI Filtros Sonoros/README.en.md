# 🎵 Documentation for AI Filtros Sonoros Tab

> [!NOTE]
> This folder contains the Lazarus components suite under the **AI Filtros Sonoros** tab.

## Audio Signal Processing and Digital Filters.
Module for sound frequency transformations and fast linear filtering applications.

### Detailed Component Reference

| Component | Description | Important Properties | Main Methods | AI Agent Role |
|---|---|---|---|---|
| **TAISoundFilters** | Sound signal digital processor. | `FilterType (LowPass, HighPass, BandPass), CutoffFrequency` | `ApplyFilter(const AInputWav, AOutputWav: string): Boolean` | Clean background noises and adjust frequencies of recordings obtained via microphones. |

### 💻 Lazarus Code Example (TAISoundFilters)

```pascal
var
  MyComponent: TAISoundFilters;
begin
  MyComponent := TAISoundFilters.Create(Self);
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


### ⚡ AI and Hardware Bridge
Each of these components features a published `Prompt` property that transparently documents its internal API to guide AI Agents (`TAIAgent`) autonomously!
