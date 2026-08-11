# source_fix_agent_demo

Minimal Lazarus/FPC console sample showing how to register the reusable developer actions in `TAIActionExecutor`.

The demo registers source read/replace, project build and trusted test actions. It executes a prepared `read_source` action against `README.md` in the workspace supplied on the command line.

Use the same pattern in an IDE: configure `WorkspaceRoot`, register the actions once, let the orchestrator/action builder prepare the JSON plan, execute it, then present diff/diagnostics to the user.
