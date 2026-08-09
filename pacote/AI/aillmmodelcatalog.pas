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
  Result := 38;
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
    0: SetInfo(AInfo, 'OpenAI', 'gpt-4o', 'GPT-4o (OpenAI)', OpenAIEndpoint, 4096, 0.7, True, True, True, True, True);
    1: SetInfo(AInfo, 'OpenAI', 'gpt-4o-mini', 'GPT-4o Mini (OpenAI)', OpenAIEndpoint, 4096, 0.7, True, True, True, True, True);
    2: SetInfo(AInfo, 'OpenAI', 'o3-mini', 'o3-mini (OpenAI Reasoning)', OpenAIEndpoint, 4096, 1.0, True, False, True, True, False);
    3: SetInfo(AInfo, 'OpenAI', 'gpt-3.5-turbo', 'GPT-3.5 Turbo (OpenAI)', OpenAIEndpoint, 4096, 0.7, True, False, True, True, True);
    4: SetInfo(AInfo, 'Gemini', 'gemini-2.5-flash', 'Gemini 2.5 Flash (Google)', '', 8192, 0.7, True, True, True, False, False);
    5: SetInfo(AInfo, 'Gemini', 'gemini-2.0-flash', 'Gemini 2.0 Flash (Google)', '', 8192, 0.7, True, True, True, False, False);
    6: SetInfo(AInfo, 'Gemini', 'gemini-2.5-pro', 'Gemini 2.5 Pro (Google)', '', 8192, 0.7, True, True, True, False, False);
    7: SetInfo(AInfo, 'Claude', 'claude-3-5-sonnet-20241022', 'Claude 3.5 Sonnet (Anthropic)', ClaudeEndpoint, 4096, 0.7, True, True, True, False, False);
    8: SetInfo(AInfo, 'Claude', 'claude-3-5-haiku-20241022', 'Claude 3.5 Haiku (Anthropic)', ClaudeEndpoint, 4096, 0.7, True, False, True, False, False);
    9: SetInfo(AInfo, 'Local', 'llama3.2:3b', 'Llama 3.2 3B (Ollama)', OllamaEndpoint, 4096, 0.7, False, False, False, True, False);
    10: SetInfo(AInfo, 'Local', 'qwen2.5:1.5b', 'Qwen 2.5 1.5B (Ollama)', OllamaEndpoint, 4096, 0.7, False, False, False, True, False);
    11: SetInfo(AInfo, 'Local', 'deepseek-r1:1.5b', 'DeepSeek R1 1.5B (Ollama)', OllamaEndpoint, 4096, 0.6, False, False, False, True, False);
    12: SetInfo(AInfo, 'Local', 'deepseek-r1:8b', 'DeepSeek R1 8B (Ollama)', OllamaEndpoint, 4096, 0.6, False, False, False, True, False);
    13: SetInfo(AInfo, 'OpenRouter', 'meta-llama/llama-3-8b-instruct:free', 'Llama 3 8B Free (OpenRouter)', OpenRouterEndpoint, 4096, 0.7, True, False, False, True, False);
    14: SetInfo(AInfo, 'OpenRouter', 'google/gemma-2-9b-it:free', 'Gemma 2 9B Free (OpenRouter)', OpenRouterEndpoint, 4096, 0.7, True, False, False, True, False);
    15: SetInfo(AInfo, 'OpenRouter', 'deepseek/deepseek-r1:free', 'DeepSeek R1 Free (OpenRouter)', OpenRouterEndpoint, 4096, 0.6, True, False, False, True, False);
    16: SetInfo(AInfo, 'Cerebras', 'qwen-3-235b-a22b-instruct-2507', 'Cerebras Qwen 3 235B', CerebrasEndpoint, 4096, 0.7, True, False, True, True, False);
    17: SetInfo(AInfo, 'DeepSeek', 'deepseek-chat', 'DeepSeek Chat', DeepSeekEndpoint, 8192, 0.7, True, False, True, True, False);
    18: SetInfo(AInfo, 'DeepSeek', 'deepseek-reasoner', 'DeepSeek Reasoner', DeepSeekEndpoint, 8192, 0.6, True, False, True, True, False);
    19: SetInfo(AInfo, 'OpenAI-compatible', 'custom-model', 'Custom OpenAI-compatible model', 'http://localhost:8000/v1/chat/completions', 4096, 0.7, False, False, False, True, False);
    20: SetInfo(AInfo, 'llama.cpp', 'custom-model', 'llama.cpp model', 'http://localhost:8080/v1/chat/completions', 4096, 0.7, False, False, False, True, False);
    21: SetInfo(AInfo, 'neural-api', 'custom-model', 'neural-api model', 'http://localhost:8000/v1/chat/completions', 4096, 0.7, False, False, False, True, False);
    22: SetInfo(AInfo, 'OpenAI', 'gpt-4', 'GPT-4 (legacy)', OpenAIEndpoint, 4096, 0.7, True, False, True, True, True);
    23: SetInfo(AInfo, 'OpenAI', 'gpt-4-turbo', 'GPT-4 Turbo (legacy)', OpenAIEndpoint, 4096, 0.7, True, True, True, True, True);
    24: SetInfo(AInfo, 'OpenAI', 'o1', 'o1 (OpenAI Reasoning)', OpenAIEndpoint, 4096, 1.0, True, False, True, True, False);
    25: SetInfo(AInfo, 'OpenAI', 'o1-mini', 'o1-mini (OpenAI Reasoning)', OpenAIEndpoint, 4096, 1.0, True, False, True, True, False);
    26: SetInfo(AInfo, 'OpenAI', 'o1-preview', 'o1-preview (legacy)', OpenAIEndpoint, 4096, 1.0, True, False, True, True, False);
    27: SetInfo(AInfo, 'OpenAI', 'gpt-4.1', 'GPT-4.1 (OpenAI)', OpenAIEndpoint, 4096, 0.7, True, True, True, True, True);
    28: SetInfo(AInfo, 'OpenAI', 'gpt-4.1-mini', 'GPT-4.1 Mini (OpenAI)', OpenAIEndpoint, 4096, 0.7, True, True, True, True, True);
    29: SetInfo(AInfo, 'OpenAI', 'gpt-5', 'GPT-5 (legacy enum)', OpenAIEndpoint, 4096, 0.7, True, True, True, True, False);
    30: SetInfo(AInfo, 'Gemini', 'gemini-1.5-flash', 'Gemini 1.5 Flash (legacy)', '', 8192, 0.7, True, True, True, False, False);
    31: SetInfo(AInfo, 'Gemini', 'gemini-1.5-pro', 'Gemini 1.5 Pro (legacy)', '', 8192, 0.7, True, True, True, False, False);
    32: SetInfo(AInfo, 'Claude', 'claude-3-opus-20240229', 'Claude 3 Opus (legacy)', ClaudeEndpoint, 4096, 0.7, True, True, True, False, False);
    33: SetInfo(AInfo, 'Local', 'deepseek-r1:14b', 'DeepSeek R1 14B (Ollama)', OllamaEndpoint, 4096, 0.6, False, False, False, True, False);
    34: SetInfo(AInfo, 'Local', 'deepseek-r1:70b', 'DeepSeek R1 70B (Ollama)', OllamaEndpoint, 4096, 0.6, False, False, False, True, False);
    35: SetInfo(AInfo, 'Local', 'deepseek_r1:1_5b', 'DeepSeek R1 1.5B (legacy id)', OllamaEndpoint, 4096, 0.6, False, False, False, True, False);
    36: SetInfo(AInfo, 'Local', 'deepseek_r1:7b', 'DeepSeek R1 7B (legacy id)', OllamaEndpoint, 4096, 0.6, False, False, False, True, False);
    37: SetInfo(AInfo, 'OpenRouter', 'meta-llama/llama-3.2-3b-instruct:free', 'Llama 3.2 3B Free (OpenRouter)', OpenRouterEndpoint, 4096, 0.7, True, False, False, True, False);
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
