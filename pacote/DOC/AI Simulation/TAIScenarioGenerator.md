# TAIScenarioGenerator Documentation

The `TAIScenarioGenerator` component generates simulation scenario configurations from natural language prompts using the `TCHATGPT` LLM component.

## Class Hierarchy
- `TComponent`
  - `TAIBaseComponent`
    - **`TAIScenarioGenerator`**

## Key Properties

| Property | Type | Default | Description |
|---|---|---|---|
| `ChatGPT` | `TCHATGPT` | `nil` | Reference to the LLM client used for generation. Must be assigned before calling `GenerateFromPrompt`. |
| `LastGeneratedConfig` | `TAIScenarioConfig` | `nil` | (Read-only) The most recently generated scenario configuration. |

## Key Methods

- **`function GenerateFromPrompt(const APrompt: string): Boolean`**
  Sends `APrompt` to the configured `TCHATGPT` component and parses the response into a `TAIScenarioConfig`. Returns `True` on success.

## Example Usage

```pascal
var
  Gen: TAIScenarioGenerator;
begin
  Gen := TAIScenarioGenerator.Create(nil);
  try
    Gen.ChatGPT := MyChatGPT;
    if Gen.GenerateFromPrompt(
      'Create a predator-prey ecosystem on a 20x20 grid ' +
      'with 10 predators and 50 prey animals') then
    begin
      Gen.LastGeneratedConfig.ApplyToEngine(SimEngine);
      WriteLn('Scenario generated: ', Gen.LastGeneratedConfig.ScenarioName);
    end
    else
      WriteLn('Generation failed: ', Gen.LastError);
  finally
    Gen.Free;
  end;
end;
```
