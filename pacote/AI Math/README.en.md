# 📐 Documentation for AI Math Tab

> [!NOTE]
> This folder contains the Lazarus components suite under the **AI Math** tab.

## High-Speed Vector and Matrix Algebra.
Implements mathematical tensor routines similar to Python's NumPy library.

### Detailed Component Reference

| Component | Description | Important Properties | Main Methods | AI Agent Role |
|---|---|---|---|---|
| **TNumPS** | Matrix and vector generator and manipulator. | `ThreadSafe` | `Zeros, Ones, Eye, MatMul, Sum, Mean, Std, Random` | Perform heavy statistical computations and linear algebra operations for the AI. |

### 💻 Lazarus Code Example (TNumPS)

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


### ⚡ AI and Hardware Bridge
Each of these components features a published `Prompt` property that transparently documents its internal API to guide AI Agents (`TAIAgent`) autonomously!
