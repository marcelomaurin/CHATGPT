#include "chatgpt_llama_bridge.h"
#include "ggml-backend.h"
#include "llama.h"

#include <atomic>
#include <exception>
#include <filesystem>
#include <memory>
#include <new>
#include <string>
#include <vector>
#include <windows.h>

struct AI_LlamaHandle {
    llama_model * model = nullptr;
    llama_context * context = nullptr;
    llama_adapter_lora * lora_adapter = nullptr;
    std::string last_error;
    std::string last_result;
    std::atomic<bool> abort_requested{false};
};

static void unload_model(AI_LlamaHandle * handle) {
    if (!handle) {
        return;
    }
    if (handle->lora_adapter) {
        if (handle->context) {
            llama_rm_adapter_lora(handle->context, handle->lora_adapter);
        }
        llama_adapter_lora_free(handle->lora_adapter);
        handle->lora_adapter = nullptr;
    }
    if (handle->context) {
        llama_free(handle->context);
        handle->context = nullptr;
    }
    if (handle->model) {
        llama_model_free(handle->model);
        handle->model = nullptr;
    }
}

static std::string bridge_directory() {
    HMODULE module = nullptr;
    if (!GetModuleHandleExW(
            GET_MODULE_HANDLE_EX_FLAG_FROM_ADDRESS |
                GET_MODULE_HANDLE_EX_FLAG_UNCHANGED_REFCOUNT,
            reinterpret_cast<LPCWSTR>(&ai_llama_bridge_version),
            &module)) {
        return {};
    }

    std::wstring path(32768, L'\0');
    const DWORD length = GetModuleFileNameW(
        module, path.data(), static_cast<DWORD>(path.size()));
    if (length == 0 || length >= path.size()) {
        return {};
    }
    path.resize(length);
    return std::filesystem::path(path).parent_path().u8string();
}

static bool format_user_prompt(
    AI_LlamaHandle * handle,
    const char * prompt,
    std::string & formatted_prompt) {
    const char * chat_template =
        llama_model_chat_template(handle->model, nullptr);
    if (!chat_template) {
        formatted_prompt = prompt;
        return true;
    }

    const llama_chat_message message = {"user", prompt};
    const int32_t required = llama_chat_apply_template(
        chat_template, &message, 1, true, nullptr, 0);
    if (required <= 0) {
        formatted_prompt = prompt;
        return true;
    }

    std::vector<char> buffer(static_cast<size_t>(required) + 1);
    const int32_t written = llama_chat_apply_template(
        chat_template,
        &message,
        1,
        true,
        buffer.data(),
        static_cast<int32_t>(buffer.size()));
    if (written < 0 || written > required) {
        handle->last_error = "llama.cpp could not apply the model chat template.";
        return false;
    }
    formatted_prompt.assign(buffer.data(), static_cast<size_t>(written));
    return true;
}

static bool token_to_text(
    AI_LlamaHandle * handle,
    const llama_vocab * vocab,
    llama_token token,
    std::string & output) {
    char stack_buffer[256];
    int32_t length = llama_token_to_piece(
        vocab, token, stack_buffer, sizeof(stack_buffer), 0, true);
    if (length >= 0) {
        output.append(stack_buffer, static_cast<size_t>(length));
        return true;
    }

    std::vector<char> buffer(static_cast<size_t>(-length));
    length = llama_token_to_piece(
        vocab,
        token,
        buffer.data(),
        static_cast<int32_t>(buffer.size()),
        0,
        true);
    if (length < 0) {
        handle->last_error = "llama.cpp could not convert a generated token.";
        return false;
    }
    output.append(buffer.data(), static_cast<size_t>(length));
    return true;
}

static bool generate_minimal(
    AI_LlamaHandle * handle,
    const char * prompt,
    int max_tokens,
    float temperature,
    int top_k,
    float top_p,
    int seed,
    std::string & output,
    AI_LlamaTokenCallback callback,
    void * user_data) {
    if (!handle || !handle->model || !handle->context) {
        if (handle) {
            handle->last_error = "A GGUF model is not loaded.";
        }
        return false;
    }
    if (!prompt || prompt[0] == '\0') {
        handle->last_error = "Prompt is empty.";
        return false;
    }
    if (max_tokens <= 0) {
        handle->last_error = "MaxTokens must be greater than zero.";
        return false;
    }

    handle->last_error.clear();
    output.clear();
    handle->abort_requested.store(false, std::memory_order_release);

    std::string formatted_prompt;
    if (!format_user_prompt(handle, prompt, formatted_prompt)) {
        return false;
    }

    const llama_vocab * vocab = llama_model_get_vocab(handle->model);
    int32_t token_count = llama_tokenize(
        vocab,
        formatted_prompt.c_str(),
        static_cast<int32_t>(formatted_prompt.size()),
        nullptr,
        0,
        true,
        true);
    if (token_count >= 0) {
        handle->last_error = "llama.cpp did not return the required token count.";
        return false;
    }
    token_count = -token_count;

    std::vector<llama_token> prompt_tokens(static_cast<size_t>(token_count));
    const int32_t tokenized = llama_tokenize(
        vocab,
        formatted_prompt.c_str(),
        static_cast<int32_t>(formatted_prompt.size()),
        prompt_tokens.data(),
        static_cast<int32_t>(prompt_tokens.size()),
        true,
        true);
    if (tokenized < 0) {
        handle->last_error = "llama.cpp could not tokenize the prompt.";
        return false;
    }
    prompt_tokens.resize(static_cast<size_t>(tokenized));

    const uint32_t context_size = llama_n_ctx(handle->context);
    if (prompt_tokens.size() >= context_size) {
        handle->last_error = "The prompt is larger than the model context.";
        return false;
    }
    const int available_tokens = static_cast<int>(
        context_size - static_cast<uint32_t>(prompt_tokens.size()));
    if (max_tokens > available_tokens) {
        max_tokens = available_tokens;
    }

    llama_kv_self_clear(handle->context);
    llama_batch batch = llama_batch_get_one(
        prompt_tokens.data(), static_cast<int32_t>(prompt_tokens.size()));
    if (llama_decode(handle->context, batch) != 0) {
        handle->last_error = "llama.cpp could not decode the prompt.";
        return false;
    }

    llama_sampler_chain_params sampler_params =
        llama_sampler_chain_default_params();
    std::unique_ptr<llama_sampler, decltype(&llama_sampler_free)> sampler(
        llama_sampler_chain_init(sampler_params), &llama_sampler_free);
    if (!sampler) {
        handle->last_error = "llama.cpp could not create the sampler.";
        return false;
    }

    if (temperature <= 0.0f) {
        llama_sampler_chain_add(sampler.get(), llama_sampler_init_greedy());
    } else {
        if (top_k > 0) {
            llama_sampler_chain_add(
                sampler.get(), llama_sampler_init_top_k(top_k));
        }
        if (top_p > 0.0f && top_p < 1.0f) {
            llama_sampler_chain_add(
                sampler.get(), llama_sampler_init_top_p(top_p, 1));
        }
        llama_sampler_chain_add(
            sampler.get(), llama_sampler_init_temp(temperature));
        llama_sampler_chain_add(
            sampler.get(),
            llama_sampler_init_dist(static_cast<uint32_t>(seed)));
    }

    for (int generated = 0; generated < max_tokens; ++generated) {
        if (handle->abort_requested.load(std::memory_order_acquire)) {
            break;
        }
        const llama_token token =
            llama_sampler_sample(sampler.get(), handle->context, -1);
        llama_sampler_accept(sampler.get(), token);
        if (llama_vocab_is_eog(vocab, token)) {
            break;
        }
        const size_t piece_start = output.size();
        if (!token_to_text(handle, vocab, token, output)) {
            return false;
        }
        if (callback) {
            const std::string piece = output.substr(piece_start);
            callback(piece.c_str(), user_data);
        }
        if (handle->abort_requested.load(std::memory_order_acquire)) {
            break;
        }
        if (generated + 1 < max_tokens) {
            llama_token next_token = token;
            batch = llama_batch_get_one(&next_token, 1);
            if (llama_decode(handle->context, batch) != 0) {
                handle->last_error = "llama.cpp could not decode a generated token.";
                return false;
            }
        }
    }

    return true;
}

const char * ai_llama_bridge_version(void) {
    return "1";
}

void ai_llama_init(void) {
    HMODULE pinned_module = nullptr;
    GetModuleHandleExW(
        GET_MODULE_HANDLE_EX_FLAG_FROM_ADDRESS |
            GET_MODULE_HANDLE_EX_FLAG_PIN,
        reinterpret_cast<LPCWSTR>(&ai_llama_init),
        &pinned_module);
    const std::string library_path = bridge_directory();
    if (library_path.empty()) {
        ggml_backend_load_all();
    } else {
        ggml_backend_load_all_from_path(library_path.c_str());
    }
    llama_backend_init();
}

void ai_llama_shutdown(void) {
    llama_backend_free();
}

AI_LlamaHandle * ai_llama_create_handle(void) {
    return new (std::nothrow) AI_LlamaHandle();
}

void ai_llama_destroy_handle(AI_LlamaHandle * handle) {
    unload_model(handle);
    delete handle;
}

const char * ai_llama_last_error(const AI_LlamaHandle * handle) {
    static const char * invalid_handle = "Invalid llama handle.";
    return handle ? handle->last_error.c_str() : invalid_handle;
}

int ai_llama_model_load(
    AI_LlamaHandle * handle,
    const char * filename,
    int context_size,
    int threads) {
    if (!handle) {
        return 0;
    }

    handle->last_error.clear();
    if (!filename || filename[0] == '\0') {
        handle->last_error = "Model filename is empty.";
        return 0;
    }
    if (context_size <= 0) {
        handle->last_error = "Context size must be greater than zero.";
        return 0;
    }
    if (threads < 0) {
        handle->last_error = "Thread count cannot be negative.";
        return 0;
    }
    if (handle->model || handle->context) {
        handle->last_error = "A model is already loaded in this handle.";
        return 0;
    }

    try {
        llama_model_params model_params = llama_model_default_params();
        handle->model = llama_model_load_from_file(filename, model_params);
        if (!handle->model) {
            handle->last_error = "llama.cpp could not load the GGUF model.";
            return 0;
        }

        llama_context_params context_params = llama_context_default_params();
        context_params.n_ctx = static_cast<uint32_t>(context_size);
        if (threads > 0) {
            context_params.n_threads = threads;
            context_params.n_threads_batch = threads;
        }

        handle->context = llama_init_from_model(handle->model, context_params);
        if (!handle->context) {
            llama_model_free(handle->model);
            handle->model = nullptr;
            handle->last_error = "llama.cpp could not create the model context.";
            return 0;
        }
    } catch (const std::exception & error) {
        if (handle->context) {
            llama_free(handle->context);
            handle->context = nullptr;
        }
        if (handle->model) {
            llama_model_free(handle->model);
            handle->model = nullptr;
        }
        handle->last_error = error.what();
        return 0;
    } catch (...) {
        if (handle->context) {
            llama_free(handle->context);
            handle->context = nullptr;
        }
        if (handle->model) {
            llama_model_free(handle->model);
            handle->model = nullptr;
        }
        handle->last_error = "Unexpected error while loading the GGUF model.";
        return 0;
    }

    return 1;
}

void ai_llama_model_unload(AI_LlamaHandle * handle) {
    unload_model(handle);
    if (handle) {
        handle->last_error.clear();
        handle->last_result.clear();
    }
}

const char * ai_llama_generate(
    AI_LlamaHandle * handle,
    const char * prompt_utf8,
    int max_tokens,
    float temperature,
    int top_k,
    float top_p,
    int seed) {
    if (!handle) {
        return nullptr;
    }

    handle->last_result.clear();
    try {
        if (!generate_minimal(
                handle,
                prompt_utf8,
                max_tokens,
                temperature,
                top_k,
                top_p,
                seed,
                handle->last_result,
                nullptr,
                nullptr)) {
            return nullptr;
        }
        return handle->last_result.c_str();
    } catch (const std::exception & error) {
        handle->last_result.clear();
        handle->last_error = error.what();
        return nullptr;
    } catch (...) {
        handle->last_result.clear();
        handle->last_error = "Unexpected error during native generation.";
        return nullptr;
    }
}

int ai_llama_generate_stream(
    AI_LlamaHandle * handle,
    const char * prompt_utf8,
    int max_tokens,
    float temperature,
    int top_k,
    float top_p,
    int seed,
    AI_LlamaTokenCallback callback,
    void * user_data) {
    if (!handle || !callback) {
        if (handle) {
            handle->last_error = "Token callback is not assigned.";
        }
        return 0;
    }

    handle->last_result.clear();
    try {
        return generate_minimal(
                   handle,
                   prompt_utf8,
                   max_tokens,
                   temperature,
                   top_k,
                   top_p,
                   seed,
                   handle->last_result,
                   callback,
                   user_data)
            ? 1
            : 0;
    } catch (const std::exception & error) {
        handle->last_result.clear();
        handle->last_error = error.what();
        return 0;
    } catch (...) {
        handle->last_result.clear();
        handle->last_error = "Unexpected error during native streaming.";
        return 0;
    }
}

void ai_llama_abort(AI_LlamaHandle * handle) {
    if (handle) {
        handle->abort_requested.store(true, std::memory_order_release);
    }
}

int ai_llama_lora_apply(
    AI_LlamaHandle * handle,
    const char * adapter_filename_utf8,
    float scale) {
    if (!handle) {
        return 0;
    }
    handle->last_error.clear();
    if (!handle->model || !handle->context) {
        handle->last_error = "A GGUF model is not loaded.";
        return 0;
    }
    if (!adapter_filename_utf8 || adapter_filename_utf8[0] == '\0') {
        handle->last_error = "LoRA adapter filename is empty.";
        return 0;
    }
    if (scale < 0.0f) {
        handle->last_error = "LoRA scale cannot be negative.";
        return 0;
    }
    if (handle->lora_adapter) {
        handle->last_error = "A LoRA adapter is already applied.";
        return 0;
    }

    try {
        llama_adapter_lora * adapter = llama_adapter_lora_init(
            handle->model, adapter_filename_utf8);
        if (!adapter) {
            handle->last_error = "llama.cpp could not load the LoRA adapter.";
            return 0;
        }
        if (llama_set_adapter_lora(handle->context, adapter, scale) != 0) {
            llama_adapter_lora_free(adapter);
            handle->last_error = "llama.cpp could not apply the LoRA adapter.";
            return 0;
        }
        handle->lora_adapter = adapter;
        return 1;
    } catch (const std::exception & error) {
        handle->last_error = error.what();
        return 0;
    } catch (...) {
        handle->last_error = "Unexpected error while applying the LoRA adapter.";
        return 0;
    }
}

int ai_llama_lora_remove(AI_LlamaHandle * handle) {
    if (!handle) {
        return 0;
    }
    handle->last_error.clear();
    if (!handle->lora_adapter) {
        return 1;
    }

    if (handle->context &&
        llama_rm_adapter_lora(handle->context, handle->lora_adapter) != 0) {
        handle->last_error = "llama.cpp could not remove the LoRA adapter.";
        return 0;
    }
    llama_adapter_lora_free(handle->lora_adapter);
    handle->lora_adapter = nullptr;
    return 1;
}
