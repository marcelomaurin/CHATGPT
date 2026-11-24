/* SPDX-License-Identifier: GPL-3.0-or-later */
#ifndef CHATGPT_SIP_BRIDGE_H
#define CHATGPT_SIP_BRIDGE_H
#include <stdint.h>
#if defined(_WIN32)
# define ASIP_API __declspec(dllexport)
#else
# define ASIP_API __attribute__((visibility("default")))
#endif
#ifdef __cplusplus
extern "C" {
#endif
#define ASIP_ABI_VERSION 1
typedef struct asip_context asip_context;
enum { ASIP_CLIENT = 0, ASIP_SERVER = 1 };
enum { ASIP_REG_STATE = 1, ASIP_REGISTRATION, ASIP_INCOMING, ASIP_CALL_STATE,
       ASIP_DTMF, ASIP_ERROR, ASIP_AUTH_RESULT, ASIP_AUDIO_DROPPED };
enum { ASIP_CALLING = 1, ASIP_RECEIVING, ASIP_RINGING, ASIP_CONNECTING,
       ASIP_CONNECTED, ASIP_DISCONNECTED };
enum { ASIP_DENY = 0, ASIP_ROUTE = 1, ASIP_LOCAL = 2 };
/* Decision/notification callbacks run on the application's owner thread,
 * during poll or API calls. PCM is queued by PJMEDIA and dispatched by poll. */
typedef int (*asip_credential_cb)(void *, const char *user, const char *realm,
    const char *remote, char *secret, int capacity, int *kind);
/* kind: 0=password, 1=MD5 HA1, 2=SHA-256 HA1. Secrets are never logged. */
typedef int (*asip_authorize_cb)(void *, const char *operation,
    const char *user, const char *target, const char *remote);
typedef int (*asip_route_cb)(void *, uint64_t call, const char *caller,
    const char *target, char *destination, int capacity);
typedef void (*asip_event_cb)(void *, int event, uint64_t call, int status,
    int value, const char *detail, const char *remote);
typedef void (*asip_audio_cb)(void *, uint64_t call, const int16_t *samples,
    int count, int sample_rate);
typedef struct asip_callbacks {
    asip_credential_cb credential;
    asip_authorize_cb authorize;
    asip_route_cb route;
    asip_event_cb event;
    asip_audio_cb audio;
} asip_callbacks;
typedef struct asip_config {
    uint32_t size, abi_version;
    int role, sip_port, rtp_port, expires, use_sound_device, digest_algorithm;
    const char *bind_address, *public_address, *user, *realm, *registrar, *password;
} asip_config;
ASIP_API int asip_abi_version(void);
ASIP_API int asip_create(const asip_config *, const asip_callbacks *, void *,
    asip_context **result, char *error, int capacity);
/* Stop/destroy and poll must be called on the thread that called create.
 * Never destroy a context from a callback; defer until poll returns. */
ASIP_API void asip_destroy(asip_context *);
ASIP_API int asip_poll(int timeout_ms);
ASIP_API int asip_register(asip_context *, int enable);
ASIP_API int asip_call(asip_context *, const char *destination, uint64_t *call);
ASIP_API int asip_answer(asip_context *, uint64_t call, int status);
ASIP_API int asip_hangup(asip_context *, uint64_t call, int status);
ASIP_API int asip_dtmf(asip_context *, uint64_t call, const char *digits);
/* PCM signed 16-bit, mono, 8000 Hz. Returns accepted samples or a negative
 * error. A bounded TX queue applies backpressure instead of dropping audio. */
ASIP_API int asip_write_audio(asip_context *, uint64_t call,
    const int16_t *samples, int count);
ASIP_API int asip_local_port(asip_context *);
#ifdef __cplusplus
}
#endif
#endif
