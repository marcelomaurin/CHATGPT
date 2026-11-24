/* SPDX-License-Identifier: GPL-3.0-or-later
 * PJSIP 2.17 bridge. SIP is pumped on one application thread; PJMEDIA audio
 * callbacks only touch locked, bounded PCM queues. No Pascal callback runs
 * on the audio clock thread. */
#include "chatgpt_sip_bridge.h"
#include <pjsua-lib/pjsua.h>
#include <pjmedia/port.h>
#include <pj/guid.h>
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <ctype.h>
#include <fenv.h>

#define REG_LIMIT 128
#define NONCE_LIMIT 256
#define PCM_FRAME 160
#define RX_FRAMES 32
#define TX_SAMPLES 16000

typedef struct {
    char user[128], contact[1024];
    uint64_t until;
} registration;
typedef struct {
    char value[65], remote[80], user[128], cnonce[128];
    unsigned nc;
    uint64_t until;
} nonce_entry;
typedef struct audio_port {
    pjmedia_port port;
    pj_pool_t *pool;
    pj_mutex_t *mutex;
    int16_t rx[RX_FRAMES][PCM_FRAME], tx[TX_SAMPLES];
    unsigned rx_head, rx_count, tx_head, tx_count, dropped;
    int closed;
} audio_port;
typedef struct call_entry call_entry;
struct asip_context {
    struct asip_context *next;
    asip_callbacks cb;
    void *user_data;
    int role, port, closing, sound, algorithm;
    pjsua_acc_id account;
    pjsua_transport_id transport;
    char realm[256];
    pj_pool_t *pool;
    pjsip_auth_srv auth;
    registration registrations[REG_LIMIT];
    nonce_entry nonces[NONCE_LIMIT];
    unsigned nonce_next;
};
struct call_entry {
    call_entry *next, *peer;
    asip_context *ctx;
    uint64_t id;
    pjsua_call_id native;
    int hidden, ended, media_slot, audio_slot, bridged;
    audio_port *audio;
};
static asip_context *contexts;
static call_entry *calls;
static uint64_t next_call_id = 1;
static int initialized, polling;
static pj_thread_t *owner_thread;
static pj_bool_t on_request(pjsip_rx_data *);
static pjsip_module registrar_module = {
    .name = { "chatgpt-sip", 11 }, .id = -1,
    .priority = PJSIP_MOD_PRIORITY_UA_PROXY_LAYER - 1,
    .on_rx_request = on_request
};

static const char *nz(const char *s) { return s ? s : ""; }
static void copy_text(char *out, size_t cap, const char *s)
{ if (cap) snprintf(out, cap, "%s", nz(s)); }
static void pj_text(char *out, size_t cap, const pj_str_t *s)
{
    size_t n = s && s->slen > 0 ? (size_t)s->slen : 0;
    if (!cap) return;
    if (n >= cap) n = cap - 1;
    if (n) memcpy(out, s->ptr, n);
    out[n] = 0;
}
static uint64_t now_ms(void)
{
    pj_time_val t;
    pj_gettickcount(&t);
    return (uint64_t)t.sec * 1000 + t.msec;
}
static int safe_atom(const char *s, size_t max)
{
    size_t n = 0;
    if (!s || !*s) return 0;
    for (; *s; ++s, ++n)
        if (n >= max || !(isalnum((unsigned char)*s) || strchr("._-", *s))) return 0;
    return 1;
}
static int valid_uri(const char *s)
{
    return s && strlen(s) < 1000 && !strchr(s, '\r') && !strchr(s, '\n') &&
        strncmp(s, "sip:", 4) == 0 && pjsua_verify_url(s) == PJ_SUCCESS;
}
static void emit(asip_context *c, int ev, uint64_t id, int status, int value,
                 const char *detail, const char *remote)
{
    if (c && !c->closing && c->cb.event)
        c->cb.event(c->user_data, ev, id, status, value, nz(detail), nz(remote));
}
static int failure(asip_context *c, pj_status_t status, const char *op)
{
    char reason[PJ_ERR_MSG_SIZE], msg[256];
    pj_strerror(status, reason, sizeof(reason));
    snprintf(msg, sizeof(msg), "%s: %.180s", op, reason);
    emit(c, ASIP_ERROR, 0, status, 0, msg, "");
    return -(int)status;
}
static asip_context *context_for_rx(const pjsip_rx_data *r)
{
    asip_context *c;
    int port = r->tp_info.transport->local_name.port;
    for (c = contexts; c; c = c->next)
        if (!c->closing && c->port == port) return c;
    return NULL;
}
static pjsip_sip_uri *sip_uri(pjsip_uri *uri)
{
    if (!uri) return NULL;
    uri = pjsip_uri_get_uri(uri);
    return PJSIP_URI_SCHEME_IS_SIP(uri) ? (pjsip_sip_uri *)uri : NULL;
}
static void uri_user(pjsip_uri *uri, char *out, size_t cap)
{
    pjsip_sip_uri *u = sip_uri(uri);
    pj_text(out, cap, u ? &u->user : NULL);
}
static void remote_address(const pjsip_rx_data *r, char *out, size_t cap)
{ snprintf(out, cap, "%s:%d", r->pkt_info.src_name, r->pkt_info.src_port); }

static pj_status_t lookup_credential(pj_pool_t *pool,
    const pjsip_auth_lookup_cred_param *p, pjsip_cred_info *cred)
{
    asip_context *c = context_for_rx(p->rdata);
    char user[128], realm[256], remote[80], secret[512] = {0};
    int kind = 0, found = 0;
    pj_text(user, sizeof(user), &p->acc_name);
    pj_text(realm, sizeof(realm), &p->realm);
    remote_address(p->rdata, remote, sizeof(remote));
    if (c && c->cb.credential)
        found = c->cb.credential(c->user_data, user, realm, remote,
                                secret, sizeof(secret), &kind);
    secret[sizeof(secret)-1] = 0;
    if (found && kind >= 0 && kind <= 2) {
        pj_bzero(cred, sizeof(*cred));
        pj_strdup2(pool, &cred->realm, realm);
        pj_strdup2(pool, &cred->username, user);
        cred->scheme = pj_str("digest");
        cred->data_type = kind ? PJSIP_CRED_DATA_DIGEST : PJSIP_CRED_DATA_PLAIN_PASSWD;
        cred->algorithm_type = kind == 2 ? PJSIP_AUTH_ALGORITHM_SHA256 : PJSIP_AUTH_ALGORITHM_MD5;
        pj_strdup2(pool, &cred->data, secret);
    } else found = 0;
    { volatile char *v = secret; size_t i; for (i=0; i<sizeof(secret); ++i) v[i]=0; }
    return found ? PJ_SUCCESS : PJSIP_EAUTHACCNOTFOUND;
}
static void respond(pjsip_rx_data *r, int status, pjsip_hdr *headers)
{
    pjsip_endpt_respond(pjsua_get_pjsip_endpt(), &registrar_module,
                       r, status, NULL, headers, NULL, NULL);
}
static void challenge(asip_context *c, pjsip_rx_data *r, int stale)
{
    pjsip_tx_data *t;
    pjsip_transaction *tsx;
    nonce_entry *n = &c->nonces[c->nonce_next++ % NONCE_LIMIT];
    pj_str_t qop = pj_str("auth"), nonce;
    memset(n, 0, sizeof(*n));
    pj_create_random_string(n->value, 48); n->value[48] = 0;
    remote_address(r, n->remote, sizeof(n->remote));
    n->until = now_ms() + 60000;
    nonce = pj_str(n->value);
    if (pjsip_endpt_create_response(pjsua_get_pjsip_endpt(), r, 401, NULL, &t) != PJ_SUCCESS) return;
    pjsip_auth_srv_challenge2(&c->auth, &qop, &nonce, NULL, stale, t,
        c->algorithm == 2 ? PJSIP_AUTH_ALGORITHM_SHA256 : PJSIP_AUTH_ALGORITHM_MD5);
    if (pjsip_tsx_create_uas(&registrar_module, r, &tsx) != PJ_SUCCESS) {
        pjsip_tx_data_dec_ref(t); return;
    }
    pjsip_tsx_recv_msg(tsx, r);
    pjsip_tsx_send_msg(tsx, t);
}
static pjsip_authorization_hdr *authorization(asip_context *c, pjsip_rx_data *r)
{
    pjsip_authorization_hdr *h = pjsip_msg_find_hdr(r->msg_info.msg, PJSIP_H_AUTHORIZATION, NULL);
    while (h) {
        if (!pj_stricmp2(&h->scheme, "digest") &&
            !pj_stricmp2(&h->credential.digest.realm, c->realm)) return h;
        h = pjsip_msg_find_hdr(r->msg_info.msg, PJSIP_H_AUTHORIZATION, h->next);
    }
    return NULL;
}
static int authenticate(asip_context *c, pjsip_rx_data *r, char *user, size_t cap)
{
    pjsip_authorization_hdr *h = authorization(c, r);
    nonce_entry *n = NULL;
    char remote[80], nonce[65], nc[16], cnonce[128], uri[1024];
    unsigned count = 0, i;
    int code = 403;
    remote_address(r, remote, sizeof(remote));
    if (!h) { challenge(c, r, 0); return 0; }
    pj_text(user, cap, &h->credential.digest.username);
    pj_text(nonce, sizeof(nonce), &h->credential.digest.nonce);
    for (i=0; i<NONCE_LIMIT; ++i)
        if (!strcmp(nonce, c->nonces[i].value) &&
            !strcmp(remote, c->nonces[i].remote) && c->nonces[i].until > now_ms()) {
            n = &c->nonces[i]; break;
        }
    if (!n) { challenge(c, r, 1); return 0; }
    /* PJSIP verifies the digest; the application must additionally check nonce
       lifetime, qop, request URI and increasing nonce count to stop replay. */
    pj_text(nc, sizeof(nc), &h->credential.digest.nc);
    pj_text(cnonce, sizeof(cnonce), &h->credential.digest.cnonce);
    i = (unsigned)pjsip_uri_print(PJSIP_URI_IN_REQ_URI, r->msg_info.msg->line.req.uri,
                                 uri, sizeof(uri)-1);
    if (i >= sizeof(uri)) { respond(r, 400, NULL); return 0; }
    uri[i] = 0;
    if (strlen(nc) != 8 || strspn(nc,"0123456789abcdefABCDEF")!=8 ||
        sscanf(nc, "%8x", &count) != 1 || !count ||
        (c->algorithm==2 && pj_stricmp2(&h->credential.digest.algorithm,"SHA-256")) ||
        (c->algorithm==1 && h->credential.digest.algorithm.slen && pj_stricmp2(&h->credential.digest.algorithm,"MD5")) ||
        pj_strcmp2(&h->credential.digest.qop, "auth") || !cnonce[0] ||
        pj_strcmp2(&h->credential.digest.uri, uri) ||
        (n->user[0] && (strcmp(n->user, user) || strcmp(n->cnonce, cnonce) || count <= n->nc)) ||
        pjsip_auth_srv_verify(&c->auth, r, &code) != PJ_SUCCESS) {
        emit(c, ASIP_AUTH_RESULT, 0, 403, 0, user, remote);
        respond(r, 403, NULL); return 0;
    }
    copy_text(n->user, sizeof(n->user), user);
    copy_text(n->cnonce, sizeof(n->cnonce), cnonce); n->nc = count;
    emit(c, ASIP_AUTH_RESULT, 0, 200, 1, user, remote);
    return 1;
}
static registration *find_registration(asip_context *c, const char *user)
{
    unsigned i;
    for (i=0; i<REG_LIMIT; ++i)
        if (c->registrations[i].until > now_ms() &&
            !strcmp(c->registrations[i].user, user)) return &c->registrations[i];
    return NULL;
}
static void register_device(asip_context *c, pjsip_rx_data *r, const char *user)
{
    pjsip_contact_hdr *h = pjsip_msg_find_hdr(r->msg_info.msg, PJSIP_H_CONTACT, NULL);
    pjsip_expires_hdr *e = pjsip_msg_find_hdr(r->msg_info.msg, PJSIP_H_EXPIRES, NULL);
    registration *reg = find_registration(c, user);
    int expires = e ? (int)e->ivalue : 300, len;
    unsigned i;
    pjsip_hdr headers;
    pjsip_contact_hdr *answer;
    char contact[1024];
    if (!h || pjsip_msg_find_hdr(r->msg_info.msg, PJSIP_H_CONTACT, h->next)) {
        respond(r, 400, NULL); return;
    }
    if (h->expires != PJSIP_EXPIRES_NOT_SPECIFIED) expires = (int)h->expires;
    if (expires < 0 || (h->star && expires)) { respond(r, 400, NULL); return; }
    if (expires > 3600) expires = 3600;
    if (expires && expires < 60) {
        pjsip_min_expires_hdr *min = pjsip_min_expires_hdr_create(r->tp_info.pool, 60);
        min->ivalue = 60; pj_list_init(&headers); pj_list_push_back(&headers, min);
        respond(r, 423, &headers); return;
    }
    if (!reg && expires) {
        for (i=0; i<REG_LIMIT; ++i) if (c->registrations[i].until <= now_ms()) {
            reg = &c->registrations[i]; break;
        }
        if (!reg) { respond(r, 503, NULL); return; }
    }
    contact[0] = 0;
    if (!h->star) {
        if (!sip_uri(h->uri)) { respond(r, 400, NULL); return; }
        len = pjsip_uri_print(PJSIP_URI_IN_REQ_URI, h->uri, contact, sizeof(contact)-1);
        if (len < 0) { respond(r, 400, NULL); return; }
        contact[len] = 0;
    }
    if (reg) {
        copy_text(reg->user, sizeof(reg->user), user);
        copy_text(reg->contact, sizeof(reg->contact), contact);
        reg->until = expires ? now_ms() + (uint64_t)expires * 1000 : 0;
    }
    pj_list_init(&headers);
    if (!h->star) {
        answer = pjsip_hdr_clone(r->tp_info.pool, h); answer->expires = expires;
        pj_list_push_back(&headers, answer);
    }
    respond(r, 200, &headers);
    emit(c, ASIP_REGISTRATION, 0, 200, expires, user, contact);
}
static pj_bool_t on_request(pjsip_rx_data *r)
{
    asip_context *c = context_for_rx(r);
    pjsip_method *m = &r->msg_info.msg->line.req.method;
    char user[128], identity[128], target[128], remote[80];
    pjsip_sip_uri *u;
    int is_register = !pj_strcmp2(&m->name, "REGISTER");
    if (!c || c->role != ASIP_SERVER) return PJ_FALSE;
    if (m->id == PJSIP_OPTIONS_METHOD) { respond(r, 200, NULL); return PJ_TRUE; }
    if (!is_register && (m->id != PJSIP_INVITE_METHOD || r->msg_info.to->tag.slen))
        return PJ_FALSE;
    if (!authenticate(c, r, user, sizeof(user))) return PJ_TRUE;
    uri_user(is_register ? r->msg_info.to->uri : r->msg_info.from->uri,
             identity, sizeof(identity));
    u = sip_uri(is_register ? r->msg_info.to->uri : r->msg_info.from->uri);
    if (!u || strcmp(user, identity) || pj_stricmp2(&u->host, c->realm)) {
        respond(r, 403, NULL); return PJ_TRUE;
    }
    uri_user(r->msg_info.msg->line.req.uri, target, sizeof(target));
    remote_address(r, remote, sizeof(remote));
    if (!c->cb.authorize || !c->cb.authorize(c->user_data,
            is_register ? "REGISTER" : "INVITE", user, target, remote)) {
        respond(r, 403, NULL); return PJ_TRUE;
    }
    if (is_register) { register_device(c, r, user); return PJ_TRUE; }
    return PJ_FALSE;
}

static call_entry *find_call(asip_context *ctx, uint64_t id)
{
    call_entry *c;
    for (c=calls; c; c=c->next)
        if (c->ctx==ctx && c->id==id && !c->ended && !c->hidden) return c;
    return NULL;
}
static call_entry *new_call(asip_context *ctx, uint64_t id)
{
    call_entry *c = calloc(1, sizeof(*c));
    if (!c) return NULL;
    c->ctx=ctx; c->id=id ? id : next_call_id++;
    c->native=PJSUA_INVALID_ID; c->media_slot=c->audio_slot=PJSUA_INVALID_ID;
    c->next=calls; calls=c;
    return c;
}
static pj_status_t audio_destroy(pjmedia_port *p)
{
    audio_port *a=(audio_port *)p;
    pj_mutex_destroy(a->mutex);
    pj_pool_release(a->pool);
    return PJ_SUCCESS;
}
static pj_status_t audio_put(pjmedia_port *p, pjmedia_frame *f)
{
    audio_port *a=(audio_port *)p;
    pj_mutex_lock(a->mutex);
    if (!a->closed && f->type==PJMEDIA_FRAME_TYPE_AUDIO && f->size==PCM_FRAME*2) {
        if (a->rx_count==RX_FRAMES) {
            a->rx_head=(a->rx_head+1)%RX_FRAMES; --a->rx_count; ++a->dropped;
        }
        memcpy(a->rx[(a->rx_head+a->rx_count)%RX_FRAMES], f->buf, f->size);
        ++a->rx_count;
    }
    pj_mutex_unlock(a->mutex);
    return PJ_SUCCESS;
}
static pj_status_t audio_get(pjmedia_port *p, pjmedia_frame *f)
{
    audio_port *a=(audio_port *)p;
    unsigned n, i;
    f->type=PJMEDIA_FRAME_TYPE_AUDIO; f->size=PCM_FRAME*2;
    memset(f->buf, 0, f->size);
    pj_mutex_lock(a->mutex);
    n=a->tx_count < PCM_FRAME ? a->tx_count : PCM_FRAME;
    for (i=0; i<n; ++i) ((int16_t *)f->buf)[i]=a->tx[(a->tx_head+i)%TX_SAMPLES];
    a->tx_head=(a->tx_head+n)%TX_SAMPLES; a->tx_count-=n;
    pj_mutex_unlock(a->mutex);
    return PJ_SUCCESS;
}
static int attach_audio(call_entry *c)
{
    pj_pool_t *pool=pjsua_pool_create("asip-audio", sizeof(audio_port)+1024, 1024);
    audio_port *a;
    pj_str_t name=pj_str("Pascal PCM");
    pj_status_t s;
    if (!pool) return -1;
    a=PJ_POOL_ZALLOC_T(pool, audio_port); a->pool=pool;
    s=pj_mutex_create_simple(pool,"asip-pcm",&a->mutex);
    if (s!=PJ_SUCCESS) { pj_pool_release(pool); return -1; }
    pjmedia_port_info_init(&a->port.info,&name,PJMEDIA_SIG_CLASS_PORT_AUD('A','S'),8000,1,16,PCM_FRAME);
    a->port.put_frame=audio_put; a->port.get_frame=audio_get; a->port.on_destroy=audio_destroy;
    s=pjmedia_port_init_grp_lock(&a->port,pool,NULL);
    if (s!=PJ_SUCCESS) { audio_destroy(&a->port); return -1; }
    s=pjsua_conf_add_port(pool,&a->port,&c->audio_slot);
    if (s!=PJ_SUCCESS) { pjmedia_port_dec_ref(&a->port); return -1; }
    c->audio=a;
    pjsua_conf_connect(c->media_slot,c->audio_slot);
    pjsua_conf_connect(c->audio_slot,c->media_slot);
    return 0;
}
static void release_audio(call_entry *c)
{
    audio_port *a=c->audio;
    if (!a) return;
    pj_mutex_lock(a->mutex); a->closed=1; pj_mutex_unlock(a->mutex);
    c->audio=NULL;
    if (c->audio_slot!=PJSUA_INVALID_ID) pjsua_conf_remove_port(c->audio_slot);
    c->audio_slot=PJSUA_INVALID_ID;
    /* The conference owns another reference until asynchronous removal. */
    pjmedia_port_dec_ref(&a->port);
}
static void on_media(pjsua_call_id id)
{
    call_entry *c=pjsua_call_get_user_data(id);
    pjsua_call_info info;
    if (!c || c->ended || pjsua_call_get_info(id,&info)!=PJ_SUCCESS) return;
    if (info.media_status!=PJSUA_CALL_MEDIA_ACTIVE) return;
    c->media_slot=info.conf_slot;
    if (!c->hidden && !c->audio && attach_audio(c))
        emit(c->ctx,ASIP_ERROR,c->id,-1,0,"Cannot attach PCM audio port","");
    if (c->ctx->sound && !c->hidden) {
        pjsua_conf_connect(0,c->media_slot); pjsua_conf_connect(c->media_slot,0);
    }
    if (c->peer && c->peer->media_slot!=PJSUA_INVALID_ID && !c->bridged) {
        pjsua_conf_connect(c->media_slot,c->peer->media_slot);
        pjsua_conf_connect(c->peer->media_slot,c->media_slot);
        c->bridged=c->peer->bridged=1;
    }
}
static void on_state(pjsua_call_id id, pjsip_event *event)
{
    call_entry *c=pjsua_call_get_user_data(id), *peer;
    pjsua_call_info info;
    char reason[256];
    PJ_UNUSED_ARG(event);
    if (!c || pjsua_call_get_info(id,&info)!=PJ_SUCCESS) return;
    c->native=id; peer=c->peer;
    if (getenv("ASIP_TRACE")) fprintf(stderr, "ASIP time=%llu port=%d native=%d logical=%llu hidden=%d state=%d code=%d peer=%d\n",
        (unsigned long long)now_ms(),c->ctx->port,id,(unsigned long long)c->id,c->hidden,info.state,info.last_status,peer ? peer->native : -1);
    pj_text(reason,sizeof(reason),&info.last_status_text);
    if (c->hidden && peer && !peer->ended) {
        if (info.state==PJSIP_INV_STATE_EARLY && info.last_status==180)
            pjsua_call_answer(peer->native,180,NULL,NULL);
        else if (info.state==PJSIP_INV_STATE_CONFIRMED)
            pjsua_call_answer(peer->native,200,NULL,NULL);
    }
    if (!c->hidden)
        emit(c->ctx,ASIP_CALL_STATE,c->id,info.last_status,info.state,reason,"");
    if (info.state==PJSIP_INV_STATE_DISCONNECTED) {
        c->ended=1; release_audio(c);
        if (peer) {
            c->peer=NULL; peer->peer=NULL;
            if (!peer->ended) pjsua_call_hangup(peer->native,
                info.last_status>=300 && info.last_status<=699 ? info.last_status : 0,NULL,NULL);
        }
        pjsua_call_set_user_data(id,NULL);
    }
}
static int destination_uri(asip_context *c, const char *target, char *out, size_t cap)
{
    registration *r;
    if (valid_uri(target)) { copy_text(out,cap,target); return 1; }
    if (!safe_atom(target,127)) return 0;
    if (c->role==ASIP_SERVER) {
        r=find_registration(c,target);
        if (!r) return 0;
        copy_text(out,cap,r->contact);
    } else snprintf(out,cap,"sip:%s@%s",target,c->realm);
    return valid_uri(out);
}
static int make_call(asip_context *c, const char *uri, call_entry *entry)
{
    pj_str_t target=pj_str((char *)uri);
    pjsua_call_setting settings;
    pj_status_t s;
    pjsua_call_setting_default(&settings); settings.vid_cnt=0; settings.aud_cnt=1; settings.txt_cnt=0;
    s=pjsua_call_make_call(c->account,&target,&settings,entry,NULL,&entry->native);
    if (s!=PJ_SUCCESS) { entry->ended=1; return failure(c,s,"Call"); }
    return 0;
}
static void on_incoming(pjsua_acc_id account, pjsua_call_id id, pjsip_rx_data *r)
{
    asip_context *ctx=context_for_rx(r);
    call_entry *c, *out;
    char caller[128],target[128],destination[1024],uri[1024];
    int action;
    PJ_UNUSED_ARG(account);
    if (!ctx) { pjsua_call_answer(id,403,NULL,NULL); return; }
    c=new_call(ctx,0);
    if (!c) { pjsua_call_answer(id,503,NULL,NULL); return; }
    c->native=id; pjsua_call_set_user_data(id,c);
    uri_user(r->msg_info.from->uri,caller,sizeof(caller));
    uri_user(r->msg_info.msg->line.req.uri,target,sizeof(target));
    if (ctx->role==ASIP_SERVER) {
        copy_text(destination,sizeof(destination),target);
        action=ctx->cb.route ? ctx->cb.route(ctx->user_data,c->id,caller,target,
            destination,sizeof(destination)) : ASIP_DENY;
        destination[sizeof(destination)-1]=0;
        if (action==ASIP_ROUTE) {
            if (!destination_uri(ctx,destination,uri,sizeof(uri))) {
                pjsua_call_answer(id,404,NULL,NULL); return;
            }
            out=new_call(ctx,c->id);
            if (!out) { pjsua_call_answer(id,503,NULL,NULL); return; }
            out->hidden=1; out->peer=c; c->peer=out;
            pjsua_call_answer(id,100,NULL,NULL);
            if (make_call(ctx,uri,out)) pjsua_call_answer(id,503,NULL,NULL);
            return;
        }
        if (action!=ASIP_LOCAL) { pjsua_call_answer(id,403,NULL,NULL); return; }
    }
    emit(ctx,ASIP_INCOMING,c->id,0,0,caller,target);
}
static void on_account(const pjsip_rx_data *r,pjsua_acc_id *id)
{
    asip_context *c=context_for_rx(r);
    if (c) *id=c->account;
}
static void on_reg(pjsua_acc_id id,pjsua_reg_info *info)
{
    asip_context *c=pjsua_acc_get_user_data(id);
    pjsua_acc_info a;
    char reason[256];
    PJ_UNUSED_ARG(info);
    if (!c || c->closing || pjsua_acc_get_info(id,&a)!=PJ_SUCCESS) return;
    pj_text(reason,sizeof(reason),&a.status_text);
    emit(c,ASIP_REG_STATE,0,a.status,a.expires==PJSIP_EXPIRES_NOT_SPECIFIED ? 0 : (int)a.expires,reason,"");
}
static void on_digit(pjsua_call_id id,const pjsua_dtmf_info *info)
{
    call_entry *c=pjsua_call_get_user_data(id);
    char digit[2]={(char)info->digit,0};
    pj_str_t s=pj_str(digit);
    if (!c || c->ended) return;
    if (c->peer && !c->peer->ended) pjsua_call_dial_dtmf(c->peer->native,&s);
    emit(c->ctx,ASIP_DTMF,c->id,0,(int)info->duration,digit,"");
}
static pj_status_t initialize(void)
{
    pjsua_config u;
    pjsua_logging_config l;
    pjsua_media_config m;
    pjsua_codec_info codecs[32];
    unsigned count=32,i;
    pj_status_t s;
    pj_log_set_level(getenv("ASIP_TRACE") ? 5 : 0);
    s=pjsua_create();
    if (s!=PJ_SUCCESS) return s;
    pjsua_config_default(&u); pjsua_logging_config_default(&l); pjsua_media_config_default(&m);
    u.thread_cnt=0; u.max_calls=PJSUA_MAX_CALLS;
    u.cb.on_incoming_call=on_incoming; u.cb.on_call_state=on_state;
    u.cb.on_call_media_state=on_media; u.cb.on_reg_state2=on_reg;
    u.cb.on_dtmf_digit2=on_digit; u.cb.on_acc_find_for_incoming=on_account;
    l.level=getenv("ASIP_TRACE") ? 5 : 1; l.console_level=getenv("ASIP_TRACE") ? 5 : 0; l.msg_logging=PJ_FALSE;
    m.clock_rate=m.snd_clock_rate=8000; m.channel_count=1; m.audio_frame_ptime=20;
    m.has_ioqueue=PJ_FALSE; m.thread_cnt=0; m.ec_tail_len=0;
    m.max_media_ports=PJSUA_MAX_CONF_PORTS;
    s=pjsua_init(&u,&l,&m);
    if (s==PJ_SUCCESS) s=pjsip_endpt_register_module(pjsua_get_pjsip_endpt(),&registrar_module);
    if (s==PJ_SUCCESS) s=pjsua_start();
    if (s==PJ_SUCCESS) s=pjsua_set_null_snd_dev();
    if (s!=PJ_SUCCESS) { pjsua_destroy(); registrar_module.id=-1; return s; }
    pjsua_enum_codecs(codecs,&count);
    for (i=0;i<count;++i) pjsua_codec_set_priority(&codecs[i].codec_id,
        pj_stristr(&codecs[i].codec_id,&(pj_str_t){"PCMU/",5}) ? 255 :
        pj_stristr(&codecs[i].codec_id,&(pj_str_t){"PCMA/",5}) ? 254 : 0);
    owner_thread=pj_thread_this(); initialized=1;
    return PJ_SUCCESS;
}

int asip_abi_version(void) { return ASIP_ABI_VERSION; }
static int create_context(const asip_config *cfg,const asip_callbacks *cb,void *data,
                asip_context **result,char *error,int capacity)
{
    asip_context *c;
    pjsua_transport_config t;
    pjsua_transport_info ti;
    pjsua_acc_config a;
    pjsip_auth_srv_init_param auth;
    pj_str_t realm;
    char identity[512],proxy[1024];
    pj_status_t s;
    if (result) *result=NULL;
    if (!cfg || !cb || !result || cfg->size!=sizeof(*cfg) ||
        cfg->abi_version!=ASIP_ABI_VERSION || cfg->role<0 || cfg->role>1 ||
        cfg->sip_port<0 || cfg->sip_port>65535 || cfg->rtp_port<1024 || cfg->rtp_port>65000 ||
        !safe_atom(cfg->realm,255) ||
        (cfg->role==ASIP_CLIENT && (!safe_atom(cfg->user,127) || !cfg->registrar))) {
        copy_text(error,capacity,"Invalid SIP configuration or ABI"); return PJ_EINVAL;
    }
    if (!initialized) { s=initialize(); if (s!=PJ_SUCCESS) {
        pj_strerror(s,error,capacity); return s;
    }}
    if (pj_thread_this()!=owner_thread || polling) {
        copy_text(error,capacity,"Create SIP contexts outside callbacks, on their owner thread"); return PJ_EINVALIDOP;
    }
    if (cfg->role==ASIP_CLIENT && !valid_uri(cfg->registrar)) {
        copy_text(error,capacity,"Registrar must be a sip: URI");
        if (!contexts) { pjsua_destroy(); initialized=0; registrar_module.id=-1; }
        return PJ_EINVAL;
    }
    c=calloc(1,sizeof(*c));
    if (!c) return PJ_ENOMEM;
    c->cb=*cb; c->user_data=data; c->role=cfg->role; c->sound=cfg->use_sound_device;
    c->algorithm=cfg->digest_algorithm; c->account=c->transport=PJSUA_INVALID_ID;
    copy_text(c->realm,sizeof(c->realm),cfg->realm);
    c->pool=pjsua_pool_create("asip-context",2048,2048);
    if (!c->pool) { s=PJ_ENOMEM; goto fail; }
    pjsua_transport_config_default(&t);
    t.port=cfg->sip_port; t.bound_addr=pj_str((char *)nz(cfg->bind_address));
    t.public_addr=pj_str((char *)nz(cfg->public_address));
    s=pjsua_transport_create(PJSIP_TRANSPORT_UDP,&t,&c->transport);
    if (s!=PJ_SUCCESS) goto fail;
    s=pjsua_transport_get_info(c->transport,&ti);
    if (s!=PJ_SUCCESS) goto fail;
    c->port=ti.local_name.port;
    pjsua_acc_config_default(&a);
    snprintf(identity,sizeof(identity),"sip:%s@%s",cfg->role==ASIP_SERVER ? "server" : cfg->user,cfg->realm);
    a.id=pj_str(identity); a.transport_id=c->transport; a.user_data=c;
    a.register_on_acc_add=PJ_FALSE; a.allow_contact_rewrite=PJ_FALSE;
    a.rtp_cfg.port=cfg->rtp_port;
    a.rtp_cfg.bound_addr=pj_str((char *)nz(cfg->bind_address));
    a.rtp_cfg.public_addr=pj_str((char *)nz(cfg->public_address));
    a.ice_cfg_use=PJSUA_ICE_CONFIG_USE_CUSTOM; a.ice_cfg.enable_ice=PJ_FALSE;
    if (cfg->role==ASIP_CLIENT) {
        a.reg_uri=pj_str((char *)cfg->registrar); a.reg_timeout=cfg->expires;
        snprintf(proxy,sizeof(proxy),"%s;lr",cfg->registrar);
        a.proxy_cnt=1; a.proxy[0]=pj_str(proxy);
        a.cred_count=1; a.cred_info[0].realm=pj_str("*");
        a.cred_info[0].scheme=pj_str("digest");
        a.cred_info[0].username=pj_str((char *)cfg->user);
        a.cred_info[0].data_type=PJSIP_CRED_DATA_PLAIN_PASSWD;
        a.cred_info[0].data=pj_str((char *)nz(cfg->password));
    }
    s=pjsua_acc_add(&a,PJ_FALSE,&c->account);
    if (s!=PJ_SUCCESS) goto fail;
    realm=pj_str(c->realm); pj_bzero(&auth,sizeof(auth));
    auth.realm=&realm; auth.lookup2=lookup_credential;
    s=pjsip_auth_srv_init2(c->pool,&c->auth,&auth);
    if (s!=PJ_SUCCESS) goto fail;
    if (c->sound) {
        s=pjsua_set_snd_dev(PJMEDIA_AUD_DEFAULT_CAPTURE_DEV,PJMEDIA_AUD_DEFAULT_PLAYBACK_DEV);
        if (s!=PJ_SUCCESS) goto fail;
    }
    c->next=contexts; contexts=c; *result=c;
    return PJ_SUCCESS;
fail:
    pj_strerror(s,error,capacity);
    if (c->account!=PJSUA_INVALID_ID) pjsua_acc_del(c->account);
    if (c->transport!=PJSUA_INVALID_ID) pjsua_transport_close(c->transport,PJ_FALSE);
    if (c->pool) pj_pool_release(c->pool);
    free(c);
    if (!contexts) { pjsua_destroy(); initialized=0; registrar_module.id=-1; }
    return s;
}
void asip_destroy(asip_context *ctx)
{
    asip_context **p;
    call_entry *c,**q;
    if (!ctx || !initialized || polling || pj_thread_this()!=owner_thread) return;
    ctx->closing=1;
    for (c=calls;c;c=c->next) if (c->ctx==ctx && !c->ended)
        pjsua_call_hangup(c->native,0,NULL,NULL);
    pjsua_acc_set_user_data(ctx->account,NULL);
    pjsua_acc_del(ctx->account);
    pjsua_transport_close(ctx->transport,PJ_FALSE);
    for (p=&contexts;*p && *p!=ctx;p=&(*p)->next) {}
    if (*p) *p=ctx->next;
    /* No further callback may retain this application's user_data. */
    for (q=&calls;*q;) {
        c=*q;
        if (c->ctx==ctx) {
            if (c->native!=PJSUA_INVALID_ID && !c->ended) pjsua_call_set_user_data(c->native,NULL);
            release_audio(c); *q=c->next; free(c);
        } else q=&c->next;
    }
    pj_pool_release(ctx->pool); free(ctx);
    if (!contexts) { pjsua_destroy(); initialized=0; owner_thread=NULL; registrar_module.id=-1; }
}
static int poll_contexts(int timeout_ms)
{
    asip_context *ctx;
    call_entry *c,**q;
    unsigned i,j,dropped;
    int result;
    int16_t frame[PCM_FRAME];
    if (!initialized || polling || pj_thread_this()!=owner_thread || timeout_ms<0 || timeout_ms>1000) return -PJ_EINVALIDOP;
    polling=1; result=pjsua_handle_events(timeout_ms);
    for (ctx=contexts;ctx;ctx=ctx->next) for (i=0;i<REG_LIMIT;++i) {
        registration *r=&ctx->registrations[i];
        if (r->until && r->until<=now_ms()) {
            r->until=0; emit(ctx,ASIP_REGISTRATION,0,408,0,r->user,r->contact);
        }
    }
    for (c=calls;c;c=c->next) {
        if (!c->audio || c->ended || c->ctx->closing) continue;
        for (j=0;j<RX_FRAMES;++j) {
            audio_port *a=c->audio;
            pj_mutex_lock(a->mutex); dropped=a->dropped; a->dropped=0;
            if (!a->rx_count) { pj_mutex_unlock(a->mutex); break; }
            memcpy(frame,a->rx[a->rx_head],sizeof(frame));
            a->rx_head=(a->rx_head+1)%RX_FRAMES; --a->rx_count;
            pj_mutex_unlock(a->mutex);
            if (dropped) emit(c->ctx,ASIP_AUDIO_DROPPED,c->id,0,dropped,"","");
            if (c->ctx->cb.audio) c->ctx->cb.audio(c->ctx->user_data,c->id,frame,PCM_FRAME,8000);
            if (c->ended || !c->audio) break;
        }
    }
    for (q=&calls;*q;) {
        c=*q;
        if (c->ended) { *q=c->next; free(c); } else q=&c->next;
    }
    polling=0; return result;
}
int asip_register(asip_context *ctx,int enable)
{
    pj_status_t s;
    if (!ctx || ctx->role!=ASIP_CLIENT) return -PJ_EINVAL;
    s=pjsua_acc_set_registration(ctx->account,enable ? PJ_TRUE : PJ_FALSE);
    return s==PJ_SUCCESS ? 0 : failure(ctx,s,"Register");
}
int asip_call(asip_context *ctx,const char *destination,uint64_t *id)
{
    char uri[1024]; call_entry *c;
    if (id) *id=0;
    if (!ctx || !id || !destination_uri(ctx,destination,uri,sizeof(uri))) return -PJ_EINVAL;
    c=new_call(ctx,0); if (!c) return -PJ_ENOMEM;
    *id=c->id; return make_call(ctx,uri,c);
}
int asip_answer(asip_context *ctx,uint64_t id,int status)
{
    call_entry *c=find_call(ctx,id); pj_status_t s;
    if (!c || (status!=180 && status!=200)) return -PJ_EINVAL;
    s=pjsua_call_answer(c->native,status,NULL,NULL);
    return s==PJ_SUCCESS ? 0 : failure(ctx,s,"Answer");
}
int asip_hangup(asip_context *ctx,uint64_t id,int status)
{
    call_entry *c=find_call(ctx,id); pj_status_t s;
    if (!c || (status && (status<400 || status>699))) return -PJ_EINVAL;
    s=pjsua_call_hangup(c->native,status,NULL,NULL);
    return s==PJ_SUCCESS ? 0 : failure(ctx,s,"Hangup");
}
int asip_dtmf(asip_context *ctx,uint64_t id,const char *digits)
{
    call_entry *c=find_call(ctx,id); pj_str_t s; pj_status_t status;
    const char *p;
    if (!c || !digits || !*digits || strlen(digits)>32) return -PJ_EINVAL;
    for (p=digits;*p;++p) if (!strchr("0123456789*#ABCDabcd",*p)) return -PJ_EINVAL;
    s=pj_str((char *)digits); status=pjsua_call_dial_dtmf(c->native,&s);
    return status==PJ_SUCCESS ? 0 : failure(ctx,status,"DTMF");
}
int asip_write_audio(asip_context *ctx,uint64_t id,const int16_t *samples,int count)
{
    call_entry *c=find_call(ctx,id); audio_port *a; int i;
    if (!c || !c->audio || !samples || count<0 || count>TX_SAMPLES) return -PJ_EINVAL;
    a=c->audio; pj_mutex_lock(a->mutex);
    if ((unsigned)count>TX_SAMPLES-a->tx_count) { pj_mutex_unlock(a->mutex); return -PJ_ETOOMANY; }
    for (i=0;i<count;++i) a->tx[(a->tx_head+a->tx_count+i)%TX_SAMPLES]=samples[i];
    a->tx_count+=count; pj_mutex_unlock(a->mutex); return count;
}
int asip_local_port(asip_context *ctx) { return ctx ? ctx->port : 0; }

/* FPC enables floating-point traps that C/PJMEDIA does not expect. Preserve
 * the caller's FPU environment while starting media threads and pumping C.
 * Audio threads inherit the non-trapping environment used during create. */
int asip_create(const asip_config *cfg,const asip_callbacks *cb,void *data,
                asip_context **result,char *error,int capacity)
{
    fenv_t saved;
    int status;
    feholdexcept(&saved);
    status=create_context(cfg,cb,data,result,error,capacity);
    fesetenv(&saved);
    return status;
}
int asip_poll(int timeout_ms)
{
    fenv_t saved;
    int status;
    feholdexcept(&saved);
    status=poll_contexts(timeout_ms);
    fesetenv(&saved);
    return status;
}
