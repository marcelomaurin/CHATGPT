#ifndef CHATGPT_LLAMA_BRIDGE_H
#define CHATGPT_LLAMA_BRIDGE_H

#define CHATGPT_LLAMA_BRIDGE_API_VERSION 1

#if defined(_WIN32)
  #if defined(CHATGPT_LLAMA_BRIDGE_EXPORTS)
    #define CHATGPT_LLAMA_BRIDGE_API __declspec(dllexport)
  #else
    #define CHATGPT_LLAMA_BRIDGE_API __declspec(dllimport)
  #endif
#else
  #define CHATGPT_LLAMA_BRIDGE_API
#endif

#ifdef __cplusplus
extern "C" {
#endif

typedef struct AI_LlamaHandle AI_LlamaHandle;
typedef void (*AI_LlamaTokenCallback)(
    const char * token_utf8,
    void * user_data);

CHATGPT_LLAMA_BRIDGE_API const char * ai_llama_bridge_version(void);
CHATGPT_LLAMA_BRIDGE_API void ai_llama_init(void);
CHATGPT_LLAMA_BRIDGE_API void ai_llama_shutdown(void);
CHATGPT_LLAMA_BRIDGE_API AI_LlamaHandle * ai_llama_create_handle(void);
CHATGPT_LLAMA_BRIDGE_API void ai_llama_destroy_handle(AI_LlamaHandle * handle);
CHATGPT_LLAMA_BRIDGE_API const char * ai_llama_last_error(
    const AI_LlamaHandle * handle);
CHATGPT_LLAMA_BRIDGE_API int ai_llama_model_load(
    AI_LlamaHandle * handle,
    const char * filename,
    int context_size,
    int threads);
CHATGPT_LLAMA_BRIDGE_API void ai_llama_model_unload(AI_LlamaHandle * handle);
CHATGPT_LLAMA_BRIDGE_API const char * ai_llama_generate(
    AI_LlamaHandle * handle,
    const char * prompt_utf8,
    int max_tokens,
    float temperature,
    int top_k,
    float top_p,
    int seed);
CHATGPT_LLAMA_BRIDGE_API int ai_llama_generate_stream(
    AI_LlamaHandle * handle,
    const char * prompt_utf8,
    int max_tokens,
    float temperature,
    int top_k,
    float top_p,
    int seed,
    AI_LlamaTokenCallback callback,
    void * user_data);
CHATGPT_LLAMA_BRIDGE_API void ai_llama_abort(AI_LlamaHandle * handle);
CHATGPT_LLAMA_BRIDGE_API int ai_llama_lora_apply(
    AI_LlamaHandle * handle,
    const char * adapter_filename_utf8,
    float scale);
CHATGPT_LLAMA_BRIDGE_API int ai_llama_lora_remove(AI_LlamaHandle * handle);

#ifdef __cplusplus
}
#endif

#endif
