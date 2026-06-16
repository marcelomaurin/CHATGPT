# 🖼️ Documentation for AI Image Tab

> [!NOTE]
> This folder contains the Lazarus components suite under the **AI Image** tab.

## Computer Vision and Digital Image Filters.
Advanced matrix image preparation filters for neural vision processing.

### Detailed Component Reference

| Component | Description | Important Properties | Main Methods | AI Agent Role |
|---|---|---|---|---|
| **TAIImageFilters** | Digital matrix image filter. | `FilterType (Sobel, Canny, Gaussian, Grayscale)` | `ApplyFilter(const AInputBmp, AOutputBmp: TBitmap): Boolean` | Preprocess images and camera frames to enhance neural recognition accuracy. |

### 💻 Lazarus Code Example (TAIImageFilters)

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


### ⚡ AI and Hardware Bridge
Each of these components features a published `Prompt` property that transparently documents its internal API to guide AI Agents (`TAIAgent`) autonomously!
