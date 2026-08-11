# Developer Source Actions

Reusable Lazarus/FPC actions for `TAIActionExecutor`.

## Components

- `TAISourceReadAction` — reads a workspace file.
- `TAISourceReplaceAction` — replaces an exact source fragment with unique-match protection and atomic temporary backup.
- `TAIProjectBuildAction` — invokes a trusted builder such as `lazbuild` for a project inside the workspace.
- `TAITrustedProjectTestAction` — invokes a trusted test runner configured by the host application.

## Security model

File paths supplied by the LLM are restricted to `WorkspaceRoot`. Path traversal outside that root is rejected. Builder and test executables are configured by the host application, not chosen by the LLM. `ASimulate=True` performs validation without changing files or running tools.

## Typical flow

1. Register the actions in `TAIActionExecutor`.
2. Let the agent produce prepared JSON actions.
3. Execute via `ExecutePreparedActionsReal`.
4. Inspect `LastOutput`/`LastError` and the executor MemoryMap.
5. Let the IDE show the resulting diff and diagnostics.

The host IDE remains responsible for user approval policy and UI presentation.
