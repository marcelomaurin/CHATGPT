unit aillmmodelcatalog;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils;

const
  AI_LLM_CATALOG_VERIFIED_DATE = '2026-10-25';

type
  TAILLMModelInfo = record
    IsLegacy: Boolean;
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
procedure GetAILLMModelsForProvider(const AProvider: string; AList: TStrings;
  AIncludeLegacy: Boolean = False);

function GetAILLMDefaultModel(const AProvider: string): string;

implementation

procedure SetInfo(out AInfo: TAILLMModelInfo; const AProvider, AInternal,
  AFriendly, AEndpoint: string; AMaxTokens: Integer; ATemperature: Double;
  ARequiresKey, AVision, ATools, AStreaming, AFineTuning: Boolean);
begin
  AInfo.IsLegacy := False;
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
  Result := 92;
end;

function GetAILLMModelInfo(AIndex: Integer;
  out AInfo: TAILLMModelInfo): Boolean;
const
  OpenAIEndpoint = 'https://api.openai.com/v1/chat/completions';
  OpenRouterEndpoint = 'https://openrouter.ai/api/v1/chat/completions';
  ClaudeEndpoint = 'https://api.anthropic.com/v1/messages';
  DeepSeekEndpoint = 'https://api.deepseek.com/v1/chat/completions';
  CerebrasEndpoint = 'https://api.cerebras.ai/v1/chat/completions';
  GroqEndpoint = 'https://api.groq.com/openai/v1/chat/completions';
  MistralEndpoint = 'https://api.mistral.ai/v1/chat/completions';
  XAIEndpoint = 'https://api.x.ai/v1/chat/completions';
  QwenEndpoint = 'https://WORKSPACE_ID.ap-southeast-1.maas.aliyuncs.com/compatible-mode/v1/chat/completions';
  RunPodEndpoint = 'https://api.runpod.ai/v2/ENDPOINT_ID/openai/v1/chat/completions';
  OllamaEndpoint = 'http://localhost:11434/v1/chat/completions';
begin
  Result := True;
  case AIndex of
    // OpenAI (Linha GPT-6, GPT-5.6, GPT-5.1 e GPT-4)
    0: SetInfo(AInfo, 'OpenAI', 'gpt-6-luna', 'GPT-6 Luna (OpenAI Fast/Budget)', OpenAIEndpoint, 8192, 1.0, True, True, True, True, False);
    1: SetInfo(AInfo, 'OpenAI', 'gpt-6-sol', 'GPT-6 Sol (OpenAI Advanced/Coding)', OpenAIEndpoint, 8192, 1.0, True, True, True, True, False);
    2: SetInfo(AInfo, 'OpenAI', 'gpt-6-astra', 'GPT-6 Astra (OpenAI Flagship)', OpenAIEndpoint, 8192, 1.0, True, True, True, True, False);
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
    58: SetInfo(AInfo, 'OpenAI', 'gpt-6.1-sol', 'GPT-6.1 Sol', OpenAIEndpoint, 8192, 1.0, True, True, True, True, False);
    59: SetInfo(AInfo, 'Gemini', 'gemini-3.8-flash', 'Gemini 3.8 Flash', '', 8192, 0.7, True, True, True, False, False);
    60: SetInfo(AInfo, 'Gemini', 'gemini-4-argon', 'Gemini 4 Argon', '', 8192, 0.7, True, True, True, False, False);
    61: SetInfo(AInfo, 'Gemini', 'gemini-3.5-flash-lite', 'Gemini 3.5 Flash-Lite', '', 8192, 0.7, True, True, True, False, False);
    62: SetInfo(AInfo, 'Gemini', 'gemini-3.1-pro-preview', 'Gemini 3.1 Pro (Preview)', '', 8192, 0.7, True, True, True, False, False);
    63: SetInfo(AInfo, 'Claude', 'claude-sonnet-5-5', 'Claude Sonnet 5.5', ClaudeEndpoint, 8192, 1.0, True, True, True, False, False);
    64: SetInfo(AInfo, 'Claude', 'claude-opus-5-5', 'Claude Opus 5.5', ClaudeEndpoint, 8192, 1.0, True, True, True, False, False);
    65: SetInfo(AInfo, 'Claude', 'claude-haiku-5-5', 'Claude Haiku 5.5', ClaudeEndpoint, 8192, 1.0, True, True, True, False, False);
    66: SetInfo(AInfo, 'Claude', 'claude-fable-5-1', 'Claude Fable 5.1', ClaudeEndpoint, 8192, 1.0, True, True, True, False, False);
    67: SetInfo(AInfo, 'DeepSeek', 'deepseek-flash', 'DeepSeek Flash (V4.1)', DeepSeekEndpoint, 8192, 1.0, True, True, True, True, False);
    68: SetInfo(AInfo, 'DeepSeek', 'deepseek-v4-pro', 'DeepSeek V4 Pro', DeepSeekEndpoint, 8192, 1.0, True, False, True, True, False);
    69: SetInfo(AInfo, 'Groq', 'openai/gpt-oss-120b', 'GPT-OSS 120B (Groq)', GroqEndpoint, 8192, 0.7, True, False, True, True, False);
    70: SetInfo(AInfo, 'Groq', 'openai/gpt-oss-20b', 'GPT-OSS 20B (Groq)', GroqEndpoint, 8192, 0.7, True, False, True, True, False);
    71: SetInfo(AInfo, 'Groq', 'llama-3.3-70b-versatile', 'Llama 3.3 70B (Groq)', GroqEndpoint, 8192, 0.7, True, False, True, True, False);
    72: SetInfo(AInfo, 'Groq', 'llama-3.1-8b-instant', 'Llama 3.1 8B (Groq)', GroqEndpoint, 8192, 0.7, True, False, True, True, False);
    73: SetInfo(AInfo, 'Mistral', 'mistral-small-2603', 'Mistral Small 4', MistralEndpoint, 8192, 0.7, True, True, True, True, False);
    74: SetInfo(AInfo, 'Mistral', 'mistral-medium-3-5', 'Mistral Medium 3.5', MistralEndpoint, 8192, 0.7, True, True, True, True, False);
    75: SetInfo(AInfo, 'Mistral', 'mistral-large-4', 'Mistral Large 4 (Public Preview)', MistralEndpoint, 8192, 0.7, True, True, True, True, False);
    76: SetInfo(AInfo, 'xAI', 'grok-4.7', 'Grok 4.7 (xAI)', XAIEndpoint, 8192, 0.7, True, True, True, True, False);
    77: SetInfo(AInfo, 'Qwen', 'qwen3.8-max', 'Qwen 3.8 Max', QwenEndpoint, 8192, 0.7, True, True, True, True, False);
    78: SetInfo(AInfo, 'Qwen', 'qwen3.7-plus', 'Qwen 3.7 Plus', QwenEndpoint, 8192, 0.7, True, True, True, True, False);
    79: SetInfo(AInfo, 'Qwen', 'qwen3.8-flash', 'Qwen 3.8 Flash', QwenEndpoint, 8192, 0.7, True, True, True, True, False);
    80: SetInfo(AInfo, 'Cerebras', 'gpt-oss-120b', 'GPT-OSS 120B (Cerebras)', CerebrasEndpoint, 8192, 0.7, True, False, True, True, False);
    81: SetInfo(AInfo, 'Cerebras', 'qwen-3.8-27b', 'Qwen 3.8 27B (Cerebras)', CerebrasEndpoint, 8192, 0.7, True, False, True, True, False);
    82: SetInfo(AInfo, 'OpenRouter', 'openrouter/free', 'Free Models Router (OpenRouter)', OpenRouterEndpoint, 8192, 0.7, True, True, True, True, False);
    83: SetInfo(AInfo, 'OpenRouter', 'openrouter/auto', 'Auto Router (OpenRouter)', OpenRouterEndpoint, 8192, 0.7, True, True, True, True, False);
    84: SetInfo(AInfo, 'Local', 'qwen3:8b', 'Qwen 3 8B (Ollama)', OllamaEndpoint, 8192, 0.7, False, False, True, True, False);
    85: SetInfo(AInfo, 'Local', 'qwen3:4b', 'Qwen 3 4B (Ollama)', OllamaEndpoint, 8192, 0.7, False, False, True, True, False);
    86: SetInfo(AInfo, 'Local', 'gemma3:4b', 'Gemma 3 4B (Ollama)', OllamaEndpoint, 8192, 0.7, False, True, False, True, False);
    87: SetInfo(AInfo, 'Local', 'gemma3:12b', 'Gemma 3 12B (Ollama)', OllamaEndpoint, 8192, 0.7, False, True, False, True, False);
    88: SetInfo(AInfo, 'Local', 'gpt-oss:20b', 'GPT-OSS 20B (Ollama)', OllamaEndpoint, 8192, 0.7, False, False, True, True, False);
    89: SetInfo(AInfo, 'RunPod', 'custom-model', 'RunPod Serverless / vLLM', RunPodEndpoint, 8192, 0.7, True, False, False, True, False);
    90: SetInfo(AInfo, 'OpenAI', 'gpt-4.1', 'GPT-4.1 (compatibility)', OpenAIEndpoint, 4096, 0.7, True, True, True, True, True);
    91: SetInfo(AInfo, 'OpenAI', 'gpt-4.1-mini', 'GPT-4.1 Mini (compatibility)', OpenAIEndpoint, 4096, 0.7, True, True, True, True, True);
  else
    Result := False;
  end;
  // Historical entries remain addressable but are hidden from suggested lists.
  AInfo.IsLegacy := AIndex in [3..25, 35..50];
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

procedure GetAILLMModelsForProvider(const AProvider: string; AList: TStrings;
  AIncludeLegacy: Boolean);
var
  I: Integer;
  Info: TAILLMModelInfo;
begin
  if AList = nil then
    Exit;
  AList.Clear;
  for I := 0 to AILLMModelCount - 1 do
    if GetAILLMModelInfo(I, Info) and SameText(Info.Provider, AProvider) and
       (AIncludeLegacy or not Info.IsLegacy) then
      AList.Add(Info.InternalName);
end;

function GetAILLMDefaultModel(const AProvider: string): string;
var
  I: Integer;
  Info: TAILLMModelInfo;
begin
  Result := '';
  for I := 0 to AILLMModelCount - 1 do
    if GetAILLMModelInfo(I, Info) and SameText(Info.Provider, AProvider) and
       not Info.IsLegacy then
      Exit(Info.InternalName);
end;

end.
