# Remote desktop foundation — 0.2.0

Runtime components for applications needing an explicit-consent remote session API.

- `airemoteidentity`: OS CSPRNG, UUID, Windows DPAPI identity storage with atomic file replacement.
- `airemotesignaling`: synchronous Windows WinHTTP JSON client, HTTPS certificate validation enabled, redirects disabled, bounded response size and timeouts.
- `openai_remote_desktop.lpk`: runtime package; no mandatory LCL or AI provider.
- `tests/test_airemote_foundation.lpr`: key validation, random identity and Windows encrypted storage tests.

Configure BaseURL (including v1) in the consuming product, never in the component. Call network operations from a worker thread and free returned JSON objects. Each mutation gets a new idempotency UUID; automatic retry of a previous mutation is deliberately not implemented. Callers requiring retry must first consult session state.

AllowLocalHTTP defaults to false; when explicitly enabled it permits only localhost/127.0.0.1 for development. WinHTTP never disables certificate validation or follows redirects. Tokens are not passed to a shell/process.

This is the first executable slice: registration, heartbeat, incoming requests, requesting/accepting/rejecting/closing sessions. Capture, input injection, media transport, session credentials and TURN are not implemented here. There is no hidden control or unattended authorization. Unsupported platforms raise an error for network/secret storage; random bytes use /dev/urandom on Unix.

DPAPI binds the identity to the current Windows account and computer. Do not silently discard an unreadable identity. Applications must persist registration credentials before sending registration so a lost response does not allocate a different machine key.

Build test (Windows, FPC 3.2.2):
```
fpc "-Fupacote/AI Communication/AIRemoteDesktop" tests/test_airemote_foundation.lpr
```
