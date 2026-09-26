unit aillmmodelcatalog;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils;

type
  TAILLMModelInfo = record
    Provider: string;
    InternalName: string;
    FriendlyName: string;
    DefaultEndpoint: string;
    MaxTokens: Integer;
    DefaultTemperature: Double;
    RequiresAPIKey: Boolean;
    SupportsVision: Boolean;
    SupportsTools: Boolean;
    SupportsStreaming: Boolean;
    SupportsFineTuning: Boolean;
  end;

function AILLMModelCount: Integer;
function GetAILLMModelInfo(AIndex: Integer; out AInfo: TAILLMModelInfo): Boolean;
function FindAILLMModel(const AProvider, AModel: string;
  out AInfo: TAILLMModelInfo): Boolean;
procedure GetAILLMModelsForProvider(const AProvider: string; AList: TStrings);

implementation

procedure SetInfo(out AInfo: TAILLMModelInfo; const AProvider, AInternal,
  AFriendly, AEndpoint: string; AMaxTokens: Integer; ATemperature: Double;
  ARequiresKey, AVision, ATools, AStreaming, AFineTuning: Boolean);
begin
  AInfo.Provider := AProvider;
  AInfo.InternalName := AInternal;
  AInfo.FriendlyName := AFriendly;
  AInfo.DefaultEndpoint := AEndpoint;
  AInfo.MaxTokens := AMaxTokens;
  AInfo.DefaultTemperature := ATemperature;
  AInfo.RequiresAPIKey := ARequiresKey;
  AInfo.SupportsVision := AVision;
  AInfo.SupportsTools := ATools;
  AInfo.SupportsStreaming := AStreaming;
  AInfo.SupportsFineTuning := AFineTuning;
end;

function AILLMModelCount: Integer;
begin
  Result := 58;
end;

function GetAILLMModelInfo(AIndex: Integer;
  out AInfo: TAILLMModelInfo): Boolean;
const
  OpenAIEndpoint = 'https://api.openai.com/v1/chat/completions';
  OpenRouterEndpoint = 'https://openrouter.ai/api/v1/chat/completions';
  ClaudeEndpoint = 'https://api.anthropic.com/v1/messages';
  DeepSeekEndpoint = 'https://api.deepseek.com/v1/chat/completions';
  CerebrasEndpoint = 'https://api.cerebras.ai/v1/chat/completions';
  OllamaEndpoint = 'http://localhost:11434/v1/chat/completions';
begin
  Result := True;
  case AIndex of
    // OpenAI (Linha GPT-6, GPT-5.6, GPT-5.1 e GPT-4)
    0: SetInfo(AInfo, 'OpenAI', 'gpt-6-luna', 'GPT-6 Luna (OpenAI Fast/Budget)', OpenAIEndpoint, 4096, 0.7, True, True, True, True, True);
    1: SetInfo(AInfo, 'OpenAI', 'gpt-6-sol', 'GPT-6 Sol (OpenAI Advanced/Coding)', OpenAIEndpoint, 4096, 0.7, True, True, True, True, True);
    2: SetInfo(AInfo, 'OpenAI', 'gpt-6-astra', 'GPT-6 Astra (OpenAI Flagship)', OpenAIEndpoint, 4096, 0.7, True, True, True, True, True);
    3: SetInfo(AInfo, 'OpenAI', 'gpt-5.6-luna', 'GPT-5.6 Luna (OpenAI)', OpenAIEndpoint, 4096, 0.7, True, True, True, True, True);
    4: SetInfo(AInfo, 'OpenAI', 'gpt-5.6-sol', 'GPT-5.6 Sol (OpenAI)', OpenAIEndpoint, 4096, 0.7, True, True, True, True, True);
    5: SetInfo(AInfo, 'OpenAI', 'gpt-5.1', 'GPT-5.1 (OpenAI)', OpenAIEndpoint, 4096, 0.7, True, True, True, True, True);
    6: SetInfo(AInfo, 'OpenAI', 'gpt-5', 'GPT-5 (OpenAI)', OpenAIEndpoint, 4096, 0.7, True, True, True, True, True);
    7: SetInfo(AInfo, 'OpenAI', 'gpt-4o', 'GPT-4o (OpenAI)', OpenAIEndpoint, 4096, 0.7, True, True, True, True, True);
    8: SetInfo(AInfo, 'OpenAI', 'gpt-4o-mini', 'GPT-4o Mini (OpenAI)', OpenAIEndpoint, 4096, 0.7, True, True, True, True, True);
    9: SetInfo(AInfo, 'OpenAI', 'o3-mini', 'o3-mini (OpenAI Reasoning)', OpenAIEndpoint, 4096, 1.0, True, False, True, True, False);
    10: SetInfo(AInfo, 'OpenAI', 'o1', 'o1 (OpenAI Reasoning)', OpenAIEndpoint, 4096, 1.0, True, False, True, True, False);
    11: SetInfo(AInfo, 'OpenAI', 'o1-mini', 'o1-mini (OpenAI Reasoning)', OpenAIEndpoint, 4096, 1.0, True, False, True, True, False);
    12: SetInfo(AInfo, 'OpenAI', 'gpt-4-turbo', 'GPT-4 Turbo (OpenAI)', OpenAIEndpoint, 4096, 0.7, True, True, True, True, True);
    13: SetInfo(AInfo, 'OpenAI', 'gpt-3.5-turbo', 'GPT-3.5 Turbo (OpenAI)', OpenAIEndpoint, 4096, 0.7, True, False, True, True, True);

    // Google Gemini (Modelos atualizados)
    14: SetInfo(AInfo, 'Gemini', 'gemini-2.0-flash', 'Gemini 2.0 Flash (Google)', '', 8192, 0.7, True, True, True, False, False);
    15: SetInfo(AInfo, 'Gemini', 'gemini-2.0-flash-lite', 'Gemini 2.0 Flash Lite (Google)', '', 8192, 0.7, True, True, True, False, False);
    16: SetInfo(AInfo, 'Gemini', 'gemini-1.5-flash', 'Gemini 1.5 Flash (Google)', '', 8192, 0.7, True, True, True, False, False);
    17: SetInfo(AInfo, 'Gemini', 'gemini-1.5-pro', 'Gemini 1.5 Pro (Google)', '', 8192, 0.7, True, True, True, False, False);
    18: SetInfo(AInfo, 'Gemini', 'gemini-2.5-flash', 'Gemini 2.5 Flash (Google Preview)', '', 8192, 0.7, True, True, True, False, False);
    19: SetInfo(AInfo, 'Gemini', 'gemini-2.5-pro', 'Gemini 2.5 Pro (Google Preview)', '', 8192, 0.7, True, True, True, False, False);

    // Anthropic Claude (Modelos atualizados incluindo 3.7 Sonnet)
    20: SetInfo(AInfo, 'Claude', 'claude-3-7-sonnet-20250219', 'Claude 3.7 Sonnet (Anthropic)', ClaudeEndpoint, 4096, 0.7, True, True, True, False, False);
    21: SetInfo(AInfo, 'Claude', 'claude-3-5-sonnet-20241022', 'Claude 3.5 Sonnet (Anthropic)', ClaudeEndpoint, 4096, 0.7, True, True, True, False, False);
    22: SetInfo(AInfo, 'Claude', 'claude-3-5-haiku-20241022', 'Claude 3.5 Haiku (Anthropic)', ClaudeEndpoint, 4096, 0.7, True, False, True, False, False);
    23: SetInfo(AInfo, 'Claude', 'claude-3-opus-20240229', 'Claude 3 Opus (Anthropic)', ClaudeEndpoint, 4096, 0.7, True, True, True, False, False);

    // DeepSeek Direct API
    24: SetInfo(AInfo, 'DeepSeek', 'deepseek-chat', 'DeepSeek-V3 Chat', DeepSeekEndpoint, 8192, 0.7, True, False, True, True, False);
    25: SetInfo(AInfo, 'DeepSeek', 'deepseek-reasoner', 'DeepSeek-R1 Reasoner', DeepSeekEndpoint, 8192, 0.6, True, False, True, True, False);

    // Local / Ollama
    26: SetInfo(AInfo, 'Local', 'llama3.2:3b', 'Llama 3.2 3B (Ollama)', OllamaEndpoint, 4096, 0.7, False, False, False, True, False);
    27: SetInfo(AInfo, 'Local', 'llama3.2:1b', 'Llama 3.2 1B (Ollama)', OllamaEndpoint, 4096, 0.7, False, False, False, True, False);
    28: SetInfo(AInfo, 'Local', 'llama3.3:70b', 'Llama 3.3 70B (Ollama)', OllamaEndpoint, 4096, 0.7, False, False, False, True, False);
    29: SetInfo(AInfo, 'Local', 'qwen2.5:1.5b', 'Qwen 2.5 1.5B (Ollama)', OllamaEndpoint, 4096, 0.7, False, False, False, True, False);
    30: SetInfo(AInfo, 'Local', 'qwen2.5:7b', 'Qwen 2.5 7B (Ollama)', OllamaEndpoint, 4096, 0.7, False, False, False, True, False);
    31: SetInfo(AInfo, 'Local', 'deepseek-r1:1.5b', 'DeepSeek R1 1.5B (Ollama)', OllamaEndpoint, 4096, 0.6, False, False, False, True, False);
    32: SetInfo(AInfo, 'Local', 'deepseek-r1:8b', 'DeepSeek R1 8B (Ollama)', OllamaEndpoint, 4096, 0.6, False, False, False, True, False);
    33: SetInfo(AInfo, 'Local', 'deepseek-r1:14b', 'DeepSeek R1 14B (Ollama)', OllamaEndpoint, 4096, 0.6, False, False, False, True, False);
    34: SetInfo(AInfo, 'Local', 'deepseek-r1:70b', 'DeepSeek R1 70B (Ollama)', OllamaEndpoint, 4096, 0.6, False, False, False, True, False);

    // OpenRouter
    35: SetInfo(AInfo, 'OpenRouter', 'meta-llama/llama-3.3-70b-instruct:free', 'Llama 3.3 70B Free (OpenRouter)', OpenRouterEndpoint, 4096, 0.7, True, False, False, True, False);
    36: SetInfo(AInfo, 'OpenRouter', 'meta-llama/llama-3-8b-instruct:free', 'Llama 3 8B Free (OpenRouter)', OpenRouterEndpoint, 4096, 0.7, True, False, False, True, False);
    37: SetInfo(AInfo, 'OpenRouter', 'google/gemma-2-9b-it:free', 'Gemma 2 9B Free (OpenRouter)', OpenRouterEndpoint, 4096, 0.7, True, False, False, True, False);
    38: SetInfo(AInfo, 'OpenRouter', 'deepseek/deepseek-r1:free', 'DeepSeek R1 Free (OpenRouter)', OpenRouterEndpoint, 4096, 0.6, True, False, False, True, False);
    39: SetInfo(AInfo, 'OpenRouter', 'meta-llama/llama-3.2-3b-instruct:free', 'Llama 3.2 3B Free (OpenRouter)', OpenRouterEndpoint, 4096, 0.7, True, False, False, True, False);

    // Cerebras
    40: SetInfo(AInfo, 'Cerebras', 'llama3.1-8b', 'Llama 3.1 8B (Cerebras Fast)', CerebrasEndpoint, 4096, 0.7, True, False, True, True, False);
    41: SetInfo(AInfo, 'Cerebras', 'llama3.1-70b', 'Llama 3.1 70B (Cerebras Fast)', CerebrasEndpoint, 4096, 0.7, True, False, True, True, False);
    42: SetInfo(AInfo, 'Cerebras', 'qwen-3-235b-a22b-instruct-2507', 'Cerebras Qwen 3 235B', CerebrasEndpoint, 4096, 0.7, True, False, True, True, False);

    // OpenAI-compatible
    43: SetInfo(AInfo, 'OpenAI-compatible', 'gpt-6-luna', 'GPT-6 Luna', 'http://localhost:8000/v1/chat/completions', 4096, 0.7, False, True, True, True, False);
    44: SetInfo(AInfo, 'OpenAI-compatible', 'gpt-6-sol', 'GPT-6 Sol', 'http://localhost:8000/v1/chat/completions', 4096, 0.7, False, True, True, True, False);
    45: SetInfo(AInfo, 'OpenAI-compatible', 'gpt-5.6-luna', 'GPT-5.6 Luna', 'http://localhost:8000/v1/chat/completions', 4096, 0.7, False, True, True, True, False);
    46: SetInfo(AInfo, 'OpenAI-compatible', 'gpt-4o-mini', 'GPT-4o Mini', 'http://localhost:8000/v1/chat/completions', 4096, 0.7, False, True, True, True, False);
    47: SetInfo(AInfo, 'OpenAI-compatible', 'gpt-4o', 'GPT-4o', 'http://localhost:8000/v1/chat/completions', 4096, 0.7, False, True, True, True, False);
    48: SetInfo(AInfo, 'OpenAI-compatible', 'gpt-3.5-turbo', 'GPT-3.5 Turbo', 'http://localhost:8000/v1/chat/completions', 4096, 0.7, False, False, True, True, False);
    49: SetInfo(AInfo, 'OpenAI-compatible', 'llama-3.2-3b-instruct', 'Llama 3.2 3B', 'http://localhost:8000/v1/chat/completions', 4096, 0.7, False, False, False, True, False);
    50: SetInfo(AInfo, 'OpenAI-compatible', 'deepseek-chat', 'DeepSeek Chat', 'http://localhost:8000/v1/chat/completions', 8192, 0.7, False, False, True, True, False);
    51: SetInfo(AInfo, 'OpenAI-compatible', 'custom-model', 'Custom model', 'http://localhost:8000/v1/chat/completions', 4096, 0.7, False, False, False, True, False);

    // llama.cpp
    52: SetInfo(AInfo, 'llama.cpp', 'llama3.2:3b', 'Llama 3.2 3B (llama.cpp)', 'http://localhost:8080/v1/chat/completions', 4096, 0.7, False, False, False, True, False);
    53: SetInfo(AInfo, 'llama.cpp', 'qwen2.5:1.5b', 'Qwen 2.5 1.5B (llama.cpp)', 'http://localhost:8080/v1/chat/completions', 4096, 0.7, False, False, False, True, False);
    54: SetInfo(AInfo, 'llama.cpp', 'deepseek-r1:1.5b', 'DeepSeek R1 1.5B (llama.cpp)', 'http://localhost:8080/v1/chat/completions', 4096, 0.6, False, False, False, True, False);
    55: SetInfo(AInfo, 'llama.cpp', 'custom-model', 'Custom model (llama.cpp)', 'http://localhost:8080/v1/chat/completions', 4096, 0.7, False, False, False, True, False);

    // neural-api
    56: SetInfo(AInfo, 'neural-api', 'default', 'Default Model (neural-api)', 'http://localhost:8000/v1/chat/completions', 4096, 0.7, False, False, False, True, False);
    57: SetInfo(AInfo, 'neural-api', 'custom-model', 'Custom model (neural-api)', 'http://localhost:8000/v1/chat/completions', 4096, 0.7, False, False, False, True, False);
  else
    Result := False;
  end;
end;

function FindAILLMModel(const AProvider, AModel: string;
  out AInfo: TAILLMModelInfo): Boolean;
var
  I: Integer;
begin
  for I := 0 to AILLMModelCount - 1 do
    if GetAILLMModelInfo(I, AInfo) and
       ((AProvider = '') or SameText(AInfo.Provider, AProvider)) and
       (SameText(AInfo.InternalName, AModel) or
        SameText(AInfo.FriendlyName, AModel)) then
      Exit(True);
  Result := False;
end;

procedure GetAILLMModelsForProvider(const AProvider: string; AList: TStrings);
var
  I: Integer;
  Info: TAILLMModelInfo;
begin
  if AList = nil then
    Exit;
  AList.Clear;
  for I := 0 to AILLMModelCount - 1 do
    if GetAILLMModelInfo(I, Info) and SameText(Info.Provider, AProvider) then
      AList.Add(Info.InternalName);
end;

end.
