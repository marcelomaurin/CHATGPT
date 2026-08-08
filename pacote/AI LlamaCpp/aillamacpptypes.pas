unit aillamacpptypes;

{$mode ObjFPC}{$H+}

interface

const
  AI_LLAMA_CLI_FILENAME = 'llama-cli.exe';
  AI_LLAMA_SERVER_FILENAME = 'llama-server.exe';
  AI_LLAMA_QUANTIZE_FILENAME = 'llama-quantize.exe';
  AI_LLAMA_LIBRARY_FILENAME = 'llama.dll';
  AI_GGML_LIBRARY_FILENAME = 'ggml.dll';
  AI_GGML_BASE_LIBRARY_FILENAME = 'ggml-base.dll';
  AI_GGML_CPU_LIBRARY_FILENAME = 'ggml-cpu.dll';

type
  TAILlamaState = (
    llsUnavailable,
    llsReady,
    llsLoading,
    llsLoaded,
    llsGenerating,
    llsError
  );

  TAILlamaBackend = (
    llbAuto,
    llbCPU,
    llbCUDA,
    llbVulkan
  );

  TAILlamaAccessMode = (
    llamServer,
    llamNative
  );

  TAILlamaSamplingConfig = record
    Temperature: Double;
    TopK: Integer;
    TopP: Double;
    Seed: Integer;
    MaxTokens: Integer;
  end;

  TAILlamaVersionInfo = record
    Version: string;
    Build: string;
    Commit: string;
    Architecture: string;
    Backend: string;
  end;

implementation

end.
